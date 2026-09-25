/// A book's table of contents, as a sheet from its row (#280): the
/// entries indented by depth, the one being read marked, a tap jumping.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// Shows [document]'s contents, the entry at [top] (a line of its text)
/// marked; the line of the entry picked, or null.
Future<int?> showEpubContents(
  BuildContext context,
  EpubDocument document,
  int top,
) {
  final current = document.entryAt(top);
  return showActionSheet<int>(
    context,
    sheetKey: const Key('epub-contents'),
    title: AppStrings.outlineTooltip,
    items: (context) => [
      for (final (index, entry) in document.contents.indexed)
        ListTile(
          key: Key('epub-contents-$index'),
          dense: true,
          selected: index == current,
          contentPadding: EdgeInsetsDirectional.only(
            start: 16 + 16.0 * entry.depth,
            end: 16,
          ),
          title: Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.of(context).pop(entry.line),
        ),
    ],
  );
}
