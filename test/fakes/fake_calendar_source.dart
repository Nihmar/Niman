/// In-memory [CalendarSource] for widget tests (#730).
///
/// `testWidgets` runs in a fake-async zone where real filesystem I/O never
/// completes, so the journal is exercised against this fake while the real
/// store is covered by the unit tests in `test/unit/`. It parses through
/// the store's own [calendarSnapshotOf], so the lines a test writes read
/// exactly as they would from disk.
library;

import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/calendar/calendar_store.dart';

/// A `calendar.txt` held in memory.
final class FakeCalendarSource implements CalendarSource {
  /// Creates a fake holding [lines] (a missing file by default, so a test
  /// that writes none sees nothing).
  new({List<String>? lines, bool exists = false})
    : _lines = <String>[...?lines],
      _exists = exists || (lines != null);

  final List<String> _lines;
  bool _exists;
  int _version = 0;

  /// The lines as they are (for assertions).
  List<String> get lines => List<String>.unmodifiable(_lines);

  /// Replaces the file's lines, as another tool or a sync would.
  void write(List<String> lines) {
    _lines
      ..clear()
      ..addAll(lines);
    _exists = true;
    _version++;
  }

  /// Whether the file exists.
  bool get exists => _exists;

  @override
  Future<CalendarSnapshot> load() async =>
      calendarSnapshotOf(_lines, exists: _exists);

  @override
  Future<CalendarFileProbe> probe() async {
    final size = _lines.fold(0, (total, line) => total + line.length + 1);
    return CalendarFileProbe(
      exists: _exists,
      size: _exists ? size : -1,
      modified: _exists
          ? DateTime(2026, 5, 4).add(Duration(seconds: _version))
          : null,
    );
  }
}
