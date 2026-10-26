/// What a write to `calendar.txt` is handed (#730, #1191): the event a form
/// holds as a [CalendarEventDraft], and where an event already in the file
/// is as a [CalendarEventRef].
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/parser.dart';

/// What Add event asks the file to hold (#730): the text, a time when one
/// was chosen, the reminder's own clock time, and the rule it repeats by.
@immutable
final class CalendarEventDraft {
  /// Creates a draft; [text] is what the event says, without its
  /// terminator and without the `rec:`, `until:` and `except:` tokens, which
  /// [recurrence] carries.
  const new({
    required this.text,
    this.startMinutes,
    this.endMinutes,
    this.reminderMinutes,
    this.recurrence,
  });

  /// The event's text as typed: its `+`/`@`/`#`/`key:value` tokens
  /// included, its rule's excluded.
  final String text;

  /// The start, minutes from midnight, or null for an event written with
  /// no time at all.
  final int? startMinutes;

  /// The end, when the event is a range.
  final int? endMinutes;

  /// The reminder's clock time, minutes from midnight: the lead time is
  /// the caller's arithmetic.
  final int? reminderMinutes;

  /// The rule the event repeats by, with its end and the days it skips
  /// (#1191), or null for an event that happens once.
  final CalendarRecurrence? recurrence;

  /// This draft with [recurrence] in place of its own (null: a plain
  /// event).
  CalendarEventDraft withRecurrence(CalendarRecurrence? recurrence) =>
      CalendarEventDraft(
        text: text,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        reminderMinutes: reminderMinutes,
        recurrence: recurrence,
      );
}

/// Where an event is, as the snapshot that showed it measured it (#730):
/// the line, the day it belongs to, and the event's own offset in the
/// line.
///
/// The write re-reads the file before it splices, so all three are
/// checked against what is on disk then: a file that moved under the
/// screen makes the write a no-op rather than an edit of the wrong event.
@immutable
final class CalendarEventRef {
  /// Creates a reference to the event opening at [start] on [day]'s line.
  const new({required this.line, required this.day, required this.start});

  /// The 0-based line index in the file.
  final int line;

  /// The day the line heads (the line's date).
  final DateTime day;

  /// The event's first character in the line.
  final int start;
}

/// The draft an edit of [event] starts from: its text without the tokens
/// the form holds apart — the rule's three, when it has a readable `rec:`,
/// and a clock `rem:` — its times, its reminder and its recurrence.
CalendarEventDraft calendarDraftOf(CalendarEvent event) {
  final recurrence = event.recurrence;
  final start = event.time?.first;
  final end = event.time?.isRange == true ? event.time?.end : null;
  final reminder = _clockMinutes(event.reminder);
  final held = <CalendarToken>[
    if (recurrence != null)
      for (final token in event.tokens)
        if (ruleKeyOf(token) != null && !isUnreadableRuleToken(token)) token,
    if (reminder != null)
      for (final token in event.tokens)
        if (token.start == event.reminderStart) token,
  ];
  return CalendarEventDraft(
    text: _withoutTokens(event, held),
    startMinutes: start?.minutes,
    endMinutes: end?.minutes,
    reminderMinutes: reminder,
    recurrence: recurrence,
  );
}

/// [event]'s text with [tokens] cut out, and the space that followed each.
String _withoutTokens(CalendarEvent event, List<CalendarToken> tokens) {
  var text = event.text;
  final spans = [
    for (final token in tokens)
      (token.start - event.textStart, token.end - event.textStart),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  for (final (from, to) in spans) {
    if (from < 0 || to > text.length) continue;
    var cut = to;
    while (cut < text.length && text[cut] == ' ') {
      cut++;
    }
    text = text.substring(0, from) + text.substring(cut);
  }
  return text.trim();
}

/// `HH:MM` as minutes from midnight, or null.
int? _clockMinutes(String? clock) {
  if (clock == null) return null;
  final parts = clock.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}
