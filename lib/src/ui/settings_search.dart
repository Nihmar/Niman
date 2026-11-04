import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/settings_area_features.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_search_appearance.dart';
import 'package:niman/src/ui/settings_search_diagnostics.dart';
import 'package:niman/src/ui/settings_search_editor.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_library.dart';
import 'package:niman/src/ui/settings_search_maintenance.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/settings_search_services.dart';
import 'package:niman/src/ui/settings_search_shortcuts.dart';

export 'package:niman/src/ui/settings_search_entry.dart';
export 'package:niman/src/ui/settings_search_match.dart';

/// Every row the settings search can find (issue #104).
///
/// Titles and areas are localized at build time; values load on demand
/// for the matches only.
List<SettingsSearchEntry> settingsSearchEntries({
  required LibrarySession controller,
  required TranscriptionModels? transcription,
  required EditorSpellCheck? spellCheck,
  required String libraryName,
  required BuildContext context,
  required void Function(Key rowKey) flashHome,
  required void Function(SettingsAreaId area, Key rowKey) openArea,
  bool keyboardAttached = true,
  bool libraryRows = true,
  OcrInstallation? ocr,
}) {
  void push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (context) => screen));

  final scope = SettingsSearchScope(
    controller: controller,
    libraryName: libraryName,
    push: push,
    flashHome: flashHome,
    openArea: openArea,
  );
  final entries = <SettingsSearchEntry>[
    ...appearanceSearchEntries(scope),
    ...editorSearchEntries(scope),
    ...librarySearchEntries(scope),
    ...diagnosticsSearchEntries(scope),
    ...serviceSearchEntries(scope, ocr: ocr, transcription: transcription),
    ...maintenanceSearchEntries(scope, libraryRows: libraryRows),
  ];
  final titles = {for (final entry in entries) entry.title};
  final all = <SettingsSearchEntry>[
    ...entries,
    ...shortcutSearchEntries(
      scope,
      titles: titles,
      keyboardAttached: keyboardAttached,
    ),
  ];
  // A row of an area whose feature is off is not found (#1109): the area is
  // not listed either.
  final features = controller.features.value;
  return [
    for (final entry in all)
      if (entry.areaId case final area? when !areaShown(area, features))
        ...const <SettingsSearchEntry>[]
      else
        entry,
  ];
}
