// What a test's heap holds, in bytes, for the memory perf files (#1193).
//
// Two readings, one exact and one a bound. With the VM service — a run asked
// for with `flutter test --enable-vmservice` — the heap is read after a
// collection (`getAllocationProfile(gc: true)`), so what a structure holds is
// the difference with it and without it, to the byte. Without it the only
// figure a test can read is the process's resident set
// (`ProcessInfo.currentRss`), which counts what the collector has not freed
// yet and what the heap already had: a bound, read as the median of a few
// runs (`test/perf/block_memory_test.dart` says how far it strays).
import 'dart:developer';
import 'dart:io';
import 'dart:isolate' as isolates;

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Reads the heap of the isolate the test runs in.
final class HeapMeter {
  new _(this._service, this._isolateId);

  /// The meter over the VM service when the run offers one, else the meter
  /// over the resident set.
  static Future<HeapMeter> open() async {
    final info = await Service.getInfo();
    final uri = info.serverWebSocketUri;
    final id = Service.getIsolateId(isolates.Isolate.current);
    if (uri == null || id == null) return HeapMeter._(null, null);
    return HeapMeter._(await vmServiceConnectUri(uri.toString()), id);
  }

  final VmService? _service;
  final String? _isolateId;

  /// Whether [held] reads the heap itself, to the byte.
  bool get exact => _service != null;

  /// What it reads, for the printed line.
  String get unit => exact ? 'heap after a collection' : 'resident set, median';

  /// How many bytes the object [build] makes holds: the heap with it minus
  /// the heap without it. [runs] readings over the resident set, the median
  /// kept; one over the heap, which needs no more.
  Future<int> held(Object Function() build, {int runs = 5}) async {
    if (exact) {
      final before = await _heap();
      final kept = build();
      final after = await _heap();
      // Read after the second collection: what is measured stays alive.
      if (identical(kept, _sink)) return 0;
      return after - before;
    }
    final readings = <int>[];
    for (var run = 0; run < runs; run++) {
      _churn();
      final before = ProcessInfo.currentRss;
      final kept = build();
      _churn();
      readings.add(ProcessInfo.currentRss - before);
      if (identical(kept, _sink)) return 0;
    }
    readings.sort();
    return readings[readings.length ~/ 2];
  }

  /// The heap in use after a collection: new space and old space, and the
  /// external memory the heap's objects own (a typed list's bytes).
  Future<int> _heap() async {
    final profile = await _service!.getAllocationProfile(_isolateId!, gc: true);
    final usage = profile.memoryUsage!;
    return usage.heapUsage! + usage.externalUsage!;
  }

  /// Lets go of the VM service connection.
  Future<void> close() async {
    await _service?.dispose();
  }
}

/// Never any object a measurement makes: its identity check keeps the object
/// alive until after the reading, which the optimizer could otherwise end.
final Object _sink = Object();

/// Fills and drops large lists, which is what makes the collector run.
void _churn() {
  for (var round = 0; round < 20; round++) {
    List<int>.filled(4 << 20, 0);
  }
  sleep(const Duration(milliseconds: 200));
}
