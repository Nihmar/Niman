// A kanban board in an export (#1170): written as sections and cards when
// the Kanban feature is on, the sheet it prints on, and the page around it.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_hooks.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/kanban_sheet.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const String _footer =
    '%% kanban:settings\n'
    '```\n'
    '{"kanban-plugin":"basic"}\n'
    '```\n'
    '%%\n';

/// The board of the design record, with prose before and inside it.
const String _board =
    '---\n'
    'type: kanban\n'
    '---\n'
    'Intro to [[Other]] before the board.\n'
    '\n'
    '## To do\n'
    '- [ ] Write the brief #work\n'
    '- [ ] Book the venue due:2026-11-10\n'
    '\n'
    '## Doing\n'
    '- [ ] Draft the slides\n'
    '  Outline first, then visuals.\n'
    '\n'
    'Prose that stays in the column.\n'
    '\n'
    '- [x] Pick a theme\n'
    '\n'
    '## Done\n'
    '- [x] Pick the date\n'
    '\n'
    '$_footer';

NoteHtml _html(
  String text, {
  bool kanban = true,
  Map<String, String> links = const {},
  Map<String, String> images = const {},
}) => NoteHtml(
  NoteHtmlSource(
    text: text,
    title: 't',
    kanban: kanban,
    links: links,
    images: images,
  ),
);

/// A board of [columns] empty columns.
String _columns(int columns) {
  final cards = [for (var i = 1; i <= columns; i++) '## C$i\n- [ ] card $i\n'];
  return '---\ntype: kanban\n---\n${cards.join('\n')}';
}

/// What a note's body was before boards: the writer with the page's hooks.
String _before(String text) {
  final source = NoteHtmlSource(text: text, title: 't');
  return TreeHtml(text, hooks: ExportHooks(source, MathSvg())).render();
}

