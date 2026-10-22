import 'package:niman/src/editor/highlighting.dart';

/// What the board reader needs to know about one line, from the editor's
/// own tokenizer so a column or a card is exactly what the editor colours
/// as a heading or a list item — and a line inside the frontmatter, a code
/// fence or a math block is neither.
final class LineFacts {
  /// Creates the facts of [line] (its text without a trailing `\r`).
  factory of(StyledLine line) {
    final text = line.text;
    var protectedLine = false;
    var headingLevel = 0;
    var headingMarkerEnd = 0;
    int? markerEnd;
    int? boxStart;
    for (final token in line.tokens) {
      final kind = token.kind;
      if (kind == TokenKind.codeFence ||
          kind == TokenKind.mathBlock ||
          kind == TokenKind.frontmatter) {
        protectedLine = true;
      } else if (kind == TokenKind.headingMarker) {
        headingLevel = token.end - token.start;
        headingMarkerEnd = token.end;
      } else if (kind == TokenKind.listMarker) {
        markerEnd = token.end;
      } else if (kind == TokenKind.taskBox) {
        boxStart = token.start;
      }
    }
    var indent = 0;
    while (indent < text.length &&
        (text.codeUnitAt(indent) == 0x20 || text.codeUnitAt(indent) == 0x09)) {
      indent++;
    }
    final marker = markerEnd == null ? null : text[markerEnd - 1];
    return LineFacts._(
      text: text,
      indent: indent,
      isBlank: text.trim().isEmpty,
      isProtected: protectedLine,
      headingLevel: headingLevel,
      headingMarkerEnd: headingMarkerEnd,
      marker: marker,
      markerEnd: markerEnd,
      boxStart: boxStart,
    );
  }

  const new _({
    required this.text,
    required this.indent,
    required this.isBlank,
    required this.isProtected,
    required this.headingLevel,
    required this.headingMarkerEnd,
    required this.marker,
    required this.markerEnd,
    required this.boxStart,
  });

  /// The line's text, without a trailing `\r`.
  final String text;

  /// The leading spaces and tabs, counted as characters.
  final int indent;

  /// Whether the line is empty or whitespace.
  final bool isBlank;

  /// Whether the line is inside the frontmatter, a code fence or a math
  /// block (the fences and the `$$` lines themselves included).
  final bool isProtected;

  /// The number of `#` of an ATX heading; 0 when the line is not one.
  final int headingLevel;

  /// The offset just after the heading's `#`s.
  final int headingMarkerEnd;

  /// The list marker's character (`-`, `*`, `+`, or the `.`/`)` of a
  /// numbered one); null when the line is not a list item.
  final String? marker;

  /// The offset just after the list marker.
  final int? markerEnd;

  /// The offset of a task box's `[`; null when the item has none.
  final int? boxStart;

  /// Whether the line opens a card: a `-`, `*` or `+` item. Numbered items
  /// are not cards.
  bool get isBullet => marker == '-' || marker == '*' || marker == '+';

  /// The offset where the item's text begins: after the box and the space
  /// that follows it, or, without a box, after the marker's spaces.
  int get textStart {
    final box = boxStart;
    if (box != null) {
      var at = box + 3;
      if (at < text.length && _isSpace(text.codeUnitAt(at))) at++;
      return at;
    }
    var at = markerEnd ?? 0;
    while (at < text.length && _isSpace(text.codeUnitAt(at))) {
      at++;
    }
    return at;
  }

  /// A heading's text: after the `#`s, without the optional closing run of
  /// `#` and the spaces around it.
  String get headingText {
    final rest = text.substring(headingMarkerEnd).trim();
    return rest.replaceFirst(_closingHashes, '').trim();
  }
}

final RegExp _closingHashes = RegExp(r'(^|\s)#+$');

bool _isSpace(int c) => c == 0x20 || c == 0x09;
