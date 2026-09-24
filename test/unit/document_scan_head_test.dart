// The top of a note, scanned alone while the whole is scanned in the
// background: its blocks are the whole note's, and it ends between blocks.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/source_buffer.dart';

void main() {
  final note = StringBuffer();
  for (var at = 0; at < 200; at++) {
    note
      ..writeln('# Section $at')
      ..writeln()
      ..writeln('A paragraph of section $at,')
      ..writeln('on two lines.')
      ..writeln()
      ..writeln('```')
      ..writeln('code $at')
      ..writeln('```')
      ..writeln();
  }
  final buffer = SourceBuffer.fromText(note.toString());
  final whole = DocumentScan.of(buffer);

  String shape(DocumentScan scan, int count) => [
    for (final block in scan.blocks.take(count))
      '${block.kind.name} ${block.startLine}-${block.endLine}',
  ].join(', ');

  for (final lines in [1, 3, 7, 50, 333]) {
    test('the top of $lines lines is the whole note, as far as it goes', () {
      final head = DocumentScan.head(buffer, lines);
      final last = head.blocks.last;
      // Cut at a blank line at or past the lines asked for, so no block of
      // the top is a piece of a longer one — the open fence included.
      expect(last.endLine, greaterThanOrEqualTo(lines));
      final kept = head.blocks.where((b) => b.endLine <= last.endLine).length;
      expect(shape(head, kept), shape(whole, kept));
      expect(head.revision, buffer.revision);
    });
  }

  test('a top longer than the note is the note', () {
    final head = DocumentScan.head(buffer, 1 << 20);
    expect(shape(head, whole.blocks.length), shape(whole, whole.blocks.length));
  });

  test('the definitions of the top are the ones above its cut', () {
    final withDefinitions = SourceBuffer.fromText(
      'See [a] and [b].\n\n[a]: https://a.test\n\n'
      '${'filler\n\n' * 50}[b]: https://b.test\n',
    );
    final head = DocumentScan.head(withDefinitions, 5);
    expect(head.scope.links.keys, ['a']);
    expect(identical(head.scope.source, withDefinitions), isTrue);
  });
}
