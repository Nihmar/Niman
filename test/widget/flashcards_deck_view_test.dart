// #533: the flashcard kind's view — a deck's counts and cards, the card
// edits that rewrite the note (in place on a wide window, from a sheet on a
// phone), and the Study seam.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:niman/src/ui/kinds/flashcards/flashcard_kind.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

final class _Host implements NoteKindHost {
  new(String text, {this.root, String name = 'Deck.md'})
    : notePath = p.join(root ?? 'library', name),
      note = ValueNotifier<String>(text);

  final ValueNotifier<String> note;

  @override
  final String notePath;

  final String? root;

  /// A text the note holds that the view has not been given yet: the sync
  /// or another pane changed it, and the view's re-read has not landed.
  String? ahead;

  @override
  String get text => ahead ?? note.value;

  @override
  void applyEdit(String newText) => note.value = newText;

  @override
  String? get libraryRoot => root;

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
tags: [esame]
---

| Verb | Past |
|---|---|
| begin | began |
| choose | chose |
| tread | trod |
''';

const Size _wide = Size(1200, 800);
const Size _phone = Size(400, 800);

/// The review states in memory: the file's reads run on a real clock.
final class _Reviews implements DeckReviewSource {
  new(this.states);

  final Map<String, ReviewState> states;

  @override
  Future<Map<String, ReviewState>> read(String root, String path) async =>
      Map.of(states);

  @override
  Future<Map<String, Map<String, ReviewState>>> readMany(
    String root,
    Iterable<String> paths,
  ) async => {for (final path in paths) path: await read(root, path)};

  @override
  Future<void> reset(String root, String path) async => states.clear();

  @override
  Future<void> write(
    String root,
    String path,
    String key,
    ReviewState? state,
  ) async {
    if (state == null) {
      states.remove(key);
    } else {
      states[key] = state;
    }
  }

  @override
  Stream<String> get changes => const Stream.empty();
}

DateTime get _today => studyToday(DateTime.now(), 0);

ReviewState _state(int daysFromToday) => ReviewState(
  ef: 2.5,
  interval: 6,
  reps: 2,
  due: _today.add(Duration(days: daysFromToday)),
  at: DateTime.utc(2026, 10),
  first: DateTime(2026, 10),
);

late _Reviews _reviews;

Future<_Host> _show(
  WidgetTester tester,
  String text, {
  Size size = _wide,
  Map<String, ReviewState> states = const {},
  DeckStudyStarter? study,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final host = _Host(text, root: 'library');
  _reviews = _Reviews({...states});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(FakeLibrarySession()),
        deckStudyStarterProvider.overrideWithValue(study),
        deckReviewSourceProvider.overrideWithValue(_reviews),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<String>(
            valueListenable: host.note,
            builder: (context, text, _) => DeckNoteView(text: text, host: host),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return host;
}

/// The states are read from the fake at once; draw them.
Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

String _counts(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('deck-counts'))).data!;

bool _studyEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(find.byKey(const Key('deck-study')))
        .onPressed !=
    null;

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('the flashcard kind is registered', () {
    expect(NoteKinds.forType('flashcard'), isA<FlashcardKindGui>());
    expect(NoteKinds.forType('flashcard')!.type, 'flashcard');
  });

  group('wide', () {
    testWidgets('the header and the rows', (tester) async {
      final states = {'begin': _state(-1), 'choose': _state(3)};
      await _show(tester, _table, states: states);
      expect(find.byKey(const Key('deck-place')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('deck-place'))).data,
        'Lingue › Inglese',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('deck-name'))).data,
        'Deck',
      );
      expect(_counts(tester), '1 due · 1 new · 3 cards');
      expect(find.text('#esame'), findsOneWidget);
      expect(find.text('Study 2'), findsOneWidget);
      // Each row says when its card comes back.
      expect(find.text('Due'), findsWidgets);
      expect(find.text('in 3 days'), findsOneWidget);
      expect(find.text('New'), findsWidgets);
      expect(
        tester.widget<Text>(find.byKey(const Key('deck-status'))).data,
        'Flashcards · 3 cards · 3 table rows',
      );
    });

    testWidgets('a deck with no category says so', (tester) async {
      await _show(
        tester,
        '---\ntype: flashcard\n---\n\n| Q | A |\n|---|---|\n',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('deck-place'))).data,
        AppStrings.flashcardsNoCategory,
      );
      expect(find.byKey(const Key('deck-empty')), findsOneWidget);
      expect(_studyEnabled(tester), isFalse);
    });

    testWidgets('Study is disabled when there is nothing to study', (
      tester,
    ) async {
      final states = {
        'begin': _state(2),
        'choose': _state(5),
        'tread': _state(40),
      };
      await _show(
        tester,
        _table,
        states: states,
        study: (context, path) async {},
      );
      expect(_counts(tester), '0 due · 0 new · 3 cards');
      expect(find.text('Study 0'), findsOneWidget);
      expect(_studyEnabled(tester), isFalse);
      expect(find.text('in 1 month'), findsOneWidget);
    });

    testWidgets('Study starts the deck through the seam', (tester) async {
      final started = <String>[];
      final host = await _show(
        tester,
        _table,
        study: (context, path) async => started.add(path),
      );
      expect(_studyEnabled(tester), isTrue);
      await tester.tap(find.byKey(const Key('deck-study')));
      await tester.pump();
      expect(started, [host.notePath]);
    });

    testWidgets('Study is disabled while nothing starts a session', (
      tester,
    ) async {
      await _show(tester, _table);
      expect(_studyEnabled(tester), isFalse);
    });

    testWidgets('a cloze shows its gap and highlights its answer', (
      tester,
    ) async {
      await _show(
        tester,
        'The past of *to tread* is ==trod==.\n\n'
        '- thrive :: throve\n',
      );
      expect(find.byKey(const Key('card-gap')), findsOneWidget);
      expect(find.byKey(const Key('deck-row-highlight')), findsOneWidget);
      expect(find.text('trod'), findsWidgets);
      expect(
        tester.widget<Text>(find.byKey(const Key('deck-status'))).data,
        'Flashcards · 2 cards · 1 :: line, 1 cloze',
      );
    });

    testWidgets('a repeated question is marked', (tester) async {
      await _show(
        tester,
        '| Q | A |\n|---|---|\n| same | one |\n| same | two |\n| other | x |\n',
      );
      expect(find.byKey(const Key('deck-row-repeated')), findsOneWidget);
    });

    testWidgets('a double click edits in place and Enter rewrites the note', (
      tester,
    ) async {
      final host = await _show(tester, _table);
      await _doubleTap(tester, find.byKey(const Key('deck-row-choose')));
      expect(find.byKey(const Key('row-question-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('row-answer-field')),
        'chose, chosen',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.text, _table.replaceFirst('| chose |', '| chose, chosen |'));
      expect(find.byKey(const Key('row-question-field')), findsNothing);
      expect(find.text('chose, chosen'), findsOneWidget);
    });

    testWidgets('Esc cancels an edit and leaves the note alone', (
      tester,
    ) async {
      final host = await _show(tester, _table);
      await _doubleTap(tester, find.byKey(const Key('deck-row-begin')));
      await tester.enterText(find.byKey(const Key('row-answer-field')), 'x');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(host.text, _table);
      expect(find.byKey(const Key('row-question-field')), findsNothing);
      expect(find.text('began'), findsOneWidget);
    });

    testWidgets('an emptied question does not save', (tester) async {
      final host = await _show(tester, _table);
      await _doubleTap(tester, find.byKey(const Key('deck-row-begin')));
      await tester.enterText(find.byKey(const Key('row-question-field')), ' ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.text, _table);
      expect(find.byKey(const Key('row-question-field')), findsOneWidget);
    });

    testWidgets('a changed question leaves the old key in the review file', (
      tester,
    ) async {
      final states = {'begin': _state(2), 'choose': _state(3)};
      final host = await _show(tester, _table, states: states);
      await _doubleTap(tester, find.byKey(const Key('deck-row-begin')));
      await tester.enterText(
        find.byKey(const Key('row-question-field')),
        'start',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.text, contains('| start | began |'));
      // The old key is an orphan now, and stays: the text change is an
      // undoable edit, and Undo brings the card back with its state.
      expect(_reviews.states.keys, ['begin', 'choose']);
      host.note.value = _table;
      await tester.pumpAndSettle();
      expect(find.text('in 2 days'), findsOneWidget);
    });

    testWidgets("an edited answer keeps the card's review state", (
      tester,
    ) async {
      final states = {'begin': _state(2)};
      await _show(tester, _table, states: states);
      await _doubleTap(tester, find.byKey(const Key('deck-row-begin')));
      await tester.enterText(
        find.byKey(const Key('row-answer-field')),
        'did begin',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(find.text('in 2 days'), findsOneWidget);
    });

    testWidgets('Add card appends a row to the first table', (tester) async {
      final host = await _show(tester, _table);
      await tester.tap(find.byKey(const Key('deck-add-card')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('add-question-field')), 'do');
      await tester.enterText(find.byKey(const Key('add-answer-field')), 'did');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.text, '$_table| do | did |\n');
      expect(find.byKey(const Key('deck-row-do')), findsOneWidget);
      expect(_counts(tester), '0 due · 4 new · 4 cards');
    });

    testWidgets('the right-click menu deletes a row', (tester) async {
      final host = await _show(tester, _table);
      await tester.tap(
        find.byKey(const Key('deck-row-choose')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.actionDelete));
      await tester.pumpAndSettle();
      expect(host.text, _table.replaceFirst('| choose | chose |\n', ''));
    });

    testWidgets('an edit opens on the card as the note holds it now', (
      tester,
    ) async {
      const note = 'The ==cat== sat.\n';
      final host = await _show(tester, 'A long line above the cloze.\n\n$note');
      // The note shrank under the view, which still holds the old card.
      host.ahead = note;
      await _doubleTap(tester, find.byKey(const Key('deck-row-The […] sat.')));
      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(
        find.byKey(const Key('row-question-field')),
      );
      expect(field.controller!.text, 'The ==cat== sat.');
    });

    testWidgets('an edit of a card the note lost does not open', (
      tester,
    ) async {
      final host = await _show(tester, _table);
      host.ahead = _table.replaceFirst('| choose | chose |\n', '');
      await _doubleTap(tester, find.byKey(const Key('deck-row-choose')));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('row-question-field')), findsNothing);
    });

    testWidgets('a cloze is edited as its sentence', (tester) async {
      final host = await _show(tester, 'The ==cat== sat.\n');
      await _doubleTap(tester, find.byKey(const Key('deck-row-The […] sat.')));
      expect(find.byKey(const Key('row-answer-field')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('row-question-field')),
        'The ==dog== sat.',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.text, 'The ==dog== sat.\n');
    });
  });

  group('phone', () {
    testWidgets('three boxes, the questions and the two buttons', (
      tester,
    ) async {
      final states = {'begin': _state(-2), 'choose': _state(4)};
      await _show(
        tester,
        _table,
        size: _phone,
        states: states,
        study: (context, path) async {},
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('deck-stat-due')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('deck-stat-cards')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.text('begin'), findsOneWidget);
      expect(find.text('began'), findsOneWidget);
      expect(find.text('in 4 days'), findsOneWidget);
      expect(find.text('Study 2 cards'), findsOneWidget);
      expect(_studyEnabled(tester), isTrue);
      expect(find.byKey(const Key('deck-add-card')), findsOneWidget);
    });

    testWidgets('a long press opens the sheet; Save rewrites the row', (
      tester,
    ) async {
      final host = await _show(tester, _table, size: _phone);
      await tester.longPress(find.byKey(const Key('deck-row-choose')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.flashcardsEditCard), findsOneWidget);
      expect(find.text(AppStrings.flashcardsEditNote), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('card-sheet-answer')),
        'chose | chosen',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('card-sheet-save')));
      await tester.pumpAndSettle();
      expect(
        host.text,
        _table.replaceFirst('| chose |', r'| chose \| chosen |'),
      );
      expect(find.byKey(const Key('card-sheet-save')), findsNothing);
    });

    testWidgets('Delete removes the row', (tester) async {
      final host = await _show(tester, _table, size: _phone);
      await tester.longPress(find.byKey(const Key('deck-row-begin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('card-sheet-delete')));
      await tester.pumpAndSettle();
      expect(host.text, _table.replaceFirst('| begin | began |\n', ''));
      expect(find.byKey(const Key('deck-row-begin')), findsNothing);
    });

    testWidgets('Save lands on the card even if the note moved under it', (
      tester,
    ) async {
      final host = await _show(tester, _table, size: _phone);
      await tester.longPress(find.byKey(const Key('deck-row-choose')));
      await tester.pumpAndSettle();
      // A sync pull adds a row above the card while the sheet is open.
      final pulled = _table.replaceFirst(
        '| begin | began |\n',
        '| be | was |\n| begin | began |\n',
      );
      host.note.value = pulled;
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('card-sheet-answer')),
        'chosen',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('card-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.text, pulled.replaceFirst('| chose |', '| chosen |'));
    });

    testWidgets('Delete does nothing if the note lost the card meanwhile', (
      tester,
    ) async {
      final host = await _show(tester, _table, size: _phone);
      await tester.longPress(find.byKey(const Key('deck-row-choose')));
      await tester.pumpAndSettle();
      final pulled = _table.replaceFirst('| choose | chose |\n', '');
      host.note.value = pulled;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('card-sheet-delete')));
      await tester.pumpAndSettle();
      expect(host.text, pulled);
    });

    testWidgets('Save is off while the question is empty', (tester) async {
      await _show(tester, _table, size: _phone);
      await tester.longPress(find.byKey(const Key('deck-row-begin')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card-sheet-question')), '');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('card-sheet-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Add card opens the sheet empty and Save appends', (
      tester,
    ) async {
      final host = await _show(tester, _table, size: _phone);
      await tester.tap(find.byKey(const Key('deck-add-card')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('card-sheet-delete')))
            .onPressed,
        isNull,
        reason: 'Delete keeps its place, with nothing to delete',
      );
      await tester.enterText(
        find.byKey(const Key('card-sheet-question')),
        'do',
      );
      await tester.enterText(find.byKey(const Key('card-sheet-answer')), 'did');
      await tester.pump();
      await tester.tap(find.byKey(const Key('card-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.text, '$_table| do | did |\n');
    });

    testWidgets('the sheet opens on the card as the note holds it now', (
      tester,
    ) async {
      const note = 'The ==cat== sat.\n';
      final host = await _show(
        tester,
        'A long line above the cloze.\n\n$note',
        size: _phone,
      );
      host.ahead = note;
      await tester.longPress(find.byKey(const Key('deck-row-The […] sat.')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(
        find.byKey(const Key('card-sheet-question')),
      );
      expect(field.controller!.text, 'The ==cat== sat.');
    });

    testWidgets('the sheet of a card the note lost does not open', (
      tester,
    ) async {
      final host = await _show(tester, _table, size: _phone);
      host.ahead = _table.replaceFirst('| choose | chose |\n', '');
      await tester.longPress(find.byKey(const Key('deck-row-choose')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('card-sheet-question')), findsNothing);
    });

    testWidgets('a cloze has one field, its sentence', (tester) async {
      final host = await _show(tester, 'The ==cat== sat.\n', size: _phone);
      await tester.longPress(find.byKey(const Key('deck-row-The […] sat.')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('card-sheet-answer')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('card-sheet-question')),
        'A ==cat== sat.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('card-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.text, 'A ==cat== sat.\n');
    });
  });
}
