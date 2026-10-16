/// A desktop's todo list (#712, #1003): section headers and
/// [TodoPointerRow]s under one menu, with the keyboard on the list -- the
/// arrows move the selection across rows and headers, `Space` checks a row
/// or folds a header, `Enter` or `F2` edits a row in place (and `Enter`
/// folds a header), `Delete` deletes -- and a double click editing in
/// place. The tab owns the files; the list owns the selection, the edit in
/// place and the menu.
library;

import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/todo/line_edits.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/ui/todo_list_reveal.dart';
import 'package:niman/src/ui/todo_menu_pick.dart';
import 'package:niman/src/ui/todo_pointer_row.dart';
import 'package:niman/src/ui/todo_row_menu.dart';
import 'package:niman/src/ui/todo_section_header.dart';

/// The headers and rows of the todo list, for a pointer and a keyboard.
final class TodoPointerList extends StatefulWidget {
  /// Creates the list of [items]: the headers and the rows the filter
  /// leaves, in order.
  const new({
    required this.items,
    required this.today,
    required this.showPriority,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onRewrite,
    required this.onToggleSection,
    super.key,
  });

  /// The headers and rows shown, in order.
  final List<TodoListItem> items;

  /// The wall-clock day.
  final DateTime today;

  /// Whether a row shows its priority as a badge.
  final bool showPriority;

  /// Checks or unchecks a task.
  final Future<void> Function(TodoRowItem row, {required bool checked})
  onToggle;

  /// Opens the edit dialog.
  final Future<void> Function(TodoRowItem row) onEdit;

  /// Deletes a task.
  final Future<void> Function(TodoRowItem row) onDelete;

  /// Writes a line in place of a task's.
  final Future<void> Function(TodoRowItem row, String line) onRewrite;

  /// Folds a section, or opens it.
  final ValueChanged<String> onToggleSection;

  @override
  State<TodoPointerList> createState() => _TodoPointerListState();
}

final class _TodoPointerListState extends State<TodoPointerList> {
  /// The item the keyboard's selection is on, by [TodoListItem.id]. A row's
  /// id is its file and its line, so the selection means the same task
  /// across rebuilds and never the other file's line of that number; a
  /// header's is its section, so it survives a fold.
  String? _selected;

  /// The row whose text is a field, by id, or null.
  String? _editing;

  /// The last click on a row, to tell a double one.
  (String, DateTime)? _lastClick;

  /// The rows' menu, one for the list (#712), and what it is open for.
  final MenuController _menu = MenuController();
  TodoRowItem? _menuRow;

  /// The box the menu opens over, to place it at a point on screen.
  final GlobalKey _listKey = GlobalKey();

  /// The list's keys: the arrows, `Space`, `Enter`/`F2`, `Delete`.
  late final FocusNode _listFocus = FocusNode(debugLabel: 'todo-list');

  /// The list's scroll position, to bring the selected row into view.
  final ScrollController _scroll = ScrollController();

  /// Brings an item into view (#909): the reveal policy, apart.
  late final TodoListReveal _reveal = TodoListReveal(
    listKey: _listKey,
    scroll: _scroll,
    items: () => widget.items,
    keyOf: _keyOf,
    selected: () => _selected,
    mounted: () => mounted,
  );

  @override
  void didUpdateWidget(TodoPointerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A row that left the list (a filter, a file written elsewhere) is no
    // longer a field: the keys would stay ignored for a row nobody sees.
    final editing = _editing;
    if (editing != null && !widget.items.any((i) => i.id == editing)) {
      _editing = null;
    }
    _settleMenu();
  }

