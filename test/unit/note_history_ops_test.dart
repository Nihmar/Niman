import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;

  setUp(() async {
    root = await Directory.current.createTemp('niman_hops_');
    dbDir = await Directory.current.createTemp('niman_hops_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: Indexer(db),
      config: LibraryConfigRepo(root.path),
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  Future<List<int>> numbers(String path) async => [
    for (final v in (await ops.noteHistory(path)).versions) v.number,
  ];

  test('an editing session keeps the text it started from, once', () async {
    await ops.saveNote('a.md', 'original');
    await ops.saveNote('a.md', 'edit 1', editSession: 1);
    await ops.saveNote('a.md', 'edit 2', editSession: 1);
    await ops.saveNote('a.md', 'edit 3', editSession: 1);

    final manifest = await ops.noteHistory('a.md');
    expect(manifest.versions, hasLength(1));
    expect(manifest.versions.single.reason, HistoryReason.session);
    expect(await ops.readNoteVersion('a.md', 1), 'original');

    // A new session keeps what the last one left.
    await ops.saveNote('a.md', 'edit 4', editSession: 2);
    expect(await numbers('a.md'), [1, 2]);
    expect(await ops.readNoteVersion('a.md', 2), 'edit 3');
  });

  test('restore brings a version back and keeps the replaced text', () async {
    await ops.saveNote('a.md', 'good');
    await ops.saveNote('a.md', 'bad', editSession: 1);
    await ops.restoreNoteVersion('a.md', 1);

    expect(File(p.join(root.path, 'a.md')).readAsStringSync(), 'good');
    final manifest = await ops.noteHistory('a.md');
    expect(manifest.newest!.reason, HistoryReason.restore);
    expect(await ops.readNoteVersion('a.md', manifest.newest!.number), 'bad');
  });

  test('rename and move carry the history along', () async {
    await ops.saveNote('a.md', 'one');
    await ops.saveNote('a.md', 'two', editSession: 1);
    await ops.writer.indexed;

    await ops.rename('a.md', 'b');
    expect(await numbers('a.md'), isEmpty);
    expect(await ops.readNoteVersion('b.md', 1), 'one');

    await ops.createFolder(parentPath: '', name: 'Dir');
    await ops.move('b.md', 'Dir');
    expect(await ops.readNoteVersion('Dir/b.md', 1), 'one');
  });

  test('the trash keeps history until it is emptied', () async {
    await ops.saveNote('a.md', 'one');
    await ops.saveNote('a.md', 'two', editSession: 1);
    await ops.writer.indexed;

    await ops.delete('a.md');
    expect(await numbers('a.md'), [1]);

    final item = (await ops.trashItems()).single;
    await ops.restoreTrash(item.name);
    expect(await numbers('a.md'), [1]);

    await ops.delete('a.md');
    await ops.emptyTrash();
    expect(await numbers('a.md'), isEmpty);
  });

  group('sync operations', () {
    String sha(String text) => sha256.convert(utf8.encode(text)).toString();

    test('pinSyncBase pins the version holding the content, keeping the '
        'note as a sync version when none does', () async {
      await ops.saveNote('a.md', 'one');
      final first = await ops.pinSyncBase('a.md', sha('one'));
      var manifest = await ops.noteHistory('a.md');
      expect(manifest.pins[syncBasePin], first);
      expect(manifest.version(first!)!.reason, HistoryReason.sync);

      // The same content again: the same version, nothing new written.
      expect(await ops.pinSyncBase('a.md', sha('one')), first);
      expect((await ops.noteHistory('a.md')).versions, hasLength(1));

      // Edited away and no version holds the content: the pin is released.
      await ops.saveNote('a.md', 'two');
      expect(await ops.pinSyncBase('a.md', sha('never')), isNull);
      manifest = await ops.noteHistory('a.md');
      expect(manifest.pins[syncBasePin], isNull);

      expect(await ops.pinSyncBase('pic.png', sha('x')), isNull);
    });

    test(
      'syncReplace keeps the replaced note text as a sync version',
      () async {
        await ops.saveNote('a.md', 'local');
        await ops.writer.indexed;
        final temp = File(p.join(root.path, '.a.md.niman-tmp-sync-1'))
          ..writeAsStringSync('remote');
        await ops.syncReplace('a.md', temp.path);
        expect(File(p.join(root.path, 'a.md')).readAsStringSync(), 'remote');
        expect(temp.existsSync(), isFalse);
        final version = (await ops.noteHistory('a.md')).versions.last;
        expect(version.reason, HistoryReason.sync);
        expect(await ops.readNoteVersion('a.md', version.number), 'local');
      },
    );

    test(
      'syncReplace of the settings file drops the cached settings',
      () async {
        await ops.setTrashEnabled(enabled: false);
        expect(await ops.trashEnabled, isFalse);
        final temp = File(p.join(root.path, '.niman', '.s.niman-tmp-sync-1'))
          ..writeAsStringSync('{"trashEnabled": true}');
        await ops.syncReplace('.niman/settings.json', temp.path);
        expect(await ops.trashEnabled, isTrue);
      },
    );

    test('syncTrash always uses the trash, whatever the toggle', () async {
      await ops.setTrashEnabled(enabled: false);
      await ops.saveNote('Notes/a.md', 'text');
      await ops.writer.indexed;
      await ops.syncTrash('Notes/a.md');
      expect(File(p.join(root.path, 'Notes', 'a.md')).existsSync(), isFalse);
      expect((await ops.trashItems()).map((t) => t.originalPath), [
        'Notes/a.md',
      ]);
      expect(await ops.find('Notes/a.md'), isNull);
      await ops.syncTrash('missing.md'); // nothing there: a no-op
    });

    test('syncMove renames across folders and the history follows', () async {
      await ops.saveNote('a.md', 'one');
      await ops.saveNote('a.md', 'two', editSession: 1);
      await ops.writer.indexed;
      await ops.syncMove('a.md', 'Deep/Down/b.md');
      expect(
        File(p.join(root.path, 'Deep', 'Down', 'b.md')).existsSync(),
        isTrue,
      );
      expect(await numbers('Deep/Down/b.md'), [1]);
      expect(await numbers('a.md'), isEmpty);
      expect(await ops.find('Deep/Down/b.md'), isNotNull);
      await expectLater(
        ops.syncMove('a.md', 'x.md'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
