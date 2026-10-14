// #533: a flashcard deck in the shell — New flashcards makes one, its ⋮
// leads with the deck's entries, the pencil shows the Markdown, F5 and the
// entry start a study session through the seam, and the columns and reset
// entries act on the note and its review.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_study.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

final class _Reviews implements DeckReviewSource {
  final List<String> resets = [];

  @override
  Future<Map<String, ReviewState>> read(String root, String path) async =>
      const {};

  @override
  Future<void> prune(String root, String path, Set<String> keep) async {}

  @override
  Future<void> reset(String root, String path) async => resets.add(path);

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
deck: Lingue/Inglese
---

| Verb | Past | Participle |
|---|---|---|
| begin | began | begun |
| choose | chose | chosen |
''';

void main() {
  late FakeLibrarySession controller;
  late Directory dir;
  late _Reviews reviews;
  late List<String> studied;

  setUp(() async {
    controller = FakeLibrarySession();
    reviews = _Reviews();
    studied = [];
    dir = await Directory.systemTemp.createTemp('niman_flashcards_shell_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  /// [study] false: no starter; [realStudy]: the app's own, the review.
  Widget buildApp({bool study = true, bool realStudy = false}) {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        windowControllerProvider.overrideWithValue(
          FakeWindowController(customTitleBar: true),
        ),
        deckReviewSourceProvider.overrideWithValue(reviews),
        if (!realStudy)
          deckStudyStarterProvider.overrideWithValue(
            study ? (context, path) async => studied.add(path) : null,
          ),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> openDeck(
    WidgetTester tester, {
    bool study = true,
    bool realStudy = false,
    Size size = const Size(1200, 900),
  }) async {
    setSurfaceSize(tester, size);
    await controller.open(dir.path, create: true);
    File(p.join(dir.path, 'Deck.md')).writeAsStringSync(_deck);
    await controller.createNote(parentPath: '', name: 'Deck', content: _deck);
    await tester.pumpWidget(buildApp(study: study, realStudy: realStudy));
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('Deck.md'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.byKey(const Key('kind-edit-raw')).evaluate().isNotEmpty) break;
    }
    await settle(tester);
  }

  testWidgets("the ⋮ of a deck: its entries, then the note's", (tester) async {
    await openDeck(tester);
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    for (final entry in [
      'studyDeck',
      'editMarkdown',
      'deckColumns',
      'deckReset',
      'rename',
      'move',
      'history',
      'export',
      'delete',
    ]) {
      expect(
        find.byKey(Key('note-menu-$entry')),
        findsOneWidget,
        reason: entry,
      );
    }
    // The editor's own entries step aside, as a slides deck's do.
    expect(find.byKey(const Key('note-menu-typewriter')), findsNothing);
    expect(find.byKey(const Key('note-menu-format')), findsNothing);
  });

  testWidgets('Study this deck and F5 start the session through the seam', (
    tester,
  ) async {
    await openDeck(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-studyDeck')));
    await settle(tester);
    expect(studied, hasLength(1));
    expect(p.basename(studied.single), 'Deck.md');

    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await settle(tester);
    expect(studied, hasLength(2));
  });

  testWidgets('Study opens the review beside the deck, its card marked', (
    tester,
  ) async {
    // Room for two panes beside the tree and the dock.
    await openDeck(tester, realStudy: true, size: const Size(1800, 900));
    await tester.tap(find.byKey(const Key('deck-study')));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byKey(const Key('review-tab')).evaluate().isNotEmpty) break;
    }
    await settle(tester);
    expect(find.byKey(const Key('review-tab')), findsOneWidget);
    expect(find.text('Study · Deck'), findsWidgets);
    // The deck stays on screen, in the pane beside, the card asked marked.
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    expect(find.byKey(const Key('deck-row-studying')), findsOneWidget);
    // The list gives no answer away while the deck is studied.
    expect(find.text('Answer'), findsNothing);
    expect(find.text('began', findRichText: true), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('review-question')),
        matching: find.text('begin', findRichText: true),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byKey(const Key('review-tab')), findsNothing);
    expect(find.byKey(const Key('deck-row-studying')), findsNothing);
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    expect(find.text('began', findRichText: true), findsOneWidget);
  });

  testWidgets('a window too narrow for two panes studies over the deck', (
    tester,
  ) async {
    await openDeck(tester, realStudy: true);
    await tester.tap(find.byKey(const Key('deck-study')));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byKey(const Key('review-tab')).evaluate().isNotEmpty) break;
    }
    await settle(tester);
    expect(find.byKey(const Key('review-question')), findsOneWidget);
    expect(find.byKey(const Key('deck-name')), findsNothing);

    // The study keeps its chip while the deck's tab is shown again.
    await tester.tap(find.text('Deck').first);
    await settle(tester);
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    expect(find.byKey(const Key('review-question')), findsNothing);
    await tester.tap(find.byKey(const Key('review-tab')));
    await settle(tester);
    expect(find.byKey(const Key('review-question')), findsOneWidget);
    await tester.tap(find.byKey(const Key('review-tab-close')));
    await settle(tester);
    expect(find.byKey(const Key('review-tab')), findsNothing);
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
  });

  testWidgets('Study is greyed while no review can start', (tester) async {
    await openDeck(tester, study: false);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    final item = tester.widget<PopupMenuItem<Object?>>(
      find.byKey(const Key('note-menu-studyDeck')),
    );
    expect(item.enabled, isFalse);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await settle(tester);
    expect(studied, isEmpty);
  });

  testWidgets("Edit as Markdown shows the note's text, the pencil too", (
    tester,
  ) async {
    await openDeck(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-editMarkdown')));
    await settle(tester);
    expect(find.byKey(const Key('deck-name')), findsNothing);
    expect(find.byKey(const Key('kind-show-list')), findsOneWidget);
    expect(find.textContaining('type: flashcard'), findsWidgets);

    await tester.tap(find.byKey(const Key('kind-show-list')));
    await settle(tester);
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    await tester.tap(find.byKey(const Key('kind-edit-raw')));
    await settle(tester);
    expect(find.byKey(const Key('deck-name')), findsNothing);
  });

  testWidgets("Reset asks, then forgets the deck's review", (tester) async {
    await openDeck(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-deckReset')));
    await settle(tester);
    expect(reviews.resets, isEmpty, reason: 'it asks first');
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(reviews.resets, isEmpty);

    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-deckReset')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('deck-reset-confirm')));
    await settle(tester);
    expect(reviews.resets, ['Deck.md']);
  });

  testWidgets('Question and answer columns write front: and back:', (
    tester,
  ) async {
    await openDeck(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-deckColumns')));
    await settle(tester);
    expect(find.byKey(const Key('deck-column-question')), findsOneWidget);

    // The answer is the third column.
    await tester.tap(find.byKey(const Key('deck-column-answer')));
    await settle(tester);
    await tester.tap(find.text('Participle').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('deck-columns-save')));
    await settle(tester);

    // The deck reads the new columns: the answers are the participles.
    expect(find.text('begun'), findsOneWidget);
    expect(find.text('began'), findsNothing);
    await tester.tap(find.byKey(const Key('kind-edit-raw')));
    await settle(tester);
    expect(find.textContaining('front: Verb'), findsWidgets);
    expect(find.textContaining('back: Participle'), findsWidgets);
  });

  testWidgets("the palette offers the deck's commands only on a deck", (
    tester,
  ) async {
    await openDeck(tester);
    await sendWithModifiers(tester, LogicalKeyboardKey.keyP, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
    ]);
    await settle(tester);
    Set<AppCommand> offered() => {
      for (final command
          in tester
              .widget<CommandPalette>(find.byType(CommandPalette))
              .commands)
        command.command,
    };
    expect(
      offered(),
      containsAll([
        AppCommand.newFlashcards,
        AppCommand.studyDeck,
        AppCommand.deckColumns,
        AppCommand.deckReset,
      ]),
    );
    expect(offered(), isNot(contains(AppCommand.presentSlides)));

    // On the deck's Markdown the deck's commands step aside.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    await tester.tap(find.byKey(const Key('kind-edit-raw')));
    await settle(tester);
    await sendWithModifiers(tester, LogicalKeyboardKey.keyP, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
    ]);
    await settle(tester);
    expect(offered(), contains(AppCommand.newFlashcards));
    expect(offered(), isNot(contains(AppCommand.studyDeck)));
  });

  testWidgets('the wide create menu offers New flashcards', (tester) async {
    await openDeck(tester);
    await tester.tap(find.byKey(const Key('new-item-menu')));
    await settle(tester);
    expect(find.byKey(const Key('new-flashcards-action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-flashcards-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Verbs');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(controller.contentOf('Verbs.md'), contains('type: flashcard'));
  });

  Future<void> openPlain(WidgetTester tester, String content) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await controller.open(dir.path, create: true);
    File(p.join(dir.path, 'Verbs.md')).writeAsStringSync(content);
    await controller.createNote(
      parentPath: '',
      name: 'Verbs',
      content: content,
    );
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('Verbs.md'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
  }

  testWidgets('Make flashcards writes the frontmatter and shows the deck', (
    tester,
  ) async {
    const plain =
        '# Verbs\n\n| Verb | Past | Participle |\n|---|---|---|\n'
        '| begin | began | begun |\n| choose | chose | chosen |\n\n'
        '- thrive :: throve\n';
    await openPlain(tester, plain);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-makeFlashcards')));
    await settle(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('make-flashcards-found'))).data,
      '2 table rows, 1 :: line',
    );
    // The answer: the participle, not the past.
    await tester.tap(find.byKey(const Key('deck-column-answer')));
    await settle(tester);
    await tester.tap(find.text('Participle').last);
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('make-flashcards-deck')),
      'Lingue/Inglese',
    );
    await settle(tester);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('make-flashcards-preview')),
          )
          .data,
      '---\ntype: flashcard\ndeck: Lingue/Inglese\nfront: Verb\n'
      'back: Participle\n---',
    );
    expect(find.text('Make 3 cards'), findsOneWidget);
    await tester.tap(find.byKey(const Key('make-flashcards-confirm')));
    await settle(tester);

    expect(
      controller.contentOf('Verbs.md'),
      '---\ntype: flashcard\ndeck: Lingue/Inglese\nfront: Verb\n'
      'back: Participle\n---\n\n$plain',
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
    expect(find.byKey(const Key('deck-name')), findsOneWidget);
    expect(find.text('begun', findRichText: true), findsOneWidget);
  });

  testWidgets('a note with nothing to make cards from says so', (tester) async {
    await openPlain(tester, 'Just prose.\n');
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-makeFlashcards')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text(
        'This note has no table, :: line or highlight to make cards from.',
      ),
      findsOneWidget,
    );
    expect(controller.contentOf('Verbs.md'), 'Just prose.\n');
  });

  testWidgets('New flashcards makes a deck with an empty table', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    final picker = useFakeFilePicker();
    await openLibrary(tester, picker);

    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-flashcards-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Verbs');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(
      controller.contentOf('Verbs.md'),
      '---\ntype: flashcard\ndeck: \n---\n\n'
      '| Question | Answer |\n|---|---|\n',
    );

    // The first deck offers Study, hidden until then, once.
    expect(find.byKey(const Key('rail-study')), findsNothing);
    expect(find.byKey(const Key('study-offer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('study-offer-show')));
    await settle(tester);
    expect(find.byKey(const Key('rail-study')), findsOneWidget);
    expect(
      (await controller.navigation).library?.hidden,
      isNot(contains('study')),
    );

    ScaffoldMessenger.of(tester.element(find.byKey(const Key('rail-study'))))
        .hideCurrentSnackBar();
    await settle(tester);
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-flashcards-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Nouns');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(controller.contentOf('Nouns.md'), isNotNull);
    expect(find.byKey(const Key('study-offer')), findsNothing);
  });
}
