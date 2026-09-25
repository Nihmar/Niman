// The notes annotating a file (#284): found by the file their frontmatter
// names, wherever they are; made in the annotations folder when the file
// has none; appended to after.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/companion_notes.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;
  late CompanionNotes companions;

  setUp(() async {
    root = await Directory.current.createTemp('niman_companions_');
    dbDir = await Directory.current.createTemp('niman_companions_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    final indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    companions = CompanionNotes(
      fields: FieldRepo(db),
      links: LinkResolver(db),
      ops: ops,
    );
    for (final book in ['Books/Dune.pdf', 'Books/Emma.epub']) {
      File(p.join(root.path, book))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([0]);
    }
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  Annotation on(String path, int page, [String comment = '']) => Annotation(
    path: path,
    place: PdfLocation(page: page),
    label: 'p. $page',
    comment: comment,
  );

  Future<WrittenAnnotation> write(Annotation annotation) => companions.write(
    annotation,
    folder: 'Annotations',
    suffix: 'Annotation',
    linkType: LinkType.wikilink,
  );

  String read(String path) => File(p.join(root.path, path)).readAsStringSync();

  test('a file with none gets one, in the annotations folder', () async {
    expect(await companions.of('Books/Dune.pdf'), isEmpty);
    final written = await write(on('Books/Dune.pdf', 3, 'First.'));
    expect(written.path, 'Annotations/Dune - Annotation.md');
    final text = read(written.path);
    expect(
      text,
      '---\n'
      'annotates: "[[Books/Dune.pdf]]"\n'
      '---\n'
      '\n'
      '## p. 3\n'
      '\n'
      '[[Books/Dune.pdf#page=3|p. 3]]\n'
      '\n'
      'First.\n',
    );
    expect(text.substring(written.offset), startsWith('## p. 3'));
    expect(await companions.of('Books/Dune.pdf'), [written.path]);
  });

  test('a second annotation joins the first, at the end', () async {
    final first = await write(on('Books/Dune.pdf', 3));
    final second = await write(on('Books/Dune.pdf', 9, 'Later.'));
    expect(second.path, first.path);
    final text = read(second.path);
    expect(text.indexOf('## p. 3'), lessThan(text.indexOf('## p. 9')));
    expect(
      text.substring(second.offset),
      '## p. 9\n\n'
      '[[Books/Dune.pdf#page=9|p. 9]]\n\nLater.\n',
    );
  });

  test('a companion written by hand is found wherever it is', () async {
    await ops.createNote(
      parentPath: '',
      name: 'My reading',
      content: '---\nannotates: "[[Dune.pdf]]"\n---\nMy own notes.\n',
    );
    expect(await companions.of('Books/Dune.pdf'), ['My reading.md']);
    final written = await write(on('Books/Dune.pdf', 5));
    expect(written.path, 'My reading.md');
    expect(read('My reading.md'), startsWith('---\nannotates'));
    expect(read('My reading.md'), contains('My own notes.\n\n## p. 5'));
  });

  test("another file's companion is not this file's", () async {
    await write(on('Books/Emma.epub', 1));
    expect(await companions.of('Books/Dune.pdf'), isEmpty);
    final written = await write(on('Books/Dune.pdf', 2));
    expect(written.path, 'Annotations/Dune - Annotation.md');
  });

  test('the file may be named by a Markdown link or a bare path', () async {
    await ops.createNote(
      parentPath: '',
      name: 'a',
      content: '---\nannotates: "[Dune](Books/Dune.pdf)"\n---\n',
    );
    await ops.createNote(
      parentPath: '',
      name: 'b',
      content: '---\nannotates: Books/Dune.pdf\n---\n',
    );
    expect(await companions.of('Books/Dune.pdf'), ['a.md', 'b.md']);
  });

  group('where a file was annotated (#285)', () {
    test("its companions' links to it, not to other files", () async {
      await write(on('Books/Dune.pdf', 3));
      await write(on('Books/Dune.pdf', 9));
      await ops.createNote(
        parentPath: '',
        name: 'By hand',
        content:
            '---\nannotates: "[[Dune.pdf]]"\n---\n'
            'See [p. 5](Books/Dune.pdf#page=5) and [[Emma.epub#page=2]].\n',
      );
      // A note that is no companion marks nothing.
      await ops.createNote(
        parentPath: '',
        name: 'Elsewhere',
        content: '[[Books/Dune.pdf#page=7]]\n',
      );
      final marks = await companions.marksOf('Books/Dune.pdf');
      expect(
        [for (final m in marks) (m.note, (m.place as PdfLocation).page)],
        [
          ('Annotations/Dune - Annotation.md', 3),
          ('Annotations/Dune - Annotation.md', 9),
          ('By hand.md', 5),
        ],
      );
      final text = read('Annotations/Dune - Annotation.md');
      expect(text.substring(marks[1].offset), startsWith('## p. 9'));
      expect(marks[1].title, 'p. 9');
    });

    test('a file with no companion has no marks', () async {
      expect(await companions.marksOf('Books/Dune.pdf'), isEmpty);
    });
  });
}
