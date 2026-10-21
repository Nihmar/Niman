// Planning and rendering a book of thousands of files (#1138): every link
// and every contents entry asked which note holds its line, every sibling
// its number, every entry whether it opens a file - each was a walk of the
// whole book, so the plan took the square of its size.
//
// The book is read once outside the clock; what is timed is the plan and
// the text of every note and of index.md. Measured on this host 2026-10-21:
// 527 ms with the walks, 84 ms without. The bar sits above the second.
//
// Every run holds it to ten times the bar, a backstop the hardware cannot
// fail; NIMAN_PERF=1 to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print, missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/epub/epub_convert_render.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  const bar = 250;
  const files = 6000;

  test('a book of $files files is planned and rendered within its bar', () {
    final tmp = Directory.systemTemp.createTempSync('niman_epub_perf_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final source = writeTestEpub(
      p.join(tmp.path, 'big.epub'),
      title: 'Big',
      chapters: [
        for (var i = 0; i < files; i++)
          (
            path: 'c$i.xhtml',
            body:
                '<h1>Chapter $i</h1><p>Text of $i, '
                '<a href="c${(i * 7) % files}.xhtml">far</a> and '
                '<a href="c${(i + 1) % files}.xhtml#next">near</a>.</p>'
                '<h2 id="next">Next $i</h2><p>More.</p>',
          ),
      ],
      nav:
          '<ol>${[for (var i = 0; i < files; i++) '<li><a href="c$i.xhtml">Chapter $i</a></li>'].join()}</ol>',
    );
    final input = InputFileStream(source.path);
    addTearDown(input.closeSync);
    final book = parseEpub(EpubArchive.open(input));
    expect(book.links, hasLength(files * 2));

    var best = 1 << 62;
    for (var round = 0; round < 3; round++) {
      final watch = Stopwatch()..start();
      final plan = EpubPlan.of(book, title: 'Big', words: _words);
      final written = [
        for (final note in plan.notes)
          if (noteBody(plan, note).trim().isNotEmpty) note,
      ];
      var length = 0;
      for (final note in written) {
        length += renderNote(
          plan,
          note,
          written,
          pictureAt: (_) => null,
        ).length;
      }
      length += renderIndex(plan, written, words: _words).length;
      if (watch.elapsedMilliseconds < best) best = watch.elapsedMilliseconds;
      expect(written, hasLength(files));
      expect(length, greaterThan(files));
    }
    print(
      '$files files, ${files * 2} links, $files contents entries: '
      '$best ms (bar $bar ms${measured ? '' : ', held to ten times it'})',
    );
    expect(best, lessThan(measured ? bar : bar * 10));
  });
}
