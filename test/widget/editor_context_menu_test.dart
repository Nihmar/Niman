// 2026-09-10 crash report: right-clicking the editor on Windows took the
// app down. re_editor's desktop overlay shows the toolbar with no
// `renderRect`, and the package's own (mobile) toolbar controller
// dereferences it with `!`.
//
// This test has a file to itself on purpose: re_editor decides whether it
// is on a phone once per isolate (`final kIsAndroid = ...` in its
// consts), so the platform override only counts for the first editor a
// file mounts.
import 'package:copist/src/editor/note_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  testWidgets('a right click on the desktop opens the menu, not a crash', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final controller = CodeLineEditingController.fromText('hello');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(controller: controller, focusNode: focus),
        ),
      ),
    );
    await tester.pump();
    // Not the package's mobile controller, which is the one that crashes.
    final editor = tester.widget<CodeEditor>(find.byType(CodeEditor));
    expect(
      editor.toolbarController,
      isNot(isA<MobileSelectionToolbarController>()),
    );

    await tester.tapAt(
      tester.getCenter(find.byType(CodeEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Paste and Select all are offered whatever the selection is.
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);

    // Back inside the body: the harness checks for a leaked foundation
    // override before the tearDowns run.
    debugDefaultTargetPlatformOverride = null;
    // Let the caret blink lapse so no timer is pending at teardown.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    controller.dispose();
    focus.dispose();
  });
}
