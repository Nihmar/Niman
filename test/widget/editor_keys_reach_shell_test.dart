// Issue #23: the tab keys work with the caret in either editor. The shell
// binds Ctrl+W, Ctrl+Tab, Ctrl+Shift+Tab and Ctrl+\ above the note; an
// editor that took them first would leave the tabs unreachable from the
// keyboard exactly where the hands are.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/note_view.dart';

void main() {
  for (final wysiwyg in [false, true]) {
    final editor = wysiwyg ? 'the WYSIWYG' : 'the source editor';
    testWidgets('the tab keys reach the shell from $editor', (tester) async {
      final hits = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallbackShortcuts(
              bindings: {
                const SingleActivator(
                  LogicalKeyboardKey.keyW,
                  control: true,
                ): () =>
                    hits.add('close'),
                const SingleActivator(
                  LogicalKeyboardKey.tab,
                  control: true,
                ): () =>
                    hits.add('next'),
                const SingleActivator(
                  LogicalKeyboardKey.tab,
                  control: true,
                  shift: true,
                ): () =>
                    hits.add('previous'),
                const SingleActivator(
                  LogicalKeyboardKey.backslash,
                  control: true,
                ): () =>
                    hits.add('split'),
              },
              child: NoteView(
                path: '/n/a.md',
                showLineNumbers: true,
                autofocusEditor: true,
                showWysiwyg: wysiwyg,
                toolbarTop: true,
                readNote: (_) async => 'hello',
                writeNote: (_, _) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The caret is in the editor: the focus sits inside it.
      final focused = FocusManager.instance.primaryFocus!.context!;
      final inEditor = wysiwyg
          ? focused.findAncestorWidgetOfExactType<quill.QuillEditor>()
          : focused.findAncestorWidgetOfExactType<NoteEditor>();
      expect(inEditor, isNotNull);

      Future<void> chord(LogicalKeyboardKey key, {bool shift = false}) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(key);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      await chord(LogicalKeyboardKey.keyW);
      await chord(LogicalKeyboardKey.tab);
      await chord(LogicalKeyboardKey.tab, shift: true);
      await chord(LogicalKeyboardKey.backslash);
      expect(hits, ['close', 'next', 'previous', 'split']);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
