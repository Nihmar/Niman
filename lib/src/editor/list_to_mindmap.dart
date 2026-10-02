/// Converting a Markdown list into a `mindmap` fence (#530).
///
/// The list is read off the block scan, not off the text: the scan already
/// knows a list item from a line inside a code fence or a front matter, an
/// item's continuation lines, the blank lines of a loose list, the
/// paragraphs and fences an item holds after its first, and how deep an
/// item sits whatever its indentation. And it reads only the list's own
/// lines, never the note's — the caller replaces that range as one
/// undoable edit.
///
/// A single outermost item is the root; several get a root of their own to
/// hang from. What an item holds past its first line joins its words.
library;

import 'dart:math' as math;

import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What a list becomes: the lines `[startLine, endLine)` it takes up, and
/// the fence's lines that replace them.
typedef ListMindMap = ({int startLine, int endLine, List<String> fence});

/// The mind map the list around [line] of [buffer] becomes, or null when
/// the line is not in a list outside any quote — an item, or a paragraph or
/// a fence an item holds.
///
/// [blockAt] is the block holding a line, from the scan the caller already
/// keeps; without one, the note is scanned as far as the list.
ListMindMap? listToMindMap({
  required SourceBuffer buffer,
  required int line,
  Block? Function(int line)? blockAt,
}) {
  final blockOf = blockAt ?? BlockScanner(buffer).blockAt;
  final at = blockOf(line);
  if (at == null || !_inList(at) || at.kind == BlockKind.blank) return null;
  final family = _familyAbove(at, blockOf, buffer);
  // Every block of the list but its blank lines, in order.
  final blocks = <Block>[at];
  for (var block = blockOf(at.startLine - 1); block != null;) {
    if (!_inList(block) || !_sameList(block, family, buffer)) break;
    if (block.kind != BlockKind.blank) blocks.insert(0, block);
    block = blockOf(block.startLine - 1);
  }
  for (var block = blockOf(at.endLine); block != null;) {
    if (!_inList(block) || !_sameList(block, family, buffer)) break;
    if (block.kind != BlockKind.blank) blocks.add(block);
    block = blockOf(block.endLine);
  }
  final items = _items(blocks, buffer);
  if (items.isEmpty) return null;
  return (
    startLine: blocks.first.startLine,
    endLine: blocks.last.endLine,
    fence: ['```mermaid', 'mindmap', ..._nodes(items), '```'],
  );
}

/// An item of the list: how deep it sits, and its words.
typedef _Item = ({int depth, List<String> words});

/// The items of [blocks], each with the words of what it holds: a block
/// that is not an item belongs to the last item before it as deep as it.
List<_Item> _items(List<Block> blocks, SourceBuffer buffer) {
  final items = <_Item>[];
  for (final block in blocks) {
    if (_isItem(block)) {
      items.add((depth: block.listDepth, words: _itemWords(block, buffer)));
    } else if (items.isNotEmpty) {
      final owner = items.lastWhere(
        (item) => item.depth == block.listDepth,
        orElse: () => items.last,
      );
      owner.words.addAll(_heldWords(block, buffer));
    }
  }
  return items;
}

/// The mind map's node lines, two spaces a level.
List<String> _nodes(List<_Item> items) {
  final least = items.map((item) => item.depth).reduce(math.min);
  final roots = items.where((item) => item.depth == least).length;
  final nodes = <String>[];
  // Several outermost items hang from a root of their own.
  final shift = roots > 1 ? 1 : 0;
  if (shift == 1) nodes.add('  root');
  for (var i = 0; i < items.length; i++) {
    final depth = items[i].depth - least + shift;
    final label = items[i].words.join(' ');
    nodes.add('${'  ' * (depth + 1)}${_node(i, label)}');
  }
  return nodes;
}

/// Whether [block] is a list item outside any quote.
bool _isItem(Block block) =>
    block.kind == BlockKind.listItem && block.quoteDepth == 0;

/// Whether [block] belongs to a list outside any quote: an item, a blank
/// line between items, or a paragraph or a fence an item holds.
bool _inList(Block block) => block.listDepth >= 0 && block.quoteDepth == 0;

/// Whether [block] is in the same list as an outermost item of [family]:
/// a change of marker at the outermost level starts another list.
bool _sameList(Block block, String? family, SourceBuffer buffer) =>
    block.kind != BlockKind.listItem ||
    block.listDepth > 0 ||
    _familyOf(block, buffer) == family;

/// The marker family of the outermost item at or above [item].
String? _familyAbove(
  Block item,
  Block? Function(int line) blockOf,
  SourceBuffer buffer,
) {
  for (Block? block = item; block != null;) {
    if (!_inList(block)) break;
    if (_isItem(block) && block.listDepth == 0) {
      return _familyOf(block, buffer);
    }
    block = blockOf(block.startLine - 1);
  }
  return null;
}

/// What kind of list an item's marker makes: each bullet is its own, and
/// an ordered list is told by its delimiter, as CommonMark tells them.
String? _familyOf(Block item, SourceBuffer buffer) {
  final marker = listItemHead(buffer.lineAt(item.startLine))?.marker;
  if (marker == null) return null;
  return marker.length == 1 ? marker : marker[marker.length - 1];
}

/// An item's words: its first line past the marker, and its continuation
/// lines; its marker when it has none.
List<String> _itemWords(Block item, SourceBuffer buffer) {
  final head = listItemHead(buffer.lineAt(item.startLine));
  final words = [
    if (head != null) head.content.trim(),
    for (var line = item.startLine + 1; line < item.endLine; line++)
      buffer.lineAt(line).trim(),
  ].where((part) => part.isNotEmpty).toList();
  return words.isEmpty ? [head?.marker ?? ''] : words;
}

/// The words of a block an item holds past its first: its lines, a fence's
/// own lines left out — they are syntax, and a line of backticks would end
/// the mind map's fence.
List<String> _heldWords(Block block, SourceBuffer buffer) {
  final fenced = block.kind == BlockKind.fencedCode;
  return [
    for (var line = block.startLine; line < block.endLine; line++)
      if (buffer.lineAt(line).trim() case final text
          when text.isNotEmpty && !(fenced && _fenceLine.hasMatch(text)))
        text,
  ];
}

/// A fence's opening or closing line.
final RegExp _fenceLine = RegExp('^(`{3,}|~{3,})');

/// The node line for [label]: bare when the mind-map parser reads it back
/// as written, quoted in the rounded box a bare node is drawn in when a
/// bracket would make it a shape, a `%%` a comment or a leading `::` an
/// icon.
String _node(int index, String label) {
  final plain =
      !label.contains(RegExp(r'[()\[\]{}"]')) &&
      !label.contains('%%') &&
      !label.startsWith('::');
  if (plain) return label;
  return 'n$index("${label.replaceAll('"', '#quot;')}")';
}
