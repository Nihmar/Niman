// T-L10N-01: the active language, and the strings that follow it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/ui/strings.dart';

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
    });

    test('an Italian system makes the app Italian', () {
      AppLanguages.system = AppLanguage.italian;
      expect(AppLanguages.resolved, AppLanguage.italian);
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

    test('the platform locales pick the first supported match', () {
      for (final language in AppLanguages.supported) {
        expect(
          AppLanguages.fromLocales([Locale(language.id)]),
          language,
          reason: language.name,
        );
      }
      // A region variant still matches its language.
      expect(
        AppLanguages.fromLocales(const [Locale('pt', 'BR')]),
        AppLanguage.portuguese,
      );
      expect(
        AppLanguages.fromLocales(const [Locale('zh', 'Hans')]),
        AppLanguage.chinese,
      );
      // The first supported match wins, even when others follow.
      expect(
        AppLanguages.fromLocales(const [Locale('de'), Locale('it')]),
        AppLanguage.german,
      );
      // An unsupported first choice falls through to the next supported one.
      expect(
        AppLanguages.fromLocales(const [Locale('kl'), Locale('it')]),
        AppLanguage.italian,
      );
      expect(
        AppLanguages.fromLocales(const [Locale('kl')]),
        AppLanguage.english,
      );
      expect(AppLanguages.fromLocales(null), AppLanguage.english);
    });
  });

  group('AppStrings', () {
    test('every label answers in every language, and they differ', () {
      // A spot check across the app's areas: the point is that the other
      // languages are really there, not that every string is listed.
      final samples = <String Function()>[
        () => AppStrings.trashTitle,
        () => AppStrings.todoTitle,
        () => AppStrings.searchHint,
        () => AppStrings.toolbarBold,
        () => AppStrings.listEmpty,
        () => AppStrings.languageTitle,
      ];
      AppLanguages.choice = AppLanguage.english;
      final en = samples.map((sample) => sample()).toList();
      for (final language in AppLanguages.supported) {
        if (language == AppLanguage.english) continue;
        AppLanguages.choice = language;
        for (var i = 0; i < samples.length; i++) {
          final value = samples[i]();
          expect(value, isNotEmpty, reason: '${language.name} label $i');
          expect(value, isNot(en[i]), reason: '${language.name} label $i');
        }
      }
    });

    test('month and weekday names are translated and complete', () {
      AppLanguages.choice = AppLanguage.english;
      expect(AppStrings.monthNamesShort.length, 12);
      expect(AppStrings.monthNamesShort[8], 'Sep');
      expect(AppStrings.monthNames[8], 'September');
      expect(AppStrings.weekdayNames.length, 7);
      expect(AppStrings.weekdayNames.first, 'Monday');
      expect(AppStrings.weekdayNamesShort.first, 'Mon');
      AppLanguages.choice = AppLanguage.italian;
      expect(AppStrings.monthNamesShort.length, 12);
      expect(AppStrings.monthNamesShort[8], 'set');
      expect(AppStrings.monthNames[8], 'settembre');
      expect(AppStrings.weekdayNames.length, 7);
      expect(AppStrings.weekdayNames.first, 'lunedì');
      expect(AppStrings.weekdayNamesShort.first, 'lun');
    });

    test('month and weekday names are complete in every language', () {
      for (final language in AppLanguages.supported) {
        AppLanguages.choice = language;
        expect(AppStrings.monthNames.length, 12, reason: language.name);
        expect(AppStrings.monthNamesShort.length, 12, reason: language.name);
        expect(AppStrings.weekdayNames.length, 7, reason: language.name);
        expect(AppStrings.weekdayNamesShort.length, 7, reason: language.name);
        expect(AppStrings.monthNames.first, isNotEmpty, reason: language.name);
        expect(
          AppStrings.weekdayNames.first,
          isNotEmpty,
          reason: language.name,
        );
      }
    });

    test('language names read in their own language', () {
      expect(AppStrings.languageName(AppLanguage.italian), 'Italiano');
      expect(AppStrings.languageName(AppLanguage.french), 'Français');
      expect(AppStrings.languageName(AppLanguage.chinese), '中文');
      expect(AppStrings.languageName(AppLanguage.system), isNotEmpty);
    });
  });
}
