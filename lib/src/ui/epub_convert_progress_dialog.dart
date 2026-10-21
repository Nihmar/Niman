/// The progress of a book's conversion into notes (#1138), with the way to
/// stop it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/epub/epub_conversion.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The conversion's progress, with the way to stop it; it closes itself
/// when the conversion ends, however it ends.
final class EpubConvertProgressDialog extends StatefulWidget {
  /// Follows [conversion].
  const new(this.conversion, {super.key});

  /// The conversion followed.
  final EpubConversion conversion;

  @override
  State<EpubConvertProgressDialog> createState() =>
      _EpubConvertProgressDialogState();
}

final class _EpubConvertProgressDialogState
    extends State<EpubConvertProgressDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.conversion.done.then<void>(
        (_) => _close(),
        onError: (Object _) => _close(),
      ),
    );
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('epub-convert-progress'),
    title: Text(AppStrings.epubConvertTitle),
    content: ValueListenableBuilder<EpubConvertProgress?>(
      valueListenable: widget.conversion.progress,
      builder: (context, progress, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: progress == null || progress.total == 0
                ? null
                : progress.done / progress.total,
          ),
          const SizedBox(height: 12),
          Text(
            progress == null
                ? AppStrings.epubConvertReading
                : AppStrings.epubConvertProgress(progress.done, progress.total),
          ),
          if (progress != null)
            Text(
              p.posix.basename(progress.what),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const Key('epub-convert-cancel'),
        onPressed: () => unawaited(widget.conversion.cancel()),
        child: Text(AppStrings.actionCancel),
      ),
    ],
  );
}
