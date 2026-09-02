import 'dart:developer' as developer;

/// Severity of a log event.
enum LogSeverity {
  /// Lowest severity; emitted only during development.
  debug,

  /// General operational information.
  info,

  /// Something unexpected but recoverable.
  warning,

  /// A failure that needs attention.
  error,
}

/// App-wide logger that routes events through [developer.log] so output
/// reaches the console (and DevTools) without raw `print` calls.
final class AppLogger {
  /// Creates a logger identified by [name].
  const AppLogger({this.name = 'copist'});

  /// Component name attached to every event this logger emits.
  final String name;

  /// Emits [message] at [LogSeverity.debug].
  void debug(String message) => _log(LogSeverity.debug, message);

  /// Emits [message] at [LogSeverity.info].
  void info(String message) => _log(LogSeverity.info, message);

  /// Emits [message] at [LogSeverity.warning].
  void warning(String message) => _log(LogSeverity.warning, message);

  /// Emits [message] at [LogSeverity.error].
  void error(String message) => _log(LogSeverity.error, message);

  void _log(LogSeverity severity, String message) {
    final level = switch (severity) {
      LogSeverity.debug => 5,
      LogSeverity.info => 3,
      LogSeverity.warning => 2,
      LogSeverity.error => 1,
    };
    developer.log(message, name: name, level: level);
  }
}
