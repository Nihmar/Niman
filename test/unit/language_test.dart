// T-L10N-01: the active language, and the strings that follow it.
import 'package:copist/src/core/language.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  group('AppLanguage', () {
    test('ids round-trip; anything unknown follows the system', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromId(language.id), language);
      }
      expect(AppLanguage.fromId('kl'), AppLanguage.system);
      expect(AppLanguage.fromId(null), AppLanguage.system);
    });
  });

  group('AppLanguages', () {
    test('the default follows the system, which starts English', () {
      expect(AppLanguages.choice, AppLanguage.system);
      expect(AppLanguages.resolved, AppLanguage.english);
      expect(AppLanguages.isItalian, isFalse);
    });

    test('an Italian system makes the app Italian', () {
      AppLanguages.system = AppLanguage.italian;
      expect(AppLanguages.resolved, AppLanguage.italian);
      expect(AppLanguages.isItalian, isTrue);
      expect(AppLanguages.locale, const Locale('it'));
    });

    test('a chosen language wins over the system', () {
      AppLanguages.system = AppLanguage.italian;
      AppLanguages.choice = AppLanguage.english;
      expect(AppLanguages.resolved, AppLanguage.english);
      expect(AppLanguages.locale, const Locale('en'));
    });

    test('the revision moves only when the resolved language changes', () {
      final start = AppLanguages.revision.value;
      // English is already what the system resolves to.
      AppLanguages.choice = AppLanguage.english;
      expect(AppLanguages.revision.value, start);

      AppLanguages.choice = AppLanguage.italian;
      expect(AppLanguages.revision.value, start + 1);

      // The system language now changes under a chosen language: nothing
      // visible changes, so nothing rebuilds.
      AppLanguages.system = AppLanguage.italian;
      expect(AppLanguages.revision.value, start + 1);
    });

    test('the platform locales pick a supported language', () {
      expect(
        AppLanguages.fromLocales(const [Locale('it', 'IT')]),
        AppLanguage.italian,
      );
      expect(
        AppLanguages.fromLocales(const [Locale('en', 'GB')]),
        AppLanguage.english,
      );
      // An unsupported first choice falls through to a supported one.
      expect(
        AppLanguages.fromLocales(const [Locale('de'), Locale('it')]),
        AppLanguage.italian,
      );
      expect(AppLanguages.fromLocales(const [Locale('de')]),
          AppLanguage.english);
      expect(AppLanguages.fromLocales(null), AppLanguage.english);
    });
  });

  group('AppStrings', () {
    test('every label answers in both languages, and they differ', () {
      // A spot check across the app's areas: the point is that the
      // Italian is really there, not that every string is listed.
      final samples = <String Function()>[
        () => AppStrings.trashTitle,
        () => AppStrings.todoTitle,
        () => AppStrings.searchHint,
        () => AppStrings.toolbarBold,
        () => AppStrings.listEmpty,
        () => AppStrings.languageTitle,
      ];
      for (final sample in samples) {
        AppLanguages.choice = AppLanguage.english;
        final en = sample();
        AppLanguages.choice = AppLanguage.italian;
        final it = sample();
        expect(en, isNotEmpty);
        expect(it, isNotEmpty);
        expect(it, isNot(en));
      }
    });

    test('month names are translated and complete', () {
      AppLanguages.choice = AppLanguage.english;
      expect(AppStrings.monthNames.length, 12);
      expect(AppStrings.monthNames[8], 'Sep');
      AppLanguages.choice = AppLanguage.italian;
      expect(AppStrings.monthNames.length, 12);
      expect(AppStrings.monthNames[8], 'set');
    });
  });
}
