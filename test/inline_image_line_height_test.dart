import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard: a tall inline WidgetSpan (how the editor renders images)
/// must grow the line height of the editing field. The default TextField strut
/// clamps the line and breaks this, so the editor disables the strut — see
/// [BlockEditor]'s `_buildBlock`.
class _ProbeController extends TextEditingController {
  _ProbeController() : super(text: '￼');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: const [
        WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: SizedBox(
              width: 120,
              height: 300,
              child: ColoredBox(color: Color(0xFF00FF00))),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('field with disabled strut grows to a tall inline image',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: TextField(
              controller: _ProbeController(),
              maxLines: null,
              // Mirrors the editor's block TextField configuration.
              strutStyle: StrutStyle.disabled,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final height = tester.getSize(find.byType(TextField)).height;
    expect(height, greaterThan(290),
        reason: 'line height must grow to the 300px inline image');
  });
}
