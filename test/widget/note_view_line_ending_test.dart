// The open note writes its file's own line ending back (#1056): the buffer
// holds LF, the file keeps what it had.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

void main() {
  Future<List<String>> typeInto(
    WidgetTester tester,
    String onDisk, {
    int reloadToken = 0,
  }) async {
    final writes = <String>[];
    await tester.pumpWidget(
      _app(
        NoteView(
          path: '/notes/a.md',
          showLineNumbers: false,
          autofocusEditor: false,
          readNote: (_) async => onDisk,
          writeNote: (_, text) async => writes.add(text),
          reloadToken: reloadToken,
        ),
      ),
    );
    await tester.pump();
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .replaceText(0, 0, 'X');
    await tester.pump(const Duration(seconds: 2));
    return writes;
  }

  testWidgets('a CRLF note is saved as CRLF', (tester) async {
    final writes = await typeInto(tester, '# Hello\r\nworld\r\n');
    expect(writes, ['X# Hello\r\nworld\r\n']);
  });

  testWidgets('an LF note is saved as LF', (tester) async {
    final writes = await typeInto(tester, '# Hello\nworld\n');
    expect(writes, ['X# Hello\nworld\n']);
  });

  testWidgets('a note adopted from disk keeps the ending it came with', (
    tester,
  ) async {
    var disk = '# Hello\nworld\n';
    final writes = <String>[];
    Widget app(int token) => _app(
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: false,
        autofocusEditor: false,
        readNote: (_) async => disk,
        writeNote: (_, text) async => writes.add(text),
        reloadToken: token,
      ),
    );
    await tester.pumpWidget(app(0));
    await tester.pump();
    // Another program rewrites the file with CRLF lines.
    disk = '# Hello\r\nthere\r\n';
    await tester.pumpWidget(app(1));
    await tester.pump();
    await tester.pump();
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .replaceText(0, 0, 'X');
    await tester.pump(const Duration(seconds: 2));
    expect(writes, ['X# Hello\r\nthere\r\n']);
  });
}
