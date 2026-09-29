// Where each book and PDF of a library was left (#281): its place, in the
// document's own terms, kept in `.niman/reading.json` by the file's
// library-relative path.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:path/path.dart' as p;

void main() {
  group('a place', () {
    test('reads back what it wrote', () {
      const places = <BookLocation>[
        PdfLocation(page: 3, fraction: 0.25),
        EpubLocation(chapter: 'OEBPS/ch5.xhtml', line: 12, fraction: 0.5),
      ];
      for (final place in places) {
        expect(BookLocation.fromJson(place.toJson()), place);
      }
    });

    test('that does not read is none', () {
      for (final json in <Object?>[
        null,
        'page 3',
        <String, Object?>{},
        {'page': 0},
        {'page': '3'},
        {'chapter': '', 'line': 1},
        {'chapter': 'a.xhtml', 'line': -1},
      ]) {
        expect(BookLocation.fromJson(json), isNull, reason: '$json');
      }
    });

    test('keeps its fraction between 0 and 1', () {
      expect(
        BookLocation.fromJson({'page': 2, 'fraction': 3}),
        const PdfLocation(page: 2, fraction: 1),
      );
    });

    test('is near where a view settles on it, not a line away', () {
      const here = EpubLocation(chapter: 'a.xhtml', line: 4, fraction: 0.5);
      expect(
        here.isNear(
          const EpubLocation(chapter: 'a.xhtml', line: 4, fraction: 0.52),
        ),
        isTrue,
      );
      expect(
        here.isNear(const EpubLocation(chapter: 'a.xhtml', line: 5)),
        isFalse,
      );
      expect(here.isNear(const PdfLocation(page: 4)), isFalse);
      expect(here.isNear(null), isFalse);
    });
  });

  group("a link's fragment (#282)", () {
    test('names a page of a PDF, as Obsidian writes it', () {
      expect(BookLocation.fromFragment('page=34'), const PdfLocation(page: 34));
      // An embed's height is not a place.
      expect(
        BookLocation.fromFragment('page=3&height=400'),
        const PdfLocation(page: 3),
      );
      expect(BookLocation.fromFragment('PAGE = 2'), const PdfLocation(page: 2));
    });

    test('names a line of a chapter of a book', () {
      expect(
        BookLocation.fromFragment('chapter=OEBPS/ch5.xhtml&line=12'),
        const EpubLocation(chapter: 'OEBPS/ch5.xhtml', line: 12),
      );
      expect(
        BookLocation.fromFragment('chapter=ch5.xhtml'),
        const EpubLocation(chapter: 'ch5.xhtml', line: 0),
      );
    });

    test('that names no place is none: a heading, a bad page', () {
      for (final fragment in [
        '',
        'My Heading',
        'page=0',
        'page=two',
        'chapter=',
        'line=4',
      ]) {
        expect(BookLocation.fromFragment(fragment), isNull, reason: fragment);
      }
    });

    test('is written for a place, and read back', () {
      const places = <BookLocation>[
        PdfLocation(page: 7),
        EpubLocation(chapter: 'OEBPS/Text/ch 5 (a&b)#1.xhtml', line: 3),
        EpubLocation(chapter: '100%/città.xhtml', line: 0),
      ];
      for (final place in places) {
        final fragment = place.toFragment();
        expect(fragment, isNot(contains(' ')));
        expect(fragment.split('#'), hasLength(1));
        expect(BookLocation.fromFragment(fragment), place, reason: fragment);
      }
      expect(
        const EpubLocation(chapter: 'OEBPS/ch 5.xhtml', line: 3).toFragment(),
        'chapter=OEBPS/ch%205.xhtml&line=3',
      );
    });

    test('goes to its line or page, not into it', () {
      expect(const PdfLocation(page: 7, fraction: 0.5).toFragment(), 'page=7');
    });
  });

  group('the positions of a library', () {
    late Directory root;
    late ReadingPositions positions;
    setUp(() {
      root = Directory.systemTemp.createTempSync('niman_reading_');
      positions = ReadingPositions(root.path);
    });
    tearDown(() => root.deleteSync(recursive: true));

    File kept() => File(p.join(root.path, ReadingPositions.filePath));

    /// Puts a file at [path], library-relative: an entry for a file that
    /// is there survives the write's pruning (#367).
    File holding(String path) => File(p.join(root.path, path))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('x');

    test('none are kept in a library that read nothing', () async {
      expect(await positions.read('book.epub'), isNull);
      expect(kept().existsSync(), isFalse);
    });

    test('keep each file where it was left, and when', () async {
      holding('books/Dune.epub');
      holding('papers/x.pdf');
      await positions.write(
        'books/Dune.epub',
        const EpubLocation(chapter: 'ch1.xhtml', line: 7),
        at: DateTime.utc(2026, 9, 25, 10),
      );
      await positions.write('papers/x.pdf', const PdfLocation(page: 2));
      expect(
        await positions.read('books/Dune.epub'),
        const EpubLocation(chapter: 'ch1.xhtml', line: 7),
      );
      expect(await positions.read('papers/x.pdf'), const PdfLocation(page: 2));
      final json = jsonDecode(kept().readAsStringSync()) as Map;
      expect(json['books/Dune.epub'], {
        'chapter': 'ch1.xhtml',
        'line': 7,
        'fraction': 0.0,
        'at': '2026-09-25T10:00:00.000Z',
      });
    });

    test('lose none of the writes made at once', () async {
      for (var page = 1; page <= 20; page++) {
        holding('p$page.pdf');
      }
      await Future.wait([
        for (var page = 1; page <= 20; page++)
          positions.write('p$page.pdf', PdfLocation(page: page)),
      ]);
      for (var page = 1; page <= 20; page++) {
        expect(await positions.read('p$page.pdf'), PdfLocation(page: page));
      }
    });

    test('follow a file renamed, and a folder with the files in it', () async {
      holding('a/one.pdf');
      holding('a/b/two.pdf');
      holding('ab/three.pdf');
      await positions.write('a/one.pdf', const PdfLocation(page: 1));
      await positions.write('a/b/two.pdf', const PdfLocation(page: 2));
      await positions.write('ab/three.pdf', const PdfLocation(page: 3));
      // The file, then the folder holding it, are renamed on disk before
      // their positions are carried (#281), as a move does.
      File(p.join(root.path, 'a', 'one.pdf'))
          .renameSync(p.join(root.path, 'a', 'uno.pdf'));
      await positions.moved('a/one.pdf', 'a/uno.pdf');
      Directory(p.join(root.path, 'a')).renameSync(p.join(root.path, 'z'));
      await positions.moved('a', 'z');
      expect(await positions.read('z/uno.pdf'), const PdfLocation(page: 1));
      expect(await positions.read('z/b/two.pdf'), const PdfLocation(page: 2));
      expect(await positions.read('a/b/two.pdf'), isNull);
      // A folder whose name begins the same is another folder.
      expect(await positions.read('ab/three.pdf'), const PdfLocation(page: 3));
    });

    test('keep a position whose book has not arrived here yet', () async {
      // #492: the sync brings device A's position for a book whose file has
      // not downloaded here. Writing another book's position rewrote the
      // file, pruned the unknown book, and the next sync deleted A's entry.
      kept()
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'books/Dune.epub': {
              'chapter': 'ch1.xhtml',
              'line': 7,
              'fraction': 0.0,
              'at': '2026-09-25T10:00:00.000Z',
            },
          }),
        );
      holding('papers/x.pdf');
      await positions.write('papers/x.pdf', const PdfLocation(page: 2));
      final json = jsonDecode(kept().readAsStringSync()) as Map;
      expect(json.keys, containsAll(['books/Dune.epub', 'papers/x.pdf']));
      expect(
        await positions.read('books/Dune.epub'),
        const EpubLocation(chapter: 'ch1.xhtml', line: 7),
      );
    });

    test(
      'drop the entries of files the library saw leave, and keep the rest',
      () async {
        holding('books/Dune.epub');
        holding('papers/x.pdf');
        await positions.write(
          'books/Dune.epub',
          const EpubLocation(chapter: 'ch1.xhtml', line: 7),
        );
        await positions.write('papers/x.pdf', const PdfLocation(page: 2));
        // The book leaves the library and the indexer reports it gone.
        File(p.join(root.path, 'books', 'Dune.epub')).deleteSync();
        await positions.removed({'books/Dune.epub'});
        final json = jsonDecode(kept().readAsStringSync()) as Map;
        expect(json.keys, ['papers/x.pdf']);
        expect(await positions.read('books/Dune.epub'), isNull);
        expect(await positions.read('papers/x.pdf'), const PdfLocation(page: 2));
      },
    );

    test('a folder the library saw leave takes the books under it', () async {
      holding('books/shelf/Dune.epub');
      holding('books/Mistborn.epub');
      await positions.write(
        'books/shelf/Dune.epub',
        const EpubLocation(chapter: 'ch1.xhtml', line: 7),
      );
      await positions.write('books/Mistborn.epub', const PdfLocation(page: 2));
      await positions.removed({'books/shelf'});
      expect(await positions.read('books/shelf/Dune.epub'), isNull);
      // A sibling whose name begins the same is another folder.
      expect(
        await positions.read('books/Mistborn.epub'),
        const PdfLocation(page: 2),
      );
    });

    test('a file that does not read is started over', () async {
      kept()
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{not json');
      expect(await positions.read('x.pdf'), isNull);
      holding('x.pdf');
      await positions.write('x.pdf', const PdfLocation(page: 4));
      expect(await positions.read('x.pdf'), const PdfLocation(page: 4));
    });

    test('key a file by its path in the library, none outside it', () {
      expect(
        positions.keyOf(p.join(root.path, 'books', 'Dune.epub')),
        'books/Dune.epub',
      );
      expect(positions.keyOf(p.join(root.parent.path, 'x.pdf')), isNull);
    });
  });
}
