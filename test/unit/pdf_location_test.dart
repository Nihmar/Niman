// A PDF's place is its page and how far down it (#281), read from where
// the view's top is in the pages laid out one under the other.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/ui/pdf_document_view.dart';

void main() {
  // Three pages 100 tall, a gap of 10 between them.
  const pages = [
    Rect.fromLTWH(0, 0, 80, 100),
    Rect.fromLTWH(0, 110, 80, 100),
    Rect.fromLTWH(0, 220, 80, 100),
  ];

  test('the page the top is on, and how far down it', () {
    expect(pdfLocationAt(pages, 0), const PdfLocation(page: 1));
    expect(
      pdfLocationAt(pages, 160),
      const PdfLocation(page: 2, fraction: 0.5),
    );
  });

  test('a top in the gap is the next page, at its top', () {
    expect(pdfLocationAt(pages, 105), const PdfLocation(page: 2));
  });

  test('a top past the last page is its bottom; no pages is no place', () {
    expect(pdfLocationAt(pages, 400), const PdfLocation(page: 3, fraction: 1));
    expect(pdfLocationAt(const [], 0), isNull);
  });
}
