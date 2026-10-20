import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/todo/reminder_cancellation.dart';

/// Keeps the alarms behind the Todo and Calendar switches (#1109).
///
/// The one place the switches meet the reminders. The library's [Features]
/// are listened to, so a switch flipped by the Features screen and one a
/// sync brought from another device take the same path, and run it once:
/// the screen does not reconcile on its own, it flips the switch and awaits
/// [settled], the answer of the reconcile the flip started.
///
/// Off cancels what the file had scheduled and counts it before the
/// reconcile takes it away; on schedules it again from the file, which is
/// the whole of the undo. The wanted set itself is the controller's: it
/// asks `Features.isOn` when it builds it, so a reconcile the feature did
/// not start (a file change, a resume) cannot bring an alarm back.
final class ReminderFeatureFollower {
  /// Follows `features`. `scheduledFor` answers how many reminders the file
  /// has for a feature right now (before its switch is applied), `resync`
  /// reconciles the alarms with the switches as they now are, and `isOpen`
  /// says whether a library is open: closing one resets the features to
  /// every one on, which must not schedule anything.
  new({
    required this._features,
    required this._scheduledFor,
    required this._resync,
    required this._isOpen,
  });

  final ValueListenable<Features> _features;
  final int Function(LibraryFeature feature) _scheduledFor;
  final Future<void> Function() _resync;
  final bool Function() _isOpen;

  late Features _applied;
  bool _started = false;
  Future<ReminderCancellation> _settled = Future.value(
    ReminderCancellation.none,
  );

  /// The switches that own alarms.
  static const List<LibraryFeature> followed = [
    LibraryFeature.todo,
    LibraryFeature.calendar,
  ];

  /// Starts listening, from the switches as they are now. Safe to call
  /// again.
  void start() {
    if (_started) return;
    _started = true;
    _applied = _features.value;
    _features.addListener(_onChanged);
  }

  /// What the latest change of the switches cancelled, once its reconcile
  /// has finished; nothing cancelled while no switch has changed.
  ///
  /// The Features screen reads it right after it flips a switch, for the
  /// snackbar: the flip has already started the reconcile, so reading this
  /// does not start a second one.
  Future<ReminderCancellation> get settled => _settled;

  void _onChanged() {
    final before = _applied;
    final after = _features.value;
    _applied = after;
    if (!_isOpen()) return;
    final changed = [
      for (final feature in followed)
        if (before.isOn(feature) != after.isOn(feature)) feature,
    ];
    // Any other switch owns no alarm: nothing to cancel or to schedule.
    if (changed.isEmpty) return;
    int cancelled(LibraryFeature feature) =>
        changed.contains(feature) && !after.isOn(feature)
        ? _scheduledFor(feature)
        : 0;
    final cancellation = ReminderCancellation(
      todo: cancelled(LibraryFeature.todo),
      calendar: cancelled(LibraryFeature.calendar),
    );
    _settled = _resync().then((_) => cancellation);
  }

  /// Stops listening.
  void dispose() {
    if (_started) _features.removeListener(_onChanged);
    _started = false;
  }
}
