/// A Home tile's frame (#535): its card, its title, and its content under
/// it in whatever height the grid or the column gives.
library;

import 'package:flutter/material.dart';

/// One tile's card.
final class HomeTileFrame extends StatelessWidget {
  /// A card titled [title], with [icon], over [child]; [trailing] sits at
  /// the title's end. With [fit] the card is as tall as [child] needs
  /// rather than the height it is given.
  const new({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.fit = false,
    super.key,
  });

  /// Whether the card takes its content's height.
  final bool fit;

  /// The tile kind's icon.
  final IconData icon;

  /// The tile's title.
  final String title;

  /// What the tile shows.
  final Widget child;

  /// A control at the title's end, or null.
  final Widget? trailing;

  /// The card's corners.
  static const double radius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.4,
    );
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Column(
          mainAxisSize: fit ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (fit) child else Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The look of a button on a tile: the island's own ground, so it stands
/// off the card it sits on in every theme (a tonal one can match the card).
ButtonStyle homeTileButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
    iconColor: scheme.primary,
  );
}

/// The line a tile shows when it has nothing to list.
final class HomeTileEmpty extends StatelessWidget {
  /// Says [text].
  const new(this.text, {super.key});

  /// What there is not.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
