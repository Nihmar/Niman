/// The dialog a note's PDF export shows while it runs (#63): the engine
/// printing, or — when no engine answers — the fallback drawing the note
/// page by page, with a way to stop.
///
/// It closes itself when the export ends, whatever the outcome: the shell
/// that starts the export owns the message about where the file landed,
/// and this only watches.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/ui/strings.dart';

/// The progress of one note's PDF export.
final class PdfExportProgressDialog extends StatefulWidget {
  /// Watches [progress] and closes when [done] completes.
  const new({
    required this.title,
    required this.progress,
    required this.done,
    required this.onCancel,
    super.key,
  });

  /// The note's own name, so the dialog says what is being exported.
  final String title;

  /// What the export is doing now; null before the first report.
  final ValueListenable<PdfExportProgress?> progress;

  /// Completes when the export is over — written, failed, or cancelled.
  final Future<void> done;

  /// Asks the export to stop; called once.
  final VoidCallback onCancel;

  @override
  State<PdfExportProgressDialog> createState() =>
      _PdfExportProgressDialogState();
}

final class _PdfExportProgressDialogState
    extends State<PdfExportProgressDialog> {
  bool _cancelling = false;

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
      // The shell shows what went wrong, or says nothing when it was
      // cancelled.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('pdf-export-progress'),
      title: Text(AppStrings.exportTitle),
      content: ValueListenableBuilder<PdfExportProgress?>(
        valueListenable: widget.progress,
        builder: (context, progress, _) {
          final done = progress?.done ?? 0;
          final total = progress?.total ?? 0;
          return Column(
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
              // The engine print has no pages to count: a bar that moves
              // on its own says the export is alive. The drawing fallback
              // counts the note's pages, so its bar is the real one.
              if (total > 0)
                LinearProgressIndicator(value: done / total)
              else
                const LinearProgressIndicator(),
              if (total > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$done / $total',
                  key: const Key('pdf-export-page'),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          key: const Key('pdf-export-cancel'),
          onPressed: _cancelling
              ? null
              : () {
                  setState(() => _cancelling = true);
                  widget.onCancel();
                },
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }
}
