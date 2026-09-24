/// The keys that move the read view, as a reader's keyboard expects them.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Moves the read view's [scroll] for [event]: the arrows by [row] a press,
/// the page keys by the viewport less a row — the row kept for context, as
/// the editor pages — and Home and End, with Ctrl or without, to the
/// note's ends. Handled when the key is one of them, whether or not there
/// was anywhere left to go, so it does not reach the shell.
///
/// The end is where the height map says, and far from the viewport that is
/// estimates: [toEnd] is called for End instead, to go there again once the
/// rows it lands on are measured.
KeyEventResult readViewKey(
  KeyEvent event,
  ScrollController scroll, {
  required double row,
  required VoidCallback toEnd,
}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  if (!scroll.hasClients) return KeyEventResult.ignored;
  final position = scroll.position;
  final key = event.logicalKey;
  final keyboard = HardwareKeyboard.instance;
  // Shift and Alt are someone else's (the shell's own shortcuts).
  if (keyboard.isShiftPressed || keyboard.isAltPressed) {
    return KeyEventResult.ignored;
  }
  final page = position.viewportDimension - row;
  final double? to;
  if (key == LogicalKeyboardKey.arrowDown) {
    to = position.pixels + row;
  } else if (key == LogicalKeyboardKey.arrowUp) {
    to = position.pixels - row;
  } else if (key == LogicalKeyboardKey.pageDown) {
    to = position.pixels + page;
  } else if (key == LogicalKeyboardKey.pageUp) {
    to = position.pixels - page;
  } else if (key == LogicalKeyboardKey.home) {
    to = position.minScrollExtent;
  } else if (key == LogicalKeyboardKey.end) {
    toEnd();
    return KeyEventResult.handled;
  } else {
    to = null;
  }
  if (to == null) return KeyEventResult.ignored;
  // An arrow with Ctrl is the shell's; Home and End take it or not.
  if (keyboard.isControlPressed &&
      key != LogicalKeyboardKey.home &&
      key != LogicalKeyboardKey.end) {
    return KeyEventResult.ignored;
  }
  scroll.jumpTo(to.clamp(position.minScrollExtent, position.maxScrollExtent));
  return KeyEventResult.handled;
}
