/// A chapter of an EPUB, from its XHTML to the Markdown the read view draws.
///
/// The book is set in the app's own typography: what is kept is its
/// structure — headings, paragraphs, emphasis, lists, quotes, code, tables,
/// pictures, links — and its CSS is not read at all. Every character of the
/// book's text is escaped where Markdown or the app's own extensions would
/// read it as syntax (`#tag`, `$math$`, `[[link]]`, `*`, `|`…), so a book is
/// only ever the words it has.
library;

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/markdown/text_escape.dart';

/// What a chapter came to: its Markdown, and where in it each element
/// with an `id` begins — as a line of the Markdown — for the links that
/// point into the chapter.
typedef ChapterMarkdown = ({String markdown, Map<String, int> anchors});

/// Converts one chapter's XHTML.
///
/// [picture] names a picture by its `src` as the chapter wrote it, for
/// the Markdown image to point at (the reader resolves the name); null
/// leaves the picture out. [link] does the same for a link's `href`.
final class XhtmlMarkdown {
  /// A converter with the book's own ways to name pictures and links.
  const new({required this.picture, required this.link});

  /// The name a picture's `src` is written under, or null to leave it out.
  final String? Function(String src) picture;

  /// The target a link's `href` is written under.
  final String Function(String href) link;

  /// The Markdown of the chapter [xhtml].
  ChapterMarkdown convert(String xhtml) {
    final document = html.parse(xhtml);
    final body = document.body ?? document.documentElement;
    final out = _Blocks();
    if (body != null) _blocks(body, out, const _Context());
    return (markdown: out.text, anchors: out.anchors);
  }

  /// The blocks under [parent], in order.
  void _blocks(Element parent, _Blocks out, _Context context) {
    // Inline content between block elements is a paragraph of its own.
    final inline = <Node>[];
    void flush() {
      if (inline.isEmpty) return;
      final text = _inlineOf(inline).trim();
      inline.clear();
      if (text.isNotEmpty) out.add(context.wrap(escapeMarkdownLineStart(text)));
    }

    for (final node in parent.nodes) {
      if (node is Element && _isBlock(node)) {
        flush();
        _block(node, out, context);
      } else {
        inline.add(node);
      }
    }
    flush();
  }

