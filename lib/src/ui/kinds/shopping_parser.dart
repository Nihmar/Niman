/// The `shopping-list` note kind's line format: a quantity hanging off
/// the item's own text (`- [ ] Latte ×2`).
///
/// The marker lives in the text so the note stays plain Markdown, and the
/// edits here are byte-stable like `list_parser.dart`'s: the lines the
/// GUI does not touch keep their bytes, so a note converted between `list`
/// and `shopping-list` (and back) never changes.
library;

import 'package:niman/src/ui/kinds/list_parser.dart';

/// The quantity at the end of an item text.
///
/// Three spellings read the same: the canonical `Latte ×2`, and the
/// hand-typed `Latte x2` / `Latte X 2`. An ASCII `x` needs whitespace
/// before it, so a name that ends in `x` and a number (`Botox2`) stays
/// the name it is; the `×` glyph is the marker whatever stands before it.
final RegExp _quantityAtEnd = RegExp(r'^(.*?)(?:\s*×|\s+[xX])\s*(\d+)\s*$');

/// The highest quantity the stepper offers; a file may carry more, and
/// one reads back what it says.
const int shoppingQuantityMax = 99;

/// The task-list items of [text] with the quantities their texts end in,
/// in document order.
///
/// Every item [parseListItems] finds is one. An item whose text ends in a
/// quantity marker keeps the marker as [ListItem.quantity] and its name
/// without it; an item with no marker — or a `×1`, which the GUI never
/// writes — is a quantity of one, and keeps its text as it stands.
List<ListItem> parseShoppingItems(String text) {
  final lines = text.split('\n');
  return <ListItem>[
    for (final item in parseListItems(text))
      _withQuantity(item, lines[item.line]),
  ];
}

/// [item] with the quantity its line ends in, if it ends in one.
ListItem _withQuantity(ListItem item, String line) {
  final raw = line.substring(item.textStart);
  final match = _quantityAtEnd.firstMatch(raw);
  if (match == null) return item;
  final name = match.group(1)!.trim();
  final quantity = int.tryParse(match.group(2)!) ?? 1;
  if (name.isEmpty || quantity < 1) return item;
  return ListItem(
    line: item.line,
    depth: item.depth,
    indent: item.indent,
    boxStart: item.boxStart,
    textStart: item.textStart,
    checked: item.checked,
    text: name,
    quantity: quantity,
  );
}

/// The suffix [quantity] is written with: ` ×2`, or nothing for one.
///
/// One is the absence of a marker rather than `×1`: the line reads as the
/// plain list item it is, and a note that never needed a quantity stays
/// clean.
String shoppingQuantitySuffix(int quantity) =>
    quantity > 1 ? ' ×$quantity' : '';

/// The note text with [item]'s name and quantity replaced (everything
/// else, frontmatter included, keeps its bytes).
String editShoppingItem(String text, ListItem item, String name, int quantity) {
  final lines = text.split('\n');
  final line = lines[item.line];
  lines[item.line] =
      '${line.substring(0, item.textStart)}'
      '$name${shoppingQuantitySuffix(quantity)}';
  return lines.join('\n');
}

/// Appends `- [ ] <name> ×<quantity>` as a new line at the end of [text]
/// (byte-stable otherwise).
String appendShoppingItem(String text, String name, int quantity) {
  final prefix = text.isEmpty || text.endsWith('\n') ? text : '$text\n';
  return '$prefix- [ ] $name${shoppingQuantitySuffix(quantity)}\n';
}
