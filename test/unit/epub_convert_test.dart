// Converting a book to notes (#1138): the notes, their folders, the
// pictures, the links and index.md a book makes, and what it refuses.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_conversion.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/export/epub_package.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

const List<int> _png = [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];

void main() {
  late Directory tmp;
  late String library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_epub_convert_');
    library = p.join(tmp.path, 'library');
    Directory(library).createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  String book(String name) => p.join(tmp.path, name);

  Future<EpubConverted> convert(
    String source, {
    String parent = '',
    bool oneNote = false,
  }) => convertEpub((
    source: source,
    libraryRoot: library,
    parent: parent,
    staging: p.join(library, '.epub.niman-tmp-1'),
    oneNote: oneNote,
    attachments: 'assets',
    words: _words,
  ));

  String read(String rel) =>
      File(p.joinAll([library, ...rel.split('/')])).readAsStringSync();

  List<String> tree(String rel) {
    final dir = Directory(p.joinAll([library, ...rel.split('/')]));
    return [
      for (final entity in dir.listSync(recursive: true))
        if (entity is File)
          p.split(p.relative(entity.path, from: dir.path)).join('/'),
    ]..sort();
  }

  group('a book of chapters', () {
    late String source;

    setUp(() {
      source = writeTestEpub(
        book('dune.epub'),
        title: 'Dune',
        unique: 'uid',
        metadata:
            '<dc:creator>Frank Herbert</dc:creator>'
            '<dc:language>en</dc:language>'
            '<dc:identifier id="uid">urn:isbn:9780441013593</dc:identifier>'
            '<dc:subject>Science Fiction</dc:subject>'
            '<meta property="belongs-to-collection" id="s">Dune</meta>'
            '<meta refines="#s" property="group-position">1</meta>',
        items:
            '<item id="cover" href="cover.png" properties="cover-image" '
            'media-type="image/png"/>',
        chapters: [
          (
            path: 'one.xhtml',
            body:
                '<h1>Arrakis</h1><p>The desert planet.</p>'
                '<p><img src="map.png" alt="Map"/></p>'
                '<p>See <a href="two.xhtml#storm">the storm</a>.</p>',
          ),
          (
            path: 'two.xhtml',
            body:
                "<h1>Muad'Dib</h1><p>A boy.</p>"
                '<h2 id="storm">The Storm</h2><p>Sand.</p>',
          ),
        ],
        nav:
            '<ol><li><a href="one.xhtml">Arrakis</a></li>'
            '<li><a href="two.xhtml">Muad\'Dib</a></li></ol>',
        files: {
          'OEBPS/map.png': _png,
          'OEBPS/cover.png': [..._png, 9],
        },
      ).path;
    });

    test(
      'is a folder of a note a chapter, its pictures, and index.md',
      () async {
        final converted = await convert(source);
        expect(converted.made, 'Dune');
        expect(converted.open, 'Dune/index.md');
        expect(converted.notes, 2);
        final files = tree('Dune');
        expect(files.where((f) => f.endsWith('.md')), [
          '01 Arrakis.md',
          "02 Muad'Dib.md",
          'index.md',
        ]);
        expect(files.where((f) => f.startsWith('assets/')), hasLength(2));
        expect(Directory(library).listSync().map((e) => p.basename(e.path)), [
          'Dune',
        ], reason: 'the staging folder is gone, nothing else written');
      },
    );

    test(
      'a picture points at its copy in the book, a link at its note',
      () async {
        await convert(source);
        final one = read('Dune/01 Arrakis.md');
        expect(one, startsWith('# Arrakis'));
        final picture = RegExp(r'!\[Map\]\((assets/[0-9a-f]{64}\.png)\)')
            .firstMatch(one);
        expect(picture, isNotNull, reason: one);
        expect(
          File(p.join(library, 'Dune', picture!.group(1))).existsSync(),
          isTrue,
        );
        expect(one, contains("[the storm](<02%20Muad'Dib.md#The%20Storm>)"));
      },
    );

    test('index.md carries what an export reads back', () async {
      await convert(source);
      final index = read('Dune/index.md');
      final metadata = epubMetadataOf(index);
      expect(metadata.title, 'Dune');
      expect(metadata.authors, ['Frank Herbert']);
      expect(metadata.language, 'en');
      expect(metadata.identifier, '9780441013593');
      expect(metadata.series, 'Dune');
      expect(metadata.seriesIndex, '1');
      expect(metadata.subjects, ['science fiction']);
      expect(metadata.cover, matches(RegExp(r'^assets/[0-9a-f]{64}\.png$')));
      expect(
        File(p.join(library, 'Dune', metadata.cover)).existsSync(),
        isTrue,
      );
      expect(index, contains('- [Arrakis](01%20Arrakis.md)'));
    });

    test('a second conversion lands beside the first', () async {
      await convert(source);
      final again = await convert(source);
      expect(again.made, 'Dune 2');
    });

    test('one note is the whole book, its pictures in the library', () async {
      final converted = await convert(source, oneNote: true, parent: 'Books');
      expect(converted.made, 'Books/Dune.md');
      final note = read('Books/Dune.md');
      expect(note, contains('# Arrakis'));
      expect(note, contains('# Muad'));
      expect(note, contains('](assets/'));
      expect(note, contains('](<#The%20Storm>)'));
      expect(Directory(p.join(library, 'assets')).listSync(), hasLength(1));
    });

    test('the preview says what would be written', () async {
      final preview = previewEpub(source, _words);
      expect(preview.title, 'Dune');
      expect(preview.authors, ['Frank Herbert']);
      expect(preview.notes, 2);
      expect(preview.folders, 0);
      expect(preview.pictures, 1);
    });
  });

  test('parts are folders, their chapters notes in them', () async {
    final source = writeTestEpub(
      book('parts.epub'),
      title: 'Parts',
      chapters: [
        (path: 'p1.xhtml', body: '<h1>Part One</h1><p>An epigraph.</p>'),
        (path: 'c1.xhtml', body: '<h1>First</h1><p>One.</p>'),
        (path: 'c2.xhtml', body: '<h1>Second</h1><p>Two.</p>'),
        // A part with no page of its own: it opens on its first chapter.
        (path: 'c3.xhtml', body: '<h1>Third</h1><p>Three.</p>'),
      ],
      nav:
          '<ol>'
          '<li><a href="p1.xhtml">Part One</a><ol>'
          '<li><a href="c1.xhtml">First</a></li>'
          '<li><a href="c2.xhtml">Second</a></li></ol></li>'
          '<li><span>Part Two</span><ol>'
          '<li><a href="c3.xhtml">Third</a></li></ol></li>'
          '</ol>',
    ).path;
    await convert(source);
    expect(tree('Parts').where((f) => f.endsWith('.md')), [
      '01 Part One/00 Part One.md',
      '01 Part One/01 First.md',
      '01 Part One/02 Second.md',
      '02 Part Two/01 Third.md',
      'index.md',
    ]);
    expect(read('Parts/01 Part One/00 Part One.md'), contains('An epigraph.'));
    final index = read('Parts/index.md');
    expect(index, contains('- [Part One](01%20Part%20One/00%20Part%20One.md)'));
    expect(index, contains('  - [First](01%20Part%20One/01%20First.md)'));
    expect(index, contains('- [Part Two](02%20Part%20Two/01%20Third.md)'));
  });

  test('a part kept in one long file splits at its chapters', () async {
    final long = '<p>${'A long sentence of the chapter. ' * 1000}</p>';
    final source = writeTestEpub(
      book('long.epub'),
      title: 'Long',
      chapters: [
        (
          path: 'part.xhtml',
          body:
              '<h1 id="a">Alpha</h1>$long<h1 id="b">Beta</h1>$long'
              '<h1 id="c">Gamma</h1>$long',
        ),
      ],
      nav:
          '<ol><li><a href="part.xhtml">The Part</a><ol>'
          '<li><a href="part.xhtml#a">Alpha</a></li>'
          '<li><a href="part.xhtml#b">Beta</a></li>'
          '<li><a href="part.xhtml#c">Gamma</a></li></ol></li></ol>',
    ).path;
    await convert(source);
    expect(tree('Long').where((f) => f.endsWith('.md')), [
      '01 The Part/01 Alpha.md',
      '01 The Part/02 Beta.md',
      '01 The Part/03 Gamma.md',
      'index.md',
    ]);
  });

  test('sections stay headings inside their chapter', () async {
    final source = writeTestEpub(
      book('sections.epub'),
      chapters: [
        (path: 'c1.xhtml', body: '<h1>One</h1><h2 id="s">Section</h2><p>x</p>'),
        (path: 'c2.xhtml', body: '<h1>Two</h1><p>y</p>'),
      ],
      nav:
          '<ol><li><a href="c1.xhtml">One</a><ol>'
          '<li><a href="c1.xhtml#s">Section</a></li></ol></li>'
          '<li><a href="c2.xhtml">Two</a></li></ol>',
    ).path;
    await convert(source);
    expect(tree('A Test Book').where((f) => f.endsWith('.md')), [
      '01 One.md',
      '02 Two.md',
      'index.md',
    ]);
    expect(
      read('A Test Book/index.md'),
      contains('  - [Section](01%20One.md#Section)'),
    );
  });

  test(
    'a book with no contents is a note a chapter, named by its heading',
    () async {
      final source = writeTestEpub(
        book('bare.epub'),
        chapters: [
          (path: 'a.xhtml', body: '<h1>Morning</h1><p>x</p>'),
          (path: 'b.xhtml', body: '<p>No heading here.</p>'),
        ],
      ).path;
      await convert(source);
      expect(tree('A Test Book').where((f) => f.endsWith('.md')), [
        '01 Morning.md',
        '02 Chapter 2.md',
        'index.md',
      ]);
    },
  );

  test('an encrypted book is refused, and nothing is written', () async {
    final source = writeTestEpub(
      book('drm.epub'),
      chapters: [(path: 'c1.xhtml', body: '<p>x</p>')],
      files: {
        'META-INF/encryption.xml':
            '<encryption '
                    'xmlns="urn:oasis:names:tc:opendocument:xmlns:container" '
                    'xmlns:enc="http://www.w3.org/2001/04/xmlenc#">'
                    '<enc:EncryptedData><enc:CipherData>'
                    '<enc:CipherReference URI="OEBPS/c1.xhtml"/>'
                    '</enc:CipherData></enc:EncryptedData></encryption>'
                .codeUnits,
      },
    ).path;
    await expectLater(
      convert(source),
      throwsA(
        isA<EpubRefused>().having(
          (e) => e.reason,
          'reason',
          EpubRefusal.protected,
        ),
      ),
    );
    expect(Directory(library).listSync(), isEmpty);
  });

  test(
    'a book is known by its mimetype entry, whatever it is called',
    () async {
      final named = writeTestEpub(
        book('msf-1234'),
        chapters: [(path: 'c1.xhtml', body: '<p>x</p>')],
      ).path;
      expect(await looksLikeEpub(named), isTrue);
      final zip = File(book('notion.zip'))
        ..writeAsBytesSync(
          ZipEncoder().encodeBytes(
            Archive()..add(ArchiveFile.string('page.md', '# Page')),
          ),
        );
      expect(await looksLikeEpub(zip.path), isFalse);
      File(book('short')).writeAsStringSync('PK');
      expect(await looksLikeEpub(book('short')), isFalse);
    },
  );

  test('a file that is not a book is refused', () async {
    final source = book('notes.epub');
    File(source).writeAsStringSync('not a zip at all');
    await expectLater(
      convert(source),
      throwsA(
        isA<EpubRefused>().having(
          (e) => e.reason,
          'reason',
          EpubRefusal.notABook,
        ),
      ),
    );
    expect(Directory(library).listSync(), isEmpty);
  });

  test('a book that expands past its budget is refused', () {
    final source = writeTestEpub(
      book('big.epub'),
      chapters: [(path: 'c1.xhtml', body: '<p>${'x' * 5000}</p>')],
    ).path;
    final input = InputFileStream(source);
    addTearDown(input.closeSync);
    expect(
      () => EpubArchive.open(input, maxBytes: 1000),
      throwsA(
        isA<EpubRefused>().having(
          (e) => e.reason,
          'reason',
          EpubRefusal.tooLarge,
        ),
      ),
    );
  });

  test('a cancelled conversion leaves the library as it was', () async {
    final source = writeTestEpub(
      book('cancel.epub'),
      chapters: [
        for (var i = 0; i < 40; i++)
          (path: 'c$i.xhtml', body: '<h1>C$i</h1><p>${'text ' * 500}</p>'),
      ],
    ).path;
    final conversion = await EpubConversion.start(
      source: source,
      libraryRoot: library,
      parent: '',
      oneNote: false,
      attachments: 'assets',
      words: _words,
    );
    expect(await conversion.cancel(), isTrue);
    await expectLater(conversion.done, throwsA(isA<EpubConvertCancelled>()));
    expect(Directory(library).listSync(), isEmpty);
  });

  test('told not to finish, it moves nothing in', () async {
    final source = writeTestEpub(
      book('stop.epub'),
      chapters: [(path: 'c1.xhtml', body: '<h1>Only</h1><p>x</p>')],
    ).path;
    await expectLater(
      convertEpub((
        source: source,
        libraryRoot: library,
        parent: '',
        staging: p.join(library, '.epub.niman-tmp-2'),
        oneNote: false,
        attachments: 'assets',
        words: _words,
      ), mayFinish: () async => false),
      throwsA(isA<EpubConvertStopped>()),
    );
    expect(Directory(library).listSync(), isEmpty);
  });

  test('a cancel leaves the book closed, free to delete or move', () async {
    final source = writeTestEpub(
      book('free.epub'),
      chapters: [
        for (var i = 0; i < 40; i++)
          (path: 'c$i.xhtml', body: '<h1>C$i</h1><p>${'text ' * 500}</p>'),
      ],
    ).path;
    for (var round = 0; round < 5; round++) {
      final conversion = await EpubConversion.start(
        source: source,
        libraryRoot: library,
        parent: '',
        oneNote: false,
        attachments: 'assets',
        words: _words,
      );
      // Let it get into the book on some rounds, not on others.
      await Future<void>.delayed(Duration(milliseconds: round * 20));
      expect(await conversion.cancel(), isTrue);
      await expectLater(conversion.done, throwsA(isA<EpubConvertCancelled>()));
      // A killed isolate holds the file open (errno 32 on Windows).
      File(source).renameSync(book('moved.epub'));
      File(book('moved.epub')).renameSync(source);
      expect(Directory(library).listSync(), isEmpty);
    }
    File(source).deleteSync();
    expect(Directory(library).listSync(), isEmpty);
  });

  test(
    'a stop between two steps ends it with its book and folder freed',
    () async {
      final source = writeTestEpub(
        book('stopped.epub'),
        chapters: [
          for (var i = 0; i < 10; i++)
            (path: 'c$i.xhtml', body: '<h1>C$i</h1><p>x</p>'),
        ],
      ).path;
      final staging = p.join(library, '.epub.niman-tmp-3');
      var seen = 0;
      await expectLater(
        convertEpub(
          (
            source: source,
            libraryRoot: library,
            parent: '',
            staging: staging,
            oneNote: false,
            attachments: 'assets',
            words: _words,
          ),
          progress: (_) => seen++,
          // True once three steps were written: after some notes were.
          stopped: () => seen >= 3,
        ),
        throwsA(isA<EpubConvertStopped>()),
      );
      expect(seen, 3);
      expect(Directory(staging).existsSync(), isFalse);
      expect(Directory(library).listSync(), isEmpty);
      File(source).deleteSync();
    },
  );

  test(
    'a stop while the book is read ends it before any step, all freed',
    () async {
      final source = writeTestEpub(
        book('reading.epub'),
        chapters: [
          for (var i = 0; i < 60; i++)
            (path: 'c$i.xhtml', body: '<h1>C$i</h1><p>${'text ' * 200}</p>'),
        ],
      ).path;
      final staging = p.join(library, '.epub.niman-tmp-4');
      var asked = 0;
      var seen = 0;
      await expectLater(
        convertEpub(
          (
            source: source,
            libraryRoot: library,
            parent: '',
            staging: staging,
            oneNote: false,
            attachments: 'assets',
            words: _words,
          ),
          progress: (_) => seen++,
          // Asked once before each chapter: true at the second one.
          stopped: () => ++asked >= 2,
        ),
        throwsA(isA<EpubConvertStopped>()),
      );
      // Stopped at the second chapter of sixty: not one step was reached.
      expect(asked, 2);
      expect(seen, 0);
      expect(Directory(staging).existsSync(), isFalse);
      expect(Directory(library).listSync(), isEmpty);
      File(source).deleteSync();
    },
  );

  test('the stepped read is the plain read, a chapter at a time', () async {
    final source = writeTestEpub(
      book('stepped.epub'),
      chapters: [
        for (var i = 0; i < 6; i++)
          (
            path: 'c$i.xhtml',
            body: '<h1 id="h$i">C$i</h1><p><a href="c0.xhtml#h0">back</a></p>',
          ),
      ],
      nav: '<li><a href="c0.xhtml">C0</a></li>',
    ).path;
    final first = InputFileStream(source);
    final second = InputFileStream(source);
    final plain = parseEpub(EpubArchive.open(first));
    var turns = 0;
    final stepped = await parseEpubStepped(
      EpubArchive.open(second),
      between: () async => turns++,
    );
    first.closeSync();
    second.closeSync();
    expect(turns, 6);
    // Records hold maps, which compare by identity: compare what they say.
    expect('${stepped.chapters}', '${plain.chapters}');
    expect(stepped.contents, plain.contents);
    expect(stepped.links, plain.links);
    expect(stepped.pictures, plain.pictures);
    expect(stepped.info.title, plain.info.title);
    File(source).deleteSync();
  });

  test('a cancel counts its job out of the gauge', () async {
    final source = writeTestEpub(
      book('gauge.epub'),
      chapters: [
        for (var i = 0; i < 40; i++)
          (path: 'c$i.xhtml', body: '<h1>C$i</h1><p>${'text ' * 500}</p>'),
      ],
    ).path;
    final before = IsolateGauge.inFlight;
    final conversion = await EpubConversion.start(
      source: source,
      libraryRoot: library,
      parent: '',
      oneNote: false,
      attachments: 'assets',
      words: _words,
    );
    expect(IsolateGauge.inFlight, before + 1);
    expect(await conversion.cancel(), isTrue);
    await expectLater(conversion.done, throwsA(isA<EpubConvertCancelled>()));
    expect(IsolateGauge.inFlight, before);
  });

  test('a cancel racing a refusal answers once, and throws nothing', () async {
    final source = book('race.epub');
    File(source).writeAsStringSync('not a zip: refused at once');
    final uncaught = <Object>[];
    await runZonedGuarded(() async {
      for (var round = 0; round < 20; round++) {
        final conversion = await EpubConversion.start(
          source: source,
          libraryRoot: library,
          parent: '',
          oneNote: false,
          attachments: 'assets',
          words: _words,
        );
        // Whichever lands first — the refusal or the cancel — is the answer.
        final cancelled = conversion.cancel();
        await expectLater(
          conversion.done,
          throwsA(anyOf(isA<EpubConvertCancelled>(), isA<EpubRefused>())),
        );
        await cancelled;
      }
    }, (error, _) => uncaught.add(error));
    expect(uncaught, isEmpty);
    expect(Directory(library).listSync(), isEmpty);
  });

  test('a conversion run on its isolate answers what it wrote', () async {
    final source = writeTestEpub(
      book('run.epub'),
      chapters: [(path: 'c1.xhtml', body: '<h1>Only</h1><p>x</p>')],
    ).path;
    final conversion = await EpubConversion.start(
      source: source,
      libraryRoot: library,
      parent: 'Books',
      oneNote: false,
      attachments: 'assets',
      words: _words,
    );
    final converted = await conversion.done;
    expect(converted.made, 'Books/A Test Book');
    expect(read('Books/A Test Book/01 Only.md'), startsWith('# Only'));
  });
}
