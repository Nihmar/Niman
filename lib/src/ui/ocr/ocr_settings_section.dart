import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_language_catalog.dart';
import 'package:niman/src/ui/download_tile.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The engine and the choices of the Text recognition settings (#593):
/// where the engine comes from, the models' quality, the default language
/// and the one read "Also". The languages themselves are
/// `OcrLanguageList`.
final class OcrSettingsSection extends StatelessWidget {
  /// Creates the section over [installation].
  const new({required this.installation, super.key});

  /// What is installed for OCR on this device.
  final OcrInstallation installation;

  @override
  Widget build(BuildContext context) {
    final settings = installation.settings;
    final also = installation.alsoLanguage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(AppStrings.ocrEngineTitle),
        _engine(),
        const SizedBox(height: 8),
        HighlightRow(
          key: SettingsKeys.ocrQuality,
          child: SettingsRowFrame(
            title: AppStrings.ocrQualityTitle,
            description: AppStrings.ocrQualityHint,
            control: SegmentedButton<OcrQuality>(
              segments: [
                for (final quality in OcrQuality.values)
                  ButtonSegment(
                    value: quality,
                    label: Text(ocrQualityLabel(quality)),
                  ),
              ],
              selected: {settings.quality},
              onSelectionChanged: (choice) =>
                  unawaited(installation.setQuality(choice.single)),
            ),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.ocrLanguage,
          child: SettingsValueRow(
            title: AppStrings.ocrLanguageTitle,
            value: installation.defaultLanguage().native,
            onTap: () => unawaited(_chooseLanguage(context)),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.ocrAlso,
          child: SettingsValueRow(
            title: AppStrings.ocrAlsoTitle,
            subtitle: AppStrings.ocrAlsoSubtitle,
            value: also?.native ?? AppStrings.ocrAlsoNone,
            onTap: () => unawaited(_chooseAlso(context)),
          ),
        ),
      ],
    );
  }

  Widget _engine() {
    final engine = installation.engine;
    final build = installation.build;
    if (engine != null && engine.source != OcrEngineSource.downloaded) {
      return ListTile(
        key: const Key('ocr-engine-installed'),
        leading: const Icon(Icons.memory_outlined),
        title: Text(AppStrings.ocrEngineName(engine.version)),
        subtitle: Text(
          engine.source == OcrEngineSource.system
              ? AppStrings.ocrEngineSystem
              : AppStrings.ocrEngineBundled,
        ),
      );
    }
    if (build == null) {
      return ListTile(
        key: const Key('ocr-engine-unavailable'),
        leading: const Icon(Icons.block),
        title: Text(AppStrings.ocrEngineUnavailable),
      );
    }
    return DownloadTile(
      id: build.id,
      keyPrefix: 'ocr',
      state: installation.stateOf(build),
      bytes: build.bytes,
      installedLeading: const Icon(Icons.memory_outlined),
      title: Text(AppStrings.ocrEngineName(OcrEngineBuild.version)),
      idle: AppStrings.byteSize(build.bytes),
      deleteTitle: AppStrings.ocrEngineDeleteTitle,
      deleteBody: AppStrings.ocrDeleteBody,
      onDownload: () => unawaited(installation.download(build)),
      onCancel: () => unawaited(installation.cancel(build)),
      onDelete: () => installation.delete(build),
    );
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final choice = await showSettingsChoice<OcrLanguage>(
      context,
      title: AppStrings.ocrLanguageTitle,
      current: installation.defaultLanguage(),
      options: [
        for (final language in _byName)
          SettingsOption(language, language.native),
      ],
    );
    if (choice != null) await installation.setLanguage(choice);
  }

  Future<void> _chooseAlso(BuildContext context) async {
    // Codes, with '' for none: the dialog answers null when dismissed.
    final choice = await showSettingsChoice<String>(
      context,
      title: AppStrings.ocrAlsoTitle,
      subtitle: AppStrings.ocrAlsoSubtitle,
      current: installation.alsoLanguage()?.code ?? '',
      options: [
        SettingsOption('', AppStrings.ocrAlsoNone),
        for (final language in _byName)
          if (language != installation.defaultLanguage())
            SettingsOption(language.code, language.native),
      ],
    );
    if (choice != null) await installation.setAlso(ocrLanguageByCode(choice));
  }
}

/// The catalog by native name.
final List<OcrLanguage> _byName = [...ocrLanguages]
  ..sort((a, b) => a.native.compareTo(b.native));

/// What [quality] is called.
String ocrQualityLabel(OcrQuality quality) => switch (quality) {
  OcrQuality.fast => AppStrings.ocrQualityFast,
  OcrQuality.best => AppStrings.ocrQualityBest,
};
