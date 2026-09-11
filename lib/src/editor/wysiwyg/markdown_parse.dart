import 'dart:convert';

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/preview/html_table.dart';
import 'package:niman/src/preview/math_syntax.dart';
import 'package:niman/src/preview/wikilink.dart';

/// Parses [source] exactly as the preview does.
///
/// The WYSIWYG codec and the preview must agree about what a block is.
/// Sharing this function is the guard against the two drifting apart.
List<md.Node> parseMarkdownDocument(String source) {
  final document = md.Document(
    blockSyntaxes: <md.BlockSyntax>[
      const MathBlockSyntax(),
      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    ],
    inlineSyntaxes: [EmbedInlineSyntax(), WikilinkInlineSyntax()],
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  return splitHtmlTables(
    splitInlineMath(document.parseLines(const LineSplitter().convert(source))),
  );
}
