// #205: the formatting keys, in the source editor and in the WYSIWYG,
// from one remappable map. Ctrl+B wraps the selection where the toolbar's
// bold button would; a remapped key applies it and the shipped one stops;
// a cleared one does nothing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

const String _doc = 'hello world';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<CodeLineEditingController> _pump(WidgetTester tester) async {
  final controller = CodeLineEditingController.fromText(_doc);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    _app(
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: true,
        controller: controller,
        readNote: (_) async => _doc,
        writeNote: (path, content) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  tester.widget<NoteEditor>(find.byType(NoteEditor)).focusNode.requestFocus();
  await tester.pump();
  controller.selection = const CodeLineSelection(
    baseIndex: 0,
    baseOffset: 0,
    extentIndex: 0,
    extentOffset: 5,
  );
  await tester.pump();
  return controller;
}

Future<void> press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => AppKeyMap.current.value = KeyMap.defaults);

  testWidgets('Ctrl+B bolds the selection in the source editor', (
    tester,
  ) async {
    final controller = await _pump(tester);
    await press(tester, LogicalKeyboardKey.keyB);
    expect(controller.text, startsWith('**hello**'));
    await tester.pump(const Duration(seconds: 1)); // drain save timers.
  });

  testWidgets('Ctrl+Shift+L makes the line a list', (tester) async {
    final controller = await _pump(tester);
    await press(tester, LogicalKeyboardKey.keyL, shift: true);
    expect(controller.text, startsWith('- hello'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a remapped key applies it, and the shipped one stops', (
    tester,
  ) async {
    final controller = await _pump(tester);
    AppKeyMap.current.value = KeyMap.defaults.withEditorBinding(
      ToolbarItem.bold,
      const SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    );
    await press(tester, LogicalKeyboardKey.keyB);
    expect(controller.text, _doc, reason: 'the shipped key is gone');
    await press(tester, LogicalKeyboardKey.keyJ);
    expect(controller.text, startsWith('**hello**'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a cleared key does nothing', (tester) async {
    final controller = await _pump(tester);
    AppKeyMap.current.value = KeyMap.defaults.withEditorBinding(
      ToolbarItem.bold,
      null,
    );
    await press(tester, LogicalKeyboardKey.keyB);
    expect(controller.text, _doc);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the same key bolds in the WYSIWYG, once', (tester) async {
    await tester.pumpWidget(
      _app(
        NoteView(
          path: '/notes/a.md',
          showLineNumbers: true,
          autofocusEditor: true,
          showWysiwyg: true,
          readNote: (_) async => _doc,
          writeNote: (path, content) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final editor = tester.state<WysiwygEditorState>(find.byType(WysiwygEditor));
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      quill.ChangeSource.local,
    );
    await tester.pump();

    bool bold() =>
        editor.controller.getSelectionStyle().attributes.containsKey('bold');

    await press(tester, LogicalKeyboardKey.keyB);
    // Bold on, and only once: Quill's own Ctrl+B never saw the key, so
    // it was not toggled back off.
    expect(bold(), isTrue);

    // Moved to another key, the shipped one stops here too — Quill binds
    // Ctrl+B itself, and the two surfaces have to agree.
    AppKeyMap.current.value = KeyMap.defaults.withEditorBinding(
      ToolbarItem.bold,
      const SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    );
    await press(tester, LogicalKeyboardKey.keyB);
    expect(bold(), isTrue, reason: 'unchanged: the old key does nothing');
    await press(tester, LogicalKeyboardKey.keyJ);
    expect(bold(), isFalse, reason: 'the new key toggled it back off');
    await tester.pump(const Duration(seconds: 1));
  });

  // 0.0.8 test round: the side panel moved onto Ctrl+Shift+L — the
  // bulleted list's key — and then nothing happened at all inside the
  // editor. A key the user gave a command is the user's word, and wins
  // there too (#159); the command's own handler runs it.
  testWidgets('a key given to a command beats the formatting it collides '
      'with', (tester) async {
    final controller = await _pump(tester);
    AppKeyMap.current.value = KeyMap.defaults.withBinding(
      AppCommand.toggleDock,
      const SingleActivator(
        LogicalKeyboardKey.keyL,
        control: true,
        shift: true,
      ),
    );
    await press(tester, LogicalKeyboardKey.keyL, shift: true);
    expect(controller.text, _doc, reason: 'no list: the command has the key');
    await tester.pump(const Duration(seconds: 1));
  });

  test('the formatting keys are kept next to the commands', () {
    final map = KeyMap.defaults.withEditorBinding(
      ToolbarItem.italic,
      const SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    );
    final read = KeyMap.fromJson(map.toJson());
    expect(
      KeyMap.sameKeys(
        read.editorBindingOf(ToolbarItem.italic)!,
        const SingleActivator(LogicalKeyboardKey.keyJ, control: true),
      ),
      isTrue,
    );
    expect(read.isEditorChanged(ToolbarItem.italic), isTrue);
    // The shipped ones are untouched, and so are the app's commands.
    expect(
      read.editorBindingOf(ToolbarItem.bold),
      KeyMap.editorDefaultOf(ToolbarItem.bold),
    );
    expect(read.overrides, isEmpty);
    expect(read.editorReverted(ToolbarItem.italic).editorOverrides, isEmpty);
  });
}
