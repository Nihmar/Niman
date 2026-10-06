/// What one line of Markdown says on its own: the markers it starts with,
/// read off its text alone.
///
/// No state here: where a line stands among the containers already open
/// is `line_containers.dart`'s, and what the scan makes of it is
/// `line_rules.dart`'s and `block_rules.dart`'s. The readers take the
/// column to start from, or how far in a marker may stand, when the caller
/// knows it.
library;

import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/markdown/line_state.dart';

/// The markers a line of Markdown opens with.
abstract final class LineSyntax {
  /// The list marker [text] opens with — its start, its width and where the
  /// item's text begins — or null: the scanner's own rule, for a reader
  /// that colours the marker of a line the scanner already took for an
  /// item, which is why the marker's indent is not asked about.
  static (int, int, int)? listMarkerOf(String text) =>
      listMarker(text, text.length);

  /// The `#`s that open a heading on [text] — where they start and how many
  /// — or null: the scanner's own rule, for a reader that colours or lists a
  /// line the scanner already took for a heading, which is why the indent
  /// before them is not asked about. Where they start is part of the answer
  /// because a heading may stand indented (up to three spaces in from the
  /// margin or from an item's content): a count alone, read as an offset
  /// from the line's start, put the marker on the spaces. A reader that has
  /// not had the line decided for it — a quote's inside — passes the
  /// [reach] CommonMark allows, three.
  static (int, int)? headingMarkerOf(String text, [int? reach]) =>
      _headingMarker(text, 0, reach ?? text.length);

  /// How many `#` open a heading on [text], or 0: up to three spaces in from
  /// [column], the content column of the item the line is in.
  static int headingLevel(String text, [int column = 0]) =>
      _headingMarker(text, column, 3)?.$2 ?? 0;

  /// Where the `#`s of a heading on [text] start and how many there are, at
  /// most [reach] spaces in from [column]; null when the line is no heading.
  static (int, int)? _headingMarker(String text, int column, int reach) {
    var at = column;
    while (at < text.length &&
        at - column < reach &&
        isSpace(text.codeUnitAt(at))) {
      at++;
    }
    var hashes = 0;
    while (at + hashes < text.length && text.codeUnitAt(at + hashes) == 0x23) {
      hashes++;
    }
    if (hashes >= 1 &&
        hashes <= 6 &&
        (at + hashes == text.length || isSpace(text.codeUnitAt(at + hashes)))) {
      return (at, hashes);
    }
    return null;
  }

  /// The setext heading level [text] is an underline for — 1 for `=`, 2 for
  /// `-`, up to three spaces in from [from] and spaces after — or 0 when it
  /// is not one.
  static int setextLevel(String text, [int from = 0]) {
    var at = from;
    while (at < from + 3 && at < text.length && isSpace(text.codeUnitAt(at))) {
      at++;
    }
    if (at >= text.length) return 0;
    final char = text.codeUnitAt(at);
    if (char != 0x3D && char != 0x2D) return 0;
    var run = 0;
    while (at + run < text.length && text.codeUnitAt(at + run) == char) {
      run++;
    }
    for (var end = at + run; end < text.length; end++) {
      if (!isSpace(text.codeUnitAt(end))) return 0;
    }
    return char == 0x3D ? 1 : 2;
  }

  /// The fence a line opens, or null: up to three spaces in from [base], the
  /// content column of the item the line is in.
  static FenceMarker? fenceOpen(String text, [int base = 0]) {
    var indent = 0;
    while (indent < base + 3 &&
        indent < text.length &&
        isSpace(text.codeUnitAt(indent))) {
      indent++;
    }
    if (indent >= text.length) return null;
    final char = text.codeUnitAt(indent);
    if (char != 0x60 && char != 0x7E) return null;
    var length = 0;
    while (indent + length < text.length &&
        text.codeUnitAt(indent + length) == char) {
      length++;
    }
    if (length < 3) return null;
    final rest = text.substring(indent + length);
    // A backtick fence's info string may not contain a backtick.
    if (char == 0x60 && rest.contains('`')) return null;
    return FenceMarker(char: char, length: length, indent: indent);
  }

  /// Whether [text] closes [fence], opened in an item whose content starts at
  /// [listIndent] (-1 outside a list): up to three spaces in from there.
  static bool isFenceClose(String text, FenceMarker fence, int listIndent) {
    final reach = (listIndent < 0 ? 0 : listIndent) + 3;
    var indent = 0;
    while (indent < reach &&
        indent < text.length &&
        isSpace(text.codeUnitAt(indent))) {
      indent++;
    }
    var length = 0;
    while (indent + length < text.length &&
        text.codeUnitAt(indent + length) == fence.char) {
      length++;
    }
    if (length < fence.length) return false;
    return text.substring(indent + length).trim().isEmpty;
  }

