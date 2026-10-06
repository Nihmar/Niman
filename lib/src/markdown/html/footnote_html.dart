/// Footnotes written as HTML, as `cmark-gfm` writes them: references
/// numbered by first citation, each with an id of its own, and the
/// section the note ends with, each footnote's links back after its text.
library;

import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/inline/inline_html.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/link_references.dart';

/// The footnotes cited so far, in citation order.
final class FootnoteHtml {
  /// Footnotes over [definitions], by normalized label.
  new(this.definitions);

  /// The note's footnote definitions: the first of each label.
  final Map<String, FootnoteNode> definitions;

  /// The labels cited, normalized, in the order first cited.
  final List<String> cited = <String>[];

  /// How many times each label is cited.
  final Map<String, int> _counts = <String, int>{};

  /// The label each was first cited with, as written.
  final Map<String, String> _written = <String, String>{};

  /// A reference, written: its number, and an id that is its own.
  String reference(FootnoteRefNode node) {
    final key = LinkReferences.normalize(node.label);
    if (!_counts.containsKey(key)) {
      cited.add(key);
      _written[key] = node.label;
    }
    final count = _counts[key] = (_counts[key] ?? 0) + 1;
    final label = InlineHtml.escapeHref(_written[key]!);
    final number = cited.indexOf(key) + 1;
    final id = count == 1 ? 'fnref-$label' : 'fnref-$label-$count';
    return '<sup class="footnote-ref"><a href="#fn-$label" id="$id" '
        'data-footnote-ref>$number</a></sup>';
  }

  /// The links back from footnote [key] to each citation of it.
  String backrefs(String key) {
    final label = InlineHtml.escapeHref(_written[key]!);
    final number = cited.indexOf(key) + 1;
    final out = <String>[];
    for (var count = 1; count <= (_counts[key] ?? 0); count++) {
      final suffix = count == 1 ? '' : '-$count';
      final index = count == 1 ? '$number' : '$number-$count';
      final mark = count == 1 ? '↩' : '↩<sup class="footnote-ref">$count</sup>';
      out.add(
        '<a href="#fnref-$label$suffix" class="footnote-backref" '
        'data-footnote-backref data-footnote-backref-idx="$index" '
        'aria-label="Back to reference $index">$mark</a>',
      );
    }
    return out.join(' ');
  }

  /// The label footnote [key] is written with in its id.
  String idOf(String key) => InlineHtml.escapeHref(_written[key]!);
}
