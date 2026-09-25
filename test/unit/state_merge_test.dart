import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/state_merge.dart';

String json(Map<String, Object?> m) => jsonEncode(m);

Map<String, Object?> parsed(String? text) =>
    (jsonDecode(text!) as Map).cast<String, Object?>();

void main() {
  group('settings, key by key', () {
    test('keys changed on different sides both land', () {
      final merged = mergeSettingsJson(
        base: json({'trashEnabled': true, 'historyVersions': 10}),
        local: json({'trashEnabled': false, 'historyVersions': 10}),
        remote: json({'trashEnabled': true, 'historyVersions': 3}),
        localNewer: false,
      );
      expect(parsed(merged), {'trashEnabled': false, 'historyVersions': 3});
    });

    test('a key both changed takes the newer file', () {
      String? merge({required bool localNewer}) => mergeSettingsJson(
        base: json({'historyVersions': 10}),
        local: json({'historyVersions': 5}),
        remote: json({'historyVersions': 20}),
        localNewer: localNewer,
      );
      expect(parsed(merge(localNewer: true)), {'historyVersions': 5});
      expect(parsed(merge(localNewer: false)), {'historyVersions': 20});
    });

    test('a key removed on one side and untouched on the other goes', () {
      final merged = mergeSettingsJson(
        base: json({'quickNotePath': 'Q.md', 'linkType': 'wikilink'}),
        local: json({'linkType': 'wikilink'}),
        remote: json({'quickNotePath': 'Q.md', 'linkType': 'markdown'}),
        localNewer: false,
      );
      expect(parsed(merged), {'linkType': 'markdown'});
    });

    test('without a base, keys either side has are kept', () {
      final merged = mergeSettingsJson(
        base: null,
        local: json({'a': 1, 'shared': 'mine'}),
        remote: json({'b': 2, 'shared': 'theirs'}),
        localNewer: true,
      );
      expect(parsed(merged), {'a': 1, 'shared': 'mine', 'b': 2});
    });

    test('lists compare by value', () {
      final merged = mergeSettingsJson(
        base: json({
          'spellDictionaries': ['it'],
        }),
        local: json({
          'spellDictionaries': ['it'],
        }),
        remote: json({
          'spellDictionaries': ['it', 'en'],
        }),
        localNewer: true,
      );
      expect(parsed(merged), {
        'spellDictionaries': ['it', 'en'],
      });
    });

    test('a side that does not parse leaves the choice to the caller', () {
      expect(
        mergeSettingsJson(
          base: null,
          local: '{not json',
          remote: json({'a': 1}),
          localNewer: true,
        ),
        isNull,
      );
      expect(
        mergeSettingsJson(
          base: null,
          local: '[1, 2]',
          remote: json({'a': 1}),
          localNewer: true,
        ),
        isNull,
      );
    });

    test('the text is the settings file format', () {
      expect(
        mergeSettingsJson(
          base: null,
          local: json({'a': 1}),
          remote: json({'a': 1}),
          localNewer: true,
        ),
        '{\n  "a": 1\n}\n',
      );
    });
  });

  group('counters, highest wins', () {
    test('every counter is the highest either side reached', () {
      final merged = mergeCountersJson(
        local: json({'meeting': 4, 'quest': 1}),
        remote: json({'meeting': 6, 'idea': 2}),
      );
      expect(parsed(merged), {'meeting': 6, 'quest': 1, 'idea': 2});
    });

    test('a side that does not parse gives null', () {
      expect(mergeCountersJson(local: 'x', remote: json({'a': 1})), isNull);
    });
  });

  group('personal dictionary, word by word', () {
    test('words added on either side are in, removed ones are out', () {
      expect(
        mergeWordList(
          base: 'Niman\nKatex\n',
          local: 'Niman\nKatex\nWebDAV\n',
          remote: 'Niman\nNextcloud\n',
        ),
        'Niman\nWebDAV\nNextcloud\n',
      );
    });

    test('without a base it is the union', () {
      expect(
        mergeWordList(base: null, local: 'uno\n', remote: 'due\nuno\n'),
        'uno\ndue\n',
      );
    });

    test('case does not make a second word; the local form stays', () {
      expect(
        mergeWordList(base: null, local: 'WebDAV\n', remote: 'webdav\n'),
        'WebDAV\n',
      );
    });

    test('no words is an empty file', () {
      expect(mergeWordList(base: 'a\n', local: '', remote: 'a\n'), '');
    });
  });

  group('reading positions, book by book (#281)', () {
    Map<String, Object?> at(int page, String when) => {
      'page': page,
      'fraction': 0.0,
      'at': when,
    };

    test('books read on different sides both land', () {
      final merged = mergeReadingJson(
        base: json({}),
        local: json({'a.pdf': at(3, '2026-09-25T10:00:00Z')}),
        remote: json({'b.pdf': at(7, '2026-09-25T09:00:00Z')}),
      );
      expect(parsed(merged), {
        'a.pdf': at(3, '2026-09-25T10:00:00Z'),
        'b.pdf': at(7, '2026-09-25T09:00:00Z'),
      });
    });

    test('a book read on both sides keeps the later reading', () {
      for (final (local, remote, kept) in [
        ('2026-09-25T10:00:00Z', '2026-09-25T11:00:00Z', 9),
        ('2026-09-25T12:00:00Z', '2026-09-25T11:00:00Z', 3),
      ]) {
        final merged = mergeReadingJson(
          base: json({'a.pdf': at(1, '2026-09-24T10:00:00Z')}),
          local: json({'a.pdf': at(3, local)}),
          remote: json({'a.pdf': at(9, remote)}),
        );
        expect((parsed(merged)['a.pdf']! as Map)['page'], kept);
      }
    });

    test('a book one side carried to a new name is not brought back', () {
      final entry = at(3, '2026-09-25T10:00:00Z');
      final merged = mergeReadingJson(
        base: json({'old.pdf': entry}),
        local: json({'new.pdf': entry}),
        remote: json({'old.pdf': entry}),
      );
      expect(parsed(merged), {'new.pdf': entry});
    });

    test('a side that is not JSON cannot be merged', () {
      expect(
        mergeReadingJson(base: null, local: '{', remote: json({})),
        isNull,
      );
    });
  });
}
