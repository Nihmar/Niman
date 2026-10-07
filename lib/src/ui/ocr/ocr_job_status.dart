import 'package:flutter/material.dart';
import 'package:niman/src/ocr/ocr_job.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// A recognition under way (#594): "Recognizing p. 3 of 4 · Cancel" over
/// a thin bar. In a file's bar ([path] set) it follows that file's job;
/// as the phone's strip ([path] null) it follows whichever job runs and
/// names its file, so it shows wherever the reader went meanwhile.
/// Nothing at all when there is no such job.
final class OcrJobStatus extends StatelessWidget {
  /// The status of [path]'s job, or of the running one.
  const new({required this.queue, this.path, this.except, super.key});

  /// The recognition jobs.
  final OcrQueue queue;

  /// The file followed (library-relative); null for the running job.
  final String? path;

  /// As the strip, the file on screen: its own bar already says it.
  final String? except;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: queue,
    builder: (context, _) {
      final path = this.path;
      final job = path == null ? queue.running : queue.jobFor(path);
      if (job == null || job.finished || job.path == except) {
        return const SizedBox.shrink();
      }
      final theme = Theme.of(context);
      final label = switch (job.phase) {
        OcrJobPhase.downloading => AppStrings.ocrPreparing,
        OcrJobPhase.recognizing ||
        OcrJobPhase.writing => AppStrings.ocrRecognizing(
          job.currentPage.clamp(1, job.pagesTotal),
          job.pagesTotal,
        ),
        _ => AppStrings.ocrRecognizeAction,
      };
      final cancel = TextButton(
        key: Key('ocr-cancel-${job.id}'),
        onPressed: () => queue.cancel(job),
        child: Text(AppStrings.actionCancel),
      );
      final progress = LinearProgressIndicator(
        value: job.phase == OcrJobPhase.recognizing ? job.fraction : null,
        minHeight: 2,
      );
      if (path != null) {
        return Row(
          key: const Key('ocr-job-status'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                SizedBox(width: 140, child: progress),
              ],
            ),
            cancel,
          ],
        );
      }
      return Material(
        key: const Key('ocr-strip'),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          p.posix.basename(job.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  cancel,
                ],
              ),
            ),
            progress,
          ],
        ),
      );
    },
  );
}
