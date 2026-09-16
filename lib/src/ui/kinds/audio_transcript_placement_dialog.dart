import 'package:flutter/material.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks what a transcript does to the clip's existing [description]:
/// replace it or go below it. Null when cancelled.
///
/// Asked before the job is queued, so nothing waits on the user once the
/// transcription is done.
Future<TranscriptPlacement?> showTranscriptPlacementDialog(
  BuildContext context,
  String description,
) {
  return showDialog<TranscriptPlacement>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        key: const Key('transcription-placement-dialog'),
        icon: const Icon(Icons.subtitles_outlined),
        title: Text(AppStrings.transcriptionExistingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.transcriptionExistingBody),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
                child: Text(
                  description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('transcription-placement-append'),
            onPressed: () =>
                Navigator.of(context).pop(TranscriptPlacement.append),
            child: Text(AppStrings.transcriptionAppend),
          ),
          FilledButton(
            key: const Key('transcription-placement-replace'),
            onPressed: () =>
                Navigator.of(context).pop(TranscriptPlacement.replace),
            child: Text(AppStrings.transcriptionReplace),
          ),
        ],
      );
    },
  );
}
