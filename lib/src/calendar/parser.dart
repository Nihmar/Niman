/// Line model + text round-trip for `calendar.txt` (#730).
///
/// The format (terokarvinen.com/2021/calendar-txt), as the page and the
/// design record read it:
///
/// ```text
/// 2026  The year of the move +home
/// 2026-10  Finish the thesis draft +thesis
/// 2026-10-05 w41  Reading week
/// 2026-10-05 w41 Mon  9-12 library +thesis @library.
/// 2026-10-12 w42 Mon  13:30-14 call with Marta @phone rem:13:15.
/// ```
///
/// One line per day, its head `YYYY-MM-DD wWW Aaa`, its events after two
/// spaces, each ending in `.` (or `;`), in time order; a line whose head
/// has no weekday is that week's, month's or year's goal. A time is `9`,
/// `08:15`, `0815`, a range `9-12`, or with a `Z` suffix for UTC; a
/// leading number is an hour, which is the format's own rule.
///
/// The model keeps [CalendarLine.raw] verbatim and [CalendarLine.toLine]
/// returns it: a line nobody edited round-trips byte for byte, which is
/// what the writer needs — it only ever rewrites the line it was asked to
/// change. Pure Dart, no I/O: the store reads the bytes off the UI
/// isolate and parses them here.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/weeks.dart';

/// What a line is.
enum CalendarLineKind {
  /// A day: a date, an optional week and weekday, then its events.
  day,

  /// A week's goal: the Monday's date, the week, then its text.
  weekGoal,

  /// A month's goal: `YYYY-MM`, then its text.
  monthGoal,

  /// A year's goal: `YYYY`, then its text.
  yearGoal,

  /// Anything else: kept, and shown as written.
  other,
}

/// A token of a line, and where it sits in the line.
@immutable
final class CalendarToken {
  /// Creates a token of [kind] over `start`..`end`.
  const new({
    required this.kind,
    required this.value,
    required this.start,
    required this.end,
  });

  /// What the token is.
  final CalendarTokenKind kind;

  /// The token's text after its sigil (`+thesis` → `thesis`,
  /// `rem:13:15` → `rem:13:15`).
  final String value;

  /// Offset of the token's first character.
  final int start;

  /// Offset one past the token's last character.
  final int end;
}

/// The kinds of token a calendar line carries, read as `todo.txt` reads
/// its own.
enum CalendarTokenKind {
  /// `+project`.
  project,

  /// `@context`.
  context,

  /// `#tag`.
  tag,

  /// `key:value`, `rem:` included.
  keyValue,
}

/// One time as written, and what it reads as.
@immutable
final class CalendarMoment {
  /// Creates a moment of [raw], [minutes] from midnight, in UTC when
  /// [utc].
  const new({required this.raw, required this.minutes, required this.utc});

  /// The time as written (`9`, `08:15`, `0815`, `0600Z`).
  final String raw;

  /// Minutes from midnight, of the time as written.
  final int minutes;

  /// Whether the written time ends in `Z`: it is UTC, not the device's
  /// zone.
  final bool utc;

  /// The hour on the clock it was written with.
  int get hour => minutes ~/ 60;

  /// The minute on the clock it was written with.
  int get minute => minutes % 60;

  @override
  bool operator ==(Object other) =>
      other is CalendarMoment &&
      other.raw == raw &&
      other.minutes == minutes &&
      other.utc == utc;

  @override
  int get hashCode => Object.hash(raw, minutes, utc);

  @override
  String toString() => 'CalendarMoment($raw)';
}

/// The time part of an event: a start, an end, or both, as written.
@immutable
final class CalendarEventTime {
  /// Creates a time over `start`..`end` (at least one is given).
  const new({required this.raw, this.start, this.end});

  /// The time as written (`9-12`, `0600Z`, `13:30-14`, `-12:00`).
  final String raw;

  /// The start, when one is written.
  final CalendarMoment? start;

  /// The end, when one is written.
  final CalendarMoment? end;

  /// Whether both ends are written.
  bool get isRange => start != null && end != null;

  /// The moment the event begins, for ordering: the start, or the end when
  /// only one is written.
  CalendarMoment? get first => start ?? end;

