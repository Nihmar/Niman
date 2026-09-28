import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// Process-wide uncaught-error capture (M2a on-device round 2).
///
/// The app "crashed" on device with nothing to analyze: the [AppLog] buffer
/// is in-memory and dies with the process. So an uncaught error is
/// (1) recorded in the buffer (visible in the settings export when the app
/// is still alive) and (2) persisted — buffer included — to a
/// `niman-crash-<stamp>.txt` in the app's private support folder, beside
/// `niman-log.txt`.
///
/// Never in the open library (#383): the report carries the note and library
/// paths and the sync host, and a file in the library is an upload the user
/// did not choose. The sync leaves the name alone wherever it finds one
/// (`sync/reconcile.dart`). The newest [_keptReports] reports are kept, so a
/// repeat failure does not pile files up.
final class CrashReporter {
  new _();

  /// The crash diagnostics.
  static const AppLogger _log = AppLogger(name: 'crash');

  /// The name a report gets before its stamp: also the shape the sync never
  /// uploads, so a report that reaches a library another way (an older
  /// build's file, a copy the user made) stays where it is.
  static const String _namePrefix = 'niman-crash-';

  /// The reports the support folder keeps, the newest first. Each one holds
  /// the whole log buffer, so a long-lived pile is weight, not evidence.
  static const int _keptReports = 5;

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
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final filename = '$_namePrefix$stamp.txt';
    final report = StringBuffer()
      ..writeln('# Niman crash report')
      ..writeln('# captured: ${now.toIso8601String()}')
      ..writeln()
      ..writeln(errorAndTrace)
      ..writeln()
      ..writeln('--- AppLog buffer (oldest first) ---')
      ..writeln(AppLog.dump())
      ..writeln();
    final String dir;
    try {
      dir = (await appSupportDirectory()).path;
    } on Object catch (error) {
      _log.warning('crash report: no folder ($error)');
      return;
    }
    final path = p.join(dir, filename);
    try {
      await File(path).writeAsString(report.toString());
    } on Object catch (error) {
      _log.warning('crash report: $path failed ($error)');
      return;
    }
    _log.info('crash report saved: $path');
    await _prune(dir);
  }

  /// Deletes the reports in [dir] beyond [_keptReports].
  ///
  /// The stamp in the name is fixed width, so the name order is the age
  /// order. Only this class's own names are touched: the support folder
  /// holds the databases and the log as well.
  static Future<void> _prune(String dir) async {
    try {
      final reports = <String, File>{};
      await for (final entity in Directory(dir).list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (_isReportName(name)) reports[name] = entity;
      }
      final names = reports.keys.toList()..sort();
      final extra = names.length - _keptReports;
      if (extra <= 0) return;
      for (final name in names.take(extra)) {
        await reports[name]!.delete();
      }
    } on Object catch (error) {
      _log.warning('crash report: prune failed ($error)');
    }
  }

  /// Whether [name] is one of this class's reports.
  static bool _isReportName(String name) =>
      name.startsWith(_namePrefix) && name.endsWith('.txt');
}
