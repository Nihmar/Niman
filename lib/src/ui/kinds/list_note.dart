import 'dart:async';

import 'package:copist/src/frontmatter/note_kind.dart';
import 'package:copist/src/ui/kinds/list_item_row.dart';
import 'package:copist/src/ui/kinds/list_parser.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The frontmatter a new list note is created with.
String listNoteContent() => '---\ntype: list\n---\n';

/// The `list` note kind (T-TK-04): a check-list GUI over the note's task
/// items.
final class ListKindGui implements NoteKindGUI {
  @override
  String get type => 'list';

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) {
    return ListNoteView(text: host.text, onChanged: host.applyEdit);
  }
}

/// The list-kind body: the note's task items as checkable rows, nested by
/// indentation, plus an add row.
///
/// Prose in the note is invisible here (the raw editor shows it). Edits
/// are byte-stable ([flipListItem], [appendListItem], [editItemText],
/// [moveSubtree]): unmodified lines keep their bytes, and a moved item
/// keeps its bytes apart from the leading spaces.
class ListNoteView extends StatefulWidget {
  /// Creates the view; [onChanged] receives the new full note text.
  const ListNoteView({
    required this.text,
    required this.onChanged,
    super.key,
  });

  /// The full note text.
  final String text;

  /// Called with the new full note text after an edit; the host persists
  /// it.
  final ValueChanged<String> onChanged;

  @override
  State<ListNoteView> createState() => _ListNoteViewState();
}

/// The item being dragged (T-TK-09).
final class _Drag {
  _Drag(this.index);

  final int index;
  Offset? position;
}

/// Where a dragged item will land: the target item index in [mode], or
/// -1 (the zone above the list) / the item count (below it).
final class _DropTarget {
  const _DropTarget(this.item, this.mode);

  final int item;
  final ListDropMode mode;
}

