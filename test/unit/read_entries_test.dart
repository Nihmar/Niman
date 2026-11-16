// The read view draws the top of a long note while the whole of it is
// scanned, and the whole of it then takes the top's place keeping the heights
// its frames measured — but only for the blocks the whole note's definitions
// draw as the top's did.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/render/read_entries.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Twenty paragraphs of prose, the second citing [cite] when there is one,
/// and [definitions] at the end of the note. The blank line after each is
/// a block of its own: the second paragraph is block 2.
SourceBuffer _note({String? cite, String definitions = ''}) {
  final text = StringBuffer();
  for (var at = 0; at < 20; at++) {
    text
      ..write('Paragraph $at goes on for a while')
      ..writeln(at == 1 && cite != null ? ' $cite.' : '.')
      ..writeln();
  }
  text.write(definitions);
  return SourceBuffer.fromText(text.toString());
}

/// The entries of [buffer]'s top, every block measured, then of the whole
/// of it.
ReadEntries _shownWhole(SourceBuffer buffer) {
  final entries = ReadEntries();
  final top = DocumentScan.head(buffer, 10);
  entries.show(buffer, top);
  final heights = entries.heights!;
  for (var at = 0; at < entries.blocks.length; at++) {
    heights.measured(at, 100);
  }
  entries.show(
    buffer,
    DocumentScan.of(buffer),
    keepTop: true,
    topScope: top.scope,
  );
  return entries;
}

void main() {
  test('the whole note keeps every height the top measured, when its '
      'definitions are the same', () {
    final entries = _shownWhole(_note(cite: '[see this]'));
    final heights = entries.heights!;
    expect(heights.isMeasured(0), isTrue);
    expect(heights.isMeasured(2), isTrue);
    expect(heights.isMeasured(4), isTrue);
  });

  test('a block citing a footnote defined further down is measured anew', () {
    final entries = _shownWhole(
      _note(cite: '[^1]', definitions: '[^1]: A note at the end.\n'),
    );
    final heights = entries.heights!;
    expect(heights.isMeasured(0), isTrue);
    expect(heights.isMeasured(2), isFalse, reason: 'it reads as a citation');
    expect(heights.isMeasured(4), isTrue);
  });

  test('a block citing a link defined further down is measured anew', () {
    final entries = _shownWhole(
      _note(cite: '[the source]', definitions: '[the source]: https://x.y\n'),
    );
    final heights = entries.heights!;
    expect(heights.isMeasured(2), isFalse, reason: 'it reads as a link');
    expect(heights.isMeasured(4), isTrue);
  });
}
