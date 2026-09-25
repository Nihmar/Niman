/// A note as HTML (#24): the body of an exported page.
///
/// The note is parsed once, whole, by the Markdown package, so lists,
/// footnotes and link references read as a document's rather than a
/// block's. What that package does not know is set aside first, block by
/// block, by the read view's own rules:
///
/// * the blocks the read view draws itself — a fence, a math block, a raw
///   HTML block, a callout — become a token on a line of their own, and
///   their HTML goes in its place after the parse;
/// * inside every other block, the constructs `ExtensionMasker` finds — code
///   spans, formulas, wikilinks, embeds, tags — become tokens the same way,
///   so the package never reads the `_` in a formula as emphasis.
///
/// A token is a private-use pair around a number: plain text to the parser,
/// which passes it through untouched. In an element's content it becomes the
/// construct's HTML; in an attribute (a picture's alt text, a heading's id)
/// its plain text.
library;

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/export/html_blocks.dart';
import 'package:niman/src/export/html_spans.dart';
import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/inline_syntaxes.dart';
import 'package:niman/src/markdown/source_buffer.dart';

const String _open = '';
const String _close = '';
final RegExp _token = RegExp('$_open(\\d+)$_close');

/// A quote line's `>` markers, every level of them.
final RegExp _quoteMarks = RegExp('^((?: {0,3}> ?)+)');

/// One level of a quote's `>`.
final RegExp _quoteLevel = RegExp('^ {0,3}> ?');

/// GitHub's Markdown without its inline HTML: the read view shows a tag it
/// does not draw as the text it is, and so does the page — a note's `<b>`
/// is not markup it ever ran in the app.
final md.ExtensionSet _extensions = md.ExtensionSet(
  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
  [
    for (final syntax in md.ExtensionSet.gitHubFlavored.inlineSyntaxes)
      if (syntax is! md.InlineHtmlSyntax) syntax,
  ],
);

/// Builds one page's body.
final class NoteHtml {
  /// A builder over [source].
  new(this.source) : _math = MathSvg() {
    _spans = HtmlSpans(source, _math);
  }

  /// What the page is built from.
  final NoteHtmlSource source;

  final MathSvg _math;
  late final HtmlSpans _spans;
  final ExtensionMasker _masker = const ExtensionMasker();

  /// What each token stands for; a block's has no plain text.
  final List<HtmlSpan> _pieces = <HtmlSpan>[];

  /// The note's body as HTML.
  String body() => _render(source.text);

  /// The `@font-face` rules the body's formulas need, or null.
  String? get fontFaces => _math.fontFaces;

  String _render(String text) {
    final buffer = SourceBuffer.fromText(text);
    final lines = <String>[];
    for (final block in BlockScanner(buffer).index.blocks) {
      final raw = <String>[
        for (var line = block.startLine; line < block.endLine; line++)
          buffer.lineAt(line),
      ];
      lines.addAll(_lines(block.kind, raw));
    }
    final document = md.Document(
      extensionSet: _extensions,
      inlineSyntaxes: nimanInlineSyntaxes,
      blockSyntaxes: const [
        md.HeaderWithIdSyntax(),
        md.SetextHeaderWithIdSyntax(),
      ],
    );
    final nodes = document.parseLines(lines);
    _rewrite(nodes);
    return md.renderToHtml(nodes, enableTagfilter: true);
  }

  /// A block's lines as the parser is to see them.
  List<String> _lines(BlockKind kind, List<String> raw) => switch (kind) {
    BlockKind.frontmatter => const <String>[],
    BlockKind.blank || BlockKind.thematicBreak || BlockKind.indentedCode => raw,
    BlockKind.fencedCode => _block(raw, fencedCodeHtml(raw)),
    BlockKind.math => _block(raw, mathBlockHtml(raw.join('\n'), _math)),
    BlockKind.html => _block(raw, htmlSourceHtml(raw.join('\n'))),
    BlockKind.quote => _quote(raw),
    BlockKind.paragraph ||
    BlockKind.heading ||
    BlockKind.listItem ||
    BlockKind.table => _masked(raw.join('\n')).split('\n'),
  };

