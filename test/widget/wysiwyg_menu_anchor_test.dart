// #161: the WYSIWYG context menu comes up at the right-click, not at the
// horizontal centre of the editor.
//
// Quill anchors from the selection (`TextSelectionToolbarAnchors
// .fromSelection`), which widens a multi-line selection's rect to the
// whole editing region and anchors at its centre — the phone convention.
// On a wide window that is half a screen from the pointer.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';

const String _note = '- Bolla originale: 425259\n- Bolla clonata: 441372\n';

void main() {
  testWidgets('the menu opens at the pointer, not centred on the editor', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey<WysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(key: key, data: _note, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pump();

    // A selection over both lines: the case where Quill's own rect spans
    // the editor and the anchor lands in the middle of it.
    key.currentState!.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 40),
      quill.ChangeSource.local,
    );
    await tester.pump();

    const at = Offset(120, 80);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await gesture.addPointer(location: at);
    addTearDown(gesture.removePointer);
    await gesture.down(at);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    final menuLeft = tester.getTopLeft(find.text('Copy')).dx;
    final editorWidth = tester.getSize(find.byType(WysiwygEditor)).width;

    debugDefaultTargetPlatformOverride = null;
    // Near the click, not out at the middle of a 1280 px editor.
    expect(
      menuLeft,
      lessThan(at.dx + 200),
      reason:
          'the menu is $menuLeft, the click was at ${at.dx}, '
          'the editor is $editorWidth wide',
    );
  });
}
