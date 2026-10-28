/// Keeping a full-stamp `rem:` where its event is (#1226).
///
/// An event's `rem:` is a clock time on its own day (`rem:16:30`), which
/// moves with the event by itself, or a full stamp that names its own day
/// (`rem:2026-10-12T16:30`, #1192), which does not: written on a copy of the
/// event it keeps pointing where it did. The distance in days from the event
/// to its stamp is what the stamp says, so a copy on another day takes the
/// stamp with the same distance.
library;

import 'package:niman/src/calendar/calendar_event_draft.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/calendar_days.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// [draft] for a copy of the event on [to], when the event it came from was
/// on [from] and its reminder [stamp] (the `rem:` value as written, or null).
///
/// A draft whose text no longer holds [stamp] — the user wrote another — is
/// left as it is: that is a date the user chose. A [stamp] that is only a
/// clock time, or none, changes nothing either.
CalendarEventDraft calendarDraftOnDay(
  CalendarEventDraft draft, {
  required String? stamp,
  required DateTime from,
  required DateTime to,
}) {
  if (stamp == null) return draft;
  final date = _stampDate.firstMatch(stamp)?.group(1);
  final day = date == null ? null : parseIsoDate(date);
  final distance = daysBetween(dateOnly(from), dateOnly(to));
  if (day == null || distance == 0) return draft;
  final moved = formatIsoDate(addCalendarDays(day, distance));
  final text = draft.text;
  for (final token in calendarTokens(text, asides: calendarAsides(text, 0))) {
    final colon = token.value.indexOf(':');
    if (token.kind != CalendarTokenKind.keyValue || colon < 0) continue;
    if (token.value.substring(0, colon).toLowerCase() != 'rem') continue;
    if (token.value.substring(colon + 1) != stamp) continue;
    final at = token.start + colon + 1;
    return draft.withText(
      text.substring(0, at) + moved + text.substring(at + date!.length),
    );
  }
  return draft;
}

/// The date a full-stamp `rem:` value opens with.
final RegExp _stampDate = RegExp(r'^(\d{4}-\d{2}-\d{2})T');
