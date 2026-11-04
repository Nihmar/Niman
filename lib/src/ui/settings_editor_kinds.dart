import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's editor rows (T-WYS-03): which editors the library
/// offers, both or one alone.
///
/// The last one on cannot be switched off (its switch disables itself),
/// so the choice never resolves to no editor.
final class SettingsEditorKinds extends StatelessWidget {
  /// Creates the rows for the [enabledEditors].
  const new({required this.enabledEditors, required this.onToggle, super.key});

  /// The editors the library offers.
  final Set<EditorKind> enabledEditors;

  /// Turns one editor on or off.
  final void Function(EditorKind kind, {required bool enabled}) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightRow(
          key: SettingsKeys.editorSource,
          child: SettingsSwitchRow(
            title: AppStrings.editorKindSource,
            description: AppStrings.editorKindSourceSubtitle,
            value: enabledEditors.contains(EditorKind.source),
            onChanged: _onChanged(EditorKind.source),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.editorWysiwyg,
          child: SettingsSwitchRow(
            title: AppStrings.editorKindWysiwyg,
            description: AppStrings.editorKindWysiwygSubtitle,
            value: enabledEditors.contains(EditorKind.wysiwyg),
            onChanged: _onChanged(EditorKind.wysiwyg),
          ),
        ),
      ],
    );
  }

  /// The switch's callback for [kind]: null, disabling it, when [kind] is
  /// the last editor on.
  ValueChanged<bool>? _onChanged(EditorKind kind) =>
      enabledEditors.length < 2 && enabledEditors.contains(kind)
      ? null
      : (value) => onToggle(kind, enabled: value);
}
