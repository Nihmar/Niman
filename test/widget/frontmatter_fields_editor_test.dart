// The frontmatter fields panel (#157) in the **live editor**: the same rows
// the read pane shows, at the top of the editor, above the note's first line.
// These drive the editor through `NoteView` and the note's own buffer — no
// widget class from the panel is imported — so they say what the panel does to
// the file, not how it is built. The read pane's own cases are in
// `frontmatter_fields_test.dart`; together the two hold that one widget serves
// both surfaces.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

/// The note the editor is handed.
const String _note =
    '---\n'
    'title: Enciclopedia\n'
    'tags: [Celestia, worldbuilding]\n'
    'date: 2026-09-01\n'
    'pinned: false\n'
    '---\n'
    '\n'
    'Body text.\n';

/// A note view over [note] with the **editor** on stage, not the read pane.
Widget _app(String note) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/tmp/niman-frontmatter-editor-test.md',
      showLineNumbers: true,
      autofocusEditor: false,
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
  testWidgets('the editor shows the same rows above the note', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('frontmatter-fields')),
      findsOneWidget,
      reason: 'the live editor shows the note frontmatter as fields',
    );
    // One row per key, the key's own type chip, and the add row last.
    expect(find.byKey(const Key('frontmatter-field-title')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-type-title')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-field-pinned')), findsOneWidget);
    expect(find.byKey(const Key('frontmatter-add')), findsOneWidget);
    // The note's own first line is still there, under the panel.
    expect(_text(tester), _note);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a field edit in the editor writes the note', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('frontmatter-value-title')));
    await tester.pumpAndSettle();
    await _fillField(tester, value: 'Nuova');

    final parsed = parseFrontmatter(_text(tester))!;
    expect(parsed.title, 'Nuova');
    expect(_text(tester), contains('title: Nuova\n'));

    // One edit, undoable like any other.
    final editor = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView, skipOffstage: false),
    );
    expect(editor.undo(), isTrue);
    expect(_text(tester), _note);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding and removing a field in the editor', (tester) async {
    await tester.pumpWidget(_app(_note));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pumpAndSettle();
    await _fillField(tester, key: 'people', type: 'list', value: 'Ada, Grace');

    expect(_text(tester), contains('people: [Ada, Grace]\n'));
    expect(parseFrontmatter(_text(tester))!.fields['people'], ['Ada', 'Grace']);
    expect(
      find.byKey(const Key('frontmatter-chip-people-Ada')),
      findsOneWidget,
      reason: 'a list is drawn as a list in the editor too',
    );

    await tester.tap(find.byKey(const Key('frontmatter-remove-pinned')));
    await tester.pumpAndSettle();
    expect(_text(tester), isNot(contains('pinned:')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the raw YAML is one toggle away in the editor', (tester) async {
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

    await tester.tap(find.byKey(const Key('frontmatter-raw-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('frontmatter-toggle-pinned')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a block the parser refuses shows no rows in the editor', (
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
    expect(find.byKey(const Key('frontmatter-add')), findsNothing);
    expect(find.byKey(const Key('frontmatter-toggle-pinned')), findsNothing);
    // Nothing the panel draws changed the note: the YAML is left as written.
    expect(_text(tester), malformed);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
