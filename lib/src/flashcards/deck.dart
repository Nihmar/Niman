/// A deck note, read (#533): its frontmatter and its cards in note order.
///
/// `docs/records/flashcards.md`, "The cards": a table row, a `::` line or a
/// cloze, read with the block tree so nothing in a code block, a formula,
/// an HTML block or the frontmatter is a card.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/card_keys.dart';
import 'package:niman/src/flashcards/deck_meta.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/flashcards/paragraph_cards.dart';
import 'package:niman/src/flashcards/table_cards.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A deck note: its metadata and its cards.
@immutable
final class Deck {
  /// A deck of [cards].
  const new({required this.meta, required this.cards});

  /// Reads the deck [text] holds, the whole note, frontmatter included.
  ///
  /// Pure and synchronous, for a caller already off the UI isolate (a deck
  /// can be a novel-length note).
  factory read(String text) {
    final meta = DeckMeta.of(parseFrontmatter(text));
    final buffer = SourceBuffer.fromText(text);
    final parser = ReadParser();
    final found = <FlashCard>[];
    for (final block in BlockScanner(buffer).index.blocks) {
      if (!_holdsCards(block)) continue;
      final read = parser.read(block, buffer);
      _visit(read.node, read, buffer, meta, found);
    }
    final keys = uniqueKeys([for (final card in found) card.key]);
    return Deck(
      meta: meta,
      cards: [for (var i = 0; i < found.length; i++) found[i].withKey(keys[i])],
    );
  }

  /// The frontmatter's say on the deck.
  final DeckMeta meta;

  /// Its cards, in note order, each under a key of its own.
  final List<FlashCard> cards;

  static bool _holdsCards(Block block) {
    if (block.footnote != 0) return false;
    return switch (block.kind) {
      BlockKind.paragraph ||
      BlockKind.table ||
      BlockKind.listItem ||
      BlockKind.quote ||
      BlockKind.div => true,
      _ => false,
    };
  }

  static void _visit(
    BlockNode node,
    ReadBlock read,
    SourceBuffer buffer,
    DeckMeta meta,
    List<FlashCard> out,
  ) {
    void visit(BlockNode child) => _visit(child, read, buffer, meta, out);
    switch (node) {
      case QuoteNode(:final children) || ItemNode(:final children):
        children.forEach(visit);
      case ColumnNode(:final children):
        children.forEach(visit);
      case ListNode(:final items):
        items.forEach(visit);
      case ColumnsNode(:final columns):
        columns.forEach(visit);
      case FootnoteNode():
        break;
      case LeafNode(:final kind) when kind == BlockKind.paragraph:
        out.addAll(paragraphCards(read.leaf(node), buffer));
      case LeafNode(:final kind) when kind == BlockKind.table:
        out.addAll(tableCards(read.leaf(node), buffer, meta));
      case LeafNode():
        break;
    }
  }
}
