import 'dart:math';
import 'package:flutter/material.dart';
import '../models/span_data_model.dart';
import '../models/image_model.dart';
import '../widgets/inline_image_widget.dart';

class TextFormatting {
  bool bold;
  bool italic;
  bool underline;
  bool strikethrough;
  int textColor;
  int? highlightColor;
  double fontSize;
  String fontFamily;
  String alignment; // 'left', 'center', 'right', 'justify'
  String? linkUrl;

  TextFormatting({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.textColor = 0xFF000000,
    this.highlightColor,
    this.fontSize = 14.0,
    this.fontFamily = 'default',
    this.alignment = 'left',
    this.linkUrl,
  });

  TextFormatting copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    int? textColor,
    int? highlightColor,
    double? fontSize,
    String? fontFamily,
    String? alignment,
    String? linkUrl,
  }) {
    return TextFormatting(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      textColor: textColor ?? this.textColor,
      highlightColor: highlightColor ?? this.highlightColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      alignment: alignment ?? this.alignment,
      linkUrl: linkUrl ?? this.linkUrl,
    );
  }

  String? _getFontFamily() {
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

  double _getLetterSpacing() {
    switch (fontFamily) {
      case 'wide':
        return 1.5;
      case 'narrow':
        return -0.5;
      default:
        return 0.0;
    }
  }

  TextStyle toTextStyle() {
    final textColorValue = Color(textColor);
    Color? bgColor;
    if (highlightColor != null) {
      final color = Color(highlightColor!);
      bgColor = color.withValues(alpha: 0.4);
    }
    return TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        if (underline) TextDecoration.underline,
        if (strikethrough) TextDecoration.lineThrough,
      ]),
      decorationColor: textColorValue,
      color: textColorValue,
      backgroundColor: bgColor,
      fontSize: fontSize,
      fontFamily: _getFontFamily(),
      letterSpacing: _getLetterSpacing(),
    );
  }

  bool get hasAnyFormatting =>
      bold || italic || underline || strikethrough ||
      textColor != 0xFF000000 || highlightColor != null ||
      fontSize != 14.0 || fontFamily != 'default' ||
      alignment != 'left';
}

class RichTextController extends TextEditingController {
  List<SpanData> spans = [];
  List<ImageData> images = [];
  TextFormatting _activeFormatting = TextFormatting();
  String? selectedImageId;

  /// Maximum width an inline image may occupy, in logical pixels. Set by the
  /// editor field from its measured content width so images never overflow it
  /// horizontally. Defaults to unbounded until the field reports its size.
  double maxImageWidth = double.infinity;

  /// Paragraph alignment for the line this controller represents in the
  /// block editor ('left' | 'center' | 'right' | 'justify'). Used both for
  /// rendering the field and for emitting one aligned <div> per block.
  String blockAlignment = 'left';

  TextEditingValue _lastValue = TextEditingValue.empty;

  /// When true, [value] assignment skips the incremental span/image offset
  /// math. Used by [setContent] when programmatically replacing the whole
  /// content (e.g. splitting/merging blocks), where spans/images are supplied
  /// directly and must not be diffed against the previous text.
  bool _suppressDiff = false;

  /// Replaces the entire content of this block at once — text, spans, images
  /// and (optionally) selection — without running the incremental diff that
  /// normal typing relies on. The caller is responsible for passing spans and
  /// image positions that already match [text].
  void setContent({
    required String text,
    List<SpanData>? spans,
    List<ImageData>? images,
    TextSelection? selection,
  }) {
    this.spans = spans ?? <SpanData>[];
    this.images = images ?? <ImageData>[];
    _suppressDiff = true;
    value = TextEditingValue(
      text: text,
      selection: selection ?? TextSelection.collapsed(offset: text.length),
    );
    _suppressDiff = false;
  }

