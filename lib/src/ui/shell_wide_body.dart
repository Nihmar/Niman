/// The wide shell's body (issue #100 moved it out of the shell): the
/// tree's island, the panes' and the dock's, the dividers over the gaps
/// between them, and the dock laid over the note where it has no room.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/dock/dock_overlay.dart';
import 'package:niman/src/ui/dock/dock_toggles.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/resize_divider.dart';
import 'package:niman/src/ui/shell_dock.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';
import 'package:niman/src/ui/shell_files_pane.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_study.dart';
import 'package:niman/src/ui/shell_tab_rows.dart';
import 'package:niman/src/ui/soft_keyboard_watch.dart';
import 'package:niman/src/ui/sync/sync_status.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';
import 'package:niman/src/ui/tree_header.dart';
import 'package:niman/src/ui/tree_overlay.dart';
import 'package:niman/src/ui/tree_shape.dart';

/// The wide body's layout, built from the shell's parts.
final class ShellWideBody {
  /// The body around [files], [tabRows]' row heading the panes where the
  /// window has no title bar of the app's own ([customTitleBar]), and the
  /// [dock]. The rest are what the islands hold and how wide they are.
  new({
    required this.dock,
    required this.files,
    required this.tabRows,
    required this.settings,
    required this.inZen,
    required this.tree,
    required this.dockWidth,
    required this.customTitleBar,
    required this.libraryName,
    required this.treeFolder,
    required this.onSwitchLibrary,
    required this.treeFooter,
    required this.nav,
    required this.sidebarShowsSearch,
    required this.sidebarShowsStudy,
    required this.searchSlot,
    required this.study,
    required this.panes,
    required this.zenPanes,
    required this.treeDivider,
    required this.dockDivider,
  });

  /// The right dock and its overlay (#175).
  final ShellDock dock;

  /// The Files pane, in the tree's island.
  final ShellFilesPane files;

  /// The rows of note tabs.
  final ShellTabRows tabRows;

  /// The library's editor settings: the tree's and the dock's widths.
  final ShellEditorSettings Function() settings;

  /// Whether Zen is what is on screen (#69).
  final bool Function() inZen;

  /// Where the tree's island stands, whether it shows, and how the one
  /// lying over the panes closes (#1266).
  final ({TreeShape shape, bool shown, VoidCallback close}) Function() tree;

  /// The dock's width on screen.
  final double Function() dockWidth;

  /// Whether the window has a title bar of the app's own.
  final bool Function() customTitleBar;

  /// The library's name, over the tree without a title bar (#1134).
  final String Function() libraryName;

  /// The folder the tree is on.
  final String Function() treeFolder;

  /// The tree header's switch of library.
  final VoidCallback onSwitchLibrary;

  /// The tree's controls at the base of its column (T-PP-22).
  final Widget Function(LibrarySession controller) treeFooter;

  /// The tabs visited: the search and the decks are built on their first.
  final ShellNavigationState nav;

  /// Whether the tree's island shows the search in place of the tree
  /// (#712).
  final bool Function() sidebarShowsSearch;

  /// Whether the tree's island shows the Study tree in place of the tree
  /// (#533).
  final bool Function() sidebarShowsStudy;

  /// The search, as the tree's island holds it.
  final Widget Function(LibrarySession controller) searchSlot;

  /// The decks and the Study tree.
  final ShellStudy Function() study;

  /// The panes of the wide layout (#23).
  final Widget Function(LibrarySession controller) panes;

  /// Zen's panes: the focused one alone.
  final Widget Function(LibrarySession controller) zenPanes;

  /// The draggable tree/detail divider (T-PP-21).
  final Widget Function({required bool touch}) treeDivider;

  /// The draggable panes/dock divider (#297).
  final Widget Function({required bool touch}) dockDivider;

  /// The wide body, to measure the note row against.
  final GlobalKey _wideBodyKey = GlobalKey(debugLabel: 'wide body');

  /// The tree's island, which moves between its place beside the panes and
  /// its place over them (#1266) with its state: the tree's scroll, the
  /// search's query and results.
  final GlobalKey _treeIslandKey = GlobalKey(debugLabel: 'tree island');

