import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

void main() {
  final probedAt = DateTime.utc(2026, 9, 15);
  final full = WebDavCapabilities(
    probedAt: probedAt,
    fileEtags: true,
    ifMatch: true,
    ifNoneMatch: true,
    move: true,
    fileIds: true,
  );
  final t0 = DateTime.utc(2026, 9, 15, 10);
  final t1 = DateTime.utc(2026, 9, 15, 11);

  SyncItem row({
    String path = 'a.md',
    String sha = 'aaaa1111',
    int size = 10,
    int localMtime = 1000,
    String? etag = '"e1"',
    int remoteSize = 10,
    DateTime? remoteMtime,
    bool unverified = false,
    String? fileId,
    int? base = 7,
  }) => SyncItem(
    libraryPath: '/lib',
    path: path,
    localSha256: sha,
    localSize: size,
    localMtimeMs: localMtime,
    remoteEtag: etag,
    remoteSize: remoteSize,
    remoteMtimeMs: (remoteMtime ?? t0).millisecondsSinceEpoch,
    remoteUnverified: unverified,
    remoteFileId: fileId,
    baseVersion: base,
    syncedAtMs: 5000,
  );

  LocalFileState disk({int size = 10, int mtime = 1000, String? sha}) =>
      LocalFileState(size: size, mtimeMs: mtime, sha256: sha);

  WebDavResource dav({
    String path = 'a.md',
    String? etag = '"e1"',
    int? size = 10,
    DateTime? modified,
    String? fileId,
    bool noModified = false,
  }) => WebDavResource(
    path: path,
    isCollection: false,
    etag: etag,
    size: size,
    modified: noModified ? null : (modified ?? t0),
    fileId: fileId,
  );

  SyncDecision decide({
    LocalFileState? local,
    WebDavResource? remote,
    SyncItem? agreed,
    WebDavCapabilities? caps,
    String? remoteSha,
  }) => reconcilePath(
    path: 'a.md',
    local: local,
    remote: remote,
    row: agreed,
    capabilities: caps,
    remoteSha256: remoteSha,
  );

  group('syncable paths', () {
    test('dot entries, system junk and malformed paths are left out', () {
      for (final path in [
        '.trash/a.md',
        '.history/a.md.v1',
        'Notes/.a.md.niman-tmp-123',
        '.git/config',
        '.niman/other.json',
        'Folder/Thumbs.db',
        'desktop.ini',
        '',
        'a//b.md',
      ]) {
        expect(isSyncablePath(path), isFalse, reason: path);
      }
    });

    test('notes, attachments and the two library files are synced', () {
      for (final path in [
        'a.md',
        'Projects/Plan è.md',
        'assets/ab12.png',
        'todo.txt',
        '.niman/settings.json',
        '.niman/counters.json',
      ]) {
        expect(isSyncablePath(path), isTrue, reason: path);
      }
    });
  });

  group('local side', () {
    test('same size and mtime is unchanged without a hash', () {
      expect(classifyLocal(disk(), row()).change, SideChange.unchanged);
    });

    test('a different size or mtime needs a hash, then the hash decides', () {
      expect(
        classifyLocal(disk(mtime: 2000), row()).change,
        SideChange.needsHash,
      );
      expect(classifyLocal(disk(size: 11), row()).change, SideChange.needsHash);
      expect(
        classifyLocal(disk(mtime: 2000, sha: 'aaaa1111'), row()).change,
        SideChange.unchanged,
      );
      expect(
        classifyLocal(disk(mtime: 2000, sha: 'bbbb2222'), row()).change,
        SideChange.changed,
      );
    });

    test('no row: a new file needs its hash; no file is absent; a row '
        'without a file is deleted', () {
      expect(classifyLocal(disk(), null).change, SideChange.needsHash);
      expect(classifyLocal(disk(sha: 'x'), null).change, SideChange.created);
      expect(classifyLocal(null, null).change, SideChange.absent);
      expect(classifyLocal(null, row()).change, SideChange.deleted);
    });
  });

  group('remote side', () {
    test('with ETags on both sides the ETag decides, whatever the mtime', () {
      expect(
        classifyRemote(dav(modified: t1), row(), full).change,
        SideChange.unchanged,
      );
      expect(
        classifyRemote(dav(etag: '"e2"'), row(), full).change,
        SideChange.changed,
      );
    });

    test('without ETags size and mtime decide', () {
      expect(
        classifyRemote(dav(etag: null), row(), null).change,
        SideChange.unchanged,
      );
      expect(
        classifyRemote(dav(etag: null, modified: t1), row(), null).change,
        SideChange.changed,
      );
      expect(
        classifyRemote(dav(etag: null, size: 11), row(), null).change,
        SideChange.changed,
      );
    });

    test('ETags ignored when the server was not probed for them', () {
      // A server whose ETags did not change with content (probe: off) is
      // judged by size and mtime even though it sends them.
      expect(
        classifyRemote(dav(etag: '"other"'), row(), null).change,
        SideChange.unchanged,
      );
    });

    test('an unverified row, or no mtime at all, needs the content hash', () {
      final doubtful = row(etag: null, unverified: true);
      expect(
        classifyRemote(dav(etag: null), doubtful, null).change,
        SideChange.needsHash,
      );
      expect(
        classifyRemote(
          dav(etag: null),
          doubtful,
          null,
          remoteSha256: 'aaaa1111',
        ).change,
        SideChange.unchanged,
      );
      expect(
        classifyRemote(
          dav(etag: null),
          doubtful,
          null,
          remoteSha256: 'cccc',
        ).change,
        SideChange.changed,
      );
      expect(
        classifyRemote(
          dav(etag: null, noModified: true),
          row(etag: null),
          null,
        ).change,
        SideChange.needsHash,
      );
    });

    test('no row: created or absent; a row without a file is deleted', () {
      expect(classifyRemote(dav(), null, full).change, SideChange.created);
      expect(classifyRemote(null, null, full).change, SideChange.absent);
      expect(classifyRemote(null, row(), full).change, SideChange.deleted);
    });
  });

  group('the decision table', () {
    // Local changed = a different mtime with a different hash; remote
    // changed = a different ETag.
    final changedLocal = disk(mtime: 2000, sha: 'bbbb2222');
    final changedRemote = dav(etag: '"e2"');

    test('unchanged | unchanged → nothing', () {
      final d = decide(local: disk(), remote: dav(), agreed: row(), caps: full);
      expect(d.kind, SyncActionKind.nothing);
    });

    test('changed | unchanged → upload with If-Match', () {
      final d = decide(
        local: changedLocal,
        remote: dav(),
        agreed: row(),
        caps: full,
      );
      expect(d.kind, SyncActionKind.upload);
      expect(d.ifMatch, '"e1"');
      expect(d.checkRemoteFirst, isFalse);
      expect(d.why, contains('sha aaaa1111→bbbb2222'));
    });

    test('unchanged | changed → download', () {
      final d = decide(
        local: disk(),
        remote: changedRemote,
        agreed: row(),
        caps: full,
      );
      expect(d.kind, SyncActionKind.download);
    });

    test('changed | changed → conflict on the pinned base', () {
      final d = decide(
        local: changedLocal,
        remote: changedRemote,
        agreed: row(),
        caps: full,
      );
      expect(d.kind, SyncActionKind.conflict);
      expect(d.baseVersion, 7);
    });

    test('deleted | unchanged → delete remote', () {
      final d = decide(remote: dav(), agreed: row(), caps: full);
      expect(d.kind, SyncActionKind.deleteRemote);
      expect(d.ifMatch, '"e1"');
      expect(d.isDestructive, isTrue);
    });

    test('unchanged | deleted → move the local file to the trash', () {
      final d = decide(local: disk(), agreed: row(), caps: full);
      expect(d.kind, SyncActionKind.trashLocal);
      expect(d.isDestructive, isTrue);
    });

    test('deleted | changed → download again: the edit wins', () {
      final d = decide(remote: changedRemote, agreed: row(), caps: full);
      expect(d.kind, SyncActionKind.download);
    });

    test('changed | deleted → upload again: the edit wins', () {
      final d = decide(local: changedLocal, agreed: row(), caps: full);
      expect(d.kind, SyncActionKind.upload);
      expect(d.ifNoneMatch, isTrue);
    });

    test('deleted | deleted → drop the row', () {
      expect(decide(agreed: row(), caps: full).kind, SyncActionKind.dropRow);
    });

    test('new | absent → upload with If-None-Match', () {
      final d = decide(
        local: disk(sha: 'x'),
        caps: full,
      );
      expect(d.kind, SyncActionKind.upload);
      expect(d.ifNoneMatch, isTrue);
      expect(d.ifMatch, isNull);
    });

    test('absent | new → download', () {
      expect(decide(remote: dav(), caps: full).kind, SyncActionKind.download);
    });

    test('new | new → conflict without a base (equal content is recorded '
        'by the engine)', () {
      final d = decide(
        local: disk(sha: 'x'),
        remote: dav(),
        caps: full,
      );
      expect(d.kind, SyncActionKind.conflict);
      expect(d.baseVersion, isNull);
    });

    test('a touched file with the same content records, transfers nothing', () {
      final d = decide(
        local: disk(mtime: 2000, sha: 'aaaa1111'),
        remote: dav(),
        agreed: row(),
        caps: full,
      );
      expect(d.kind, SyncActionKind.record);
    });

    test('a hash that clears a doubt records', () {
      final d = decide(
        local: disk(),
        remote: dav(etag: null),
        agreed: row(etag: null, unverified: true),
        remoteSha: 'aaaa1111',
      );
      expect(d.kind, SyncActionKind.record);
    });

    test('hashes come first: local, then remote', () {
      expect(
        decide(local: disk(mtime: 2000), remote: dav(), agreed: row()).kind,
        SyncActionKind.hashLocal,
      );
      expect(
        decide(
          agreed: row(etag: null, unverified: true),
          remote: dav(etag: null),
        ).kind,
        SyncActionKind.hashRemote,
      );
    });

    test('without preconditions every write checks the remote first', () {
      final upload = decide(local: changedLocal, remote: dav(), agreed: row());
      expect(upload.ifMatch, isNull);
      expect(upload.checkRemoteFirst, isTrue);
      final create = decide(local: disk(sha: 'x'));
      expect(create.ifNoneMatch, isFalse);
      expect(create.checkRemoteFirst, isTrue);
      final delete = decide(remote: dav(), agreed: row());
      expect(delete.checkRemoteFirst, isTrue);
    });
  });

  group('plan', () {
    test('a first sync (no rows) never deletes and lists no nothing', () {
      final plan = planSync(
        local: {
          'a.md': disk(sha: 'a'),
          'same.md': disk(sha: 's'),
        },
        remote: {
          'b.md': dav(path: 'b.md'),
          'same.md': dav(path: 'same.md'),
        },
        rows: const {},
        capabilities: full,
      );
      expect(plan.destructiveCount, 0);
      expect(
        {for (final d in plan.decisions) d.path: d.kind},
        {
          'a.md': SyncActionKind.upload,
          'b.md': SyncActionKind.download,
          'same.md': SyncActionKind.conflict,
        },
      );
    });

    test('excluded paths are ignored on both sides', () {
      final plan = planSync(
        local: {'.trash/a.md': disk(sha: 'a')},
        remote: {'.history/x.v1': dav(path: '.history/x.v1')},
        rows: {'.git/HEAD': row(path: '.git/HEAD')},
      );
      expect(plan.decisions, isEmpty);
      expect(plan.summary(), 'nothing to do');
      expect(plan.rowCount, 0);
    });

    test('hashes supplied for a second pass settle the plan', () {
      final local = {'a.md': disk(mtime: 2000), 'n.md': disk()};
      final remote = {'a.md': dav()};
      final rows = {'a.md': row()};
      final first = planSync(
        local: local,
        remote: remote,
        rows: rows,
        capabilities: full,
      );
      expect(first.needsHashes, isTrue);
      expect(first.count(SyncActionKind.hashLocal), 2);
      final second = planSync(
        local: local,
        remote: remote,
        rows: rows,
        capabilities: full,
        localSha256: {'a.md': 'aaaa1111', 'n.md': 'new'},
      );
      expect(second.needsHashes, isFalse);
      expect(second.summary(), 'record 1, upload 1');
    });

    test('a local rename becomes one remote MOVE when the server has it', () {
      final local = {'New name.md': disk(sha: 'aaaa1111')};
      final remote = {'a.md': dav()};
      final rows = {'a.md': row()};
      final plan = planSync(
        local: local,
        remote: remote,
        rows: rows,
        capabilities: full,
      );
      final move = plan.decisions.single;
      expect(move.kind, SyncActionKind.moveRemote);
      expect(move.path, 'New name.md');
      expect(move.fromPath, 'a.md');
      expect(move.ifMatch, '"e1"');

      final noMove = planSync(
        local: local,
        remote: remote,
        rows: rows,
        capabilities: WebDavCapabilities(probedAt: probedAt, fileEtags: true),
      );
      expect(noMove.summary(), 'upload 1, deleteRemote 1');
    });

    test('ambiguous content is not paired', () {
      final plan = planSync(
        local: {
          'x.md': disk(sha: 'aaaa1111'),
          'y.md': disk(sha: 'aaaa1111'),
        },
        remote: {'a.md': dav()},
        rows: {'a.md': row()},
        capabilities: full,
      );
      expect(plan.count(SyncActionKind.moveRemote), 0);
      expect(plan.summary(), 'upload 2, deleteRemote 1');
    });

    test('a remote rename found by file id becomes a local move', () {
      final plan = planSync(
        local: {'a.md': disk()},
        remote: {'Renamed.md': dav(path: 'Renamed.md', fileId: '42')},
        rows: {'a.md': row(fileId: '42')},
        capabilities: full,
      );
      final move = plan.decisions.single;
      expect(move.kind, SyncActionKind.moveLocal);
      expect(move.path, 'Renamed.md');
      expect(move.fromPath, 'a.md');
    });

    test('an emptied remote looks like a mass deletion', () {
      final rows = {for (var i = 0; i < 12; i++) 'n$i.md': row(path: 'n$i.md')};
      final local = {for (final path in rows.keys) path: disk()};
      final plan = planSync(
        local: local,
        remote: const {},
        rows: rows,
        capabilities: full,
      );
      expect(plan.count(SyncActionKind.trashLocal), 12);
      expect(plan.looksLikeMassDeletion, isTrue);

      // A handful of deletions, or few relative to the library, is normal.
      final few = planSync(
        local: local,
        remote: {for (final path in rows.keys.skip(3)) path: dav(path: path)},
        rows: rows,
        capabilities: full,
      );
      expect(few.destructiveCount, 3);
      expect(few.looksLikeMassDeletion, isFalse);
      expect(few.decisions, hasLength(3));
    });
  });
}
