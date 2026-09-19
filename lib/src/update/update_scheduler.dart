/// Periodic update checks (issue #81: auto-update).
///
/// One check shortly after launch, then every six hours, each gated on the
/// settings toggle. The check itself throws nothing: a failure (offline,
/// unparseable version, GitHub hiccup) is a quiet skip, and whatever went
/// wrong reaches the log.
library;

import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/update/update_check.dart';

/// Runs the auto-update check on a schedule (issue #81).
///
/// The scheduler owns no I/O: [isEnabled] and [noteChecked] reach the
/// settings store, [runCheck] reaches GitHub, [onUpdate] reaches the UI.
/// All four are plain callbacks so tests can fake them.
final class UpdateScheduler {
  /// Creates a scheduler; [start] begins the checks.
  new({
    required this.isEnabled,
    required this.runCheck,
    required this.noteChecked,
    required this.onUpdate,
    this.startupDelay = const Duration(seconds: 10),
    this.checkInterval = const Duration(hours: 6),
  });

  /// Whether automatic checks are switched on.
  final Future<bool> Function() isEnabled;

  /// Runs one check; null when current or when the check failed quietly.
  final Future<UpdateAvailable?> Function() runCheck;

  /// Records a completed check attempt.
  final Future<void> Function(DateTime time) noteChecked;

  /// Receives an available update.
  final void Function(UpdateAvailable update) onUpdate;

  /// Delay before the launch check, so startup stays fast.
  final Duration startupDelay;

  /// Period between checks.
  final Duration checkInterval;

  Timer? _launch;
  Timer? _timer;
  bool _started = false;

  /// Starts the launch check and the periodic timer; idempotent.
  ///
  /// The launch check is a timer too, so [stop] cancels it: a library
  /// closed within [startupDelay] of opening left it to fire on the
  /// settings database that had closed with it.
  void start() {
    if (_started) return;
    _started = true;
    _launch = Timer(startupDelay, () => unawaited(checkOnce()));
    _timer = Timer.periodic(checkInterval, (_) => unawaited(checkOnce()));
  }

  /// Runs one gated check now.
  Future<void> checkOnce() async {
    try {
      if (!await isEnabled()) return;
      final update = await runCheck();
      await noteChecked(DateTime.now().toUtc());
      if (update != null) onUpdate(update);
    } on Object catch (error) {
      const AppLogger(name: 'update').warning('scheduled check failed: $error');
    }
  }

  /// Stops the periodic timer; idempotent.
  void stop() {
    _launch?.cancel();
    _launch = null;
    _timer?.cancel();
    _timer = null;
    _started = false;
  }
}
