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
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/transfers/direct_write.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_sync_secret_store.dart';
import '../fakes/fake_webdav_server.dart';

/// A library synced against [FakeWebDavServer], with the engine's limit for
/// a new file held in memory set by the test.
final class _Device {
  new _(this.root, this.dbDir, this.index, this.app, this.ops, this.limit)
    : store = SyncStore(app);

  static Future<_Device> create({int limit = kSyncDirectWriteMaxBytes}) async {
    final root = await Directory.current.createTemp('niman_direct');
    final dbDir = await Directory.current.createTemp('niman_direct_db');
    final index = IndexDatabase(
      NativeDatabase(File(p.join(dbDir.path, 'index.sqlite'))),
    );
    final path = p.normalize(root.path);
    final ops = NoteOps(
      root: path,
      db: index,
      indexer: Indexer(index),
      config: LibraryConfigRepo(path),
    );
    return _Device._(
      root,
      dbDir,
      index,
      AppDatabase(NativeDatabase.memory()),
      ops,
      limit,
    );
  }

  final Directory root;
  final Directory dbDir;
  final IndexDatabase index;
  final AppDatabase app;
  final NoteOps ops;
  final SyncStore store;
  final int limit;

  String get path => p.normalize(root.path);

  late final engine = SyncEngine(
    root: path,
    ops: ops,
    store: store,
    secrets: FakeSyncSecretStore(),
    directWriteLimit: limit,
    clientFactory: (destination, password) => WebDavClient(
      url: Uri.parse(destination.url),
      username: destination.username,
      password: password,
      timeout: const Duration(seconds: 5),
    ),
  );

  Future<void> connect(Uri url) =>
      store.saveDestination(libraryPath: path, url: url);

