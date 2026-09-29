// The frontmatter fields panel (#157) as the app uses it: a `NoteView` with a
// note in it, the read pane on top. These drive it through `NoteView` and the
// note's own editor buffer — no widget class from the panel is imported — so
// they say what the panel does to the file, not how it is built.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

/// The note the pane is handed.
const String _note =
    '---\n'
    'title: Enciclopedia\n'
    'tags: [Celestia, worldbuilding]\n'
    'date: 2026-09-01\n'
    'pinned: false\n'
    '---\n'
    '\n'
    'Body text.\n';

/// A note view over [note], the read pane showing, with the library's
/// properties-panel setting ([panel]).
Widget _app(String note, {bool panel = true}) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/tmp/niman-frontmatter-panel-test.md',
      showLineNumbers: true,
      autofocusEditor: false,
      showPreview: true,
      frontmatterPanel: panel,
      readNote: (_) async => note,
      writeNote: (_, _) async {},
    ),
  ),
);

/// The note as the editor holds it now.
String _text(WidgetTester tester) => tester
    .state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView, skipOffstage: false),
    )
    .widget
    .buffer
    .text;

/// Opens the field dialog and fills it in.
Future<void> _fillField(
  WidgetTester tester, {
  String? key,
  String? type,
  String? value,
}) async {
  if (key != null) {
    await tester.enterText(find.byKey(const Key('frontmatter-key-field')), key);
  }
  if (type != null) {
    await tester.tap(find.byKey(const Key('frontmatter-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(type).last);
    await tester.pumpAndSettle();
  }
  if (value != null) {
    await tester.enterText(
      find.byKey(const Key('frontmatter-value-field')),
      value,
    );
  }
  await tester.tap(find.byKey(const Key('frontmatter-save')));
  await tester.pumpAndSettle();
}

/// Opens the fields panel through its handle: the panel opens closed (#157).
Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('frontmatter-collapse-toggle')));
  await tester.pumpAndSettle();
}

/// Scrolls the read pane to [offset], so a case can drive the note past its
/// head and back without a gesture.
Future<void> _scrollReadPane(WidgetTester tester, double offset) async {
  tester
      .widget<MarkdownReadView>(find.byType(MarkdownReadView))
      .controller!
      .jumpTo(offset);
  await tester.pumpAndSettle();
}

