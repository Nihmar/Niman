/// GFM's footnote definition, for the export's whole-note parse: with a
/// place for its link back when it ends with a list.
library;

import 'package:markdown/markdown.dart' as md;

/// `md.FootnoteDefSyntax`, its footnote's last block never a list.
///
/// The package appends a cited footnote's link back to the children of its
/// last block. A list's children are typed for its items, so the link could
/// not be added there: the parse threw, and a note whose footnote ends with
/// a list could not be exported. An empty paragraph after the list takes
/// the link instead — after the list, where a reader expects it, not
/// inside it as a stray child of the `<ul>`.
final class ExportFootnoteSyntax extends md.FootnoteDefSyntax {
  /// The syntax.
  const new();

  @override
  md.Node? parse(md.BlockParser parser) {
    final node = super.parse(parser);
    final children = node is md.Element ? node.children : null;
    if (children != null && children.isNotEmpty) {
      final last = children.last;
      if (last is md.Element && (last.tag == 'ul' || last.tag == 'ol')) {
        children.add(md.Element('p', <md.Node>[]));
      }
    }
    return node;
  }
}
