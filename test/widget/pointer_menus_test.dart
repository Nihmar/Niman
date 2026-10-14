// Every menu on a pointer is the tree's compact one (#296): 32 px rows, the
// label in body text, an 18 px icon — and on a thumb's theme the touch
// sizes stay. The theme carries what Flutter reads from it; the helpers
// carry the rest, so a menu of any kind is checked here.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/selection_buttons_menu.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/app_menu.dart';
import 'package:niman/src/ui/note_menu.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/pointer_menu_scope.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

/// A desktop's theme: pointer-dense.
final ThemeData _pointer = ThemeData(visualDensity: VisualDensity.compact);

/// A phone's theme: standard density.
final ThemeData _touch = ThemeData(visualDensity: VisualDensity.standard);

Future<void> _pump(WidgetTester tester, ThemeData theme, Widget body) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => PointerMenuScope(child: child!),
      home: Scaffold(body: body),
    ),
  );
}

/// The style the first text under [item] is drawn in.
TextStyle _labelStyle(WidgetTester tester, Finder item) => tester
    .widget<RichText>(
      find
          .descendant(
            of: find.descendant(of: item, matching: find.byType(Text)).first,
            matching: find.byType(RichText),
          )
          .first,
    )
    .text
    .style!;

/// The theme the app is drawn with, its text theme localized.
ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first));

/// That [style] is body text: the weight and spacing of `bodyMedium`, not
/// of the label style Material's menus default to.
void _expectBody(WidgetTester tester, TextStyle style) {
  final body = _theme(tester).textTheme.bodyMedium!;
  expect(style.fontSize, body.fontSize);
  expect(style.fontWeight, body.fontWeight);
  expect(style.letterSpacing, body.letterSpacing);
}

