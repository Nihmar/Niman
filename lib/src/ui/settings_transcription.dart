import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';

/// The Transcription area of the settings home (issue #104): the default
/// model and the recordings' language.
///
/// App-wide, like the models it points at, but under the library group:
/// that is where the voice notes it transcribes live.
final class SettingsTranscriptionScreen extends StatelessWidget {
  /// Creates the screen over the installation's [models].
  const new({required this.controller, required this.models, super.key});

  /// The session the screen's library name comes from.
  final LibrarySession controller;

  /// The installation's transcription models and settings.
  final TranscriptionModels models;

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsSectionTranscription,
      controller: controller,
      library: true,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [TranscriptionSettingsSection(models: models)],
      ),
    );
  }
}
