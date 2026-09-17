/// The preview's own controls (issue #100, split out of `shell.dart`):
/// the eye that flips editor and preview, the picker for how the two
/// share the window, and the way back out of a full-screen preview.
///
/// One file for the three of them because they are one control surface:
/// what the preview is doing, said in the three places the layouts have
/// room for it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/strings.dart';

/// The app-bar eye action: flips the editor/preview pane (phone
/// full-screen note and the wide switch override).
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

/// The split/switch picker (user, 2026-09-09): how the preview shares
/// the window is an editor control, not a settings-screen row. Wide
/// only — below 600 dp the panes cannot share the screen, so there is
/// nothing to choose.
final class PreviewLayoutModeAction extends StatelessWidget {
  /// Creates the picker showing [mode] as the checked one.
  const new({
    required this.mode,
    required this.onSelected,
    this.compact = false,
    super.key,
  });

  /// The library's current layout override.
  final PreviewLayoutMode mode;

  /// Reports the chosen mode; the shell persists it.
  final ValueChanged<PreviewLayoutMode> onSelected;

  /// Whether the action sits in a tight row (the editor header).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PreviewLayoutMode>(
      key: const Key('layout-mode'),
      tooltip: AppStrings.previewModeTitle,
      icon: Icon(Icons.splitscreen, size: compact ? 18 : null),
      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
      onSelected: onSelected,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: PreviewLayoutMode.auto,
          checked: mode == PreviewLayoutMode.auto,
          child: Text(AppStrings.previewModeAuto),
        ),
        CheckedPopupMenuItem(
          value: PreviewLayoutMode.fullScreen,
          checked: mode == PreviewLayoutMode.fullScreen,
          child: Text(AppStrings.previewModeSwitch),
        ),
      ],
    );
  }
}

/// The way back out of a full-screen preview, floating over it.
///
/// The chrome that would normally carry this action is exactly what is
/// hidden, so the button rides above the content instead — inside the
/// safe area, so a notch or a rounded corner never eats it.
final class ExitFullScreenButton extends StatelessWidget {
  /// Creates the button; [onExit] leaves full screen.
  const new({required this.onExit, super.key});

  /// Leaves the full-screen preview.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            type: MaterialType.circle,
            color: Theme.of(context).colorScheme.surface
                .withValues(alpha: 0.85),
            elevation: 2,
            child: IconButton(
              key: const Key('preview-fullscreen-exit'),
              tooltip: AppStrings.exitFullScreenTooltip,
              icon: const Icon(Icons.fullscreen_exit),
              onPressed: onExit,
            ),
          ),
        ),
      ),
    );
  }
}