void main() {
  const noteMenu = Key('note-menu');
  const deleteItem = Key('note-menu-delete');

  Future<void> openNoteMenu(WidgetTester tester, ThemeData theme) async {
    await _pump(
      tester,
      theme,
      Align(
        alignment: Alignment.topRight,
        child: NoteMenuButton(onSelected: (_) {}),
      ),
    );
    await tester.tap(find.byKey(noteMenu));
    await tester.pumpAndSettle();
  }

  group('on a pointer', () {
    testWidgets("the note's ⋮ menu has 32 px rows in body text", (
      tester,
    ) async {
      await openNoteMenu(tester, _pointer);

      final item = find.byKey(deleteItem);
      expect(tester.getSize(item).height, pointerDenseItemHeight);
      _expectBody(tester, _labelStyle(tester, item));
      expect(
        tester.getSize(find.byIcon(Icons.delete_outline)),
        const Size.square(18),
      );
    });

    testWidgets('a tab’s right-click menu has 32 px rows and short dividers', (
      tester,
    ) async {
      await _pump(
        tester,
        _pointer,
        SizedBox(
          height: 38,
          child: NoteTabBar(
            tabs: const [WorkspaceTab('a.md'), WorkspaceTab('b.md')],
            active: 0,
            unsaved: const {},
            onActivate: (_) {},
            onClose: (_) {},
            onNew: () {},
            onSplit: (_, _) {},
            onTabAction: (_, _, _) {},
          ),
        ),
      );
      await tester.tap(
        find.byKey(const Key('note-tab-0')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();

      final close = find.byKey(const Key('tab-menu-close'));
      final others = find.byKey(const Key('tab-menu-close-others'));
      expect(tester.getSize(close).height, pointerDenseItemHeight);
      _expectBody(tester, _labelStyle(tester, close));
      // The disabled one keeps its place and its size, in body text too.
      expect(tester.getSize(others).height, pointerDenseItemHeight);
      _expectBody(tester, _labelStyle(tester, others));
      // Close, Close others, Close to the right, Close all, then the
      // divider: its 9 px, not the phone's 16.
      final gap =
          tester.getTopLeft(find.byKey(const Key('tab-menu-reveal'))).dy -
          tester.getBottomLeft(find.byKey(const Key('tab-menu-close-all'))).dy;
      expect(gap, pointerDenseDividerHeight);
    });

    testWidgets("the ☰ menu's items are 32 px and name their keys small", (
      tester,
    ) async {
      await _pump(
        tester,
        _pointer,
        Align(
          alignment: Alignment.topLeft,
          child: AppMenuButton(handlers: () => const {}),
        ),
      );
      await tester.tap(find.byKey(const Key('app-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-menu-group-view')));
      await tester.pumpAndSettle();

      final item = find.byKey(const Key('app-menu-toggleDock'));
      expect(tester.getSize(item).height, pointerDenseItemHeight);
      final texts = find.descendant(of: item, matching: find.byType(Text));
      expect(texts, findsNWidgets(2), reason: 'the label and its keys');
      final label = tester.widget<Text>(texts.first);
      final keys = tester.widget<Text>(texts.last);
      _expectBody(tester, _labelStyle(tester, item));
      expect(
        keys.style!.fontSize,
        _theme(tester).textTheme.bodySmall!.fontSize,
        reason: 'the keys are small, ${label.data}',
      );
    });

    testWidgets("an action sheet's pop-up runs 32 px tiles in body text", (
      tester,
    ) async {
      await _pump(
        tester,
        _pointer,
        Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showActionSheet<int>(
              context,
              items: (context) => [
                ListTile(
                  key: const Key('tile'),
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit'),
                  onTap: () {},
                ),
              ],
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      const tile = Key('tile');
      expect(tester.getSize(find.byKey(tile)).height, pointerDenseItemHeight);
      _expectBody(tester, _labelStyle(tester, find.byKey(tile)));
      expect(
        tester.getSize(find.byIcon(Icons.edit_outlined)),
        const Size.square(18),
      );
    });

    testWidgets("the editors' context menu has 32 px rows", (tester) async {
      await _pump(
        tester,
        _pointer,
        Stack(
          children: [
            Positioned.fill(
              child: EditorContextMenu(
                anchors: const TextSelectionToolbarAnchors(
                  primaryAnchor: Offset(100, 100),
                ),
                clipboard: [
                  ContextMenuButtonItem(
                    type: ContextMenuButtonType.copy,
                    onPressed: () {},
                  ),
                  const ContextMenuButtonItem(
                    type: ContextMenuButtonType.paste,
                    onPressed: null,
                  ),
                ],
                onDismiss: () {},
              ),
            ),
          ],
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('context-copy'))).height,
        pointerDenseItemHeight,
      );
      // Paste has no action here: it is greyed out and keeps its size.
      expect(
        tester.getSize(find.byKey(const Key('context-paste'))).height,
        pointerDenseItemHeight,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('the read view and PDF selection menu has 32 px rows', (
      tester,
    ) async {
      await _pump(
        tester,
        _pointer,
        Stack(
          children: [
            Positioned.fill(
              child: SelectionButtonsMenu(
                anchor: const Offset(100, 100),
                items: [
                  ContextMenuButtonItem(
                    type: ContextMenuButtonType.copy,
                    onPressed: () {},
                  ),
                  ContextMenuButtonItem(label: 'Annotate', onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      );

      for (final i in [0, 1]) {
        expect(
          tester.getSize(find.byKey(Key('selection-menu-$i'))).height,
          pointerDenseItemHeight,
        );
      }
      expect(find.text('Annotate'), findsOne);
    });
  });

  group('on a thumb', () {
    testWidgets("the note's ⋮ menu keeps Material's 48 px rows", (
      tester,
    ) async {
      await openNoteMenu(tester, _touch);

      final item = find.byKey(deleteItem);
      expect(tester.getSize(item).height, kMinInteractiveDimension);
      final style = _labelStyle(tester, item);
      expect(style.fontWeight, _theme(tester).textTheme.labelLarge!.fontWeight);
      expect(
        tester.getSize(find.byIcon(Icons.delete_outline)),
        const Size.square(20),
      );
    });

    test('the theme is left as it came', () {
      expect(identical(_touch, pointerMenuTheme(_touch)), isTrue);
      expect(_touch.popupMenuTheme.menuPadding, isNull);
    });

    test('two themes made from the same colours are equal', () {
      expect(pointerMenuTheme(_pointer), pointerMenuTheme(_pointer));
    });
  });
}
