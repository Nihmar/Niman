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
final class DesktopShownLog {
  /// Creates an empty log.
  new();

  /// When each id was shown, by the moment it was due.
  final Map<DateTime, Map<int, DateTime>> _shown = {};

  /// When [reminder] was shown, or null if it was not (in this run).
  DateTime? shownAt(TodoReminder reminder) =>
      _shown[reminder.when]?[reminder.id];

  /// Whether [reminder] has been shown.
  bool isShown(TodoReminder reminder) => shownAt(reminder) != null;

  /// Records that [reminder] was shown at [at].
  void record(TodoReminder reminder, DateTime at) {
    (_shown[reminder.when] ??= {})[reminder.id] = at;
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
        final at = shown.remove(gone[i])!;
        if (i < fresh.length) {
          shown[fresh[i]] = at;
        }
      }
      if (shown.isEmpty) {
        _shown.remove(moment);
      }
    }
  }
}
