import 'package:flutter/material.dart';

/// The board's colours, all from the theme's [ColorScheme] so the board
/// follows light and dark (#1167).
final class KanbanPalette {
  const new _({
    required this.column,
    required this.card,
    required this.border,
    required this.focus,
    required this.muted,
    required this.chip,
    required this.onChip,
  });

  /// The palette of [context]'s theme.
  factory of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return KanbanPalette._(
      column: dark ? scheme.surfaceContainerLow : scheme.surfaceContainer,
      card: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      border: scheme.outlineVariant,
      focus: scheme.primary,
      muted: scheme.onSurfaceVariant,
      chip: scheme.secondaryContainer,
      onChip: scheme.onSecondaryContainer,
    );
  }

  /// A column's tinted background.
  final Color column;

  /// A card's surface.
  final Color card;

  /// The hairline round a card and a dashed control.
  final Color border;

  /// The ring of the focused card, the drop marker.
  final Color focus;

  /// Secondary text and icons.
  final Color muted;

  /// A tag chip's fill.
  final Color chip;

  /// A tag chip's text.
  final Color onChip;
}
