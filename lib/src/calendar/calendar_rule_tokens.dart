/// Changing the `until:` and `except:` of an event already in a day's line
/// (#1191): the two tokens a skip and a "this and following" are written
/// with.
///
/// Each function takes the line as it is and the event on it, and answers
/// the line with that one token changed — replaced where the event already
/// has one, added at the event's end where it has none. Every other
/// character of the line, the rest of the event included, is as it was.
library;

import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';

/// [line] with [day] added to the event's `except:`: the first readable
/// list is rewritten as the sorted union, or a new token closes the event
/// when it has none. Null when [event] has no rule.
String? calendarLineWithException(
  String line,
  CalendarEvent event,
  DateTime day,
) {
  final recurrence = event.recurrence;
  if (recurrence == null) return null;
  final bounds = RecurrenceBounds(
    until: recurrence.bounds.until,
    except: {...recurrence.bounds.except, dateOnly(day)},
  );
  final token = bounds.exceptToken!;
  final first = _firstToken(event, 'except', readable: true);
  return _replacedOrAdded(line, event, first, token);
}

/// [line] with the event's `until:` set to [day]: the first one the event
/// has is rewritten, or a new token closes the event. Null when [event]
/// has no rule.
String? calendarLineWithUntil(String line, CalendarEvent event, DateTime day) {
  if (event.recurrence == null) return null;
  final token = RecurrenceBounds(until: day).untilToken!;
  final first = _firstToken(event, 'until', readable: false);
  return _replacedOrAdded(line, event, first, token);
}

/// The first token of [event] with key [key] — a readable one only, when
/// [readable] — or null.
CalendarToken? _firstToken(
  CalendarEvent event,
  String key, {
  required bool readable,
}) {
  for (final token in event.tokens) {
    if (ruleKeyOf(token) != key) continue;
    if (readable && isUnreadableRuleToken(token)) continue;
    return token;
  }
  return null;
}

String _replacedOrAdded(
  String line,
  CalendarEvent event,
  CalendarToken? old,
  String token,
) {
  if (old != null) {
    return line.substring(0, old.start) + token + line.substring(old.end);
  }
  return '${line.substring(0, event.end)} $token${line.substring(event.end)}';
}
