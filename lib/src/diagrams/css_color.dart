/// Reading a colour written the way CSS writes one, for a Mermaid `style`
/// statement.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The colours a note can name rather than spell: CSS's basic sixteen and
/// the few names a diagram reaches for most.
const Map<String, Color> _named = {
  'black': Color(0xFF000000),
  'silver': Color(0xFFC0C0C0),
  'gray': Color(0xFF808080),
  'grey': Color(0xFF808080),
  'white': Color(0xFFFFFFFF),
  'maroon': Color(0xFF800000),
  'red': Color(0xFFFF0000),
  'purple': Color(0xFF800080),
  'fuchsia': Color(0xFFFF00FF),
  'magenta': Color(0xFFFF00FF),
  'green': Color(0xFF008000),
  'lime': Color(0xFF00FF00),
  'olive': Color(0xFF808000),
  'yellow': Color(0xFFFFFF00),
  'navy': Color(0xFF000080),
  'blue': Color(0xFF0000FF),
  'teal': Color(0xFF008080),
  'aqua': Color(0xFF00FFFF),
  'cyan': Color(0xFF00FFFF),
  'orange': Color(0xFFFFA500),
  'pink': Color(0xFFFFC0CB),
  'gold': Color(0xFFFFD700),
  'brown': Color(0xFFA52A2A),
  'lightgray': Color(0xFFD3D3D3),
  'lightgrey': Color(0xFFD3D3D3),
  'darkgray': Color(0xFFA9A9A9),
  'darkgrey': Color(0xFFA9A9A9),
  'lightblue': Color(0xFFADD8E6),
  'lightgreen': Color(0xFF90EE90),
  'transparent': Color(0x00000000),
  'none': Color(0x00000000),
};

final RegExp _function = RegExp(r'^rgba?\(([^)]*)\)$');

/// The colour [value] spells — `#f9f`, `#ff99ff`, `#ff99ff80`, `rgb(…)`,
/// `rgba(…)` or one of a few names — or null when it spells none.
Color? parseCssColor(String value) {
  final text = value.trim().toLowerCase();
  final named = _named[text];
  if (named != null) return named;
  if (text.startsWith('#')) return _hex(text.substring(1));
  final call = _function.firstMatch(text);
  if (call == null) return null;
  final parts = call.group(1)!.split(RegExp(r'[\s,/]+'))
    ..removeWhere((part) => part.isEmpty);
  if (parts.length != 3 && parts.length != 4) return null;
  final channels = <int>[];
  for (final part in parts.take(3)) {
    final channel = _channel(part);
    if (channel == null) return null;
    channels.add(channel);
  }
  var alpha = 255;
  if (parts.length == 4) {
    final share = _share(parts[3]);
    if (share == null) return null;
    alpha = (share * 255).round();
  }
  return Color.fromARGB(alpha, channels[0], channels[1], channels[2]);
}

Color? _hex(String digits) {
  if (!RegExp(r'^[0-9a-f]+$').hasMatch(digits)) return null;
  final full = switch (digits.length) {
    3 || 4 => [for (final digit in digits.split('')) '$digit$digit'].join(),
    6 || 8 => digits,
    _ => null,
  };
  if (full == null) return null;
  final rgb = int.parse(full.substring(0, 6), radix: 16);
  final alpha = full.length == 8
      ? int.parse(full.substring(6), radix: 16)
      : 255;
  return Color((alpha << 24) | rgb);
}

/// A channel written as 0–255 or as a percentage.
int? _channel(String part) {
  if (part.endsWith('%')) {
    final share = double.tryParse(part.substring(0, part.length - 1));
    return share == null ? null : (share.clamp(0, 100) * 2.55).round();
  }
  final value = double.tryParse(part);
  return value?.round().clamp(0, 255);
}

/// An alpha written as 0–1 or as a percentage.
double? _share(String part) {
  if (part.endsWith('%')) {
    final share = double.tryParse(part.substring(0, part.length - 1));
    return share == null ? null : math.min(math.max(share / 100, 0), 1);
  }
  final value = double.tryParse(part);
  return value == null ? null : math.min(math.max(value, 0), 1);
}
