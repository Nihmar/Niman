import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// What a search hit's menu was asked to do.
enum SearchHitAction {
  /// Open the hit, as a tap does.
  open,

  /// Open the hit in a new tab.
  newtab,

  /// Open the hit in the other pane.
  beside,

  /// Show the hit as a row of the tree.
  reveal,

  /// Replace in the hit's note alone (T-M3-10).
  replace,
}

/// Shows a result row's menu: the single-note replace (T-M3-10) and, with
/// [opens] set — where the shell has them —, the other ways to open it
/// (#712). A long press on a phone; a right click, at [anchor], where a
/// pointer aims. Null when it is dismissed.
Future<SearchHitAction?> showSearchHitMenu(
  BuildContext context, {
  required bool opens,
  Rect? anchor,
}) {
  Widget row(SearchHitAction value, IconData icon, String label) => ListTile(
    key: Key('search-hit-action-${value.name}'),
    leading: Icon(icon),
    title: Text(label),
    onTap: () => Navigator.pop(context, value),
  );
  return showActionSheet<SearchHitAction>(
    context,
    anchor: anchor,
    items: (context) => [
      if (opens) ...[
        row(
          SearchHitAction.open,
          Icons.open_in_browser_outlined,
          AppStrings.actionOpen,
        ),
        row(
          SearchHitAction.newtab,
          Icons.tab_outlined,
          AppStrings.openInNewTab,
        ),
        row(
          SearchHitAction.beside,
          Icons.vertical_split_outlined,
          AppStrings.openBeside,
        ),
        row(
          SearchHitAction.reveal,
          Icons.account_tree_outlined,
          AppStrings.revealInTree,
        ),
      ],
      ListTile(
        key: const Key('replace-note-action'),
        leading: const Icon(Icons.find_replace),
        title: Text(AppStrings.replaceInNoteAction),
        onTap: () => Navigator.pop(context, SearchHitAction.replace),
      ),
    ],
  );
}
