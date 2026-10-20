/// Which feature a settings area belongs to (#1109): the area of a feature
/// that is off is not listed, and the settings search does not find its
/// rows.
library;

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/settings_areas.dart';

/// The feature [area] belongs to, or null for one that is core — or, for
/// Reminders, for one that waits on two: see [areaShown].
LibraryFeature? featureOfArea(SettingsAreaId area) => switch (area) {
  SettingsAreaId.journal => LibraryFeature.journal,
  SettingsAreaId.study => LibraryFeature.kindFlashcards,
  SettingsAreaId.transcription => LibraryFeature.transcription,
  SettingsAreaId.textRecognition => LibraryFeature.ocr,
  SettingsAreaId.appearance ||
  SettingsAreaId.themes ||
  SettingsAreaId.editor ||
  SettingsAreaId.shortcuts ||
  SettingsAreaId.commands ||
  SettingsAreaId.updates ||
  SettingsAreaId.diagnostics ||
  // Always listed: it is where the switches are (#1109).
  SettingsAreaId.features ||
  SettingsAreaId.folders ||
  SettingsAreaId.navigation ||
  SettingsAreaId.trashHistory ||
  SettingsAreaId.sync ||
  // Serves both todo and the calendar: see [areaShown].
  SettingsAreaId.reminders => null,
};

/// Whether the settings list [area] with [features] as they are: the
/// feature's, and for Reminders either of the two it serves.
bool areaShown(SettingsAreaId area, Features features) => switch (area) {
  SettingsAreaId.reminders =>
    features.isOn(LibraryFeature.todo) ||
        features.isOn(LibraryFeature.calendar),
  _ => switch (featureOfArea(area)) {
    final feature? => features.isOn(feature),
    null => true,
  },
};
