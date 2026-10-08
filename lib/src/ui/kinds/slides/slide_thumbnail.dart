import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/slides/slide_stage.dart';

/// A thumbnail's width in the row under the slide.
const double slideThumbWidth = 112;

/// One slide in the row under the stage: the slide in small, its number
/// under it, ringed when it is the one on screen.
final class SlideThumbnail extends StatelessWidget {
  /// A thumbnail of [child], numbered [number].
  const new({
    required this.number,
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  /// The slide's number, from 1.
  final int number;

  /// Whether it is the slide on screen.
  final bool selected;

  /// Puts the slide on screen.
  final VoidCallback onTap;

  /// The slide, drawn as a picture.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        children: [
          SizedBox(
            width: slideThumbWidth,
            height: slideThumbWidth * 9 / 16,
            child: SlideStage(
              radius: 5,
              ringWidth: selected ? 2 : null,
              child: child,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$number',
            style: TextStyle(
              fontSize: 11.5,
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
