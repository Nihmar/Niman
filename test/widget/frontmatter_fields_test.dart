// The frontmatter fields panel (#157) as the app uses it: a `NoteView` with a
// note in it, the read pane on top. These drive it through `NoteView` and the
// note's own editor buffer — no widget class from the panel is imported — so
// they say what the panel does to the file, not how it is built.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/parser.dart';
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

/// A note view over [note], the read pane showing.
Widget _app(String note) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/tmp/niman-frontmatter-panel-test.md',
      showLineNumbers: true,
      autofocusEditor: false,
      showPreview: true,
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
      reason: 'the read pane shows the note frontmatter as fields',
    );

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

    // Change the date: it stays a bare date, read back as one.
    await tester.tap(find.byKey(const Key('frontmatter-value-date')));
    await tester.pumpAndSettle();
    await _fillField(tester, value: '2026-10-02');

    expect(_text(tester), contains('date: 2026-10-02\n'));
    expect(parseFrontmatter(_text(tester))!.date, DateTime(2026, 10, 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a field takes its line out', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

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

    expect(find.byKey(const Key('frontmatter-panel-error')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-raw')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-toggle-pinned')), findsNothing);
    expect(find.byKey(const Key('frontmatter-add')), findsNothing);
    // Nothing the panel draws changed the note.
    expect(_text(tester), malformed);
    await tester.pumpAndSettle();
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
