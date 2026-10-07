import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/ocr/ocr_tree_order.dart';

void main() {
  List<String> nested(List<String> names) => [
    for (final (name, under) in nestOcrSidecars(names, (n) => n))
      '${under ? '  ' : ''}$name',
  ];

  test('a sidecar moves under its file', () {
    expect(nested(['a.md', 'scan.ocr.md', 'scan.pdf', 'z.md']), [
      'a.md',
      'scan.pdf',
      '  scan.ocr.md',
      'z.md',
    ]);
  });

  test('a picture, and the full-name sidecar of a shared stem', () {
    expect(
      nested([
        'board.jpg',
        'board.ocr.md',
        'scan.jpg',
        'scan.pdf',
        'scan.pdf.ocr.md',
      ]),
      [
        'board.jpg',
        '  board.ocr.md',
        'scan.jpg',
        'scan.pdf',
        '  scan.pdf.ocr.md',
      ],
    );
  });

  test('a sidecar with no file beside it, or beside a note, stays put', () {
    expect(nested(['notes.md', 'notes.ocr.md', 'lost.ocr.md']), [
      'notes.md',
      'notes.ocr.md',
      'lost.ocr.md',
    ]);
  });
}
