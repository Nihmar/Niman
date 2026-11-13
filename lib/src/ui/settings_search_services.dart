import 'package:flutter/widgets.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/ocr/ocr_settings_section.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';

/// The settings search's rows of Reminders, Text recognition,
/// Transcription and Sync (#104), in the order the search lists them:
/// text recognition's only with an [ocr], transcription's only with
/// [transcription] models, and sync's only when the library syncs.
List<SettingsSearchEntry> serviceSearchEntries(
  SettingsSearchScope scope, {
  required OcrInstallation? ocr,
  required TranscriptionModels? transcription,
}) {
  final controller = scope.controller;
  return [
    SettingsSearchEntry(
      title: AppStrings.reminderShowTokensTitle,
      area: scope.libraryArea(AppStrings.settingsSectionReminders),
      rowKey: SettingsKeys.reminderShowTokens,
      value: () async =>
          scope.onOff(on: await controller.librarySettings.reminderShowTokens),
      areaId: SettingsAreaId.reminders,
      open: () => scope.openArea(
        SettingsAreaId.reminders,
        SettingsKeys.reminderShowTokens,
      ),
    ),
    if (ocr case final ocr?) ...[
      SettingsSearchEntry(
        title: AppStrings.ocrQualityTitle,
        area: AppStrings.settingsSectionTextRecognition,
        rowKey: SettingsKeys.ocrQuality,
        value: () async => ocrQualityLabel(ocr.settings.quality),
        areaId: SettingsAreaId.textRecognition,
        open: () => scope.openArea(
          SettingsAreaId.textRecognition,
          SettingsKeys.ocrQuality,
        ),
      ),
      SettingsSearchEntry(
        title: AppStrings.ocrLanguageTitle,
        area: AppStrings.settingsSectionTextRecognition,
        rowKey: SettingsKeys.ocrLanguage,
        value: () async => ocr.defaultLanguage().native,
        areaId: SettingsAreaId.textRecognition,
        open: () => scope.openArea(
          SettingsAreaId.textRecognition,
          SettingsKeys.ocrLanguage,
        ),
      ),
      SettingsSearchEntry(
        title: AppStrings.ocrAlsoTitle,
        area: AppStrings.settingsSectionTextRecognition,
        rowKey: SettingsKeys.ocrAlso,
        value: () async => ocr.alsoLanguage()?.native ?? AppStrings.ocrAlsoNone,
        areaId: SettingsAreaId.textRecognition,
        open: () => scope.openArea(
          SettingsAreaId.textRecognition,
          SettingsKeys.ocrAlso,
        ),
      ),
    ],
    if (transcription case final models?) ...[
      SettingsSearchEntry(
        title: AppStrings.transcriptionModelTitle,
        area: scope.libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: SettingsKeys.transcriptionModel,
        value: () async {
          final model = models.defaultModel;
          return model == null
              ? AppStrings.transcriptionModelNone
              : AppStrings.transcriptionModelName(model);
        },
        areaId: SettingsAreaId.transcription,
        open: () => scope.openArea(
          SettingsAreaId.transcription,
          SettingsKeys.transcriptionModel,
        ),
      ),
      SettingsSearchEntry(
        title: AppStrings.transcriptionLanguageTitle,
        area: scope.libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: SettingsKeys.transcriptionLanguage,
        value: () async => TranscriptionSettingsSection.languageLabel(
          models.settings.language,
        ),
        open: () => scope.openArea(
          SettingsAreaId.transcription,
          SettingsKeys.transcriptionLanguage,
        ),
      ),
    ],
    if (controller.sync case final sync?)
      SettingsSearchEntry(
        title: AppStrings.settingsSectionSync,
        area: scope.libraryArea(AppStrings.settingsSectionSync),
        rowKey: const Key('settings-area-sync'),
        value: () async => syncStatusLine(sync.status, DateTime.now()),
        areaId: SettingsAreaId.sync,
        open: () => scope.openArea(
          SettingsAreaId.sync,
          const Key('settings-area-sync'),
        ),
      ),
  ];
}
