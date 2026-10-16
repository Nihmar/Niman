import 'package:flutter/material.dart';
import 'package:niman/src/todo/todo_list_item.dart';

/// Brings an item of the desktop's todo list into view (#909) -- the
/// reveal policy of the keyboard's selection, apart from the list that owns
/// the selection.
///
/// It scrolls no further than the item's edge: `down` moves bring its
/// bottom in, the others its top. An item outside the list's built range
/// has no context to reveal, so the list first jumps to where the index is
/// estimated to sit -- the list's own estimate of its length, shared out by
/// item -- and the item, built there or near it, is then scrolled to. Each
/// jump lays out real items around the target, which sharpens the estimate
/// (the search list's `_revealHit` does the same).
final class TodoListReveal {
  /// Creates the reveal of the list drawn in [listKey] and scrolled by
  /// [scroll].
  ///
  /// The list owns what changes under a reveal and says it through the
  /// callbacks: its current [items], the widget [keyOf] an item wears, the
  /// [selected] id, and whether it is still [mounted].
  const new({
    required this.listKey,
    required this.scroll,
    required this.items,
    required this.keyOf,
    required this.selected,
    required this.mounted,
  });

  /// The box the list is drawn in.
  final GlobalKey listKey;

  /// The list's scroll position.
  final ScrollController scroll;

  /// The items shown now, in order.
  final List<TodoListItem> Function() items;

  /// The key the widget of an item wears.
  final Key Function(TodoListItem item) keyOf;

  /// The id of the selected item, or null.
  final String? Function() selected;

  /// Whether the list is still in the tree.
  final bool Function() mounted;

  /// How many jumps [run] makes at most: a bound keeps a list that keeps
  /// changing under it from holding the reveal open.
  static const int _revealJumps = 8;

  /// How long the scroll to an item takes.
  static const Duration _stepScroll = Duration(milliseconds: 100);

  /// Brings the item at [index] into view.
  Future<void> run(int index, {required bool down}) async {
    for (var jump = 0; jump < _revealJumps; jump++) {
      await WidgetsBinding.instance.endOfFrame;
      final current = items();
      // Another move or a new list since: that one reveals its own.
      if (!mounted() ||
          index >= current.length ||
          current[index].id != selected()) {
        return;
      }
      final target = _itemContext(current[index]);
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
      if (!scroll.hasClients) return;
      final position = scroll.position;
      final length = position.maxScrollExtent + position.viewportDimension;
      final offset =
          length * index / current.length - position.viewportDimension / 2;
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
    final list = listKey.currentContext?.findRenderObject();
    if (item is! RenderBox || list is! RenderBox) return down;
    final itemTop = item.localToGlobal(Offset.zero).dy;
    final itemBottom = itemTop + item.size.height;
    final listTop = list.localToGlobal(Offset.zero).dy;
    if (itemBottom > listTop + list.size.height) return true;
    if (itemTop < listTop) return false;
    return down;
  }

  /// The context of the built widget of [item], or null while it is not
  /// built.
  BuildContext? _itemContext(TodoListItem item) {
    final key = keyOf(item);
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget.key == key) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    listKey.currentContext?.visitChildElements(visit);
    return found;
  }
}
