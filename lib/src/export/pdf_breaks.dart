/// Where the raster fallback's pages end (#63).
///
/// The fallback lays the note out once and takes one page per slice of it
/// (`pdf_raster.dart`), so a slice's edge *is* the page break — and a
/// break at the page's nominal edge cuts whatever line or picture
/// straddles it: the top half at the foot of one page, the bottom half at
/// the head of the next, which reads as a line with no bottom and loses
/// the words that fell in between. A break is therefore placed above the
/// line that would be cut, at the last offset where the page's content
/// ends and nothing carries over.
///
/// The layout is asked what its ink is ([rasterInkSpans]) and the breaks
/// fall in the gaps it leaves ([rasterBreaks]): one walk of the render
/// tree per export, then arithmetic per page.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// The vertical spans [box] draws in: one per line of text, one per
/// picture, rule or formula, in [box]'s own coordinates.
///
/// A paragraph contributes one span per line it wrapped to: it is laid out
/// as one box, and a break inside it is what a page does anyway — as long
/// as the break falls between two of its lines, not through one.
List<(double, double)> rasterInkSpans(RenderBox box) {
  final spans = <(double, double)>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      _addLines(node, box, spans);
    } else if (node is RenderBox && node.hasSize && !_hasChildren(node)) {
      // A leaf box is drawn as one piece — a picture, a rule, a formula —
      // and a break through it is a break through the picture.
      final top = box.globalToLocal(node.localToGlobal(Offset.zero)).dy;
      spans.add((top, top + node.size.height));
    }
    node.visitChildren(visit);
  }

  visit(box);
  return spans;
}

/// The y where each page of a layout [total] tall ends, given the ink
/// [spans] it draws and how much one page holds ([contentHeight]).
///
/// `breaks[i]` is where page `i` ends and `breaks[i + 1]` where the next
/// begins, so page `i` covers `[breaks[i], breaks[i + 1])` and the last
/// element is [total]. Every break but the last falls where no span of ink
/// crosses it; a line or a picture taller than a page has nowhere to break
/// and is cut, which is the one cut that is left.
List<double> rasterBreaks({
  required double total,
  required List<(double, double)> spans,
  required double contentHeight,
}) {
  if (contentHeight <= 0 || total <= 0) {
    // A note that lays out to nothing still takes a page (P5).
    return <double>[0, math.max(total, contentHeight)];
  }
  final blocked = _merged(spans);
  final breaks = <double>[0];
  while (breaks.last < total) {
    final top = breaks.last;
    final target = math.min(top + contentHeight, total);
    final next = _clearOf(blocked, target);
    breaks.add(next > top ? next : target);
  }
  return breaks;
}

/// [target] moved up to the head of the span that would be cut, or [target]
/// itself when nothing is in the way.
double _clearOf(List<(double, double)> blocked, double target) {
  var at = target;
  for (var index = _lastStartingBefore(blocked, at); index >= 0; index--) {
    final (top, bottom) = blocked[index];
    // Sorted and disjoint: past this span's end, everything earlier is too.
    if (at >= bottom) break;
    if (at > top) at = top;
  }
  return at;
}

/// The last index of [blocked] whose top is below [at], or -1.
int _lastStartingBefore(List<(double, double)> blocked, double at) {
  var low = 0;
  var high = blocked.length;
  while (low < high) {
    final mid = (low + high) >> 1;
    if (blocked[mid].$1 < at) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low - 1;
}

/// [spans] in order, with the ones that overlap joined: a break is clear of
/// a merged span exactly when it is clear of every span in it.
List<(double, double)> _merged(List<(double, double)> spans) {
  final sorted = spans.where((span) => span.$2 > span.$1).toList()
    ..sort((a, b) => a.$1.compareTo(b.$1));
  final out = <(double, double)>[];
  for (final span in sorted) {
    final last = out.isEmpty ? null : out.last;
    if (last != null && span.$1 < last.$2) {
      if (span.$2 > last.$2) out[out.length - 1] = (last.$1, span.$2);
      continue;
    }
    out.add(span);
  }
  return out;
}

/// Adds one span per line of [paragraph], in [box]'s coordinates.
void _addLines(
  RenderParagraph paragraph,
  RenderBox box,
  List<(double, double)> spans,
) {
  final characters = paragraph.text.toPlainText().length;
  if (characters == 0) return;
  final origin = box.globalToLocal(paragraph.localToGlobal(Offset.zero));
  final lines = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: characters),
  );
  for (final line in lines) {
    spans.add((origin.dy + line.top, origin.dy + line.bottom));
  }
}

/// Whether [node] draws anything of its own below it.
bool _hasChildren(RenderObject node) {
  var any = false;
  node.visitChildren((_) => any = true);
  return any;
}
