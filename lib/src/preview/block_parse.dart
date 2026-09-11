// The preview's two-phase parse.
//
// The old whole-document parse cost 390 ms on the 931 KB note (bench,
// /tmp/niman/geo_bench): 4 % was the block phase (BlockParser + footnote
// gathering + HTML tables) and 96 % the inline phase (the package's inline
// parser over every block's text). This file splits the two: [parseBlocks]
// runs only the block phase (14 ms there) and leaves each block's inlines
// as raw [md.UnparsedContent] leaves; [withInlines] runs the inline phase
// for a single block when that block is about to be drawn (~0.1 ms), so the
// preview pays for the blocks it shows instead of the whole document.
//
// The WYSIWYG codec keeps the full parse ([parseMarkdownDocument]): a
// round trip needs every inline in place, once per edit.
import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

import 'package:niman/src/preview/html_table.dart';
import 'package:niman/src/preview/math_syntax.dart';
import 'package:niman/src/preview/wikilink.dart';

/// The parser the preview parses with: GFM plus the note's math and link
/// extras. One construction shared by the preview (block phase +
/// per-block inlines) and the WYSIWYG codec (full inlines) so the two
/// cannot drift apart.
md.Document makeDocument() => md.Document(
  blockSyntaxes: <md.BlockSyntax>[
    const MathBlockSyntax(),
    ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
  ],
  inlineSyntaxes: [EmbedInlineSyntax(), WikilinkInlineSyntax()],
  extensionSet: md.ExtensionSet.gitHubFlavored,
  encodeHtml: false,
);

/// The top-level blocks of [source], with the inlines left raw
/// ([md.UnparsedContent] leaves) and footnote definitions gathered into the
/// trailing `section.footnotes` block the preview draws as one.
///
/// This is the block phase of the markdown parse — the only stage the
/// preview pays up front. It is not a full parse: [withInlines] runs the
/// inline phase for a single block when that block builds, producing the
/// same nodes the old whole-document parse produced for that block.
List<md.Node> parseBlocks(String source) {
  final doc = makeDocument();
  final nodes = md.BlockParser(
    const LineSplitter().convert(source).map(md.Line.new).toList(),
    doc,
  ).parseLines();
  return _gatherFootnotes(nodes);
}

/// Seeds the inline-phase state [withInlines] needs from the whole
/// document: the footnote state into [doc].
///
/// Inlines run per block — the visible blocks first, out of order — so the
/// state a whole-document parse would have accumulated is fixed here
/// instead: the block phase seeds `footnoteReferences` with 0 on each
/// definition (and the references it meets count up from there), and the
/// labels are numbered in document order. Both are read from the trailing
/// `section.footnotes` that [parseBlocks] appended.
void prepareInlines(md.Document doc, List<md.Node> nodes) {
  for (final node in nodes) {
    if (node is! md.Element || node.tag != 'section') continue;
    for (final child in node.children ?? const <md.Node>[]) {
      if (child is! md.Element || child.tag != 'ol') continue;
      for (final item in child.children ?? const <md.Node>[]) {
        final label = item is md.Element ? item.footnoteLabel : null;
        if (label != null) {
          doc.footnoteReferences[label] = 0;
          doc.footnoteLabels.add(label.toLowerCase());
        }
      }
    }
  }
}

/// The inline phase of a single top-level block: [doc] parses its raw
/// leaves, then the two block-specific transforms run on the result (inline
/// math, HTML tables) — the same nodes the block got inside the old
/// whole-document parse, at the cost of the block alone.
List<md.Node> withInlines(md.Document doc, md.Node block) {
  List<md.Node> top;
  if (block is md.UnparsedContent) {
    top = doc.parseInline(block.textContent);
  } else if (block is md.Element) {
    final children = block.children;
    if (children != null) _inlined(doc, children);
    top = [block];
  } else {
    top = [block];
  }
  final parsed = splitHtmlTables(splitInlineMath(top));
  // The math elements exist only after the split, so the punctuation glue
  // runs on the result (and walks the subtree, for inlines in lists or
  // blockquotes).
  _glueSubtree(parsed);
  return parsed;
}

/// [_glueMathPunctuation] over [nodes] and every Element subtree below.
void _glueSubtree(List<md.Node> nodes) {
  _glueMathPunctuation(nodes);
  for (final node in nodes) {
    final kids = node is md.Element ? node.children : null;
    if (kids != null) _glueSubtree(kids);
  }
}

/// The inlines of [children], with every raw leaf replaced in place by its
/// parsed inlines — the package's `_parseInlineContent` over one block's
/// subtree (the children list is final, so the edits are in place).
void _inlined(md.Document doc, List<md.Node> children) {
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    if (child is md.UnparsedContent) {
      final inlines = doc.parseInline(child.textContent);
      children
        ..removeAt(i)
        ..insertAll(i, inlines);
      i += inlines.length - 1;
    } else if (child is md.Element && child.children != null) {
      _inlined(doc, child.children!);
    }
  }
}

/// The key the trailing-punctuation glue stores on an inline `math`
/// element (see [_glueMathPunctuation]).
const mathTrailingAttribute = 'niman-trailing';

