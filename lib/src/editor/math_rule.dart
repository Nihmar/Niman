/// The shared Markdown math-span rules (T-M2-05): one definition of "what
/// is a math span" for both consumers, so the editor highlight and the
/// preview parse can never drift:
///
/// * inline math: a `$` whose next char is not whitespace or `$` opens; the
///   span closes at a `$` whose previous char is not whitespace and not a
///   backslash, and whose next char is not a digit (so `$5` and `\$$` are
///   not math).
/// * display math: a line starting (after optional indentation) with `$$`.
///   A line whose trimmed content is exactly `$$…$$` is single-line
///   display; otherwise the block runs until the next line starting with
///   `$$` (an unterminated block runs to EOF).
library;

/// Whether [trimmed] is a single-line display block (`$$…$$`).
bool isSingleLineDisplay(String trimmed) =>
    trimmed.length >= 4 &&
    trimmed.startsWith(r'$$') &&
    trimmed.endsWith(r'$$');

/// Whether a *line* (trimmed) starts a display-math block — single-line or
/// multi-line. The block runs until [isDisplayClose] (or EOF).
bool isDisplayOpen(String trimmed) =>
    trimmed.startsWith(r'$$') && !isSingleLineDisplay(trimmed);

/// Whether [trimmed] closes a multi-line display block.
bool isDisplayClose(String trimmed) => trimmed.startsWith(r'$$');

/// The index of the first `$` of a leading `$$` marker on [line], or -1.
int displayMarkerStart(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith(r'$$')
      ? line.length - trimmed.length
      : -1;
}

/// The first inline-math span in [line] at/after [from], or null.
///
/// The span covers the markers (`$…$`); the LaTeX is `line.substring(s + 1,
/// e - 1)`. A `$` candidate is only an opener when the rules above hold; the
/// matching close is the first `$` that passes the close rules after the
/// open position.
(int, int)? findInlineMath(String line, int from) {
  for (var i = from; i < line.length; i++) {
    if (line.codeUnitAt(i) != 0x24) continue;
    final after = i + 1;
    if (after >= line.length) continue;
    final a = line.codeUnitAt(after);
    if (a == 0x24 || _isSpaceChar(a)) continue;
    for (var j = after; j < line.length; j++) {
      if (line.codeUnitAt(j) != 0x24) continue;
      final before = line.codeUnitAt(j - 1);
      if (before == 0x5C || _isSpaceChar(before)) continue;
      final next = j + 1 < line.length ? line.codeUnitAt(j + 1) : -1;
      if (next >= 0x30 && next <= 0x39) continue;
      return (i, j + 1);
    }
  }
  return null;
}

/// All inline-math spans in [line], in order.
Iterable<(int, int)> allInlineMath(String line) sync* {
  var pos = 0;
  while (pos < line.length) {
    final span = findInlineMath(line, pos);
    if (span == null) return;
    yield span;
    pos = span.$2;
  }
}

bool _isSpaceChar(int c) =>
    c == 0x20 ||
    c == 0x09 ||
    c == 0x0A ||
    c == 0x0B ||
    c == 0x0C ||
    c == 0x0D;
