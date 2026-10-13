// #844: what a block id is, asked once: the link parser, the scan that finds
// the ids and the anchor reader all agree because they ask the same class.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/block_id.dart';
import 'package:niman/src/links/parser.dart';

void main() {
  const accepted = ['a', '37066d', 'quote-of-the-day', 'A-B-9', '0', '---'];
  const refused = ['', 'two words', 'ünï', 'a_b', 'a.b', 'a^b', '^a', 'a/b'];

  test('an id is letters, digits and dashes', () {
    for (final id in accepted) {
      expect(BlockId.isValid(id), isTrue, reason: id);
    }
    for (final id in refused) {
      expect(BlockId.isValid(id), isFalse, reason: '"$id"');
    }
  });

  test('the parser, the line scan and the anchor reader agree on it', () {
    for (final id in [...accepted, ...refused]) {
      final valid = BlockId.isValid(id);
      expect(
        parseWikiRef('Note#^$id').block != null,
        valid,
        reason: 'the link parser on "$id"',
      );
      expect(
        parseAnchor('^$id') is BlockIdAnchor,
        valid,
        reason: 'the anchor reader on "$id"',
      );
      if (id.isNotEmpty && !id.contains(' ')) {
        expect(
          trailingBlockId('text ^$id') == id,
          valid,
          reason: 'the line scan on "$id"',
        );
      }
    }
  });

  test("a trailing id is a space, a caret and an id at the line's end", () {
    expect(BlockId.trailingIn('a ^id')?.group(1), 'id');
    expect(BlockId.trailingIn('^id')?.group(1), 'id');
    expect(BlockId.trailingIn('a ^id  ')?.group(1), 'id');
    expect(BlockId.trailingIn('a^id'), isNull);
    expect(BlockId.trailingIn('a ^id more'), isNull);
  });
}
