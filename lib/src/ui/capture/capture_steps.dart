/// What the capture dialog says while a page is read (#531): each step as
/// it happens — downloading, downloaded and how much, only so many words,
/// running the page in a browser and what that browser can reach — and,
/// when the page could not be had, why.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/ui/strings.dart';

/// A page's size as the dialog says it: kilobytes under a megabyte.
String capturedSize(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).ceil()} KB'
    : AppStrings.byteSize(bytes);

/// Why [error] kept the page from being captured, in words.
String captureFailureText(PageFetchException error) => switch (error.failure) {
  PageFetchFailure.scheme => AppStrings.captureFailScheme,
  PageFetchFailure.redirects => AppStrings.captureFailRedirects,
  PageFetchFailure.timeout => AppStrings.captureFailTimeout,
  PageFetchFailure.tooLarge => AppStrings.captureFailTooLarge,
  PageFetchFailure.notHtml => AppStrings.captureFailNotHtml,
  PageFetchFailure.status => AppStrings.captureFailStatus(error.detail),
  PageFetchFailure.network => AppStrings.captureFailNetwork,
};

/// The steps of a reading so far.
final class CaptureSteps extends StatelessWidget {
  /// The steps of [progress], the last one still running.
  const new({required this.progress, super.key});

  /// What the reading has said, the latest last.
  final CaptureProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget step(String text, {required bool done, String? detail}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 18,
            child: done
                ? Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  )
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text),
                if (detail != null) Text(detail, style: muted),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      key: const Key('capture-steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (progress.stage) {
        CaptureStage.downloading => [
          step(AppStrings.captureDownloading, done: false),
        ],
        CaptureStage.runningBrowser => [
          step(
            AppStrings.captureDownloaded(capturedSize(progress.bytes)),
            done: true,
          ),
          step(AppStrings.captureFewWords(progress.words), done: true),
          step(
            AppStrings.captureRunningBrowser,
            done: false,
            detail: AppStrings.captureBrowserPrivacy,
          ),
        ],
      },
    );
  }
}