  /// The row menu across a publish: it means the task it was opened on, and
  /// a pick writes by that task's line -- in either file. The same task at
  /// the same place resolves against the fresh list; a row the publish took
  /// away or changed closes the menu, so no pick reaches a line that is
  /// another task's now.
  void _settleMenu() {
    final open = _menuRow;
    if (open == null) return;
    for (final item in widget.items) {
      if (item is TodoRowItem &&
          item.id == open.id &&
          item.entry.task.raw == open.entry.task.raw) {
        _menuRow = item;
        return;
      }
    }
    _menuRow = null;
    // The anchor is mid-build: it closes once the frame is out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _menu.isOpen) _menu.close();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return MenuAnchor(
      controller: _menu,
      menuChildren: _menuRow == null
          ? const []
          : todoRowMenuItems(
              onPick: (pick) => unawaited(_runPick(_menuRow!, pick)),
            ),
      child: Focus(
        key: _listKey,
        focusNode: _listFocus,
        onKeyEvent: _onListKey,
        child: ListView.builder(
          key: const Key('todo-list'),
          controller: _scroll,
          itemCount: items.length,
          itemBuilder: (context, index) {
            switch (items[index]) {
              case final TodoHeaderItem header:
                return TodoSectionHeader(
                  key: _keyOf(header),
                  item: header,
                  selected: header.id == _selected,
                  onToggle: () => _clickHeader(header),
                );
              case final TodoRowItem row:
                return TodoPointerRow(
                  key: _keyOf(row),
                  row: row,
                  today: widget.today,
                  selected: row.id == _selected,
                  editing: row.id == _editing,
                  showPriority: widget.showPriority,
                  onToggle: (checked) =>
                      unawaited(_toggle(row, checked: checked)),
                  onClick: () => _click(row),
                  onSubmitText: (text) => unawaited(_writeText(row, text)),
                  onCancelEdit: () => setState(() => _editing = null),
                  onMenuAt: (at) => _openMenu(row, at),
                );
            }
          },
        ),
      ),
    );
  }

  /// The key an item's widget wears: the ones the tests and [_reveal] find
  /// it by.
  Key _keyOf(TodoListItem item) {
    return switch (item) {
      TodoHeaderItem(:final section) => Key('todo-section-$section'),
      TodoRowItem(:final view, :final entry) => Key(
        'todo-row-$view-${entry.lineIndex}',
      ),
    };
  }

  /// A click on a row selects it; a second one on it in time edits its
  /// text.
  void _click(TodoRowItem row) {
    final now = DateTime.now();
    final last = _lastClick;
    final id = row.id;
    final twice =
        last != null &&
        last.$1 == id &&
        now.difference(last.$2) <= kDoubleTapTimeout;
    _lastClick = twice ? null : (id, now);
    _listFocus.requestFocus();
    setState(() {
      _selected = id;
      if (twice) _editing = id;
    });
  }

  /// A click on a header selects it and folds or opens its section.
  void _clickHeader(TodoHeaderItem header) {
    _lastClick = null;
    _listFocus.requestFocus();
    setState(() => _selected = header.id);
    widget.onToggleSection(header.section);
  }

  /// The list's keys (#712).
  KeyEventResult _onListKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _editing != null) {
      return KeyEventResult.ignored;
    }
    final items = widget.items;
    if (items.isEmpty) return KeyEventResult.ignored;
    final at = items.indexWhere((item) => item.id == _selected);
    final selected = at < 0 ? null : items[at];
    void select(int index, {required bool down}) {
      setState(() => _selected = items[index].id);
      unawaited(_reveal.run(index, down: down));
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        select(at < 0 ? 0 : (at + 1).clamp(0, items.length - 1), down: true);
      case LogicalKeyboardKey.arrowUp:
        select(
          at < 0 ? items.length - 1 : (at - 1).clamp(0, items.length - 1),
          down: false,
        );
      case LogicalKeyboardKey.space when event is KeyDownEvent:
        switch (selected) {
          case TodoRowItem():
            unawaited(
              _toggle(selected, checked: !selected.entry.task.completed),
            );
          case TodoHeaderItem():
            widget.onToggleSection(selected.section);
          case null:
            return KeyEventResult.ignored;
        }
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter
          when event is KeyDownEvent:
        switch (selected) {
          case TodoRowItem():
            setState(() => _editing = selected.id);
          case TodoHeaderItem():
            widget.onToggleSection(selected.section);
          case null:
            return KeyEventResult.ignored;
        }
      case LogicalKeyboardKey.f2
          when selected is TodoRowItem && event is KeyDownEvent:
        setState(() => _editing = selected.id);
      case LogicalKeyboardKey.delete
          when selected is TodoRowItem && event is KeyDownEvent:
        unawaited(_delete(selected));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Checks or unchecks [row]: its line moves to the other file.
  Future<void> _toggle(TodoRowItem row, {required bool checked}) {
    _leaves(row);
    return widget.onToggle(row, checked: checked);
  }

  /// Deletes [row]'s line.
  Future<void> _delete(TodoRowItem row) {
    _leaves(row);
    return widget.onDelete(row);
  }

  /// Follows the lines of the file [row] is in when its line leaves it
  /// (deleted, or moved to the other file): each below it takes the index
  /// above, so the selection stays on the same task — or, if it was [row],
  /// on the row that takes its place, the one before at the end (#910). The
  /// items are in display order, which the sort makes unlike the line
  /// order: a neighbour may sit above [row] in the file as well as below,
  /// and in the other file altogether, whose lines do not move.
  void _leaves(TodoRowItem row) {
    final items = widget.items;
    final at = items.indexWhere((item) => item.id == row.id);
    final gone = row.entry.lineIndex;
    final prefix = '${row.view}:';
    String? follow(String? id) {
      if (id == null || !id.startsWith(prefix)) return id;
      final line = int.parse(id.substring(prefix.length));
      return line < gone ? id : todoRowId(done: row.done, line: line - 1);
    }

    String? neighbour() {
      if (at < 0) return null;
      for (var i = at + 1; i < items.length; i++) {
        if (items[i] is TodoRowItem) return items[i].id;
      }
      for (var i = at - 1; i >= 0; i--) {
        if (items[i] is TodoRowItem) return items[i].id;
      }
      return null;
    }

    setState(() {
      _selected = _selected == row.id ? follow(neighbour()) : follow(_selected);
      _editing = _editing == row.id ? null : follow(_editing);
      _lastClick = null;
    });
  }

  /// Writes the text edited in place into [row]'s line.
  Future<void> _writeText(TodoRowItem row, String text) async {
    setState(() => _editing = null);
    _listFocus.requestFocus();
    final task = row.entry.task;
    if (text == task.description) return;
    await widget.onRewrite(row, todoLineWithText(task, text));
  }

  /// Opens the row menu for [row] at [global], a point on screen.
  void _openMenu(TodoRowItem row, Offset global) {
    final box = _listKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    setState(() {
      _menuRow = row;
      _selected = row.id;
    });
    _menu.open(position: box.globalToLocal(global));
  }

  /// Runs what the row menu picked for [row].
  Future<void> _runPick(TodoRowItem row, TodoMenuPick pick) {
    return runTodoMenuPick(
      context,
      row,
      pick,
      today: widget.today,
      onEdit: widget.onEdit,
      onDelete: _delete,
      onRewrite: widget.onRewrite,
    );
  }
}
