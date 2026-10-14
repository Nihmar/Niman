/// The Todo tab: Open/Done lists over `todo.txt` / `done.txt`
/// (T-TD-04).
///
/// The shell owns the [TodoController] (its add action shares it); the
/// tab opens the controller on mount, renders the Open/Done switch over
/// the same list shape, and routes row gestures: checkbox toggles
/// check/uncheck, tap edits (the dialog can also delete), long-press or
/// right-click opens the bottom sheet (the app's menu pattern) with
/// edit/delete, and a swipe towards the start deletes after asking.
///
/// Where a pointer aims (#712) the rows are [TodoPointerRow]s: a click
/// selects, a double click or `Enter`/`F2` edits the text in place, the
/// arrows move, `Space` checks, `Delete` deletes, and the row's menu —
/// Edit…, Set due ▸, Priority ▸, Delete — opens at a right click or under
/// its ⋯. A quick-add field tops the list, and the filter opens under its
/// pill.
library;

import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/todo/line_edits.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/reminder_health_banner.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_filter_bar.dart';
import 'package:niman/src/ui/todo_filter_sheet.dart';
import 'package:niman/src/ui/todo_help.dart';
import 'package:niman/src/ui/todo_pointer_row.dart';
import 'package:niman/src/ui/todo_quick_add.dart';
import 'package:niman/src/ui/todo_row.dart';
import 'package:niman/src/ui/todo_row_menu.dart';

/// The Todo tab body.
final class TodoTab extends StatefulWidget {
  /// Creates the tab over [controller].
  ///
  /// [clock] fixes the wall-clock day for due badges and the edit
  /// dialog (defaults to now; widget tests inject a fixed time).
  ///
  /// [onAddTask] is the shell's add flow: the desktop panel's Add button
  /// uses it (the phone's FAB owns creation there).
  const new({
    required this.controller,
    this.reminders,
    this.clock,
    this.onAddTask,
    this.column = NoteColumn.off,
    super.key,
  });

  /// The note column (#171), which the list keeps to as a note's text
  /// does (0.0.8 test round).
  final NoteColumn column;

  /// The session-bound todo state (owned by the shell).
  final TodoController controller;

  /// The reminder service, for the health banner (null hides it).
  final ReminderService? reminders;

  /// The wall-clock source for "today".
  final DateTime Function()? clock;

  /// Creates a task; the desktop filter panel shows the button.
  final VoidCallback? onAddTask;

  @override
  State<TodoTab> createState() => _TodoTabState();
}

final class _TodoTabState extends State<TodoTab> {
  static const AppLogger _log = AppLogger(name: 'todo');

  /// Whether the Done list shows (false = the Open list).
  bool _showDone = false;

  /// The list filter (due range + token chips + sort key).
  TodoFilter _filter = const TodoFilter();

  /// Rows swiped away whose delete has not published yet. A dismissed
  /// [Dismissible] must leave the tree at once, while the controller's
  /// snapshot arrives after the file write; the next publish (the delete,
  /// or its failure) clears this, and a failed delete brings the row back.
  final Set<TodoEntry> _swiped = {};

  /// The line the keyboard's selection is on (#712); a delete leaves it
  /// on the line that takes the index.
  int? _selectedLine;

  /// The line whose text is a field, or null.
  int? _editingLine;

  /// The last click on a row, to tell a double one.
  (int, DateTime)? _lastClick;

  /// The rows' menu, one for the list (#712), and what it is open for.
  final MenuController _menu = MenuController();
  TodoEntry? _menuEntry;
  bool _menuDueOnly = false;

  /// The box the menu opens over, to place it at a point on screen.
  final GlobalKey _listKey = GlobalKey();

  /// The list's keys: the arrows, `Space`, `Enter`/`F2`, `Delete`.
  late final FocusNode _listFocus = FocusNode(debugLabel: 'todo-list');

