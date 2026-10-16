/// A slot kept mounted while it is not shown, that costs nothing to resize
/// (#1079).
///
/// `Offstage` hides its child from paint, hit tests and semantics, but its
/// render object still lays the child out: every window resize, divider
/// drag and keyboard frame re-laid-out every hidden editor and tab body.
/// [HiddenSlot] skips the layout too, as the `Overlay` does for a route
/// that keeps its state under another. The child keeps its element, state
/// and focus nodes; showing it again lays it out once, at the size the
/// slot then has.
///
/// It also keeps focus out of what it hides: a hidden editor must not be
/// reached by Tab or by the keyboard, and one that held the focus lets it
/// go as it is hidden (#1074). Hiding and not taking focus are one thing
/// here, so no caller has to remember the second.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [child], laid out, painted, hit and focusable only while not [hidden].
final class HiddenSlot extends StatelessWidget {
  /// Hides [child] when [hidden], keeping it mounted.
  const new({required this.hidden, required this.child, super.key});

  /// Whether the slot is out of sight: no layout, paint, hit test or focus.
  final bool hidden;

  /// The kept-alive content.
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: hidden,
    child: _HiddenLayout(hidden: hidden, child: child),
  );
}

/// The layout half of [HiddenSlot].
final class _HiddenLayout extends SingleChildRenderObjectWidget {
  const new({required this.hidden, super.child});

  final bool hidden;

  @override
  RenderHiddenSlot createRenderObject(BuildContext context) =>
      RenderHiddenSlot(hidden: hidden);

  @override
  void updateRenderObject(BuildContext context, RenderHiddenSlot renderObject) {
    renderObject.hidden = hidden;
  }

  @override
  SingleChildRenderObjectElement createElement() => _HiddenLayoutElement(this);
}

/// The element: the debug tree, and with it the test finders, skip what
/// is hidden as they skip an `Offstage` child.
final class _HiddenLayoutElement extends SingleChildRenderObjectElement {
  new(_HiddenLayout super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (!(widget as _HiddenLayout).hidden) {
      super.debugVisitOnstageChildren(visitor);
    }
  }
}

/// The render object of [HiddenSlot]: `RenderOffstage`, but with the child
/// left alone while hidden.
final class RenderHiddenSlot extends RenderProxyBox {
  /// Makes the slot, [_hidden] or not.
  new({required this._hidden, RenderBox? child}) : super(child);

  /// Whether the slot is out of sight.
  bool get hidden => _hidden;
  bool _hidden;
  set hidden(bool value) {
    if (value == _hidden) return;
    _hidden = value;
    // The slot's size comes from its constraints while hidden, from its
    // child otherwise.
    markNeedsLayoutForSizedByParentChange();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _hidden ? 0.0 : super.computeMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _hidden ? 0.0 : super.computeMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _hidden ? 0.0 : super.computeMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _hidden ? 0.0 : super.computeMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _hidden ? null : super.computeDistanceToActualBaseline(baseline);

  @override
  bool get sizedByParent => _hidden;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _hidden ? constraints.smallest : super.computeDryLayout(constraints);

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _hidden ? null : super.computeDryBaseline(constraints, baseline);

  @override
  void performResize() {
    size = constraints.smallest;
  }

  @override
  void performLayout() {
    if (!_hidden) {
      super.performLayout();
      return;
    }
    // Hidden, the child is laid out at the size it last had, not at the
    // one the slot has now, which nobody sees: a clean child returns at
    // once, and the resizes it is spared are the point. A child that has
    // never been laid out gets its first layout at the slot's size, the
    // one `Offstage` would give it: its overlay portals (a toolbar, a
    // preview card) are laid out through it, and a portal left dirty
    // under a clean slot breaks the pipeline's rule that a dirty node has
    // dirty ancestors up to its boundary. A child that changed on its
    // own is dirty and is laid out here for the same reason.
    final box = child;
    if (box == null) return;
    box.layout(
      box.hasSize ? box.constraints : constraints,
      parentUsesSize: true,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !_hidden && super.hitTest(result, position: position);

  @override
  bool paintsChild(RenderBox child) => !_hidden;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hidden) return;
    super.paint(context, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_hidden) return;
    super.visitChildrenForSemantics(visitor);
  }
}
