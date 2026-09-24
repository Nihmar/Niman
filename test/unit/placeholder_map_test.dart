// The correction table a block with an inline widget needs: one code unit where
// the source may be five. The pixels around the placeholder are the painter's
// (`caret_rectangle_test.dart`, measured); this is the arithmetic the surface
// does around it.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/placeholder_map.dart';

void main() {
  // `see $x^2$ here`: the formula is source 4..9 and one code unit at text 4.
  const map = PlaceholderMap(
    sourceLength: 14,
    spans: [(textOffset: 4, sourceStart: 4, sourceLength: 5)],
  );

  group('the identity', () {
    test('is what a block with nothing drawn in it has', () {
      const plain = PlaceholderMap.identity(14);
      expect(plain.isIdentity, isTrue);
      expect(plain.textLength, 14);
      expect(plain.sourceOf(7), 7);
      expect(plain.textOf(7), 7);
      expect(plain.sourceRangeOf(7), (7, 8));
      expect(plain.sourceOf(99), 14);
      expect(plain.textOf(-3), 0);
    });

    test('is not what a block with a formula in it has', () {
      expect(map.isIdentity, isFalse);
      // 14 source characters, 4 of them saved by the one placeholder.
      expect(map.textLength, 10);
    });
  });

  group('the two offset spaces', () {
    test('part company after the placeholder', () {
      expect(map.sourceOf(4), 4);
      expect(map.sourceOf(5), 9);
      expect(map.sourceOf(map.textLength), 14);
      expect(map.textOf(4), 4);
      expect(map.textOf(9), 5);
      expect(map.textOf(3), 3);
    });

    test('a source offset inside the formula is the placeholder, not text', () {
      // The source of a formula is hidden, so the caret cannot rest in it:
      // every offset it covers comes back as the one place the box stands at.
      for (final inside in <int>[4, 5, 6, 7, 8]) {
        expect(map.textOf(inside), 4);
      }
    });

    test('a range is the whole formula, or one character', () {
      expect(map.sourceRangeOf(4), (4, 9));
      expect(map.sourceRangeOf(3), (3, 4));
      expect(map.sourceRangeOf(5), (9, 10));
    });

    test('two placeholders in one block add up', () {
      // Text 0,1 are source 0,1; the first box sits at text 2 for source 2..6;
      // text 3,4 are source 6,7; the second box is text 5 for source 8..11; the
      // rest is source 11..20 and text 6..15.
      const two = PlaceholderMap(
        sourceLength: 20,
        spans: [
          (textOffset: 2, sourceStart: 2, sourceLength: 4),
          (textOffset: 5, sourceStart: 8, sourceLength: 3),
        ],
      );
      // 20 characters, less three for the first span and two for the second.
      expect(two.textLength, 15);
      // Before, between and after the two, in both directions.
      expect(two.sourceOf(2), 2);
      expect(two.sourceOf(3), 6);
      expect(two.sourceOf(5), 8);
      expect(two.sourceOf(6), 11);
      expect(two.textOf(6), 3);
      expect(two.textOf(10), 5);
      expect(two.textOf(11), 6);
      expect(two.sourceRangeOf(2), (2, 6));
      expect(two.sourceRangeOf(5), (8, 11));
    });
  });
}