  @override
  set value(TextEditingValue newValue) {
    if (_suppressDiff) {
      _lastValue = newValue;
      super.value = newValue;
      return;
    }

    final oldText = _lastValue.text;
    final newText = newValue.text;
    const imagePlaceholder = '￼';

    if (newText.length > oldText.length) {
      final addedCount = newText.length - oldText.length;
      final insertPos = _findInsertionPoint(oldText, newText);

      for (var span in spans) {
        if (span.start >= insertPos) {
          spans[spans.indexOf(span)] = span.copyWith(
            start: span.start + addedCount,
            end: span.end + addedCount,
          );
        } else if (span.end > insertPos) {
          spans[spans.indexOf(span)] = span.copyWith(
            end: span.end + addedCount,
          );
        }
      }

      for (int i = 0; i < images.length; i++) {
        if (images[i].position >= insertPos) {
          images[i] = images[i].copyWith(position: images[i].position + addedCount);
        }
      }

      if (_activeFormatting.hasAnyFormatting) {
        final newSpan = SpanData(
          start: insertPos,
          end: insertPos + addedCount,
          bold: _activeFormatting.bold,
          italic: _activeFormatting.italic,
          underline: _activeFormatting.underline,
          strikethrough: _activeFormatting.strikethrough,
          textColor: _activeFormatting.textColor,
          highlightColor: _activeFormatting.highlightColor,
          fontSize: _activeFormatting.fontSize,
          fontFamily: _activeFormatting.fontFamily,
          alignment: _activeFormatting.alignment,
          linkUrl: _activeFormatting.linkUrl,
        );
        _addSpan(newSpan);
      }
    } else if (newText.length < oldText.length) {
      final deletedCount = oldText.length - newText.length;
      final deletePos = _findDeletionPoint(oldText, newText);

      final deletedText = oldText.substring(deletePos, deletePos + deletedCount);
      if (deletedText.contains(imagePlaceholder)) {
        for (int i = 0; i < deletedText.length; i++) {
          if (deletedText[i] == imagePlaceholder) {
            final placeholderPos = deletePos + i;
            images.removeWhere((img) => img.position == placeholderPos);
          }
        }
      }

      // Remove spans that are completely within the deleted range
      spans.removeWhere((span) => span.start >= deletePos && span.end <= deletePos + deletedCount);

      // Adjust remaining spans
      final newSpans = <SpanData>[];
      for (var span in spans) {
        if (span.end <= deletePos) {
          // Span is completely before deletion - keep as is
          newSpans.add(span);
        } else if (span.start >= deletePos + deletedCount) {
          // Span is completely after deletion - shift back
          newSpans.add(span.copyWith(
            start: span.start - deletedCount,
            end: span.end - deletedCount,
          ));
        } else {
          // Span overlaps with deletion - adjust boundaries
          final newStart = span.start < deletePos ? span.start : deletePos;
          final newEnd = max(newStart, (span.end - deletedCount).clamp(0, newText.length));
          if (newEnd > newStart) {
            newSpans.add(span.copyWith(
              start: newStart,
              end: newEnd,
            ));
          }
        }
      }
      spans = newSpans;

      for (int i = 0; i < images.length; i++) {
        if (images[i].position > deletePos) {
          images[i] = images[i].copyWith(position: images[i].position - deletedCount);
        }
      }
    }

    _lastValue = newValue;
    super.value = newValue;
  }

  int _findInsertionPoint(String oldText, String newText) {
    for (int i = 0; i < oldText.length; i++) {
      if (i >= newText.length || oldText[i] != newText[i]) {
        return i;
      }
    }
    return oldText.length;
  }

  int _findDeletionPoint(String oldText, String newText) {
    for (int i = 0; i < newText.length; i++) {
      if (oldText[i] != newText[i]) {
        return i;
      }
    }
    return newText.length;
  }

  void _addSpan(SpanData span) {
    spans.add(span);
    spans.sort((a, b) => a.start.compareTo(b.start));
  }

