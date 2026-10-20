import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_config.dart';

/// The open library's settings, read once from
/// `<library>/.niman/settings.json` and written back on every change
/// (T-ML-02).
///
/// The file replaced a database row, and a row was cheap to read: the
/// trash toggle is consulted on every delete, the list folder and the
/// quick note on UI paths. Re-reading and re-parsing the file each time
/// would put disk I/O on those paths, so the value is cached for the life
/// of the session — which is also the life of the open library, so an
/// external edit of the file is picked up the next time it is opened.
///
/// Writes are read-modify-write over a shared file, so they run one at a
/// time, and the cache is replaced only once the write has landed.
final class LibraryConfigRepo {
  /// Creates the repo for the library at its absolute path; [device]
  /// keeps the device's share of the settings (see [LibraryConfigStore]),
  /// and [welcomeDefaults] are the editor keys the welcome's answer
  /// hands a library this device opens for the first time (#266).
  new(
    String libraryPath, {
    DeviceSettingsStore? device,
    Map<String, Object?>? welcomeDefaults,
    ValueNotifier<Features>? features,
  }) : _features = features ?? ValueNotifier(const Features()),
       _store = LibraryConfigStore(
         libraryPath,
         device: device,
         welcomeDefaults: welcomeDefaults,
       );

  final LibraryConfigStore _store;
  final ValueNotifier<Features> _features;

  Future<LibraryConfig>? _config;
  Future<void> _chain = Future<void>.value();

  /// Called after every write that changed the file (the sync queues the
  /// file for upload); a change of a device setting alone does not.
  void Function()? onWritten;

  /// The library's features (#1109), as the settings hold them: every one
  /// on until the file has been read, then the value of each read, write
  /// and reload that changes it. What every surface rebuilds from.
  ValueListenable<Features> get features => _features;

  /// The library's settings; the first call reads the file, later ones
  /// return the cached value.
  Future<LibraryConfig> get config => _config ??= _store.read().then(_seen);

  LibraryConfig _seen(LibraryConfig config) {
    _features.value = config.features;
    return config;
  }

  /// Drops the cached settings, so the next read comes from the file —
  /// after something other than this repo replaced it (a sync download).
  /// Waits for a write in progress, which would otherwise put its own
  /// copy back into the cache. The file is read again at once, so a change
  /// a sync brought reaches whoever listens to [features].
  Future<void> reload() {
    final next = _chain.then((_) async {
      _config = null;
      await config;
    });
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// Applies [change] to the current settings and persists the result.
  ///
  /// A change that produces an equal config writes nothing.
  Future<void> update(LibraryConfig Function(LibraryConfig) change) {
    final next = _chain.then((_) async {
      final current = await config;
      final updated = change(current);
      if (updated == current) return;
      final fileChanged = await _store.write(updated);
      _config = Future<LibraryConfig>.value(updated);
      _features.value = updated.features;
      if (fileChanged) onWritten?.call();
    });
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
