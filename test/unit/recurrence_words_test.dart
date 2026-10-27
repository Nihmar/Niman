// #1189: a recurrence rule in the words of the app language.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/ui/recurrence_words.dart';
import 'package:niman/src/ui/strings.dart';

String words(String rec, {bool fromDue = false}) =>
    recurrenceWords(RecurrenceRule.parse(rec)!.description, fromDue: fromDue);

void main() {
  setUp(() {
    AppLanguages.reset();
    AppLanguages.choice = AppLanguage.english;
  });
  tearDown(AppLanguages.reset);

  group('English', () {
    test('the plain steps', () {
      expect(words('1d'), 'every day');
      expect(words('1w'), 'every week');
      expect(words('1m'), 'every month');
      expect(words('1y'), 'every year');
      expect(words('1b'), 'every weekday');
      expect(words('2w'), 'every 2 weeks');
      expect(words('3b'), 'every 3 business days');
    });

    test('weekdays and the Nth weekday', () {
      expect(words('1w;mo,we'), 'every week on Mon, Wed');
      expect(words('2w;fr'), 'every 2 weeks on Fri');
      expect(words('1m;2tu'), 'every month on the 2nd Tuesday');
      expect(words('1m;-1fr'), 'every month on the last Friday');
    });

    test('strict says so only when asked', () {
      expect(words('+1w'), 'every week');
      expect(words('+1w', fromDue: true), 'every week from the due date');
      expect(words('1w', fromDue: true), 'every week');
    });

    test('sentenceCase raises the first letter only', () {
      expect(sentenceCase('every week on Mon'), 'Every week on Mon');
      expect(sentenceCase(''), '');
      expect(sentenceCase('毎週'), '毎週');
    });
  });

  group('every language', () {
    test('has a sentence for every shape of rule', () {
      for (final language in AppLanguages.supported) {
        AppLanguages.choice = language;
        for (final rec in [
          '1d',
          '2d',
          '5d',
          '12d',
          '21w',
          '1b',
          '3b',
          '1m',
          '1y',
          '1w;mo,we,fr',
          '1m;3th',
          '1m;-1su',
          '+1w',
        ]) {
          final text = words(rec, fromDue: true);
          expect(text, isNotEmpty, reason: '${language.id} $rec');
          expect(text, isNot(contains(r'$')), reason: '${language.id} $rec');
        }
        // The same sentence is not reused for different counts.
        expect(words('2d'), isNot(words('1d')), reason: language.id);
        expect(
          words('1m;2tu'),
          isNot(words('1m;3tu')),
          reason: '${language.id} ordinals',
        );
        expect(AppStrings.todoRepeat, isNotEmpty);
      }
    });
  });
}
