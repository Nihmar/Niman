// What the file watcher's batches queue for the sync, in the order the
// batches came (#1147 review): the probe that tells a changed file from a
// deleted one runs on an isolate, and two batches' probes must not race.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/file_watcher.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_sync_secret_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory root;

  setUp(() async {
    tmp = await Directory.current.createTemp('niman_watch_sync_');
    root = Directory(p.join(tmp.path, 'library'))..createSync();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<AppDatabase> appDb() async =>
      AppDatabase(NativeDatabase(File(p.join(tmp.path, 'niman.db'))));

  Future<IndexDatabase> indexDb(String libraryPath) async => IndexDatabase(
    NativeDatabase(File(p.join(tmp.path, '${p.basename(libraryPath)}.db'))),
  );

  test('two batches whose probes would answer out of order leave the last '
      "state's hint", () async {
    final watched = StreamController<WatchChange>.broadcast();
    addTearDown(watched.close);
    final secrets = FakeSyncSecretStore();

    // The probe is the test's: the first batch's answer ("it is there") is
    // held until released, the second's ("it is gone") comes at once. Left
    // to race, the second lands first and the first's "changed" is queued
    // after it for a file that no longer exists.
    final releaseFirst = Completer<void>();
    final firstAsked = Completer<void>();
    final secondAsked = Completer<void>();
    var asked = 0;
    Future<List<bool>> probe(List<String> paths) async {
      final call = ++asked;
      if (call == 1) {
        firstAsked.complete();
        await releaseFirst.future;
        return [for (final _ in paths) true];
      }
      if (!secondAsked.isCompleted) secondAsked.complete();
      return [for (final _ in paths) false];
    }

    final controller = LibraryController(
      appDb,
      indexDbFactory: indexDb,
      rescanInterval: const Duration(hours: 1),
      // Each change is a batch of its own.
      watcherDebounce: Duration.zero,
      watchSource: (_) => watched.stream,
      syncSecrets: secrets,
      syncProbe: probe,
    );
    addTearDown(controller.dispose);

    // A destination with no automatic sync: the queue fills, nothing runs.
    await controller.open(root.path, create: false);
    await controller.close();
    final store = SyncStore(await controller.appDatabase);
    await store.saveDestination(
      libraryPath: root.path,
      url: Uri.parse('http://nas/dav/'),
      autoSync: false,
    );
    await controller.open(root.path, create: false);

    final note = p.join(root.path, 'b.md');
    watched.add(WatchChange(note));
    await firstAsked.future.timeout(const Duration(seconds: 10));

    // The second batch arrives while the first one's probe is out.
    watched.add(WatchChange(note));
    await pumpEventQueue(times: 100);
    releaseFirst.complete();
    await secondAsked.future.timeout(const Duration(seconds: 10));
    await pumpEventQueue(times: 100);

    // Read behind the writes the batches issued: the last word is the
    // second batch's, "deleted".
    final queued = await store.pendingOps(p.normalize(root.path));
    expect(queued.map((op) => (op.path, op.kind)).toList(), [
      ('b.md', 'deleted'),
    ]);
    await controller.close();
  });
}
