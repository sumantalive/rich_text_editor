import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text_editor/rich_text_editor.dart';

void main() {

  test('RichTextEditorConfig can be customized', () {
    final config = RichTextEditorConfig(
      title: 'Custom Editor',
      appBarColor: Colors.red,
      enableExport: false,
      enableHtmlImport: false,
    );

    expect(config.title, equals('Custom Editor'));
    expect(config.appBarColor, equals(Colors.red));
    expect(config.enableExport, equals(false));
    expect(config.enableHtmlImport, equals(false));
  });

  test('RichTextController can manage text', () {
    final controller = RichTextController();

    // Test basic text operations
    controller.text = 'Hello, World!';
    expect(controller.text, equals('Hello, World!'));

    // Test span data extraction
    final spans = controller.extractSpanData();
    expect(spans, isNotNull);

    // Test image data extraction
    final images = controller.extractImageData();
    expect(images, isNotNull);
  });

  test('SpanData can be created and copied', () {
    final span = SpanData(
      start: 0,
      end: 5,
      bold: true,
      italic: false,
      textColor: 0xFF000000,
    );

    expect(span.bold, equals(true));
    expect(span.italic, equals(false));

    // Test copyWith
    final modifiedSpan = span.copyWith(italic: true);
    expect(modifiedSpan.bold, equals(true));
    expect(modifiedSpan.italic, equals(true));
  });

  test('HtmlConverter can convert text to HTML', () {
    const text = 'Hello, World!';
    const spans = <SpanData>[];
    const images = <ImageData>[];
    const alignment = 'left';

    final html = HtmlConverter.toHtml(text, spans, images, alignment);

    expect(html, contains(text));
    expect(html, contains('text-align'));
  });
}
