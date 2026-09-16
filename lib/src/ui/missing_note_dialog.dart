import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks whether to create the missing note at library-relative `[path]`
/// (issue #78); resolves to whether the user chose to create it.
///
/// The dialog offers the proposed path, so the user sees exactly where
/// the note would land before it does. A dismiss (outside tap) reads
/// as a decline: `null`.
Future<bool?> showMissingNoteDialog(
  BuildContext context, {
  required String path,
}) {
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
