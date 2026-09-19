import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_sync_secret_store.dart';
import '../fakes/fake_webdav_server.dart';

/// One device: its own library folder, index, app database and engine,
/// all pointed at the same server.
final class _Device {
  new _(this.root, this.dbDir, this.index, this.app, this.ops, this.store)
    : secrets = FakeSyncSecretStore();

  static Future<_Device> create(String name) async {
    final root = await Directory.current.createTemp('niman_sync_$name');
    final dbDir = await Directory.current.createTemp('niman_sync_db_$name');
    final index = IndexDatabase(
      NativeDatabase(File(p.join(dbDir.path, 'index.sqlite'))),
    );
    final app = AppDatabase(NativeDatabase.memory());
    final path = p.normalize(root.path);
    final ops = NoteOps(
      root: path,
      db: index,
      indexer: Indexer(index),
      config: LibraryConfigRepo(path),
    );
    return _Device._(root, dbDir, index, app, ops, SyncStore(app));
  }

  final Directory root;
  final Directory dbDir;
  final IndexDatabase index;
  final AppDatabase app;
  final NoteOps ops;
  final SyncStore store;
  final FakeSyncSecretStore secrets;

  String get path => p.normalize(root.path);

  late final engine = SyncEngine(
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
  );

  static var _tick = 0;

  Future<void> connect(
    Uri url, {
    String user = '',
    String password = '',
  }) async {
    await store.saveDestination(libraryPath: path, url: url, username: user);
    if (password.isNotEmpty) await secrets.write(path, password);
  }

