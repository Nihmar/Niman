import 'package:niman/src/editor/toolbar_item.dart';

/// The user's editor toolbar: every button in their order, with the ones
/// they hid marked (T-TB-02).
///
/// One ordered list rather than two, because that is what the settings
/// screen shows: a hidden button keeps its place in the list and simply
/// does not reach the toolbar, so unhiding it puts it back where it was.
///
/// Stored as `bold,italic,-strike,…`, a `-` prefix meaning hidden. A
/// stored value from another build still yields a usable toolbar: ids
/// this build does not know are dropped, and items the value never
/// mentions are appended, visible. That is what makes adding a button
/// later a non-event.
final class ToolbarLayout {
  /// Creates a layout from an explicit order and hidden set.
  const new({required this.order, required this.hidden});

  /// Reads a stored value; anything unparseable falls back to
  /// [defaults].
  factory parse(String? stored) {
    if (stored == null || stored.trim().isEmpty) return defaults;
    final order = <ToolbarItem>[];
    final hidden = <ToolbarItem>{};
    for (final raw in stored.split(',')) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      final isHidden = token.startsWith('-');
      final item = ToolbarItem.fromId(isHidden ? token.substring(1) : token);
      if (item == null || order.contains(item)) continue;
      order.add(item);
      if (isHidden) hidden.add(item);
    }
    if (order.isEmpty) return defaults;
    // Buttons this build has and the stored value does not: a newer
    // build's additions, shown rather than silently missing. One whose
    // neighbours in the catalogue were both stored is a button added
    // between them — a checkbox list among the lists — and goes beside
    // the one before it; any other goes at the end.
    const catalogue = ToolbarItem.values;
    final kept = {...order};
    for (var at = 0; at < catalogue.length; at++) {
      final item = catalogue[at];
      if (order.contains(item)) continue;
      final between =
          at > 0 &&
          at < catalogue.length - 1 &&
          kept.contains(catalogue[at - 1]) &&
          kept.contains(catalogue[at + 1]);
      if (between) {
        order.insert(order.indexOf(catalogue[at - 1]) + 1, item);
      } else {
        order.add(item);
      }
    }
    return ToolbarLayout(order: order, hidden: hidden);
  }

  /// The toolbar as it ships: every button, in the catalogue's order,
  /// nothing hidden.
  static const ToolbarLayout defaults = ToolbarLayout(
    order: ToolbarItem.values,
    hidden: <ToolbarItem>{},
  );

  /// Every known button, in the order the user put them in.
  final List<ToolbarItem> order;

  /// The buttons the user hid.
  final Set<ToolbarItem> hidden;

  /// The buttons the toolbar actually renders, in order.
  List<ToolbarItem> get visible => [
    for (final item in order)
      if (!hidden.contains(item)) item,
  ];

  /// Whether [item] is shown.
  bool isVisible(ToolbarItem item) => !hidden.contains(item);

  /// The stored form of this layout.
  String encode() => [
    for (final item in order)
      if (hidden.contains(item)) '-${item.id}' else item.id,
  ].join(',');

  /// This layout with [item] shown or hidden.
  ToolbarLayout withVisible(ToolbarItem item, {required bool visible}) {
    final next = <ToolbarItem>{...hidden};
    if (visible) {
      next.remove(item);
    } else {
      next.add(item);
    }
    return ToolbarLayout(order: order, hidden: next);
  }

  /// This layout with the row at [oldIndex] moved to [newIndex], in the
  /// index convention `ReorderableListView.onReorderItem` uses (the
  /// destination already accounts for the row leaving its old place).
  ToolbarLayout reorderedItem(int oldIndex, int newIndex) {
    final next = [...order];
    next.insert(newIndex, next.removeAt(oldIndex));
    return ToolbarLayout(order: next, hidden: hidden);
  }
}
