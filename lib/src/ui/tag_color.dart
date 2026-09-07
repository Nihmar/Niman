/// Deterministic colors for tag names (plan/todo-mockup.md T-TDM-02).
///
/// The todo row's left accent bar colors a task after its first `#tag`,
/// so the color is a visual mnemonic, not data: stable across runs and
/// restarts, theme-independent, derived from the name alone.
library;

import 'package:flutter/material.dart';

/// The color of [tag] (case-insensitive).
Color tagColorFor(String tag) {
  final hash = tag.toLowerCase().hashCode;
  final hue = (hash & 0x7fffffff) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.62).toColor();
}
