import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text_editor/src/controllers/rich_text_controller.dart';

void main() {
  group('setSelectionLink', () {
    test('adds a link to the selected range only', () {
      final c = RichTextController()..text = 'hello world';
      c.setSelectionLink('https://x.com',
          explicitSelection: const TextSelection(baseOffset: 0, extentOffset: 5));

      final linked = c.spans.where((s) => s.linkUrl != null).toList();
      expect(linked, isNotEmpty);
      // Every linked span stays within the selected [0,5) range.
      for (final s in linked) {
        expect(s.start, greaterThanOrEqualTo(0));
        expect(s.end, lessThanOrEqualTo(5));
        expect(s.linkUrl, 'https://x.com');
      }
      // 'world' (offset 6+) carries no link.
      expect(c.getFormattingAt(7).linkUrl, isNull);
    });

    test('clears an existing link', () {
      final c = RichTextController()..text = 'hello world';
      const sel = TextSelection(baseOffset: 0, extentOffset: 5);
      c.setSelectionLink('https://x.com', explicitSelection: sel);
      expect(c.getFormattingAt(2).linkUrl, 'https://x.com');

      c.setSelectionLink(null, explicitSelection: sel);
      expect(c.getFormattingAt(2).linkUrl, isNull);
    });
  });

  group('updateImageLink', () {
    test('sets then clears an image link', () {
      final c = RichTextController();
      c.addImage('https://img.com/a.png', 0);
      final id = c.images.first.id;

      c.updateImageLink(id, 'https://dest.com');
      expect(c.images.first.linkUrl, 'https://dest.com');

      c.updateImageLink(id, null);
      expect(c.images.first.linkUrl, isNull);
    });
  });
}
