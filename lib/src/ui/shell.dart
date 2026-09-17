import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/storage_access.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/tray.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:niman/src/spellcheck/spell_check_provider.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/transcription/open_audio_notes.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/history/history_flow.dart';
import 'package:niman/src/ui/kinds/audio_transcript_writer.dart';
import 'package:niman/src/ui/new_item_fab.dart';
import 'package:niman/src/ui/note_menu.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/open_library.dart';
import 'package:niman/src/ui/quick_note_tab.dart';
import 'package:niman/src/ui/settings_tab.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_detail_pane.dart';
import 'package:niman/src/ui/shell_editor_header.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';
import 'package:niman/src/ui/shell_home_widgets.dart';
import 'package:niman/src/ui/shell_layout.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_preview_actions.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/shell_row_menu.dart';
import 'package:niman/src/ui/shell_search_slot.dart';
import 'package:niman/src/ui/shell_sync_actions.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/shell_tree_footer.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_status.dart';
import 'package:niman/src/ui/tab_body_stack.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_tab.dart';
import 'package:niman/src/ui/trash.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/update_banner.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

/// Root screen: the open/create screen until a library is ready, then the
/// sidebar | detail shell (editor/preview arrive in M2).
final class LibraryHome extends ConsumerStatefulWidget {
  /// Creates the root screen.
  const new({super.key});

  @override
  ConsumerState<LibraryHome> createState() => _LibraryHomeState();
}

final class _LibraryHomeState extends ConsumerState<LibraryHome> {
  bool _resumeStarted = false;

  @override
  void initState() {
    super.initState();
    if (!_resumeStarted) {
      _resumeStarted = true;
      unawaited(_resume());
    }
    unawaited(_startLanguageAndActions());
    unawaited(_applyTheme());
  }

  @override
  void dispose() {
    AppLanguages.revision.removeListener(_republishQuickActions);
    super.dispose();
  }

  /// The stored language, and only then the quick actions.
  ///
  /// Their labels are strings like any other, so they answer in whatever
  /// language is set when they are published — and publishing before the
  /// stored choice had landed handed the launcher the *system* language
  /// instead of the app's, on every launch (device report, 2026-09-10).
  Future<void> _startLanguageAndActions() async {
    await _applyLanguage();
    if (!mounted) return;
    await _publishQuickActions();
    // And again whenever the language changes under them: the settings
    // switch, or the OS locale moving while the app runs.
    AppLanguages.revision.addListener(_republishQuickActions);
  }

  void _republishQuickActions() => unawaited(_publishQuickActions());

  /// Applies the stored theme (T-M6-05).
  ///
  /// Read once at start, like the language: the app wears the device's
  /// colors until the choice lands, which is what it wears anyway unless
  /// the user picked a palette.
  Future<void> _applyTheme() async {
    final session = ref.read(librarySessionProvider);
    AppThemes.apply(
      brightness: await session.themeBrightness,
      palette: await session.themePalette,
    );
  }

  /// Applies the stored UI language (T-L10N-03).
  ///
  /// Read once at start: the app renders in the OS language until it
  /// lands, which is the same answer whenever the user never chose one.
  Future<void> _applyLanguage() async {
    AppLanguages.choice = await ref.read(librarySessionProvider).language;
  }

  /// Publishes the quick actions on every surface that takes a label map:
  /// the Android launcher (T-SC-02) and the desktop tray (T-PP-06b). Both
  /// carry the same ids, so both run the same flows.
  ///
  /// Here rather than in the shell: they belong to the app, not to an
  /// open library, so they are there on the very first launch too. Called
  /// again on every language change, so both surfaces speak the app's
  /// language and not the system's.
  Future<void> _publishQuickActions() async {
    final labels = {
      ShortcutAction.quickNote: AppStrings.shortcutQuickNote,
      ShortcutAction.newTodo: AppStrings.shortcutNewTodo,
      ShortcutAction.newNote: AppStrings.shortcutNewNote,
      ShortcutAction.newList: AppStrings.shortcutNewList,
      ShortcutAction.newVoice: AppStrings.shortcutNewAudio,
    };
    await ref.read(shortcutServiceProvider).publish(labels);
    await ref.read(trayServiceProvider).init(labels);
  }

  /// Resumes the last library, unless Android is withholding the
  /// shared-storage permission.
  ///
  /// Resuming without it would reconcile the index against a root whose
  /// files the OS hides, rewriting the tree down to its folders. The open
  /// screen shows the permission prompt instead.
  Future<void> _resume() async {
    if (!await StorageAccess.hasAllFilesAccess()) return;
    if (!mounted) return;
    await ref.read(librarySessionProvider).resume();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(librarySessionProvider);
    // Started once: writes transcripts into notes no view has open.
    ref.read(audioTranscriptWriterProvider);
    return StreamBuilder<int>(
      stream: controller.events,
      initialData: controller.revision,
      builder: (context, _) => switch (controller.phase) {
        LibraryPhase.ready => Column(
          children: [
            UpdateAvailableBanner(session: controller),
            Expanded(
              child: _LibraryShell(
                controller: controller,
                reminders: ref.read(reminderServiceProvider),
                spellCheck: ref.read(spellCheckProvider),
                transcription: ref.read(transcriptionModelsProvider),
                openNotes: ref.read(openAudioNotesProvider),
                shortcuts: ref.read(shortcutServiceProvider),
                todoSourceFactory: ref.read(todoSourceFactoryProvider),
                unsavedTracker: ref.watch(unsavedTrackerProvider),
                targets: ref.read(widgetTargetServiceProvider),
                widgetUpdater: ref.read(widgetUpdaterProvider),
                widgetHost: ref.read(widgetHostServiceProvider),
                tray: ref.read(trayServiceProvider),
                window: ref.read(windowControllerProvider),
              ),
            ),
          ],
        ),
        _ => OpenLibraryScreen(controller: controller),
      },
    );
  }
}

/// The library shell: sidebar tree + action bar on the left, detail pane
/// on the right.
final class _LibraryShell extends StatefulWidget {
  const new({
    required this.controller,
    required this.reminders,
    required this.spellCheck,
    required this.shortcuts,
    required this.todoSourceFactory,
    required this.unsavedTracker,
    required this.targets,
    required this.widgetUpdater,
    required this.widgetHost,
    required this.tray,
    required this.window,
    this.transcription,
    this.openNotes,
  });

  final LibrarySession controller;

  /// The on-screen notes registry the transcript writer checks; null
  /// skips the marking.
  final OpenAudioNotes? openNotes;

  /// The installation's transcription models (settings section); null
  /// hides it.
  final TranscriptionModels? transcription;

  /// The OS reminder service (notification taps open the Todo tab).
  final ReminderService reminders;

  /// The editor's spelling state (T-PP-09), passed to every [NoteView].
  final EditorSpellCheck spellCheck;

  /// The launcher quick actions (T-SC-03: each one lands on the flow its
  /// in-app control uses).
  final ShortcutService shortcuts;

  /// Builds the todo file source per library root (overridden with a
  /// fake in widget tests).
  final TodoSource Function(String root) todoSourceFactory;

  /// The open notes' unsaved edits, which the window's close guard reads
  /// (T-PP-11); passed down to every [NoteView].
  final UnsavedTracker unsavedTracker;

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
  State<_LibraryShell> createState() => _LibraryShellState();
}

/// The app tabs: the bottom navigation bar on the narrow layout, the
/// fixed left rail on the wide layout (T-PP-14).
enum ShellTab {
  /// The note tree plus the note-open stack (T-UI-02).
  files,

  /// Reserved tab for the todo section (T-UI-10).
  todo,

  /// Full-text search (M3 T-M3-05); the SearchScreen tab.
  search,

  /// The scratch quick note at the library root (T-UI-10).
  quickNote,

  /// The library settings (the pushed SettingsScreen on wide screens).
  settings,
}

