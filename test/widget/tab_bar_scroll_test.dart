// Issue #1080: a tab row too full to fit scrolls with the mouse wheel, and
// a finger's swipe along it scrolls rather than lifting a tab out.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/tab_drag.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

void main() {
  final drops = <(TabDrag, int)>[];

  setUp(drops.clear);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 38,
          child: NoteTabBar(
            tabs: [for (var i = 0; i < 30; i++) WorkspaceTab('note$i.md')],
            active: 0,
            unsaved: const {},
            onActivate: (_) {},
            onClose: (_) {},
            onNew: () {},
            onDrop: (drag, at) => drops.add((drag, at)),
          ),
        ),
      ),
    ),
  );

  /// The row's scroll offset.
  double offset(WidgetTester tester) => tester
      .widget<SingleChildScrollView>(
        find.descendant(
          of: find.byKey(const Key('note-tab-bar')),
          matching: find.byType(SingleChildScrollView),
        ),
      )
      .controller!
      .offset;

  testWidgets('the mouse wheel over the row scrolls it sideways', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final before = offset(tester);

    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    final at = tester.getCenter(find.byKey(const Key('note-tab-bar')));
    await tester.sendEventToBinding(mouse.hover(at));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 120)));
    await tester.pump();
    expect(offset(tester), before + 120);

    // Back up: the wheel turned the other way gives it back.
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -120)));
    await tester.pump();
    expect(offset(tester), before);
  });

  testWidgets('a finger swiping along the row scrolls it and drops nothing', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final before = offset(tester);

    final finger = await tester.startGesture(
      tester.getCenter(find.text('note3')),
    );
    await finger.moveBy(const Offset(-80, 0));
    await tester.pump();
    await finger.moveBy(const Offset(-120, 0));
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();

    expect(offset(tester), greaterThan(before));
    expect(drops, isEmpty);
    expect(find.byType(TabDragFeedback), findsNothing);
  });

  testWidgets('a finger holding a tab still drags it; a mouse drags at once', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();

    final finger = await tester.startGesture(
      tester.getCenter(find.text('note3')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await finger.moveBy(const Offset(0, 30));
    await tester.pump();
    await finger.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(find.byType(TabDragFeedback), findsOneWidget);
    await finger.up();
    await tester.pumpAndSettle();

    final mouse = await tester.startGesture(
      tester.getCenter(find.text('note4')),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(0, 30));
    await tester.pump();
    await mouse.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(find.byType(TabDragFeedback), findsOneWidget);
    await mouse.up();
    await tester.pumpAndSettle();
  });
}
