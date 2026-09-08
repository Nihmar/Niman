import 'package:flutter/material.dart';

/// The insertion marker of a list drag (T-TK-09): a dot plus a bar drawn
/// at the exact indentation the dragged item will land on, so its future
/// position — and its future nesting level — are both visible.
class ListDropIndicator extends StatelessWidget {
  /// Creates the marker, inset by [indent] logical pixels.
  const ListDropIndicator({required this.indent, super.key});

  /// The left inset: the indentation the dropped item will have.
  final double indent;

  /// The marker's height; the row overlays it centred on its edge.
  static const double height = 10;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(width: indent),
          Container(
            width: height,
            height: height,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
