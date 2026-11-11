import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/tray.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/export/export_files.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/library/note_relocation.dart' show linkRewriteBatch;
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/task_link_rewriter.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/transcription/open_audio_notes.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/app_menu.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/capture/capture_services.dart';
import 'package:niman/src/ui/deferred_listenable.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/dismiss_chain.dart';
import 'package:niman/src/ui/dock/close_overlay_action.dart';
import 'package:niman/src/ui/epub_convert_flow.dart';
import 'package:niman/src/ui/expanded_folders.dart';
import 'package:niman/src/ui/feature_off.dart';
import 'package:niman/src/ui/features/features_host.dart';
import 'package:niman/src/ui/features_link.dart';
import 'package:niman/src/ui/history/history_flow.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/link_update_dialog.dart';
import 'package:niman/src/ui/mac_menu_bar.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/pinned_tab_chip.dart';
import 'package:niman/src/ui/shell_annotation_flow.dart';
import 'package:niman/src/ui/shell_commands.dart';
import 'package:niman/src/ui/shell_compare_tab.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_dock.dart';
import 'package:niman/src/ui/shell_export_flow.dart';
import 'package:niman/src/ui/shell_fab.dart';
import 'package:niman/src/ui/shell_features_intro.dart';
import 'package:niman/src/ui/shell_files_pane.dart';
import 'package:niman/src/ui/shell_home_widgets.dart';
import 'package:niman/src/ui/shell_import_flow.dart';
import 'package:niman/src/ui/shell_inbound_routes.dart';
import 'package:niman/src/ui/shell_intent_gate.dart';
import 'package:niman/src/ui/shell_journal_ui.dart';
import 'package:niman/src/ui/shell_layout.dart';
import 'package:niman/src/ui/shell_lifecycle.dart';
import 'package:niman/src/ui/shell_marked_actions.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_note_actions.dart';
import 'package:niman/src/ui/shell_note_fade.dart';
import 'package:niman/src/ui/shell_note_history.dart';
import 'package:niman/src/ui/shell_note_kind.dart';
import 'package:niman/src/ui/shell_note_panes.dart';
import 'package:niman/src/ui/shell_ocr_flow.dart';
import 'package:niman/src/ui/shell_open_notes.dart';
import 'package:niman/src/ui/shell_outside_routes.dart';
import 'package:niman/src/ui/shell_palette.dart';
import 'package:niman/src/ui/shell_personal_dictionary.dart';
import 'package:niman/src/ui/shell_phone_chrome.dart';
import 'package:niman/src/ui/shell_quick_note.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_shown_note.dart';
import 'package:niman/src/ui/shell_study.dart';
import 'package:niman/src/ui/shell_sync_actions.dart';
import 'package:niman/src/ui/shell_tab_bodies.dart';
import 'package:niman/src/ui/shell_tab_rows.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/shell_tasks.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/shell_tree_editing.dart';
import 'package:niman/src/ui/shell_tree_menus.dart';
import 'package:niman/src/ui/shell_tree_open.dart';
import 'package:niman/src/ui/shell_wide_body.dart';
import 'package:niman/src/ui/shell_wide_layout.dart';
import 'package:niman/src/ui/shell_windows.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/shell_workspace_follow.dart';
import 'package:niman/src/ui/shell_zen.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tour/tour_host.dart';
import 'package:niman/src/ui/trash.dart';
import 'package:niman/src/ui/tree_click_clock.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/ui/zen_mode.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

/// The library shell: sidebar tree + action bar on the left, detail pane
/// on the right.
final class LibraryShell extends ConsumerStatefulWidget {
  /// The shell over [controller]'s open library, with the app's services
  /// the root screen reads from its providers.
  const new({
    required this.controller,
    required this.reminders,
    required this.spellCheck,
    required this.shortcuts,
    required this.shareIn,
    required this.capture,
    required this.todoSourceFactory,
    required this.calendarSourceFactory,
    required this.unsavedTracker,
    required this.saveExportFile,
    required this.pickExportFolder,
    required this.pdfPrinter,
    required this.pdfEngineLookup,
    required this.epubMetadataProblem,
    required this.epubExport,
    required this.outsideFiles,
    required this.launchRequests,
    required this.targets,
    required this.widgetUpdater,
    required this.widgetHost,
    required this.tray,
    required this.window,
    this.transcription,
    this.ocr,
    this.ocrQueue,
    this.openNotes,
    super.key,
  });

  /// The open library.
  final LibrarySession controller;

  /// The on-screen notes registry the transcript writer checks; null
  /// skips the marking.
  final OpenAudioNotes? openNotes;

  /// The installation's transcription models (settings section); null
  /// hides it.
  final TranscriptionModels? transcription;

  /// What is installed for text recognition; null hides its area.
  final OcrInstallation? ocr;

  /// The text recognition jobs (#594); null offers no Recognize text.
  final OcrQueue? ocrQueue;

  /// The OS reminder service (notification taps open the Todo tab).
  final ReminderService reminders;

  /// The editor's spelling state (T-PP-09), passed to every [NoteView].
  final EditorSpellCheck spellCheck;

  /// The launcher quick actions (T-SC-03: each one lands on the flow its
  /// in-app control uses).
  final ShortcutService shortcuts;

  /// What other apps share into Niman (#40): text to the quick note, a
  /// file imported into the library.
  final ShareInService shareIn;

  /// How a captured page is read, and the captures made off screen
  /// (#531).
  final CaptureServices capture;

  /// Builds the todo file source per library root (overridden with a
  /// fake in widget tests).
  final TodoSource Function(String root) todoSourceFactory;

  /// Builds the calendar file source per library root (a widget-test seam,
  /// as the todo one is).
  final CalendarSource Function(String root) calendarSourceFactory;

  /// The open notes' unsaved edits, which the window's close guard reads
  /// (T-PP-11); passed down to every [NoteView].
  final UnsavedTracker unsavedTracker;

  /// Where an export is written (#24); the tests hand in their own.
  final SaveExportFile saveExportFile;

  /// Where a folder's export is written (#24).
  final PickExportFolder pickExportFolder;

  /// What prints a note's PDF (#63); a fake in the tests, where no engine
  /// can start.
  final PdfPrinter pdfPrinter;

  /// The browser a folder's PDF zip prints with, looked up on demand: a
  /// `Future` so the chooser can wait for the answer instead of reading a
  /// null that is only the search still running.
  final Future<String?> Function() pdfEngineLookup;

  /// Why a folder's book has no metadata source (#303, E3), asked before
  /// its EPUB export starts so the user can stop and add an `index.md`.
  final EpubMetadataLookup epubMetadataProblem;

  /// Builds a note's EPUB book (#303); a seam, so a widget test can watch
  /// the working dialog without the real builder's isolate.
  final EpubNoteExport epubExport;

  /// The files open outside any library (#77).
  final OutsideFiles outsideFiles;

  /// Files and actions launches asked for (#41).
  final LaunchRequests launchRequests;

  /// The home-screen widget taps (issue 6: each one lands on the tab or
  /// note its widget shows, switching libraries first when it points
  /// elsewhere).
  final WidgetTargetService targets;

  /// Pushes todo snapshots to the home-screen widgets (issue 6).
  final WidgetUpdater widgetUpdater;

  /// Lists the placed widget instances for adoption (issue 6).
  final WidgetHostService widgetHost;

  /// The desktop tray's quick actions (T-PP-06b): the same four flows the
  /// launcher publishes, on a third surface.
  final TrayService tray;

  /// The platform window; a tray activation brings it back to the front.
  final WindowController window;

  @override
  ConsumerState<LibraryShell> createState() => _LibraryShellState();
}

