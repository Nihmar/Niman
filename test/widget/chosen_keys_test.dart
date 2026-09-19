// Issue #159: a key the user chose wins in both editors, even where the
// editor means something else by it — Ctrl+Z is the editor's undo, and
// here it is a command's.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

const _ctrlZ = SingleActivator(LogicalKeyboardKey.keyZ, control: true);

void main() {
  tearDown(() {
    AppKeyMap.current.value = KeyMap.defaults;
    AppKeyMap.capturing = false;
  });

  for (final wysiwyg in [false, true]) {
    final editor = wysiwyg ? 'the WYSIWYG' : 'the source editor';
    testWidgets('a chosen key wins in $editor', (tester) async {
      AppKeyMap.current.value = KeyMap.defaults.withBinding(
        AppCommand.toggleDock,
        _ctrlZ,
      );
      var ran = 0;
      final keys = ChosenKeys(
        handlers: () => {AppCommand.toggleDock: () => ran++},
        active: () => true,
      )..attach();
      addTearDown(keys.detach);
      final controller = CodeLineEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: '/n/a.md',
              showLineNumbers: true,
              autofocusEditor: true,
              showWysiwyg: wysiwyg,
              controller: controller,
              readNote: (_) async => 'hello',
              writeNote: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (!wysiwyg) controller.replaceSelection('!');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(ran, 1);
      // The editor never heard it: no undo.
      if (!wysiwyg) expect(controller.text, '!hello');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      // On the desktop, where the editors have Ctrl+Z: on the default
      // (Android) test platform re_editor binds no undo, and the check
      // above passed whether the editor heard the key or not.
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  }

  testWidgets('nothing runs while a combination is being recorded', (
    tester,
  ) async {
    AppKeyMap.current.value = KeyMap.defaults.withBinding(
      AppCommand.toggleDock,
      _ctrlZ,
    );
    var ran = 0;
    final keys = ChosenKeys(
      handlers: () => {AppCommand.toggleDock: () => ran++},
      active: () => true,
    )..attach();
    addTearDown(keys.detach);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    AppKeyMap.capturing = true;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(ran, 0);
  });
}
