/// Where a book's text goes when it is converted to notes (#1138): which
/// notes, in which folders, holding which lines.
///
/// The book is the reader's text — its chapters joined in reading order, a
/// rule between two — and its table of contents says where it breaks:
///
/// - **An entry is a note**, holding the book's lines from where it opens to
///   where the next one does. Its title names it, after a number that keeps
///   the reading order in any tree sorted by name: `03 The Storm.md`.
/// - **An entry with entries under it is a folder** — a part and its
///   chapters, `02 Part Two/01 Arrival.md` — and the text the part opens on
///   before its first chapter (its title page, an epigraph) is the folder's
///   own first note, `00 Part Two.md`. As deep as the contents go, down to
///   the split depth below.
/// - **The text before the first entry** — a title page, a dedication — is
///   a note of its own at the top, `00 <opening>.md`.
/// - **The split depth.** A contents entry deeper than it stays a heading
///   inside its chapter's note: a section is not a note. It is the deepest
///   level whose entries open a file of the book (a book is usually a file a
///   chapter), and one deeper while the notes would still average more than
///   [_splitAbove] — a part kept whole in one file, its chapters anchors in
///   it — never past the third level.
///
/// A book with no usable contents gets a note a chapter file, each named
/// by its first heading. The plan is lines and names alone; what the notes
/// say is `epub_convert_render.dart`'s.
library;

import 'dart:math';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:path/path.dart' as p;

/// What a note averages before the plan splits one level deeper.
const int _splitAbove = 40 * 1024;

/// The deepest level the plan splits at (0 is the top).
const int _deepestSplit = 2;

/// One note of a converted book: its path in the book's folder
/// (`/`-separated), its title, and the lines of the book it holds.
typedef EpubPlannedNote = ({String path, String title, int start, int end});

/// One entry of the book's contents as `index.md` lists it.
typedef EpubPlannedEntry = ({String title, int depth, int line});

/// The words a conversion writes in the user's language, handed in: the
/// isolate that writes has no locale.
typedef EpubConvertWords = ({
  /// A chapter no contents entry names; `{n}` is its number.
  String chapter,

  /// The text before the first contents entry.
  String opening,

  /// `index.md`'s heading over the contents.
  String contents,
});

/// Where a book's text goes.
final class EpubPlan {
  /// Plans [book]: a note a contents entry, or [oneNote] for one note of it
  /// all, named [title].
  factory of(
    EpubBook book, {
    required String title,
    required EpubConvertWords words,
    bool oneNote = false,
  }) {
    final text = _joined(book);
    if (oneNote) {
      final name = '${sanitizeName(title, fallback: defaultNoteName)}.md';
      return EpubPlan._(
        book: book,
        title: title,
        lines: text.lines,
        notes: [(path: name, title: title, start: 0, end: text.lines.length)],
        contents: [
          for (final entry in book.contents)
            if (text.lineOf(entry.file, entry.fragment) case final line?)
              (title: entry.title, depth: entry.depth, line: line),
        ],
        lineOf: text.lineOf,
      );
    }
    final entries = _entries(book, text, words);
    final split = _splitDepth(entries, text);
    final notes = _place(
      [
        for (final entry in entries)
          if (entry.depth <= split) entry,
      ],
      text,
      words,
    );
    return EpubPlan._(
      book: book,
      title: title,
      lines: text.lines,
      notes: notes,
      contents: entries,
      lineOf: text.lineOf,
    );
  }

  new _({
    required this.book,
    required this.title,
    required this.lines,
    required this.notes,
    required this.contents,
    required this._lineOf,
  });

  /// The book planned.
  final EpubBook book;

  /// What the book is called.
  final String title;

  /// The book's text, a line an item: the reader's.
  final List<String> lines;

  /// The notes, in reading order. A note whose lines are blank is not
  /// written; [noteAt] sends what pointed at it to the next one.
  final List<EpubPlannedNote> notes;

  /// The contents, as `index.md` lists them.
  final List<EpubPlannedEntry> contents;

  final int? Function(String file, String fragment) _lineOf;

  /// The line of the book [target] opens on, or null when it is not in it.
  int? lineOfTarget(EpubTarget target) => _lineOf(target.file, target.fragment);

  /// The note that holds [line], among [written]: the last one opening at or
  /// above it, or — when that one was not written — the next one that was.
  EpubPlannedNote? noteAt(int line, List<EpubPlannedNote> written) {
    if (written.isEmpty) return null;
    var found = written.first;
    for (final note in written) {
      if (note.start > line) break;
      found = note;
    }
    if (line < found.end || identical(found, written.last)) return found;
    return written.firstWhere(
      (note) => note.start >= line,
      orElse: () => written.last,
    );
  }
}

/// The book's text as the reader joins it, and where each file opens in it.
final class _Joined {
  new(this.lines, this._starts, this._anchors, this._spine);

  final List<String> lines;
  final Map<String, int> _starts;
  final Map<String, Map<String, int>> _anchors;
  final List<String> _spine;

  /// Where [file] opens — or, for a file with no text (a part's title page),
  /// the next file of the spine with some — plus [fragment]'s line in it.
  int? lineOf(String file, String fragment) {
    final start = _starts[file];
    if (start != null) {
      if (fragment.isEmpty) return start;
      return _anchors[file]?[fragment] ?? start;
    }
    final at = _spine.indexOf(file);
    if (at < 0) return null;
    for (final next in _spine.skip(at + 1)) {
      if (_starts[next] case final start?) return start;
    }
    return null;
  }

