import 'package:copist/src/editor/note_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

Widget _app(NoteEditor editor) => MaterialApp(home: Scaffold(body: editor));

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
}

void main() {
  group('NoteEditor', () {
    testWidgets('builds a CodeEditor over the given controller', (
      tester,
    ) async {
      final controller = CodeLineEditingController.fromText('hi');
      final focus = FocusNode();
      await tester.pumpWidget(
        _app(NoteEditor(controller: controller, focusNode: focus)),
      );
      final editor = tester.widget<CodeEditor>(find.byType(CodeEditor));
      expect(editor.controller, same(controller));
      expect(editor.focusNode, same(focus));
      // The keyboard appears on an explicit tap only, never on open
      // (unless the keyboard-on-open toggle is set).
      expect(editor.autofocus, isFalse);
      // Prose wraps at the viewport.
      expect(editor.wordWrap, isTrue);
      // Monospace source text with a row-number column.
      expect(editor.style?.fontFamily, 'monospace');
      expect(editor.indicatorBuilder, isNotNull);
      expect(find.byType(DefaultCodeLineNumber), findsOneWidget);
      // No whole-file engine highlighting: each line is styled through the
      // controller's spanBuilder (the incremental tokenizer wired by the
      // owner).
      expect(editor.style?.codeTheme, isNull);
      await _unmount(tester);
      controller.dispose();
      focus.dispose();
    });

    testWidgets('focuses on open when the keyboard-on-open toggle is set', (
      tester,
    ) async {
      final controller = CodeLineEditingController.fromText('hi');
      final focus = FocusNode();
      await tester.pumpWidget(
        _app(
          NoteEditor(controller: controller, focusNode: focus, autofocus: true),
        ),
      );
      final editor = tester.widget<CodeEditor>(find.byType(CodeEditor));
      expect(editor.autofocus, isTrue);
      // Let the focus-driven cursor-blink timer lapse (re_editor schedules a
      // 100 ms one-shot on Android) so no timer is pending at teardown.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      await _unmount(tester);
      controller.dispose();
      focus.dispose();
    });

    testWidgets('hides the row-number column when disabled', (tester) async {
      final controller = CodeLineEditingController.fromText('hi');
      final focus = FocusNode();
      await tester.pumpWidget(
        _app(
          NoteEditor(
            controller: controller,
            focusNode: focus,
            showLineNumbers: false,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<CodeEditor>(find.byType(CodeEditor)).indicatorBuilder,
        isNull,
      );
      expect(find.byType(DefaultCodeLineNumber), findsNothing);
      await _unmount(tester);
      controller.dispose();
      focus.dispose();
    });

    testWidgets('a note with a spanBuilder renders styled lines', (
      tester,
    ) async {
      // The NoteView wires the spanBuilder on the controller; the editor
      // just paints what it gets. A styled TextSpan goes through the editor
      // paragraph pipeline without error (it paints with its own render
      // object, so the find-text finders do not see it).
      final controller = CodeLineEditingController(
        spanBuilder:
            ({
              required context,
              required index,
              required codeLine,
              required textSpan,
              required style,
            }) {
              return codeLine.text.isEmpty
                  ? textSpan
                  : TextSpan(
                      text: codeLine.text,
                      style: style.copyWith(color: const Color(0xFFFF0000)),
                    );
            },
      )..text = '# Hi\n\nbody';
      final focus = FocusNode();
      await tester.pumpWidget(
        _app(NoteEditor(controller: controller, focusNode: focus)),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.text, '# Hi\n\nbody');
      await _unmount(tester);
      controller.dispose();
      focus.dispose();
    });
  });
}