  /// Whether [text] closes a `$$` block.
  static bool closesMath(String text) => isDisplayClose(text.trim());

  /// Whether line [line] opens the frontmatter block: only the first line can.
  static bool opensFrontmatter(int line, String text) =>
      line == 0 && (text.trim() == '---' || text.trim() == '...');

  /// Whether [text] closes the frontmatter.
  static bool closesFrontmatter(String text) {
    final trimmed = text.trim();
    return trimmed == '---' || trimmed == '...';
  }

  /// How deep in blockquotes a line sits, by its own markers, read from
  /// [column] on.
  static int quoteDepth(String text, [int column = 0]) {
    var at = column;
    var depth = 0;
    while (at < text.length) {
      var spaces = 0;
      while (at + spaces < text.length &&
          spaces < 3 &&
          isSpace(text.codeUnitAt(at + spaces))) {
        spaces++;
      }
      if (at + spaces >= text.length || text.codeUnitAt(at + spaces) != 0x3E) {
        break;
      }
      depth++;
      at += spaces + 1;
      if (at < text.length && isSpace(text.codeUnitAt(at))) at++;
    }
    return depth;
  }

  /// The list marker on [text], or null: its start, width and content indent.
  ///
  /// A marker may stand up to three spaces in from where a line starts its
  /// text — the note's margin, or inside a list item the item's own content
  /// column, which is [reach] minus those three. Counting them from the
  /// margin alone took `    - c`, a third level, for the text of the item
  /// above it: every list stopped at two levels.
  static (int, int, int)? listMarker(String text, [int reach = 3]) {
    var at = 0;
    while (at < reach && at < text.length && isSpace(text.codeUnitAt(at))) {
      at++;
    }
    if (at >= text.length) return null;
    final char = text.codeUnitAt(at);
    var width = 0;
    if (char == 0x2D || char == 0x2B || char == 0x2A) {
      width = 1;
    } else if (isDigit(char)) {
      var digits = 0;
      while (at + digits < text.length &&
          digits < 9 &&
          isDigit(text.codeUnitAt(at + digits))) {
        digits++;
      }
      if (digits == 0 || at + digits >= text.length) return null;
      final delimiter = text.codeUnitAt(at + digits);
      if (delimiter != 0x2E && delimiter != 0x29) return null;
      width = digits + 1;
    } else {
      return null;
    }
    final after = at + width;
    if (after >= text.length) return (at, width, after);
    if (!isSpace(text.codeUnitAt(after))) return null;
    var padding = 0;
    while (after + padding < text.length &&
        padding < 4 &&
        isSpace(text.codeUnitAt(after + padding))) {
      padding++;
    }
    if (padding == 0) padding = 1;
    return (at, width, after + padding);
  }

  /// How far in the lines of the item [marker] opens on [text] stand, and
  /// whether the marker has no text after it — `package:markdown`'s rule,
  /// which the read view draws with: past the marker and one space, plus
  /// the spaces after that up to three; four or more are the item's
  /// indented code, and count as one.
  static (int, bool) itemIndent(String text, (int, int, int) marker) {
    final (start, width, _) = marker;
    final base = start + width + 1;
    var at = start + width + 1;
    while (at < text.length && isSpace(text.codeUnitAt(at))) {
      at++;
    }
    if (at >= text.length) return (base, true);
    final spaces = at - base;
    return (spaces >= 4 ? base : at, false);
  }

  /// What a quote line [text] holds inside its first `>`: past the marker
  /// and the one space or tab after it.
  static String quoteChild(String text) {
    var at = 0;
    while (at < text.length && text.codeUnitAt(at) != 0x3E) {
      at++;
    }
    at++;
    if (at < text.length && isSpace(text.codeUnitAt(at))) at++;
    return at >= text.length ? '' : text.substring(at);
  }

  /// Whether [text] could start a link reference definition (`[label]:`),
  /// which is not paragraph text to a quote's lazy reading.
  static bool startsLinkReference(String text) {
    var at = 0;
    while (at < 3 && at < text.length && text.codeUnitAt(at) == 0x20) {
      at++;
    }
    return at < text.length && text.codeUnitAt(at) == 0x5B;
  }

  /// Whether the marker [marker] on [text] may interrupt an open paragraph:
  /// an empty item (a marker with only spaces after it) never does; an
  /// ordered one only if it starts at 1, unless the paragraph is in a list
  /// item ([inItem]), where any marker starts a list.
  static bool markerInterrupts(
    (int, int, int) marker,
    String text, {
    bool inItem = false,
  }) {
    final (start, width, _) = marker;
    var at = start + width;
    while (at < text.length && isSpace(text.codeUnitAt(at))) {
      at++;
    }
    if (at >= text.length) return false;
    if (inItem) return true;
    final char = text.codeUnitAt(start);
    if (isDigit(char)) return width == 2 && char == 0x31;
    return true;
  }

