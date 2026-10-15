/// **Make flashcards** (#533, `docs/records/flashcards.md`): a note turned
/// into a deck by its frontmatter alone; its body, where the cards are, is
/// not touched.
library;

import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/frontmatter/yaml_scalar.dart';

/// [text] made a deck: `type: flashcard`, `deck:` when [deck] says a place,
/// and `front:` and `back:` when the question and answer columns are named.
String makeDeckText(
  String text, {
  required String deck,
  String? front,
  String? back,
}) {
  var next = setFrontmatterKey(text, 'type', 'flashcard');
  final place = deck.trim();
  if (place.isNotEmpty) {
    next = setFrontmatterKey(next, 'deck', yamlString(place));
  }
  if (front != null) next = setFrontmatterKey(next, 'front', yamlString(front));
  if (back != null) next = setFrontmatterKey(next, 'back', yamlString(back));
  return next;
}

/// The frontmatter of [text] as the note writes it, fences included: what
/// the dialog shows will be written. Empty when there is none.
String frontmatterOf(String text) {
  final block = frontmatterBlock(text);
  if (block == null) return '';
  // Up to the closing fence's line, scanned: the note can be a novel.
  var end = -1;
  for (var line = 0; line <= block.endLine; line++) {
    end = text.indexOf('\n', end + 1);
    if (end < 0) return text.trimRight();
  }
  return text.substring(0, end).replaceAll('\r', '');
}
