// #1107: what a sync moves, and how fast, measured where the app pays it.
//
// The sync's file transfers used to run on the app's own isolate, one file at
// a time; they now run on a worker isolate, four at once. This runs the same
// payloads through both — the old path (the transfers on the client, one
// step at a time: `InlineSyncTransfers`, a pool of one) and the new
// (`IsolateSyncTransfers`, a pool of four) — against a server that lives in
// an isolate of its own, so the client is the only thing timed:
//
//   * one large file, down and up;
//   * the same with the test's own isolate kept busy, as the app's is by
//     frames, the file watcher and the indexer: the case the worker exists
//     for, since a transfer on a busy isolate waits for its turn on every
//     chunk;
//   * many small files, down and up;
//   * the same many small files with a pause per transfer, the round trip
//     of a real link, which is what the pool exists to hide.
//
// Every number is printed (MiB/s of the apply phase, from the run's own
// report) and the run asserts only a backstop: everything arrived intact,
// and the new path is not slower than the old one by more than a loopback
// run's noise. The design's bars are asserted by a run that asks for them,
// `NIMAN_PERF=1 flutter test test/perf/sync_transfer_test.dart` (AGENTS.md,
// #329): a shared runner reads wall-clock differently from the machine the
// bars were set on.
// ignore_for_file: avoid_print
@Timeout(Duration(minutes: 10))
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_step_pool.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/sync_transfer_line.dart';
import 'package:niman/src/sync/transfers/inline_sync_transfers.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_sync_secret_store.dart';
import '../fakes/fake_webdav_server_isolate.dart';

/// Whether this run holds the design's bars (AGENTS.md, #329).
final bool _strict = Platform.environment['NIMAN_PERF'] == '1';

/// The large file, in bytes.
const int _largeBytes = 64 * 1024 * 1024;

/// How many small files there are, and how long each is.
const int _smallCount = 200;
const int _smallBytes = 40 * 1024;

/// The pause a transfer takes on the server in the round-trip cases.
const Duration _roundTrip = Duration(milliseconds: 10);

/// One way to run the transfers.
enum _Path {
  /// The transfers on the client, one step at a time: how a run went before.
  inlineSerial('inline + serial'),

  /// The transfers on a worker isolate, four at once.
  isolatePool('isolate + pool');

  new(this.label);

  final String label;
}

/// One device's library, index, state and engine.
final class _Device {
  new _(this.root, this.dbDir, this.index, this.app, this.ops, this.engine);

  static Future<_Device> create(_Path path, Uri url) async {
    final root = await Directory.systemTemp.createTemp('niman_perf_sync');
    final dbDir = await Directory.systemTemp.createTemp('niman_perf_db');
    // In memory: the index is a rebuildable cache, and an fsync per upserted
    // file on this isolate would be timed in place of the transfers.
    final index = IndexDatabase(NativeDatabase.memory());
    final app = AppDatabase(NativeDatabase.memory());
    final libraryPath = p.normalize(root.path);
    final ops = NoteOps(
      root: libraryPath,
      db: index,
      indexer: Indexer(index),
      config: LibraryConfigRepo(libraryPath),
    );
    final store = SyncStore(app);
    await store.saveDestination(libraryPath: libraryPath, url: url);
    final engine = SyncEngine(
      root: libraryPath,
      ops: ops,
      store: store,
      secrets: FakeSyncSecretStore(),
      // The old path: the transfers on the client, one step at a time.
      transferConcurrency: path == _Path.inlineSerial
          ? 1
          : kSyncTransferConcurrency,
      transfersFactory: path == _Path.inlineSerial
          ? InlineSyncTransfers.new
          : null,
      clientFactory: (destination, password) =>
          WebDavClient(url: Uri.parse(destination.url)),
    );
    return _Device._(root, dbDir, index, app, ops, engine);
  }

  final Directory root;
  final Directory dbDir;
  final IndexDatabase index;
  final AppDatabase app;
  final NoteOps ops;
  final SyncEngine engine;

  Future<SyncReport> sync() async {
    final report = (await engine.run()).report;
    await ops.writer.indexed;
    return report;
  }

  Future<void> close() async {
    await ops.writer.indexed;
    await index.close();
    await app.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  }
}

