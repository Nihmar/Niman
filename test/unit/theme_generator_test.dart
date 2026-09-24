// Issue #269: a theme invented at random is complete, is readable at both
// brightnesses, and survives being written down and read back.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/core/theme_generator.dart';
import 'package:niman/src/ui/theme/palettes.dart';

/// The WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final one = a.computeLuminance();
  final two = b.computeLuminance();
  final lighter = one > two ? one : two;
  final darker = one > two ? two : one;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The theme seed [seed] makes: the same one every run.
CustomTheme _themeFor(int seed) => randomCustomTheme(
  id: 'random-$seed',
  name: 'Random $seed',
  random: Random(seed),
);

/// Enough seeds to walk the color wheel several times over.
const int _seeds = 40;

void main() {
  test('every role is filled in at both brightnesses, and round-trips', () {
    for (var seed = 0; seed < _seeds; seed++) {
      final theme = _themeFor(seed);
      for (final colors in [theme.day, theme.night]) {
        // A color that does not survive `#RRGGBB` is a color that changes
        // the moment the theme is stored or exported.
        expect(ThemeColors.fromJson(colors.toJson()), colors, reason: '$seed');
      }
    }
  });

  test('day and night are different colors', () {
    for (var seed = 0; seed < _seeds; seed++) {
      final theme = _themeFor(seed);
      expect(theme.day, isNot(theme.night), reason: '$seed');
    }
  });

  test('text reads on the ground, and so does the accent', () {
    for (var seed = 0; seed < _seeds; seed++) {
      final theme = CustomAppTheme(_themeFor(seed));
      for (final brightness in Brightness.values) {
        final colors = themeColors(theme, brightness);
        final scheme = colors.scheme;
        expect(scheme.brightness, brightness, reason: '$seed');
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThan(4.5),
          reason: 'seed $seed at $brightness',
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThan(4.5),
          reason: 'seed $seed at $brightness',
        );
        // The Markdown colors are read on the same ground.
        expect(
          _contrast(colors.syntax.link, scheme.surface),
          greaterThan(3),
          reason: 'seed $seed at $brightness',
        );
      }
    }
  });

  test('a task list reads by its priority, and a finished task steps back', () {
    for (var seed = 0; seed < _seeds; seed++) {
      final theme = _themeFor(seed);
      for (final colors in [theme.day, theme.night]) {
        final syntax = colors.syntax;
        final ground = colors.tokens.background;
        final reason = 'seed $seed';
        // Colors of their own, not a note's borrowed.
        expect(syntax.todoPriority, isNot(syntax.task), reason: reason);
        expect(syntax.todoProject, isNot(syntax.wikilink), reason: reason);
        expect(syntax.todoContext, isNot(syntax.link), reason: reason);
        expect(syntax.todoProject, isNot(syntax.todoContext), reason: reason);
        expect(
          _contrast(syntax.todoPriority, ground),
          greaterThan(3),
          reason: reason,
        );
        // Done is quieter than the text, the date and even the markers.
        final done = _contrast(syntax.todoDone, ground);
        expect(done, lessThan(_contrast(colors.tokens.text, ground)));
        expect(done, lessThan(_contrast(syntax.todoDate, ground)));
        expect(done, lessThan(_contrast(syntax.dim, ground)));
      }
    }
  });

  test('the same seed is the same theme, another seed is not', () {
    final one = _themeFor(7);
    final again = _themeFor(7);
    final other = _themeFor(8);
    expect(one, again);
    expect(one.day.tokens.accent, isNot(other.day.tokens.accent));
  });

  test('the name and the id are the ones it was asked for', () {
    final theme = _themeFor(1);
    expect(theme.id, 'random-1');
    expect(theme.name, 'Random 1');
  });
}
