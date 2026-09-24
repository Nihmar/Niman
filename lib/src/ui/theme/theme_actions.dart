// What the Themes page can do to a theme (issue #269): make one, copy one,
// edit one, rename one, move one in and out of the app, delete one.
//
// A plain object rather than page code: each of these is a dialog, a
// session call and a reload, and none of them is about what is on screen.
// The page hands the context in per call — a dialog belongs where the user
// is — and [reload] is what it asks for once a theme has changed.

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme_generator.dart';
import 'package:niman/src/core/theme_transfer.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/palettes.dart';
import 'package:niman/src/ui/theme/theme_dialogs.dart';
import 'package:niman/src/ui/theme/theme_editor_screen.dart';
import 'package:niman/src/ui/theme/theme_files.dart';
import 'package:niman/src/ui/theme/theme_row.dart';

/// The actions behind a theme row's menu, and behind *New theme*.
final class ThemeActions {
  /// Creates the actions over [controller]'s session.
  ///
  /// [themes] and [takenNames] are read when a dialog needs them, so what
  /// the list holds right now is what they say; the two file calls are the
  /// system's pickers, and a seam the tests hand their own through.
  new({
    required this.controller,
    required this.reload,
    required this.themes,
    required this.takenNames,
    this.saveThemeFile = saveThemeFileToDisk,
    this.pickThemeFile = pickThemeFileFromDisk,
  });

  /// The session the themes are stored in.
  final LibrarySession controller;

  /// Re-reads what the page shows, after anything that changed it.
  final Future<void> Function() reload;

  /// Every theme the page lists.
  final List<AppTheme> Function() themes;

  /// The names the list already answers to, lowercased.
  final Set<String> Function() takenNames;

  /// Writes an exported theme where the user says.
  final SaveThemeFile saveThemeFile;

  /// Reads an imported theme from where the user says.
  final PickThemeFile pickThemeFile;

  /// Runs what the menu asked for.
  Future<void> act(
    BuildContext context,
    ThemeRowAction action,
    AppTheme theme,
  ) async {
    switch (action) {
      case ThemeRowAction.edit:
        await edit(context, theme);
      case ThemeRowAction.duplicate:
        await duplicate(theme);
      case ThemeRowAction.rename:
        await rename(context, theme);
      case ThemeRowAction.export:
        await export(context, theme);
      case ThemeRowAction.delete:
        await delete(context, theme);
    }
  }

  /// Asks for a new theme, stores it, worn, and opens it in the editor: a
  /// theme is made to be given its own colors, and landing back on the
  /// list left the user to find it and open it again.
  Future<void> newTheme(BuildContext context) async {
    final request = await showNewThemeDialog(
      context,
      sources: [
        for (final theme in themes()) (theme: theme, label: themeLabel(theme)),
      ],
      takenNames: takenNames(),
    );
    if (request == null || !context.mounted) {
      return;
    }
    final from = request.from;
    final theme = from == null
        ? randomCustomTheme(id: newCustomThemeId(), name: request.name)
        : customThemeCopyOf(from, id: newCustomThemeId(), name: request.name);
    await _save(theme);
    if (!context.mounted) {
      return;
    }
    await edit(context, CustomAppTheme(theme));
  }

  /// Copies [theme] into a theme of the user's own, named after it.
  Future<void> duplicate(AppTheme theme) async {
    await _save(
      customThemeCopyOf(
        theme,
        id: newCustomThemeId(),
        name: uniqueThemeName(themeLabel(theme), takenNames()),
      ),
    );
  }

  /// Opens the editor on [theme] and re-reads the rows whatever came of it.
  Future<void> edit(BuildContext context, AppTheme theme) async {
    if (theme is! CustomAppTheme) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<CustomTheme>(
        builder: (context) =>
            ThemeEditorScreen(controller: controller, theme: theme.theme),
      ),
    );
    await reload();
  }

  /// Asks for another name and stores it.
  Future<void> rename(BuildContext context, AppTheme theme) async {
    if (theme is! CustomAppTheme) {
      return;
    }
    final taken = takenNames()..remove(theme.theme.name.toLowerCase());
    final name = await showThemeNameDialog(
      context,
      title: AppStrings.actionRename,
      initial: theme.theme.name,
      takenNames: taken,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await controller.renameCustomTheme(theme.theme.id, name);
    await reload();
  }

  /// Writes [theme] out into a file the user names.
  Future<void> export(BuildContext context, AppTheme theme) async {
    if (theme is! CustomAppTheme) {
      return;
    }
    final custom = theme.theme;
    try {
      final where = await saveThemeFile(
        name: custom.name,
        json: encodeThemeFile(
          name: custom.name,
          day: custom.day,
          night: custom.night,
        ),
      );
      if (where == null || !context.mounted) return; // Dismissed.
      _report(context, AppStrings.themeExportDone(where));
    } on Object catch (error) {
      if (!context.mounted) return;
      _report(context, AppStrings.themeFileFailed('$error'));
    }
  }

  /// Reads a theme file and stores what it holds, worn like the rest.
  ///
  /// A name the list already answers to is refused with the chance to
  /// import the theme under another one, typed on the spot: two themes
  /// cannot answer to one name.
  Future<void> import(BuildContext context) async {
    final String? source;
    try {
      source = await pickThemeFile();
    } on Object catch (error) {
      if (context.mounted) {
        _report(context, AppStrings.themeFileFailed('$error'));
      }
      return;
    }
    if (source == null || !context.mounted) {
      return;
    }
    final result = decodeThemeFile(source);
    if (result is ThemeFileRefused) {
      await _refuseImport(context, result.problem);
      return;
    }
    final read = result as ThemeFileRead;
    var name = read.name;
    if (takenNames().contains(name.toLowerCase())) {
      final chosen = await showThemeNameDialog(
        context,
        title: AppStrings.themeImport,
        initial: name,
        takenNames: takenNames(),
        description: AppStrings.themeNameTaken,
      );
      if (chosen == null || !context.mounted) {
        return;
      }
      name = chosen;
    }
    await _save(
      CustomTheme(
        id: newCustomThemeId(),
        name: name,
        day: read.day,
        night: read.night,
      ),
    );
  }

  /// Asks first, then deletes [theme]; the theme in use falls back to the
  /// app's own colors when the deleted one was it.
  Future<void> delete(BuildContext context, AppTheme theme) async {
    if (theme is! CustomAppTheme) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.actionDelete),
        content: Text(AppStrings.themeDeleteBody(theme.theme.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await controller.deleteCustomTheme(theme.theme.id);
    await reload();
  }

  /// Stores [theme] and wears it: making one, copying one and importing
  /// one all end with the new theme in front of the user.
  Future<void> _save(CustomTheme theme) async {
    await controller.saveCustomTheme(theme);
    await controller.setTheme(CustomAppTheme(theme));
    AppThemes.theme = CustomAppTheme(theme);
    await reload();
  }

  /// Says why a file could not be read into a theme.
  Future<void> _refuseImport(BuildContext context, ThemeImportProblem problem) {
    final reason = switch (problem.kind) {
      ThemeImportKind.notATheme => AppStrings.themeImportInvalid,
      ThemeImportKind.newerVersion => AppStrings.themeImportVersion(
        problem.version ?? 0,
      ),
      ThemeImportKind.badRole => AppStrings.themeImportBadRole(
        problem.role ?? '',
      ),
    };
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.themeImport),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.actionOk),
          ),
        ],
      ),
    );
  }

  /// Says what happened, where the eye already is.
  void _report(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
