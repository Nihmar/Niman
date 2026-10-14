// A deck note renamed or moved, or the folder holding it renamed, keeps its
// review states (#533): `.niman/review.json` follows the note.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;
  late ReviewStore store;

  setUp(() async {
    root = await Directory.current.createTemp('niman_review_ops_');
    dbDir = await Directory.current.createTemp('niman_review_ops_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    final indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    store = ReviewStore(root.path);
    File(p.join(root.path, 'Studio', 'Verbs.md'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('| Q | A |\n|---|---|\n| begin | began |\n');
    Directory(p.join(root.path, 'Shelf')).createSync();
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  final state = ReviewState(
    ef: 2.5,
    interval: 6,
    reps: 2,
    due: DateTime(2026, 10, 20),
    at: DateTime.utc(2026, 10, 14, 9),
  );

  test('a deck renamed keeps its reviews', () async {
    await store.write('Studio/Verbs.md', 'begin', state);
    await ops.rename('Studio/Verbs.md', 'Irregular');
    expect(await store.read('Studio/Irregular.md'), {'begin': state});
    expect(await store.read('Studio/Verbs.md'), isEmpty);
  });

  test('a deck moved keeps its reviews', () async {
    await store.write('Studio/Verbs.md', 'begin', state);
    await ops.move('Studio/Verbs.md', 'Shelf');
    expect(await store.read('Shelf/Verbs.md'), {'begin': state});
    expect(await store.read('Studio/Verbs.md'), isEmpty);
  });

  test('a folder renamed takes its decks along', () async {
    await store.write('Studio/Verbs.md', 'begin', state);
    await ops.rename('Studio', 'Lessons');
    expect(await store.read('Lessons/Verbs.md'), {'begin': state});
  });
}
