import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/ocr_placed_lines.dart';
import 'package:niman/src/ocr/ocr_sidecar.dart';

void main() {
  OcrLine line(String text, double top, {bool paragraph = false}) => OcrLine(
    text,
    left: 0.1,
    top: top,
    right: 0.9,
    bottom: top + 0.03,
    paragraphStart: paragraph,
  );

  final sidecar = ocrSidecarText(
    fileName: 'scan.pdf',
    languages: 'ita+eng',
    date: DateTime(2026, 10, 7),
    paged: true,
    pages: {
      1: [
        line('# First', 0.1, paragraph: true),
        line('second', 0.15),
        line('Third', 0.4, paragraph: true),
      ],
      2: [line('Other page', 0.2, paragraph: true)],
    },
  );

  test('every line comes back with its page, box and place', () {
    final read = readOcrPlacedLines(sidecar);
    expect(read.lostByPage, isEmpty);
    expect(read.languages.map((l) => l.code), ['ita', 'eng']);
    expect(
      [for (final l in read.lines) (l.page, l.text)],
      [(1, '# First'), (1, 'second'), (1, 'Third'), (2, 'Other page')],
    );
    final rows = sidecar.split('\n');
    for (final l in read.lines) {
      expect(rows[l.sourceLine], startsWith(l.text.replaceAll('#', r'\#')));
    }
    final second = read.lines[1];
    expect(second.box.top, closeTo(0.15, 1e-9));
    // "# First " then the soft break: the second line starts after both.
    expect(second.chars, (start: 9, end: 15));
    expect(read.lines[2].chars, (start: 0, end: 5));
  });

  test('lines joined or split by hand lose their place, by page', () {
    final edited = sidecar
        // Joined: the two comments end up on one line.
        .replaceFirst('-->\nsecond', '--> second')
        .replaceFirst('Other page', 'Other\npage');
    final read = readOcrPlacedLines(edited);
    expect(read.lostByPage, {1: 1, 2: 1});
    expect(read.lines.map((l) => l.text), ['Third', 'page']);
  });

  test("a picture's sidecar is page 1", () {
    final picture = ocrSidecarText(
      fileName: 'board.png',
      languages: 'eng',
      date: DateTime(2026, 10, 7),
      paged: false,
      pages: {
        1: [line('Sprint 14', 0.1, paragraph: true)],
      },
    );
    final read = readOcrPlacedLines(picture);
    expect(read.lines.single.page, 1);
  });
}
