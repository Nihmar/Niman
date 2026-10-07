import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/ui/strings.dart';

/// One downloadable file in a list (a transcription model, the OCR engine,
/// an OCR language): what it shows and offers follows its [state].
///
/// Downloading shows the bytes and a bar, with cancel; a download the
/// connection cut off shows where it paused, with resume and discard; a
/// failure says so, with retry; an installed file offers delete, after
/// asking with [deleteTitle] and [deleteBody]. The keys are
/// `<keyPrefix>-download-<id>`, `-cancel-`, `-discard-`, `-retry-`,
/// `-delete-` and `<keyPrefix>-delete-confirm`.
final class DownloadTile extends StatelessWidget {
  /// The row for the file [id], [bytes] long as published.
  const new({
    required this.id,
    required this.keyPrefix,
    required this.state,
    required this.bytes,
    required this.title,
    required this.idle,
    required this.deleteTitle,
    required this.deleteBody,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    this.installedLeading,
    this.onTap,
    super.key,
  });

  /// The file's id, in the keys.
  final String id;

  /// What the keys start with.
  final String keyPrefix;

  /// Where the file stands.
  final DownloadState state;

  /// The published size, until the file on disk says otherwise.
  final int bytes;

  /// The title line, badges included.
  final Widget title;

  /// The subtitle while nothing is downloading or failed.
  final String idle;

  /// The delete confirmation's title.
  final String deleteTitle;

  /// The delete confirmation's body, given the size freed.
  final String Function(String size) deleteBody;

  /// Starts or resumes the download.
  final VoidCallback onDownload;

  /// Stops the download, discarding its bytes.
  final VoidCallback onCancel;

  /// Deletes the file, once confirmed.
  final Future<void> Function() onDelete;

  /// The leading widget once installed; a check when null.
  final Widget? installedLeading;

  /// The tap on the whole row, if any.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = AppStrings.byteSize(switch (state) {
      Downloaded(:final bytes) => bytes,
      _ => bytes,
    });

    final leading = switch (state) {
      Downloaded() =>
        installedLeading ?? const Icon(Icons.download_done_outlined),
      Downloading(:final fraction) => SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(value: fraction, strokeWidth: 2.5),
      ),
      DownloadFailed(resumable: true) => const Icon(Icons.pause_circle_outline),
      DownloadFailed() => Icon(Icons.error_outline, color: colors.error),
      NotDownloaded() => const Icon(Icons.cloud_download_outlined),
    };

    String progress(int received, int total, double fraction) =>
        '${AppStrings.byteSize(received)} / '
        '${AppStrings.byteSize(total)} · ${(fraction * 100).floor()}%';
    const figures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

    final subtitle = switch (state) {
      Downloading(
        :final received,
        :final total,
        :final fraction,
        :final retrying,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              retrying
                  ? AppStrings.downloadRetrying
                  : progress(received, total, fraction),
              style: figures,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: fraction),
          ],
        ),
      DownloadFailed(
        resumable: true,
        :final received,
        :final total,
        :final fraction,
      ) =>
        Text(
          AppStrings.downloadPaused(progress(received, total, fraction)),
          style: figures,
        ),
      DownloadFailed() => Text(
        AppStrings.downloadFailed,
        style: TextStyle(color: colors.error),
      ),
      _ => Text(idle),
    };

    final trailing = switch (state) {
      Downloaded() => IconButton(
        key: Key('$keyPrefix-delete-$id'),
        tooltip: AppStrings.actionDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => unawaited(_confirmDelete(context, size)),
      ),
      Downloading() => IconButton(
        key: Key('$keyPrefix-cancel-$id'),
        tooltip: AppStrings.actionCancel,
        icon: const Icon(Icons.close),
        onPressed: onCancel,
      ),
      DownloadFailed(:final resumable) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resumable)
            IconButton(
              key: Key('$keyPrefix-discard-$id'),
              tooltip: AppStrings.actionCancel,
              icon: const Icon(Icons.close),
              onPressed: onCancel,
            ),
          TextButton(
            key: Key('$keyPrefix-retry-$id'),
            onPressed: onDownload,
            child: Text(
              resumable ? AppStrings.actionResume : AppStrings.actionRetry,
            ),
          ),
        ],
      ),
      NotDownloaded() => IconButton(
        key: Key('$keyPrefix-download-$id'),
        tooltip: AppStrings.actionDownload,
        icon: const Icon(Icons.download),
        onPressed: onDownload,
      ),
    };

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _confirmDelete(BuildContext context, String size) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(deleteBody(size)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: Key('$keyPrefix-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await onDelete();
  }
}
