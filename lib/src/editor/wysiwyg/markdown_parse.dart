import 'dart:convert';

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/preview/block_parse.dart';
import 'package:niman/src/preview/html_table.dart';
import 'package:niman/src/preview/math_syntax.dart';

/// Parses [source] exactly as the preview does.
///
/// The WYSIWYG codec and the preview must agree about what a block is.
/// Sharing the construction ([makeDocument]) is the guard against the two
/// drifting apart. This is the preview's parse run in full — every block
/// inlined at once: the codec's round trip needs it, and it runs once per
/// edit, not per keystroke.
List<md.Node> parseMarkdownDocument(String source) {
  final document = makeDocument();
  return splitHtmlTables(
    splitInlineMath(document.parseLines(const LineSplitter().convert(source))),
  );
}
