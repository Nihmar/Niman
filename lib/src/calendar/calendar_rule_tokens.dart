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

/// What two copies of one rule event have in common (#1191): the event with
/// its `until:` and `except:` taken out and the spaces between its words
/// made one — its time, text, tokens and `rec:` — or null when the event
/// has no readable rule, or an `until:` or `except:` the grammar cannot
/// read (kept as it is, and never paired).
///
/// The sync merge pairs the rule events of a day line by this: two devices
/// that each skipped a different occurrence of the same rule wrote two
/// different events with one key.
String? calendarRuleKey(CalendarEvent event) {
  if (event.recurrence == null || _hasUnreadableBound(event)) return null;
  final bounds = _boundTokens(event);
  var raw = event.raw;
  for (final token in bounds.reversed) {
    raw =
        raw.substring(0, token.start - event.start) +
        raw.substring(token.end - event.start);
  }
  return raw.trim().split(RegExp(r'\s+')).join(' ');
}

/// [event] as written, with its `until:` and `except:` replaced by
/// [bounds]: the first of each is rewritten where it stands (or one is added
/// at the event's end), the others go, and a bound [bounds] does not have
/// takes its token away. The event's other characters are as they were.
String calendarEventRawWithBounds(
  CalendarEvent event,
  RecurrenceBounds bounds,
) {
  var raw = event.raw;
  final spans = <(int, int, String?)>[];
  var untilDone = bounds.untilToken == null;
  var exceptDone = bounds.exceptToken == null;
  for (final token in _boundTokens(event)) {
    final from = token.start - event.start;
    final to = token.end - event.start;
    if (ruleKeyOf(token) == 'until' && !untilDone) {
      untilDone = true;
      spans.add((from, to, bounds.untilToken));
    } else if (ruleKeyOf(token) == 'except' && !exceptDone) {
      exceptDone = true;
      spans.add((from, to, bounds.exceptToken));
    } else {
      spans.add((from, to, null));
    }
  }
  for (final (from, to, text) in spans.reversed) {
    if (text != null) {
      raw = raw.substring(0, from) + text + raw.substring(to);
      continue;
    }
    // A token taken out takes the spaces before it along.
    var start = from;
    while (start > 0 && raw[start - 1] == ' ') {
      start--;
    }
    raw = raw.substring(0, start) + raw.substring(to);
  }
  final added = [
    if (!untilDone) ?bounds.untilToken,
    if (!exceptDone) ?bounds.exceptToken,
  ];
  return added.isEmpty ? raw : '$raw ${added.join(' ')}';
}

/// The `until:` and `except:` tokens of [event], in the order written.
List<CalendarToken> _boundTokens(CalendarEvent event) => [
  for (final token in event.tokens)
    if (ruleKeyOf(token) case 'until' || 'except') token,
];

bool _hasUnreadableBound(CalendarEvent event) =>
    _boundTokens(event).any(isUnreadableRuleToken);

/// [text] without any `rec:`, `until:` or `except:` token, readable or not,
/// and the spaces that followed each (#1227).
///
/// What the writer does to a draft that carries a rule: the form's rule,
/// end and skipped days are the only ones the line is left with. A token the
/// grammar cannot read, or a second copy of one, would otherwise stay in the
/// text and — the first `until:` and the first `rec:` counting — win over
/// the ones the form writes.
String calendarTextWithoutRuleTokens(String text) {
  final tokens = [
    for (final token in calendarTokens(text, asides: calendarAsides(text, 0)))
      if (ruleKeyOf(token) != null) token,
  ];
  var out = text;
  for (final token in tokens.reversed) {
    var cut = token.end;
    while (cut < out.length && out[cut] == ' ') {
      cut++;
    }
    out = out.substring(0, token.start) + out.substring(cut);
  }
  return out.trim();
}
