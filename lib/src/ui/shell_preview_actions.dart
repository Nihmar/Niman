/// The preview's own control (issue #100, split out of `shell.dart`):
/// the eye that flips the note between its editor and its preview.
///
/// One file for one control: it lived here with the picker for how the
/// two shared the window and the way out of a full-screen preview, and
/// both went with the split — the note is one pane, so the eye is all
/// there is to say about it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The app-bar eye action: flips the editor and the preview in the note's
/// one pane (the phone's app bar and the wide layout's status row).
final class PreviewToggleAction extends StatelessWidget {
  /// Creates the action; [previewVisible] decides which way it points.
  const new({
    required this.previewVisible,
    required this.onToggle,
    this.compact = false,
    super.key,
  });

  /// Whether the preview is the pane on screen.
  final bool previewVisible;

  /// Flips the pane.
  final VoidCallback onToggle;

  /// Whether the action sits in a tight row (the editor header).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('editor-preview-toggle'),
      tooltip: previewVisible
          ? AppStrings.showEditorTooltip
          : AppStrings.showPreviewTooltip,
      icon: Icon(previewVisible ? Icons.edit : Icons.visibility),
      iconSize: compact ? 18 : null,
      visualDensity: compact ? VisualDensity.compact : null,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact
          ? const BoxConstraints(minWidth: 34, minHeight: 26)
          : null,
      onPressed: onToggle,
    );
  }
}
