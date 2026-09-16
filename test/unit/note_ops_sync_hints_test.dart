import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;
  late List<String> hints;

  setUp(() async {
    root = await Directory.current.createTemp('niman_hints_');
    dbDir = await Directory.current.createTemp('niman_hints_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: Indexer(db),
      config: LibraryConfigRepo(root.path),
    );
    hints = [];
    ops.syncHints = (path, kind, {fromPath}) => hints.add(
      '${kind.name} $path${fromPath == null ? '' : ' <- $fromPath'}',
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  test('user operations report what they changed', () async {
    final note = await ops.createNote(parentPath: '', name: 'a');
    await ops.saveNote(note.path, 'text');
    await ops.appendToNote(note.path, 'more');
    await ops.setPinned(note.path, pinned: true);
    await ops.createFolder(parentPath: '', name: 'Dir');
    await ops.rename(note.path, 'b');
    await ops.move('b.md', 'Dir');
    await ops.rename('Dir', 'Folder');
    await ops.delete('Folder/b.md');
    final item = (await ops.trashItems()).single;
    await ops.restoreTrash(item.name);

    expect(hints, [
      'changed a.md',
      'changed a.md',
      'changed a.md',
      'changed a.md',
      'moved b.md <- a.md',
      'moved Dir/b.md <- b.md',
      'moved Folder <- Dir',
      'deleted Folder/b.md',
      'changed Folder/b.md',
    ]);
  });

  test('a restored version and a settings change are reported', () async {
    await ops.saveNote('a.md', 'one');
    await ops.saveNote('a.md', 'two', editSession: 1);
    hints.clear();

    await ops.restoreNoteVersion('a.md', 1);
    await ops.setTrashEnabled(enabled: false);
    // An equal value writes nothing, so it reports nothing.
    await ops.setTrashEnabled(enabled: false);

    expect(hints, ['changed a.md', 'changed .niman/settings.json']);
  });

  test('the sync operations report nothing and mark their writes', () async {
    await ops.saveNote('a.md', 'one');
    await ops.writer.indexed;
    hints.clear();
    expect(ops.changedBySync('a.md'), isFalse);

    final temp = File(p.join(root.path, '.a.md.niman-tmp-sync-1'))
      ..writeAsStringSync('from the server');
    await ops.syncReplace('a.md', temp.path);
    await ops.writer.indexed;
    await ops.syncMove('a.md', 'b.md');
    await ops.syncTrash('b.md');

    expect(hints, isEmpty);
    expect(ops.changedBySync('a.md'), isTrue);
    expect(ops.changedBySync('b.md'), isTrue);
    expect(ops.changedBySync('c.md'), isFalse);
  });

  test('without a sink nothing is reported and nothing fails', () async {
    ops.syncHints = null;
    await ops.saveNote('a.md', 'text');
    await ops.writer.indexed;
    await ops.delete('a.md');
    expect(hints, isEmpty);
    expect(SyncOpKind.parse('deleted'), SyncOpKind.deleted);
  });
}
