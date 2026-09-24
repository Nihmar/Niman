// #7: the strip over a journal entry — its day, and the entries around it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/journal/journal_strip.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  Future<List<String>> pump(
    WidgetTester tester, {
    required DateTime day,
    List<DateTime> days = const [],
  }) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalStrip(
            day: day,
            today: today,
            entryDays: () async => days,
            onPrevious: () => calls.add('previous'),
            onNext: () => calls.add('next'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('today: its date, the badge, and nowhere further', (
    tester,
  ) async {
    final calls = await pump(
      tester,
      day: today,
      days: [DateTime(2026, 9, 21), today],
    );
    expect(find.text('Wednesday 23 September 2026'), findsOne);
    expect(find.byKey(const Key('journal-today-badge')), findsOne);
    expect(find.text('Mon 21'), findsOne, reason: 'the entry before');
    final next = tester.widget<TextButton>(
      find.byKey(const Key('journal-next')),
    );
    expect(next.onPressed, isNull);
    await tester.tap(find.byKey(const Key('journal-previous')));
    expect(calls, ['previous']);
  });

  testWidgets('a past day: the entries around it, skipping the gaps', (
    tester,
  ) async {
    final calls = await pump(
      tester,
      day: DateTime(2026, 9, 14),
      days: [DateTime(2026, 9), DateTime(2026, 9, 14), today],
    );
    expect(find.byKey(const Key('journal-today-badge')), findsNothing);
    expect(find.text('Tue 1'), findsOne);
    expect(find.text('Wed 23'), findsOne);
    await tester.tap(find.byKey(const Key('journal-next')));
    expect(calls, ['next']);
  });

  testWidgets('with nothing around, the days next to it', (tester) async {
    await pump(tester, day: DateTime(2026, 9, 14));
    expect(find.text('Sun 13'), findsOne);
    expect(find.text('Tue 15'), findsOne);
  });
}
