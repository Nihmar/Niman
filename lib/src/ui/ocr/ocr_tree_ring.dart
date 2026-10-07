import 'package:flutter/material.dart';
import 'package:niman/src/ocr/ocr_queue.dart';

/// A small ring at the end of a tree row while its file is being read
/// (#595): how far the job got, and nothing once it is over.
final class OcrTreeRing extends StatelessWidget {
  /// The ring of [path]'s (library-relative) job in [queue].
  const new({required this.queue, required this.path, super.key});

  /// The recognition jobs.
  final OcrQueue queue;

  /// The file, library-relative.
  final String path;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: queue,
    builder: (context, _) {
      final job = queue.jobFor(path);
      if (job == null || job.finished) return const SizedBox.shrink();
      return Padding(
        key: Key('ocr-ring-$path'),
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            value: job.pagesTotal == 0 ? null : job.fraction,
            strokeWidth: 2,
          ),
        ),
      );
    },
  );
}
