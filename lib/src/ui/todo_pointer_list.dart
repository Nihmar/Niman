/// A desktop's todo list (#712): [TodoPointerRow]s under one menu, with
/// the keyboard on the list — the arrows move the selection, `Space`
/// checks, `Enter` or `F2` edits in place, `Delete` deletes — and a double
/// click editing in place. The tab owns the files; the list owns the
/// selection, the edit in place and the menu.
library;

import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/todo/line_edits.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/todo_pointer_row.dart';
import 'package:niman/src/ui/todo_row_menu.dart';

/// The rows of one todo file, for a pointer and a keyboard.
final class TodoPointerList extends StatefulWidget {
  /// Creates the list of [entries], the rows the filter leaves, in order.
  const new({
    required this.entries,
    required this.view,
    required this.today,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onRewrite,
    super.key,
  });

  /// The rows shown, in order.
  final List<TodoEntry> entries;

  /// `open` or `done`: the file shown, in the rows' keys.
  final String view;

  /// The wall-clock day.
  final DateTime today;

  /// Checks or unchecks a task.
  final Future<void> Function(TodoEntry entry, {required bool checked})
  onToggle;

  /// Opens the edit dialog.
  final Future<void> Function(TodoEntry entry) onEdit;

  /// Deletes a task.
  final Future<void> Function(TodoEntry entry) onDelete;

  /// Writes a line in place of a task's.
  final Future<void> Function(TodoEntry entry, String line) onRewrite;

  @override
  State<TodoPointerList> createState() => _TodoPointerListState();
}

final class _TodoPointerListState extends State<TodoPointerList> {
  /// The line the keyboard's selection is on (#712). A line is an index
  /// into the file shown, so it means nothing in the other one: the
  /// selection goes with the view (#910), and [_leaves] keeps it on the
  /// row that takes a removed one's place.
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

