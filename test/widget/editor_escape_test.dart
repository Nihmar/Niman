// Esc in the note editors: a selection takes the first press and
// collapses, and with nothing left to cancel the key goes on to the app's
// own Esc — a DismissIntent, which is what leaves Zen mode (#69). Quill's
// Esc (hiding its selection toolbar) was on whenever there was a caret,
// so from the WYSIWYG editor the key never got out.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

/// re_editor keys its shortcuts by platform, and caches them: every test
/// here runs on the desktop, where the keyboard is.
final _desktop = TargetPlatformVariant.only(TargetPlatform.linux);

void main() {
  for (final wysiwyg in [false, true]) {
    testWidgets('from the ${wysiwyg ? 'WYSIWYG' : 'source'} editor, Esc '
        'reaches the app’s dismiss, a selection first', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Under the route and the Scaffold, as the shell's is: their
            // own Esc actions would be the nearest otherwise.
            body: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) => dismissed++,
                ),
              },
              child: NoteView(
                path: '/n/a.md',
                showLineNumbers: true,
                autofocusEditor: false,
                toolbarTop: true,
                showWysiwyg: wysiwyg,
                readNote: (_) async => 'Some text.',
                writeNote: (_, _) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        wysiwyg ? find.byType(quill.QuillEditor) : find.byType(CodeEditor),
      );
      await tester.pumpAndSettle();

      if (wysiwyg) {
        tester
            .widget<quill.QuillEditor>(find.byType(quill.QuillEditor))
            .controller
            .updateSelection(
              const TextSelection(baseOffset: 0, extentOffset: 4),
              quill.ChangeSource.local,
            );
      } else {
        tester
            .widget<CodeEditor>(find.byType(CodeEditor))
            .controller!
            .selectAll();
      }
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(dismissed, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(dismissed, 1);
    }, variant: _desktop);
  }
}
