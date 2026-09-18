// Issue #174: right-click in either editor offers the toolbar's
// formatting actions under the clipboard ones, applies them to the
// selection, and shows the same active state the toolbar does.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

/// Whether the menu's Bold row reads as on.
bool _boldOn(WidgetTester tester) => tester
    .widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('context-bold')),
            matching: find.byType(Semantics),
          )
          .first,
    )
    .properties
    .toggled!;

void main() {
  testWidgets('the source editor: Bold from the menu wraps the selection', (
    tester,
  ) async {
    // The desktop's menu: flutter_test runs as Android unless told.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final controller = CodeLineEditingController.fromText('hello');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/a.md',
            showLineNumbers: true,
            autofocusEditor: true,
            toolbarTop: true,
            controller: controller,
            readNote: (_) async => 'hello',
            writeNote: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.selectAll();
    await tester.pump();

    await tester.tapAt(
      tester.getCenter(find.byType(CodeEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    // The clipboard first, the formatting after it.
    expect(find.text('Paste'), findsOneWidget);
    final paste = tester.getTopLeft(find.text('Paste')).dy;
    expect(
      tester.getTopLeft(find.byKey(const Key('context-bold'))).dy,
      greaterThan(paste),
    );
    // Every visible toolbar button is there, by the toolbar's name.
    expect(find.byKey(const Key('context-heading')), findsOneWidget);
    expect(find.byKey(const Key('context-tools')), findsOneWidget);

    await tester.tap(find.byKey(const Key('context-bold')));
    await tester.pump();
    expect(controller.text, '**hello**');
    // The menu closed behind the action.
    expect(find.byKey(const Key('context-bold')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    controller.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the WYSIWYG: Bold from the menu, then shown as on', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/a.md',
            showLineNumbers: true,
            autofocusEditor: true,
            toolbarTop: true,
            showWysiwyg: true,
            readNote: (_) async => 'hello world',
            writeNote: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final state = tester.state<WysiwygEditorState>(find.byType(WysiwygEditor));
    state.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      quill.ChangeSource.local,
    );
    await tester.pump();

    Future<void> rightClick() async {
      await tester.tapAt(
        tester.getTopLeft(find.byType(WysiwygEditor)) + const Offset(40, 30),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
    }

    await rightClick();
    expect(find.byType(EditorContextMenu), findsOneWidget);
    expect(_boldOn(tester), isFalse);
    await tester.tap(find.byKey(const Key('context-bold')));
    await tester.pumpAndSettle();
    expect(
      state.controller.document.collectStyle(0, 5).attributes,
      contains('bold'),
    );

    // The caret inside the bold word: the menu says so, as the toolbar
    // does.
    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 2),
      quill.ChangeSource.local,
    );
    await tester.pumpAndSettle();
    await rightClick();
    expect(_boldOn(tester), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    debugDefaultTargetPlatformOverride = null;
  });

  // The phone's long-press bar carries the same entries (#174), the
  // format that is on standing out as it does on the toolbar.
  testWidgets('the phone: the formatting rides the selection bar', (
    tester,
  ) async {
    var bolded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorContextMenu(
            anchors: const TextSelectionToolbarAnchors(
              primaryAnchor: Offset(200, 200),
            ),
            clipboard: [
              ContextMenuButtonItem(
                type: ContextMenuButtonType.copy,
                onPressed: () {},
              ),
            ],
            formats: [
              FormatMenuEntry(
                item: ToolbarItem.bold,
                active: true,
                onPressed: () => bolded = true,
              ),
            ],
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final label = tester.widget<Text>(find.text(ToolbarItem.bold.label));
    expect(label.style?.fontWeight, FontWeight.bold);
    await tester.tap(find.text(ToolbarItem.bold.label));
    expect(bolded, isTrue);
  });
}
