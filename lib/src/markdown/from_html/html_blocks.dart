/// The blocks of a page as Markdown: headings, paragraphs, lists, quotes,
/// code, tables.
library;

import 'package:html/dom.dart';
import 'package:niman/src/markdown/from_html/block_context.dart';
import 'package:niman/src/markdown/from_html/html_inline.dart';
import 'package:niman/src/markdown/from_html/html_table.dart';
import 'package:niman/src/markdown/from_html/markdown_blocks.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// Writes the blocks of a page, one conversion at a time.
final class HtmlBlocks {
  /// A block writer that sets inline content with [inline]; with
  /// [breaksAsParagraphs] the lines of a paragraph, cut at its `<br>`s, are
  /// paragraphs of their own.
  const new(this.inline, {this.breaksAsParagraphs = false});

  /// The writer of inline content.
  final HtmlInline inline;

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
        out.add(context.wrap('$fence\n${code.trimRight()}\n$fence'));
      case 'div' when element.attributes.containsKey('data-mermaid'):
        // A diagram Niman exported: its fence, not its drawing (#530).
        final source = element.attributes['data-mermaid']!.trimRight();
        final fence = source.contains('```') ? '~~~~' : '```';
        out.add(context.wrap('${fence}mermaid\n$source\n$fence'));
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
      if (item.localName != 'li') continue;
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
      out.add(
        context.wrap(
          '$marker${text.isEmpty ? '' : escapeMarkdownLineStart(text)}',
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
