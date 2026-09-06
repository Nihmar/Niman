import 'package:flutter/material.dart';

/// Copist's selection-handle controls (M2a round-5 T2): the stock Material
/// toolbar and behavior, but smaller bottom-hanging flat balls (stock is
/// 22 px).
///
/// Only the handle rendering differs from [MaterialTextSelectionControls]:
/// everything else (toolbar, copy/cut/paste/select-all gating, magnifier
/// policy) is inherited unchanged, so this stays the "standard selection
/// UI" with a Copist look.
final class CopistSelectionControls extends MaterialTextSelectionControls {
  /// Creates the controls (no state).
  CopistSelectionControls();

  /// The handle box side, px (stock is 22).
  static const double handleSize = 16;

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    // The collapsed caret handle keeps the stock rendering (a 45° onion);
    // only the selection balls are custom.
    if (type == TextSelectionHandleType.collapsed) {
      return super.buildHandle(context, type, textHeight, onTap);
    }
    final theme = Theme.of(context);
    final color =
        TextSelectionTheme.of(context).selectionHandleColor ??
        theme.colorScheme.primary;
    return SizedBox.square(
      dimension: handleSize,
      child: CustomPaint(
        painter: _CopistHandlePainter(
          color: color,
          // The left ball mirrors the right one (tips face the selection
          // from opposite sides, as stock).
          mirrored: type == TextSelectionHandleType.left,
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
        ),
      ),
    );
  }

  /// The tip sits exactly on the selection endpoint and the ball hangs
  /// below it: left tip at the box's top-right, right tip at top-left
  /// (the stock anchor convention, so the overlay math holds).
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return switch (type) {
      TextSelectionHandleType.left => const Offset(handleSize, 0),
      TextSelectionHandleType.right => Offset.zero,
      TextSelectionHandleType.collapsed => super.getHandleAnchor(
        type,
        textLineHeight,
      ),
    };
  }
}

/// A 16 px teardrop: filled ball + stem to the tip (flat, no rim —
/// round-7 removed the bright edge highlight). Unmirrored, the tip is the
/// box's top-left corner and the ball hangs bottom-right; [mirrored] flips
/// it horizontally.
final class _CopistHandlePainter extends CustomPainter {
  /// Creates the painter in [color], optionally [mirrored] horizontally.
  const _CopistHandlePainter({required this.color, required this.mirrored});

  /// The ball fill.
  final Color color;

  /// Whether to mirror horizontally (the left ball).
  final bool mirrored;

  static const double _size = CopistSelectionControls.handleSize;
  static const double _ballRadius = 5.5;
  static const Offset _ballCenter = Offset(6.5, 10);
  static const double _stemWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    canvas.save();
    if (mirrored) {
      canvas
        ..translate(_size, 0)
        ..scale(-1, 1);
    }
    canvas
      ..drawCircle(_ballCenter, _ballRadius, fill)
      ..drawRect(const Rect.fromLTWH(0, 0, _stemWidth, 7), fill)
      ..restore();
  }

  @override
  bool shouldRepaint(_CopistHandlePainter old) =>
      old.color != color || old.mirrored != mirrored;
}
