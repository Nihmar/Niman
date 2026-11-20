/// The links of an imported page (#1293) that are not written as links:
/// `javascript:`, `vbscript:` and `data:` ones run or carry code, not lead
/// anywhere. Their words stay as text.
library;

/// Whether [href] is one of the links not written as a link. A browser
/// ignores the tabs, line breaks and control characters inside a scheme
/// (`java\tscript:`), so they are ignored here.
bool isUnlinked(String href) =>
    _scheme.hasMatch(href.replaceAll(RegExp(r'[\u0000- \u007f]'), ''));

final RegExp _scheme = RegExp(
  '^(javascript|vbscript|data):',
  caseSensitive: false,
);
