/// The questions editing the Home asks before it undoes something (#535).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks whether the Home goes back to the default one.
Future<bool> confirmHomeReset(BuildContext context) => _confirm(
  context,
  key: 'home-reset-dialog',
  title: AppStrings.homeResetTitle,
  body: AppStrings.homeResetBody,
  confirm: AppStrings.homeReset,
);

/// Asks whether this device's own Home is dropped for the library's.
Future<bool> confirmUseLibraryHome(BuildContext context) => _confirm(
  context,
  key: 'home-use-library-dialog',
  title: AppStrings.homeUseLibraryTitle,
  body: AppStrings.homeUseLibraryBody,
  confirm: AppStrings.homeUseLibraryConfirm,
);

Future<bool> _confirm(
  BuildContext context, {
  required String key,
  required String title,
  required String body,
  required String confirm,
}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: Key(key),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: Key('$key-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return yes ?? false;
}
