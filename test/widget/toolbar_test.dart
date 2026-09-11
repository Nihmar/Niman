// The editor formatting toolbar (T-UI-08): every button applies its
// markdown command through the controller's range-replacement op, and the
// editor keeps focus (the keyboard stays open) after a tap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

const String _doc = '# Head\n\nhello world\nsecond line';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

NoteView _view(CodeLineEditingController controller) {
  return NoteView(
    path: '/notes/a.md',
    showLineNumbers: true,
    autofocusEditor: false,
    controller: controller,
    readNote: (_) async => _doc,
    writeNote: (path, content) async {},
  );
}

/// Pumps a fresh NoteView over a new controller for the [_doc].
Future<CodeLineEditingController> _pumpFresh(WidgetTester tester) async {
  final controller = CodeLineEditingController.fromText(_doc);
  addTearDown(controller.dispose);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_app(_view(controller)));
  await tester.pump();
  await tester.pump();
  return controller;
}

/// Selects from line [index], offset [offset] to [extentIndex].
/// [extentOffset] (or just [index].[offset] when collapsed).
void _select(
  CodeLineEditingController controller, {
  required int index,
  required int offset,
  int? extentIndex,
  int? extentOffset,
}) {
  controller.selection = CodeLineSelection(
    baseIndex: index,
    baseOffset: offset,
    extentIndex: extentIndex ?? index,
    extentOffset: extentOffset ?? offset,
  );
}

void main() {
  testWidgets('the editor keeps focus after a toolbar tap (IME stays open)', (
    tester,
  ) async {
    final controller = await _pumpFresh(tester);
    final focusNode =
        tester.widget<NoteEditor>(find.byType(NoteEditor)).focusNode
          ..requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    // The toolbar must not take the editor's focus (the keyboard stays).
    expect(focusNode.hasFocus, isTrue);
    expect(controller.text, contains('**'));
    await tester.pump(const Duration(seconds: 1)); // drain save timers.
  });

  testWidgets('wrap buttons wrap the selection (bold, italic, strike, '
      'superscript, underline, link)', (tester) async {
    final cases = <Key, String>{
      const Key('toolbar-bold'): '**hello world**',
      const Key('toolbar-italic'): '*hello world*',
      const Key('toolbar-strike'): '~~hello world~~',
      const Key('toolbar-sup'): '<sup>hello world</sup>',
      const Key('toolbar-underline'): '<u>hello world</u>',
      const Key('toolbar-link'): '[[hello world]]',
    };
    for (final entry in cases.entries) {
      final controller = await _pumpFresh(tester);
      _select(controller, index: 2, offset: 0, extentOffset: 11);
      await tester.pump();
      await tester.tap(find.byKey(entry.key));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        controller.text,
        '# Head\n\n${entry.value}\nsecond line',
        reason: 'button ${entry.key}',
      );
      await tester.pump(const Duration(seconds: 1)); // drain save timers.
    }
  });

  testWidgets('code block: a selection is fenced; a caret opens a block', (
    tester,
  ) async {
    // Selection fenced.
    final controller = await _pumpFresh(tester);
    _select(controller, index: 2, offset: 0, extentOffset: 11);
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-code')));
    await tester.pump();
    expect(controller.text, '# Head\n\n```\nhello world\n```\nsecond line');
    await tester.pump(const Duration(seconds: 1));

    // Collapsed caret on the blank line: fences around a blank line.
    final caret = await _pumpFresh(tester);
    _select(caret, index: 1, offset: 0);
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-code')));
    await tester.pump();
    expect(caret.text, '# Head\n```\n\n```\nhello world\nsecond line');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('list and quote prefix the touched lines', (tester) async {
    // List: lines 2 and 3 get "- ".
    final controller = await _pumpFresh(tester);
    _select(controller, index: 2, offset: 0, extentIndex: 3, extentOffset: 11);
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-list')));
    await tester.pump();
    expect(controller.text, '# Head\n\n- hello world\n- second line');
    await tester.pump(const Duration(seconds: 1));

    // Quote: the caret line gets "> ".
    final caret = await _pumpFresh(tester);
    _select(caret, index: 3, offset: 0);
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-quote')));
    await tester.pump();
    expect(caret.text, '# Head\n\nhello world\n> second line');
    await tester.pump(const Duration(seconds: 1));
  });
}
