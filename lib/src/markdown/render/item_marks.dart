/// A list item's bullet and checkbox, drawn one way wherever a note is
/// read: `live` paints them behind a line, the read view in its marker
/// column, and the two looked like two apps — a `•` glyph and a Material
/// icon on one side, a dot and a rounded box on the other.
///
/// Both are sized in `em`, the size the item's text is drawn at, so they
/// grow with the note's text.
library;

import 'package:flutter/widgets.dart';

/// Paints a bullet centred on [centre].
void paintBullet(Canvas canvas, Offset centre, double em, Color color) {
  canvas.drawCircle(centre, em * 0.18, Paint()..color = color);
}

/// Paints a checkbox centred on [centre], filled and ticked when [ticked].
void paintCheckbox(
  Canvas canvas,
  Offset centre,
  double em,
  Color color, {
  required bool ticked,
}) {
  final side = em * 0.86;
  final rect = Rect.fromCenter(center: centre, width: side, height: side);
  final frame = RRect.fromRectAndRadius(rect, Radius.circular(em * 0.14));
  if (ticked) {
    canvas.drawRRect(frame, Paint()..color = color);
    final inset = em * 0.18;
    final tick = Path()
      ..moveTo(rect.left + inset, rect.center.dy)
      ..lineTo(rect.left + side * 0.42, rect.bottom - em * 0.21)
      ..lineTo(rect.right - inset, rect.top + em * 0.21);
    canvas.drawPath(
      tick,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = em * 0.11,
    );
    return;
  }
  canvas.drawRRect(
    frame,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = em * 0.1,
  );
}

/// What a list item's marker column shows in the read view: its bullet or
/// its checkbox, centred in the column on the item's first row — where
/// `live` draws them in the same room.
final class ItemMarkPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.em,
    required this.row,
    required this.color,
    this.task,
  });

  /// The size the item's text is drawn at.
  final double em;

  /// How tall the item's first row is: the mark is centred on it.
  final double row;

  /// The mark's colour.
  final Color color;

  /// Whether the checkbox is ticked, for a task item; null draws a bullet.
  final bool? task;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, row / 2);
    final ticked = task;
    if (ticked == null) {
      paintBullet(canvas, centre, em, color);
    } else {
      paintCheckbox(canvas, centre, em, color, ticked: ticked);
    }
  }

  @override
  bool shouldRepaint(ItemMarkPainter oldDelegate) =>
      oldDelegate.em != em ||
      oldDelegate.row != row ||
      oldDelegate.color != color ||
      oldDelegate.task != task;
}
