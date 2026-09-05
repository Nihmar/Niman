import 'package:copist/src/editor/caret_geometry.dart';
import 'package:copist/src/editor/caret_painter.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RowModel model;
  late CaretGeometry geo;

  CaretPainter painter({
    int caretOffset = 0,
    TextRange composing = const TextRange(start: 0, end: 0),
    bool caretVisible = true,
  }) {
    return CaretPainter(
      geometry: geo,
      caretOffset: caretOffset,
      composing: composing,
      caretVisible: caretVisible,
    );
  }

  setUp(() {
    final buffer = LineBuffer.fromText('ab\nabcdef');
    model = RowModel(buffer, columns: 4);
    geo = CaretGeometry(
      rowModel: model,
      charWidth: 10,
      rowHeight: 20,
      leftPadding: 5,
    );
  });

  test('shouldRepaint tracks the inputs', () {
    final p = painter();
    expect(p.shouldRepaint(painter()), isFalse);
    expect(p.shouldRepaint(painter(caretOffset: 3)), isTrue);
    expect(
      p.shouldRepaint(
        painter(composing: const TextRange(start: 3, end: 5)),
      ),
      isTrue,
    );
    expect(p.shouldRepaint(painter(caretVisible: false)), isTrue);
  });

  testWidgets('paint renders without error', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(
          size: const Size(100, 100),
          painter: painter(
            caretOffset: 7,
            composing: const TextRange(start: 3, end: 5),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
