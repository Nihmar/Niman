// T-M3-04 AC: the user text is never a raw FTS expression — quotes,
// hyphens, parentheses, wildcards and operators are literals; only the last
// token gets the prefix suffix; empty input = no query.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/search/query.dart';

void main() {
  group('buildFtsQuery', () {
    test('simple terms: every token quoted, last gets the prefix star', () {
      expect(buildFtsQuery('hello world'), '"hello" "world"*');
      expect(buildFtsQuery('a b c'), '"a" "b" "c"*');
    });

    test('empty and whitespace-only input is no query', () {
      expect(buildFtsQuery(''), isNull);
      expect(buildFtsQuery('   \t\n'), isNull);
    });

    test('internal quotes are doubled', () {
      expect(buildFtsQuery('say "hi"'), '"say" """hi"""*');
    });

    test('hyphens, parentheses, wildcards and operators are literal', () {
      expect(buildFtsQuery('well-known'), '"well-known"*');
      expect(buildFtsQuery('a (b)'), '"a" "(b)"*');
      expect(buildFtsQuery('AND OR NOT'), '"AND" "OR" "NOT"*');
      expect(buildFtsQuery('wild*card'), '"wild*card"*');
      expect(buildFtsQuery('a-b'), '"a-b"*');
    });

    test('quote-only tokens are dropped, not malformed phrases', () {
      expect(buildFtsQuery('"'), isNull);
      expect(buildFtsQuery('hello "" tail'), '"hello" "tail"*');
    });

    test('multiple spaces collapse', () {
      expect(buildFtsQuery('a   b'), '"a" "b"*');
    });
  });

  group('fieldQuery (T-M4-03)', () {
    test('key = value, with or without the spaces', () {
      expect(fieldQuery('status = draft'), (key: 'status', value: 'draft'));
      expect(fieldQuery('status=draft'), (key: 'status', value: 'draft'));
      expect(fieldQuery('  Status  =  Draft  '), (
        key: 'status',
        value: 'Draft',
      ));
    });

    test('an empty value asks for every note declaring the key', () {
      expect(fieldQuery('status ='), (key: 'status', value: ''));
    });

    test('a quoted value keeps its spaces', () {
      expect(fieldQuery('author = "Ada Lovelace"'), (
        key: 'author',
        value: 'Ada Lovelace',
      ));
      expect(fieldQuery("author = 'Ada Lovelace'"), (
        key: 'author',
        value: 'Ada Lovelace',
      ));
    });

    test('a dotted key (a nested field) parses', () {
      expect(fieldQuery('author.name = Ada'), (
        key: 'author.name',
        value: 'Ada',
      ));
    });

    test('anything that is not a key stays a text search', () {
      expect(fieldQuery('plain text'), isNull);
      expect(fieldQuery('= draft'), isNull); // no key
      expect(fieldQuery('x = y = z'), isNull); // two of them
      expect(fieldQuery('some words = draft'), isNull); // key has a space
      expect(fieldQuery('a+b = c'), isNull); // not key characters
      expect(fieldQuery(''), isNull);
    });
  });

  group('tagQuery', () {
    test('a single #tag is a tag query, normalized', () {
      expect(tagQuery('#Work'), 'work');
      expect(tagQuery('#Inbox/Work'), 'inbox/work');
      expect(tagQuery('  #Tag  '), 'tag');
    });

    test('mixed input or a plain word stays a word search', () {
      expect(tagQuery('#work extra'), isNull);
      expect(tagQuery('work'), isNull);
      expect(tagQuery(''), isNull);
      expect(tagQuery('#'), isNull); // nothing after the hash
    });
  });
}
