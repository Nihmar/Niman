// The packed chunk of blocks (#1196): every field of a block has to come back
// from it as it went in, wherever it is stored — the columns, the word of
// small fields, or the extras beside them — and a chunk moved or spliced
// must keep the fields of the blocks it did not touch.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_chunk.dart';
import 'package:niman/src/markdown/block_list.dart';
import 'package:niman/src/markdown/line_state.dart';

const LineState _inQuote = LineState(quoteDepth: 2, quoteLast: 2);
const LineState _inFence = LineState(math: true);

/// Every field of [block], so that two blocks are alike only if they are.
String _all(Block block) =>
    '${block.kind.name} ${block.startLine}..${block.endLine} '
    'quote:${block.quoteDepth} list:${block.listDepth} '
    'ordinal:${block.listOrdinal} heading:${block.headingLevel} '
    'info:${block.fenceInfo} entering:${identityHashCode(block.entering)} '
    'footnote:${block.footnote} definition:${block.definition} '
    'reach:${block.reach} role:${block.divRole?.name} '
    'div:${block.divDepth} fence:${block.holdsFence}';

/// Blocks that between them put every field at every width it has, and past
/// the one it has in the word.
List<Block> _varied() {
  var line = 0;
  Block next(
    BlockKind kind, {
    int quoteDepth = 0,
    int listDepth = -1,
    int listOrdinal = 0,
    int headingLevel = 0,
    String? fenceInfo,
    LineState? entering,
    int footnote = 0,
    int definition = 0,
    int reach = 0,
    DivRole? divRole,
    int divDepth = 0,
    bool holdsFence = false,
  }) {
    final block = Block(
      kind: kind,
      startLine: line,
      endLine: line + 3,
      quoteDepth: quoteDepth,
      listDepth: listDepth,
      listOrdinal: listOrdinal,
      headingLevel: headingLevel,
      fenceInfo: fenceInfo,
      entering: entering,
      footnote: footnote,
      definition: definition,
      reach: reach,
      divRole: divRole,
      divDepth: divDepth,
      holdsFence: holdsFence,
    );
    line += 3;
    return block;
  }

  return [
    for (final kind in BlockKind.values) next(kind),
    for (final role in DivRole.values)
      next(BlockKind.div, divRole: role, divDepth: role.index + 1),
    // The depths at the edges of their bits, and past them.
    for (final depth in [0, 1, 253, 254, 255, 256, 1000])
      next(BlockKind.quote, quoteDepth: depth, holdsFence: depth.isEven),
    for (final depth in [-1, 0, 1, 253, 254, 255, 300])
      next(BlockKind.listItem, listDepth: depth, listOrdinal: depth + 2),
    next(BlockKind.listItem, listDepth: -2),
    for (final level in [0, 1, 6, 7, 8, 9])
      next(BlockKind.heading, headingLevel: level),
    for (final footnote in [0, 1, 2, 3, 4])
      next(BlockKind.paragraph, footnote: footnote),
    for (final definition in [0, 2, 3, 4])
      next(BlockKind.paragraph, definition: definition),
    // Ordinals and reaches up to what a 32-bit column holds, and past it.
    for (final value in [0x7fffffff, 0x80000000, 1 << 40, -1, -0x80000000])
      next(
        BlockKind.listItem,
        listDepth: 0,
        listOrdinal: value,
        reach: value,
        holdsFence: value.isOdd,
      ),
    next(BlockKind.paragraph, reach: 12),
    next(BlockKind.fencedCode, fenceInfo: 'dart'),
    next(BlockKind.fencedCode, fenceInfo: ''),
    next(BlockKind.fencedCode, fenceInfo: 'dart', divDepth: 2),
    next(BlockKind.paragraph, divDepth: 1),
    next(BlockKind.quote, entering: _inQuote, quoteDepth: 2),
    next(BlockKind.fencedCode, entering: _inFence, fenceInfo: 'c'),
    next(BlockKind.paragraph, entering: LineState.initial),
    // Everything at once.
    next(
      BlockKind.listItem,
      quoteDepth: 1000,
      listDepth: 400,
      listOrdinal: 1 << 33,
      headingLevel: 2,
      fenceInfo: 'x',
      entering: _inQuote,
      footnote: 2,
      definition: 2,
      reach: 1 << 35,
      divRole: DivRole.opensOther,
      divDepth: 5,
      holdsFence: true,
    ),
  ];
}

