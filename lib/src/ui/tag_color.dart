/// Deterministic colors for tag names (T-TDM-02).
///
/// The todo row's token chips dot each `+project` / `@context` / `#tag`
/// (the old left accent bar's color, repurposed on 2026-09-07), so the
/// color is a visual mnemonic, not data: stable across runs and
/// restarts, theme-independent, derived from the name alone.
library;

import 'package:flutter/material.dart';

/// The color of [tag] (case-insensitive).
Color tagColorFor(String tag) {
  final hash = tag.toLowerCase().hashCode;
  final hue = (hash & 0x7fffffff) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.62).toColor();
}
