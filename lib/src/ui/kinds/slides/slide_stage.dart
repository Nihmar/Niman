import 'package:flutter/material.dart';

/// A slide's frame: rounded, with a hairline round it — or, [ringWidth]
/// wide in the accent, the ring of the slide on screen.
final class SlideStage extends StatelessWidget {
  /// Frames [child].
  const new({required this.child, this.radius = 10, this.ringWidth, super.key});

  /// The slide.
  final Widget child;

  /// The corners' radius.
  final double radius;

  /// The ring's width, or null for the hairline.
  final double? ringWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = ringWidth;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: ring == null
            ? Border.all(color: scheme.outlineVariant)
            : Border.all(color: scheme.primary, width: ring),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}
