// The plan a book's text is split by (#1138, #1294), over lines and contents
// entries alone: the notes an entry makes, their numbers, the parts that are
// folders, the text before the first entry, the names an entry's title is
// given.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/book/book_render.dart';

const BookWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Front matter',
  contents: 'Contents',
);

List<String> _lines(int count) => [for (var i = 0; i < count; i++) 'line $i'];

void main() {
  group('a note an entry', () {
    test('numbered in reading order, each to where the next opens', () {
      final plan = BookPlan.split(
        title: 'Dune',
        lines: _lines(30),
        entries: const [
          (title: 'Arrival', depth: 0, line: 0),
          (title: 'The Storm', depth: 0, line: 10),
          (title: 'Home', depth: 0, line: 20),
        ],
        words: _words,
      );
      expect(plan.notes, [
        (path: '01 Arrival.md', title: 'Arrival', start: 0, end: 10),
        (path: '02 The Storm.md', title: 'The Storm', start: 10, end: 20),
        (path: '03 Home.md', title: 'Home', start: 20, end: 30),
      ]);
    });

    test('the text before the first entry is a note of its own', () {
      final plan = BookPlan.split(
        title: 'Dune',
        lines: _lines(30),
        entries: const [(title: 'One', depth: 0, line: 5)],
        words: _words,
      );
      expect(plan.notes.first, (
        path: '00 Front matter.md',
        title: 'Front matter',
        start: 0,
        end: 5,
      ));
      expect(plan.notes.last.path, '01 One.md');
    });

    test('a part with entries under it is a folder', () {
      final plan = BookPlan.split(
        title: 'Dune',
        lines: _lines(30),
        entries: const [
          (title: 'Part Two', depth: 0, line: 0),
          (title: 'Arrival', depth: 1, line: 10),
          (title: 'Home', depth: 1, line: 20),
        ],
        words: _words,
      );
      expect(plan.notes.map((note) => note.path), [
        '01 Part Two/00 Part Two.md',
        '01 Part Two/01 Arrival.md',
        '01 Part Two/02 Home.md',
      ]);
    });

    test('is named by what nameOf makes of its title', () {
      final plan = BookPlan.split(
        title: 'Dune',
        lines: _lines(20),
        entries: const [
          (title: 'Chapter 1: The Storm', depth: 0, line: 0),
          (title: 'Chapter 2', depth: 0, line: 10),
        ],
        words: _words,
        nameOf: (title) => title.split(': ').last,
      );
      expect(plan.notes.map((note) => note.path), [
        '01 The Storm.md',
        '02 Chapter 2.md',
      ]);
      // The title the note is shown by stays whole.
      expect(plan.notes.first.title, 'Chapter 1: The Storm');
    });
  });

  test('one note holds every line, named after the book', () {
    final plan = BookPlan.single(title: 'Dune', lines: _lines(12));
    expect(plan.notes, [(path: 'Dune.md', title: 'Dune', start: 0, end: 12)]);
  });

  test('bookEntries makes the depths a tree', () {
    expect(
      bookEntries(const [
        (title: 'A', depth: 2, line: 0),
        (title: 'B', depth: 3, line: 1),
        (title: 'C', depth: 0, line: 2),
      ]).map((entry) => entry.depth),
      [0, 1, 0],
    );
  });

  group('a link into the book', () {
    final plan = BookPlan.split(
      title: 'Dune',
      lines: const [
        '# One',
        '',
        'text',
        '',
        '## Section',
        '',
        '# Two',
        '',
        'more',
      ],
      entries: const [
        (title: 'One', depth: 0, line: 0),
        (title: 'Two', depth: 0, line: 6),
      ],
      words: _words,
    );

    test('lands in the note that holds it, at the heading it is on', () {
      expect(
        bookLinkTo(plan, plan.notes.last, plan.notes, 4),
        '01%20One.md#Section',
      );
    });

    test('is the heading alone within its own note', () {
      expect(bookLinkTo(plan, plan.notes.first, plan.notes, 4), '#Section');
    });

    test('has no heading where it lands on the first line', () {
      expect(bookLinkTo(plan, plan.notes.first, plan.notes, 6), '02%20Two.md');
    });
  });

  test('the contents are links, indented by depth', () {
    final plan = BookPlan.split(
      title: 'Dune',
      lines: _lines(30),
      entries: const [
        (title: 'Part One', depth: 0, line: 0),
        (title: 'Arrival', depth: 1, line: 10),
      ],
      words: _words,
    );
    expect(
      bookContents(plan, plan.notes),
      '- [Part One](01%20Part%20One/00%20Part%20One.md)\n'
      '  - [Arrival](01%20Part%20One/01%20Arrival.md)\n',
    );
  });
}
