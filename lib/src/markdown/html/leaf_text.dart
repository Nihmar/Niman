/// What a leaf of the block tree holds for the inline parser, and for a
/// code block's writer: its lines as CommonMark reads them.
library;

import 'package:niman/src/markdown/block_node.dart';

/// The text of a leaf, read off the note's lines.
abstract final class LeafText {
  /// The leaf's lines as its container reads them.
  static List<String> linesOf(LeafNode leaf, List<String> lines) => [
    for (final span in leaf.lines)
      lines[span.line].substring(span.start, span.end),
  ];

  /// [lines], a fence's, each with the columns of a tab its container's
  /// prefix ended inside of written as spaces: the code's own (`- ```` /
  /// tab `w` is the code `  w`), or the opening fence's indent, which comes
  /// off the code after (`CodeHtml.fenceParts`).
  static List<String> withLeftOver(LeafNode leaf, List<String> lines) => [
    for (var at = 0; at < lines.length; at++)
      if (at < leaf.leftOver.length && leaf.leftOver[at] > 0)
        '${' ' * leaf.leftOver[at]}${lines[at]}'
      else
        lines[at],
  ];

  /// A paragraph's inline text: each line's leading white space off, the
  /// last line's trailing white space too, the lines joined.
  static String paragraph(List<String> lines) =>
      _trimEnd(lines.map(_trimStart).join('\n'));

  /// An ATX heading's inline text: its `#`s off, and the closing run of
  /// them when white space stands before it.
  static String atxHeading(String line) {
    var text = _trimStart(line);
    var hashes = 0;
    while (hashes < text.length && text.codeUnitAt(hashes) == 0x23) {
      hashes++;
    }
    text = _trimEnd(text.substring(hashes));
    var end = text.length;
    while (end > 0 && text.codeUnitAt(end - 1) == 0x23) {
      end--;
    }
    if (end < text.length &&
        (end == 0 ||
            text.codeUnitAt(end - 1) == 0x20 ||
            text.codeUnitAt(end - 1) == 0x09)) {
      text = text.substring(0, end);
    }
    return _trimEnd(_trimStart(text));
  }

  /// A setext heading's inline text: its lines but the underline, as a
  /// paragraph's.
  static String setextHeading(List<String> lines) =>
      paragraph(lines.sublist(0, lines.length - 1));

  static String _trimStart(String text) {
    var at = 0;
    while (at < text.length &&
        (text.codeUnitAt(at) == 0x20 || text.codeUnitAt(at) == 0x09)) {
      at++;
    }
    return at == 0 ? text : text.substring(at);
  }

  static String _trimEnd(String text) {
    var end = text.length;
    while (end > 0 &&
        (text.codeUnitAt(end - 1) == 0x20 ||
            text.codeUnitAt(end - 1) == 0x09 ||
            text.codeUnitAt(end - 1) == 0x0A)) {
      end--;
    }
    return end == text.length ? text : text.substring(0, end);
  }
}
