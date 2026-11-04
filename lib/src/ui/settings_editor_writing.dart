import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's writing switches: typewriter mode (#70), the
/// cascading checklist (#326), link previews (#846), the properties panel
/// (#157) and, on a phone or a tablet, the keyboard on opening a note.
final class SettingsEditorWriting extends StatelessWidget {
  /// Creates the switches for their current values.
  const new({
    required this.typewriter,
    required this.cascadeChecklist,
    required this.linkPreview,
    required this.frontmatterPanel,
    required this.autofocusEditor,
    required this.onTypewriter,
    required this.onCascadeChecklist,
    required this.onLinkPreview,
    required this.onFrontmatterPanel,
    required this.onAutofocusEditor,
    super.key,
  });

  /// Whether the line being written stays in the middle of the editor.
  final bool typewriter;

  /// Whether ticking a checklist item ticks the ones nested under it.
  final bool cascadeChecklist;

  /// Whether a link shows what it points at.
  final bool linkPreview;

  /// Whether a note's properties show in a panel above it.
  final bool frontmatterPanel;

  /// Whether opening a note brings up the keyboard; null until read.
  final bool? autofocusEditor;

  /// Persists typewriter mode.
  final ValueChanged<bool> onTypewriter;

  /// Persists the cascading checklist.
  final ValueChanged<bool> onCascadeChecklist;

  /// Persists link previews.
  final ValueChanged<bool> onLinkPreview;

  /// Persists the properties panel.
  final ValueChanged<bool> onFrontmatterPanel;

  /// Persists the keyboard on opening a note.
  final ValueChanged<bool> onAutofocusEditor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightRow(
          key: SettingsKeys.typewriter,
          child: SettingsSwitchRow(
            title: AppStrings.typewriterTitle,
            description: AppStrings.typewriterSubtitle,
            value: typewriter,
            onChanged: onTypewriter,
          ),
        ),
        HighlightRow(
          key: SettingsKeys.cascadeChecklist,
          child: SettingsSwitchRow(
            title: AppStrings.cascadeChecklistTitle,
            description: AppStrings.cascadeChecklistSubtitle,
            value: cascadeChecklist,
            onChanged: onCascadeChecklist,
          ),
        ),
        HighlightRow(
          key: SettingsKeys.linkPreview,
          child: SettingsSwitchRow(
            title: AppStrings.linkPreviewTitle,
            description: AppStrings.linkPreviewSubtitle,
            value: linkPreview,
            onChanged: onLinkPreview,
          ),
        ),
        HighlightRow(
          key: SettingsKeys.frontmatterPanel,
          child: SettingsSwitchRow(
            title: AppStrings.frontmatterPanelTitle,
            description: AppStrings.frontmatterPanelSubtitle,
            value: frontmatterPanel,
            onChanged: onFrontmatterPanel,
          ),
        ),
        // Phones and tablets only: there is no on-screen keyboard to
        // show on desktop, so the row would toggle a no-op (user,
        // 2026-09-09).
        if (Platform.isAndroid || Platform.isIOS)
          SettingsSwitchRow(
            title: AppStrings.keyboardOnOpenTitle,
            description: AppStrings.keyboardOnOpenSubtitle,
            value: autofocusEditor ?? false,
            onChanged: onAutofocusEditor,
          ),
      ],
    );
  }
}