  void _block(Element element, _Blocks out, _Context context) {
    final id = element.id;
    if (id.isNotEmpty) out.anchor(id);
    final tag = element.localName ?? '';
    switch (tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        final text = _inlineOf(element.nodes).trim();
        _anchorsWithin(element, out);
        if (text.isEmpty) return;
        final level = int.parse(tag.substring(1));
        out.add(context.wrap('${'#' * level} $text'));
      case 'p':
        _anchorsWithin(element, out);
        final text = _inlineOf(element.nodes).trim();
        if (text.isNotEmpty) {
          out.add(context.wrap(escapeMarkdownLineStart(text)));
        }
      case 'blockquote':
        _blocks(element, out, context.quoted());
      case 'ul' || 'ol':
        _list(element, out, context, ordered: tag == 'ol');
      case 'pre':
        _anchorsWithin(element, out);
        final code = element.text.replaceAll('\r\n', '\n');
        final fence = code.contains('```') ? '~~~~' : '```';
        out.add(context.wrap('$fence\n${code.trimRight()}\n$fence'));
      case 'hr':
        out.add(context.wrap('---'));
      case 'table':
        _anchorsWithin(element, out);
        final table = _table(element);
        if (table != null) out.add(context.wrap(table));
      default:
        // A container — section, div, figure, article, aside…: its blocks.
        _blocks(element, out, context);
    }
  }

  /// Records the ids of the elements inside [element], which a link may
  /// point at, at the line the block starts on.
  void _anchorsWithin(Element element, _Blocks out) {
    for (final inner in element.querySelectorAll('[id]')) {
      out.anchor(inner.id);
    }
  }

  void _list(
    Element list,
    _Blocks out,
    _Context context, {
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
      final text = _inlineOf(_flatten(words)).trim();
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

  String? _table(Element table) {
    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return null;
    final cells = [
      for (final row in rows)
        [
          for (final cell in row.children)
            if (cell.localName == 'td' || cell.localName == 'th')
              // One line a row: a break in a cell is a space. (Its `|`s
              // are escaped with the rest of the text.)
              _inlineOf(cell.nodes).replaceAll('\\\n', ' ').trim(),
        ],
    ];
    final width = cells.fold<int>(0, (w, r) => r.length > w ? r.length : w);
    if (width == 0) return null;
    String row(List<String> r) =>
        '| ${[...r, for (var i = r.length; i < width; i++) ''].join(' | ')} |';
    return [
      row(cells.first),
      '|${List.filled(width, ' --- ').join('|')}|',
      for (final r in cells.skip(1)) row(r),
    ].join('\n');
  }

  String? _pictureOf(Element element) {
    final img = element.localName == 'svg'
        ? element.querySelector('image')
        : element;
    if (img == null) return null;
    final src =
        img.attributes['src'] ??
        _attribute(img, 'xlink:href') ??
        img.attributes['href'];
    if (src == null || src.isEmpty) return null;
    final name = picture(src);
    if (name == null) return null;
    final alt = escapeMarkdownText(_collapse(img.attributes['alt'] ?? ''));
    return '![$alt]($name)';
  }

  /// The TeX a formula's SVG carries in its `aria-label`, as the app's own
  /// math syntax: `$…$` in the line, `$$…$$` for a display formula (the
  /// SVG's `math-display` class). Null when the SVG is not a formula — a
  /// picture's, or one with no source to set again.
  ///
  /// Niman's own exports set every formula that way (#303), and the read
  /// view typesets the TeX itself rather than drawing another page's SVG.
  static String? _mathOf(Element element) {
    if (element.localName != 'svg') return null;
    final tex = element.attributes['aria-label']?.trim();
    if (tex == null || tex.isEmpty) return null;
    // A `$` inside the TeX would end the span it is written in.
    final escaped = tex.replaceAllMapped(
      RegExp(r'(?<!\\)\$'),
      (match) => r'\$',
    );
    // One `$` in the line, two on a line of its own for a display formula.
    final sign = element.classes.contains('math-display') ? r'$$' : r'$';
    return '$sign$escaped$sign';
  }

  /// [element]'s attribute [name], looked up by how it prints: inside an
  /// SVG the parser keys `xlink:href` by an `AttributeName`, not a string.
  static String? _attribute(Element element, String name) => element
      .attributes
      .entries
      .where((entry) => entry.key.toString() == name)
      .firstOrNull
      ?.value;

  /// The inline Markdown of [nodes].
  String _inlineOf(List<Node> nodes) {
    final out = StringBuffer();
    for (final node in nodes) {
      _inline(node, out);
    }
    return out.toString().replaceAll(RegExp(r'[ \t]+'), ' ');
  }

  void _inline(Node node, StringBuffer out) {
    if (node is Text) {
      out.write(escapeMarkdownText(_collapse(node.text)));
      return;
    }
    if (node is! Element) return;
    String inner() => _inlineOf(node.nodes);
    switch (node.localName) {
      case 'em' || 'i' || 'cite' || 'dfn' || 'var':
        _wrapped(out, inner(), '*');
      case 'strong' || 'b':
        _wrapped(out, inner(), '**');
      case 's' || 'del' || 'strike':
        _wrapped(out, inner(), '~~');
      case 'code' || 'kbd' || 'samp' || 'tt':
        final code = _collapse(node.text);
        if (code.trim().isEmpty) return;
        final fence = code.contains('`') ? '``' : '`';
        out.write('$fence${code.contains('`') ? ' $code ' : code}$fence');
      case 'br':
        out.write('\\\n');
      case 'a':
        final text = inner();
        final href = node.attributes['href'];
        if (href == null || href.isEmpty || text.trim().isEmpty) {
          out.write(text);
          return;
        }
        out.write('[$text](<${link(href)}>)');
      case 'img' || 'image' || 'svg':
        final math = _mathOf(node);
        if (math != null) {
          out.write(math);
          return;
        }
        final picture = _pictureOf(node);
        if (picture != null) out.write(picture);
      case 'script' || 'style' || 'head':
        return;
      default:
        out.write(inner());
    }
  }

  /// [text] between [marker]s, the blank space at its ends kept outside:
  /// `* word*` is no emphasis.
  static void _wrapped(StringBuffer out, String text, String marker) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      out.write(text);
      return;
    }
    if (text.startsWith(' ')) out.write(' ');
    out.write('$marker$trimmed$marker');
    if (text.endsWith(' ')) out.write(' ');
  }

  /// Runs of blank space as one space, as a browser shows them.
  static String _collapse(String text) => text.replaceAll(_blank, ' ');

  static final RegExp _blank = RegExp(r'\s+');

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

/// Where a block goes: inside how many quotes, indented how far.
final class _Context {
  const new({this.quotes = 0, this.indent = 0});

  final int quotes;

  final int indent;

  _Context quoted() => _Context(quotes: quotes + 1, indent: indent);

  _Context indented(int by) => _Context(quotes: quotes, indent: indent + by);

  /// [block] with this context's quote marks and indent on every line.
  String wrap(String block) {
    if (quotes == 0 && indent == 0) return block;
    final prefix = '${'> ' * quotes}${' ' * indent}';
    return block.split('\n').map((line) => '$prefix$line').join('\n');
  }
}

/// The chapter's blocks as they come, with the line each one starts on.
final class _Blocks {
  final StringBuffer _out = StringBuffer();
  int _line = 0;
  final List<String> _pending = <String>[];

  /// Where each element with an id begins.
  final Map<String, int> anchors = <String, int>{};

  /// The Markdown so far.
  String get text => _out.toString();

  /// Adds [block], a blank line from the one before it.
  void add(String block) {
    if (_out.isNotEmpty) {
      _out.write('\n\n');
      _line += 2;
    }
    for (final id in _pending) {
      anchors[id] = _line;
    }
    _pending.clear();
    _out.write(block);
    _line += '\n'.allMatches(block).length;
  }

  /// Notes [id] as starting where the next block does.
  void anchor(String id) {
    if (!anchors.containsKey(id)) _pending.add(id);
  }
}
