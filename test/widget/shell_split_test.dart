// Issue #23, PR 3: two panes. The window splits right or down, each pane
// keeps its own tabs, the title bar's row divides where the panes do, a
// click gives a pane the focus, and a tab moved across keeps its editor.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';
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

  Future<void> pumpShell(WidgetTester tester) async {
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
    for (final name in ['alpha', 'beta', 'gamma']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  Workspace w() => controller.workspace;
  List<String> pane(int i) => w().panes[i].tabs.map((t) => t.path).toList();

  Future<void> openTwo(WidgetTester tester) async {
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(noteRow('beta.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  Future<void> tabMenu(WidgetTester tester, String tab, String item) async {
    await tester.tapAt(
      tester.getCenter(find.byKey(Key(tab))),
      buttons: kSecondaryMouseButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(Key(item)));
    await settle(tester);
  }

  testWidgets(r'Ctrl+\ splits right with the tab on screen', (tester) async {
    await pumpShell(tester);
    await openTwo(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(w().isSplit, isTrue);
    expect(pane(0), ['alpha.md']);
    expect(pane(1), ['beta.md']);
    // Both notes on screen at once.
    expect(find.byType(NoteView), findsNWidgets(2));
    // The title bar's row divides where the panes do.
    final divider = tester.getRect(find.byKey(const Key('pane-divider')));
    final second = tester.getRect(find.byKey(const Key('pane-tabs-1')));
    expect(second.left, closeTo(divider.right, 1));
  });

  testWidgets('a click in a pane gives it the next note', (tester) async {
    await pumpShell(tester);
    await openTwo(tester);
    await tabMenu(tester, 'note-tab-1', 'tab-menu-split-right');
    expect(w().focused, 1);
    // Back in the left pane, the tree opens there.
    final left = tester.getRect(find.byKey(const Key('pane-divider'))).left;
    await tester.tapAt(Offset(left - 60, 400));
    await settle(tester);
    expect(w().focused, 0);
    await tester.tap(noteRow('gamma.md'));
    await settle(tester);
    expect(pane(0), ['gamma.md']);
    expect(pane(1), ['beta.md']);
  });

  testWidgets('a tab moved across takes its editor along', (tester) async {
    await pumpShell(tester);
    await openTwo(tester);
    await tabMenu(tester, 'note-tab-1', 'tab-menu-split-right');
    final before = tester.state(
      find.byWidgetPredicate(
        (widget) => widget is NoteView && widget.path.endsWith('beta.md'),
      ),
    );
    // Right pane's only tab back to the left: the split closes.
    await tester.tapAt(
      tester.getCenter(
        find.descendant(
          of: find.byKey(const Key('pane-tabs-1')),
          matching: find.byKey(const Key('note-tab-0')),
        ),
      ),
      buttons: kSecondaryMouseButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('tab-menu-move')));
    await settle(tester);
    expect(w().isSplit, isFalse);
    expect(pane(0), ['alpha.md', 'beta.md']);
    final after = tester.state(
      find.byWidgetPredicate(
        (widget) => widget is NoteView && widget.path.endsWith('beta.md'),
        skipOffstage: false,
      ),
    );
    expect(identical(before, after), isTrue);
  });

  testWidgets("closing a pane's last tab closes the split", (tester) async {
    await pumpShell(tester);
    await openTwo(tester);
    await tabMenu(tester, 'note-tab-1', 'tab-menu-split-right');
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('pane-tabs-1')),
        matching: find.byKey(const Key('note-tab-close-0')),
      ),
    );
    await settle(tester);
    expect(w().isSplit, isFalse);
    expect(find.byKey(const Key('pane-divider')), findsNothing);
  });

  testWidgets('split down, the lower pane heads its own tabs', (tester) async {
    await pumpShell(tester);
    await openTwo(tester);
    await tabMenu(tester, 'note-tab-1', 'tab-menu-split-down');
    expect(w().axis, SplitAxis.down);
    final divider = tester.getRect(find.byKey(const Key('pane-divider')));
    final lower = tester.getRect(find.byKey(const Key('pane-tabs-1')));
    expect(lower.top, greaterThan(divider.top));
  });

  testWidgets('open to the side, from the tree', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.tapAt(
      tester.getCenter(noteRow('gamma.md')),
      buttons: kSecondaryButton,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-open-beside')));
    await settle(tester);
    expect(pane(0), ['alpha.md']);
    expect(pane(1), ['gamma.md']);
  });

  testWidgets('the divider drags, and the split keeps it', (tester) async {
    await pumpShell(tester);
    await openTwo(tester);
    await tabMenu(tester, 'note-tab-1', 'tab-menu-split-right');
    await tester.drag(
      find.byKey(const Key('pane-divider')),
      const Offset(-100, 0),
    );
    await settle(tester);
    expect(w().fraction, lessThan(0.5));
  });
}
