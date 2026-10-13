/// The grammar of a block id (#844), in one place.
///
/// A link names a block by the id the block ends with (`[[note#^37066d]]`,
/// ` ^37066d` at the end of a line). The parser that reads the link, the scan
/// that finds the ids, the read view that hides one and the suggester that
/// lists them all ask this class what an id is.
library;

/// What a block id is made of.
abstract final class BlockId {
  /// The characters of an id, as a regular expression: letters, digits and
  /// dashes (Obsidian's human-readable ids).
  static const String chars = '[A-Za-z0-9-]';

  static final RegExp _whole = RegExp('^$chars+\$');

  // A space (or the line's start), a caret and an id at the end of a line.
  static final RegExp _trailing = RegExp('(?:^|[ \\t])\\^($chars+)[ \\t]*\$');

  /// Whether [text] is an id, whole.
  static bool isValid(String text) => _whole.hasMatch(text);

  /// The ` ^id` that ends [line]: its match, whose group 1 is the id; null when
  /// the line ends with none.
  static RegExpMatch? trailingIn(String line) => _trailing.firstMatch(line);
}
