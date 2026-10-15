// #965: an open deck keeps its review states current — the reads that
// overlap land in the order they were asked.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/study_day.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_note_view.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_study.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

final class _Host implements NoteKindHost {
  const new();

  @override
  String get notePath => p.join('library', 'Deck.md');

  @override
  String get text => _table;

  @override
  void applyEdit(String newText) {}

  @override
  String? get libraryRoot => 'library';

  @override
  String get attachmentsFolder => '';

  @override
  LinkType get linkType => LinkType.wikilink;

  @override
  Future<String?> resolveEmbed(String target) async => null;

  @override
  void openLink(BuildContext context, String href) {}

  @override
  void openWikiLink(BuildContext context, String inner) {}

  @override
  VoidCallback? get showMarkdown => null;
}

const String _table = '''
---
type: flashcard
deck: Lingue/Inglese
---

| Verb | Past |
|---|---|
| begin | began |
| choose | chose |
''';

/// A source whose reads wait for the test to answer them, so it decides in
/// which order they land.
final class _HeldReviews implements DeckReviewSource {
  final List<Completer<Map<String, ReviewState>>> reads = [];
  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  void changed() => _changes.add('library');

  @override
  Future<Map<String, ReviewState>> read(String root, String path) {
    final read = Completer<Map<String, ReviewState>>();
    reads.add(read);
    return read.future;
  }

  @override
  Future<Map<String, Map<String, ReviewState>>> readMany(
    String root,
    Iterable<String> paths,
  ) async => {for (final path in paths) path: const {}};

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
  Stream<String> get changes => _changes.stream;
}

/// The states of a deck whose card `begin` is due [days] days after [today].
Map<String, ReviewState> _begin(DateTime today, int days) => {
  'begin': ReviewState(
    ef: 2.5,
    interval: 6,
    reps: 2,
    due: today.add(Duration(days: days)),
    at: DateTime.utc(2026, 10),
    first: DateTime(2026, 10),
  ),
};

String _counts(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('deck-counts'))).data!;

Future<void> _show(
  WidgetTester tester,
  _HeldReviews reviews, {
  FakeLibrarySession? session,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(
          session ?? FakeLibrarySession(),
        ),
        deckStudyStarterProvider.overrideWithValue(null),
        deckReviewSourceProvider.overrideWithValue(reviews),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: DeckNoteView(text: _table, host: _Host()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final today = studyToday(DateTime.now(), 0);

  group('overlapping reads of the states (#965)', () {
    testWidgets('an older read that lands last does not put old states back', (
      tester,
    ) async {
      final reviews = _HeldReviews();
      await _show(tester, reviews);
      reviews.reads.single.complete(const {});
      await tester.pumpAndSettle();
      expect(_counts(tester), '0 due · 2 new · 2 cards');

      // Two grades in a row, each a read of its own.
      reviews
        ..changed()
        ..changed();
      await tester.pumpAndSettle();
      expect(reviews.reads, hasLength(3));

      // The later read answers first, with the grade; the older one, which
      // read the file before it, lands after.
      reviews.reads[2].complete(_begin(today, 3));
      await tester.pumpAndSettle();
      expect(_counts(tester), '0 due · 1 new · 2 cards');
      reviews.reads[1].complete(const {});
      await tester.pumpAndSettle();
      expect(_counts(tester), '0 due · 1 new · 2 cards');
    });
  });
}
