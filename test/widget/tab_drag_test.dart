// #204: tabs are dragged — along their own row to reorder, onto the other
// pane to move, and onto an unsplit pane's right or bottom edge to split
// with them.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/pane_split.dart';
import 'package:niman/src/ui/tab_drag.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  /// A wide window with alpha and beta open, beta showing.
  Future<void> pump(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    for (final name in ['alpha', 'beta']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    // Ctrl+click: beta opens in a tab of its own instead of taking
    // alpha's (#210).
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  /// The tab rows' labels, in order, pane by pane.
  List<List<String>> rows(WidgetTester tester) => [
    for (final bar in tester.widgetList<NoteTabBar>(find.byType(NoteTabBar)))
      [for (final tab in bar.tabs) noteTabLabel(tab.path)],
  ];

  /// Drags the tab reading [label] to [to], as a mouse does.
  Future<void> drag(WidgetTester tester, String label, Offset to) async {
    final from = tester.getCenter(find.text(label));
    final pointer = await tester.startGesture(
      from,
      kind: PointerDeviceKind.mouse,
    );
    // Past the slop first, then to the target in steps: a drop reads the
    // last position the target saw.
    await pointer.moveBy(const Offset(0, 24));
    await tester.pump();
    for (var step = 1; step <= 4; step++) {
      await pointer.moveTo(Offset.lerp(from, to, step / 4)!);
      await tester.pump();
    }
    await pointer.up();
    await settle(tester);
  }

  testWidgets('a tab dragged along its row is reordered', (tester) async {
    await pump(tester);
    expect(rows(tester).first, ['alpha', 'beta']);

    // Onto alpha's left half: beta lands before it.
    final alpha = tester.getCenter(find.text('alpha'));
    await drag(tester, 'beta', Offset(alpha.dx - 40, alpha.dy));
    expect(rows(tester).first, ['beta', 'alpha']);
  });

  /// A point inside [pane]'s body: its middle, or near an edge.
  Offset inPane(WidgetTester tester, int pane, {Alignment? edge}) {
    final rect = tester.getRect(find.byType(TabDropZone).at(pane));
    if (edge == null) return rect.center;
    return Offset(
      rect.center.dx + edge.x * rect.width * 0.45,
      rect.center.dy + edge.y * rect.height * 0.45,
    );
  }

  testWidgets('a tab dropped on the right edge splits the window with it', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(NoteTabBar), findsOne, reason: 'one pane');

    await drag(tester, 'alpha', inPane(tester, 0, edge: Alignment.centerRight));
    expect(find.byType(NoteTabBar), findsNWidgets(2), reason: 'split right');
    expect(rows(tester), [
      ['beta'],
      ['alpha'],
    ]);
  });

  testWidgets('a tab dropped on the other pane moves there', (tester) async {
    await pump(tester);
    await drag(tester, 'alpha', inPane(tester, 0, edge: Alignment.centerRight));
    await settle(tester);
    expect(rows(tester), [
      ['beta'],
      ['alpha'],
    ]);

    // And back: dropped in the middle of the left pane.
    await drag(tester, 'alpha', inPane(tester, 0));
    expect(rows(tester), [
      ['beta', 'alpha'],
    ]);
    expect(find.byType(NoteTabBar), findsOne, reason: 'the pane emptied');
  });

  testWidgets('a tab dropped on the bottom edge splits down', (tester) async {
    await pump(tester);
    await drag(
      tester,
      'alpha',
      inPane(tester, 0, edge: Alignment.bottomCenter),
    );
    expect(find.byType(NoteTabBar), findsNWidgets(2));
    final workspace = tester
        .widgetList<PaneSplit>(find.byType(PaneSplit))
        .single;
    expect(workspace.axis, SplitAxis.down);
  });
}