class _ListNoteViewState extends State<ListNoteView>
    with SingleTickerProviderStateMixin {
  late List<ListItem> _items;
  final TextEditingController _newItem = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _rowKeys = {};
  int? _editingIndex;
  _Drag? _drag;
  _DropTarget? _drop;

  /// Drives the add row's show/hide: it steps aside while a row is being
  /// edited in place, so the edited row is never hidden behind it.
  late final AnimationController _addRowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final CurvedAnimation _addRowShown = CurvedAnimation(
    parent: _addRowController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _items = parseListItems(widget.text);
  }

  /// Opens ([index]) or closes (null) the in-place edit, animating the
  /// add row out of the way with it.
  void _setEditing(int? index) {
    _editingIndex = index;
    if (index == null) {
      _addRowController.forward();
    } else {
      _addRowController.reverse();
    }
  }

  @override
  void didUpdateWidget(ListNoteView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      final oldItems = _items;
      _items = parseListItems(widget.text);
      _drag = null;
      _drop = null;
      // An open in-place edit survives the rebuild unless its own line
      // changed (a committed edit or a pencil edit under the field).
      final e = _editingIndex;
      if (e != null &&
          (e >= _items.length || oldItems[e].text != _items[e].text)) {
        _setEditing(null);
      }
    }
  }

  @override
  void dispose() {
    _newItem.dispose();
    _scroll.dispose();
    _addRowShown.dispose();
    _addRowController.dispose();
    super.dispose();
  }

  GlobalKey _rowKey(int index) => _rowKeys.putIfAbsent(index, GlobalKey.new);

  void _toggle(int index) {
    widget.onChanged(flipListItem(widget.text, _items[index]));
  }

  void _add() {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    _newItem.clear();
    widget.onChanged(appendListItem(widget.text, text));
  }

  void _beginEdit(int index) {
    if (_drag != null) return;
    setState(() => _setEditing(index));
  }

  void _commitEdit(int index, String raw) {
    if (!mounted) return;
    final text = raw.trim();
    final item = _items[index];
    if (text == item.text) {
      if (_editingIndex == index) setState(() => _setEditing(null));
      return;
    }
    widget.onChanged(editItemText(widget.text, item, text));
  }

  void _onDragStart(int index, Offset global) {
    if (_drag != null) return;
    unawaited(HapticFeedback.mediumImpact());
    _drag = _Drag(index)..position = global;
    _drop = _dropAt(global);
    _autoScroll(global);
    setState(() {});
  }

  void _onDragMove(Offset global) {
    final drag = _drag;
    if (drag == null) return;
    drag.position = global;
    _autoScroll(global);
    final drop = _dropAt(global);
    if (!_sameDrop(drop, _drop)) {
      setState(() => _drop = drop);
    }
  }

  void _onDragEnd() {
    final drag = _drag;
    final drop = _drop;
    setState(() {
      _drag = null;
      _drop = null;
    });
    if (drag == null || drop == null) return;
    final resolved = resolveListDrop(
      _items,
      drag.index,
      drop.item,
      drop.mode,
      listLineCount(widget.text),
    );
    if (resolved == null) return;
    unawaited(HapticFeedback.mediumImpact());
    widget.onChanged(
      moveSubtree(
        widget.text,
        _items,
        drag.index,
        insertLine: resolved.insertLine,
        indent: resolved.indent,
      ),
    );
  }

  void _onDragCancel() {
    setState(() {
      _drag = null;
      _drop = null;
    });
  }

  bool _sameDrop(_DropTarget? a, _DropTarget? b) =>
      a == null ? b == null : b != null && a.item == b.item && a.mode == b.mode;

  /// The drop target under [global], or null (no indicator).
  _DropTarget? _dropAt(Offset global) {
    final items = _items;
    final drag = _drag;
    if (items.isEmpty || drag == null) return null;
    final listBox = _listBox();
    if (listBox == null) return null;
    final listRect = listBox.localToGlobal(Offset.zero) & listBox.size;
    if (global.dx < listRect.left || global.dx > listRect.right) return null;

    final dragLine = items[drag.index].line;
    final dragEnd = subtreeEnd(items, drag.index, listLineCount(widget.text));
    for (var j = 0; j < items.length; j++) {
      if (j == drag.index) continue;
      final line = items[j].line;
      if (line > dragLine && line < dragEnd) continue; // own subtree
      final box = _rowBox(j);
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final height = box.size.height;
      if (global.dy < top || global.dy >= top + height) continue;
      final rel = (global.dy - top) / height;
      return _DropTarget(
        j,
        rel < 0.25
            ? ListDropMode.before
            : rel > 0.75
                ? ListDropMode.after
                : ListDropMode.under,
      );
    }

    final first = _rowBox(0);
    if (first != null) {
      final top = first.localToGlobal(Offset.zero).dy;
      final bottom = top + first.size.height;
      if (bottom >= listRect.top && global.dy < top) {
        return const _DropTarget(-1, ListDropMode.before);
      }
    }
    final last = _rowBox(items.length - 1);
    if (last != null) {
      final top = last.localToGlobal(Offset.zero).dy;
      final bottom = top + last.size.height;
      if (top <= listRect.bottom && global.dy >= bottom) {
        return _DropTarget(items.length, ListDropMode.after);
      }
    }
    return null;
  }

  RenderBox? _rowBox(int index) {
    final key = _rowKeys[index];
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    return box is RenderBox ? box : null;
  }

  RenderBox? _listBox() {
    final ctx = _listKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    return box is RenderBox ? box : null;
  }

  /// Keeps the drop zone reachable: scrolls while the pointer is near a
  /// list edge.
  ///
  /// [ScrollPosition.jumpTo], not `correctBy`: the latter is a layout-time
  /// correction that moves the offset without notifying anyone, so the
  /// list only actually scrolled on the frames something else happened to
  /// rebuild it.
  void _autoScroll(Offset global) {
    final box = _listBox();
    if (box == null || !_scroll.hasClients) return;
    final local = box.globalToLocal(global);
    const edge = 60.0;
    final position = _scroll.position;
    var delta = 0.0;
    if (local.dy < edge) {
      delta = -(edge - local.dy) * 0.5;
    } else if (local.dy > box.size.height - edge) {
      delta = (local.dy - (box.size.height - edge)) * 0.5;
    }
    if (delta == 0) return;
    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if (target != position.pixels) _scroll.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Padding(
      padding: EdgeInsets.only(
        // Raised above the bottom edge: phones with rounded screen
        // corners clip the add row's own corners there.
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.listEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: _listKey,
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      ListDropMode? indicator;
                      final drop = _drop;
                      if (drop != null) {
                        if (drop.item == index) {
                          indicator = drop.mode;
                        } else if (drop.item == -1 && index == 0) {
                          indicator = ListDropMode.before;
                        } else if (drop.item == items.length &&
                            index == items.length - 1) {
                          indicator = ListDropMode.after;
                        }
                      }
                      return ListItemRow(
                        key: _rowKey(index),
                        item: item,
                        isDragSource: _drag?.index == index,
                        isEditing: _editingIndex == index,
                        indicator: indicator,
                        onToggle: () => _toggle(index),
                        onBeginEdit: () => _beginEdit(index),
                        onCommitEdit: (text) => _commitEdit(index, text),
                        onDragStart: (global) => _onDragStart(index, global),
                        onDragMove: _onDragMove,
                        onDragEnd: _onDragEnd,
                        onDragCancel: _onDragCancel,
                      );
                    },
                  ),
          ),
          _addRow(context),
        ],
      ),
    );
  }

  Widget _addRow(BuildContext context) {
    return SizeTransition(
      key: const Key('list-add-row'),
      sizeFactor: _addRowShown,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _addRowShown,
        child: _addField(context),
      ),
    );
  }

  Widget _addField(BuildContext context) {
    return Padding(
      // Inset from the screen edges, which are rounded on most phones.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: TextField(
        controller: _newItem,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.listAddHint,
          prefixIcon: const Icon(Icons.add),
          suffixIcon: IconButton(
            key: const Key('list-add-button'),
            icon: const Icon(Icons.check),
            tooltip: AppStrings.listAddTooltip,
            onPressed: _add,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (_) => _add(),
      ),
    );
  }
}
