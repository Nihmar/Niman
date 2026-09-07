import 'dart:async';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/storage_access.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/name_dialog.dart';
import 'package:copist/src/ui/new_item_fab.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/open_library.dart';
import 'package:copist/src/ui/quick_note_tab.dart';
import 'package:copist/src/ui/search_tab.dart';
import 'package:copist/src/ui/settings.dart';
import 'package:copist/src/ui/settings_tab.dart';
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
  const LibraryHome({super.key});

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
        LibraryPhase.ready => _LibraryShell(controller: controller),
        _ => OpenLibraryScreen(controller: controller),
      },
    );
  }
}

/// The library shell: sidebar tree + action bar on the left, detail pane
/// on the right.
final class _LibraryShell extends StatefulWidget {
  const _LibraryShell({required this.controller});

  final LibrarySession controller;

  @override
  State<_LibraryShell> createState() => _LibraryShellState();
}

/// The bottom-navigation tabs (phone/narrow layout only).
enum ShellTab {
  /// The note tree plus the note-open stack (T-UI-02).
  files,

  /// Reserved tab for the todo section (T-UI-10).
  todo,

  /// Disabled until the M3 SearchScreen lands (R3).
  search,

  /// The scratch quick note at the library root (T-UI-10).
  quickNote,

  /// The library settings (the pushed SettingsScreen on wide screens).
  settings,
}

final class _LibraryShellState extends State<_LibraryShell> {
  String? _selected;
  bool _selectedIsDir = false;
  final Set<String> _expanded = <String>{};
  bool _busy = false;

  /// The currently selected bottom tab (narrow layout).
  ShellTab _tab = ShellTab.files;

  /// The tab active when the full-screen note opened (back returns there).
  ShellTab _noteFromTab = ShellTab.files;

