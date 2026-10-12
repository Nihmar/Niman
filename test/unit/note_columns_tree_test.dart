// The note's columns as the scanner and the tree read them (#729,
// `docs/records/note-columns.md`): Pandoc's fenced divs, in every context
// blocks are read in.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// [nodes] written out: `cols[…|…]` a `columns` div and its columns, `c[…]`
/// a column (`c40%` with a width, `i` an implicit one, `…` after one that
/// runs to its container's end), `Q`, `F`, `ul`, `-` as in
/// `block_tree_test`, and a leaf as its kind and its text.
String _shape(String text, List<BlockNode> nodes) {
  final lines = text.split('\n');
  String spanned(List<SourceSpan> spans) =>
      spans.map((s) => lines[s.line].substring(s.start, s.end)).join('/');
  String of(BlockNode node) => switch (node) {
    QuoteNode(:final children, :final callout) =>
      '${callout == null ? 'Q' : 'C:${callout.type}'}'
          '[${children.map(of).join(' ')}]',
    FootnoteNode(:final label, :final children) =>
      'F$label[${children.map(of).join(' ')}]',
    ListNode(:final items, :final ordered, :final start) =>
      '${ordered ? 'ol$start' : 'ul'}[${items.map(of).join(' ')}]',
    ItemNode(:final delimiter, :final children) =>
      '$delimiter[${children.map(of).join(' ')}]',
    ColumnsNode(:final columns, :final closer) =>
      'cols${closer == null ? '…' : ''}[${columns.map(of).join(' | ')}]',
    ColumnNode(:final children, :final width, :final implicit, :final closer) =>
      '${implicit ? 'i' : 'c'}${width == null ? '' : '${width.round()}%'}'
          '${!implicit && closer == null ? '…' : ''}'
          '[${children.map(of).join(' ')}]',
    LeafNode(:final kind, lines: final spans) =>
      '${kind.name}"${spanned(spans)}"',
  };
  return nodes.map(of).join(' ');
}

String _treeOf(String text, {bool appSyntax = true}) =>
    _shape(text, BlockTree.of(text, appSyntax: appSyntax));

/// Each block the scanner makes of [text]: its kind, its role when it is a
/// fence line, and how many divs it stands in.
List<String> _blocksOf(String text) => [
  for (final block in BlockScanner(SourceBuffer.fromText(text)).index.blocks)
    _described(block),
];

String _described(Block block) {
  final depth = block.divDepth > 0 ? '@${block.divDepth}' : '';
  return '${block.startLine}:${block.divRole?.name ?? block.kind.name}$depth';
}

const String _two = '''
:::: columns
::: {.column width="40%"}
Left
:::

::: column
Right
:::
::::''';

