import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/note_view.dart';
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

    // The preview has no editable: flipping the switch must dismiss the
    // keyboard instead of leaving it up over a read-only pane.
    testWidgets('flipping to preview dismisses the keyboard', (tester) async {
      var showPreview = false;
      late StateSetter flip;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                flip = setState;
                return NoteView(
                  path: '/notes/a.md',
                  showLineNumbers: false,
                  autofocusEditor: true,
                  showPreview: showPreview,
                  readNote: (_) async => 'hello',
                );
              },
            ),
          ),
        ),
      );
      await tester.pump(); // load lands, the editor mounts and autofocuses.
      await tester.pump();
      final editorFocus = tester
          .widget<NoteEditor>(find.byType(NoteEditor))
          .focusNode;
      expect(editorFocus.hasPrimaryFocus, isTrue);
      // Let the focus-driven blink one-shot lapse while the editor is
      // still mounted (re_editor never cancels it, so disposing the
      // editor first would fire it use-after-dispose).
      await tester.pump(const Duration(milliseconds: 200));
      expect(editorFocus.hasPrimaryFocus, isTrue);

      // Straight after the flip (the fade has not advanced, so the editor
      // is still mounted): the IME target is already gone.
      flip(() => showPreview = true);
      await tester.pump();
      expect(editorFocus.hasPrimaryFocus, isFalse);
      // Step past the fade in small frames: the fade disposes the editor
      // at 180 ms, leaving no timer pending at teardown.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    });

    // Opening straight into the preview must dismiss an existing focus
    // once the load lands (e.g. the search field behind the new note).
    testWidgets('opening in preview dismisses an existing focus', (
      tester,
    ) async {
      final gate = Completer<String>();
      final fieldFocus = FocusNode();
      addTearDown(fieldFocus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: fieldFocus),
                Expanded(
                  child: NoteView(
                    path: '/notes/a.md',
                    showLineNumbers: false,
                    autofocusEditor: false,
                    showPreview: true,
                    readNote: (_) => gate.future,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(); // load pending behind the gate.
      fieldFocus.requestFocus();
      await tester.pump();
      expect(fieldFocus.hasFocus, isTrue);

      gate.complete('hello');
      await tester.pump();
      await tester.pump();
      expect(fieldFocus.hasFocus, isFalse);
    });

    testWidgets('the status icons breathe on desktop', (tester) async {
      // The test host is a desktop platform: each status icon stands off
      // its neighbours and the word count stands off the icons (user,
      // 2026-09-11). The phone keeps the row tight.
      await tester.pumpWidget(
        _app(_view(path: '/notes/a.md', readNote: (_) async => 'hello')),
      );
      await tester.pump();
      await tester.pump();
      final outline = find.byKey(const Key('outline-toggle'));
      final findButton = find.byKey(const Key('editor-find-open'));
      expect(outline, findsOneWidget);
      expect(findButton, findsOneWidget);
      expect(tester.getRect(outline).width, 40);
      final between =
          tester.getTopLeft(findButton).dx - tester.getTopRight(outline).dx;
      expect(between, 6);
      final words = find.text('1 words');
      expect(words, findsOneWidget);
      final afterFind =
          tester.getTopLeft(words).dx - tester.getTopRight(findButton).dx;
      expect(afterFind, 9);
    });
  });
}
