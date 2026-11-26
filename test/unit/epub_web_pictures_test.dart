// A picture on the web in an exported EPUB (#1309): downloaded when the
// container is written and carried inside it, as the PDF's engine fetches it
// while printing; the alt text as a link only for what did not come.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/epub_web_pictures.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:path/path.dart' as p;

/// A PNG's signature and a few bytes: what the book sniffs a type from.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4, //
]);

void main() {
  late Directory root;
  late HttpServer server;
  late String base;
  late Map<String, int> hits;
  late Completer<void> slowAsked;

  setUp(() async {
    root = await Directory.current.createTemp('niman_epub_web_');
    hits = <String, int>{};
    slowAsked = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      final path = request.uri.path;
      hits[path] = (hits[path] ?? 0) + 1;
      final response = request.response;
      if (path == '/slow') {
        // Never answered: a download that has to be cut.
        if (!slowAsked.isCompleted) slowAsked.complete();
        return;
      }
      if (path.startsWith('/pic')) {
        response.headers.contentType = ContentType('image', 'png');
        response.add(_png);
      } else if (path == '/page') {
        response.headers.contentType = ContentType('image', 'png');
        response.write('<html>not a picture</html>');
      } else if (path == '/text') {
        response.headers.contentType = ContentType('text', 'html');
        response.write('<html></html>');
      } else if (path == '/bmp') {
        response.headers.contentType = ContentType('image', 'bmp');
        response.add(<int>[0x42, 0x4D, 1, 2, 3, 4]);
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Map<String, List<int>> entries(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    return <String, List<int>>{
      for (final file in archive.files)
        if (file.isFile) file.name: file.content as List<int>,
    };
  }

  String text(Map<String, List<int>> files, String name) =>
      utf8.decode(files[name]!);

  Future<Map<String, List<int>>> noteBook(String markdown) async {
    final payload = await exportNoteEpub(
      text: markdown,
      title: 'T',
      path: 'T.md',
      root: root.path,
      language: 'en',
    );
    final file = p.join(root.path, 'note.epub');
    await File(file).writeAsBytes(payload.bytes);
    return entries(file);
  }

  Future<Map<String, List<int>>> folderBook(String markdown) async {
    final notes = p.join(root.path, 'Notes');
    await Directory(notes).create(recursive: true);
    await File(p.join(notes, 'a.md')).writeAsString(markdown);
    final out = p.join(root.path, 'folder.epub');
    await TreeExport.run(
      dir: notes,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    return entries(out);
  }

  List<String> imageEntries(Map<String, List<int>> files) => [
    for (final name in files.keys)
      if (name.startsWith('OEBPS/images/')) name,
  ];

  group('a picture on the web is in the book', () {
    test('a note carries it as a manifest item and an img', () async {
      final files = await noteBook('# T\n\n![w]($base/pic.png)\n');
      expect(imageEntries(files), ['OEBPS/images/img-1.png']);
      expect(files['OEBPS/images/img-1.png'], _png);
      expect(text(files, 'OEBPS/content.opf'), contains('image/png'));
      final chapter = text(files, 'OEBPS/text/note.xhtml');
      expect(chapter, contains('<img src="../images/img-1.png"'));
      expect(chapter, isNot(contains(base)));
      expect(chapter, isNot(contains('<a href')));
    });

    test('a folder carries it as a manifest item and an img', () async {
      final files = await folderBook('# T\n\n![w]($base/pic.png)\n');
      expect(imageEntries(files), ['OEBPS/images/img-1.png']);
      expect(files['OEBPS/images/img-1.png'], _png);
      expect(text(files, 'OEBPS/content.opf'), contains('image/png'));
      final chapter = text(files, 'OEBPS/text/a.xhtml');
      expect(chapter, contains('<img src="../images/img-1.png"'));
      expect(chapter, isNot(contains(base)));
    });

    test('a local picture is still a file of the library', () async {
      await File(p.join(root.path, 'photo.png')).writeAsBytes(_png);
      final files = await noteBook(
        '# T\n\n![a](photo.png)\n\n![b]($base/pic.png)\n',
      );
      // A library's file and a download are two items, whatever their bytes.
      expect(imageEntries(files), hasLength(2));
      final chapter = text(files, 'OEBPS/text/note.xhtml');
      expect(chapter, isNot(contains(base)));
      expect(RegExp('<img ').allMatches(chapter), hasLength(2));
    });

    test('the same address twice is one item, fetched once', () async {
      final files = await noteBook(
        '# T\n\n![a]($base/pic.png)\n\n![b]($base/pic.png)\n',
      );
      expect(imageEntries(files), hasLength(1));
      expect(hits['/pic.png'], 1);
      final chapter = text(files, 'OEBPS/text/note.xhtml');
      expect(RegExp('<img ').allMatches(chapter), hasLength(2));
    });

    test('two addresses of the same bytes are one item', () async {
      final files = await noteBook(
        '# T\n\n![a]($base/pic1.png)\n\n![b]($base/pic2.png)\n',
      );
      expect(imageEntries(files), hasLength(1));
      expect(hits['/pic1.png'], 1);
      expect(hits['/pic2.png'], 1);
    });

    test('a folder fetches an address once for all its chapters', () async {
      final notes = p.join(root.path, 'Notes');
      await Directory(notes).create(recursive: true);
      for (final name in ['a', 'b']) {
        await File(p.join(notes, '$name.md'))
            .writeAsString('# $name\n\n![w]($base/pic.png)\n');
      }
      final out = p.join(root.path, 'two.epub');
      await TreeExport.run(
        dir: notes,
        zipPath: out,
        format: ExportTreeFormat.epub,
        language: 'en',
      );
      final files = entries(out);
      expect(imageEntries(files), hasLength(1));
      expect(hits['/pic.png'], 1);
      for (final name in ['a', 'b']) {
        expect(
          text(files, 'OEBPS/text/$name.xhtml'),
          contains('<img src="../images/img-1.png"'),
        );
      }
    });
  });

  group('what does not come is the alt text, linked', () {
    Future<void> expectLink(String address, {String alt = 'w'}) async {
      final markdown = '# T\n\n![$alt]($address)\n';
      for (final files in [
        await noteBook(markdown),
        await folderBook(markdown),
      ]) {
        expect(imageEntries(files), isEmpty);
        final name = files.containsKey('OEBPS/text/note.xhtml')
            ? 'OEBPS/text/note.xhtml'
            : 'OEBPS/text/a.xhtml';
        final chapter = text(files, name);
        expect(chapter, isNot(contains('<img')));
        expect(chapter, contains('<a href="$address">$alt</a>'));
        expect(text(files, 'OEBPS/content.opf'), isNot(contains('image/')));
      }
      // The folder's own book is not the note's: a second run is clean.
      await Directory(p.join(root.path, 'Notes')).delete(recursive: true);
    }

    test('an error status', () => expectLink('$base/missing.png'));

    test('bytes that are no picture', () => expectLink('$base/page'));

    test('a type that is not an image', () => expectLink('$base/text'));

    test(
      'a type an EPUB does not carry',
      () => expectLink('$base/bmp', alt: 'bitmap'),
    );

    test('an address that does not answer', () async {
      final closed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final address = 'http://127.0.0.1:${closed.port}/a.png';
      await closed.close(force: true);
      await expectLink(address);
    });

    test('an address of the web with no alt text is the address', () async {
      final files = await noteBook('# T\n\n![]($base/missing.png)\n');
      expect(
        text(files, 'OEBPS/text/note.xhtml'),
        contains('<a href="$base/missing.png">$base/missing.png</a>'),
      );
    });
  });

  group('the downloads are bounded', () {
    test('the book tries at most the number it is given', () async {
      final fetched = <String>[];
      final web = EpubWebPictures(
        isCancelled: () => false,
        maxDownloads: 2,
        fetch: (url) async {
          fetched.add(url);
          return (bytes: _png, extension: '.png');
        },
      );
      addTearDown(web.close);
      final book = await _book(root);
      final images = await web.carry(book, 'OEBPS/text', [
        'http://h/1.png',
        'http://h/2.png',
        'http://h/3.png',
      ]);
      await book.close();
      expect(fetched, hasLength(2));
      expect(images.keys, ['http://h/1.png', 'http://h/2.png']);
      // The same bytes: one file, so one address in the book.
      expect(images.values.toSet(), hasLength(1));
      expect(images, isNot(contains('http://h/3.png')));
    });

    test('a download past its timeout is left out', () async {
      final web = EpubWebPictures(
        isCancelled: () => false,
        fetch: (url) => Future<Never>.error(TimeoutException('slow')),
      );
      addTearDown(web.close);
      final book = await _book(root);
      final images = await web.carry(book, 'OEBPS/text', ['http://h/a.png']);
      await book.close();
      expect(images, isEmpty);
    });

    test('only http and https are downloaded', () {
      expect(
        EpubWebPictures.webTargets([
          'http://h/a.png',
          'HTTPS://h/b.png',
          'ftp://h/c.png',
          'photo.png',
          'data:image/png;base64,AAAA',
        ]),
        ['http://h/a.png', 'HTTPS://h/b.png'],
      );
    });
  });

  group('a stop', () {
    test("cuts a note's download and writes no book", () async {
      final scratch = await Directory(p.join(root.path, 's')).create();
      var stop = false;
      final run = exportNoteEpub(
        text: '# T\n\n![w]($base/slow)\n',
        title: 'T',
        path: 'T.md',
        root: root.path,
        language: 'en',
        scratch: scratch,
        isCancelled: () => stop,
      );
      final outcome = expectLater(run, throwsA(isA<EpubExportCancelled>()));
      await slowAsked.future.timeout(const Duration(seconds: 30));
      stop = true;
      // Far less than the download's own timeout.
      await outcome.timeout(const Duration(seconds: 10));
    });

    test("cuts a folder's download and leaves no zip", () async {
      final notes = p.join(root.path, 'Notes');
      await Directory(notes).create(recursive: true);
      await File(p.join(notes, 'a.md'))
          .writeAsString('# T\n\n![w]($base/slow)\n');
      final out = p.join(root.path, 'folder.epub');
      final export = await TreeExport.start(
        dir: notes,
        zipPath: out,
        format: ExportTreeFormat.epub,
        language: 'en',
      );
      final outcome = expectLater(export.done, throwsA(isA<ExportCancelled>()));
      await slowAsked.future.timeout(const Duration(seconds: 30));
      await export.cancel();
      await outcome.timeout(const Duration(seconds: 10));
      expect(File(out).existsSync(), isFalse);
    });
  });
}

Future<EpubBook> _book(Directory root) => EpubBook.start(
  path: p.join(root.path, 'unit.epub'),
  title: 'T',
  language: 'en',
  libraryPath: 'T.md',
);
