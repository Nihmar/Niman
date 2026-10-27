/// Data-source seam over `calendar.txt` (#730): what the journal reads.
///
/// The controller talks to this interface; production uses the real store
/// (disk reads, covered by unit tests) while widget tests inject an
/// in-memory fake (`test/fakes/fake_calendar_source.dart`): `testWidgets`
/// runs in a fake-async zone where real filesystem I/O never completes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';

/// What the calendar UI layer needs from `calendar.txt`: the file, and
/// the writes an event is added, edited and deleted with (#730), and an
/// occurrence of a repeating one skipped, edited and deleted (#1191).
abstract interface class CalendarSource {
  /// Loads and parses the file (a missing file reads as empty).
  Future<CalendarSnapshot> load();

  /// Probes the file's existence + size + mtime off the UI isolate.
  Future<CalendarFileProbe> probe();

  /// Adds [event] to [day] — making the file, and the day's line, when
  /// missing — and answers the file as it is after the write.
  Future<CalendarSnapshot> addEvent(DateTime day, CalendarEventDraft event);

  /// Replaces the event [ref] names with [event]; a file that no longer
  /// holds it is left as it is.
  Future<CalendarSnapshot> updateEvent(
    CalendarEventRef ref,
    CalendarEventDraft event,
  );

  /// Takes the event [ref] names out; a file that no longer holds it is
  /// left as it is.
  Future<CalendarSnapshot> deleteEvent(CalendarEventRef ref);

  /// Skips [occurrence] of the repeating event [ref] names (#1191): the
  /// day joins its `except:`.
  Future<CalendarSnapshot> skipOccurrence(
    CalendarEventRef ref,
    DateTime occurrence,
  );

  /// Changes [occurrence] of the repeating event [ref] names to [event] as
  /// [scope] says (#1191).
  Future<CalendarSnapshot> updateOccurrence(
    CalendarEventRef ref,
    DateTime occurrence,
    CalendarEventDraft event,
    CalendarOccurrenceScope scope,
  );

  /// Deletes [occurrence] of the repeating event [ref] names as [scope]
  /// says (#1191).
  Future<CalendarSnapshot> deleteOccurrence(
    CalendarEventRef ref,
    DateTime occurrence,
    CalendarOccurrenceScope scope,
  );
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
