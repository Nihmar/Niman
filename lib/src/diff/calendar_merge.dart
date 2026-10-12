/// Merge for `calendar.txt` (#730): the task files' record merge, made
/// calendar-aware.
///
/// The line merge asks the user wherever both sides touched the same
/// place, and the common collision here is the day line: two devices each
/// add an event to the same day, and both append it to the same line.
/// That is not a disagreement. So a **day line** is paired by its date —
/// not by its exact text, so two conventions of the same head still meet —
/// and the events of one day are merged as a set: an event added on either
/// side is in, one removed from the base on either side is out, one added
/// on both is in once. The merged set is spliced back into one line, in
/// time order, and the line the local side wrote is kept verbatim when
/// nothing about it changed.
///
/// A **goal** is not a set of items: its line says one thing, in prose.
/// Two different texts for one head are two edits, and the record rule
/// keeps both rather than choosing one and losing the other — as a task
/// edited differently on both sides comes out as both edits. So goal lines
/// and lines with no key (blank, comments, what the parser cannot read)
/// follow the record merge exactly, and only day lines are paired.
///
/// Every line keeps **its own ending**: a merged line takes the ending of
/// the side it came from, a line the merge did not touch keeps the one it
/// was written with, and only a line rebuilt by the merge itself falls
/// back to the file's dominant ending. A byte-order mark is out of scope
/// here — the merge works on decoded texts, as the task files' own merge
/// does.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';
import 'package:niman/src/diff/three_way.dart';

/// Merges what [local] and [remote] each did to the calendar file [base]
/// (empty when there is no common version: then the union of both).
String mergeCalendar(String base, String local, String remote) {
  final merge = mergeThreeWay(base, local, remote);
  final endings = _Endings(local: local, remote: remote, base: base);
  final lines = <CalendarRawLine>[];
  for (final chunk in merge.chunks) {
    if (chunk.kind != MergeKind.conflict) {
      for (final line in chunk.resolved()) {
        lines.add(endings.of(line));
      }
      continue;
    }
    lines.addAll(_mergedChunk(chunk, endings));
  }
  final body = StringBuffer();
  for (var at = 0; at < lines.length; at++) {
    final last = at == lines.length - 1;
    body.write(last && !merge.trailingNewline ? lines[at].text : lines[at].raw);
  }
  return body.toString();
}

/// The key two day lines are paired by: the date they head. A goal's head
/// and a line the parser cannot read have no key — they merge as records.
String? calendarDayKey(String line) {
  final parsed = parseCalendarLine(line, weekdays: calendarWeekdays);
  if (parsed.kind != CalendarLineKind.day) return null;
  final date = parsed.date;
  return date == null ? null : _dayText(date);
}

/// One overlapping region, settled: local's lines in order (its day keys
/// merged with the server's events), then the server's new ones.
List<CalendarRawLine> _mergedChunk(MergeChunk chunk, _Endings endings) {
  final base = chunk.base;
  final local = chunk.local;
  final remote = chunk.remote;
  final out = <CalendarRawLine>[];
  final done = <String>{};
  for (final line in local) {
    final key = calendarDayKey(line);
    if (key == null) {
      // The record rule, exactly as the task files use it.
      if (!base.contains(line) || remote.contains(line)) {
        out.add(endings.of(line));
      }
      continue;
    }
    if (!done.add(key)) continue;
    final merged = _mergeDay(
      local: _withKey(local, key),
      remote: _withKey(remote, key),
      base: _withKey(base, key),
      endings: endings,
    );
    if (merged != null) out.add(merged);
  }
  for (final line in remote) {
    final key = calendarDayKey(line);
    if (key == null) {
      if (!base.contains(line) && !local.contains(line)) {
        out.add(endings.of(line));
      }
      continue;
    }
    if (!done.add(key)) continue;
    final merged = _mergeDay(
      local: const [],
      remote: _withKey(remote, key),
      base: _withKey(base, key),
      endings: endings,
    );
    if (merged != null) out.add(merged);
  }
  return out;
}

List<String> _withKey(List<String> lines, String key) => [
  for (final line in lines)
    if (calendarDayKey(line) == key) line,
];