  /// The wide-layout body: the tree pane and the split detail pane, in
  /// [context], the shell's.
  ///
  /// The tree keeps its own controls at the base (T-PP-22), and an open
  /// note gets a header inside the detail pane carrying its name and the
  /// note controls the window app bar used to hold. Hiding the tree (the
  /// title bar's toggle) gives its width to the detail pane.
  ///
  /// Each of the three is an [Island] on the chrome's base, [Island.gap]
  /// from the window's edges and from each other, with the title bar
  /// sitting on them — no band above (#749); the dividers are the
  /// base between them. The gaps never change while the tree or the dock
  /// comes and goes, so nothing on screen moves but the edge that has to.
  /// Zen drops the base: the note takes the window edge to edge.
  Widget build(BuildContext context, LibrarySession controller) =>
      SoftKeyboardWatch(
        onChanged: (up) {
          _keyboardUp = up;
          _syncWriting();
        },
        // Rebuilt when writing starts or stops, not on each frame of the
        // keyboard's animation.
        child: ListenableBuilder(
          listenable: _writing,
          builder: (context, _) => _body(context, controller),
        ),
      );

  /// Whether a note is being written in (#1266): the keyboard up with the
  /// focus in the panes. A tablet's tree steps aside for it.
  bool get writing => _writing.value;
  final ValueNotifier<bool> _writing = ValueNotifier(false);
  bool _keyboardUp = false;
  bool _panesFocused = false;

  void _syncWriting() => _writing.value = _keyboardUp && _panesFocused;

