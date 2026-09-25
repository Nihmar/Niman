// A book or a PDF moved, or the folder holding it renamed, keeps where it
// was left (#281): the reading positions follow the file.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;
  late ReadingPositions positions;

  setUp(() async {
    root = await Directory.current.createTemp('niman_reading_ops_');
    dbDir = await Directory.current.createTemp('niman_reading_ops_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    final indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    positions = ReadingPositions(root.path);
    File(p.join(root.path, 'Books', 'Dune.epub'))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([0]);
    Directory(p.join(root.path, 'Shelf')).createSync();
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  const place = PdfLocation(page: 12);

  test('a book moved keeps its place', () async {
    await positions.write('Books/Dune.epub', place);
    await ops.move('Books/Dune.epub', 'Shelf');
    expect(await positions.read('Shelf/Dune.epub'), place);
    expect(await positions.read('Books/Dune.epub'), isNull);
  });

  test('a folder renamed takes its books along', () async {
    await positions.write('Books/Dune.epub', place);
    await ops.rename('Books', 'Novels');
    expect(await positions.read('Novels/Dune.epub'), place);
  });
}
