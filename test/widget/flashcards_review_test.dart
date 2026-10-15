// #533: the review — the question, the answer, the four grades and what
// each writes, the keys, undo, and the summary at the end.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/study_session.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/kinds/flashcards/review_view.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

/// The writes, in order; the reads are not used.
final class _Reviews implements DeckReviewSource {
  final List<(String, ReviewState?)> writes = [];
  final List<List<String>> reads = [];

  @override
  Future<Map<String, ReviewState>> read(String root, String path) async {
    reads.add([path]);
    return const {};
  }

  @override
  Future<Map<String, Map<String, ReviewState>>> readMany(
    String root,
    Iterable<String> paths,
  ) async {
    reads.add(paths.toList());
    return {for (final path in paths) path: const {}};
  }

  @override
  Future<void> reset(String root, String path) async {}

  @override
  Future<void> write(
    String root,
    String path,
    String key,
    ReviewState? state,
  ) async => writes.add((key, state));

  @override
  Stream<String> get changes => const Stream.empty();
}

const String _deck = '''
---
type: flashcard
---

| Verb | Past |
|---|---|
| begin | began |
| choose | chose |
''';

void main() {
  late _Reviews reviews;
  late int closed;
  late List<String> nextDecks;

  Future<ReviewRun> show(WidgetTester tester, {String? nextDeck}) async {
    reviews = _Reviews();
    closed = 0;
    nextDecks = [];
    final run = ReviewRun(
      session: StudySession.start(
        decks: [SessionDeck(path: 'Verbs.md', cards: Deck.read(_deck).cards)],
        today: DateTime(2026, 10, 14),
        newPerDay: 20,
      ),
      title: 'Verbs',
      root: 'library',
      reviews: reviews,
      nextDeck: () async => nextDeck,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewView(
            run: run,
            onClose: () => closed++,
            onNextDeck: nextDecks.add,
          ),
        ),
      ),
    );
    await tester.pump();
    return run;
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('Show answer, then a grade writes the card and asks the next', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('begin'), findsOneWidget);
    expect(find.byKey(const Key('review-answer')), findsNothing);
    expect(find.byKey(const Key('review-grade-good')), findsNothing);
    expect(text(tester, 'review-counts'), '0 due · 2 new · 0 again');

    await tester.tap(find.byKey(const Key('review-show')));
    await tester.pump();
    expect(find.text('began'), findsOneWidget);
    // A new card: Again today, Hard and Good tomorrow, Easy a day more.
    expect(find.text('today'), findsOneWidget);
    expect(find.text('tomorrow'), findsNWidgets(2));
    expect(find.text('in 2 days'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-grade-good')));
    await tester.pump();
    expect(reviews.writes.single.$1, 'begin');
    expect(reviews.writes.single.$2!.interval, 1);
    expect(find.text('choose'), findsOneWidget);
    expect(text(tester, 'review-counts'), '0 due · 1 new · 0 again');
  });

  testWidgets('Again asks the card once more, at the end', (tester) async {
    final run = await show(tester);
    run
      ..show()
      ..grade(.again);
    await tester.pump();
    expect(text(tester, 'review-counts'), '0 due · 1 new · 1 again');
    run
      ..show()
      ..grade(.good);
    await tester.pump();
    expect(find.text('begin'), findsOneWidget);
  });

  testWidgets('the keys: Space shows then grades Good, 1-4 grade, Esc ends', (
    tester,
  ) async {
    await show(tester);
    // A grade key before the answer shows does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    expect(reviews.writes, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.text('began'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(reviews.writes.single.$2!.interval, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();
    expect(reviews.writes.last.$1, 'choose');
    expect(reviews.writes.last.$2!.interval, greaterThan(1));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, 1);
  });

  testWidgets('Ctrl+Z takes the grade back and writes the state before', (
    tester,
  ) async {
    await show(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    expect(find.text('choose'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('begin'), findsOneWidget);
    // A new card's undo takes it back to never reviewed.
    expect(reviews.writes.last, ('begin', null));
  });

  testWidgets('the summary: the counts, the next cards, Next deck', (
    tester,
  ) async {
    final run = await show(tester, nextDeck: 'Other.md');
    for (final grade in [Grade.again, Grade.good, Grade.good]) {
      run
        ..show()
        ..grade(grade);
    }
    await tester.pumpAndSettle();
    expect(find.text('Done for today'), findsOneWidget);
    expect(
      text(tester, 'review-summary-counts'),
      startsWith('2 reviewed · 1 again · '),
    );
    expect(text(tester, 'review-summary-next'), 'Next: tomorrow · 2 cards');

    await tester.tap(find.byKey(const Key('review-next-deck')));
    expect(nextDecks, ['Other.md']);
    await tester.tap(find.byKey(const Key('review-back')));
    expect(closed, 1);
  });

  testWidgets('Next deck is off when no other deck has cards today', (
    tester,
  ) async {
    final run = await show(tester);
    for (var i = 0; i < 2; i++) {
      run
        ..show()
        ..grade(.easy);
    }
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('review-next-deck')))
          .onPressed,
      isNull,
    );
  });

  test(
    'a run reads the deck from disk and leaves a missing note out',
    () async {
      final dir = await Directory.systemTemp.createTemp('niman_review_run_');
      final session = FakeLibrarySession();
      addTearDown(() async {
        await session.close();
        await session.dispose();
        await dir.delete(recursive: true);
      });
      await session.open(dir.path, create: true);
      File(p.join(dir.path, 'Verbs.md')).writeAsStringSync(_deck);
      final run = await loadReviewRun(
        session: session,
        reviews: _Reviews(),
        paths: [p.join(dir.path, 'Verbs.md'), p.join(dir.path, 'Gone.md')],
      );
      expect(run!.title, 'Verbs');
      expect(run.session.decks.single.path, 'Verbs.md');
      expect(run.session.remainingNew, 2);
      expect(run.session.current!.card.question, 'begin');
    },
  );

  test('a run of several decks reads the states in one go (#946)', () async {
    final dir = await Directory.systemTemp.createTemp('niman_review_many_');
    final session = FakeLibrarySession();
    addTearDown(() async {
      await session.close();
      await session.dispose();
      await dir.delete(recursive: true);
    });
    await session.open(dir.path, create: true);
    for (final name in ['A.md', 'B.md', 'C.md']) {
      File(p.join(dir.path, name)).writeAsStringSync(_deck);
    }
    final reviews = _Reviews();
    final run = await loadReviewRun(
      session: session,
      reviews: reviews,
      paths: [
        for (final name in ['A.md', 'B.md', 'C.md']) p.join(dir.path, name),
      ],
    );
    expect(run!.session.decks.map((deck) => deck.path), [
      'A.md',
      'B.md',
      'C.md',
    ]);
    expect(reviews.reads, [
      ['A.md', 'B.md', 'C.md'],
    ]);
  });
}
