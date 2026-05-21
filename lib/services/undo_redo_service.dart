import '../models/span_data_model.dart';
import '../models/image_model.dart';

class EditorState {
  final String text;
  final List<SpanData> spans;
  final String alignment;
  final List<ImageData> images;

  EditorState({
    required this.text,
    required this.spans,
    required this.alignment,
    this.images = const [],
  });

  EditorState copyWith({
    String? text,
    List<SpanData>? spans,
    String? alignment,
    List<ImageData>? images,
  }) {
    return EditorState(
      text: text ?? this.text,
      spans: spans ?? this.spans,
      alignment: alignment ?? this.alignment,
      images: images ?? this.images,
    );
  }
}

class UndoRedoService {
  static const int maxHistorySize = 10;

  final List<EditorState> _history = [];
  int _currentIndex = -1;

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  void pushState(EditorState state) {
    // Remove any redo states
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(state);
    _currentIndex++;

    // Keep only last 10 states
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  EditorState? undo() {
    if (!canUndo) return null;
    _currentIndex--;
    return _history[_currentIndex];
  }

  EditorState? redo() {
    if (!canRedo) return null;
    _currentIndex++;
    return _history[_currentIndex];
  }

  EditorState? getCurrentState() {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      return _history[_currentIndex];
    }
    return null;
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}
