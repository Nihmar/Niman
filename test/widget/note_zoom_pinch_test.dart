// #538: two fingers spread or brought together over the note zoom its
// text, a trackpad's pinch too; two fingers swiped down together — the
// palette's gesture — zoom nothing.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_zoom_pinch.dart';

void main() {
  late double scale;
  late List<(double, bool)> told;

  Future<void> pump(WidgetTester tester) async {
    scale = 1;
    told = [];
    await tester.pumpWidget(
      MaterialApp(
        home: NoteZoomPinch(
          scale: () => scale,
          onZoom: (value, {required done}) {
            told.add((value, done));
            scale = value;
          },
          child: ListView(
            children: [for (var i = 0; i < 50; i++) Text('riga $i')],
          ),
        ),
      ),
    );
  }

  /// Two fingers from [a] and [b] to [a2] and [b2], in steps.
  Future<void> twoFingers(
    WidgetTester tester,
    (Offset, Offset) from,
    (Offset, Offset) to,
  ) async {
    final one = await tester.startGesture(from.$1, pointer: 1);
    final two = await tester.startGesture(from.$2, pointer: 2);
    for (var step = 1; step <= 10; step++) {
      await one.moveTo(Offset.lerp(from.$1, to.$1, step / 10)!);
      await two.moveTo(Offset.lerp(from.$2, to.$2, step / 10)!);
      await tester.pump();
    }
    await one.up();
    await two.up();
    await tester.pump();
  }

  testWidgets('spread, the text grows; pinched, it shrinks; kept at the end', (
    tester,
  ) async {
    await pump(tester);
    await twoFingers(
      tester,
      (const Offset(200, 300), const Offset(260, 300)),
      (const Offset(185, 300), const Offset(275, 300)),
    );
    expect(told.last, (1.5, true), reason: 'the fingers half again as far');
    expect(told.where((t) => !t.$2), isNotEmpty, reason: 'shown live');
    await twoFingers(
      tester,
      (const Offset(150, 300), const Offset(310, 300)),
      (const Offset(200, 300), const Offset(260, 300)),
    );
    expect(told.last.$2, isTrue);
    expect(told.last.$1, lessThan(1.5));
  });

  testWidgets("two fingers down together are the palette's, not a zoom", (
    tester,
  ) async {
    await pump(tester);
    await twoFingers(
      tester,
      (const Offset(200, 200), const Offset(260, 200)),
      (const Offset(200, 320), const Offset(262, 320)),
    );
    expect(told, isEmpty);
  });

  testWidgets("a trackpad's pinch zooms", (tester) async {
    await pump(tester);
    final pad = TestPointer(1, PointerDeviceKind.trackpad);
    final at = tester.getCenter(find.byType(ListView));
    await tester.sendEventToBinding(pad.panZoomStart(at));
    await tester.sendEventToBinding(pad.panZoomUpdate(at, scale: 1.3));
    await tester.sendEventToBinding(pad.panZoomEnd());
    await tester.pump();
    expect(told.last, (1.3, true));
  });
}
