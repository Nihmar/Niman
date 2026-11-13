// A book's reading progress (#1275): counted once in characters and words,
// a line at a time, and looked up by the chapter and the book.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_progress.dart';

void main() {
  /// A line of [words] words.
  String words(int words) => List.filled(words, 'w').join(' ');

  group('the counts', () {
    test('characters leave out whitespace, a line at a time', () {
      final counts = EpubCounts.of('ab cd\n\nefg\n');
      expect(counts.lines, 4);
      expect(counts.chars, 7);
      expect(counts.charsAt(0), 0);
      expect(counts.charsAt(1), 4);
      expect(counts.charsAt(2), 4, reason: 'a blank line counts nothing');
      expect(counts.charsAt(0, 0.5), 2);
      expect(counts.charsAt(9), 7, reason: 'past the end is the end');
      expect(counts.charsAt(-1), 0);
    });

    test('words are runs between spaces', () {
      final counts = EpubCounts.of('one two  three\nfour\n');
      expect(counts.wordsAt(1), 3);
      expect(counts.wordsAt(counts.lines), 4);
    });

    test('a script without spaces is a word every two characters', () {
      expect(EpubCounts.of('日本語の本').wordsAt(1), 2.5);
      expect(EpubCounts.of('本 one').wordsAt(1), 1.5);
    });

    test('a character outside the basic plane is one character', () {
      expect(EpubCounts.of('a😀b').chars, 3);
    });
  });

  group('the progress', () {
    // Two chapters of two lines, 500 words each line.
    final text = '${List.filled(4, words(500)).join('\n')}\n';
    final progress = EpubProgress(EpubCounts.of(text), const [0, 2]);

    test('at the start of the book', () {
      final at = progress.at(0);
      expect(at.chapter, 1);
      expect(at.chapters, 2);
      expect(at.inChapter, 0);
      expect(at.inBook, 0);
      expect(at.chapterMinutes, 4, reason: '1000 words at 250 a minute');
      expect(at.bookMinutes, 8);
    });

    test('inside a line, by how far into it the view is', () {
      final at = progress.at(1, 0.5);
      expect(at.inChapter, 0.75);
      expect(at.inBook, 0.375);
      expect(at.chapterMinutes, 1);
      expect(at.bookMinutes, 5);
    });

    test("a chapter's first line opens it at none of it read", () {
      final at = progress.at(2);
      expect(at.chapter, 2);
      expect(at.inChapter, 0);
      expect(at.inBook, 0.5);
      expect(at.chapterMinutes, at.bookMinutes, reason: 'the last chapter');
    });

    test("past the last line is the book's end", () {
      final at = progress.at(99);
      expect(at.chapter, 2);
      expect(at.inChapter, 1);
      expect(at.inBook, 1);
      expect(at.chapterMinutes, 0);
      expect(at.bookMinutes, 0);
    });

    test("the ticks are the chapters' starts after the first", () {
      expect(progress.chapterTicks, [0.5]);
    });

    test('an empty chapter is read once it is reached', () {
      final progress = EpubProgress(EpubCounts.of('aaaa\n\nbbbb\n'), const [
        0,
        1,
        2,
      ]);
      final at = progress.at(1);
      expect(at.chapter, 2);
      expect(at.inChapter, 1);
      expect(at.inBook, 0.5);
    });

    test('a book of one chapter has one figure for both', () {
      final progress = EpubProgress(EpubCounts.of('aaaa\nbbbb\n'), const [0]);
      final at = progress.at(1);
      expect(at.inChapter, at.inBook);
      expect(at.chapters, 1);
      expect(progress.chapterTicks, isEmpty);
    });

    test('a book that names no chapter is one', () {
      final progress = EpubProgress(EpubCounts.of('aaaa\nbbbb\n'), const []);
      expect(progress.at(1).chapters, 1);
      expect(progress.at(1).inChapter, 0.5);
    });

    test('a book with no text has nothing to show', () {
      final progress = EpubProgress(EpubCounts.of('\n\n'), const [0]);
      expect(progress.isEmpty, isTrue);
      expect(progress.chapterTicks, isEmpty);
      expect(progress.at(0).inBook, 0);
    });
  });

  group('the views', () {
    test('a tap cycles chapter, book, time and back', () {
      expect(EpubProgressView.chapter.next, EpubProgressView.book);
      expect(EpubProgressView.book.next, EpubProgressView.time);
      expect(EpubProgressView.time.next, EpubProgressView.chapter);
    });

    test('a name read back is its view, anything else the chapter', () {
      expect(EpubProgressView.fromName('time'), EpubProgressView.time);
      expect(EpubProgressView.fromName('pages'), EpubProgressView.chapter);
      expect(EpubProgressView.fromName(null), EpubProgressView.chapter);
    });
  });
}
