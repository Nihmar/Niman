import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:path/path.dart' as p;

/// External-change reloads (home-screen widget toggles edit the note in
/// a background isolate): the shell bumps `reloadToken` when the
/// already-open note may have changed on disk, and the view re-reads
/// the file only when its buffer is clean.
Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view({
  required String path,
  required Future<String> Function(String) readNote,
  Future<void> Function(String, String)? writeNote,
  int reloadToken = 0,
}) => NoteView(
  path: path,
  showLineNumbers: true,
  autofocusEditor: false,
  readNote: readNote,
  writeNote: writeNote,
  reloadToken: reloadToken,
);

MarkdownSourceViewState _surface(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

String _editorText(WidgetTester tester) => _surface(tester).widget.buffer.text;

void main() {
  // The gate in front of the read (docs/dev/huge-notes.md item 4): a watcher
  // reports that something happened to a path, and a reload asks the file
  // what it looks like before it reads it. These two use a real file, since
  // the read they are about is the real one — `readNote` is null and the view
  // reads through the same path production does.
  group('NoteView reload gate', () {
    late Directory dir;
    late String path;

    setUp(() async {
      dir = await Directory.current.createTemp('niman_reload_');
      path = p.join(dir.path, 'note.md');
    });

    tearDown(() => dir.delete(recursive: true));

    testWidgets('a bump with the file untouched does not read it again', (
      tester,
    ) async {
      File(path).writeAsStringSync('one two three');
      await tester.pumpWidget(
        _app(
          NoteView(path: path, showLineNumbers: false, autofocusEditor: false),
        ),
      );
      // The real read is an isolate: give it its turn.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(MarkdownSourceView), findsOneWidget);
      final buffer = tester
          .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
          .widget
          .buffer;
      expect(buffer.text, 'one two three');
      // The test's own edit: what is on screen is not what is on disk, and a
      // reload that actually read would replace it.
      final at = buffer.length;
      buffer.insert(at, ' AND MORE');
      await tester.pump();

      await tester.pumpWidget(
        _app(
          NoteView(
            path: path,
            showLineNumbers: false,
            autofocusEditor: false,
            reloadToken: 1,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(
        buffer.text,
        'one two three AND MORE',
        reason: 'the file did not change, so nothing was read',
      );
    });

    testWidgets('a bump after the file changed adopts it', (tester) async {
      File(path).writeAsStringSync('one two three');
      await tester.pumpWidget(
        _app(
          NoteView(path: path, showLineNumbers: false, autofocusEditor: false),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await tester.pump();

      // A different size and a new time: what a real external write looks
      // like, and what the gate has to let through.
      File(path).writeAsStringSync('changed on disk, and longer');
      await tester.pumpWidget(
        _app(
          NoteView(
            path: path,
            showLineNumbers: false,
            autofocusEditor: false,
            reloadToken: 1,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      final buffer = tester
          .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
          .widget
          .buffer;
      expect(buffer.text, 'changed on disk, and longer');
    });
  });

  group('NoteView reloadToken', () {
    testWidgets('a token bump re-reads the file when clean', (tester) async {
      var disk = '- [ ] one';
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => disk,
            writeNote: (_, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      expect(_editorText(tester), '- [ ] one');

      // A widget toggle flips the box on disk; the shell reopens the
      // already-open note, bumping the token.
      disk = '- [x] one';
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => disk,
            writeNote: (_, c) async => writes.add(c),
            reloadToken: 1,
          ),
        ),
      );
      await tester.pump();
      expect(_editorText(tester), '- [x] one');
      // The adopted disk text is clean: no save of identical content.
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, isEmpty);
    });

    testWidgets('unsaved edits win over the disk', (tester) async {
      var disk = '- [ ] one';
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => disk,
            writeNote: (_, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      _surface(tester).replaceText(9, 9, ' (typed)');
      await tester.pump();
      disk = '- [x] one';

      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => disk,
            writeNote: (_, c) async => writes.add(c),
            reloadToken: 1,
          ),
        ),
      );
      await tester.pump();
      // The user's edit survives; the debounced save persists it.
      expect(_editorText(tester), '- [ ] one (typed)');
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, ['- [ ] one (typed)']);
    });

    testWidgets('identical content is a no-op', (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async {
              reads++;
              return 'same';
            },
          ),
        ),
      );
      await tester.pump();
      expect(_editorText(tester), 'same');

      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async {
              reads++;
              return 'same';
            },
            reloadToken: 1,
          ),
        ),
      );
      await tester.pump();
      expect(reads, 2);
      expect(_editorText(tester), 'same');
      expect(find.text('Saved'), findsOneWidget);
    });
  });
}
