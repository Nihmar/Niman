/// The heading-level picker shared by the source editor and the WYSIWYG
/// surface (#51).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// Shows the heading-level picker (H1..H6); resolves to the chosen level
/// (1..6) or null (dismissed).
Future<int?> showHeadingLevelDialog(BuildContext context) {
  return showActionSheet<int>(
    context,
    sheetKey: const Key('heading-level-sheet'),
    title: AppStrings.headingDialogTitle,
    items: (context) => [
      for (var level = 1; level <= 6; level++)
        ListTile(
          key: ValueKey<int>(level),
          onTap: () => Navigator.of(context).pop(level),
          // The label is set in the size the heading will be, which says
          // more about the choice than the number does.
          title: Text(
            AppStrings.headingLevelLabel(level),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 26.0 - level * 2),
          ),
        ),
    ],
  );
}