void main() {
  group('the scan', () {
    test('a fence line is a block of its own, at the depth around it', () {
      expect(_blocksOf(_two), [
        '0:opensColumns',
        '1:opensColumn@1',
        '2:paragraph@2',
        '3:closesColumn@1',
        '4:blank@1',
        '5:opensColumn@1',
        '6:paragraph@2',
        '7:closesColumn@1',
        '8:closesColumns',
      ]);
    });

    test('an opener cannot interrupt a paragraph, a closer ends one', () {
      expect(_blocksOf(':::: columns\nProse\n::: column\nmore\n::::'), [
        '0:opensColumns',
        '1:paragraph@1',
        '4:closesColumns',
      ]);
    });

    test('inside code, math, HTML and frontmatter a fence line is content', () {
      for (final (open, close) in [
        ('```', '```'),
        (r'$$', r'$$'),
        ('<div>', '</div>'),
      ]) {
        final text = ':::: columns\n$open\n:::\n::: column\n$close\n\n::::';
        expect(_blocksOf(text).first, '0:opensColumns', reason: open);
        expect(_blocksOf(text).last, '6:closesColumns', reason: open);
        expect(_blocksOf(text), isNot(contains('2:closesColumns')));
      }
      expect(_blocksOf('---\n:::: columns\n---\n:::'), [
        '0:frontmatter',
        '3:paragraph',
      ]);
    });

    test('outside columns an unknown div is text, and so is its closer', () {
      expect(_blocksOf('::: warning\nCareful.\n:::'), ['0:paragraph']);
      expect(_blocksOf('::: column\nx\n:::'), ['0:paragraph']);
      expect(_blocksOf(':::'), ['0:paragraph']);
    });

    test('inside columns an unknown div is tracked for its closer', () {
      expect(
        _blocksOf(
          ':::: columns\n::: column\n::: warning\nCareful.\n:::\n'
          'More.\n:::\n::::',
        ),
        [
          '0:opensColumns',
          '1:opensColumn@1',
          '2:opensOther@2',
          '3:paragraph@3',
          '4:closesOther@2',
          '5:paragraph@2',
          '6:closesColumn@1',
          '7:closesColumns',
        ],
      );
    });

    test("without the app's syntax a fence line is text", () {
      final scanner = BlockScanner(
        SourceBuffer.fromText(_two),
        appSyntax: false,
      );
      expect(
        scanner.index.blocks.where((b) => b.kind == BlockKind.div),
        isEmpty,
      );
    });

    test('a div opened in an item ends with it', () {
      expect(_blocksOf('- item\n\n  :::: columns\n  a\n\nafter\n:::'), [
        '0:listItem',
        '1:blank',
        '2:opensColumns',
        '3:paragraph@1',
        '4:blank@1',
        // Text, with no div open: it goes on with the paragraph.
        '5:paragraph',
      ]);
    });

    test('a closer short of an item ends it, and closes the div', () {
      expect(_blocksOf(':::: columns\n- a\n::::\nafter'), [
        '0:opensColumns',
        '1:listItem@1',
        '2:closesColumns',
        '3:paragraph',
      ]);
    });

    test('a closer ends a quote it would go on with lazily', () {
      expect(_blocksOf(':::: columns\n> a\n::::\nafter'), [
        '0:opensColumns',
        '1:quote@1',
        '2:closesColumns',
        '3:paragraph',
      ]);
    });

    test('a closer ends a table', () {
      expect(_blocksOf(':::: columns\n| a |\n|---|\n| 1 |\n::::'), [
        '0:opensColumns',
        '1:table@1',
        '4:closesColumns',
      ]);
    });

    test('an unclosed opener runs to the end of the note', () {
      expect(_blocksOf(':::: columns\na\n\n# h'), [
        '0:opensColumns',
        '1:paragraph@1',
        '2:blank@1',
        '3:heading@1',
      ]);
    });

    test('a footnote definition opens at a column margin', () {
      expect(_blocksOf(':::: columns\n[^1]: note\n::::'), [
        '0:opensColumns',
        '1:paragraph@1',
        '2:closesColumns',
      ]);
      final buffer = SourceBuffer.fromText(':::: columns\n[^1]: note\n::::');
      expect(BlockScanner(buffer).blockAt(1)!.footnote, Block.opensFootnote);
    });
  });

  group('the tree', () {
    test('two columns, one with a width', () {
      expect(
        _treeOf(_two),
        'cols[c40%[paragraph"Left"] | c[paragraph"Right"]]',
      );
    });

    test('content outside any column is an implicit column', () {
      expect(
        _treeOf(':::: columns\nfirst\n\n::: column\nx\n:::\nlast\n::::'),
        'cols[i[paragraph"first" blank""] | c[paragraph"x"] | '
        'i[paragraph"last"]]',
      );
      // Blank lines alone between columns are the gap, and no column.
      expect(_treeOf(_two), isNot(contains('i[')));
    });

    test('an unclosed opener runs to the end of the note', () {
      expect(
        _treeOf(':::: columns\n::: column\na\n\nb'),
        'cols…[c…[paragraph"a" blank"" paragraph"b"]]',
      );
    });

    test("an unknown div's fence lines are text where they stand", () {
      expect(
        _treeOf(
          ':::: columns\n::: column\n::: warning\nCareful.\n:::\n'
          'More.\n:::\n::::',
        ),
        'cols[c[paragraph"::: warning" paragraph"Careful." '
        'paragraph":::" paragraph"More."]]',
      );
      expect(
        _treeOf('::: warning\nCareful.\n:::'),
        'paragraph"::: warning/Careful./:::"',
      );
    });

    test('columns inside a column', () {
      expect(
        _treeOf(
          ':::::: columns\n::: column\n:::: columns\n::: column\nin\n:::\n'
          '::::\n:::\n::::::',
        ),
        'cols[c[cols[c[paragraph"in"]]]]',
      );
    });

    test('columns inside a quote and a callout', () {
      expect(
        _treeOf('> :::: columns\n> ::: column\n> a\n> :::\n> ::::'),
        'Q[cols[c[paragraph"a"]]]',
      );
      expect(
        _treeOf('> [!note]\n> :::: columns\n> a\n> ::::'),
        'C:note[cols[i[paragraph"a"]]]',
      );
    });

    test('columns inside a list item', () {
      expect(
        _treeOf('- item\n\n  :::: columns\n  ::: column\n  a\n  :::\n  ::::'),
        'ul[-[paragraph"item" blank"" cols[c[paragraph"a"]]]]',
      );
    });

    test('a list inside a column', () {
      expect(
        _treeOf(':::: columns\n::: column\n- a\n- b\n:::\n::::'),
        'cols[c[ul[-[paragraph"a"] -[paragraph"b"]]]]',
      );
    });

    test('a footnote definition inside a column goes to the note', () {
      expect(
        _treeOf(':::: columns\n::: column\n[^1]: note\n:::\n::::'),
        'cols[c[]] F1[paragraph"note"]',
      );
    });

    test('the read view draws a fence line as a fence leaf', () {
      final buffer = SourceBuffer.fromText(_two);
      final blocks = BlockScanner(buffer).index.blocks.toList();
      final node = BlockTree.ofBlock(blocks.first, buffer);
      expect(node, isA<LeafNode>());
      expect((node as LeafNode).kind, BlockKind.div);
    });
  });
}
