import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/transcription_models_screen.dart';

/// The "Transcription" group of the settings list: the default model
/// (opening the models page) and the recordings' language.
final class TranscriptionSettingsSection extends StatelessWidget {
  /// Creates the section over the installation's [models].
  const new({required this.models, super.key});

  /// The installation's transcription models and settings.
  final TranscriptionModels models;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: models,
      builder: (context, _) {
        final model = models.defaultModel;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(AppStrings.settingsSectionTranscription),
            SettingsValueRow(
              key: const Key('transcription-model-setting'),
              title: AppStrings.transcriptionModelTitle,
              value: model == null
                  ? AppStrings.transcriptionModelNone
                  : AppStrings.transcriptionModelName(model),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) =>
                      TranscriptionModelsScreen(models: models),
                ),
              ),
            ),
            SettingsValueRow(
              key: const Key('transcription-language-setting'),
              title: AppStrings.transcriptionLanguageTitle,
              value: languageLabel(models.settings.language),
              onTap: () => unawaited(_chooseLanguage(context)),
            ),
          ],
        );
      },
    );
  }

  /// What a stored language value reads as.
  static String languageLabel(String language) => switch (language) {
    TranscriptionSettings.followApp => AppStrings.transcriptionLanguageApp(
      AppStrings.languageName(AppLanguages.resolved),
    ),
    TranscriptionSettings.detect => AppStrings.transcriptionLanguageDetect,
    _ => AppStrings.languageName(AppLanguage.fromId(language)),
  };

  Future<void> _chooseLanguage(BuildContext context) async {
    final choice = await showSettingsChoice<String>(
      context,
      title: AppStrings.transcriptionLanguageTitle,
      subtitle: AppStrings.transcriptionLanguageSubtitle,
      current: models.settings.language,
      options: [
        for (final value in [
          TranscriptionSettings.followApp,
          TranscriptionSettings.detect,
          for (final language in AppLanguages.supported) language.id,
        ])
          SettingsOption(value, languageLabel(value)),
      ],
    );
    if (choice != null) await models.setLanguage(choice);
  }
}
