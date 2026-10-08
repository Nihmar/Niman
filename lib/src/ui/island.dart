import 'package:flutter/material.dart';

/// One part of the wide layout — the tree, the notes, the side panel, a
/// tab's screen — drawn as a rounded island on the chrome's base.
///
/// The base is the color of the title bar and the rail
/// ([ColorScheme.surfaceContainer]); the island wears the ground the
/// part has always been painted on ([ColorScheme.surface]), so the two
/// tell apart in every theme, a custom one included, exactly as the
/// title bar and the note under it always have. The space between two
/// islands, and between an island and the window's edge, is
/// [Island.gap] wide; the shell lays it out.
///
/// The child is clipped to the rounding, so nothing it paints — a
/// scrollbar, a selection, the note's toolbar — reaches over a corner.
/// The clip is a plain anti-aliased one, never a saved layer, so a note
/// of any size pays nothing for it. With [floating] off (Zen, where the
/// note takes the window edge to edge) the corners go square and the
/// clip goes away, while the widget stays where it was in the tree: the
/// editor inside it is never rebuilt for the switch.
final class Island extends StatelessWidget {
  /// An island around [child].
  const new({required this.child, this.floating = true, super.key});

  /// The base showing between two islands, and around them.
  static const double gap = 8;

  /// The corners' radius.
  static const double radius = 10;

  /// Whether the island floats on the base, rounded; off, it is a plain
  /// square ground under [child].
  final bool floating;

  /// What sits on the island.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(floating ? radius : 0),
      clipBehavior: floating ? Clip.antiAlias : Clip.none,
      // A Material, not a bare color: the rows' ink — a tree row's
      // splash, a selected tile — paints on the nearest Material, and a
      // colored box over the Scaffold's would hide it.
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: child,
      ),
    );
  }
}
