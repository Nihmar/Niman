import 'package:copist/src/app.dart';
import 'package:copist/src/core/logging.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrypoint of the Copist application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _reportSlowFrames();
  runApp(const ProviderScope(child: CopistApp()));
}

/// Logs every frame whose total UI work misses the 60 Hz budget, so jank
/// (while editing novel-length notes, scrolling, …) is visible in the
/// exported debug log together with the build/layout/paint breakdown.
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

String _ms(Duration d) =>
    '${(d.inMicroseconds / 1000).toStringAsFixed(1)} ms';
