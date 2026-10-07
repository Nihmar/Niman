import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ui/ocr/ocr_language_list.dart';
import 'package:niman/src/ui/ocr/ocr_settings_section.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/strings.dart';

/// The Text recognition area of the settings (#593): what recognition
/// does, the engine, the quality, the languages. The same page on the
/// desktop and the phone; app-wide, like the data it lists.
final class SettingsTextRecognitionScreen extends StatelessWidget {
  /// Creates the screen over [installation].
  const new({
    required this.controller,
    required this.installation,
    this.highlight,
    super.key,
  });

  /// The session the area frame reads.
  final LibrarySession controller;

  /// What is installed for OCR on this device.
  final OcrInstallation installation;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsAreaShell(
      title: AppStrings.settingsSectionTextRecognition,
      controller: controller,
      highlight: highlight,
      body: ListenableBuilder(
        listenable: installation,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                AppStrings.ocrIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            OcrSettingsSection(installation: installation),
            OcrLanguageList(installation: installation),
          ],
        ),
      ),
    );
  }
}
