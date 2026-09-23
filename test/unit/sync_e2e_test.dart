// End to end over the fake WebDAV server (issue #20), through the whole
// stack a device uses: NoteOps writes, hints reach the queue, the
// scheduler triggers, the engine syncs, and the service reports it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_sync_secret_store.dart';
import '../fakes/fake_webdav_server.dart';

/// One device: its library folder, its databases, and the sync service
/// the UI would drive — automatic triggers included.
final class _Device {
  new _(this.name, this.root, this.dbDir, this.index, this.app)
    : secrets = FakeSyncSecretStore();

  static Future<_Device> create(String name) async {
    final root = await Directory.current.createTemp('niman_e2e_$name');
    final dbDir = await Directory.current.createTemp('niman_e2e_db_$name');
    final index = IndexDatabase(
      NativeDatabase(File(p.join(dbDir.path, 'index.sqlite'))),
    );
    final app = AppDatabase(
      NativeDatabase(File(p.join(dbDir.path, 'app.sqlite'))),
    );
    return _Device._(name, root, dbDir, index, app);
  }

  final String name;
  final Directory root;
  final Directory dbDir;
  final IndexDatabase index;
  final AppDatabase app;
  final FakeSyncSecretStore secrets;

  String get path => p.normalize(root.path);

  NoteOps? _ops;
  LibrarySyncService? _service;

  NoteOps get ops => _ops!;
  LibrarySyncService get sync => _service!;

  /// Opens the library, as `LibraryController` does: ops, service, hints
  /// and (when [automatic]) the triggers.
  Future<void> open({bool automatic = false}) async {
    final ops = NoteOps(
      root: path,
      db: index,
      indexer: Indexer(index),
      config: LibraryConfigRepo(path),
    );
    final store = SyncStore(app);
    final service = LibrarySyncService(
      root: path,
      engine: SyncEngine(
        root: path,
        ops: ops,
        store: store,
        secrets: secrets,
        clientFactory: (destination, password) => WebDavClient(
          url: Uri.parse(destination.url),
          username: destination.username,
          password: password,
          timeout: const Duration(seconds: 5),
        ),
      ),
      store: store,
      secrets: secrets,
      quickDelay: const Duration(milliseconds: 100),
    );
    ops.syncHints = service.hint;
    _ops = ops;
    _service = service;
    if (automatic) {
      await service.start();
    } else {
      await service.load();
    }
  }

  /// Closes everything but the databases and the folder: a restart.
  Future<void> closeLibrary() async {
    await _service?.close();
    await _ops?.writer.indexed;
    _service = null;
    _ops = null;
  }

  Future<void> connect(Uri url) =>
      sync.save(url: '$url', username: '', password: '');

  Future<SyncReport> syncNow() async {
    final report = await sync.syncNow(
      confirm: (plan, {required firstSync}) async => true,
    );
    await ops.writer.indexed;
    return report;
  }

