// A book's marks in the reader (#1306): every highlight in the last chapter
// of a book counted the line breaks of the whole text to find where that
// chapter ends, and the pane placed every mark again on every build - each
// sentence read aloud, each step of the text-size slider.
//
// The book is built in memory outside the clock (~2 MB, 200 chapters, 300
// highlights in the last one); what is timed is placing the marks, the work
// of one build. Measured on this host 2026-11-26: 719 ms with the count
// (the issue's figure), 1.7 ms without. The bar sits above the second.
//
// Every run holds it to ten times the bar, a backstop the hardware cannot
// fail; NIMAN_PERF=1 to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_marks.dart';
import 'package:niman/src/epub/epub_progress.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/reading/book_location.dart';

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  const bar = 10;
  const chapterCount = 200;
  const marksCount = 300;

  test('$marksCount marks in the last chapter of a 2 MB book are placed '
      'within their bar', () {
    final lines = <String>[];
    final chapters = <EpubChapter>[];
    for (var c = 0; c < chapterCount; c++) {
      if (lines.isNotEmpty) lines.addAll(['', '---', '']);
      chapters.add((file: 'OEBPS/ch$c.xhtml', line: lines.length));
      for (var l = 0; l < 160; l++) {
        lines.add('Chapter $c, paragraph $l: ${'lorem ipsum ' * 6}');
      }
    }
    final markdown = '${lines.join('\n')}\n';
    expect(markdown.length, greaterThan(1800000));
    final document = EpubDocument(
      title: 'Big',
      markdown: markdown,
      lineCount: lines.length,
      contents: const [],
      pictures: const {},
      links: const [],
      chapters: chapters,
      counts: EpubCounts.of(markdown),
    );
    final marks = [
      for (var i = 0; i < marksCount; i++)
        AnnotationMark(
          note: 'Big.md',
          offset: i,
          place: EpubLocation(
            chapter: chapters.last.file,
            line: i % 160,
            chars: (start: 0, end: 5),
          ),
          highlight: HighlightColour.yellow,
        ),
    ];

    var best = 1 << 62;
    for (var round = 0; round < 3; round++) {
      final watch = Stopwatch()..start();
      final blocks = epubBlockMarks(document, marks);
      best = best < watch.elapsedMicroseconds
          ? best
          : watch.elapsedMicroseconds;
      expect(blocks, hasLength(marksCount));
      expect(blocks.first.line, chapters.last.line);
    }
    final ms = best / 1000;
    print(
      'epub marks: $marksCount marks, last of $chapterCount chapters: '
      '${ms.toStringAsFixed(2)} ms (bar $bar ms'
      '${measured ? '' : ', not enforced'})',
    );
    expect(ms, lessThan(measured ? bar : bar * 10));
  });
}
