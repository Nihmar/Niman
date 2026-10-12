/// Data-source seam over `calendar.txt` (#730): what the journal reads.
///
/// The controller talks to this interface; production uses the real store
/// (disk reads, covered by unit tests) while widget tests inject an
/// in-memory fake (`test/fakes/fake_calendar_source.dart`): `testWidgets`
/// runs in a fake-async zone where real filesystem I/O never completes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/calendar/calendar_store.dart';

/// What the calendar UI layer needs from `calendar.txt`.
///
/// Phase 1 is read-only; the write ops (add, edit, delete an event) join
/// this interface with the write phase, as `todo.txt`'s does.
abstract interface class CalendarSource {
  /// Loads and parses the file (a missing file reads as empty).
  Future<CalendarSnapshot> load();

  /// Probes the file's existence + size + mtime off the UI isolate.
  Future<CalendarFileProbe> probe();
}

/// Builds the calendar file source per library root.
///
/// The shell reads this provider for the controller's factory so widget
/// tests can override it with an in-memory fake (the real store's
/// `Isolate.run` reads never complete in the fake-async test zone).
final calendarSourceFactoryProvider = Provider<CalendarSource Function(String)>(
  (ref) => _defaultCalendarSource,
);

/// The production file source for [root].
CalendarSource _defaultCalendarSource(String root) => CalendarStore(root: root);
