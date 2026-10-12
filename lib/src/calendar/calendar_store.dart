/// File store over `calendar.txt` (#730): reads it off the UI isolate and
/// parses it here.
///
/// One file at the library root, a constant rather than a setting: it
/// travels and syncs with the library, and `grep +thesis` over both it and
/// `todo.txt` — the format's own promise — keeps working. No file, nothing
/// shown; phase 3's first Add event creates it.
///
/// Isolate discipline (the Android FUSE rule): the bytes and the stat are
/// read via [Isolate.run]; parsing them is pure CPU work and stays on the
/// caller, as the todo store does.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// The calendar file at the library root.
const String calendarFileName = 'calendar.txt';

/// Existence + size + mtime of [calendarFileName], read off the UI
/// isolate ([CalendarStore.probe]).
///
/// The journal's revision-driven refresh compares these before reloading:
/// a session event that did not move the file (any note edit anywhere)
/// costs one stat and no content read.
@immutable
final class CalendarFileProbe {
  /// Creates a probe: [exists] false means the file is missing (then
  /// [size] is -1 and [modified] null).
  const new({required this.exists, required this.size, required this.modified});

  /// Whether the file exists on disk.
  final bool exists;

  /// The file size in bytes (-1 when missing).
  final int size;

  /// The file mtime (null when missing).
  final DateTime? modified;

  @override
  bool operator ==(Object other) {
    return other is CalendarFileProbe &&
        other.exists == exists &&
        other.size == size &&
        other.modified == modified;
  }

  @override
  int get hashCode => Object.hash(exists, size, modified);

  @override
  String toString() =>
      'CalendarFileProbe(exists: $exists, size: $size, modified: $modified)';
}

/// One parsed line with its 0-based index in the file.
@immutable
final class CalendarEntry {
  /// Creates an entry for [line] at file line [lineIndex].
  const new({required this.lineIndex, required this.line});

  /// The 0-based line index in `calendar.txt`.
  final int lineIndex;

  /// The parsed line.
  final CalendarLine line;

  @override
  String toString() => 'CalendarEntry($lineIndex, $line)';
}

/// One event with the line it sits on: what the journal's Events section
/// shows and what a tap opens the file at.
@immutable
final class CalendarEntryEvent {
  /// Creates an event of [line] at file line [lineIndex].
  const new({required this.lineIndex, required this.line, required this.event});

  /// The 0-based line index in `calendar.txt`.
  final int lineIndex;

  /// The line the event sits on.
  final CalendarLine line;

  /// The event itself.
  final CalendarEvent event;

  /// The minutes the event starts at, for ordering; an event with no time
  /// written comes last.
  int get startMinutes => event.time?.first?.minutes ?? _untimed;

  static const int _untimed = 24 * 60;

  /// Whether the event carries no time at all.
  bool get untimed => event.time?.first == null;

  @override
  String toString() => 'CalendarEntryEvent($lineIndex, $event)';
}

/// The parsed contents of `calendar.txt`.
final class CalendarSnapshot {
  /// Creates a snapshot of [entries] (the file's lines, in order).
  new({
    required this.entries,
    this.exists = true,
    this.validUtf8 = true,
    this.bom = false,
  }) : daysWithEvents = _daysWithEvents(entries);

  /// The file's lines, in order (blank and unrecognised ones included:
  /// the editor and the writer address them by index).
  final List<CalendarEntry> entries;

  /// Whether the file exists on disk.
  final bool exists;

  /// Whether the file decoded as UTF-8 (false means it is shown and never
  /// written).
  final bool validUtf8;

  /// Whether the file starts with a byte-order mark (kept on a rewrite).
  final bool bom;

  /// The days with at least one event, for the calendar's second dot —
  /// computed once with the snapshot, not per build.
  final Set<DateTime> daysWithEvents;

  /// The parsed lines, in order.
  List<CalendarLine> get lines => [for (final entry in entries) entry.line];

  /// Whether the file holds nothing shown at all.
  bool get isEmpty =>
      entries.every((entry) => entry.line.kind == CalendarLineKind.other);

  /// Every event on [date], from every line that carries one (a hand edit
  /// or another tool's merge can leave two), in time order — an event with
  /// no time written last, in the order the line writes them.
  List<CalendarEntryEvent> eventsFor(DateTime date) {
    final events = <CalendarEntryEvent>[];
    for (final entry in entries) {
      if (entry.line.kind != CalendarLineKind.day) continue;
      if (!_sameDay(entry.line.date, date)) continue;
      for (final event in entry.line.events) {
        events.add(
          CalendarEntryEvent(
            lineIndex: entry.lineIndex,
            line: entry.line,
            event: event,
          ),
        );
      }
    }
    events.sort((a, b) {
      final order = a.startMinutes.compareTo(b.startMinutes);
      if (order != 0) return order;
      // Same time (or no time at all): the file's own order decides, so
      // the list never jumps between two builds.
      final line = a.lineIndex.compareTo(b.lineIndex);
      if (line != 0) return line;
      return a.event.start.compareTo(b.event.start);
    });
    return events;
  }

