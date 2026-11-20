/// The blocks of a page as Markdown: headings, paragraphs, lists, quotes,
/// code, tables.
library;

import 'package:html/dom.dart';
import 'package:niman/src/markdown/from_html/block_context.dart';
import 'package:niman/src/markdown/from_html/html_code_language.dart';
import 'package:niman/src/markdown/from_html/html_footnotes.dart';
import 'package:niman/src/markdown/from_html/html_inline.dart';
import 'package:niman/src/markdown/from_html/html_table.dart';
import 'package:niman/src/markdown/from_html/markdown_blocks.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// Writes the blocks of a page, one conversion at a time.
final class HtmlBlocks {
  /// A block writer that sets inline content with [inline]; with
  /// [breaksAsParagraphs] the lines of a paragraph, cut at its `<br>`s, are
  /// paragraphs of their own.
  const new(this.inline, this.footnotes, {this.breaksAsParagraphs = false});

  /// The writer of inline content.
  final HtmlInline inline;

  /// The page's footnotes: not written where they stand.
  final HtmlFootnotes footnotes;

  /// Whether a `<br>` between two lines of a paragraph ends the paragraph.
  final bool breaksAsParagraphs;

  /// The blocks of [nodes], in order.
  void walk(Iterable<Node> nodes, MarkdownBlocks out, BlockContext context) {
    // Inline content between block elements is a paragraph of its own.
    final run = <Node>[];
    void flush() {
      if (run.isEmpty) return;
      _paragraphs(run, out, context);
      run.clear();
    }

    for (final node in nodes) {
      if (node is Element && _isBlock(node)) {
        flush();
        _block(node, out, context);
      } else {
        run.add(node);
      }
    }
    flush();
  }

