import 'package:flutter/material.dart';

/// The sync glyph, turning while a run is in flight.
///
/// Wherever the UI says a sync is running it says it the same way, so a
/// still `Icons.sync` never reads as a stalled one: the tree's status
/// button, the progress strip and the WebDAV screen all use this.
final class SpinningSyncIcon extends StatefulWidget {
  /// A turning sync glyph, in [color] and at [size] (the icon theme's
  /// otherwise).
  const new({this.color, this.size, super.key});

  /// The glyph's color.
  final Color? color;

  /// The glyph's size.
  final double? size;

  @override
  State<SpinningSyncIcon> createState() => _SpinningSyncIconState();
}

final class _SpinningSyncIconState extends State<SpinningSyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the icon still says "syncing", it just holds still.
    if (MediaQuery.disableAnimationsOf(context)) {
      _turns.stop();
    } else if (!_turns.isAnimating) {
      _turns.repeat();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    // Material's sync arrows turn clockwise; the icon reads backwards.
    turns: ReverseAnimation(_turns),
    child: Icon(
      Icons.sync,
      size: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    ),
  );
}
