import '../models/span_data_model.dart';
import '../models/image_model.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class HtmlConverter {
  static String toHtml(String text, List<SpanData> spans, List<ImageData> images, String alignment) {
    if (text.isEmpty && images.isEmpty) return '';

    const imagePlaceholder = '￼';
    final buffer = StringBuffer();
    buffer.write('<div style="text-align: $alignment;">');

    if (text.isEmpty) {
      buffer.write('</div>');
      return buffer.toString();
    }

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
          if (imageData.linkUrl != null && imageData.linkUrl!.isNotEmpty) {
            buffer.write('<a href="${_escapeHtml(imageData.linkUrl!)}" target="_blank">');
          }
          buffer.write('<img src="${_escapeHtml(imageData.imageUrl)}" style="max-width: 200px; margin: 8px 0; border: none;" alt="image"/>');
          if (imageData.linkUrl != null && imageData.linkUrl!.isNotEmpty) {
            buffer.write('</a>');
          }
        }
        lastEnd = i + 1;
      }
    }

    if (lastEnd < text.length) {
      _addFormattedTextSegment(buffer, text.substring(lastEnd), lastEnd, sortedSpans);
    }

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

  static HtmlImportData parseHtmlFull(String htmlContent) {
    final doc = html_parser.parse(htmlContent);
    final text = StringBuffer();
    final spans = <SpanData>[];
    final images = <ImageData>[];
    var alignment = 'left';

    if (doc.body == null) {
      return HtmlImportData(text: '', spans: [], images: [], alignment: 'left');
    }

    final divElements = doc.body!.querySelectorAll('div');
    if (divElements.isNotEmpty) {
      final firstDiv = divElements.first;
      final style = firstDiv.attributes['style'] ?? '';
      if (style.contains('text-align:')) {
        final alignMatch = RegExp(r'text-align:\s*(\w+)').firstMatch(style);
        if (alignMatch != null) {
          alignment = alignMatch.group(1) ?? 'left';
        }
      }
    }

    _parseNode(doc.body!, text, spans, images, 0);

    final finalText = text.toString().trim();
    _adjustSpanOffsets(spans, finalText);

    return HtmlImportData(
      text: finalText,
      spans: spans,
      images: images,
      alignment: alignment,
    );
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
          images.add(ImageData(
            id: _generateId(),
            imageUrl: src,
            position: text.length - 1,
            linkUrl: linkUrl.isNotEmpty ? linkUrl : null,
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

class HtmlImportData {
  final String text;
  final List<SpanData> spans;
  final List<ImageData> images;
  final String alignment;

  HtmlImportData({
    required this.text,
    required this.spans,
    required this.images,
    required this.alignment,
  });
}
