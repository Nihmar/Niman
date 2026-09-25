// Issue #287: a note's title that is too long for the room it has
// scrolls itself, so the whole name can be read without opening it. A
// title that fits, and a system set to reduce motion, stay plain.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/marquee_text.dart';

Widget _host(
  String text, {
  required double width,
  bool reduced = false,
  double velocity = 400,
  Duration pause = const Duration(milliseconds: 200),
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: MarqueeText(
              text: text,
              style: const TextStyle(fontSize: 14),
              velocity: velocity,
              pause: pause,
            ),
          ),
        ),
      ),
    ),
  );
}

double _offset(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const Key('marquee-offset')),
  );
  return transform.transform.getTranslation().x;
}

void main() {
  const short = 'Note';
  // Eight characters at the test font's 14 px em: 112 px wide.
  const eight = 'abcdefgh';

  testWidgets('a title that fits is drawn plain', (tester) async {
    await tester.pumpWidget(_host(short, width: 200));
    await tester.pump();

    expect(find.text(short), findsOne);
    expect(find.byType(OverflowBox), findsNothing);
  });

  testWidgets('a title too long for its room scrolls left, then back', (
    tester,
  ) async {
    await tester.pumpWidget(_host(eight, width: 60));
    // One pump builds and schedules the movement; the next runs it.
    await tester.pump();
    await tester.pump();

    // Past the opening pause and the travel: the line rests with its end
    // in view.
    await tester.pump(const Duration(milliseconds: 500));
    expect(_offset(tester), lessThan(-30), reason: 'the end came into view');

    // A full cycle later it is home again, ready for the next pass.
    await tester.pump(const Duration(milliseconds: 300));
    expect(_offset(tester), greaterThan(-1), reason: 'looped back to start');
  });

  testWidgets('reduce motion keeps the ellipsis', (tester) async {
    await tester.pumpWidget(_host(eight, width: 60, reduced: true));
    await tester.pump();

    expect(find.text(eight), findsOne);
    expect(find.byType(OverflowBox), findsNothing);
  });

  testWidgets('a wider room stops the movement', (tester) async {
    await tester.pumpWidget(_host(eight, width: 60));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('marquee-offset')), findsOne);

    await tester.pumpWidget(_host(short, width: 200));
    await tester.pump();
    expect(find.byKey(const Key('marquee-offset')), findsNothing);
    expect(find.text(short), findsOne);
  });
}