  /// Writes [text] at [rel] with an mtime no earlier write can share.
  void write(String rel, String text) {
    File(p.join(path, rel))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text)
      ..setLastModifiedSync(DateTime.now().add(Duration(seconds: ++_tick)));
  }

  String? read(String rel) {
    final file = File(p.join(path, rel));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  void delete(String rel) => File(p.join(path, rel)).deleteSync();

  Future<SyncReport> sync({SyncConfirm? confirm}) async {
    final report = await engine.run(confirm: confirm);
    await ops.writer.indexed;
    return report;
  }

  Future<SyncReport> quick() async {
    final report = await engine.run(quick: true);
    await ops.writer.indexed;
    return report;
  }

  Future<void> hint(String rel, SyncOpKind kind, {String? from}) =>
      store.enqueue(path, rel, kind, fromPath: from);

  Future<List<String>> queue() async => [
    for (final op in await store.pendingOps(path))
      '${op.kind} ${op.path} x${op.attempts}',
  ];

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
  late _Device a;
  late _Device b;

  setUp(() async {
    server = await FakeWebDavServer.start()
      ..putFile('.keep', const []); // the folder exists remotely
    a = await _Device.create('a');
    b = await _Device.create('b');
    await a.connect(server.url);
    await b.connect(server.url);
  });

  tearDown(() async {
    await a.close();
    await b.close();
    await server.close();
  });

  String remoteText(String path) => utf8.decode(server.file(path)!);

  /// Requests after the capability probe, as `VERB path`.
  List<String> dataRequests() => [
    for (final r in server.requests)
      if (!r.path.contains('.niman-probe')) '${r.method} ${r.path}',
  ];

  test(
    'a first sync uploads and downloads, and a second has nothing to do',
    () async {
      a
        ..write('Notes/Plan.md', 'plan')
        ..write('assets/pic.png', 'png-bytes');
      server.putFile('Remote.md', utf8.encode('from the server'));

      final first = await a.sync();
      expect(first.clean, isTrue, reason: first.summary());
      expect(first.done[SyncActionKind.upload], 2);
      expect(first.done[SyncActionKind.download], 1);
      expect(remoteText('Notes/Plan.md'), 'plan');
      expect(remoteText('assets/pic.png'), 'png-bytes');
      expect(a.read('Remote.md'), 'from the server');
      expect(
        (await a.store.items(a.path)).keys,
        unorderedEquals(['Notes/Plan.md', 'assets/pic.png', 'Remote.md']),
      );
      expect(server.paths.where((x) => x.startsWith('.niman-probe')), isEmpty);
      expect((await a.store.capabilities(a.path))!.fileEtags, isTrue);

      final second = await a.sync();
      expect(second.summary(), 'nothing to do');
      expect((await a.store.destination(a.path))!.lastError, isNull);
    },
  );

  test(
    'an edit travels to the other device, keeping history and the base',
    () async {
      a.write('a.md', 'one');
      await a.sync();
      await b.sync();
      expect(b.read('a.md'), 'one');

      b.write('a.md', 'two');
      final up = await b.sync();
      expect(up.done[SyncActionKind.upload], 1);
      expect(
        server.requests.any(
          (r) => r.method == 'PUT' && r.headers['if-match'] != null,
        ),
        isTrue,
        reason: 'the edit is guarded with If-Match',
      );
      expect(remoteText('a.md'), 'two');

      final down = await a.sync();
      expect(down.done[SyncActionKind.download], 1, reason: down.summary());
      expect(a.read('a.md'), 'two');

      final manifest = await a.ops.noteHistory('a.md');
      final replaced = manifest.versions.where(
        (v) => v.reason == HistoryReason.sync,
      );
      expect(
        await a.ops.readNoteVersion('a.md', replaced.first.number),
        'one',
        reason: 'the text the download replaced is a version',
      );
      final base = manifest.pins[syncBasePin];
      expect(base, isNotNull);
      expect(await a.ops.readNoteVersion('a.md', base!), 'two');
      expect((await a.store.item(a.path, 'a.md'))!.baseVersion, base);
    },
  );

  test('a deletion travels, and lands in the other device trash', () async {
    a
      ..write('gone.md', 'bye')
      ..write('kept.md', 'hi');
    await a.sync();
    await b.sync();

    a.delete('gone.md');
    final report = await a.sync();
    expect(report.done[SyncActionKind.deleteRemote], 1);
    expect(server.exists('gone.md'), isFalse);

    final there = await b.sync();
    expect(there.done[SyncActionKind.trashLocal], 1, reason: there.summary());
    expect(b.read('gone.md'), isNull);
    expect(File(p.join(b.path, '.trash', 'gone.md')).existsSync(), isTrue);
    expect((await b.ops.trashItems()).map((t) => t.originalPath), ['gone.md']);
    expect(await b.store.item(b.path, 'gone.md'), isNull);
    expect(b.read('kept.md'), 'hi');
  });

  test('an edit wins over a deletion on the other device', () async {
    a.write('a.md', 'v1');
    await a.sync();
    await b.sync();

    a.delete('a.md');
    await a.sync();
    b.write('a.md', 'v2 edited');
    final report = await b.sync();
    expect(report.done[SyncActionKind.upload], 1, reason: report.summary());
    expect(remoteText('a.md'), 'v2 edited');

    await a.sync();
    expect(a.read('a.md'), 'v2 edited');
  });

  test(
    'both sides edited differently: a conflict, nothing overwritten',
    () async {
      a.write('a.md', 'base');
      await a.sync();
      await b.sync();

      a.write('a.md', 'mine');
      b.write('a.md', 'theirs');
      await b.sync();
      final report = await a.sync();
      expect(report.conflicts.single.path, 'a.md');
      expect(report.conflicts.single.baseVersion, isNotNull);
      expect(report.clean, isFalse);
      expect(a.read('a.md'), 'mine');
      expect(remoteText('a.md'), 'theirs');
      expect(
        await a.ops.readNoteVersion(
          'a.md',
          report.conflicts.single.baseVersion!,
        ),
        'base',
      );
    },
  );

  test(
    'both sides created the same content: recorded, no transfer back',
    () async {
      a.write('same.md', 'identical');
      b.write('same.md', 'identical');
      await a.sync();
      final report = await b.sync();
      expect(report.conflicts, isEmpty);
      expect(report.done[SyncActionKind.conflict], 1);
      expect(await b.store.item(b.path, 'same.md'), isNotNull);
    },
  );

  test('library settings: the newer side wins whole', () async {
    a.write('.niman/settings.json', '{"historyVersions": 3}');
    await a.sync();
    b.write('.niman/settings.json', '{"historyVersions": 7}');
    await b.sync();
    expect(remoteText('.niman/settings.json'), '{"historyVersions": 7}');
    // B's file was written later (the test mtimes only move forward).
    expect(b.read('.niman/settings.json'), '{"historyVersions": 7}');
  });

  test('a local rename is one MOVE, not a new upload', () async {
    a.write('Old name.md', 'content');
    await a.sync();
    final before = dataRequests().length;
    final file = File(p.join(a.path, 'Old name.md'));
    final mtime = file.lastModifiedSync();
    Directory(p.join(a.path, 'Moved')).createSync();
    file.renameSync(p.join(a.path, 'Moved', 'New name.md'));
    File(p.join(a.path, 'Moved', 'New name.md')).setLastModifiedSync(mtime);

    final report = await a.sync();
    expect(report.done[SyncActionKind.moveRemote], 1, reason: report.summary());
    final after = dataRequests().sublist(before);
    expect(after.where((r) => r.startsWith('MOVE ')), hasLength(1));
    expect(after.where((r) => r.startsWith('PUT ')), isEmpty);
    expect(remoteText('Moved/New name.md'), 'content');
    expect(server.exists('Old name.md'), isFalse);
    expect(await a.store.item(a.path, 'Moved/New name.md'), isNotNull);
    expect(await a.store.item(a.path, 'Old name.md'), isNull);
    expect((await a.sync()).summary(), 'nothing to do');
  });

  // #163: a server that answers a PROPFIND for a missing file with a 207
  // holding a 404 made every new file look taken on the server, and the
  // upload was skipped on every run, forever.
  test(
    'a new file uploads to a server that answers "missing" with a 207',
    () async {
      // Without preconditions the run looks before each PUT, as that
      // session's server made it.
      server
        ..missingAsMultistatus = true
        ..preconditions = false;
      a
        ..write('.niman/settings.json', '{"lineNumbers": true}')
        ..write('New.md', 'new');
      final report = await a.sync();
      expect(report.clean, isTrue, reason: report.summary());
      expect(report.skipped, isEmpty);
      expect(remoteText('.niman/settings.json'), '{"lineNumbers": true}');
      expect(remoteText('New.md'), 'new');
    },
  );

  group('a bare server (no ETags, no preconditions, no MOVE)', () {
    setUp(() {
      server
        ..etags = false
        ..collectionEtags = false
        ..preconditions = false
        ..supportMove = false;
    });

    test('edits and deletions still travel both ways', () async {
      a
        ..write('a.md', 'one')
        ..write('b.md', 'bee');
      expect((await a.sync()).clean, isTrue);
      expect((await b.sync()).clean, isTrue);
      expect(b.read('a.md'), 'one');

      b
        ..write('a.md', 'two, longer')
        ..delete('b.md');
      final report = await b.sync();
      expect(report.clean, isTrue, reason: report.summary());
      // Without If-Match every write is checked with a PROPFIND first.
      final puts = server.requests.where(
        (r) => r.method == 'PUT' && !r.path.contains('.niman-probe'),
      );
      expect(puts, isNotEmpty);
      expect(puts.every((r) => r.headers['if-match'] == null), isTrue);

      final back = await a.sync();
      expect(back.clean, isTrue, reason: back.summary());
      expect(a.read('a.md'), 'two, longer');
      expect(a.read('b.md'), isNull);
    });

    test('a same-second rewrite of equal size is caught by hashing', () async {
      a.write('a.md', 'aaa');
      await a.sync();
      final row = (await a.store.item(a.path, 'a.md'))!;
      expect(row.remoteUnverified, isTrue, reason: 'uploaded this second');

      // Another device rewrites it in the same second, same size.
      server.putFile('a.md', utf8.encode('bbb'));
      final report = await a.sync();
      expect(report.done[SyncActionKind.download], 1, reason: report.summary());
      expect(a.read('a.md'), 'bbb');
    });

    test('a rename becomes delete + upload', () async {
      a.write('x.md', 'x');
      await a.sync();
      File(p.join(a.path, 'x.md')).renameSync(p.join(a.path, 'y.md'));
      final report = await a.sync();
      expect(report.clean, isTrue, reason: report.summary());
      expect(server.exists('x.md'), isFalse);
      expect(remoteText('y.md'), 'x');
    });
  });

  group('safety', () {
    test(
      'an emptied remote does not empty the library without a yes',
      () async {
        for (var i = 0; i < 12; i++) {
          a.write('n$i.md', 'note $i');
        }
        await a.sync();
        for (var i = 0; i < 12; i++) {
          server.remove('n$i.md');
        }

        final refused = await a.sync();
        expect(refused.aborted, SyncAbort.notConfirmed);
        expect(a.read('n0.md'), 'note 0');

        var asked = false;
        final confirmed = await a.sync(
          confirm: (plan, {required firstSync}) async {
            asked = true;
            expect(firstSync, isFalse);
            expect(plan.looksLikeMassDeletion, isTrue);
            return true;
          },
        );
        expect(asked, isTrue);
        expect(confirmed.done[SyncActionKind.trashLocal], 12);
        expect(a.read('n0.md'), isNull);
      },
    );

    test('a first sync asks, and a refusal touches nothing', () async {
      a.write('a.md', 'local');
      final report = await a.sync(
        confirm: (plan, {required firstSync}) async {
          expect(firstSync, isTrue);
          expect(plan.count(SyncActionKind.upload), 1);
          return false;
        },
      );
      expect(report.aborted, SyncAbort.notConfirmed);
      expect(server.exists('a.md'), isFalse);
    });

    test(
      'a missing remote folder aborts instead of reading as empty',
      () async {
        a.write('a.md', 'x');
        await a.sync();
        await a.store.saveDestination(
          libraryPath: a.path,
          url: server.url.resolve('missing/'),
        );
        final report = await a.sync();
        expect(report.aborted, isNotNull);
        expect(a.read('a.md'), 'x');
      },
    );

    test('no destination, no password, wrong password, no server', () async {
      final lone = await _Device.create('lone');
      addTearDown(lone.close);
      expect((await lone.sync()).aborted, SyncAbort.notConfigured);

      await lone.connect(server.url, user: 'ale');
      expect((await lone.sync()).aborted, SyncAbort.missingPassword);

      server.credentials = (user: 'ale', password: 'right');
      await lone.secrets.write(lone.path, 'wrong');
      final denied = await lone.sync();
      expect(denied.aborted, SyncAbort.authentication);
      expect(
        (await lone.store.destination(lone.path))!.lastError,
        contains('authentication'),
      );

      await lone.secrets.write(lone.path, 'right');
      expect((await lone.sync()).aborted, isNull);

      await server.close();
      final offline = await lone.sync();
      expect(offline.aborted, SyncAbort.offline);
      server = await FakeWebDavServer.start(); // for tearDown
    });

    test('a failing file is reported and the others still sync', () async {
      a.write('a.md', 'a');
      await a.sync();
      a
        ..write('a.md', 'a2')
        ..write('b.md', 'b');
      // The first PUT of the run answers 507; the rest go through.
      server.failPutsTo('a.md', 507);
      final report = await a.sync();
      expect(report.failures.single.path, 'a.md');
      expect(remoteText('b.md'), 'b');
      expect(report.aborted, isNull);
      expect((await a.store.destination(a.path))!.lastError, contains('a.md'));

      final retry = await a.sync();
      expect(retry.clean, isTrue, reason: retry.summary());
      expect(remoteText('a.md'), 'a2');
    });
  });

  group('one conflict at a time', () {
    Future<void> makeConflict() async {
      a.write('a.md', 'base');
      await a.sync();
      await b.sync();
      a.write('a.md', 'mine');
      b.write('a.md', 'theirs');
      await b.sync();
      final report = await a.sync();
      expect(report.conflicts.single.path, 'a.md');
    }

    test('both texts can be read', () async {
      await makeConflict();
      final texts = await a.engine.conflictTexts('a.md');
      expect(texts.local, 'mine');
      expect(texts.remote, 'theirs');
    });

    test('keeping this device uploads it and the next sync is quiet', () async {
      await makeConflict();
      await a.engine.resolveConflict('a.md', keepLocal: true);
      expect(remoteText('a.md'), 'mine');
      expect((await a.sync()).summary(), 'nothing to do');
      await b.sync();
      expect(b.read('a.md'), 'mine');
    });

    test(
      'keeping the server replaces the file and keeps ours in history',
      () async {
        await makeConflict();
        await a.engine.resolveConflict('a.md', keepLocal: false);
        expect(a.read('a.md'), 'theirs');
        final versions = (await a.ops.noteHistory('a.md')).versions;
        final kept = versions.lastWhere((v) => v.reason == HistoryReason.sync);
        final texts = <String>[
          for (final v in versions)
            await a.ops.readNoteVersion('a.md', v.number),
        ];
        expect(texts, contains('mine'));
        expect(kept, isNotNull);
        expect((await a.sync()).summary(), 'nothing to do');
      },
    );

    test('a resolution without a destination fails as SyncFailure', () async {
      final lone = await _Device.create('lone2');
      addTearDown(lone.close);
      await expectLater(
        lone.engine.resolveConflict('a.md', keepLocal: true),
        throwsA(
          isA<SyncFailure>().having(
            (f) => f.reason,
            'reason',
            SyncAbort.notConfigured,
          ),
        ),
      );
    });
  });

  test(
    'progress reports the stages and counts; changed paths are listed',
    () async {
      server
        ..putFile('r1.md', utf8.encode('one'))
        ..putFile('r2.md', utf8.encode('two'));
      a.write('l.md', 'local');
      final stages = <SyncStage>[];
      final counts = <(int, int)>[];
      final report = await a.engine.run(
        onProgress: (stage, done, total) {
          if (stages.isEmpty || stages.last != stage) stages.add(stage);
          if (stage == SyncStage.applying) counts.add((done, total));
        },
      );
      expect(stages, [
        SyncStage.connecting,
        SyncStage.scanning,
        SyncStage.comparing,
        SyncStage.applying,
      ]);
      expect(counts, [(0, 3), (1, 3), (2, 3)]);
      expect(report.changedLocally, {'r1.md', 'r2.md'});
    },
  );

  group('merge', () {
    String note(List<String> lines) => '${lines.join('\n')}\n';

    /// Both devices start from the same four-line note.
    Future<void> shared() async {
      a.write('note.md', note(['# Title', 'one', 'two', 'three']));
      final first = await a.sync();
      expect(first.clean, isTrue, reason: first.summary());
      final second = await b.sync();
      expect(second.clean, isTrue, reason: second.summary());
    }

    test('edits in different places merge without asking', () async {
      await shared();
      a.write('note.md', note(['# Title', 'one', 'two', 'three', 'four']));
      b.write('note.md', note(['# Notes', 'one', 'two', 'three']));
      await b.sync();

      final report = await a.sync();
      expect(report.merged, ['note.md'], reason: report.summary());
      expect(report.conflicts, isEmpty);
      expect(report.changedLocally, contains('note.md'));
      final merged = note(['# Notes', 'one', 'two', 'three', 'four']);
      expect(a.read('note.md'), merged);
      expect(remoteText('note.md'), merged);

      // The text the merge replaced is in the history, and the base moved
      // on: the next sync has nothing to do.
      final manifest = await a.ops.noteHistory('note.md');
      final texts = [
        for (final v in manifest.versions)
          await a.ops.readNoteVersion('note.md', v.number),
      ];
      expect(
        texts,
        contains(note(['# Title', 'one', 'two', 'three', 'four'])),
        reason: 'the text the merge replaced here',
      );
      final base = manifest.pins[syncBasePin];
      expect(await a.ops.readNoteVersion('note.md', base!), merged);
      expect((await a.sync()).summary(), 'nothing to do');
      expect((await b.sync()).done[SyncActionKind.download], 1);
      expect(b.read('note.md'), merged);
    });

    test('a remote-only change still merges, without touching the row '
        'twice', () async {
      await shared();
      b.write('note.md', note(['# Title', 'one', 'TWO', 'three']));
      await b.sync();
      a.write('note.md', note(['# Title', 'one', 'two', 'three', 'four']));

      final report = await a.sync();
      expect(report.merged, ['note.md'], reason: report.summary());
      expect(
        a.read('note.md'),
        note(['# Title', 'one', 'TWO', 'three', 'four']),
      );
      expect((await a.store.item(a.path, 'note.md'))!.baseVersion, isNotNull);
    });

    test(
      'overlapping edits stay a conflict, with the base to merge on',
      () async {
        await shared();
        a.write('note.md', note(['# Title', 'one', 'mine', 'three']));
        b.write('note.md', note(['# Title', 'one', 'theirs', 'three']));
        await b.sync();

        final report = await a.sync();
        expect(report.merged, isEmpty);
        expect(report.conflicts.single.path, 'note.md');
        expect(a.read('note.md'), note(['# Title', 'one', 'mine', 'three']));

        final texts = await a.engine.conflictTexts('note.md');
        expect(texts.base, note(['# Title', 'one', 'two', 'three']));
        expect(texts.local, note(['# Title', 'one', 'mine', 'three']));
        expect(texts.remote, note(['# Title', 'one', 'theirs', 'three']));

        final chosen = note(['# Title', 'one', 'mine', 'theirs', 'three']);
        await a.engine.resolveMerged('note.md', chosen);
        await a.ops.writer.indexed;
        expect(a.read('note.md'), chosen);
        expect(remoteText('note.md'), chosen);
        expect((await a.sync()).summary(), 'nothing to do');
        expect(
          (await a.store.destination(a.path))!.lastError,
          isNull,
          reason: 'the conflict is over',
        );
      },
    );

    test('without a base both sides are left alone', () async {
      // A file that never had a sync base: both devices created it.
      a.write('fresh.txt', note(['mine']));
      b.write('fresh.txt', note(['theirs']));
      await b.sync();
      final report = await a.sync();
      expect(report.merged, isEmpty);
      expect(report.conflicts.single.path, 'fresh.txt');
      expect(report.conflicts.single.baseVersion, isNull);
      expect(a.read('fresh.txt'), note(['mine']));
      expect(remoteText('fresh.txt'), note(['theirs']));
    });
  });

  group('quick sync and the queue', () {
    /// PROPFINDs that list a folder's children.
    List<String> listings() => [
      for (final r in server.requests)
        if (r.method == 'PROPFIND' && r.headers['depth'] == '1') r.path,
    ];

    setUp(() async {
      a
        ..write('a.md', 'one')
        ..write('Dir/x.md', 'x')
        ..write('Dir/y.md', 'y');
      final first = await a.sync();
      expect(first.clean, isTrue, reason: first.summary());
      server.requests.clear();
    });

    test('uploads only the queued paths, without listing folders', () async {
      a
        ..write('a.md', 'two')
        ..write('Dir/x.md', 'not queued');
      await a.hint('a.md', SyncOpKind.changed);

      final report = await a.quick();
      expect(report.quick, isTrue);
      expect(report.done[SyncActionKind.upload], 1, reason: report.summary());
      expect(remoteText('a.md'), 'two');
      expect(remoteText('Dir/x.md'), 'x', reason: 'not queued, not looked at');
      expect(listings(), isEmpty);
      expect(report.hintsDone, 1);
      expect(await a.queue(), isEmpty);

      // The full sync still finds what no hint pointed at.
      final full = await a.sync();
      expect(full.done[SyncActionKind.upload], 1, reason: full.summary());
      expect(remoteText('Dir/x.md'), 'not queued');
    });

    test('with nothing due it does not even connect', () async {
      final report = await a.quick();
      expect(report.summary(), 'nothing to do');
      expect(server.requests, isEmpty);
    });

    test('is never a first sync, and leaves the hints alone', () async {
      b.write('b.md', 'new device');
      await b.hint('b.md', SyncOpKind.changed);
      final report = await b.quick();
      expect(report.aborted, SyncAbort.notConfirmed);
      expect(server.exists('b.md'), isFalse);
      expect(await b.queue(), ['changed b.md x0']);
    });

    test('a queued rename becomes a MOVE', () async {
      await a.ops.writer.indexed;
      File(p.join(a.path, 'a.md')).renameSync(p.join(a.path, 'b.md'));
      await a.hint('b.md', SyncOpKind.moved, from: 'a.md');

      final report = await a.quick();
      expect(
        report.done[SyncActionKind.moveRemote],
        1,
        reason: report.summary(),
      );
      expect(server.exists('a.md'), isFalse);
      expect(remoteText('b.md'), 'one');
      expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
      expect((await a.store.items(a.path)).keys, contains('b.md'));
    });

    test('a queued folder deletion deletes every file under it', () async {
      Directory(p.join(a.path, 'Dir')).deleteSync(recursive: true);
      await a.hint('Dir', SyncOpKind.deleted);

      final report = await a.quick();
      expect(
        report.done[SyncActionKind.deleteRemote],
        2,
        reason: report.summary(),
      );
      expect(server.exists('Dir/x.md'), isFalse);
      expect(server.exists('Dir/y.md'), isFalse);
      expect(remoteText('a.md'), 'one');
    });

    test(
      'a file missing remotely is left for the full sync to trash',
      () async {
        server.remove('a.md');
        await a.hint('a.md', SyncOpKind.changed);

        final report = await a.quick();
        expect(report.deferred.single.kind, SyncActionKind.trashLocal);
        expect(a.read('a.md'), 'one');
        expect(await a.queue(), isEmpty);

        final full = await a.sync();
        expect(full.done[SyncActionKind.trashLocal], 1);
        expect(a.read('a.md'), isNull);
      },
    );

    test('a server that goes away keeps the queue, which resumes', () async {
      a.write('a.md', 'written offline');
      await a.hint('a.md', SyncOpKind.changed);
      server.failNext(503, retryAfter: '30');

      final down = await a.quick();
      expect(down.aborted, SyncAbort.offline);
      expect(down.retryAfter, const Duration(seconds: 30));
      expect(down.hintsFailed, 1);
      expect(await a.queue(), ['changed a.md x1']);
      expect(
        (await a.store.pendingOps(a.path)).single.lastError,
        contains('offline'),
      );
      expect(await a.store.dueOps(a.path), isEmpty, reason: 'backing off');
      expect(remoteText('a.md'), 'one');

      await a.store.retryNow(a.path);
      final up = await a.quick();
      expect(up.clean, isTrue, reason: up.summary());
      expect(remoteText('a.md'), 'written offline');
      expect(await a.queue(), isEmpty);
    });

    test('a path that fails backs off alone', () async {
      a
        ..write('a.md', 'two')
        ..write('Dir/x.md', 'x2');
      await a.hint('a.md', SyncOpKind.changed);
      await a.hint('Dir/x.md', SyncOpKind.changed);
      server.failPutsTo('Dir/x.md', 507);

      final report = await a.quick();
      expect(report.failures.single.path, 'Dir/x.md');
      expect(await a.queue(), ['changed Dir/x.md x1']);
      expect(remoteText('a.md'), 'two');
    });

    test('an automatic full sync leaves a backing-off hint and its path '
        'alone; once it is due, it goes (#163)', () async {
      a.write('a.md', 'two');
      await a.hint('a.md', SyncOpKind.changed);
      final op = (await a.store.pendingOps(a.path)).single;
      await a.store.failOp(op, 'offline');
      await a.hint('Dir/gone.md', SyncOpKind.deleted);

      final report = await a.sync();
      expect(report.clean, isTrue, reason: report.summary());
      expect(report.waiting.map((d) => d.path), ['a.md']);
      expect(report.hintsDone, 1);
      expect(remoteText('a.md'), 'one');
      expect(await a.queue(), ['changed a.md x1']);

      // What a sync the user asks for does first.
      await a.store.retryNow(a.path);
      final again = await a.sync();
      expect(again.clean, isTrue, reason: again.summary());
      expect(remoteText('a.md'), 'two');
      expect(await a.queue(), isEmpty);
    });

    test(
      'a path skipped run after run is reported as failing (#163)',
      () async {
        await a.hint('a.md', SyncOpKind.changed);
        SyncReport? last;
        for (var run = 1; run <= SyncEngine.stuckAfter; run++) {
          a.write('a.md', 'v$run');
          await a.store.retryNow(a.path);
          var rewritten = false;
          last = await a.engine.run(
            onProgress: (stage, _, _) {
              // The file changes under the run, every time.
              if (stage == SyncStage.applying && !rewritten) {
                rewritten = true;
                a.write('a.md', 'v$run and more');
              }
            },
          );
          await a.ops.writer.indexed;
          expect(last.skipped, ['a.md']);
          expect(
            last.failures.isEmpty,
            run < SyncEngine.stuckAfter,
            reason: 'run $run',
          );
        }
        expect(last!.clean, isFalse);
        expect(last.failures.single.path, 'a.md');
        expect(last.failures.single.error, contains('3 runs in a row'));
      },
    );

    test('a hint rewritten during the run survives it', () async {
      a.write('a.md', 'two');
      await a.hint('a.md', SyncOpKind.changed);
      Future<void>? rewrite;
      await a.engine.run(
        quick: true,
        onProgress: (stage, _, _) {
          // Lands once the run has read the older hint.
          if (stage == SyncStage.scanning) {
            rewrite ??= a.hint('a.md', SyncOpKind.changed);
          }
        },
      );
      await rewrite;
      await a.ops.writer.indexed;
      expect(await a.queue(), ['changed a.md x0']);
    });
  });
}
