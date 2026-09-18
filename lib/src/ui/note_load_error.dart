/// What the note pane shows when the file behind it could not be opened
/// (issue #156).
///
/// A message in the user's words, never the exception: the detail is in
/// the log. When the file is not text — an attachment picked in the tree —
/// the desktop offers it to the application the system opens it with,
/// through the same path as the tree row's own entry (issue #76).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/strings.dart';

/// The note pane's body for a file that did not open.
class NoteLoadError extends StatelessWidget {
  /// Shows [message] for the file at [path]; [offerDefaultApp] adds the
  /// hand-off to the OS where the platform has one.
  const new({
    required this.message,
    required this.path,
    this.offerDefaultApp = false,
    this.launcher = const OsLauncher(),
    super.key,
  });

  /// What went wrong, already in the user's language.
  final String message;

  /// The absolute path of the file that did not open.
  final String path;

  /// Whether to offer the file to its default application.
  final bool offerDefaultApp;

  /// The OS seam, replaced in tests.
  final OsLauncher launcher;

  Future<void> _openOutside(BuildContext context) async {
    final outcome = await runTreeContextAction(
      path,
      TreeContextAction.openInDefaultApp,
      launcher: launcher,
    );
    if (!context.mounted || outcome == TreeContextOutcome.opened) return;
    final text = outcome == TreeContextOutcome.missing
        ? AppStrings.openFileMissing
        : AppStrings.openFileFailed;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              key: const Key('note-load-error'),
              textAlign: TextAlign.center,
            ),
            if (offerDefaultApp && supportsTreeContextActions) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('note-load-error-open-outside'),
                icon: const Icon(Icons.open_in_new),
                label: Text(AppStrings.openInDefaultApp),
                onPressed: () => unawaited(_openOutside(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
