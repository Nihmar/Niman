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
  /// Footnotes over [definitions], by normalized label; [xhtml] gives the
  /// attributes `cmark-gfm` writes bare a value, as XHTML has them.
  new(this.definitions, {this.xhtml = false});

  /// Whether attributes are written as XHTML has them.
  final bool xhtml;

  /// `cmark-gfm`'s bare attribute [name], as HTML or XHTML has it.
  String _flag(String name) => xhtml ? '$name=""' : name;

  /// The note's footnote definitions: the first of each label.
  final Map<String, FootnoteNode> definitions;

  /// The labels cited, normalized, in the order first cited.
  final List<String> cited = <String>[];

  /// How many times each label is cited.
  final Map<String, int> _counts = <String, int>{};

  /// The label each was first cited with, as written.
  final Map<String, String> _written = <String, String>{};

  /// Each label's number, its place in [cited] from one: a lookup, where
  /// `cited.indexOf` per citation made a note's export quadratic (#582).
  final Map<String, int> _numbers = <String, int>{};

  /// A reference, written: its number, and an id that is its own.
  String reference(FootnoteRefNode node) {
    final key = LinkReferences.normalize(node.label);
    if (!_counts.containsKey(key)) {
      cited.add(key);
      _written[key] = node.label;
      _numbers[key] = cited.length;
    }
    final count = _counts[key] = (_counts[key] ?? 0) + 1;
    final label = InlineHtml.escapeHref(_written[key]!);
    final number = _numbers[key]!;
    final id = count == 1 ? 'fnref-$label' : 'fnref-$label-$count';
    return '<sup class="footnote-ref"><a href="#fn-$label" id="$id" '
        '${_flag('data-footnote-ref')}>$number</a></sup>';
  }

  /// The links back from footnote [key] to each citation of it.
  String backrefs(String key) {
    final label = InlineHtml.escapeHref(_written[key]!);
    final number = _numbers[key]!;
    final out = <String>[];
    for (var count = 1; count <= (_counts[key] ?? 0); count++) {
      final suffix = count == 1 ? '' : '-$count';
      final index = count == 1 ? '$number' : '$number-$count';
      final mark = count == 1 ? '↩' : '↩<sup class="footnote-ref">$count</sup>';
      out.add(
        '<a href="#fnref-$label$suffix" class="footnote-backref" '
        '${_flag('data-footnote-backref')} '
        'data-footnote-backref-idx="$index" '
        'aria-label="Back to reference $index">$mark</a>',
      );
    }
    return out.join(' ');
  }

  /// Where a footnote's links back go in its body, while the body is
  /// written and the citations are not all counted: its last U+0000, the
  /// body's tail.
  static const String backrefsMark = '\u0000';

  /// The section the note ends with, listing the footnotes cited, each from
  /// its body in [bodies] (by normalized label) with its links back put in
  /// place; empty when none is cited.
  String section(Map<String, String> bodies) {
    if (cited.isEmpty) return '';
    final out = StringBuffer(
      '<section class="footnotes" '
      'data-footnotes${xhtml ? '=""' : ''}>\n<ol>\n',
    );
    for (final key in cited) {
      if (!definitions.containsKey(key)) continue;
      out.write('<li id="fn-${idOf(key)}">\n');
      final body = bodies[key]!;
      final tail = body.lastIndexOf(backrefsMark);
      out.write(body.replaceRange(tail, tail + 1, backrefs(key)));
      if (!body.endsWith('\n')) out.write('\n');
      out.write('</li>\n');
    }
    out.write('</ol>\n</section>\n');
    return out.toString();
  }

  /// The label footnote [key] is written with in its id.
  String idOf(String key) => InlineHtml.escapeHref(_written[key]!);
}
