/// Converting a Markdown list into a `mindmap` fence (#530).
///
/// The list is read off the block scan, not off the text: the scan already
/// knows a list item from a line inside a code fence or a front matter, an
/// item's continuation lines, the blank lines of a loose list, and how deep
/// an item sits whatever its indentation. And it reads only the list's own
/// lines, never the note's — the caller replaces that range as one
/// undoable edit.
///
/// A single outermost item is the root; several get a root of their own to
/// hang from.
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
/// the line is not in a list item outside any quote.
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
  if (at == null || !_isItem(at)) return null;
  final family = _familyAbove(at, blockOf, buffer);
  final items = <Block>[at];
  for (var block = blockOf(at.startLine - 1); block != null;) {
    if (!_inList(block) || !_sameList(block, family, buffer)) break;
    if (_isItem(block)) items.insert(0, block);
    block = blockOf(block.startLine - 1);
  }
  for (var block = blockOf(at.endLine); block != null;) {
    if (!_inList(block) || !_sameList(block, family, buffer)) break;
    if (_isItem(block)) items.add(block);
    block = blockOf(block.endLine);
  }
  return (
    startLine: items.first.startLine,
    endLine: items.last.endLine,
    fence: ['```mermaid', 'mindmap', ..._nodes(items, buffer), '```'],
  );
}

/// The mind map's node lines, two spaces a level.
List<String> _nodes(List<Block> items, SourceBuffer buffer) {
  final least = items.map((item) => item.listDepth).reduce(math.min);
  final roots = items.where((item) => item.listDepth == least).length;
  final nodes = <String>[];
  // Several outermost items hang from a root of their own.
  final shift = roots > 1 ? 1 : 0;
  if (shift == 1) nodes.add('  root');
  for (var i = 0; i < items.length; i++) {
    final depth = items[i].listDepth - least + shift;
    nodes.add('${'  ' * (depth + 1)}${_node(i, _label(items[i], buffer))}');
  }
  return nodes;
}

/// Whether [block] is a list item outside any quote.
bool _isItem(Block block) =>
    block.kind == BlockKind.listItem && block.quoteDepth == 0;

/// Whether [block] belongs to a list: an item, or a blank line inside one.
bool _inList(Block block) =>
    _isItem(block) || (block.kind == BlockKind.blank && block.listDepth >= 0);

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

/// An item's text, its continuation lines joined to its first.
String _label(Block item, SourceBuffer buffer) {
  final head = listItemHead(buffer.lineAt(item.startLine));
  final words = <String>[
    if (head != null) head.content.trim(),
    for (var line = item.startLine + 1; line < item.endLine; line++)
      buffer.lineAt(line).trim(),
  ].where((part) => part.isNotEmpty).join(' ');
  return words.isEmpty ? (head?.marker ?? '') : words;
}

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