final class _LibraryShellState extends ConsumerState<LibraryShell>
    with WidgetsBindingObserver {
  final ExpandedFolders _expanded = ExpandedFolders();
  bool _busy = false;

  /// What is selected and what shows, and what the note about to open is
  /// asked (#1256): every transition between screens goes through it, and
  /// the shell follows what it says changed.
  late final ShellSelection _selection = ShellSelection(
    nav: _nav,
    expanded: _expanded,
  )..addListener(_onSelectionChanged);

  /// The selection moved: a note opened is asked its kind afresh and fades
  /// in over the phone's tabs; one left gives the tabs back at once.
  void _onSelectionChanged() {
    switch (_selection.shift) {
      case NoteShift.opened:
        _kind.reset();
        _noteFade.opened();
      case NoteShift.closed:
        _kind.reset();
        _noteFade.closed();
      case NoteShift.none:
    }
    _rebuild();
  }

  /// What a frame the shell draws costs it (#324): the region above the two
  /// panes — the title bar, the tabs, the rail, the tree, the settings page.
  ///
  /// The editor and the read pane report their own share of a frame (#316,
  /// #323); a frame that misses with both under their bars had no line of its
  /// own, so the shell names it. Nothing of it runs unless `NIMAN_FRAMES` is
  /// set (see [FrameCost]).
  final FrameCost _frameCost = shellFrameCost();

  /// Where the shell is: the tab on screen, the tabs placed, the ones
  /// visited, where Back goes, the content tab pinned in a pane (issue
  /// #100 moved it into [ShellNavigationState]).
  late final ShellNavigationState _nav = ShellNavigationState(
    features: () => _features,
  );

  /// The tab on screen ([ShellNavigationState.tab]): a plain switch moves
  /// only its notifier (#46).
  ShellTab get _tab => _nav.tab;

  /// The moves between the destinations (#1256): a tab picked, the layout
  /// placed again, a content tab pinned, the phone's note closed.
  late final ShellTabSwitch _tabs = ShellTabSwitch(
    nav: _nav,
    selection: _selection,
    workspace: _workspace,
    reviewTab: _reviewTab,
    compare: _compare,
    noteFade: _noteFade,
    fab: _fab,
    fullScreen: _immersive.fullScreen,
    shellFocus: _shellFocus,
    wide: () => _wide,
    openQuickNote: () => _quickNote.openFromTile(),
    openSettings: () => unawaited(_windows.openSettings(context)),
    update: setState,
    mounted: () => mounted,
  );

  /// The quick note's tile, tab and chooser, and the text shared into
  /// Niman waiting for it (#1256).
  late final ShellQuickNote _quickNote = ShellQuickNote(
    controller: widget.controller,
    unsaved: widget.unsavedTracker,
    selection: _selection,
    nav: _nav,
    tabs: _tabs,
    guard: _guard,
    wide: () => _wide,
    update: setState,
    mounted: () => mounted,
  );

  /// The tree's rows and the Files pane's tiles opened (#1256).
  late final ShellTreeOpen _treeOpen = ShellTreeOpen(
    selection: _selection,
    workspace: _workspace,
    nav: _nav,
    clock: () => ref.read(treeClickClockProvider)(),
    wide: () => _wide,
    desktop: () => _desktop,
    panesShowNotes: () => _panesShowNotes,
    notePreview: () => _shown.preview,
    update: setState,
  );

  /// The library's features (#1109): every surface of the shell asks this,
  /// and none keeps a boolean of its own.
  Features get _features => widget.controller.features.value;

  /// Whether a note opened now would land in a pane the user can see:
  /// the panes are the files slot, and no content tab paints over them
  /// (#712).
  bool get _panesShowNotes =>
      _wideLayout.filesSlotVisible && !_tabs.contentTabShows;

  /// Whether something pinned — Home or Todo, a version, a study — covers
  /// the notes of [pane]: the chip, not a note tab, is what it shows.
  bool _chipCovers(int pane) =>
      (_tabs.contentTabShows && pane == _tabs.contentPaneShown) ||
      _compare.shownIn(pane) ||
      _reviewIn(pane);

  /// The open library's personal dictionary (issue #60).
  late final ShellPersonalDictionary _personalDictionary =
      ShellPersonalDictionary(
        spellCheck: widget.spellCheck,
        mounted: () => mounted,
      );

  /// Shows the todo list, wherever this layout keeps it.
  ///
  /// The narrow bottom bar and the wide rail both own a Todo tab, so this
  /// only selects it. Reminder taps land here, so a tap opens the app on
  /// the list with no hint missing of why.
  void _openTodo() {
    _tabs.select(ShellTab.todo);
  }

  /// The sync surfaces: the status button and the screens behind it
  /// (issue #100 moved the how of them into [ShellSyncActions]).
  late final ShellSyncActions _syncActions = ShellSyncActions(
    unsaved: widget.unsavedTracker,
    onShowTrash: _openTrash,
  );

  /// What a way in from outside asks before it opens a screen: a shortcut,
  /// a notification or a widget tap for a feature that is off says so in
  /// one sentence (#1109).
  late final ShellIntentGate _intents = ShellIntentGate(
    features: widget.controller.features,
    say: (feature) {
      if (!mounted) return;
      showFeatureOff(context, feature, openFeatures: _openFeaturesFromWidget);
    },
  );

  /// Where a notification, a launcher action or a share leads, tapped
  /// while the shell is up or carried by a cold start (issue #100 moved
  /// them into [ShellOutsideRoutes]).
  late final ShellOutsideRoutes _outside = ShellOutsideRoutes(
    reminders: widget.reminders,
    shortcuts: widget.shortcuts,
    shareIn: widget.shareIn,
    capture: widget.capture,
    intents: _intents,
    featuresIntro: _featuresIntro,
    imports: _imports,
    creates: _createFlow,
    journal: _journalFlow,
    journalUi: _journalUi,
    openTodo: _openTodo,
    addTodo: _tasks.add,
    openQuickNote: _quickNote.openFromTile,
    openRecognizedText: _openRecognizedText,
    openNote: (path) => _openNoteFromLink(path, null),
    revealFolder: _revealFolder,
  );

  /// The home-screen widgets of this library: pushes out, taps back in
  /// (issue #100 moved the how of it into [ShellHomeWidgets]).
  late final ShellHomeWidgets _homeWidgets = ShellHomeWidgets(
    controller: widget.controller,
    targets: widget.targets,
    updater: widget.widgetUpdater,
    host: widget.widgetHost,
    todoSnapshot: () => _tasks.todo.snapshot,
    decks: () async => switch (_study.decks) {
      final catalog? when catalog.loaded => catalog.summaries,
      _ => null,
    },
    openTodo: _openTodo,
    openStudy: () => _tabs.destinationSelected(ShellTab.study),
    openFeatures: _openFeaturesFromWidget,
    onRequest: _featuresIntro.requested,
    openNote: _openNoteFromLink,
    mounted: () => mounted,
    allows: _intents.allows,
    onTargetBlocked: () =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.closeSaveFailed))),
    unsaved: widget.unsavedTracker,
  );

  /// Where "Open Features" lands (#1109): on a home-screen widget that is
  /// off, and on the sentence a shortcut or a notification for a feature
  /// that is off says. Settings → Features, the way the palette's link
  /// opens it: the screen is opened for its own sake, so the introduction's
  /// flag is left as it was.
  void _openFeaturesFromWidget() => _bodies.openSettingsAt(featuresTarget);

  /// The open library's settings as the shell paints with them: the
  /// editor's, the quick note, the journal, the links (#1256). The shell
  /// rebuilds when they change.
  late final ShellSettings _settings = ShellSettings(
    controller: widget.controller,
    spellCheck: widget.spellCheck,
  )..addListener(_rebuild);

  /// Rebuilds for a change a collaborator reports.
  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Reads the library's settings again, and places the navigation it
  /// lays out.
  Future<void> _refreshEditorSettings() async {
    _personalDictionary.follow(widget.controller);
    final layout = await _settings.refresh();
    if (mounted && layout != null && layout != _nav.layout) {
      _tabs.setNavigation(layout);
    }
  }

  /// Switches the Files pane between the tree and the grid (#727). The
  /// grid starts in the tree's selection — the selected folder, or the
  /// selected note's folder — every time it is switched to, and keeps that
  /// folder while it is the pane on screen.
  Future<void> _setTreeView(TreeView next) async {
    if (next == _settings.editor.treeView) return;
    if (next == TreeView.grid) _files.gridFromTree();
    await _settings.setTreeView(next);
  }

  /// Carries focus for the app accelerators (T-PP-10) when nothing else
  /// wants it, so a keyboard-only tab switch is followed by a working next
  /// one: [FocusManager] would otherwise leave nothing focused.
  final FocusNode _shellFocus = FocusNode(debugLabel: 'app shortcuts');

  /// Takes the focus back when it falls to nothing on a wide window.
  ///
  /// The preview's eye, a note closing, the preview opening: each lets
  /// the focus go, and it lands on the route's scope, above the shell,
  /// where no key reaches the bindings — not the next command, and not
  /// the Esc that leaves Zen (#69). The phone is left alone: there,
  /// focus is the software keyboard.
  void _reclaimFocus() {
    if (!mounted || !_wide || _shellFocus.hasFocus) return;
    if (FocusManager.instance.primaryFocus is! FocusScopeNode) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _shellFocus.requestFocus();
  }

  /// Whether the Search tab shows the Tags screen (T-M3-06) instead of
  /// the search box; the tabs button flips it and back.

  /// The library's tasks and calendar: the two controllers, the links of
  /// the tasks, the Todo list's view and a note's task list (#1256).
  late final ShellTasks _tasks = ShellTasks(
    session: widget.controller,
    reminders: widget.reminders,
    todoSourceFactory: widget.todoSourceFactory,
    calendarSourceFactory: widget.calendarSourceFactory,
    linkSource: () => _settings.linkSource,
    suggester: () => _settings.wikilinkSuggester,
    linkPreview: () => _settings.editor.linkPreview,
    newItemLocation: () => _settings.editor.newItemLocation,
    openNote: _openNoteFromLink,
    guard: _guard,
    context: () => context,
  );

  /// Making new things in the library: the FAB, the tree footer's menu
  /// and the row menu all run these (issue #100 moved the how of them
  /// into [ShellCreateFlow]).
  late final ShellCreateFlow _createFlow = ShellCreateFlow(
    controller: widget.controller,
    newItemRule: _newItemRule,
    guard: _guard,
    onCreated: _onItemCreated,
    nameInPlace: _treeEditing.nameInPlace,
  );

  /// The rows renamed and made in place in the Files pane (#707, #712;
  /// issue #100 moved them into [ShellTreeEditing]).
  late final ShellTreeEditing _treeEditing = ShellTreeEditing(
    expanded: _expanded,
    paneOnScreen: () =>
        _desktop &&
        _wide &&
        _selection.sidebarVisible &&
        _wideLayout.filesSlotVisible &&
        !_wideLayout.sidebarShowsView,
    gridFolder: () => _files.gridOn ? _files.gridStart : null,
    renameTo: (path, name) => _rowActions.renameTo(path, name),
    update: setState,
    mounted: () => mounted,
  );

  /// Web pages captured as notes (#531).
  late final CaptureFlow _captureFlow = CaptureFlow(
    controller: widget.controller,
    services: widget.capture,
    // A quote appended to the note on screen lands between its buffer's
    // save and its re-read, as shared text does in the quick note (#635).
    saveOpen: () => widget.unsavedTracker.saveAll(),
    onAppended: () {
      if (mounted) _selection.reload();
    },
    attachmentsFolder: () => _settings.editor.attachmentsFolder,
    linkType: () => _settings.editor.linkType,
    onCaptured: (path) => _openNoteFromLink(path, null),
    // A picture, a PDF or a book on screen is no note to append to (#636).
    openNote: () => _shown.isAttachment ? null : _shown.path,
  );

  /// Opens what a create just made: a note takes the screen, a folder
  /// only takes the selection.
  void _onItemCreated(CreatedItem item) {
    if (!mounted) return;
    if (!item.isDir) return _showNote(item.path);
    _selection.selectFolder(item.path, expand: false);
  }

  /// The exports: a note, a folder, the library (#24).
  late final ShellExportFlow _exportFlow = ShellExportFlow(
    controller: widget.controller,
    guard: _guard,
    saveOpen: () => widget.unsavedTracker.saveAll(),
    saveExportFile: widget.saveExportFile,
    pickExportFolder: widget.pickExportFolder,
    pdfPrinter: widget.pdfPrinter,
    pdfEngineLookup: widget.pdfEngineLookup,
    epubMetadataProblem: widget.epubMetadataProblem,
    epubExport: widget.epubExport,
    linkSource: () => _settings.linkSource,
    todoBlocks: _tasks.exportBlocks,
    wide: () => _wide,
    shownNote: () => _shown.path,
  );

  /// Converting a book into notes (#1138): from its row in the reader, the
  /// tree, the palette, a drop or a share.
  late final EpubConvertFlow _epubConvert = EpubConvertFlow(
    session: widget.controller,
    reveal: _revealFolder,
    open: (note) => _openNoteFromLink(note, null),
  );

  void _convertBook(String path) => unawaited(_epubConvert.run(context, path));

  /// Shares, Notion exports, books and folders brought in from outside.
  late final ShellImportFlow _imports = ShellImportFlow(
    controller: widget.controller,
    guard: _guard,
    capture: _captureFlow,
    epubConvert: _epubConvert,
    shareText: _quickNote.share,
    newItemFolder: () => _newItemRule.folder,
    reveal: _revealFolder,
    openNote: (path) => _openNoteFromLink(path, null),
  );

  /// What a tree row's menu choice does: rename, move, delete, pin, open
  /// outside the app (issue #100 moved them into [ShellRowActions]).
  /// What several marked tree rows do together (#712).
  late final ShellMarkedActions _markedActions = ShellMarkedActions(
    _rowActions,
  );

  /// The tree's and the grid's menus: a row's, the empty space's, and the
  /// footer's New menu (issue #100 moved them into [ShellTreeMenus]).
  late final ShellTreeMenus _treeMenus = ShellTreeMenus(
    rows: _rowActions,
    exports: _exportFlow,
    journal: _journalFlow,
    capture: _captureFlow,
    features: () => _features,
    offersOcr: () => _offersOcr,
    wide: () => _wide,
  );

  late final ShellRowActions _rowActions = ShellRowActions(
    renameInPlace: _treeEditing.startRename,
    // Under "ask", the question is the shell's to put (#848).
    confirmLinks: (notes) async =>
        mounted && await askLinkUpdate(context, notes),
    // The rewrite lands after the move's own reload (#859).
    onLinksRewritten: () {
      if (mounted) _selection.reload();
    },
    onLinksProgress: _showLinksProgress,
    // The links in the tasks follow the move too (#1152).
    taskLinks: TaskLinkRewriter(
      map: _tasks.links,
      write: _tasks.todo.replaceLines,
    ),
    controller: widget.controller,
    guard: _guard,
    saveOpen: () => widget.unsavedTracker.saveAll(),
    creates: _createFlow,
    templates: _templateFlow,
    selectedPath: () => _selection.path,
    onMoved: (from, to) {
      // The open notes' editors follow the rename, and are told where they
      // came from for the frame that shows them under the new name (#1076).
      _shown.keys.moved(from, to);
      _kind.moved(from, to);
      WidgetsBinding.instance.addPostFrameCallback((_) => _shown.keys.settle());
      _workspace.moved(from, to);
      // The folders open under it stay open under its new name (#1069),
      // and the selection follows a rename that is about it. The move
      // rewrote the links other notes hold to it, on disk (#507): an open
      // one re-reads its file, which a clean buffer adopts — and every
      // buffer is clean, the move having saved them first.
      _selection
        ..moved(from, to)
        ..reload();
      // The grid's own folder follows a rename or a move of it, or of a
      // folder above it (#727): F2 with no tile under the cursor renames
      // the selection, which is the folder shown.
      _files.moved(from, to);
    },
    onDeleted: (path) {
      _workspace.deleted(path);
      final wide = _wide;
      // Deleting the open note closes it: the tabs show at once.
      if (!wide) _noteFade.closed();
      _selection.deleted(path, wide: wide);
    },
    onOpenInNewTab: (path) => _workspace.show(path, newTab: true),
    onOpenBeside: (path) => _workspace.openBeside(path, SplitAxis.right),
    onHistory: _openHistory,
    onExport: (path, anchor) =>
        _exportFlow.runNoteExport(context, path, anchor: anchor),
    onExportFolder: (path, anchor) => _exportFlow.runFolderExport(
      context,
      path,
      library: false,
      anchor: anchor,
    ),
    onRecognize: _recognize,
    onConvertBook: (path) {
      if (widget.controller.root case final root?) {
        _convertBook(p.join(root, path));
      }
    },
  );

  /// Note creation from the library's templates (#51, T-M4-07): the flow
  /// owns the picker, the questions, the directives, the render and the
  /// file; the shell keeps the selection state it reads through callbacks
  /// and the open that follows.
  late final ShellTemplateFlow _templateFlow;

  /// Opens and makes journal entries (#7).
  late final JournalFlow _journalFlow;

  /// What reaches the shell from outside while it is up, and where each
  /// leads (#1256): listened to in [initState], cancelled in [dispose].
  late final ShellInboundRoutes _inboundRoutes = ShellInboundRoutes(
    controller: widget.controller,
    workspace: _workspace,
    selection: _selection,
    unsaved: widget.unsavedTracker,
    personalDictionary: _personalDictionary,
    homeWidgets: _homeWidgets,
    reminders: widget.reminders,
    ocrQueue: widget.ocrQueue,
    ocrFlow: () => _ocrFlow,
    shortcuts: widget.shortcuts,
    shareIn: widget.shareIn,
    tray: widget.tray,
    window: widget.window,
    launchRequests: widget.launchRequests,
    outside: _outside,
    imports: _imports,
    captureFlow: _captureFlow,
    openPath: _openPath,
    onRequest: _featuresIntro.requested,
    context: () => context,
    mounted: () => mounted,
  );

  /// The introduction of Settings → Features (#1109): shown once, on a
  /// normal open of a library that has not been through it. What
  /// [_inboundRoutes] marks as a request from outside, and what a launch
  /// carried, keeps it away.
  late final ShellFeaturesIntro _featuresIntro = ShellFeaturesIntro(
    controller: widget.controller,
    open: (introduction) =>
        unawaited(_windows.openFeaturesIntroduction(context, introduction)),
    mounted: () => mounted,
  );

  /// What Settings → Features asks of this shell (#1109): how many
  /// reminders a switch cancelled, from the todo controller that follows
  /// the switches.
  late final FeaturesHost _featuresHost = FeaturesHost(
    featureReconcile: () => _tasks.todo.featureReconcile,
  );

  /// The open notes' kinds as their views report them, and the raw editor
  /// shown in place of a kind's GUI (T-TK-02, T-TK-05; issue #100 moved
  /// them into [ShellNoteKind]).
  late final ShellNoteKind _kind = ShellNoteKind(
    features: () => _features,
    update: setState,
    mounted: () => mounted,
  );

  void _openNoteFromLink(String path, String? anchor) {
    const AppLogger(name: 'links').debug(
      'shell open request: $path anchor=${anchor == null ? '-' : '"$anchor"'} '
      '(current tab ${_tab.name})',
    );
    _showNote(path, anchor: anchor, followsLink: true);
  }

  /// Shows the note at [path] (library-relative): the one way the shell
  /// opens a note, whoever asks (#709, #710). It selects the note, keeps
  /// the tab it was opened from for the way back and, on a wide window,
  /// brings Files forward — the only slot a note shows in there — so a
  /// note opened from the Home, the Todo list or the search does not
  /// open out of sight behind it.
  ///
  /// [anchor] is a heading to land on, [caret] a template `{{cursor}}`
  /// offset (#53), [preview] opens the note in its preview (a template's
  /// `open` directive, #51). [followsLink] counts a link followed: a PDF
  /// or a book goes back to the link's place (#282).
  void _showNote(
    String path, {
    String? anchor,
    int? caret,
    List<String>? find,
    bool preview = false,
    bool followsLink = false,
  }) {
    // A note opened right now shows only its preview: the IME has no
    // target and must go before the transition, or its resize lands
    // mid-fade.
    if (_shown.preview) FocusManager.instance.primaryFocus?.unfocus();
    _selection.open(
      path,
      request: OpenRequest(anchor: anchor, caret: caret, find: find),
      preview: preview,
      followsLink: followsLink,
      bringFiles: _wide && !_panesShowNotes,
    );
  }

  /// Reads back what was left open in the library, and the tree as it was:
  /// the folders that were expanded, and the ones above the note on screen
  /// (#1069). From then on the tree's expansion is kept with the workspace.
  Future<void> _restoreWorkspace() async {
    final saved = await _workspace.load();
    if (!mounted) return;
    setState(() {
      _expanded.addAll(saved.expanded);
      if (_workspace.value.activePath case final shown?) {
        _expanded.addWithAncestors(parentOf(shown));
      }
    });
    _expanded.persistTo(
      (folders) => _workspace.controller.update((w) => w.withExpanded(folders)),
    );
  }

  /// Whether the shell is the wide one: the tabs' layout (#23). A phone
  /// never is, whichever way it is turned (#849).
  bool get _wide => isWideShell(context);

  /// Whether the window was wide when the dependencies last changed: a
  /// crossing of the breakpoint is told by it (#770).
  bool? _wasWide;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wide = _wide;
    if (wide && _wasWide == false) _tabs.becameWide();
    _wasWide = wide;
  }

  /// The note on screen: which it is, how its tab shows it, the view that
  /// edits it (#1256).
  late final ShellShownNote _shown = ShellShownNote(
    workspace: _workspace,
    selection: _selection,
    settings: _settings,
    features: () => _features,
    wide: () => _wide,
  );

  /// What the shell does to the note on screen: its menu, its bar, the
  /// tidy, the zoom, the deck's and the slides' entries (#1256).
  late final ShellNoteActions _noteActions = ShellNoteActions(
    controller: widget.controller,
    shown: _shown,
    kind: _kind,
    settings: _settings,
    selection: _selection,
    tasks: _tasks,
    unsaved: widget.unsavedTracker,
    window: widget.window,
    exports: _exportFlow,
    rows: _rowActions,
    palette: () => _palette,
    read: ref.read,
    guard: _guard,
    showPanel: _showPanel,
    openHistory: _openHistory,
    recognize: _recognize,
    offersOcr: () => _offersOcr,
    paletteByTouch: () => _paletteByTouch,
    features: () => _features,
    wide: () => _wide,
    context: () => context,
    update: setState,
    mounted: () => mounted,
  );

  /// The note views: the phone's full-screen note, the wide window's
  /// panes (#1256).
  late final ShellNotePanes _notePanes = ShellNotePanes(
    controller: widget.controller,
    workspace: _workspace,
    selection: _selection,
    settings: _settings,
    shown: _shown,
    kind: _kind,
    noteActions: _noteActions,
    tabs: _tabs,
    nav: _nav,
    tabRows: _tabRows,
    compare: _compare,
    study: () => _study,
    reviewIn: _reviewIn,
    immersive: _immersive,
    journalUi: _journalUi,
    annotations: _annotations,
    annotating: () => _annotating,
    annotate: _annotate,
    ocrActions: () => _ocrActions,
    convertBook: _convertBook,
    tasks: _tasks,
    unsaved: widget.unsavedTracker,
    spellCheck: widget.spellCheck,
    window: widget.window,
    ocrQueue: widget.ocrQueue,
    shellFocus: _shellFocus,
    dockToggle: _dockToggle,
    dockShown: () => _dockShown,
    createFlow: _createFlow,
    templateFlow: _templateFlow,
    palette: _palette,
    openSearchNote: _openSearchNote,
    openNote: _openNoteFromLink,
    tabBodyFor: _bodies.bodyFor,
    wide: () => _wide,
    context: () => context,
    mounted: () => mounted,
  );

  /// The tabs' bodies, the tree's footer, and what Home and Search ask of
  /// the shell (#1256).
  late final ShellTabBodies _bodies = ShellTabBodies(
    controller: widget.controller,
    nav: _nav,
    tabs: _tabs,
    selection: _selection,
    workspace: _workspace,
    settings: _settings,
    tasks: _tasks,
    fab: _fab,
    files: _files,
    quickNote: _quickNote,
    newItemRule: _newItemRule,
    study: () => _study,
    journalFlow: _journalFlow,
    journalUi: () => _journalUi,
    templateFlow: _templateFlow,
    captureFlow: _captureFlow,
    treeMenus: _treeMenus,
    syncActions: _syncActions,
    windows: _windows,
    featuresHost: _featuresHost,
    unsaved: widget.unsavedTracker,
    reminders: widget.reminders,
    spellCheck: widget.spellCheck,
    transcription: widget.transcription,
    ocr: widget.ocr,
    openSearchNote: _openSearchNote,
    openSearchHit: _openSearchHit,
    showNote: _showNote,
    openTodo: _openTodo,
    revealInTree: _revealInTree,
    setTreeView: _setTreeView,
    wide: () => _wide,
    context: () => context,
    update: setState,
    mounted: () => mounted,
  );

  /// The commands: what each does, and which can run now (#155, #1256).
  late final ShellCommands _commands = ShellCommands(
    controller: widget.controller,
    selection: _selection,
    workspace: _workspace,
    settings: _settings,
    shown: _shown,
    kind: _kind,
    noteActions: _noteActions,
    tabs: _tabs,
    bodies: _bodies,
    tasks: _tasks,
    quickNote: _quickNote,
    createFlow: _createFlow,
    captureFlow: _captureFlow,
    exportFlow: _exportFlow,
    epubConvert: _epubConvert,
    journalFlow: _journalFlow,
    journalUi: () => _journalUi,
    immersive: _immersive,
    noteHistory: _noteHistory,
    rows: _rowActions,
    windows: _windows,
    dock: _dock,
    compare: _compare,
    reviewTab: _reviewTab,
    palette: () => _palette,
    ocrFlow: () => _ocrFlow,
    treeFocus: _treeFocus,
    ref: ref,
    guard: _guard,
    openTodo: _openTodo,
    recognize: _recognize,
    openHistory: _openHistory,
    openPath: _openPath,
    revealInTree: _revealInTree,
    chipCovers: _chipCovers,
    activateTab: _activateTab,
    reviewIn: _reviewIn,
    zenPossible: () => _zenPossible,
    features: () => _features,
    wide: () => _wide,
    context: () => context,
    mounted: () => mounted,
  );

  /// The wide window's slots, dividers and widths, and its Back (#1256).
  late final ShellWideLayout _wideLayout = ShellWideLayout(
    nav: _nav,
    tabs: _tabs,
    quickNote: _quickNote,
    wideBody: () => _wideBody,
    bodies: _bodies,
    settings: _settings,
    selection: _selection,
    dock: _dock,
    immersive: _immersive,
    reviewTab: _reviewTab,
    compare: _compare,
    workspace: _workspace,
    files: _files,
    tabRows: _tabRows,
    wide: () => _wide,
    context: () => context,
  );

  /// The phone's full-screen note fading in over the tabs (issue #4;
  /// issue #100 moved it into [ShellNoteFade]).
  late final ShellNoteFade _noteFade = ShellNoteFade(
    noteOnScreen: () =>
        _selection.path != null && !_selection.isDir && !_selection.treeVisible,
    update: setState,
    mounted: () => mounted,
  );

  /// The notes open in this library on this device (issue #23): for now
  /// the one the shell shows, kept current and kept for the next launch.
  late final ShellWorkspace _workspace = ShellWorkspace(widget.controller);

  late final ShellOpenNotes _openNotes = ShellOpenNotes(
    workspace: _workspace,
    selection: _selection,
    tabs: _tabs,
    createFlow: _createFlow,
    changes: _tabsListenable,
    unsaved: _unsavedRelPaths,
    open: (path) => _openNoteFromLink(path, null),
    context: () => context,
  );

  /// The right dock and the phone's panel sheets.
  late final ShellDock _dock = ShellDock(
    workspace: _workspace,
    controller: widget.controller,
    windowWidth: () => MediaQuery.sizeOf(context).width,
    wide: () => _wide,
    panelNote: () => _shown.handle,
    journalBrowser: (context) =>
        _journalUi.browser(context, focusDay: _shown.journalDay),
    tasks: () => _tasks.notes,
    // All versions: the page, whatever the window.
    onOpenHistory: (path) => unawaited(_openHistoryPage(path)),
    onOpenNoteFromLink: (path) => _openNoteFromLink(path, null),
    onOpenVersion: (path, version) => unawaited(_compare.open(path, version)),
    onChanged: _rebuild,
  );

  /// The study beside the deck (#533, decision 9): a tab of the pane
  /// [ShellWideLayout.placeReview] picks, its chip at the end of that
  /// pane's row.
  late final ReviewTab _reviewTab = ref.read(reviewTabProvider);

  /// A version of a note compared with the note, as a tab of a pane
  /// (#712; issue #100 moved it into [ShellCompareTab]).
  late final ShellCompareTab _compare = ShellCompareTab(
    workspace: _workspace,
    unsaved: widget.unsavedTracker,
    reviewTab: _reviewTab,
    reviewPane: () => _reviewPaneShown,
    update: setState,
    mounted: () => mounted,
  );

  /// Which pane draws the study: the one it opened in, or pane 0 when the
  /// window is not split any more.
  int get _reviewPaneShown =>
      _workspace.value.isSplit ? _reviewTab.pane ?? 0 : 0;

  /// Whether [pane] shows the study now.
  bool _reviewIn(int pane) =>
      _wide && _reviewTab.shows && pane == _reviewPaneShown;

  void _onReviewTab() {
    if (!mounted) return;
    if (_reviewTab.run != null && _reviewTab.pane == null) {
      _wideLayout.placeReview();
    }
    if (_reviewTab.shows) {
      FocusManager.instance.primaryFocus?.unfocus();
      // A study opened over the compare tab's pane covers it.
      if (_compare.paneShown == _reviewPaneShown) _compare.hide();
    }
    setState(() {});
  }

  /// The decks, the Study tree and the study beside the deck (#533).
  ShellStudy get _study => _studyMade ??= ShellStudy(
    controller: widget.controller,
    reviewTab: _reviewTab,
    workspace: _workspace,
    read: ref.read,
    onCounted: () => _homeWidgets.pushStudy(),
    showNote: _showNote,
    openDeck: (path) =>
        _wide ? _treeOpen.show(path, newTab: false) : _showNote(path),
    newDeck: () => unawaited(_createFlow.createFlashcards(context)),
    mounted: () => mounted,
  );

  ShellStudy? _studyMade;

  /// Back and forward through the notes shown (#700).
  late final NoteHistoryNavigator _noteHistory = NoteHistoryNavigator(
    workspace: _workspace,
    missing: widget.controller.missingPaths,
    show: (path) {
      if (mounted) _openSearchNote(path);
    },
  );

  /// The library's name: what the title bar reads over the tree, once the
  /// notes' names are on their tabs (#23).
  String get _libraryName {
    final root = widget.controller.root;
    return root == null ? AppStrings.appTitle : p.basename(root);
  }

  /// The pinned chips at the end of [pane]'s row (#712), in their order:
  /// the study, the version, the content tab.
  List<Widget> _pinnedChips(int pane) => [
    if (_reviewTab.run != null && pane == _reviewPaneShown)
      _study.chip(pane, selected: _reviewIn(pane)),
    if (_compare.heldIn(pane)) _compare.chip(pane),
    if (_nav.contentTab case final content? when pane == _tabs.contentPaneShown)
      _contentTabChip(content, pane),
  ];

  /// The rows of note tabs, in the title bar or heading the panes (issue
  /// #100 moved them into [ShellTabRows]).
  late final ShellTabRows _tabRows = ShellTabRows(
    workspace: _workspace,
    changes: _tabsListenable,
    history: _noteHistory,
    unsaved: _unsavedRelPaths,
    chipCovers: _chipCovers,
    chips: _pinnedChips,
    activate: _activateTab,
    takePane: _takePane,
    onTabAction: (path, action, anchor) =>
        unawaited(_tabAction(path, action, anchor)),
    sidebarVisible: () => _selection.sidebarVisible,
    onToggleSidebar: _selection.toggleSidebar,
    dockToggle: _dockToggle,
  );

  /// Runs a tab menu's note action on the note at [path] (#712).
  Future<void> _tabAction(
    String path,
    NoteTabAction action,
    Rect anchor,
  ) async {
    switch (action) {
      case NoteTabAction.reveal:
        _revealInTree(path);
      case NoteTabAction.copyPath:
        await Clipboard.setData(ClipboardData(text: path));
      case NoteTabAction.rename:
        await _rowActions.rename(context, path);
      case NoteTabAction.history:
        await _openHistory(path);
      case NoteTabAction.export:
        await _exportFlow.runNoteExport(context, path, anchor: anchor);
    }
  }

  /// The pinned content tab's chip (#712), at the end of [pane]'s row: the
  /// rectangle the note tabs wear, a click shows it again, the ✕ closes it.
  Widget _contentTabChip(ShellTab tab, int pane) {
    final w = _workspace.value;
    final home = tab == ShellTab.home;
    return PinnedTabChip(
      tabKey: Key('content-tab-${tab.name}'),
      closeKey: Key('content-tab-close-${tab.name}'),
      icon: home ? Icons.home_outlined : Icons.check_box_outlined,
      label: home ? AppStrings.tabHome : AppStrings.todoTitle,
      selected: _tab == tab,
      focused: !w.isSplit || w.focused == pane,
      onTap: () => _tabs.showContentTab(tab, pane),
      onClose: _tabs.closeContentTab,
    );
  }

  /// What the tabs redraw on: the workspace, and — moved out of any build
  /// it lands in — the unsaved tracker.
  late final DeferredListenable _tabsListenable = DeferredListenable(
    Listenable.merge([_workspace.controller, widget.unsavedTracker]),
  );

  /// The workspace moved (#23): the selection follows the showing tab, a
  /// page covering the pane gives way (issue #1256 moved it into
  /// [ShellWorkspaceFollow]).
  late final ShellWorkspaceFollow _workspaceFollow = ShellWorkspaceFollow(
    workspace: _workspace,
    selection: _selection,
    compare: _compare,
    reviewTab: _reviewTab,
    reviewPane: () => _reviewPaneShown,
    kind: _kind,
    wide: () => _wide,
    update: setState,
    mounted: () => mounted,
  );

  /// Shows the tab at [index], and the Files tab it lives in. A sidebar
  /// view (the search, the tags tree in it) is left alone on a wide
  /// window (#769): the panes are on screen beside it, and its hits stay
  /// there to step through.
  void _activateTab(int pane, int index) {
    _takePane(pane);
    _workspace.activate(pane, index);
  }

  /// [pane] is about to show one of its own tabs: the pages over it give
  /// way, and the Files tab it lives in shows.
  void _takePane(int pane) {
    // Only the pane that shows the compare page gives it up: a version
    // stays open beside the note being edited in the other one (#975).
    if (_compare.shownIn(pane)) setState(_compare.hide);
    if (pane == _reviewPaneShown) _reviewTab.show(on: false);
    if (_tab != ShellTab.files && !_wideLayout.sidebarShowsView) {
      _tabs.destinationSelected(ShellTab.files);
    }
  }

  /// The note the shell shows, as registered in [LibraryShell.openNotes].
  String? _openNote;

  /// Keeps the selected note marked open for the transcript writer, in
  /// whatever editor shows it: the raw editor has no audio view to take a
  /// finished transcript, and writing the file under its buffer would
  /// have the next autosave undo it. The result waits until the note is
  /// left instead.
  void _markOpenNote(String? root, String? selected) {
    final notes = widget.openNotes;
    if (notes == null) return;
    final path = root == null || selected == null || _selection.isDir
        ? null
        : p.join(root, selected);
    if (path == _openNote) return;
    final previous = _openNote;
    _openNote = path;
    if (path != null) notes.open(path);
    if (previous != null) notes.close(previous);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reviewTab
      ..hosted = true
      ..addListener(_onReviewTab);
    // The todo widgets follow the snapshot: every mutation notifies, and
    // the initial open notifies too, so one listener covers both.
    _tasks.todo.addListener(_homeWidgets.pushTodos);
    _templateFlow = ShellTemplateFlow(
      controller: widget.controller,
      origin: () => (
        selected: _selection.path,
        isDir: _selection.isDir,
        treeVisible: _selection.treeVisible,
      ),
      newItemRule: _newItemRule,
      guard: _guard,
      opensPreviewOnly: () => _shown.preview,
      onNoteFiled: _onTemplateNoteFiled,
      nameInPlace: _treeEditing.nameInPlace,
    );
    _journalFlow = JournalFlow(
      controller: widget.controller,
      templates: _templateFlow,
      guard: _guard,
      onOpen: (path) => _openNoteFromLink(path, null),
      onCreated: _openNewJournalEntry,
    );
    _tasks.open();
    // The Study widgets have no other first push: the decks are counted
    // for them only when one is placed (#533).
    _homeWidgets
      ..start()
      ..pushStudy();
    _workspaceFollow.attach();
    _workspace.unsavedPaths = _unsavedRelPaths;
    widget.controller.features.addListener(_tabs.featuresChanged);
    AppKeyMap.current.addListener(_rebuild);
    _chosenKeys.attach();
    FocusManager.instance.addListener(_reclaimFocus);
    HardwareKeyboard.instance.addHandler(_noteHistory.unfocusedKey);
    _immersive.addListener(_rebuild);
    unawaited(_restoreWorkspace());
    _inboundRoutes.listen();
    // Files dropped on the window that nothing opens: attached to the note
    // on screen (#1250).
    widget.launchRequests.attachHandler = _noteActions.attachDropped;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = widget.launchRequests.consumeFile();
      if (path != null && mounted) {
        _featuresIntro.requested();
        unawaited(_openPath(path));
      }
    });
    // What a cold start carried — a notification, a launcher action, a
    // share, a widget, a file — opens its own target. The Features
    // introduction (#1109) waits for all of them, and for the welcome's
    // offer of the tour, and is shown only when none was found.
    final launches = [
      _outside.reminderLaunch(context),
      _outside.shortcutLaunch(context),
      _outside.shareLaunch(context),
      _homeWidgets.applyLaunchTarget(),
      // The welcome's "show me around" (#266): asked once a library is
      // open, because the tour points at the shell.
      offerTour(context, ref),
    ];
    unawaited(_featuresIntro.offer(launches));
    unawaited(_refreshEditorSettings());
    unawaited(_settings.loadLinks());
  }

  @override
  void dispose() {
    _studyMade?.dispose();
    // A library closed or switched from a floating window: the window
    // goes with the shell it was over (#202, #203). Off the teardown, which
    // must not change the navigator it runs under.
    _windows.close();
    _markOpenNote(null, null);
    _bodies.dispose();
    _treeFocus.dispose();
    _workspaceFollow.detach();
    widget.controller.features.removeListener(_tabs.featuresChanged);
    // The study is the library's: the tab is app-wide, and a run left in it
    // would show in the next library's panes and grade into this one's
    // review.json (#944).
    _reviewTab
      ..removeListener(_onReviewTab)
      ..close()
      ..hosted = false;
    AppKeyMap.current.removeListener(_rebuild);
    _chosenKeys.detach();
    FocusManager.instance.removeListener(_reclaimFocus);
    HardwareKeyboard.instance.removeHandler(_noteHistory.unfocusedKey);
    // A library switch tears the shell down: the window it maximized goes
    // back as it was.
    _immersive.removeListener(_rebuild);
    _immersive.dispose();
    _tabsListenable.dispose();
    _selection.dispose();
    _expanded.dispose();
    _workspace.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _noteFade.dispose();
    unawaited(_homeWidgets.dispose());
    unawaited(_inboundRoutes.cancel());
    if (widget.launchRequests.attachHandler == _noteActions.attachDropped) {
      widget.launchRequests.attachHandler = null;
    }
    _tasks.todo.removeListener(_homeWidgets.pushTodos);
    _tasks.dispose();
    _personalDictionary.dispose();
    _fab.dispose();
    _shellFocus.dispose();
    _nav.dispose();
    _settings.dispose();
    super.dispose();
  }

  /// What the shell does as the app comes and goes from the foreground
  /// (issue #100 moved it into [ShellLifecycle]).
  late final ShellLifecycle _lifecycle = ShellLifecycle(
    controller: widget.controller,
    workspace: _workspace,
    todo: _tasks.todo,
    calendar: _tasks.calendar,
    study: () => _studyMade,
    homeWidgets: _homeWidgets,
    reloadOpenNote: () => _selection.reloadOpen(),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifecycle.changed(state);
  }

  /// Says how far the rewrite of the links to a note that moved has come
  /// (#1041), in one snack bar that is replaced as it goes and leaves when it
  /// is done: a rewrite of a thousand notes runs after the move has returned,
  /// and would otherwise be unseen. A rewrite of a few notes is over before
  /// it would be read, and says nothing.
  void _showLinksProgress(int done, int total) {
    if (!mounted || total <= linkRewriteBatch) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (done >= total) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.linksUpdating(done, total)),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LibraryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_refreshEditorSettings());
  }

  /// The library's one rule for where new notes and folders go (#850),
  /// read on each creation: its setting, and the note on screen.
  late final NewItemRule _newItemRule = NewItemRule(
    location: () => _settings.editor.newItemLocation,
    activeNote: () => _shown.path,
  );

  /// Opens a search result at [path] (library-relative): phone — the
  /// note takes the screen, back returns to the search tab; wide — the
  /// rail flips to Files and the detail pane shows it alongside the tree
  /// (the search body would otherwise hide the selection).
  void _openSearchNote(String path) {
    _showNote(path);
    logNextFrame('shell', 'search result open first frame');
  }

  /// Opens a search result at the words it matched (#1045): the note
  /// shows the first of [terms] it holds, selected, with the find bar
  /// marking the rest.
  void _openSearchHit(String path, List<String> terms) {
    _showNote(path, find: terms);
    logNextFrame('shell', 'search result open first frame');
  }

  Future<void> _guard(Future<void> Function() action) async {
    // Pure reentrancy flag (no UI reads it): no setState around it, so a
    // guarded action rebuilds once for its own state instead of three
    // times around the transition it animates (issue #4).
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } on Object catch (error) {
      const AppLogger(name: 'shell').error('guarded action failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.shellActionFailed)));
      }
      return;
    } finally {
      _busy = false;
    }
  }

  /// Annotates a place of a book or a PDF in its companion note, over the
  /// file (#284).
  late final ShellAnnotationFlow _annotations = ShellAnnotationFlow(
    controller: widget.controller,
    unsaved: widget.unsavedTracker,
    linkType: () => _settings.editor.linkType,
    // The companion may be the note on screen, or in the tree.
    onWritten: () {
      widget.controller.notify();
      if (mounted) _selection.reload();
    },
    onOpen: (path, offset) =>
        _onTemplateNoteFiled(path: path, preview: false, caret: offset),
  );

  /// Whether the readers annotate (#1109): off, they offer no annotating
  /// and draw no marks, the companion notes untouched.
  bool get _annotating =>
      widget.controller.features.value.isOn(LibraryFeature.annotations);

  void _annotate(Annotation annotation) =>
      unawaited(_annotations.annotate(context, annotation));

  /// Recognizes a PDF's or a picture's text into a sidecar (#594).
  late final ShellOcrFlow? _ocrFlow = switch ((widget.ocr, widget.ocrQueue)) {
    (final installation?, final queue?) => ShellOcrFlow(
      controller: widget.controller,
      unsaved: widget.unsavedTracker,
      installation: installation,
      queue: queue,
      // The sidecar may be the note on screen, or in the tree.
      onWritten: () {
        widget.controller.notify();
        if (mounted) _selection.reload();
      },
      onOpen: _openRecognizedText,
    ),
    _ => null,
  };

  /// Whether the Recognize text entries are offered: there is OCR, and the
  /// library has it on (#1109).
  bool get _offersOcr =>
      _ocrFlow != null && commandFeatureOn(AppCommand.recognizeText, _features);

  /// The file views' Recognize text, or null without OCR or a library.
  OcrFileActions? get _ocrActions {
    final queue = widget.ocrQueue;
    final root = widget.controller.root;
    final ops = widget.controller.ops;
    final flow = _ocrFlow;
    if (flow == null ||
        !_offersOcr ||
        queue == null ||
        root == null ||
        ops == null) {
      return null;
    }
    return OcrFileActions(
      queue: queue,
      root: root,
      ops: ops,
      recognize: _recognize,
      openNote: _openRecognizedText,
      recognizeAgain: flow.recognizeAgain,
    );
  }

  /// Asks how to recognize [path] (library-relative) and queues it.
  void _recognize(String path, {int? page, int? pageCount}) {
    final flow = _ocrFlow;
    if (flow == null) return;
    unawaited(flow.recognize(context, path, page: page, pageCount: pageCount));
  }

  /// Opens the note at [path] (a recognized text).
  void _openRecognizedText(String path) =>
      _onTemplateNoteFiled(path: path, preview: false, caret: null);

  /// Opens a note the template flow just filed (#51): preview per its
  /// `open` directive, caret per its `{{cursor}}`. The state the flow
  /// cannot know is set here, not in the flow.
  void _onTemplateNoteFiled({
    required String path,
    required bool preview,
    required int? caret,
  }) => _showNote(path, preview: preview, caret: caret);

  /// Opens the history of the note at [path]; a restore reloads the open
  /// note when it is that one.
  /// The history of the note at [path]: on a desktop with the dock, the
  /// note on screen's goes to the dock's pane, whose versions open beside
  /// the note (#712); any other note's, and a phone's, open the history
  /// page.
  Future<void> _openHistory(String path) async {
    if (_wide && _dockRoom && path == _workspace.value.activePath) {
      _workspace.controller.update(
        (w) => w.withDock(open: true, pane: DockPane.history),
      );
      return;
    }
    await _openHistoryPage(path);
  }

  Future<void> _openHistoryPage(String path) => openNoteHistory(
    context,
    session: widget.controller,
    unsaved: widget.unsavedTracker,
    path: path,
    window: widget.window,
    onRestored: () {
      if (mounted && _selection.path == path) _selection.reload();
    },
  );

  @override
  Widget build(BuildContext context) {
    DeviceShapeScope.debugCheck(context);
    final controller = widget.controller;
    final selectedPath = _selection.path;
    final narrow = !isWideShell(context);
    _markOpenNote(controller.root, _shown.path);
    // Notes stay open until they are closed: a folder selected, or the
    // phone back on its tree, closes none (#23). On the phone a note
    // opened joins the ones already open, for the switcher to reach.
    _workspace.follow(_selection.note, keepOnNone: true, alongside: !_wide);
    // A template's `open: preview` (#51) belongs to the tab the follow
    // above is about to make, so it is asked for once that has landed.
    if (_selection.takePreview() case final path?) {
      _workspace.showPreviewWhenOpen(path);
    }
    _leaveZenIfEmpty();
    final props = ShellLayoutProps(
      controller: controller,
      selectedPath: selectedPath,
      selectedIsDir: _selection.isDir,
      treeVisible: _selection.treeVisible,
      previewToggleVisible: _noteActions.previewToggleVisible,
      noteHidingTabs: _noteFade.hidingTabs,
      noteFade: ShellNoteFade.duration,
      shortcutBindings: _commands.shortcutBindings(),
      onCloseFullScreenNote: _tabs.closeNote,
      isQuickNote:
          selectedPath != null && selectedPath == _settings.quickNotePath,
      noteBarActions: _noteActions.barActions(_openNotes.button()),
      buildTabShell: () => _phoneChrome.scaffold(
        context,
        controller: controller,
        bodies: _bodies.children(controller),
      ),
      buildFullNote: (path) => _notePanes.fullNote(controller, path),
      window: widget.window,
      windowTitle: narrow ? _windowTitle : _libraryName,
      buildTabs: narrow ? null : _wideLayout.tabsRow,
      tabsStart: _wideLayout.tabsStart,
      // A Mac's commands are in the system's menu bar ([MacMenuBar]).
      menu: narrow || systemMenuBar
          ? null
          : AppMenuButton(
              handlers: _commands.handlers,
              features: () => _features,
            ),
      sidebarVisible: _selection.sidebarVisible,
      onToggleSidebar: _selection.toggleSidebar,
      shellFocus: _shellFocus,
      tab: _tab,
      destinations: _nav.destinations,
      onDestinationSelected: _tabs.destinationSelected,
      hiddenTab: !_nav.shown(_tab),
      onLeaveHiddenTab: _tabs.leaveHiddenTab,
      // Back walks up one folder before it leaves the Files tab, while the
      // grid is inside one (#727).
      backStepAvailable:
          narrow &&
          _tab == ShellTab.files &&
          _selection.treeVisible &&
          _files.gridInFolder,
      onBackStep: _files.gridUp,
      onSwitchLibrary: () => _windows.switchLibrary(context),
      // The touch way into the palette (#206); the desktop has a key.
      onOpenPalette: _paletteByTouch
          ? () => unawaited(_palette.open(context))
          : null,
      wideBackAvailable: _wideLayout.backAvailable,
      onWideBack: _wideLayout.back,
      buildWideSlots: () => _wideLayout.slots(controller),
      zen: _inZen,
      zenTitle: p.basename(_workspace.value.activePath ?? ''),
      onLeaveZen: _immersive.leaveZen,
      zenPreviewVisible: _shown.preview,
      onZenTogglePreview: _noteActions.previewToggleVisible
          ? _shown.togglePreview
          : null,
      leaveZenOnEsc: _leaveZenOnEsc,
    );
    // The region above the two panes, measured so a frame that misses with
    // both panes under their bars has a name of its own (#324).
    return _frameCost.timed(
      // A link pasted where nothing else takes a paste — the tree, the read
      // view — is a page to capture (#531): a text field and the editor
      // answer the paste first.
      () => MacMenuBar(
        handlers: _commands.handlers,
        features: () => _features,
        child: Actions(
          actions: <Type, Action<Intent>>{
            PasteTextIntent: CapturePasteAction(
              (url) => unawaited(_captureFlow.capture(context, url: url)),
            ),
          },
          child: _noteHistory.mouseButtons(
            narrow
                ? NarrowShellLayout(props: props)
                : WideShellLayout(props: props),
          ),
        ),
      ),
    );
  }

  /// The open notes holding unsaved edits, library-relative.
  Set<String> _unsavedRelPaths() {
    final root = widget.controller.root;
    return {
      if (root != null)
        for (final path in widget.unsavedTracker.unsavedPaths)
          if (p.isWithin(root, path)) relPath(path, root),
    };
  }

  /// The phone's tab chrome: the tab's app bar and FAB, the bottom tab
  /// bar, the bodies' stack (issue #100 moved it into [ShellPhoneChrome]).
  late final ShellPhoneChrome _phoneChrome = ShellPhoneChrome(
    nav: _nav,
    onDestinationSelected: _tabs.destinationSelected,
    onLeaveHiddenTab: _tabs.leaveHiddenTab,
    fab: _fab,
    menus: _treeMenus,
    addTodo: _tasks.add,
    todo: _tasks.todo,
    todoView: _tasks.view,
    palette: _palette,
    journalUi: _journalUi,
    syncActions: _syncActions,
    workspace: _workspace,
    openNotesButton: _openNotes.button,
    sortToggle: _bodies.sortToggle,
    features: () => _features,
    ocrQueue: widget.ocrQueue,
  );

  void _openTrash(LibrarySession controller) =>
      unawaited(openTrash(context, controller));

  /// The title bar's text: the app, and the open note when there is one.
  String get _windowTitle {
    final path = _selection.note;
    if (path == null) return AppStrings.appTitle;
    return '${AppStrings.appTitle} — ${p.basename(path)}';
  }

  /// Esc leaves Zen (#69): the app's Esc is a [DismissIntent], and this is
  /// what it dismisses while Zen is on. It gets there only when nothing
  /// nearer wanted the key: the find bar and a selection take the first
  /// press, a dialog or a menu its own.
  ///
  /// The same key shuts the side panel while it lies over the note (the
  /// two never show together: Zen hides it).
  late final Action<DismissIntent> _leaveZenOnEsc = DismissChain([
    CloseOverlayAction(() => _dock.overlayShown && !_inZen, _dock.closeOverlay),
    LeaveZenAction(_immersive.zen, () => _inZen),
  ]);

  /// Zen mode (#69) and the book read in full screen (#621).
  late final ShellImmersive _immersive = ShellImmersive(
    window: widget.window,
    possible: () => _zenPossible,
  );

  /// Whether Zen can show: a desktop window wide enough for the panes,
  /// on the notes, with a note open in them.
  bool get _zenPossible =>
      widget.window.customTitleBar &&
      _wide &&
      _wideLayout.filesSlotVisible &&
      _workspace.value.activePath != null;

  /// Whether Zen is what is on screen.
  bool get _inZen => _immersive.inZen;

  /// Leaves Zen once there is nothing left for it to show — the last tab
  /// closed, another place of the rail chosen, the window narrowed — so
  /// the chrome and the window size come back rather than wait.
  void _leaveZenIfEmpty() => _immersive.leaveIfEmpty();

  /// Opens an entry the journal just made, the caret where its template
  /// put it.
  void _openNewJournalEntry(String path, int? caret) =>
      _showNote(path, caret: caret);

  /// The keys the user chose, winning in both editors too (#159); not
  /// under a dialog or another screen.
  late final ChosenKeys _chosenKeys = ChosenKeys(
    handlers: _commands.handlers,
    active: () => mounted && (ModalRoute.of(context)?.isCurrent ?? true),
  );

  /// Opens the file at [path] (absolute): as its note when it is inside
  /// this library, on its own otherwise. What Open file does with the
  /// file picked, and what a launch with a file does (#41).
  Future<void> _openPath(String path) async {
    final root = widget.controller.root;
    if (root != null && p.isWithin(root, path)) {
      _openNoteFromLink(relPath(path, root), null);
      return;
    }
    await openOutsideFile(
      context,
      widget.outsideFiles,
      EditorOnlyDocument(path),
    );
  }

  /// Shows the library folder [folder] (relative; '' is the root) in the
  /// tree: the Files tab, the tree open, the folder and every folder
  /// above it expanded, and it selected.
  void _revealFolder(String folder) => _selection.revealFolder(folder);

  /// The phone's expandable "+" and the scrim its menu draws (T-UI-05):
  /// the shell rebuilds as it opens and closes, for the FAB slot and the
  /// body under the scrim are both the shell's.
  late final ShellFab _fab = ShellFab(
    listFolder: () async =>
        await widget.controller.ops?.listNoteFolder ?? defaultListFolder,
  )..addListener(_rebuild);

  /// The journal's calendar, strip and recent entries (#7).
  late final ShellJournalUi _journalUi = ShellJournalUi(
    controller: widget.controller,
    journal: () => _settings.journal,
    flow: _journalFlow,
    tasks: _tasks.todo,
    calendar: _tasks.calendar,
    openEvent: _bodies.openCalendarEvent,
    writeEvent: (day, event) =>
        unawaited(_guard(() => _tasks.calendar.addEvent(day, event))),
    editEvent: (entry, event, scope) => unawaited(
      _guard(() => _tasks.calendar.updateOccurrence(entry, event, scope)),
    ),
    skipEvent: (entry) =>
        unawaited(_guard(() => _tasks.calendar.skipOccurrence(entry))),
    deleteEvent: (entry, scope) =>
        unawaited(_guard(() => _tasks.calendar.deleteOccurrence(entry, scope))),
    addTask: (day) => unawaited(_tasks.add(due: day)),
    knownTokens: () => _tasks.knownTokens,
    calendarFile: () => _tasks.calendar.snapshot?.file,
    dockRoom: () => _dockRoom,
    openDockJournal: () => _workspace.controller.update(
      (w) => w.withDock(open: true, pane: DockPane.journal),
    ),
    openTasks: _openTodo,
    showRowMenuAt: (note, position) =>
        _treeMenus.rowMenuAt(context, note, position),
  );

  /// The floating windows over the shell: Settings, the libraries.
  late final ShellWindows _windows = ShellWindows(
    controller: widget.controller,
    spellCheck: widget.spellCheck,
    transcription: widget.transcription,
    ocr: widget.ocr,
    unsaved: widget.unsavedTracker,
    wide: () => _wide,
    featuresHost: _featuresHost,
  );

  /// The command palette (#155).
  late final ShellPalette _palette = ShellPalette(
    controller: widget.controller,
    transcription: widget.transcription,
    ocr: widget.ocr,
    spellCheck: widget.spellCheck,
    commandHandlers: _commands.handlers,
    commandsOffByFeature: _commands.offByFeature,
    labelOf: _commands.labelOf,
    recentNotes: () => _workspace.recentNotes,
    wide: () => _wide,
    openNote: (path) => _openNoteFromLink(path, null),
    openSettingsAt: _bodies.openSettingsAt,
    runHomeAction: (action) =>
        unawaited(_bodies.homeActions.run(context, action)),
    openFeatures: () => _bodies.openSettingsAt(featuresTarget),
  );

  /// The wide shell's body: the islands, their dividers and the dock's
  /// overlay (issue #100 moved it into [ShellWideBody]).
  late final ShellWideBody _wideBody = ShellWideBody(
    dock: _dock,
    files: _files,
    tabRows: _tabRows,
    settings: () => _settings.editor,
    inZen: () => _inZen,
    sidebarVisible: () => _selection.sidebarVisible,
    dockWidth: () => _wideLayout.dockWidth,
    customTitleBar: () => widget.window.customTitleBar,
    libraryName: () => _libraryName,
    treeFolder: () => _treeFolder,
    onSwitchLibrary: () => _windows.switchLibrary(context),
    treeFooter: _bodies.treeFooter,
    nav: _nav,
    sidebarShowsSearch: () => _wideLayout.sidebarShowsSearch,
    sidebarShowsStudy: () => _wideLayout.sidebarShowsStudy,
    searchSlot: (controller) => _bodies.searchSlot(controller, tree: true),
    study: () => _study,
    panes: _notePanes.panes,
    zenPanes: _notePanes.zenPanes,
    treeDivider: _wideLayout.treeDivider,
    dockDivider: _wideLayout.dockDivider,
  );

  /// Whether the window has room for the right dock beside a note (#175):
  /// a desktop, a tablet, a phone in landscape — on the same rule.
  bool get _dockRoom => _dock.room;

  /// Whether the dock shows: there is room, and it was not closed.
  bool get _dockShown => _dock.shown;

  /// The dock's button: on the note row under a title bar of the app's
  /// own, at the end of the panes' tab row without one (#1134).
  Widget _dockToggle() => _dock.toggle();

  /// Opens [pane] for the note: in the dock where it fits, else as a
  /// sheet (the phone's way to the same three, #175).
  Future<void> _showPanel(DockPane pane, {Rect? anchor}) =>
      _dock.showPanel(context, pane, anchor: anchor);

  /// The tree's keyboard focus, which Reveal in tree hands the keyboard
  /// (#712).
  final FocusNode _treeFocus = FocusNode(debugLabel: 'note-tree');

  /// Shows the note at [path] (library-relative) as the tree's selected
  /// row (#712): the Files view in the sidebar, every folder above it open.
  void _revealInTree(String path) => _selection.revealNote(path);

  /// The Files pane: the tree, or the grid in its place, and the folder
  /// the grid shows (#727; issue #100 moved it into [ShellFilesPane]).
  late final ShellFilesPane _files = ShellFilesPane(
    ocrQueue: widget.ocrQueue,
    settings: () => _settings.editor,
    selected: () => _selection.path,
    treeFolder: () => _treeFolder,
    expanded: _expanded,
    focusNode: _treeFocus,
    treeActive: () => !_wideLayout.sidebarShowsView,
    desktop: () => _desktop,
    menus: _treeMenus,
    rows: _rowActions,
    marked: _markedActions,
    editing: _treeEditing,
    onToggle: _selection.toggleFolder,
    onSelect: _treeOpen.fromPane,
    onOpenInNewTab: (note) => _treeOpen.pick(note, newTab: true),
    selectFolder: _selection.selectFolder,
    update: setState,
  );

  /// Whether this is a desktop: the keyboard is always there, and a click
  /// on a note can put the caret in it (#727). On a phone the tap that
  /// opens a note is also what raises the IME, and the "keyboard on open"
  /// setting decides that — so the caret is asked for on a desktop only.
  static bool get _desktop => switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.macOS => true,
    _ => false,
  };

  /// The folder the tree is on: the selected folder, or the selected
  /// note's folder, or the root.
  String get _treeFolder => _selection.folder;

  /// Whether the palette is reached by touch (#206, #849): on a window
  /// that is not the wide shell, and on any touch device's wide one. A
  /// desktop's wide window has a key.
  bool get _paletteByTouch => !_wide || !_desktop;
}