  /// Selects [tab]; a full-screen note closes to its tree (the selected
  /// note stays highlighted).
  void _selectShellTab(ShellTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _treeVisible = true;
      _fabExpanded = false;
    });
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

  /// The library tree sort order (T-UI-03).
  TreeSort _treeSort = TreeSort.nameAsc;

  /// Phone (< [_phoneBreakpoint]) mode: which pane is visible.
  /// `false` = the selected note is open full-screen.
  bool _treeVisible = true;

  /// Whether the FAB menu (New note / New folder minis) is expanded;
  /// the shell owns it so the body can be scrimmed while it is open.
  bool _fabExpanded = false;

  /// Marks the main FAB so [FabScrim]'s reveal circle is centered on its
  /// icon (the shell owns it: the FAB slot and the scrim are siblings).
  final GlobalKey _fabAnchorKey = GlobalKey();

  /// Below this width the shell is single-pane (spec: phones are
  /// full-screen tree or editor, the split lands at 600 px and up).
  static const double _phoneBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshEditorSettings());
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
    final treeSort = await controller.treeSort;
    if (mounted &&
        (lineNumbers != _lineNumbers ||
            autofocus != _autofocusEditor ||
            previewMode != _previewMode ||
            splitRatio != _splitRatio ||
            treeSort != _treeSort)) {
      setState(() {
        _lineNumbers = lineNumbers;
        _autofocusEditor = autofocus;
        _previewMode = previewMode;
        _splitRatio = splitRatio;
        _treeSort = treeSort;
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
    setState(() {
      _selected = note.path;
      _selectedIsDir = note.isDir;
      _treeVisible = note.isDir;
      _noteFromTab = _tab;
      if (note.isDir) _expanded.add(note.path);
    });
  }

  /// Opens the quick note at [path]; back returns to the Files tab.
  /// A stale setting (the note was moved, renamed, or deleted) is cleared
  /// so the tab returns to its empty state.
  Future<void> _openQuickNote(String path) async {
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
        _noteFromTab = ShellTab.files;
        _selected = note.path;
        _selectedIsDir = false;
        _treeVisible = false;
      });
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
      _selectShellTab(ShellTab.quickNote);
      return;
    }
    await _openQuickNote(path);
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
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Creates a note in [parent] (default: the FAB target). Used by the
  /// FAB and the context menu.
  Future<void> _createNote({String? parent}) async {
    final name =
        await _nameDialog(context, title: 'New note', initial: 'New note');
    if (name == null) return;
    await _guard(() async {
      final row = await widget.controller.ops!.createNote(
        parentPath: parent ?? _createParent,
        name: name,
      );
      setState(() {
        _selected = row.path;
        _selectedIsDir = false;
        _treeVisible = false;
      });
    });
  }

  /// Creates a folder in [parent] (default: the FAB target).
  Future<void> _createFolder({String? parent}) async {
    final name = await _nameDialog(
      context,
      title: 'New folder',
      initial: 'New folder',
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
      });
    });
  }

  Future<void> _rename([String? path]) async {
    final sel = path ?? _selected;
    if (sel == null) return;
    final name = await _nameDialog(
      context,
      title: 'Rename',
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
        title: const Text('Delete'),
        content: Text(
          trash
              ? '$name will be moved to .trash/'
              : '$name will be permanently deleted',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _guard(() async {
      await ops.delete(sel);
      setState(() => _selected = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trash ? 'Moved to trash' : 'Deleted')),
        );
      }
    });
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
              title: const Text('New note here'),
              onTap: () => Navigator.pop(context, 'note'),
            ),
            if (note.isDir)
              ListTile(
                key: const Key('menu-new-folder'),
                leading: const Icon(Icons.create_new_folder),
                title: const Text('New folder here'),
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
                      ? 'Current quick note'
                      : 'Set as quick note',
                ),
                onTap: () => Navigator.pop(context, 'quicknote'),
              ),
            ListTile(
              key: const Key('menu-rename'),
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              key: const Key('menu-move'),
              leading: const Icon(Icons.drive_folder_upload),
              title: const Text('Move'),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              key: const Key('menu-delete'),
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
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
      // Phone: the selected note opens full-screen (from any tab).
      if (selectedPath != null && !_selectedIsDir && !_treeVisible) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => _closeFullScreenNote(),
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _closeFullScreenNote),
              title: Text(p.basename(selectedPath)),
            ),
            body: NoteView(
              path: p.join(controller.root ?? '', selectedPath),
              showLineNumbers: _lineNumbers,
              autofocusEditor: _autofocusEditor,
              splitPreview: _effectiveSplit(narrow: true),
              splitFraction: _splitRatio,
              onSplitFractionChanged: _onSplitFractionChanged,
              onSplitDragEnd: _onSplitDragEnd,
              libraryRoot: controller.root,
            ),
          ),
        );
      }
      return _tabShell(
        title: _tabTitle,
        actions: _tab == ShellTab.files
            ? _filesAppBarActions(controller)
            : const [],
        floatingActionButton: _tab == ShellTab.files
            ? _newItemFab()
            : null,
        body: _tabBody(controller),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copist'),
        actions: [
          IconButton(
            key: const Key('open-trash'),
            tooltip: 'Trash',
            icon: const Icon(Icons.delete),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => TrashScreen(controller: controller),
              ),
            ),
          ),
          _sortToggle(),
          IconButton(
            key: const Key('open-settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    SettingsScreen(controller: controller),
              ),
            ),
          ),
        ],
      ),
      body: _withFabScrim(_wideBody(controller)),
      floatingActionButton: _newItemFab(),
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
      onNewFolder: () {
        _closeFab();
        unawaited(_createFolder());
      },
    );
  }

  /// Collapses the expanded FAB menu.
  void _closeFab() => setState(() => _fabExpanded = false);

  /// Covers [child] with the FAB-menu scrim: a circle that grows out of
  /// the main FAB icon, dims the body, and closes the menu on any tap
  /// (the FABs live in the Scaffold's FAB slot, above this layer, so they
  /// stay tappable). Always mounted; inert while collapsed.
  Widget _withFabScrim(Widget child) {
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
      tooltip: _treeSort == TreeSort.nameAsc ? 'Sort Z-A' : 'Sort A-Z',
      icon: const Icon(Icons.unfold_more),
      onPressed: _toggleTreeSort,
    );
  }

  /// Trash/sort actions of the Files-tab app bar (per mockup: trash +
  /// sort chevrons; the settings gear moved to the Settings tab).
  List<Widget> _filesAppBarActions(LibrarySession controller) {
    return [
      IconButton(
        key: const Key('open-trash'),
        tooltip: 'Trash',
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
      _treeVisible = true;
    });
  }

  String get _tabTitle => switch (_tab) {
        ShellTab.files => 'Copist',
        ShellTab.todo => 'Todo',
        ShellTab.search => 'Search',
        ShellTab.quickNote => 'Quick note',
        ShellTab.settings => 'Settings',
      };

  /// The narrow shell: app bar for the tab + the bottom navigation bar.
  Widget _tabShell({
    required String title,
    required List<Widget> actions,
    required Widget body,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: _withFabScrim(body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        key: const Key('shell-tabs'),
        selectedIndex: _tab.index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            key: Key('tab-files'),
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'Todo',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Quick note',
          ),
          NavigationDestination(
            key: Key('tab-settings'),
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    final tab = ShellTab.values[index];
    if (tab == ShellTab.search) {
      // R3: the Search tab stays disabled until M3 lands SearchScreen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search lands in M3')),
      );
      return;
    }
    if (tab == ShellTab.quickNote) {
      unawaited(_openQuickNoteFromTile());
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
            splitPreview: _effectiveSplit(narrow: false),
            splitFraction: _splitRatio,
            onSplitFractionChanged: _onSplitFractionChanged,
            onSplitDragEnd: _onSplitDragEnd,
          ),
        ),
      ],
    );
  }

  /// The body of the selected tab.
  Widget _tabBody(LibrarySession controller) {
    return switch (_tab) {
      ShellTab.files => _treePane(controller),
      ShellTab.todo => const TodoTab(),
      ShellTab.search => const SearchTab(),
      ShellTab.quickNote =>
        QuickNoteTab(controller: controller, onOpen: _openQuickNote),
      ShellTab.settings => SettingsTab(controller: controller),
    };
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
  const _DetailPane({
    required this.root,
    required this.selectedPath,
    required this.selectedIsDir,
    required this.showLineNumbers,
    required this.autofocusEditor,
    required this.splitPreview,
    required this.splitFraction,
    required this.onSplitFractionChanged,
    required this.onSplitDragEnd,
  });

  /// Absolute library root; null until the session is ready.
  final String? root;

  /// Library-relative path of the selection.
  final String? selectedPath;

  final bool selectedIsDir;

  /// Editor setting forwards.
  final bool showLineNumbers;
  final bool autofocusEditor;

  /// Preview layout (T-M2-08).
  final bool splitPreview;
  final double splitFraction;
  final ValueChanged<double> onSplitFractionChanged;
  final VoidCallback onSplitDragEnd;

  @override
  Widget build(BuildContext context) {
    final path = selectedPath;
    final root = this.root;
    if (path == null || selectedIsDir || root == null) {
      return const Center(child: Text('Select a note'));
    }
    return NoteView(
      path: p.join(root, path),
      showLineNumbers: showLineNumbers,
      autofocusEditor: autofocusEditor,
      splitPreview: splitPreview,
      splitFraction: splitFraction,
      onSplitFractionChanged: onSplitFractionChanged,
      onSplitDragEnd: onSplitDragEnd,
      libraryRoot: root,
    );
  }
}

/// A name-entry dialog; resolves to the trimmed text or null.
Future<String?> _nameDialog(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  return showNameDialog(context, title: title, initial: initial);
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
  const _MovePicker({required this.name, required this.folders});

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
      title: Text('Move ${widget.name}'),
      content: SizedBox(
        width: 320,
        child: DropdownButton<String>(
          value: _target,
          hint: const Text('Choose destination'),
          onChanged: (value) => setState(() => _target = value),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Library root'),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _target == null
              ? null
              : () => Navigator.pop(context, _target),
          child: const Text('Move'),
        ),
      ],
    );
  }
}
