/// What a note's pieces share when the writer (`TreeHtml`) writes them one
/// by one (#1170): the note's link reference definitions, its footnotes
/// and the count of their citations.
///
/// A page that is written in pieces — a kanban board's cards and prose —
/// still resolves a `[x][ref]` or a `[^1]` against a definition anywhere in
/// the note, numbers its footnotes over the whole note, and writes their
/// list once, after the last piece.
library;

import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/html/footnote_html.dart';
import 'package:niman/src/markdown/inline/link_references.dart';

/// The definitions of one note, whole.
final class HtmlDefinitions {
  /// An empty set; [xhtml] gives the footnotes' attributes as XHTML has
  /// them.
  new({bool xhtml = false}) {
    footnotes = FootnoteHtml(definitions, xhtml: xhtml);
  }

  /// The link reference definitions, the first of each label winning.
  final Map<String, LinkReference> references = <String, LinkReference>{};

  /// The footnote definitions, by normalized label: the first of each.
  final Map<String, FootnoteNode> definitions = <String, FootnoteNode>{};

  /// Each footnote definition's body, written where it stands, by
  /// normalized label, so that the citations in it count in the note's
  /// order, as `cmark-gfm` counts them — its links back left as
  /// [FootnoteHtml.backrefsMark] until the citations are all counted.
  final Map<String, String> bodies = <String, String>{};

  /// The citations counted so far, and the section they end in.
  late final FootnoteHtml footnotes;
}
