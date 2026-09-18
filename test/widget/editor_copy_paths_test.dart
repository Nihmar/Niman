// #161: cut/copy/paste in the source editor, by the two routes a writer
// has — the keyboard and the right-click menu.
//
// Its own file, like `editor_context_menu_test.dart`: re_editor decides
// once per isolate whether it is on a phone, so the platform override
// only counts for the first editor a file mounts.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_editing_controller.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:re_editor/re_editor.dart';

const String _note = 'first line\nsecond line\nthird line';

typedef _Editor = ({MarkdownEditingController controller, FocusNode focus});

void main() {
  String? copied;

  setUp(() {
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  /// Mounts the editor over [_note], wrapped the way `NoteView` wraps it.
  ///
  /// The platform override is set here and cleared in [settle]: the
  /// harness checks for a leaked foundation override before the tearDowns
  /// run, so every assertion happens after that call.
  Future<_Editor> pumpEditor(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final controller = MarkdownEditingController(
      delegate: CodeLineEditingController.fromText(_note),
      isPlain: (_) => true,
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(controller: controller, focusNode: focus),
        ),
      ),
    );
    await tester.pump();
    focus.requestFocus();
    await tester.pump();
    return (controller: controller, focus: focus);
  }

  /// Clears the override and unmounts, letting the caret blink lapse so no
  /// timer is pending at teardown.
  Future<void> settle(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = null;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.byType(CodeEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();
  }

  testWidgets('Ctrl+A then Ctrl+C copies the whole note', (tester) async {
    final editor = await pumpEditor(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    final selected = editor.controller.selectedText;

    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();
    final onClipboard = copied;

    await settle(tester);
    expect(selected, _note, reason: 'Ctrl+A did not select the note');
    expect(onClipboard, _note);
  });

  testWidgets('the menu keeps the editor focused, so its items run', (
    tester,
  ) async {
    final editor = await pumpEditor(tester);
    await openMenu(tester);
    expect(find.text('Select all'), findsOneWidget);

    await tester.tap(find.text('Select all'));
    await tester.pump();
    // The editor has to still hold the focus. re_editor unfocuses on a tap
    // outside its own tap region and hides the selection toolbar the
    // moment it loses focus — which takes the button away before its own
    // tap can fire.
    final keptFocus = editor.focus.hasFocus;
    final selected = editor.controller.selectedText;

    await settle(tester);
    expect(keptFocus, isTrue, reason: 'the menu unfocused the editor');
    expect(selected, _note, reason: 'the menu item did not reach the editor');
  });

  testWidgets('Copy from the menu puts the selection on the clipboard', (
    tester,
  ) async {
    final editor = await pumpEditor(tester);
    editor.controller.selectAll();
    await tester.pump();

    await openMenu(tester);
    await tester.tap(find.text('Copy'));
    await tester.pump();
    final onClipboard = copied;

    await settle(tester);
    expect(onClipboard, _note);
  });

  testWidgets('a click outside still takes the menu down', (tester) async {
    await pumpEditor(tester);
    await openMenu(tester);
    expect(find.text('Paste'), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    final gone = find.text('Paste').evaluate().isEmpty;

    await settle(tester);
    expect(gone, isTrue);
  });
}
