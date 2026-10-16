/// A wheel over a row that scrolls sideways (#1080).
///
/// Flutter maps a plain mouse wheel to the vertical axis, so a horizontal
/// scrollable answers only to Shift and the wheel. The tab row has no
/// vertical axis to give it to: the wheel scrolls it.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Scrolls [controller]'s horizontal position by a plain wheel's turn.
final class WheelScroll extends StatelessWidget {
  /// Makes the wheel over [child] scroll [controller].
  const new({required this.controller, required this.child, super.key});

  /// The horizontal scrollable [child] holds.
  final ScrollController controller;

  /// The scrollable, or a widget around it.
  final Widget child;

  void _signal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !controller.hasClients) return;
    // A sideways wheel, or Shift and the wheel, is the scrollable's own.
    final delta = event.scrollDelta;
    if (delta.dy == 0 || delta.dx != 0) return;
    if (HardwareKeyboard.instance.isShiftPressed) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final position = controller.position;
      final to = (position.pixels + delta.dy).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (to != position.pixels) position.jumpTo(to);
    });
  }

  @override
  Widget build(BuildContext context) =>
      Listener(onPointerSignal: _signal, child: child);
}
