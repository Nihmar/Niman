/// The narrow shell's chrome around its tab bodies (issue #100 moved it
/// out of the shell): the app bar of the tab, its FAB, the bottom tab bar,
/// and the stack that keeps the bodies mounted.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/ocr/ocr_job_status.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/shell_fab.dart';
import 'package:niman/src/ui/shell_journal_ui.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_palette.dart';
import 'package:niman/src/ui/shell_sync_actions.dart';
import 'package:niman/src/ui/shell_tree_footer.dart';
import 'package:niman/src/ui/shell_tree_menus.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_status.dart';
import 'package:niman/src/ui/tab_body_stack.dart';
import 'package:niman/src/ui/todo_list_buttons.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';
import 'package:niman/src/ui/trash.dart';

/// The phone's tab chrome, drawn from the shell's tab state.
final class ShellPhoneChrome {
  /// The chrome of [nav]'s tabs. A tab is picked through
  /// [onDestinationSelected], a hidden one left through [onLeaveHiddenTab].
  /// Files' `+` opens [fab]'s menu, whose entries [menus] runs; Todo's adds
  /// a task through [addTodo]. The rest is what the app bars carry.
  new({
    required this.nav,
    required this.onDestinationSelected,
    required this.onLeaveHiddenTab,
    required this.fab,
    required this.menus,
    required this.addTodo,
    required this.todo,
    required this.todoView,
    required this.palette,
    required this.journalUi,
    required this.syncActions,
    required this.workspace,
    required this.openNotesButton,
    required this.sortToggle,
    required this.features,
    required this.ocrQueue,
  });

  /// The tab on screen and the tabs placed.
  final ShellNavigationState nav;

  /// A tap on a tab of the bar.
  final ValueChanged<ShellTab> onDestinationSelected;

  /// The back arrow of a hidden tab opened anyway (#536).
  final VoidCallback onLeaveHiddenTab;

  /// The expandable "+" and its menu (T-UI-05).
  final ShellFab fab;

  /// What the "+" menu's entries make.
  final ShellTreeMenus menus;

  /// Adds a task (T-TD-04).
  final Future<void> Function() addTodo;

  /// The tasks, for the Todo tab's app bar.
  final TodoController todo;

  /// What the Todo list shows: its filter and its sort (#1003).
  final TodoListView todoView;

  /// The command palette, Search's bar's way in (#206).
  final ShellPalette palette;

  /// The journal's calendar, on Files' bar.
  final ShellJournalUi journalUi;

  /// The sync's status button.
  final ShellSyncActions syncActions;

  /// The notes open: Files' bar shows their switcher while there are any.
  final ShellWorkspace workspace;

  /// The phone's badge for the notes left open (#23).
  final Widget Function() openNotesButton;

  /// The tree's sort control, with the List | Grid choice in its menu.
  final Widget Function({bool withView}) sortToggle;

  /// The library's features (#1109).
  final Features Function() features;

  /// The recognitions under way, shown above the bodies (#594).
  final OcrQueue? ocrQueue;

