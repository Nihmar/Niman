// #1191: merging a day line whose events repeat. Two devices that each skip
// a different occurrence of one rule must leave one rule event, not two —
// every occurrence would show twice — and the pairing must never join two
// events that differ in anything but their `until:` and `except:`.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/diff/calendar_merge.dart';

void main() {
  /// The day line of the 5th, holding [events] (already closed with `.`).
  String day(String events, {String head = '2026-10-05 w41 Mon'}) =>
      '$head  $events\n';

  const standup = '9-9:30 Standup @work rec:1w';

  String merge(String base, String local, String remote) =>
      mergeCalendar(day(base), day(local), day(remote));

  test('each device skips a different day: one rule, the union', () {
    expect(
      merge(
        '$standup.',
        '$standup except:2026-10-12.',
        '$standup except:2026-10-26.',
      ),
      day('$standup except:2026-10-12,2026-10-26.'),
    );
  });

  test('both lists grow from the same skip: the base day stays once', () {
    expect(
      merge(
        '$standup except:2026-10-12.',
        '$standup except:2026-10-12,2026-10-19.',
        '$standup except:2026-10-12,2026-10-26.',
      ),
      day('$standup except:2026-10-12,2026-10-19,2026-10-26.'),
    );
  });

  test('one ends the rule while the other skips: the end and the skip', () {
    expect(
      merge(
        '$standup.',
        '$standup until:2026-11-30.',
        '$standup except:2026-10-26.',
      ),
      day('$standup until:2026-11-30 except:2026-10-26.'),
    );
    // And the other way round.
    expect(
      merge(
        '$standup.',
        '$standup except:2026-10-26.',
        '$standup until:2026-11-30.',
      ),
      day('$standup except:2026-10-26 until:2026-11-30.'),
    );
  });

  test('both end it: the earlier end', () {
    expect(
      merge(
        '$standup.',
        '$standup until:2026-12-31.',
        '$standup until:2026-11-30.',
      ),
      day('$standup until:2026-11-30.'),
    );
  });

  test('a side that left the end alone follows the one that moved it', () {
    // Base ends at the 31st; one device lengthens it, the other skips.
    expect(
      merge(
        '$standup until:2026-10-31.',
        '$standup until:2026-12-31.',
        '$standup until:2026-10-31 except:2026-10-12.',
      ),
      day('$standup until:2026-12-31 except:2026-10-12.'),
    );
    // One device takes the end away, the other leaves it: no end.
    expect(
      merge(
        '$standup until:2026-10-31.',
        '$standup.',
        '$standup until:2026-10-31 except:2026-10-12.',
      ),
      day('$standup except:2026-10-12.'),
    );
  });

  test('both moved it differently: the earlier, and none is later', () {
    expect(
      merge(
        '$standup until:2026-10-31.',
        '$standup until:2026-12-31.',
        '$standup until:2026-11-30.',
      ),
      day('$standup until:2026-11-30.'),
    );
    expect(
      merge(
        '$standup until:2026-10-31.',
        '$standup.',
        '$standup until:2026-11-30.',
      ),
      day('$standup until:2026-11-30.'),
      reason: 'one removed it, the other moved it: the one that is there',
    );
  });

  test('no base: two devices that both started the rule still pair', () {
    expect(
      mergeCalendar(
        '',
        day('$standup except:2026-10-12 until:2026-12-31.'),
        day('$standup except:2026-10-19 until:2026-11-30.'),
      ),
      day('$standup except:2026-10-12,2026-10-19 until:2026-11-30.'),
    );
  });

  test('a day a side gave back is out, whatever the other still has', () {
    expect(
      merge(
        '$standup except:2026-10-12,2026-10-19.',
        '$standup except:2026-10-19.',
        '$standup except:2026-10-12,2026-10-19,2026-10-26.',
      ),
      day('$standup except:2026-10-19,2026-10-26.'),
    );
  });

  test('a side that changed nothing takes the other, to the character', () {
    // Spacing the pairing would have normalised stays as the other wrote it.
    expect(
      merge(
        '$standup.',
        '$standup.',
        '9-9:30  Standup @work rec:1w  except:2026-10-12.',
      ),
      day('9-9:30  Standup @work rec:1w  except:2026-10-12.'),
    );
  });

  test('the rest of the line is merged as it always was', () {
    expect(
      merge(
        '$standup. 17 jog.',
        '$standup except:2026-10-12. 17 jog. 18 dinner.',
        '$standup except:2026-10-26. 17 jog.',
      ),
      day('$standup except:2026-10-12,2026-10-26. 17 jog. 18 dinner.'),
    );
  });

  test('removed on one side and skipped on the other: the edit stands', () {
    // As any event removed on one side and changed on the other.
    expect(
      merge('$standup.', '', '$standup except:2026-10-26.'),
      day('$standup except:2026-10-26.'),
    );
  });

  test('a different text is a different event: both are kept', () {
    expect(
      merge(
        '$standup.',
        '9-9:30 Standup @work rec:1w except:2026-10-12.',
        '9-9:30 Standup @home rec:1w except:2026-10-26.',
      ),
      day(
        '9-9:30 Standup @work rec:1w except:2026-10-12. '
        '9-9:30 Standup @home rec:1w except:2026-10-26.',
      ),
    );
  });

  test('another rule, or another time, is not the same event', () {
    expect(
      merge(
        '$standup.',
        '9-9:30 Standup @work rec:2w except:2026-10-12.',
        '$standup except:2026-10-26.',
      ),
      day(
        '9-9:30 Standup @work rec:2w except:2026-10-12. '
        '$standup except:2026-10-26.',
      ),
    );
  });

  test('a bound the grammar cannot read is never paired', () {
    expect(
      merge(
        '$standup.',
        '$standup except:soon.',
        '$standup except:2026-10-26.',
      ),
      day('$standup except:soon. $standup except:2026-10-26.'),
    );
  });

  test('events without a rule are as they were: equal text only', () {
    expect(
      merge('9 gym.', '9 gym until:2026-12-31.', '9 gym except:2026-10-12.'),
      day('9 gym until:2026-12-31. 9 gym except:2026-10-12.'),
      reason: 'until: and except: mean nothing without a rec:',
    );
  });

  test('the merged line reads as one rule, every occurrence once', () {
    final merged = mergeCalendar(
      day('$standup.'),
      day('$standup except:2026-10-12.'),
      day('$standup except:2026-10-26.'),
    );
    final snapshot = calendarSnapshotOf(calendarFileOf(merged.split('\n')));
    final shown = [
      for (var d = 5; d <= 31; d++)
        if (snapshot.eventsFor(DateTime(2026, 10, d)).isNotEmpty) d,
    ];
    expect(shown, [5, 19]);
    expect(
      snapshot.eventsFor(DateTime(2026, 10, 5)),
      hasLength(1),
      reason: 'not twice on its own day',
    );
  });

  test('the line keeps the endings it had', () {
    const head = '2026-10-05 w41 Mon  ';
    final merged = mergeCalendar(
      '$head$standup.\r\n2026-10-06 w41 Tue  9 x.\n',
      '$head$standup except:2026-10-12.\r\n2026-10-06 w41 Tue  9 x.\n',
      '$head$standup except:2026-10-26.\r\n2026-10-06 w41 Tue  9 x.\n',
    );
    expect(
      merged,
      '$head$standup except:2026-10-12,2026-10-26.\r\n'
      '2026-10-06 w41 Tue  9 x.\n',
    );
  });
}
