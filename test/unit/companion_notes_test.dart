// The notes annotating a file (#284): found by the file their frontmatter
// names, wherever they are; made in the annotations folder when the file
// has none; appended to after.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/annotations/companion_notes.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
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

    test(
      "a CRLF companion's mark opens where the editor shows it (#374)",
      () async {
        final file = File(p.join(root.path, 'My reading.md'))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '---\r\n'
            'annotates: "[[Dune.pdf]]"\r\n'
            '---\r\n'
            '\r\n'
            '## Dune, p. 3\r\n'
            '\r\n'
            '[[Books/Dune.pdf#page=3|Dune, p. 3]]\r\n',
          );
        await Indexer(db).fullScan(root.path);
        final mark = (await companions.marksOf('Books/Dune.pdf')).single;
        // The text the editor opens the note with, which is what a caret
        // stands at.
        final shown = normalizedLineEndings(file.readAsStringSync());
        expect(shown.substring(mark.offset), startsWith('## Dune, p. 3'));
        expect(mark.title, 'Dune, p. 3');
      },
    );

    test(
      'an annotation written into a CRLF companion opens at itself (#374)',
      () async {
        await ops.createNote(
          parentPath: '',
          name: 'My reading',
          content: '---\nannotates: "[[Dune.pdf]]"\n---\nMy own notes.\n',
        );
        final file = File(p.join(root.path, 'My reading.md'));
        file.writeAsStringSync(
          file.readAsStringSync().replaceAll('\n', '\r\n'),
        );
        await Indexer(db).fullScan(root.path);
        final written = await write(on('Books/Dune.pdf', 9));
        final shown = normalizedLineEndings(read(written.path));
        expect(shown.substring(written.offset), startsWith('## p. 9'));
      },
    );
  });

  group('highlights (#626)', () {
    Annotation highlight(int page, HighlightColour colour) => Annotation(
      path: 'Books/Dune.pdf',
      place: PdfLocation(page: page, chars: (start: 0, end: 9)),
      label: 'p. $page',
      quote: 'Passage $page.',
      highlight: colour,
    );

    test('are written into the companion, and read back as marks', () async {
      await write(on('Books/Dune.pdf', 3, 'A comment.'));
      await write(highlight(4, HighlightColour.green));
      await write(highlight(5, HighlightColour.pink));
      final marks = await companions.marksOf('Books/Dune.pdf');
      expect(
        [for (final m in marks) m.highlight],
        [null, HighlightColour.green, HighlightColour.pink],
      );
      expect(marks[1].quote, 'Passage 4.');
      expect(marks[1].title, isNull);
    });

    test('one is removed with its quote, the rest kept', () async {
      await write(on('Books/Dune.pdf', 3, 'A comment.'));
      await write(highlight(4, HighlightColour.green));
      await write(highlight(5, HighlightColour.pink));
      final path = (await companions.of('Books/Dune.pdf')).single;
      final before = read(path);
      final green = (await companions.marksOf('Books/Dune.pdf'))[1];
      await companions.removeHighlight(green);
      final after = read(path);
      expect(after, isNot(contains('Passage 4.')));
      expect(after, contains('A comment.\n\n> Passage 5.'));
      expect(after.length, lessThan(before.length));
      // The last one too, and the note ends as a note does.
      final pink = (await companions.marksOf('Books/Dune.pdf')).last;
      await companions.removeHighlight(pink);
      expect(read(path), endsWith('A comment.\n'));
      expect(
        [for (final m in await companions.marksOf('Books/Dune.pdf')) m.title],
        ['p. 3'],
      );
    });

    test('its colour changes in its link', () async {
      await write(highlight(4, HighlightColour.green));
      final mark = (await companions.marksOf('Books/Dune.pdf')).single;
      await companions.recolour(mark, HighlightColour.blue);
      final again = (await companions.marksOf('Books/Dune.pdf')).single;
      expect(again.highlight, HighlightColour.blue);
      expect(again.quote, 'Passage 4.');
    });

    test('annotated, it becomes an annotation where it is', () async {
      await write(highlight(4, HighlightColour.green));
      await write(highlight(5, HighlightColour.pink));
      final green = (await companions.marksOf('Books/Dune.pdf')).first;
      expect(green.label, 'p. 4');
      await companions.annotateHighlight(
        green,
        label: green.label!,
        comment: 'Worth a second look.',
      );
      final marks = await companions.marksOf('Books/Dune.pdf');
      expect(
        [for (final m in marks) m.highlight],
        [null, HighlightColour.pink],
      );
      expect(marks.first.title, 'p. 4');
      final text = read(marks.first.note);
      expect(
        text,
        contains(
          '## p. 4\n\n> Passage 4.\n'
          '> — [[Books/Dune.pdf#page=4&chars=0-9|p. 4]]\n'
          '\nWorth a second look.\n\n> Passage 5.',
        ),
      );
    });

    test('its link is rewritten in any case and order (#642)', () async {
      await write(highlight(4, HighlightColour.green));
      final path = (await companions.of('Books/Dune.pdf')).single;
      Future<void> relink(String from, String to) =>
          ops.saveNote(path, read(path).replaceFirst(from, to));
      Future<List<AnnotationMark>> marks() =>
          companions.marksOf('Books/Dune.pdf');

      await relink('highlight=green', 'highlight=Green');
      await companions.recolour((await marks()).single, HighlightColour.blue);
      expect((await marks()).single.highlight, HighlightColour.blue);

      await relink(
        '#page=4&chars=0-9&highlight=blue',
        '#highlight=blue&page=4&chars=0-9',
      );
      await companions.annotateHighlight(
        (await marks()).single,
        label: 'p. 4',
        comment: 'Noted.',
      );
      expect((await marks()).single.highlight, isNull);
      expect(read(path), contains('[[Books/Dune.pdf#page=4&chars=0-9|p. 4]]'));
    });

    test('a note edited since is not changed blindly', () async {
      await write(highlight(4, HighlightColour.green));
      final mark = (await companions.marksOf('Books/Dune.pdf')).single;
      final path = mark.note;
      await ops.saveNote(
        path,
        read(path).replaceFirst('---\n\n', '---\n\nNew line.\n\n'),
      );
      await expectLater(companions.removeHighlight(mark), throwsStateError);
      expect(read(path), contains('Passage 4.'));
    });

    test('a CRLF companion stays CRLF', () async {
      await write(highlight(4, HighlightColour.green));
      await write(highlight(5, HighlightColour.pink));
      final path = (await companions.of('Books/Dune.pdf')).single;
      final file = File(p.join(root.path, path));
      file.writeAsStringSync(file.readAsStringSync().replaceAll('\n', '\r\n'));
      await Indexer(db).fullScan(root.path);
      final green = (await companions.marksOf('Books/Dune.pdf')).first;
      await companions.removeHighlight(green);
      final text = file.readAsStringSync();
      expect(text, isNot(contains('Passage 4.')));
      expect(text.replaceAll('\r\n', ''), isNot(contains('\n')));
      expect(text, contains('> Passage 5.\r\n'));
    });
  });
}
