/// The desktop context menu's pages: the menu, or a submenu in its place.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/table_menu.dart';

/// The desktop menu's rows: the menu itself, or the table's submenu open
/// in its place (#261).
final class ContextMenuPages extends StatefulWidget {
  /// Creates the pages.
  const new({required this.main, required this.group, super.key});

  /// The menu's rows, given what opens a submenu.
  final List<Widget> Function(
    BuildContext context,
    void Function(TableMenuGroup group) open,
  )
  main;

  /// A submenu's rows, given the way back.
  final List<Widget> Function(TableMenuGroup group, VoidCallback back) group;

  @override
  State<ContextMenuPages> createState() => _ContextMenuPagesState();
}

final class _ContextMenuPagesState extends State<ContextMenuPages> {
  TableMenuGroup? _open;

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: open == null
          ? widget.main(context, (group) => setState(() => _open = group))
          : widget.group(open, () => setState(() => _open = null)),
    );
  }
}
