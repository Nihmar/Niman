// The tree and its right-click menu are drawn for the surface (#296): a
// pointer's theme (Windows, Linux) gets short rows and a tight menu, a
// touch theme keeps the phone's thumb-sized ones.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_row_menu.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Future<Set<String>> pumpTree(
    WidgetTester tester,
    VisualDensity density,
  ) async {
    final toggled = <String>{};
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Docs');
    await session.createNote(parentPath: '', name: 'nota', content: 'x');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: density),
        home: Scaffold(
          body: NoteTree(
            controller: session,
            selectedPath: null,
            expanded: const <String>{},
            onToggle: toggled.add,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return toggled;
  }

  /// The row holding [name]: the tree's own `InkWell` around it.
  Rect rowOf(WidgetTester tester, String name) => tester.getRect(
    find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first,
  );

  testWidgets('a pointer gets short rows and names near the edge', (
    tester,
  ) async {
    final toggled = await pumpTree(tester, VisualDensity.compact);
    expect(rowOf(tester, 'nota.md').height, 28);
    expect(tester.getTopLeft(find.text('nota.md')).dx, 8 + 24);
    // The folder's name lines up with the note's.
    expect(tester.getTopLeft(find.text('Docs')).dx, 8 + 24);

    // The narrowed chevron still takes the click.
    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(toggled, {'Docs'});
  });

  testWidgets('a touch screen keeps the thumb-sized rows', (tester) async {
    await pumpTree(tester, VisualDensity.standard);
    expect(rowOf(tester, 'nota.md').height, 40);
    expect(tester.getTopLeft(find.text('nota.md')).dx, 8 + 48);
  });

  Future<void> openMenu(WidgetTester tester, VisualDensity density) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: density),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showTreeBackgroundMenuAt(context, position: Offset.zero),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  double itemHeight(WidgetTester tester) =>
      tester.getSize(find.byKey(const Key('tree-menu-new-note'))).height;

  testWidgets("a pointer's menu is tight", (tester) async {
    await openMenu(tester, VisualDensity.compact);
    expect(itemHeight(tester), 32);
  });

  testWidgets("a touch screen's menu keeps its items", (tester) async {
    await openMenu(tester, VisualDensity.standard);
    expect(itemHeight(tester), kMinInteractiveDimension);
  });
}
