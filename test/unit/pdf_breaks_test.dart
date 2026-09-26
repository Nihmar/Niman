// Where the raster fallback's pages end (#63): a page's break falls
// between two lines of text, not through one.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/pdf_breaks.dart';

void main() {
  test("a break inside a line moves up to that line's head", () {
    // Three lines, 10 tall each with a 2-point gap: the page's nominal edge
    // at 20 falls inside the line that runs 12..22.
    final breaks = rasterBreaks(
      total: 40,
      spans: const <(double, double)>[(0, 10), (12, 22), (24, 34)],
      contentHeight: 20,
    );
    expect(breaks, <double>[0, 12, 24, 40]);
  });

  test('a line taller than a page is cut: there is nowhere to break', () {
    final breaks = rasterBreaks(
      total: 100,
      spans: const <(double, double)>[(0, 60)],
      contentHeight: 50,
    );
    expect(breaks, <double>[0, 50, 100]);
  });

  test('spans that overlap are one, so a break clears both', () {
    // The line 4..20 and something drawn inside it (a formula, a mark):
    // a break below the inner span is still inside the outer one.
    final breaks = rasterBreaks(
      total: 40,
      spans: const <(double, double)>[(4, 20), (8, 12)],
      contentHeight: 15,
    );
    expect(breaks.first, 0);
    expect(breaks[1], 4, reason: 'the break ends above the line, not in it');
  });

  test('a break just below a span is kept where it is', () {
    final breaks = rasterBreaks(
      total: 30,
      spans: const <(double, double)>[(0, 10), (20, 30)],
      contentHeight: 15,
    );
    expect(breaks, <double>[0, 15, 30]);
  });

  test("the last break is the note's own end", () {
    final breaks = rasterBreaks(
      total: 25,
      spans: const <(double, double)>[(0, 10)],
      contentHeight: 20,
    );
    expect(breaks.last, 25);
    expect(breaks, orderedEquals(<double>[0, 20, 25]));
  });

  test('a note that lays out to nothing still takes a page', () {
    // A zero-height capture is an empty image on some backends and an error
    // on others, and a PDF wants a page (P5).
    expect(
      rasterBreaks(
        total: 0,
        spans: const <(double, double)>[],
        contentHeight: 100,
      ),
      <double>[0, 100],
    );
  });
}
