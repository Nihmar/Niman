/// Writing a PDF of page pictures (#63).
///
/// The raster fallback has no text to place: each page is an image, and
/// this writes those images into a PDF of A4 pages — one image per page,
/// each fitted into the page's content box. Nothing but `dart:io`'s zlib
/// is needed: an image XObject holds Flate-compressed RGB, the content
/// stream draws it, and a cross-reference table ends the file.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A4 in PDF points (1/72 inch).
const double a4Width = 595.276;

/// A4's height in PDF points.
const double a4Height = 841.89;

/// One page's picture: its size and its pixels, three bytes each
/// (red, green, blue), row-major from the top.
final class PdfPageImage {
  /// Creates a page picture of [width]×[height] RGB [rgb].
  const new({required this.width, required this.height, required this.rgb});

  /// The image's width in pixels.
  final int width;

  /// The image's height in pixels.
  final int height;

  /// `width * height * 3` bytes, row-major, top row first.
  final Uint8List rgb;
}

/// Writes [pages] as a PDF, each image fitted into the page's content box
/// — an A4 sheet with [margin] points on every side.
Uint8List writePdf(
  List<PdfPageImage> pages, {
  double pageWidth = a4Width,
  double pageHeight = a4Height,
  double margin = 0,
}) {
  final content = (
    left: margin,
    bottom: margin,
    width: pageWidth - 2 * margin,
    height: pageHeight - 2 * margin,
  );
  final out = BytesBuilder();
  final offsets = <int>[];
  void write(String text) => out.add(utf8.encode(text));
  void begin(int number) {
    offsets.add(out.length);
    write('$number 0 obj\n');
  }

  write('%PDF-1.4\n');
  // The bytes a PDF reader uses to know the file is binary.
  out.add(<int>[0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);

  // 1: the catalog, 2: the page tree, then a page, its content and its
  // image per picture.
  begin(1);
  write('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
  begin(2);
  write('<< /Type /Pages /Kids [');
  for (var at = 0; at < pages.length; at++) {
    write('${4 + at * 3} 0 R ');
  }
  write('] /Count ${pages.length} >>\nendobj\n');

  for (var at = 0; at < pages.length; at++) {
    final page = pages[at];
    final pageObject = 3 + at * 3;
    final contentObject = pageObject + 1;
    final imageObject = pageObject + 2;
    final scale = _fit(page, content.width, content.height);
    final x = content.left + (content.width - page.width * scale) / 2;
    final y = content.bottom + (content.height - page.height * scale) / 2;
    final drawn = utf8.encode(
      'q ${_number(page.width * scale)} 0 0 ${_number(page.height * scale)} '
      '${_number(x)} ${_number(y)} cm /Im0 Do Q\n',
    );

    begin(pageObject);
    write(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 '
      '${_number(pageWidth)} ${_number(pageHeight)}] '
      '/Resources << /XObject << /Im0 $imageObject 0 R >> >> '
      '/Contents $contentObject 0 R >>\nendobj\n',
    );
    begin(contentObject);
    write('<< /Length ${drawn.length} >>\nstream\n');
    out.add(drawn);
    write('\nendstream\nendobj\n');
    begin(imageObject);
    final compressed = Uint8List.fromList(ZLibCodec().encode(page.rgb));
    write(
      '<< /Type /XObject /Subtype /Image /Width ${page.width} '
      '/Height ${page.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 '
      '/Filter /FlateDecode /Length ${compressed.length} >>\nstream\n',
    );
    out.add(compressed);
    write('\nendstream\nendobj\n');
  }

  final startxref = out.length;
  write('xref\n0 ${offsets.length + 1}\n');
  write('0000000000 65535 f \n');
  for (final offset in offsets) {
    write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  write(
    'trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\n'
    'startxref\n$startxref\n%%EOF\n',
  );
  return out.takeBytes();
}

/// How much [page] is scaled to fit a [width]×[height] box: whole, and
/// never stretched.
double _fit(PdfPageImage page, double width, double height) {
  final byWidth = width / page.width;
  final byHeight = height / page.height;
  return byWidth < byHeight ? byWidth : byHeight;
}

/// A PDF number: at most two decimals, and no trailing `.0`.
String _number(double value) {
  final rounded = (value * 100).roundToDouble() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(2);
}
