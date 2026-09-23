// #7: which days have an entry, and the ones around a day.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/journal/journal_days.dart';
import 'package:niman/src/journal/journal_settings.dart';

void main() {
  const settings = JournalSettings();

  test('entries are read from their paths, oldest first, once', () {
    expect(
      journalDays(settings, [
        'Journal/2026/09/2026-09-21.md',
        'Journal/2026/09/2026-09-03.md',
        'Journal/2026/09/Ideas.md',
        'Journal/About.md',
        'Journal/2026/08/2026-08-31.md',
      ]),
      [DateTime(2026, 8, 31), DateTime(2026, 9, 3), DateTime(2026, 9, 21)],
    );
  });

  test("a month's entries are read from the narrowest folder", () {
    expect(journalMonthFolder(settings, DateTime(2026, 9)), 'Journal/2026/09');
    const flat = JournalSettings(entryName: 'YYYY-MM-DD');
    expect(journalMonthFolder(flat, DateTime(2026, 9)), 'Journal');
    const perYear = JournalSettings(entryName: 'YYYY/M-D');
    expect(journalMonthFolder(perYear, DateTime(2026, 9)), 'Journal/2026');
    const atRoot = JournalSettings(folder: '', entryName: 'YYYY-MM-DD');
    expect(journalMonthFolder(atRoot, DateTime(2026, 9)), '');
  });

  test('the entries around a day skip the days without one', () {
    final days = [DateTime(2026, 9), DateTime(2026, 9, 3)];
    expect(journalDayBefore(days, DateTime(2026, 9, 3)), DateTime(2026, 9));
    expect(journalDayBefore(days, DateTime(2026, 9)), isNull);
    expect(journalDayAfter(days, DateTime(2026, 9)), DateTime(2026, 9, 3));
    expect(journalDayAfter(days, DateTime(2026, 9, 2)), DateTime(2026, 9, 3));
    expect(journalDayAfter(days, DateTime(2026, 9, 3)), isNull);
  });
}
