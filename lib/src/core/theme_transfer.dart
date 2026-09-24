// Moving a theme between installations (issue #269).
//
// One theme, one file: JSON and not an `.ini`, because a theme is two
// structured maps of twenty-six colors, JSON carries that structure natively
// and validates cheaply, and it is what the app already writes elsewhere
// (`settings.json`). The file says what it is (`format`) and which shape
// it is in (`version`), so a file from a later build is refused with an
// answer instead of read into a theme with holes.
//
// Nothing here touches the disk or the database: this is the shape, and
// the settings page is what reads and writes it.

import 'dart:convert';

import 'package:niman/src/core/theme_colors.dart';

/// What a theme file calls itself.
const String themeFileFormat = 'niman-theme';

/// The file shape this build writes and reads.
const int themeFileVersion = 1;

/// What an exported theme file's name ends with.
const String themeFileExtension = '.json';

/// A theme as the text of a theme file: what it is called ([name], the
/// format and the shape it is in), and the colors it wears at [day] and at
/// [night].
String encodeThemeFile({
  required String name,
  required ThemeColors day,
  required ThemeColors night,
}) {
  final theme = <String, Object?>{
    'format': themeFileFormat,
    'version': themeFileVersion,
    'name': name,
    'day': day.toJson(),
    'night': night.toJson(),
  };
  // A file ends with a newline, like the rest of the text the app writes.
  return '${const JsonEncoder.withIndent('  ').convert(theme)}\n';
}

/// What a theme file said, or why it was refused.
sealed class ThemeFileResult {
  /// For the two answers.
  const new();
}

/// A theme file read whole: the name and the colors, with the id left to
/// whoever imports it.
final class ThemeFileRead extends ThemeFileResult {
  /// Creates the answer.
  const new({required this.name, required this.day, required this.night});

  /// What the file calls the theme.
  final String name;

  /// Its daylight colors.
  final ThemeColors day;

  /// Its night colors.
  final ThemeColors night;
}

/// A file that is not a theme this build can wear.
final class ThemeFileRefused extends ThemeFileResult {
  /// Creates the answer, with [problem] saying what is wrong.
  const new(this.problem);

  /// What is wrong with the file.
  final ThemeImportProblem problem;
}

/// What is wrong with a theme file.
enum ThemeImportKind {
  /// Not JSON, not a Niman theme file, or no name in it.
  notATheme,

  /// A file from a later build, whose shape this one does not know.
  newerVersion,

  /// A role the file leaves out, or gives something that is not a color.
  badRole,
}

/// The reason an import was refused, with what it was about.
final class ThemeImportProblem {
  /// Creates the reason.
  const new(this.kind, {this.role, this.version});

  /// What is wrong.
  final ThemeImportKind kind;

  /// Which role, for [ThemeImportKind.badRole].
  final String? role;

  /// Which version, for [ThemeImportKind.newerVersion].
  final int? version;
}

/// Reads [source] as a theme file.
///
/// Strict on purpose: every role is required at both brightnesses and
/// every color has to be one, because a theme with a hole in it would be
/// a theme wearing a color from somewhere else. The task-list roles are
/// the exception, and only when left out: a file exported before they
/// existed still imports, reading them from the roles they were painted
/// with ([ThemeColors.taskListRoleSources]). One that names them has to
/// name colors.
ThemeFileResult decodeThemeFile(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return const ThemeFileRefused(
      ThemeImportProblem(ThemeImportKind.notATheme),
    );
  }
  if (decoded is! Map<String, Object?>) {
    return const ThemeFileRefused(
      ThemeImportProblem(ThemeImportKind.notATheme),
    );
  }
  if (decoded['format'] != themeFileFormat) {
    return const ThemeFileRefused(
      ThemeImportProblem(ThemeImportKind.notATheme),
    );
  }
  final version = decoded['version'];
  if (version is! int) {
    return const ThemeFileRefused(
      ThemeImportProblem(ThemeImportKind.notATheme),
    );
  }
  if (version > themeFileVersion) {
    return ThemeFileRefused(
      ThemeImportProblem(ThemeImportKind.newerVersion, version: version),
    );
  }
  final name = decoded['name'];
  if (name is! String || name.trim().isEmpty) {
    return const ThemeFileRefused(
      ThemeImportProblem(ThemeImportKind.notATheme),
    );
  }
  final day = _side(decoded['day']);
  if (day.colors == null) return ThemeFileRefused(day.problem!);
  final night = _side(decoded['night']);
  if (night.colors == null) return ThemeFileRefused(night.problem!);
  return ThemeFileRead(
    name: name.trim(),
    day: day.colors!,
    night: night.colors!,
  );
}

/// One brightness of the file: its colors, or the first role that is
/// wrong — missing, or not a color.
({ThemeColors? colors, ThemeImportProblem? problem}) _side(Object? side) {
  if (side is! Map<String, Object?>) {
    return (
      colors: null,
      problem: const ThemeImportProblem(ThemeImportKind.notATheme),
    );
  }
  for (final role in ThemeColors.roleNames) {
    final value = side[role];
    if (value == null && ThemeColors.taskListRoleSources.containsKey(role)) {
      continue;
    }
    if (value is! String || colorFromHex(value) == null) {
      return (
        colors: null,
        problem: ThemeImportProblem(ThemeImportKind.badRole, role: role),
      );
    }
  }
  return (colors: ThemeColors.fromJson(side)!, problem: null);
}
