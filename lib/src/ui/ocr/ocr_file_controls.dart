import 'package:flutter/material.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_job_status.dart';
import 'package:niman/src/ui/ocr/ocr_text_toggle.dart';
import 'package:niman/src/ui/strings.dart';

/// The file bar's part of text recognition: its job's progress while one
/// runs, and the Recognize text button, off meanwhile.
final class OcrFileControls extends StatelessWidget {
  /// The controls for the file at [path] (absolute); [pages] tells the
  /// page read and the page count of a PDF when pressed.
  const new({required this.actions, required this.path, this.pages, super.key});

  /// The shell's recognition actions.
  final OcrFileActions actions;

  /// The file, absolute.
  final String path;

  /// The page on screen and the page count; null for a picture or a PDF
  /// not laid out yet.
  final ({int page, int count})? Function()? pages;

  @override
  Widget build(BuildContext context) {
    final relative = actions.relative(path);
    return ListenableBuilder(
      listenable: actions.queue,
      builder: (context, _) {
        final job = actions.queue.jobFor(relative);
        final busy = job != null && !job.finished;
        final text = OcrTextToggle.maybeOf(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OcrJobStatus(queue: actions.queue, path: relative),
            // Filled while the pane is shown: the outline says it is off.
            if (text != null)
              IconButton(
                key: const Key('ocr-text-toggle'),
                tooltip: text.shown
                    ? AppStrings.ocrHideText
                    : AppStrings.ocrShowText,
                icon: Icon(text.shown ? Icons.article : Icons.article_outlined),
                visualDensity: VisualDensity.compact,
                onPressed: text.toggle,
              ),
            IconButton(
              key: const Key('recognize-button'),
              tooltip: AppStrings.ocrRecognizeAction,
              icon: const Icon(Icons.document_scanner_outlined),
              visualDensity: VisualDensity.compact,
              onPressed: busy
                  ? null
                  : () {
                      final at = pages?.call();
                      actions.recognize(
                        relative,
                        page: at?.page,
                        pageCount: at?.count,
                      );
                    },
            ),
          ],
        );
      },
    );
  }
}
