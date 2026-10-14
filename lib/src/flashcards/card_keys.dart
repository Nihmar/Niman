/// A card's key: its question as plain text (#533,
/// `docs/records/flashcards.md`, "A card's identity").
library;

import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/read_block.dart';

final RegExp _white = RegExp(r'\s+');

/// [nodes] as plain text, its Markdown marks gone and its white space one
/// space: the key of a question. [gaps] are written as given, by identity —
/// how a cloze's hidden highlight becomes `[…]`.
String plainKey(List<InlineNode> nodes, {Map<InlineNode, String>? gaps}) =>
    ReadInline.plainOf(nodes, instead: gaps).replaceAll(_white, ' ').trim();

/// The key of [markdown], a question written on its own.
String plainKeyOf(String markdown) => plainKey(InlineParser(markdown).parse());

/// [keys] with each question asked again made a key of its own: the second
/// `question (2)`, the third `question (3)`, by order. A suffixed key that
/// the note also asks outright is passed over for the next number.
List<String> uniqueKeys(List<String> keys) {
  final seen = <String>{};
  final counts = <String, int>{};
  final out = <String>[];
  for (final key in keys) {
    var unique = key;
    if (!seen.add(unique)) {
      var number = counts[key] ?? 1;
      do {
        number++;
        unique = '$key ($number)';
      } while (!seen.add(unique));
      counts[key] = number;
    }
    out.add(unique);
  }
  return out;
}