  /// The number an ordered marker was written with, or 0 for an unordered one.
  static int writtenOrdinal(String text) {
    // Asked of a line already taken for an item: its indent is settled.
    final marker = listMarker(text, text.length);
    if (marker == null) return 0;
    final (start, width, _) = marker;
    final slice = text.substring(start, start + width).trim();
    final digits = int.tryParse(slice.replaceAll(RegExp('[^0-9]'), ''));
    return digits ?? 0;
  }

  /// Whether [text] from [from] on is a thematic break, as the read view's
  /// parser reads one: up to three spaces, then three or more of one `-`,
  /// `*` or `_`, with spaces or tabs between them and nothing else —
  /// `* * *` as much as `***`.
  ///
  /// Read by hand, not by an expression: every line is asked, twice (its
  /// kind, and whether it is paragraph text), and the expression was the
  /// largest single cost of a scan. Nearly every line is answered at its
  /// first character.
  static bool isHr(String text, int from) {
    var at = from;
    while (at < text.length && at - from < 3 && text.codeUnitAt(at) == 0x20) {
      at++;
    }
    if (at >= text.length) return false;
    final char = text.codeUnitAt(at);
    if (char != 0x2D && char != 0x2A && char != 0x5F) return false;
    var count = 0;
    for (; at < text.length; at++) {
      final next = text.codeUnitAt(at);
      if (next == char) {
        count++;
      } else if (next != 0x20 && next != 0x09) {
        return false;
      }
    }
    return count >= 3;
  }

  /// [text] with the tabs of its leading whitespace made spaces, to the
  /// next stop of four columns: what the read view's parser counts a
  /// line's indent in. Obsidian indents a sublist with a tab, which is four
  /// columns and so inside an item of two — counted as one, the sublist
  /// was a sibling. The tabs after a marker stay as they are: the parser
  /// takes the one after a marker as its one space.
  static String expandIndent(String text) {
    var at = 0;
    var tab = false;
    while (at < text.length && isSpace(text.codeUnitAt(at))) {
      if (text.codeUnitAt(at) == 0x09) tab = true;
      at++;
    }
    if (!tab) return text;
    final spaces = StringBuffer();
    var column = 0;
    for (var i = 0; i < at; i++) {
      final width = text.codeUnitAt(i) == 0x09 ? 4 - column % 4 : 1;
      for (var space = 0; space < width; space++) {
        spaces.write(' ');
      }
      column += width;
    }
    return '$spaces${text.substring(at)}';
  }

  /// How far in [text] stands, in columns, a tab to the next stop of four,
  /// plus [remaining] columns a tab taken off it before left over: what a
  /// list item compares with its indent (`package:markdown`'s
  /// `indentation()` and `tabRemaining`).
  static int columnsOf(String text, [int remaining = 0]) {
    var columns = 0;
    for (var at = 0; at < text.length; at++) {
      final char = text.codeUnitAt(at);
      if (char == 0x09) {
        columns += 4 - columns % 4;
      } else if (char == 0x20) {
        columns++;
      } else {
        break;
      }
    }
    return columns + remaining;
  }

  /// [text] with [indent] columns of its leading whitespace taken off, the
  /// way the read view's parser takes an item's indent off its lines
  /// (`package:markdown`'s `dedent`): a tab is four columns wherever it
  /// stands, and goes whole once the indent is reached in it, its columns
  /// past the indent left over — the second of the pair, which counts
  /// toward the next item's indent and nothing else. A tab short of the
  /// indent goes too, and leaves nothing.
  static (String, int) dedent(String text, int indent) {
    var start = 0;
    var columns = 0;
    var remaining = 0;
    var tab = false;
    for (; start < text.length && start < indent; start++) {
      final char = text.codeUnitAt(start);
      if (char != 0x20 && char != 0x09) break;
      final isTab = char == 0x09;
      if (isTab) {
        columns += 4;
        tab = true;
      } else {
        columns += 1;
      }
      if (columns >= indent) {
        if (tab) remaining = columns - indent;
        if (columns == indent || isTab) start++;
        return (text.substring(start), remaining);
      }
    }
    return (text.substring(start), 0);
  }

  /// How many spaces [text] starts with.
  static int indentOf(String text) => text.length - text.trimLeft().length;

  /// A space or a tab.
  static bool isSpace(int char) => char == 0x20 || char == 0x09;

  /// An ASCII digit.
  static bool isDigit(int char) => char >= 0x30 && char <= 0x39;
}
