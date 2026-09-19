/// Settings on a wide window (#202): a floating window over the note,
/// instead of a destination that takes the content area from it.
///
/// Inside it is the same two-column [SettingsTab] a wide window used to
/// fill: the areas on the left, the chosen one on the right. The screens
/// an area opens (the keyboard, the toolbar) open inside the window, and
/// Esc steps back out of them before it closes it. The phone keeps
/// Settings as a tab.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/floating_window.dart';
import 'package:niman/src/ui/settings_tab.dart';
import 'package:niman/src/ui/strings.dart';

/// The library's settings as a floating window's route; the caller
/// pushes it, and removes it if the library closes under it.
Route<void> settingsWindowRoute(
  BuildContext context, {
  required LibrarySession controller,
  EditorSpellCheck? spellCheck,
  TranscriptionModels? transcription,
}) {
  return floatingWindowRoute(
    context,
    title: AppStrings.tabSettings,
    panelKey: const Key('settings-window'),
    builder: (context) => SettingsTab(
      controller: controller,
      spellCheck: spellCheck,
      transcription: transcription,
      libraryRows: false,
    ),
  );
}