  void _block(Element element, MarkdownBlocks out, BlockContext context) {
    if (footnotes.isNote(element)) return;
    final id = element.id;
    if (id.isNotEmpty) out.anchor(id);
    final tag = element.localName ?? '';
    switch (tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        final text = inline.of(element.nodes).trim();
        _anchorsWithin(element, out);
        if (text.isEmpty) return;
        final level = int.parse(tag.substring(1));
        out.add(context.wrap('${'#' * level} $text'));
      case 'p':
        _anchorsWithin(element, out);
        _paragraphs(element.nodes, out, context);
      case 'blockquote':
        walk(element.nodes, out, context.quoted());
      case 'ul' || 'ol':
        _list(element, out, context, ordered: tag == 'ol');
      case 'pre':
        _anchorsWithin(element, out);
        final code = element.text.replaceAll('\r\n', '\n');
        final fence = code.contains('```') ? '~~~~' : '```';
        final language = HtmlCodeLanguage.of(element);
        out.add(context.wrap('$fence$language\n${code.trimRight()}\n$fence'));
      case 'div' when element.attributes.containsKey('data-mermaid'):
        // A diagram Niman exported: its fence, not its drawing (#530).
        final source = element.attributes['data-mermaid']!.trimRight();
        final fence = source.contains('```') ? '~~~~' : '```';
        out.add(context.wrap('${fence}mermaid\n$source\n$fence'));
      case 'dt':
        // The app has no list of terms: a term is a bold paragraph, and its
        // `dd`s, blocks like any, come after it.
        _anchorsWithin(element, out);
        final text = inline.of(element.nodes).trim();
        if (text.isNotEmpty) out.add(context.wrap(_bold(element, text)));
      case 'details':
        _details(element, out, context);
      case 'hr':
        out.add(context.wrap('---'));
      case 'table':
        _anchorsWithin(element, out);
        final table = HtmlTable(inline).of(element);
        if (table != null) out.add(context.wrap(table));
      default:
        // A container — section, div, figure, article, aside…: its blocks.
        walk(element.nodes, out, context);
    }
  }

  /// [text], [element]'s words, in bold, unless they are already.
  static String _bold(Element element, String text) {
    final only = element.children.length == 1 ? element.children.first : null;
    final strong =
        only != null &&
        (only.localName == 'strong' || only.localName == 'b') &&
        only.text.trim() == element.text.trim();
    return strong ? text : '**$text**';
  }

  /// A `<details>` as a callout that folds, closed unless the page opens
  /// it, its `<summary>` the title and the rest of it the body.
  void _details(Element element, MarkdownBlocks out, BlockContext context) {
    final summary = element.children
        .where((child) => child.localName == 'summary')
        .firstOrNull;
    // The title is read first: a footnote it cites comes before the body's.
    final title = summary == null
        ? 'Details'
        : inline.of(summary.nodes).replaceAll('\\\n', ' ').trim();
    final body = MarkdownBlocks();
    walk(
      element.nodes.where((node) => node != summary),
      body,
      const BlockContext(),
    );
    if (title.isEmpty && body.text.isEmpty) return;
    // Niman's own export names the callout's type on its `<details>`.
    final written = element.attributes['data-callout'] ?? '';
    final type = _calloutType.hasMatch(written) ? written : 'note';
    final fold = element.attributes.containsKey('open') ? '+' : '-';
    final head = '[!$type]$fold${title.isEmpty ? '' : ' $title'}';
    final lines = [head, if (body.text.isNotEmpty) ...body.text.split('\n')];
    // The callout is one quote: its blank lines carry the `>` too.
    out.addHolding(
      context.wrap(
        lines.map((line) => line.isEmpty ? '>' : '> $line').join('\n'),
      ),
      body,
      lineOffset: 1,
    );
  }

  static final RegExp _calloutType = RegExp(r'^[A-Za-z][\w-]*$');

  /// The notes the page cites and the ones it does not, each as a block of
  /// its own: `[^n]: text`, the paragraphs of a note run into one line.
  void writeFootnotes(MarkdownBlocks out) {
    footnotes
        .definitions((note) => inline.of(_flatten(note.nodes)).trim())
        .forEach(out.add);
  }

  /// The paragraphs of the inline content [nodes].
  void _paragraphs(List<Node> nodes, MarkdownBlocks out, BlockContext context) {
    for (final text in inline.paragraphsOf(
      nodes,
      splitAtBreaks: breaksAsParagraphs,
    )) {
      out.add(context.wrap(escapeMarkdownLineStart(text)));
    }
  }

  /// Records the ids of the elements inside [element], which a link may
  /// point at, at the line the block starts on.
  void _anchorsWithin(Element element, MarkdownBlocks out) {
    for (final inner in element.querySelectorAll('[id]')) {
      out.anchor(inner.id);
    }
  }

  void _list(
    Element list,
    MarkdownBlocks out,
    BlockContext context, {
    required bool ordered,
  }) {
    var number = int.tryParse(list.attributes['start'] ?? '') ?? 1;
    for (final item in list.children) {
      if (item.localName != 'li' || footnotes.isNote(item)) continue;
      if (item.id.isNotEmpty) out.anchor(item.id);
      _anchorsWithin(item, out);
      final marker = ordered ? '${number++}. ' : '- ';
      // The item's own words, then the lists nested in it, indented to its
      // text so they stay inside it.
      final words = <Node>[
        for (final node in item.nodes)
          if (!(node is Element && _isList(node))) node,
      ];
      final text = inline.of(_flatten(words)).trim();
      // A checkbox the item opens with is a task's box.
      final box = _checkboxOf(item);
      final task = box == null
          ? ''
          : box.attributes.containsKey('checked')
          ? '[x]'
          : '[ ]';
      final body = text.isEmpty ? '' : escapeMarkdownLineStart(text);
      out.add(
        context.wrap(
          '$marker${task.isEmpty || body.isEmpty ? task : '$task '}$body',
        ),
      );
      for (final nested in item.children.where(_isList)) {
        _list(
          nested,
          out,
          context.indented(marker.length),
          ordered: nested.localName == 'ol',
        );
      }
    }
  }

  /// The checkbox [item] opens with — GFM's `<li><input type="checkbox">`,
  /// as Niman's export writes it, or one in a leading paragraph or label —
  /// or null when it opens with something else.
  static Element? _checkboxOf(Element item) {
    Node? first(List<Node> nodes) => nodes
        .where(
          (node) =>
              !(node is Text && node.text.trim().isEmpty) && node is! Comment,
        )
        .firstOrNull;
    var node = first(item.nodes);
    while (node is Element) {
      if (node.localName == 'input') {
        return node.attributes['type']?.toLowerCase() == 'checkbox'
            ? node
            : null;
      }
      if (!_boxHolders.contains(node.localName)) return null;
      node = first(node.nodes);
    }
    return null;
  }

  static const Set<String> _boxHolders = {'p', 'label', 'span', 'div'};

  /// [nodes], with the paragraphs inside a list item run into one line.
  List<Node> _flatten(List<Node> nodes) => [
    for (final node in nodes)
      if (node is Element && _isBlock(node)) ...[
        ...node.nodes,
        Text(' '),
      ] else
        node,
  ];

  static bool _isList(Element element) =>
      element.localName == 'ul' || element.localName == 'ol';

  static bool _isBlock(Element element) =>
      _blockTags.contains(element.localName);

  static const Set<String> _blockTags = {
    'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'ul', 'ol', //
    'pre', 'hr', 'table', 'div', 'section', 'article', 'aside', 'header',
    'footer', 'nav', 'main', 'figure', 'figcaption', 'dl', 'dt', 'dd',
    'address', 'details', 'summary',
  };
}