  /// The list's scroll position, to bring the selected row into view.
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(TodoPointerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The other file's lines are other tasks: the selection, the edit in
    // place, a click awaiting its double and the open menu are not theirs.
    if (oldWidget.view != widget.view) {
      _selectedLine = null;
      _editingLine = null;
      _lastClick = null;
      _menuEntry = null;
      _menu.close();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
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
          controller: _scroll,
          itemCount: widget.entries.length,
          itemBuilder: (context, index) {
            final entry = widget.entries[index];
            final line = entry.lineIndex;
            return TodoPointerRow(
              key: Key('todo-row-$view-$line'),
              entry: entry,
              today: widget.today,
              selected: line == _selectedLine,
              editing: line == _editingLine,
              onToggle: (checked) =>
                  unawaited(_toggle(entry, checked: checked)),
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
    final rows = widget.entries;
    if (rows.isEmpty) return KeyEventResult.ignored;
    final at = rows.indexWhere((e) => e.lineIndex == _selectedLine);
    final selected = at < 0 ? null : rows[at];
    void select(int index, {required bool down}) {
      setState(() => _selectedLine = rows[index].lineIndex);
      unawaited(_reveal(index, down: down));
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        select(at < 0 ? 0 : (at + 1).clamp(0, rows.length - 1), down: true);
      case LogicalKeyboardKey.arrowUp:
        select(
          at < 0 ? rows.length - 1 : (at - 1).clamp(0, rows.length - 1),
          down: false,
        );
      case LogicalKeyboardKey.space
          when selected != null && event is KeyDownEvent:
        unawaited(_toggle(selected, checked: !selected.task.completed));
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

  /// Brings the row at [index] into view (#909), scrolling no further than
  /// its edge: [down] moves bring its bottom in, the others its top. A row
  /// outside the list's built range has no context to reveal, so the list
  /// first jumps to where the index is estimated to sit — the list's own
  /// estimate of its length, shared out by row — and the row, built there
  /// or near it, is then scrolled to. Each jump lays out real rows around
  /// the target, which sharpens the estimate (the search list's `_revealHit`
  /// does the same).
  Future<void> _reveal(int index, {required bool down}) async {
    for (var jump = 0; jump < _revealJumps; jump++) {
      await WidgetsBinding.instance.endOfFrame;
      final rows = widget.entries;
      // Another move or a new list since: that one reveals its own.
      if (!mounted ||
          index >= rows.length ||
          rows[index].lineIndex != _selectedLine) {
        return;
      }
      final row = _rowContext(rows[index].lineIndex);
      if (row != null) {
        if (!row.mounted) return;
        await Scrollable.ensureVisible(
          row,
          duration: _stepScroll,
          alignmentPolicy: down
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
        return;
      }
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final length = position.maxScrollExtent + position.viewportDimension;
      final offset =
          length * index / rows.length - position.viewportDimension / 2;
      position.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
  }

  /// How many jumps [_reveal] makes at most: a bound keeps a list that
  /// keeps changing under it from holding the reveal open.
  static const int _revealJumps = 8;

  /// How long the scroll to a row takes.
  static const Duration _stepScroll = Duration(milliseconds: 100);

  /// The context of the built row on [line], or null while it is not built.
  BuildContext? _rowContext(int line) {
    final key = Key('todo-row-${widget.view}-$line');
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget.key == key) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    _listKey.currentContext?.visitChildElements(visit);
    return found;
  }

  /// Checks or unchecks [entry]: its line moves to the other file.
  Future<void> _toggle(TodoEntry entry, {required bool checked}) {
    _leaves(entry);
    return widget.onToggle(entry, checked: checked);
  }

  /// Deletes [entry]'s line.
  Future<void> _delete(TodoEntry entry) {
    _leaves(entry);
    return widget.onDelete(entry);
  }

  /// Follows the lines of the file shown when [entry]'s leaves it (deleted,
  /// or moved to the other file): each below it takes the index above, so
  /// the selection stays on the same task — or, if it was [entry], on the
  /// row that takes its place, the one before at the end (#910). The rows
  /// are in display order, which the sort makes unlike the line order: a
  /// neighbour may sit above [entry] in the file as well as below.
  void _leaves(TodoEntry entry) {
    final rows = widget.entries;
    final at = rows.indexOf(entry);
    final gone = entry.lineIndex;
    int? follow(int? line) => line == null || line < gone ? line : line - 1;
    setState(() {
      if (_selectedLine == gone) {
        _selectedLine = at < 0
            ? null
            : at + 1 < rows.length
            ? follow(rows[at + 1].lineIndex)
            : at > 0
            ? follow(rows[at - 1].lineIndex)
            : null;
      } else {
        _selectedLine = follow(_selectedLine);
      }
      _editingLine = _editingLine == gone ? null : follow(_editingLine);
      _lastClick = null;
    });
  }

  /// Writes the text edited in place into [entry]'s line.
  Future<void> _writeText(TodoEntry entry, String text) async {
    setState(() => _editingLine = null);
    _listFocus.requestFocus();
    if (text == entry.task.description) return;
    await widget.onRewrite(entry, todoLineWithText(entry.task, text));
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
    final today = widget.today;
    switch (pick) {
      case TodoMenuPick.edit:
        await widget.onEdit(entry);
      case TodoMenuPick.delete:
        await _delete(entry);
      case TodoMenuPick.dueToday:
        await widget.onRewrite(entry, todoLineWithDue(task, today));
      case TodoMenuPick.dueTomorrow:
        await widget.onRewrite(
          entry,
          todoLineWithDue(task, today.add(const Duration(days: 1))),
        );
      case TodoMenuPick.dueNextWeek:
        await widget.onRewrite(
          entry,
          todoLineWithDue(task, today.add(const Duration(days: 7))),
        );
      case TodoMenuPick.dueNone:
        await widget.onRewrite(entry, todoLineWithDue(task, null));
      case TodoMenuPick.duePick:
        final day = await showDayPicker(
          context,
          initialDate: task.due ?? today,
          firstDate: DateTime(today.year - 5),
          lastDate: DateTime(today.year + 10),
        );
        if (day != null) {
          await widget.onRewrite(entry, todoLineWithDue(task, day));
        }
      case TodoMenuPick.priorityA:
        await widget.onRewrite(entry, todoLineWithPriority(task, 'A'));
      case TodoMenuPick.priorityB:
        await widget.onRewrite(entry, todoLineWithPriority(task, 'B'));
      case TodoMenuPick.priorityC:
        await widget.onRewrite(entry, todoLineWithPriority(task, 'C'));
      case TodoMenuPick.priorityNone:
        await widget.onRewrite(entry, todoLineWithPriority(task, null));
    }
  }
}
