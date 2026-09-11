import 'package:flutter/material.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// The heading outline (T-M2-07): the note's headings, indented by level;
/// picking one jumps the editor to that heading's line.
///
/// It opens as the app's action sheet rather than the panel it used to be
/// (user, 2026-09-09): jumping is a choice from a list, the same shape as
/// the tree's long-press menu, and as a sheet it can be as tall as the
/// note is deep without taking the room away from the editor underneath.
///
/// Resolves to the chosen heading's line, or null when dismissed.
Future<int?> showOutlineSheet(
  BuildContext context, {
  required List<OutlineEntry> entries,
  Set<int> foldedLines = const <int>{},
}) {
  return showActionSheet<int>(
    context,
    sheetKey: const Key('outline-sheet'),
    title: AppStrings.outlineTooltip,
    items: (context) => [
      if (entries.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Text(
            AppStrings.outlineNoHeadings,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final entry in entries)
        _OutlineRow(
          entry: entry,
          folded: foldedLines.contains(entry.line),
          onTap: () => Navigator.of(context).pop(entry.line),
        ),
    ],
  );
}

/// One heading row: indented by its level, named by its text, with a
/// filled chevron when the heading is folded in the editor.
final class _OutlineRow extends StatelessWidget {
  const new({required this.entry, required this.folded, required this.onTap});

  final OutlineEntry entry;
  final bool folded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 8 + (entry.level - 1) * 14.0),
            Icon(
              folded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.text.isEmpty ? AppStrings.outlineNoTitle : entry.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: entry.level == 1
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
