/// A note written as HTML from its block tree and our inline parser, the
/// way `cmark-gfm`'s HTML renderer writes it (`html.c` and the GFM
/// extensions) — the form the specifications' examples are in
/// (`docs/dev/block-tree.md`).
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/html/code_html.dart';
import 'package:niman/src/markdown/html/footnote_html.dart';
import 'package:niman/src/markdown/html/leaf_text.dart';
import 'package:niman/src/markdown/html/table_html.dart';
import 'package:niman/src/markdown/inline/inline_html.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/inline/link_references.dart';

/// Writes one note as HTML.
final class TreeHtml {
  /// A writer of [source].
  new(this.source) : _lines = source.split('\n');

  /// The note.
  final String source;
  final List<String> _lines;
  final StringBuffer _out = StringBuffer();
  int _last = 0x0A;
  final Map<String, LinkReference> _references = <String, LinkReference>{};
  final Map<String, FootnoteNode> _definitions = <String, FootnoteNode>{};
  late final FootnoteHtml _footnotes = FootnoteHtml(_definitions);

  /// Each paragraph's inline text, the link reference definitions it
  /// starts with taken out.
  final Map<LeafNode, String> _paragraphs = Map<LeafNode, String>.identity();

  /// The note as HTML.
  String render() {
    final tree = BlockTree.of(source);
    _collect(tree);
    _blocks(tree, tight: false);
    _section();
    return _out.toString();
  }

  void _write(String text) {
    if (text.isEmpty) return;
    _out.write(text);
    _last = text.codeUnitAt(text.length - 1);
  }

  /// A line break, unless the output is at the start of a line.
  void _cr() {
    if (_out.isNotEmpty && _last != 0x0A) _write('\n');
  }

  /// The definitions a note's inlines resolve against, wherever they are.
  void _collect(List<BlockNode> nodes) {
    for (final node in nodes) {
      switch (node) {
        case QuoteNode(:final children) || ItemNode(:final children):
          _collect(children);
        case FootnoteNode(:final label, :final children):
          _definitions.putIfAbsent(LinkReferences.normalize(label), () => node);
          _collect(children);
        case ListNode(:final items):
          _collect(items);
        case LeafNode(:final kind) when kind == BlockKind.paragraph:
          final text = LeafText.paragraph(LeafText.linesOf(node, _lines));
          final rest = LinkReferences.parseInto(text, _references);
          _paragraphs[node] = text.substring(rest);
        case LeafNode():
          break;
      }
    }
  }

  /// [nodes] as HTML, their paragraphs bare in a [tight] list's item;
  /// [tail] written in the last paragraph, or after the last block.
  void _blocks(List<BlockNode> nodes, {required bool tight, String? tail}) {
    var last = nodes.length - 1;
    while (last >= 0 && !_draws(nodes[last])) {
      last--;
    }
    for (var at = 0; at < nodes.length; at++) {
      final node = nodes[at];
      final mine = at == last ? tail : null;
      switch (node) {
        case QuoteNode(:final children):
          _cr();
          _write('<blockquote>\n');
          _blocks(children, tight: false);
          _cr();
          _write('</blockquote>\n');
        case ListNode():
          _list(node);
        case ItemNode():
          _item(node, tight: tight);
        case FootnoteNode():
          break;
        case LeafNode():
          if (!_leaf(node, tight: tight, tail: mine) && mine != null) {
            _write(mine);
            _write('\n');
          }
      }
      if (at == last && mine != null && node is! LeafNode) {
        _write(mine);
        _write('\n');
      }
    }
    if (last < 0 && tail != null) {
      _write(tail);
      _write('\n');
    }
  }

  /// Whether [node] writes anything.
  bool _draws(BlockNode node) => switch (node) {
    LeafNode(:final kind) when kind == BlockKind.blank => false,
    LeafNode(:final kind) when kind == BlockKind.paragraph =>
      (_paragraphs[node] ?? '').isNotEmpty,
    FootnoteNode() => false,
    _ => true,
  };

  void _list(ListNode list) {
    final tight = _tight(list);
    _cr();
    if (!list.ordered) {
      _write('<ul>\n');
    } else if (list.start != 1) {
      _write('<ol start="${list.start}">\n');
    } else {
      _write('<ol>\n');
    }
    for (final item in list.items) {
      _item(item, tight: tight);
    }
    _write(list.ordered ? '</ol>\n' : '</ul>\n');
  }

