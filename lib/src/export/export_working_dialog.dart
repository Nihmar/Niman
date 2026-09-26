/// The dialog a note's EPUB export shows while its book is built (#303):
/// the page parsed and typeset, the pictures copied into the container, the
/// zip written.
///
/// There is no step small enough to report — the typesetting is one
/// isolate pass, the container one close — so the bar moves on its own.
/// The dialog closes itself when `done` completes, whatever the outcome:
/// the shell that started the export owns the message about where the file
/// landed, and this only watches.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// A running export with no countable steps, watched by [done].
final class ExportWorkingDialog extends StatefulWidget {
  /// Shows [title] and closes when [done] completes.
  const new({required this.title, required this.done, super.key});

  /// The note's own name, so the dialog says what is being exported.
  final String title;

  /// Completes when the export is over — written or failed.
  final Future<void> done;

  @override
  State<ExportWorkingDialog> createState() => _ExportWorkingDialogState();
}

final class _ExportWorkingDialogState extends State<ExportWorkingDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(_watch());
  }

  /// Waits the export out — an error is the caller's to report — and closes
  /// the dialog.
  Future<void> _watch() async {
    try {
      await widget.done;
    } on Object {
      // The shell shows what went wrong.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('export-working'),
      title: Text(AppStrings.exportTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
