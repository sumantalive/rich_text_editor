import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../controllers/rich_text_controller.dart';
import '../models/email_model.dart';
import '../services/undo_redo_service.dart';
import '../widgets/formatting_toolbar.dart';

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

    // Save initial state
    _saveState();

    // Listen for changes
    _bodyController.addListener(_onBodyChanged);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'text': _bodyController.text,
      'spans': _bodyController.extractSpanData(),
      'alignment': _textAlignmentNotifier.value,
    };
    await prefs.setString('saved_data', jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved successfully')),
      );
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDataJson = prefs.getString('saved_data');

    if (savedDataJson == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved data found')),
        );
      }
      return;
    }

    try {
      final data = jsonDecode(savedDataJson) as Map<String, dynamic>;
      _isRestoringState = true;

      _bodyController.text = data['text'] ?? '';
      if (data['spans'] != null) {
        final spansList = (data['spans'] as List)
            .map((span) => SpanData.fromJson(span as Map<String, dynamic>))
            .toList();
        _bodyController.spans = spansList;
      }
      _textAlignmentNotifier.value = data['alignment'] ?? 'left';

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

  void _saveState() {
    if (_isRestoringState) return;

    final state = EditorState(
      text: _bodyController.text,
      spans: List.from(_bodyController.extractSpanData()),
      alignment: _textAlignmentNotifier.value,
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
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.upload),
                label: const Text('Load'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _saveData,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
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
                      );
                    },
                  );
                },
              );
            },
          ),
          const Divider(height: 0),
          ValueListenableBuilder<String>(
            valueListenable: _textAlignmentNotifier,
            builder: (context, alignment, _) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    maxLines: null,
                    expands: true,
                    textAlign: _getTextAlign(alignment),
                    decoration: InputDecoration(
                      hintText: 'Start typing...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
