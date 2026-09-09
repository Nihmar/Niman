import 'dart:convert';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/db/app_database.dart';
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
/// Two migrations use it now. T-ML-02 moved four settings out of a
/// table; T-ML-10 moved seven more out of `app_settings`, where they had
/// been one value for every library. Both park what they had and let the
/// first open of each library collect it.
///
/// A library that already has a settings file keeps every key it has and
/// gains only the ones it lacks. The file is newer than whatever was
/// parked, so it wins where the two overlap.
final class LegacyLibrarySettings {
  /// Creates the migrator over the app database.
  new(this._db);

  final AppDatabase _db;

  final AppLogger _log = const AppLogger(name: 'settings');

  /// Writes the parked settings for [libraryPath] into its
  /// `.copist/settings.json`, then forgets them.
  ///
  /// Keys the file already has are left alone: it is the newer of the
  /// two. Does nothing when there is nothing parked for that library, and
  /// leaves the entry parked when the write fails, so an unwritable
  /// library is retried on its next open rather than losing its settings.
  Future<void> seed(String libraryPath) async {
    final parked = await _parked();
    final entry = parked[libraryPath];
    if (entry == null) return;

    final store = LibraryConfigStore(libraryPath);
    final merged = <String, Object?>{...entry, ..._rawFile(store)};
    try {
      await store.write(LibraryConfig.fromJsonMap(merged));
    } on Object catch (error) {
      _log.warning('legacy settings: $libraryPath not written ($error)');
      return;
    }
    _log.info('legacy settings: $libraryPath migrated into its folder');
    await _save(parked..remove(libraryPath));
  }

  /// The settings file exactly as it stands, or empty when there is none
  /// or it cannot be read as an object.
  ///
  /// Read raw rather than through [LibraryConfig]: parsing fills every
  /// missing key with a default, and a default is precisely what the
  /// parked value should be allowed to replace.
  Map<String, Object?> _rawFile(LibraryConfigStore store) {
    try {
      if (!store.file.existsSync()) return const {};
      final decoded = jsonDecode(store.file.readAsStringSync());
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    } on Object catch (_) {
      return const {};
    }
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
