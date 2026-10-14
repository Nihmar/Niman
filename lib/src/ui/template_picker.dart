import 'package:flutter/material.dart';
import 'package:niman/src/templates/repo.dart';
import 'package:niman/src/ui/palette/quick_pick.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks which template to create from; resolves to the chosen entry, or
/// null when the dialog is dismissed (T-M4-07).
///
/// A library with no templates yet gets an explanation instead of an
/// empty list: the folder is a setting, and the way to fill it is to put
/// notes in it, neither of which is guessable from a blank dialog.
///
/// Where a pointer aims the templates are a quick pick in the palette's
/// panel (#712): typing filters them, the arrows and `Enter` choose.
Future<TemplateEntry?> showTemplatePicker(
  BuildContext context, {
  required List<TemplateEntry> templates,
  required String folder,
}) {
  if (templates.isNotEmpty && pointerDense(Theme.of(context))) {
    return showQuickPick<TemplateEntry>(
      context,
      key: const Key('template-picker'),
      hint: AppStrings.templatePickerTitle,
      items: [for (final template in templates) (template.name, template)],
      itemKey: (template) => Key('template-${template.path}'),
    );
  }
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
