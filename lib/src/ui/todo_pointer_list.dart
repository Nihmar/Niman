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
import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/todo/line_edits.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/ui/os_pickers.dart';
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

  @override
  void didUpdateWidget(TodoPointerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A row that left the list (a filter, a file written elsewhere) is no
    // longer a field: the keys would stay ignored for a row nobody sees.
    final editing = _editing;
    if (editing != null && !widget.items.any((i) => i.id == editing)) {
      _editing = null;
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
      unawaited(_reveal(index, down: down));
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

  /// Brings the item at [index] into view (#909), scrolling no further than
  /// its edge: [down] moves bring its bottom in, the others its top. An item
  /// outside the list's built range has no context to reveal, so the list
  /// first jumps to where the index is estimated to sit — the list's own
  /// estimate of its length, shared out by item — and the item, built there
  /// or near it, is then scrolled to. Each jump lays out real items around
  /// the target, which sharpens the estimate (the search list's `_revealHit`
  /// does the same).
  Future<void> _reveal(int index, {required bool down}) async {
    for (var jump = 0; jump < _revealJumps; jump++) {
      await WidgetsBinding.instance.endOfFrame;
      final items = widget.items;
      // Another move or a new list since: that one reveals its own.
      if (!mounted || index >= items.length || items[index].id != _selected) {
        return;
      }
      final target = _itemContext(items[index]);
      if (target != null) {
        if (!target.mounted) return;
        await Scrollable.ensureVisible(
          target,
          duration: _stepScroll,
          alignmentPolicy: _below(target, down: down)
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
        return;
      }
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final length = position.maxScrollExtent + position.viewportDimension;
      final offset =
          length * index / items.length - position.viewportDimension / 2;
      position.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
  }

  /// Whether the edge of [target] to bring into view is its bottom: it ends
  /// below the list's viewport, whichever way the selection moved (the first
  /// arrow up lands on the last item, from below). Fully in view, a [down]
  /// move keeps its bottom.
  bool _below(BuildContext target, {required bool down}) {
    final item = target.findRenderObject();
    final list = _listKey.currentContext?.findRenderObject();
    if (item is! RenderBox || list is! RenderBox) return down;
    final itemTop = item.localToGlobal(Offset.zero).dy;
    final itemBottom = itemTop + item.size.height;
    final listTop = list.localToGlobal(Offset.zero).dy;
    if (itemBottom > listTop + list.size.height) return true;
    if (itemTop < listTop) return false;
    return down;
  }

  /// How many jumps [_reveal] makes at most: a bound keeps a list that
  /// keeps changing under it from holding the reveal open.
  static const int _revealJumps = 8;

  /// How long the scroll to an item takes.
  static const Duration _stepScroll = Duration(milliseconds: 100);

  /// The context of the built widget of [item], or null while it is not
  /// built.
  BuildContext? _itemContext(TodoListItem item) {
    final key = _keyOf(item);
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
  Future<void> _runPick(TodoRowItem row, TodoMenuPick pick) async {
    final task = row.entry.task;
    final today = widget.today;
    switch (pick) {
      case TodoMenuPick.edit:
        await widget.onEdit(row);
      case TodoMenuPick.delete:
        await _delete(row);
      case TodoMenuPick.dueToday:
        await widget.onRewrite(row, todoLineWithDue(task, today));
      case TodoMenuPick.dueTomorrow:
        await widget.onRewrite(
          row,
          todoLineWithDue(task, addCalendarDays(today, 1)),
        );
      case TodoMenuPick.dueNextWeek:
        await widget.onRewrite(
          row,
          todoLineWithDue(task, addCalendarDays(today, 7)),
        );
      case TodoMenuPick.dueNone:
        await widget.onRewrite(row, todoLineWithDue(task, null));
      case TodoMenuPick.duePick:
        final day = await showDayPicker(
          context,
          initialDate: task.due ?? today,
          firstDate: DateTime(today.year - 5),
          lastDate: DateTime(today.year + 10),
        );
        if (day != null) {
          await widget.onRewrite(row, todoLineWithDue(task, day));
        }
      case TodoMenuPick.priorityA:
        await widget.onRewrite(row, todoLineWithPriority(task, 'A'));
      case TodoMenuPick.priorityB:
        await widget.onRewrite(row, todoLineWithPriority(task, 'B'));
      case TodoMenuPick.priorityC:
        await widget.onRewrite(row, todoLineWithPriority(task, 'C'));
      case TodoMenuPick.priorityNone:
        await widget.onRewrite(row, todoLineWithPriority(task, null));
    }
  }
}
