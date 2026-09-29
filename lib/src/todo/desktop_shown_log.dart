/// What a desktop run has already shown, and for which task (#42, #497).
library;

import 'package:niman/src/todo/todo_reminder.dart';

/// The record of the reminders one desktop run has shown.
///
/// A reminder stays wanted for `reminderGrace` past its moment, so every
/// reconcile in that hour hands it over again and the backend has to know
/// it was delivered. The record is "this task at this moment": by moment
/// alone, two different tasks due at the same minute would suppress each
/// other; by id alone, an edit would show a task twice, because the id
/// hashes the whole description (`due:` and `rem:` included) and an edit
/// gives the task a new one while its moment stands.
///
/// So it keeps the shown ids per moment, and [reconcile] settles what an id
/// that is new at a shown moment means, by one rule: **it is the same task,
/// rewritten, when a shown id of that moment has left the wanted set;
/// otherwise it is another task and it is shown.** Every shown id that
/// left the set is taken as the task it was rewritten into, one for one,
/// in the order they appear; a shown id nothing replaced is a deleted task
/// and is forgotten.
///
/// A show takes time (a daemon that is slow to answer), and a reconcile that
/// comes in meanwhile must not post the reminder again: an id is recorded
/// when its show starts ([begin]) and stays recorded if the show succeeds;
/// a show that fails takes the record back, so the next reconcile retries
/// it. The record is per id, so one task's failure is not hidden by another
/// task's success at the same moment.
final class DesktopShownLog {
  /// Creates an empty log.
  new();

  /// Each id shown, or being shown, by the moment it was due.
  final Map<DateTime, Map<int, _Show>> _shown = {};

  /// When [reminder] was shown, or null if it was not (in this run) or is
  /// still being shown.
  DateTime? shownAt(TodoReminder reminder) =>
      _shown[reminder.when]?[reminder.id]?.at;

  /// Whether [reminder] has been shown or is being shown: not to be posted.
  bool isShown(TodoReminder reminder) =>
      _shown[reminder.when]?.containsKey(reminder.id) ?? false;

  /// Whether a show of [reminder] has started and not yet answered.
  bool isShowing(TodoReminder reminder) {
    final show = _shown[reminder.when]?[reminder.id];
    return show != null && show.at == null;
  }

  /// Records that a show of [reminder] starts now, and answers what
  /// settles it: called with the time it was shown at, or with null when it
  /// failed (the record goes, and the reminder is shown by the next
  /// reconcile).
  void Function(DateTime? at) begin(TodoReminder reminder) {
    final show = _Show(reminder.when);
    (_shown[reminder.when] ??= {})[reminder.id] = show;
    return (at) {
      if (at != null) {
        show.at = at;
        return;
      }
      // The id it was recorded under may have changed since, when the task
      // was rewritten while the show was in flight: it is found by the
      // record itself.
      final moment = _shown[show.moment];
      moment?.removeWhere((_, other) => identical(other, show));
      if (moment != null && moment.isEmpty) _shown.remove(show.moment);
    };
  }

  /// Carries the record over the edits in [wanted], the whole set the
  /// service is reconciling. Called before anything is scheduled, so that
  /// an edited task already reads as shown.
  void reconcile(Iterable<TodoReminder> wanted) {
    if (_shown.isEmpty) {
      return;
    }
    final wantedIds = {for (final reminder in wanted) reminder.id};
    for (final moment in _shown.keys.toList()) {
      final shown = _shown[moment]!;
      final gone = [
        for (final id in shown.keys)
          if (!wantedIds.contains(id)) id,
      ];
      if (gone.isEmpty) {
        continue;
      }
      final fresh = [
        for (final reminder in wanted)
          if (reminder.when == moment && !shown.containsKey(reminder.id))
            reminder.id,
      ];
      for (var i = 0; i < gone.length; i++) {
        final show = shown.remove(gone[i])!;
        if (i < fresh.length) {
          shown[fresh[i]] = show;
        }
      }
      if (shown.isEmpty) {
        _shown.remove(moment);
      }
    }
  }
}

/// One reminder's show: its moment, and when it was shown (null while it is
/// in flight).
final class _Show {
  new(this.moment);

  final DateTime moment;
  DateTime? at;
}
