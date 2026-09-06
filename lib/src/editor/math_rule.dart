/// The shared Markdown math-span rules (T-M2-05): one definition of "what
/// is a math span" for both consumers, so the editor highlight and the
/// preview parse can never drift:
///
/// * inline math: a `$` (not preceded by `\`) opens unless the next char is
///   a `$` (display). Whitespace next to a delimiter is allowed (`$ x $`
///   typesets) and digit-adjacent openers are math too: the real notes use
///   `$1$`, `$2 \times 2$` everywhere (579 digit spans, no prose prices).
///   A span closing guards only against `\$`; a `$5 and $10`-style prose
///   price is the one documented edge (renders as a KaTeX error fallback).
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
  return trimmed.startsWith(r'$$') ? line.length - trimmed.length : -1;
}

/// The first inline-math span in [line] at/after [from], or null.
///
/// The span covers the markers (`$…$`); the LaTeX is `line.substring(s + 1,
/// e - 1)`. Whitespace and digits inside the delimiters are allowed;
/// `\$` (escaped) and `$$` (display) are not math.
(int, int)? findInlineMath(String line, int from) {
  for (var i = from; i < line.length; i++) {
    if (line.codeUnitAt(i) != 0x24) continue;
    if (i > 0 && line.codeUnitAt(i - 1) == 0x5C) continue;
    final after = i + 1;
    if (after >= line.length) continue;
    if (line.codeUnitAt(after) == 0x24) continue;
    for (var j = after; j < line.length; j++) {
      if (line.codeUnitAt(j) != 0x24) continue;
      if (j > 0 && line.codeUnitAt(j - 1) == 0x5C) continue;
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
