import '../models/span_data_model.dart';
import '../models/image_model.dart';
import '../models/block_data.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class HtmlConverter {
  /// Serializes a list of blocks to Gmail-style HTML: one `<div>` per line,
  /// each carrying its own `text-align`, with inline formatting, links and
  /// natural-size images. Empty lines become `<div><br></div>`.
  ///
  /// `white-space: pre-wrap` is written on every block so the rendered HTML
  /// preserves what the user typed: runs of spaces stay as multiple spaces,
  /// trailing whitespace at the end of a line stays visible, and the line
  /// still wraps at the container width. Without this, the browser collapses
  /// consecutive spaces and trims trailing whitespace per the HTML default,
  /// so a paragraph the user right-aligned and padded with spaces would lose
  /// that padding on export.
  static String toHtmlFromBlocks(List<BlockData> blocks) {
    if (blocks.isEmpty) return '';
    final buffer = StringBuffer();
    for (final block in blocks) {
      buffer.write(
        '<div style="text-align: ${block.alignment}; white-space: pre-wrap;">',
      );
      if (block.text.isEmpty && block.images.isEmpty) {
        buffer.write('<br>');
      } else {
        _writeBlockInner(buffer, block.text, block.spans, block.images);
      }
      buffer.write('</div>');
    }
    return buffer.toString();
  }

  /// Parses HTML into per-line blocks, preserving each block's alignment.
  static List<BlockData> parseHtmlToBlocks(String htmlContent) {
    final doc = html_parser.parse(htmlContent);
    if (doc.body == null) return [BlockData(text: '')];

    final out = <BlockData>[];
    _collectBlocks(doc.body!, 'left', out);
    return out.isEmpty ? [BlockData(text: '')] : out;
  }

  /// Walks the tree collecting one [BlockData] per leaf block element
  /// (`div`/`p` with no block children). Alignment cascades from ancestors.
  static void _collectBlocks(html_dom.Element el, String inherited, List<BlockData> out) {
    final alignment = _alignmentOf(el, inherited);
    final blockChildren = el.children
        .where((c) => c.localName == 'div' || c.localName == 'p')
        .toList();

    if (blockChildren.isEmpty) {
      out.addAll(_parseLeafBlock(el, alignment));
    } else {
      for (final child in blockChildren) {
        _collectBlocks(child, alignment, out);
      }
    }
  }

  static String _alignmentOf(html_dom.Element el, String inherited) {
    final style = el.attributes['style'] ?? '';
    final match = RegExp(r'text-align:\s*(\w+)').firstMatch(style);
    return match != null ? (match.group(1) ?? inherited) : inherited;
  }

  /// Parses the inline content of a leaf block. A `<br>` inside it produces an
  /// extra (empty or split) block so each rendered line stays separate.
  static List<BlockData> _parseLeafBlock(html_dom.Element el, String alignment) {
    final text = StringBuffer();
    final spans = <SpanData>[];
    final images = <ImageData>[];
    for (final node in el.nodes) {
      _parseNode(node, text, spans, images, 0);
    }
    var finalText = text.toString();
    while (finalText.endsWith('\n')) {
      finalText = finalText.substring(0, finalText.length - 1);
    }
    _adjustSpanOffsets(spans, finalText);
    return _splitIntoLines(finalText, spans, images, alignment);
  }

  /// Splits a parsed block on any embedded newlines into separate [BlockData],
  /// distributing spans and images so each line keeps its formatting.
  static List<BlockData> _splitIntoLines(
    String text,
    List<SpanData> spans,
    List<ImageData> images,
    String alignment,
  ) {
    if (!text.contains('\n')) {
      return [BlockData(text: text, spans: spans, images: images, alignment: alignment)];
    }
    final out = <BlockData>[];
    var lineStart = 0;
    for (var i = 0; i <= text.length; i++) {
      if (i == text.length || text[i] == '\n') {
        final lineEnd = i;
        final lineText = text.substring(lineStart, lineEnd);
        final lineSpans = <SpanData>[];
        for (final s in spans) {
          final ns = s.start.clamp(lineStart, lineEnd);
          final ne = s.end.clamp(lineStart, lineEnd);
          if (ne > ns) lineSpans.add(s.copyWith(start: ns - lineStart, end: ne - lineStart));
        }
        final lineImages = <ImageData>[];
        for (final img in images) {
          if (img.position >= lineStart && img.position < lineEnd) {
            lineImages.add(img.copyWith(position: img.position - lineStart));
          }
        }
        out.add(BlockData(text: lineText, spans: lineSpans, images: lineImages, alignment: alignment));
        lineStart = i + 1;
      }
    }
    return out;
  }

  /// Writes the inner HTML of one block: formatted text segments interleaved
  /// with inline images (shared by [toHtml] and [toHtmlFromBlocks]).
  static void _writeBlockInner(StringBuffer buffer, String text, List<SpanData> spans, List<ImageData> images) {
    const imagePlaceholder = '￼';
    final sortedSpans = [...spans]..sort((a, b) => a.start.compareTo(b.start));
    var lastEnd = 0;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == imagePlaceholder) {
        if (i > lastEnd) {
          _addFormattedTextSegment(buffer, text.substring(lastEnd, i), lastEnd, sortedSpans);
        }
        final imageData = images.firstWhere(
          (img) => img.position == i,
          orElse: () => ImageData(imageUrl: ''),
        );
        if (imageData.imageUrl.isNotEmpty) {
          _writeImage(buffer, imageData);
        }
        lastEnd = i + 1;
      }
    }

    if (lastEnd < text.length) {
      _addFormattedTextSegment(buffer, text.substring(lastEnd), lastEnd, sortedSpans);
    }
  }

  /// Emits one `<img>` (optionally wrapped in a link). Width/height are only
  /// written when known (> 0) so unsized images render at their natural size.
  static void _writeImage(StringBuffer buffer, ImageData imageData) {
    final hasLink = imageData.linkUrl != null && imageData.linkUrl!.isNotEmpty;
    if (hasLink) {
      buffer.write('<a href="${_escapeHtml(imageData.linkUrl!)}" target="_blank">');
    }
    final w = imageData.width.round();
    final h = imageData.height.round();
    final sizeAttrs = (w > 0 && h > 0) ? ' width="$w" height="$h"' : '';
    final sizeStyle = (w > 0 && h > 0) ? 'width: ${w}px; height: ${h}px; ' : '';
    buffer.write(
      '<img src="${_escapeHtml(imageData.imageUrl)}"$sizeAttrs style="${sizeStyle}max-width: 100%; margin: 8px 0; border: none;" alt="image"/>',
    );
    if (hasLink) {
      buffer.write('</a>');
    }
  }
  static String toHtml(String text, List<SpanData> spans, List<ImageData> images, String alignment) {
    if (text.isEmpty && images.isEmpty) return '';

    final buffer = StringBuffer();
    // See [toHtmlFromBlocks] for why pre-wrap is needed.
    buffer.write('<div style="text-align: $alignment; white-space: pre-wrap;">');

    if (text.isEmpty) {
      buffer.write('</div>');
      return buffer.toString();
    }

    _writeBlockInner(buffer, text, spans, images);

    buffer.write('</div>');
    return buffer.toString();
  }

  static void _addFormattedTextSegment(StringBuffer buffer, String textSegment, int segmentStart, List<SpanData> sortedSpans) {
    var lastEnd = 0;
    final segmentEnd = segmentStart + textSegment.length;

    for (final span in sortedSpans) {
      if (span.end <= segmentStart || span.start >= segmentEnd) continue;

      final spanStartInSegment = span.start > segmentStart ? span.start - segmentStart : 0;
      final spanEndInSegment = span.end < segmentEnd ? span.end - segmentStart : textSegment.length;

      if (spanStartInSegment > lastEnd) {
        buffer.write(_escapeHtml(textSegment.substring(lastEnd, spanStartInSegment)));
      }

      final spanText = textSegment.substring(spanStartInSegment, spanEndInSegment);
      buffer.write(_formatSpan(spanText, span));

      lastEnd = spanEndInSegment;
    }

    if (lastEnd < textSegment.length) {
      buffer.write(_escapeHtml(textSegment.substring(lastEnd)));
    }
  }


  static String _formatSpan(String text, SpanData span) {
    var html = _escapeHtml(text);

    if (span.linkUrl != null && span.linkUrl!.isNotEmpty) {
      html = '<a href="${_escapeHtml(span.linkUrl!)}" style="color: #0A7EFF; text-decoration: underline; text-decoration-color: #0A7EFF;">$html</a>';
    }

    if (span.bold) html = '<strong>$html</strong>';
    if (span.italic) html = '<em>$html</em>';
    if (span.underline) html = '<u>$html</u>';
    if (span.strikethrough) html = '<s>$html</s>';

    final fontSize = span.fontSize != 14.0 ? 'font-size: ${span.fontSize}px;' : '';
    final textColor = span.textColor != 0xFF000000 ? 'color: ${_colorToHex(span.textColor)};' : '';
    final bgColor = span.highlightColor != null ? 'background-color: ${_colorToHex(span.highlightColor!)};' : '';
    final decorationColor = (span.underline || span.strikethrough) ? 'text-decoration-color: ${_colorToHex(span.textColor)};' : '';

    final fontFamily = _getFontFamilyName(span.fontFamily);
    final fontFamilyStyle = fontFamily != null ? 'font-family: $fontFamily;' : '';

    final styles = [fontSize, textColor, bgColor, fontFamilyStyle, decorationColor].where((s) => s.isNotEmpty).join(' ');

    if (styles.isNotEmpty) {
      html = '<span style="$styles">$html</span>';
    }

    return html;
  }

  static String _colorToHex(int color) {
    return '#${color.toRadixString(16).substring(2).toUpperCase()}';
  }

  static String? _getFontFamilyName(String fontFamily) {
    switch (fontFamily) {
      case 'default':
        return null;
      case 'sans-serif':
        return 'sans-serif';
      case 'serif':
        return 'serif';
      case 'monospace':
        return 'monospace';
      case 'comic-sans-ms':
        return 'Comic Sans MS';
      case 'garamond':
        return 'Garamond';
      case 'georgia':
        return 'Georgia';
      case 'tahoma':
        return 'Tahoma';
      case 'trebuchet-ms':
        return 'Trebuchet MS';
      case 'verdana':
        return 'Verdana';
      default:
        return fontFamily == 'default' ? null : fontFamily;
    }
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _unescapeHtml(String html) {
    return html
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  static String fromHtml(String html) {
    // Simple HTML to plain text conversion
    html = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    html = html.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    html = html.replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '');
    return _unescapeHtml(html).trim();
  }

  static void _parseNode(
    html_dom.Node node,
    StringBuffer text,
    List<SpanData> spans,
    List<ImageData> images,
    int depth,
  ) {
    const imagePlaceholder = '￼';

    if (node is html_dom.Text) {
      final nodeText = node.text;
      if (nodeText.isNotEmpty) {
        text.write(_unescapeHtml(nodeText));
      }
    } else if (node is html_dom.Element) {
      final tag = node.localName;
      final startOffset = text.length;

      if (tag == 'img') {
        final src = node.attributes['src'] ?? '';
        final linkUrl = node.parent?.localName == 'a'
            ? (node.parent as html_dom.Element).attributes['href'] ?? ''
            : '';
        if (src.isNotEmpty) {
          text.write(imagePlaceholder);
          final imgStyle = node.attributes['style'] ?? '';
          final width = _extractImageDimension(node, imgStyle, 'width');
          final height = _extractImageDimension(node, imgStyle, 'height');
          images.add(ImageData(
            id: _generateId(),
            imageUrl: src,
            position: text.length - 1,
            linkUrl: linkUrl.isNotEmpty ? linkUrl : null,
            // 0 = auto: resolve from the image's natural size on load.
            width: width ?? 0,
            height: height ?? width ?? 0,
          ));
        }
      } else if (tag == 'br') {
        text.write('\n');
      } else if (tag != 'a' || node.parent?.localName != 'a') {
        for (final child in node.nodes) {
          _parseNode(child, text, spans, images, depth + 1);
        }
      } else {
        for (final child in node.nodes) {
          _parseNode(child, text, spans, images, depth + 1);
        }
      }

      if (tag == 'p' || tag == 'div') {
        if (text.isNotEmpty && !text.toString().endsWith('\n')) {
          text.write('\n');
        }
      }

      final endOffset = text.length;

      if ((tag == 'strong' || tag == 'b') && startOffset < endOffset) {
        _addSpanModifier(spans, startOffset, endOffset, (span) {
          return span.copyWith(bold: true);
        });
      }

      if ((tag == 'em' || tag == 'i') && startOffset < endOffset) {
        _addSpanModifier(spans, startOffset, endOffset, (span) {
          return span.copyWith(italic: true);
        });
      }

      if (tag == 'u' && startOffset < endOffset) {
        _addSpanModifier(spans, startOffset, endOffset, (span) {
          return span.copyWith(underline: true);
        });
      }

      if (tag == 's' && startOffset < endOffset) {
        _addSpanModifier(spans, startOffset, endOffset, (span) {
          return span.copyWith(strikethrough: true);
        });
      }

      if (tag == 'a' && startOffset < endOffset) {
        final href = node.attributes['href'] ?? '';
        if (href.isNotEmpty) {
          _addSpanModifier(spans, startOffset, endOffset, (span) {
            return span.copyWith(linkUrl: href);
          });
        }
      }

      if ((tag == 'span' || tag == 'strong' || tag == 'em' || tag == 'u' || tag == 's') && startOffset < endOffset) {
        final style = node.attributes['style'] ?? '';
        _applyStyleToSpan(spans, startOffset, endOffset, style);
      }
    } else {
      for (final child in node.nodes) {
        _parseNode(child, text, spans, images, depth + 1);
      }
    }
  }

  static void _applyStyleToSpan(List<SpanData> spans, int start, int end, String style) {
    if (style.isEmpty) return;

    final fontSize = _extractValue(style, 'font-size', r'(\d+(?:\.\d+)?)', 14.0);
    final color = _extractColor(style, 'color');
    final bgColor = _extractColor(style, 'background-color');
    final fontFamily = _extractFontFamily(style);

    _addSpanModifier(spans, start, end, (span) {
      var modified = span;
      if (fontSize != 14.0) modified = modified.copyWith(fontSize: fontSize);
      if (color != 0xFF000000) modified = modified.copyWith(textColor: color);
      if (bgColor != null) modified = modified.copyWith(highlightColor: bgColor);
      if (fontFamily.isNotEmpty) modified = modified.copyWith(fontFamily: fontFamily);
      return modified;
    });
  }

  /// Reads an image dimension ([property] is 'width' or 'height') from the
  /// inline style (`width`/`height` or `max-width`/`max-height`, px values),
  /// falling back to the matching HTML attribute. Returns null if absent.
  static double? _extractImageDimension(html_dom.Element node, String style, String property) {
    for (final prop in [property, 'max-$property']) {
      final regex = RegExp('(?<![\\w-])$prop\\s*:\\s*(\\d+(?:\\.\\d+)?)\\s*px', caseSensitive: false);
      final match = regex.firstMatch(style);
      if (match != null) {
        final value = double.tryParse(match.group(1) ?? '');
        if (value != null) return value;
      }
    }

    final attr = node.attributes[property];
    if (attr != null) {
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(attr);
      if (match != null) return double.tryParse(match.group(1) ?? '');
    }

    return null;
  }

  static double _extractValue(String style, String property, String pattern, double defaultValue) {
    final regex = RegExp('$property\\s*:\\s*$pattern');
    final match = regex.firstMatch(style);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '') ?? defaultValue;
    }
    return defaultValue;
  }

  static int? _extractColor(String style, String property) {
    final regex = RegExp('(?<![\\w-])$property\\s*:\\s*([#\\w()]+)');
    final match = regex.firstMatch(style);
    if (match != null) {
      final colorStr = match.group(1) ?? '';
      return _parseColor(colorStr);
    }
    return null;
  }

  static int? _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      try {
        final hex = colorStr.substring(1);
        if (hex.length == 6) {
          return int.parse('FF$hex', radix: 16);
        } else if (hex.length == 8) {
          return int.parse(hex, radix: 16);
        }
      } catch (e) {
        return null;
      }
    } else if (colorStr.startsWith('rgb')) {
      final matches = RegExp(r'(\d+)').allMatches(colorStr);
      if (matches.length >= 3) {
        final r = int.parse(matches.elementAt(0).group(1)!);
        final g = int.parse(matches.elementAt(1).group(1)!);
        final b = int.parse(matches.elementAt(2).group(1)!);
        final a = matches.length > 3 ? (int.parse(matches.elementAt(3).group(1)!) * 255).toInt() : 255;
        return ((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff);
      }
    }
    return null;
  }

  static String _extractFontFamily(String style) {
    final regex = RegExp(r'font-family:\s*([^;]+)');
    final match = regex.firstMatch(style);
    if (match != null) {
      var family = match.group(1)?.trim() ?? '';
      family = family.replaceAll('"', '').replaceAll("'", '');
      return _normalizeFontFamily(family);
    }
    return 'default';
  }

  static String _normalizeFontFamily(String family) {
    final lower = family.toLowerCase();
    if (lower.contains('sans-serif')) return 'sans-serif';
    if (lower.contains('serif')) return 'serif';
    if (lower.contains('monospace')) return 'monospace';
    if (lower.contains('comic')) return 'comic-sans-ms';
    if (lower.contains('garamond')) return 'garamond';
    if (lower.contains('georgia')) return 'georgia';
    if (lower.contains('tahoma')) return 'tahoma';
    if (lower.contains('trebuchet')) return 'trebuchet-ms';
    if (lower.contains('verdana')) return 'verdana';
    return 'default';
  }

  static void _addSpanModifier(
    List<SpanData> spans,
    int start,
    int end,
    SpanData Function(SpanData) modifier,
  ) {
    if (start >= end) return;

    final baseSpan = SpanData(
      start: start,
      end: end,
      bold: false,
      italic: false,
      underline: false,
      strikethrough: false,
      fontSize: 14.0,
      textColor: 0xFF000000,
      fontFamily: 'default',
    );

    final modifiedSpan = modifier(baseSpan);

    final existingIndex = spans.indexWhere((s) => s.start == start && s.end == end);
    if (existingIndex >= 0) {
      spans[existingIndex] = modifier(spans[existingIndex]);
    } else {
      spans.add(modifiedSpan);
    }
  }

  static void _adjustSpanOffsets(List<SpanData> spans, String finalText) {
    // Cleanup and validate spans
    spans.removeWhere((span) => span.start >= span.end || span.end > finalText.length);
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + (DateTime.now().microsecond % 1000).toString();
  }
}
