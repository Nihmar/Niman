import 'dart:async';
import 'dart:developer' as developer;

import 'package:copist/src/core/log_file.dart';

/// Severity of a log event.
enum LogSeverity {
  /// Lowest severity; fine-grained diagnostics.
  debug,

  /// General operational information.
  info,

  /// Something unexpected but recoverable.
  warning,

  /// A failure that needs attention.
  error,
}

/// App-wide logger that records events into the [AppLog] buffer and routes
/// them through [developer.log] so output also reaches the console (and
/// DevTools) without raw `print` calls.
///
/// Recording honors the global [AppLog.enabled] toggle; while disabled,
/// events are dropped entirely (no buffering, no console output).
final class AppLogger {
  /// Creates a logger identified by [name].
  const AppLogger({this.name = 'copist'});

  /// Component name attached to every event this logger emits.
  final String name;

  /// Emits [message] at [LogSeverity.debug].
  void debug(String message) =>
      AppLog.record(LogSeverity.debug, name, message);

  /// Emits [message] at [LogSeverity.info].
  void info(String message) =>
      AppLog.record(LogSeverity.info, name, message);

  /// Emits [message] at [LogSeverity.warning].
  void warning(String message) =>
      AppLog.record(LogSeverity.warning, name, message);

  /// Emits [message] at [LogSeverity.error].
  void error(String message) =>
      AppLog.record(LogSeverity.error, name, message);
}

/// The process-wide, in-memory log buffer behind [AppLogger].
///
/// Every recorded event becomes one formatted line
/// (`<timestamp> <SEVERITY> [<name>] <message>`), kept oldest-first and
/// capped at [maxLines] (oldest lines drop off first). The buffer feeds
/// the settings-screen log export, together with the [LogFile] mirror
/// when one is set -- the buffer alone dies with the process, and
/// a reminder firing with the app closed leaves no other trace.
/// [enabled] is synced from the
/// persisted app setting whenever a library session opens, so users can
/// switch recording on or off without rebuilding anything.
final class AppLog {
  /// The buffer is process-wide; no instances.
  AppLog._();

  /// Maximum number of lines kept in the buffer.
  static const int maxLines = 5000;

  /// Whether [record]s are kept.
  ///
  /// Defaults to true (first runs log until the user opts out); synced from
  /// the persisted app setting when a library session opens.
  static bool enabled = true;

  static final List<String> _lines = <String>[];

  /// The disk mirror every recorded line is also written to, or null
  /// while logging is memory-only.
  ///
  /// The in-memory buffer dies with the process, which is precisely when
  /// the log matters: a reminder that fired with the app closed, a kill
  /// by an OEM battery manager, a crash, a reboot. Attaching one is
  /// optional so tests and the desktop builds can stay memory-only.
  static LogFile? file;

  /// Writes anything the disk mirror still holds (no-op when detached).
  ///
  /// Called when the app backgrounds so a swipe away keeps its tail.
  static Future<void> flush() async => file?.flush();

  /// Records [message] at [severity] under [name].
  ///
  /// Dropped entirely when [enabled] is false.
  static void record(LogSeverity severity, String name, String message) {
    if (!enabled) return;
    _lines.add(
      '${_timestamp(DateTime.now())} ${severity.name.toUpperCase()} [$name] '
      '$message',
    );
    if (_lines.length > maxLines) {
      _lines.removeRange(0, _lines.length - maxLines);
    }
    file?.add(_lines.last);
    developer.log(
      message,
      name: name,
      level: switch (severity) {
        LogSeverity.debug => 5,
        LogSeverity.info => 3,
        LogSeverity.warning => 2,
        LogSeverity.error => 1,
      },
    );
  }

  /// The buffered lines, oldest first.
  static List<String> lines() => List<String>.unmodifiable(_lines);

  /// The whole buffer as a single text blob, for export.
  static String dump() => _lines.join('\n');

  /// Drops all buffered lines, on disk too.
  static void clear() {
    _lines.clear();
    unawaited(file?.clear() ?? Future<void>.value());
  }

  static String _timestamp(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    final date =
        '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)}';
    final time = '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
    return '$date $time.$ms';
  }
}
