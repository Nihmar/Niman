/// The palette's gesture on a phone (#206): two fingers swiped down.
///
/// The phone has no `Ctrl+Shift+P`, and the library's search is about
/// notes, not commands — the two used to share the Search tab, which read
/// as one search that sometimes answered with commands. So the palette
/// gets a way in of its own: two fingers anywhere on the shell, dragged
/// down, the way a phone opens things that are not part of the page.
///
/// Two fingers rather than one: one finger belongs to the page — the
/// list it scrolls, the note it selects in. This watches the raw
/// pointers instead of claiming a gesture in the arena, so nothing it
/// listens to is taken away from a scroll or a tap underneath; the
/// palette opens once both have gone far enough down together, and the
/// gesture is done until every finger is lifted.
library;

import 'package:flutter/widgets.dart';

/// Opens the palette when two fingers are dragged down over [child].
final class PaletteSwipe extends StatefulWidget {
  /// Watches [child] for the gesture; a null [onOpen] leaves it alone.
  const new({required this.child, this.onOpen, super.key});

  /// The subtree the gesture is watched over.
  final Widget child;

  /// Opens the palette; null on a layout that has a key for it.
  final VoidCallback? onOpen;

  /// How far down both fingers travel before the palette opens.
  static const double distance = 80;

  /// How far sideways either may wander first: a two-finger pan across
  /// the page is not this gesture.
  static const double slack = 60;

  @override
  State<PaletteSwipe> createState() => _PaletteSwipeState();
}

final class _PaletteSwipeState extends State<PaletteSwipe> {
  /// Where each finger went down, while it is down.
  final Map<int, Offset> _from = {};

  /// Set once the gesture has fired, or been ruled out, for the fingers
  /// now down; cleared when the last of them is lifted.
  bool _spent = false;

  void _onDown(PointerDownEvent event) {
    _from[event.pointer] = event.position;
    // A third finger is another gesture: leave it be.
    if (_from.length > 2) _spent = true;
  }

  void _onMove(PointerMoveEvent event) {
    final onOpen = widget.onOpen;
    if (_spent || onOpen == null || !_from.containsKey(event.pointer)) return;
    _latest[event.pointer] = event.position;
    if (_from.length != 2 || _latest.length != 2) return;
    var down = double.infinity;
    for (final MapEntry(key: pointer, value: from) in _from.entries) {
      final at = _latest[pointer];
      if (at == null) return;
      if ((at.dx - from.dx).abs() > PaletteSwipe.slack) {
        _spent = true;
        return;
      }
      final dy = at.dy - from.dy;
      if (dy < down) down = dy;
    }
    // The shorter of the two has to have gone the distance.
    if (down < PaletteSwipe.distance) return;
    _spent = true;
    onOpen();
  }

  /// Where each finger is now: a move reports one finger, and the test
  /// is about both.
  final Map<int, Offset> _latest = {};

  void _onUp(PointerEvent event) {
    _from.remove(event.pointer);
    _latest.remove(event.pointer);
    if (_from.isEmpty) _spent = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onOpen == null) return widget.child;
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: widget.child,
    );
  }
}
