import 'dart:async';

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/reminder_cancellation.dart';

/// Writes the switches of Settings → Features (#1109) and answers what a
/// switch cost.
///
/// Edits run one after the other, each computed from the switches as the
/// last one left them, so two quick flips never overwrite each other. After
/// an edit that turned Todo or Calendar off it asks the shell how many
/// reminders that cancelled and hands the number, with the way back, to
/// [onCancelled]. It never reconciles reminders itself: the todo
/// controller follows the library's features.
final class FeaturesEditor {
  /// An editor over [session]'s library. [featureReconcile] is the shell's
  /// answer to *how many reminders were cancelled* (null says nothing), and
  /// [onCancelled] is told when it is more than none.
  new({
    required this.session,
    required this.featureReconcile,
    required this.onCancelled,
  });

  /// The library whose switches are written.
  final LibrarySession session;

  /// The todo controller's settled reconcile, or null where no shell is
  /// wired.
  final Future<ReminderCancellation> Function()? featureReconcile;

  /// Told how many reminders an edit cancelled, with the way to undo it:
  /// that turns the switches that went off back as they were.
  final void Function(int cancelled, Future<void> Function() undo) onCancelled;

  Future<void> _chain = Future<void>.value();

  /// The two switches whose reminders go with them.
  static const List<LibraryFeature> _reminderFeatures = [
    LibraryFeature.todo,
    LibraryFeature.calendar,
  ];

  /// Applies [change] to the switches as they stand when its turn comes.
  Future<void> edit(Features Function(Features) change) {
    final next = _chain.then((_) => _run(change));
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _run(Features Function(Features) change) async {
    final before = session.features.value;
    final after = change(before);
    if (after == before) return;
    await session.setFeatures(after);
    final wentOff = [
      for (final feature in _reminderFeatures)
        if (before.isOn(feature) && !after.isOn(feature)) feature,
    ];
    final reconcile = featureReconcile;
    if (wentOff.isEmpty || reconcile == null) return;
    final cancelled = await reconcile();
    if (cancelled.total == 0) return;
    onCancelled(cancelled.total, () => _undo(before, wentOff));
  }

  /// Turns [features] back to the value [before] gave them, leaving every
  /// other switch as the user has set it since.
  Future<void> _undo(Features before, List<LibraryFeature> features) => edit(
    (now) => features.fold(
      now,
      (all, feature) => all.withSwitch(feature, on: before.own(feature)),
    ),
  );
}
