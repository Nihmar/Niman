// #717: the notes a delete offers to take along — a file's companion notes
// and OCR sidecar, a folder's companions that live outside it.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/ui/carried_notes.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteOps ops;
  late CarriedNotes carried;

  setUp(() async {
    root = await Directory.current.createTemp('niman_carried_');
    dbDir = await Directory.current.createTemp('niman_carried_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    carried = CarriedNotes(
      ops: ops,
      fields: FieldRepo(db),
      links: LinkResolver(db),
      root: root.path,
      annotationsFolder: 'Annotations',
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  /// Writes without indexing, as a companion is written a moment before
  /// the index catches up.
  Future<void> writeRaw(String path, [String text = '']) async {
    final file = File(p.joinAll([root.path, ...path.split('/')]));
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  Future<void> write(String path, [String text = '']) async {
    await writeRaw(path, text);
    await indexer.fullScan(root.path);
  }

  test('a file carries its companion and its sidecar', () async {
    await write('Books/Dune.pdf');
    await write(
      'Annotations/Dune - Annotation.md',
      '---\nannotates: "[[Books/Dune.pdf]]"\n---\n\n## p. 3\n\nA note.\n',
    );
    await write(
      'Books/Dune.ocr.md',
      '---\nocr: "[[Dune.pdf]]"\n---\n\n## p. 1\n\nRecognized.\n',
    );

    expect(await carried.of('Books/Dune.pdf', isDir: false), [
      'Annotations/Dune - Annotation.md',
      'Books/Dune.ocr.md',
    ]);
  });

  test('a noted file with nothing written about it carries nothing', () async {
    await write('Books/Emma.epub');
    await write('Books/Other.md', 'No link at all.\n');

    expect(await carried.of('Books/Emma.epub', isDir: false), isEmpty);
  });

  test('a folder carries only the companions outside it', () async {
    await write('Books/Dune.pdf');
    // Inside: the sidecar and a companion both go with the folder itself.
    await write(
      'Books/Dune.ocr.md',
      '---\nocr: "[[Dune.pdf]]"\n---\n\nRecognized.\n',
    );
    await write(
      'Books/Dune notes.md',
      '---\nannotates: "[[Books/Dune.pdf]]"\n---\n\nA note.\n',
    );
    // Outside: it would stay behind pointing at a folder that is gone.
    await write(
      'Annotations/Dune - Annotation.md',
      '---\nannotates: "[[Books/Dune.pdf]]"\n---\n\nA note.\n',
    );

    expect(await carried.of('Books', isDir: true), [
      'Annotations/Dune - Annotation.md',
    ]);
  });

  test('a companion the index has not seen yet is still carried', () async {
    await write('Books/Dune.pdf');
    // Written and not scanned: the index does not know it yet (#717).
    await writeRaw(
      'Annotations/Dune - Annotation.md',
      '---\nannotates: "[[Books/Dune.pdf]]"\n---\n\nA note.\n',
    );

    expect(await carried.of('Books/Dune.pdf', isDir: false), [
      'Annotations/Dune - Annotation.md',
    ]);
  });

  // #775: what the annotations folder says on disk is merged by note, not
  // by file — a note read there must not hide the file's other companions.
  test('a fresh companion joins the indexed ones elsewhere', () async {
    await write('Books/Dune.epub');
    await write(
      'Notes/Dune.md',
      '---\nannotates: "[[Books/Dune.epub]]"\n---\n\nMine.\n',
    );
    await writeRaw(
      'Annotations/Dune - Annotation.md',
      '---\nannotates: "[[Books/Dune.epub]]"\n---\n\nA highlight.\n',
    );

    expect(await carried.of('Books/Dune.epub', isDir: false), [
      'Annotations/Dune - Annotation.md',
      'Notes/Dune.md',
    ]);
  });

  test('a companion that names another file now is not carried', () async {
    await write('Books/Dune.epub');
    await write('Books/Emma.epub');
    await write(
      'Annotations/Notes.md',
      '---\nannotates: "[[Books/Dune.epub]]"\n---\n',
    );
    // Rewritten since the index read it, and not read again yet.
    await writeRaw(
      'Annotations/Notes.md',
      '---\nannotates: "[[Books/Emma.epub]]"\n---\n',
    );
    File(p.join(root.path, 'Annotations', 'Notes.md'))
        .setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));

    expect(await carried.of('Books/Dune.epub', isDir: false), isEmpty);
    expect(await carried.of('Books/Emma.epub', isDir: false), [
      'Annotations/Notes.md',
    ]);
  });

  test('a companion naming a note elsewhere is not carried', () async {
    await write('Books/Dune.pdf');
    await write('Books/Emma.epub');
    await write(
      'Annotations/Emma.md',
      '---\nannotates: "[[Books/Emma.epub]]"\n---\n',
    );

    expect(await carried.of('Books/Dune.pdf', isDir: false), isEmpty);
  });
}
