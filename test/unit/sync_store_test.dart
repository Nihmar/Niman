import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late SyncStore store;
  var clock = DateTime.utc(2026, 9, 15, 12);

  // Normalized, so the spelling is whatever this platform stores.
  final lib = p.normalize('/libraries/Work');
  final other = p.normalize('/libraries/Home');

  setUp(() {
    clock = DateTime.utc(2026, 9, 15, 12);
    db = AppDatabase(NativeDatabase.memory());
    store = SyncStore(db, now: () => clock);
  });

  tearDown(() => db.close());

  SyncItem item(String path, {String? library, String sha = 'aa'}) => SyncItem(
    libraryPath: library ?? lib,
    path: path,
    localSha256: sha,
    localSize: 3,
    localMtimeMs: 1000,
    remoteEtag: '"e1"',
    remoteSize: 3,
    remoteMtimeMs: 1000,
    remoteUnverified: false,
    baseVersion: 4,
    syncedAtMs: 2000,
  );

  Future<Map<String, String>> queue([String? library]) async => {
    for (final op in await store.pendingOps(library ?? lib))
      op.path: op.fromPath == null ? op.kind : '${op.kind}<${op.fromPath}',
  };

  test('backoff doubles from 5 s and stops at 10 minutes', () {
    expect(syncBackoff(0), Duration.zero);
    expect(syncBackoff(1), const Duration(seconds: 5));
    expect(syncBackoff(2), const Duration(seconds: 10));
    expect(syncBackoff(4), const Duration(seconds: 40));
    expect(syncBackoff(8), const Duration(minutes: 10));
    expect(syncBackoff(60), const Duration(minutes: 10));
  });

  group('destinations', () {
    test('save, read back, and normalize the URL and library path', () async {
      await store.saveDestination(
        libraryPath: '$lib/',
        url: Uri.parse('http://nas:8080/webdav/Notes'),
        username: 'ale',
        intervalSeconds: 300,
        wifiOnly: true,
      );
      final row = (await store.destination(lib))!;
      expect(row.libraryPath, lib);
      expect(row.url, 'http://nas:8080/webdav/Notes/');
      expect(row.username, 'ale');
      expect(row.enabled, isTrue);
      expect(row.autoSync, isTrue);
      expect(row.intervalSeconds, 300);
      expect(row.wifiOnly, isTrue);
      expect(row.capabilities, '{}');
      expect(await store.capabilities(lib), isNull);
      expect(await store.destination(other), isNull);
    });

    test('capabilities and results round-trip; an error keeps the last '
        'success', () async {
      await store.saveDestination(
        libraryPath: lib,
        url: Uri.parse('http://a/'),
      );
      final caps = WebDavCapabilities(probedAt: clock, fileEtags: true);
      await store.setCapabilities(lib, caps);
      expect(await store.capabilities(lib), caps);

      await store.recordSyncResult(lib);
      expect(
        (await store.destination(lib))!.lastSyncAtMs,
        clock.millisecondsSinceEpoch,
      );
      await store.recordSyncResult(lib, error: 'offline');
      final row = (await store.destination(lib))!;
      expect(row.lastError, 'offline');
      expect(row.lastSyncAtMs, clock.millisecondsSinceEpoch);
      await store.recordSyncResult(lib);
      expect((await store.destination(lib))!.lastError, isNull);
    });

    test('changing only the options keeps the state', () async {
      await store.saveDestination(
        libraryPath: lib,
        url: Uri.parse('http://a/'),
      );
      await store.setCapabilities(lib, WebDavCapabilities(probedAt: clock));
      await store.recordSyncResult(lib);
      await store.putItems([item('a.md')]);

      await store.saveDestination(
        libraryPath: lib,
        url: Uri.parse('http://a/'),
        enabled: false,
      );
      final row = (await store.destination(lib))!;
      expect(row.enabled, isFalse);
      expect(row.capabilities, isNot('{}'));
      expect(row.lastSyncAtMs, isNotNull);
      expect(await store.items(lib), hasLength(1));
    });

    test('pointing at another URL or user clears items and capabilities but '
        'keeps the queue', () async {
      await store.saveDestination(
        libraryPath: lib,
        url: Uri.parse('http://a/'),
      );
      await store.setCapabilities(lib, WebDavCapabilities(probedAt: clock));
      await store.recordSyncResult(lib);
      await store.putItems([item('a.md'), item('b.md', library: other)]);
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);

      await store.saveDestination(
        libraryPath: lib,
        url: Uri.parse('http://b/'),
      );
      var row = (await store.destination(lib))!;
      expect(row.capabilities, '{}');
      expect(row.lastSyncAtMs, isNull);
      expect(await store.items(lib), isEmpty);
      expect(await store.items(other), hasLength(1));
      expect(await queue(), {'a.md': 'changed'});

      await store.putItems([item('a.md')]);
      await store.saveDestination(
        libraryPath: lib,
        url: Uri.parse('http://b/'),
        username: 'someone',
      );
      row = (await store.destination(lib))!;
      expect(await store.items(lib), isEmpty);
      expect(row.username, 'someone');
    });

    test('removeLibrary drops destination, items and queue of that library '
        'only', () async {
      for (final library in [lib, other]) {
        await store.saveDestination(
          libraryPath: library,
          url: Uri.parse('http://a/'),
        );
        await store.putItems([item('a.md', library: library)]);
        await store.enqueue(library, 'a.md', SyncOpKind.changed);
      }
      await store.removeLibrary('$lib/');
      expect(await store.destination(lib), isNull);
      expect(await store.items(lib), isEmpty);
      expect(await store.pendingOps(lib), isEmpty);
      expect(await store.destination(other), isNotNull);
      expect(await store.items(other), hasLength(1));
      expect(await store.pendingOps(other), hasLength(1));
    });
  });

  group('items', () {
    test('put replaces by path; read one or all', () async {
      await store.putItems([item('a.md'), item('Sub/b.md')]);
      await store.putItems([item('a.md', sha: 'bb')]);
      final all = await store.items(lib);
      expect(all.keys, unorderedEquals(['a.md', 'Sub/b.md']));
      expect(all['a.md']!.localSha256, 'bb');
      expect((await store.item(lib, 'Sub/b.md'))!.baseVersion, 4);
      expect(await store.item(lib, 'nope.md'), isNull);
    });

    test('remove by path and under a folder, literally', () async {
      await store.putItems([
        item('a.md'),
        item('A_b/x.md'),
        item('AXb/y.md'),
        item('A_b.md'),
        item('Deep/A_b/z.md'),
      ]);
      await store.removeItems(lib, ['a.md', 'missing.md']);
      await store.removeItemsUnder(lib, 'A_b');
      expect(
        (await store.items(lib)).keys,
        unorderedEquals(['AXb/y.md', 'A_b.md', 'Deep/A_b/z.md']),
      );
    });

    test('move re-paths a file or a whole folder, replacing targets', () async {
      await store.putItems([
        item('Old/a.md'),
        item('Old/Sub/b.md'),
        item('Older/c.md'),
        item('New/a.md', sha: 'stale'),
        item('x.md'),
      ]);
      await store.moveItems(lib, 'Old', 'New');
      await store.moveItems(lib, 'x.md', 'y.md');
      final all = await store.items(lib);
      expect(
        all.keys,
        unorderedEquals(['New/a.md', 'New/Sub/b.md', 'Older/c.md', 'y.md']),
      );
      expect(all['New/a.md']!.localSha256, 'aa');
    });
  });

  group('queue', () {
    test('one hint per path, per library', () async {
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      await store.enqueue(other, 'a.md', SyncOpKind.deleted);
      expect(await queue(), {'a.md': 'changed'});
      expect(await queue(other), {'a.md': 'deleted'});
    });

    test('changed and deleted replace each other', () async {
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      await store.enqueue(lib, 'a.md', SyncOpKind.deleted);
      expect(await queue(), {'a.md': 'deleted'});
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      expect(await queue(), {'a.md': 'changed'});
    });

    test('a move takes over the source hint; an edit keeps the move', () async {
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      await store.enqueue(lib, 'b.md', SyncOpKind.moved, fromPath: 'a.md');
      expect(await queue(), {'b.md': 'moved<a.md'});
      await store.enqueue(lib, 'b.md', SyncOpKind.changed);
      expect(await queue(), {'b.md': 'moved<a.md'});
    });

    test('moves chain, and moving back is a change', () async {
      await store.enqueue(lib, 'b.md', SyncOpKind.moved, fromPath: 'a.md');
      await store.enqueue(lib, 'c.md', SyncOpKind.moved, fromPath: 'b.md');
      expect(await queue(), {'c.md': 'moved<a.md'});
      await store.enqueue(lib, 'a.md', SyncOpKind.moved, fromPath: 'c.md');
      expect(await queue(), {'a.md': 'changed'});
    });

    test('deleting a moved file also deletes it at the source', () async {
      await store.enqueue(lib, 'b.md', SyncOpKind.moved, fromPath: 'a.md');
      await store.enqueue(lib, 'b.md', SyncOpKind.deleted);
      expect(await queue(), {'b.md': 'deleted', 'a.md': 'deleted'});
    });

    test('hints under a moved folder move with it', () async {
      await store.enqueue(lib, 'Old/a.md', SyncOpKind.changed);
      await store.enqueue(lib, 'Old/Sub/b.md', SyncOpKind.deleted);
      await store.enqueue(lib, 'Older/c.md', SyncOpKind.changed);
      await store.enqueue(lib, 'New', SyncOpKind.moved, fromPath: 'Old');
      expect(await queue(), {
        'New/a.md': 'changed',
        'New/Sub/b.md': 'deleted',
        'Older/c.md': 'changed',
        'New': 'moved<Old',
      });
    });

    test('a move needs a different source', () async {
      await expectLater(
        store.enqueue(lib, 'a.md', SyncOpKind.moved),
        throwsArgumentError,
      );
      await expectLater(
        store.enqueue(lib, 'a.md', SyncOpKind.moved, fromPath: 'a.md'),
        throwsArgumentError,
      );
    });

    test('failures back off; due, next retry and retryNow follow', () async {
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      await store.enqueue(lib, 'b.md', SyncOpKind.changed);
      var op = (await store.dueOps(lib)).first;
      op = (await store.failOp(op, 'offline'))!;
      expect(op.attempts, 1);
      expect(op.lastError, 'offline');
      expect((await store.dueOps(lib)).map((o) => o.path), ['b.md']);
      expect(
        await store.nextRetryAt(lib),
        DateTime.fromMillisecondsSinceEpoch(
          clock.add(const Duration(seconds: 5)).millisecondsSinceEpoch,
        ),
      );
      op = (await store.failOp(op, 'offline'))!;
      expect(op.attempts, 2);
      clock = clock.add(const Duration(seconds: 9));
      expect((await store.dueOps(lib)).map((o) => o.path), ['b.md']);
      clock = clock.add(const Duration(seconds: 1));
      expect((await store.dueOps(lib)).map((o) => o.path), ['a.md', 'b.md']);

      op = (await store.failOp(op, 'offline'))!;
      await store.retryNow(lib);
      final due = await store.dueOps(lib);
      expect(due.map((o) => o.path), ['a.md', 'b.md']);
      expect(due.first.attempts, 3, reason: 'retryNow keeps the count');
      expect(await store.nextRetryAt(lib), isNull);
    });

    test('a rewrite keeps the backoff', () async {
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      final op = (await store.failOp(
        (await store.pendingOps(lib)).single,
        'offline',
      ))!;
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      final rewritten = (await store.pendingOps(lib)).single;
      expect(rewritten.attempts, 1);
      expect(rewritten.nextAttemptAtMs, op.nextAttemptAtMs);
    });

    test('completing or failing a hint rewritten meanwhile leaves the new '
        'hint alone, even within the same millisecond', () async {
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      final read = (await store.pendingOps(lib)).single;
      // A save lands while the sync of that hint is running.
      await store.enqueue(lib, 'a.md', SyncOpKind.changed);
      expect(await store.completeOp(read), isFalse);
      expect(await store.failOp(read, 'x'), isNull);
      final current = (await store.pendingOps(lib)).single;
      expect(current.attempts, 0);
      expect(current.createdAtMs, greaterThan(read.createdAtMs));
      expect(await store.completeOp(current), isTrue);
      expect(await store.pendingOps(lib), isEmpty);
    });

    test('an unknown kind reads as changed', () async {
      await db
          .into(db.syncOps)
          .insert(
            SyncOpsCompanion.insert(
              libraryPath: lib,
              path: 'a.md',
              kind: 'renamed-in-a-future-build',
              createdAtMs: 1,
              fromPath: const Value(null),
            ),
          );
      final op = (await store.pendingOps(lib)).single;
      expect(SyncOpKind.parse(op.kind), SyncOpKind.changed);
    });
  });
}