final class _LibraryShellState extends State<_LibraryShell>
    with WidgetsBindingObserver {
  String? _selected;
  bool _selectedIsDir = false;
  final Set<String> _expanded = <String>{};
  bool _busy = false;

  /// External-change reload requests for the open note (home-screen
  /// widget toggles edit the file in a background isolate): bumped when
  /// the already-open note is reopened and on app resume, so the
  /// mounted NoteView re-reads the file when its buffer is clean.
  int _noteReloadToken = 0;

  /// The currently selected bottom tab (narrow layout).
  ///
  /// A [ValueNotifier] rather than a plain field so a plain tab switch can
  /// refresh the chrome and the visible slot through a
  /// [ValueListenableBuilder] *without* a shell-wide `setState`: the
  /// kept-alive bodies do not depend on which tab is current, so rebuilding
  /// all of them on every switch was 12-24 ms of wasted `build` (device log,
  /// #46). Read and written through [_tab], so every existing call site is
  /// unchanged; the full-`setState` paths still fire where the switch also
  /// changes state the bodies do read.
  final ValueNotifier<ShellTab> _tabListenable = ValueNotifier(ShellTab.files);
  ShellTab get _tab => _tabListenable.value;
  set _tab(ShellTab value) => _tabListenable.value = value;

  /// Every tab visited so far: bodies mount on first visit and stay
  /// mounted afterwards, so a switch only flips visibility instead of
  /// disposing one state and inflating another mid-animation (the
  /// 2026-09-08 device log put that inflate at 14-17 ms of frame build).
  /// Query, results, and scroll therefore survive a switch, by choice.
  final Set<ShellTab> _visitedTabs = <ShellTab>{ShellTab.files};

  /// The tab active when the full-screen note opened (back returns there).
  ShellTab _noteFromTab = ShellTab.files;

  /// The open library's personal dictionary (issue #60), attached to the
  /// spell state: loaded once per root, the old one disposed and swapped
  /// when the library changes, detached on close.
  PersonalDictionary? _personalDictionary;

  /// The root a personal-dictionary open is in flight for: the repeated
  /// [_refreshEditorSettings] calls must not open the same file again.
  String? _personalDictionaryOpening;

  /// Shows the todo list, wherever this layout keeps it.
  ///
  /// The narrow bottom bar and the wide rail both own a Todo tab, so this
  /// only selects it. Reminder taps land here, so a tap opens the app on
  /// the list with no hint missing of why.
  void _openTodo() {
    _selectShellTab(ShellTab.todo);
  }

  /// The sync surfaces: the status button and the screens behind it
  /// (issue #100 moved the how of them into [ShellSyncActions]).
  late final ShellSyncActions _syncActions = ShellSyncActions(
    unsaved: widget.unsavedTracker,
    onShowTrash: _openTrash,
  );

  /// The home-screen widgets of this library: pushes out, taps back in
  /// (issue #100 moved the how of it into [ShellHomeWidgets]).
  late final ShellHomeWidgets _homeWidgets = ShellHomeWidgets(
    controller: widget.controller,
    targets: widget.targets,
    updater: widget.widgetUpdater,
    host: widget.widgetHost,
    todoSnapshot: () => _todoController.snapshot,
    openTodo: _openTodo,
    openNote: _openNoteFromLink,
    mounted: () => mounted,
  );

  /// Selects [tab]; a full-screen note closes to its tree (the selected
  /// note stays highlighted).
  void _selectShellTab(ShellTab tab) {
    if (_tab == tab) return;
    // The switch is logged so a slow frame in an exported log can be
    // attributed to a tab rather than guessed at: the reported stutter is
    // specific to Search, and until this line existed nothing in the log
    // said when Search was entered.
    const AppLogger(name: 'shell').debug('tab: ${_tab.name} -> ${tab.name}');
    // A kept-alive search field would otherwise hold focus (and the
    // keyboard) on the next tab: disposing used to drop it for free.
    FocusManager.instance.primaryFocus?.unfocus();
    // Put it back on the shell so the next accelerator still reaches the
    // bindings (T-PP-10).
    _shellFocus.requestFocus();
    // #46 fast path: on the phone, a plain switch (no fullscreen note in the
    // way, the FAB menu closed, the target already mounted) changes nothing
    // the kept-alive bodies read, so it only moves the visible-tab notifier
    // the chrome and the body stack listen to. The bodies keep their
    // instances and Element.update skips their subtrees, instead of a
    // shell-wide rebuild re-running every mounted body's build (12-24 ms of
    // `build` per switch in the device log). A fullscreen note to close, a
    // first mount, or the open FAB all still fall to the full setState.
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    if (narrow && _treeVisible && !_fabExpanded && _visitedTabs.contains(tab)) {
      _noteClosed();
      _tab = tab;
    } else {
      setState(() {
        _tab = tab;
        _visitedTabs.add(tab);
        _treeVisible = true;
        _fabExpanded = false;
        // Leaving any open note: the tabs show at once (issue #4).
        _noteClosed();
      });
    }
    // Time-to-visible of the switch itself: the 'tap tab' line above is the
    // input, this is when the first new frame actually painted (with the
    // navigation-bar selection animation the user said lags on Search).
    logNextFrame('shell', 'tab ${tab.name} first frame');
    // #48: the frames after that first one, attributed to this switch. The
    // shared slow-frame log flushes in batches, so a switch could never be
    // told apart from the one before it.
    FrameProbe.watch('shell', 'tab ${tab.name} frames');
    // T-TS-09 marker: brackets the fade so a slow frame can be attributed
    // to the switch itself (before it) or to what settles after it. Only
    // the latest switch reports: a rapid double-tap's stale marker would
    // misattribute the frames.
    final settled = tab;
    unawaited(
      Future<void>.delayed(TabBodyStack.fade + const Duration(milliseconds: 20))
          .then((_) {
            if (mounted && _tab == settled) {
              const AppLogger(name: 'shell')
                  .debug('tab fade settled: ${settled.name}');
            }
          }),
    );
  }

  /// The editor settings toggles, held here so both NoteView sites get the
  /// same values and they refresh on session events (the settings screen
  /// calls `notify()` after a toggle), so an open editor picks them up
  /// without reopening the note. The shell rebuilds on every session event
  /// (the LibraryHome StreamBuilder), so a refetch happens there — no
  /// subscription needed.
  ShellEditorSettings _editorSettings = ShellEditorSettings.defaults;

  /// Whether the wide layout's tree pane shows (the title bar's toggle;
  /// the rail always stays, T-PP-22).
  bool _sidebarVisible = true;

  /// The library's quick note (library-relative path, or none): the
  /// note page's app bar labels it, now that the tabs no longer do
  /// (issue #73, item 1). Refreshed with the editor settings.
  String? _quickNotePath;

  /// Carries focus for the app accelerators (T-PP-10) when nothing else
  /// wants it, so a keyboard-only tab switch is followed by a working next
  /// one: [FocusManager] would otherwise leave nothing focused.
  final FocusNode _shellFocus = FocusNode(debugLabel: 'app shortcuts');

  /// Phone (< [splitBreakpoint]) mode: which pane is visible.
  /// `false` = the selected note is open full-screen.
  bool _treeVisible = true;

  /// Whether the Search tab shows the Tags screen (T-M3-06) instead of
  /// the search box; the tabs button flips it and back.

  /// The link-resolution source (T-M3-07), resolved from the session.
  LinkSource? _linkSource;

  /// The todo state (T-TD-04): owned here so the tab body and the tab's
  /// app-bar add action share one controller.
  late final TodoController _todoController;

  /// Making new things in the library: the FAB, the tree footer's menu
  /// and the row menu all run these (issue #100 moved the how of them
  /// into [ShellCreateFlow]).
  late final ShellCreateFlow _createFlow = ShellCreateFlow(
    controller: widget.controller,
    createParent: () => _createParent,
    guard: _guard,
    onCreated: _onItemCreated,
  );

  /// Opens what a create just made: a note takes the screen, a folder
  /// only takes the selection.
  void _onItemCreated(CreatedItem item) {
    if (!mounted) return;
    if (!item.isDir && _opensPreviewOnly()) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      _selected = item.path;
      _selectedIsDir = item.isDir;
      _pendingAnchor = null;
      _pendingCaretOffset = null;
      if (item.hasKind) _resetNoteKind();
      if (!item.isDir) {
        _treeVisible = false;
        _noteOpened();
      }
    });
  }

  /// What a tree row's menu choice does: rename, move, delete, pin, open
  /// outside the app (issue #100 moved them into [ShellRowActions]).
  late final ShellRowActions _rowActions = ShellRowActions(
    controller: widget.controller,
    guard: _guard,
    creates: _createFlow,
    templates: _templateFlow,
    selectedPath: () => _selected,
    onMoved: (path) => setState(() => _selected = path),
    onDeleted: () => setState(() {
      _selected = null;
      // Deleting the open note closes it: the tabs show at once.
      _noteClosed();
    }),
    onHistory: _openHistory,
  );

  /// Note creation from the library's templates (#51, T-M4-07): the flow
  /// owns the picker, the questions, the directives, the render and the
  /// file; the shell keeps the selection state it reads through callbacks
  /// and the open that follows.
  late final ShellTemplateFlow _templateFlow;

  /// Notification taps while running: a todo tap opens the Todo tab.
  StreamSubscription<String?>? _reminderTaps;
  StreamSubscription<ShortcutAction>? _shortcutTaps;
  StreamSubscription<ShortcutAction>? _trayTaps;
  StreamSubscription<void>? _trayActivations;

  /// Library session events (every note op bumps the revision): the
  /// pinned notes follow the files, so each one refreshes the note
  /// widgets (issue 6).
  StreamSubscription<int>? _libraryEvents;

  /// Paths a sync just changed on disk: the open note among them is
  /// re-read (its buffer was saved before the sync started).
  StreamSubscription<Set<String>>? _syncChanges;

  /// A heading anchor to land on after the next note opens (T-M3-07).
  String? _pendingAnchor;

  /// A template `{{cursor}}` offset to land the caret on after the created
  /// note opens (#53). Fresh notes only: appended text joins an existing
  /// file whose length the creation flow does not know.
  int? _pendingCaretOffset;

  /// The open note's kind (the frontmatter `type`, null = plain note or
  /// no note); reported by the open NoteView (T-TK-02).
  String? _noteKind;

  /// Whether the open note shows the raw editor instead of its kind GUI
  /// (the app-bar pencil toggle, T-TK-05).
  bool _kindRawMode = false;

  /// The open NoteView reports the note's kind; the app bar shows the
  /// kind toggle for known kinds.
  void _onNoteKindChanged(String? type) {
    if (!mounted) return;
    setState(() => _noteKind = type);
  }

  /// The GUI behind the open note's kind (T-TK-02): null for a plain
  /// note, no note, or a `type` without a registered GUI (a `type: list`
  /// note is a list, everything else is a document).
  NoteKindGUI? get _kindGui => NoteKinds.forType(_noteKind);

  /// Whether the app bar shows the editor/preview eye action: hidden in
  /// kind mode (the note is a list, not a document) unless the user is
  /// in raw-edit mode.
  bool get _previewToggleVisible =>
      _editorSettings.previewEnabled && (_kindGui == null || _kindRawMode);

  /// The kind toggle actions (T-TK-05): a note whose kind has a GUI offers
  /// the raw editor (pencil); in raw mode the kind GUI is offered back.
  /// Empty when the open note has no kind GUI (including unknown `type`s).
  List<Widget> get _kindActions {
    if (_kindGui == null) return const [];
    final isAudio = _noteKind == 'audio';
    return [
      if (_kindRawMode)
        IconButton(
          key: const Key('kind-show-list'),
          tooltip: isAudio
              ? AppStrings.showAudioTooltip
              : AppStrings.showListTooltip,
          icon: Icon(isAudio ? Icons.mic_outlined : Icons.checklist),
          onPressed: () => setState(() => _kindRawMode = false),
        )
      else
        IconButton(
          key: const Key('kind-edit-raw'),
          tooltip: AppStrings.editRawTooltip,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => setState(() => _kindRawMode = true),
        ),
    ];
  }

  void _resetNoteKind() {
    _noteKind = null;
    _kindRawMode = false;
    // Fullscreen is a property of the note being previewed, not of the
    // app: the next note opens with its chrome.
    _previewFullScreen = false;
  }

  Future<void> _loadLinkSource() async {
    final source = await widget.controller.linkSource;
    if (mounted && source != null) setState(() => _linkSource = source);
  }

  /// Opens a note reached through a link (T-M3-07): selects it, remembers
  /// the heading anchor, and clears pending anchors for direct
  /// selections.
  void _openNoteFromLink(String path, String? anchor) {
    const AppLogger(name: 'links').debug(
      'shell open request: $path anchor=${anchor == null ? '-' : '"$anchor"'} '
      '(current tab ${_tab.name})',
    );
    if (_opensPreviewOnly()) FocusManager.instance.primaryFocus?.unfocus();
    // Reopening the already-open note (a widget header tap after a row
    // toggle): the path does not change, so the NoteView would keep its
    // buffer — ask it to re-read the file instead.
    final sameNote = _selected == path && !_selectedIsDir;
    setState(() {
      _selected = path;
      _selectedIsDir = false;
      _treeVisible = false;
      _noteFromTab = _tab;
      _pendingAnchor = anchor;
      _pendingCaretOffset = null;
      _resetNoteKind();
      if (sameNote) _noteReloadToken++;
      _noteOpened();
    });
  }

  /// Whether the FAB menu (New note / New folder minis) is expanded;
  /// the shell owns it so the body can be scrimmed while it is open.
  bool _fabExpanded = false;

  /// Where the main FAB is, so [FabScrim]'s reveal circle is centered on
  /// its icon (the shell owns it: the FAB slot and the scrim are
  /// siblings). Written from the FAB's paint, read when the scrim builds.
  Offset? _fabAnchor;

  /// Editor/preview switch for the non-split layouts (T-UI-06): the eye
  /// action lives in the shared app bar, so the shell owns the state.
  bool _previewVisible = false;

  void _togglePreview() {
    // The preview has no editable: flipping to it dismisses the keyboard
    // instead of leaving the IME up over a read-only pane.
    if (!_previewVisible) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _previewVisible = !_previewVisible;
      // Fullscreen belongs to the preview: switching back to the editor
      // must not leave a chromeless editor with no way out.
      if (!_previewVisible) _previewFullScreen = false;
    });
    // Device trace (preview toggle needs two presses on huge notes) —
    // temporary: remove once the trace is in.
    const AppLogger(name: 'preview')
        .info('toggle → ${_previewVisible ? 'preview' : 'editor'}');
  }

  /// Whether a note opened right now would show only the preview (the
  /// editor hidden): the IME has no target and must go before the
  /// transition, or its resize lands mid-fade.
  bool _opensPreviewOnly() {
    if (!_previewVisible) return false;
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    return !previewSplits(
      _editorSettings.previewMode,
      narrow: narrow,
      editor: _editorSettings.editorKind,
      previewEnabled: _editorSettings.previewEnabled,
    );
  }

  /// Records a note open: the tabs stay painted under the fading note
  /// (issue #4, see [_noteHidingTabs]) and hide once it has covered them.
  /// A no-op when they are already hidden (opening another note while one
  /// is open swaps the content opaquely — no fade, nothing to cover).
  void _noteOpened() {
    if (_noteHidingTabs) return;
    _noteHidingTabs = false;
    _noteHideTimer?.cancel();
    final token = ++_noteHideRevision;
    _noteHideTimer = Timer(
      _fullNoteFade + const Duration(milliseconds: 40),
      () {
        _noteHideTimer = null;
        if (!mounted || token != _noteHideRevision) return;
        if (_selected == null || _selectedIsDir || _treeVisible) return;
        setState(() => _noteHidingTabs = true);
      },
    );
  }

  /// Records a note close: the tabs show at once so the fading note
  /// cross-fades over them instead of over the window background.
  void _noteClosed() {
    _noteHideTimer?.cancel();
    _noteHideTimer = null;
    _noteHideRevision++;
    _noteHidingTabs = false;
  }

  /// Whether the preview has taken over the phone screen (2026-09-08
  /// user request): app bar and tab bar hidden, the note's own text left.
  ///
  /// Phone-only. On the wide layout the note already shares the window
  /// with the tree, and "fullscreen" there would mean something else.
  bool _previewFullScreen = false;

  /// The full-note open fade (matches the AnimatedSwitcher below).
  static const _fullNoteFade = Duration(milliseconds: 220);

  /// Whether the tab shell stays hidden under the open note. It flips on
  /// only once the open fade has covered it (issue #4): hiding the shell
  /// in the same frame as the open exposes the window background through
  /// the fading note — a black frame in dark mode. Tickers stop at once;
  /// layout and paint follow the fade.
  bool _noteHidingTabs = false;

  /// Whether the Quick note tab body is the choose/create screen.
  ///
  /// It is only ever wanted when no quick note is set. With one set, the
  /// tab is a way of opening that note, and the tab shell stays painted
  /// under the opening note for the length of the fade — long enough for
  /// the chooser to flash behind a note the user had already chosen.
  bool _showQuickNoteChooser = false;

  /// The pending tab-hide after a note open (canceled on close).
  Timer? _noteHideTimer;

  /// Guards the pending hide against a rapid close/reopen.
  int _noteHideRevision = 0;

  /// The app-bar fullscreen action, left of the editor/preview eye —
  /// which stays where it is (see [_noteBarActions]).
  Widget _previewFullScreenAction() {
    return IconButton(
      key: const Key('preview-fullscreen'),
      tooltip: AppStrings.enterFullScreenTooltip,
      icon: const Icon(Icons.fullscreen),
      onPressed: () => setState(() => _previewFullScreen = true),
    );
  }

  /// The phone full-screen note body (one builder for both the chromed
  /// and the immersive variants: only the Scaffold around it changes).
  Widget _fullNoteView(LibrarySession controller, String selectedPath) {
    return NoteView(
      path: p.join(controller.root ?? '', selectedPath),
      showLineNumbers: _editorSettings.lineNumbers,
      autofocusEditor: _editorSettings.autofocusEditor,
      linkType: _editorSettings.linkType,
      missingNoteLocation: _editorSettings.missingNoteLocation,
      attachmentsFolder: _editorSettings.attachmentsFolder,
      indentWidth: _editorSettings.indentWidth,
      toolbarLayout: _editorSettings.toolbarLayout,
      splitPreview: previewSplits(
        _editorSettings.previewMode,
        narrow: true,
        editor: _editorSettings.editorKind,
        previewEnabled: _editorSettings.previewEnabled,
      ),
      showPreview: _editorSettings.previewEnabled && _previewVisible,
      showWysiwyg: _editorSettings.editorKind == EditorKind.wysiwyg,
      // A single enabled editor has nowhere to switch to: the note hides
      // its switch instead of offering a dead toggle.
      onEditorKindChanged: _editorSettings.editorsEnabled.length > 1
          ? _setEditorKind
          : null,
      splitFraction: _editorSettings.splitRatio,
      onSplitFractionChanged: _onSplitFractionChanged,
      onSplitDragEnd: _onSplitDragEnd,
      libraryRoot: controller.root,
      linkSource: _linkSource,
      onOpenNote: _openNoteFromLink,
      initialAnchor: _pendingAnchor,
      initialCaretOffset: _pendingCaretOffset,
      kindMode: !_kindRawMode,
      onNoteKindChanged: _onNoteKindChanged,
      unsavedTracker: widget.unsavedTracker,
      spellCheck: widget.spellCheck,
      reloadToken: _noteReloadToken,
      saveNote: _noteSaver(controller),
      createMissingNote: _missingNoteCreator(controller),
    );
  }

  /// The dead-link note-creation path (issue #78): an empty note through
  /// the library's own creation path; null while no library is ready,
  /// which keeps the dead-link snackbar instead of the offer.
  Future<String> Function(String relPath)? _missingNoteCreator(
    LibrarySession controller,
  ) {
    final ops = controller.ops;
    if (ops == null) return null;
    return (relPath) async {
      final note = await ops.createNote(
        parentPath: parentOf(relPath),
        name: p.basenameWithoutExtension(relPath),
      );
      return note.path;
    };
  }

  /// The note the shell shows, as registered in [_LibraryShell.openNotes].
  String? _openNote;

  /// Keeps the selected note marked open for the transcript writer, in
  /// whatever editor shows it: the raw editor has no audio view to take a
  /// finished transcript, and writing the file under its buffer would
  /// have the next autosave undo it. The result waits until the note is
  /// left instead.
  void _markOpenNote(String? root, String? selected) {
    final notes = widget.openNotes;
    if (notes == null) return;
    final path = root == null || selected == null || _selectedIsDir
        ? null
        : p.join(root, selected);
    if (path == _openNote) return;
    final previous = _openNote;
    _openNote = path;
    if (path != null) notes.open(path);
    if (previous != null) notes.close(previous);
  }

  /// The editor's write path into the open library: [NoteOperations.saveNote]
  /// with the editor's absolute path turned library-relative. Null while no
  /// library is ready, or for a note outside the library root — the editor
  /// then writes the file itself.
  NoteSaver? _noteSaver(LibrarySession controller) {
    final ops = controller.ops;
    final root = controller.root;
    if (ops == null || root == null) return null;
    return (path, content, {required editSession}) {
      if (!p.isWithin(root, path)) {
        return writeNoteOffIsolate(path, content).then((_) {});
      }
      return ops.saveNote(
        relPath(path, root),
        content,
        editSession: editSession,
      );
    };
  }

  /// The app-bar eye action: flips the editor/preview pane.
  Widget _previewToggleAction({bool compact = false}) {
    return PreviewToggleAction(
      previewVisible: _previewVisible,
      onToggle: _togglePreview,
      compact: compact,
    );
  }

  /// The split/switch picker: how the preview shares the window. Wide
  /// only — below 600 dp the panes cannot share the screen.
  Widget _layoutModeAction({bool compact = false}) {
    return PreviewLayoutModeAction(
      mode: _editorSettings.previewMode,
      onSelected: (mode) => unawaited(_setPreviewMode(mode)),
      compact: compact,
    );
  }

  /// Persists the split/switch choice the layout menu made: the stored
  /// value is shared with the settings ratio row, and the session event
  /// refreshes every NoteView through [_refreshEditorSettings].
  Future<void> _setPreviewMode(PreviewLayoutMode mode) async {
    if (mode == _editorSettings.previewMode) return;
    final controller = widget.controller;
    await controller.setPreviewMode(mode);
    controller.notify();
    if (mounted) {
      setState(
        () => _editorSettings = _editorSettings.copyWith(previewMode: mode),
      );
    }
  }

  /// Switches the library's current editor from the note's status row
  /// (T-WYS-12): persisted, then the shell re-reads it. Only offered when
  /// the library enables both editors.
  Future<void> _setEditorKind(EditorKind kind) async {
    if (kind == _editorSettings.editorKind) return;
    final controller = widget.controller;
    await controller.setEditorKind(kind);
    controller.notify();
    if (mounted) {
      setState(
        () => _editorSettings = _editorSettings.copyWith(editorKind: kind),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _todoController = TodoController(
      session: widget.controller,
      reminders: widget.reminders,
      sourceFactory: widget.todoSourceFactory,
    );
    // The todo widgets follow the snapshot: every mutation notifies, and
    // the initial open notifies too, so one listener covers both.
    _todoController.addListener(_homeWidgets.pushTodos);
    _templateFlow = ShellTemplateFlow(
      controller: widget.controller,
      origin: () => (
        selected: _selected,
        isDir: _selectedIsDir,
        treeVisible: _treeVisible,
      ),
      createParent: () => _createParent,
      guard: _guard,
      opensPreviewOnly: _opensPreviewOnly,
      onNoteFiled: _onTemplateNoteFiled,
    );
    // The controller loads here, not in TodoTab.initState: T-TD-07
    // reconciles reminders at every library open, and the Todo tab is
    // only reachable in the narrow layout -- a >= 600 px device would
    // otherwise never reconcile. The tab's own open() then takes the
    // probe-skip path instead of a second full read.
    unawaited(_todoController.open());
    _reminderTaps = widget.reminders.taps.listen((payload) {
      if (payload == todoReminderPayload && mounted) {
        const AppLogger(name: 'todo').debug('todo tap: opening the todo list');
        _openTodo();
      }
    });
    _homeWidgets.start();
    _libraryEvents = widget.controller.events.listen(
      (_) => _homeWidgets.pushNotes(),
    );
    _syncChanges = widget.controller.sync?.localChanges.listen((paths) {
      final open = _selected;
      if (!mounted || open == null || _selectedIsDir) return;
      if (paths.contains(open)) setState(() => _noteReloadToken++);
    });
    _shortcutTaps = widget.shortcuts.actions.listen(
      (action) => unawaited(_runShortcut(action)),
    );
    _trayTaps = widget.tray.actions.listen(
      (action) => unawaited(_runShortcut(action)),
    );
    _trayActivations = widget.tray.activated.listen(
      (_) => unawaited(widget.window.show()),
    );
    unawaited(_applyReminderLaunch());
    unawaited(_applyShortcutLaunch());
    unawaited(_homeWidgets.applyLaunchTarget());
    unawaited(_refreshEditorSettings());
    unawaited(_loadLinkSource());
  }

  @override
  void dispose() {
    _markOpenNote(null, null);
    WidgetsBinding.instance.removeObserver(this);
    _noteHideTimer?.cancel();
    unawaited(_homeWidgets.dispose());
    unawaited(_reminderTaps?.cancel());
    unawaited(_shortcutTaps?.cancel());
    unawaited(_libraryEvents?.cancel());
    unawaited(_syncChanges?.cancel());
    _todoController.removeListener(_homeWidgets.pushTodos);
    unawaited(_trayTaps?.cancel());
    unawaited(_trayActivations?.cancel());
    _todoController.dispose();
    _personalDictionary?.dispose();
    _shellFocus.dispose();
    _tabListenable.dispose();
    super.dispose();
  }

  /// Re-reconciles reminders on return to the app: the exact-alarm and
  /// notification grants live in system settings, so coming back from
  /// there must reschedule without waiting for the next file change.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // The queued changes go now: the process may not come back.
      widget.controller.sync?.appBackgrounded();
    }
    if (state != AppLifecycleState.resumed) {
      // Leaving the foreground may be the last thing this process does
      // (a swipe away, an OEM battery kill): get the buffered log on
      // disk while there is still a chance to.
      unawaited(AppLog.flush());
      return;
    }
    unawaited(_todoController.resyncReminders());
    // Changes made on other devices while the app was away.
    widget.controller.sync?.appResumed();
    // A home-screen widget toggle edits todo.txt / the note file in a
    // background isolate while the app is away (the Android watcher is
    // unreliable, so no session event may arrive): re-read both surfaces
    // when clean instead of showing the pre-toggle state.
    unawaited(_todoController.open());
    if (_selected != null && !_selectedIsDir) {
      setState(() => _noteReloadToken++);
    }
    // Pushes the home-screen widgets: the todo resync above skips its
    // notification when the files did not move, and a widget placed
    // while the app was away has no trigger of its own at all.
    _homeWidgets.pushAll();
  }

  /// A notification tap that started the app lands on the Todo tab.
  Future<void> _applyReminderLaunch() async {
    final payload = await widget.reminders.consumeLaunchPayload();
    if (payload == todoReminderPayload && mounted) {
      _openTodo();
    }
  }

  /// A launcher quick action that started the app (T-SC-03, cold start).
  ///
  /// Asked for here rather than at app start because the action needs an
  /// open library: the shell mounts once the library is ready, so a first
  /// run that has to pick a library first still runs the action after.
  Future<void> _applyShortcutLaunch() async {
    final action = await widget.shortcuts.consumeLaunchAction();
    if (action == null) return;
    await _runShortcut(action);
  }

  /// Runs [action]'s in-app flow: the same one the equivalent control
  /// uses, so a shortcut cannot drift from the button it mirrors.
  Future<void> _runShortcut(ShortcutAction action) async {
    if (!mounted) return;
    const AppLogger(name: 'shortcuts').debug('running ${action.id}');
    switch (action) {
      case ShortcutAction.quickNote:
        await _openQuickNoteFromTile();
      case ShortcutAction.newTodo:
        _openTodo();
        await _addTodo();
      case ShortcutAction.newNote:
        await _createFlow.createNote(context);
      case ShortcutAction.newList:
        await _createFlow.createListNote(context);
      case ShortcutAction.newVoice:
        await _createFlow.createAudioNote(context);
    }
  }

  @override
  void didUpdateWidget(covariant _LibraryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_refreshEditorSettings());
  }

  Future<void> _refreshEditorSettings() async {
    final controller = widget.controller;
    _syncPersonalDictionary(controller);
    final settings = await ShellEditorSettings.read(controller);
    // The spell checker follows the library's dictionaries (T-PP-09,
    // revised); it notifies the open editor itself, so it stays out of
    // the settings value and needs no setState of its own.
    final spellDictionaries = await controller.spellDictionaries;
    final ops = controller.ops;
    final quickNote = ops == null ? null : await ops.quickNotePath;
    if (!mounted) return;
    widget.spellCheck.setDictionaries(spellDictionaries);
    if (settings != _editorSettings) {
      setState(() => _editorSettings = settings);
    }
    if (quickNote != _quickNotePath) {
      setState(() => _quickNotePath = quickNote);
    }
  }

  /// Attaches the open library's personal dictionary to the spell state
  /// (issue #60): loaded once per root; a library switch disposes the old
  /// one and loads the new root's words; a closed library detaches.
  void _syncPersonalDictionary(LibrarySession controller) {
    final root = controller.root;
    final expected = root == null
        ? null
        : p.join(root, '.niman', 'dictionary.txt');
    if (_personalDictionary?.path == expected) return;
    if (root == null) {
      _personalDictionaryOpening = null;
      _personalDictionary?.dispose();
      _personalDictionary = null;
      widget.spellCheck.setPersonalDictionary(null);
      return;
    }
    if (_personalDictionaryOpening == root) return;
    _personalDictionaryOpening = root;
    unawaited(_openPersonalDictionary(controller, root));
  }

  /// Opens [root]'s dictionary file; on completion the words attach, the
  /// old dictionary disposes, and the spell state re-scans the open note.
  /// A library switched away before completion disposes the words instead.
  Future<void> _openPersonalDictionary(
    LibrarySession controller,
    String root,
  ) async {
    final dictionary = await PersonalDictionary.open(root);
    if (!mounted || controller.root != root) {
      dictionary.dispose();
      return;
    }
    _personalDictionaryOpening = null;
    _personalDictionary?.dispose();
    _personalDictionary = dictionary;
    widget.spellCheck.setPersonalDictionary(dictionary);
  }

  /// Flips the tree sort direction and persists it (T-UI-03).
  Future<void> _toggleTreeSort() async {
    final next = _editorSettings.treeSort == TreeSort.nameAsc
        ? TreeSort.nameDesc
        : TreeSort.nameAsc;
    setState(() => _editorSettings = _editorSettings.copyWith(treeSort: next));
    await widget.controller.setTreeSort(next);
    widget.controller.notify();
  }

  /// Live divider moves mirror into the settings value's split ratio;
  /// the lift persists it.
  void _onSplitFractionChanged(double value) =>
      _editorSettings = _editorSettings.copyWith(splitRatio: value);

  Future<void> _onSplitDragEnd() async {
    await widget.controller.setSplitRatio(_editorSettings.splitRatio);
    widget.controller.notify();
  }

  /// Parent path for new note/folder creation.
  String get _createParent {
    if (_selected == null) return '';
    return _selectedIsDir ? _selected! : parentOf(_selected!);
  }

  void _select(Note note) {
    // A note opening in preview-only has no editable for the IME.
    final previewOnly = !note.isDir && _opensPreviewOnly();
    if (previewOnly) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = note.path;
      _selectedIsDir = note.isDir;
      _treeVisible = note.isDir;
      _noteFromTab = _tab;
      _pendingAnchor = null;
      _pendingCaretOffset = null;
      _resetNoteKind();
      if (note.isDir) {
        _noteClosed();
        _expanded.add(note.path);
      } else {
        _noteOpened();
      }
    });
  }

  /// Opens a search result at [path] (library-relative): phone — the
  /// note takes the screen, back returns to the search tab; wide — the
  /// rail flips to Files and the detail pane shows it alongside the tree
  /// (the search body would otherwise hide the selection).
  void _openSearchNote(String path) {
    if (_opensPreviewOnly()) FocusManager.instance.primaryFocus?.unfocus();
    final wide = MediaQuery.sizeOf(context).width >= splitBreakpoint;
    setState(() {
      _selected = path;
      _selectedIsDir = false;
      _treeVisible = false;
      _noteFromTab = _tab;
      if (wide) {
        _tab = ShellTab.files;
        _visitedTabs.add(ShellTab.files);
      }
      _resetNoteKind();
      _noteOpened();
    });
    logNextFrame('shell', 'search result open first frame');
  }

  /// Opens the quick note at [path]; back returns to the tab it was
  /// opened from: the tile sits in every tab, not in Files (issue #73,
  /// item 1). The chooser flow arrives here from the quick note tab
  /// itself, and Files is its home. A stale setting (the note was moved,
  /// renamed, or deleted) is cleared so the tab returns to its empty
  /// state.
  Future<void> _openQuickNote(String path) async {
    // Closes the keyboard before the transition (issue #4): opening the
    // overlay over a live IME rips focus mid-fade while adjustResize
    // reshapes the window, which flashes on device. Tab switches already
    // do this in _selectShellTab.
    FocusManager.instance.primaryFocus?.unfocus();
    await _guard(() async {
      final ops = widget.controller.ops;
      if (ops == null) return;
      final note = await ops.find(path);
      if (note == null || note.isDir) {
        // The note it pointed at is gone: forget it and ask again, rather
        // than leaving the tap with nothing to show for itself.
        await ops.setQuickNotePath(path: null);
        widget.controller.notify();
        if (mounted) _openQuickNoteChooser();
        return;
      }
      if (!mounted) return;
      // Read the origin before the switch below: the chooser flow arrives
      // here from the quick note tab itself, and Files is its home.
      final fromTab = _tab == ShellTab.quickNote ? ShellTab.files : _tab;
      setState(() {
        _tab = ShellTab.quickNote;
        _visitedTabs.add(ShellTab.quickNote);
        _showQuickNoteChooser = false;
        _noteFromTab = fromTab;
        _selected = note.path;
        _selectedIsDir = false;
        _treeVisible = false;
        _resetNoteKind();
        _noteOpened();
      });
      logNextFrame('shell', 'quick note open first frame');
    });
  }

  /// The bottom-nav tile: once a quick note is set it opens directly;
  /// otherwise switch to the tab (the choose/create screen).
  Future<void> _openQuickNoteFromTile() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final path = await ops.quickNotePath;
    if (!mounted) return;
    if (path == null || path.isEmpty) {
      _openQuickNoteChooser();
      return;
    }
    // Already on screen: just land on the tab. Reopening would unfocus
    // the editor, reset the kind view and restart the hide timer for
    // identical content — on wide, where both tabs share the detail pane,
    // that reads as a close/reopen flash.
    //
    // On screen, not merely selected (2026-09-10 device report): closing
    // the note leaves it selected, and on a phone the tab it lands on has
    // an empty body by design — so the shortcut showed nothing at all.
    // The tree being up is what says the note is closed.
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    final onScreen = !narrow || !_treeVisible;
    if (onScreen &&
        _selected == path &&
        !_selectedIsDir &&
        !_showQuickNoteChooser) {
      if (_tab != ShellTab.quickNote) {
        setState(() {
          _tab = ShellTab.quickNote;
          _visitedTabs.add(ShellTab.quickNote);
        });
      }
      return;
    }
    await _openQuickNote(path);
  }

  /// Shows the choose/create screen, wherever this layout keeps it.
  ///
  /// Every layout shows it inline in the Quick note tab body (the rail on
  /// wide, the bottom bar on narrow), so the tab chrome always persists —
  /// opening it over the shell used to hide the rail on wide.
  void _openQuickNoteChooser() {
    setState(() => _showQuickNoteChooser = true);
    _selectShellTab(ShellTab.quickNote);
  }

  void _toggle(String path) {
    setState(() {
      if (_expanded.contains(path)) {
        _expanded.remove(path);
      } else {
        _expanded.add(path);
      }
    });
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    } finally {
      _busy = false;
    }
  }

  /// Opens a note the template flow just filed (#51): preview per its
  /// `open` directive, caret per its `{{cursor}}`. The state the flow
  /// cannot know is set here, not in the flow.
  void _onTemplateNoteFiled({
    required String path,
    required bool preview,
    required int? caret,
  }) {
    setState(() {
      if (preview) _previewVisible = true;
      _selected = path;
      _selectedIsDir = false;
      _treeVisible = false;
      _pendingAnchor = null;
      _pendingCaretOffset = caret;
      _resetNoteKind();
      _noteOpened();
    });
  }

  /// Adds a task from the Todo tab's add FAB (T-TD-04).
  Future<void> _addTodo() async {
    const AppLogger(name: 'todo').debug('todo add pressed');
    final snapshot = _todoController.snapshot;
    final line = await showTodoTaskDialog(
      context,
      today: DateTime.now(),
      knownTokens: snapshot == null
          ? const <String>{}
          : snapshotTokens(snapshot),
    );
    if (line == null || !mounted) {
      return;
    }
    await _guard(() => _todoController.add(line));
  }

  /// Long-press context menu on a tree row (T-UI-05): the note actions,
  /// scoped to the pressed row. New note/folder target the row's folder
  /// (issue #100 moved the menu itself into `shell_row_menu.dart`).
  Future<void> _showRowMenu(Note note) async {
    final here = note.isDir ? note.path : parentOf(note.path);
    final isQuickNote = await widget.controller.ops?.quickNotePath == note.path;
    if (!mounted) return;
    final action = await showRowMenuSheet(
      context,
      note: note,
      isQuickNote: isQuickNote,
    );
    if (!mounted) return;
    await _rowActions.run(context, action, note, here);
  }

  /// Right-click context menu on a tree row (T-PP-20): the same actions
  /// at the cursor instead of in the phone's bottom sheet.
  Future<void> _showRowMenuAt(Note note, Offset position) async {
    final here = note.isDir ? note.path : parentOf(note.path);
    final isQuickNote = await widget.controller.ops?.quickNotePath == note.path;
    if (!mounted) return;
    final action = await showRowMenuAt(
      context,
      note: note,
      isQuickNote: isQuickNote,
      position: position,
    );
    if (!mounted) return;
    await _rowActions.run(context, action, note, here);
  }

  /// Opens the history of the note at [path]; a restore reloads the open
  /// note when it is that one.
  Future<void> _openHistory(String path) => openNoteHistory(
    context,
    session: widget.controller,
    unsaved: widget.unsavedTracker,
    path: path,
    onRestored: () {
      if (!mounted || _selected != path) return;
      setState(() => _noteReloadToken++);
    },
  );

  /// The open note's ⋮ menu (mockup H2), on the phone's note bar and in
  /// the wide layout's editor header.
  Widget _noteMenu() => NoteMenuButton(
    onSelected: (action) {
      final path = _selected;
      if (path == null) return;
      unawaited(switch (action) {
        NoteMenuAction.history => _openHistory(path),
        NoteMenuAction.rename => _rowActions.rename(context, path),
        NoteMenuAction.move => _rowActions.move(context, path),
        NoteMenuAction.delete => _rowActions.delete(context, path),
      });
    },
  );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selectedPath = _selected;
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    _markOpenNote(controller.root, selectedPath);
    final splitsPreview = previewSplits(
      _editorSettings.previewMode,
      narrow: narrow,
      editor: _editorSettings.editorKind,
      previewEnabled: _editorSettings.previewEnabled,
    );
    final props = ShellLayoutProps(
      controller: controller,
      selectedPath: selectedPath,
      selectedIsDir: _selectedIsDir,
      treeVisible: _treeVisible,
      previewFullScreen: _previewFullScreen,
      previewSplitsHere: splitsPreview,
      previewVisible: _previewVisible,
      previewToggleVisible: _previewToggleVisible,
      noteHidingTabs: _noteHidingTabs,
      noteFade: _fullNoteFade,
      shortcutBindings: _appShortcutBindings(),
      onCloseFullScreenNote: _closeFullScreenNote,
      onLeaveFullScreenPreview: () =>
          setState(() => _previewFullScreen = false),
      isQuickNote: _selected != null && _selected == _quickNotePath,
      noteBarActions: _noteBarActions(splitsPreview: splitsPreview),
      buildTabShell: () => _tabShell(
        controller: controller,
        bodies: _tabBodyChildren(controller),
      ),
      buildFullNote: (path) => _fullNoteView(controller, path),
      window: widget.window,
      windowTitle: _windowTitle,
      sidebarVisible: _sidebarVisible,
      onToggleSidebar: _toggleSidebar,
      shellFocus: _shellFocus,
      tabIndex: _tab.index,
      onDestinationSelected: _onDestinationSelected,
      buildWideSlots: () => _wideSlots(controller),
    );
    return narrow
        ? NarrowShellLayout(props: props)
        : WideShellLayout(props: props);
  }

  /// The open note's actions on the phone's note bar: the kind toggles,
  /// the preview controls where a preview can be toggled at all, and the
  /// ⋮ menu.
  List<Widget> _noteBarActions({required bool splitsPreview}) {
    return [
      ..._kindActions,
      if (!splitsPreview && _previewToggleVisible) ...[
        // Fullscreen goes before the toggle, not after it (user,
        // 2026-09-17). App-bar actions are laid out from the right, so an
        // action that only appears in one state has to be inserted on the
        // left: added after, the fullscreen button took the eye's place
        // and pushed the toggle along, moving the one button the user
        // alternates on out from under the thumb that was already there.
        if (_previewVisible) _previewFullScreenAction(),
        _previewToggleAction(),
      ],
      _noteMenu(),
    ];
  }

  /// The wide layout's tab slots: the tree + detail split for Files (and
  /// for an open quick note, which lives in the detail pane — its tab
  /// body is empty by design), then one slot per remaining tab.
  ///
  /// Bodies are kept mounted exactly like the narrow stack
  /// ([TabBodyStack]): the tree/detail pair shares ONE slot across Files
  /// and the open quick note, so a tab switch never re-runs the tree's
  /// per-level queries or re-inflates the open editor. The 2026-09-10
  /// desktop log showed the cost of the old swap-in/swap-out: 6-9 ms tree
  /// flattens, 28 ms Search and 62 ms Settings first builds, every switch.
  List<Widget> _wideSlots(LibrarySession controller) {
    final filesVisible =
        _tab == ShellTab.files ||
        (_tab == ShellTab.quickNote && !_showQuickNoteChooser);
    return [
      _wideSlot(visible: filesVisible, child: _wideBody(controller)),
      // One slot per remaining tab, in tab order so a slot's identity
      // never moves. Unvisited tabs build the empty placeholder
      // `_tabBodyFor` returns.
      for (final tab in ShellTab.values)
        if (tab != ShellTab.files && tab != ShellTab.quickNote)
          _wideSlot(
            visible: _tab == tab,
            retainLayout: tab == ShellTab.search,
            child: _tabBodyFor(tab, controller),
          ),
      // The quick-note chooser: empty while its note is open in the slot
      // above, the choose/create screen otherwise.
      _wideSlot(
        visible: _tab == ShellTab.quickNote && _showQuickNoteChooser,
        child: _tabBodyFor(ShellTab.quickNote, controller),
      ),
    ];
  }

  /// One kept-alive wide-layout slot. Hidden slots skip layout, paint and
  /// tickers (see [TabBodyStack]); [retainLayout] keeps an expensive one
  /// laid out, so showing it is paint-only.
  Widget _wideSlot({
    required bool visible,
    required Widget child,
    bool retainLayout = false,
  }) {
    final slot = TickerMode(enabled: visible, child: child);
    if (retainLayout) {
      return Visibility(
        visible: visible,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: slot,
      );
    }
    return Offstage(offstage: !visible, child: slot);
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
  Widget? _tabFab() {
    final fab = switch (_tab) {
      ShellTab.files => _newItemFab(),
      ShellTab.todo => _todoAddFab(),
      ShellTab.search || ShellTab.quickNote || ShellTab.settings => null,
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
      onPressed: _addTodo,
      child: const Icon(Icons.add),
    );
  }

  /// The expandable "+" FAB (bottom-right, above the bottom nav):
  /// reveals New note / New folder mini FABs; each creates in the
  /// selected folder, root if none (T-UI-05).
  Widget _newItemFab() {
    return NewItemFab(
      onAnchor: (center) => _fabAnchor = center,
      expanded: _fabExpanded,
      onToggle: () => setState(() => _fabExpanded = !_fabExpanded),
      onNewNote: () {
        _closeFab();
        unawaited(_createFlow.createNote(context));
      },
      onNewListNote: () {
        _closeFab();
        unawaited(_createFlow.createListNote(context));
      },
      onNewAudioNote: () {
        _closeFab();
        unawaited(_createFlow.createAudioNote(context));
      },
      onNewFromTemplate: () {
        _closeFab();
        unawaited(_templateFlow.createFromTemplate(context));
      },
      onNewFolder: () {
        _closeFab();
        unawaited(_createFlow.createFolder(context));
      },
    );
  }

  /// Collapses the expanded FAB menu.
  void _closeFab() => setState(() => _fabExpanded = false);

  /// Covers [child] with the FAB-menu scrim: a circle that grows out of
  /// the main FAB icon, dims the body, and closes the menu on any tap
  /// (the FABs live in the Scaffold's FAB slot, above this layer, so they
  /// stay tappable). Always mounted; inert while collapsed.
  /// Wraps [child] in the FAB menu's tap-to-dismiss scrim.
  ///
  /// [enabled] is false on the tabs that have no expandable FAB. Not an
  /// optimisation: the scrim resolves the FAB's anchor key during layout,
  /// and since the Files and Todo tabs now share one FAB slot, a scrim
  /// left mounted on Todo reaches for an anchor that tab does not have.
  ///
  /// Never toggle this wrapper around a kept-alive subtree (like the tab
  /// stack): swapping between the bare child and the [Stack] reparents it
  /// and remounts every state inside. The Files slot below is always
  /// wrapped; hiding it via [Offstage] skips layout, so the anchor is only
  /// resolved while Files is visible.
  Widget _withFabScrim(Widget child, {bool enabled = true}) {
    if (!enabled) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        FabScrim(
          anchor: _fabAnchor,
          expanded: _fabExpanded,
          onClose: _closeFab,
        ),
      ],
    );
  }

  /// The sort-direction toggle (T-UI-03): the mockup's `unfold_more`
  /// chevrons; the icon reflects the current direction.
  Widget _sortToggle() {
    return TreeSortToggle(
      ascending: _editorSettings.treeSort == TreeSort.nameAsc,
      onToggle: () => unawaited(_toggleTreeSort()),
    );
  }

  void _openTrash(LibrarySession controller) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrashScreen(controller: controller),
      ),
    );
  }

  /// Trash/sort actions of the Files-tab app bar (per mockup: trash +  /// sort chevrons; the settings gear moved to the Settings tab).
  List<Widget> _filesAppBarActions(LibrarySession controller) {
    return [
      _syncActions.button(context, controller),
      IconButton(
        key: const Key('open-trash'),
        tooltip: AppStrings.trashTitle,
        icon: const Icon(Icons.delete),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => TrashScreen(controller: controller),
          ),
        ),
      ),
      _sortToggle(),
    ];
  }

  /// Closes the full-screen note: returns to the tab it was opened from,
  /// with its tree/body visible (the note stays highlighted).
  void _closeFullScreenNote() {
    setState(() {
      _tab = _noteFromTab;
      _visitedTabs.add(_noteFromTab);
      _treeVisible = true;
      _resetNoteKind();
      _noteClosed();
    });
    logNextFrame('shell', 'note close first frame');
  }

  /// The app bar's title on each tab: the tab's own name, matching the
  /// label under the icon that got you there. The Files tab used to say
  /// "Niman", which named the app on a screen that is about the tree.
  String get _tabTitle => switch (_tab) {
    ShellTab.files => AppStrings.tabFiles,
    ShellTab.todo => AppStrings.todoTitle,
    ShellTab.search => AppStrings.tabSearch,
    ShellTab.quickNote => AppStrings.quickNoteTitle,
    ShellTab.settings => AppStrings.tabSettings,
  };

  /// The narrow shell: app bar for the tab + the bottom navigation bar.
  ///
  /// The `_tab`-dependent chrome (title, Files actions, FAB, nav-bar
  /// selection, and the stack's visible index) rebuilds through a
  /// [ValueListenableBuilder] on [_tabListenable], so a plain switch
  /// refreshes it without a shell-wide `setState` (#46). [bodies] are built
  /// once by the caller and reused by identity: the kept-alive bodies do not
  /// depend on the current tab, so a switch keeps their instances and their
  /// subtrees are skipped.
  Widget _tabShell({
    required LibrarySession controller,
    required List<Widget> bodies,
  }) {
    return ValueListenableBuilder<ShellTab>(
      valueListenable: _tabListenable,
      builder: (context, tab, _) => Scaffold(
        appBar: AppBar(
          title: Text(_tabTitle),
          actions: tab == ShellTab.files
              ? _filesAppBarActions(controller)
              : const [],
        ),
        // Bodies stay mounted once visited (see TabBodyStack): the switch
        // only flips visibility and fades the incoming body in, instead of
        // rebuilding two transparency layers mid-animation. The stack itself
        // stays the direct body child on every tab: wrapping it in anything
        // conditional (like the FAB scrim was) reparents the whole subtree
        // and remounts every body, defeating the keep-alive. Only its
        // currentIndex changes here; [bodies] are the same instances across
        // a switch, so no body re-inflates.
        body: TabBodyStack(
          currentIndex: tab.index,
          retainLayout: <int>{ShellTab.search.index},
          children: bodies,
        ),
        floatingActionButton: _tabFab(),
        bottomNavigationBar: switch (controller.sync) {
          final sync? when tab == ShellTab.files => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncProgressStrip(sync: sync),
              _shellTabs(),
            ],
          ),
          _ => _shellTabs(),
        },
      ),
    );
  }

  /// The bottom tab bar.
  ///
  /// Shown by the tab shell *and* by an open note: the tabs are how the
  /// app is navigated, so having them vanish behind a note meant going
  /// back before going anywhere.
  Widget _shellTabs() {
    return ShellTabBar(
      selectedIndex: _tab.index,
      onDestinationSelected: _onDestinationSelected,
    );
  }

  void _onDestinationSelected(int index) {
    final tab = ShellTab.values[index];
    const AppLogger(name: 'shell').debug('tap tab: ${tab.name}');
    if (tab == ShellTab.quickNote) {
      unawaited(_openQuickNoteFromTile());
      return;
    }
    // Tapping the tab a note was opened from closes the note: the tab is
    // already selected, so nothing else would happen.
    if (tab == _tab && !_treeVisible) {
      _closeFullScreenNote();
      return;
    }
    _selectShellTab(tab);
  }

  /// The title bar's text: the app, and the open note when there is one.
  String get _windowTitle {
    final path = _selected;
    if (path == null || _selectedIsDir) return AppStrings.appTitle;
    return '${AppStrings.appTitle} — ${p.basename(path)}';
  }

  /// Shows/hides the wide tree pane; the rail stays (T-PP-22).
  void _toggleSidebar() {
    setState(() => _sidebarVisible = !_sidebarVisible);
  }

  /// The app accelerators (T-PP-10), built from the shared registry so the
  /// installed keys and the in-app reference cannot drift.
  Map<ShortcutActivator, VoidCallback> _appShortcutBindings() {
    return appShortcutBindings({
      AppCommand.newNote: () => unawaited(_createFlow.createNote(context)),
      AppCommand.newListNote: () =>
          unawaited(_createFlow.createListNote(context)),
      AppCommand.newAudioNote: () =>
          unawaited(_createFlow.createAudioNote(context)),
      AppCommand.newTodo: () {
        _openTodo();
        unawaited(_addTodo());
      },
      AppCommand.quickNote: () => unawaited(_openQuickNoteFromTile()),
      AppCommand.toggleSidebar: _toggleSidebar,
      AppCommand.tabFiles: () => _onDestinationSelected(ShellTab.files.index),
      AppCommand.tabTodo: () => _onDestinationSelected(ShellTab.todo.index),
      AppCommand.tabSearch: () => _onDestinationSelected(ShellTab.search.index),
      AppCommand.tabQuickNote: () =>
          _onDestinationSelected(ShellTab.quickNote.index),
      AppCommand.tabSettings: () =>
          _onDestinationSelected(ShellTab.settings.index),
    });
  }

  /// The wide-layout body: the tree pane and the split detail pane.
  ///
  /// The tree keeps its own controls at the base (T-PP-22), and an open
  /// note gets a header inside the detail pane carrying its name and the
  /// note controls the window app bar used to hold. Hiding the tree (the
  /// title bar's toggle) gives its width to the detail pane.
  Widget _wideBody(LibrarySession controller) {
    final noteOpen = _selected != null && !_selectedIsDir;
    return Row(
      children: [
        if (_sidebarVisible) ...[
          SizedBox(
            width: _editorSettings.treeWidth,
            child: Column(
              children: [
                Expanded(child: _treePane(controller)),
                if (controller.sync case final sync?)
                  SyncProgressStrip(sync: sync),
                _treeFooter(controller),
              ],
            ),
          ),
          _treeDivider(),
        ],
        Expanded(
          child: Column(
            children: [
              if (noteOpen) _editorHeader(),
              Expanded(
                child: ShellDetailPane(
                  root: controller.root,
                  selectedPath: _selected,
                  selectedIsDir: _selectedIsDir,
                  showLineNumbers: _editorSettings.lineNumbers,
                  autofocusEditor: _editorSettings.autofocusEditor,
                  linkType: _editorSettings.linkType,
                  missingNoteLocation: _editorSettings.missingNoteLocation,
                  attachmentsFolder: _editorSettings.attachmentsFolder,
                  indentWidth: _editorSettings.indentWidth,
                  toolbarLayout: _editorSettings.toolbarLayout,
                  splitPreview: previewSplits(
                    _editorSettings.previewMode,
                    narrow: false,
                    editor: _editorSettings.editorKind,
                    previewEnabled: _editorSettings.previewEnabled,
                  ),
                  showPreview:
                      _editorSettings.previewEnabled && _previewVisible,
                  showWysiwyg: _editorSettings.editorKind == EditorKind.wysiwyg,
                  // A single enabled editor has nowhere to switch to:
                  // the note hides its switch instead of offering a
                  // dead toggle.
                  onEditorKindChanged: _editorSettings.editorsEnabled.length > 1
                      ? _setEditorKind
                      : null,
                  splitFraction: _editorSettings.splitRatio,
                  onSplitFractionChanged: _onSplitFractionChanged,
                  onSplitDragEnd: _onSplitDragEnd,
                  linkSource: _linkSource,
                  onOpenNote: _openNoteFromLink,
                  initialAnchor: _pendingAnchor,
                  kindMode: !_kindRawMode,
                  onNoteKindChanged: _onNoteKindChanged,
                  unsavedTracker: widget.unsavedTracker,
                  spellCheck: widget.spellCheck,
                  reloadToken: _noteReloadToken,
                  saveNote: _noteSaver(controller),
                  createMissingNote: _missingNoteCreator(controller),
                  statusActions: [
                    // The view controls live in the note's status row on the
                    // desktop (T-PP-22): the header above is about the file,
                    // the footer about how it is shown.
                    if (_previewToggleVisible) ...[
                      if (_editorSettings.editorKind == EditorKind.source)
                        _layoutModeAction(compact: true),
                      if (!previewSplits(
                        _editorSettings.previewMode,
                        narrow: false,
                        editor: _editorSettings.editorKind,
                        previewEnabled: _editorSettings.previewEnabled,
                      ))
                        _previewToggleAction(compact: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The draggable tree/detail divider (T-PP-21): a 1 px visual with a
  /// wider grab box and the resize cursor, mirroring the editor split.
  /// Moves apply live; the lift persists the width to the library.
  Widget _treeDivider() {
    return GestureDetector(
      key: const Key('tree-divider'),
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) => setState(() {
        _editorSettings = _editorSettings.copyWith(
          treeWidth: (_editorSettings.treeWidth + details.delta.dx).clamp(
            minTreeWidth,
            maxTreeWidth,
          ),
        );
      }),
      onHorizontalDragEnd: (_) => unawaited(_persistTreeWidth()),
      child: const MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: SizedBox(
          width: 13,
          child: Center(child: VerticalDivider(width: 1)),
        ),
      ),
    );
  }

  /// Persists the dragged tree width to the library settings.
  Future<void> _persistTreeWidth() async {
    await widget.controller.setTreeWidth(_editorSettings.treeWidth);
    widget.controller.notify();
  }

  /// All five tab bodies, in tab order: each mounts on its first visit and
  /// stays mounted (query, results, and scroll survive a switch), while the
  /// fade only covers the incoming body — no cross-fade of two transparency
  /// layers, and no re-inflate mid-animation.
  ///
  /// Built once per shell build and handed to [_tabShell] by identity, so a
  /// plain tab switch reuses the instances instead of rebuilding every body
  /// (#46). Only the search slot retains layout while hidden (T-TS-10): it
  /// is the one whose show-layout costs frames; the plain lists relayout
  /// cheaply.
  List<Widget> _tabBodyChildren(LibrarySession controller) => [
    for (final tab in ShellTab.values) _tabBodyFor(tab, controller),
  ];

  /// The body for [tab], or a placeholder until its first visit (lazy so
  /// opening a library does not inflate all five tabs up front).
  Widget _tabBodyFor(ShellTab tab, LibrarySession controller) {
    if (!_visitedTabs.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      // Always scrim-wrapped (never toggled): see [_withFabScrim].
      ShellTab.files => _withFabScrim(_treePane(controller)),
      ShellTab.todo => TodoTab(
        controller: _todoController,
        reminders: widget.reminders,
        onAddTask: _addTodo,
      ),
      ShellTab.search => _searchSlot(controller),
      // Empty unless the shell actually sent the user here to choose: an
      // open quick note leaves this body painted under the opening note.
      ShellTab.quickNote =>
        _showQuickNoteChooser
            ? QuickNoteTab(controller: controller, onOpen: _openQuickNote)
            : const SizedBox.shrink(),
      ShellTab.settings => SettingsTab(
        controller: controller,
        spellCheck: widget.spellCheck,
        transcription: widget.transcription,
      ),
    };
  }

  /// The Search tab's body; the slot owns which of the two shows
  /// (issue #100 moved it into [SearchSlot]).
  Widget _searchSlot(LibrarySession controller) {
    return SearchSlot(controller: controller, onOpenNote: _openSearchNote);
  }

  /// The desktop tree's controls at the base of its column (T-PP-22):
  /// creation, the trash and the sort order — the app-bar actions the
  /// wide layout used to carry, where the tree is the thing they act on
  /// (issue #100 moved the bar itself into [TreeFooterBar]).
  Widget _treeFooter(LibrarySession controller) {
    return TreeFooterBar(
      controller: controller,
      onNewItem: _onNewItem,
      syncButton: _syncActions.button(context, controller),
      sortToggle: _sortToggle(),
    );
  }

  /// Runs the create flow behind a tree-footer menu entry.
  void _onNewItem(NewShellItem item) {
    switch (item) {
      case NewShellItem.note:
        unawaited(_createFlow.createNote(context));
      case NewShellItem.listNote:
        unawaited(_createFlow.createListNote(context));
      case NewShellItem.audioNote:
        unawaited(_createFlow.createAudioNote(context));
      case NewShellItem.template:
        unawaited(_templateFlow.createFromTemplate(context));
      case NewShellItem.folder:
        unawaited(_createFlow.createFolder(context));
    }
  }

  /// The open note's header in the detail pane (issue #100 moved the bar
  /// itself into [EditorHeaderBar]).
  Widget _editorHeader() {
    return EditorHeaderBar(
      path: _selected!,
      actions: [..._kindActions, _noteMenu()],
    );
  }

  /// The tree pane: the action bar and the note tree — the whole body on
  /// phones, the left column on wide screens.
  Widget _treePane(LibrarySession controller) {
    return NoteTree(
      controller: controller,
      nameDesc: _editorSettings.treeSort == TreeSort.nameDesc,
      selectedPath: _selected,
      expanded: _expanded,
      onToggle: _toggle,
      onSelect: _select,
      onLongPress: _showRowMenu,
      onSecondaryTapDown: (note, details) =>
          _showRowMenuAt(note, details.globalPosition),
    );
  }
}
