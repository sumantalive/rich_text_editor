import '../models/span_data_model.dart';
import '../models/image_model.dart';

class HtmlConverter {
  static String toHtml(String text, List<SpanData> spans, List<ImageData> images, String alignment) {
    if (text.isEmpty && images.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('<div style="text-align: $alignment;">');

    // Add text with formatting
    if (text.isNotEmpty) {
      buffer.write(_textToHtml(text, spans));
    }

    // Add images
    for (final image in images) {
      buffer.write('<br/>');
      buffer.write('<img src="${_escapeHtml(image.imageUrl)}" style="max-width: 200px; margin: 8px 0;');
      if (image.linkUrl != null && image.linkUrl!.isNotEmpty) {
        buffer.write('" data-link="${_escapeHtml(image.linkUrl!)}" />');
      } else {
        buffer.write('" />');
      }
    }

    buffer.write('</div>');
    return buffer.toString();
  }

  static String _textToHtml(String text, List<SpanData> spans) {
    if (spans.isEmpty) {
      return '<p>${_escapeHtml(text)}</p>';
    }

    final buffer = StringBuffer();
    var lastEnd = 0;
    final sortedSpans = [...spans]..sort((a, b) => a.start.compareTo(b.start));

    for (final span in sortedSpans) {
      // Add text before span
      if (span.start > lastEnd) {
        buffer.write(_escapeHtml(text.substring(lastEnd, span.start)));
      }

      // Add formatted text
      final spanEnd = span.end.clamp(span.start, text.length);
      final spanText = text.substring(span.start, spanEnd);
      buffer.write(_formatSpan(spanText, span));

      lastEnd = spanEnd;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      buffer.write(_escapeHtml(text.substring(lastEnd)));
    }

    return buffer.toString();
  }

  static String _formatSpan(String text, SpanData span) {
    var html = _escapeHtml(text);

    if (span.linkUrl != null && span.linkUrl!.isNotEmpty) {
      html = '<a href="${_escapeHtml(span.linkUrl!)}" style="color: #0A7EFF; text-decoration: underline;">$html</a>';
    }

    if (span.bold) html = '<strong>$html</strong>';
    if (span.italic) html = '<em>$html</em>';
    if (span.underline) html = '<u>$html</u>';
    if (span.strikethrough) html = '<s>$html</s>';

    final fontSize = span.fontSize != 14.0 ? 'font-size: ${span.fontSize}px;' : '';
    final textColor = span.textColor != 0xFF000000 ? 'color: ${_colorToHex(span.textColor)};' : '';
    final bgColor = span.highlightColor != null ? 'background-color: ${_colorToHex(span.highlightColor!)};' : '';

    final fontFamily = _getFontFamilyName(span.fontFamily);
    final fontFamilyStyle = fontFamily != null ? 'font-family: $fontFamily;' : '';

    final styles = [fontSize, textColor, bgColor, fontFamilyStyle].where((s) => s.isNotEmpty).join(' ');

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
}
