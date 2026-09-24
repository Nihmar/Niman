// Issue #269: the shape a theme's colors are stored and exported in.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/theme_colors.dart';

import '../fakes/sample_themes.dart';

ThemeColors _colors() => sampleThemeColors(
  background: sampleDayBackground,
  accent: sampleDayAccent,
  dark: false,
);

void main() {
  group('the role map', () {
    test('every role is there, in the order a file lists them', () {
      final json = _colors().toJson();
      expect(json.keys.toList(), ThemeColors.roleNames);
      expect(json.length, 20);
    });

    test('a theme survives the round trip', () {
      final colors = _colors();
      expect(ThemeColors.fromJson(colors.toJson()), colors);
    });

    test('colors are opaque #RRGGBB', () {
      expect(colorToHex(const Color(0xFF00695C)), '#00695C');
      expect(colorToHex(const Color(0x0000695c)), '#00695C');
      expect(colorFromHex('#00695c'), const Color(0xFF00695C));
      expect(colorFromHex('  #FFFFFF  '), const Color(0xFFFFFFFF));
    });

    test('anything that is not such a color reads as none', () {
      for (final bad in ['red', '#FFF', '#GGGGGG', '#11223344', '', '695C00']) {
        expect(colorFromHex(bad), isNull, reason: bad);
      }
    });

    test('a map missing a role is not a theme', () {
      final json = _colors().toJson();
      for (final role in ThemeColors.roleNames) {
        final without = Map.of(json)..remove(role);
        expect(ThemeColors.fromJson(without), isNull, reason: '$role missing');
      }
    });

    test('a map with a color that is not one is not a theme', () {
      final json = _colors().toJson();
      json['accent'] = 'teal';
      expect(ThemeColors.fromJson(json), isNull);
      json['accent'] = '#00695C';
      json['text'] = '#12345';
      expect(ThemeColors.fromJson(json), isNull);
    });

    test('roles this build does not know are ignored, not fatal', () {
      // A file from a build that added a role: the theme still reads.
      final json = _colors().toJson()..['futureRole'] = '#FFFFFF';
      expect(ThemeColors.fromJson(json), isNotNull);
    });
  });
}
