// What a voice reads of a book (#1276): its headings, paragraphs, list
// items and quotes, a sentence at a time; pictures, rules and code left
// out, a sentence too long for the engine cut at a space.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/read_aloud_text.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';

void main() {
  List<String> sentences(String text, {int maxLength = 4000}) => [
    for (final range in splitSentences(text, maxLength: maxLength))
      text.substring(range.start, range.end),
  ];

  group('the sentences', () {
    test('end at a stop followed by a space', () {
      expect(sentences('It begins. It goes on! Does it end? Yes…'), [
        'It begins.',
        'It goes on!',
        'Does it end?',
        'Yes…',
      ]);
    });

    test('a closing quote or bracket stays with its sentence', () {
      expect(sentences('He said: “Go.” She went. (Slowly.) Then.'), [
        'He said: “Go.”',
        'She went.',
        '(Slowly.)',
        'Then.',
      ]);
    });

    test('a stop before a lowercase word, or inside one, does not end it', () {
      expect(sentences('See e.g. this one. Pi is 3.14 here.'), [
        'See e.g. this one.',
        'Pi is 3.14 here.',
      ]);
    });

    test('a script without spaces ends at its full stop', () {
      expect(sentences('今日は晴れ。明日は雨！'), ['今日は晴れ。', '明日は雨！']);
    });

    test('the spaces around a sentence are not part of it', () {
      const text = '  One.   Two.  ';
      expect(splitSentences(text), [(start: 2, end: 6), (start: 9, end: 13)]);
    });

    test('one longer than the engine takes is cut at a space before it', () {
      final long = List.filled(30, 'word').join(' ');
      final parts = sentences(long, maxLength: 50);
      expect(parts.every((part) => part.length <= 50), isTrue);
      expect(parts.join(' '), long);
    });

    test('one with no space to cut at is cut at the limit', () {
      expect(sentences('a' * 120, maxLength: 50).map((s) => s.length), [
        50,
        50,
        20,
      ]);
    });
  });

  group('the paragraphs', () {
    List<ReadAloudParagraph> read(String markdown) {
      final buffer = SourceBuffer.fromText(markdown);
      final parser = ReadParser();
      return readAloudParagraphs([
        for (final block in DocumentScan.of(buffer).blocks)
          (line: block.startLine, block: parser.of(block, buffer)),
      ]);
    }

    test('headings and paragraphs, each marked where it is', () {
      final paragraphs = read('# Chapter one\n\nIt begins. It *goes* on.\n');
      expect(paragraphs.map((p) => p.line), [0, 2]);
      expect(paragraphs[1].sentences.map((s) => s.text), [
        'It begins.',
        'It goes on.',
      ]);
      expect(paragraphs[1].sentences[1].chars, (start: 11, end: 22));
    });

    test('pictures, rules and code are not read; a link is its text', () {
      final paragraphs = read(
        '![A map](epub-picture:0)\n\n---\n\n```\ncode\n```\n\n'
        'See [the map](epub-link:1) here.\n',
      );
      expect(paragraphs, hasLength(1));
      expect(paragraphs.single.sentences.single.text, 'See the map here.');
    });

    test('a list is read item by item, a quote whole, the block marked', () {
      final paragraphs = read('- One.\n- Two.\n\n> Quoted. Twice.\n');
      final texts = [
        for (final p in paragraphs) [for (final s in p.sentences) s.text],
      ];
      expect(texts, [
        ['One.'],
        ['Two.'],
        ['Quoted.', 'Twice.'],
      ]);
      expect(paragraphs.first.sentences.first.chars, isNull);
    });

    test('a footnote mark is not read', () {
      final paragraphs = read('A claim.[^1]\n\n[^1]: The source.\n');
      expect(paragraphs.first.sentences.single.text, 'A claim.');
    });
  });
}
