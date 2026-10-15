/// The cards of one paragraph or list item (#533): a one-line ` :: ` card,
/// or a cloze for each `==highlight==` of any other.
library;

import 'package:niman/src/flashcards/card_keys.dart';
import 'package:niman/src/flashcards/card_ranges.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What splits a line into its question and its answer.
const String _divider = ' :: ';

/// The cards of the paragraph [leaf], in order; none when it holds neither
/// a divider nor a highlight.
List<FlashCard> paragraphCards(ReadLeaf leaf, SourceBuffer buffer) {
  final inline = leaf.inline;
  if (inline == null || inline.isEmpty) return const [];
  if (leaf.node.lines.length == 1) {
    final card = _lineCard(leaf, inline, buffer);
    if (card != null) return [card];
    // No divider, or one inside a code span or a formula: a line of
    // highlights, perhaps.
  }
  return _clozes(leaf, inline, buffer);
}

FlashCard? _lineCard(ReadLeaf leaf, ReadInline inline, SourceBuffer buffer) {
  final text = inline.text;
  final literals = <InlineNode>[];
  _collect(
    inline.nodes,
    literals,
    (node) => node is CodeNode || node is MathNode,
  );
  var at = text.indexOf(_divider);
  while (at >= 0 && literals.any((node) => at >= node.start && at < node.end)) {
    at = text.indexOf(_divider, at + 1);
  }
  if (at < 0) return null;
  final question = text.substring(0, at).trim();
  if (question.isEmpty) return null;
  final answerFrom = at + _divider.length;
  return FlashCard(
    kind: CardKind.line,
    question: question,
    answer: text.substring(answerFrom).trim(),
    key: plainKeyOf(question),
    source: sourceOf(
      buffer,
      leaf.node.lines,
      question: noteRange(inline.map, buffer, text, 0, at),
      answer: noteRange(inline.map, buffer, text, answerFrom, text.length),
    ),
  );
}

List<FlashCard> _clozes(ReadLeaf leaf, ReadInline inline, SourceBuffer buffer) {
  final text = inline.text;
  final marks = <InlineNode>[];
  _collect(inline.nodes, marks, (node) => node is HighlightNode, into: false);
  final highlights = [
    for (final mark in marks.cast<HighlightNode>())
      if (_hidden(text, mark).trim().isNotEmpty) mark,
  ];
  return [
    for (final hidden in highlights)
      FlashCard(
        kind: CardKind.cloze,
        question: _questionWith(text, highlights, hidden),
        answer: _hidden(text, hidden).trim(),
        key: plainKey(inline.nodes, gaps: {hidden: FlashCard.clozeGap}),
        source: sourceOf(
          buffer,
          leaf.node.lines,
          answer: noteRange(inline.map, buffer, text, hidden.start, hidden.end),
        ),
      ),
  ];
}

/// The text a highlight hides, as written.
String _hidden(String text, HighlightNode mark) => mark.children.isEmpty
    ? ''
    : text.substring(mark.children.first.start, mark.children.last.end);

/// [text] with [gap]'s highlight a gap and the others plain text.
String _questionWith(
  String text,
  List<HighlightNode> highlights,
  HighlightNode gap,
) {
  final out = StringBuffer();
  var from = 0;
  for (final mark in highlights) {
    out
      ..write(_literal(text.substring(from, mark.start)))
      ..write(
        identical(mark, gap)
            ? FlashCard.clozeGap
            : _literal(_hidden(text, mark)),
      );
    from = mark.end;
  }
  return (out..write(_literal(text.substring(from)))).toString();
}

/// [text] with each literal `[…]` (an elision in a quotation) written
/// [FlashCard.clozeElision], so the question's only `[…]` is the gap.
String _literal(String text) =>
    text.replaceAll(FlashCard.clozeGap, FlashCard.clozeElision);

/// The nodes of [nodes] and below that [test] picks, in order; [into] false
/// leaves a picked node's own children alone.
void _collect(
  List<InlineNode> nodes,
  List<InlineNode> found,
  bool Function(InlineNode node) test, {
  bool into = true,
}) {
  for (final node in nodes) {
    if (test(node)) {
      found.add(node);
      if (!into) continue;
    }
    if (node is InlineContainer) {
      _collect(node.children, found, test, into: into);
    }
  }
}
