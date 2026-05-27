import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/rich_text_controller.dart';
import '../models/editor_block.dart';
import '../models/block_data.dart';
import '../models/span_data_model.dart';
import '../models/image_model.dart';

/// Owns the list of [EditorBlock]s and all structural operations (split on
/// Enter, merge on Backspace, alignment, image insert, undo snapshots). The
/// toolbar binds to [activeController]; [ComposeScreen] listens for changes.
class BlockEditorController extends ChangeNotifier {
  final List<EditorBlock> _blocks = [];
  EditorBlock? _activeBlock;

  /// Called whenever block content changes (for autosave / undo capture).
  VoidCallback? onContentChanged;

  /// True while we are programmatically rebuilding blocks (load / undo), so
  /// content-change notifications can be suppressed by the host.
  bool isRestoring = false;

  BlockEditorController() {
    _addBlock(EditorBlock(), notify: false);
    _activeBlock = _blocks.first;
  }

  List<EditorBlock> get blocks => List.unmodifiable(_blocks);
  EditorBlock get activeBlock => _activeBlock ?? _blocks.first;
  RichTextController get activeController => activeBlock.controller;
  String get activeAlignment => activeBlock.alignment;

  // ---- block lifecycle -----------------------------------------------------

  void _addBlock(EditorBlock block, {required bool notify, int? at}) {
    if (at == null) {
      _blocks.add(block);
    } else {
      _blocks.insert(at, block);
    }
    block.focusNode.onKeyEvent = (node, event) => _onKey(block, event);
    void focusListener() => _onFocusChange(block);
    void contentListener() => _onBlockChanged(block);
    _focusListeners[block.id] = focusListener;
    _contentListeners[block.id] = contentListener;
    block.focusNode.addListener(focusListener);
    block.controller.addListener(contentListener);
    if (notify) notifyListeners();
  }

  final Map<String, VoidCallback> _focusListeners = {};
  final Map<String, VoidCallback> _contentListeners = {};

  /// Suppresses per-keystroke content notifications while a structural edit
  /// (split/merge) runs, so each Enter/Backspace yields a single undo step.
  bool _suppressNotify = false;

  void _disposeBlock(EditorBlock block) {
    final f = _focusListeners.remove(block.id);
    if (f != null) block.focusNode.removeListener(f);
    final c = _contentListeners.remove(block.id);
    if (c != null) block.controller.removeListener(c);
    block.dispose();
  }

  void _notifyContentChanged() {
    if (!isRestoring && !_suppressNotify) onContentChanged?.call();
  }

  /// Per-block change handler. A newline in a block's text means Enter was
  /// entered via a soft keyboard/IME (hardware Enter is caught in [_onKey]
  /// before any text is inserted), so split at it. Otherwise just notify.
  void _onBlockChanged(EditorBlock block) {
    if (block.text.contains('\n')) {
      Future.microtask(() {
        if (!_blocks.contains(block)) return;
        final idx = block.text.indexOf('\n');
        if (idx < 0) return;
        _splitBlock(block, idx, idx + 1);
      });
      return;
    }
    _notifyContentChanged();
  }

  void _onFocusChange(EditorBlock block) {
    if (block.focusNode.hasFocus && !identical(_activeBlock, block)) {
      _activeBlock = block;
      notifyListeners();
    }
  }

  // ---- key handling: Enter splits, Backspace-at-start merges ---------------

