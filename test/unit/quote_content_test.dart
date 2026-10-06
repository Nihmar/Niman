// A quote's content as the tree reads it, for `live`: the blocks the read
// view draws a quote's lines as (`quote_content.dart`,
// `live_quote_content.dart`).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What line [line] of [text], a quote, is inside it: its block's kind and
/// its index in the content, or null.
(BlockKind, int)? _inside(String text, int line) {
  final buffer = SourceBuffer.fromText(text);
  final quote = BlockScanner(buffer).index.blocks.first;
  final quoted = LiveQuoteContent().of(line, quote, buffer);
  return quoted == null ? null : (quoted.block.kind, quoted.line);
}

void main() {
  test("a callout's body is read without its title, as the read view's", () {
    // Four spaces after the title: code in the callout, as the tree reads
    // it. Read with the title, it went on the title's paragraph lazily.
    const note = '> [!note] Title\n>     code';
    expect(_inside(note, 0), isNull, reason: 'the title is no block of it');
    expect(_inside(note, 1), (BlockKind.indentedCode, 0));
    final buffer = SourceBuffer.fromText(note);
    final quote = BlockScanner(buffer).index.blocks.first;
    expect(LiveQuoteContent().calloutOf(quote, buffer)?.type, 'note');
  });

  test('a quote is a quote, and the one inside it is read again', () {
    const note = '> a\n>\n> > # h\n> > - i';
    expect(_inside(note, 0), (BlockKind.paragraph, 0));
    expect(_inside(note, 2), (BlockKind.heading, 0));
    expect(_inside(note, 3), (BlockKind.listItem, 1));
    final buffer = SourceBuffer.fromText(note);
    final quote = BlockScanner(buffer).index.blocks.first;
    expect(LiveQuoteContent().calloutOf(quote, buffer), isNull);
  });

  test("a tab's columns past a quote's mark stay the content's", () {
    // `>` takes one column of the tab; the other two and the next tab
    // make the line code, `  b`, as the read view draws it.
    expect(_inside('>\t\tb', 0), (BlockKind.indentedCode, 0));
  });
}
