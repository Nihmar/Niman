// 0.0.8 test round: a narrow pane (a split window at 960 px) cut the
// tabs' names at the start and let the status row paint over the pane
// beside it; with the tree hidden, the first tab stuck to the sidebar
// toggle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/title_bar.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

import '../fakes/fake_window_controller.dart';

Widget _in(double width, Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, height: 60, child: child),
    ),
  ),
);

NoteTabBar _tabs(List<String> paths) => NoteTabBar(
  tabs: [for (final path in paths) WorkspaceTab(path)],
  active: 0,
  unsaved: const {},
  onActivate: (_) {},
  onClose: (_) {},
  onNew: () {},
);

NoteStatusRow _status() => NoteStatusRow(
  loading: false,
  showPreview: false,
  showWysiwyg: false,
  spellCheckAvailable: true,
  canSwitchEditorKind: true,
  wordCount: 1234,
  statusText: 'Saved',
  statusActions: const [Icon(Icons.visibility), Icon(Icons.view_column)],
  onOutline: () async {},
  onFind: () {},
  onSpellCheck: () async {},
  onToggleEditorKind: () {},
  onToggleTypewriter: () {},
);

void main() {
  testWidgets('in a narrow pane the tabs shrink, their names cut at the '
      'end, not the start', (tester) async {
    await tester.pumpWidget(
      _in(260, _tabs(['a-rather-long-name.md', 'another-long-one.md'])),
    );
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(NoteTabBar));
    for (final label in ['a-rather-long-name', 'another-long-one']) {
      final text = tester.getRect(find.text(label));
      expect(text.left, greaterThanOrEqualTo(bar.left), reason: label);
    }
    final strip = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(strip.position.pixels, 0, reason: 'nothing scrolled away');
  });

  testWidgets('with no room even for the narrowest tabs, the row scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _in(260, _tabs([for (var i = 0; i < 8; i++) 'note$i.md'])),
    );
    await tester.pumpAndSettle();
    final strip = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(strip.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('a status row too wide for its pane stays inside it', (
    tester,
  ) async {
    await tester.pumpWidget(_in(220, _status()));
    await tester.pumpAndSettle();
    // A Row painting past its box raises an overflow in tests.
    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byKey(const Key('status-row')));
    expect(row.width, lessThanOrEqualTo(220));
  });

  testWidgets('with room, the readings still sit at the right end', (
    tester,
  ) async {
    await tester.pumpWidget(_in(900, _status()));
    await tester.pumpAndSettle();
    final saved = tester.getRect(find.text('Saved'));
    expect(saved.right, greaterThan(700));
  });

  testWidgets('with the tree hidden, the first tab keeps off the toggle '
      'and over the panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTitleBar(
            title: 'Niman',
            sidebarVisible: false,
            onToggleSidebar: () {},
            window: FakeWindowController(customTitleBar: true),
            // The panes' island with the tree hidden: the rail, the base's
            // pixel and the islands' gap.
            tabsStart: _panesStart,
            tabs: (drag) => _tabs(['alpha.md']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = tester.getRect(find.byKey(const Key('toggle-sidebar')));
    // The tab's own box, its outline included, not the name inside it.
    final tab = tester.getRect(
      find.ancestor(of: find.text('alpha'), matching: find.byType(InkWell)),
    );
    expect(tab.left, _panesStart, reason: 'over the panel, not past it');
    // Room still (0.0.8 test round): the toggle's glyph ends 8 px inside
    // its box, so the eye reads some 22 px of it.
    expect(tab.left - toggle.right, greaterThanOrEqualTo(12));
  });
}

/// Where the panes' island starts with the tree hidden.
const double _panesStart = ShellRail.width + 1 + Island.gap;
