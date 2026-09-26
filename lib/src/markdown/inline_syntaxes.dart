/// What Niman reads inline beyond GitHub's Markdown: `==highlight==` and the
/// HTML style tags.
///
/// One list for every reader of a note's inline text — the read view's block
/// parser and the HTML export — so a construct the note shows is a construct
/// the export writes, and the two cannot learn different dialects.
library;

import 'package:markdown/markdown.dart' as md;

/// The inline syntaxes to add to GitHub's: the HTML style tags and
/// `==highlight==`.
final List<md.InlineSyntax> nimanInlineSyntaxes = <md.InlineSyntax>[
  ..._htmlStyleSyntaxes,
  _HighlightSyntax(),
];

/// `==text==` on one line, as a `mark` element whose contents are parsed
/// like any other inline text (#279).
///
/// The text neither starts nor ends with a space, as emphasis does not:
/// `a == b == c` is two comparisons, not a highlighted ` b `.
final class _HighlightSyntax extends md.InlineSyntax {
  new() : super(r'==(?![\s=])(.+?)(?<![\s=])==', startCharacter: 0x3D);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final children = md.InlineParser(match[1]!, parser.document).parse();
    parser.addNode(md.Element('mark', children));
    return true;
  }
}

/// The HTML tags a note uses for what Markdown has no syntax for, read as the
/// constructs they are rather than as raw HTML.
final List<md.InlineSyntax> _htmlStyleSyntaxes = <md.InlineSyntax>[
  for (final tag in const <String>['u', 'sup', 'sub']) _HtmlStyleSyntax(tag),
];

/// `<tag>…</tag>` on one line, as an element whose contents are parsed like
/// any other inline text — so `<u>**x**</u>` is bold and underlined.
///
/// The package reads inline HTML as text it passes through, which a renderer
/// that draws runs cannot draw: the toolbar's underline wrote `<u>` into the
/// note, and both the read view and `live` mode showed the tags.
final class _HtmlStyleSyntax extends md.InlineSyntax {
  new(this.tag)
    : super('<$tag>(.+?)</$tag>', startCharacter: 0x3C, caseSensitive: false);

  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final children = md.InlineParser(match[1]!, parser.document).parse();
    parser.addNode(md.Element(tag, children));
    return true;
  }
}
