import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_navigation.dart';
import 'package:niman/src/ui/settings_section_pane.dart';

/// The Settings tab: the settings list without its own Scaffold — the
/// shell provides the app bar.
///
/// Wide (issue #172), it is two columns: the search and the areas on the
/// left, the selected area on the right — a window with room for both
/// shows them both, instead of navigating from one to the other. Narrow,
/// it is the phone's list, whose areas open as screens of their own.
final class SettingsTab extends StatefulWidget {
  /// Creates the settings tab.
  const new({
    required this.controller,
    this.spellCheck,
    this.transcription,
    super.key,
  });

  /// The session of the library whose settings this tab edits.
  final LibrarySession controller;

  /// The editor's spelling state (T-PP-09), for its toggle; null hides it.
  final EditorSpellCheck? spellCheck;

  /// The installation's transcription models; null hides their section.
  final TranscriptionModels? transcription;

  /// The left column's width: the areas' names and the search, no more.
  static const double listWidth = 280;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

final class _SettingsTabState extends State<SettingsTab> {
  final SettingsNavigation _navigation = SettingsNavigation();

  @override
  void dispose() {
    _navigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < splitBreakpoint) {
          return SettingsBody(
            controller: widget.controller,
            spellCheck: widget.spellCheck,
            transcription: widget.transcription,
          );
        }
        return Row(
          children: [
            SizedBox(
              width: SettingsTab.listWidth,
              child: SettingsBody(
                controller: widget.controller,
                spellCheck: widget.spellCheck,
                transcription: widget.transcription,
                navigation: _navigation,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: SettingsSectionPane(
                navigation: _navigation,
                areas: () => settingsAreas(
                  controller: widget.controller,
                  spellCheck: widget.spellCheck,
                  transcription: widget.transcription,
                  keyboardAttached: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
