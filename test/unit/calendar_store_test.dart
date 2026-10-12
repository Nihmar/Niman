// #730 phase 1: the calendar store — reading `calendar.txt` off the UI
// isolate, the snapshot's own lookups (a day's events in time order, the
// goals that apply, the days with events) and the probe the controller
// skips reloads by.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_calendar_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  void write(String content, {bool bom = false}) {
    File(p.join(root.path, calendarFileName))
        .writeAsStringSync('${bom ? '\uFEFF' : ''}$content');
  }

  Future<CalendarStore> store() async => CalendarStore(root: root.path);

  test('a missing file reads as empty and does not exist', () async {
    final snapshot = await (await store()).load();
    expect(snapshot.exists, isFalse);
    expect(snapshot.entries, isEmpty);
    expect(snapshot.isEmpty, isTrue);
    expect(snapshot.daysWithEvents, isEmpty);
  });

  test('the file is parsed line by line, indexes included', () async {
    write(
      '2026  The year of the move +home\n'
      '2026-10  Finish the thesis draft\n'
      '2026-10-12 w42  Writing week\n'
      '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis @library.\n',
    );
    final snapshot = await (await store()).load();
    expect(snapshot.entries, hasLength(4));
    expect(snapshot.entries[1].lineIndex, 1);
    expect(snapshot.entries[1].line.kind.name, 'monthGoal');
    expect(snapshot.exists, isTrue);
    expect(snapshot.validUtf8, isTrue);
  });

  test("a day's events come in time order, untimed ones last", () async {
    write(
      '2026-10-12 w42 Mon  13:30-14 call. lunch with Marta. 9-12 library.\n',
    );
    final snapshot = await (await store()).load();
    final events = snapshot.eventsFor(DateTime(2026, 10, 12));
    expect(events.map((e) => e.event.raw), [
      '9-12 library',
      '13:30-14 call',
      'lunch with Marta',
    ]);
    expect(events.first.lineIndex, 0);
    expect(events.first.event.projects, isEmpty);
    expect(events.last.untimed, isTrue);
  });

  test('two lines for one day: every event is shown', () async {
    write(
      '2026-10-12 w42 Mon  9-12 a.\n'
      '2026-10-12 w42 Mon  18-19 b.\n',
    );
    final snapshot = await (await store()).load();
    expect(snapshot.eventsFor(DateTime(2026, 10, 12)), hasLength(2));
  });

  test("another day's events are not shown", () async {
    write('2026-10-12 w42 Mon  9-12 a.\n');
    final snapshot = await (await store()).load();
    expect(snapshot.eventsFor(DateTime(2026, 10, 13)), isEmpty);
  });

  test('the goals that apply to a day, week then month then year', () async {
    write(
      '2026  The year of the move\n'
      '2026-10  Finish the thesis draft\n'
      '2026-10-12 w42  Writing week\n',
    );
    final snapshot = await (await store()).load();
    final goals = snapshot.goalsFor(DateTime(2026, 10, 14));
    expect(goals.map((g) => g.line.goalText), [
      'Writing week',
      'Finish the thesis draft',
      'The year of the move',
    ]);
    expect(goals.first.lineIndex, 2);
  });

  test("the days with events: the calendar's second dot", () async {
    write(
      '2026-10-12 w42 Mon  9-12 a.\n'
      '2026-10-13 w42 Tue\n'
      '2026-10-14 w42 Wed  9-12 b. 10-11 c.\n',
    );
    final snapshot = await (await store()).load();
    expect(snapshot.daysWithEvents, {
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 14),
    });
    expect(snapshot.hasEventsOn(DateTime(2026, 10, 13)), isFalse);
    expect(snapshot.hasEventsOn(DateTime(2026, 10, 14)), isTrue);
  });

  test('a localized weekday head reads as a day', () async {
    // The parser is given every language the app ships, so a file written
    // in one of them reads its own day heads (#730).
    write('2026-10-05 w41 lun  9-12 biblioteca.\n');
    final snapshot = await (await store()).load();
    expect(snapshot.entries.single.line.kind.name, 'day');
    expect(snapshot.eventsFor(DateTime(2026, 10, 5)), hasLength(1));
  });

  test('a byte-order mark is kept and not a line', () async {
    write('2026-10-05 w41 Mon  9-12 a.\n', bom: true);
    final snapshot = await (await store()).load();
    expect(snapshot.bom, isTrue);
    expect(snapshot.entries, hasLength(1));
  });

  test('a file that is not UTF-8 is loaded, and marked', () async {
    File(p.join(root.path, calendarFileName)).writeAsBytesSync([
      ...'2026-10-05 w41 Mon  9-12 a.\n'.codeUnits,
      0xFF,
      0xFE,
    ]);
    final snapshot = await (await store()).load();
    expect(snapshot.validUtf8, isFalse);
    expect(snapshot.entries.first.line.kind.name, 'day');
  });

  test('the probe follows the file: missing, written, written again', () async {
    final at = await store();
    final missing = await at.probe();
    expect(missing.exists, isFalse);
    expect(missing.size, -1);

    write('2026-10-05 w41 Mon  9-12 a.\n');
    final first = await at.probe();
    expect(first.exists, isTrue);
    expect(first.size, greaterThan(0));
    expect(first.modified, isNotNull);

    write('2026-10-05 w41 Mon  9-12 a.\n2026-10-06 w41 Tue\n');
    final second = await at.probe();
    expect(second == first, isFalse, reason: 'the file moved');
  });

  test(
    'the same file probes equal, so a quiet revision reads nothing',
    () async {
      write('2026-10-05 w41 Mon  9-12 a.\n');
      final at = await store();
      expect(await at.probe(), await at.probe());
    },
  );
}