void main() {
  group('the board', () {
    test('is a column per heading, with its count, and a card per item', () {
      final html = _html(_board, links: {'Other': 'other.html'}).body();
      expect(html, contains('<div class="kanban" data-columns="3">'));
      expect(
        RegExp('<section class="kanban-column">').allMatches(html),
        hasLength(3),
      );
      expect(html, contains('<h2 id="to-do">To do</h2>'));
      expect(html, contains('<h2 id="doing">Doing</h2>'));
      expect(html, contains('<h2 id="done">Done</h2>'));
      // The counts: two, two and one cards.
      final counts = RegExp(r'<span class="kanban-count">(\d+)</span>')
          .allMatches(html)
          .map((m) => m.group(1))
          .toList();
      expect(counts, <String?>['2', '2', '1']);
      expect(RegExp('<li class="kanban-card').allMatches(html), hasLength(5));
    });

    test('keeps the text before the first column, links resolved', () {
      final html = _html(_board, links: {'Other': 'other.html'}).body();
      expect(
        html,
        startsWith(
          '<p>Intro to <a class="wikilink" href="other.html">Other</a> '
          'before the board.</p>\n<div class="kanban"',
        ),
      );
      // The frontmatter is not on the page.
      expect(html, isNot(contains('type: kanban')));
    });

    test('draws the task box as the writer does, ticked as written', () {
      final html = _html(_board).body();
      expect(
        html,
        contains(
          '<div class="kanban-card-title"><input type="checkbox" '
          'disabled="" /> Draft the slides</div>',
        ),
      );
      expect(
        html,
        contains(
          '<li class="kanban-card kanban-done">\n'
          '<div class="kanban-card-title"><input type="checkbox" '
          'checked="" disabled="" /> Pick the date',
        ),
      );
    });

    test('shows tags and the due date as chips, out of the title', () {
      final html = _html(_board).body();
      expect(
        html,
        contains('<input type="checkbox" disabled="" /> Write the brief</div>'),
      );
      expect(
        html,
        contains('<span class="kanban-chip kanban-tag">#work</span>'),
      );
      expect(html, contains('<span class="kanban-chip kanban-due">2026-11-10'));
      expect(html, isNot(contains('due:2026')));
    });

    test('keeps a card body and the prose between cards where they are', () {
      final html = _html(_board).body();
      expect(
        html,
        contains(
          '<div class="kanban-card-body">\n'
          '<p>Outline first, then visuals.</p>\n</div>',
        ),
      );
      final prose = html.indexOf('<p>Prose that stays in the column.</p>');
      final before = html.indexOf('Draft the slides');
      final after = html.indexOf('Pick a theme');
      expect(prose, greaterThan(before));
      expect(prose, lessThan(after));
      // The column's cards are two lists around the prose.
      final doing = html.substring(html.indexOf('id="doing"'));
      final column = doing.substring(0, doing.indexOf('</section>'));
      expect(
        RegExp('<ul class="kanban-cards">').allMatches(column),
        hasLength(2),
      );
    });

    test('leaves the settings footer out', () {
      final html = _html(_board).body();
      expect(html, isNot(contains('kanban-plugin')));
      expect(html, isNot(contains('kanban:settings')));
    });

    test('escapes a title, a column name and a tag', () {
      final html = _html(
        '---\ntype: kanban\n---\n'
        '## A <b> & "c"\n'
        '- [ ] Fix <script>alert(1)</script> & go #a&b\n',
      ).body();
      expect(html, contains('A &lt;b&gt; &amp; &quot;c&quot;'));
      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('<b>')));
      expect(html, contains('&lt;script&gt;'));
      expect(html, contains('#a&amp;b</span>'));
    });

    test('resolves a link and a wikilink in a card through the hooks', () {
      final html = _html(
        '---\ntype: kanban\n---\n'
        '## Todo\n'
        '- [ ] Read [[Other note]] and [the page](Page.md) now\n'
        '  And [[Other note#Part]] in the body.\n',
        links: {
          'Other note': 'other.html',
          'Page.md': 'page.html',
          'Other note#Part': 'other.html#part',
        },
      ).body();
      expect(html, contains('<a class="wikilink" href="other.html">'));
      expect(html, contains('<a href="page.html">the page</a>'));
      expect(html, contains('Other note'));
    });

    test('a board with no column is its prose, and has no sheet', () {
      final note = _html('---\ntype: kanban\n---\nJust text.\n\n$_footer');
      expect(note.body(), '<p>Just text.</p>\n');
      expect(note.boardSheet, isNull);
    });

    test('reads a CRLF board as an LF one', () {
      final crlf = _html(_board.replaceAll('\n', '\r\n')).body();
      expect(crlf, _html(_board).body());
    });

    test('keeps the column ids in the order of the note', () {
      final html = _html(
        '---\ntype: kanban\n---\n## Same\n- a\n\n## Same\n- b\n',
      ).body();
      expect(html, contains('<h2 id="same">Same</h2>'));
      expect(html, contains('<h2 id="same-2">Same</h2>'));
    });
  });

  group('the switch', () {
    test('is off with the feature: a kanban note is as it was', () {
      expect(_html(_board, kanban: false).body(), _before(_board));
      expect(_html(_board, kanban: false).boardSheet, isNull);
    });

    test('leaves any other note as it was', () {
      const text = '# Plain\n\n## Heading\n- [ ] a task\n\n$_footer';
      expect(_html(text).body(), _before(text));
      const other = '---\ntype: slides\n---\n## One\n- item\n';
      expect(_html(other).body(), _before(other));
      expect(_html(other).boardSheet, isNull);
    });

    test('finds a picture in a card, a title or a body', () {
      final targets = _html(
        '---\ntype: kanban\n---\n'
        '## Todo\n'
        '- [ ] Look ![alt](title.png)\n'
        '  ![[body.jpg]]\n',
      ).pictureTargets();
      expect(targets.images, <String>['title.png']);
      expect(targets.embeds, <String>['body.jpg']);
    });

    test('says a card with a formula drew SVG', () {
      final html = _html(
        '---\ntype: kanban\n---\n## Todo\n- [ ] Solve \$x^2\$\n',
      );
      expect(html.body(), contains('<svg '));
      expect(html.usesSvg, isTrue);
      expect(_html(_board).usesSvg, isFalse);
    });

    test('draws a picture from the images the page was given', () {
      final html = _html(
        '---\ntype: kanban\n---\n## Todo\n- [ ] ![p](a.png)\n',
        images: {'a.png': 'data:image/png;base64,AAAA'},
      ).body();
      expect(html, contains('src="data:image/png;base64,AAAA"'));
    });
  });

  group('the definitions of the note', () {
    const head = '---\ntype: kanban\n---\n';

    test('resolve a reference link in a card, defined after the board', () {
      final html = _html(
        '$head## Todo\n'
        '- [ ] See [the docs][docs] now\n'
        '- [ ] Other\n'
        '\n'
        '[docs]: https://example.org/docs\n',
      ).body();
      expect(html, contains('<a href="https://example.org/docs">the docs</a>'));
      // The definition is not card text, nor prose.
      expect(html, isNot(contains('[docs]')));
      expect(html, isNot(contains('kanban-prose')));
    });

    test(
      'resolve a reference link against another card, and the other way',
      () {
        final html = _html(
          '$head## Todo\n'
          '- [ ] First [x][ref]\n'
          '- [ ] Second [y][later]\n'
          '  [ref]: https://example.org/r\n'
          '## Doing\n'
          '- [ ] Third\n'
          '  [later]: <https://example.org/l> "Title"\n',
        ).body();
        expect(html, contains('<a href="https://example.org/r">x</a>'));
        expect(
          html,
          contains('<a href="https://example.org/l" title="Title">y</a>'),
        );
        expect(html, isNot(contains('[ref]:')));
        expect(html, isNot(contains('[later]:')));
        // Cards that held only a definition have no body.
        expect(html, isNot(contains('kanban-card-body')));
      },
    );

    test('a reference with no definition stays text', () {
      final html = _html('$head## Todo\n- [ ] See [a][none]\n').body();
      expect(html, contains('See [a][none]'));
    });

    test('number the footnotes over the note, listed once after the board', () {
      final html = _html(
        '${head}Before[^b] the board.\n'
        '\n'
        '## Todo\n'
        '- [ ] Claim[^a] and again[^b]\n'
        '  Body cites[^c].\n'
        '- [ ] Holds the notes\n'
        '  [^c]: Note c, in a card.\n'
        '## Done\n'
        '- [x] Cites a missing one[^9]\n'
        '  \n'
        '[^a]: Note a, after the board.\n'
        '[^b]: Note b.\n',
      ).body();
      // Numbered by first citation over the whole note: b, a, c.
      expect(
        RegExp(r'data-footnote-ref="">(\d)</a>')
            .allMatches(html)
            .map((m) => m[1]),
        <String?>['1', '2', '1', '3'],
      );
      expect(html, contains('href="#fn-b" id="fnref-b"'));
      expect(html, contains('href="#fn-b" id="fnref-b-2"'));
      // One list, after the board, in citation order.
      expect(
        RegExp('<section class="footnotes"').allMatches(html),
        hasLength(1),
      );
      expect(
        html.indexOf('</div>'),
        lessThan(html.indexOf('class="footnotes"')),
      );
      final list = html.substring(html.indexOf('class="footnotes"'));
      expect(list.indexOf('Note b.'), lessThan(list.indexOf('Note a, after')));
      expect(list.indexOf('Note a, after'), lessThan(list.indexOf('Note c')));
      expect(list, contains('footnote-backref'));
      // The definitions are not card text; an undefined one is text.
      expect(
        html.substring(0, html.indexOf('class="footnotes"')),
        isNot(contains('Note c')),
      );
      expect(html, contains('missing one[^9]'));
    });

    test('write the footnote list as XHTML for a book', () {
      final html = _html('$head## Todo\n- [ ] Claim[^a]\n\n[^a]: Note a.\n')
          .body();
      expect(html, contains('<section class="footnotes" data-footnotes="">'));
      expect(html, contains('<li id="fn-a">'));
    });

    test('leave a note that is no board as the writer wrote it', () {
      const text =
          'A claim[^a] and [a link][r].\n\n'
          '## Heading\n- [ ] a card[^a]\n\n'
          '[r]: https://example.org\n[^a]: A note.\n';
      expect(_html(text).body(), _before(text));
      expect(
        _html('---\ntype: kanban\n---\n$text', kanban: false).body(),
        _before('---\ntype: kanban\n---\n$text'),
      );
    });
  });

  group('the sheet', () {
    test('is landscape while the columns fit one row, portrait after', () {
      expect(kanbanSheetFor(1), KanbanSheet.landscape);
      expect(kanbanSheetFor(4), KanbanSheet.landscape);
      expect(kanbanSheetFor(5), KanbanSheet.portrait);
      expect(kanbanSheetFor(12), KanbanSheet.portrait);
      // Nothing to wrap: an empty board is not asked for, but it is a row.
      expect(kanbanSheetFor(0), KanbanSheet.landscape);
    });

    test('counts the usable width of A4 with the page margin', () {
      expect(KanbanSheet.landscape.usableMm, 261);
      expect(KanbanSheet.portrait.usableMm, 174);
      expect(kanbanLandscapeColumns, 4);
      expect(kanbanPortraitColumns, 2);
      // Wrapped in portrait, a column is still at least the minimum wide.
      final portrait = KanbanSheet.portrait.usableMm;
      final width =
          (portrait - (kanbanPortraitColumns - 1) * kanbanGapMm) /
          kanbanPortraitColumns;
      expect(width, greaterThanOrEqualTo(kanbanColumnMinMm));
      // Four columns and their gaps fit a landscape row; five do not.
      double row(int n) => n * kanbanColumnMinMm + (n - 1) * kanbanGapMm;
      expect(row(4), lessThanOrEqualTo(KanbanSheet.landscape.usableMm));
      expect(row(5), greaterThan(KanbanSheet.landscape.usableMm));
    });

    test('is the board, read off the note', () {
      expect(_html(_columns(4)).boardSheet, KanbanSheet.landscape);
      expect(_html(_columns(5)).boardSheet, KanbanSheet.portrait);
      expect(_html(_board).boardSheet, KanbanSheet.landscape);
    });
  });

  group('the page', () {
    String page(String text, {bool kanban = true}) {
      final html = _html(text, kanban: kanban);
      return htmlPage(title: 't', body: html.body(), board: html.boardSheet);
    }

    test('asks for A4 landscape for four columns, not for five', () {
      expect(page(_columns(4)), contains('size: A4 landscape'));
      final five = page(_columns(5));
      expect(five, isNot(contains('A4 landscape')));
      // The grid that wraps two to a row, as many as fit at the minimum.
      expect(five, contains('repeat(2, minmax(0, 1fr))'));
    });

    test('carries the cards that never split and the heads that stay', () {
      final css = page(_columns(2));
      expect(css, contains('.kanban-card {'));
      expect(css, contains('break-inside: avoid'));
      expect(css, contains('break-after: avoid'));
      expect(css, contains('@media (max-width: 600px)'));
    });

    test('is the page it was for a page with no board', () {
      final off = page(_board, kanban: false);
      expect(off, isNot(contains('kanban-column')));
      expect(off, isNot(contains('.kanban-card')));
      expect(
        page('# Plain\n'),
        htmlPage(title: 't', body: _before('# Plain\n')),
      );
    });
  });

  group('the exports', () {
    late Directory root;

    setUp(() async {
      root = await Directory.current.createTemp('niman_kanban_');
    });

    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    Future<String> html({required bool kanban}) async {
      final payload = await exportNote(
        text: _board,
        title: 'Board',
        path: 'Board.md',
        root: root.path,
        language: 'en',
        format: ExportFileFormat.html,
        kanban: kanban,
      );
      return utf8.decode(payload.bytes);
    }

    test('a note exported as HTML is the board, with its style', () async {
      final page = await html(kanban: true);
      expect(page, contains('<div class="kanban" data-columns="3">'));
      expect(page, contains('.kanban-column {'));
      expect(page, contains('size: A4 landscape'));
      final off = await html(kanban: false);
      expect(off, isNot(contains('kanban-column')));
      expect(off, contains('<h2 id="to-do">To do</h2>'));
    });

    test('a folder with a board writes the board in its page', () async {
      final notes = p.join(root.path, 'Notes');
      await Directory(notes).create(recursive: true);
      await File(p.join(notes, 'board.md')).writeAsString(_board);
      await File(p.join(notes, 'plain.md')).writeAsString('# Plain\n');
      Future<Map<String, String>> zipped({required bool kanban}) async {
        final zip = p.join(root.path, 'out-$kanban.zip');
        await TreeExport.run(
          dir: notes,
          zipPath: zip,
          format: ExportTreeFormat.html,
          language: 'en',
          kanban: kanban,
        );
        final archive = ZipDecoder().decodeBytes(File(zip).readAsBytesSync());
        return <String, String>{
          for (final file in archive.files)
            if (file.isFile) file.name: utf8.decode(file.content as List<int>),
        };
      }

      final on = await zipped(kanban: true);
      expect(
        on['board.html'],
        contains('<div class="kanban" data-columns="3">'),
      );
      expect(on['board.html'], contains('size: A4 landscape'));
      expect(on['plain.html'], isNot(contains('kanban')));
      final off = await zipped(kanban: false);
      expect(off['board.html'], isNot(contains('kanban-column')));
    });

    test('a note exported as an EPUB stacks the board as sections', () async {
      Future<Map<String, String>> book({required bool kanban}) async {
        final payload = await exportNoteEpub(
          text: _board,
          title: 'Board',
          path: 'Board.md',
          root: root.path,
          language: 'en',
          kanban: kanban,
        );
        final archive = ZipDecoder().decodeBytes(payload.bytes);
        return <String, String>{
          for (final file in archive.files)
            if (file.isFile) file.name: utf8.decode(file.content as List<int>),
        };
      }

      final on = await book(kanban: true);
      expect(
        on['OEBPS/text/note.xhtml'],
        contains('<section class="kanban-column">'),
      );
      // The chapter is XHTML a reader will parse.
      XmlDocument.parse(on['OEBPS/text/note.xhtml']!);
      final style = on['OEBPS/style.css']!;
      expect(style, contains('.kanban-card {'));
      // No side-by-side layout, and no sheet, in a reflowing book.
      expect(style, isNot(contains('A4 landscape')));
      expect(style, isNot(contains('flex: 0 0 16em')));
      final off = await book(kanban: false);
      expect(off['OEBPS/text/note.xhtml'], isNot(contains('kanban-column')));
      expect(off['OEBPS/style.css'], isNot(contains('.kanban-card')));
    });
  });
}
