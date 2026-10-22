/// A note written as HTML from its block tree and our inline parser, the
/// way `cmark-gfm`'s HTML renderer writes it (`html.c` and the GFM
/// extensions) — the form the specifications' examples are in
/// (`docs/dev/block-tree.md`).
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/column_layout.dart';
import 'package:niman/src/markdown/html/code_html.dart';
import 'package:niman/src/markdown/html/footnote_html.dart';
import 'package:niman/src/markdown/html/html_definitions.dart';
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
  ///
  /// [shared] makes [source] one piece of a larger note: its link
  /// references and footnotes are the whole note's ([HtmlDefinitions],
  /// filled by [collect] over every piece first), its citations are counted
  /// across the pieces, and the footnotes' section is not written here:
  /// the caller writes it once, after the last piece.
  new(
    this.source, {
    this.extensions = true,
    this.appSyntax = true,
    this.hooks = const HtmlHooks(),
    HtmlDefinitions? shared,
  }) : _body = _withoutLastBreak(source),
       _lines = _withoutLastBreak(source).split('\n'),
       _shared = shared != null,
       _defs = shared ?? HtmlDefinitions(xhtml: hooks.xhtml);

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
  final bool _shared;
  final HtmlDefinitions _defs;
  late final Set<String> _footnoteKeys = _defs.definitions.keys.toSet();

  /// Each paragraph's inline text, the link reference definitions it
  /// starts with taken out.
  final Map<LeafNode, String> _paragraphs = Map<LeafNode, String>.identity();

  /// The note as HTML.
  String render() {
    final tree = BlockTree.of(_body, appSyntax: appSyntax);
    _collect(tree);
    _blocks(tree, tight: false);
    if (!_shared) {
      final section = _defs.footnotes.section(_defs.bodies);
      if (section.isNotEmpty) {
        _cr();
        _write(section);
      }
    }
    return _out.toString();
  }

  /// Only reads the definitions [source] holds into the shared set, writing
  /// nothing: the first pass over a note's pieces, so that a link or a
  /// footnote in one resolves against a definition in another.
  void collect() => _collect(BlockTree.of(_body, appSyntax: appSyntax));

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
          _defs.definitions.putIfAbsent(
            LinkReferences.normalize(label),
            () => node,
          );
          _collect(children);
        case ListNode(:final items):
          _collect(items);
        case ColumnsNode(:final columns):
          _collect(columns);
        case ColumnNode(:final children):
          _collect(children);
        case LeafNode(:final kind) when kind == BlockKind.paragraph:
          final text = LeafText.paragraph(LeafText.linesOf(node, _lines));
          final rest = LinkReferences.parseInto(text, _defs.references);
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
        case ColumnsNode():
          _columns(node);
        case ColumnNode(:final children):
          _blocks(children, tight: false);
        case FootnoteNode(:final children):
          // The first definition of a label is the one written; the others
          // are written too, for the citations in them to count.
          final body = _captured(
            () => _blocks(
              children,
              tight: false,
              tail: FootnoteHtml.backrefsMark,
            ),
          );
          _defs.bodies.putIfAbsent(
            LinkReferences.normalize(node.label),
            () => body,
          );
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

  /// A `columns` div (#729) as the page lays it out: a flex row that
  /// wraps, each column growing by its share (`pageStyle`).
  void _columns(ColumnsNode columns) {
    final shares = ColumnLayout.shares([
      for (final column in columns.columns) column.width,
    ]);
    _cr();
    _write('<div class="columns">\n');
    for (var at = 0; at < columns.columns.length; at++) {
      _write('<div class="column" style="flex-grow:${_share(shares[at])}">\n');
      _blocks(columns.columns[at].children, tight: false);
      _cr();
      _write('</div>\n');
    }
    _write('</div>\n');
  }

  /// A share as CSS takes it: a whole number bare, a fraction to four
  /// places, its trailing zeros off.
  static String _share(double share) {
    if (share == share.roundToDouble()) return share.round().toString();
    return share
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

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
  /// two blocks of one of them — a block that writes nothing, a paragraph
  /// of definitions, being none.
  bool _tight(ListNode list) {
    for (var at = 0; at < list.items.length; at++) {
      // A blank line before the item's first block stands between none.
      var started = false;
      var blank = false;
      for (final child in _kept(list.items[at].children)) {
        if (_blank(child)) {
          blank = started;
          continue;
        }
        if (blank) return false;
        started = true;
        // A blank line at the end of a block — a sublist's last item's
        // own — stands between it and the next one as much.
        blank = _endsBlank(child);
      }
      if (at < list.items.length - 1 && _endsBlank(list.items[at])) {
        return false;
      }
    }
    return true;
  }

  static bool _blank(BlockNode node) =>
      node is LeafNode && node.kind == BlockKind.blank;

  /// [children] as `cmark` keeps them: a block that writes nothing is
  /// taken off, its blank lines left standing where it was — but for a
  /// footnote definition, moved to the end only after the lists are told
  /// tight or loose.
  Iterable<BlockNode> _kept(List<BlockNode> children) => children.where(
    (child) => _blank(child) || child is FootnoteNode || _draws(child),
  );

  bool _endsBlank(BlockNode node) => switch (node) {
    LeafNode() => node.kind == BlockKind.blank,
    ListNode(:final items) => _endsBlank(items.last),
    ItemNode(:final children) => switch (_kept(children).lastOrNull) {
      final last? => _endsBlank(last),
      null => false,
    },
    _ => false,
  };

  /// Writes [leaf]; whether it took [tail].
  bool _leaf(LeafNode leaf, {required bool tight, String? tail}) {
    final lines = LeafText.linesOf(leaf, _lines);
    final drawn = _isBlock(leaf.kind)
        ? hooks.leaf(
            leaf,
            leaf.kind == BlockKind.fencedCode
                ? LeafText.withLeftOver(leaf, lines)
                : lines,
          )
        : null;
    if (drawn != null) {
      _cr();
      _write(drawn);
      _write('\n');
      return false;
    }
    switch (leaf.kind) {
      case BlockKind.paragraph || BlockKind.math:
        final written = leaf.kind == BlockKind.math
            ? LeafText.paragraph(lines)
            : _paragraphs[leaf] ?? '';
        if (written.isEmpty) return false;
        // A trailing ` ^id` is the block's name for a link, not prose: the
        // page leaves it out, as the read view does, and keeps the name as
        // an `id` (#928).
        final block = leaf.kind == BlockKind.paragraph
            ? hooks.blockId(written)
            : null;
        final text = block?.shown ?? written;
        final anchor = block?.anchor;
        if (text.isEmpty) {
          // A line that is only an id names the block above it: nothing
          // drawn, the name kept where it stands.
          if (anchor != null) {
            if (!tight) _cr();
            _write('<span id="${InlineHtml.escape(anchor)}"></span>');
            if (!tight) _write('\n');
          }
          return false;
        }
        if (!tight) {
          _cr();
          _write(
            anchor == null ? '<p>' : '<p id="${InlineHtml.escape(anchor)}">',
          );
        }
        _write(_named(_inlineHtml(text), anchor, wrap: tight));
        if (tail != null) _write(' $tail');
        if (!tight) _write('</p>\n');
        return tail != null;
      case BlockKind.heading:
        final atx = lines.length == 1;
        final level = leaf.headingLevel;
        final written = atx
            ? LeafText.atxHeading(lines.single)
            : LeafText.setextHeading(lines);
        final block = hooks.blockId(written);
        final text = block?.shown ?? written;
        final id = hooks.headingId(text);
        _cr();
        _write(
          id == null ? '<h$level>' : '<h$level id="${InlineHtml.escape(id)}">',
        );
        // The heading's own `id` is its text's; the block's name rides on
        // a span around the text, for a link to the block to land.
        _write(_named(_inlineHtml(text), block?.anchor, wrap: true));
        _write('</h$level>\n');
      case BlockKind.thematicBreak:
        _cr();
        _write('<hr />\n');
      case BlockKind.fencedCode:
        _cr();
        _write(CodeHtml.fenced(LeafText.withLeftOver(leaf, lines)));
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
          BlockKind.div ||
          BlockKind.frontmatter ||
          BlockKind.quote ||
          BlockKind.listItem:
        break;
    }
    return false;
  }

  /// [html] named [anchor], when it has one and [wrap] says the block has no
  /// element to carry the name (a heading has its own `id`, a tight list
  /// item's paragraph no element at all): a span around it.
  static String _named(String html, String? anchor, {required bool wrap}) =>
      anchor == null || !wrap
      ? html
      : '<span id="${InlineHtml.escape(anchor)}">$html</span>';

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
        references: _defs.references,
        footnotes: _footnoteKeys,
        extendedAutolinks: extensions,
        appSyntax: appSyntax,
      ).parse(),
      footnote: _defs.footnotes.reference,
      tagFilter: extensions,
      hooks: hooks,
    );
  }
}
