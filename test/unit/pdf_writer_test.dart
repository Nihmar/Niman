// The PDF writer of the raster fallback (#63): page pictures in, a PDF
// whose image streams read back as the pixels that went in.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/pdf_writer.dart';

Uint8List _rgb(int seed) => Uint8List.fromList(<int>[
  seed,
  seed + 1,
  seed + 2,
  seed + 3,
  seed + 4,
  seed + 5,
  seed + 6,
  seed + 7,
  seed + 8,
  seed + 9,
  seed + 10,
  seed + 11,
]);

int _indexOf(Uint8List haystack, List<int> needle, int from) {
  outer:
  for (var at = from; at + needle.length <= haystack.length; at++) {
    for (var i = 0; i < needle.length; i++) {
      if (haystack[at + i] != needle[i]) continue outer;
    }
    return at;
  }
  return -1;
}

/// Every `stream` body, raw, in file order.
List<Uint8List> _streamBodies(Uint8List pdf) {
  const open = <int>[0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x0A]; // 'stream\n'
  const close = <int>[
    0x0A,
    0x65,
    0x6E,
    0x64,
    0x73,
    0x74,
    0x72,
    0x65,
    0x61,
    0x6D,
  ];
  final out = <Uint8List>[];
  var at = 0;
  while (true) {
    final start = _indexOf(pdf, open, at);
    if (start < 0) break;
    final end = _indexOf(pdf, close, start);
    out.add(pdf.sublist(start + open.length, end));
    at = end + close.length;
  }
  return out;
}

/// [bodies] that inflate: the image streams. The content streams are
/// plain text and are left out.
List<Uint8List> _images(List<Uint8List> bodies) {
  final out = <Uint8List>[];
  for (final body in bodies) {
    try {
      out.add(Uint8List.fromList(ZLibCodec().decode(body)));
    } on FormatException {
      // Not a flate stream: a content stream, which is plain text.
    }
  }
  return out;
}

void main() {
  test('the file is a PDF with a page and an image per picture', () {
    final first = PdfPageImage(width: 2, height: 2, rgb: _rgb(10));
    final second = PdfPageImage(width: 2, height: 2, rgb: _rgb(100));
    final pdf = writePdf(<PdfPageImage>[first, second]);

    expect(latin1.decode(pdf.sublist(0, 8)), '%PDF-1.4');
    final text = latin1.decode(pdf);
    expect(text, contains('/Type /Catalog'));
    expect(text, contains('/Count 2'));
    expect(text, contains('xref'));
    expect(text, contains('%%EOF'));

    // The two images come back as the pixels that went in, and each page
    // draws its own.
    final bodies = _streamBodies(pdf);
    final images = _images(bodies);
    expect(images, hasLength(2));
    expect(images.any((s) => listEquals(s, first.rgb)), isTrue);
    expect(images.any((s) => listEquals(s, second.rgb)), isTrue);
    expect(
      bodies.where((s) => ascii.decode(s, allowInvalid: true).contains('Do')),
      hasLength(2),
    );
  });

  test('an image is fitted into the content box, not stretched', () {
    // A wide picture in a square content box is limited by the width.
    final wide = PdfPageImage(width: 4, height: 2, rgb: Uint8List(24));
    final pdf = writePdf(
      <PdfPageImage>[wide],
      pageWidth: 200,
      pageHeight: 200,
      margin: 10,
    );
    final content = _streamBodies(pdf)
        .firstWhere((s) => ascii.decode(s, allowInvalid: true).contains('cm'));
    final line = ascii.decode(content);
    expect(line, contains('q 180 0 0 90 10 55 cm'));
    // The page is the one that was asked for, in the writer's own unit.
    expect(latin1.decode(pdf), contains('/MediaBox [0 0 200 200]'));
  });
}
