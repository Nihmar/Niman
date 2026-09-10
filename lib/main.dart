import 'dart:async';

import 'package:copist/src/app.dart';
import 'package:copist/src/core/crash_reporter.dart';
import 'package:copist/src/core/launch_args.dart';
import 'package:copist/src/core/log_file.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/shortcuts.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Entrypoint of the Copist application.
void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  CrashReporter.install();
  unawaited(_attachLogFile());
  _reportSlowFrames();
  // Desktop only by construction: Android launches with no arguments, so
  // the platform service stays in charge there.
  final launch = parseLaunchArgs(args);
  final openPath = launch.openPath;
  if (openPath != null) {
    const AppLogger(name: 'launch')
        .info('file argument not opened yet (P3): $openPath');
  }
  runApp(
    ProviderScope(
      overrides: [
        if (launch.action case final action?)
          shortcutServiceProvider.overrideWith(
            (ref) => CliShortcutService(action),
          ),
      ],
      child: const CopistApp(),
    ),
  );
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
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'copist-log.txt');
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
