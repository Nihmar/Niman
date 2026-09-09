import 'dart:async';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/frame_log.dart';
import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/shortcuts.dart';
import 'package:copist/src/core/storage_access.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/editor/toolbar_layout.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_controller.dart';
import 'package:copist/src/todo/todo_filter.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:copist/src/ui/kinds/list_note.dart';
import 'package:copist/src/ui/name_dialog.dart';
import 'package:copist/src/ui/new_item_fab.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/open_library.dart';
import 'package:copist/src/ui/quick_note_tab.dart';
import 'package:copist/src/ui/search_screen.dart';
import 'package:copist/src/ui/settings.dart';
import 'package:copist/src/ui/settings_tab.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/tab_body_stack.dart';
import 'package:copist/src/ui/tags_screen.dart';
import 'package:copist/src/ui/todo_edit_dialog.dart';
import 'package:copist/src/ui/todo_help.dart';
import 'package:copist/src/ui/todo_tab.dart';
import 'package:copist/src/ui/trash.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    unawaited(_publishShortcuts());
    unawaited(_applyLanguage());
  }

  /// Applies the stored UI language (T-L10N-03).
  ///
  /// Read once at start: the app renders in the OS language until it
  /// lands, which is the same answer whenever the user never chose one.
  Future<void> _applyLanguage() async {
    AppLanguages.choice = await ref.read(librarySessionProvider).language;
  }

  /// Publishes the launcher quick actions (T-SC-02).
  ///
  /// Here rather than in the shell: they belong to the app, not to an
  /// open library, so they are there on the very first launch too.
  Future<void> _publishShortcuts() {
    return ref.read(shortcutServiceProvider).publish({
      ShortcutAction.quickNote: AppStrings.shortcutQuickNote,
      ShortcutAction.newTodo: AppStrings.shortcutNewTodo,
      ShortcutAction.newNote: AppStrings.shortcutNewNote,
      ShortcutAction.newList: AppStrings.shortcutNewList,
    });
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
    return StreamBuilder<int>(
      stream: controller.events,
      initialData: controller.revision,
      builder: (context, _) => switch (controller.phase) {
        LibraryPhase.ready => _LibraryShell(
          controller: controller,
          reminders: ref.read(reminderServiceProvider),
          shortcuts: ref.read(shortcutServiceProvider),
          todoSourceFactory: ref.read(todoSourceFactoryProvider),
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
    required this.shortcuts,
    required this.todoSourceFactory,
  });

  final LibrarySession controller;

  /// The OS reminder service (notification taps open the Todo tab).
  final ReminderService reminders;

  /// The launcher quick actions (T-SC-03: each one lands on the flow its
  /// in-app control uses).
  final ShortcutService shortcuts;

  /// Builds the todo file source per library root (overridden with a
  /// fake in widget tests).
  final TodoSource Function(String root) todoSourceFactory;

  @override
  State<_LibraryShell> createState() => _LibraryShellState();
}

/// The bottom-navigation tabs (phone/narrow layout only).
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

  /// The currently selected bottom tab (narrow layout).
  ShellTab _tab = ShellTab.files;

  /// Every tab visited so far: bodies mount on first visit and stay
  /// mounted afterwards, so a switch only flips visibility instead of
  /// disposing one state and inflating another mid-animation (the
  /// 2026-09-08 device log put that inflate at 14-17 ms of frame build).
  /// Query, results, and scroll therefore survive a switch, by choice.
  final Set<ShellTab> _visitedTabs = <ShellTab>{ShellTab.files};

  /// Whether the Tags screen has ever been opened: like the tabs, it
  /// mounts once and stays alive so the search query survives the flip.
  bool _tagsVisited = false;

  /// The tab active when the full-screen note opened (back returns there).
  ShellTab _noteFromTab = ShellTab.files;

  /// The app-bar action opening the todo.txt format reference.
  ///
  /// The dialog writes the syntax, so a user can go a long way without
  /// seeing it — until they open todo.txt in another editor, or wonder
  /// what the chips are. The reference is one tap from the list.
  Widget _todoHelpAction() {
    return IconButton(
      key: const Key('todo-help'),
      tooltip: AppStrings.todoHelpTooltip,
      icon: const Icon(Icons.help_outline),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (context) => const TodoHelpScreen()),
      ),
    );
  }

  /// Shows the todo list, wherever this layout keeps it.
  ///
  /// The bottom-nav tab only exists on a phone; the wide layout pushes it
  /// as a screen instead. Reminder taps land here, so a tablet no longer
  /// opens the app on the file tree with no hint of why.
  void _openTodo() {
    if (MediaQuery.sizeOf(context).width < _phoneBreakpoint) {
      _selectShellTab(ShellTab.todo);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.todoTitle),
            actions: [_todoHelpAction()],
          ),
          // 2026-09-07 user feedback: the add action is a FAB, not an
          // app-bar `+` (the bar `+` read as something else).
          floatingActionButton: FloatingActionButton(
            key: const Key('todo-add-wide'),
            heroTag: 'todo-add-wide',
            tooltip: AppStrings.todoAddTooltip,
            onPressed: _addTodo,
            child: const Icon(Icons.add),
          ),
          body: TodoTab(
            controller: _todoController,
            reminders: widget.reminders,
          ),
        ),
      ),
    );
  }

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
    setState(() {
      _tab = tab;
      _visitedTabs.add(tab);
      _treeVisible = true;
      _fabExpanded = false;
      // Leaving any open note: the tabs show at once (issue #4).
      _noteClosed();
    });
    // Time-to-visible of the switch itself: the 'tap tab' line above is the
    // input, this is when the first new frame actually painted (with the
    // navigation-bar selection animation the user said lags on Search).
    logNextFrame('shell', 'tab ${tab.name} first frame');
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
  bool _lineNumbers = true;
  bool _autofocusEditor = false;

  /// Preview layout (T-M2-08): the mode override and the split ratio the
  /// shell persists; the effective mode is resolved at build (width ×
  /// override).
  PreviewLayoutMode _previewMode = PreviewLayoutMode.auto;
  double _splitRatio = defaultSplitRatio;

  /// The editor's link format and indent width (settings).
  LinkType _linkType = LinkType.wikilink;
  int _indentWidth = 2;

  /// The editor toolbar the user arranged (settings, T-TB-04).
  ToolbarLayout _toolbarLayout = ToolbarLayout.defaults;

  /// The library tree sort order (T-UI-03).
  TreeSort _treeSort = TreeSort.nameAsc;

  /// Phone (< [_phoneBreakpoint]) mode: which pane is visible.
  /// `false` = the selected note is open full-screen.
  bool _treeVisible = true;

  /// Whether the Search tab shows the Tags screen (T-M3-06) instead of
  /// the search box; the tabs button flips it and back.
  bool _showTags = false;

  /// The link-resolution source (T-M3-07), resolved from the session.
  LinkSource? _linkSource;

  /// The todo state (T-TD-04): owned here so the tab body and the tab's
  /// app-bar add action share one controller.
  late final TodoController _todoController;

  /// Notification taps while running: a todo tap opens the Todo tab.
  StreamSubscription<String?>? _reminderTaps;
  StreamSubscription<ShortcutAction>? _shortcutTaps;

  /// A heading anchor to land on after the next note opens (T-M3-07).
  String? _pendingAnchor;

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

  /// Whether the app bar shows the editor/preview eye action: hidden in
  /// kind mode (the note is a list, not a document) unless the user is
  /// in raw-edit mode.
  bool get _previewToggleVisible => _noteKind == null || _kindRawMode;

  /// The kind toggle actions (T-TK-05): a kinded note offers the raw
  /// editor (pencil); in raw mode the kind GUI is offered back. Empty
  /// when no kinded note is open.
  List<Widget> get _kindActions {
    if (_noteKind == null) return const [];
    return [
      if (_kindRawMode)
        IconButton(
          key: const Key('kind-show-list'),
          tooltip: AppStrings.showListTooltip,
          icon: const Icon(Icons.checklist),
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
  /// the heading anchor, and clears pending anchors for direct selections.
  void _openNoteFromLink(String path, String? anchor) {
    const AppLogger(name: 'links').debug(
      'shell open request: $path anchor=${anchor == null ? '-' : '"$anchor"'} '
      '(current tab ${_tab.name})',
    );
    if (_opensPreviewOnly()) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = path;
      _selectedIsDir = false;
      _treeVisible = false;
      _noteFromTab = _tab;
      _pendingAnchor = anchor;
      _resetNoteKind();
      _noteOpened();
    });
  }

  /// Whether the FAB menu (New note / New folder minis) is expanded;
  /// the shell owns it so the body can be scrimmed while it is open.
  bool _fabExpanded = false;

  /// Marks the main FAB so [FabScrim]'s reveal circle is centered on its
  /// icon (the shell owns it: the FAB slot and the scrim are siblings).
  final GlobalKey _fabAnchorKey = GlobalKey();

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
  }

  /// Whether a note opened right now would show only the preview (the
  /// editor hidden): the IME has no target and must go before the
  /// transition, or its resize lands mid-fade.
  bool _opensPreviewOnly() {
    if (!_previewVisible) return false;
    final narrow = MediaQuery.sizeOf(context).width < _phoneBreakpoint;
    return !_effectiveSplit(narrow: narrow);
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

  /// The pending tab-hide after a note open (canceled on close).
  Timer? _noteHideTimer;

  /// Guards the pending hide against a rapid close/reopen.
  int _noteHideRevision = 0;

  /// The app-bar fullscreen action, next to the editor/preview eye.
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
      showLineNumbers: _lineNumbers,
      autofocusEditor: _autofocusEditor,
      linkType: _linkType,
      indentWidth: _indentWidth,
      toolbarLayout: _toolbarLayout,
      splitPreview: _effectiveSplit(narrow: true),
      showPreview: _previewVisible,
      splitFraction: _splitRatio,
      onSplitFractionChanged: _onSplitFractionChanged,
      onSplitDragEnd: _onSplitDragEnd,
      libraryRoot: controller.root,
      linkSource: _linkSource,
      onOpenNote: _openNoteFromLink,
      initialAnchor: _pendingAnchor,
      kindMode: !_kindRawMode,
      onNoteKindChanged: _onNoteKindChanged,
    );
  }

  /// The way back out of [_previewFullScreen], floating over the preview.
  ///
  /// The chrome that would normally carry this action is exactly what is
  /// hidden, so the button rides above the content instead — inside the
  /// safe area, so a notch or a rounded corner never eats it.
  Widget _exitFullScreenButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            type: MaterialType.circle,
            color: Theme.of(context).colorScheme.surface
                .withValues(alpha: 0.85),
            elevation: 2,
            child: IconButton(
              key: const Key('preview-fullscreen-exit'),
              tooltip: AppStrings.exitFullScreenTooltip,
              icon: const Icon(Icons.fullscreen_exit),
              onPressed: () => setState(() => _previewFullScreen = false),
            ),
          ),
        ),
      ),
    );
  }

  /// The app-bar eye action: flips the editor/preview pane (phone
  /// full-screen note and the wide switch override).
  Widget _previewToggleAction() {
    return IconButton(
      key: const Key('editor-preview-toggle'),
      tooltip: _previewVisible
          ? AppStrings.showEditorTooltip
          : AppStrings.showPreviewTooltip,
      icon: Icon(_previewVisible ? Icons.edit : Icons.visibility),
      onPressed: _togglePreview,
    );
  }

  /// Below this width the shell is single-pane (spec: phones are
  /// full-screen tree or editor, the split lands at 600 px and up).
  static const double _phoneBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _todoController = TodoController(
      session: widget.controller,
      reminders: widget.reminders,
      sourceFactory: widget.todoSourceFactory,
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
    _shortcutTaps = widget.shortcuts.actions.listen(
      (action) => unawaited(_runShortcut(action)),
    );
    unawaited(_applyReminderLaunch());
    unawaited(_applyShortcutLaunch());
    unawaited(_refreshEditorSettings());
    unawaited(_loadLinkSource());
    unawaited(_warmSearchSource());
  }

  /// Opens the background search connection before anything asks for it.
  ///
  /// The first `SearchScreen` asks the session for its source, and that
  /// call is what spawns drift's background isolate and opens a second
  /// SQLite connection on the database file. It is awaited rather than
  /// blocking, but an isolate spawn is not free on a phone: it competes
  /// for the same cores as the frame being drawn, and the frame being
  /// drawn is the tab-switch animation (2026-09-08 user feedback: moving
  /// to and from Search sometimes stutters).
  ///
  /// Doing it here costs the same work at a moment nothing is animating.
  /// After a delay, not in `initState`: opening a library is already the
  /// heaviest stretch of a run, and this has no deadline — whoever gets
  /// there first still gets a source, since the session caches one.
  Future<void> _warmSearchSource() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final started = DateTime.now();
    final source = await widget.controller.searchSource;
    const AppLogger(name: 'search').info(
      'source warmed in ${DateTime.now().difference(started).inMilliseconds}ms '
      '(${source == null ? 'unavailable' : 'ready'})',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteHideTimer?.cancel();
    unawaited(_reminderTaps?.cancel());
    unawaited(_shortcutTaps?.cancel());
    _todoController.dispose();
    super.dispose();
  }

  /// Re-reconciles reminders on return to the app: the exact-alarm and
  /// notification grants live in system settings, so coming back from
  /// there must reschedule without waiting for the next file change.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_todoController.resyncReminders());
      return;
    }
    // Leaving the foreground may be the last thing this process does (a
    // swipe away, an OEM battery kill): get the buffered log on disk
    // while there is still a chance to.
    unawaited(AppLog.flush());
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
        await _createNote();
      case ShortcutAction.newList:
        await _createListNote();
    }
  }

  @override
  void didUpdateWidget(covariant _LibraryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_refreshEditorSettings());
  }

  Future<void> _refreshEditorSettings() async {
    final controller = widget.controller;
    final lineNumbers = await controller.lineNumbersEnabled;
    final autofocus = await controller.editorAutofocusEnabled;
    final previewMode = await controller.previewMode;
    final splitRatio = await controller.splitRatio;
    final linkType = await controller.linkType;
    final indentWidth = await controller.indentWidth;
    final treeSort = await controller.treeSort;
    final toolbar = await controller.editorToolbar;
    if (mounted &&
        (lineNumbers != _lineNumbers ||
            autofocus != _autofocusEditor ||
            previewMode != _previewMode ||
            splitRatio != _splitRatio ||
            linkType != _linkType ||
            indentWidth != _indentWidth ||
            treeSort != _treeSort ||
            toolbar != _toolbarLayout.encode())) {
      setState(() {
        _lineNumbers = lineNumbers;
        _autofocusEditor = autofocus;
        _previewMode = previewMode;
        _splitRatio = splitRatio;
        _linkType = linkType;
        _indentWidth = indentWidth;
        _treeSort = treeSort;
        _toolbarLayout = ToolbarLayout.parse(toolbar);
      });
    }
  }

  /// Flips the tree sort direction and persists it (T-UI-03).
  Future<void> _toggleTreeSort() async {
    final next = _treeSort == TreeSort.nameAsc
        ? TreeSort.nameDesc
        : TreeSort.nameAsc;
    setState(() => _treeSort = next);
    await widget.controller.setTreeSort(next);
    widget.controller.notify();
  }

  /// Live divider moves mirror into [_splitRatio]; the lift persists.
  //ignore: use_setters_to_change_properties
  void _onSplitFractionChanged(double value) => _splitRatio = value;

  Future<void> _onSplitDragEnd() async {
    await widget.controller.setSplitRatio(_splitRatio);
    widget.controller.notify();
  }

  /// Resolves the effective preview layout for a width: forced modes win,
  /// `auto` follows the width (split ≥ 600 dp, switch on phones).
  bool _effectiveSplit({required bool narrow}) {
    if (_previewMode == PreviewLayoutMode.split) return true;
    if (_previewMode == PreviewLayoutMode.fullScreen) return false;
    return !narrow;
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
  /// detail pane shows it alongside the tree.
  void _openSearchNote(String path) {
    if (_opensPreviewOnly()) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = path;
      _selectedIsDir = false;
      _treeVisible = false;
      _noteFromTab = _tab;
      _resetNoteKind();
      _noteOpened();
    });
    logNextFrame('shell', 'search result open first frame');
  }

  /// Opens the quick note at [path]; back returns to the Files tab.
  /// A stale setting (the note was moved, renamed, or deleted) is cleared
  /// so the tab returns to its empty state.
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
        await ops.setQuickNotePath(path: null);
        widget.controller.notify();
        return;
      }
      if (!mounted) return;
      setState(() {
        _tab = ShellTab.quickNote;
        _visitedTabs.add(ShellTab.quickNote);
        _noteFromTab = ShellTab.files;
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
    await _openQuickNote(path);
  }

  /// Shows the choose/create screen, wherever this layout keeps it.
  ///
  /// The bottom-nav tab is phone-only, so a wide layout pushes it as a
  /// screen — otherwise the launcher's Quick note action would land
  /// nowhere on a tablet with no quick note set yet.
  void _openQuickNoteChooser() {
    if (MediaQuery.sizeOf(context).width < _phoneBreakpoint) {
      _selectShellTab(ShellTab.quickNote);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(AppStrings.quickNoteTitle)),
          body: QuickNoteTab(
            controller: widget.controller,
            onOpen: (path) {
              Navigator.pop(context);
              unawaited(_openQuickNote(path));
            },
          ),
        ),
      ),
    );
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

  /// Creates a note in [parent] (default: the FAB target). Used by the
  /// FAB and the context menu.
  Future<void> _createNote({String? parent}) async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newNoteTitle,
      initial: AppStrings.newNoteTitle,
    );
    if (name == null) return;
    await _guard(() async {
      final row = await widget.controller.ops!.createNote(
        parentPath: parent ?? _createParent,
        name: name,
      );
      if (!mounted) return;
      if (_opensPreviewOnly()) FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _selected = row.path;
        _selectedIsDir = false;
        _treeVisible = false;
        _pendingAnchor = null;
        _noteOpened();
      });
    });
  }

  /// Creates a folder in [parent] (default: the FAB target).
  Future<void> _createFolder({String? parent}) async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newFolderTitle,
      initial: AppStrings.newFolderTitle,
    );
    if (name == null) return;
    await _guard(() async {
      final row = await widget.controller.ops!.createFolder(
        parentPath: parent ?? _createParent,
        name: name,
      );
      setState(() {
        _selected = row.path;
        _selectedIsDir = true;
        _pendingAnchor = null;
      });
    });
  }

  Future<void> _rename([String? path]) async {
    final sel = path ?? _selected;
    if (sel == null) return;
    final name = await showNameDialog(
      context,
      title: AppStrings.actionRename,
      initial: p.basename(sel),
    );
    if (name == null) return;
    await _guard(() async {
      final row = await widget.controller.ops!.rename(sel, name);
      setState(() => _selected = row.path);
    });
  }

  Future<void> _move([String? path]) async {
    final sel = path ?? _selected;
    if (sel == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    // A folder cannot move into itself or its own subtree, so those
    // targets are not offered.
    final candidates = [
      for (final folder in folders)
        if (folder.path != sel && !isUnder(sel, folder.path)) folder,
    ];
    final target = await _showMoveDialog(
      context,
      name: p.basename(sel),
      folders: candidates,
    );
    if (target == null) return;
    await _guard(() async {
      final row = await widget.controller.ops!.move(sel, target);
      setState(() => _selected = row.path);
    });
  }

  Future<void> _delete([String? path]) async {
    final sel = path ?? _selected;
    if (sel == null) return;
    final ops = widget.controller.ops;
    if (ops == null) return;
    final trash = await ops.trashEnabled;
    if (!mounted) return;
    final name = p.basename(sel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.actionDelete),
        content: Text(
          trash
              ? AppStrings.deleteToTrashConfirm(name)
              : AppStrings.deleteForeverConfirm(name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _guard(() async {
      await ops.delete(sel);
      setState(() {
        _selected = null;
        // Deleting the open note closes it: the tabs show at once.
        _noteClosed();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trash ? AppStrings.movedToTrash : AppStrings.deletedMessage,
            ),
          ),
        );
      }
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
  /// scoped to the pressed row. New note/folder target the row's folder.
  Future<void> _showRowMenu(Note note) async {
    final here = note.isDir ? note.path : parentOf(note.path);
    final isQuickNote = await widget.controller.ops?.quickNotePath == note.path;
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('menu-new-note'),
              leading: const Icon(Icons.note_add),
              title: Text(AppStrings.newNoteHere),
              onTap: () => Navigator.pop(context, 'note'),
            ),
            if (note.isDir)
              ListTile(
                key: const Key('menu-new-folder'),
                leading: const Icon(Icons.create_new_folder),
                title: Text(AppStrings.newFolderHere),
                onTap: () => Navigator.pop(context, 'folder'),
              ),
            if (!note.isDir)
              ListTile(
                key: const Key('menu-quick-note'),
                leading: Icon(
                  isQuickNote
                      ? Icons.sticky_note_2
                      : Icons.sticky_note_2_outlined,
                ),
                title: Text(
                  isQuickNote
                      ? AppStrings.currentQuickNote
                      : AppStrings.setAsQuickNote,
                ),
                onTap: () => Navigator.pop(context, 'quicknote'),
              ),
            ListTile(
              key: const Key('menu-rename'),
              leading: const Icon(Icons.edit),
              title: Text(AppStrings.actionRename),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              key: const Key('menu-move'),
              leading: const Icon(Icons.drive_folder_upload),
              title: Text(AppStrings.actionMove),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              key: const Key('menu-delete'),
              leading: const Icon(Icons.delete_outline),
              title: Text(AppStrings.actionDelete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case 'note':
        await _createNote(parent: here);
      case 'folder':
        await _createFolder(parent: here);
      case 'quicknote':
        await _guard(() async {
          await widget.controller.ops!.setQuickNotePath(path: note.path);
          widget.controller.notify();
        });
      case 'rename':
        await _rename(note.path);
      case 'move':
        await _move(note.path);
      case 'delete':
        await _delete(note.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selectedPath = _selected;
    final narrow = MediaQuery.sizeOf(context).width < _phoneBreakpoint;

    if (narrow) {
      // Phone: the selected note opens full-screen (from any tab) over the
      // tab shell, which stays mounted underneath (T-TS-08): swapping it
      // out used to dispose all five kept-alive bodies at once, and going
      // back remounted them mid-animation. The note fades in and out with
      // the same fade as before.
      final fullNote = selectedPath != null && !_selectedIsDir && !_treeVisible;
      // The preview may show without its chrome; only a note that is
      // actually previewing (not split, not a kind GUI) can get there, so
      // the flag alone never decides it.
      final immersive =
          fullNote &&
          _previewFullScreen &&
          _previewVisible &&
          _previewToggleVisible &&
          !_effectiveSplit(narrow: true);
      return PopScope(
        canPop: !fullNote,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // Back leaves fullscreen before it leaves the note: one gesture,
          // one layer of chrome, the way every other fullscreen behaves.
          if (immersive) {
            setState(() => _previewFullScreen = false);
            return;
          }
          _closeFullScreenNote();
        },
        child: ColoredBox(
          // Opaque surface behind every phone transition (issue #4): the
          // full-note fade starts from transparent, and without this the
          // first frames expose the black Android window instead.
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The tab shell never unmounts: hidden it skips layout, paint,
              // and tickers, and the fullscreen note above is opaque. The
              // hiding waits out the open fade (issue #4): the note fades
              // in over the tabs instead of over the window background.
              Offstage(
                key: const ValueKey('tab-shell-offstage'),
                offstage: fullNote && _noteHidingTabs,
                child: TickerMode(
                  enabled: !fullNote,
                  child: KeyedSubtree(
                    key: const ValueKey('tab-shell'),
                    child: _tabShell(
                      controller: controller,
                      title: _tabTitle,
                      actions: _tab == ShellTab.files
                          ? _filesAppBarActions(controller)
                          : _tab == ShellTab.todo
                          ? [_todoHelpAction()]
                          : const [],
                      floatingActionButton: _tabFab(),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: _fullNoteFade,
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: fullNote
                    ? KeyedSubtree(
                        key: const ValueKey('full-note'),
                        child: Scaffold(
                          appBar: immersive
                              ? null
                              : AppBar(
                                  leading: BackButton(
                                    onPressed: _closeFullScreenNote,
                                  ),
                                  title: Text(p.basename(selectedPath)),
                                  actions: [
                                    ..._kindActions,
                                    if (!_effectiveSplit(narrow: true) &&
                                        _previewToggleVisible) ...[
                                      _previewToggleAction(),
                                      if (_previewVisible)
                                        _previewFullScreenAction(),
                                    ],
                                  ],
                                ),
                          body: Stack(
                            children: [
                              // Stable subtree across the immersive toggle:
                              // only the top inset flips, so entering or
                              // leaving fullscreen never reparents (and
                              // disposes) the open note's state, focus and
                              // scroll. The all-false SafeArea is a layout
                              // no-op.
                              Positioned.fill(
                                child: SafeArea(
                                  top: immersive,
                                  bottom: false,
                                  left: false,
                                  right: false,
                                  child: _fullNoteView(
                                    controller,
                                    selectedPath,
                                  ),
                                ),
                              ),
                              if (immersive) _exitFullScreenButton(),
                            ],
                          ),
                          bottomNavigationBar: immersive ? null : _shellTabs(),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          if (_selected != null && !_selectedIsDir) ..._kindActions,
          if (_selected != null &&
              !_selectedIsDir &&
              _previewToggleVisible &&
              !_effectiveSplit(narrow: false))
            _previewToggleAction(),
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
          IconButton(
            key: const Key('open-todo'),
            tooltip: AppStrings.todoTitle,
            icon: const Icon(Icons.checklist),
            onPressed: _openTodo,
          ),
          _sortToggle(),
          IconButton(
            key: const Key('open-settings'),
            tooltip: AppStrings.tabSettings,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => SettingsScreen(controller: controller),
              ),
            ),
          ),
        ],
      ),
      body: _withFabScrim(_wideBody(controller)),
      floatingActionButton: _newItemFab(),
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
      anchorKey: _fabAnchorKey,
      expanded: _fabExpanded,
      onToggle: () => setState(() => _fabExpanded = !_fabExpanded),
      onNewNote: () {
        _closeFab();
        unawaited(_createNote());
      },
      onNewListNote: () {
        _closeFab();
        unawaited(_createListNote());
      },
      onNewFolder: () {
        _closeFab();
        unawaited(_createFolder());
      },
    );
  }

  /// Creates a list note (T-TK-06): a note file with `type: list`
  /// frontmatter in the configured list folder (default `Lists`),
  /// regardless of the selected folder.
  Future<void> _createListNote() async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newListNoteTitle,
      initial: AppStrings.newListNoteDefault,
    );
    if (name == null) return;
    await _guard(() async {
      final ops = widget.controller.ops!;
      final folder = await _ensureListFolder(ops);
      final row = await ops.createNote(
        parentPath: folder,
        name: name,
        content: listNoteContent(),
      );
      if (!mounted) return;
      if (_opensPreviewOnly()) FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _selected = row.path;
        _selectedIsDir = false;
        _treeVisible = false;
        _pendingAnchor = null;
        _resetNoteKind();
        _noteOpened();
      });
    });
  }

  /// The configured list-note folder, creating it (and any missing
  /// ancestors) when absent.
  ///
  /// The folder is written back to the settings, so a library where none
  /// was ever chosen ends up with the default one (`Lists`) created on
  /// disk and shown in the settings, not just implied.
  Future<String> _ensureListFolder(NoteOperations ops) async {
    final folder = await ops.listNoteFolder;
    var prefix = '';
    for (final part in folder.split('/')) {
      if (part.isEmpty) continue;
      prefix = prefix.isEmpty ? part : '$prefix/$part';
      final existing = await ops.find(prefix);
      if (existing == null || !existing.isDir) {
        await ops.createFolder(parentPath: parentOf(prefix), name: part);
      }
    }
    await ops.setListNoteFolder(folder: folder);
    return folder;
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
          anchorKey: _fabAnchorKey,
          expanded: _fabExpanded,
          onClose: _closeFab,
        ),
      ],
    );
  }

  /// The sort-direction toggle (T-UI-03): the mockup's `unfold_more`
  /// chevrons; the icon reflects the current direction.
  Widget _sortToggle() {
    return IconButton(
      key: const Key('toggle-sort'),
      tooltip: _treeSort == TreeSort.nameAsc
          ? AppStrings.sortDescTooltip
          : AppStrings.sortAscTooltip,
      icon: AnimatedRotation(
        turns: _treeSort == TreeSort.nameAsc ? 0 : 0.5,
        duration: const Duration(milliseconds: 180),
        child: const Icon(Icons.unfold_more),
      ),
      onPressed: _toggleTreeSort,
    );
  }

  /// Trash/sort actions of the Files-tab app bar (per mockup: trash +
  /// sort chevrons; the settings gear moved to the Settings tab).
  List<Widget> _filesAppBarActions(LibrarySession controller) {
    return [
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

  String get _tabTitle => switch (_tab) {
    ShellTab.files => AppStrings.appTitle,
    ShellTab.todo => AppStrings.todoTitle,
    ShellTab.search => AppStrings.tabSearch,
    ShellTab.quickNote => AppStrings.quickNoteTitle,
    ShellTab.settings => AppStrings.tabSettings,
  };

  /// The narrow shell: app bar for the tab + the bottom navigation bar.
  Widget _tabShell({
    required LibrarySession controller,
    required String title,
    required List<Widget> actions,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      // Bodies stay mounted once visited (see TabBodyStack): the switch
      // only flips visibility and fades the incoming body in, instead of
      // rebuilding two transparency layers mid-animation. The stack itself
      // stays the direct body child on every tab: wrapping it in anything
      // conditional (like the FAB scrim was) reparents the whole subtree
      // and remounts every body, defeating the keep-alive.
      body: _tabBodies(controller),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: _shellTabs(),
    );
  }

  /// The bottom tab bar.
  ///
  /// Shown by the tab shell *and* by an open note: the tabs are how the
  /// app is navigated, so having them vanish behind a note meant going
  /// back before going anywhere.
  Widget _shellTabs() {
    return NavigationBar(
      key: const Key('shell-tabs'),
      selectedIndex: _tab.index,
      onDestinationSelected: _onDestinationSelected,
      destinations: [
        NavigationDestination(
          key: const Key('tab-files'),
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder),
          label: AppStrings.tabFiles,
        ),
        NavigationDestination(
          icon: const Icon(Icons.check_box_outlined),
          selectedIcon: const Icon(Icons.check_box),
          label: AppStrings.todoTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search),
          label: AppStrings.tabSearch,
        ),
        NavigationDestination(
          icon: const Icon(Icons.edit_outlined),
          selectedIcon: const Icon(Icons.edit),
          label: AppStrings.quickNoteTitle,
        ),
        NavigationDestination(
          key: const Key('tab-settings'),
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: AppStrings.tabSettings,
        ),
      ],
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

  /// The wide-layout body: the tree pane and the split detail pane.
  Widget _wideBody(LibrarySession controller) {
    return Row(
      children: [
        SizedBox(width: 340, child: _treePane(controller)),
        const VerticalDivider(width: 1),
        Expanded(
          child: _DetailPane(
            root: controller.root,
            selectedPath: _selected,
            selectedIsDir: _selectedIsDir,
            showLineNumbers: _lineNumbers,
            autofocusEditor: _autofocusEditor,
            linkType: _linkType,
            indentWidth: _indentWidth,
            toolbarLayout: _toolbarLayout,
            splitPreview: _effectiveSplit(narrow: false),
            showPreview: _previewVisible,
            splitFraction: _splitRatio,
            onSplitFractionChanged: _onSplitFractionChanged,
            onSplitDragEnd: _onSplitDragEnd,
            linkSource: _linkSource,
            onOpenNote: _openNoteFromLink,
            initialAnchor: _pendingAnchor,
            kindMode: !_kindRawMode,
            onNoteKindChanged: _onNoteKindChanged,
          ),
        ),
      ],
    );
  }

  /// All five tab bodies: each mounts on its first visit and stays
  /// mounted (query, results, and scroll survive a switch), while the
  /// fade only covers the incoming body — no cross-fade of two
  /// transparency layers, and no re-inflate mid-animation. Only the
  /// search slot retains layout while hidden (T-TS-10): it is the one
  /// whose show-layout costs frames; the plain lists relayout cheaply.
  Widget _tabBodies(LibrarySession controller) {
    return TabBodyStack(
      currentIndex: _tab.index,
      retainLayout: <int>{ShellTab.search.index},
      children: [
        for (final tab in ShellTab.values) _tabBodyFor(tab, controller),
      ],
    );
  }

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
      ),
      ShellTab.search => _searchSlot(controller),
      ShellTab.quickNote => QuickNoteTab(
        controller: controller,
        onOpen: _openQuickNote,
      ),
      ShellTab.settings => SettingsTab(controller: controller),
    };
  }

  /// The search tab: Search and Tags side by side, Tags mounting once.
  /// The flip stays instant (as before — same tab, no transition); the
  /// outer fade already covered entering the tab. Search retains layout
  /// while Tags shows (T-TS-10): flipping back is then paint-only,
  /// matching the tab-level switch into Search.
  Widget _searchSlot(LibrarySession controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Visibility(
          visible: !_showTags,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: TickerMode(
            enabled: !_showTags,
            child: SearchScreen(
              controller: controller,
              onOpenNote: _openSearchNote,
              onOpenTags: () => setState(() {
                _showTags = true;
                _tagsVisited = true;
              }),
            ),
          ),
        ),
        if (_tagsVisited)
          Offstage(
            offstage: !_showTags,
            child: TickerMode(
              enabled: _showTags,
              child: TagsScreen(
                controller: controller,
                onOpenNote: _openSearchNote,
                onBack: () => setState(() => _showTags = false),
              ),
            ),
          ),
      ],
    );
  }

  /// The tree pane: the action bar and the note tree — the whole body on
  /// phones, the left column on wide screens.
  Widget _treePane(LibrarySession controller) {
    return NoteTree(
      controller: controller,
      nameDesc: _treeSort == TreeSort.nameDesc,
      selectedPath: _selected,
      expanded: _expanded,
      onToggle: _toggle,
      onSelect: _select,
      onLongPress: _showRowMenu,
    );
  }
}

