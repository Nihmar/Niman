// The chunked block list: every read has to be what a plain list moved by
// hand would answer, and a copy — the read pane's — must never see the
// scanner's writes, nor they its.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_list.dart';

Block _block(int start, int length, int tag) => Block(
  kind: BlockKind.values[tag % BlockKind.values.length],
  startLine: start,
  endLine: start + length,
  listOrdinal: tag,
);

String _describe(Block block) =>
    '${block.kind.name} ${block.startLine}-${block.endLine} '
    '#${block.listOrdinal}';

/// A block list and the plain list it must agree with.
final class _Pair {
  new(this.plain) : list = BlockList(plain);

  new sharing(_Pair other)
    : plain = List<Block>.of(other.plain),
      list = BlockList.sharing(other.list);

  final List<Block> plain;
  final BlockList list;
  static int _tags = 0;

  /// A random edit made to both: a splice, and every block after it moved,
  /// as an edit that adds or removes lines does.
  void edit(Random random) {
    final start = random.nextInt(plain.length + 1);
    final end = min(plain.length, start + random.nextInt(2000));
    final count = random.nextInt(10) == 0
        ? random.nextInt(3000)
        : random.nextInt(3);
    final at = start == 0 ? 0 : plain[start - 1].endLine;
    final added = [for (var n = 0; n < count; n++) _block(at + n, 1, _tags++)];
    plain.replaceRange(start, end, added);
    list.splice(start, end, added);
    // Where the move starts is its own: the scanner moves the blocks after
    // an edit before it splices, into chunks it may share with a copy.
    final from = random.nextBool()
        ? start + added.length
        : random.nextInt(plain.length + 1);
    final delta = random.nextInt(7) - 3;
    for (var n = from; n < plain.length; n++) {
      plain[n] = plain[n].shifted(delta);
    }
    list.shiftFrom(from, delta);
  }

  void check(String reason) {
    expect(list.length, plain.length, reason: reason);
    for (var at = 0; at < plain.length; at++) {
      expect(_describe(list[at]), _describe(plain[at]), reason: '$reason @$at');
    }
    // Out of order, as a binary search reads.
    final random = Random(plain.length);
    for (var ask = 0; ask < 200 && plain.isNotEmpty; ask++) {
      final at = random.nextInt(plain.length);
      expect(_describe(list[at]), _describe(plain[at]), reason: '$reason @$at');
    }
  }
}

void main() {
  List<Block> blocks(int count) => [
    for (var at = 0; at < count; at++) _block(at * 2, 2, at),
  ];

  test('reads as a plain list moved by hand would', () {
    final random = Random(2);
    final pair = _Pair(blocks(5000));
    for (var edit = 0; edit < 200; edit++) {
      pair
        ..edit(random)
        ..check('edit $edit');
    }
  });

  test("a copy and its source never see each other's writes", () {
    final random = Random(4);
    var older = _Pair(blocks(6000));
    for (var round = 0; round < 30; round++) {
      final newer = _Pair.sharing(older);
      for (var edit = 0; edit < 5; edit++) {
        older.edit(random);
        newer.edit(random);
      }
      older.check('round $round, the source');
      newer.check('round $round, the copy');
      older = random.nextBool() ? older : newer;
    }
  });

  test('a move inside a shared chunk is not seen by the copy', () {
    // What the scanner does to the chunk an Enter lands in, while the read
    // pane holds a copy: the blocks after the Enter move, the chunk's first
    // ones do not.
    final source = BlockList(blocks(3000));
    final copy = BlockList.sharing(source);
    const middle = BlockList.chunkSize + BlockList.chunkSize ~/ 2;
    source.shiftFrom(middle, 1);
    for (var at = 0; at < 3000; at++) {
      expect(copy[at].startLine, at * 2, reason: 'the copy @$at');
      expect(
        source[at].startLine,
        at * 2 + (at >= middle ? 1 : 0),
        reason: 'the source @$at',
      );
    }
    copy.shiftFrom(middle + 10, -1);
    expect(source[middle + 10].startLine, (middle + 10) * 2 + 1);
    expect(copy[middle + 10].startLine, (middle + 10) * 2 - 1);
  });

  test('matching moves only the blocks it takes, and all of them', () {
    final random = Random(6);
    final pair = _Pair(blocks(5000));
    for (var edit = 0; edit < 20; edit++) {
      pair.edit(random);
    }
    bool even(Block block) => block.listOrdinal.isEven;
    expect(
      pair.list.matching(even).map(_describe).toList(),
      pair.plain.where(even).map(_describe).toList(),
    );
  });

  test('is a list nobody else can write to', () {
    final list = BlockList(blocks(3));
    expect(() => list[0] = _block(0, 1, 0), throwsUnsupportedError);
    expect(() => list.add(_block(0, 1, 0)), throwsUnsupportedError);
    expect(list.map((block) => block.startLine), [0, 2, 4]);
  });
}