/// A finished run, with the bytes it was asked to move.
typedef _Run = ({_Path path, SyncReport report, int payload});

String _rate(_Run run) => formatRate(run.payload, run.report.applyMs) ?? 'n/a';

double _mibPerSecond(_Run run) =>
    run.payload / (1024 * 1024) / (run.report.applyMs.clamp(1, 1 << 40) / 1000);

/// Keeps this isolate busy about three quarters of the time, in slices of
/// 6 ms: what drawing frames, watching the tree and indexing do to the
/// isolate the sync used to run on.
Timer _loadTheIsolate() => Timer.periodic(const Duration(milliseconds: 8), (_) {
  final slice = Stopwatch()..start();
  while (slice.elapsedMilliseconds < 6) {}
});

String _name(int index) => 'f${index.toString().padLeft(3, '0')}.png';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late IsolatedWebDavServer server;

  setUp(() async {
    server = await IsolatedWebDavServer.start();
  });

  tearDown(() => server.close());

  /// Runs one scenario on a fresh device of [path], against an empty server
  /// tree where every transfer takes [hold]: [arrange] sets the two sides
  /// up, the sync runs, [check] looks at what it left.
  Future<_Run> run(
    _Path path, {
    required Duration hold,
    required int payload,
    required Future<void> Function(_Device d) arrange,
    required void Function(SyncReport report) check,
    bool busy = false,
  }) async {
    await server.clear();
    await server.hold(hold == Duration.zero ? null : hold);
    final d = await _Device.create(path, server.url);
    try {
      await arrange(d);
      final load = busy ? _loadTheIsolate() : null;
      final SyncReport report;
      try {
        report = await d.sync();
      } finally {
        load?.cancel();
      }
      check(report);
      return (path: path, report: report, payload: payload);
    } finally {
      await d.close();
    }
  }

  /// Both paths through the same scenario, the numbers printed.
  Future<Map<_Path, _Run>> measure(
    String name,
    Future<_Run> Function(_Path path) scenario,
  ) async {
    final runs = <_Path, _Run>{};
    for (final path in _Path.values) {
      final result = await scenario(path);
      final r = result.report;
      print(
        '[perf] $name, ${path.label}: scan ${r.scanMs} ms, '
        'hash ${r.hashMs} ms, apply ${r.applyMs} ms = ${_rate(result)} '
        'of ${formatBytes(result.payload)}',
      );
      runs[path] = result;
    }
    final before = runs[_Path.inlineSerial]!.report.applyMs;
    final after = runs[_Path.isolatePool]!.report.applyMs;
    print(
      '[perf] $name: apply $before ms -> $after ms '
      '(${(before / after.clamp(1, 1 << 40)).toStringAsFixed(2)}x)',
    );
    // The backstop every run holds: the new path is not slower than the old
    // by more than a loopback run's noise.
    expect(after, lessThan(before * 3 + 500));
    return runs;
  }

  test('one large file down', () async {
    final runs = await measure('large download', (path) {
      return run(
        path,
        hold: Duration.zero,
        payload: _largeBytes,
        arrange: (d) => server.putGenerated('big.bin', _largeBytes, seed: 7),
        check: (report) {
          expect(report.done[SyncActionKind.download], 1);
          expect(report.bytesDown, _largeBytes);
          expect(report.clean, isTrue, reason: report.summary());
        },
      );
    });
    // What arrived is what the server holds, byte for byte.
    expect(
      sha256.convert(generatedBytes(_largeBytes, seed: 7)).toString(),
      await server.sha256Of('big.bin'),
    );
    if (_strict) {
      expect(
        _mibPerSecond(runs[_Path.isolatePool]!),
        greaterThan(30),
        reason: 'the isolate download holds 30 MiB/s',
      );
    }
  });

  test('one large file up', () async {
    final runs = await measure('large upload', (path) {
      return run(
        path,
        hold: Duration.zero,
        payload: _largeBytes,
        arrange: (d) async =>
            File(p.join(d.root.path, 'big.bin'))
                .writeAsBytesSync(generatedBytes(_largeBytes, seed: 9)),
        check: (report) {
          expect(report.done[SyncActionKind.upload], 1);
          expect(report.bytesUp, greaterThanOrEqualTo(_largeBytes));
          expect(report.clean, isTrue, reason: report.summary());
        },
      );
    });
    expect(await server.length('big.bin'), _largeBytes);
    expect(
      await server.sha256Of('big.bin'),
      sha256.convert(generatedBytes(_largeBytes, seed: 9)).toString(),
    );
    if (_strict) {
      expect(
        _mibPerSecond(runs[_Path.isolatePool]!),
        greaterThan(30),
        reason: 'the isolate upload holds 30 MiB/s',
      );
    }
  });

  test('one large file down, the isolate busy', () async {
    final runs = await measure('large download, busy isolate', (path) {
      return run(
        path,
        hold: Duration.zero,
        payload: _largeBytes,
        busy: true,
        arrange: (d) => server.putGenerated('big.bin', _largeBytes, seed: 7),
        check: (report) {
          expect(report.done[SyncActionKind.download], 1);
          expect(report.bytesDown, _largeBytes);
          expect(report.clean, isTrue, reason: report.summary());
        },
      );
    });
    if (_strict) {
      expect(
        _mibPerSecond(runs[_Path.isolatePool]!),
        greaterThan(2 * _mibPerSecond(runs[_Path.inlineSerial]!)),
        reason: 'the worker keeps its speed while the isolate is busy',
      );
    }
  });

  test('one large file up, the isolate busy', () async {
    final runs = await measure('large upload, busy isolate', (path) {
      return run(
        path,
        hold: Duration.zero,
        payload: _largeBytes,
        busy: true,
        arrange: (d) async =>
            File(p.join(d.root.path, 'big.bin'))
                .writeAsBytesSync(generatedBytes(_largeBytes, seed: 9)),
        check: (report) {
          expect(report.done[SyncActionKind.upload], 1);
          expect(report.bytesUp, greaterThanOrEqualTo(_largeBytes));
          expect(report.clean, isTrue, reason: report.summary());
        },
      );
    });
    if (_strict) {
      expect(
        _mibPerSecond(runs[_Path.isolatePool]!),
        greaterThan(2 * _mibPerSecond(runs[_Path.inlineSerial]!)),
        reason: 'the worker keeps its speed while the isolate is busy',
      );
    }
  });

  for (final hold in [Duration.zero, _roundTrip]) {
    final suffix = hold == Duration.zero
        ? ''
        : ' with ${hold.inMilliseconds} ms per transfer';
    const payload = _smallCount * _smallBytes;

    // What the pool buys on a link with round trips: the files wait for
    // the link together instead of one after the other, so a run is at least
    // twice as fast.
    void faster(Map<_Path, _Run> runs, num factor) {
      if (!_strict || hold == Duration.zero) return;
      expect(
        runs[_Path.isolatePool]!.report.applyMs * factor,
        lessThan(runs[_Path.inlineSerial]!.report.applyMs),
        reason: 'the pool is at least ${factor}x faster over round trips',
      );
    }

    test('many small files down$suffix', () async {
      final runs = await measure('small download$suffix', (path) {
        return run(
          path,
          hold: hold,
          payload: payload,
          arrange: (d) async {
            for (var i = 0; i < _smallCount; i++) {
              await server.putGenerated(
                'Attachments/${_name(i)}',
                _smallBytes,
                seed: i,
              );
            }
          },
          check: (report) {
            expect(report.done[SyncActionKind.download], _smallCount);
            expect(report.bytesDown, payload);
            expect(report.clean, isTrue, reason: report.summary());
          },
        );
      });
      faster(runs, 2);
    });

    test('many small files up$suffix', () async {
      final runs = await measure('small upload$suffix', (path) {
        return run(
          path,
          hold: hold,
          payload: payload,
          arrange: (d) async {
            final folder = Directory(p.join(d.root.path, 'Attachments'))
              ..createSync(recursive: true);
            for (var i = 0; i < _smallCount; i++) {
              File(p.join(folder.path, _name(i)))
                  .writeAsBytesSync(generatedBytes(_smallBytes, seed: i));
            }
          },
          check: (report) {
            expect(report.done[SyncActionKind.upload], _smallCount);
            expect(report.bytesUp, greaterThanOrEqualTo(payload));
            expect(report.clean, isTrue, reason: report.summary());
          },
        );
      });
      expect(await server.filesUnder('Attachments'), _smallCount);
      faster(runs, 2);
    });
  }
}
