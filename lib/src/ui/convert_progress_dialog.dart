/// The progress of a conversion into notes (a book, #1138; a web page,
/// #1293), with the way to stop it: one dialog for both, which differ only
/// in what they are called and in what follows them.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// How far a conversion has got: `done` of `total` steps, and the name of
/// the one being written (`what`). The progress of the book's and of the
/// page's conversion alike.
typedef ConvertProgress = ({int done, int total, String what});

/// A conversion's progress, with the way to stop it; it closes itself when
/// the conversion ends, however it ends.
final class ConvertProgressDialog extends StatefulWidget {
  /// Follows a conversion: [progress] says how far it is, [done] ends when
  /// it does (with a value or an error), [cancel] asks it to stop.
  /// [reading] is what is said before the first step is known.
  const new({
    required this.progress,
    required this.done,
    required this.cancel,
    required this.reading,
    super.key,
    this.cancelKey,
  });

  /// Puts the dialog over [context]'s screen, for the conversion whose
  /// [progress], [done] and [cancel] are given: it cannot be dismissed but
  /// by stopping the conversion, and closes itself when that ends.
  static void show(
    BuildContext context, {
    required ValueListenable<ConvertProgress?> progress,
    required Future<void> done,
    required Future<void> Function() cancel,
    required String reading,
    Key? key,
    Key? cancelKey,
  }) => unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConvertProgressDialog(
        key: key,
        progress: progress,
        done: done,
        cancel: cancel,
        reading: reading,
        cancelKey: cancelKey,
      ),
    ),
  );

  /// How far the conversion is; null before its first step.
  final ValueListenable<ConvertProgress?> progress;

  /// Ends when the conversion does.
  final Future<void> done;

  /// Asks the conversion to stop.
  final Future<void> Function() cancel;

  /// What is said before the first step is known: "Reading the book…".
  final String reading;

  /// The key of the Cancel button.
  final Key? cancelKey;

  @override
  State<ConvertProgressDialog> createState() => _ConvertProgressDialogState();
}

final class _ConvertProgressDialogState extends State<ConvertProgressDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.done.then<void>((_) => _close(), onError: (Object _) => _close()),
    );
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(AppStrings.convertTitle),
    content: ValueListenableBuilder<ConvertProgress?>(
      valueListenable: widget.progress,
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
                ? widget.reading
                : AppStrings.convertProgress(progress.done, progress.total),
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
        key: widget.cancelKey,
        onPressed: () => unawaited(widget.cancel()),
        child: Text(AppStrings.actionCancel),
      ),
    ],
  );
}
