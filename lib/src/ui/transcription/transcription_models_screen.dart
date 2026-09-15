import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/transcription_model_row.dart';

/// Settings → Transcription → Model: the models on this device, grouped
/// by what can be done with them.
///
/// Downloaded models pick the default (tap the row) and can be deleted;
/// downloads show their progress and can be cancelled; the rest can be
/// downloaded. A download outlives the page: the state lives in
/// [TranscriptionModels].
final class TranscriptionModelsScreen extends StatefulWidget {
  /// Creates the page over the installation's [models].
  const new({required this.models, super.key});

  /// The installation's transcription models.
  final TranscriptionModels models;

  @override
  State<TranscriptionModelsScreen> createState() =>
      _TranscriptionModelsScreenState();
}

final class _TranscriptionModelsScreenState
    extends State<TranscriptionModelsScreen> {
  @override
  void initState() {
    super.initState();
    // Pick up files added or removed while the page was closed.
    unawaited(widget.models.load());
  }

  @override
  Widget build(BuildContext context) {
    final models = widget.models;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.transcriptionModelsTitle)),
      body: ListenableBuilder(
        listenable: models,
        builder: (context, _) {
          if (!models.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final installed = <TranscriptionModel>[];
          final downloading = <TranscriptionModel>[];
          final available = <TranscriptionModel>[];
          for (final model in models.models) {
            switch (models.stateOf(model)) {
              case ModelInstalled():
                installed.add(model);
              case ModelDownloading():
                downloading.add(model);
              case ModelAbsent() || ModelFailed():
                available.add(model);
            }
          }
          Widget rows(List<TranscriptionModel> group) => Column(
            children: [
              for (final model in group)
                TranscriptionModelRow(
                  key: Key('transcription-model-${model.id}'),
                  model: model,
                  models: models,
                ),
            ],
          );
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              ListTile(
                key: const Key('transcription-models-storage'),
                leading: const Icon(Icons.sd_storage_outlined),
                title: Text(
                  AppStrings.transcriptionModelsUsed(
                    AppStrings.byteSize(models.installedBytes),
                  ),
                ),
              ),
              if (installed.isNotEmpty) ...[
                SettingsSection(AppStrings.transcriptionModelsInstalled),
                rows(installed),
              ],
              if (downloading.isNotEmpty) ...[
                SettingsSection(AppStrings.transcriptionModelsDownloading),
                rows(downloading),
              ],
              if (available.isNotEmpty) ...[
                SettingsSection(AppStrings.transcriptionModelsAvailable),
                rows(available),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.transcriptionModelsFooter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
