import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../controllers/rich_text_controller.dart';
import 'span_data_model.dart';
import 'image_model.dart';

/// One paragraph/line in the block editor. Each block owns its own
/// [RichTextController] (so all the existing span/image/formatting machinery
/// works per line) plus its own [FocusNode] and paragraph [alignment].
///
/// A block never contains a newline — pressing Enter splits it into two
/// blocks, and Backspace at offset 0 merges it into the previous one. This is
/// what lets every line carry its own alignment, like an email compose box.
class EditorBlock {
  final String id;
  final RichTextController controller;
  final FocusNode focusNode;

  EditorBlock({
    String? id,
    String text = '',
    List<SpanData>? spans,
    List<ImageData>? images,
    String alignment = 'left',
  })  : id = id ?? const Uuid().v4(),
        controller = RichTextController(),
        focusNode = FocusNode() {
    controller.blockAlignment = alignment;
    if (text.isNotEmpty || (spans?.isNotEmpty ?? false) || (images?.isNotEmpty ?? false)) {
      controller.setContent(text: text, spans: spans, images: images);
    }
  }

  String get alignment => controller.blockAlignment;
  set alignment(String value) => controller.blockAlignment = value;

  String get text => controller.text;
  List<SpanData> get spans => controller.spans;
  List<ImageData> get images => controller.images;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
