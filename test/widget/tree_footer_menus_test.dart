// The tree footer's two menus with a pointer (#747, #785): the dense menu
// padding the tree's row menu has, a sort button with a name, and the
// sort order's check said to a screen reader.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/shell_tree_footer.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // Pointer-dense, as a desktop's theme is.
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: 320,
              child: TreeFooterBar(
                controller: session,
                onNewItem: (_) {},
                syncButton: const SizedBox.shrink(),
                sortToggle: TreeSortToggle(
                  sort: TreeSort.nameAsc,
                  onSort: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The room between the open menu's edge and its first row, [first].
  double topPadding(WidgetTester tester, Finder first) {
    final menu = find
        .ancestor(of: first, matching: find.byType(Material))
        .first;
    return tester.getTopLeft(first).dy - tester.getTopLeft(menu).dy;
  }

  testWidgets('both menus keep the dense 4 px padding', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('new-item-menu')));
    await tester.pumpAndSettle();
    expect(
      topPadding(tester, find.byKey(const Key('journal-today-action'))),
      pointerDenseMenuPadding.top,
    );
    await tester.tapAt(const Offset(780, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggle-sort')));
    await tester.pumpAndSettle();
    expect(
      topPadding(tester, find.byKey(const Key('sort-name'))),
      pointerDenseMenuPadding.top,
    );
  });

  testWidgets('the sort button is named, and says which order is on', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    final sort = find.byKey(const Key('toggle-sort'));
    // Not Flutter's generic "Show menu": the tooltip, which is also what a
    // screen reader is told the button is.
    expect(
      find.descendant(of: sort, matching: find.byTooltip('Sort')),
      findsOne,
    );
    expect(find.byTooltip('Show menu'), findsNothing);

    await tester.tap(sort);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const Key('sort-name'))),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('sort-modified'))),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('sort-ascending'))),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    semantics.dispose();
  });
}