  /// Whether [line] is where a file of the book opens.
  bool opensFile(int line) => _starts.containsValue(line);

  int get bytes => lines.fold(0, (sum, line) => sum + line.length + 1);
}

_Joined _joined(EpubBook book) {
  final starts = <String, int>{};
  final anchors = <String, Map<String, int>>{};
  final lines = <String>[];
  for (final chapter in book.chapters) {
    if (lines.isNotEmpty) {
      // As the reader joins them: a rule, a blank line on each side.
      lines
        ..add('')
        ..add('---')
        ..add('');
    }
    final start = lines.length;
    starts[chapter.file] = start;
    anchors[chapter.file] = {
      for (final entry in chapter.anchors.entries)
        entry.key: start + entry.value,
    };
    lines.addAll(chapter.markdown.split('\n'));
  }
  return _Joined(lines, starts, anchors, book.spine);
}

/// The contents entries that open somewhere in the text, their depths made
/// a tree's (no entry more than one level under the one before it); or a
/// chapter file an entry when the book has no usable contents.
List<EpubPlannedEntry> _entries(
  EpubBook book,
  _Joined text,
  EpubConvertWords words,
) {
  final out = <EpubPlannedEntry>[];
  var previous = -1;
  for (final entry in book.contents) {
    final line = text.lineOf(entry.file, entry.fragment);
    if (line == null) continue;
    final depth = min(entry.depth, previous + 1);
    out.add((title: entry.title, depth: depth, line: line));
    previous = depth;
  }
  if (out.isNotEmpty) return out;
  return [
    for (final (index, chapter) in book.chapters.indexed)
      (
        title:
            _firstHeading(chapter.markdown) ??
            words.chapter.replaceAll('{n}', '${index + 1}'),
        depth: 0,
        line: text.lineOf(chapter.file, '')!,
      ),
  ];
}

String? _firstHeading(String markdown) {
  for (final line in markdown.split('\n')) {
    final match = _heading.firstMatch(line);
    if (match != null) return match.group(1)!.trim();
  }
  return null;
}

final RegExp _heading = RegExp(r'^#{1,6}\s+(.+?)\s*#*\s*$');

/// The deepest level the book splits at: see the library's doc.
int _splitDepth(List<EpubPlannedEntry> entries, _Joined text) {
  if (entries.isEmpty) return 0;
  var depth = 0;
  for (final entry in entries) {
    if (text.opensFile(entry.line)) depth = max(depth, entry.depth);
  }
  depth = min(depth, _deepestSplit);
  final deepest = entries.map((entry) => entry.depth).reduce(max);
  while (depth < min(deepest, _deepestSplit)) {
    final notes = entries.where((entry) => entry.depth <= depth).length + 1;
    if (text.bytes / notes <= _splitAbove) break;
    depth++;
  }
  return depth;
}

/// The notes [split] makes of [text], named and numbered in their folders.
List<EpubPlannedNote> _place(
  List<EpubPlannedEntry> split,
  _Joined text,
  EpubConvertWords words,
) {
  // Stable by line: the contents' own order breaks a tie.
  final ordered = [...split.indexed]
    ..sort((a, b) {
      final byLine = a.$2.line.compareTo(b.$2.line);
      return byLine != 0 ? byLine : a.$1.compareTo(b.$1);
    });
  final entries = [for (final (_, entry) in ordered) entry];
  // The tree: each entry's children, by index; -1 is the book's folder.
  final children = <int, List<int>>{-1: []};
  final parents = <int>[];
  final stack = <int>[];
  for (var i = 0; i < entries.length; i++) {
    while (stack.isNotEmpty && entries[stack.last].depth >= entries[i].depth) {
      stack.removeLast();
    }
    final parent = stack.isEmpty ? -1 : stack.last;
    parents.add(parent);
    (children[parent] ??= []).add(i);
    children[i] = [];
    stack.add(i);
  }
  int endOf(int i) =>
      i + 1 < entries.length ? entries[i + 1].line : text.lines.length;

  final notes = <EpubPlannedNote>[];
  final folders = <int, String>{-1: ''};
  String join(String folder, String name) =>
      folder.isEmpty ? name : '$folder/$name';
  String numbered(int n, int of, String title) {
    final width = max(2, '$of'.length);
    return '${'$n'.padLeft(width, '0')} '
        '${sanitizeName(title, fallback: defaultNoteName)}';
  }

  final first = entries.isEmpty ? text.lines.length : entries.first.line;
  if (first > 0) {
    final count = children[-1]!.length;
    notes.add((
      path: '${numbered(0, count, words.opening)}.md',
      title: words.opening,
      start: 0,
      end: first,
    ));
  }
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final parent = parents[i];
    final siblings = children[parent]!;
    final name = numbered(
      siblings.indexOf(i) + 1,
      siblings.length,
      entry.title,
    );
    final folder = folders[parent]!;
    if (children[i]!.isEmpty) {
      notes.add((
        path: '${join(folder, name)}.md',
        title: entry.title,
        start: entry.line,
        end: endOf(i),
      ));
      continue;
    }
    final own = join(folder, name);
    folders[i] = own;
    notes.add((
      path: '${join(own, numbered(0, children[i]!.length, entry.title))}.md',
      title: entry.title,
      start: entry.line,
      end: endOf(i),
    ));
  }
  return notes;
}

/// The folder [path] (a note's, in the book's folder) sits in, `/`-separated;
/// '' at the top.
String noteFolderOf(String path) {
  final folder = p.posix.dirname(path);
  return folder == '.' ? '' : folder;
}
