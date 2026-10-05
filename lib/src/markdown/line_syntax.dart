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

  /// Whether the marker [marker] on [text] may interrupt an open paragraph:
  /// an unordered item always may, an ordered one only if it starts at 1, and
  /// an empty item (a marker with no content) never does.
  static bool markerInterrupts((int, int, int) marker, String text) {
    if (marker.$3 >= text.length) return false;
    final char = text.codeUnitAt(marker.$1);
    if (isDigit(char)) return marker.$2 == 2 && char == 0x31;
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

  /// Whether [text] from [from] on matches [_hr].
  ///
  /// The expression cannot match unless three of one `-`, `*` or `_` in a
  /// row stand within the first four characters with only whitespace before
  /// them, so a line with anything else there — nearly every line of prose,
  /// and every list item's `- ` — is answered without running it. Every
  /// line is asked, twice (its kind, and whether it is paragraph text), and
  /// the expression was the largest single cost of a scan.
  static bool isHr(String text, int from) {
    for (var at = from; at < text.length && at < from + 4; at++) {
      final char = text.codeUnitAt(at);
      if (char == 0x2D || char == 0x2A || char == 0x5F) {
        return at + 2 < text.length &&
            text.codeUnitAt(at + 1) == char &&
            text.codeUnitAt(at + 2) == char &&
            _hr.hasMatch(from == 0 ? text : text.substring(from));
      }
      // What `\s` may match: ASCII whitespace, or past ASCII, where Unicode
      // whitespace is — taken as space, so the expression decides.
      final space =
          char == 0x20 || (char >= 0x09 && char <= 0x0D) || char > 0x7F;
      if (!space) return false;
    }
    return false;
  }

  static final RegExp _hr = RegExp(
    r'^\s{0,3}((?:-{3,})|(?:\*{3,})|(?:_{3,}))\s*$',
  );

  /// Whether [text] is a table's delimiter row: only `-`, `:`, `|` and spaces,
  /// with at least one `-`.
  static bool isDelimiterRow(String text) {
    final trimmed = text.trim();
    if (!trimmed.contains('-') || !trimmed.contains('|')) return false;
    if (!hasPipe(trimmed)) return false;
    for (final rune in trimmed.codeUnits) {
      final ok = rune == 0x2D || rune == 0x3A || rune == 0x7C || isSpace(rune);
      if (!ok) return false;
    }
    return true;
  }

  /// Whether [text] has a `|`, which every table row does.
  static bool hasPipe(String text) => text.contains('|');

  /// How many spaces [text] starts with.
  static int indentOf(String text) => text.length - text.trimLeft().length;

  /// A space or a tab.
  static bool isSpace(int char) => char == 0x20 || char == 0x09;

  /// An ASCII digit.
  static bool isDigit(int char) => char >= 0x30 && char <= 0x39;
}