  /// The rows on screen, in order, for the arrows.
  List<TodoEntry> _visible = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPublished);
    unawaited(widget.controller.open());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPublished);
    _listFocus.dispose();
    super.dispose();
  }

  void _onPublished() => _swiped.clear();

  DateTime get _today {
    final now = widget.clock?.call() ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The pane the tab lives in decides the shape, and the shell
        // too: a phone keeps its own switch row and the FAB adds, while a
        // wide shell's pane (#712) folds the switch into the filter panel
        // as long as the pane holds the panel's pills — under that it
        // takes the phone's row, with Add in it, because the wide shell
        // has no FAB at all.
        final shellWide = isWideShell(context);
        final wide = shellWide && constraints.maxWidth >= _minFoldWidth;
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final snapshot = controller.snapshot;
            final reminders = widget.reminders;
            return Column(
              children: [
                if (reminders != null) ReminderHealthBanner(service: reminders),
                // The phone keeps the switch on its own row; the desktop folds
                // it — and the help — into the filter panel below (T-PP-22).
                if (!wide)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    // A Wrap, not a Row: a wide shell's pane can be
                    // narrower than the switch, Add and help together,
                    // and they drop to a second line rather than clip.
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _viewSwitch(),
                        if (shellWide && widget.onAddTask != null) _addButton(),
                        _helpButton(),
                      ],
                    ),
                  ),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      key: const Key('todo-error'),
                      controller.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: NoteColumnPadding(
                    column: _column,
                    child: _body(snapshot, wide: wide),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// The note column, never narrower than the filter bar needs: the
  /// Open/Done switch, both pills, the count, Add and help on one line.
  NoteColumn get _column {
    final column = widget.column;
    if (!column.enabled || column.width >= _minColumnWidth) return column;
    return const NoteColumn(width: _minColumnWidth);
  }

  static const double _minColumnWidth = 800;

  /// The narrowest pane that holds the folded filter panel's own row: the
  /// switch and the two pills. Under it the tab takes the phone's rows.
  static const double _minFoldWidth = 420;

  /// The Open/Done switch: its own row on the phone, the leading control
  /// of the desktop filter panel.
  Widget _viewSwitch() {
    return SegmentedButton<bool>(
      key: const Key('todo-view-switch'),
      segments: [
        ButtonSegment(value: false, label: Text(AppStrings.todoOpen)),
        ButtonSegment(value: true, label: Text(AppStrings.todoDone)),
      ],
      selected: {_showDone},
      onSelectionChanged: (selected) => _selectView(selected.single),
    );
  }

  /// Adds a task: the filter panel's Add on the desktop, and the row's
  /// where a wide shell's pane is too narrow to fold it and has no FAB.
  Widget _addButton() {
    return TextButton.icon(
      key: const Key('todo-add-button'),
      onPressed: widget.onAddTask,
      icon: const Icon(Icons.add, size: 18),
      label: Text(AppStrings.todoAddTooltip),
    );
  }

  /// The format reference stays one tap from the list on every layout
  /// (T-TD-08): the wide layout has no app bar to hold it any more.
  Widget _helpButton() {
    return IconButton(
      key: const Key('todo-help'),
      tooltip: AppStrings.todoHelpTooltip,
      icon: const Icon(Icons.help_outline),
      onPressed: _openHelp,
    );
  }

  /// Opens the todo.txt format reference (T-TD-08).
  ///
  /// The dialog writes the syntax, so a user can go a long way without
  /// seeing it — until they open todo.txt in another editor, or wonder
  /// what the chips are. On the desktop it opens as a dialog over the
  /// tab: a pushed screen would hide the rail and the list (T-PP-22).
  Future<void> _openHelp() async {
    if (!isWideShell(context)) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (context) => const TodoHelpScreen()),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        key: const Key('todo-help-dialog'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.todoHelpTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      key: const Key('todo-help-close'),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Flexible(child: TodoHelpBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// Switches the visible file, pruning token chips absent from it so
  /// a stale chip never dead-ends the list.
  void _selectView(bool done) {
    final snapshot = widget.controller.snapshot;
    var filter = _filter;
    if (snapshot != null) {
      final entries = done ? snapshot.done : snapshot.todo;
      final available = <String>{
        for (final chip in tokenCountsFor(entries, TodoDueRange.all, _today))
          chip.token,
      };
      filter = filter.pruneTokens(available);
    }
    _log.debug('todo view: ${done ? 'done' : 'open'}');
    setState(() {
      _showDone = done;
      _filter = filter;
    });
  }

  /// The list (or loading/empty state) for the visible file on [wide],
  /// where the filter panel leads with the view switch and trails with
  /// Add task and help (T-PP-22).
  Widget _body(TodoSnapshot? snapshot, {required bool wide}) {
    if (snapshot == null) {
      return const Center(
        key: Key('todo-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final fileEntries = [
      for (final entry in (_showDone ? snapshot.done : snapshot.todo))
        if (entry.task.raw.trim().isNotEmpty) entry,
    ];
    final visible = [
      for (final entry in applyTodoFilter(fileEntries, _filter, _today))
        if (!_swiped.contains(entry)) entry,
    ];
    final pointer = pointerDense(Theme.of(context));
    _visible = visible;
    return Column(
      children: [
        TodoFilterBar(
          filter: _filter,
          showDone: _showDone,
          count: fileEntries.length,
          leading: wide ? _viewSwitch() : null,
          trailing: wide
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onAddTask != null) _addButton(),
                    _helpButton(),
                  ],
                )
              : null,
          onDueRange: (range) {
            _log.debug('todo filter due: ${range.name}');
            setState(() => _filter = _filter.copyWith(dueRange: range));
          },
          onOpenFilter: (anchor) => _openFilterSheet(fileEntries, anchor),
        ),
        if (pointer)
          TodoQuickAdd(
            key: const Key('todo-quick-add-row'),
            onAdd: _quickAdd,
            knownTokens: _knownTokens,
          ),
        Expanded(
          child: visible.isEmpty
              ? _emptyList(fileEntries.isEmpty)
              : pointer
              ? _pointerList(visible)
              : ListView.builder(
                  key: const Key('todo-list'),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    final view = _showDone ? 'done' : 'open';
                    return _swipeToDelete(
                      entry,
                      TodoRow(
                        key: Key('todo-row-$view-${entry.lineIndex}'),
                        entry: entry,
                        today: _today,
                        onToggle: (checked) => _toggle(entry, checked),
                        onEdit: () => _edit(entry),
                        onShowMenu: () => _showRowMenu(entry),
                        onShowMenuAt: (at) => _showRowMenuAt(entry, at),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// [row] made swipeable towards the start, which deletes [entry] once
  /// the user confirms: a stray swipe on a phone must not lose a task,
  /// since a deleted line has no trash.
  Widget _swipeToDelete(TodoEntry entry, Widget row) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      // Per entry object, never per line index: once a line goes, the
      // next one takes its index, and must not inherit a dismissed state.
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: scheme.errorContainer,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 24),
            child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          ),
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(entry),
      onDismissed: (_) {
        setState(() => _swiped.add(entry));
        unawaited(_delete(entry));
      },
      child: row,
    );
  }

  /// Asks before a swipe deletes [entry]; true deletes.
  Future<bool> _confirmDelete(TodoEntry entry) async {
    _log.debug('todo swipe: line ${entry.lineIndex}, asking');
    final display = taskDisplayText(entry.task.description);
    final name = '“${display.isEmpty ? entry.task.raw : display}”';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.todoDeleteAction),
        content: Text(AppStrings.deleteForeverConfirm(name)),
        actions: [
          TextButton(
            key: const Key('todo-swipe-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('todo-swipe-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Opens the token + sort sheet (T-TDM-03) over the visible file; where
  /// a pointer aims, a pop-up under the pill at [anchor] (#712).
  void _openFilterSheet(List<TodoEntry> fileEntries, Rect? anchor) {
    final counts = tokenCountsFor(fileEntries, _filter.dueRange, _today);
    if (pointerDense(Theme.of(context))) {
      unawaited(
        showActionSheet<void>(
          context,
          anchor: anchor,
          items: (context) => [_filterSheet(counts)],
        ),
      );
      return;
    }
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => _filterSheet(counts),
      ),
    );
  }

  /// The tokens and the sort, as the sheet or the pop-up shows them.
  Widget _filterSheet(List<({String token, int count})> counts) =>
      TodoFilterSheet(
        filter: _filter,
        counts: counts,
        onToggleToken: (token) {
          final tokens = {..._filter.tokens};
          if (!tokens.remove(token)) {
            tokens.add(token);
          }
          _log.debug('todo filter tokens: $tokens');
          setState(() => _filter = _filter.copyWith(tokens: tokens));
        },
        onSort: (sort) {
          setState(() => _filter = _filter.copyWith(sort: sort));
        },
      );

  /// Adds the task typed in the quick-add field (#712), created today.
  void _quickAdd(String text) {
    _log.debug('todo quick add');
    unawaited(
      widget.controller.add(
        formatTodoLine(
          completed: false,
          creationDate: _today,
          description: text,
        ),
      ),
    );
  }

  /// The desktop's list (#712): [TodoPointerRow]s under one menu, with the
  /// keyboard on the list.
  Widget _pointerList(List<TodoEntry> visible) {
    final view = _showDone ? 'done' : 'open';
    return MenuAnchor(
      controller: _menu,
      menuChildren: _menuEntry == null
          ? const []
          : todoRowMenuItems(
              dueOnly: _menuDueOnly,
              onPick: (pick) => unawaited(_runPick(_menuEntry!, pick)),
            ),
      child: Focus(
        key: _listKey,
        focusNode: _listFocus,
        onKeyEvent: _onListKey,
        child: ListView.builder(
          key: const Key('todo-list'),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final entry = visible[index];
            final line = entry.lineIndex;
            return TodoPointerRow(
              key: Key('todo-row-$view-$line'),
              entry: entry,
              today: _today,
              selected: line == _selectedLine,
              editing: line == _editingLine,
              onToggle: (checked) => _toggle(entry, checked),
              onClick: () => _click(entry),
              onSubmitText: (text) => unawaited(_writeText(entry, text)),
              onCancelEdit: () => setState(() => _editingLine = null),
              onMenuAt: (at) => _openMenu(entry, at),
              onDueMenuAt: (at) => _openMenu(entry, at, dueOnly: true),
              onDelete: () => unawaited(_delete(entry)),
            );
          },
        ),
      ),
    );
  }

  /// A click selects the row; a second one on it in time edits its text.
  void _click(TodoEntry entry) {
    final now = DateTime.now();
    final last = _lastClick;
    final line = entry.lineIndex;
    final twice =
        last != null &&
        last.$1 == line &&
        now.difference(last.$2) <= kDoubleTapTimeout;
    _lastClick = twice ? null : (line, now);
    _listFocus.requestFocus();
    setState(() {
      _selectedLine = line;
      if (twice) _editingLine = line;
    });
  }

  /// The list's keys (#712).
  KeyEventResult _onListKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _editingLine != null) {
      return KeyEventResult.ignored;
    }
    final rows = _visible;
    if (rows.isEmpty) return KeyEventResult.ignored;
    final at = rows.indexWhere((e) => e.lineIndex == _selectedLine);
    final selected = at < 0 ? null : rows[at];
    void select(int index) =>
        setState(() => _selectedLine = rows[index].lineIndex);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        select(at < 0 ? 0 : (at + 1).clamp(0, rows.length - 1));
      case LogicalKeyboardKey.arrowUp:
        select(at < 0 ? rows.length - 1 : (at - 1).clamp(0, rows.length - 1));
      case LogicalKeyboardKey.space
          when selected != null && event is KeyDownEvent:
        unawaited(_toggle(selected, !selected.task.completed));
      case LogicalKeyboardKey.enter ||
              LogicalKeyboardKey.numpadEnter ||
              LogicalKeyboardKey.f2
          when selected != null && event is KeyDownEvent:
        setState(() => _editingLine = selected.lineIndex);
      case LogicalKeyboardKey.delete
          when selected != null && event is KeyDownEvent:
        unawaited(_delete(selected));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Writes the text edited in place into [entry]'s line.
  Future<void> _writeText(TodoEntry entry, String text) async {
    setState(() => _editingLine = null);
    _listFocus.requestFocus();
    if (text == entry.task.description) return;
    await _rewrite(entry, todoLineWithText(entry.task, text));
  }

  /// Opens the row menu for [entry] at [global], a point on screen.
  void _openMenu(TodoEntry entry, Offset global, {bool dueOnly = false}) {
    final box = _listKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    setState(() {
      _menuEntry = entry;
      _menuDueOnly = dueOnly;
      _selectedLine = entry.lineIndex;
    });
    _menu.open(position: box.globalToLocal(global));
  }

  /// Runs what the row menu picked for [entry].
  Future<void> _runPick(TodoEntry entry, TodoMenuPick pick) async {
    final task = entry.task;
    final today = _today;
    switch (pick) {
      case TodoMenuPick.edit:
        await _edit(entry);
      case TodoMenuPick.delete:
        await _delete(entry);
      case TodoMenuPick.dueToday:
        await _rewrite(entry, todoLineWithDue(task, today));
      case TodoMenuPick.dueTomorrow:
        await _rewrite(
          entry,
          todoLineWithDue(task, today.add(const Duration(days: 1))),
        );
      case TodoMenuPick.dueNextWeek:
        await _rewrite(
          entry,
          todoLineWithDue(task, today.add(const Duration(days: 7))),
        );
      case TodoMenuPick.dueNone:
        await _rewrite(entry, todoLineWithDue(task, null));
      case TodoMenuPick.duePick:
        final day = await showDayPicker(
          context,
          initialDate: task.due ?? today,
          firstDate: DateTime(today.year - 5),
          lastDate: DateTime(today.year + 10),
        );
        if (day != null) await _rewrite(entry, todoLineWithDue(task, day));
      case TodoMenuPick.priorityA:
        await _rewrite(entry, todoLineWithPriority(task, 'A'));
      case TodoMenuPick.priorityB:
        await _rewrite(entry, todoLineWithPriority(task, 'B'));
      case TodoMenuPick.priorityC:
        await _rewrite(entry, todoLineWithPriority(task, 'C'));
      case TodoMenuPick.priorityNone:
        await _rewrite(entry, todoLineWithPriority(task, null));
    }
  }

  /// Writes [line] in place of [entry]'s, in the file it is in.
  Future<void> _rewrite(TodoEntry entry, String line) {
    _log.debug('todo row rewritten: line ${entry.lineIndex}');
    return _showDone
        ? widget.controller.updateDone(entry, line)
        : widget.controller.updateTodo(entry, line);
  }

  /// The empty state: the file's own when it holds nothing, the filtered
  /// one when chips hide every row.
  Widget _emptyList(bool fileEmpty) {
    final text = fileEmpty
        ? (_showDone ? AppStrings.todoEmptyDone : AppStrings.todoEmptyOpen)
        : AppStrings.todoEmptyFiltered;
    return Center(child: Text(text));
  }

  /// Flips a task: check from Open, uncheck from Done. A checkbox that
  /// disagrees with its view (a stray `x` line awaiting migration)
  /// still does the useful thing.
  Future<void> _toggle(TodoEntry entry, bool checked) {
    _log.debug('todo toggle: line ${entry.lineIndex} -> $checked');
    return checked
        ? widget.controller.check(entry)
        : widget.controller.uncheck(entry);
  }

  /// Opens the edit dialog and applies the result to the visible file.
  Future<void> _edit(TodoEntry entry) async {
    final reminders = widget.reminders;
    final line = await showTodoTaskDialog(
      context,
      initial: entry.task,
      today: _today,
      knownTokens: _knownTokens(),
      onDelete: () => unawaited(_delete(entry)),
      health: reminders?.health.value ?? ReminderHealth.ok,
      onOpenReminderSettings: reminders?.openHealthSettings,
    );
    if (line == null || !mounted) {
      return;
    }
    _log.debug('todo edit applied: line ${entry.lineIndex}');
    if (_showDone) {
      await widget.controller.updateDone(entry, line);
    } else {
      await widget.controller.updateTodo(entry, line);
    }
  }

  /// The completion pool for the edit dialog: every token in both
  /// files.
  Set<String> _knownTokens() {
    final snapshot = widget.controller.snapshot;
    return snapshot == null ? const <String>{} : snapshotTokens(snapshot);
  }

  /// Long-press bottom sheet (the app's menu pattern): edit or delete.
  Future<void> _showRowMenu(TodoEntry entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('todo-menu-edit'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppStrings.todoEditAction),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              key: const Key('todo-menu-delete'),
              leading: const Icon(Icons.delete_outline),
              title: Text(AppStrings.todoDeleteAction),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    await _runRowMenu(entry, action);
  }

  /// Right-click menu (T-PP-20): the same two actions at the cursor, the
  /// shape a pointer gets (#712).
  Future<void> _showRowMenuAt(TodoEntry entry, Offset at) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        at & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        _menuItem(
          key: const Key('todo-menu-edit'),
          icon: Icons.edit_outlined,
          label: AppStrings.todoEditAction,
          value: 'edit',
        ),
        _menuItem(
          key: const Key('todo-menu-delete'),
          icon: Icons.delete_outline,
          label: AppStrings.todoDeleteAction,
          value: 'delete',
          destructive: true,
        ),
      ],
    );
    await _runRowMenu(entry, action);
  }

  /// One entry of the cursor menu, its icon left of its label.
  PopupMenuItem<String> _menuItem({
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    bool destructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final colour = destructive ? scheme.error : null;
    return PopupMenuItem<String>(
      key: key,
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: colour),
          const SizedBox(width: 12),
          Text(label, style: colour == null ? null : TextStyle(color: colour)),
        ],
      ),
    );
  }

  /// Runs what either row menu answered.
  Future<void> _runRowMenu(TodoEntry entry, String? action) async {
    if (action == null || !mounted) return;
    switch (action) {
      case 'edit':
        await _edit(entry);
      case 'delete':
        await _delete(entry);
    }
  }

  /// Removes [entry]'s line from the visible file.
  Future<void> _delete(TodoEntry entry) {
    _log.debug('todo delete: line ${entry.lineIndex}');
    return _showDone
        ? widget.controller.deleteDone(entry)
        : widget.controller.deleteTodo(entry);
  }
}
