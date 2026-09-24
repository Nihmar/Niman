/// The desktop context menu as a menu is on a desktop: a panel at the
/// click, and a group's submenu in a panel of its own beside the row it
/// opens from, opening as the pointer comes onto that row (#260 follow-up,
/// 2026-09-24 report).
///
/// The menu used to turn into the submenu in its own place, with a way
/// back on top: a selection toolbar has nowhere steady to put a flyout.
/// This one is the whole screen's, the overlay the menu is shown in, so
/// the two panels are placed on it directly — beside each other, and both
/// kept inside the window.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_items.dart';

/// What the main panel's rows are given: `open` for what a row the pointer
/// comes onto opens — a group, or nothing — and `keyOf`, the key a group's
/// row carries so its submenu can stand level with it.
typedef FlyoutRows = ({
  void Function(ContextMenuGroup? group) open,
  GlobalKey Function(ContextMenuGroup group) keyOf,
});

/// The menu at [anchor], and the submenu open beside it.
final class ContextMenuFlyout extends StatefulWidget {
  /// Creates the menu.
  const new({
    required this.anchor,
    required this.main,
    required this.group,
    super.key,
  });

  /// Where the menu opens, in the overlay's coordinates.
  final Offset anchor;

  /// The menu's rows, given what the pointer on a row opens.
  final List<Widget> Function(BuildContext context, FlyoutRows rows) main;

  /// A group's rows.
  final List<Widget> Function(ContextMenuGroup group) group;

  /// How wide each panel is.
  static const double width = 248;

  /// What a panel leaves free round the window's edge.
  static const double margin = 8;

  /// A panel's padding above and below its rows.
  static const double padding = 4;

  @override
  State<ContextMenuFlyout> createState() => _ContextMenuFlyoutState();
}

final class _ContextMenuFlyoutState extends State<ContextMenuFlyout> {
  ContextMenuGroup? _open;

  /// Where the row the open group hangs from starts, from the menu's top.
  double _rowTop = 0;

  final GlobalKey _mainKey = GlobalKey();

  /// Each group row's key, by the group's id, kept across rebuilds.
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};

  GlobalKey _keyOf(ContextMenuGroup group) =>
      _rowKeys.putIfAbsent(group.id, GlobalKey.new);

  void _openFrom(ContextMenuGroup? group) {
    if (group == null) {
      if (_open != null) setState(() => _open = null);
      return;
    }
    if (group.id == _open?.id) return;
    final main = _mainKey.currentContext?.findRenderObject();
    final box = _keyOf(group).currentContext?.findRenderObject();
    var top = 0.0;
    if (main is RenderBox &&
        box is RenderBox &&
        main.attached &&
        box.attached) {
      top = box.localToGlobal(Offset.zero, ancestor: main).dy;
    }
    setState(() {
      _open = group;
      _rowTop = top;
    });
  }

  Widget _panel(BuildContext context, List<Widget> rows, {Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    final room =
        MediaQuery.sizeOf(context).height - 2 * ContextMenuFlyout.margin;
    return Material(
      key: key,
      elevation: 8,
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ContextMenuFlyout.width,
          minWidth: ContextMenuFlyout.width,
          maxHeight: room < 0 ? 0 : room,
        ),
        // All of the rows make a tall menu: on a short window it keeps to
        // the window and scrolls, rather than running off its foot.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: ContextMenuFlyout.padding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return CustomMultiChildLayout(
      delegate: _FlyoutLayout(anchor: widget.anchor, rowTop: _rowTop),
      children: <Widget>[
        LayoutId(
          id: _Panel.main,
          child: _panel(
            context,
            widget.main(context, (open: _openFrom, keyOf: _keyOf)),
            key: _mainKey,
          ),
        ),
        if (open != null)
          LayoutId(
            id: _Panel.sub,
            child: _panel(
              context,
              widget.group(open),
              key: Key('${open.id}-submenu'),
            ),
          ),
      ],
    );
  }
}

enum _Panel { main, sub }

/// Places the menu at the anchor and the submenu beside its row, both
/// inside the window: the menu goes left or up from the anchor when it
/// would run off the right or the bottom, and the submenu to the menu's
/// left when there is no room on its right.
final class _FlyoutLayout extends MultiChildLayoutDelegate {
  new({required this.anchor, required this.rowTop});

  final Offset anchor;
  final double rowTop;

  @override
  void performLayout(Size size) {
    const margin = ContextMenuFlyout.margin;
    final loose = BoxConstraints.loose(size);
    final main = layoutChild(_Panel.main, loose);
    var x = anchor.dx;
    var y = anchor.dy;
    if (x + main.width > size.width - margin) x = anchor.dx - main.width;
    if (y + main.height > size.height - margin) {
      y = size.height - margin - main.height;
    }
    x = x.clamp(margin, _max(size.width - margin - main.width, margin));
    y = y.clamp(margin, _max(size.height - margin - main.height, margin));
    positionChild(_Panel.main, Offset(x, y));
    if (!hasChild(_Panel.sub)) return;
    final sub = layoutChild(_Panel.sub, loose);
    var subX = x + main.width - 2;
    if (subX + sub.width > size.width - margin) subX = x - sub.width + 2;
    // Its first row level with the row it opened from.
    var subY = y + rowTop - ContextMenuFlyout.padding;
    if (subY + sub.height > size.height - margin) {
      subY = size.height - margin - sub.height;
    }
    subY = subY.clamp(margin, _max(size.height - margin - sub.height, margin));
    positionChild(_Panel.sub, Offset(subX, subY));
  }

  static double _max(double a, double b) => a > b ? a : b;

  @override
  bool shouldRelayout(_FlyoutLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.rowTop != rowTop;
}
