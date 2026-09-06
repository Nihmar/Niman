import 'package:copist/src/editor/selection_handle_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('handle anchors hang the ball below the endpoint', () {
    final controls = CopistSelectionControls();
    // Tips exactly on the endpoint, balls below: left tip top-right,
    // right tip top-left (the stock overlay convention).
    expect(
      controls.getHandleAnchor(TextSelectionHandleType.left, 21),
      const Offset(CopistSelectionControls.handleSize, 0),
    );
    expect(
      controls.getHandleAnchor(TextSelectionHandleType.right, 21),
      Offset.zero,
    );
  });

  testWidgets('handles render smaller than stock (16 px)', (tester) async {
    final controls = CopistSelectionControls();
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            controls.buildHandle(
              context,
              TextSelectionHandleType.left,
              21,
            ),
            controls.buildHandle(
              context,
              TextSelectionHandleType.right,
              21,
            ),
          ],
        ),
      ),
    );
    final boxes = find.byWidgetPredicate(
      (w) =>
          w is SizedBox &&
          w.width == CopistSelectionControls.handleSize &&
          w.height == CopistSelectionControls.handleSize,
    );
    expect(boxes, findsNWidgets(2));
    final paints = find.descendant(
      of: find.byType(Row),
      matching: find.byType(CustomPaint),
    );
    expect(paints, findsNWidgets(2));
  });
}
