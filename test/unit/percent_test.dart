// A link's escapes decoded, the text around them kept as written: a
// Markdown href as Obsidian writes it, a place in a book (#282).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/percent.dart';

void main() {
  test('escapes are decoded, as UTF-8', () {
    expect(percentDecoded('My%20Note.md'), 'My Note.md');
    expect(percentDecoded('Citt%C3%A0.md'), 'Città.md');
    expect(percentDecoded('a%2fb'), 'a/b');
  });

  test('the text around them is kept, whatever it is', () {
    expect(percentDecoded('città%20nota.md'), 'città nota.md');
    expect(percentDecoded('日本%20語'), '日本 語');
    expect(percentDecoded('no escapes'), 'no escapes');
  });

  test('a % that begins no escape is kept as written', () {
    for (final s in ['100%.md', '%', '%2', '%zz', '%-1', 'a%+1b']) {
      expect(percentDecoded(s), s, reason: s);
    }
  });

  test('bytes that are not UTF-8 read as the replacement character', () {
    expect(percentDecoded('a%FFb'), 'a\u{FFFD}b');
  });
}
