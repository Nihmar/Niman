// The note view's statistics on the unified surface (docs/dev/huge-notes.md,
// item 2): the word count follows the edits and the outline comes off the
// pane's own scan — neither joins the note, and neither waits for a scan of
// it to be asked again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

const String _note = '# Alpha\n\none two\n\n## Beta\n\nthree\n';

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
          unifiedMarkdown: true,
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
    expect(surface.widget.surface!.words.words, countWords(buffer.text));
    expect(_shownWords(tester), contains(countWords(buffer.text).toString()));
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
          unifiedMarkdown: true,
          readNote: (_) async => _note,
        ),
      ),
    );
    await tester.pump();
    final surface = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    final buffer = surface.widget.buffer;
    final before = countWords(buffer.text);

    // A new line inside the paragraph: two words become three lines of one
    // word each, and the note's word count must not drift.
    final at = buffer.offsetOfLine(2) + 'one'.length;
    surface.replaceText(at, at, '\n');
    await tester.pumpAndSettle();
    expect(_shownWords(tester), contains(before.toString()));
  });
}
