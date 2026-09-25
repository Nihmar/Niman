/// The row under an attachment in the note pane.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The row under an attachment: its name, the attachment's own [actions],
/// and where the platform has one, the way to the system's own application
/// for it.
///
/// The [actions] sit to the left of that last button, on the side the row
/// grows from: the name gives them its room, and nothing already on the
/// row moves.
final class AttachmentBar extends StatelessWidget {
  /// The row for the attachment at [path].
  const new({
    required this.path,
    required this.launcher,
    this.actions = const <Widget>[],
    super.key,
  });

  /// The attachment's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// What this kind of attachment adds to the row: a book's contents.
  final List<Widget> actions;

  Future<void> _openOutside(BuildContext context) async {
    final outcome = await runTreeContextAction(
      path,
      TreeContextAction.openInDefaultApp,
      launcher: launcher,
    );
    if (!context.mounted || outcome == TreeContextOutcome.opened) return;
    final text = outcome == TreeContextOutcome.missing
        ? AppStrings.attachmentMissing
        : AppStrings.attachmentOpenFailed;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                p.basename(path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...actions,
            if (supportsTreeContextActions)
              IconButton(
                key: const Key('attachment-open-outside'),
                tooltip: AppStrings.openInDefaultApp,
                icon: const Icon(Icons.open_in_new),
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(_openOutside(context)),
              ),
          ],
        ),
      ),
    );
  }
}
