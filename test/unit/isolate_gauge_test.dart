// Issue #103: the in-flight isolate gauge. What matters is that the
// count is honest — a job that throws must still be counted out, or a
// stalled run's "in flight" reading is worthless.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/isolate_gauge.dart';

int _double(int n) => n * 2;

int _boom() => throw StateError('boom');

void main() {
  test('a job runs, returns its value and is counted out', () async {
    final before = IsolateGauge.inFlight;

    expect(await IsolateGauge.run(() => _double(21), 'double'), 42);

    expect(IsolateGauge.inFlight, before);
  });

  test('a job that throws rethrows and is still counted out', () async {
    final before = IsolateGauge.inFlight;

    await expectLater(
      IsolateGauge.run(_boom, 'boom'),
      throwsA(isA<StateError>()),
    );

    expect(IsolateGauge.inFlight, before);
  });

  test('a long-running job is counted from begin to finishJob', () {
    final before = IsolateGauge.inFlight;

    final job = IsolateGauge.begin('stream "Notes/a.md"');
    expect(IsolateGauge.inFlight, before + 1);

    IsolateGauge.finishJob(job);
    expect(IsolateGauge.inFlight, before);

    // A second finish for the same ticket is a no-op: a caller that tidies
    // up twice must not count somebody else's job out.
    IsolateGauge.finishJob(job);
    expect(IsolateGauge.inFlight, before);
  });

  test('concurrent jobs raise the peak and all come back', () async {
    final before = IsolateGauge.peak;

    final results = await Future.wait([
      for (var i = 0; i < 3; i++) IsolateGauge.run(() => _double(i), 'job $i'),
    ]);

    expect(results, [0, 2, 4]);
    expect(IsolateGauge.peak, greaterThanOrEqualTo(before));
    expect(IsolateGauge.peak, greaterThanOrEqualTo(3));
    expect(IsolateGauge.inFlight, 0);
  });
}
