import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_sync_secret_store.dart';
import '../fakes/fake_webdav_server.dart';

void main() {
  late FakeWebDavServer server;
  late Directory root;
  late Directory dbDir;
  late IndexDatabase index;
  late AppDatabase app;
  late NoteOps ops;
  late FakeSyncSecretStore secrets;
  late SyncStore store;
  late LibrarySyncService service;
  late String path;

  WebDavClient client(Uri url, String user, String password) => WebDavClient(
    url: url,
    username: user,
    password: password,
    timeout: const Duration(seconds: 5),
  );

  setUp(() async {
    server = await FakeWebDavServer.start();
    root = await Directory.current.createTemp('niman_svc_');
    dbDir = await Directory.current.createTemp('niman_svc_db_');
    index = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'i.db'))));
    app = AppDatabase(NativeDatabase.memory());
    path = p.normalize(root.path);
    ops = NoteOps(
      root: path,
      db: index,
      indexer: Indexer(index),
      config: LibraryConfigRepo(path),
    );
    secrets = FakeSyncSecretStore();
    store = SyncStore(app);
    service = LibrarySyncService(
      root: path,
      engine: SyncEngine(
        root: path,
        ops: ops,
        store: store,
        secrets: secrets,
        clientFactory: (d, password) =>
            client(Uri.parse(d.url), d.username, password),
      ),
      store: store,
      secrets: secrets,
      testClientFactory: client,
      quickDelay: const Duration(milliseconds: 100),
    );
  });

  /// Waits (in real time) until [condition] holds.
  Future<void> eventually(
    FutureOr<bool> Function() condition, {
    String reason = '',
  }) async {
    final clock = Stopwatch()..start();
    while (!await condition()) {
      if (clock.elapsed > const Duration(seconds: 10)) {
        fail('timed out waiting: $reason');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  tearDown(() async {
    await service.close();
    await ops.writer.indexed;
    await index.close();
    await app.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
    await server.close();
  });

  group('testConnection', () {
    test(
      'a working folder reports its capabilities and stores nothing',
      () async {
        final result = await service.testConnection(
          url: '${server.url}',
          username: '',
          password: '',
        );
        expect(result.ok, isTrue);
        expect(result.capabilities!.fileEtags, isTrue);
        expect(await store.destination(path), isNull);
        expect(secrets.secrets, isEmpty);
      },
    );

    test('each failure has its outcome', () async {
      Future<SyncTestOutcome> outcome(String url, {String user = ''}) async =>
          (await service.testConnection(
            url: url,
            username: user,
            password: 'x',
          )).outcome;

      expect(await outcome('ftp://nas/dav'), SyncTestOutcome.invalidUrl);
      expect(
        await outcome('http://u:p@127.0.0.1/dav/'),
        SyncTestOutcome.invalidUrl,
      );
      expect(await outcome('not a url'), SyncTestOutcome.invalidUrl);
      expect(
        await outcome('${server.origin}/nowhere/'),
        SyncTestOutcome.notFound,
      );
      server.credentials = (user: 'ale', password: 'right');
      expect(
        await outcome('${server.url}', user: 'ale'),
        SyncTestOutcome.authentication,
      );
      server
        ..credentials = null
        ..davHeader = false
        ..propfindRefused = true;
      expect(await outcome('${server.url}'), SyncTestOutcome.unsupported);
      final url = server.url;
      await server.close();
      expect(await outcome('$url'), SyncTestOutcome.offline);
      server = await FakeWebDavServer.start();
    });

    test('a null password tests with the stored one', () async {
      server.credentials = (user: 'ale', password: 'stored');
      await secrets.write(path, 'stored');
      final result = await service.testConnection(
        url: '${server.url}',
        username: 'ale',
      );
      expect(result.ok, isTrue);
    });
  });

  test('save, sync, resolve and disconnect move the status along', () async {
    final statuses = <SyncStatus>[];
    service.addListener(() => statuses.add(service.status));
    await service.load();
    expect(service.status.configured, isFalse);

    server.credentials = (user: 'ale', password: 'pw');
    final test = await service.testConnection(
      url: '${server.url}',
      username: 'ale',
      password: 'pw',
    );
    await service.save(
      url: '${server.url}',
      username: 'ale',
      password: 'pw',
      capabilities: test.capabilities,
    );
    expect(service.status.configured, isTrue);
    expect(service.status.capabilities, isNotNull);
    expect(await secrets.read(path), 'pw');

    File(p.join(path, 'a.md')).writeAsStringSync('local');
    server.putFile('b.md', 'remote'.codeUnits);
    final changes = <Set<String>>[];
    final sub = service.localChanges.listen(changes.add);
    addTearDown(sub.cancel);
    statuses.clear();
    final report = await service.syncNow();
    expect(report.clean, isTrue, reason: report.summary());
    expect(statuses.any((s) => s.running), isTrue);
    expect(
      statuses.map((s) => s.stage).whereType<SyncStage>().toSet(),
      containsAll([SyncStage.connecting, SyncStage.applying]),
    );
    expect(service.status.running, isFalse);
    expect(service.status.lastSyncAt, isNotNull);
    expect(service.status.lastReport, same(report));
    await pumpEventQueue();
    expect(changes.single, {'b.md'});

    // Saving again with a null password keeps the stored one.
    await service.save(url: '${server.url}', username: 'ale');
    expect(await secrets.read(path), 'pw');

    await service.disconnect();
    expect(service.status.configured, isFalse);
    expect(await store.destination(path), isNull);
    expect(await secrets.read(path), isNull);
    expect(File(p.join(path, 'a.md')).existsSync(), isTrue);
    expect(server.exists('a.md'), isTrue);
  });

  test('a resolved conflict leaves the status and reloads the file', () async {
    await service.save(url: '${server.url}', username: '');
    File(p.join(path, 'a.md')).writeAsStringSync('base');
    await service.syncNow();
    File(p.join(path, 'a.md'))
      ..writeAsStringSync('mine, longer')
      ..setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));
    server.putFile('a.md', 'theirs'.codeUnits);
    final report = await service.syncNow();
    expect(
      service.status.conflicts.single.path,
      'a.md',
      reason: report.summary(),
    );

    final changes = <Set<String>>[];
    final sub = service.localChanges.listen(changes.add);
    addTearDown(sub.cancel);
    await service.resolveConflict('a.md', keepLocal: false);
    await pumpEventQueue();
    expect(service.status.conflicts, isEmpty);
    expect(changes.single, {'a.md'});
    expect(File(p.join(path, 'a.md')).readAsStringSync(), 'theirs');
  });

  group('automatic sync', () {
    String? remote(String rel) {
      final bytes = server.file(rel);
      return bytes == null ? null : utf8.decode(bytes);
    }

    setUp(() async {
      ops.syncHints = service.hint;
      await service.save(url: '${server.url}', username: '');
      File(p.join(path, 'a.md')).writeAsStringSync('one');
      final first = await service.syncNow();
      expect(first.clean, isTrue, reason: first.summary());
      await ops.writer.indexed;
      await service.start();
    });

    test('a saved note reaches the server by itself', () async {
      await ops.saveNote('a.md', 'two');
      await eventually(() => remote('a.md') == 'two', reason: 'upload');
      await eventually(
        () async => (await store.pendingOps(path)).isEmpty,
        reason: 'the hint settled',
      );
      await eventually(() => service.status.pendingHints == 0);
      expect(service.status.running, isFalse);
    });

    test('the watcher queues what changed behind the ops', () async {
      final abs = p.join(path, 'Notes', 'b.md');
      File(abs)
        ..parent.createSync()
        ..writeAsStringSync('from another app');
      service.watched([abs, p.join(path, '.history', 'x.v1')], []);
      await eventually(
        () => remote('Notes/b.md') == 'from another app',
        reason: 'upload',
      );
    });

    test("the watcher's echo of a sync download queues nothing", () async {
      server.putFile('c.md', utf8.encode('remote'));
      await service.syncNow();
      await ops.writer.indexed;
      service.watched([p.join(path, 'c.md')], []);
      await pumpEventQueue();
      expect(await store.pendingOps(path), isEmpty);
    });

    test('a server out of reach shows the queue and when it retries', () async {
      server.failNext(503, count: 5);
      await ops.saveNote('a.md', 'offline edit');
      await eventually(
        () => service.status.aborted == SyncAbort.offline,
        reason: 'the quick sync failed',
      );
      await eventually(() => service.status.pendingHints == 1);
      expect(service.status.nextRetryAt, isNotNull);
      expect(service.status.needsAttention, isTrue);
      expect(remote('a.md'), 'one');
    });

    test('the trigger options are stored and shown', () async {
      await service.setTriggers(intervalSeconds: 300, wifiOnly: true);
      final row = (await store.destination(path))!;
      expect(row.intervalSeconds, 300);
      expect(row.wifiOnly, isTrue);
      expect(row.autoSync, isTrue);
      expect(service.status.destination!.intervalSeconds, 300);
      expect(service.offersWifiOnly, isFalse, reason: 'not a phone');
    });
  });
}
