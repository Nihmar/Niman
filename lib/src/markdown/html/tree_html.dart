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
import 'package:niman/src/markdown/html/html_hooks.dart';
import 'package:niman/src/markdown/html/leaf_text.dart';
import 'package:niman/src/markdown/html/table_html.dart';
import 'package:niman/src/markdown/inline/inline_html.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/inline/link_references.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/task_box.dart';

/// Writes one note as HTML.
final class TreeHtml {
  /// A writer of [source], GFM's [extensions] on — extended autolinks and
  /// the tag filter — as in the app; off for the spec's examples of plain
  /// CommonMark, as `cmark-gfm` runs them.
  ///
  /// [appSyntax] off reads the blocks without the app's frontmatter and
  /// display math, as the specifications' examples are written.
  ///
  /// [hooks] draw what a page draws its own way: the export's code, its
  /// formulas, callouts and links.
  new(
    this.source, {
    this.extensions = true,
    this.appSyntax = true,
    this.hooks = const HtmlHooks(),
  }) : _body = _withoutLastBreak(source),
       _lines = _withoutLastBreak(source).split('\n');

  /// The note.
  final String source;

  /// Whether GFM's extensions are on.
  final bool extensions;

  /// Whether the app's own block syntax is read.
  final bool appSyntax;

  /// What a page draws its own way.
  final HtmlHooks hooks;

  /// The note without the line break that ends its last line: it ends a
  /// line, and opens none — kept, it was an empty last line, inside a fence
  /// left open to the end.
  final String _body;
  final List<String> _lines;

  static String _withoutLastBreak(String text) => text.endsWith('\r\n')
      ? text.substring(0, text.length - 2)
      : text.endsWith('\n')
      ? text.substring(0, text.length - 1)
      : text;
  StringBuffer _out = StringBuffer();
  int _last = 0x0A;
  final Map<String, LinkReference> _references = <String, LinkReference>{};
  final Map<String, FootnoteNode> _definitions = <String, FootnoteNode>{};
  late final Set<String> _footnoteKeys = _definitions.keys.toSet();
  late final FootnoteHtml _footnotes = FootnoteHtml(
    _definitions,
    xhtml: hooks.xhtml,
  );

  /// Each paragraph's inline text, the link reference definitions it
  /// starts with taken out.
  final Map<LeafNode, String> _paragraphs = Map<LeafNode, String>.identity();

  /// The note as HTML.
  String render() {
    final tree = BlockTree.of(_body, appSyntax: appSyntax);
    _collect(tree);
    _blocks(tree, tight: false);
    _section();
    return _out.toString();
  }

  /// What [write] writes, apart from the page: a callout's body, for the
  /// hooks to frame.
  String _captured(void Function() write) {
    final out = _out;
    final last = _last;
    _out = StringBuffer();
    _last = 0x0A;
    write();
    final captured = _out.toString();
    _out = out;
    _last = last;
    return captured;
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
        case QuoteNode(:final children, :final callout?):
          final body = _captured(() => _blocks(children, tight: false));
          final written = node.title;
          final title = written == null
              ? null
              : _inlineHtml(
                  LeafText.paragraph([
                    _lines[written.line].substring(written.start, written.end),
                  ]),
                );
          _cr();
          final drawn = hooks.callout(callout, body, title);
          if (drawn != null) {
            _write(drawn);
            _write('\n');
          } else {
            // The app's callout, where the page draws none of its own: a
            // quote, marked, its title a paragraph of its own.
            _write(
              '<blockquote class="callout" '
              'data-callout="${InlineHtml.escape(callout.type)}">\n'
              '<p class="callout-title">'
              '${title ?? InlineHtml.escape(callout.title)}</p>\n',
            );
            _write(body);
            _cr();
            _write('</blockquote>\n');
          }
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
      final task = TaskBox.of(text);
      if (task != null) {
        _write(
          task.checked
              ? '<input type="checkbox" checked="" disabled="" /> '
              : '<input type="checkbox" disabled="" /> ',
        );
        _paragraphs[first] = text.substring(task.length);
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
        if (blank && !_blank(child)) return false;
        // A blank line at the end of a block — a sublist's last item's
        // own — stands between it and the next one as much.
        blank = _blank(child) || _endsBlank(child);
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
    final drawn = _isBlock(leaf.kind) ? hooks.leaf(leaf, lines) : null;
    if (drawn != null) {
      _cr();
      _write(drawn);
      _write('\n');
      return false;
    }
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
        final text = atx
            ? LeafText.atxHeading(lines.single)
            : LeafText.setextHeading(lines);
        final id = hooks.headingId(text);
        _cr();
        _write(
          id == null ? '<h$level>' : '<h$level id="${InlineHtml.escape(id)}">',
        );
        _inline(text);
        _write('</h$level>\n');
      case BlockKind.thematicBreak:
        _cr();
        _write('<hr />\n');
      case BlockKind.fencedCode:
        _cr();
        _write(CodeHtml.fenced(lines));
      case BlockKind.indentedCode:
        _cr();
        _write(
          CodeHtml.indented(
            lines,
            starts: [
              for (final span in leaf.lines)
                LineSyntax.columnsTo(_lines[span.line], span.start),
            ],
            leftOver: leaf.leftOver,
          ),
        );
      case BlockKind.html:
        _cr();
        final html = lines.join('\n');
        _write(extensions ? InlineHtml.filterTags(html) : html);
        _write('\n');
      case BlockKind.table:
        _cr();
        final out = StringBuffer();
        TableHtml.write(out, lines, (text) => _inlineInto(out, text));
        _write(out.toString());
      case BlockKind.blank ||
          BlockKind.frontmatter ||
          BlockKind.quote ||
          BlockKind.listItem:
        break;
    }
    return false;
  }

  void _inline(String text) => _write(_inlineHtml(text));

  /// [text]'s inlines as HTML.
  String _inlineHtml(String text) {
    final out = StringBuffer();
    _inlineInto(out, text);
    return out.toString();
  }

  /// Whether a leaf of [kind] is a block a page may draw its own way.
  static bool _isBlock(BlockKind kind) =>
      kind == BlockKind.fencedCode ||
      kind == BlockKind.indentedCode ||
      kind == BlockKind.math ||
      kind == BlockKind.html;

  /// [text]'s inlines, parsed and written into [out].
  void _inlineInto(StringBuffer out, String text) {
    InlineHtml.write(
      out,
      InlineParser(
        text,
        references: _references,
        footnotes: _footnoteKeys,
        extendedAutolinks: extensions,
        appSyntax: appSyntax,
      ).parse(),
      footnote: _footnotes.reference,
      tagFilter: extensions,
      hooks: hooks,
    );
  }

  /// The footnotes cited, at the note's end.
  void _section() {
    if (_footnotes.cited.isEmpty) return;
    _cr();
    _write(
      '<section class="footnotes" '
      'data-footnotes${hooks.xhtml ? '=""' : ''}>\n<ol>\n',
    );
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
}
