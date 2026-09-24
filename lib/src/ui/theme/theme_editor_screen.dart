// The editor for a theme of the user's own (issue #269).
//
// Every role the theme fills in, at the brightness being edited, with the
// app wearing the colors as they move: the draft is what the whole
// interface wears while this screen is open, so a color is chosen by
// seeing it in place rather than by reading it. Save stores it; leaving
// without saving — the back gesture included — puts back what was
// stored.
//
// The brightness being edited is also the brightness on screen: editing
// the night side of a theme in daylight would be editing blind, so the
// preview follows, and the user's own choice comes back on the way out.

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/color_picker_dialog.dart';

/// Edits [theme] and, on Save, stores it; the saved theme, or null when
/// nothing was saved.
final class ThemeEditorScreen extends StatefulWidget {
  /// Creates the editor for [theme] in [controller]'s session.
  const new({required this.controller, required this.theme, super.key});

  /// The session the theme is stored in.
  final LibrarySession controller;

  /// The theme as it was when the editor opened.
  final CustomTheme theme;

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

final class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late CustomTheme _theme = widget.theme;

  /// The brightness the user had chosen, to be put back on the way out.
  late final AppBrightness _chosenBrightness;

  /// Which side of the theme is being edited, and worn as a preview.
  late Brightness _side;

  @override
  void initState() {
    super.initState();
    // Both read before the preview moves anything: a `late` field is
    // evaluated on first read, and a first read *after* the preview would
    // remember the preview's own brightness.
    _chosenBrightness = AppThemes.brightness;
    _side = switch (_chosenBrightness) {
      AppBrightness.day => Brightness.light,
      AppBrightness.night => Brightness.dark,
      AppBrightness.system => PlatformDispatcher.instance.platformBrightness,
    };
    _previewDraft();
  }

  /// What is on screen right now: the theme being edited, at the side
  /// being edited.
  ThemeColors get _colors =>
      _side == Brightness.dark ? _theme.night : _theme.day;

  bool get _changed => _theme != widget.theme;

  void _previewDraft() {
    AppThemes.brightness = _side == Brightness.dark
        ? AppBrightness.night
        : AppBrightness.day;
    AppThemes.setDraft(CustomAppTheme(_theme));
  }

  /// Leaves the preview as it was found: what is stored, at the user's
  /// own brightness.
  void _endPreview() {
    AppThemes.setDraft(null);
    AppThemes.brightness = _chosenBrightness;
  }

  void _chooseSide(Brightness side) {
    setState(() => _side = side);
    _previewDraft();
  }

  Future<void> _editRole(String role) async {
    final current = _colors.colorOf(role) ?? const Color(0xFF000000);
    final chosen = await showColorPickerDialog(
      context,
      title: role,
      initial: current,
    );
    if (chosen == null || !mounted) return;
    final updated = _colors.withRole(role, chosen);
    setState(() {
      _theme = _side == Brightness.dark
          ? _theme.copyWith(night: updated)
          : _theme.copyWith(day: updated);
    });
    _previewDraft();
  }

  Future<void> _save() async {
    await widget.controller.saveCustomTheme(_theme);
    if (!mounted) return;
    _endPreview();
    Navigator.pop(context, _theme);
  }

  /// Leaves without saving; asks first when something was moved.
  Future<void> _discard() async {
    if (_changed) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.themeEditorDiscardTitle),
          content: Text(AppStrings.themeEditorDiscardBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.themeEditorDiscard),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    _endPreview();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Every way out goes through [_discard]: leaving with the back
    // gesture has to put the preview back even when nothing was moved.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_discard());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.themeEditorTitle),
              Text(
                _theme.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const Key('theme-editor-save'),
              tooltip: AppStrings.actionSave,
              icon: const Icon(Icons.check),
              onPressed: () => unawaited(_save()),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SegmentedButton<Brightness>(
                segments: [
                  ButtonSegment(
                    value: Brightness.light,
                    label: Text(AppStrings.themeBrightnessDay),
                  ),
                  ButtonSegment(
                    value: Brightness.dark,
                    label: Text(AppStrings.themeBrightnessNight),
                  ),
                ],
                selected: {_side},
                onSelectionChanged: (sides) => _chooseSide(sides.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                AppStrings.themeEditorRolesHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SettingsSection(AppStrings.themeEditorChrome),
            for (final role in ThemeColors.chromeRoles)
              _RoleRow(
                key: Key('theme-role-$role'),
                role: role,
                color: _colors.colorOf(role)!,
                onTap: () => unawaited(_editRole(role)),
              ),
            SettingsSection(AppStrings.themeEditorMarkdown),
            for (final role in ThemeColors.markdownRoles)
              if (!ThemeColors.taskListRoles.contains(role))
                _RoleRow(
                  key: Key('theme-role-$role'),
                  role: role,
                  color: _colors.colorOf(role)!,
                  onTap: () => unawaited(_editRole(role)),
                ),
            // A task list is Markdown's neighbour, not part of a note: its
            // roles are the last of the Markdown ones, under their own
            // heading so they are found where a task list is thought of.
            SettingsSection(AppStrings.themeEditorTaskLists),
            for (final role in ThemeColors.taskListRoles)
              _RoleRow(
                key: Key('theme-role-$role'),
                role: role,
                color: _colors.colorOf(role)!,
                onTap: () => unawaited(_editRole(role)),
              ),
          ],
        ),
      ),
    );
  }
}

/// One color a theme fills in: its name — the one the exported file uses —
/// and the color itself, tapped to change it.
final class _RoleRow extends StatelessWidget {
  const new({
    required this.role,
    required this.color,
    required this.onTap,
    super.key,
  });

  /// The role's name in the theme file.
  final String role;

  /// What it holds right now.
  final Color color;

  /// Opens the picker.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(role),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            colorToHex(color),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }
}
