import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// A thumbnail's width in the row under the slide.
const double slideThumbWidth = 112;

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

/// A slide's speaker notes, in a card: shown in the working views, never
/// on the projected screen nor in the PDF.
final class SpeakerNotes extends StatelessWidget {
  /// Shows [notes].
  const new({required this.notes, this.large = false, super.key});

  /// The notes' text.
  final String notes;

  /// The presenter view's size, read from a step back.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const Key('speaker-notes'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.slidesSpeakerNotes,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  notes,
                  style: large
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// Where the slide on screen is in a short deck.
final class SlideDots extends StatelessWidget {
  /// [count] dots, the one at [index] lit.
  const new({required this.count, required this.index, super.key});

  /// How many slides.
  final int count;

  /// The slide on screen.
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
