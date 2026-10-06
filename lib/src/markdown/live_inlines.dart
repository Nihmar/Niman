/// A block's inline constructs on its lines, for `live` and source mode:
/// our parser's nodes (`docs/dev/block-tree.md`, phase 6), each put back
/// on the note through its leaf's [SourceMap], split into its markers —
/// what `live` hides — and its text.
library;

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/source_map.dart';

/// A construct's piece of a line, before the line's pieces are made
/// disjoint: [depth] says which one a stretch of the line goes to, the
/// deepest.
final class InlinePiece {
  /// A piece of [kind] over columns `[start, end)` of its line.
  const new(this.kind, this.start, this.end, this.depth, {this.marker = false});

  /// What it is.
  final TokenKind kind;

  /// Its first column.
  final int start;

  /// One past its last column.
  final int end;

  /// How deep its construct is: inside another, deeper.
  final int depth;

  /// Whether it is the construct's syntax — a `**`, a link's `](href)`.
  final bool marker;
}

/// A picture on a line: where its source is, in the line's columns, what
/// it points at, what stands in for it, and the source as written.
typedef LinePicture = ({
  int start,
  int end,
  String target,
  String display,
  String source,
});

/// A link on a line: its columns and where it goes.
typedef LineLink = ({int start, int end, String href});

/// A block's constructs, line by line, its lines counted from the block's
/// first: the same answer wherever the block moves to.
final class LiveInlines {
  /// The constructs of [read], whose first line is [first].
  factory of(ReadBlock read, int first) {
    final out = LiveInlines._(first);
    void visit(BlockNode node) {
      switch (node) {
        case QuoteNode(:final children):
          final title = read.titleOf(node);
          if (title != null) out._read(title);
          children.forEach(visit);
        case ItemNode(:final children) || FootnoteNode(:final children):
          children.forEach(visit);
        case ListNode(:final items):
          items.forEach(visit);
        case LeafNode():
          final leaf = read.leaf(node);
          final inline = leaf.inline;
          if (inline != null) out._read(inline);
          for (final row in leaf.rows) {
            row.forEach(out._read);
          }
      }
    }

    visit(read.node);
    return out;
  }

  new _(this._first);

  final int _first;
  final Map<int, List<InlinePiece>> _pieces = <int, List<InlinePiece>>{};
  final Map<int, List<LinePicture>> _pictures = <int, List<LinePicture>>{};
  final Map<int, List<LineLink>> _links = <int, List<LineLink>>{};

  /// The pieces on line [index] of the block.
  List<InlinePiece> piecesOn(int index) =>
      _pieces[index] ?? const <InlinePiece>[];

  /// The pictures on line [index] of the block, in order.
  List<LinePicture> picturesOn(int index) =>
      _pictures[index] ?? const <LinePicture>[];

  /// The links on line [index] of the block.
  List<LineLink> linksOn(int index) => _links[index] ?? const <LineLink>[];

