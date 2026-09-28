// The typed view of a note's frontmatter (#157): what the fields panel reads
// and what it writes back. The write is `edit.dart`'s line edit, so these hold
// the round trip the design asks for — a field shown, edited and read again is
// the same key and the same type, and every other line of the block is where it
// was.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/frontmatter/typed_fields.dart';

/// A note with the block under test at the top.
String _note(String block) => '---\n$block---\n\nBody text.\n';

void main() {
  group('frontmatterFieldsIn', () {
    test('reads each type YAML gives a value', () {
      final parsed = frontmatterFieldsIn(
        'title: Enciclopedia\n'
        'year: 1998\n'
        'ratio: 1.5\n'
        'date: 2026-09-01\n'
        'pinned: true\n'
        'tags: [Celestia, worldbuilding]\n',
      );
      expect(parsed.error, isNull);
      final byKey = {for (final field in parsed.fields) field.key: field};
      expect(byKey['title']!.type, FrontmatterFieldType.text);
      expect(byKey['title']!.value, 'Enciclopedia');
      expect(byKey['year']!.type, FrontmatterFieldType.number);
      expect(byKey['year']!.value, '1998');
      expect(byKey['ratio']!.type, FrontmatterFieldType.number);
      expect(byKey['ratio']!.value, '1.5');
      expect(byKey['date']!.type, FrontmatterFieldType.date);
      expect(byKey['date']!.value, '2026-09-01');
      expect(byKey['pinned']!.type, FrontmatterFieldType.boolean);
      expect(byKey['tags']!.type, FrontmatterFieldType.list);
      expect(byKey['tags']!.values, ['Celestia', 'worldbuilding']);
    });

    test('a quoted date under date: is a date, under any other key text', () {
      final parsed = frontmatterFieldsIn(
        'date: "2026-09-01"\nreleased: "2026-09-01"\n',
      );
      final byKey = {for (final field in parsed.fields) field.key: field};
      expect(byKey['date']!.type, FrontmatterFieldType.date);
      expect(byKey['released']!.type, FrontmatterFieldType.text);
    });

    test('a block the parser refuses yields its message and no fields', () {
      // The parser is the arbiter: what it will not read, no field row shows.
      final parsed = frontmatterFieldsIn('title: [unclosed\n');
      expect(parsed.error, isNotNull);
      expect(parsed.fields, isEmpty);
    });

    test('a nested mapping has no field row and is left to the raw source', () {
      final parsed = frontmatterFieldsIn(
        'title: A note\nauthor:\n  name: Ada\n',
      );
      expect(parsed.error, isNull);
      expect(parsed.fields.map((field) => field.key), ['title']);
    });

    test('an empty block has no fields', () {
      expect(frontmatterFieldsIn('').fields, isEmpty);
      expect(frontmatterFieldsIn('\n').fields, isEmpty);
    });
  });

  group('frontmatterFieldYaml', () {
    test('writes the type the field has', () {
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.text, ['A note']),
        'A note',
      );
      expect(frontmatterFieldYaml(FrontmatterFieldType.number, ['42']), '42');
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.date, ['2026-09-01']),
        '2026-09-01',
      );
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.boolean, ['true']),
        'true',
      );
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.boolean, ['false']),
        'false',
      );
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.list, ['a', 'b']),
        '[a, b]',
      );
    });

    test('quotes text that YAML would read as something else', () {
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.text, ['true']),
        '"true"',
      );
      expect(frontmatterFieldYaml(FrontmatterFieldType.text, ['42']), '"42"');
      expect(
        frontmatterFieldYaml(FrontmatterFieldType.text, ['a: b']),
        '"a: b"',
      );
      expect(frontmatterFieldYaml(FrontmatterFieldType.text, ['']), '""');
    });
  });

  group('a field edit through the parser', () {
    test('writes YAML the parser reads back identically', () {
      final edited = setFrontmatterKey(
        _note('title: Old\n'),
        'title',
        frontmatterFieldYaml(FrontmatterFieldType.text, ['Nuova']),
      );
      final parsed = parseFrontmatter(edited)!;
      expect(parsed.title, 'Nuova');
      expect(parsed.fields['title'], ['Nuova']);
    });

    test('a list stays a list and a date stays a date', () {
      final withList = setFrontmatterKey(
        _note('title: A note\n'),
        'tags',
        frontmatterFieldYaml(FrontmatterFieldType.list, [
          'Celestia',
          'worldbuilding',
        ]),
      );
      final withDate = setFrontmatterKey(
        withList,
        'date',
        frontmatterFieldYaml(FrontmatterFieldType.date, ['2026-10-02']),
      );

      // The file says a YAML list and a bare date...
      expect(withDate, contains('tags: [Celestia, worldbuilding]\n'));
      expect(withDate, contains('date: 2026-10-02\n'));
      // ...and the parser reads them back as the types the panel drew.
      final fields = frontmatterFieldsIn(frontmatterBlock(withDate)!.text)
          .fields;
      final byKey = {for (final field in fields) field.key: field};
      expect(byKey['tags']!.type, FrontmatterFieldType.list);
      expect(byKey['tags']!.values, ['Celestia', 'worldbuilding']);
      expect(byKey['date']!.type, FrontmatterFieldType.date);
      expect(parseFrontmatter(withDate)!.date, DateTime(2026, 10, 2));
    });

    test('leaves every other line of the block exactly where it was', () {
      // The hard constraint: a UI edit rewrites the named key's line and
      // nothing else — key order, comments and quoting included.
      const block =
          '# the title, hand-quoted\n'
          'title: "Old"  # keep me\n'
          'tags: [a, b]\n'
          'custom: 3\n';
      final edited = setFrontmatterKey(
        _note(block),
        'title',
        frontmatterFieldYaml(FrontmatterFieldType.text, ['New']),
      );
      expect(
        edited,
        '---\n'
        '# the title, hand-quoted\n'
        'title: New\n'
        'tags: [a, b]\n'
        'custom: 3\n'
        '---\n'
        '\n'
        'Body text.\n',
      );
    });

    test('removing the last key takes the fences with it', () {
      final edited = removeFrontmatterKey(_note('title: Only\n'), 'title');
      expect(edited, 'Body text.\n');
    });
  });
}
