// #533: Settings → Library → Study — the new cards a deck shows a day, and
// Reset all reviews.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/ui/study/settings_study.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_settings_study_');
    session = FakeLibrarySession();
    await session.open(dir.path, create: true);
  });

  tearDown(() async {
    await session.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsStudyScreen(controller: session)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('New cards per day: 20, then the one picked', (tester) async {
    await pump(tester);
    expect(find.text('20'), findsOne);
    await tester.tap(find.text('New cards per day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    expect(await session.newCardsPerDay, 5);
    expect(find.text('5'), findsOne);
  });

  testWidgets('Reset all reviews asks, then empties review.json', (
    tester,
  ) async {
    final store = ReviewStore(dir.path);
    await tester.runAsync(
      () => store.write(
        'a.md',
        'one',
        ReviewState(
          ef: 2.5,
          interval: 1,
          reps: 1,
          due: DateTime(2026, 10, 15),
          at: DateTime.utc(2026, 10, 14),
          first: DateTime(2026, 10, 14),
        ),
      ),
    );
    await pump(tester);
    await tester.tap(find.text('Reset all reviews'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-all-reviews-confirm')));
    // The file is written on an isolate, on a real clock.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    final left = await tester.runAsync(store.readAll);
    expect(left, isEmpty);
  });
}
