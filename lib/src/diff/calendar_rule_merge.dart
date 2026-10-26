/// Merging the rule events of one day line (#1191).
///
/// The calendar merge treats a day's events as a set, and an event is its
/// text: so two devices that each skipped a different occurrence of the same
/// repeating event — each adding a date to its `except:` — would hand the
/// set two events, and every occurrence would show twice. A rule event is
/// the same event whatever its `until:` and `except:` say, so those two are
/// taken out to pair the copies ([calendarRuleKey]), and a pair merges into
/// one event:
///
/// - **`except:`** is a set merged against the base: the days either side
///   added are in, and a day the base had stays unless a side took it out.
///   With no base it is the union. (Niman only ever adds days; a hand edit
///   that gives a skipped day back is not undone by the other side still
///   having it.)
/// - **`until:`** is a date merged against the base: the side that did not
///   change it follows the one that did. When both did — or there is no
///   base — the earlier wins, and no `until:` counts as later than any: a
///   rule one device ended and the other left running is ended.
///
/// Any other difference between two events is a real edit and both are
/// kept, as for every event. Pure Dart, no I/O.
library;

import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_rule_tokens.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// The rule events among [events], by [calendarRuleKey]: the first of each
/// key, since a second copy on one side is the same event written twice.
Map<String, CalendarEvent> calendarRuleEventsByKey(
  Iterable<CalendarEvent> events,
) {
  final byKey = <String, CalendarEvent>{};
  for (final event in events) {
    final key = calendarRuleKey(event);
    if (key != null) byKey.putIfAbsent(key, () => event);
  }
  return byKey;
}

/// The one event two copies of a rule event merge into: [local] and
/// [remote] are the sides' copies (same [calendarRuleKey]) and [base] the
/// common version's, or null when there is none. Written the way [local]
/// writes it, with the merged `until:` and `except:`.
String mergeRuleEvents({
  required CalendarEvent local,
  required CalendarEvent remote,
  CalendarEvent? base,
}) {
  // A side that left the event as the base had it takes the other's, to
  // the character.
  if (base != null && local.raw == base.raw) return remote.raw;
  if (base != null && remote.raw == base.raw) return local.raw;
  final mine = local.recurrence!.bounds;
  final theirs = remote.recurrence!.bounds;
  final original = base?.recurrence?.bounds;
  final merged = RecurrenceBounds(
    until: _mergedUntil(
      original: original?.until,
      local: mine.until,
      remote: theirs.until,
      hasBase: original != null,
    ),
    except: _mergedExcept(
      original: original?.except,
      local: mine.except,
      remote: theirs.except,
    ),
  );
  return calendarEventRawWithBounds(local, merged);
}

DateTime? _mergedUntil({
  required DateTime? original,
  required DateTime? local,
  required DateTime? remote,
  required bool hasBase,
}) {
  if (local == remote) return local;
  if (hasBase && local == original) return remote;
  if (hasBase && remote == original) return local;
  if (local == null) return remote;
  if (remote == null) return local;
  return dateOnly(local).isBefore(dateOnly(remote)) ? local : remote;
}

Set<DateTime> _mergedExcept({
  required Set<DateTime>? original,
  required Set<DateTime> local,
  required Set<DateTime> remote,
}) {
  final union = {...local, ...remote};
  if (original == null) return union;
  return {
    for (final day in union)
      // Given back by a side: out.
      if (!original.contains(day) ||
          (local.contains(day) && remote.contains(day)))
        day,
  };
}
