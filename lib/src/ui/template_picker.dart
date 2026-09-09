import 'package:copist/src/templates/repo.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// Asks which template to create from; resolves to the chosen entry, or
/// null when the dialog is dismissed (T-M4-07).
///
/// A library with no templates yet gets an explanation instead of an
/// empty list: the folder is a setting, and the way to fill it is to put
/// notes in it, neither of which is guessable from a blank dialog.
Future<TemplateEntry?> showTemplatePicker(
  BuildContext context, {
  required List<TemplateEntry> templates,
  required String folder,
}) {
  return showDialog<TemplateEntry>(
    context: context,
    builder: (context) {
      if (templates.isEmpty) {
        return AlertDialog(
          key: const Key('template-picker-empty'),
          title: Text(AppStrings.templatePickerTitle),
          content: Text(AppStrings.templatePickerEmpty(folder)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.actionOk),
            ),
          ],
        );
      }
      return SimpleDialog(
        key: const Key('template-picker'),
        title: Text(AppStrings.templatePickerTitle),
        children: [
          for (final template in templates)
            SimpleDialogOption(
              key: Key('template-${template.path}'),
              onPressed: () => Navigator.pop(context, template),
              child: Text(template.name),
            ),
        ],
      );
    },
  );
}