  /// The goals that apply to [date], in the order the journal shows them:
  /// the week's, the month's, the year's.
  List<CalendarEntry> goalsFor(DateTime date) {
    final byLine = {for (final entry in entries) entry.line: entry};
    return [for (final line in calendarGoalsFor(lines, date)) ?byLine[line]];
  }

  /// Whether [date] has any event at all.
  bool hasEventsOn(DateTime date) => daysWithEvents.contains(_dayOf(date));
}

/// Parses [lines] into a snapshot: the store's own parse, and what an
/// in-memory fake source answers a widget test with.
CalendarSnapshot calendarSnapshotOf(
  List<String> lines, {
  bool exists = true,
  bool validUtf8 = true,
  bool bom = false,
}) {
  return CalendarSnapshot(
    entries: [
      for (var at = 0; at < lines.length; at++)
        CalendarEntry(
          lineIndex: at,
          line: parseCalendarLine(lines[at], weekdays: calendarWeekdays),
        ),
    ],
    exists: exists,
    validUtf8: validUtf8,
    bom: bom,
  );
}

/// Reads `calendar.txt` under [root].
///
/// Stateless and read-only in phase 1; the write phase re-reads the file
/// inside its writer chain, as the todo store does.
final class CalendarStore implements CalendarSource {
  /// Creates a store over the library root at [root] (absolute path).
  new({required this.root});

  /// The absolute library root path.
  final String root;

  static const AppLogger _log = AppLogger(name: 'calendar');

  /// Loads and parses the file (a missing file reads as empty).
  @override
  Future<CalendarSnapshot> load() async {
    final bytes = await _isolateRead(root);
    final file = splitCalendarFile(bytes);
    final snapshot = calendarSnapshotOf(
      [for (final line in file.lines) line.text],
      exists: file.exists,
      validUtf8: file.validUtf8,
      bom: file.bom,
    );
    _log.debug('calendar load: ${snapshot.entries.length} lines');
    return snapshot;
  }

  /// Probes the file's existence + size + mtime off the UI isolate.
  @override
  Future<CalendarFileProbe> probe() async {
    final raw = await Isolate.run(() => _probeCalendarFile(root));
    return _fileProbe(raw[0], raw[1]);
  }
}

/// Reads the file's bytes on the isolate it is called on: top-level and
/// fully synchronous so it can be handed to [Isolate.run], capturing only
/// the sendable [root]. Null = missing file.
Future<Uint8List?> _isolateRead(String root) {
  return Isolate.run(() => _readCalendarBytes(root));
}

Uint8List? _readCalendarBytes(String root) {
  final file = File(p.join(root, calendarFileName));
  return file.existsSync() ? file.readAsBytesSync() : null;
}

/// Stats the file on the isolate it is called on (`[size, mtimeUs]`,
/// -1 for a missing one).
List<int> _probeCalendarFile(String root) {
  final file = File(p.join(root, calendarFileName));
  if (!file.existsSync()) return const <int>[-1, -1];
  final stat = file.statSync();
  return <int>[stat.size, stat.modified.microsecondsSinceEpoch];
}

/// Builds a [CalendarFileProbe] from a (`size`, `mtimeUs`) pair.
CalendarFileProbe _fileProbe(int size, int mtimeUs) {
  if (size < 0) {
    return const CalendarFileProbe(exists: false, size: -1, modified: null);
  }
  return CalendarFileProbe(
    exists: true,
    size: size,
    modified: DateTime.fromMicrosecondsSinceEpoch(mtimeUs),
  );
}

/// The days that carry at least one event.
Set<DateTime> _daysWithEvents(List<CalendarEntry> entries) {
  final days = <DateTime>{};
  for (final entry in entries) {
    if (entry.line.kind != CalendarLineKind.day) continue;
    if (entry.line.events.isEmpty) continue;
    final date = entry.line.date;
    if (date == null) continue;
    days.add(_dayOf(date));
  }
  return days;
}

/// [date] at midnight: the key the calendar's days are compared by.
DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime? date, DateTime other) =>
    date != null &&
    date.year == other.year &&
    date.month == other.month &&
    date.day == other.day;