/// One day, its events merged as a set: null when the day itself was
/// removed on the side that no longer has it.
CalendarRawLine? _mergeDay({
  required List<String> local,
  required List<String> remote,
  required List<String> base,
  required _Endings endings,
}) {
  if (local.isEmpty && remote.isEmpty) return null;
  if (local.isEmpty) {
    // Added there — or removed here, from the base both sides had.
    return base.isEmpty ? endings.of(remote.first) : null;
  }
  if (remote.isEmpty) {
    // Added here — or removed there.
    return base.isEmpty ? endings.of(local.first) : null;
  }
  final localEvents = _events(local);
  final remoteEvents = _events(remote);
  final baseEvents = _events(base);
  // `raw`, not `text`: an event is what the line writes, its time
  // included, so two events that say the same thing at different hours are
  // two events.
  final baseTexts = {for (final event in baseEvents) event.raw};
  final localTexts = {for (final event in localEvents) event.raw};
  final remoteTexts = {for (final event in remoteEvents) event.raw};
  final merged = <String>[];
  void keep(String text) {
    if (!merged.contains(text)) merged.add(text);
  }

  for (final event in localEvents) {
    if (!baseTexts.contains(event.raw) || remoteTexts.contains(event.raw)) {
      keep(event.raw);
    }
  }
  for (final event in remoteEvents) {
    if (!baseTexts.contains(event.raw) && !localTexts.contains(event.raw)) {
      keep(event.raw);
    }
  }
  if (local.length == 1 && _sameTexts(localEvents, merged)) {
    // Nothing about this day changed here: the local line, byte for byte.
    return endings.of(local.first);
  }
  return CalendarRawLine(
    _rebuilt(local.first, merged, [
      ...localEvents,
      ...remoteEvents,
      ...baseEvents,
    ]),
    endings.endingOf(local.first),
  );
}

List<CalendarEvent> _events(List<String> lines) => [
  for (final line in lines)
    ...parseCalendarLine(line, weekdays: calendarWeekdays).events,
];

bool _sameTexts(List<CalendarEvent> events, List<String> merged) {
  if (events.length != merged.length) return false;
  for (var at = 0; at < events.length; at++) {
    if (events[at].raw != merged[at]) return false;
  }
  return true;
}

/// The line [raw] rebuilt around [events], in time order — what an event
/// with no time starts at coming last. The head keeps the local side's
/// own convention, and the day keeps its two spaces before the first
/// event.
String _rebuilt(String raw, List<String> events, List<CalendarEvent> known) {
  final parsed = parseCalendarLine(raw, weekdays: calendarWeekdays);
  final head = (parsed.head ?? raw).trimRight();
  if (events.isEmpty) return head;
  final minutes = <String, int>{
    for (final event in known)
      event.raw: event.time?.first?.minutes ?? _untimed,
  };
  final ordered = [
    ...events,
  ]..sort((a, b) => (minutes[a] ?? _untimed).compareTo(minutes[b] ?? _untimed));
  return '$head  ${[for (final event in ordered) '$event.'].join(' ')}';
}

/// What an event with no time starts at, for ordering: after every timed
/// one.
const int _untimed = 24 * 60;

/// Each line's own ending, as the three sides wrote it: a merged line
/// takes the ending of the side it came from, and one the merge rebuilt
/// the file's dominant ending.
final class _Endings {
  /// Reads the endings out of [local], [remote] and [base], in that
  /// order: the same text on two sides keeps the first one's.
  new({required String local, required String remote, required String base}) {
    for (final text in [local, remote, base]) {
      for (final line in _split(text)) {
        _byText.putIfAbsent(line.text, () => line.ending);
      }
    }
    _dominant = _dominantOf(
      _split(local).isEmpty ? _split(remote) : _split(local),
    );
  }

  final Map<String, String> _byText = {};
  late final String _dominant;

  /// The line [text] with its own ending, or with the file's.
  CalendarRawLine of(String text) =>
      CalendarRawLine(text, _byText[text] ?? _dominant);

  /// The ending [text] was written with, or the file's.
  String endingOf(String text) => _byText[text] ?? _dominant;

  static List<CalendarRawLine> _split(String text) =>
      splitCalendarFile(Uint8List.fromList(utf8.encode(text))).lines;

  static String _dominantOf(List<CalendarRawLine> lines) {
    var crlf = 0;
    var lf = 0;
    for (final line in lines) {
      if (line.ending == '\r\n') {
        crlf++;
      } else if (line.ending == '\n') {
        lf++;
      }
    }
    return crlf > 0 && crlf >= lf ? '\r\n' : '\n';
  }
}

String _dayText(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}'
    '-${day.day.toString().padLeft(2, '0')}';
