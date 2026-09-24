// Issue #269: the file a theme travels in.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/core/theme_transfer.dart';
import 'package:niman/src/ui/theme/theme_files.dart';

import '../fakes/sample_themes.dart';

void main() {
  final theme = sampleCustomTheme(id: 'mine', name: 'Sea Glass');

  String file() =>
      encodeThemeFile(name: theme.name, day: theme.day, night: theme.night);

  test('a theme survives the round trip', () {
    final read = decodeThemeFile(file());

    expect(read, isA<ThemeFileRead>());
    final readTheme = read as ThemeFileRead;
    expect(readTheme.name, 'Sea Glass');
    expect(readTheme.day, theme.day);
    expect(readTheme.night, theme.night);
  });

  test('the file says what it is, and which shape', () {
    final json = jsonDecode(file()) as Map<String, Object?>;

    expect(json['format'], 'niman-theme');
    expect(json['version'], 1);
    expect(json['name'], 'Sea Glass');
    // Both brightnesses, every role, in the order everything else reads
    // them in.
    expect((json['day']! as Map<String, Object?>).keys, ThemeColors.roleNames);
    expect(
      (json['night']! as Map<String, Object?>).keys,
      ThemeColors.roleNames,
    );
  });

  test('something that is not a theme file is refused', () {
    for (final source in [
      '',
      'not json at all',
      '[]',
      '{}',
      '{"format":"other","version":1,"name":"Dracula"}',
      '{"format":"niman-theme","version":1}',
      '{"format":"niman-theme","version":"one","name":"Dracula"}',
    ]) {
      final result = decodeThemeFile(source);
      expect(result, isA<ThemeFileRefused>(), reason: source);
      expect(
        (result as ThemeFileRefused).problem.kind,
        ThemeImportKind.notATheme,
        reason: source,
      );
    }
  });

  test('a file from a later build is refused with its version', () {
    final result = decodeThemeFile(
      jsonEncode({'format': 'niman-theme', 'version': 2, 'name': 'Later'}),
    );

    final refused = result as ThemeFileRefused;
    expect(refused.problem.kind, ThemeImportKind.newerVersion);
    expect(refused.problem.version, 2);
  });

  test('a role that is missing, or is not a color, is named', () {
    for (final side in ['day', 'night']) {
      for (final role in ['background', 'accent', 'wikilink', 'tag']) {
        final json = jsonDecode(file()) as Map<String, Object?>;
        final colors = Map<String, Object?>.of(
          json[side]! as Map<String, Object?>,
        )..remove(role);
        json[side] = colors;

        final refused = decodeThemeFile(jsonEncode(json)) as ThemeFileRefused;
        expect(refused.problem.kind, ThemeImportKind.badRole);
        expect(refused.problem.role, role, reason: '$side/$role');

        // Spelled wrong is the same as missing.
        colors[role] = 'teal';
        json[side] = colors;
        final misspelled =
            decodeThemeFile(jsonEncode(json)) as ThemeFileRefused;
        expect(misspelled.problem.kind, ThemeImportKind.badRole);
        expect(misspelled.problem.role, role, reason: '$side/$role');
      }
    }
  });

  test('a brightness that is not there at all is refused', () {
    final json = jsonDecode(file()) as Map<String, Object?>..remove('night');
    final refused = decodeThemeFile(jsonEncode(json)) as ThemeFileRefused;
    expect(refused.problem.kind, ThemeImportKind.notATheme);
  });

  test('a theme name becomes a file name', () {
    expect(themeFileName('Sea Glass'), 'Sea Glass');
    expect(themeFileName('a/b:c*d?e"f<g>h|i'), 'a-b-c-d-e-f-g-h-i');
    expect(themeFileName('  Spaced  '), 'Spaced');
    expect(themeFileName('   '), 'theme');
    expect(themeFileExtension, '.json');
  });

  test('an id is not something a file carries', () {
    // Two installations importing the same file get two themes, and the
    // id is what tells them apart.
    final one = newCustomThemeId();
    final two = newCustomThemeId();
    expect(one, isNot(two));
    expect(decodeThemeFile(file()), isA<ThemeFileRead>());
  });
}