  void _item(ItemNode item, {required bool tight}) {
    _cr();
    _write('<li>');
    final first = item.children.isEmpty ? null : item.children.first;
    if (first is LeafNode && first.kind == BlockKind.paragraph) {
      final text = _paragraphs[first] ?? '';
      final task = _task.matchAsPrefix(text);
      if (task != null) {
        _write(
          task.group(1) == ' '
              ? '<input type="checkbox" disabled="" /> '
              : '<input type="checkbox" checked="" disabled="" /> ',
        );
        _paragraphs[first] = text.substring(task.end);
      }
    }
    _blocks(item.children, tight: tight);
    _write('</li>\n');
  }

  /// Whether [list] is tight: no blank line between its items, nor between
  /// two blocks of one of them.
  static bool _tight(ListNode list) {
    for (var at = 0; at < list.items.length; at++) {
      final children = list.items[at].children;
      var blank = false;
      for (final child in children) {
        if (_blank(child)) {
          blank = true;
        } else if (blank) {
          return false;
        }
      }
      if (at < list.items.length - 1 && _endsBlank(list.items[at])) {
        return false;
      }
    }
    return true;
  }

  static bool _blank(BlockNode node) =>
      node is LeafNode && node.kind == BlockKind.blank;

  static bool _endsBlank(BlockNode node) => switch (node) {
    LeafNode() => node.kind == BlockKind.blank,
    ListNode(:final items) => _endsBlank(items.last),
    ItemNode(:final children) =>
      children.isNotEmpty && _endsBlank(children.last),
    _ => false,
  };

  /// Writes [leaf]; whether it took [tail].
  bool _leaf(LeafNode leaf, {required bool tight, String? tail}) {
    final lines = LeafText.linesOf(leaf, _lines);
    switch (leaf.kind) {
      case BlockKind.paragraph || BlockKind.math:
        final text = leaf.kind == BlockKind.math
            ? LeafText.paragraph(lines)
            : _paragraphs[leaf] ?? '';
        if (text.isEmpty) return false;
        if (!tight) {
          _cr();
          _write('<p>');
        }
        _inline(text);
        if (tail != null) _write(' $tail');
        if (!tight) _write('</p>\n');
        return tail != null;
      case BlockKind.heading:
        final atx = lines.length == 1;
        final level = leaf.headingLevel;
        _cr();
        _write('<h$level>');
        _inline(
          atx
              ? LeafText.atxHeading(lines.single)
              : LeafText.setextHeading(lines),
        );
        _write('</h$level>\n');
      case BlockKind.thematicBreak:
        _cr();
        _write('<hr />\n');
      case BlockKind.fencedCode:
        _cr();
        _write(CodeHtml.fenced(lines));
      case BlockKind.indentedCode:
        _cr();
        _write(CodeHtml.indented(lines));
      case BlockKind.html:
        _cr();
        _write(InlineHtml.filterTags(lines.join('\n')));
        _write('\n');
      case BlockKind.table:
        _cr();
        final out = StringBuffer();
        TableHtml.write(out, lines, (text) {
          final cell = StringBuffer();
          InlineHtml.write(
            cell,
            InlineParser(
              text,
              references: _references,
              footnotes: _definitions.keys.toSet(),
            ).parse(),
            footnote: _footnotes.reference,
          );
          out.write(cell);
        });
        _write(out.toString());
      case BlockKind.blank ||
          BlockKind.frontmatter ||
          BlockKind.quote ||
          BlockKind.listItem:
        break;
    }
    return false;
  }

  void _inline(String text) {
    final cell = StringBuffer();
    InlineHtml.write(
      cell,
      InlineParser(
        text,
        references: _references,
        footnotes: _definitions.keys.toSet(),
      ).parse(),
      footnote: _footnotes.reference,
    );
    _write(cell.toString());
  }

  /// The footnotes cited, at the note's end.
  void _section() {
    if (_footnotes.cited.isEmpty) return;
    _cr();
    _write('<section class="footnotes" data-footnotes>\n<ol>\n');
    for (var at = 0; at < _footnotes.cited.length; at++) {
      final key = _footnotes.cited[at];
      final definition = _definitions[key];
      if (definition == null) continue;
      _write('<li id="fn-${_footnotes.idOf(key)}">\n');
      _blocks(
        definition.children,
        tight: false,
        tail: _footnotes.backrefs(key),
      );
      _cr();
      _write('</li>\n');
    }
    _write('</ol>\n</section>\n');
  }

  /// A task item's box: `[ ]`, `[x]` or `[X]` and the white space after
  /// it.
  static final RegExp _task = RegExp(r'\[([ xX])\][ \t]+');
}