  void write(String rel, String text) => File(p.join(path, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  String? read(String rel) {
    final file = File(p.join(path, rel));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  /// The files of the library, `/`-separated, without the history a new
  /// note gets and the trash — a temp left next to a file is listed.
  List<String> files() =>
      [
            for (final e in root.listSync(recursive: true))
              if (e is File)
                p.relative(e.path, from: path).replaceAll(r'\', '/'),
          ]
          .where((f) => !f.startsWith('.history/') && !f.startsWith('.trash/'))
          .toList()
        ..sort();

  Future<SyncReport> sync() async {
    final report = (await engine.run()).report;
    await ops.writer.indexed;
    return report;
  }

  Future<List<String>> marks() => store.pendingDownloads.pending(path);

  Future<bool> indexed(String rel) async =>
      (await index.select(index.notes).get()).any((n) => n.path == rel);

  Future<void> close() async {
    await ops.writer.indexed;
    await index.close();
    await app.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeWebDavServer server;
  final devices = <_Device>[];

  Future<_Device> device({int limit = kSyncDirectWriteMaxBytes}) async {
    final d = await _Device.create(limit: limit);
    devices.add(d);
    await d.connect(server.url);
    return d;
  }

  setUp(() async {
    server = await FakeWebDavServer.start()
      ..putFile('.keep', const []);
  });

  tearDown(() async {
    for (final d in devices) {
      await d.close();
    }
    devices.clear();
    await server.close();
  });

  List<String> requests(String method, String rel) => [
    for (final r in server.requests)
      if (r.method == method && r.path.endsWith('/$rel')) r.path,
  ];

  // Under the limit the body is held in memory, over it streamed: both
  // land the file under its name, recorded and indexed, with no mark left.
  for (final (how, limit) in [('in memory', 1 << 20), ('streamed', 4)]) {
    group('a new file, $how', () {
      test('is written under its name, recorded and indexed', () async {
        server.putFile('dir/new.md', utf8.encode('# New\nbody\n'));
        final a = await device(limit: limit);

        final report = await a.sync();

        expect(report.clean, isTrue, reason: report.summary());
        expect(report.done[SyncActionKind.download], 1);
        expect(a.read('dir/new.md'), '# New\nbody\n');
        expect(a.files(), ['dir/new.md'], reason: 'no temp left');
        expect(await a.marks(), isEmpty);
        expect((await a.store.items(a.path)).keys, contains('dir/new.md'));
        expect(await a.indexed('dir/new.md'), isTrue);

        // Agreed: the next run has nothing to move.
        final again = await a.sync();
        expect(again.done, isEmpty, reason: again.summary());
      });

      test('cut short leaves nothing, and the next run fetches it', () async {
        server.putFile('new.md', utf8.encode('x' * 64));
        final a = await device(limit: limit);

        server.dropNextGet();
        final report = await a.sync();

        expect(report.clean, isFalse, reason: report.summary());
        expect(a.read('new.md'), isNull, reason: 'no partial file');
        expect(await a.marks(), isEmpty);

        final again = await a.sync();
        expect(again.clean, isTrue, reason: again.summary());
        expect(a.read('new.md'), 'x' * 64);
        expect(await a.marks(), isEmpty);
      });
    });
  }

  test('a file that turns up during the download is left as it is', () async {
    server.putFile('new.md', utf8.encode('theirs'));
    final a = await device();
    server.beforeAnswer = (request) {
      if (request.method == 'GET' && request.path.endsWith('/new.md')) {
        a.write('new.md', 'mine');
      }
    };

    final report = await a.sync();

    expect(report.skipped, ['new.md'], reason: report.summary());
    expect(a.read('new.md'), 'mine');
    expect(await a.marks(), isEmpty);
    expect(utf8.decode(server.file('new.md')!), 'theirs');
  });

  test('a file that exists is still replaced through a temp', () async {
    server.putFile('note.md', utf8.encode('one'));
    final a = await device();
    await a.sync();
    server.putFile('note.md', utf8.encode('two, longer'));

    final report = await a.sync();

    expect(report.done[SyncActionKind.download], 1, reason: report.summary());
    expect(a.read('note.md'), 'two, longer');
    expect(await a.marks(), isEmpty, reason: 'only new files are marked');
  });

  group('a download an earlier run left unfinished', () {
    test('with no file: the mark goes and the file comes', () async {
      server.putFile('new.md', utf8.encode('whole'));
      final a = await device();
      await a.store.pendingDownloads.mark(a.path, 'new.md');

      final report = await a.sync();

      expect(report.clean, isTrue, reason: report.summary());
      expect(a.read('new.md'), 'whole');
      expect(await a.marks(), isEmpty);
    });

    test('partial: trashed, fetched again, never uploaded', () async {
      server.putFile('new.md', utf8.encode('the whole body'));
      final a = await device();
      await a.store.pendingDownloads.mark(a.path, 'new.md');
      a.write('new.md', 'the who');

      final report = await a.sync();

      expect(report.clean, isTrue, reason: report.summary());
      expect(a.read('new.md'), 'the whole body');
      expect(utf8.decode(server.file('new.md')!), 'the whole body');
      expect(requests('PUT', 'new.md'), isEmpty);
      expect((await a.ops.trashItems()).map((t) => t.originalPath), ['new.md']);
      expect(await a.marks(), isEmpty);
    });

    test('the right size with other bytes counts as partial', () async {
      server.putFile('new.md', utf8.encode('abcdef'));
      final a = await device();
      await a.store.pendingDownloads.mark(a.path, 'new.md');
      a.write('new.md', 'abc\x00\x00\x00');

      final report = await a.sync();

      expect(report.clean, isTrue, reason: report.summary());
      expect(a.read('new.md'), 'abcdef');
      expect(requests('PUT', 'new.md'), isEmpty);
      expect(await a.ops.trashItems(), hasLength(1));
    });

    test('whole: kept and recorded, nothing moves', () async {
      server.putFile('new.md', utf8.encode('whole'));
      final a = await device();
      await a.store.pendingDownloads.mark(a.path, 'new.md');
      a.write('new.md', 'whole');

      final report = await a.sync();

      expect(report.clean, isTrue, reason: report.summary());
      expect(a.read('new.md'), 'whole');
      expect(requests('PUT', 'new.md'), isEmpty);
      expect(await a.ops.trashItems(), isEmpty);
      expect(await a.marks(), isEmpty);
      expect((await a.store.items(a.path)).keys, contains('new.md'));
    });

    test('gone from the server: the partial file is trashed', () async {
      final a = await device();
      await a.store.pendingDownloads.mark(a.path, 'new.md');
      a.write('new.md', 'part');

      final report = await a.sync();

      expect(report.clean, isTrue, reason: report.summary());
      expect(a.read('new.md'), isNull);
      expect(server.exists('new.md'), isFalse, reason: 'not uploaded');
      expect(await a.ops.trashItems(), hasLength(1));
      expect(await a.marks(), isEmpty);
    });
  });
}
