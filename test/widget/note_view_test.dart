import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view({
  required String path,
  Future<String> Function(String)? readNote,
  Future<void> Function(String, String)? writeNote,
  CodeLineEditingController? controller,
  bool showLineNumbers = true,
  bool autofocusEditor = false,
}) => NoteView(
  showLineNumbers: showLineNumbers,
  autofocusEditor: autofocusEditor,
  path: path,
  readNote: readNote,
  writeNote: writeNote,
  controller: controller,
);

String _editorText(WidgetTester tester) =>
    tester.widget<NoteEditor>(find.byType(NoteEditor)).controller.text;

void main() {
  group('NoteView', () {
    testWidgets('loads the note file into the editor', (tester) async {
      String? readPath;
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (p) async {
              readPath = p;
              return '# Hello\r\nworld';
            },
          ),
        ),
      );
      await tester.pump(); // let the async load land.
      expect(readPath, '/notes/a.md');
      expect(find.byType(NoteEditor), findsOneWidget);
      // CRLF is normalized to LF on load.
      expect(_editorText(tester), '# Hello\nworld');
      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('autosaves ~500 ms after the last edit', (tester) async {
      final writes = <String>[];
      final controller = CodeLineEditingController.fromText('start');
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      controller.text = 'start!';
      await tester.pump();
      expect(writes, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, ['start!']);
      expect(find.text('saved'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('a selection-only change does not schedule a save', (
      tester,
    ) async {
      final writes = <String>[];
      final controller = CodeLineEditingController.fromText('start');
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      controller.selection = const CodeLineSelection.collapsed(
        index: 0,
        offset: 1,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, isEmpty);
      controller.dispose();
    });

    testWidgets('the line-numbers toggle reaches the editor', (tester) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            showLineNumbers: false,
          ),
        ),
      );
      await tester.pump();
      final editor = tester.widget<NoteEditor>(find.byType(NoteEditor));
      expect(editor.showLineNumbers, isFalse);
    });

    testWidgets('the keyboard-on-open toggle reaches the editor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            autofocusEditor: true,
          ),
        ),
      );
      await tester.pump(); // let the load land; autofocus takes effect.
      final editor = tester.widget<NoteEditor>(find.byType(NoteEditor));
      expect(editor.autofocus, isTrue);
      // Let the focus-driven cursor-blink timer lapse (re_editor schedules
      // a 100 ms one-shot on Android) so none is pending at teardown.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
    });

    testWidgets('saves on dispose when the debounce has not fired', (
      tester,
    ) async {
      final writes = <String>[];
      final controller = CodeLineEditingController.fromText('start');
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      controller.text = 'start!';
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      expect(writes, ['start!']);
      controller.dispose();
    });
  });
}
