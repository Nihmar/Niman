import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/strings.dart';

/// One model on the models page; what it shows and offers follows the
/// model's [DownloadState].
final class TranscriptionModelRow extends StatelessWidget {
  /// Creates the row for [model].
  const new({required this.model, required this.models, super.key});

  /// The model this row stands for.
  final TranscriptionModel model;

  /// The installation's models, for the state and the actions.
  final TranscriptionModels models;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = models.stateOf(model);
    final isDefault = models.defaultModel == model;
    final size = AppStrings.byteSize(switch (state) {
      Downloaded(:final bytes) => bytes,
      _ => model.bytes,
    });

    final leading = switch (state) {
      Downloaded() => Icon(
        isDefault ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isDefault ? colors.primary : null,
      ),
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
                  ? AppStrings.transcriptionModelRetrying
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
          AppStrings.transcriptionModelInterrupted(
            progress(received, total, fraction),
          ),
          style: figures,
        ),
      DownloadFailed() => Text(
        AppStrings.transcriptionModelFailed,
        style: TextStyle(color: colors.error),
      ),
      _ => Text('$size · ${AppStrings.transcriptionModelHint(model)}'),
    };

    final trailing = switch (state) {
      Downloaded() => IconButton(
        key: Key('transcription-delete-${model.id}'),
        tooltip: AppStrings.actionDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => unawaited(_confirmDelete(context, size)),
      ),
      Downloading() => IconButton(
        key: Key('transcription-cancel-${model.id}'),
        tooltip: AppStrings.actionCancel,
        icon: const Icon(Icons.close),
        onPressed: () => unawaited(models.cancel(model)),
      ),
      DownloadFailed(:final resumable) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resumable)
            IconButton(
              key: Key('transcription-discard-${model.id}'),
              tooltip: AppStrings.actionCancel,
              icon: const Icon(Icons.close),
              onPressed: () => unawaited(models.cancel(model)),
            ),
          TextButton(
            key: Key('transcription-retry-${model.id}'),
            onPressed: () => unawaited(models.download(model)),
            child: Text(
              resumable ? AppStrings.actionResume : AppStrings.actionRetry,
            ),
          ),
        ],
      ),
      NotDownloaded() => IconButton(
        key: Key('transcription-download-${model.id}'),
        tooltip: AppStrings.transcriptionModelDownload,
        icon: const Icon(Icons.download),
        onPressed: () => unawaited(models.download(model)),
      ),
    };

    return ListTile(
      leading: leading,
      title: Row(
        children: [
          Flexible(child: Text(AppStrings.transcriptionModelName(model))),
          if (isDefault)
            _Badge(
              AppStrings.transcriptionModelDefault,
              background: colors.primaryContainer,
              foreground: colors.onPrimaryContainer,
            ),
          if (models.phone && model.slowOnPhones)
            _Badge(
              AppStrings.transcriptionModelSlow,
              background: colors.tertiaryContainer,
              foreground: colors.onTertiaryContainer,
            ),
        ],
      ),
      subtitle: subtitle,
      trailing: trailing,
      onTap: state is Downloaded && !isDefault
          ? () => unawaited(models.setDefault(model))
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, String size) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.transcriptionModelDeleteTitle(
            AppStrings.transcriptionModelName(model),
          ),
        ),
        content: Text(AppStrings.transcriptionModelDeleteBody(size)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('transcription-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await models.delete(model);
  }
}

final class _Badge extends StatelessWidget {
  const new(this.label, {required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
