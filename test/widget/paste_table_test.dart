// #1248: cells copied from a spreadsheet and pasted into a note go in as a
// Markdown table, on lines of their own, and the snackbar's Paste as text
// puts the clipboard's text back; in code, and for text that is no table,
// a paste is the plain text it always was.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_editor_options.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';

const String _cells = 'Name\tQty\r\nApples\t3\r\nPears\t12\r\n';

const String _table =
    '| Name | Qty |\n'
    '| --- | --- |\n'
    '| Apples | 3 |\n'
    '| Pears | 12 |';

void main() {
  late String? clipboard;

  setUp(() => clipboard = _cells);

  Future<void> open(WidgetTester tester, String note) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => switch (call.method) {
        'Clipboard.getData' =>
          clipboard == null ? null : <String, dynamic>{'text': clipboard},
        _ => null,
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/notes/stock.md',
            options: const NoteEditorOptions(
              showLineNumbers: false,
              autofocusEditor: true,
            ),
            toolbarTop: true,
            services: NoteServices(
              readNote: (_) async => note,
              writeNote: (_, _) async {},
              // No files on the clipboard: the platform's reader is a channel
              // whose answer the fake clock never brings (#1249).
              readClipboardFiles: () async => const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MarkdownSourceViewState editor(WidgetTester tester) =>
      tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

  Future<void> pasteAt(WidgetTester tester, int offset) async {
    editor(tester).placeCaret(offset);
    await tester.pump();
    await editor(tester).paste();
    await tester.pumpAndSettle();
  }

  testWidgets('the cells go in as a table, apart from the text around it', (
    tester,
  ) async {
    await open(tester, 'Stock: \nNext.');
    await pasteAt(tester, 'Stock: '.length);

    expect(editor(tester).widget.buffer.text, 'Stock: \n\n$_table\n\nNext.');
    expect(find.text(AppStrings.pastedAsTable), findsOne);

    await tester.tap(find.text(AppStrings.pasteAsText));
    await tester.pumpAndSettle();
    expect(
      editor(tester).widget.buffer.text,
      'Stock: Name\tQty\nApples\t3\nPears\t12\n\nNext.',
      reason: "what a plain paste puts there, line endings the note's",
    );
  });

  testWidgets('on a blank line between paragraphs no blank line is added', (
    tester,
  ) async {
    await open(tester, 'Above.\n\n\n\nBelow.');
    await pasteAt(tester, 'Above.\n\n'.length);
    expect(editor(tester).widget.buffer.text, 'Above.\n\n$_table\n\nBelow.');
  });

  testWidgets('one undo takes the table out', (tester) async {
    await open(tester, '');
    await pasteAt(tester, 0);
    expect(editor(tester).widget.buffer.text, _table);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(editor(tester).widget.buffer.text, '');
  });

  testWidgets('inside a code fence the cells stay text', (tester) async {
    await open(tester, '```\n\n```\n');
    await pasteAt(tester, '```\n'.length);
    expect(
      editor(tester).widget.buffer.text,
      '```\nName\tQty\nApples\t3\nPears\t12\n\n```\n',
    );
    expect(find.text(AppStrings.pastedAsTable), findsNothing);
  });

  testWidgets('text that is no table pastes as it is', (tester) async {
    clipboard = 'Hello, world.\nYes, again.';
    await open(tester, '');
    await pasteAt(tester, 0);
    expect(editor(tester).widget.buffer.text, 'Hello, world.\nYes, again.');
    expect(find.text(AppStrings.pastedAsTable), findsNothing);
  });
}
