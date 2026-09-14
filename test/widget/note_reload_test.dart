import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

/// External-change reloads (home-screen widget toggles edit the note in
/// a background isolate): the shell bumps `reloadToken` when the
/// already-open note may have changed on disk, and the view re-reads
/// the file only when its buffer is clean.
Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view({
  required String path,
  required Future<String> Function(String) readNote,
  Future<void> Function(String, String)? writeNote,
  CodeLineEditingController? controller,
  int reloadToken = 0,
}) => NoteView(
  path: path,
  showLineNumbers: true,
  autofocusEditor: false,
  readNote: readNote,
  writeNote: writeNote,
  controller: controller,
  reloadToken: reloadToken,
);

String _editorText(WidgetTester tester) =>
    tester.widget<NoteEditor>(find.byType(NoteEditor)).controller.text;

void main() {
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
      final controller = CodeLineEditingController.fromText('start');
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => disk,
            writeNote: (_, c) async => writes.add(c),
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      controller.text = '- [ ] one (typed)';
      await tester.pump();
      disk = '- [x] one';

      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => disk,
            writeNote: (_, c) async => writes.add(c),
            controller: controller,
            reloadToken: 1,
          ),
        ),
      );
      await tester.pump();
      // The user's edit survives; the debounced save persists it.
      expect(_editorText(tester), '- [ ] one (typed)');
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, ['- [ ] one (typed)']);
      controller.dispose();
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
      expect(find.text('saved'), findsOneWidget);
    });
  });
}
