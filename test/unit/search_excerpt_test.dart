// The excerpt reader under the search results: folding, word starts, and a
// match cut out of a note read a slice at a time.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/search/search_excerpt.dart';
import 'package:path/path.dart' as p;

void main() {
  test('the folding table has one letter per character it covers', () {
    // U+00C0 to U+017F.
    expect(latinBase.length, 0x180 - 0xC0);
    expect(
      foldForSearch('ÀÉÎÕÜÇÑ àéîõüçñÿ ĄČĐĘĞĦĪĴĶŁŃŐŘŠŤŰŴŶŽ ſ'),
      'aeioucn aeioucny acdeghijklnorstuwyz s',
    );
    // Letters of their own keep themselves, lowercased, one for one.
    expect(foldForSearch('ÆŒßØ'), 'æœßo');
  });

  test('a word finder matches the start of a word only', () {
    final find = wordFinder(['ano']);
    expect(find(foldForSearch('piano, anothers')), (start: 7, end: 15));
    expect(find(foldForSearch('piano')), isNull);
  });

  test('a contains finder matches anywhere', () {
    final find = containsFinder('ANO');
    expect(find(foldForSearch('piano')), (start: 2, end: 5));
  });

  test('a note is read no further than its first match', () async {
    final dir = Directory.systemTemp.createTempSync('niman_excerpt_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'n.md'))
      ..writeAsStringSync('first line\n${'filler ' * 100000}');
    var asked = 0;
    ExcerptMatch? counting(String folded) {
      asked++;
      return containsFinder('first')(folded);
    }

    expect(
      await excerptInFile(file.path, counting),
      '<mark>first</mark> line filler filler filler filler filler…',
    );
    expect(asked, 1, reason: 'the first slice answered');
  });

  test('a note without the match answers null', () async {
    final dir = Directory.systemTemp.createTempSync('niman_excerpt_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'n.md'))..writeAsStringSync('nothing');
    expect(await excerptInFile(file.path, containsFinder('zzz')), isNull);
    expect(
      await excerptInFile(p.join(dir.path, 'gone.md'), containsFinder('a')),
      isNull,
    );
  });
}
