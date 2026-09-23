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
}
