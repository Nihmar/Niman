/// The dialog a folder's (or the library's) export shows while it runs
/// (#24): how far it has got, what it is on, and a way to stop it.
///
/// It closes itself when the export ends, whatever the outcome: the shell
/// that starts the export owns the message about where the file landed,
/// and this only watches.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/ui/strings.dart';

/// The progress of one running [TreeExport].
final class ExportProgressDialog extends StatefulWidget {
  /// Watches [export].
  const new({required this.export, super.key});

  /// The export running.
  final TreeExport export;

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

final class _ExportProgressDialogState extends State<ExportProgressDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(_watch());
  }

  /// Waits the export out — an error is the caller's to report — and
  /// closes the dialog.
  Future<void> _watch() async {
    try {
      await widget.export.done;
    } on Object {
      // The shell shows what went wrong, or says nothing when it was
      // cancelled.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('export-progress'),
      title: Text(AppStrings.exportTitle),
      content: ValueListenableBuilder<ExportProgress?>(
        valueListenable: widget.export.progress,
        builder: (context, progress, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress?.fraction),
            const SizedBox(height: 12),
            Text(
              progress?.current ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('export-cancel'),
          onPressed: () => unawaited(widget.export.cancel()),
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }
}