  String? read(String rel) {
    final file = File(p.join(path, rel));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  Future<void> dispose() async {
    await closeLibrary();
    await index.close();
    await app.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeWebDavServer server;
  late _Device a;
  late _Device b;

  setUp(() async {
    server = await FakeWebDavServer.start()
      ..putFile('.keep', const []);
    a = await _Device.create('a');
    b = await _Device.create('b');
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
    await server.close();
  });

  String remote(String path) {
    final bytes = server.file(path);
    return bytes == null ? '' : utf8.decode(bytes);
  }

  String note(List<String> lines) => '${lines.join('\n')}\n';

  /// Waits, in real time, until [condition] holds.
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

  test('two devices, a whole day of edits', () async {
    await a.open(automatic: true);
    await a.connect(server.url);
    final created = await a.ops.createNote(
      parentPath: '',
      name: 'Shopping',
      content: note(['# Shopping', 'bread']),
    );
    await a.syncNow();
    expect(remote('Shopping.md'), note(['# Shopping', 'bread']));

    // B joins: the first sync brings the note down.
    await b.open(automatic: true);
    await b.connect(server.url);
    await b.syncNow();
    expect(b.read('Shopping.md'), note(['# Shopping', 'bread']));

    // An edit on A goes out by itself, through the queue.
    await a.ops.saveNote(created.path, note(['# Shopping', 'bread', 'milk']));
    await eventually(
      () => remote('Shopping.md') == note(['# Shopping', 'bread', 'milk']),
      reason: 'the edit to reach the server on its own',
    );
    await eventually(
      () => a.sync.status.pendingHints == 0,
      reason: 'the queue to read as empty',
    );

    // A rename travels as a MOVE, and B follows it.
    await a.ops.rename(created.path, 'Groceries');
    await eventually(
      () => server.exists('Groceries.md') && !server.exists('Shopping.md'),
      reason: 'the rename to reach the server',
    );
    await b.syncNow();
    expect(b.read('Groceries.md'), note(['# Shopping', 'bread', 'milk']));
    expect(b.read('Shopping.md'), isNull);

    // A deletion here becomes a trashed file there.
    await a.ops.delete('Groceries.md');
    await eventually(
      () => !server.exists('Groceries.md'),
      reason: 'the deletion to reach the server',
    );
    final report = await b.syncNow();
    expect(report.done[SyncActionKind.trashLocal], 1, reason: report.summary());
    expect(b.read('Groceries.md'), isNull);
    expect(File(p.join(b.path, '.trash', 'Groceries.md')).existsSync(), isTrue);
  });

  test(
    'edits from both devices merge, overlaps are left to the user',
    () async {
      await a.open();
      await b.open();
      await a.connect(server.url);
      await b.connect(server.url);
      await a.ops.saveNote('note.md', note(['# Title', 'one', 'two', 'three']));
      await a.syncNow();
      await b.syncNow();

      // Different places: merged on both sides without a question.
      await a.ops.saveNote(
        'note.md',
        note(['# Title', 'one', 'two', 'three', 'four']),
      );
      await a.syncNow();
      await b.ops.saveNote('note.md', note(['# Notes', 'one', 'two', 'three']));
      final merged = await b.syncNow();
      expect(merged.merged, ['note.md'], reason: merged.summary());
      final both = note(['# Notes', 'one', 'two', 'three', 'four']);
      expect(b.read('note.md'), both);
      expect(remote('note.md'), both);
      await a.syncNow();
      expect(a.read('note.md'), both);

      // The same line on both: a conflict, and neither copy is touched.
      await a.ops.saveNote(
        'note.md',
        note(['# Notes', 'mine', 'two', 'three', 'four']),
      );
      await a.syncNow();
      await b.ops.saveNote(
        'note.md',
        note(['# Notes', 'theirs', 'two', 'three', 'four']),
      );
      final conflicted = await b.syncNow();
      expect(conflicted.conflicts.single.path, 'note.md');
      expect(b.sync.status.needsAttention, isTrue);
      expect(
        b.read('note.md'),
        note(['# Notes', 'theirs', 'two', 'three', 'four']),
      );

      // The user merges by hand: both sides end up with the chosen text.
      final texts = await b.sync.conflictTexts('note.md');
      expect(texts.base, both);
      final chosen = note([
        '# Notes',
        'mine',
        'theirs',
        'two',
        'three',
        'four',
      ]);
      await b.sync.resolveMerged('note.md', chosen, shown: texts);
      await b.ops.writer.indexed;
      expect(b.read('note.md'), chosen);
      expect(remote('note.md'), chosen);
      expect(b.sync.status.conflicts, isEmpty);
      await a.syncNow();
      expect(a.read('note.md'), chosen);
    },
  );

  test('a queue written offline survives a restart and goes out', () async {
    await a.open(automatic: true);
    await a.connect(server.url);
    await a.ops.saveNote('offline.md', 'first');
    await a.syncNow();

    // The server goes away; the edits pile up in the queue.
    server.failNext(503, count: 40);
    await a.ops.saveNote('offline.md', 'second');
    await a.ops.saveNote('other.md', 'new one');
    await eventually(
      () async => (await SyncStore(a.app).pendingOps(a.path)).length == 2,
      reason: 'both edits queued',
    );
    await eventually(
      () => a.sync.status.aborted == SyncAbort.offline,
      reason: 'the quick sync to fail',
    );
    expect(a.sync.status.pendingHints, 2);
    expect(remote('offline.md'), 'first');

    // The app closes and opens again: the queue is still there.
    await a.closeLibrary();
    await a.open(automatic: true);
    expect(a.sync.status.pendingHints, 2);

    // The server answers again and the user taps "Sync now".
    server.clearFailures();
    final report = await a.syncNow();
    expect(report.clean, isTrue, reason: report.summary());
    expect(remote('offline.md'), 'second');
    expect(remote('other.md'), 'new one');
    await eventually(() async {
      return (await SyncStore(a.app).pendingOps(a.path)).isEmpty;
    }, reason: 'the queue to drain');
  });

  test('a server without ETags or preconditions still round-trips', () async {
    server
      ..etags = false
      ..collectionEtags = false
      ..preconditions = false;
    await a.open();
    await b.open();
    await a.connect(server.url);
    await b.connect(server.url);
    expect(
      (await a.sync.testConnection(
        url: '${server.url}',
        username: '',
        password: '',
      )).capabilities!.fileEtags,
      isFalse,
    );

    await a.ops.saveNote('plain.md', 'one');
    await a.syncNow();
    await b.syncNow();
    expect(b.read('plain.md'), 'one');

    await b.ops.saveNote('plain.md', 'two, from the other device');
    await b.syncNow();
    final down = await a.syncNow();
    expect(down.done[SyncActionKind.download], 1, reason: down.summary());
    expect(a.read('plain.md'), 'two, from the other device');

    // Without ETags the row stays doubtful for a couple of seconds: the
    // next sync re-reads the file and records it, and transfers nothing.
    final after = await a.syncNow();
    expect(
      after.done.keys.where((k) => k != SyncActionKind.record),
      isEmpty,
      reason: after.summary(),
    );
    expect(a.read('plain.md'), 'two, from the other device');
    expect(remote('plain.md'), 'two, from the other device');
  });

  test('a write the server refuses is retried, not lost', () async {
    await a.open();
    await a.connect(server.url);
    await a.ops.saveNote('guarded.md', 'one');
    await a.syncNow();

    // 412: the file changed on the server since the plan was made.
    server.failPutsTo('guarded.md', 412);
    await a.ops.saveNote('guarded.md', 'two');
    final failed = await a.syncNow();
    expect(failed.failures.single.path, 'guarded.md');
    expect(remote('guarded.md'), 'one');
    expect(a.sync.status.needsAttention, isTrue);

    final retried = await a.syncNow();
    expect(retried.clean, isTrue, reason: retried.summary());
    expect(remote('guarded.md'), 'two');
    expect(a.sync.status.needsAttention, isFalse);
  });
}
