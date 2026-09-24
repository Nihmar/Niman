// A theme of the user's own making (issue #269).
//
// Name and colors, nothing else: where it came from, whether it is the
// one in use and how it is exported are not properties of the theme.
// Colors are explicit at day and at night — the two brightnesses a
// Material scheme needs — and an id keeps a rename from losing the theme
// the app is wearing.

import 'dart:math';

import 'package:flutter/foundation.dart' show immutable;
import 'package:niman/src/core/theme_colors.dart';

/// A custom theme: what it is called, and what it wears.
@immutable
final class CustomTheme {
  /// Creates a theme.
  const new({
    required this.id,
    required this.name,
    required this.day,
    required this.night,
  });

  /// The id it is stored under. Never shown; it survives a rename.
  final String id;

  /// What the user calls it.
  final String name;

  /// Its colors in daylight.
  final ThemeColors day;

  /// Its colors at night.
  final ThemeColors night;

  /// The longest a name may be, so a row in the list and the export's
  /// file name stay sane.
  static const int maxNameLength = 60;

  /// [name] as it will be stored: the spaces a field pads in are not part
  /// of it, and an all-spaces name is no name at all.
  static String cleanName(String name) => name.trim();

  /// This theme with some of it replaced.
  CustomTheme copyWith({String? name, ThemeColors? day, ThemeColors? night}) =>
      CustomTheme(
        id: id,
        name: name ?? this.name,
        day: day ?? this.day,
        night: night ?? this.night,
      );

  // Compared, not just carried: the app rebuilds its theme when the one
  // being edited changes under the same id.
  @override
  bool operator ==(Object other) =>
      other is CustomTheme &&
      other.id == id &&
      other.name == name &&
      other.day == day &&
      other.night == night;

  @override
  int get hashCode => Object.hash(id, name, day, night);
}

/// [base] with a number appended until it is not in [taken]: what a copy
/// of a theme is called when nobody is asked ("Gruvbox 2").
///
/// [taken] holds the names already in the list, lowercased.
String uniqueThemeName(String base, Set<String> taken) {
  final clean = CustomTheme.cleanName(base);
  if (!taken.contains(clean.toLowerCase())) return clean;
  for (var number = 2; ; number++) {
    final candidate = '$clean $number';
    if (!taken.contains(candidate.toLowerCase())) return candidate;
  }
}

/// An id for a theme the app is about to create.
///
/// Unique on this installation without a table read: the clock alone is
/// enough for a theme somebody makes by hand, and the salt is there for
/// two taps landing in the same microsecond.
String newCustomThemeId({Random? random}) {
  final rng = random ?? Random();
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = rng.nextInt(1 << 32).toRadixString(36);
  return '$stamp-$salt';
}
