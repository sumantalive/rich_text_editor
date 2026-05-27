import 'span_data_model.dart';
import 'image_model.dart';

/// Plain data for one paragraph/line. Used to load HTML, persist, and restore
/// undo snapshots without coupling the parser to live editor widgets.
class BlockData {
  final String text;
  final List<SpanData> spans;
  final List<ImageData> images;
  final String alignment;

  BlockData({
    required this.text,
    this.spans = const [],
    this.images = const [],
    this.alignment = 'left',
  });
}
