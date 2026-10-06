/// A footnote definition's lines, as the read view's parser reads them
/// (`package:markdown`'s `FootnoteDefSyntax`, `docs/dev/block-tree.md`).
library;

import 'package:markdown/markdown.dart' as md;

/// What a line says about a footnote definition: whether it opens one,
/// goes on with one, or ends one.
abstract final class FootnoteSyntax {
  /// The definition [text] opens — its label, and where its content starts
  /// past `[^label]:` and the spaces after — or null: up to three spaces in,
  /// a label without spaces or tabs.
  static (String, int)? opening(String text) {
    final match = _opening.firstMatch(text);
    if (match == null) return null;
    return (match.group(2)!, match.end);
  }

  /// Whether [text], a line under an open definition that is neither blank
  /// nor four spaces in, ends it: the line would open a block of any kind —
  /// the parser asks every block syntax's pattern, not whether the block
  /// could interrupt a paragraph. A line that does not goes on with the
  /// definition lazily.
  static bool ends(String text) => _blocks.any((block) => block.hasMatch(text));

  /// How many characters a line takes to go on with an open definition by
  /// its indent: four spaces, literally — a tab is not four spaces here.
  static const int indent = 4;

  /// Whether [text] goes on with an open definition by its indent.
  static bool indented(String text) => text.startsWith('    ');

  static final RegExp _opening = const md.FootnoteDefSyntax().pattern;

  /// The patterns of the block syntaxes the parser tries, GFM's and the
  /// standard ones, but for the empty line and those that match nothing
  /// (a table, a paragraph): `FootnoteDefSyntax._isBlock`.
  static final List<RegExp> _blocks = <RegExp>[
    const md.FencedCodeBlockSyntax().pattern,
    const md.UnorderedListWithCheckboxSyntax().pattern,
    const md.OrderedListWithCheckboxSyntax().pattern,
    const md.FootnoteDefSyntax().pattern,
    const md.HtmlBlockSyntax().pattern,
    const md.SetextHeaderSyntax().pattern,
    const md.HeaderSyntax().pattern,
    const md.CodeBlockSyntax().pattern,
    const md.BlockquoteSyntax().pattern,
    const md.HorizontalRuleSyntax().pattern,
    const md.UnorderedListSyntax().pattern,
    const md.OrderedListSyntax().pattern,
    const md.LinkReferenceDefinitionSyntax().pattern,
  ];
}