void main() {
  test('every field comes back as it went in', () {
    final blocks = _varied();
    final chunk = BlockChunk.of(blocks);
    expect(chunk.length, blocks.length);
    for (var at = 0; at < blocks.length; at++) {
      expect(_all(chunk.blockAt(at, 0)), _all(blocks[at]), reason: 'block $at');
      expect(chunk.kindAt(at), blocks[at].kind, reason: 'kind of $at');
      expect(chunk.holdsFenceAt(at), blocks[at].holdsFence);
    }
  });

  test('a range is packed alone', () {
    final blocks = _varied();
    final chunk = BlockChunk.of(blocks, 5, 40);
    expect(chunk.length, 35);
    for (var at = 0; at < 35; at++) {
      expect(_all(chunk.blockAt(at, 0)), _all(blocks[5 + at]));
    }
  });

  test('the states are the objects they were, not equal ones', () {
    final blocks = [
      const Block(
        kind: BlockKind.quote,
        startLine: 0,
        endLine: 1,
        entering: _inQuote,
      ),
      const Block(kind: BlockKind.paragraph, startLine: 1, endLine: 2),
    ];
    final chunk = BlockChunk.of(blocks);
    expect(identical(chunk.blockAt(0, 0).entering, _inQuote), isTrue);
    expect(chunk.blockAt(1, 0).entering, isNull);
  });

  test('a shift moves the lines and nothing else', () {
    final blocks = _varied();
    final chunk = BlockChunk.of(blocks);
    for (var at = 0; at < blocks.length; at++) {
      expect(_all(chunk.blockAt(at, 7)), _all(blocks[at].shifted(7)));
      expect(_all(chunk.blockAt(at, -3)), _all(blocks[at].shifted(-3)));
    }
  });

  test('shiftFrom moves the blocks from an index on, in place', () {
    final blocks = _varied();
    final chunk = BlockChunk.of(blocks)..shiftFrom(10, 4);
    for (var at = 0; at < blocks.length; at++) {
      expect(
        _all(chunk.blockAt(at, 0)),
        _all(at < 10 ? blocks[at] : blocks[at].shifted(4)),
        reason: 'block $at',
      );
    }
  });

  test('a chunk made its own is moved apart from the one it came from', () {
    final blocks = _varied();
    final shared = BlockChunk.of(blocks);
    final own = shared.toOwn()..shiftFrom(0, 5);
    for (var at = 0; at < blocks.length; at++) {
      expect(_all(shared.blockAt(at, 0)), _all(blocks[at]), reason: 'shared');
      expect(_all(own.blockAt(at, 0)), _all(blocks[at].shifted(5)));
    }
  });

  test('a note of plain blocks has no extras, and equal ones share', () {
    final plain = BlockChunk.of([
      for (var at = 0; at < 100; at++)
        Block(
          kind: BlockKind.listItem,
          startLine: at,
          endLine: at + 1,
          quoteDepth: 3,
          listDepth: 2,
          listOrdinal: at,
          headingLevel: 2,
          footnote: 1,
          definition: 2,
          reach: at,
          divRole: DivRole.closesColumn,
          holdsFence: true,
        ),
    ]);
    expect(plain.extraCount, 0);
    final fences = BlockChunk.of([
      for (var at = 0; at < 100; at++)
        Block(
          kind: BlockKind.fencedCode,
          startLine: at,
          endLine: at + 1,
          // A string of its own each: one the scanner cut from every fence.
          fenceInfo: String.fromCharCodes([100, 97, 114, 116]),
        ),
    ]);
    // One entry per block that has one: the object they point to is shared.
    expect(fences.extraCount, 100);
    expect(fences.blockAt(0, 0).fenceInfo, 'dart');
    expect(
      identical(
        fences.blockAt(0, 0).fenceInfo,
        fences.blockAt(99, 0).fenceInfo,
      ),
      isTrue,
    );
  });

  test('the kinds and roles fit the bits the word gives them', () {
    expect(BlockKind.values.length, lessThanOrEqualTo(16));
    expect(DivRole.values.length, lessThanOrEqualTo(7));
  });

  test('counts the fence lines of divs and the quotes that hold one', () {
    final chunk = BlockChunk.of(_varied());
    final blocks = _varied();
    expect(chunk.divCount, blocks.where((b) => b.kind == BlockKind.div).length);
    expect(
      chunk.fenceQuoteCount,
      blocks.where((b) => b.kind == BlockKind.quote && b.holdsFence).length,
    );
  });

  test('a list of them keeps every field through a move and a splice', () {
    final blocks = [for (var round = 0; round < 90; round++) ..._varied()];
    // Lines that tile, as a scan's do.
    final tiled = [
      for (var at = 0; at < blocks.length; at++)
        blocks[at].shifted(at * 3 - blocks[at].startLine),
    ];
    final plain = List<Block>.of(tiled);
    final list = BlockList(tiled);
    expect(list.length, plain.length);
    void check(String reason) {
      expect(list.length, plain.length, reason: reason);
      for (var at = 0; at < plain.length; at++) {
        expect(_all(list[at]), _all(plain[at]), reason: '$reason @$at');
      }
    }

    check('stored');
    final shared = BlockList.sharing(list);
    list.shiftFrom(1500, 2);
    for (var at = 1500; at < plain.length; at++) {
      plain[at] = plain[at].shifted(2);
    }
    check('moved');
    // The copy did not see the move.
    for (var at = 0; at < tiled.length; at++) {
      expect(_all(shared[at]), _all(tiled[at]), reason: 'copy @$at');
    }
    final varied = _varied();
    list.splice(1200, 1300, varied);
    plain.replaceRange(1200, 1300, varied);
    check('spliced');
    list.splice(0, 5, const []);
    plain.removeRange(0, 5);
    check('cut');
    expect(
      list.divBlocks.map(_all).toList(),
      plain.where((b) => b.kind == BlockKind.div).map(_all).toList(),
    );
    expect(
      list.fenceQuoteBlocks.map(_all).toList(),
      plain
          .where((b) => b.kind == BlockKind.quote && b.holdsFence)
          .map(_all)
          .toList(),
    );
    expect(list.divCount, plain.where((b) => b.kind == BlockKind.div).length);
  });
}
