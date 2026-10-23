/// What an exported page draws its own way, on the writer (`TreeHtml`):
/// the read view's forms — coloured code, formulas and diagrams as SVG, a
/// raw HTML block as its source, a callout's frame, wikilinks and embeds —
/// and the pictures and links the export points elsewhere (#24,
/// `docs/dev/block-tree.md` phase 7).
library;

import 'package:niman/src/export/html_blocks.dart';
import 'package:niman/src/export/html_spans.dart';
import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/export/todo_block_html.dart';
import 'package:niman/src/links/block_anchors.dart'
    show trailingBlockId, withoutTrailingBlockId;
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/fence_body.dart';
import 'package:niman/src/markdown/html/html_hooks.dart';
import 'package:niman/src/markdown/inline/inline_html.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';

/// A local Markdown note link's path, a `#` fragment or `?` query aside.
final RegExp _noteHref = RegExp(r'\.md(?:[#?].*)?$');

/// One page's drawing of what the writer leaves to it.
final class ExportHooks extends HtmlHooks {
  /// The page of [source], its formulas through [math].
  new(this.source, this.math) : _spans = HtmlSpans(source, math);

  /// What the page is built from: its pictures and its links.
  final NoteHtmlSource source;

  /// The page's formula renderer.
  final MathSvg math;

  final HtmlSpans _spans;

  /// The heading ids given so far: a second heading of one text gets
  /// `-2`, as pages exported before had it.
  final Set<String> _ids = <String>{};

  /// The block ids given so far.
  final Set<String> _blockIds = <String>{};

  /// Whether the page drew a diagram.
  bool usedDiagram = false;

  @override
  bool get xhtml => true;

  @override
  String? leaf(LeafNode leaf, List<String> lines) {
    switch (leaf.kind) {
      case BlockKind.fencedCode:
        final list = _todoList(lines);
        if (list != null) return list;
        final diagram = mermaidBlockHtml(lines);
        if (diagram != null) {
          usedDiagram = true;
          return diagram;
        }
        return fencedCodeHtml(lines);
      case BlockKind.math:
        return mathBlockHtml(lines.join('\n'), math);
      case BlockKind.html:
        return htmlSourceHtml(lines.join('\n'));
      case BlockKind.indentedCode ||
          BlockKind.paragraph ||
          BlockKind.heading ||
          BlockKind.table ||
          BlockKind.thematicBreak ||
          BlockKind.blank ||
          BlockKind.div ||
          BlockKind.frontmatter ||
          BlockKind.quote ||
          BlockKind.listItem:
        return null;
    }
  }

  /// The list a closed `todo` fence of [lines] is, as the export found it, or
  /// null for any other fence and for one that was not asked for (#1152).
  String? _todoList(List<String> lines) {
    final parts = fenceBody(lines);
    if (parts == null || !parts.closed) return null;
    if (parts.language.toLowerCase() != 'todo') return null;
    final printed = source.todoBlocks[todoBlockKey(parts.code)];
    return printed == null ? null : todoBlockHtml(printed);
  }

  @override
  String? callout(Callout callout, String body, String? title) =>
      calloutHtml(callout, body, titleHtml: title);

  @override
  ({String shown, String? anchor})? blockId(String text) {
    // The read view's rule and the scanner's, not a second one: the page
    // draws `Title` for `## Title ^abc`, and `abc` names the block (#928).
    final id = trailingBlockId(text);
    if (id == null) return null;
    return (
      shown: withoutTrailingBlockId(text),
      // The first block that carries an id owns it, as for the scanner.
      anchor: _blockIds.add(id) ? blockAnchor(id) : null,
    );
  }

  @override
  String? headingId(String text) {
    // [text] is what the page draws: `Title` for `## Title ^abc`, so the
    // heading's id is the one of `Title`, as the outline's entry for it is
    // (#912).
    return uniqueHeadingId(_ids, headingAnchor(text));
  }

  @override
  String? inline(InlineNode node) => switch (node) {
    MathNode(:final tex, :final display) =>
      _spans.formula(tex, InlineHtml.source(node), display: display).html,
    WikiLinkNode(:final inner, embed: true) => _spans.embed(inner).html,
    WikiLinkNode(:final inner) => _spans.wikilink(inner).html,
    TagNode() => _spans.tag(InlineHtml.source(node)).html,
    // The read view shows a tag it does not draw as the text it is, and so
    // does the page: a note's `<b>` is not markup it ever ran in the app.
    HtmlNode(:final html) => escapeHtml(html),
    _ => null,
  };

  @override
  String? linkTarget(String destination) {
    final target = _target(source.links, destination);
    if (target != null) return target;
    // A Markdown link to a note the page has no target for shows the text
    // it wrote, as a wikilink does: `[x](other.md)` on a one-note export
    // pointed at a file the page does not carry (E4).
    return _isNoteLink(destination) ? '' : null;
  }

  @override
  String? imageSource(String destination) =>
      _target(source.images, destination);

  /// What [targets] has for [written], as written or percent-decoded.
  static String? _target(Map<String, String> targets, String written) {
    final target = targets[written];
    if (target != null) return target;
    try {
      return targets[Uri.decodeFull(written)];
    } on FormatException {
      return null;
    }
  }

  /// Whether [href] names a local Markdown note, by its path; a fragment or
  /// a query does not change that, and an absolute URL is not one.
  static bool _isNoteLink(String href) {
    if (href.isEmpty) return false;
    final lower = href.toLowerCase();
    if (lower.startsWith('#') ||
        lower.startsWith('mailto:') ||
        lower.startsWith('data:') ||
        lower.contains('://')) {
      return false;
    }
    return _noteHref.hasMatch(lower);
  }
}

/// The `todo` fences a page holds, drawn nothing: what an export asks the
/// tasks about before the page is built (#1152).
final class TodoBlockSources extends HtmlHooks {
  /// Hooks that only collect.
  new();

  /// The source of each closed `todo` fence, in order, as written.
  final List<String> sources = <String>[];

  @override
  String? leaf(LeafNode leaf, List<String> lines) {
    if (leaf.kind != BlockKind.fencedCode) return '';
    final parts = fenceBody(lines);
    if (parts != null &&
        parts.closed &&
        parts.language.toLowerCase() == 'todo') {
      sources.add(parts.code);
    }
    return '';
  }
}

/// The pictures a page names, drawn nothing: what an export resolves before
/// the page is built.
final class PictureTargets extends HtmlHooks {
  /// Hooks that only collect.
  new();

  /// Each image's `src`, in order, as written.
  final List<String> images = <String>[];

  /// Each embed's target, in order, as written.
  final List<String> embeds = <String>[];

  @override
  String? leaf(LeafNode leaf, List<String> lines) => switch (leaf.kind) {
    // Nothing typeset, nothing coloured: the page is not kept.
    BlockKind.fencedCode || BlockKind.math || BlockKind.html => '',
    _ => null,
  };

  @override
  String? inline(InlineNode node) {
    if (node case WikiLinkNode(:final inner, embed: true)) {
      final target = parseWikiRef(inner).target;
      if (target.isNotEmpty) embeds.add(target);
    }
    return node is MathNode ? '' : null;
  }

  @override
  String? imageSource(String destination) {
    if (destination.isNotEmpty) images.add(destination);
    return null;
  }
}
