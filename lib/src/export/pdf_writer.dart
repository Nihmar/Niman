/// Writing a PDF of page pictures (#63).
///
/// The raster fallback has no text to place: each page is an image, and
/// this writes those images into a PDF of A4 pages — one image per page,
/// each fitted into the page's content box. Nothing but `dart:io`'s zlib
/// is needed: an image XObject holds Flate-compressed RGB, the content
/// stream draws it, and a cross-reference table ends the file.
///
/// Pages go in one at a time ([PdfWriter.addPage]): the raster fallback's
/// pages are megabytes each, and a novel's worth of them must not be held
/// while the file is assembled — the file being built plus one page is the
/// ceiling (M6).
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
  final writer = PdfWriter(
    pageWidth: pageWidth,
    pageHeight: pageHeight,
    margin: margin,
  );
  pages.forEach(writer.addPage);
  return writer.finish();
}

/// A PDF taking shape, one page picture at a time.
///
/// The page tree is written last, when the page count is known; object
/// numbers still start at 3, so the tree can point at pages that are
/// already in the file.
final class PdfWriter {
  /// Creates a writer of A4 pages with [margin] points on every side.
  new({this.pageWidth = a4Width, this.pageHeight = a4Height, this.margin = 0});

  /// The page's width in PDF points.
  final double pageWidth;

  /// The page's height in PDF points.
  final double pageHeight;

  /// The content box's margin, in PDF points.
  final double margin;

  final BytesBuilder _out = BytesBuilder();
  final List<int> _offsets = <int>[];
  int _pages = 0;
  bool _started = false;
  bool _finished = false;

  void _write(String text) => _out.add(utf8.encode(text));

  void _begin(int number) {
    _offsets.add(_out.length);
    _write('$number 0 obj\n');
  }

  /// Appends [page] as its own PDF page.
  void addPage(PdfPageImage page) {
    if (_finished) throw StateError('the PDF is already finished');
    _start();
    final content = (
      left: margin,
      bottom: margin,
      width: pageWidth - 2 * margin,
      height: pageHeight - 2 * margin,
    );
    final pageObject = 3 + _pages * 3;
    final contentObject = pageObject + 1;
    final imageObject = pageObject + 2;
    final scale = _fit(page, content.width, content.height);
    final x = content.left + (content.width - page.width * scale) / 2;
    final y = content.bottom + (content.height - page.height * scale) / 2;
    final drawn = utf8.encode(
      'q ${_number(page.width * scale)} 0 0 ${_number(page.height * scale)} '
      '${_number(x)} ${_number(y)} cm /Im0 Do Q\n',
    );

    _begin(pageObject);
    _write(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 '
      '${_number(pageWidth)} ${_number(pageHeight)}] '
      '/Resources << /XObject << /Im0 $imageObject 0 R >> >> '
      '/Contents $contentObject 0 R >>\nendobj\n',
    );
    _begin(contentObject);
    _write('<< /Length ${drawn.length} >>\nstream\n');
    _out.add(drawn);
    _write('\nendstream\nendobj\n');
    _begin(imageObject);
    // Compressed here, so the page's pixels are megabytes for as long as
    // this call, not until the file ends.
    final compressed = Uint8List.fromList(ZLibCodec().encode(page.rgb));
    _write(
      '<< /Type /XObject /Subtype /Image /Width ${page.width} '
      '/Height ${page.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 '
      '/Filter /FlateDecode /Length ${compressed.length} >>\nstream\n',
    );
    _out.add(compressed);
    _write('\nendstream\nendobj\n');
    _pages++;
  }

  /// The file's bytes: the page tree, the cross-reference table and the
  /// trailer.
  Uint8List finish() {
    if (_finished) throw StateError('the PDF is already finished');
    _start();
    _begin(2);
    _write('<< /Type /Pages /Kids [');
    for (var at = 0; at < _pages; at++) {
      _write('${3 + at * 3} 0 R ');
    }
    _write('] /Count $_pages >>\nendobj\n');

    final startxref = _out.length;
    _write('xref\n0 ${_offsets.length + 1}\n');
    _write('0000000000 65535 f \n');
    for (final offset in _offsets) {
      _write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    _write(
      'trailer\n<< /Size ${_offsets.length + 1} /Root 1 0 R >>\n'
      'startxref\n$startxref\n%%EOF\n',
    );
    _finished = true;
    return _out.takeBytes();
  }

  /// Writes what a PDF starts with, once.
  void _start() {
    if (_started) return;
    _started = true;
    _write('%PDF-1.4\n');
    // The bytes a PDF reader uses to know the file is binary.
    _out.add(<int>[0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);
    // 1: the catalog, 2: the page tree (written by `finish`), then a page,
    // its content and its image per picture.
    _begin(1);
    _write('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
  }
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
