import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/sync_step_pool.dart';

/// A step of a test run: a name, whether it may overlap, and the key of
/// what it works on.
typedef _Step = ({String name, bool parallel, String key});

_Step _parallel(String name, {String? key}) =>
    (name: name, parallel: true, key: key ?? name);

_Step _barrier(String name) => (name: name, parallel: false, key: name);

SyncStepPool<_Step> _pool(
  int concurrency, {
  void Function(Object error)? onFatal,
}) => SyncStepPool<_Step>(
  concurrency: concurrency,
  isParallel: (s) => s.parallel,
  keyOf: (s) => s.key,
  onFatal: onFatal,
);

const _tick = Duration(milliseconds: 20);

void main() {
  test('at most the pool width are in flight, and it fills up', () async {
    final pool = _pool(4);
    var active = 0;
    var peak = 0;

    await pool.run([for (var i = 0; i < 12; i++) _parallel('t$i')], (s) async {
      active++;
      if (active > peak) peak = active;
      await Future<void>.delayed(_tick);
      active--;
    });

    expect(peak, 4);
    expect(pool.peak, 4);
    expect(active, 0);
  });

  test('a pool of one runs the steps in plan order', () async {
    final pool = _pool(1);
    final started = <String>[];
    final finished = <String>[];

    await pool.run(
      [_parallel('a'), _barrier('b'), _parallel('c'), _parallel('d')],
      (s) async {
        started.add(s.name);
        await Future<void>.delayed(_tick);
        finished.add(s.name);
      },
    );

    expect(started, ['a', 'b', 'c', 'd']);
    expect(finished, ['a', 'b', 'c', 'd']);
  });

  test('a barrier waits for what is in flight and runs alone', () async {
    final pool = _pool(4);
    final events = <String>[];

    await pool.run(
      [
        _parallel('u1'),
        _parallel('u2'),
        _parallel('u3'),
        _barrier('delete'),
        _parallel('u4'),
        _parallel('u5'),
      ],
      (s) async {
        events.add('start ${s.name}');
        await Future<void>.delayed(s.name == 'u2' ? _tick * 3 : _tick);
        events.add('end ${s.name}');
      },
    );

    final delete = events.indexOf('start delete');
    expect(
      events.sublist(0, delete),
      containsAll(['end u1', 'end u2', 'end u3']),
      reason: '$events',
    );
    expect(events[delete + 1], 'end delete', reason: 'it runs alone');
    expect(
      events.sublist(delete + 2).first,
      startsWith('start u'),
      reason: 'nothing after it started before it ended',
    );
  });

  test('two steps on one key never overlap', () async {
    final pool = _pool(4);
    var onShared = 0;
    var overlapped = false;

    await pool.run(
      [
        _parallel('x1', key: 'shared'),
        _parallel('x2', key: 'shared'),
        _parallel('y'),
      ],
      (s) async {
        if (s.key == 'shared') {
          onShared++;
          if (onShared > 1) overlapped = true;
        }
        await Future<void>.delayed(_tick);
        if (s.key == 'shared') onShared--;
      },
    );

    expect(overlapped, isFalse);
  });

  test('a fatal step stops the starts, is reported once and winds the '
      'others up before it is thrown', () async {
    final heard = <Object>[];
    final pool = _pool(4, onFatal: heard.add);
    final started = <String>[];
    final finished = <String>[];

    final run = pool.run([for (var i = 0; i < 10; i++) _parallel('t$i')], (
      s,
    ) async {
      started.add(s.name);
      if (s.name == 't1') {
        await Future<void>.delayed(_tick);
        throw const FormatException('first');
      }
      if (s.name == 't2') {
        await Future<void>.delayed(_tick * 2);
        throw StateError('second');
      }
      await Future<void>.delayed(_tick * 4);
      finished.add(s.name);
    });

    await expectLater(run, throwsA(isA<FormatException>()));
    expect(heard, hasLength(1));
    expect(heard.single, isA<FormatException>());
    expect(started, hasLength(4), reason: 'only the first four ever started');
    expect(
      finished,
      unorderedEquals(['t0', 't3']),
      reason: 'the others were waited for, not abandoned',
    );
    expect(pool.aborted, isTrue);
  });

  test('a fatal barrier stops what follows', () async {
    final pool = _pool(2);
    final started = <String>[];

    final run = pool.run([_parallel('a'), _barrier('b'), _parallel('c')], (
      s,
    ) async {
      started.add(s.name);
      if (s.name == 'b') throw StateError('b');
    });

    await expectLater(run, throwsStateError);
    expect(started, ['a', 'b']);
  });

  test('a run that fails nowhere throws nothing and is not aborted', () async {
    final pool = _pool(3);

    await pool.run([_parallel('a'), _barrier('b')], (s) async {});

    expect(pool.aborted, isFalse);
  });
}