/// Right-hand pane: the note editor, or a prompt until a note is chosen.
final class _DetailPane extends StatelessWidget {
  const new({
    required this.root,
    required this.selectedPath,
    required this.selectedIsDir,
    required this.showLineNumbers,
    required this.autofocusEditor,
    required this.linkType,
    required this.indentWidth,
    required this.toolbarLayout,
    required this.splitPreview,
    required this.showPreview,
    required this.splitFraction,
    required this.onSplitFractionChanged,
    required this.onSplitDragEnd,
    required this.linkSource,
    required this.onOpenNote,
    required this.initialAnchor,
    required this.kindMode,
    required this.onNoteKindChanged,
  });

  /// Absolute library root; null until the session is ready.
  final String? root;

  /// Library-relative path of the selection.
  final String? selectedPath;

  final bool selectedIsDir;

  /// Editor setting forwards.
  final bool showLineNumbers;
  final bool autofocusEditor;
  final LinkType linkType;
  final int indentWidth;
  final ToolbarLayout toolbarLayout;

  /// Preview layout (T-M2-08).
  final bool splitPreview;
  final double splitFraction;
  final ValueChanged<double> onSplitFractionChanged;
  final VoidCallback onSplitDragEnd;

  /// Editor/preview switch state (T-UI-06): the shared app bar owns it.
  final bool showPreview;

