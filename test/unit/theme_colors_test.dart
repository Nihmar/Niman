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
      expect(json.length, 26);
    });

    test('the task-list roles are the last of the Markdown ones', () {
      expect(
        ThemeColors.markdownRoles.sublist(
          ThemeColors.markdownRoles.length - ThemeColors.taskListRoles.length,
        ),
        ThemeColors.taskListRoles,
      );
      expect(ThemeColors.taskListRoleSources.keys, ThemeColors.taskListRoles);
      // Each one is read from a role a theme had before it.
      for (final source in ThemeColors.taskListRoleSources.values) {
        expect(ThemeColors.taskListRoles, isNot(contains(source)));
        expect(ThemeColors.roleNames, contains(source));
      }
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
        if (ThemeColors.taskListRoles.contains(role)) continue;
        final without = Map.of(json)..remove(role);
        expect(ThemeColors.fromJson(without), isNull, reason: '$role missing');
      }
    });

    test('a theme from before the task-list roles reads them from the '
        'roles it was painted with', () {
      // Stored or exported before the roles existed: the theme loads, and
      // a task list looks exactly as it did then.
      final colors = _colors();
      final json = colors.toJson()
        ..removeWhere((role, _) => ThemeColors.taskListRoles.contains(role));

      final read = ThemeColors.fromJson(json)!;
      final syntax = colors.syntax;
      expect(read.tokens, colors.tokens);
      expect(read.syntax.todoPriority, syntax.task);
      expect(read.syntax.todoDate, syntax.dim);
      expect(read.syntax.todoProject, syntax.wikilink);
      expect(read.syntax.todoContext, syntax.link);
      expect(read.syntax.todoKeyValue, syntax.code);
      expect(read.syntax.todoDone, syntax.dim);
      // The rest of the Markdown roles are untouched.
      expect(read.syntax.tag, syntax.tag);
      expect(read.syntax.math, syntax.math);
    });

    test('a task-list role left out alone is derived, the rest kept', () {
      final json = _colors().toJson()
        ..['todoProject'] = '#123456'
        ..remove('todoPriority');

      final read = ThemeColors.fromJson(json)!;
      expect(read.syntax.todoProject, const Color(0xFF123456));
      expect(read.syntax.todoPriority, _colors().syntax.task);
    });

    test('a task-list role that is not a color is not a theme', () {
      // Left out is an older theme; named wrong is a broken one.
      for (final role in ThemeColors.taskListRoles) {
        final json = _colors().toJson()..[role] = 'teal';
        expect(ThemeColors.fromJson(json), isNull, reason: role);
      }
    });

    test('each task-list role is a color of its own', () {
      final colors = _colors();
      for (final role in ThemeColors.taskListRoles) {
        final moved = colors.withRole(role, const Color(0xFF010203));
        expect(moved.colorOf(role), const Color(0xFF010203), reason: role);
        expect(ThemeColors.fromJson(moved.toJson()), moved, reason: role);
        for (final other in ThemeColors.roleNames) {
          if (other == role) continue;
          expect(moved.colorOf(other), colors.colorOf(other), reason: other);
        }
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
