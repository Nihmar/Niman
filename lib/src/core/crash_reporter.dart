import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Process-wide uncaught-error capture (M2a on-device round 2).
///
/// The app "crashed" on device with nothing to analyze: the [AppLog] buffer
/// is in-memory and dies with the process. So an uncaught error is
/// (1) recorded in the buffer (visible in the settings export when the app
/// is still alive) and (2) persisted — buffer included — to a
/// `copist-crash-<stamp>.txt` in the open library (falling back to the app
/// documents directory), where the user can send it back for analysis.
final class CrashReporter {
  CrashReporter._();

  /// The crash diagnostics.
  static const AppLogger _log = AppLogger(name: 'crash');

  /// Whether [install] already ran (it is idempotent).
  static bool installed = false;

  /// Installs the [PlatformDispatcher] and [FlutterError] handlers.
  ///
  /// The platform handler returns true: the app stays alive behind the log
  /// instead of dying on the exception screen before the user can export
  /// anything. Framework errors keep the default presentation after the
  /// capture.
  static void install() {
    if (installed) return;
    installed = true;
    PlatformDispatcher.instance.onError = (error, stack) {
      _report('uncaught error', error, stack);
      return true;
    };
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      _report('flutter error', details.exception, details.stack);
      previous?.call(details);
    };
  }

  static void _report(String kind, Object error, StackTrace? stack) {
    final message = '$error';
    final trace = stack?.toString() ?? '(no stack)';
    _log.error('$kind: $message');
    unawaited(_persist('$kind\n$message\n$trace'));
  }

  static Future<void> _persist(String errorAndTrace) async {
    final now = DateTime.now();
    final stamp = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final filename = 'copist-crash-$stamp.txt';
    final report = StringBuffer()
      ..writeln('# Copist crash report')
      ..writeln('# captured: ${now.toIso8601String()}')
      ..writeln()
      ..writeln(errorAndTrace)
      ..writeln()
      ..writeln('--- AppLog buffer (oldest first) ---')
      ..writeln(AppLog.dump())
      ..writeln();
    final libraryRoot = LibraryController.currentRootPath;
    final dirs = <String>[await _appDocumentsDir()];
    if (libraryRoot != null) dirs.insert(0, libraryRoot);
    for (final dir in dirs) {
      try {
        await File(p.join(dir, filename)).writeAsString(report.toString());
        _log.info('crash report saved: $dir/$filename');
        return;
      } on Object catch (error) {
        _log.warning('crash report: $dir failed ($error)');
      }
    }
    _log.warning('crash report: no writable location');
  }

  static Future<String> _appDocumentsDir() async {
    try {
      return (await getApplicationDocumentsDirectory()).path;
    } on Object {
      return Directory.systemTemp.path;
    }
  }
}
