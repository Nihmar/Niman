// What a converted book's pictures are stored as (#1138): the extension
// comes from the picture and a short list of types, never from the book's
// own text.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/epub/epub_picture_type.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

const List<int> _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2];
const List<int> _jpg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 16];
const List<int> _gif = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 1, 0];
const List<int> _webp = [
  ...[0x52, 0x49, 0x46, 0x46, 4, 0, 0, 0],
  ...[0x57, 0x45, 0x42, 0x50, 0x56],
];
const List<int> _bmp = [0x42, 0x4D, 1, 2, 3];
const List<int> _avif = [
  ...[0, 0, 0, 0x1C, 0x66, 0x74, 0x79, 0x70],
  ...[0x61, 0x76, 0x69, 0x66],
];

void main() {
  String extensionOf(String path, List<int> bytes) =>
      epubPictureExtension(path, Uint8List.fromList(bytes));

  group('the extension of a picture', () {
    test('comes from its bytes, whatever the book calls it', () {
      expect(extensionOf('a.md', _png), '.png');
      expect(extensionOf('a.png', _jpg), '.jpg');
      expect(extensionOf('noextension', _gif), '.gif');
      expect(extensionOf('a.png:stream', _webp), '.webp');
      expect(extensionOf('a.', _bmp), '.bmp');
      expect(extensionOf('a.txt', _avif), '.avif');
    });

    test('is .svg for text that is an svg, however it begins', () {
      for (final text in [
        '<svg xmlns="http://www.w3.org/2000/svg"/>',
        '<?xml version="1.0"?>\n<svg width="1"/>',
        '﻿  <?xml version="1.0"?><!-- made by --><!DOCTYPE svg><svg>',
        '<SVG>',
      ]) {
        expect(extensionOf('a.bin', utf8.encode(text)), '.svg', reason: text);
      }
      expect(extensionOf('a.bin', utf8.encode('<html><svg/></html>')), '.bin');
    });

    test('keeps a listed name for a picture the bytes do not tell', () {
      expect(extensionOf('Pic.JPEG', [1, 2, 3]), '.jpeg');
      expect(extensionOf('dir/a.avif', [1, 2, 3]), '.avif');
      expect(extensionOf('a.svg', [1, 2, 3]), '.svg');
    });

    test('is opaque for what is no picture the app shows', () {
      for (final name in [
        'x.md',
        'x.md.',
        'a.png:stream',
        'x.${'a' * 300}',
        'noextension',
        'x.exe',
        'a.png ',
        'a.p\u0000ng',
      ]) {
        expect(extensionOf(name, [1, 2, 3]), epubPictureFallback, reason: name);
      }
    });
  });

  test('a converted book stores each picture under a safe name', () async {
    final tmp = Directory.systemTemp.createTempSync('niman_epub_pictures_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final library = Directory(p.join(tmp.path, 'library'))..createSync();
    final names = ['x.md', 'y.png:stream', 'z.', 'w.${'a' * 200}', 'v.JPG'];
    final bytes = <String, List<int>>{
      'x.md': _png,
      'y.png:stream': _gif,
      'z.': [9, 9, 9],
      'w.${'a' * 200}': [8, 8, 8],
      'v.JPG': _jpg,
    };
    final images = [for (final n in names) '<p><img src="$n" alt="$n"/></p>']
        .join();
    final source = writeTestEpub(
      p.join(tmp.path, 'pictures.epub'),
      chapters: [(path: 'c.xhtml', body: '<h1>One</h1>$images')],
      files: {for (final n in names) 'OEBPS/$n': bytes[n]!},
    );
    final converted = await convertEpub((
      source: source.path,
      name: null,
      libraryRoot: library.path,
      parent: '',
      staging: p.join(library.path, '.epub.niman-tmp-1'),
      oneNote: false,
      attachments: 'assets',
      words: _words,
    ));
    final assets = Directory(p.join(library.path, converted.made, 'assets'))
        .listSync()
        .map((e) => p.basename(e.path))
        .toList();
    expect(assets, hasLength(names.length));
    expect(assets.map(p.extension).toList()..sort(), [
      '.bin',
      '.bin',
      '.gif',
      '.jpg',
      '.png',
    ], reason: 'the bytes tell a picture, the rest is opaque, nothing is .md');
    final note = File(p.join(library.path, converted.made, '01 One.md'))
        .readAsStringSync();
    for (final asset in assets) {
      expect(note, contains(asset), reason: 'the note points at $asset');
    }
  });
}
