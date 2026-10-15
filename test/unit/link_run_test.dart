// #971: where each link of a line is, read from the tokens the styler gives —
// whose markers fuse across two links that touch.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/link_run.dart';

/// The line the [parts] spell and the tokens the styler cuts it in: the even
/// parts are markers, the odd ones text, and a marker is a part of its own
/// even when it touches the next one.
(String, List<Token>) _cut(TokenKind kind, List<String> parts) {
  final tokens = <Token>[];
  var at = 0;
  for (var i = 0; i < parts.length; i++) {
    final end = at + parts[i].length;
    if (end > at) tokens.add(Token(kind, at, end, marker: i.isEven));
    at = end;
  }
  return (parts.join(), tokens);
}

List<String> _runs((String, List<Token>) cut) => [
  for (final run in linkRuns(cut.$2, cut.$1))
    cut.$1.substring(run.start, run.end),
];

void main() {
  const w = TokenKind.wikilink;
  const l = TokenKind.link;

  test('a link is the tokens from its opening marker to its closing one', () {
    expect(_runs(_cut(w, ['[[', 'a', ']]'])), ['[[a]]']);
    expect(_runs(_cut(l, ['[', 'a', '](b.md)'])), ['[a](b.md)']);
  });

  test('the closing and opening markers of two wikilinks are cut apart', () {
    expect(_runs(_cut(w, ['![[', 'a|x', ']][[', 'b', ']][[', 'c', ']]'])), [
      '![[a|x]]',
      '[[b]]',
      '[[c]]',
    ]);
  });

  test('an inline link ends at the parenthesis that closes its href', () {
    expect(_runs(_cut(l, ['[', 'a', '](b(1).md "t)")[', 'c', '](<d e.md>)'])), [
      '[a](b(1).md "t)")',
      '[c](<d e.md>)',
    ]);
  });

  test('a reference link takes its label, a footnote only its bracket', () {
    expect(_runs(_cut(l, ['[', 'a', '][r][', 'b', '][c]'])), [
      '[a][r]',
      '[b][c]',
    ]);
    expect(_runs(_cut(l, ['[^', '1', '][^', '2', ']'])), ['[^1]', '[^2]']);
  });

  test('a link with no text is closed by its own marker', () {
    expect(_runs(_cut(l, ['[](a.md)[](b.md)'])), ['[](a.md)', '[](b.md)']);
  });

  test('a link of one token is a whole link, whatever touches it', () {
    expect(linkRuns(const [Token(w, 0, 5), Token(w, 5, 10)], '[[a]][[b]]'), [
      (kind: w, start: 0, end: 5),
      (kind: w, start: 5, end: 10),
    ]);
    expect(_runs(_cut(l, ['', 'https://a.b', '[', 'c', '](d)'])), [
      'https://a.b',
      '[c](d)',
    ]);
  });
}
