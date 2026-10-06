/// A footnote definition's lines, as `cmark-gfm` reads them: a container
/// opened by `[^label]:` at the margin, holding the lines four columns in
/// and, lazily, the lines that go on with its paragraph
/// (`docs/dev/block-tree.md`).
library;

import 'package:niman/src/markdown/line_syntax.dart';

/// What a line says about a footnote definition: whether it opens one, or
/// goes on with one by its indent.
///
/// Whether a line short of that indent ends one is whether it would open
/// a block that interrupts a paragraph (`ContainerWalk.interruptsParagraph`):
/// anything else goes on with the definition's paragraph lazily.
abstract final class FootnoteSyntax {
  /// The definition [text] opens — its label, and where its content starts
  /// past `[^label]:` and the spaces after — or null: up to three spaces in,
  /// a label without spaces or tabs.
  static (String, int)? opening(String text) {
    final match = _opening.firstMatch(text);
    if (match == null) return null;
    return (match.group(1)!, match.end);
  }

  /// How many columns a line stands in to go on with an open definition by
  /// its indent.
  static const int indent = 4;

  /// Whether [text] goes on with an open definition by its indent: four
  /// columns in, a tab to the next stop of four.
  static bool indented(String text) => LineSyntax.columnsOf(text) >= indent;

  /// [text], a line [indented] into a definition, past its four columns:
  /// the rest, and the columns of a tab the four ended inside of, left
  /// over toward an item inside (`LineSyntax.dedent`).
  static (String, int) content(String text) => LineSyntax.dedent(text, indent);

  /// `[^label]:` up to three spaces in, a label without white space.
  static final RegExp _opening = RegExp(
    r'^ {0,3}\[\^([^\] \r\n\x00\t]+)\]:[ \t]*',
  );
}
