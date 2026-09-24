import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/crash_reporter.dart';
import 'package:niman/src/core/launch_args.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/log_file.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/single_instance.dart';
import 'package:niman/src/widget/widget_toggle.dart';
import 'package:path/path.dart' as p;

/// Entrypoint of the Niman application.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  CrashReporter.install();
  unawaited(_attachLogFile());
  unawaited(_registerWidgetToggle());
  _reportSlowFrames();
  // Desktop only by construction: Android launches with no arguments, so
  // the platform service stays in charge there.
  final launch = parseLaunchArgs(args, cwd: Directory.current.path);
  final desktop = Platform.isLinux || Platform.isWindows;
  // One Niman per session (#41): a later launch hands itself to the first
  // and ends here, before it opens anything.
  final instance = desktop ? await _claimSession(launch) : null;
  if (desktop && instance == null) exit(0);
  final later = instance?.launches.map(LaunchArgs.fromJson).asBroadcastStream();
  runApp(
    ProviderScope(
      overrides: [
        if (desktop)
          shortcutServiceProvider.overrideWith(
            (ref) => CliShortcutService(
              launch.action,
              later: later == null
                  ? const Stream.empty()
                  : later
                        .map((launch) => launch.action)
                        .where((action) => action != null)
                        .cast<ShortcutAction>(),
            ),
          ),
        if (desktop)
          launchRequestsProvider.overrideWithValue(
            LaunchRequests(
              file: launch.openPath,
              later: later ?? const Stream.empty(),
            ),
          ),
      ],
      child: const NimanApp(),
    ),
  );
}

/// Claims the session for this process, or hands [launch] to the Niman
/// already holding it and answers null.
///
/// A failure to claim at all (an unwritable support folder) must not stop
/// Niman from starting: it runs unguarded, as it did before #41, and says
/// so in the log. The instance answered then is a stand-in that is never
/// handed anything.
Future<SingleInstance?> _claimSession(LaunchArgs launch) async {
  try {
    final dir = await appSupportDirectory();
    return await SingleInstance.claim(dir, launch.toJson());
  } on Object catch (error) {
    const AppLogger(name: 'instance').warning('running unguarded ($error)');
    return SingleInstance.unguarded();
  }
}

/// Registers the widget checkbox toggle (round 2, R2): without this the
/// background taps have no Dart callback to reach.
///
/// Android-only and best-effort — like the log file, a missing handler
/// is a degraded mode, not a launch failure.
Future<void> _registerWidgetToggle() async {
  if (!Platform.isAndroid) return;
  try {
    await registerWidgetToggle();
  } on MissingPluginException {
    // No host handler (tests).
  } on PlatformException catch (error) {
    const AppLogger(name: 'widgets').warning('toggle not registered ($error)');
  }
}

/// Points the log buffer at a file in the app's private support directory.
///
/// Without it the log lives only in memory and dies with the process,
/// which is exactly when it is worth reading: a reminder that fired (or
/// did not) with the app closed, an OEM battery kill, a reboot. Async and
/// unawaited so it never delays the first frame; the lines logged before
/// it lands are still in the buffer and reach the file on the first flush.
Future<void> _attachLogFile() async {
  try {
    final dir = await appSupportDirectory();
    final path = p.join(dir.path, 'niman-log.txt');
    AppLog.file = LogFile(path: path);
    const AppLogger(name: 'log').info('log file attached: $path');
  } on Object catch (error) {
    // Memory-only logging is a degraded mode, not a failure worth
    // taking the app down for.
    const AppLogger(name: 'log').warning('log file unavailable ($error)');
  }
}

/// Logs every frame whose total UI work misses the 60 Hz budget, so jank
/// (while editing novel-length notes, scrolling, …) is visible in the
/// exported debug log together with the build/raster/vsync breakdown.
///
/// Only the slow ones. A round of tab-switch profiling briefly logged
/// every rendered frame, which answered "how many frames did that
/// animation take" but cost more than it was worth: at 60 lines a second
/// while anything moves, it fills the 5000-line buffer in under two
/// minutes and rotates the 512 KB disk mirror about as fast. That mirror
/// exists to survive the process — a reminder that fired with the app
/// closed, an OEM kill — and an export taken after a few minutes of
/// ordinary use no longer held any of it. Formatting a line per frame on
/// the UI isolate also charges the very frames it measures.
///
/// Timing every frame is the right tool for a profiling round, not for a
/// build someone uses. Put it back behind its own switch if a later round
/// wants it.
void _reportSlowFrames() {
  const logger = AppLogger(name: 'frames');
  const budget = Duration(milliseconds: 16);
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      final total = timing.totalSpan;
      if (total < budget) continue;
      logger.warning(
        'slow frame: total ${_ms(total)} '
        '(build ${_ms(timing.buildDuration)}, '
        'raster ${_ms(timing.rasterDuration)}, '
        'vsync ${_ms(timing.vsyncOverhead)})',
      );
    }
  });
}

String _ms(Duration d) => '${(d.inMicroseconds / 1000).toStringAsFixed(1)} ms';
