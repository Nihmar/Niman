/// The shared Markdown math-span rules (T-M2-05): one definition of "what
/// is a math span" for every consumer — the editor highlight, the preview
/// parse and the read view's block scanner — so they can never drift:
///
/// * inline math: a `$` (not preceded by `\`) opens unless the next char is
///   a `$` (display). Whitespace next to a delimiter is allowed (`$ x $`
///   typesets) and digits inside are math too: the real notes use `$1$`,
///   `$2 \times 2$` everywhere (579 digit spans). A `$` is a currency sign
///   where it touches a number from outside: right after a digit it opens
///   nothing (`20$ + 0,10$/Kg`), right before one it closes nothing
///   (`$5 and $10`) — Pandoc's closing rule, and its mirror. Measured on a
///   945 KB note of 13 004 formulas: none breaks either.
/// * display math: a line starting (after optional indentation) with `$$`.
///   A line whose trimmed content is exactly `$$…$$` is single-line
///   display; otherwise the block runs until the next line starting with
///   `$$` (an unterminated block runs to EOF).
library;

/// Whether [trimmed] is a single-line display block (`$$…$$`).
bool isSingleLineDisplay(String trimmed) =>
    trimmed.length >= 4 && trimmed.startsWith(r'$$') && trimmed.endsWith(r'$$');

/// Whether [trimmed] is display math at all — a `$$` line, of either form.
///
/// The door the other two are asked behind: the preview's `MathBlockSyntax`
/// and the read view's block scanner both classify by this first, so a line
/// holding `$$x$$` is a display block in both. They drifted while the scanner
/// kept its own copy of these rules — the line was a display block in the
/// preview and a paragraph in the read view (#252) — so the copy is gone.
bool isDisplayLine(String trimmed) => trimmed.startsWith(r'$$');

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
    final end = inlineMathAt(line, i);
    if (end != null) return (i, end);
  }
  return null;
}

/// Whether the character at [at] in [line] may open inline math: a `$`
/// not escaped, not right after a digit (a price written after its
/// number, `20$`), and not the first of a `$$`.
bool opensInlineMath(String line, int at) {
  if (line.codeUnitAt(at) != 0x24) return false;
  if (at > 0 && line.codeUnitAt(at - 1) == 0x5C) return false;
  if (at > 0 && _isDigit(line.codeUnitAt(at - 1))) return false;
  final after = at + 1;
  return after < line.length && line.codeUnitAt(after) != 0x24;
}

/// The end of the inline-math span the `$` at [at] opens, or null: the
/// first `$` after it that is not escaped and not right before a digit (a
/// price written before its number, `$10`).
int? inlineMathAt(String line, int at) {
  if (!opensInlineMath(line, at)) return null;
  for (var j = at + 1; j < line.length; j++) {
    if (line.codeUnitAt(j) != 0x24) continue;
    if (line.codeUnitAt(j - 1) == 0x5C) continue;
    if (j + 1 < line.length && _isDigit(line.codeUnitAt(j + 1))) continue;
    return j + 1;
  }
  return null;
}

bool _isDigit(int char) => char >= 0x30 && char <= 0x39;

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