/// The characters that glue to a preceding math element.
const _gluePunctuation = <String>{
  '.',
  ',',
  ';',
  ':',
  '!',
  '?',
  '%',
  ')',
  '"',
  '\u2019',
  '\u2014',
};

/// Keeps the punctuation that follows an inline math element with it.
///
/// The math renders as a widget (a forced line-break boundary), so the wrap
/// that fills the line right after it would strand the punctuation (`.`,
/// `,`, …) at the start of the next line, split from its formula. The
/// leading punctuation (+ at most one space) moves into the element's
/// [mathTrailingAttribute]; the math view renders it inside its own (atomic)
/// span, where it can no longer wrap away from the math. The text after
/// keeps the remainder.
void _glueMathPunctuation(List<md.Node> children) {
  for (var i = 0; i + 1 < children.length; i++) {
    final math = children[i];
    if (math is! md.Element ||
        math.tag != 'math' ||
        math.attributes[mathTrailingAttribute] != null) {
      continue;
    }
    final next = children[i + 1];
    if (next is! md.Text || next.text.isEmpty) continue;
    final first = next.text[0];
    if (!_gluePunctuation.contains(first)) continue;
    var cut = 1;
    if (next.text.length > 1 && next.text[1] == ' ') cut = 2;
    final glued = next.text.substring(0, cut);
    final rest = next.text.substring(cut);
    math.attributes[mathTrailingAttribute] = glued;
    if (rest.isEmpty) {
      children.removeAt(i + 1);
    } else {
      children[i + 1] = md.Text(rest);
    }
  }
}

/// The block phase of the package's `_filterFootnotes`: footnote
/// definitions leave the body, and the ones referenced gather at the end
/// into a single `section.footnotes` (the preview draws it as one block,
/// and the scroll map locates it as one). Definitions that nothing
/// references are dropped, matching the upstream behavior.
///
/// Upstream computes the referencing state out of the inline phase, which
/// does not run here; the raw-text scan over the blocks is its stand-in.
List<md.Node> _gatherFootnotes(List<md.Node> nodes) {
  final blocks = <md.Node>[];
  final defs = <String, md.Element>{};
  for (final node in nodes) {
    if (node is md.Element && node.tag == 'li') {
      final label = node.footnoteLabel;
      if (label != null) {
        defs[label] = node;
        continue;
      }
    }
    blocks.add(node);
  }
  if (defs.isEmpty) return blocks;
  final counts = _footnoteRefCounts(blocks);
  // Resolve the referenced labels to their definitions, first-reference
  // order; references without a definition stay literal text.
  final defOf = <String, String>{};
  for (final label in defs.keys) {
    defOf[label.toLowerCase()] = label;
  }
  final order = <String>[];
  for (final key in counts.keys) {
    final label = defOf[key];
    if (label != null) order.add(label);
  }
  if (order.isEmpty) return blocks;
  for (final label in order) {
    final key = label.toLowerCase();
    final kids = defs[label]!.children;
    if (kids != null) {
      _appendBackref(kids, Uri.encodeComponent(label), counts[key] ?? 0);
    }
  }
  final section = md.Element('section', [
    md.Element('ol', [for (final label in order) defs[label]!]),
  ])..attributes['class'] = 'footnotes';
  return [...blocks, section];
}

/// The footnote references in the raw text of [nodes]: lowercase label to
/// occurrence count, keys in first-seen order. Code blocks are skipped —
/// inlines never run inside them, and neither does this scan.
Map<String, int> _footnoteRefCounts(List<md.Node> nodes) {
  final counts = <String, int>{};
  for (final node in nodes) {
    _scanForRefs(node, counts);
  }
  return counts;
}

final RegExp _refPattern = RegExp(r'\[\^([^\]\s]+)\]');

void _scanForRefs(md.Node node, Map<String, int> counts) {
  if (node is md.UnparsedContent) {
    for (final match in _refPattern.allMatches(node.textContent)) {
      final key = match.group(1)!.trim().toLowerCase();
      if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
    }
  } else if (node is md.Element && node.tag != 'pre') {
    node.children?.forEach((child) => _scanForRefs(child, counts));
  }
}

/// The upstream `_appendBackref`: the back-reference anchors (one per body
/// reference) appended where the definition's text ends, so the footnote
/// section reads the way the old whole-document parse produced it.
void _appendBackref(List<md.Node> children, String ref, int count) {
  final refs = <md.Node>[
    for (var i = 0; i < count; i++) ...<md.Node>[
      md.Text(' '),
      _backrefAnchor(ref, i),
    ],
  ];
  if (children.isEmpty) {
    children.addAll(refs);
  } else {
    final last = children.last;
    if (last is md.Element) {
      last.children?.addAll(refs);
    } else {
      children.last = md.Element('p', [last, ...refs]);
    }
  }
}

md.Element _backrefAnchor(String ref, int i) {
  final suffix = i > 0 ? '-${i + 1}' : '';
  return md.Element('a', [
      md.Text('\u21a9'),
      if (i > 0)
        md.Element('sup', [md.Text('${i + 1}')])
          ..attributes['class'] = 'footnote-ref',
    ])
    ..attributes['href'] = '#fnref-$ref$suffix'
    ..attributes['class'] = 'footnote-backref';
}
