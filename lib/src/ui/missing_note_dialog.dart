import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks whether to create the missing note at library-relative `[path]`
/// (issue #78); resolves to whether the user chose to create it.
///
/// The dialog offers the proposed path, so the user sees exactly where
/// the note would land before it does. A dismiss (outside tap) reads
/// as a decline: `null`.
///
/// Where a pointer aims it is a menu at [anchor] — where the link was
/// clicked — with Create as its row (#712): a click away declines.
Future<bool?> showMissingNoteDialog(
  BuildContext context, {
  required String path,
  Rect? anchor,
}) {
  if (pointerDense(Theme.of(context))) {
    return showActionSheet<bool>(
      context,
      title: AppStrings.missingNoteDialogBody(path),
      anchor: anchor,
      items: (context) => [
        ListTile(
          key: const Key('missing-note-create'),
          leading: const Icon(Icons.note_add_outlined),
          title: Text(AppStrings.actionCreate),
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppStrings.missingNoteDialogTitle),
      content: Text(AppStrings.missingNoteDialogBody(path)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppStrings.actionCreate),
        ),
      ],
    ),
  );
}
