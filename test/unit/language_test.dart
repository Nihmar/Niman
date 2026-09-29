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
        // The welcome deck and the guided tour (#308) were the last
        // English-only surface; the samples keep them localized.
        () => AppStrings.welcomeNotesTitle,
        () => AppStrings.welcomeNext,
        () => AppStrings.tourTreeTitle,
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

    // The editor's word count used to read "1 words", in English, in
    // every language. A count carries a plural, and a plural is not a
    // letter added to the end of a noun.
    test('the word count follows each language plural rule', () {
      AppLanguages.choice = AppLanguage.english;
      expect(AppStrings.wordCount(0), '0 words');
      expect(AppStrings.wordCount(1), '1 word');
      expect(AppStrings.wordCount(2), '2 words');

      AppLanguages.choice = AppLanguage.italian;
      expect(AppStrings.wordCount(1), '1 parola');
      expect(AppStrings.wordCount(3), '3 parole');

      // Three forms, and the teens are their own case.
      AppLanguages.choice = AppLanguage.polish;
      expect(AppStrings.wordCount(1), '1 słowo');
      expect(AppStrings.wordCount(3), '3 słowa');
      expect(AppStrings.wordCount(5), '5 słów');
      expect(AppStrings.wordCount(13), '13 słów');
      expect(AppStrings.wordCount(22), '22 słowa');

      AppLanguages.choice = AppLanguage.czech;
      expect(AppStrings.wordCount(1), '1 slovo');
      expect(AppStrings.wordCount(4), '4 slova');
      expect(AppStrings.wordCount(5), '5 slov');

      AppLanguages.choice = AppLanguage.ukrainian;
      expect(AppStrings.wordCount(1), '1 слово');
      expect(AppStrings.wordCount(2), '2 слова');
      expect(AppStrings.wordCount(11), '11 слів');
      expect(AppStrings.wordCount(21), '21 слово');

      // Romanian puts "de" in front of the noun from twenty up.
      AppLanguages.choice = AppLanguage.romanian;
      expect(AppStrings.wordCount(1), '1 cuvânt');
      expect(AppStrings.wordCount(19), '19 cuvinte');
      expect(AppStrings.wordCount(20), '20 de cuvinte');
      expect(AppStrings.wordCount(100), '100 de cuvinte');
      expect(AppStrings.wordCount(101), '101 cuvinte');
    });

    // The status row counts the checker's findings, and the same count in
    // the same language takes the same form there as it does in the word
    // count: a language whose twenty-one is a singular must not say
    // "1 problem" for it, and one that also puts twenty-one in the
    // singular must not take the plural form for it either.
    test('the template problem count follows its language plural rule', () {
      AppLanguages.choice = AppLanguage.ukrainian;
      expect(AppStrings.templateProblems(1), '1 проблема в цьому шаблоні');
      expect(AppStrings.templateProblems(21), '21 проблема в цьому шаблоні');
      expect(AppStrings.templateProblems(22), '22 проблеми в цьому шаблоні');
      expect(AppStrings.templateProblems(11), '11 проблем у цьому шаблоні');
      expect(AppStrings.templateProblems(25), '25 проблем у цьому шаблоні');

      AppLanguages.choice = AppLanguage.lithuanian;
      expect(AppStrings.templateProblems(1), '1 problema šiame šablone');
      expect(AppStrings.templateProblems(21), '21 problema šiame šablone');
      expect(AppStrings.templateProblems(22), '22 problemos šiame šablone');
      expect(AppStrings.templateProblems(11), '11 problemų šiame šablone');

      AppLanguages.choice = AppLanguage.belarusian;
      expect(AppStrings.templateProblems(1), '1 праблема ў гэтым шаблоне');
      expect(AppStrings.templateProblems(21), '21 праблема ў гэтым шаблоне');
      expect(AppStrings.templateProblems(22), '22 праблемы ў гэтым шаблоне');
      expect(AppStrings.templateProblems(11), '11 праблем у гэтым шаблоне');
      expect(AppStrings.templateProblems(25), '25 праблем у гэтым шаблоне');

      AppLanguages.choice = AppLanguage.croatian;
      expect(AppStrings.templateProblems(1), '1 problem u ovom predlošku');
      expect(AppStrings.templateProblems(21), '21 problem u ovom predlošku');
      expect(AppStrings.templateProblems(11), '11 problema u ovom predlošku');

      AppLanguages.choice = AppLanguage.bosnian;
      expect(AppStrings.templateProblems(1), '1 problem u ovom predlošku');
      expect(AppStrings.templateProblems(21), '21 problem u ovom predlošku');
      expect(AppStrings.templateProblems(11), '11 problema u ovom predlošku');

      AppLanguages.choice = AppLanguage.serbian;
      expect(AppStrings.templateProblems(1), '1 проблем у овом шаблону');
      expect(AppStrings.templateProblems(21), '21 проблем у овом шаблону');
      expect(AppStrings.templateProblems(11), '11 проблема у овом шаблону');

      AppLanguages.choice = AppLanguage.latvian;
      expect(AppStrings.templateProblems(0), '0 problēmu šajā šablonā');
      expect(AppStrings.templateProblems(1), '1 problēma šajā šablonā');
      expect(AppStrings.templateProblems(2), '2 problēmas šajā šablonā');
      expect(AppStrings.templateProblems(11), '11 problēmu šajā šablonā');
      expect(AppStrings.templateProblems(21), '21 problēma šajā šablonā');

      AppLanguages.choice = AppLanguage.macedonian;
      expect(AppStrings.templateProblems(1), '1 проблем во овој шаблон');
      expect(AppStrings.templateProblems(21), '21 проблем во овој шаблон');
      expect(AppStrings.templateProblems(11), '11 проблеми во овој шаблон');

      // Slovene counts by the last two digits: 101 is a "one" again.
      AppLanguages.choice = AppLanguage.slovenian;
      expect(AppStrings.templateProblems(2), '2 težavi v tej predlogi');
      expect(AppStrings.templateProblems(101), '101 težava v tej predlogi');
      expect(AppStrings.templateProblems(102), '102 težavi v tej predlogi');
      expect(AppStrings.templateProblems(5), '5 težav v tej predlogi');
    });

    // The same rule, asked of every language at once: the counts that take
    // one form in the word count must take one form in the problem count,
    // and the counts that take different forms there must here. The nouns
    // differ, so the number is cut out and the rest is compared as the
    // form; a language whose word count never changes form has no rule to
    // hold the problem count to.
    test('the problem count changes form where the word count does', () {
      String form(String text, int n) => text.replaceFirst('$n', '#');
      // Counts grouped by the form they take, each named by its smallest.
      List<int> classes(String Function(int) say) {
        final firstOf = <String, int>{};
        return [
          for (var n = 0; n <= 130; n++)
            firstOf.putIfAbsent(form(say(n), n), () => n),
        ];
      }

      final differ = <String>[];
      for (final language in AppLanguages.supported) {
        AppLanguages.choice = language;
        final words = classes(AppStrings.wordCount);
        if (words.toSet().length == 1) continue;
        final problems = classes(AppStrings.templateProblems);
        for (var n = 0; n < words.length; n++) {
          if (words[n] != problems[n]) {
            differ.add('${language.id}: $n');
            break;
          }
        }
      }
      expect(differ, isEmpty);
    });

    // The replace summary counts notes too, and the singular is the
    // language's own: twenty-one notes are a singular in Ukrainian, Slovene
    // counts by the last two digits, and `count == 1` said the plural for
    // both. The word count is the language's rule for which counts are "one";
    // the summary must agree with it on every count, and on no other. Only
    // the singular is compared, because a language can merge its other forms
    // (Polish says "notatkach" from two up) and Croatian spells its "few" and
    // "many" nouns alike in the word count. A language whose word never
    // changes form has no rule to hold the summary to.
    test('the replace counts take the singular where the word count does', () {
      String form(String text, int n) => text.replaceFirst('$n', '#');
      final counts = <String, String Function(int)>{
        'replaceScopeNotes': AppStrings.replaceScopeNotes,
        'replaceWriteFailed': AppStrings.replaceWriteFailed,
      };
      final differ = <String>[];
      for (final language in AppLanguages.supported) {
        AppLanguages.choice = language;
        final singular = form(AppStrings.wordCount(1), 1);
        if (singular == form(AppStrings.wordCount(2), 2)) continue;
        for (final entry in counts.entries) {
          final one = form(entry.value(1), 1);
          // Finnish puts one note and two in the same partitive.
          if (one == form(entry.value(2), 2)) continue;
          for (var n = 0; n <= 130; n++) {
            final wordSaysOne = form(AppStrings.wordCount(n), n) == singular;
            final summarySaysOne = form(entry.value(n), n) == one;
            if (wordSaysOne != summarySaysOne) {
              differ.add('${language.id} ${entry.key}: $n');
              break;
            }
          }
        }
      }
      expect(differ, isEmpty);
    });

    test('the replace counts follow the plural rule of the language', () {
      AppLanguages.choice = AppLanguage.ukrainian;
      expect(AppStrings.replaceScopeNotes(21), 'у 21 нотатці');
      expect(
        AppStrings.replaceWriteFailed(2),
        ' (2 нотатки не вдалося записати)',
      );
      expect(
        AppStrings.replaceWriteFailed(5),
        ' (5 нотаток не вдалося записати)',
      );
      expect(
        AppStrings.replaceWriteFailed(21),
        ' (21 нотатку не вдалося записати)',
      );

      AppLanguages.choice = AppLanguage.croatian;
      expect(AppStrings.replaceScopeNotes(21), 'u 21 napomeni');
      expect(AppStrings.replaceScopeNotes(3), 'u 3 napomene');
      expect(AppStrings.replaceScopeNotes(11), 'u 11 napomena');

      AppLanguages.choice = AppLanguage.czech;
      expect(AppStrings.replaceWriteFailed(1), ' (1 poznámku nešlo zapsat)');
      expect(AppStrings.replaceWriteFailed(3), ' (3 poznámky nešlo zapsat)');
      expect(AppStrings.replaceWriteFailed(5), ' (5 poznámek nešlo zapsat)');

      AppLanguages.choice = AppLanguage.romanian;
      expect(AppStrings.replaceScopeNotes(19), 'în 19 note');
      expect(AppStrings.replaceScopeNotes(20), 'în 20 de note');
      expect(AppStrings.replaceScopeNotes(100), 'în 100 de note');

      AppLanguages.choice = AppLanguage.slovenian;
      expect(AppStrings.replaceScopeNotes(101), 'v 101 opombi');
      expect(AppStrings.replaceScopeNotes(102), 'v 102 opombah');
    });

    test('every language answers the note statuses', () {
      for (final language in AppLanguages.supported) {
        AppLanguages.choice = language;
        for (final status in [
          AppStrings.noteStatusLoading,
          AppStrings.noteStatusSaving,
          AppStrings.noteStatusUnsaved,
          AppStrings.noteStatusSaved,
          AppStrings.noteStatusError,
        ]) {
          expect(status, isNotEmpty, reason: language.name);
        }
        // Saved and unsaved are the pair the eye checks at a glance.
        expect(
          AppStrings.noteStatusSaved,
          isNot(AppStrings.noteStatusUnsaved),
          reason: language.name,
        );
      }
    });

    // The history-off notice points at where the switch is: it used to
    // name "Settings, Library", which stopped being a place when the
    // settings were reshaped (#498).
    test('the history-off notice names the Trash and history section', () {
      for (final language in AppLanguages.supported) {
        AppLanguages.choice = language;
        expect(
          AppStrings.historyOff,
          contains(AppStrings.settingsAreaTrashHistory),
          reason: language.name,
        );
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

    // The keys added after v0.1.3 shipped as the English text copied into
    // every locale. The abstract `Strings` contract only checks that a
    // member exists, so an English copy compiles and hides in plain
    // sight; these probes ask each language for the key and compare the
    // answer to English, which a copy cannot pass.
    group('the keys added since v0.1.3 are translated', () {
      // The answers that really are the same word in every language: a
      // digest label is a digest label, whoever spells it.
      const sameEverywhere = <String>{'syncCertTrustedSubtitle'};

      // The words a language genuinely spells like English: a type is a
      // type, and `in <path>` is what three languages say for it.
      const sameWord = <String>{
        'da/frontmatterTypeLabel',
        'fr/frontmatterTypeLabel',
        'nb/frontmatterTypeLabel',
        'nl/frontmatterTypeLabel',
        'ca/frontmatterTypeText',
        'cs/frontmatterTypeText',
        'ro/frontmatterTypeText',
        'sk/frontmatterTypeText',
        'sv/frontmatterTypeText',
        'fr/frontmatterTypeDate',
        'de/replaceScopeNote',
        'it/replaceScopeNote',
        'nl/replaceScopeNote',
      };

      // `alias` is the word for it in the languages that took it from
      // Latin, and the panel's pill says the name and nothing else: no
      // language has a shorter one to put there.
      const aliasIsTheWord = <String>[
        'bs',
        'cs',
        'da',
        'es',
        'et',
        'fi',
        'fr',
        'gl',
        'hr',
        'is',
        'it',
        'nb',
        'nl',
        'pl',
        'pt',
        'ro',
        'sk',
        'sq',
        'sv',
      ];

      final probes = <String, String Function()>{
        'sourceFontTitle': () => AppStrings.sourceFontTitle,
        'sourceFontSubtitle': () => AppStrings.sourceFontSubtitle,
        'sourceFontMonospace': () => AppStrings.sourceFontMonospace,
        'sourceFontSansSerif': () => AppStrings.sourceFontSansSerif,
        'sourceFontSerif': () => AppStrings.sourceFontSerif,
        'frontmatterTitle': () => AppStrings.frontmatterTitle,
        'frontmatterPanelTitle': () => AppStrings.frontmatterPanelTitle,
        'frontmatterPanelSubtitle': () => AppStrings.frontmatterPanelSubtitle,
        'frontmatterShowRaw': () => AppStrings.frontmatterShowRaw,
        'frontmatterShowFields': () => AppStrings.frontmatterShowFields,
        'frontmatterAddField': () => AppStrings.frontmatterAddField,
        'frontmatterNewField': () => AppStrings.frontmatterNewField,
        'frontmatterEditField': () => AppStrings.frontmatterEditField,
        'frontmatterKeyLabel': () => AppStrings.frontmatterKeyLabel,
        'frontmatterValueLabel': () => AppStrings.frontmatterValueLabel,
        'frontmatterTypeLabel': () => AppStrings.frontmatterTypeLabel,
        'frontmatterListHint': () => AppStrings.frontmatterListHint,
        'frontmatterRemoveField': () => AppStrings.frontmatterRemoveField,
        'frontmatterNoFields': () => AppStrings.frontmatterNoFields,
        'frontmatterTypeText': () => AppStrings.frontmatterTypeText,
        'frontmatterTypeNumber': () => AppStrings.frontmatterTypeNumber,
        'frontmatterTypeDate': () => AppStrings.frontmatterTypeDate,
        'frontmatterTypeBoolean': () => AppStrings.frontmatterTypeBoolean,
        'frontmatterTypeList': () => AppStrings.frontmatterTypeList,
        'replaceScopeNote': () => AppStrings.replaceScopeNote('a.md'),
        'replaceScopeWholeLibrary': () => AppStrings.replaceScopeWholeLibrary,
        'replaceScopeNotes': () => AppStrings.replaceScopeNotes(2),
        'replaceWriteFailed': () => AppStrings.replaceWriteFailed(2),
        'audioPlayFailed': () => AppStrings.audioPlayFailed,
        'shellActionFailed': () => AppStrings.shellActionFailed,
        'templateOpenFailed': () => AppStrings.templateOpenFailed,
        'notionImportFailed': () => AppStrings.notionImportFailed,
        'exportPdfEngineFailed': () =>
            AppStrings.exportPdfEngineFailed('the engine exited with 3'),
        'trashActionFailed': () => AppStrings.trashActionFailed,
        'trashEmptyFailed': () => AppStrings.trashEmptyFailed,
        'reindexFailed': () => AppStrings.reindexFailed,
        'syncTestCertificate': () => AppStrings.syncTestCertificate,
        'syncTestCertificateHint': () => AppStrings.syncTestCertificateHint,
        'syncCertTrustTitle': () => AppStrings.syncCertTrustTitle,
        'syncCertTrustBody': () =>
            AppStrings.syncCertTrustBody('host', 'fingerprint'),
        'syncCertTrustAction': () => AppStrings.syncCertTrustAction,
        'syncCertTrustedTitle': () => AppStrings.syncCertTrustedTitle,
        'syncCertTrustedSubtitle': () =>
            AppStrings.syncCertTrustedSubtitle('fingerprint'),
        'syncCertForgetTitle': () => AppStrings.syncCertForgetTitle,
        'syncCertForgetBody': () => AppStrings.syncCertForgetBody,
        'syncCertForgetAction': () => AppStrings.syncCertForgetAction,
        // The wikilink panel's own words and the book forms' hints
        // (#475), and what the template checker's hint says (T-TPL-09):
        // the code wrote them in English until now.
        'wikilinkHeadingsIn': () => AppStrings.wikilinkHeadingsIn('Note'),
        'wikilinkPlacesIn': () => AppStrings.wikilinkPlacesIn('Dune.pdf'),
        'wikilinkThisNote': () => AppStrings.wikilinkThisNote,
        'wikilinkNoMatchHeading': () =>
            AppStrings.wikilinkNoMatchHeading('Intro'),
        'wikilinkNoMatchNote': () => AppStrings.wikilinkNoMatchNote('Intro'),
        'wikilinkNoHeading': () => AppStrings.wikilinkNoHeading,
        'wikilinkNoNote': () => AppStrings.wikilinkNoNote,
        'wikilinkAlias': () => AppStrings.wikilinkAlias('Ada'),
        'wikilinkBookNote': () => AppStrings.wikilinkBookNote,
        'wikilinkFooterMove': () => AppStrings.wikilinkFooterMove,
        'wikilinkFooterOr': () => AppStrings.wikilinkFooterOr,
        'wikilinkFooterInsert': () => AppStrings.wikilinkFooterInsert,
        'wikilinkFooterClose': () => AppStrings.wikilinkFooterClose,
        'suggesterPageHint': () => AppStrings.suggesterPageHint,
        'suggesterChapterHint': () => AppStrings.suggesterChapterHint,
        'templateProblemUnclosedBraces': () =>
            AppStrings.templateProblemUnclosedBraces,
        'templateProblemEmptyPlaceholder': () =>
            AppStrings.templateProblemEmptyPlaceholder,
        'templateProblemUnknownPlaceholder': () =>
            AppStrings.templateProblemUnknownPlaceholder('titlex'),
        'templateProblemAskNoLabel': () =>
            AppStrings.templateProblemAskNoLabel('ask'),
        'templateProblemCounterNoName': () =>
            AppStrings.templateProblemCounterNoName('counter'),
        'templateProblemCursorFilters': () =>
            AppStrings.templateProblemCursorFilters('cursor'),
        'templateProblemUnclosedQuote': () =>
            AppStrings.templateProblemUnclosedQuote,
        'templateProblemUnknownDateToken': () =>
            AppStrings.templateProblemUnknownDateToken('YYYYY'),
        'templateProblemEmptyFilter': () =>
            AppStrings.templateProblemEmptyFilter,
        'templateProblemDateMove': () =>
            AppStrings.templateProblemDateMove('+1d', 'YYYY, MM'),
        'templateProblemNotADateMove': () =>
            AppStrings.templateProblemNotADateMove('+xd'),
        'templateProblemSnapUnit': () => AppStrings.templateProblemSnapUnit(
          'startof:month',
          'year, month',
          'week',
        ),
        'templateProblemPadWidth': () =>
            AppStrings.templateProblemPadWidth('pad', 'wide'),
        'templateProblemUnknownFilter': () =>
            AppStrings.templateProblemUnknownFilter('upperr'),
      };

      test('no language answers the English text', () {
        AppLanguages.choice = AppLanguage.english;
        final english = <String, String>{
          for (final key in probes.keys) key: probes[key]!(),
        };
        for (final language in AppLanguages.supported) {
          if (language == AppLanguage.english) continue;
          AppLanguages.choice = language;
          for (final key in probes.keys) {
            final value = probes[key]!();
            expect(value, isNotEmpty, reason: '${language.name} $key');
            if (sameEverywhere.contains(key)) continue;
            if (sameWord.contains('${language.id}/$key')) continue;
            if (key == 'wikilinkAlias' &&
                aliasIsTheWord.contains(language.id)) {
              continue;
            }
            expect(value, isNot(english[key]), reason: '${language.name} $key');
          }
        }
      });

      // A failure snackbar names the trash the way the trash's own title
      // does: two words for one place in one language read as two places.
      // Inflection changes the ending, so the start of the word is what is
      // compared. Hungarian is left out: its accusative lengthens the last
      // vowel ("kuka", "kukát"), so the stem does not survive the ending.
      test("the empty-trash failure uses the language's word for trash", () {
        final differ = <String>[];
        for (final language in AppLanguages.supported) {
          if (language.id == 'hu') continue;
          AppLanguages.choice = language;
          final title = AppStrings.trashTitle.toLowerCase();
          final stem = title.substring(0, title.length < 4 ? title.length : 4);
          if (!AppStrings.trashEmptyFailed.toLowerCase().contains(stem)) {
            differ.add(
              '${language.id}: "${AppStrings.trashTitle}" / '
              '"${AppStrings.trashEmptyFailed}"',
            );
          }
        }
        expect(differ, isEmpty);
      });

      // What a translation says cannot be pinned by a test: the certificate
      // dialog once claimed, in all 36 languages, the opposite of what the
      // English source says, and every check passed. What a test can hold
      // is that the dialog still shows the two facts the user decides on.
      test('the certificate dialog shows the host and the fingerprint', () {
        for (final language in AppLanguages.supported) {
          AppLanguages.choice = language;
          final body = AppStrings.syncCertTrustBody('example.test', 'AB:CD:EF');
          expect(body, contains('example.test'), reason: language.name);
          expect(body, contains('AB:CD:EF'), reason: language.name);
          expect(body, contains('SHA-256'), reason: language.name);
        }
      });
    });
  });
}
