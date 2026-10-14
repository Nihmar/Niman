// #533: Study — hidden from the navigation until asked for, the decks'
// tree in the left island of a wide window and as a destination on a
// phone, its tags, its counts, a deck opened from it and a category
// studied whole.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

final class _Reviews implements DeckReviewSource {
  @override
  Future<Map<String, ReviewState>> read(String root, String path) async =>
      const {};

  @override
  Future<void> prune(String root, String path, Set<String> keep) async {}

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

String _deck(String deck, List<String> tags, int cards) =>
    '''
---
type: flashcard
deck: $deck
tags: [${tags.join(', ')}]
---

| Q | A |
|---|---|
${[for (var i = 0; i < cards; i++) '| q$i | a$i |'].join('\n')}
''';

void main() {
  late FakeLibrarySession controller;
  late Directory dir;

  setUp(() async {
    controller = FakeLibrarySession();
    dir = await Directory.systemTemp.createTemp('niman_flashcards_study_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> wait(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (until.evaluate().isNotEmpty) break;
    }
    await settle(tester);
  }

  Future<void> boot(
    WidgetTester tester, {
    Size size = const Size(1800, 900),
  }) async {
    setSurfaceSize(tester, size);
    await controller.open(dir.path, create: true);
    for (final (name, deck, tags, cards) in [
      ('Verbs', 'Lingue/Inglese', ['esame'], 3),
      ('Nouns', 'Lingue/Tedesco', <String>[], 2),
      ('Loose', '', <String>[], 1),
    ]) {
      final text = _deck(deck, tags, cards);
      // The index is the fake's; the catalog reads the decks from disk.
      File(p.join(dir.path, '$name.md')).writeAsStringSync(text);
      await controller.createNote(parentPath: '', name: name, content: text);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
          deckReviewSourceProvider.overrideWithValue(_Reviews()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await settle(tester);
  }

  Future<void> openStudy(WidgetTester tester) async {
    // A key goes to the focused widget: a note opened gives the shell one.
    await tester.tap(noteRow('Loose.md'));
    await wait(tester, find.byKey(const Key('deck-name')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await wait(tester, find.byKey(const Key('study-deck-Verbs.md')));
  }

  testWidgets('Study is hidden from the rail; Ctrl+7 shows the decks', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byKey(const Key('rail-study')), findsNothing);
    await openStudy(tester);

    // The categories from deck:, the decks as leaves, No category last.
    for (final key in [
      'study-category-Lingue',
      'study-category-Lingue/Inglese',
      'study-deck-Verbs.md',
      'study-category-Lingue/Tedesco',
      'study-deck-Nouns.md',
      'study-category-\u0000',
      'study-deck-Loose.md',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    // Five new cards under Lingue, summed up the tree.
    expect(
      find.descendant(
        of: find.byKey(const Key('study-category-Lingue')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );

    // A tag leaves the decks that carry it.
    await tester.tap(find.byKey(const Key('study-tag-esame')));
    await settle(tester);
    expect(find.byKey(const Key('study-deck-Verbs.md')), findsOneWidget);
    expect(find.byKey(const Key('study-deck-Nouns.md')), findsNothing);
    await tester.tap(find.byKey(const Key('study-tag-esame')));
    await settle(tester);

    // A category folds.
    await tester.tap(find.byKey(const Key('study-category-Lingue')));
    await settle(tester);
    expect(find.byKey(const Key('study-deck-Verbs.md')), findsNothing);
  });

  testWidgets('a deck opens beside the tree; a category is studied whole', (
    tester,
  ) async {
    await boot(tester);
    await openStudy(tester);

    await tester.tap(find.byKey(const Key('study-deck-Nouns.md')));
    await wait(tester, find.byKey(const Key('deck-name')));
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    // The tree stays in the left island.
    expect(find.byKey(const Key('study-deck-Verbs.md')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('study-category-Lingue')),
        matching: find.byKey(const Key('study-row-study')),
      ),
    );
    await wait(tester, find.byKey(const Key('review-tab')));
    expect(find.text('Study · Lingue'), findsWidgets);
    expect(find.text('0 due · 5 new · 0 again'), findsOneWidget);
  });

  testWidgets('a phone reaches the hidden Study from the palette', (
    tester,
  ) async {
    await boot(tester, size: const Size(400, 800));
    expect(find.byKey(const Key('tab-study')), findsNothing);
    await tester.tap(find.byKey(const Key('tab-search')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('search-open-palette')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), 'Study');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => '${w.key}'.contains('palette-item-')),
        matching: find.text('Go to: Study', findRichText: true),
      ),
    );
    await wait(tester, find.byKey(const Key('study-deck-Verbs.md')));
    expect(find.byKey(const Key('study-deck-Verbs.md')), findsOneWidget);
    // Hidden from the bar, opened anyway: a page with its way back.
    expect(find.byKey(const Key('hidden-tab-back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('study-deck-Verbs.md')));
    await wait(tester, find.byKey(const Key('deck-place')));
    expect(find.text('Lingue › Inglese'), findsOneWidget);
  });
}