  void applyToSelection(TextFormatting formatting, {TextSelection? explicitSelection}) {
    final selection = explicitSelection ?? this.selection;
    if (selection.start >= selection.end) return;

    final selStart = selection.start;
    final selEnd = selection.end;
    final textContent = text;

    // Handle alignment - expand to line boundaries
    int applyStart = selStart;
    int applyEnd = selEnd;

    if (formatting.alignment != 'left') {
      while (applyStart > 0 && textContent[applyStart - 1] != '\n') {
        applyStart--;
      }
      while (applyEnd < textContent.length && textContent[applyEnd] != '\n') {
        applyEnd++;
      }
    }

    final newSpans = <SpanData>[];
    bool selectionWasCovered = false;

    // Process existing spans
    for (final span in spans) {
      // No overlap
      if (span.end <= applyStart || span.start >= applyEnd) {
        newSpans.add(span);
        continue;
      }

      // Complete overlap - replace entire span
      if (span.start >= applyStart && span.end <= applyEnd) {
        newSpans.add(_mergeFormatting(span, formatting));
        selectionWasCovered = true;
        continue;
      }

      // Partial overlap - split span
      if (span.start < applyStart) {
        newSpans.add(span.copyWith(end: applyStart));
      }

      final overlapStart = max(span.start, applyStart);
      final overlapEnd = min(span.end, applyEnd);
      final mergedSpan = SpanData(
        start: overlapStart,
        end: overlapEnd,
        bold: formatting.bold || span.bold,
        italic: formatting.italic || span.italic,
        underline: formatting.underline || span.underline,
        strikethrough: formatting.strikethrough || span.strikethrough,
        textColor: formatting.textColor == 0xFF000000 ? span.textColor : formatting.textColor,
        highlightColor: formatting.highlightColor ?? span.highlightColor,
        fontSize: formatting.fontSize == 14.0 ? span.fontSize : formatting.fontSize,
        fontFamily: formatting.fontFamily == 'default' ? span.fontFamily : formatting.fontFamily,
        alignment: formatting.alignment == 'left' ? span.alignment : formatting.alignment,
        linkUrl: formatting.linkUrl ?? span.linkUrl,
      );
      newSpans.add(mergedSpan);
      selectionWasCovered = true;

      if (span.end > applyEnd) {
        newSpans.add(span.copyWith(start: applyEnd));
      }
    }

    // Create span if selection wasn't covered by any existing span
    // For uncovered areas, only apply non-default properties
    if (!selectionWasCovered && formatting.hasAnyFormatting) {
      newSpans.add(SpanData(
        start: applyStart,
        end: applyEnd,
        bold: formatting.bold,
        italic: formatting.italic,
        underline: formatting.underline,
        strikethrough: formatting.strikethrough,
        textColor: formatting.textColor,
        highlightColor: formatting.highlightColor,
        fontSize: formatting.fontSize,
        fontFamily: formatting.fontFamily,
        alignment: formatting.alignment,
        linkUrl: formatting.linkUrl,
      ));
    }

    spans = newSpans;
    spans.sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  SpanData _mergeFormatting(SpanData span, TextFormatting formatting) {
    return SpanData(
      start: span.start,
      end: span.end,
      bold: formatting.bold || span.bold,
      italic: formatting.italic || span.italic,
      underline: formatting.underline || span.underline,
      strikethrough: formatting.strikethrough || span.strikethrough,
      textColor: formatting.textColor == 0xFF000000 ? span.textColor : formatting.textColor,
      highlightColor: formatting.highlightColor ?? span.highlightColor,
      fontSize: formatting.fontSize == 14.0 ? span.fontSize : formatting.fontSize,
      fontFamily: formatting.fontFamily == 'default' ? span.fontFamily : formatting.fontFamily,
      alignment: formatting.alignment == 'left' ? span.alignment : formatting.alignment,
      linkUrl: formatting.linkUrl ?? span.linkUrl,
    );
  }

  void applyPropertyToSelection(TextFormatting formatting, {TextSelection? explicitSelection}) {
    final selection = explicitSelection ?? this.selection;
    if (selection.start >= selection.end) return;

    final selStart = selection.start;
    final selEnd = selection.end;
    final newSpans = <SpanData>[];

    for (final span in spans) {
      // No overlap
      if (span.end <= selStart || span.start >= selEnd) {
        newSpans.add(span);
        continue;
      }

      // Overlap - merge formatting properties intelligently
      if (span.start < selStart && span.end > selEnd) {
        // Span completely contains selection - split it
        newSpans.add(span.copyWith(end: selStart));
        final middle = _mergeSpanWithFormatting(span.copyWith(start: selStart, end: selEnd), formatting);
        newSpans.add(middle);
        newSpans.add(span.copyWith(start: selEnd));
      } else if (span.start < selStart) {
        // Partial overlap on left
        newSpans.add(span.copyWith(end: selStart));
        final overlapped = span.copyWith(start: selStart);
        newSpans.add(_mergeSpanWithFormatting(overlapped, formatting));
      } else if (span.end > selEnd) {
        // Partial overlap on right
        final overlapped = span.copyWith(end: selEnd);
        newSpans.add(_mergeSpanWithFormatting(overlapped, formatting));
        newSpans.add(span.copyWith(start: selEnd));
      } else {
        // Complete overlap
        newSpans.add(_mergeSpanWithFormatting(span, formatting));
      }
    }

    // Handle unformatted areas
    _fillUnformattedAreasForProperty(newSpans, selStart, selEnd, formatting);

    spans = newSpans;
    spans.sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  SpanData _mergeSpanWithFormatting(SpanData span, TextFormatting formatting) {
    return SpanData(
      start: span.start,
      end: span.end,
      bold: formatting.bold || span.bold,
      italic: formatting.italic || span.italic,
      underline: formatting.underline || span.underline,
      strikethrough: formatting.strikethrough || span.strikethrough,
      textColor: formatting.textColor == 0xFF000000 ? span.textColor : formatting.textColor,
      highlightColor: formatting.highlightColor ?? span.highlightColor,
      fontSize: formatting.fontSize == 14.0 ? span.fontSize : formatting.fontSize,
      fontFamily: formatting.fontFamily == 'default' ? span.fontFamily : formatting.fontFamily,
      alignment: formatting.alignment == 'left' ? span.alignment : formatting.alignment,
      linkUrl: formatting.linkUrl ?? span.linkUrl,
    );
  }

  void _fillUnformattedAreasForProperty(List<SpanData> spans, int selStart, int selEnd, TextFormatting formatting) {
    final sorted = spans.where((s) => s.start < selEnd && s.end > selStart).toList();
    sorted.sort((a, b) => a.start.compareTo(b.start));

    int currentPos = selStart;
    for (final span in sorted) {
      if (span.start > currentPos) {
        spans.add(SpanData(
          start: currentPos,
          end: span.start,
          bold: formatting.bold,
          italic: formatting.italic,
          underline: formatting.underline,
          strikethrough: formatting.strikethrough,
          textColor: formatting.textColor,
          highlightColor: formatting.highlightColor,
          fontSize: formatting.fontSize,
          fontFamily: formatting.fontFamily,
          alignment: formatting.alignment,
        ));
      }
      currentPos = span.end;
    }

    if (currentPos < selEnd) {
      spans.add(SpanData(
        start: currentPos,
        end: selEnd,
        bold: formatting.bold,
        italic: formatting.italic,
        underline: formatting.underline,
        strikethrough: formatting.strikethrough,
        textColor: formatting.textColor,
        highlightColor: formatting.highlightColor,
        fontSize: formatting.fontSize,
        fontFamily: formatting.fontFamily,
        alignment: formatting.alignment,
      ));
    }
  }

  /// Sets the hyperlink on the current selection, or clears it when [url] is
  /// null/empty. Spans are split at the selection boundaries so only the
  /// selected text is affected. Unlike [applyPropertyToSelection], this can
  /// also remove a link (the `??` merge there can never clear a value).
  void setSelectionLink(String? url, {TextSelection? explicitSelection}) {
    final selection = explicitSelection ?? this.selection;
    if (selection.start >= selection.end) return;
    final link = (url == null || url.isEmpty) ? null : url;

    final selStart = selection.start;
    final selEnd = selection.end;
    final newSpans = <SpanData>[];

    for (final span in spans) {
      if (span.end <= selStart || span.start >= selEnd) {
        newSpans.add(span); // no overlap
        continue;
      }
      if (span.start < selStart && span.end > selEnd) {
        newSpans.add(span.copyWith(end: selStart));
        newSpans.add(_withLink(span.copyWith(start: selStart, end: selEnd), link));
        newSpans.add(span.copyWith(start: selEnd));
      } else if (span.start < selStart) {
        newSpans.add(span.copyWith(end: selStart));
        newSpans.add(_withLink(span.copyWith(start: selStart), link));
      } else if (span.end > selEnd) {
        newSpans.add(_withLink(span.copyWith(end: selEnd), link));
        newSpans.add(span.copyWith(start: selEnd));
      } else {
        newSpans.add(_withLink(span, link));
      }
    }

    // Fill selected gaps that had no span (only needed when setting a link).
    if (link != null) {
      final covering = newSpans
          .where((s) => s.start < selEnd && s.end > selStart)
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      var pos = selStart;
      for (final s in covering) {
        if (s.start > pos) {
          newSpans.add(SpanData(start: pos, end: s.start, linkUrl: link));
        }
        if (s.end > pos) pos = s.end;
      }
      if (pos < selEnd) {
        newSpans.add(SpanData(start: pos, end: selEnd, linkUrl: link));
      }
    }

    spans = newSpans;
    spans.sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  /// Returns a copy of [span] with its [SpanData.linkUrl] set to [url],
  /// including clearing it to null (which `copyWith` cannot do).
  SpanData _withLink(SpanData span, String? url) => SpanData(
        start: span.start,
        end: span.end,
        bold: span.bold,
        italic: span.italic,
        underline: span.underline,
        strikethrough: span.strikethrough,
        textColor: span.textColor,
        highlightColor: span.highlightColor,
        fontSize: span.fontSize,
        fontFamily: span.fontFamily,
        alignment: span.alignment,
        linkUrl: url,
      );

  void togglePropertyInSelection(String property, {TextSelection? explicitSelection}) {
    final selection = explicitSelection ?? this.selection;
    if (selection.start >= selection.end) return;

    final selStart = selection.start;
    final selEnd = selection.end;
    final newSpans = <SpanData>[];

    for (final span in spans) {
      // No overlap
      if (span.end <= selStart || span.start >= selEnd) {
        newSpans.add(span);
        continue;
      }

      // Overlap - toggle the property for this span
      if (span.start < selStart && span.end > selEnd) {
        // Span completely contains selection - split it
        newSpans.add(span.copyWith(end: selStart));
        final middle = _toggleSpanProperty(span.copyWith(start: selStart, end: selEnd), property);
        newSpans.add(middle);
        newSpans.add(span.copyWith(start: selEnd));
      } else if (span.start < selStart) {
        // Partial overlap on left
        newSpans.add(span.copyWith(end: selStart));
        final overlapped = span.copyWith(start: selStart);
        newSpans.add(_toggleSpanProperty(overlapped, property));
      } else if (span.end > selEnd) {
        // Partial overlap on right
        final overlapped = span.copyWith(end: selEnd);
        newSpans.add(_toggleSpanProperty(overlapped, property));
        newSpans.add(span.copyWith(start: selEnd));
      } else {
        // Complete overlap
        newSpans.add(_toggleSpanProperty(span, property));
      }
    }

    // Handle unformatted areas in selection
    _fillUnformattedAreas(newSpans, selStart, selEnd, property);

    spans = newSpans;
    spans.sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  SpanData _toggleSpanProperty(SpanData span, String property) {
    switch (property) {
      case 'bold':
        return span.copyWith(bold: !span.bold);
      case 'italic':
        return span.copyWith(italic: !span.italic);
      case 'underline':
        return span.copyWith(underline: !span.underline);
      case 'strikethrough':
        return span.copyWith(strikethrough: !span.strikethrough);
      default:
        return span;
    }
  }

  void _fillUnformattedAreas(List<SpanData> spans, int selStart, int selEnd, String property) {
    // Check for gaps and add default formatting toggle
    final sorted = spans.where((s) => s.start < selEnd && s.end > selStart).toList();
    sorted.sort((a, b) => a.start.compareTo(b.start));

    int currentPos = selStart;
    for (final span in sorted) {
      if (span.start > currentPos) {
        // Gap found - add default formatting with property toggled
        bool value = false;
        if (property == 'bold') value = true;
        if (property == 'italic') value = true;
        if (property == 'underline') value = true;
        if (property == 'strikethrough') value = true;

        spans.add(SpanData(
          start: currentPos,
          end: span.start,
          bold: property == 'bold' ? value : false,
          italic: property == 'italic' ? value : false,
          underline: property == 'underline' ? value : false,
          strikethrough: property == 'strikethrough' ? value : false,
        ));
      }
      currentPos = span.end;
    }

    if (currentPos < selEnd) {
      bool value = false;
      if (property == 'bold') value = true;
      if (property == 'italic') value = true;
      if (property == 'underline') value = true;
      if (property == 'strikethrough') value = true;

      spans.add(SpanData(
        start: currentPos,
        end: selEnd,
        bold: property == 'bold' ? value : false,
        italic: property == 'italic' ? value : false,
        underline: property == 'underline' ? value : false,
        strikethrough: property == 'strikethrough' ? value : false,
      ));
    }
  }

  TextFormatting get activeFormatting => _activeFormatting;

  void setActiveFormatting(TextFormatting formatting) {
    _activeFormatting = formatting;
  }

  void toggleActiveFormatting(String property) {
    switch (property) {
      case 'bold':
        _activeFormatting = _activeFormatting.copyWith(bold: !_activeFormatting.bold);
        break;
      case 'italic':
        _activeFormatting = _activeFormatting.copyWith(italic: !_activeFormatting.italic);
        break;
      case 'underline':
        _activeFormatting = _activeFormatting.copyWith(underline: !_activeFormatting.underline);
        break;
      case 'strikethrough':
        _activeFormatting = _activeFormatting.copyWith(strikethrough: !_activeFormatting.strikethrough);
        break;
    }
  }

  TextFormatting getFormattingAt(int offset) {
    if (offset < 0 || offset > text.length) return TextFormatting();

    // Find span at exact position
    for (final span in spans) {
      if (offset >= span.start && offset < span.end) {
        return TextFormatting(
          bold: span.bold,
          italic: span.italic,
          underline: span.underline,
          strikethrough: span.strikethrough,
          textColor: span.textColor,
          highlightColor: span.highlightColor,
          fontSize: span.fontSize,
          fontFamily: span.fontFamily,
          alignment: span.alignment,
          linkUrl: span.linkUrl,
        );
      }
    }

    // If at end of text, use last span's formatting
    if (offset == text.length && spans.isNotEmpty) {
      final lastSpan = spans.last;
      return TextFormatting(
        bold: lastSpan.bold,
        italic: lastSpan.italic,
        underline: lastSpan.underline,
        strikethrough: lastSpan.strikethrough,
        textColor: lastSpan.textColor,
        highlightColor: lastSpan.highlightColor,
        fontSize: lastSpan.fontSize,
        fontFamily: lastSpan.fontFamily,
        alignment: lastSpan.alignment,
        linkUrl: lastSpan.linkUrl,
      );
    }

    // Find previous span for alignment continuity
    SpanData? previousSpan;
    for (final span in spans) {
      if (span.end <= offset) {
        previousSpan = span;
      } else {
        break;
      }
    }

    if (previousSpan != null) {
      return TextFormatting(alignment: previousSpan.alignment);
    }

    return TextFormatting();
  }


  List<SpanData> extractSpanData() => spans;

  List<ImageData> extractImageData() => images;

  void addImage(String imageUrl, int cursorPosition) {
    const imagePlaceholder = '￼';
    final newText = text.substring(0, cursorPosition) + imagePlaceholder + text.substring(cursorPosition);

    value = value.copyWith(text: newText);

    final imageData = ImageData(
      imageUrl: imageUrl,
      position: cursorPosition,
    );
    images.add(imageData);
    notifyListeners();
  }

  void removeImage(String imageId) {
    final imageIndex = images.indexWhere((img) => img.id == imageId);
    if (imageIndex != -1) {
      final imageData = images[imageIndex];
      const imagePlaceholder = '￼';

      if (imageData.position < text.length && text[imageData.position] == imagePlaceholder) {
        final newText = text.substring(0, imageData.position) + text.substring(imageData.position + 1);

        images.removeAt(imageIndex);

        for (var i = imageIndex; i < images.length; i++) {
          if (images[i].position > imageData.position) {
            images[i] = images[i].copyWith(position: images[i].position - 1);
          }
        }

        value = value.copyWith(text: newText);
      } else {
        images.removeAt(imageIndex);
      }
    }
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final image = images.removeAt(oldIndex);
    images.insert(newIndex, image);
    notifyListeners();
  }

  void updateImageLink(String imageId, String? linkUrl) {
    final index = images.indexWhere((img) => img.id == imageId);
    if (index != -1) {
      final img = images[index];
      final link = (linkUrl == null || linkUrl.isEmpty) ? null : linkUrl;
      // Rebuild directly (not copyWith) so a null link actually clears it.
      images[index] = ImageData(
        id: img.id,
        imageUrl: img.imageUrl,
        position: img.position,
        linkUrl: link,
        width: img.width,
        height: img.height,
      );
      notifyListeners();
    }
  }

  /// The link currently set on the selected image, or null if none/unselected.
  String? get selectedImageLink {
    if (selectedImageId == null) return null;
    for (final img in images) {
      if (img.id == selectedImageId) return img.linkUrl;
    }
    return null;
  }

  void clearFormatting() {
    spans.clear();
    notifyListeners();
  }

  void selectImage(String imageId) {
    selectedImageId = imageId;
    notifyListeners();
  }

  void deselectImage() {
    selectedImageId = null;
    notifyListeners();
  }

  void resizeImage(String imageId, double width, double height) {
    // Only enforce a minimum so the resize handle stays grabbable; no max
    // limit — images use their natural/user-chosen dimensions.
    const minSize = 28.0;

    final clampedWidth = width < minSize ? minSize : width;
    final clampedHeight = height < minSize ? minSize : height;

    final index = images.indexWhere((img) => img.id == imageId);
    if (index != -1) {
      images[index] = images[index].copyWith(
        width: clampedWidth,
        height: clampedHeight,
      );
      notifyListeners();
    }
  }

  double getMaxImageHeight() {
    if (images.isEmpty) return 0;
    return images.map((img) => img.height).reduce((a, b) => a > b ? a : b);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    const imagePlaceholder = '￼';
    final children = <InlineSpan>[];
    var lastEnd = 0;

    final sortedSpans = [...spans]..sort((a, b) => a.start.compareTo(b.start));

    for (int i = 0; i < text.length; i++) {
      if (text[i] == imagePlaceholder) {
        if (i > lastEnd) {
          _addTextSpans(text.substring(lastEnd, i), lastEnd, style, sortedSpans, children);
        }

        final image = images.firstWhere(
          (img) => img.position == i,
          orElse: () => ImageData(imageUrl: ''),
        );

        if (image.imageUrl.isNotEmpty) {
          final isSelected = selectedImageId == image.id;
          children.add(
            WidgetSpan(
              // Align the image's top with the line top so the line height
              // grows to the image's natural height (text flows below the
              // image rather than overlapping it).
              alignment: PlaceholderAlignment.top,
              child: InlineImageWidget(
                image: image,
                isSelected: isSelected,
                maxWidth: maxImageWidth,
                onSelect: () => selectImage(image.id),
                onDeselect: () => deselectImage(),
                onResize: (width, height) => resizeImage(image.id, width, height),
              ),
            ),
          );
        }
        lastEnd = i + 1;
      }
    }

    if (lastEnd < text.length) {
      _addTextSpans(text.substring(lastEnd), lastEnd, style, sortedSpans, children);
    }

    if (children.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    return TextSpan(children: children, style: style);
  }

  void _addTextSpans(
    String textSegment,
    int segmentStart,
    TextStyle? style,
    List<SpanData> sortedSpans,
    List<InlineSpan> children,
  ) {
    final segmentEnd = segmentStart + textSegment.length;
    var segmentLastEnd = 0;

    for (final span in sortedSpans) {
      if (span.end <= segmentStart || span.start >= segmentEnd) continue;

      final spanStartInSegment = max(0, span.start - segmentStart);
      final spanEndInSegment = min(segmentEnd - segmentStart, span.end - segmentStart);

      if (spanStartInSegment > segmentLastEnd) {
        children.add(TextSpan(
          text: textSegment.substring(segmentLastEnd, spanStartInSegment),
          style: style,
        ));
      }

      children.add(TextSpan(
        text: textSegment.substring(spanStartInSegment, spanEndInSegment),
        style: (style ?? const TextStyle()).merge(span.toTextStyle()),
      ));

      segmentLastEnd = spanEndInSegment;
    }

    if (segmentLastEnd < segmentEnd - segmentStart) {
      children.add(TextSpan(
        text: textSegment.substring(segmentLastEnd),
        style: style,
      ));
    }
  }
}

extension on SpanData {
  String? _getFontFamily() {
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

  double _getLetterSpacing() {
    switch (fontFamily) {
      case 'wide':
        return 1.5;
      case 'narrow':
        return -0.5;
      default:
        return 0.0;
    }
  }

  TextStyle toTextStyle() {
    final textColorValue = linkUrl != null ? Colors.blue : Color(textColor);
    Color? bgColor;
    if (highlightColor != null) {
      final color = Color(highlightColor!);
      bgColor = color;
    }
    return TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        if (underline || linkUrl != null) TextDecoration.underline,
        if (strikethrough) TextDecoration.lineThrough,
      ]),
      decorationColor: textColorValue,
      color: textColorValue,
      backgroundColor: bgColor,
      fontSize: fontSize,
      fontFamily: _getFontFamily(),
      letterSpacing: _getLetterSpacing(),
    );
  }
}
