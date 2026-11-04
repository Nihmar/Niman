import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:path/path.dart' as p;

/// The reader/writer for one library's settings: `.niman/settings.json`
/// and, with a [DeviceSettingsStore], the device's share of them
/// ([LibraryConfig.deviceKeys]).
///
/// Reading a missing, unreadable or malformed file yields the defaults
/// rather than throwing: the settings file is user-editable and must
/// never take the app down. Writing is atomic (temp file + rename, same
/// as a note), so a reader never observes a partial write.
///
/// Without a device store (tests, tools, the legacy seed) the file keeps
/// every key, as it did before the split.
final class LibraryConfigStore {
  /// Creates a store for the library at its absolute path; [welcomeDefaults]
  /// are the device keys a library takes from the welcome's answer (#266)
  /// when this device has never stored any for it — every such library,
  /// not only the first.
  new(this._libraryPath, {this._device, this.welcomeDefaults});

  final String _libraryPath;
  final DeviceSettingsStore? _device;

  /// The welcome's answer as device keys ([LibraryConfig.editorDeviceKeys]),
  /// or null when the question was never asked. Merged *under* the file's
  /// own values, so a library that has an editor choice of its own keeps
  /// it.
  final Map<String, Object?>? welcomeDefaults;

  /// The settings file: `<library>/.niman/settings.json`.
  File get file => File(p.join(_libraryPath, '.niman', 'settings.json'));

  /// The settings logger: the fallback to defaults used to be silent, and that
  /// silence is half of how #258 went unnoticed for days.
  static const AppLogger _log = AppLogger(name: 'settings');

  /// Reads the library's settings; defaults when the file is missing,
  /// unreadable or malformed.
  ///
  /// With a device store, the device keys come from it — whatever the
  /// file says about them, since an older build elsewhere may still write
  /// its own there. A device that has none yet takes the file's values
  /// once and keeps them: that is the move out of the shared file.
  Future<LibraryConfig> read() async {
    final json = await _readFile();
    final deviceStore = _device;
    if (deviceStore == null) return LibraryConfig.fromJsonMap(json);
    var device = await deviceStore.read(_libraryPath);
    if (device == null) {
      device = {
        for (final key in LibraryConfig.deviceKeys)
          if (json.containsKey(key)) key: json[key],
      };
      // The first run's answer fills what the file does not say — a new
      // library, or one that never carried these keys (#266).
      final defaults = welcomeDefaults;
      if (defaults != null) {
        for (final entry in defaults.entries) {
          device.putIfAbsent(entry.key, () => entry.value);
        }
      }
      await deviceStore.write(_libraryPath, device);
    }
    return LibraryConfig.fromJsonMap({
      for (final entry in json.entries)
        if (!LibraryConfig.deviceKeys.contains(entry.key))
          entry.key: entry.value,
      ...device,
    });
  }

  /// The file's JSON object; empty — the defaults — when it is missing,
  /// unreadable or not an object.
  ///
  /// The fallback stays — a library must open whatever its settings file
  /// says — but it **says which** of the three happened, because the
  /// defaults are not neutral: which editors are on, the toolbar, the
  /// links, the trash all revert, and nothing on screen mentions it. A
  /// missing file in a library that has been written to before is a
  /// `warning` (that is the shape of a lost or trashed file); a library
  /// with no `.niman/` at all is an `info`, because that is simply a new
  /// one.
  Future<Map<String, Object?>> _readFile() async {
    String raw;
    try {
      raw = await file.readAsString();
    } on Object catch (error) {
      if (await file.parent.exists()) {
        _log.warning(
          'settings.json is missing or unreadable in ${file.parent.path} '
          '($error): this library is on defaults',
        );
      } else {
        _log.info('no settings.json yet: a new library, on defaults');
      }
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _log.warning(
          'settings.json is not an object in ${file.parent.path}: '
          'this library is on defaults',
        );
        return const {};
      }
      // jsonDecode yields `Map<String, dynamic>`; bridge to the typed view.
      return {
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    } on Object catch (error) {
      _log.warning(
        'settings.json could not be parsed in ${file.parent.path} ($error): '
        'this library is on defaults',
      );
      return const {};
    }
  }

  /// Writes [config]: its library keys to the file (atomically, creating
  /// `.niman/` if needed) and, with a device store, its device keys there.
  ///
  /// The file is rewritten only when its text changes, so a change of a
  /// device key never touches it. Returns whether the file was written —
  /// what the sync needs to hear about.
  Future<bool> write(LibraryConfig config) async {
    final deviceStore = _device;
    if (deviceStore != null) {
      await deviceStore.write(_libraryPath, config.deviceJsonMap());
    }
    final json = deviceStore == null
        ? config.toJsonMap()
        : config.libraryJsonMap();
    final text = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
    try {
      if (await file.readAsString() == text) return false;
    } on FileSystemException {
      // Missing: written below.
    }
    await file.parent.create(recursive: true);
    await writeFileAtomically(file, utf8.encode(text));
    return true;
  }
}
