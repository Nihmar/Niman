import 'dart:async';

import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/update/update_scheduler.dart';
import 'package:niman/src/update/update_service.dart';

/// The session's launch + six-hourly update checks (issue #81), and the
/// update they last found.
final class SessionUpdateChecks {
  /// Checks that call [onUpdate] when they find an update.
  new({required this.onUpdate});

  /// Called once [pending] holds a newly found update.
  final void Function() onUpdate;

  final AppLogger _log = const AppLogger(name: 'session');

  UpdateScheduler? _updateScheduler;

  /// The latest available update the scheduler found, if any (issue #81).
  UpdateAvailable? get pending => _pending;
  UpdateAvailable? _pending;

  /// Drops the pending update.
  void clear() {
    _pending = null;
  }

  /// Starts the launch + six-hourly update checks, once per controller.
  ///
  /// The scheduler only reads the settings store and GitHub; drift writes
  /// stay on the main isolate, in its callbacks.
  void start(AppDatabase appDb) {
    // Testing builds check no release channel (issue #106), and iOS is the
    // App Store's to update: the stored toggle is irrelevant, nothing
    // polls and no banner can appear.
    if (!appUpdatesItself) return;
    if (_updateScheduler != null) return;
    // What an earlier update left in Android's updates folder has done its
    // work, or was not wanted: the next one is fetched afresh (#900). Once,
    // at launch — never under a download this run started.
    unawaited(clearUpdateDownloads());
    final repo = AppSettingsRepo(appDb);
    _updateScheduler = UpdateScheduler(
      isEnabled: repo.autoUpdateEnabled,
      runCheck: () async {
        try {
          final current = await currentAppVersion();
          final update = await checkNow(current: current);
          _log.debug(
            'update check: current $current -> '
            '${update == null ? 'up to date' : 'available ${update.version}'}',
          );
          return update;
        } on Object catch (error) {
          _log.warning('update check failed: $error');
          return null;
        }
      },
      noteChecked: repo.setLastUpdateCheck,
      onUpdate: (update) {
        _pending = update;
        onUpdate();
      },
    )..start();
  }

  /// Stops the checks.
  void stop() {
    _updateScheduler?.stop();
    _updateScheduler = null;
  }
}
