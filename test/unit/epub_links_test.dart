// The links a converted book writes (#1138) resolve in the app: every
// destination of index.md and of the notes, with the characters a title can
// carry that a Markdown destination cannot (parentheses, angle brackets, #,
// %, spaces, accents), is read back by the app's own link parser and
// resolver to the note and the heading it was written for - not just the
// shape of its string.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

/// The titles of the chapters, and of the section each one holds.
const List<(String, String)> _titles = [
  ('1) Start', 'Why (not) begin'),
  ('Fish <&> Chips', 'a > b < c'),
  ('Part #2 (of 3)', 'Issue #12'),
  ('100% Sure', '50%25 off'),
  ('Café (Déjà vu)', 'Año (nuevo)'),
];

void main() {
  late Directory tmp;
  late Directory library;
  late IndexDatabase db;
  late String folder;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('niman_epub_links_');
    library = Directory(p.join(tmp.path, 'library'))..createSync();
    String xml(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    // A link to every chapter's section, this one's included.
    final links = [
      for (var i = 0; i < _titles.length; i++)
        '<a href="c$i.xhtml#s">to $i</a>',
    ].join(' ');
    String entry(int index, (String, String) title) =>
        '<li><a href="c$index.xhtml">${xml(title.$1)}</a><ol>'
        '<li><a href="c$index.xhtml#s">${xml(title.$2)}</a></li>'
        '</ol></li>';
    final source = writeTestEpub(
      p.join(tmp.path, 'odd.epub'),
      title: 'Odd (Titles)',
      chapters: [
        for (final (index, (chapter, section)) in _titles.indexed)
          (
            path: 'c$index.xhtml',
            body:
                '<h1>${xml(chapter)}</h1><p>Text.</p>'
                '<h2 id="s">${xml(section)}</h2>'
                '<p>$links</p>',
          ),
      ],
      nav: '<ol>${_titles.indexed.map((e) => entry(e.$1, e.$2)).join()}</ol>',
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
    folder = converted.made;
    db = IndexDatabase(NativeDatabase(File(p.join(tmp.path, 'i.sqlite'))));
    await Indexer(db).fullScan(library.path);
  });

  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  String text(String rel) =>
      File(p.joinAll([library.path, ...rel.split('/')])).readAsStringSync();

  /// [line] without the backslashes the conversion escaped its text with.
  String plain(String line) => line.replaceAll(r'\', '');

  /// Where [href], written in [from], goes: the first line of the note it
  /// lands in and the heading line it names there (null for the note's top).
  Future<({String note, String? heading})> follow(
    String from,
    String href,
  ) async {
    final result = await LinkResolver(db).resolveMarkdown(href, from: from);
    final String note;
    final String? heading;
    switch (result) {
      case ResolvedNote(note: final found, heading: final fragment):
        note = text(found.path);
        heading = fragment;
      case LocalAnchor(heading: final fragment):
        note = text(from);
        heading = fragment;
      default:
        fail('"$href" in $from resolved to $result');
    }
    final line = note.split('\n').first;
    if (heading != null && heading.isNotEmpty) {
      final anchor = parseAnchor(heading)! as HeadingAnchor;
      final at = headingLineOf(outlineOfText(note), anchor);
      expect(at, isNotNull, reason: '"$href" names no heading of its note');
      return (note: plain(line), heading: plain(note.split('\n')[at!]));
    }
    return (note: plain(line), heading: null);
  }

  test('the contents link every chapter and section where it is', () async {
    final from = '$folder/index.md';
    final links = parseLinks(text(from)).whereType<MarkdownLink>().toList();
    // A chapter and its section an entry each; the book's cover has none.
    expect(links, hasLength(_titles.length * 2));
    final followed = [for (final link in links) await follow(from, link.href)];
    for (final (index, (chapter, section)) in _titles.indexed) {
      expect(followed[index * 2].note, '# $chapter');
      expect(followed[index * 2].heading, isNull);
      expect(followed[index * 2 + 1].note, '# $chapter');
      expect(followed[index * 2 + 1].heading, endsWith(section));
    }
  });

  test('a link in a chapter lands on the section it names', () async {
    for (final (index, (chapter, _)) in _titles.indexed) {
      final from = Directory(p.join(library.path, folder))
          .listSync()
          .whereType<File>()
          .map((f) => '$folder/${p.basename(f.path)}')
          .singleWhere((f) => plain(text(f)).startsWith('# $chapter'));
      final links = parseLinks(text(from)).whereType<MarkdownLink>().toList();
      expect(links, hasLength(_titles.length), reason: from);
      for (final (target, link) in links.indexed) {
        final landed = await follow(from, link.href);
        expect(landed.note, '# ${_titles[target].$1}', reason: 'from $index');
        expect(landed.heading, endsWith(_titles[target].$2));
      }
    }
  });
}
