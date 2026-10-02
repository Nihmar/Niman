// The Mermaid Gantt parser (#530): the date formats, every way a task
// writes its start and end, the excluded days, and the errors that name a
// line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/gantt_dates.dart';
import 'package:niman/src/diagrams/gantt_model.dart';
import 'package:niman/src/diagrams/gantt_parser.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

DateTime _d(int y, int m, int d, [int h = 0]) => DateTime.utc(y, m, d, h);

List<GanttTask> _tasks(GanttChart chart) => [
  for (final section in chart.sections) ...section.tasks,
];

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('a date format reads its own dates and refuses others', () {
    final iso = GanttDateFormat.of('YYYY-MM-DD');
    expect(iso.read('2014-01-06'), _d(2014, 1, 6));
    expect(iso.read('2014-02-30'), isNull);
    expect(iso.read('06/01/2014'), isNull);
    final european = GanttDateFormat.of('DD/MM/YYYY HH:mm');
    expect(european.read('06/01/2014 09:30'), DateTime.utc(2014, 1, 6, 9, 30));
    expect(GanttDateFormat.of('X').read('86400'), _d(1970, 1, 2));
  });

  test('a duration is written in its units', () {
    expect(ganttDuration('3d'), const Duration(days: 3));
    expect(ganttDuration('2w'), const Duration(days: 14));
    expect(ganttDuration('1.5d'), const Duration(hours: 36));
    expect(ganttDuration('12h'), const Duration(hours: 12));
    expect(ganttDuration('3 days'), isNull);
  });

  test('the axis writes a date in strftime', () {
    final date = DateTime.utc(2014, 1, 6, 9, 5);
    expect(formatGanttDate(date, '%Y-%m-%d'), '2014-01-06');
    expect(formatGanttDate(date, '%d %b'), '06 Jan');
    expect(formatGanttDate(date, '%A %e %B, %H:%M'), 'Monday 6 January, 09:05');
  });

  test('every way of writing a start and an end resolves', () {
    final chart = parseGantt(
      'gantt\n'
      'title A plan\n'
      'dateFormat YYYY-MM-DD\n'
      'section One\n'
      'First   :a1, 2014-01-01, 30d\n'
      'Second  :after a1, 20d\n'
      'section Two\n'
      'Third   :2014-01-12, 12d\n'
      'Fourth  :24d\n'
      'Fifth   :done, d1, 2014-01-06, 2014-01-08\n'
      'Sixth   :crit, active, 2014-01-06, until d1\n'
      'Seventh :milestone, m1, 2014-01-25, 0d',
    );
    expect(chart.title, 'A plan');
    expect(chart.sections.map((s) => s.name), ['One', 'Two']);
    final tasks = _tasks(chart);
    expect(
      [for (final t in tasks) (t.start, t.end)],
      [
        (_d(2014, 1, 1), _d(2014, 1, 31)),
        (_d(2014, 1, 31), _d(2014, 2, 20)),
        (_d(2014, 1, 12), _d(2014, 1, 24)),
        (_d(2014, 1, 24), _d(2014, 2, 17)),
        (_d(2014, 1, 6), _d(2014, 1, 8)),
        (_d(2014, 1, 6), _d(2014, 1, 6)),
        (_d(2014, 1, 25), _d(2014, 1, 25)),
      ],
    );
    expect(tasks[4].done, isTrue);
    expect(tasks[5].critical && tasks[5].active, isTrue);
    expect(tasks[6].milestone, isTrue);
  });

  test('a task may wait on one written after it, and on several', () {
    final tasks = _tasks(
      parseGantt(
        'gantt\nLast :after a b, 1d\n'
        'A :a, 2024-03-01, 2d\nB :b, 2024-03-01, 5d',
      ),
    );
    expect(tasks.first.start, _d(2024, 3, 6));
  });

  test('excluded days stretch a task over them', () {
    final tasks = _tasks(
      parseGantt(
        'gantt\nexcludes weekends, 2024-03-13\n'
        'Week :2024-03-08, 5d',
      ),
    );
    // From Friday the 8th, five working days — the 8th, 11th, 12th, 14th
    // and 15th — skipping the weekends and Wednesday the 13th.
    expect(tasks.single.end, _d(2024, 3, 18));
  });

  test('tasks before the first section have a section of their own', () {
    final chart = parseGantt('gantt\nLoose :2024-01-01, 1d\nsection S\nIn :1d');
    expect(chart.sections.map((s) => s.name), ['', 'S']);
  });

  test('settings the drawing has no use for are read past', () {
    final chart = parseGantt(
      'gantt\ntodayMarker off\ntickInterval 1week\nweekday monday\n'
      'axisFormat %d/%m\naccTitle: x\nT :t, 2024-01-01, 1d\nclick t href "x"',
    );
    expect(chart.axisFormat, '%d/%m');
  });

  test('what does not read names its line', () {
    expect(
      () => parseGantt('gantt\nA :2024-13-01, 1d'),
      _error(2, 'expected a date'),
    );
    expect(
      () => parseGantt('gantt\nA :2024-01-01, soon'),
      _error(2, 'expected a duration'),
    );
    expect(
      () => parseGantt('gantt\nA :after nobody, 1d'),
      _error(2, 'no task has the id "nobody"'),
    );
    expect(
      () => parseGantt('gantt\nA :a, after b, 1d\nB :b, after a, 1d'),
      _error(2, 'waits on itself'),
    );
    expect(() => parseGantt('gantt\nJust words'), _error(2, 'expected a task'));
    expect(() => parseGantt('gantt\nA :1d'), _error(2, 'needs a start'));
    expect(() => parseGantt('gantt\ntitle x'), _error(1, 'needs a task'));
  });
}
