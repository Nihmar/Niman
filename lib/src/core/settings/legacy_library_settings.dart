import 'dart:convert';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart';

/// Delivers the settings the dropped `library_settings` table held to the
/// libraries they describe (T-ML-02).
///
/// The schema migration parks those rows in
/// `app_settings.legacy_library_settings` because it cannot write them:
/// it runs at startup, before Android grants storage access, and a
/// library may be on a drive that is not plugged in. This drains one
/// entry per library open, when the folder is known to be reachable —
/// after which the library's own `.copist/settings.json` is the only
/// source and the parked entry is gone.
///
/// A library that already has a settings file keeps it: the file is
/// newer than the table by construction, so the parked entry is
/// discarded rather than applied.
final class LegacyLibrarySettings {
  /// Creates the migrator over the app database.
  new(this._db);

  final CopistDatabase _db;

  final AppLogger _log = const AppLogger(name: 'settings');

  /// Writes the parked settings for [libraryPath] into its
  /// `.copist/settings.json`, then forgets them.
  ///
  /// Does nothing when there is nothing parked for that library, and
  /// leaves the entry parked when the write fails, so an unwritable
  /// library is retried on its next open rather than losing its settings.
  Future<void> seed(String libraryPath) async {
    final parked = await _parked();
    final entry = parked[libraryPath];
    if (entry == null) return;

    final store = LibraryConfigStore(libraryPath);
    if (store.file.existsSync()) {
      _log.info('legacy settings: $libraryPath already has a file, dropping');
      await _save(parked..remove(libraryPath));
      return;
    }
    try {
      await store.write(LibraryConfig.fromJsonMap(entry));
    } on Object catch (error) {
      _log.warning('legacy settings: $libraryPath not written ($error)');
      return;
    }
    _log.info('legacy settings: $libraryPath migrated into its folder');
    await _save(parked..remove(libraryPath));
  }

  /// The parked settings, by absolute library path; empty when there is
  /// nothing to carry or the value is not the object it should be.
  Future<Map<String, Map<String, Object?>>> _parked() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isEmpty) return {};
    final raw = rows.first.legacyLibrarySettings;
    if (raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return {
      for (final entry in decoded.entries)
        if (entry.value case final Map<Object?, Object?> value)
          entry.key.toString(): {
            for (final field in value.entries)
              field.key.toString(): field.value,
          },
    };
  }

  Future<void> _save(Map<String, Map<String, Object?>> parked) async {
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(
        legacyLibrarySettings: Value(parked.isEmpty ? '' : jsonEncode(parked)),
      ),
    );
  }
}
