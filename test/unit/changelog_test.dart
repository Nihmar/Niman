import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/changelog.dart';

void main() {
  group('parseChangelog', () {
    const sample = '''
# Changelog

Some introductory prose that is not an entry.
See [the releases](https://example.com).

## [0.0.3] - 2026-09-14

### Added
- First feature
- Second feature

### Fixed
- A fix

## [0.0.2]

### Added
- Older feature
''';

    test('reads versions, dates, sections and items', () {
      final entries = parseChangelog(sample);
      expect(entries, hasLength(2));

      expect(entries[0].version, '0.0.3');
      expect(entries[0].date, DateTime(2026, 9, 14));
      expect(entries[0].sections, hasLength(2));
      expect(entries[0].sections[0].title, 'Added');
      expect(entries[0].sections[0].items, ['First feature', 'Second feature']);
      expect(entries[0].sections[1].title, 'Fixed');
      expect(entries[0].sections[1].items, ['A fix']);

      expect(entries[1].version, '0.0.2');
      expect(entries[1].date, isNull);
      expect(entries[1].sections.single.title, 'Added');
      expect(entries[1].sections.single.items, ['Older feature']);
    });

    test('a bullet before any section heading gets an untitled section', () {
      const text = '## [1.0.0]\n- bare bullet\n';
      final section = parseChangelog(text).single.sections.single;
      expect(section.title, isNull);
      expect(section.items, ['bare bullet']);
    });

    test('star bullets count too', () {
      const text = '## [1.0.0]\n* star bullet\n';
      expect(parseChangelog(text).single.sections.single.items, [
        'star bullet',
      ]);
    });

    test('entries stay in file order, newest first', () {
      const text = '## [2.0.0]\n- b\n\n## [1.0.0]\n- a\n';
      expect(parseChangelog(text).map((e) => e.version), ['2.0.0', '1.0.0']);
    });

    test('a bullet outside any version is dropped', () {
      const text = '- stray bullet\n## [1.0.0]\n- kept\n';
      final entry = parseChangelog(text).single;
      expect(entry.sections.single.items, ['kept']);
    });

    test('prose, links and tables are ignored', () {
      const text =
          '## [1.0.0] - 2026-01-01\n'
          '| Platform | File |\n'
          '|----------|------|\n'
          '| Android | apk |\n'
          '- only the bullet counts\n';
      final entry = parseChangelog(text).single;
      expect(entry.date, DateTime(2026));
      expect(entry.sections.single.items, ['only the bullet counts']);
    });

    test('an empty file has no entries', () {
      expect(parseChangelog(''), isEmpty);
      expect(parseChangelog('# Changelog\n\nProse only.\n'), isEmpty);
    });
  });

  group('isNewerVersion', () {
    test('compares major, minor and patch', () {
      expect(isNewerVersion('1.2.3', '1.2.2'), isTrue);
      expect(isNewerVersion('1.3.0', '1.2.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
      expect(isNewerVersion('1.2.2', '1.2.3'), isFalse);
    });

    test('equal versions are not newer', () {
      expect(isNewerVersion('0.0.3', '0.0.3'), isFalse);
    });

    test('a missing piece counts as zero', () {
      expect(isNewerVersion('0.2', '0.1.9'), isTrue);
      expect(isNewerVersion('0.2', '0.2.0'), isFalse);
      expect(isNewerVersion('0.2.1', '0.2'), isTrue);
    });

    test('a non-numeric piece counts as zero rather than crashing', () {
      expect(isNewerVersion('1.0.dev', '1.0.0'), isFalse);
      expect(isNewerVersion('1.1.0', '1.0.dev'), isTrue);
    });
  });
}
