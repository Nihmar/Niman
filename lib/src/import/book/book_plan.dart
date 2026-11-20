/// Where a book's text goes when it is converted to notes (#1138, #1294):
/// which notes, in which folders, holding which lines.
///
/// The plan knows a book as **lines and contents entries** — each entry a
/// title, a depth and the line it opens on — and nothing of where they came
/// from: an EPUB's chapters (`epub_convert_plan.dart`) and an HTML page that
/// is a book (`html_book_*.dart`) are planned alike.
///
/// The book is the reader's text — its chapters joined in reading order — and
/// its contents say where it breaks:
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
/// The plan is lines and names alone; what the notes say is the caller's.
library;

import 'dart:math';

import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

/// What a note averages before the plan splits one level deeper.
const int _splitAbove = 40 * 1024;

/// The deepest level the plan splits at (0 is the top).
const int _deepestSplit = 2;

/// One note of a converted book: its path in the book's folder
/// (`/`-separated), its title, and the lines of the book it holds.
typedef BookPlannedNote = ({String path, String title, int start, int end});

/// One entry of the book's contents as `index.md` lists it.
typedef BookPlannedEntry = ({String title, int depth, int line});

/// The words a conversion writes in the user's language, handed in: the
/// isolate that writes has no locale.
typedef BookWords = ({
  /// A chapter no contents entry names; `{n}` is its number.
  String chapter,

  /// The text before the first contents entry.
  String opening,

  /// `index.md`'s heading over the contents.
  String contents,
});

/// Where a book's text goes.
base class BookPlan {
  /// A plan of [notes] and [contents] over [lines].
  const new({
    required this.title,
    required this.lines,
    required this.notes,
    required this.contents,
  });

  /// Plans one note of the whole text, named [title]; [contents] is what
  /// `index.md` would list.
  factory single({
    required String title,
    required List<String> lines,
    List<BookPlannedEntry> contents = const [],
  }) {
    final name = '${sanitizeName(title, fallback: defaultNoteName)}.md';
    return BookPlan(
      title: title,
      lines: lines,
      notes: [(path: name, title: title, start: 0, end: lines.length)],
      contents: contents,
    );
  }

  /// Plans a note an entry of [entries] (their depths a tree's: see
  /// [bookEntries]). [opensFile] says whether a line is where a file of the
  /// book opens, for the split depth; [nameOf] turns an entry's title into
  /// the words its file is named by (its title when null).
  factory split({
    required String title,
    required List<String> lines,
    required List<BookPlannedEntry> entries,
    required BookWords words,
    bool Function(int line)? opensFile,
    String Function(String title)? nameOf,
  }) => BookPlan(
    title: title,
    lines: lines,
    notes: planNotes(
      lines: lines,
      entries: entries,
      words: words,
      opensFile: opensFile ?? (_) => true,
      nameOf: nameOf,
    ),
    contents: entries,
  );

  /// What the book is called.
  final String title;

  /// The book's text, a line an item: the reader's.
  final List<String> lines;

  /// The notes, in reading order. A note whose lines are blank is not
  /// written; [noteAt] sends what pointed at it to the next one.
  final List<BookPlannedNote> notes;

  /// The contents, as `index.md` lists them.
  final List<BookPlannedEntry> contents;

  /// The note that holds [line], among [written]: the last one opening at or
  /// above it, or — when that one was not written — the next one that was.
  ///
  /// [written] is in reading order, so its notes open at ascending lines:
  /// found by bisection, as a link and a contents entry each ask it.
  BookPlannedNote? noteAt(int line, List<BookPlannedNote> written) {
    if (written.isEmpty) return null;
    // The first note opening past `line`; the one before it is the last at
    // or above it.
    final past = _firstOpening(written, (note) => note.start > line);
    final at = past == 0 ? 0 : past - 1;
    final found = written[at];
    if (line < found.end || at == written.length - 1) return found;
    final next = _firstOpening(written, (note) => note.start >= line);
    return written[next == written.length ? written.length - 1 : next];
  }
}

