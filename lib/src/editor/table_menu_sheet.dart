/// The phone's face of a table's submenu (#261).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/editor/table_menu.dart';

/// The phone's face of a table's submenu: a sheet of its actions, the
/// menu gone first.
void showTableMenuSheet(
  BuildContext context,
  TableMenuGroup group, {
  required VoidCallback onDismiss,
}) {
  final navigator = Navigator.of(context);
  onDismiss();
  unawaited(
    showModalBottomSheet<void>(
      context: navigator.context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (i, section) in group.sections.indexed) ...[
              if (i > 0) const Divider(),
              for (final action in section)
                ListTile(
                  key: Key('table-${action.id}'),
                  leading: Icon(action.icon),
                  title: Text(action.label),
                  enabled: action.onPressed != null,
                  onTap: () {
                    Navigator.of(context).pop();
                    action.onPressed?.call();
                  },
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
