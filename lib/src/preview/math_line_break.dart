/// Breaking a display formula across lines when the pane is too narrow for it.
///
/// A maths book on a phone is the case this exists for: `Geometria 1.md` has
/// 824 display formulas and **306 are wider than a phone pane's 368 pixels**
/// (median 316, p90 495, widest 712), and they were clamped to the pane and cut
/// — in both surfaces (#257). A reader studying from a phone cannot see the end
/// of a third of the book's equations.
///
/// The first answer is the one a book uses: **break at the formula's own
/// operators**, at full size, rather than shrink it. The box tree carries what
/// a break needs — the top level of a formula is a row of atoms in source order
/// — and it carries what makes breaking *safe*: a subscript or an exponent is a
/// `VList`, not a top-level child, so no break can land inside `x^{-1}`, and an
/// operator written as `\left( … \right)` is one child, so a break never splits
/// a delimiter pair.
///
/// Breaks go **after** the operator, as TeX does (`a =` then `b + c`), and only
/// after the operators and relations that a formula may be broken at.
library;

import 'package:katex_dart/katex_dart.dart';

/// The characters a line may break after: the binary operators and the
/// relations of TeX's own break rules, in the codepoints the fonts use.
///
/// Not an exhaustive list of everything a formula could be broken at — it is
/// the list that shows up at the top level of real formulas, and a break that
/// is not offered is a formula that stays whole (which is the behaviour this
/// replaces, so a miss is safe).
const Set<int> _breakAfter = <int>{
  0x2B, // +
  0x2D, // -
  0x2C, // ,
  0x3B, // ;
  0x3D, // =
  0x3C, // <
  0x3E, // >
  0xB1, // ±
  0xB7, // ·
  0xD7, // ×
  0xF7, // ÷
  0x2212, // −
  0x2213, // ∓
  0x2248, // ≈
  0x2260, // ≠
  0x2264, // ≤
  0x2265, // ≥
  0x2208, // ∈
  0x2209, // ∉
  0x2282, // ⊂
  0x2286, // ⊆
  0x2192, // →
  0x21A6, // ↦
  0x22C5, // ⋅
  0x2225, // ∥
  0x22A5, // ⊥
};

/// [box] split into lines no wider than [maxEm], or `[box]` itself when it fits
/// or cannot be broken.
///
/// Each line is wrapped the way [box] wraps its children, so a formula drawn in
/// a colour keeps it on every line.
List<BoxNode> breakDisplayMath(BoxNode box, {required double maxEm}) {
  if (!maxEm.isFinite || maxEm <= 0) return <BoxNode>[box];
  // The row of atoms to break is not always the root: `\color{red} a = b`
  // puts a one-child wrapper in front of it, and a break inside *that* keeps
  // the colour (`_wrap` rebuilds the wrapper it split).
  final path = <BoxNode>[box];
  var row = box;
  while (row.width > maxEm) {
    final only = switch (row) {
      HBox(:final children) when children.length == 1 => children.first,
      SpanNode(:final children) when children.length == 1 => children.first,
      _ => null,
    };
    if (only == null) break;
    row = only;
    path.add(row);
  }
  final children = switch (row) {
    HBox(:final children) => children,
    SpanNode(:final children) => children,
    _ => const <BoxNode>[],
  };
  if (children.length < 3 || row.width <= maxEm) return <BoxNode>[box];

  final lines = <List<BoxNode>>[];
  var line = <BoxNode>[];
  var width = 0.0;
  // The last child a line may end after, and the width up to it: a line is cut
  // at the *last* operator that keeps it inside the pane, not at the one that
  // overflows.
  var breakAt = -1;
  var breakWidth = 0.0;

  for (final child in children) {
    line.add(child);
    width += child.width;
    if (_breaksAfter(child)) {
      breakAt = line.length;
      breakWidth = width;
    }
    if (width <= maxEm) continue;
    if (breakAt <= 0) continue; // nothing to break at yet: this line runs long
    lines.add(line.sublist(0, breakAt));
    line = line.sublist(breakAt);
    width -= breakWidth;
    breakAt = -1;
    breakWidth = 0.0;
  }
  lines.add(line);
  if (lines.length < 2) return <BoxNode>[box];
  return <BoxNode>[for (final of in lines) _rebuild(path, row, of)];
}

/// One line of the split, wrapped back up the way the formula was: the row's
/// own wrapper first, then every wrapper the descent went through — so a
/// `\color{red}` three levels above the operators is on every line, and a size
/// multiplier is not lost either.
BoxNode _rebuild(List<BoxNode> path, BoxNode row, List<BoxNode> children) {
  var built = _wrap(row, children);
  for (final ancestor in path.reversed.skip(1)) {
    built = _wrap(ancestor, <BoxNode>[built]);
  }
  return built;
}

/// Whether a line may end after [child]: it is an operator glyph, under
/// whatever wrappers the builder put around it.
bool _breaksAfter(BoxNode child) {
  final codepoint = _onlyGlyph(child);
  return codepoint != null && _breakAfter.contains(codepoint);
}

/// The codepoint of [node] when it is one glyph, under single-child wrappers.
///
/// The builder wraps almost everything — an `HBox` holding a `GlyphNode`
/// holding a plus sign is three levels for one character — and anything that is
/// not one glyph (a matrix, a stretched delimiter, a script) is deliberately
/// not a break point.
int? _onlyGlyph(BoxNode node) => switch (node) {
  GlyphNode() => node.codepoint,
  HBox(:final children) when children.length == 1 => _onlyGlyph(children.first),
  SpanNode(:final children) when children.length == 1 => _onlyGlyph(
    children.first,
  ),
  _ => null,
};

/// [children] inside the same wrapper [box] used, so nothing the wrapper
/// carried (a colour, a class, a size) is lost by the split.
BoxNode _wrap(BoxNode box, List<BoxNode> children) => switch (box) {
  SpanNode(:final color, :final classes, :final sizeMultiplier) => SpanNode(
    children,
    color: color,
    classes: classes,
    sizeMultiplier: sizeMultiplier,
  ),
  _ => HBox(children),
};
