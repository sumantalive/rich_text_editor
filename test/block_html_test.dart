import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text_editor/src/services/html_converter.dart';
import 'package:rich_text_editor/src/models/block_data.dart';

void main() {
  group('block HTML', () {
    test('parses per-line alignment from Gmail-style HTML', () {
      const html =
          '<div style="text-align: right;">line one</div>'
          '<div style="text-align: center;">line two</div>'
          '<div style="text-align: left;">line three</div>';

      final blocks = HtmlConverter.parseHtmlToBlocks(html);

      expect(blocks.length, 3);
      expect(blocks[0].text, 'line one');
      expect(blocks[0].alignment, 'right');
      expect(blocks[1].alignment, 'center');
      expect(blocks[2].alignment, 'left');
    });

    test('round-trips alignment through export', () {
      final blocks = [
        BlockData(text: 'a', alignment: 'center'),
        BlockData(text: 'b', alignment: 'right'),
      ];
      final html = HtmlConverter.toHtmlFromBlocks(blocks);

      expect(html.contains('text-align: center;'), isTrue);
      expect(html.contains('text-align: right;'), isTrue);

      final reparsed = HtmlConverter.parseHtmlToBlocks(html);
      expect(reparsed.map((b) => b.alignment).toList(), ['center', 'right']);
      expect(reparsed.map((b) => b.text).toList(), ['a', 'b']);
    });

    test('handles nested Gmail divs and <br> empty lines', () {
      const html = '<div><div style="text-align: center;">hi</div>'
          '<div><br></div></div>';
      final blocks = HtmlConverter.parseHtmlToBlocks(html);
      expect(blocks.any((b) => b.text == 'hi' && b.alignment == 'center'), isTrue);
    });
  });
}
