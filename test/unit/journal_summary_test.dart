// #7: an entry's first words, for the journal's recent list.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/journal/journal_summary.dart';

void main() {
  test('past the frontmatter and the headings, markers off', () {
    expect(
      journalSummary(
        '---\ntags: [journal]\n---\n# Wednesday\n\n- [x] Call the plumber\n',
      ),
      'Call the plumber',
    );
    expect(journalSummary('# Day\n\n> Rain all day.\n'), 'Rain all day.');
    expect(journalSummary('1. First thing\n'), 'First thing');
  });

  test('a long line is cut, an empty entry says nothing', () {
    expect(journalSummary('word ' * 40, max: 20), hasLength(20));
    expect(journalSummary('word ' * 40, max: 20), endsWith('…'));
    expect(journalSummary('# Only a heading\n\n'), '');
  });
}
