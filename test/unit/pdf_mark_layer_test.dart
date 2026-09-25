// A PDF passage marked where it was annotated (#285): its characters in
// the page's text, one rectangle per run of text they cover.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/pdf_mark_layer.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  // Two lines of five characters each, ten points wide, the first line
  // above the second (PDF coordinates grow upwards).
  PdfPageText page() {
    final fragments = <PdfPageTextFragment>[];
    final rects = [
      for (var line = 0; line < 2; line++)
        for (var char = 0; char < 5; char++)
          PdfRect(
            char * 10.0,
            100 - line * 20.0,
            char * 10.0 + 10,
            90 - line * 20.0,
          ),
    ];
    final text = PdfPageText(
      pageNumber: 1,
      fullText: 'abcdefghij',
      charRects: rects,
      fragments: fragments,
    );
    for (var line = 0; line < 2; line++) {
      fragments.add(
        PdfPageTextFragment(
          pageText: text,
          index: line * 5,
          length: 5,
          bounds: rects.boundingRect(start: line * 5, end: line * 5 + 5),
          charRects: rects.sublist(line * 5, line * 5 + 5),
          direction: PdfTextDirection.ltr,
        ),
      );
    }
    return text;
  }

  test('a passage on one line is one rectangle', () {
    expect(passageRects(page(), 1, 3), [const PdfRect(10, 100, 30, 90)]);
  });

  test('a passage over two lines is one rectangle a line', () {
    expect(passageRects(page(), 3, 7), [
      const PdfRect(30, 100, 50, 90),
      const PdfRect(0, 80, 20, 70),
    ]);
  });

  test("characters past the page's text mark nothing past it", () {
    expect(passageRects(page(), 8, 40), [const PdfRect(30, 80, 50, 70)]);
    expect(passageRects(page(), 20, 40), isEmpty);
  });
}
