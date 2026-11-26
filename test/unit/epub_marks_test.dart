// A book's marks as the lines they point at (#285, #626), and the places of
// its last chapter kept within the book's text (#1306).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_marks.dart';
import 'package:niman/src/epub/epub_progress.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/reading/book_location.dart';

/// A book of two chapters, 5 lines each, a rule between: 13 lines, the
/// second opening at line 8.
EpubDocument _book() {
  final lines = [
    for (var i = 0; i < 5; i++) 'one $i',
    '',
    '---',
    '',
    for (var i = 0; i < 5; i++) 'two $i',
  ];
  final markdown = '${lines.join('\n')}\n';
  return EpubDocument(
    title: 'Two',
    markdown: markdown,
    lineCount: lines.length,
    contents: const [],
    pictures: const {},
    links: const [],
    chapters: const [
      (file: 'OEBPS/Text/ch1.xhtml', line: 0),
      (file: 'OEBPS/Text/ch2.xhtml', line: 8),
    ],
    counts: EpubCounts.of(markdown),
  );
}

AnnotationMark _mark(String chapter, int line) => AnnotationMark(
  note: 'Two.md',
  offset: line,
  place: EpubLocation(chapter: chapter, line: line),
  highlight: HighlightColour.yellow,
);

void main() {
  group('the last chapter of a book', () {
    test('keeps a place within its last line, as the text counts it', () {
      final document = _book();
      expect(document.lineCount, 13);
      expect(
        document.lineOfLocation(
          const EpubLocation(chapter: 'OEBPS/Text/ch2.xhtml', line: 2),
        ),
        10,
      );
      expect(
        document.lineOfLocation(
          const EpubLocation(chapter: 'OEBPS/Text/ch2.xhtml', line: 500),
        ),
        12,
      );
    });

    test('is found by its path, any case, or its file name alone', () {
      final document = _book();
      for (final name in [
        'OEBPS/Text/ch2.xhtml',
        'oebps/text/CH2.xhtml',
        'ch2.xhtml',
        'Text/ch2.xhtml',
      ]) {
        expect(
          document.lineOfLocation(EpubLocation(chapter: name, line: 1)),
          9,
          reason: name,
        );
      }
      expect(
        document.lineOfLocation(
          const EpubLocation(chapter: 'h2.xhtml', line: 0),
        ),
        isNull,
      );
    });
  });

  group('the block marks of a book are placed once per change', () {
    test('the same marks of the same book are the same answer', () {
      final document = _book();
      final marks = [_mark('OEBPS/Text/ch2.xhtml', 3)];
      final cache = EpubBlockMarksCache();
      final first = cache.of(document, marks);
      expect(first.single.line, 11);
      expect(identical(cache.of(document, marks), first), isTrue);
    });

    test('other marks, or another book, are placed again', () {
      final document = _book();
      final cache = EpubBlockMarksCache();
      final first = cache.of(document, [_mark('OEBPS/Text/ch1.xhtml', 1)]);
      expect(first.single.line, 1);
      final second = cache.of(document, [_mark('OEBPS/Text/ch2.xhtml', 1)]);
      expect(second.single.line, 9);
      final marks = [_mark('OEBPS/Text/ch1.xhtml', 2)];
      expect(cache.of(document, marks).single.line, 2);
      final other = _book();
      expect(identical(cache.of(other, marks), cache.of(other, marks)), isTrue);
      expect(cache.of(other, marks).single.line, 2);
    });
  });
}
