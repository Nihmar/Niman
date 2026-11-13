import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/features/features_host.dart';
import 'package:niman/src/ui/home/action_runner.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_note_action.dart';
import 'package:niman/src/ui/home/home_screen.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/quick_note_tab.dart';
import 'package:niman/src/ui/search_request.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_tab.dart';
import 'package:niman/src/ui/shell_fab.dart';
import 'package:niman/src/ui/shell_files_pane.dart';
import 'package:niman/src/ui/shell_journal_ui.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_phone_chrome.dart';
import 'package:niman/src/ui/shell_quick_note.dart';
import 'package:niman/src/ui/shell_search_slot.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_study.dart';
import 'package:niman/src/ui/shell_sync_actions.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/shell_tasks.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/shell_tree_footer.dart';
import 'package:niman/src/ui/shell_tree_menus.dart';
import 'package:niman/src/ui/shell_windows.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/todo_tab.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';
import 'package:niman/src/ui/tree_view_toggle.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The tabs' bodies (#1256): Files, Todo, Search, the quick note's
/// chooser, Home, Study and Settings, each made on its first visit and
/// kept; the tree's footer; and what Home and Search ask of the shell —
/// a search shown, a hit stepped, an event or a task opened, Settings
/// opened where it points.
final class ShellTabBodies {
  /// The bodies of [controller]'s tabs.
  new({
    required this.controller,
    required this.nav,
    required this.tabs,
    required this.selection,
    required this.workspace,
    required this.settings,
    required this.tasks,
    required this.fab,
    required this.files,
    required this.quickNote,
    required this.newItemRule,
    required this.study,
    required this.journalFlow,
    required this.journalUi,
    required this.templateFlow,
    required this.captureFlow,
    required this.treeMenus,
    required this.syncActions,
    required this.windows,
    required this.featuresHost,
    required this.unsaved,
    required this.reminders,
    required this.spellCheck,
    required this.transcription,
    required this.ocr,
    required this.openSearchNote,
    required this.openSearchHit,
    required this.showNote,
    required this.openTodo,
    required this.revealInTree,
    required this.setTreeView,
    required this.wide,
    required this.context,
    required this.update,
    required this.mounted,
  });

  /// The open library.
  final LibrarySession controller;

  /// Where the shell is: the tab on screen, the ones visited.
  final ShellNavigationState nav;

  /// The moves between destinations.
  final ShellTabSwitch tabs;

  /// What is selected, and the sidebar a search shows in.
  final ShellSelection selection;

  /// The panes, which a hit opens in.
  final ShellWorkspace workspace;

  /// The library's settings: the column, the journal's clock, the tree's view.
  final ShellSettings settings;

  /// The tasks and the calendar.
  final ShellTasks tasks;

  /// The phone's expandable +, whose scrim covers the Files body.
  final ShellFab fab;

  /// The Files pane.
  final ShellFilesPane files;

  /// The quick note's chooser.
  final ShellQuickNote quickNote;

  /// Where new notes go.
  final NewItemRule newItemRule;

  /// The decks and the Study tree (#533).
  final ShellStudy Function() study;

  /// Opens and makes journal entries (#7).
  final JournalFlow journalFlow;

  /// The journal's calendar.
  final ShellJournalUi Function() journalUi;

  /// New notes from templates, a Home action's.
  final ShellTemplateFlow templateFlow;

  /// Web pages captured as notes, a Home action's.
  final CaptureFlow captureFlow;

  /// The tree footer's New menu.
  final ShellTreeMenus treeMenus;

  /// The sync button in the tree's footer.
  final ShellSyncActions syncActions;

  /// The floating Settings window.
  final ShellWindows windows;

  /// What Settings → Features asks of the shell.
  final FeaturesHost featuresHost;

  /// The notes with unsaved edits.
  final UnsavedTracker unsaved;

  /// The tasks' reminders.
  final ReminderService reminders;

  /// The editor's spelling, which Settings sets.
  final EditorSpellCheck spellCheck;

  /// The transcription models, which Settings manages.
  final TranscriptionModels? transcription;

  /// The OCR engine, which Settings manages.
  final OcrInstallation? ocr;

  /// Opens a note the way a search result opens.
  final void Function(String path) openSearchNote;

  /// Opens a search result at the words it matched.
  final void Function(String path, List<String> terms) openSearchHit;

  /// Shows a note, the caret at an offset when there is one.
  final void Function(String path, {int? caret}) showNote;

  /// Shows the todo list.
  final VoidCallback openTodo;

  /// Shows a note as the tree's selected row.
  final void Function(String path) revealInTree;

  /// Switches the Files pane between the tree and the grid.
  final Future<void> Function(TreeView view) setTreeView;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// Where the screens and the snack bars open.
  final BuildContext Function() context;

  /// The shell's `setState`.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// All five tab bodies, in tab order: each mounts on its first visit and
  /// stays mounted() (query, results, and scroll survive a switch), while the
  /// fade only covers the incoming body — no cross-fade of two transparency
  /// layers, and no re-inflate mid-animation.
  ///
  /// Built once per shell build and handed to [ShellPhoneChrome.scaffold]
  /// by identity, so a plain tab switch reuses the instances instead of
  /// rebuilding every body (#46). Only the search slot retains layout
  /// while hidden (T-TS-10): it is the one whose show-layout costs frames;
  /// the plain lists relayout cheaply.
  List<Widget> children(LibrarySession controller) => [
    for (final tab in ShellTab.values) bodyFor(tab, controller),
  ];

  /// The body for [tab], or a placeholder until its first visit (lazy so
  /// opening a library does not inflate all five tabs up front).
  Widget bodyFor(ShellTab tab, LibrarySession controller) {
    if (!nav.visited.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      // Always scrim-wrapped (never toggled): see [ShellFab.withScrim].
      ShellTab.files => fab.withScrim(files.build(context(), controller)),
      ShellTab.todo => TodoTab(
        controller: tasks.todo,
        view: tasks.view,
        reminders: reminders,
        onAddTask: tasks.add,
        column: settings.editor.noteColumn,
        links: tasks.todoLinks,
      ),
      ShellTab.search => searchSlot(controller),
      // Empty unless the shell actually sent the user here to choose: an
      // open quick note leaves this body painted under the opening note.
      ShellTab.quickNote =>
        quickNote.choosing
            ? QuickNoteTab(
                controller: controller,
                newItemRule: newItemRule,
                onOpen: quickNote.open,
              )
            : const SizedBox.shrink(),
      ShellTab.home => HomeScreen(
        host: _homeHost(controller),
        tab: nav.tabListenable,
      ),
      ShellTab.study => study().view(context()),
      ShellTab.settings => SettingsTab(
        // A palette pick opens the tab where it points, once (#229).
        key: ValueKey(_settingsTarget),
        controller: controller,
        // The phone's Maintenance rows switch the library themselves:
        // they save the open notes first (#351).
        unsaved: unsaved,
        spellCheck: spellCheck,
        transcription: transcription,
        ocr: ocr,
        target: _settingsTarget,
        featuresHost: featuresHost,
      ),
    };
  }

  /// The Search tab's body; the slot owns which of the two shows
  /// (issue #100 moved it into [SearchSlot]).
  Widget searchSlot(LibrarySession controller, {bool tree = false}) {
    return SearchSlot(
      controller: controller,
      unsavedTracker: unsaved,
      onOpenNote: openSearchNote,
      onOpenHit: openSearchHit,
      requests: _searchRequests,
      commands: _searchCommands,
      tree: tree,
      taskEvents: tasks.events,
      onOpenTaskEvent: openTaskEvent,
      eventTimesClock: settings.journal.clockTimes,
      // Tabs, panes and the tree beside the list are a wide window's.
      hitOpens: wide()
          ? (
              newTab: (path) => workspace.show(path, newTab: true),
              beside: (path) => workspace.openBeside(path, SplitAxis.right),
              reveal: revealInTree,
            )
          : null,
    );
  }

  /// What the shell asks Search to do besides showing (#712): the field's
  /// focus and the step through the hits.
  final SearchCommands _searchCommands = SearchCommands();

  /// Steps the sidebar's hits (#712), the way `F4` / `Shift+F4` do.
  void stepSearchHits(int direction) {
    // Nothing to step: the sidebar keeps the last results, but only while
    // it is the one showing.
    if (nav.tab != ShellTab.search || !nav.visited.contains(ShellTab.search)) {
      return;
    }
    _searchCommands.stepBy(direction);
  }

  /// Puts the cursor in the search field (`Ctrl+Shift+F`, #712), showing
  /// the sidebar first on a wide window.
  void focusSearchField() {
    tabs.select(ShellTab.search);
    if (wide()) selection.showSidebar();
    // The screen may mount in this frame: ask once it has.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted()) _searchCommands.focus();
    });
  }

  /// What the Home asks Search to show (#535).
  final ValueNotifier<SearchRequest?> _searchRequests = ValueNotifier(null);

  /// Shows Search with [request]: a query typed in, or a tag's notes.
  void _showSearch(SearchRequest request) {
    _searchRequests.value = request;
    tabs.select(ShellTab.search);
  }

  /// The Home's way into the shell (#535). A note opens the way a search
  /// result does: over the tab on a phone, in the panes on a wide window.
  HomeHost _homeHost(LibrarySession controller) => HomeHost(
    controller: controller,
    todo: tasks.todo,
    calendar: tasks.calendar,
    journal: journalFlow,
    clockEventTimes: () => settings.journal.clockTimes,
    openEvent: openCalendarEvent,
    openJournal: () => journalUi().showCalendar(context()),
    openNote: openSearchNote,
    openSearch: (query) => _showSearch(SearchRequest.forText(query)),
    openTag: (tag) => _showSearch(SearchRequest.forTag(tag)),
    openTodo: openTodo,
    runAction: (action) => unawaited(
      homeActions.run(context(), action.under(controller.features.value)),
    ),
    decks: () => study().decks,
    study: (paths, title) => study().studyPaths(context(), paths, title),
  );

  /// Runs the Home's actions through the shell's own flows (#535).
  late final HomeActionRunner homeActions = HomeActionRunner(
    newNote: (context, action) => makeHomeNote(
      context,
      action,
      controller: controller,
      templates: templateFlow,
    ),
    addTask: _addHomeTask,
    openNote: openSearchNote,
    openJournal: journalFlow.openToday,
    capture: (context, action) =>
        captureFlow.capture(context, folder: action.folder),
    missing: controller.tree.missingPaths,
    tell: (message) =>
        ScaffoldMessenger.of(context())
            .showSnackBar(SnackBar(content: Text(message))),
  );

  /// Adds a task from a Home action: its project and context are written
  /// in, the caret before them.
  Future<void> _addHomeTask(HomeAction action) => tasks.add(
    text: [
      '',
      if (action.project case final project? when project.isNotEmpty)
        '+$project',
      if (action.context case final where? when where.isNotEmpty) '@$where',
    ].join(' '),
  );

  /// Opens the event's line in `calendar.txt` (#730), the caret at the
  /// line's start: the desktop's tap on an event (a phone's sheet, with
  /// Edit and Delete, comes with the writing phase).
  void openCalendarEvent(CalendarEntryEvent event) {
    showNote(calendarFileName, caret: tasks.calendarOffsetOf(event.lineIndex));
  }

  /// Opens a row of Search's tasks-and-events group (#730): a task is the
  /// task list's, an event or a goal is its line in `calendar.txt`.
  void openTaskEvent(TaskEventHit hit) {
    switch (hit.kind) {
      case TaskEventKind.task:
        openTodo();
      case TaskEventKind.event:
        openCalendarEvent(hit.event!);
      case TaskEventKind.goal:
        showNote(
          calendarFileName,
          caret: tasks.calendarOffsetOf(hit.lineIndex),
        );
    }
  }

  /// Opens the settings at [target] (#229): the floating window on a
  /// wide one, the Settings tab on a phone.
  void openSettingsAt(SettingsTarget target) {
    if (wide()) {
      unawaited(windows.openSettings(context(), target: target));
      return;
    }
    update(() => _settingsTarget = target);
    tabs.destinationSelected(ShellTab.settings);
  }

  /// Where the Settings tab opens next, once (#229).
  SettingsTarget? _settingsTarget;

  /// The desktop tree's controls at the base of its column (T-PP-22):
  /// creation, the trash and the sort order — the app-bar actions the
  /// wide layout used to carry, where the tree is the thing they act on
  /// (issue #100 moved the bar itself into [TreeFooterBar]).
  Widget treeFooter(LibrarySession controller) {
    return TourTarget(
      id: TourTargets.create,
      child: TreeFooterBar(
        controller: controller,
        onNewItem: (item) => treeMenus.newItem(context(), item),
        syncButton: syncActions.button(context(), controller),
        viewToggle: TreeViewToggle(
          view: settings.editor.treeView,
          onView: (view) => unawaited(setTreeView(view)),
        ),
        sortToggle: sortToggle(),
      ),
    );
  }

  /// The tree's sort control (T-UI-03, #726): the mockup's `unfold_more`
  /// chevrons open the menu of orders, the icon saying the direction.
  ///
  /// [withView] adds the List | Grid choices at the top of the same menu:
  /// the phone's app bar has no room for the pair beside the chevron, so
  /// the switch rides in the menu there (#727).
  Widget sortToggle({bool withView = false}) {
    return TreeSortToggle(
      sort: settings.editor.treeSort,
      onSort: (sort) => unawaited(settings.setTreeSort(sort)),
      view: withView ? settings.editor.treeView : null,
      onView: withView ? (view) => unawaited(setTreeView(view)) : null,
    );
  }

  /// Lets go of what Search was asked.
  void dispose() {
    _searchRequests.dispose();
    _searchCommands.dispose();
  }
}
