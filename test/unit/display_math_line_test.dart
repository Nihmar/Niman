// What a line that starts with `$$` is (#1371): a block when it is the formula
// alone or opens one it does not close, and a paragraph with the formula in it
// when it closes on its own line and goes on with text, as the same text
// mid-line is.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The kind and range of each block of [text].
List<String> _blocks(String text) => [
  for (final block in BlockScanner(SourceBuffer.fromText(text)).index.blocks)
    '${block.kind.name} ${block.startLine}-${block.endLine}',
];

void main() {
  group('the line', () {
    for (final (text, display, open) in [
      (r'$$', true, true),
      (r'$$x$$', true, false),
      (r'$$ x $$', true, false),
      (r'$$x$$ tail', false, false),
      (r'$$x$$ tail $$', true, false),
      (r'$$5 off', true, true),
      (r'$$x', true, true),
      (r'$$$$', true, false),
      (r'$x$ and $$', false, false),
    ]) {
      test(text, () {
        expect(isDisplayLine(text), display);
        expect(isDisplayOpen(text), open);
      });
    }
  });

  group('the block structure', () {
    test(r'`$$x$$ tail` is a paragraph, and the lines after it are free', () {
      expect(_blocks('\$\$x\$\$ tail\n*em*'), ['paragraph 0-2']);
      expect(_blocks('\$\$x\$\$ tail\n\nnext'), [
        'paragraph 0-1',
        'blank 1-2',
        'paragraph 2-3',
      ]);
    });

    test(r'an open block is still closed by a line that starts with `$$`', () {
      // The closer is any line that starts with `$$`, tail or no tail.
      expect(_blocks('\$\$\na\n\$\$x\$\$ tail\nb'), [
        'math 0-3',
        'paragraph 3-4',
      ]);
    });

    test('the formula alone is a block of one line', () {
      expect(_blocks('\$\$x\$\$\ntext'), ['math 0-1', 'paragraph 1-2']);
    });

    test(r'`$$5 off` opens a block that runs to the next `$$` line', () {
      expect(_blocks('\$\$5 off\n*em*\n\$\$\nafter'), [
        'math 0-3',
        'paragraph 3-4',
      ]);
      expect(_blocks('\$\$5 off\nrest'), ['math 0-2']);
    });

    test(r'`$$` alone opens one', () {
      expect(_blocks('\$\$\nx\n\$\$'), ['math 0-3']);
    });

    test('in a quote and an item', () {
      expect(_blocks('> \$\$x\$\$ tail\n> *em*'), ['quote 0-2']);
      final html = TreeHtml('> \$\$x\$\$ tail\n> *em*').render();
      expect(html, contains('<em>em</em>'));
      expect(_blocks('- \$\$x\$\$ tail\n  *em*').first, startsWith('listItem'));
    });
  });

  test('the read view: the tail is text, the lines after it are read', () {
    final html = TreeHtml('\$\$x\$\$ tail\n*em*').render();
    expect(html, contains('<em>em</em>'));
    expect(html, contains('tail'));
    expect(BlockKind.values, contains(BlockKind.math));
  });
}
