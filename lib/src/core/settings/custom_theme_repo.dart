// The custom themes of one installation (issue #269).
//
// They live in the app's own database, not in a library: a theme is how
// this installation looks, so a copied library folder must not carry
// someone else's colors and a synced library must not spread them. This
// is the only place that reads and writes the `custom_themes` rows; the
// JSON in them is [ThemeColors]' own shape.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/db/app_database.dart';

const AppLogger _log = AppLogger(name: 'theme');

/// The custom themes stored on this installation.
final class CustomThemeRepo {
  /// Creates the repo over the given [AppDatabase].
  new(this._db);

  final AppDatabase _db;

  /// Every custom theme, by name (case-insensitively).
  ///
  /// A row whose colors cannot be read — a database edited by hand, or
  /// written by a build whose roles differed — is skipped and logged
  /// rather than taking the themes screen down with it.
  Future<List<CustomTheme>> list() async {
    final rows =
        await (_db.select(_db.customThemes)..orderBy([
              (t) => OrderingTerm(expression: t.name.collate(Collate.noCase)),
            ]))
            .get();
    final themes = <CustomTheme>[];
    for (final row in rows) {
      final theme = _fromRow(row);
      if (theme != null) themes.add(theme);
    }
    return themes;
  }

  /// The custom theme with [id], or null — unreadable rows included.
  Future<CustomTheme?> byId(String id) async {
    final row = await (_db.select(
      _db.customThemes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Whether [name] is a theme's name already, case-insensitively.
  Future<bool> nameTaken(String name) async {
    final wanted = CustomTheme.cleanName(name).toLowerCase();
    final rows =
        await (_db.select(_db.customThemes)
              ..where((t) => t.name.collate(Collate.noCase).equals(wanted))
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  /// Stores [theme]: the row with its id when there is one, a new row
  /// otherwise.
  Future<void> save(CustomTheme theme) async {
    await _db
        .into(_db.customThemes)
        .insertOnConflictUpdate(
          CustomThemesCompanion.insert(
            id: theme.id,
            name: CustomTheme.cleanName(theme.name),
            dayColors: jsonEncode(theme.day.toJson()),
            nightColors: jsonEncode(theme.night.toJson()),
          ),
        );
  }

  /// Renames the theme with [id].
  Future<void> rename(String id, String name) async {
    await (_db.update(_db.customThemes)..where((t) => t.id.equals(id))).write(
      CustomThemesCompanion(name: Value(CustomTheme.cleanName(name))),
    );
  }

  /// Deletes the theme with [id]; nothing else is touched, so a setting
  /// still pointing at it is the caller's to repair (the session repairs
  /// it by falling back to the app's own colors).
  Future<void> delete(String id) async {
    await (_db.delete(_db.customThemes)..where((t) => t.id.equals(id))).go();
  }

  /// The theme [row] holds, or null when a color of it cannot be read.
  CustomTheme? _fromRow(CustomThemeRow row) {
    final day = _colors(row.dayColors);
    final night = _colors(row.nightColors);
    if (day == null || night == null) {
      _log.warning('custom theme ${row.id} has unreadable colors; skipping it');
      return null;
    }
    return CustomTheme(id: row.id, name: row.name, day: day, night: night);
  }
}

/// The colors [json] holds, or null when it is not the shape they have.
ThemeColors? _colors(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  return ThemeColors.fromJson(decoded);
}