  @override
  bool operator ==(Object other) =>
      other is CalendarEventTime &&
      other.raw == raw &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(raw, start, end);

  @override
  String toString() => 'CalendarEventTime($raw)';
}

/// A `( … )` aside of an event, shown dimmed and never read for tokens.
@immutable
final class CalendarAside {
  /// Creates an aside over `start`..`end` (the parentheses included).
  const new({required this.start, required this.end});

  /// Offset of the aside's opening parenthesis.
  final int start;

  /// Offset one past the aside's closing parenthesis.
  final int end;

  @override
  bool operator ==(Object other) =>
      other is CalendarAside && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// One event of a day line.
@immutable
final class CalendarEvent {
  /// Creates an event; use [parseCalendarLine], not this constructor.
  const new({
    required this.raw,
    required this.text,
    required this.start,
    required this.textStart,
    required this.end,
    this.time,
    this.reminder,
    this.reminderStart,
    this.reminderEnd,
    this.asides = const <CalendarAside>[],
    this.tokens = const <CalendarToken>[],
  });

  /// The event as written, the time included and the closing `.`/`;`
  /// excluded — what a write splices back and a merge compares.
  final String raw;

  /// The event's text as written, the time excluded: what the journal
  /// shows beside the time.
  final String text;

  /// Offset of the event's first character (its time, when it has one).
  final int start;

  /// Offset of [text]'s first character.
  final int textStart;

  /// Offset one past the event's last character (its terminator excluded).
  final int end;

  /// The time it was written with, or null for an event with none (kept,
  /// and shown after the timed ones).
  final CalendarEventTime? time;

  /// The first `rem:` value as written (`13:15`, `2026-10-13T18:00`), or
  /// null. The date comes from the line's own.
  final String? reminder;

  /// Offset of the `rem:`'s first character, for the editor's colouring.
  final int? reminderStart;

  /// Offset one past the `rem:`.
  final int? reminderEnd;

  /// The `( … )` asides, in order.
  final List<CalendarAside> asides;

  /// The `+`/`@`/`#`/`key:value` tokens, asides excluded, in order.
  final List<CalendarToken> tokens;

  /// The event's `+project` values, in order.
  List<String> get projects => _values(CalendarTokenKind.project);

  /// The event's `@context` values, in order.
  List<String> get contexts => _values(CalendarTokenKind.context);

  /// The event's `#tag` values, in order.
  List<String> get hashtags => _values(CalendarTokenKind.tag);

  List<String> _values(CalendarTokenKind kind) => [
    for (final token in tokens)
      if (token.kind == kind) token.value,
  ];

  /// Whether the event has no text at all (a stray `.`).
  bool get isEmpty => raw.trim().isEmpty;

  @override
  String toString() => 'CalendarEvent(${raw.trim()})';
}

/// One parsed line of `calendar.txt`.
@immutable
final class CalendarLine {
  /// Creates a line; use [parseCalendarLine], not this constructor.
  const new({
    required this.raw,
    required this.kind,
    this.date,
    this.week,
    this.weekday,
    this.weekMismatch = false,
    this.weekdayMismatch = false,
    this.head,
    this.goalText,
    this.events = const <CalendarEvent>[],
    this.tokens = const <CalendarToken>[],
  });

  /// The line as written, its terminator excluded. Returned by [toLine],
  /// so an untouched line is byte-stable.
  final String raw;

  /// What the line is.
  final CalendarLineKind kind;

  /// The line's date: a day's day, a week goal's Monday, a month goal's
  /// first day, a year goal's 1 January. Null for
  /// [CalendarLineKind.other].
  final DateTime? date;

  /// The `wNN` week number as written, when the head carries one.
  final int? week;

  /// The weekday as written (`Mon`, `lun.`, `ke`), when the head carries
  /// one the parser recognised.
  final String? weekday;

  /// The written week number is not [date]'s ISO week: flagged in the
  /// editor, never fixed (the date is what is read).
  final bool weekMismatch;

  /// The written weekday is not [date]'s: flagged in the editor, never
  /// fixed.
  final bool weekdayMismatch;

  /// The head as written, the two spaces that follow it excluded
  /// (`2026-10-12 w42 Mon`, `2026-10-05 w41`, `2026-10`).
  final String? head;

