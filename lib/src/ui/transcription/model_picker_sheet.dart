import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';

/// Asks which model to download for the first transcription, returning
/// it (already the default) or null when dismissed.
///
/// Shown only when no model is downloaded: the offered models with their
/// size and trade-off, base preselected, the recordings' language, and
/// one button that starts the download.
Future<TranscriptionModel?> showModelPickerSheet(
  BuildContext context,
  TranscriptionModels models,
) async {
  final picked = await showModalBottomSheet<TranscriptionModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ModelPicker(models: models),
  );
  if (picked != null) await models.setDefault(picked);
  return picked;
}

final class _ModelPicker extends StatefulWidget {
  const new({required this.models});

  final TranscriptionModels models;

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

final class _ModelPickerState extends State<_ModelPicker> {
  late TranscriptionModel _selected =
      transcriptionModelById(widget.models.settings.modelId) ??
      transcriptionModelById('base')!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final models = widget.models;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ListenableBuilder(
          listenable: models,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.transcriptionPickModelTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.transcriptionPickModelBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final model in models.models)
                ListTile(
                  key: Key('transcription-pick-${model.id}'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  selected: model == _selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selectedTileColor: colors.secondaryContainer,
                  leading: Icon(
                    model == _selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppStrings.transcriptionModelName(model)),
                      if (model.id == 'base')
                        _Tag(
                          AppStrings.transcriptionModelRecommended,
                          background: colors.primaryContainer,
                          foreground: colors.onPrimaryContainer,
                        ),
                      if (models.phone && model.slowOnPhones)
                        _Tag(
                          AppStrings.transcriptionModelSlow,
                          background: colors.tertiaryContainer,
                          foreground: colors.onTertiaryContainer,
                        ),
                    ],
                  ),
                  subtitle: Text(AppStrings.transcriptionModelHint(model)),
                  trailing: Text(
                    AppStrings.byteSize(model.bytes),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: () => setState(() => _selected = model),
                ),
              const Divider(height: 24),
              ListTile(
                key: const Key('transcription-pick-language'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.language),
                title: Text(AppStrings.transcriptionLanguageTitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TranscriptionSettingsSection.languageLabel(
                        models.settings.language,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () =>
                    unawaited(chooseTranscriptionLanguage(context, models)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('transcription-pick-confirm'),
                icon: const Icon(Icons.download),
                label: Text(AppStrings.transcriptionPickModelAction),
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Tag extends StatelessWidget {
  const new(this.label, {required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}
