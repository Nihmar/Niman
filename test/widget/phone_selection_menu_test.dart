// 0.0.8 test round (Android): the menu a selection brings up stayed on
// screen after a tap elsewhere. The editor sits in the note column's
// LayoutBuilder (#171), so the keyboard coming up rebuilt it — and every
// build handed re_editor a new toolbar controller, which had nothing to
// hide when the tap came.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

Widget _app(double height) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 400,
        height: height,
        child: NoteView(
          path: '/n/a.md',
          showLineNumbers: false,
          autofocusEditor: false,
          // On, as the app has it (#171): the LayoutBuilder that rebuilds.
          noteColumn: const NoteColumn(),
          readNote: (_) async => 'first words here\n\nand more words below',
          writeNote: (_, _) async {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the selection menu goes when the tap goes elsewhere, even '
      'after the editor was rebuilt', (tester) async {
    await tester.pumpWidget(_app(700));
    await tester.pumpAndSettle();
    final editor = find.byType(CodeEditor);
    final at = tester.getTopLeft(editor) + const Offset(40, 14);
    await tester.longPressAt(at);
    await tester.pumpAndSettle();
    final menu = find.byType(AdaptiveTextSelectionToolbar);
    expect(menu, findsOne);

    // The keyboard comes up: the pane is shorter, the editor rebuilt.
    await tester.pumpWidget(_app(400));
    await tester.pumpAndSettle();

    // Well below the menu, which sits by the selection at the top.
    await tester.tapAt(tester.getTopLeft(editor) + const Offset(60, 320));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
  });
}
