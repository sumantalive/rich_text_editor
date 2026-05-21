import 'package:flutter/material.dart';
import '../models/email_model.dart';

class EmailViewScreen extends StatelessWidget {
  final EmailModel email;

  const EmailViewScreen({
    super.key,
    required this.email,
  });

  Widget _buildFormattedBody() {
    if (email.body.isEmpty) {
      return const SizedBox.shrink();
    }

    final lines = email.body.split('\n');
    final children = <Widget>[];
    var currentPos = 0;

    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      final lineStart = currentPos;
      final lineEnd = currentPos + line.length;

      // Find alignment for this line by checking which span covers the start of the line
      String lineAlignment = 'left';
      for (final span in email.spans) {
        if (span.start <= lineStart && span.end > lineStart) {
          lineAlignment = span.alignment;
          break;
        }
      }

      final lineSpans = <TextSpan>[];
      var lastPos = 0;

      // Get all spans that overlap with this line
      final applicableSpans = email.spans
          .where((s) => s.start < lineEnd && s.end > lineStart)
          .toList();
      applicableSpans.sort((a, b) => a.start.compareTo(b.start));

      for (final span in applicableSpans) {
        final spanStart = (span.start - lineStart).clamp(0, line.length);
        final spanEnd = (span.end - lineStart).clamp(0, line.length);

        if (spanStart > lastPos && lastPos < line.length) {
          lineSpans.add(TextSpan(text: line.substring(lastPos, spanStart)));
        }

        if (spanStart < spanEnd && spanStart < line.length) {
          final actualEnd = spanEnd.clamp(0, line.length);
          if (spanStart < actualEnd) {
            lineSpans.add(TextSpan(
              text: line.substring(spanStart, actualEnd),
              style: TextStyle(
                fontWeight: span.bold ? FontWeight.bold : FontWeight.normal,
                fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
                decoration: TextDecoration.combine([
                  if (span.underline) TextDecoration.underline,
                  if (span.strikethrough) TextDecoration.lineThrough,
                ]),
                color: Color(span.textColor),
                backgroundColor: span.highlightColor != null
                    ? Color(span.highlightColor!)
                    : null,
                fontSize: span.fontSize,
                fontFamily: span.fontFamily == 'default'
                    ? null
                    : span.fontFamily,
              ),
            ));
          }
        }
        lastPos = spanEnd;
      }

      if (lastPos < line.length) {
        lineSpans.add(TextSpan(text: line.substring(lastPos)));
      }

      final text = RichText(
        text: TextSpan(
          children: lineSpans.isEmpty ? [TextSpan(text: line)] : lineSpans,
        ),
        textAlign: _convertStringToTextAlign(lineAlignment),
      );

      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: text,
      ));

      currentPos = lineEnd + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  TextAlign _convertStringToTextAlign(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'To: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(email.to),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Subject: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(email.subject),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Date: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${email.createdAt.day}/${email.createdAt.month}/${email.createdAt.year} '
                          '${email.createdAt.hour}:${email.createdAt.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: const TextStyle(fontSize: 14, height: 1.5),
                child: _buildFormattedBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
