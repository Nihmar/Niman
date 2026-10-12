/// The colours of a `calendar.txt` line in the editor (#730): where its
/// date, its week and weekday, its event times, its asides, its tokens and
/// its `rem:` are, and the wavy flag a head that does not match its date
/// wears.
///
/// Read from the same parse the journal reads with ([parseCalendarLine]),
/// so the editor and the list never disagree about what a line says. The
/// `+`/`@`/`#`/`key:value` runs are todo.txt's own roles: the two formats
/// share the vocabulary, and the format's promise is that `grep +thesis`
/// reads both files together.
library;

import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/editor/highlighting.dart';

/// Whether the file named [name] is the calendar the editor colours.
bool isCalendarTxtFile(String name) => name.toLowerCase() == 'calendar.txt';

/// The runs of `calendar.txt` [line], disjoint and in order.
List<Token> calendarTxtTokens(String line) {
  final parsed = parseCalendarLine(line);
  final tokens = <Token>[];
  void add(TokenKind kind, int start, int end) {
    if (end > start) tokens.add(Token(kind, start, end));
  }

  final head = parsed.head;
  if (head != null) {
    // The head is a goal's (`2026`, `2026-10`, `2026-10-05 w41`) or a
    // day's: a goal is the plan itself and wears the goal's green, a day
    // the calendar's own greys.
    final goal = parsed.kind != CalendarLineKind.day;
    // The date, at the head's start: `2026-10-12`, `2026-10`, `2026`.
    final date = _dateAtStart.matchAsPrefix(head);
    if (date != null) {
      add(
        goal ? TokenKind.calendarGoal : TokenKind.calendarDate,
        date.start,
        date.end,
      );
      // The week and the weekday after it, when the head carries them; the
      // one the parser flagged keeps its colour and wears the flag.
      final week = _weekInHead.matchAsPrefix(head, date.end);
      if (week != null) {
        // The regex eats the space before `wNN`; the space stays plain.
        add(_weekKind(parsed), week.start + 1, week.end);
      }
      final weekday = parsed.weekday;
      if (weekday != null && head.endsWith(weekday)) {
        final start = head.length - weekday.length;
        add(
          parsed.weekdayMismatch
              ? TokenKind.calendarMismatch
              : TokenKind.calendarHead,
          start,
          head.length,
        );
      }
    }
  }

  for (final event in parsed.events) {
    final time = event.time;
    if (time != null) {
      add(TokenKind.calendarTime, event.start, event.start + time.raw.length);
    }
    for (final aside in event.asides) {
      add(TokenKind.calendarAside, aside.start, aside.end);
    }
  }

  // Every `+`/`@`/`#`/`key:value` run, the events' and a goal's own, in
  // the roles todo.txt uses for them.
  for (final token in [...parsed.tokens, ..._eventTokens(parsed)]) {
    add(_tokenKind(token.kind), token.start, token.end);
  }

  tokens.sort((a, b) => a.start.compareTo(b.start));
  return tokens;
}

/// The tokens of every event of [parsed], in order.
List<CalendarToken> _eventTokens(CalendarLine parsed) => [
  for (final event in parsed.events) ...event.tokens,
];

/// The kind a head's week number wears: flagged when it does not match the
/// date, else the head's own — a goal's green, a day's grey.
TokenKind _weekKind(CalendarLine parsed) {
  if (parsed.weekMismatch) return TokenKind.calendarMismatch;
  return parsed.kind == CalendarLineKind.day
      ? TokenKind.calendarHead
      : TokenKind.calendarGoal;
}

TokenKind _tokenKind(CalendarTokenKind kind) => switch (kind) {
  CalendarTokenKind.project => TokenKind.todoProject,
  CalendarTokenKind.context => TokenKind.todoContext,
  CalendarTokenKind.tag => TokenKind.tag,
  CalendarTokenKind.keyValue => TokenKind.todoKeyValue,
};

/// The date at a head's start: a day, a month or a year.
final RegExp _dateAtStart = RegExp(r'(\d{4}-\d{2}-\d{2}|\d{4}-\d{2}|\d{4})');

/// The `wNN` a head carries after its date.
final RegExp _weekInHead = RegExp(r' w(\d{1,2})');
