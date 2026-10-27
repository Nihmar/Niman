// The width a picture is laid out in, for the size it is decoded at
// (#1194).

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/preview/decode_bound.dart';

/// Reports the width its child is laid out in, as a [decodeBound].
///
/// A `LayoutBuilder` would hand the width to the build, but it cannot
/// answer an intrinsic query, and a picture in a table cell — a column
/// sized by `IntrinsicColumnWidth` — is asked one (the same reason the read
/// view measures its formulas once, `markdown_read_view.dart`). This box
/// passes those queries to its child and reads the width after layout.
final class DecodeWidthProbe extends SingleChildRenderObjectWidget {
  /// Reports [child]'s layout width to [onWidth].
  const new({
    required this.ratio,
    required this.fallback,
    required this.onWidth,
    super.key,
    super.child,
  });

  /// The device pixel ratio the bound is in.
  final double ratio;

  /// The width an unbounded layout stands for.
  final double fallback;

  /// Told the bound after every layout.
  final ValueChanged<int> onWidth;

  @override
  RenderDecodeWidthProbe createRenderObject(BuildContext context) =>
      RenderDecodeWidthProbe(
        ratio: ratio,
        fallback: fallback,
        onWidth: onWidth,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDecodeWidthProbe renderObject,
  ) {
    renderObject
      ..ratio = ratio
      ..fallback = fallback
      ..onWidth = onWidth;
  }
}

/// The render half of [DecodeWidthProbe].
final class RenderDecodeWidthProbe extends RenderProxyBox {
  /// A probe reporting to [onWidth].
  new({required this._ratio, required this._fallback, required this.onWidth});

  /// [DecodeWidthProbe.ratio]. A change lays out again: the bound is
  /// reported from layout, and new constraints are not the only thing it
  /// depends on (a window moved to a denser screen, #1237).
  double get ratio => _ratio;
  double _ratio;
  set ratio(double value) {
    if (value == _ratio) return;
    _ratio = value;
    markNeedsLayout();
  }

  /// [DecodeWidthProbe.fallback]; a change lays out again like [ratio].
  double get fallback => _fallback;
  double _fallback;
  set fallback(double value) {
    if (value == _fallback) return;
    _fallback = value;
    markNeedsLayout();
  }

  /// [DecodeWidthProbe.onWidth].
  ValueChanged<int> onWidth;

  @override
  void performLayout() {
    super.performLayout();
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : fallback;
    onWidth(decodeBound(width, ratio));
  }
}
