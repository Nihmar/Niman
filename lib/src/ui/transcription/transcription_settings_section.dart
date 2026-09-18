import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/transcription_models_screen.dart';

/// The "Transcription" rows of the settings: the default model
/// (opening the models page) and the recordings' language.
///
/// The area screen carries the title; this is just the rows.
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
            HighlightRow(
              key: SettingsKeys.transcriptionModel,
              child: SettingsValueRow(
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
            ),
            HighlightRow(
              key: SettingsKeys.transcriptionLanguage,
              child: SettingsValueRow(
                title: AppStrings.transcriptionLanguageTitle,
                value: languageLabel(models.settings.language),
                onTap: () =>
                    unawaited(chooseTranscriptionLanguage(context, models)),
              ),
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
}

/// Asks for the recordings' language and stores it in [models]; shared
/// by the settings row and the model sheet of the first transcription.
Future<void> chooseTranscriptionLanguage(
  BuildContext context,
  TranscriptionModels models,
) async {
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
        SettingsOption(
          value,
          TranscriptionSettingsSection.languageLabel(value),
        ),
    ],
  );
  if (choice != null) await models.setLanguage(choice);
}
