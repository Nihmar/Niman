// T-M6-12 AC: the two text sizes are per-library settings that survive a
// round trip through the settings file, land in range whatever the file
// says, and reach the screen as two scalers that never multiply each
// other.
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/text_scale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AppTextScales.reset);
  tearDown(AppTextScales.reset);

  group('normalizeTextScale', () {
    test('a number in range is kept', () {
      expect(normalizeTextScale(1.25), 1.25);
      expect(normalizeTextScale(minTextScale), minTextScale);
      expect(normalizeTextScale(maxTextScale), maxTextScale);
    });

    test('out of range clamps to the nearest legal size', () {
      expect(normalizeTextScale(0.1), minTextScale);
      expect(normalizeTextScale(12), maxTextScale);
      expect(normalizeTextScale(-3), minTextScale);
    });

    test('anything that is not a finite number is the shipped size', () {
      expect(normalizeTextScale(null), defaultTextScale);
      expect(normalizeTextScale('big'), defaultTextScale);
      expect(normalizeTextScale(double.nan), defaultTextScale);
      expect(normalizeTextScale(double.infinity), defaultTextScale);
    });

    test('an int in the file reads as a scale', () {
      expect(normalizeTextScale(1), 1.0);
    });
  });

  group('the library config carries both sizes', () {
    test('a fresh library reads at the shipped sizes', () {
      expect(LibraryConfig.defaults.uiTextScale, defaultTextScale);
      expect(LibraryConfig.defaults.noteTextScale, defaultTextScale);
    });

    test('they survive a write and a read', () {
      final config = LibraryConfig.defaults.copyWith(
        uiTextScale: 1.3,
        noteTextScale: 1.6,
      );
      final back = LibraryConfig.fromJsonMap(config.toJsonMap());
      expect(back.uiTextScale, 1.3);
      expect(back.noteTextScale, 1.6);
      expect(back, config);
    });

    test('a hand-typed nonsense size is read into range', () {
      final back = LibraryConfig.fromJsonMap(<String, Object?>{
        'uiTextScale': 40,
        'noteTextScale': 'huge',
      });
      expect(back.uiTextScale, maxTextScale);
      expect(back.noteTextScale, defaultTextScale);
    });
  });

  group('AppTextScales', () {
    test('a change bumps the revision the app root listens to', () {
      final before = AppTextScales.revision.value;
      AppTextScales.ui = 1.4;
      expect(AppTextScales.revision.value, before + 1);
      // The same size again is not a change.
      AppTextScales.ui = 1.4;
      expect(AppTextScales.revision.value, before + 1);
    });

    test('a size out of range is stored clamped', () {
      AppTextScales.note = 99;
      expect(AppTextScales.note, maxTextScale);
    });

    test('the editor font size follows the note slider only', () {
      AppTextScales.apply(ui: 1.5, note: 1.2);
      expect(AppTextScales.noteFontSize, closeTo(baseNoteFontSize * 1.2, 1e-9));
    });

    test('reset puts both back to the shipped sizes', () {
      AppTextScales.apply(ui: 1.5, note: 1.2);
      AppTextScales.reset();
      expect(AppTextScales.ui, defaultTextScale);
      expect(AppTextScales.note, defaultTextScale);
    });
  });

  group('ComposedTextScaler', () {
    test('multiplies the platform scale rather than replacing it', () {
      const platform = TextScaler.linear(1.5);
      const composed = ComposedTextScaler(platform, 2);
      expect(composed.scale(10), 30);
    });

    test('two with the same parts are the same scaler', () {
      // MediaQuery compares its data; a scaler that is never equal to
      // itself would rebuild the whole app every frame.
      const a = ComposedTextScaler(TextScaler.linear(1.5), 2);
      const b = ComposedTextScaler(TextScaler.linear(1.5), 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('clamping still bounds the result', () {
      const composed = ComposedTextScaler(TextScaler.linear(1), 4);
      expect(composed.clamp(maxScaleFactor: 2).scale(10), 20);
      expect(composed.clamp().scale(10), 40);
    });
  });

  group('the note scaler starts from under the interface one', () {
    testWidgets('so the two sliders do not multiply', (tester) async {
      AppTextScales.apply(ui: 1.5, note: 1.2);
      late TextScaler noteScaler;
      await tester.pumpWidget(
        MediaQuery(
          // What the app root installs.
          data: const MediaQueryData(
            textScaler: ComposedTextScaler(TextScaler.linear(2), 1.5),
          ),
          child: Builder(
            builder: (context) {
              noteScaler = noteTextScalerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // 2 (the platform) x 1.2 (the note slider). The interface's 1.5 is
      // gone: it was taken back off, not multiplied in.
      expect(noteScaler.scale(10), closeTo(24, 1e-9));
    });

    testWidgets('and a plain platform scaler passes straight through', (
      tester,
    ) async {
      AppTextScales.note = 1.2;
      late TextScaler noteScaler;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (context) {
              noteScaler = noteTextScalerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(noteScaler.scale(10), closeTo(24, 1e-9));
    });
  });
}
