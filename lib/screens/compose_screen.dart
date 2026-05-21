import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../controllers/rich_text_controller.dart';
import '../models/span_data_model.dart';
import '../models/image_model.dart';
import '../services/undo_redo_service.dart';
import '../services/html_converter.dart';
import '../widgets/formatting_toolbar.dart';
import '../widgets/image_preview_dialog.dart';
import '../widgets/image_link_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/html_import_dialog.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late RichTextController _bodyController;
  late FocusNode _bodyFocusNode;
  late UndoRedoService _undoRedoService;
  late ValueNotifier<String> _textAlignmentNotifier;
  late ValueNotifier<bool> _canUndoNotifier;
  late ValueNotifier<bool> _canRedoNotifier;
  late ValueNotifier<List<ImageData>> _imagesNotifier;
  bool _isRestoringState = false;

  @override
  void initState() {
    super.initState();
    _bodyController = RichTextController();
    _bodyFocusNode = FocusNode();
    _undoRedoService = UndoRedoService();
    _textAlignmentNotifier = ValueNotifier<String>('left');
    _canUndoNotifier = ValueNotifier<bool>(false);
    _canRedoNotifier = ValueNotifier<bool>(false);
    _imagesNotifier = ValueNotifier<List<ImageData>>([]);

    // Save initial state
    _saveState();

    // Listen for changes
    _bodyController.addListener(_onBodyChanged);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final htmlContent = HtmlConverter.toHtml(
      _bodyController.text,
      _bodyController.extractSpanData(),
      _bodyController.extractImageData(),
      _textAlignmentNotifier.value,
    );
    await prefs.setString('saved_data', htmlContent);
    print("htmlContent===>$htmlContent");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved as HTML successfully')),
      );
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('saved_data');

    if (savedData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved data found')),
        );
      }
      return;
    }

    try {
      _isRestoringState = true;

      if (savedData.startsWith('{')) {
        final data = jsonDecode(savedData) as Map<String, dynamic>;
        _bodyController.text = data['text'] ?? '';
        if (data['spans'] != null) {
          final spansList = (data['spans'] as List)
              .map((span) => SpanData.fromJson(span as Map<String, dynamic>))
              .toList();
          _bodyController.spans = spansList;
        }
        if (data['images'] != null) {
          final imagesList = (data['images'] as List)
              .map((img) => ImageData.fromJson(img as Map<String, dynamic>))
              .toList();
          _bodyController.images = imagesList;
          _imagesNotifier.value = List.from(imagesList);
        }
        _textAlignmentNotifier.value = data['alignment'] ?? 'left';
      } else {
        _bodyController.text = HtmlConverter.fromHtml(savedData);
        _textAlignmentNotifier.value = 'left';
      }

      _isRestoringState = false;
      _undoRedoService.clear();
      _updateUndoRedoButtons();
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
      _isRestoringState = true;

      final importData = HtmlConverter.parseHtmlFull(htmlContent);
      _bodyController.text = importData.text;
      _bodyController.spans = importData.spans;
      _bodyController.images = importData.images;
      _imagesNotifier.value = List.from(importData.images);
      _textAlignmentNotifier.value = importData.alignment;

      _isRestoringState = false;
      _undoRedoService.clear();
      _updateUndoRedoButtons();
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

  void _showHtmlImportDialog() {
    showDialog(
      context: context,
      builder: (context) => HtmlImportDialog(
        onImport: _importHtmlData,
      ),
    );
  }

  void _saveState() {
    if (_isRestoringState) return;

    final state = EditorState(
      text: _bodyController.text,
      spans: List.from(_bodyController.extractSpanData()),
      alignment: _textAlignmentNotifier.value,
      images: List.from(_bodyController.extractImageData()),
    );
    _undoRedoService.pushState(state);
    _updateUndoRedoButtons();
  }

  void _onBodyChanged() {
    _saveState();
    _updateUndoRedoButtons();
  }

  void _updateUndoRedoButtons() {
    _canUndoNotifier.value = _undoRedoService.canUndo;
    _canRedoNotifier.value = _undoRedoService.canRedo;
  }

  void _undo() {
    final state = _undoRedoService.undo();
    if (state != null) {
      _isRestoringState = true;
      _bodyController.text = state.text;
      _bodyController.spans = state.spans;
      _bodyController.images = state.images;
      _imagesNotifier.value = List.from(state.images);
      _textAlignmentNotifier.value = state.alignment;
      _isRestoringState = false;
      _updateUndoRedoButtons();
    }
  }

  void _redo() {
    final state = _undoRedoService.redo();
    if (state != null) {
      _isRestoringState = true;
      _bodyController.text = state.text;
      _bodyController.spans = state.spans;
      _bodyController.images = state.images;
      _imagesNotifier.value = List.from(state.images);
      _textAlignmentNotifier.value = state.alignment;
      _isRestoringState = false;
      _updateUndoRedoButtons();
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    _textAlignmentNotifier.dispose();
    _canUndoNotifier.dispose();
    _canRedoNotifier.dispose();
    _imagesNotifier.dispose();
    super.dispose();
  }

  TextAlign _getTextAlign(String alignment) {
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

  void _showHtmlExport() {
    final htmlContent = HtmlConverter.toHtml(
      _bodyController.text,
      _bodyController.extractSpanData(),
      _bodyController.extractImageData(),
      _textAlignmentNotifier.value,
    );

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
    if (mounted) {
      Clipboard.setData(ClipboardData(text: "Your text here")).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HTML copied to clipboard')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Editor'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
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
          ValueListenableBuilder<String>(
            valueListenable: _textAlignmentNotifier,
            builder: (context, alignment, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: _canUndoNotifier,
                builder: (context, canUndo, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _canRedoNotifier,
                    builder: (context, canRedo, _) {
                      return FormattingToolbar(
                        controller: _bodyController,
                        initialAlignment: alignment,
                        focusNode: _bodyFocusNode,
                        canUndo: canUndo,
                        canRedo: canRedo,
                        onUndo: _undo,
                        onRedo: _redo,
                        onAlignmentChanged: (newAlignment) {
                          _textAlignmentNotifier.value = newAlignment;
                          Future.delayed(const Duration(milliseconds: 100), _saveState);
                          _bodyFocusNode.requestFocus();
                        },
                        onSelectionChanged: (value) {},
                        onImageAdded: (url) {
                          _bodyController.addImage(url);
                          _imagesNotifier.value = List.from(_bodyController.images);
                          _saveState();
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          const Divider(height: 0),
          Expanded(
            child: Column(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _textAlignmentNotifier,
                  builder: (context, alignment, _) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Enter Your Message',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500,letterSpacing: 0.8)),
                            SizedBox(height: 4),
                            TextField(
                              controller: _bodyController,
                              focusNode: _bodyFocusNode,
                              maxLines: null,
                              textAlign: _getTextAlign(alignment),
                              decoration: InputDecoration(
                                hintText: 'Write message...',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<List<ImageData>>(
                  valueListenable: _imagesNotifier,
                  builder: (context, images, _) {
                    if (images.isEmpty) return const SizedBox.shrink();
                    return Container(
                      height: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: ReorderableListView(
                        scrollDirection: Axis.horizontal,
                        onReorder: (oldIndex, newIndex) {
                          _bodyController.reorderImages(oldIndex, newIndex);
                          _imagesNotifier.value = List.from(_bodyController.images);
                          _saveState();
                        },
                        children: [
                          for (int i = 0; i < images.length; i++)
                            SizedBox(
                              key: ValueKey(images[i].id),
                              width: 100,
                              height: 100,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => ImagePreviewDialog(
                                            imageUrl: images[i].imageUrl,
                                            linkUrl: images[i].linkUrl,
                                            onAddLinkPressed: () {
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                builder: (context) => ImageLinkDialog(
                                                  initialLink: images[i].linkUrl,
                                                  onLinkSaved: (link) {
                                                    _bodyController.updateImageLink(images[i].id, link);
                                                    _imagesNotifier.value = List.from(_bodyController.images);
                                                    _saveState();
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                images[i].imageUrl,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 100,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.image_not_supported, size: 24),
                                                        SizedBox(height: 4),
                                                        Text('Load Error', style: TextStyle(fontSize: 10)),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (images[i].linkUrl != null && images[i].linkUrl!.isNotEmpty)
                                                Positioned(
                                                  bottom: 4,
                                                  left: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.8),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Icon(Icons.link, size: 12, color: Colors.white),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          _bodyController.removeImage(images[i].id);
                                          _imagesNotifier.value = List.from(_bodyController.images);
                                          _saveState();
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => ImageLinkDialog(
                                              initialLink: images[i].linkUrl,
                                              onLinkSaved: (link) {
                                                _bodyController.updateImageLink(images[i].id, link);
                                                _imagesNotifier.value = List.from(_bodyController.images);
                                                _saveState();
                                              },
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.more_vert,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