  Widget _body(BuildContext context, LibrarySession controller) {
    final zen = inZen();
    final touch = thumbDense(Theme.of(context));
    final tree = this.tree();
    dock.settle();
    // A stack always, the overlay or not: the islands below keep their
    // place in the tree, and so their editors their state.
    return Stack(
      key: _wideBodyKey,
      fit: StackFit.expand,
      children: [
        _wideIslands(context, controller, zen: zen, touch: touch, tree: tree),
        // A tablet without the room for the tree beside the note lays it
        // over the panes, from the rail's edge (#1266).
        if (tree.shape == TreeShape.over && !zen)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Island.gap,
              0,
              Island.gap,
              Island.gap,
            ),
            child: TreeOverlay(
              open: tree.shown,
              width: settings().treeWidth,
              onDismiss: tree.close,
              island: _treeIsland(context, controller),
            ),
          ),
        // A window without room for the dock beside the note lays it over
        // the note instead, under the title bar and the rail — and under
        // the note's row, whose button stays in reach to shut it again.
        if (dock.overlayShown && !zen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: dock.toggles.rowBottom(
              within: _wideBodyKey.currentContext?.findRenderObject(),
            ),
            child: DockOverlay(
              width: settings().dockWidth,
              onDismiss: dock.closeOverlay,
              dock: dock.build(context, overlay: true),
            ),
          ),
      ],
    );
  }

  /// The wide body's islands and the dividers over their gaps.
  Widget _wideIslands(
    BuildContext context,
    LibrarySession controller, {
    required bool zen,
    required bool touch,
    required ({TreeShape shape, bool shown, VoidCallback close}) tree,
  }) {
    final beside = tree.shape == TreeShape.beside && tree.shown;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        zen ? 0 : Island.gap,
        0,
        zen ? 0 : Island.gap,
        zen ? 0 : Island.gap,
      ),
      // The dividers' grab strips lie over the row rather than in it: each
      // is wider than the gap it sits in, over the islands' edges either
      // side (#786), and only on top of them does it take the pointer there.
      child: Stack(
        fit: StackFit.expand,
        children: [
          _wideRow(context, controller, zen: zen, treeBeside: beside),
          if (beside && !zen)
            Positioned(
              left:
                  settings().treeWidth -
                  ResizeDivider.overhangFor(touch: touch),
              top: 0,
              bottom: 0,
              child: treeDivider(touch: touch),
            ),
          if (dock.shown && !zen)
            Positioned(
              right: dockWidth() - ResizeDivider.overhangFor(touch: touch),
              top: 0,
              bottom: 0,
              child: dockDivider(touch: touch),
            ),
        ],
      ),
    );
  }

  /// The tree's island: the tree, or the sidebar view in its place
  /// (#712). Keyed, so it keeps its state where it moves (#1266).
  Widget _treeIsland(BuildContext context, LibrarySession controller) {
    final showsSearch = sidebarShowsSearch();
    final showsStudy = sidebarShowsStudy();
    return KeyedSubtree(
      key: _treeIslandKey,
      child: Island(
        key: const Key('tree-island'),
        // Both stay mounted across a sidebar switch (#712): the
        // search keeps its query and results, and the tree its
        // expansion and scroll, as they did when each had a slot
        // of its own. The search keeps its layout too — it is the
        // one whose show-layout costs frames (T-TS-10).
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: showsSearch || showsStudy,
              child: Column(
                children: [
                  // Without a title bar of the app's own, nothing
                  // else says which library this is (#1134).
                  if (!customTitleBar()) ...[
                    TreeHeader(
                      library: libraryName(),
                      folder: treeFolder(),
                      height: NoteTabBar.rowHeight(
                        touch: thumbDense(Theme.of(context)),
                      ),
                      onSwitchLibrary: onSwitchLibrary,
                    ),
                    const Divider(height: 1),
                  ],
                  Expanded(child: files.build(context, controller)),
                  if (controller.sync case final sync?)
                    SyncProgressStrip(sync: sync),
                  treeFooter(controller),
                ],
              ),
            ),
            // Built on the first visit, as its slot was: the
            // search source (a background connection) is not
            // opened for a library no one searched in.
            if (nav.visited.contains(ShellTab.search))
              Visibility(
                visible: showsSearch,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: searchSlot(controller),
              ),
            // The decks (#533): built on the first visit too.
            if (nav.visited.contains(ShellTab.study))
              Offstage(offstage: !showsStudy, child: study().view(context)),
          ],
        ),
      ),
    );
  }

  /// The wide body's row: the islands, [Island.gap] apart, the gaps where
  /// the dividers lie.
  Widget _wideRow(
    BuildContext context,
    LibrarySession controller, {
    required bool zen,
    required bool treeBeside,
  }) {
    return Row(
      children: [
        if (treeBeside && !zen) ...[
          SizedBox(
            width: settings().treeWidth,
            child: _treeIsland(context, controller),
          ),
          const SizedBox(width: ResizeDivider.width),
        ],
        Expanded(
          // Keyed: the tree and the dock come and go on either side of
          // it (Zen takes both at once), and the panes must stay where
          // they are.
          key: const ValueKey('wide-panes'),
          // Hears the focus come into the panes and leave them: with the
          // keyboard up, that is a note being written in (#1266).
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (focused) {
              _panesFocused = focused;
              _syncWriting();
            },
            // One island for the panes, split or not: the split's divider
            // stays a line inside it, as the title bar's tabs divide at
            // that same x — two islands would part the panes by a gap the
            // tabs above them do not have.
            child: Island(
              key: const Key('panes-island'),
              floating: !zen,
              child: Column(
                children: [
                  // Without a title bar of the app's own (an Android
                  // tablet, a phone in landscape) the tabs head the panes
                  // instead: the same row, at the same x as the panes
                  // below it.
                  if (!customTitleBar()) ...[
                    SizedBox(
                      key: paneTabRowKey,
                      height: NoteTabBar.rowHeight(
                        touch: thumbDense(Theme.of(context)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) => tabRows.row(
                          const SizedBox.shrink(),
                          panesWidth: constraints.maxWidth,
                          chrome: true,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  Expanded(
                    child: zen ? zenPanes(controller) : panes(controller),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (dock.shown && !zen) ...[
          const SizedBox(width: ResizeDivider.width),
          TourTarget(
            id: TourTargets.dock,
            child: SizedBox(
              width: dockWidth(),
              child: Island(
                key: const Key('dock-island'),
                child: dock.build(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
