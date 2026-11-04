import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/core/settings/legacy_library_settings.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:path/path.dart' as p;

/// The open library's `.niman/settings.json` (T-ML-10): its reader, the
/// features it switches on (#1109), and whether the open that made the
/// session created the library.
///
/// While no library is open every setting reads at the shipped defaults,
/// every feature reads as on, and a write has nowhere to go.
final class OpenLibrarySettings {
  /// Settings with no library attached.
  new();

  final AppLogger _log = const AppLogger(name: 'session');

  /// The open library's `.niman/settings.json`; null while none is open,
  /// and then every setting reads and writes app-wide.
  LibraryConfigRepo? _configRepo;

  final ValueNotifier<Features> _features = ValueNotifier(const Features());

  /// Whether the open that made this session was of a folder with no
  /// settings file: a library being created (#1109).
  bool _createdLibrary = false;

  /// The open library's features (#1109); every one on while none is open.
  ValueListenable<Features> get features => _features;

  /// The open library's settings, or the shipped defaults while none is
  /// open (T-ML-10).
  ///
  /// The settings screen only exists inside an open library, so the
  /// defaults branch is what a startup read sees before the first open,
  /// not a state a user can edit from.
  Future<LibraryConfig> get config async =>
      await _configRepo?.config ?? LibraryConfig.defaults;

  /// Applies [change] to the open library's settings; a no-op with none
  /// open, since there is nothing to write it to.
  Future<void> edit(LibraryConfig Function(LibraryConfig) change) async {
    await _configRepo?.update(change);
  }

  /// The introduction Settings → Features has still to show (#1109).
  Future<FeaturesIntroduction> get featuresIntroduction async {
    if ((await config).featuresReviewed) return FeaturesIntroduction.none;
    return _createdLibrary
        ? FeaturesIntroduction.created
        : FeaturesIntroduction.existing;
  }

  /// Reads the settings of the library at [abs] from here on, and returns
  /// their reader; [opening] is false for a rebuild of the index, which is
  /// not an open.
  Future<LibraryConfigRepo> attach(
    String abs,
    AppDatabase appDb, {
    required bool opening,
  }) async {
    // Whether this open is a library being created: a folder with no
    // settings file, asked before the seed below can write one (#1109). A
    // rebuild of the index is not an open and says nothing about it.
    final hadSettings = !opening || await _hasSettingsFile(abs);
    // Before anything reads the settings: a library upgraded from the
    // `library_settings` table gets its `.niman/settings.json` here,
    // now that the folder is known to be reachable (T-ML-02).
    await LegacyLibrarySettings(appDb).seed(abs);
    if (opening) {
      _createdLibrary = !hadSettings && !await _hasSettingsFile(abs);
    }
    // One reader of `.niman/settings.json` per session: the four
    // per-library settings and the overrides (T-ML-10) share its cache.
    // The welcome's answer (#266) seeds the editors of every library
    // this device has never stored settings for — not only the first.
    // A failure to read it is not a reason to fail the open.
    Map<String, Object?>? welcomeDefaults;
    try {
      welcomeDefaults = await DbWelcomeStore(AppSettingsRepo(appDb))
          .firstLibraryEditorKeys();
    } on Object catch (error) {
      _log.warning('welcome editor defaults unavailable ($error)');
    }
    final config = LibraryConfigRepo(
      abs,
      device: DbDeviceSettingsStore(appDb),
      welcomeDefaults: welcomeDefaults,
      features: _features,
    );
    _configRepo = config;
    return config;
  }

  /// Drops the library's settings: nothing is open.
  void detach() {
    _configRepo = null;
    // Nothing is open: every feature reads as on until a library says
    // otherwise, so the next open never starts from the last one's.
    _features.value = const Features();
  }

  /// Whether the library at [abs] has a `.niman/settings.json`.
  Future<bool> _hasSettingsFile(String abs) =>
      File(p.join(abs, '.niman', 'settings.json')).exists();
}
