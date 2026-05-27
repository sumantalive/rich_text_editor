import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rich_text_editor/src/widgets/image_url_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_data.dart';
import '../services/html_converter.dart';
import '../widgets/block_editor.dart';
import '../widgets/formatting_toolbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/html_import_dialog.dart';
import '../config/editor_config.dart';

class ComposeScreen extends StatefulWidget {
  final RichTextEditorConfig config;
  final VoidCallback? onSave;
  final VoidCallback? onLoad;

  const ComposeScreen({
    super.key,
    this.config = const RichTextEditorConfig(),
    this.onSave,
    this.onLoad,
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late BlockEditorController _blockController;
  late ValueNotifier<bool> _canUndoNotifier;
  late ValueNotifier<bool> _canRedoNotifier;

  // Document-level undo history. Each entry is a full snapshot of all blocks;
  // the last entry is always the current document.
  final List<List<BlockData>> _undoStack = [];
  final List<List<BlockData>> _redoStack = [];
  static const int _maxHistory = 30;
  bool _isRestoringState = false;

  @override
  void initState() {
    super.initState();
    _blockController = BlockEditorController();
    _canUndoNotifier = ValueNotifier<bool>(false);
    _canRedoNotifier = ValueNotifier<bool>(false);

    _blockController.onContentChanged = _onContentChanged;
    _captureSnapshot(initial: true);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final htmlContent = HtmlConverter.toHtmlFromBlocks(_blockController.toBlockData());
    await prefs.setString(widget.config.storageKey, htmlContent);
    widget.onSave?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved as HTML successfully')),
      );
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(widget.config.storageKey);

    if (savedData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved data found')),
        );
      }
      return;
    }

    try {
      _loadBlocksFromHtml(savedData);
      widget.onLoad?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data loaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _importHtmlData(String htmlContent) async {
    try {
      _loadBlocksFromHtml(htmlContent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HTML imported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing HTML: $e')),
        );
      }
    }
  }

  void _loadBlocksFromHtml(String htmlContent) {
    final blocks = HtmlConverter.parseHtmlToBlocks(htmlContent);
    _blockController.loadBlocks(blocks);
    _captureSnapshot(initial: true);
  }

  void _showHtmlImportDialog() {
    showDialog(
      context: context,
      builder: (context) => HtmlImportDialog(
        onImport: _importHtmlData,
      ),
    );
  }

  bool get _canUndo => _undoStack.length > 1;
  bool get _canRedo => _redoStack.isNotEmpty;

  void _captureSnapshot({bool initial = false}) {
    final snapshot = _blockController.toBlockData();
    if (initial) {
      _undoStack
        ..clear()
        ..add(snapshot);
      _redoStack.clear();
    } else {
      _undoStack.add(snapshot);
      if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
      _redoStack.clear();
    }
    _updateUndoRedoButtons();
  }

  void _onContentChanged() {
    if (_isRestoringState) return;
    _captureSnapshot();
  }

  void _updateUndoRedoButtons() {
    _canUndoNotifier.value = _canUndo;
    _canRedoNotifier.value = _canRedo;
  }

  void _undo() {
    if (!_canUndo) return;
    _redoStack.add(_undoStack.removeLast());
    _restoreSnapshot(_undoStack.last);
  }

  void _redo() {
    if (!_canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _restoreSnapshot(next);
  }

  void _restoreSnapshot(List<BlockData> snapshot) {
    _isRestoringState = true;
    // Deep-copy so the live blocks don't mutate the stored snapshot.
    _blockController.loadBlocks(
      snapshot
          .map((b) => BlockData(
                text: b.text,
                spans: b.spans.map((s) => s.copyWith()).toList(),
                images: b.images.map((i) => i.copyWith()).toList(),
                alignment: b.alignment,
              ))
          .toList(),
    );
    _isRestoringState = false;
    _updateUndoRedoButtons();
  }

  @override
  void dispose() {
    _blockController.dispose();
    _canUndoNotifier.dispose();
    _canRedoNotifier.dispose();
    super.dispose();
  }

  void _showHtmlExport() {
    final htmlContent = HtmlConverter.toHtmlFromBlocks(_blockController.toBlockData());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HTML Export'),
        content: SingleChildScrollView(
          child: SelectableText(
            htmlContent,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(htmlContent);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HTML copied to clipboard')),
        );
      }
    });
  }
  void _showImageUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => ImageUrlDialog(
        onImageUrlAdded: (url) {
          Navigator.pop(context);
          _blockController.insertImage(url);
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.title),
        backgroundColor: widget.config.appBarColor,
        elevation: 0,
        actions: [
          if (widget.config.enableExport)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: CustomButton(
                  label: 'Export HTML',
                  icon: Icons.download,
                  onPressed: _showHtmlExport,
                ),
              ),
            ),
          if (widget.config.enableHtmlImport)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: CustomButton(
                  label: 'Import HTML',
                  icon: Icons.publish,
                  onPressed: _showHtmlImportDialog,
                ),
              ),
            ),
          if (widget.config.enableLoad)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: CustomButton(
                  label: 'Load',
                  icon: Icons.upload,
                  onPressed: _loadData,
                ),
              ),
            ),
          if (widget.config.enableSave)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: CustomButton(
                  label: 'Save',
                  icon: Icons.save,
                  onPressed: _saveData,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar rebinds to whichever block currently has focus, so every
          // tool acts on the active line.
          ListenableBuilder(
            listenable: _blockController,
            builder: (context, _) {
              final active = _blockController.activeBlock;
              return ValueListenableBuilder<bool>(
                valueListenable: _canUndoNotifier,
                builder: (context, canUndo, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _canRedoNotifier,
                    builder: (context, canRedo, _) {
                      return FormattingToolbar(
                        key: ValueKey(active.id),
                        controller: active.controller,
                        focusNode: active.focusNode,
                        initialAlignment: active.alignment,
                        canUndo: canUndo,
                        canRedo: canRedo,
                        onUndo: _undo,
                        onRedo: _redo,
                        onAlignmentChanged: _blockController.setAlignment,
                        onSelectionChanged: (value) {},
                        onImageAdded: _showImageUrlDialog,
                      );
                    },
                  );
                },
              );
            },
          ),
          const Divider(height: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter Your Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: BlockEditor(controller: _blockController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
