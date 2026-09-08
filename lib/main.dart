import 'dart:async';

import 'package:copist/src/app.dart';
import 'package:copist/src/core/crash_reporter.dart';
import 'package:copist/src/core/log_file.dart';
import 'package:copist/src/core/logging.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Entrypoint of the Copist application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CrashReporter.install();
  unawaited(_attachLogFile());
  _reportFrames();
  runApp(const ProviderScope(child: CopistApp()));
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

/// Logs the timing of every rendered frame, not just the slow ones.
///
/// The warning still catches the frames that miss the 60 Hz budget; the
/// debug line logs every frame with the gap since the previous one, so the
/// exported log carries the whole frame timeline of an animation — which
/// frame landed when, and where the rhythm broke. Without it the 2026-09-08
/// search-tab lag showed up as a warning that said how long a frame took,
/// never when it landed or what it delayed.
void _reportFrames() {
  const logger = AppLogger(name: 'frames');
  const budget = Duration(milliseconds: 16);
  DateTime? lastFrame;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      final total = timing.totalSpan;
      final now = DateTime.now();
      final gap = lastFrame == null ? null : now.difference(lastFrame!);
      lastFrame = now;
      logger.debug(
        'frame: total ${_ms(total)} '
        '(build ${_ms(timing.buildDuration)}, '
        'raster ${_ms(timing.rasterDuration)}, '
        'vsync ${_ms(timing.vsyncOverhead)})'
        '${gap == null ? '' : ', gap ${_ms(gap)} since previous'}',
      );
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