  /// A block drawn as [html], as a token on a line of its own at the
  /// block's indent — so a fence inside a list item stays inside it.
  List<String> _block(List<String> raw, String html) {
    final first = raw.isEmpty ? '' : raw.first;
    final indent = first.substring(0, first.length - first.trimLeft().length);
    return <String>['', '$indent${_tokenFor((html: html, plain: ''))}', ''];
  }

  /// A quote: a callout's frame around its body, or the quote with its
  /// constructs set aside under its `>` markers.
  List<String> _quote(List<String> raw) {
    final firstLevel = _quoteLevel.firstMatch(raw.first);
    final callout = firstLevel == null
        ? null
        : Callout.of(raw.first.substring(firstLevel.end));
    if (callout != null) {
      final inner = [
        for (final line in raw.skip(1)) line.replaceFirst(_quoteLevel, ''),
      ].join('\n');
      return _block(raw, calloutHtml(callout, _render(inner)));
    }
    final marks = [
      for (final line in raw) _quoteMarks.firstMatch(line)?.group(1) ?? '',
    ];
    final content = [
      for (var at = 0; at < raw.length; at++)
        raw[at].substring(marks[at].length),
    ].join('\n');
    // A construct running over a line break joins the lines it spans, so
    // there can be fewer lines than marks; they are all a quote's marks.
    final masked = _masked(content).split('\n');
    return <String>[
      for (var at = 0; at < masked.length; at++)
        '${marks[at < marks.length ? at : marks.length - 1]}${masked[at]}',
    ];
  }

  /// [text] with the constructs the read view draws itself replaced by
  /// tokens.
  String _masked(String text) {
    final spans = _masker.mask(text).spans;
    if (spans.isEmpty) return text;
    final out = StringBuffer();
    var at = 0;
    for (final span in spans) {
      out
        ..write(text.substring(at, span.start))
        ..write(_tokenFor(_spans.render(span)));
      at = span.end;
    }
    out.write(text.substring(at));
    return out.toString();
  }

  String _tokenFor(HtmlSpan piece) {
    _pieces.add(piece);
    return '$_open${_pieces.length - 1}$_close';
  }

  /// Puts the pieces back, and points pictures and links where the page
  /// needs them.
  void _rewrite(List<md.Node> nodes) {
    for (var at = 0; at < nodes.length; at++) {
      final node = nodes[at];
      if (node is md.Text) {
        nodes[at] = md.Text(_content(node.text));
        continue;
      }
      if (node is! md.Element) continue;
      // A block's token alone in a paragraph: the block, unwrapped.
      final only = _onlyToken(node);
      if (only != null) {
        nodes[at] = md.Text(only);
        continue;
      }
      node.attributes.updateAll((_, value) => _attribute(value));
      // A task's box shows its state; a page has nothing to tick it for.
      if (node.tag == 'input') node.attributes['disabled'] = '';
      if (node.tag == 'img') _repoint(node, 'src', source.images);
      if (node.tag == 'a') _repoint(node, 'href', source.links);
      final children = node.children;
      if (children != null) _rewrite(children);
    }
  }

  /// The HTML of the block whose token is all [element] holds, when it is
  /// a paragraph holding one; null otherwise.
  String? _onlyToken(md.Element element) {
    if (element.tag != 'p') return null;
    final children = element.children;
    if (children == null || children.length != 1) return null;
    final child = children.single;
    if (child is! md.Text) return null;
    final match = _token.firstMatch(child.text.trim());
    if (match == null || match.group(0) != child.text.trim()) return null;
    final piece = _pieces[int.parse(match.group(1)!)];
    return piece.plain.isEmpty ? piece.html : null;
  }

  String _content(String text) => text.replaceAllMapped(
    _token,
    (match) => _pieces[int.parse(match.group(1)!)].html,
  );

  String _attribute(String value) => value.replaceAllMapped(
    _token,
    (match) => escapeAttribute(_pieces[int.parse(match.group(1)!)].plain),
  );

  /// Points [element]'s [attribute] at what [targets] has for it, as written
  /// or as the parser percent-encoded it.
  static void _repoint(
    md.Element element,
    String attribute,
    Map<String, String> targets,
  ) {
    final written = element.attributes[attribute];
    if (written == null) return;
    var target = targets[written];
    if (target == null) {
      try {
        target = targets[Uri.decodeFull(written)];
      } on FormatException {
        return;
      }
    }
    if (target != null) element.attributes[attribute] = target;
  }
}
