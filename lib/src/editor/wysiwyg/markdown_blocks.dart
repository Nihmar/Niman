import 'dart:convert';

import 'package:copist/src/editor/wysiwyg/markdown_parse.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:markdown/markdown.dart' as md;

/// One top-level block of a note: the exact bytes it came from and whether
/// the codec can represent it in the WYSIWYG document.
final class MarkdownBlock {
  /// Creates a block.
  const new({
    required this.source,
    required this.tag,
    required this.opaque,
    this.node,
    this.level = 0,
  });

  /// The exact source slice, including its trailing newline when the file
  /// has one.
  final String source;

  /// The top-level tag: p, h1..h6, ul, ol, blockquote, pre, or raw.
  final String tag;

  /// True when the block is kept verbatim as an opaque embed.
  final bool opaque;

  /// The parsed element, or null for a raw (HTML/text) block.
  final md.Element? node;

  /// The heading level for h1..h6, else 0.
  final int level;
}

/// The top-level tags the codec can turn into Quill lines.
const Set<String> _blockTags = <String>{
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'ul',
  'ol',
  'blockquote',
  'pre',
};

/// Splits [markdown] into top-level blocks.
///
/// The parser is the preview's and the boundaries are the scroll map's
/// [BlockLocator]. When the two disagree about the count, the whole note
/// becomes one opaque block rather than risk a silent mis-slice.
List<MarkdownBlock> splitMarkdownBlocks(String markdown) {
  if (markdown.isEmpty) return const <MarkdownBlock>[];
  final nodes = parseMarkdownDocument(markdown);
  final lines = const LineSplitter().convert(markdown);
  final starts = BlockLocator().locate(lines);
  if (starts.length != nodes.length) {
    return <MarkdownBlock>[
      MarkdownBlock(source: markdown, tag: 'raw', opaque: true),
    ];
  }
  final offsets = <int>[];
  var offset = 0;
  for (final line in lines) {
    offsets.add(offset);
    offset += line.length + 1;
  }
  final blocks = <MarkdownBlock>[];
  for (var i = 0; i < nodes.length; i++) {
    final node = nodes[i];
    final tag = node is md.Element ? node.tag : 'raw';
    final supported =
        node is md.Element && _blockTags.contains(tag) && _isSupported(node);
    final end = i + 1 < starts.length
        ? offsets[starts[i + 1]]
        : markdown.length;
    blocks.add(
      MarkdownBlock(
        source: markdown.substring(offsets[starts[i]], end),
        tag: tag,
        opaque: !supported,
        node: node is md.Element ? node : null,
        level: _headingLevel(tag),
      ),
    );
  }
  return blocks;
}

int _headingLevel(String tag) {
  if (tag.length == 2 && tag.startsWith('h')) {
    return int.tryParse(tag.substring(1)) ?? 0;
  }
  return 0;
}

/// True when every child of [element] has a Quill representation.
bool _isSupported(md.Element element) {
  if (element.tag == 'pre') return true;
  for (final child in element.children ?? const <md.Node>[]) {
    if (child is md.Text) continue;
    if (child is! md.Element) return false;
    switch (child.tag) {
      case 'strong':
      case 'em':
      case 'del':
      case 'code':
      case 'a':
      case 'input':
      case 'p':
        break;
      case 'li':
      case 'ul':
      case 'ol':
        break;
      default:
        return false;
    }
    if (!_isSupported(child)) return false;
  }
  return true;
}
