import 'dart:math';
import 'package:flutter/material.dart';
import '../models/span_data_model.dart';
import '../models/image_model.dart';

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
    return TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        if (underline) TextDecoration.underline,
        if (strikethrough) TextDecoration.lineThrough,
      ]),
      color: Color(textColor),
      backgroundColor: highlightColor != null ? Color(highlightColor!) : null,
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

  TextEditingValue _lastValue = TextEditingValue.empty;

  @override
  set value(TextEditingValue newValue) {
    final oldText = _lastValue.text;
    final newText = newValue.text;

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

  void addImage(String imageUrl) {
    final imageData = ImageData(imageUrl: imageUrl);
    images.add(imageData);
    notifyListeners();
  }

  void removeImage(String imageId) {
    images.removeWhere((img) => img.id == imageId);
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
      images[index] = images[index].copyWith(linkUrl: linkUrl);
      notifyListeners();
    }
  }

  void clearFormatting() {
    spans.clear();
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (spans.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final children = <TextSpan>[];
    var lastEnd = 0;

    final sortedSpans = [...spans]..sort((a, b) => a.start.compareTo(b.start));

    for (final span in sortedSpans) {
      if (span.start > lastEnd) {
        children.add(TextSpan(
          text: text.substring(lastEnd, span.start),
          style: style,
        ));
      }

      final spanEnd = span.end.clamp(span.start, text.length);
      children.add(TextSpan(
        text: text.substring(span.start, spanEnd),
        style: (style ?? const TextStyle()).merge(span.toTextStyle()),
      ));

      lastEnd = span.end;
    }

    if (lastEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return TextSpan(children: children, style: style);
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
    return TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine([
        if (underline || linkUrl != null) TextDecoration.underline,
        if (strikethrough) TextDecoration.lineThrough,
      ]),
      color: linkUrl != null ? Colors.blue : Color(textColor),
      backgroundColor: highlightColor != null ? Color(highlightColor!) : null,
      fontSize: fontSize,
      fontFamily: _getFontFamily(),
      letterSpacing: _getLetterSpacing(),
    );
  }
}
