import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/download_tile.dart';
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
    final colors = Theme.of(context).colorScheme;
    final state = models.stateOf(model);
    final isDefault = models.defaultModel == model;
    return DownloadTile(
      id: model.id,
      keyPrefix: 'transcription',
      state: state,
      bytes: model.bytes,
      installedLeading: Icon(
        isDefault ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isDefault ? colors.primary : null,
      ),
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
      idle:
          '${AppStrings.byteSize(model.bytes)} · '
          '${AppStrings.transcriptionModelHint(model)}',
      deleteTitle: AppStrings.transcriptionModelDeleteTitle(
        AppStrings.transcriptionModelName(model),
      ),
      deleteBody: AppStrings.transcriptionModelDeleteBody,
      onDownload: () => unawaited(models.download(model)),
      onCancel: () => unawaited(models.cancel(model)),
      onDelete: () => models.delete(model),
      onTap: state is Downloaded && !isDefault
          ? () => unawaited(models.setDefault(model))
          : null,
    );
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
