/// A book's text as the reader joins it (#1138) — its chapters in reading
/// order, a rule between two — and where each file and each anchor opens
/// in it: the lines a conversion's plan splits into notes.
library;

import 'package:niman/src/epub/epub_book.dart';

/// The book's text as the reader joins it, and where each file opens in it.
final class EpubBookText {
  /// [lines], each file's first line in [_starts], each anchor's in
  /// [_anchors], and the book's `spine` for the files with no text.
  new(this.lines, this._starts, this._anchors, List<String> spine)
    : _opening = _openingLines(_starts, spine),
      _startLines = _starts.values.toSet();

  /// The joined text, a line an entry.
  final List<String> lines;
  final Map<String, int> _starts;
  final Map<String, Map<String, int>> _anchors;

  /// For each file of the spine with no text, where the next one with some
  /// opens (a file with none after it has no entry).
  final Map<String, int> _opening;
  final Set<int> _startLines;

  /// Where [file] opens — or, for a file with no text (a part's title page),
  /// the next file of the spine with some — plus [fragment]'s line in it.
  int? lineOf(String file, String fragment) {
    final start = _starts[file];
    if (start != null) {
      if (fragment.isEmpty) return start;
      return epubAnchorLine(_anchors[file], fragment) ?? start;
    }
    return _opening[file];
  }

  /// Whether [line] is where a file of the book opens.
  bool opensFile(int line) => _startLines.contains(line);

  /// The text's size, its line breaks counted.
  int get bytes => lines.fold(0, (sum, line) => sum + line.length + 1);
}

/// Where each file of [spine] with no text in [starts] opens: its next file
/// with some, one pass from the end.
Map<String, int> _openingLines(Map<String, int> starts, List<String> spine) {
  final out = <String, int>{};
  int? next;
  for (final file in spine.reversed) {
    if (starts[file] case final start?) {
      next = start;
    } else if (next != null) {
      out[file] = next;
    }
  }
  return out;
}

/// [book]'s chapters joined as the reader joins them.
EpubBookText epubBookText(EpubBook book) {
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
  return EpubBookText(lines, starts, anchors, book.spine);
}
