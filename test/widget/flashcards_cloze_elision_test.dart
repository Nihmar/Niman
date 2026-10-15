// #949: a cloze whose sentence holds a literal elision mark ("[…]") draws one
// gap, the real one, and the review's answer fills that one.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/study_session.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/kinds/flashcards/review_view.dart';

final class _Reviews implements DeckReviewSource {
  @override
  Future<Map<String, ReviewState>> read(String root, String path) async =>
      const {};

  @override
  Future<Map<String, Map<String, ReviewState>>> readMany(
    String root,
    Iterable<String> paths,
  ) async => {for (final path in paths) path: await read(root, path)};

  @override
  Future<void> reset(String root, String path) async {}

  @override
  Future<void> write(
    String root,
    String path,
    String key,
    ReviewState? state,
  ) async {}

  @override
  Stream<String> get changes => const Stream.empty();
}

const String _deck = '''
---
type: flashcard
---

I came […] and ==conquered==.
''';

void main() {
  testWidgets('the question draws the gap once and the elision as text', (
    tester,
  ) async {
    final run = await _show(tester);
    expect(run.session.current!.card.question, r'I came […\] and […].');
    expect(find.byKey(const Key('card-gap')), findsOneWidget);
    expect(_plain(tester, 'review-question'), contains('I came […] and '));
  });

  testWidgets('Show answer fills the gap, not the elision', (tester) async {
    await _show(tester);
    await tester.tap(find.byKey(const Key('review-show')));
    await tester.pump();
    expect(find.byKey(const Key('card-gap')), findsNothing);
    expect(_plain(tester, 'review-answer'), 'I came […] and conquered.');
  });
}

String _plain(WidgetTester tester, String key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
    )
    .textSpan!
    .toPlainText(includePlaceholders: false);

Future<ReviewRun> _show(WidgetTester tester) async {
  final run = ReviewRun(
    session: StudySession.start(
      decks: [SessionDeck(path: 'Caesar.md', cards: Deck.read(_deck).cards)],
      today: DateTime(2026, 10, 14),
      newPerDay: 20,
    ),
    title: 'Caesar',
    root: 'library',
    reviews: _Reviews(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReviewView(run: run, onClose: () {}, onNextDeck: (_) {}),
      ),
    ),
  );
  await tester.pump();
  return run;
}
