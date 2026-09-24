// #7: the journal's entry names and settings — a day to its entry's path
// and back, and what settings.json may hold.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/journal/journal_pattern.dart';
import 'package:niman/src/journal/journal_settings.dart';

void main() {
  final day = DateTime(2026, 9, 3);

  group('the entry-name pattern', () {
    test('the default files each day under its year and month', () {
      final pattern = JournalPattern.tryParse(defaultJournalEntryName)!;
      expect(pattern.format(day), '2026/09/2026-09-03');
      expect(pattern.dayOf('2026/09/2026-09-03'), day);
    });

    test('short numbers and quoted words', () {
      final pattern = JournalPattern.tryParse("'Day' D.M.YYYY")!;
      expect(pattern.format(day), 'Day 3.9.2026');
      expect(pattern.dayOf('Day 3.9.2026'), day);
      expect(pattern.dayOf('Day 03.09.2026'), isNull);
    });

    test('a name it would not make is not an entry', () {
      final pattern = JournalPattern.tryParse(defaultJournalEntryName)!;
      expect(pattern.dayOf('2026/09/2026-09-31'), isNull, reason: 'no day');
      expect(pattern.dayOf('2026/08/2026-09-03'), isNull, reason: 'folders');
      expect(pattern.dayOf('2026/09/Notes'), isNull);
      expect(pattern.dayOf('2026/09/2026-09-03 copy'), isNull);
    });

    test('a pattern that cannot name one entry per day is refused', () {
      for (final bad in [
        'YYYY-MM', // no day
        'MM-DD', // no year
        'YY-MM-DD', // a two-digit year is not one
        'YYYY:MM:DD', // not a file name on Windows
        'YYYY//MM-DD', // an empty folder
        '../YYYY-MM-DD',
        "'open quote YYYY-MM-DD",
      ]) {
        expect(JournalPattern.tryParse(bad), isNull, reason: bad);
      }
    });

    test('a refused pattern falls back to the default', () {
      expect(
        JournalPattern.orDefault('nonsense').source,
        defaultJournalEntryName,
      );
    });
  });

  group('the settings', () {
    test('entry paths sit in the folder, or at the root', () {
      const settings = JournalSettings();
      expect(settings.entryPath(day), 'Journal/2026/09/2026-09-03.md');
      expect(settings.dayOfPath('Journal/2026/09/2026-09-03.md'), day);
      expect(settings.dayOfPath('Other/2026/09/2026-09-03.md'), isNull);
      expect(settings.dayOfPath('Journal/2026/09/2026-09-03.txt'), isNull);
      const atRoot = JournalSettings(folder: '', entryName: 'YYYY-MM-DD');
      expect(atRoot.entryPath(day), '2026-09-03.md');
      expect(atRoot.dayOfPath('2026-09-03.md'), day);
    });

    test('a day may start after midnight', () {
      const late = JournalSettings(dayStartHour: 4);
      expect(late.today(DateTime(2026, 9, 3, 3, 59)), DateTime(2026, 9, 2));
      expect(late.today(DateTime(2026, 9, 3, 4)), day);
      expect(late.today(DateTime(2026, 9, 1, 1)), DateTime(2026, 8, 31));
      expect(const JournalSettings().today(DateTime(2026, 9, 3, 0, 5)), day);
    });

    test('a hand-edited file reads back sane', () {
      final settings = JournalSettings.fromJson(const {
        'journalFolder': '/Diary/../2026/',
        'journalEntryName': 'MM-DD',
        'journalTemplate': '  ',
        'journalDayStart': 9,
      });
      expect(settings.folder, 'Diary/2026');
      expect(settings.entryName, defaultJournalEntryName);
      expect(settings.template, isNull);
      expect(settings.dayStartHour, 0);
    });

    test('they travel in settings.json', () {
      final config = LibraryConfig.defaults.copyWith(
        journal: const JournalSettings(
          folder: 'Diary',
          template: 'Templates/Day.md',
          dayStartHour: 4,
        ),
      );
      final json = config.toJsonMap();
      expect(json['journalFolder'], 'Diary');
      expect(json['journalTemplate'], 'Templates/Day.md');
      expect(LibraryConfig.fromJsonMap(json), config);
      expect(LibraryConfig.fromJsonMap(json).extra, isEmpty);
      expect(
        LibraryConfig.defaults.toJsonMap().containsKey('journalTemplate'),
        isFalse,
      );
    });
  });
}
