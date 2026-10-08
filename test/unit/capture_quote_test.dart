// A quote shared from a web page (#531), as a note holds it: a block
// quote whose words stay words, and the page it came from under it.
//
// The expected text runs on across its pieces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_quote.dart';

final Uri _url = Uri.parse('https://example.com/blog/offline-first');

void main() {
  test('a quote is a block quote, the page under it', () {
    expect(
      quoteMarkdown(
        'Conflicts should read as a choice, not an error.',
        _url,
        title: 'Offline-first, ten years later',
      ),
      '> Conflicts should read as a choice, not an error.\n'
      '> — [Offline-first, ten years later]'
      '(<https://example.com/blog/offline-first>)\n',
    );
  });

  test('its words stay words, and its paragraphs stay apart', () {
    expect(
      quoteMarkdown('# not a heading\n\n- not a list *nor* #a-tag', _url),
      r'> \# not a heading'
      '\n>\n'
      r'> \- not a list \*nor\* \#a-tag'
      '\n> — [example.com](<https://example.com/blog/offline-first>)\n',
    );
  });

  test('a new note of a quote starts with the frontmatter', () {
    final note = quoteNote(
      'A choice, not an error.',
      _url,
      captured: DateTime(2026, 10, 8),
      title: 'Offline-first',
      tags: ['web'],
    );
    expect(
      note,
      '---\n'
      'source: https://example.com/blog/offline-first\n'
      'captured: 2026-10-08\n'
      'tags: [web]\n'
      '---\n'
      '\n'
      '> A choice, not an error.\n'
      '> — [Offline-first](<https://example.com/blog/offline-first>)\n',
    );
  });
}
