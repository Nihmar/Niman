// What a quote's line is inside the quote, for `live`: the quote's marks
// taken off as the read view takes them, and the content scanned again.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The kind of block line [line] of [text] is inside its quote, or null.
BlockKind? _inside(String text, int line) {
  final buffer = SourceBuffer.fromText(text);
  final quote = BlockScanner(buffer).blockAt(line);
  return LiveQuoteContent().of(line, quote, buffer)?.block.kind;
}

void main() {
  test('a quote at the margin is read inside its marks', () {
    expect(_inside('> # h', 0), BlockKind.heading);
    expect(_inside('> a\n> - b', 1), BlockKind.listItem);
  });

  test('a quote in a list item is read past the item and its marks', () {
    // `    > # h` is a quote in the item (content at 2): its `>` stands
    // four spaces from the margin. Counted from there, the marks stayed on,
    // and the line was read as code inside the quote.
    expect(_inside('- a\n    > # h', 1), BlockKind.heading);
    expect(_inside('  1. a\n       > b\n       > - c', 2), BlockKind.listItem);
  });
}
