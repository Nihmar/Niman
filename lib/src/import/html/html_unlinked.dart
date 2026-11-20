/// The links of an imported page (#1293) that are not written as links:
/// `javascript:`, `vbscript:` and `data:` ones run or carry code, not lead
/// anywhere. Their words stay as text.
///
/// The converter writes every link it is given a target for, so the
/// import's `link` callback names such a link by a placeholder
/// ([unlinkedTarget]) and [withoutUnlinked] takes the link away from the
/// text once it is written: `[words](<placeholder>)` becomes `words`.
library;

/// Whether [href] is one of the links not written as a link. A browser
/// ignores the tabs, line breaks and control characters inside a scheme
/// (`java\tscript:`), so they are ignored here.
bool isUnlinked(String href) =>
    _scheme.hasMatch(href.replaceAll(RegExp(r'[\u0000- \u007f]'), ''));

/// The placeholder target of a link [isUnlinked].
const String unlinkedTarget = 'niman-unlinked:';

final RegExp _scheme = RegExp(
  '^(javascript|vbscript|data):',
  caseSensitive: false,
);

const String _marker = '](<$unlinkedTarget>)';

/// [markdown] with each link that carries the placeholder reduced to its
/// words. The brackets of the words are matched as Markdown matches them:
/// a picture or an escaped bracket inside does not end them.
String withoutUnlinked(String markdown) {
  var text = markdown;
  var at = text.lastIndexOf(_marker);
  while (at >= 0) {
    final open = _openingBracket(text, at);
    text = open < 0
        ? text.replaceRange(at, at + _marker.length, '](<#>)')
        : text.substring(0, open) +
              text.substring(open + 1, at) +
              text.substring(at + _marker.length);
    at = at == 0 ? -1 : text.lastIndexOf(_marker, at - 1);
  }
  return text;
}

/// The `[` that opens the words ending at the `]` at [close], or -1.
int _openingBracket(String text, int close) {
  var depth = 1;
  for (var i = close - 1; i >= 0; i--) {
    final unit = text.codeUnitAt(i);
    if (unit != 0x5B && unit != 0x5D) continue;
    // A bracket after an odd run of backslashes is text.
    var slashes = 0;
    while (i - 1 - slashes >= 0 && text.codeUnitAt(i - 1 - slashes) == 0x5C) {
      slashes++;
    }
    if (slashes.isOdd) continue;
    depth += unit == 0x5D ? 1 : -1;
    if (depth == 0) return i;
  }
  return -1;
}