  /// Reads [inline]'s nodes, without recursion: emphasis thousands deep is
  /// a note's to write.
  void _read(ReadInline inline) {
    final text = inline.text;
    final map = inline.map;
    // A cell's `\` before its `|` is syntax whatever it stands in: `\|` in
    // a code span is a `|` of the code, as `cmark-gfm` reads a table.
    for (final gap in map.gaps()) {
      (_pieces[gap.line - _first] ??= <InlinePiece>[]).add(
        InlinePiece(TokenKind.plain, gap.start, gap.end, _gap, marker: true),
      );
    }
    final stack = <(InlineNode, int)>[
      for (final node in inline.nodes.reversed) (node, 0),
    ];
    void add(
      TokenKind kind,
      int from,
      int to,
      int depth, {
      bool marker = false,
    }) {
      if (from >= to) return;
      for (final span in map.spans(from, to)) {
        (_pieces[span.line - _first] ??= <InlinePiece>[]).add(
          InlinePiece(kind, span.start, span.end, depth, marker: marker),
        );
      }
    }

    void construct(
      TokenKind kind,
      InlineNode node,
      int open,
      int close,
      int depth,
    ) {
      add(kind, node.start, open, depth, marker: true);
      add(kind, open, close, depth);
      add(kind, close, node.end, depth, marker: true);
    }

    void children(List<InlineNode> nodes, int depth) {
      for (var at = nodes.length - 1; at >= 0; at--) {
        stack.add((nodes[at], depth));
      }
    }

    while (stack.isNotEmpty) {
      final (node, depth) = stack.removeLast();
      switch (node) {
        case EmphasisNode(children: final inner):
          construct(TokenKind.italic, node, _open(node), _close(node), depth);
          children(inner, depth + 1);
        case StrongNode(children: final inner):
          construct(TokenKind.bold, node, _open(node), _close(node), depth);
          children(inner, depth + 1);
        case StrikethroughNode(children: final inner):
          construct(TokenKind.strike, node, _open(node), _close(node), depth);
          children(inner, depth + 1);
        case HighlightNode(children: final inner):
          construct(
            TokenKind.highlight,
            node,
            _open(node),
            _close(node),
            depth,
          );
          children(inner, depth + 1);
        case StyledNode(:final tag, children: final inner):
          final kind = switch (tag) {
            'u' => TokenKind.underline,
            'sup' => TokenKind.superscript,
            _ => TokenKind.subscript,
          };
          final open = text.indexOf('>', node.start) + 1;
          final close = text.lastIndexOf('<', node.end - 1);
          construct(kind, node, open, close, depth);
          children(inner, depth + 1);
        case LinkNode(:final destination, children: final inner):
          final (open, close) = _linkText(node, text);
          construct(TokenKind.link, node, open, close, depth);
          children(inner, depth + 1);
          _link(node, destination, map);
        case ImageNode(children: final inner):
          final close = inner.isEmpty ? node.start + 2 : inner.last.end;
          construct(TokenKind.image, node, node.start + 2, close, depth);
          children(inner, depth + 1);
          _picture(
            node,
            node.destination,
            ReadInline.plainOf(inner),
            text,
            map,
          );
        case CodeNode():
          final ticks = _run(text, node.start, 0x60);
          construct(
            TokenKind.codeInline,
            node,
            node.start + ticks,
            node.end - ticks,
            depth,
          );
        case MathNode(:final display):
          final dollars = display ? 2 : 1;
          construct(
            TokenKind.mathInline,
            node,
            node.start + dollars,
            node.end - dollars,
            depth,
          );
        case WikiLinkNode(:final inner, :final embed):
          construct(
            TokenKind.wikilink,
            node,
            node.start + (embed ? 3 : 2),
            node.end - 2,
            depth,
          );
          if (embed) {
            final pipe = inner.indexOf('|');
            final target = (pipe >= 0 ? inner.substring(0, pipe) : inner)
                .trim();
            final alias = pipe >= 0 ? inner.substring(pipe + 1).trim() : '';
            _picture(node, target, alias.isEmpty ? target : alias, text, map);
          }
        case TagNode():
          add(TokenKind.tag, node.start, node.end, depth);
        case FootnoteRefNode():
          // `[^label]`: its label raised, the brackets its syntax.
          add(TokenKind.superscript, node.start, node.end, depth);
          construct(
            TokenKind.link,
            node,
            node.start + 2,
            node.end - 1,
            depth + 1,
          );
        case TextNode():
          // A backslash escape: the backslash is syntax, the character it
          // escapes the text — `\$5` reads `$5`.
          if (node.end - node.start == 2 &&
              text.codeUnitAt(node.start) == 0x5C) {
            add(
              TokenKind.plain,
              node.start,
              node.start + 1,
              depth,
              marker: true,
            );
          }
        case HtmlNode() || SoftBreakNode() || HardBreakNode():
          break;
      }
    }
  }

  /// The depth a cell's escaping `\` wins at: deeper than any construct it
  /// stands in.
  static const int _gap = 1 << 16;

  /// Where a delimited construct's text starts: past its opening run.
  static int _open(InlineContainer node) =>
      node.children.isEmpty ? node.end : node.children.first.start;

  /// Where it ends: before its closing run.
  static int _close(InlineContainer node) =>
      node.children.isEmpty ? node.end : node.children.last.end;

  /// A link's text: between `[` and `]`, inside `<` and `>` of an
  /// autolink, the whole of a bare one.
  static (int, int) _linkText(LinkNode node, String text) {
    if (node.auto) {
      return text.codeUnitAt(node.start) == 0x3C
          ? (node.start + 1, node.end - 1)
          : (node.start, node.end);
    }
    final open = node.start + 1;
    return (open, node.children.isEmpty ? open : node.children.last.end);
  }

  /// How many [char]s [text] has at [at].
  static int _run(String text, int at, int char) {
    var end = at;
    while (end < text.length && text.codeUnitAt(end) == char) {
      end++;
    }
    return end - at;
  }

  /// [node], a link to [href], on the lines it covers.
  void _link(InlineNode node, String href, SourceMap map) {
    for (final span in map.spans(node.start, node.end)) {
      (_links[span.line - _first] ??= <LineLink>[]).add((
        start: span.start,
        end: span.end,
        href: href,
      ));
    }
  }

  /// [node], a picture of [target] shown as [display], when it is on one
  /// line.
  void _picture(
    InlineNode node,
    String target,
    String display,
    String text,
    SourceMap map,
  ) {
    final spans = map.spans(node.start, node.end);
    if (spans.length != 1) return;
    final span = spans.single;
    (_pictures[span.line - _first] ??= <LinePicture>[]).add((
      start: span.start,
      end: span.end,
      target: target,
      display: display,
      source: text.substring(node.start, node.end),
    ));
  }
}
