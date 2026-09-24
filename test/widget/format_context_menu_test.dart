// Issue #174, grouped by #260: right-click in either unified mode offers
// the formatting under Format, applies it to the selection, and shows the
// same active state the toolbar does.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

/// Whether the menu's Bold row reads as on.
bool _boldOn(WidgetTester tester) => tester
    .widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('menu-bold')),
            matching: find.byType(Semantics),
          )
          .first,
    )
    .properties
    .toggled!;

/// The desktop's menu: flutter_test runs as Android unless told.
final TargetPlatformVariant _desktop = TargetPlatformVariant.only(
  TargetPlatform.linux,
);

void main() {
  for (final live in [false, true]) {
    testWidgets('Format › Bold wraps the selection, then shows as on '
        '(${live ? 'live' : 'source'})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: '/n/a.md',
              showLineNumbers: true,
              autofocusEditor: true,
              toolbarTop: true,
              showWysiwyg: live,
              readNote: (_) async => 'hello world',
              writeNote: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<MarkdownSourceViewState>(
        find.byType(MarkdownSourceView),
      )..select(const SelectionModel(anchor: 0, extent: 5));
      await tester.pump();

      Future<void> format() async {
        state.showContextMenu();
        await tester.pump();
        expect(find.text('Paste'), findsOneWidget);
        await tester.tap(find.byKey(const Key('menu-format')));
        await tester.pump();
      }

      await format();
      expect(_boldOn(tester), isFalse);
      await tester.tap(find.byKey(const Key('menu-bold')));
      await tester.pumpAndSettle();
      expect(state.widget.buffer.text, '**hello** world');
      // The menu closed behind the action.
      expect(find.byKey(const Key('menu-bold')), findsNothing);

      // The caret inside the bold word: the menu says so, as the toolbar
      // does.
      state.placeCaret(4);
      await tester.pump();
      await format();
      expect(_boldOn(tester), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(seconds: 1));
    }, variant: _desktop);
  }

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