  /// The narrow shell: app bar for the tab + the bottom navigation bar,
  /// over [bodies], in [context], the shell's.
  ///
  /// The tab-dependent chrome (title, Files actions, FAB, nav-bar
  /// selection, and the stack's visible index) rebuilds through a
  /// [ValueListenableBuilder] on [ShellNavigationState.tabListenable], so a
  /// plain switch refreshes it without a shell-wide `setState` (#46).
  /// [bodies] are built once by the caller and reused by identity: the
  /// kept-alive bodies do not depend on the current tab, so a switch keeps
  /// their instances and their subtrees are skipped.
  Widget scaffold(
    BuildContext context, {
    required LibrarySession controller,
    required List<Widget> bodies,
  }) {
    final shellContext = context;
    return ValueListenableBuilder<ShellTab>(
      valueListenable: nav.tabListenable,
      builder: (context, tab, _) => Scaffold(
        appBar: AppBar(
          // A hidden tab opened anyway is a page, not a tab (#536): back
          // instead of a bar with nothing to select.
          leading: nav.shown(tab)
              ? null
              : BackButton(
                  key: const Key('hidden-tab-back'),
                  onPressed: onLeaveHiddenTab,
                ),
          title: Text(_tabTitle),
          actions: switch (tab) {
            ShellTab.files => _filesAppBarActions(shellContext, controller),
            // The palette is not the library's search (#206): its own
            // way in, on the bar of the tab whose results it used to
            // sit above.
            ShellTab.search => [
              IconButton(
                key: const Key('search-open-palette'),
                tooltip: AppStrings.commandPaletteTitle,
                icon: const Icon(Icons.bolt_outlined),
                onPressed: () => unawaited(palette.open(context)),
              ),
            ],
            ShellTab.todo => [
              TodoAppBarActions(controller: todo, view: todoView),
            ],
            _ => const [],
          },
        ),
        // Bodies stay mounted once visited (see TabBodyStack): the switch
        // only flips visibility and fades the incoming body in, instead of
        // rebuilding two transparency layers mid-animation. The stack itself
        // stays the direct body child on every tab: wrapping it in anything
        // conditional (like the FAB scrim was) reparents the whole subtree
        // and remounts every body, defeating the keep-alive. Only its
        // currentIndex changes here; [bodies] are the same instances across
        // a switch, so no body re-inflates.
        body: fab.measuring(switch (ocrQueue) {
          final queue? => Column(
            children: [
              OcrJobStatus(queue: queue),
              Expanded(
                child: TabBodyStack(
                  currentIndex: tab.index,
                  retainLayout: <int>{ShellTab.search.index},
                  children: bodies,
                ),
              ),
            ],
          ),
          null => TabBodyStack(
            currentIndex: tab.index,
            retainLayout: <int>{ShellTab.search.index},
            children: bodies,
          ),
        }),
        floatingActionButton: _tabFab(shellContext),
        bottomNavigationBar: switch (controller.sync) {
          _ when !nav.shown(tab) => null,
          final sync? when tab == ShellTab.files => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncProgressStrip(sync: sync),
              tabBar(),
            ],
          ),
          _ => tabBar(),
        },
      ),
    );
  }

  /// The app bar's title on each tab: the tab's own name, matching the
  /// label under the icon that got you there. The Files tab used to say
  /// "Niman", which named the app on a screen that is about the tree.
  String get _tabTitle => switch (nav.tab) {
    ShellTab.files => AppStrings.tabFiles,
    ShellTab.todo => AppStrings.todoTitle,
    ShellTab.search => AppStrings.tabSearch,
    ShellTab.quickNote => AppStrings.quickNoteTitle,
    ShellTab.settings => AppStrings.tabSettings,
    ShellTab.home => AppStrings.tabHome,
    ShellTab.study => AppStrings.tabStudy,
  };

  /// The bottom tab bar.
  ///
  /// Shown by the tab shell *and* by an open note: the tabs are how the
  /// app is navigated, so having them vanish behind a note meant going
  /// back before going anywhere.
  Widget tabBar() {
    return TourTarget(
      id: TourTargets.nav,
      child: ShellTabBar(
        destinations: nav.destinations,
        current: nav.tab,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }

  /// The current tab's FAB, or null for the tabs that have none.
  ///
  /// Files and Todo both put a `+` in the same corner, so scaling one out
  /// and the next one in reads as a flicker on a button that never moved
  /// (2026-09-08 user feedback). `Scaffold` decides whether to animate by
  /// comparing the old and new FAB's key, so one shared key here is the
  /// whole fix: the slot rebuilds in place between those two tabs and
  /// still animates on the way to a tab that has no FAB, which is right —
  /// there the button really is leaving.
  ///
  /// The inner keys stay as they were: they identify which `+` this is,
  /// to the tests and to `Scaffold`'s hero.
  Widget? _tabFab(BuildContext context) {
    final fab = switch (nav.tab) {
      ShellTab.files => _newItemFab(context),
      ShellTab.todo => _todoAddFab(),
      ShellTab.search ||
      ShellTab.quickNote ||
      ShellTab.settings ||
      ShellTab.home ||
      ShellTab.study => null,
    };
    if (fab == null) return null;
    return KeyedSubtree(key: const Key('shell-tab-fab'), child: fab);
  }

  /// The Todo tab's add FAB (2026-09-07 user feedback: the app-bar `+`
  /// moved to the standard add position).
  Widget _todoAddFab() {
    return FloatingActionButton(
      key: const Key('todo-add'),
      heroTag: 'todo-add',
      tooltip: AppStrings.todoAddTooltip,
      onPressed: addTodo,
      child: const Icon(Icons.add),
    );
  }

  /// The expandable "+" FAB (bottom-right, above the bottom nav):
  /// reveals New note / New folder mini FABs; each creates in the
  /// selected folder, root if none (T-UI-05).
  Widget _newItemFab(BuildContext context) {
    void make(NewShellItem item) => menus.newItem(context, item);
    return TourTarget(
      id: TourTargets.create,
      child: fab.button(
        onNewNote: () => make(NewShellItem.note),
        onJournalToday: () => make(NewShellItem.journal),
        onNewListNote: () => make(NewShellItem.listNote),
        onNewAudioNote: () => make(NewShellItem.audioNote),
        onNewSlides: () => make(NewShellItem.slides),
        onNewFlashcards: () => make(NewShellItem.flashcards),
        onNewKanban: () => make(NewShellItem.kanban),
        onNewFromTemplate: () => make(NewShellItem.template),
        onNewFolder: () => make(NewShellItem.folder),
        onCaptureWebPage: () => make(NewShellItem.captureWebPage),
        features: features(),
      ),
    );
  }

  /// Trash/sort actions of the Files-tab app bar (per mockup: trash +
  /// sort chevrons; the settings gear moved to the Settings tab).
  List<Widget> _filesAppBarActions(
    BuildContext context,
    LibrarySession controller,
  ) {
    return [
      // Leftmost: it comes and goes, and the row grows from the left, so
      // the buttons a thumb already knows stay where they were.
      if (workspace.value.tabs.isNotEmpty) openNotesButton(),
      // The journal's calendar is the command's too, and goes with its
      // feature (#1109): a setting, not a state, so the row closes up.
      if (commandFeatureOn(AppCommand.journalCalendar, features()))
        IconButton(
          key: const Key('open-journal'),
          tooltip: AppStrings.paletteGroupJournal,
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: () => journalUi.showCalendar(context),
        ),
      syncActions.button(context, controller),
      IconButton(
        key: const Key('open-trash'),
        tooltip: AppStrings.trashTitle,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => unawaited(openTrash(context, controller)),
      ),
      sortToggle(withView: true),
    ];
  }
}
