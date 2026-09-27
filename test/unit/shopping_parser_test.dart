// #309: the shopping-list line format — a quantity in the item's own
// text, byte-stable edits, and the rule that one is not written.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/kinds/shopping_parser.dart';

void main() {
  group('parseShoppingItems', () {
    test('reads the canonical marker and keeps the name', () {
      const text =
          '---\ntype: shopping-list\n---\n'
          '- [ ] Latte ×2\n- [ ] Pane\n- [x] Uova ×6\n';
      final items = parseShoppingItems(text);
      expect(items.map((i) => i.text).toList(), ['Latte', 'Pane', 'Uova']);
      expect(items.map((i) => i.quantity).toList(), [2, 1, 6]);
      expect(items.map((i) => i.checked).toList(), [false, false, true]);
    });

    test('a hand-typed x or X reads the same as ×', () {
      const text = '- [ ] Latte x2\n- [ ] Pane X 3\n- [ ] Uova x 4\n';
      final items = parseShoppingItems(text);
      expect(items.map((i) => i.quantity).toList(), [2, 3, 4]);
      expect(items.map((i) => i.text).toList(), ['Latte', 'Pane', 'Uova']);
    });

    test('a name that merely ends in x and a number is a name', () {
      const text = '- [ ] Botox2\n- [ ] 2 x 4 screws\n';
      final items = parseShoppingItems(text);
      expect(items.map((i) => i.text).toList(), ['Botox2', '2 x 4 screws']);
      expect(items.map((i) => i.quantity).toList(), [1, 1]);
    });

    test('×1 is read as one, and the name stays clean', () {
      final items = parseShoppingItems('- [ ] Pane ×1\n');
      expect(items.single.quantity, 1);
      expect(items.single.text, 'Pane');
    });

    test('an item with only a marker keeps the text it has', () {
      final items = parseShoppingItems('- [ ] ×2\n');
      expect(items.single.quantity, 1);
      expect(items.single.text, '×2');
    });

    test('nesting, prose and fences read as the plain parser does', () {
      const text = 'prose\n- [ ] a ×2\n  - [ ] b ×3\n```\n- [ ] no ×9\n```\n';
      final items = parseShoppingItems(text);
      expect(items.map((i) => i.depth).toList(), [0, 1]);
      expect(items.map((i) => i.quantity).toList(), [2, 3]);
    });
  });

  group('shoppingQuantitySuffix', () {
    test('one writes nothing at all', () {
      expect(shoppingQuantitySuffix(1), '');
      expect(shoppingQuantitySuffix(2), ' ×2');
      expect(shoppingQuantitySuffix(99), ' ×99');
    });
  });

  group('editShoppingItem', () {
    test('rewrites only the item line, byte-stable otherwise', () {
      const text = 'prose\n- [ ] Latte ×2\n- [x] Pane\n';
      final items = parseShoppingItems(text);
      expect(
        editShoppingItem(text, items[0], 'Latte intero', 3),
        'prose\n- [ ] Latte intero ×3\n- [x] Pane\n',
      );
      expect(
        editShoppingItem(text, items[1], 'Pane', 1),
        'prose\n- [ ] Latte ×2\n- [x] Pane\n',
      );
    });

    test('a quantity back to one takes the marker out', () {
      const text = '- [ ] Uova ×6\n';
      final items = parseShoppingItems(text);
      expect(editShoppingItem(text, items.single, 'Uova', 1), '- [ ] Uova\n');
    });

    test('an edit that changes nothing leaves the note as it is', () {
      const text = '---\ntype: shopping-list\n---\n- [ ] Latte ×2\n';
      final items = parseShoppingItems(text);
      expect(editShoppingItem(text, items.single, 'Latte', 2), text);
    });
  });

  group('appendShoppingItem', () {
    test('appends with the marker, or without one for one', () {
      expect(appendShoppingItem('', 'Latte', 2), '- [ ] Latte ×2\n');
      expect(appendShoppingItem('a\n', 'Latte', 1), 'a\n- [ ] Latte\n');
      expect(appendShoppingItem('a', 'Latte', 2), 'a\n- [ ] Latte ×2\n');
    });
  });
}
