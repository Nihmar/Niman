// The paper a PDF export is printed on (#1285): the sizes offered, the
// sheet a printer is told, the page's `@page` rule, and how a size reads in
// the settings.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/paper_size.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  tearDown(AppLanguages.reset);

  test('the sizes offered, A4 the default and the fallback', () {
    expect(PaperSize.values.map((size) => size.name), [
      'a0',
      'a1',
      'a2',
      'a3',
      'a4',
      'a5',
      'letter',
      'legal',
      'tabloid',
    ]);
    expect(PaperSize.fromName('letter'), PaperSize.letter);
    expect(PaperSize.fromName('b5'), PaperSize.a4);
    expect(PaperSize.fromName(null), PaperSize.a4);
  });

  test('every size stands up: its short side first', () {
    for (final size in PaperSize.values) {
      expect(size.widthMm, lessThan(size.heightMm), reason: size.name);
    }
    expect(PaperSize.a0.widthMm * PaperSize.a0.heightMm, closeTo(1e6, 1e4));
  });

  test('a sheet is told by its sides as it lies, in points', () {
    const letter = PdfPaper(PaperSize.letter);
    expect(letter.name, 'portrait');
    expect(letter.widthPt, closeTo(612, 0.01));
    expect(letter.heightPt, closeTo(792, 0.01));
    final side = letter.onItsSide;
    expect(side.name, 'landscape');
    expect(side.widthPt, closeTo(792, 0.01));
    expect(side.cssSize, '279.4mm 215.9mm');
    expect(PdfPaper.a4.cssSize, '210mm 297mm');
    expect(PdfPaper.slides.name, 'slides');
    // A sheet is its size and its way, however it was made.
    expect(PdfPaper(PaperSize.fromName('a4')), PdfPaper.a4);
    expect(PdfPaper.a4, isNot(PdfPaper.a4Landscape));
  });

  test("a page asks for the paper picked, A4's own rule left alone", () {
    String page(PaperSize paper) =>
        htmlPage(title: 't', body: '<p>x</p>', paper: paper);
    expect(page(PaperSize.a4), isNot(contains('@media print { @page { size')));
    expect(
      page(PaperSize.letter),
      contains('@media print { @page { size: 215.9mm 279.4mm; } }'),
    );
  });

  test('a size reads with its sides, in its own units', () {
    expect(AppStrings.paperSizeName(PaperSize.a4), 'A4 · 210 × 297 mm');
    expect(AppStrings.paperSizeName(PaperSize.letter), 'Letter · 8.5 × 11 in');
    expect(AppStrings.paperSizeName(PaperSize.legal), 'Legal · 8.5 × 14 in');
    expect(AppStrings.paperSizeName(PaperSize.tabloid), 'Tabloid · 11 × 17 in');
  });

  test("and in the language's decimal separator", () {
    AppLanguages.choice = AppLanguage.italian;
    expect(AppStrings.paperSizeName(PaperSize.letter), 'Letter · 8,5 × 11 in');
  });
}
