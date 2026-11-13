/// What a voice reads of a book (#1276): the text of its headings,
/// paragraphs, list items and quotes, a sentence at a time.
///
/// Read off the blocks the read view draws (`ReadBlock`), so a sentence's
/// characters are the ones the view lays out and its mark lands on the
/// words spoken. Pictures, rules, code, tables and footnote marks are not
/// spoken; a link is its text. A sentence longer than the engine takes at
/// once is cut at a space before the limit.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';

/// A sentence to speak, and where it is drawn: its characters in its
/// block's text, or null when the block draws more than its text (a list,
/// a quote) and the whole block is marked instead.
typedef ReadAloudSentence = ({String text, CharRange? chars});

/// A paragraph to speak: the line its block opens on, and its sentences.
typedef ReadAloudParagraph = ({int line, List<ReadAloudSentence> sentences});

/// How much a sentence may hold at most: Android's engine takes 4000
/// characters at once (`TextToSpeech.getMaxSpeechInputLength`).
const int readAloudMaxLength = 4000;

/// The paragraphs a voice reads of [blocks], each with its first line, in
/// order; a block with nothing to speak is left out.
List<ReadAloudParagraph> readAloudParagraphs(
  Iterable<({int line, ReadBlock block})> blocks, {
  int maxLength = readAloudMaxLength,
}) => [
  for (final (:line, :block) in blocks)
    if (_sentencesOf(block, maxLength) case final sentences
        when sentences.isNotEmpty)
      (line: line, sentences: sentences),
];

List<ReadAloudSentence> _sentencesOf(ReadBlock block, int maxLength) {
  final node = block.node;
  if (node is LeafNode) {
    // A heading or a paragraph draws its text and nothing else: its
    // sentences are marked where they are.
    final text = _spokenOf(block, node);
    if (text == null) return const [];
    return [
      for (final range in splitSentences(text, maxLength: maxLength))
        (text: text.substring(range.start, range.end), chars: range),
    ];
  }
  final out = <ReadAloudSentence>[];
  void add(BlockNode node) {
    switch (node) {
      case QuoteNode(:final children) ||
          ItemNode(:final children) ||
          ColumnNode(:final children):
        children.forEach(add);
      case ListNode(:final items):
        items.forEach(add);
      case ColumnsNode(:final columns):
        columns.forEach(add);
      case FootnoteNode():
        break;
      case LeafNode():
        final text = _spokenOf(block, node);
        if (text == null) return;
        for (final range in splitSentences(text, maxLength: maxLength)) {
          out.add((text: text.substring(range.start, range.end), chars: null));
        }
    }
  }

  add(node);
  return out;
}

/// What [leaf] says aloud: a heading's or a paragraph's text, its
/// pictures left out; null for the leaves that are not read.
String? _spokenOf(ReadBlock block, LeafNode leaf) {
  if (leaf.kind != BlockKind.paragraph && leaf.kind != BlockKind.heading) {
    return null;
  }
  final inline = block.leaf(leaf).inline;
  if (inline == null) return null;
  final pictures = <InlineNode, String>{};
  final stack = <InlineNode>[...inline.nodes];
  while (stack.isNotEmpty) {
    switch (stack.removeLast()) {
      case final ImageNode picture:
        pictures[picture] = '';
      case InlineContainer(:final children):
        stack.addAll(children);
      default:
        break;
    }
  }
  final text = ReadInline.plainOf(inline.nodes, instead: pictures);
  return text.trim().isEmpty ? null : text;
}

/// Where [text]'s sentences are, each without the spaces around it: a
/// sentence ends after `.`, `!`, `?` or `…` (and their full-width forms),
/// with any closing quote or bracket after, where a space or the end
/// follows and the next word does not open in lowercase — "e.g. this" stays
/// one. One longer than [maxLength] is cut at its last space before it, or
/// at it when there is none.
List<CharRange> splitSentences(
  String text, {
  int maxLength = readAloudMaxLength,
}) {
  final out = <CharRange>[];
  void add(int from, int to) {
    var start = from;
    var end = to;
    while (start < end && _isSpace(text.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _isSpace(text.codeUnitAt(end - 1))) {
      end--;
    }
    while (end - start > maxLength) {
      var cut = start + maxLength;
      while (cut > start && !_isSpace(text.codeUnitAt(cut))) {
        cut--;
      }
      if (cut == start) cut = start + maxLength;
      out.add((start: start, end: cut));
      start = cut;
      while (start < end && _isSpace(text.codeUnitAt(start))) {
        start++;
      }
    }
    if (end > start) out.add((start: start, end: end));
  }

  var start = 0;
  var i = 0;
  while (i < text.length) {
    final unit = text.codeUnitAt(i);
    i++;
    if (!_ends(unit)) continue;
    // A run of stops, then whatever closes the sentence after them.
    while (i < text.length && _ends(text.codeUnitAt(i))) {
      i++;
    }
    while (i < text.length && _closes(text.codeUnitAt(i))) {
      i++;
    }
    final wide = unit >= 0x3000;
    if (i < text.length && !wide && !_isSpace(text.codeUnitAt(i))) continue;
    var next = i;
    while (next < text.length && _isSpace(text.codeUnitAt(next))) {
      next++;
    }
    if (next < text.length && _isLower(text.codeUnitAt(next))) continue;
    add(start, i);
    start = i;
  }
  add(start, text.length);
  return out;
}

bool _ends(int unit) =>
    unit == 0x2E || // .
    unit == 0x21 || // !
    unit == 0x3F || // ?
    unit == 0x2026 || // …
    unit == 0x3002 || // 。
    unit == 0xFF01 || // ！
    unit == 0xFF1F; // ？

bool _closes(int unit) =>
    unit == 0x22 || // "
    unit == 0x27 || // '
    unit == 0x29 || // )
    unit == 0x5D || // ]
    unit == 0xBB || // »
    unit == 0x2019 || // ’
    unit == 0x201D || // ”
    unit == 0x300D || // 」
    unit == 0x300F; // 』

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0xA0;

bool _isLower(int unit) {
  final char = String.fromCharCode(unit);
  return char.toLowerCase() == char && char.toUpperCase() != char;
}
