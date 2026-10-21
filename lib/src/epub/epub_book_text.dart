/// A book's text as the reader joins it (#1138) — its chapters in reading
/// order, a rule between two — and where each file and each anchor opens
/// in it: the lines a conversion's plan splits into notes.
library;

import 'package:niman/src/epub/epub_book.dart';

/// The book's text as the reader joins it, and where each file opens in it.
final class EpubBookText {
  /// [lines], each file's first line in [_starts], each anchor's in
  /// [_anchors], and the book's [_spine] for files with no text.
  new(this.lines, this._starts, this._anchors, this._spine);

  /// The joined text, a line an entry.
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
      return epubAnchorLine(_anchors[file], fragment) ?? start;
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

  /// The text's size, its line breaks counted.
  int get bytes => lines.fold(0, (sum, line) => sum + line.length + 1);
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