/// Picks day [day] in the picker a date field opens (#157).
///
/// The dialog seeds the picker with the date the field was written with, so
/// the month it shows is that date's own.
Future<void> _pickDay(WidgetTester tester, int day) async {
  await tester.tap(find.byKey(const Key('frontmatter-date-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a field edit writes the YAML the parser reads back', (
    tester,
  ) async {
    // The regression: before the panel there was no UI at all, so the panel
    // and the edit below are both new.
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('frontmatter-fields')),
      findsOneWidget,
      reason: 'the read pane shows the note frontmatter as a panel',
    );
    // Closed on opening the note: the rows are a tap away (#157).
    expect(find.byKey(const Key('frontmatter-value-title')), findsNothing);
    await _openPanel(tester);
    expect(find.byKey(const Key('frontmatter-value-title')), findsOneWidget);

    // A text field: tap the value, change it, save.
    await tester.tap(find.byKey(const Key('frontmatter-value-title')));
    await tester.pumpAndSettle();
    await _fillField(tester, value: 'Nuova');

    final parsed = parseFrontmatter(_text(tester))!;
    expect(parsed.title, 'Nuova');
    expect(parsed.fields['title'], ['Nuova']);
    expect(_text(tester), contains('title: Nuova\n'));

    // It is one edit, and it undoes like any other.
    final editor = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView, skipOffstage: false),
    );
    expect(editor.undo(), isTrue);
    expect(_text(tester), _note);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticking a boolean field writes the note', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();
    await _openPanel(tester);

    await tester.tap(find.byKey(const Key('frontmatter-toggle-pinned')));
    await tester.pumpAndSettle();

    expect(_text(tester), contains('pinned: true\n'));
    expect(parseFrontmatter(_text(tester))!.pinned, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new list stays a list and a date stays a date', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    await _openPanel(tester);

    // Add a list field: the panel draws it as chips, and the file keeps a
    // YAML list.
    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pumpAndSettle();
    await _fillField(tester, key: 'people', type: 'list', value: 'Ada, Grace');

    expect(_text(tester), contains('people: [Ada, Grace]\n'));
    expect(parseFrontmatter(_text(tester))!.fields['people'], ['Ada', 'Grace']);
    expect(
      find.byKey(const Key('frontmatter-chip-people-Ada')),
      findsOneWidget,
      reason: 'a list is drawn as a list',
    );

    // Change the date: a date is picked, not typed (#157), and the file
    // keeps a bare date the parser reads back as one.
    await tester.tap(find.byKey(const Key('frontmatter-value-date')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('frontmatter-value-field')),
      findsNothing,
      reason: 'a date field asks for a date, not for a string',
    );
    await _pickDay(tester, 2);
    await tester.tap(find.byKey(const Key('frontmatter-save')));
    await tester.pumpAndSettle();

    expect(_text(tester), contains('date: 2026-09-02\n'));
    expect(parseFrontmatter(_text(tester))!.date, DateTime(2026, 9, 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // Deleting a chip rewrites the list around it: the chip deleted was the
  // only change — an equal chip beside it, a number, an item holding a
  // comma all come through as they were.
  testWidgets('deleting a chip changes nothing else in the list', (
    tester,
  ) async {
    const note =
        '---\n'
        'ids: [1, 2, 1]\n'
        'authors: ["Doe, J", "Roe, K", x]\n'
        '---\n'
        '\n'
        'Body text.\n';
    await tester.pumpWidget(_app(note));
    await tester.pumpAndSettle();

    await _openPanel(tester);

    void delete(String key) =>
        tester.widget<InputChip>(find.byKey(Key(key))).onDeleted!();

    delete('frontmatter-chip-ids-2');
    await tester.pumpAndSettle();
    expect(_text(tester), contains('ids: [1, 1]\n'));
    expect(parseFrontmatter(_text(tester))!.fields['ids'], ['1', '1']);

    // The second of two equal chips is a chip of its own.
    delete('frontmatter-chip-ids-1-2');
    await tester.pumpAndSettle();
    expect(_text(tester), contains('ids: [1]\n'));

    delete('frontmatter-chip-authors-x');
    await tester.pumpAndSettle();
    expect(_text(tester), contains('authors: ["Doe, J", "Roe, K"]\n'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a field saved as it was shown leaves the note alone', (
    tester,
  ) async {
    const note =
        '---\n'
        'version: 1.10\n'
        'desc: |\n'
        '  line one\n'
        '  line two\n'
        'authors: ["Doe, J", x]\n'
        '---\n'
        '\n'
        'Body text.\n';
    await tester.pumpWidget(_app(note));
    await tester.pumpAndSettle();

    await _openPanel(tester);

    for (final opener in [
      'frontmatter-value-version',
      'frontmatter-value-desc',
      'frontmatter-add-item-authors',
    ]) {
      await tester.tap(find.byKey(Key(opener)));
      await tester.pumpAndSettle();
      await _fillField(tester);
      expect(_text(tester), note, reason: opener);
    }

    // And a list edited in the editor keeps an item's comma inside it.
    await tester.tap(find.byKey(const Key('frontmatter-add-item-authors')));
    await tester.pumpAndSettle();
    await _fillField(tester, value: '"Doe, J", x, "Roe, K"');
    expect(_text(tester), contains('authors: ["Doe, J", x, "Roe, K"]\n'));
    expect(parseFrontmatter(_text(tester))!.fields['authors'], [
      'Doe, J',
      'x',
      'Roe, K',
    ]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a field takes its line out', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    await _openPanel(tester);

    await tester.tap(find.byKey(const Key('frontmatter-remove-pinned')));
    await tester.pumpAndSettle();

    expect(_text(tester), isNot(contains('pinned:')));
    expect(parseFrontmatter(_text(tester))!.pinned, isFalse);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the raw YAML is one toggle away', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();
    await _openPanel(tester);
    expect(find.byKey(const Key('frontmatter-toggle-pinned')), findsOneWidget);

    await tester.tap(find.byKey(const Key('frontmatter-raw-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('frontmatter-raw')), findsOneWidget);
    expect(
      find.byKey(const Key('frontmatter-toggle-pinned')),
      findsNothing,
      reason: 'the fields give way to the source they were read from',
    );
    expect(find.textContaining('title: Enciclopedia'), findsWidgets);

    await tester.tap(find.byKey(const Key('frontmatter-raw-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('frontmatter-toggle-pinned')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a block the parser refuses shows raw, and is left alone', (
    tester,
  ) async {
    const malformed =
        '---\n'
        'title: [unclosed\n'
        '---\n'
        '\n'
        'Body text.\n';
    await tester.pumpWidget(_app(malformed));
    await tester.pumpAndSettle();
    await _openPanel(tester);

    expect(find.byKey(const Key('frontmatter-panel-error')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-raw')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-toggle-pinned')), findsNothing);
    expect(find.byKey(const Key('frontmatter-add')), findsNothing);
    // Nothing the panel draws changed the note.
    expect(_text(tester), malformed);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // The panel is the note's head (#157): one row of chrome on opening the
  // note, the fields behind the handle.
  testWidgets('the panel opens closed, and the handle opens and closes it', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('frontmatter-fields')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-value-title')), findsNothing);
    expect(
      find.byKey(const Key('frontmatter-add')),
      findsOneWidget,
      reason: 'the panel’s one action is there on a closed panel too',
    );
    expect(find.byKey(const Key('frontmatter-raw-toggle')), findsNothing);

    await _openPanel(tester);
    expect(find.byKey(const Key('frontmatter-value-title')), findsOneWidget);
    expect(
      find.byKey(const Key('frontmatter-raw-toggle')),
      findsOneWidget,
      reason: 'the raw toggle belongs to the body it switches',
    );

    await _openPanel(tester);
    expect(find.byKey(const Key('frontmatter-fields')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-value-title')), findsNothing);
    expect(find.byKey(const Key('frontmatter-add')), findsOneWidget);
    expect(_text(tester), _note, reason: 'closing the panel edits nothing');
    expect(tester.takeException(), isNull);
  });

  // A note read to its end: the panel belongs to the head, and away from the
  // head it takes no room at all (#157).
  testWidgets('scrolling the note past its head puts the panel away', (
    tester,
  ) async {
    final long =
        '---\n'
        'title: Enciclopedia\n'
        '---\n'
        '\n'
        '${'Body text.\n' * 80}';
    await tester.pumpWidget(_app(long));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('frontmatter-fields')), findsOneWidget);

    await _scrollReadPane(tester, 200);
    expect(
      find.byKey(const Key('frontmatter-fields')),
      findsNothing,
      reason: 'the note left its head, and the panel left with it',
    );

    // Back at the head, the panel is back — as it was left: closed.
    await _scrollReadPane(tester, 0);
    expect(find.byKey(const Key('frontmatter-fields')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-value-title')), findsNothing);
    expect(find.byKey(const Key('frontmatter-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // A phone pane is narrower than any note column, so there is no column to
  // align to — and the panel used to run to the screen's own edge (device
  // report, 2026-09-29). It keeps the note's own inset instead.
  testWidgets('the panel keeps off the pane’s own edges', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    const pane = 360.0; // 1080 physical pixels at 3×.
    final panel = tester.getRect(find.byKey(const Key('frontmatter-fields')));
    expect(panel.left, NoteColumn.textInset);
    expect(panel.right, pane - NoteColumn.textInset);
    // And room over it: a box that touches the chrome above reads as part
    // of it, which is what the journal's day strip showed (2026-09-29).
    expect(panel.top, greaterThanOrEqualTo(12));
    expect(tester.takeException(), isNull);
  });

  // The library's own setting: a library that wants no panel gets none
  // (#157).
  testWidgets('the library setting hides the panel', (tester) async {
    await tester.pumpWidget(_app(_note, panel: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('frontmatter-fields')), findsNothing);
    expect(find.byKey(const Key('frontmatter-add')), findsNothing);
    expect(_text(tester), _note);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a note with no frontmatter shows no panel', (tester) async {
    await tester.pumpWidget(_app('Body only.\n'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('frontmatter-fields')), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
