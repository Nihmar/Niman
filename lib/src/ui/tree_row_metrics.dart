import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_density.dart';

/// The sizes a note tree row is drawn at (#296).
///
/// A phone's row takes a thumb: 40 px tall, with a 48 px slot for the
/// folder chevron that every note's icon lines up with. A mouse needs far
/// less, and the phone's sizes on a desktop read as a touch app on a mouse
/// screen — so a pointer surface gets rows about a third shorter and a
/// leading slot half as wide, which starts every name closer to the edge.
enum TreeRowMetrics {
  /// A touch screen's rows.
  touch._(height: 40, leading: 48, indent: 16, chevronSize: 18),

  /// A pointer's rows.
  pointer._(height: 28, leading: 24, indent: 12, chevronSize: 16);

  new _({
    required this.height,
    required this.leading,
    required this.indent,
    required this.chevronSize,
  });

  /// The metrics [context]'s theme asks for.
  static TreeRowMetrics of(BuildContext context) =>
      pointerDense(Theme.of(context)) ? pointer : touch;

  /// A row's height.
  final double height;

  /// The width of the slot the chevron or the file icon sits in.
  final double leading;

  /// How far in each folder level moves its rows.
  final double indent;

  /// The folder chevron's size.
  final double chevronSize;
}
