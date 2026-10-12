import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// `:::: columns` on line 0, a column over lines 1–3 and one over 4–6, its
/// closer on line 7.
const LiveRun _run = LiveRun(
  start: 0,
  end: 8,
  closed: true,
  items: 0,
  columns: [(start: 1, end: 4, width: null), (start: 4, end: 7, width: null)],
);

LiveHosts _laidOut() => LiveHosts()
  ..layOut(
    const [_run],
    widthOf: (_) => 800,
    em: 14,
    estimate: (_, _) => 20,
    allowed: (_) => true,
  );

/// Enter on [line] of [hosts]' note: one line replaced by two.
void _enter(LiveHosts hosts, int line) => hosts.edited(
  SourceEdit(firstLine: line, removedLines: 1, insertedLines: 2, revision: 1),
  (_, _) => 20,
);

void main() {
  test('Enter in the first column moves neither the opener nor its start', () {
    final hosts = _laidOut();
    expect(hosts.layouts, hasLength(1));
    _enter(hosts, 2);
    final layout = hosts.openedOn(0);
    expect(layout, isNotNull);
    final run = layout!.run;
    expect((run.start, run.end), (0, 9));
    expect(run.columns.map((c) => (c.start, c.end)), [(1, 5), (5, 8)]);
    expect(layout.maps.first.length, 4);
    expect(layout.maps.last.length, 3);
  });

  test('Enter in the second column moves only what is past it', () {
    final hosts = _laidOut();
    _enter(hosts, 5);
    final run = hosts.openedOn(0)!.run;
    expect((run.start, run.end), (0, 9));
    expect(run.columns.map((c) => (c.start, c.end)), [(1, 4), (4, 8)]);
  });

  test('an edit above the block moves all of it', () {
    final hosts = LiveHosts()
      ..layOut(
        [
          LiveRun(
            start: _run.start + 2,
            end: _run.end + 2,
            closed: true,
            items: 0,
            columns: [
              for (final c in _run.columns)
                (start: c.start + 2, end: c.end + 2, width: null),
            ],
          ),
        ],
        widthOf: (_) => 800,
        em: 14,
        estimate: (_, _) => 20,
        allowed: (_) => true,
      );
    _enter(hosts, 0);
    final run = hosts.openedOn(3)!.run;
    expect((run.start, run.end), (3, 11));
    expect(run.columns.map((c) => (c.start, c.end)), [(4, 7), (7, 10)]);
  });
}
