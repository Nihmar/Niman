import 'dart:convert';

import 'package:niman/src/db/app_database.dart';
import 'package:path/path.dart' as p;

/// Where a library's device settings live (`LibraryConfig.deviceKeys`):
/// the part of its configuration that describes this screen and this
/// person, and so stays on this device instead of travelling in
/// `.niman/settings.json`.
///
/// An interface so tests and tools can keep them in memory.
abstract interface class DeviceSettingsStore {
  /// The device settings kept for [libraryPath], or null when this device
  /// has never stored any (a library opened for the first time since the
  /// split, whose values still sit in its settings file).
  Future<Map<String, Object?>?> read(String libraryPath);

  /// Keeps [settings] as [libraryPath]'s device settings.
  Future<void> write(String libraryPath, Map<String, Object?> settings);

  /// Forgets [libraryPath]'s device settings (the library was forgotten).
  Future<void> remove(String libraryPath);
}

/// The app database's `library_device_settings` table, one row per
/// library.
final class DbDeviceSettingsStore implements DeviceSettingsStore {
  /// A store over [_db].
  new(this._db);

  final AppDatabase _db;

  @override
  Future<Map<String, Object?>?> read(String libraryPath) async {
    final row =
        await (_db.select(_db.libraryDeviceSettings)
              ..where((t) => t.libraryPath.equals(p.normalize(libraryPath))))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.settings);
      // An unreadable row is no row: the file's values are the best
      // answer left.
      if (decoded is! Map) return null;
      return {
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String libraryPath, Map<String, Object?> settings) async {
    await _db
        .into(_db.libraryDeviceSettings)
        .insertOnConflictUpdate(
          LibraryDeviceSettingsCompanion.insert(
            libraryPath: p.normalize(libraryPath),
            settings: jsonEncode(settings),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> remove(String libraryPath) async {
    await (_db.delete(
      _db.libraryDeviceSettings,
    )..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))).go();
  }
}

/// Device settings kept in memory, for tests and tools that open a
/// library without the app database.
final class MemoryDeviceSettingsStore implements DeviceSettingsStore {
  final Map<String, Map<String, Object?>> _rows = {};

  @override
  Future<Map<String, Object?>?> read(String libraryPath) async {
    final row = _rows[p.normalize(libraryPath)];
    return row == null ? null : Map.of(row);
  }

  @override
  Future<void> write(String libraryPath, Map<String, Object?> settings) async {
    _rows[p.normalize(libraryPath)] = Map.of(settings);
  }

  @override
  Future<void> remove(String libraryPath) async {
    _rows.remove(p.normalize(libraryPath));
  }
}