  /// Link navigation (T-M3-07).
  final LinkSource? linkSource;
  final void Function(String path, String? anchor) onOpenNote;
  final String? initialAnchor;

  /// Note kind mode (T-TK-02).
  final bool kindMode;
  final void Function(String? type) onNoteKindChanged;

  @override
  Widget build(BuildContext context) {
    final path = selectedPath;
    final root = this.root;
    final notePath = path == null || selectedIsDir || root == null
        ? null
        : path;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      // The outgoing pane leaves immediately: an editor and its twin must
      // never coexist (same controller).
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      child: notePath == null
          ? KeyedSubtree(
              key: const ValueKey('detail-empty'),
              child: Center(child: Text(AppStrings.selectANote)),
            )
          : KeyedSubtree(
              key: ValueKey('detail-note-$notePath'),
              child: NoteView(
                path: p.join(root!, notePath),
                showLineNumbers: showLineNumbers,
                autofocusEditor: autofocusEditor,
                linkType: linkType,
                indentWidth: indentWidth,
                toolbarLayout: toolbarLayout,
                splitPreview: splitPreview,
                showPreview: showPreview,
                splitFraction: splitFraction,
                onSplitFractionChanged: onSplitFractionChanged,
                onSplitDragEnd: onSplitDragEnd,
                libraryRoot: root,
                linkSource: linkSource,
                onOpenNote: onOpenNote,
                initialAnchor: initialAnchor,
                kindMode: kindMode,
                onNoteKindChanged: onNoteKindChanged,
              ),
            ),
    );
  }
}

/// A move-target picker over all indexed folders; resolves to the target
/// parent path ('' = root) or null.
Future<String?> _showMoveDialog(
  BuildContext context, {
  required String name,
  required List<Note> folders,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _MovePicker(name: name, folders: folders),
  );
}

final class _MovePicker extends StatefulWidget {
  const new({required this.name, required this.folders});

  final String name;
  final List<Note> folders;

  @override
  State<_MovePicker> createState() => _MovePickerState();
}

final class _MovePickerState extends State<_MovePicker> {
  String? _target;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.moveTitle(widget.name)),
      content: SizedBox(
        width: 320,
        child: DropdownButton<String>(
          value: _target,
          hint: Text(AppStrings.chooseDestination),
          onChanged: (value) => setState(() => _target = value),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(AppStrings.libraryRoot),
            ),
            for (final folder in widget.folders)
              DropdownMenuItem<String>(
                value: folder.path,
                child: Text(folder.path),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: _target == null
              ? null
              : () => Navigator.pop(context, _target),
          child: Text(AppStrings.actionMove),
        ),
      ],
    );
  }
}
