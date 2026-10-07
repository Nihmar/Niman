import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_line.dart';
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

  final date = DateTime(2026, 10, 7);

  test('a PDF: frontmatter, a section per page, a box per line', () {
    final text = ocrSidecarText(
      fileName: 'Contratto 2019 (scan).pdf',
      languages: 'ita+eng',
      date: date,
      paged: true,
      pages: {
        2: [line('Second page', 0.2, paragraph: true)],
        1: [
          line('First line', 0.1, paragraph: true),
          line('goes on', 0.14),
          line('New paragraph', 0.3, paragraph: true),
        ],
      },
    );
    expect(text, '''
---
ocr: "[[Contratto 2019 (scan).pdf]]"
language: ita+eng
recognized: 2026-10-07
---

## p. 1

First line <!-- ocr 0.100 0.100 0.900 0.130 -->
goes on <!-- ocr 0.100 0.140 0.900 0.170 -->

New paragraph <!-- ocr 0.100 0.300 0.900 0.330 -->

## p. 2

Second page <!-- ocr 0.100 0.200 0.900 0.230 -->
''');
  });

  test('what a scan reads as syntax stays words', () {
    final text = ocrSidecarText(
      fileName: 'a.png',
      languages: 'eng',
      date: date,
      paged: false,
      pages: {
        1: [
          line('# Total [[x]] <!-- y', 0.1, paragraph: true),
          line('- 3 items', 0.2),
          line('1. first', 0.3),
        ],
      },
    );
    expect(text, contains(r'\# Total \[\[x\]\] \<\!-- y <!-- ocr'));
    expect(text, contains('\n\\- 3 items <!-- ocr'));
    expect(text, contains('\n1\\. first <!-- ocr'));
    expect(text, isNot(contains('## p.')));
  });

  test('a page recognized again replaces only its own section', () {
    final first = ocrSidecarText(
      fileName: 'scan.pdf',
      languages: 'ita',
      date: date,
      paged: true,
      pages: {
        1: [line('one', 0.1, paragraph: true)],
        2: [line('two', 0.1, paragraph: true)],
      },
    );
    final corrected = first.replaceFirst('one <!--', 'ONE, by hand <!--');
    final merged = mergeOcrSidecar(corrected, {
      2: [line('two again', 0.1, paragraph: true)],
      4: [line('four', 0.1, paragraph: true)],
    }, paged: true);
    expect(merged, contains('ONE, by hand'));
    expect(merged, contains('two again'));
    expect(merged, isNot(contains('\ntwo <!--')));
    expect(RegExp(r'## p. (\d)').allMatches(merged).map((m) => m[1]).toList(), [
      '1',
      '2',
      '4',
    ]);
    expect(merged, startsWith('---\nocr: "[[scan.pdf]]"'));
  });

  test("a picture's text is replaced under its frontmatter", () {
    final first = ocrSidecarText(
      fileName: 'board.jpg',
      languages: 'ita',
      date: date,
      paged: false,
      pages: {
        1: [line('old', 0.1, paragraph: true)],
      },
    ).replaceFirst('language: ita', 'language: ita\ntags: [work]');
    final merged = mergeOcrSidecar(first, {
      1: [line('new', 0.1, paragraph: true)],
    }, paged: false);
    expect(merged, contains('tags: [work]'));
    expect(merged, contains('new <!-- ocr'));
    expect(merged, isNot(contains('old')));
  });

  test('a page with no text keeps its heading', () {
    final text = ocrSidecarText(
      fileName: 's.pdf',
      languages: 'eng',
      date: date,
      paged: true,
      pages: {1: const []},
    );
    expect(text, endsWith('---\n\n## p. 1\n'));
  });

  test('names and counts', () {
    expect(
      ocrSidecarName('Contratto 2019 (scan).pdf'),
      'Contratto 2019 (scan).ocr',
    );
    expect(ocrSidecarName('Lavagna 12-03.jpg'), 'Lavagna 12-03.ocr');
    expect(
      ocrWordCount({
        1: [line('Il contratto  scade', 0.1)],
        2: [line('oggi', 0.1)],
      }),
      4,
    );
  });
}