/// The index of the first of [notes] that [satisfies] - [notes].length when
/// none does - given that once a note does, the ones after it do.
int _firstOpening(
  List<BookPlannedNote> notes,
  bool Function(BookPlannedNote note) satisfies,
) {
  var low = 0;
  var high = notes.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (satisfies(notes[middle])) {
      high = middle;
    } else {
      low = middle + 1;
    }
  }
  return low;
}

/// [raw] with its depths made a tree's: no entry more than one level under
/// the one before it.
List<BookPlannedEntry> bookEntries(Iterable<BookPlannedEntry> raw) {
  final out = <BookPlannedEntry>[];
  var previous = -1;
  for (final entry in raw) {
    final depth = min(entry.depth, previous + 1);
    out.add((title: entry.title, depth: depth, line: entry.line));
    previous = depth;
  }
  return out;
}

/// The notes [entries] make of [lines], split as the library's doc says,
/// named and numbered in their folders.
List<BookPlannedNote> planNotes({
  required List<String> lines,
  required List<BookPlannedEntry> entries,
  required BookWords words,
  required bool Function(int line) opensFile,
  String Function(String title)? nameOf,
}) {
  final split = _splitDepth(entries, lines, opensFile);
  return _place(
    [
      for (final entry in entries)
        if (entry.depth <= split) entry,
    ],
    lines.length,
    words,
    nameOf ?? (title) => title,
  );
}

/// The deepest level the book splits at: see the library's doc.
int _splitDepth(
  List<BookPlannedEntry> entries,
  List<String> lines,
  bool Function(int line) opensFile,
) {
  if (entries.isEmpty) return 0;
  var depth = 0;
  for (final entry in entries) {
    if (opensFile(entry.line)) depth = max(depth, entry.depth);
  }
  depth = min(depth, _deepestSplit);
  final deepest = entries.map((entry) => entry.depth).reduce(max);
  if (depth >= min(deepest, _deepestSplit)) return depth;
  final bytes = lines.fold(0, (sum, line) => sum + line.length + 1);
  while (depth < min(deepest, _deepestSplit)) {
    final notes = entries.where((entry) => entry.depth <= depth).length + 1;
    if (bytes / notes <= _splitAbove) break;
    depth++;
  }
  return depth;
}

/// The notes [split] makes of a text [length] lines long, named and
/// numbered in their folders.
List<BookPlannedNote> _place(
  List<BookPlannedEntry> split,
  int length,
  BookWords words,
  String Function(String title) nameOf,
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
  // Each entry's place among its parent's children, for its number.
  final positions = <int>[];
  final parents = <int>[];
  final stack = <int>[];
  for (var i = 0; i < entries.length; i++) {
    while (stack.isNotEmpty && entries[stack.last].depth >= entries[i].depth) {
      stack.removeLast();
    }
    final parent = stack.isEmpty ? -1 : stack.last;
    parents.add(parent);
    positions.add(children[parent]!.length);
    (children[parent] ??= []).add(i);
    children[i] = [];
    stack.add(i);
  }
  int endOf(int i) => i + 1 < entries.length ? entries[i + 1].line : length;

  final notes = <BookPlannedNote>[];
  final folders = <int, String>{-1: ''};
  String join(String folder, String name) =>
      folder.isEmpty ? name : '$folder/$name';
  String numbered(int n, int of, String title) {
    final width = max(2, '$of'.length);
    return '${'$n'.padLeft(width, '0')} '
        '${sanitizeName(title, fallback: defaultNoteName)}';
  }

  final first = entries.isEmpty ? length : entries.first.line;
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
    final named = nameOf(entry.title);
    final name = numbered(positions[i] + 1, siblings.length, named);
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
      path: '${join(own, numbered(0, children[i]!.length, named))}.md',
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
