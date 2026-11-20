/// What a web page dropped on the window becomes (#1293): converted into a
/// note, attached to the note on screen as it always was (#1250), or both.
///
/// The two choices that attach are there with no note to attach to too,
/// disabled and saying why, so the dialog is the same shape either way and
/// nothing moves under a thumb already on it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What the dialog answers.
enum HtmlDropChoice {
  /// Make a note of the page; the file is not kept.
  convert,

  /// Attach the file to the note on screen, as a drop always did.
  attach,

  /// Attach the file, then make a note of the page.
  both,
}

/// Asks what to do with the pages at [paths]; null when it is dismissed.
/// With [canAttach] false the choices that attach are disabled.
Future<HtmlDropChoice?> showHtmlDropDialog(
  BuildContext context, {
  required List<String> paths,
  required bool canAttach,
}) => showDialog<HtmlDropChoice>(
  context: context,
  builder: (context) => HtmlDropDialog(paths: paths, canAttach: canAttach),
);

/// The dialog itself.
final class HtmlDropDialog extends StatelessWidget {
  /// Asks about the pages at [paths].
  const new({required this.paths, required this.canAttach, super.key});

  /// The dropped files, absolute paths.
  final List<String> paths;

  /// Whether a note is there to attach them to.
  final bool canAttach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void pick(HtmlDropChoice choice) => Navigator.of(context).pop(choice);
    return AlertDialog(
      key: const Key('html-drop-dialog'),
      title: Text(AppStrings.htmlDropTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paths.length > 1)
            Text(
              AppStrings.htmlConvertMany(paths.length),
              style: theme.textTheme.titleMedium,
            ),
          for (final path in paths)
            Text(
              p.basename(path),
              style: paths.length > 1
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('html-drop-convert'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.note_add_outlined),
            title: Text(AppStrings.convertStart),
            subtitle: Text(AppStrings.htmlDropConvertDetail),
            onTap: () => pick(HtmlDropChoice.convert),
          ),
          ListTile(
            key: const Key('html-drop-attach'),
            contentPadding: EdgeInsets.zero,
            enabled: canAttach,
            leading: const Icon(Icons.attach_file_outlined),
            title: Text(AppStrings.htmlDropAttach),
            subtitle: Text(AppStrings.htmlDropAttachDetail),
            onTap: () => pick(HtmlDropChoice.attach),
          ),
          ListTile(
            key: const Key('html-drop-both'),
            contentPadding: EdgeInsets.zero,
            enabled: canAttach,
            leading: const Icon(Icons.library_add_outlined),
            title: Text(AppStrings.htmlDropBoth),
            subtitle: Text(AppStrings.htmlDropBothDetail),
            onTap: () => pick(HtmlDropChoice.both),
          ),
          // Its place kept with a note open, so the dialog is as tall either
          // way and nothing moves.
          Visibility(
            visible: !canAttach,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppStrings.htmlDropNeedsNote,
                key: const Key('html-drop-needs-note'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('html-drop-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }
}