  /// A goal's text as written ([goalText] is null on a day line).
  final String? goalText;

  /// A day's events, in the order they are written.
  final List<CalendarEvent> events;

  /// The `+`/`@`/`#`/`key:value` tokens of a goal's text.
  final List<CalendarToken> tokens;

  /// The line exactly as it was parsed (its terminator belongs to the
  /// file model).
  String toLine() => raw;

  /// Whether anything on the line is flagged: a week number or a weekday
  /// that does not match its date.
  bool get flagged => weekMismatch || weekdayMismatch;

  /// The key the sync merge pairs two lines by (#730): the date, for a day
  /// and for a goal (its period's start), as `YYYY-MM-DD`; null for a line
  /// that is neither.
  String? get key {
    final at = date;
    if (at == null || kind == CalendarLineKind.other) return null;
    final month = at.month.toString().padLeft(2, '0');
    final day = at.day.toString().padLeft(2, '0');
    return '${at.year}-$month-$day';
  }

  @override
  String toString() => 'CalendarLine(${kind.name}, ${toLine()})';
}

/// Parses one line of `calendar.txt`.
///
/// [weekdays] maps a recognised weekday name (lowercased, its trailing
/// period kept or dropped) to the ISO weekday number the app counts in
/// (1 = Monday). English's names are always known; the app adds its own
/// locales' names on top ([calendarWeekdayNames]).
///
/// A head Niman cannot read — a third token that is not a weekday it
/// knows — is read as that week's goal whose text starts with the token,
/// as the design record decides (#730): the harm is display only, and the
/// line is never rewritten.
CalendarLine parseCalendarLine(
  String line, {
  Map<String, int> weekdays = const <String, int>{},
}) {
  var raw = line;
  if (raw.endsWith('\r')) raw = raw.substring(0, raw.length - 1);
  final other = CalendarLine(raw: raw, kind: CalendarLineKind.other);
  if (raw.trim().isEmpty) return other;

  final year = _year.matchAsPrefix(raw);
  if (year != null) {
    final at = year.end;
    // `2026  The year of the move`: two spaces, then the text.
    if (raw.startsWith('  ', at)) {
      return _goal(
        raw,
        CalendarLineKind.yearGoal,
        DateTime(int.parse(year.group(1)!)),
        week: null,
        at: at,
      );
    }
  }

  final month = _month.matchAsPrefix(raw);
  if (month != null) {
    final at = month.end;
    if (raw.startsWith('  ', at)) {
      return _goal(
        raw,
        CalendarLineKind.monthGoal,
        DateTime(int.parse(month.group(1)!), int.parse(month.group(2)!)),
        week: null,
        at: at,
      );
    }
  }

  final day = _day.matchAsPrefix(raw);
  if (day == null) return other;
  final date = DateTime(
    int.parse(day.group(1)!),
    int.parse(day.group(2)!),
    int.parse(day.group(3)!),
  );
  final week = day.group(4) == null ? null : int.tryParse(day.group(4)!);
  final weekMismatch = week != null && week != isoWeekOf(date);
  final at = day.end;
  if (at >= raw.length) {
    // A day with nothing on it yet: a head, and the room to write.
    return CalendarLine(
      raw: raw,
      kind: CalendarLineKind.day,
      date: date,
      week: week,
      weekMismatch: weekMismatch,
      head: raw,
    );
  }
  if (raw.startsWith('  ', at)) {
    // `2026-10-05 w41  Reading week`: the head is a goal's.
    return _goal(raw, CalendarLineKind.weekGoal, date, week: week, at: at);
  }
  if (!raw.startsWith(' ', at)) {
    // `2026-10-051x`: no separator after the head at all.
    return _goal(raw, CalendarLineKind.weekGoal, date, week: week, at: at);
  }
  final word = _word.matchAsPrefix(raw, at + 1);
  final known = word == null
      ? null
      : weekdayNumberFor(word.group(0)!, weekdays);
  if (word == null || known == null) {
    // A third token Niman does not know as a weekday: the line reads as
    // the week's goal, its text starting at that token.
    return _goal(raw, CalendarLineKind.weekGoal, date, week: week, at: at);
  }
  final after = word.end;
  return CalendarLine(
    raw: raw,
    kind: CalendarLineKind.day,
    date: date,
    week: week,
    weekday: word.group(0),
    weekMismatch: weekMismatch,
    weekdayMismatch: known != date.weekday,
    head: raw.substring(0, after),
    events: parseCalendarEvents(raw, from: after),
  );
}

/// A goal line: [raw] from its head's end ([at]) is the text, and the
/// head's own date is the line's.
CalendarLine _goal(
  String raw,
  CalendarLineKind kind,
  DateTime date, {
  required int? week,
  required int at,
}) {
  return CalendarLine(
    raw: raw,
    kind: kind,
    date: date,
    week: week,
    weekMismatch: week != null && week != isoWeekOf(date),
    head: raw.substring(0, at),
    goalText: _textAfter(raw, at),
    tokens: calendarTokens(raw, from: at),
  );
}

/// The events of a day line, from [from] (the end of its head).
///
/// An event ends at a `.` or a `;` followed by a space or the line's end,
/// so `v1.2` and the dot that closes a `rem:16:30.` keep their event
/// together.
List<CalendarEvent> parseCalendarEvents(String raw, {required int from}) {
  final events = <CalendarEvent>[];
  var at = from;
  while (at < raw.length) {
    at = _skipSpaces(raw, at);
    if (at >= raw.length) break;
    final event = _parseEvent(raw, at);
    if (!event.isEmpty) events.add(event);
    at = event.end;
    // The terminator, and any space before the next event.
    at = _skipSpaces(raw, _afterTerminator(raw, event.end));
  }
  return events;
}

/// One event starting at [at] (already trimmed of leading spaces).
CalendarEvent _parseEvent(String raw, int at) {
  var cursor = at;
  CalendarEventTime? time;
  final timeMatch = _timeRange.matchAsPrefix(raw, cursor);
  if (timeMatch != null) {
    final written = timeMatch.group(0)!;
    final first = timeMatch.group(1);
    final second = timeMatch.group(2);
    final start = first == null || first.startsWith('-')
        ? null
        : parseCalendarMoment(first);
    final end = second != null
        ? parseCalendarMoment(second)
        : (first != null && first.startsWith('-')
              ? parseCalendarMoment(first.substring(1))
              : null);
    if (start != null || end != null) {
      time = CalendarEventTime(raw: written, start: start, end: end);
      cursor = timeMatch.end;
    }
  }
  var textStart = _skipSpaces(raw, cursor);
  // The event's own end: the terminator, or the line's.
  var end = raw.length;
  final terminator = _firstTerminator(raw, cursor);
  if (terminator != null) end = terminator.start;
  while (end > textStart && _isSpace(raw.codeUnitAt(end - 1))) {
    end--;
  }
  if (end < textStart) {
    textStart = end;
  }
  final body = raw.substring(textStart, end);
  final asides = _asides(body, textStart);
  final tokens = calendarTokens(raw, from: textStart, to: end, asides: asides);
  final reminder = _reminderToken(tokens);
  return CalendarEvent(
    raw: raw.substring(at, end),
    text: body,
    start: at,
    textStart: textStart,
    end: end,
    time: time,
    reminder: reminder?.value.substring(reminder.value.indexOf(':') + 1),
    reminderStart: reminder?.start,
    reminderEnd: reminder?.end,
    asides: asides,
    tokens: tokens,
  );
}

/// The `+`/`@`/`#`/`key:value` tokens of [raw], from [from] (to [to], the
/// line's end by default), skipping the `( … )` asides ([asides], for the
/// event-sized [raw] the spans are absolute already).
List<CalendarToken> calendarTokens(
  String raw, {
  int from = 0,
  int? to,
  List<CalendarAside> asides = const <CalendarAside>[],
}) {
  final end = to ?? raw.length;
  final tokens = <CalendarToken>[];
  for (final match in _word.allMatches(raw, from)) {
    if (match.start >= end) break;
    final token = _tokenAt(match.group(0)!, match.start);
    if (token == null) continue;
    if (asides.any(
      (aside) => token.start >= aside.start && token.end <= aside.end,
    )) {
      continue;
    }
    if (tokens.isNotEmpty && token.start < tokens.last.end) continue;
    tokens.add(token);
  }
  return tokens;
}

/// The token one whitespace-delimited [word] at [at] is, or null for plain
/// text. Trailing punctuation a written event carries (`,`, `;`, `.`) is
/// not part of the token.
CalendarToken? _tokenAt(String word, int at) {
  final trimmed = _trailingPunctuation.hasMatch(word)
      ? word.substring(0, word.length - 1)
      : word;
  if (trimmed.length < 2) return null;
  final end = at + trimmed.length;
  final kind = switch (trimmed[0]) {
    '+' => CalendarTokenKind.project,
    '@' => CalendarTokenKind.context,
    '#' => CalendarTokenKind.tag,
    _ => _keyValue.hasMatch(trimmed) ? CalendarTokenKind.keyValue : null,
  };
  if (kind == null) return null;
  final value = kind == CalendarTokenKind.keyValue
      ? trimmed
      : trimmed.substring(1);
  return CalendarToken(kind: kind, value: value, start: at, end: end);
}

/// The first `rem:` token of [tokens], or null.
CalendarToken? _reminderToken(List<CalendarToken> tokens) {
  for (final token in tokens) {
    if (token.kind != CalendarTokenKind.keyValue) continue;
    final colon = token.value.indexOf(':');
    if (colon < 0) continue;
    if (token.value.substring(0, colon).toLowerCase() == 'rem') return token;
  }
  return null;
}

/// The value of the first `rem:` of [tokens] (`13:15` of `rem:13:15`), or
/// null.
String? calendarReminderOf(List<CalendarToken> tokens) {
  final token = _reminderToken(tokens);
  if (token == null) return null;
  return token.value.substring(token.value.indexOf(':') + 1);
}

/// Parses a written time (`9`, `08:15`, `0815`, `0600Z`), or null when it
/// is not a time at all.
CalendarMoment? parseCalendarMoment(String raw) {
  var body = raw;
  var utc = false;
  if (body.endsWith('Z') || body.endsWith('z')) {
    utc = true;
    body = body.substring(0, body.length - 1);
  }
  int? hour;
  int? minute;
  if (body.contains(':')) {
    final parts = body.split(':');
    if (parts.length != 2) return null;
    hour = int.tryParse(parts[0]);
    minute = int.tryParse(parts[1]);
  } else if (body.length <= 2) {
    hour = int.tryParse(body);
    minute = 0;
  } else if (body.length <= 4) {
    hour = int.tryParse(body.substring(0, body.length - 2));
    minute = int.tryParse(body.substring(body.length - 2));
  }
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return CalendarMoment(raw: raw, minutes: hour * 60 + minute, utc: utc);
}

/// The ISO weekday number of a written [name], or null when the parser
/// does not know it.
///
/// English's names are always known; [weekdays] adds the app's locales and
/// the file's own convention (lowercased, with and without a trailing
/// period).
int? weekdayNumberFor(String name, [Map<String, int> weekdays = const {}]) {
  final lower = name.toLowerCase();
  final known = weekdays[lower];
  if (known != null) return known;
  final withoutPeriod = lower.endsWith('.')
      ? lower.substring(0, lower.length - 1)
      : '$lower.';
  return weekdays[withoutPeriod] ?? _englishWeekdays[lower];
}

/// The names the app's own locales use, English included, mapped to ISO
/// weekday numbers (1 = Monday): what [parseCalendarLine] should be given.
Map<String, int> calendarWeekdayNames(Iterable<List<String>> locales) {
  final names = <String, int>{..._englishWeekdays};
  for (final names_ in locales) {
    for (var at = 0; at < names_.length && at < 7; at++) {
      final name = names_[at].toLowerCase().trim();
      if (name.isEmpty) continue;
      names.putIfAbsent(name, () => at + 1);
      if (name.endsWith('.')) {
        names.putIfAbsent(name.substring(0, name.length - 1), () => at + 1);
      }
    }
  }
  return names;
}

/// The day lines for [date], in file order: a hand edit or another tool's
/// merge can leave two (#730).
List<CalendarLine> calendarDaysFor(List<CalendarLine> lines, DateTime date) => [
  for (final line in lines)
    if (line.kind == CalendarLineKind.day && _sameDay(line.date, date)) line,
];

/// The goals that apply to [date], in the order the journal shows them: the
/// week's, the month's, the year's (#730).
List<CalendarLine> calendarGoalsFor(List<CalendarLine> lines, DateTime date) =>
    [
      for (final kind in const [
        CalendarLineKind.weekGoal,
        CalendarLineKind.monthGoal,
        CalendarLineKind.yearGoal,
      ])
        for (final line in lines)
          if (line.kind == kind && _goalApplies(line, date)) line,
    ];

bool _goalApplies(CalendarLine line, DateTime date) {
  final at = line.date;
  if (at == null) return false;
  return switch (line.kind) {
    CalendarLineKind.weekGoal =>
      isoWeekOf(at) == isoWeekOf(date) && at.year == date.year,
    CalendarLineKind.monthGoal =>
      at.year == date.year && at.month == date.month,
    CalendarLineKind.yearGoal => at.year == date.year,
    _ => false,
  };
}

/// Whether [date] and [other] are the same calendar day.
bool _sameDay(DateTime? date, DateTime other) =>
    date != null &&
    date.year == other.year &&
    date.month == other.month &&
    date.day == other.day;

/// The text that follows a head at [at] (its two spaces skipped), or null
/// when there is none.
String? _textAfter(String raw, int at) {
  final from = _skipSpaces(raw, at);
  if (from >= raw.length) return null;
  return raw.substring(from);
}

int _skipSpaces(String raw, int at) {
  var cursor = at;
  while (cursor < raw.length && _isSpace(raw.codeUnitAt(cursor))) {
    cursor++;
  }
  return cursor;
}

bool _isSpace(int codeUnit) => codeUnit == 0x20 || codeUnit == 0x09;

/// Where an event's terminator is: a `.` or a `;` followed by a space or
/// the line's end.
final RegExp _terminator = RegExp(r'[.;](?=\s|$)');

int _afterTerminator(String raw, int at) {
  final match = _terminator.matchAsPrefix(raw, at);
  return match == null ? at : match.end;
}

/// The first terminator at or after [at], or null.
RegExpMatch? _firstTerminator(String raw, int at) {
  final matches = _terminator.allMatches(raw, at);
  return matches.isEmpty ? null : matches.first;
}

/// The aside spans of an event body, relative to the whole line.
List<CalendarAside> _asides(String body, int from) {
  final asides = <CalendarAside>[];
  for (final match in _aside.allMatches(body)) {
    asides.add(CalendarAside(start: from + match.start, end: from + match.end));
  }
  return asides;
}

/// A time, or a time range: `9`, `08:15`, `0815`, `0600Z`, `9-12`,
/// `13:30-14`, `-12:00`. A leading `-` on the first is an end-only range.
final RegExp _timeRange = RegExp(
  r'(-?\d{1,2}:\d{2}[Zz]?|-?\d{1,4}[Zz]?)(?:-(\d{1,2}:\d{2}[Zz]?|\d{1,4}[Zz]?))?(?=\s|$)',
);

final RegExp _word = RegExp(r'[^ \t]+');
final RegExp _trailingPunctuation = RegExp(r'[,;.]$');
final RegExp _aside = RegExp(r'\([^)]*\)');
final RegExp _keyValue = RegExp(r'^[A-Za-z][A-Za-z0-9_-]*:\S+$');
final RegExp _year = RegExp(r'(\d{4})(?=\s|$)');
final RegExp _month = RegExp(r'(\d{4})-(\d{2})(?=\s|$)');
final RegExp _day = RegExp(r'(\d{4})-(\d{2})-(\d{2})(?: w(\d{1,2}))?(?=\s|$)');

/// English's three-letter weekday names, the spec's own and the mockups'.
const Map<String, int> _englishWeekdays = {
  'mon': 1,
  'monday': 1,
  'tue': 2,
  'tues': 2,
  'tuesday': 2,
  'wed': 3,
  'wednesday': 3,
  'thu': 4,
  'thur': 4,
  'thurs': 4,
  'thursday': 4,
  'fri': 5,
  'friday': 5,
  'sat': 6,
  'saturday': 6,
  'sun': 7,
  'sunday': 7,
};
