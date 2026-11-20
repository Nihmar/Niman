// A note's EPUB page cut into chapters at its headings: at the shallowest
// level that repeats, its opening a page of its own, its links inside the
// note pointing at the file that now holds their id.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/chapter_level.dart';
import 'package:niman/src/export/epub_note_chapters.dart';
import 'package:xml/xml.dart';

void main() {
  group('chapterLevelOf', () {
    test('is the shallowest level that occurs three times', () {
      expect(chapterLevelOf([1, 2, 2, 2, 3, 3, 3, 3]), 2);
      expect(chapterLevelOf([1, 1, 1, 2, 2, 2]), 1);
    });

    test('is none when no level repeats three times', () {
      expect(chapterLevelOf([1, 2, 2]), isNull);
      expect(chapterLevelOf(const <int>[]), isNull);
    });
  });

  group('splitEpubNoteChapters', () {
    test('a page without a repeated level is one chapter', () {
      const body = '<h1>T</h1>\n<p>a</p>\n<h2>S</h2>\n<p>b</p>\n';
      final chapters = splitEpubNoteChapters(body, title: 'T');
      expect(chapters, hasLength(1));
      expect(chapters.single.file, epubNoteFile);
      expect(chapters.single.title, 'T');
      expect(chapters.single.body, body);
    });

    test('a note chaptered at # keeps its ## inside the chapters', () {
      const body =
          '<h1 id="one">One</h1>\n<p>a</p>\n<h2>Scene</h2>\n<p>b</p>\n'
          '<h1 id="two">Two</h1>\n<h2>Scene</h2>\n<h2>Scene</h2>\n'
          '<h1 id="three">Three</h1>\n<p>c</p>\n';
      final chapters = splitEpubNoteChapters(body, title: 'Book');
      // Three `##` too, but `#` is the shallower level that repeats.
      expect([for (final c in chapters) c.title], ['One', 'Two', 'Three']);
      expect(
        [for (final c in chapters) c.file],
        ['note-1.xhtml', 'note-2.xhtml', 'note-3.xhtml'],
      );
      expect(chapters.first.body, startsWith('<h1 id="one">'));
      expect(chapters.first.body, contains('<h2>Scene</h2>'));
      expect(chapters[1].body, contains('<h2>Scene</h2>\n<h2>Scene</h2>'));
      // Nothing lost and nothing added: the cuts are between elements.
      expect(chapters.map((c) => c.body).join(), body);
    });

    test('a note titled by its one # is cut at its ##', () {
      const body =
          '<h1>The Book</h1>\n<p>Summary.</p>\n'
          '<h2>Chapter 1</h2>\n<p>a</p>\n'
          '<h2>Chapter <em>2</em></h2>\n<p>b</p>\n'
          '<h2>Chapter 3</h2>\n<p>c</p>\n';
      final chapters = splitEpubNoteChapters(body, title: 'The Book');
      expect(
        [for (final c in chapters) c.title],
        ['The Book', 'Chapter 1', 'Chapter 2', 'Chapter 3'],
      );
      // The opening — the title and the summary — is a page of its own.
      expect(chapters.first.body, '<h1>The Book</h1>\n<p>Summary.</p>\n');
      expect(chapters[2].body, startsWith('<h2>Chapter <em>2</em></h2>'));
      expect(chapters.map((c) => c.body).join(), body);
    });

    test('an empty opening is no page', () {
      const body = '\n<h2>A</h2>\n<h2>B</h2>\n<h2>C</h2>\n';
      final chapters = splitEpubNoteChapters(body, title: 'T');
      expect([for (final c in chapters) c.title], ['A', 'B', 'C']);
      // Its blank goes with it.
      expect(chapters.first.body, '<h2>A</h2>\n');
    });

    test('a heading inside another element does not cut', () {
      const body =
          '<blockquote><h2>Q</h2><h2>Q</h2><h2>Q</h2></blockquote>'
          '<p>x</p>';
      expect(splitEpubNoteChapters(body, title: 'T'), hasLength(1));
    });

    test('a link to an id in another chapter names its file', () {
      const body =
          '<h2 id="a">A</h2>\n'
          '<p>See<sup class="footnote-ref">\n'
          '<a href="#fn-1" id="fnref-1">1</a></sup>\n'
          'and <a href="#c">C</a>.</p>\n'
          '<h2 id="b">B</h2>\n<p><a href="#b">here</a></p>\n'
          '<h2 id="c">C</h2>\n<p>c</p>\n'
          '<section class="footnotes"><ol><li id="fn-1"><p>Note. '
          '<a href="#fnref-1" class="footnote-backref">↩</a></p></li></ol>\n'
          '</section>\n';
      final chapters = splitEpubNoteChapters(body, title: 'T');
      expect(chapters, hasLength(3));
      expect(chapters[0].body, contains('href="note-3.xhtml#fn-1"'));
      expect(chapters[0].body, contains('href="note-3.xhtml#c"'));
      // An id the chapter carries itself stays a fragment.
      expect(chapters[1].body, contains('<a href="#b">'));
      // The footnotes are the last chapter's, their way back the first's.
      expect(chapters[2].body, contains('<li id="fn-1">'));
      expect(chapters[2].body, contains('href="note-1.xhtml#fnref-1"'));
      for (final chapter in chapters) {
        XmlDocument.parse('<div>${chapter.body}</div>');
      }
    });

    test('a page the parser cannot follow stays whole', () {
      const body = '<h2>A</h2><h2>B</h2><p>x</div><h2>C</h2>';
      final chapters = splitEpubNoteChapters(body, title: 'T');
      expect(chapters, hasLength(1));
      expect(chapters.single.body, body);
    });
  });
}
