// The note view's statistics on the unified surface (docs/records/huge-notes.md,
// item 2): the word count follows the edits and the outline comes off the
// pane's own scan — neither joins the note, and neither waits for a scan of
// it to be asked again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';

const String _note = '# Alpha\n\none two\n\n## Beta\n\nthree\n';

/// The words of [text] as the note counts them: its text, not its Markdown
/// syntax (#1051), counted whole.
int _wordsOf(String text) => WordCount.of(SourceBuffer.fromText(text)).words;

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

/// The count the status row is showing.
String _shownWords(WidgetTester tester) {
  final text = tester.widgetList<Text>(find.textContaining('words')).first.data;
  expect(text, isNotNull);
  return text!;
}

void main() {
  setUp(() => NoteView.statsDelayOverride = Duration.zero);
  tearDown(() => NoteView.statsDelayOverride = null);

  testWidgets('the word count follows the edits', (tester) async {
    await tester.pumpWidget(
      _app(
        NoteView(
          path: '/notes/stats.md',
          showLineNumbers: false,
          autofocusEditor: false,
          readNote: (_) async => _note,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MarkdownSourceView), findsOneWidget);

    // The pane shows the note; the count is the note's, read off the blocks
    // the surface holds rather than by walking the text again.
    final surface = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    expect(surface.lineCount, 8);

    // Type one word at the end of the first line: the count follows it.
    final buffer = surface.widget.buffer;
    surface.placeCaret(buffer.offsetOfLine(0) + buffer.lineAt(0).length);
    await tester.pump();
    surface.replaceText(
      buffer.offsetOfLine(0) + buffer.lineAt(0).length,
      buffer.offsetOfLine(0) + buffer.lineAt(0).length,
      ' extra',
    );
    await tester.pumpAndSettle();
    expect(buffer.text, contains('# Alpha extra'));
    expect(
      surface.widget.surface!.words.isCounted,
      isTrue,
      reason: 'the counter is built before an edit can follow it',
    );
    expect(surface.widget.surface!.words.words, _wordsOf(buffer.text));
    expect(_shownWords(tester), contains(_wordsOf(buffer.text).toString()));
  });

  testWidgets('an edit inside a line does not move the count of the note', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        NoteView(
          path: '/notes/stats.md',
          showLineNumbers: false,
          autofocusEditor: false,
          readNote: (_) async => _note,
        ),
      ),
    );
    await tester.pump();
    final surface = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    final buffer = surface.widget.buffer;
    final before = _wordsOf(buffer.text);

    // A new line inside the paragraph: two words become three lines of one
    // word each, and the note's word count must not drift.
    final at = buffer.offsetOfLine(2) + 'one'.length;
    surface.replaceText(at, at, '\n');
    await tester.pumpAndSettle();
    expect(_shownWords(tester), contains(before.toString()));
  });

  testWidgets(
    'a big note gets its count and outline once they are worked out',
    (tester) async {
      // Past the size counted in place, and past the lines the pane scans in
      // place: both answers come from an isolate, after the refresh that asked.
      MarkdownSourceViewState.backgroundLines = 100;
      addTearDown(() => MarkdownSourceViewState.backgroundLines = 50000);
      final note = StringBuffer('# Alpha\n\n');
      for (var i = 0; i < 3000; i++) {
        note.writeln('one two three four five six seven eight nine ten');
      }
      note.write('\n## Beta\n\nlast words\n');
      final text = note.toString();
      final key = GlobalKey<State<NoteView>>();
      expect(text.length, greaterThan(64 * 1024));
      await tester.pumpWidget(
        _app(
          NoteView(
            key: key,
            path: '/notes/big.md',
            showLineNumbers: false,
            autofocusEditor: false,
            readNote: (_) async => text,
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 1));
      }
      final view = key.currentState! as NoteViewHandle;
      expect(view.outline.value.map((e) => e.text), <String>['Alpha', 'Beta']);
      expect(_shownWords(tester), contains(_wordsOf(text).toString()));
    },
  );

  // The log of 2026-10-20: a note with no headings, then a big one with many.
  // The outline was asked for as the big note loaded, when the panes still
  // drew the note before it, and their empty outline was taken as the big
  // note's — for good, since nothing asked again until an edit — so every
  // `[[#heading]]` in it said the heading was not there.
  for (final preview in <bool>[false, true]) {
    testWidgets('a note opened after another gets its own outline'
        '${preview ? ' (preview shown)' : ''}', (tester) async {
      final big = StringBuffer('# Alpha\n\n');
      for (var i = 0; i < 1500; i++) {
        big.writeln('one two three four five six seven eight nine ten');
      }
      big.write('\n## Beta\n\nlast words\n');
      final text = big.toString();
      expect(text.length, greaterThan(64 * 1024));
      final notes = <String, String>{
        '/notes/plain.md': 'no headings here\n',
        '/notes/big.md': text,
      };
      final key = GlobalKey<State<NoteView>>();
      Widget at(String path) => _app(
        NoteView(
          key: key,
          path: path,
          showLineNumbers: false,
          showPreview: preview,
          autofocusEditor: false,
          readNote: (path) async => notes[path]!,
        ),
      );
      await tester.pumpWidget(at('/notes/plain.md'));
      await tester.pumpAndSettle();
      final view = key.currentState! as NoteViewHandle;
      expect(view.outline.value, isEmpty);

      await tester.pumpWidget(at('/notes/big.md'));
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(view.outline.value.map((e) => e.text), <String>['Alpha', 'Beta']);
    });
  }

  // Every note opens at revision 0: the revision alone took the note just
  // opened for the one before it, and kept that one's outline.
  testWidgets('a small note opened after another gets its own outline', (
    tester,
  ) async {
    final notes = <String, String>{
      '/notes/one.md': '# Uno\n\ntext\n',
      '/notes/two.md': '# Due\n\ntext\n',
    };
    final key = GlobalKey<State<NoteView>>();
    Widget at(String path) => _app(
      NoteView(
        key: key,
        path: path,
        showLineNumbers: false,
        autofocusEditor: false,
        readNote: (path) async => notes[path]!,
      ),
    );
    await tester.pumpWidget(at('/notes/one.md'));
    await tester.pumpAndSettle();
    final view = key.currentState! as NoteViewHandle;
    expect(view.outline.value.map((e) => e.text), <String>['Uno']);

    await tester.pumpWidget(at('/notes/two.md'));
    await tester.pumpAndSettle();
    expect(view.outline.value.map((e) => e.text), <String>['Due']);
  });
}
