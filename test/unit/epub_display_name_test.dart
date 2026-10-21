// A book with no title of its own is named after its file (#1138) - after the
// name a share came with, not after the copy a share leaves in the cache
// (`<millis>-Dune.epub`).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

void main() {
  late Directory tmp;
  late String library;
  late String copy;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_epub_display_');
    library = p.join(tmp.path, 'library');
    Directory(library).createSync();
    copy = writeTestEpub(
      p.join(tmp.path, '1729512345678-Dune.epub'),
      title: '',
      chapters: [(path: 'c1.xhtml', body: '<h1>One</h1><p>Text.</p>')],
    ).path;
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<EpubConverted> convert({String? name}) => convertEpub((
    source: copy,
    name: name,
    libraryRoot: library,
    parent: '',
    staging: p.join(library, '.epub.niman-tmp-1'),
    oneNote: false,
    attachments: 'assets',
    words: _words,
  ));

  test('the preview and the folder carry the share name', () async {
    expect(previewEpub(copy, _words, name: 'Dune.epub').title, 'Dune');
    expect((await convert(name: 'Dune.epub')).made, 'Dune');
  });

  test('a file named as it is keeps its own name', () async {
    expect(previewEpub(copy, _words).title, '1729512345678-Dune');
    expect((await convert()).made, '1729512345678-Dune');
  });

  test('a name with no extension or only blanks is told apart', () async {
    expect(previewEpub(copy, _words, name: 'Dune').title, 'Dune');
    expect(
      previewEpub(copy, _words, name: '  ').title,
      '1729512345678-Dune',
      reason: 'a blank name names nothing: the file is read as it is',
    );
  });

  test('what the user is told a book is called', () {
    expect(epubDisplayName('/cache/1-Dune.epub', 'Dune.epub'), 'Dune.epub');
    expect(epubDisplayName('/books/Dune.epub', null), 'Dune.epub');
    expect(epubDisplayName('/books/Dune.epub', ''), 'Dune.epub');
  });
}
