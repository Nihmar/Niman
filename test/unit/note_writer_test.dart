import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteWriter writer;

  setUp(() async {
    root = await Directory.current.createTemp('niman_writer_');
    dbDir = await Directory.current.createTemp('niman_writer_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    indexer = Indexer(db);
    writer = NoteWriter(root: root.path, indexer: indexer);
  });

  tearDown(() async {
    await writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  String read(String rel) => File(p.join(root.path, rel)).readAsStringSync();

  test('writes the text and creates missing folders', () async {
    await writer.save('Inbox/Deep/Note.md', 'hello');
    expect(read('Inbox/Deep/Note.md'), 'hello');
  });

  test('overwrites an existing note', () async {
    File(p.join(root.path, 'a.md')).writeAsStringSync('old');
    await writer.save('a.md', 'new', editSession: 3);
    expect(read('a.md'), 'new');
  });

  test('saves of one note land in the order they were made', () async {
    final saves = [
      for (var i = 0; i < 20; i++) writer.save('a.md', 'version $i'),
    ];
    await Future.wait(saves);
    expect(read('a.md'), 'version 19');
  });

  test('the index follows the save', () async {
    await writer.save('Indexed.md', '# Title\n\nbody words');
    await writer.indexed;
    final row = await indexer.dao.find('Indexed.md');
    expect(row, isNotNull);
    expect(row!.size, '# Title\n\nbody words'.length);
  });

  test('an equal-size edit in the same second still re-indexes', () async {
    await writer.save('Same.md', 'aaaa');
    await writer.indexed;
    final before = (await indexer.dao.find('Same.md'))!.sha256;
    await writer.save('Same.md', 'bbbb');
    await writer.indexed;
    final after = (await indexer.dao.find('Same.md'))!.sha256;
    expect(after, isNot(before));
  });

  test(
    'a failed save reaches the caller and does not block the next',
    () async {
      // A file where the note's folder should be: the write cannot land.
      File(p.join(root.path, 'Blocked')).writeAsStringSync('not a folder');
      await expectLater(writer.save('Blocked/Note.md', 'x'), throwsA(anything));
      await writer.save('Free.md', 'fine');
      expect(read('Free.md'), 'fine');
    },
  );

  test('NoteOps.saveNote writes through the writer', () async {
    final ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    await ops.saveNote('Via ops.md', 'from ops', editSession: 1);
    await ops.writer.indexed;
    expect(read('Via ops.md'), 'from ops');
    expect(await ops.find('Via ops.md'), isNotNull);
  });
}