  KeyEventResult _onKey(EditorBlock block, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final sel = block.controller.selection;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final start = sel.start < 0 ? block.text.length : sel.start;
      final end = sel.end < 0 ? start : sel.end;
      _splitBlock(block, start, end);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace) {
      if (sel.isCollapsed && sel.start == 0) {
        final index = _blocks.indexOf(block);
        if (index > 0) {
          _mergeWithPrevious(block);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _splitBlock(EditorBlock block, int selStart, int selEnd) {
    final text = block.text;
    selStart = selStart.clamp(0, text.length);
    selEnd = selEnd.clamp(selStart, text.length);

    final leftText = text.substring(0, selStart);
    final rightText = text.substring(selEnd);

    final leftSpans = _clipSpans(block.spans, 0, selStart, 0);
    final rightSpans = _clipSpans(block.spans, selEnd, text.length, selEnd);

    final leftImages = _clipImages(block.images, 0, selStart, 0);
    final rightImages = _clipImages(block.images, selEnd, text.length, selEnd);

    final newBlock = EditorBlock(alignment: block.alignment);
    final index = _blocks.indexOf(block);

    _suppressNotify = true;
    block.controller.setContent(
      text: leftText,
      spans: leftSpans,
      images: leftImages,
      selection: TextSelection.collapsed(offset: leftText.length),
    );
    _addBlock(newBlock, notify: false, at: index + 1);
    newBlock.controller.setContent(
      text: rightText,
      spans: rightSpans,
      images: rightImages,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _suppressNotify = false;

    _activeBlock = newBlock;
    notifyListeners();
    _focusBlock(newBlock, offset: 0);
    _notifyContentChanged();
  }

  void _mergeWithPrevious(EditorBlock block) {
    final index = _blocks.indexOf(block);
    final prev = _blocks[index - 1];
    final mergeOffset = prev.text.length;

    final mergedText = prev.text + block.text;
    final mergedSpans = [
      ...prev.spans,
      ..._clipSpans(block.spans, 0, block.text.length, -mergeOffset),
    ];
    final mergedImages = [
      ...prev.images,
      ..._clipImages(block.images, 0, block.text.length, -mergeOffset),
    ];

    _suppressNotify = true;
    prev.controller.setContent(
      text: mergedText,
      spans: mergedSpans,
      images: mergedImages,
      selection: TextSelection.collapsed(offset: mergeOffset),
    );
    _blocks.removeAt(index);
    _disposeBlock(block);
    _suppressNotify = false;

    _activeBlock = prev;
    notifyListeners();
    _focusBlock(prev, offset: mergeOffset);
    _notifyContentChanged();
  }

  /// Returns spans overlapping [start, end), clipped to that range and shifted
  /// left by [shift] (so the result is relative to the new block's text).
  List<SpanData> _clipSpans(List<SpanData> spans, int start, int end, int shift) {
    final out = <SpanData>[];
    for (final s in spans) {
      final ns = s.start.clamp(start, end);
      final ne = s.end.clamp(start, end);
      if (ne > ns) out.add(s.copyWith(start: ns - shift, end: ne - shift));
    }
    return out;
  }

  List<ImageData> _clipImages(List<ImageData> images, int start, int end, int shift) {
    final out = <ImageData>[];
    for (final img in images) {
      if (img.position >= start && img.position < end) {
        out.add(img.copyWith(position: img.position - shift));
      }
    }
    return out;
  }

  void _focusBlock(EditorBlock block, {required int offset}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      block.focusNode.requestFocus();
      block.controller.selection = TextSelection.collapsed(
        offset: offset.clamp(0, block.text.length),
      );
    });
  }

  // ---- toolbar-driven operations -------------------------------------------

  void setAlignment(String alignment) {
    activeBlock.alignment = alignment;
    notifyListeners();
    _notifyContentChanged();
  }

  void insertImage(String url) {
    final offset = activeController.selection.baseOffset;
    // addImage notifies the block's listener, which captures the snapshot.
    activeController.addImage(url, offset < 0 ? activeController.text.length : offset);
  }

  // ---- load / snapshot ------------------------------------------------------

  void loadBlocks(List<BlockData> data) {
    isRestoring = true;
    for (final b in _blocks) {
      _disposeBlock(b);
    }
    _blocks.clear();
    final source = data.isEmpty ? [BlockData(text: '')] : data;
    for (final d in source) {
      _addBlock(
        EditorBlock(
          text: d.text,
          spans: d.spans,
          images: d.images,
          alignment: d.alignment,
        ),
        notify: false,
      );
    }
    _activeBlock = _blocks.first;
    isRestoring = false;
    notifyListeners();
  }

  List<BlockData> toBlockData() => _blocks
      .map((b) => BlockData(
            text: b.text,
            spans: b.spans.map((s) => s.copyWith()).toList(),
            images: b.images.map((i) => i.copyWith()).toList(),
            alignment: b.alignment,
          ))
      .toList();

  @override
  void dispose() {
    for (final b in _blocks) {
      _disposeBlock(b);
    }
    super.dispose();
  }
}

/// Renders the document as a vertical stack of per-line fields, each with its
/// own alignment — the editing surface that behaves like an email compose box.
class BlockEditor extends StatefulWidget {
  final BlockEditorController controller;
  final String hintText;

  const BlockEditor({
    super.key,
    required this.controller,
    this.hintText = 'Write message...',
  });

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  TextAlign _align(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  /// Focuses the last block and places the caret at its end, so tapping the
  /// empty area below the content lets the user keep writing after the text.
  void _focusLastBlock() {
    final blocks = widget.controller.blocks;
    if (blocks.isEmpty) return;
    final last = blocks.last;
    last.focusNode.requestFocus();
    last.controller.selection =
        TextSelection.collapsed(offset: last.controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.controller.blocks;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxImageWidth =
            (constraints.maxWidth - 24).clamp(0.0, double.infinity);
        return SingleChildScrollView(
          // Always allow the board to scroll, even when content is shorter
          // than the viewport (so long documents/tall images are reachable).
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            // Make the editable surface fill the box height so the tap area
            // below the last line is part of the editor, not dead space.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focusLastBlock,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < blocks.length; i++)
                    _buildBlock(blocks[i], i == 0, maxImageWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlock(EditorBlock block, bool isFirst, double maxImageWidth) {
    block.controller.maxImageWidth = maxImageWidth;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: TextField(
        controller: block.controller,
        focusNode: block.focusNode,
        maxLines: null,
        // The default strut forces a fixed font-based line height, which caps
        // the line and stops a tall inline image (WidgetSpan) from growing it —
        // the image would overflow and overlap the next line. Disabling the
        // strut lets each line's height track its content, so a line holding an
        // image grows to the image's height.
        strutStyle: StrutStyle.disabled,
        textAlign: _align(block.alignment),
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: isFirst ? widget.hintText : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }
}
