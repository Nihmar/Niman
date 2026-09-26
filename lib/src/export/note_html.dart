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

/// A local Markdown note link's path, a `#` fragment or `?` query aside.
final RegExp _noteHref = RegExp(r'\.md(?:[#?].*)?$');

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
    final nodes = _parsed(text);
    _rewrite(nodes);
    return md.renderToHtml(nodes, enableTagfilter: true);
  }

  /// The `src` of every picture the page will draw, as the parser writes
  /// them: what an export resolves before the page is built (#24). Nothing
  /// is typeset for it — the tokens are placeholders.
  List<String> imageTargets() {
    final nodes = _parsed(source.text, rendered: false);
    final out = <String>[];
    void walk(List<md.Node> nodes) {
      for (final node in nodes) {
        if (node is! md.Element) continue;
        if (node.tag == 'img') {
          final src = node.attributes['src'];
          if (src != null && src.isNotEmpty) out.add(src);
        }
        final children = node.children;
        if (children != null) walk(children);
      }
    }

    walk(nodes);
    return out;
  }

  /// The note's lines as one document, the constructs masked into tokens.
  ///
  /// With [rendered] false the pieces are empty placeholders: the parse is
  /// for collecting what the page needs ([imageTargets]), so no formula or
  /// code block is typeset.
  List<md.Node> _parsed(String text, {bool rendered = true}) {
    // The sentinels are private-use characters the *note* may hold too:
    // escaped into pieces of their own, they can never read as a token
    // that indexes into a piece list they do not belong to.
    final buffer = SourceBuffer.fromText(_escapeSentinels(text));
    final lines = <String>[];
    for (final block in BlockScanner(buffer).index.blocks) {
      final raw = <String>[
        for (var line = block.startLine; line < block.endLine; line++)
          buffer.lineAt(line),
      ];
      lines.addAll(_lines(block.kind, raw, rendered: rendered));
    }
    final document = md.Document(
      extensionSet: _extensions,
      inlineSyntaxes: nimanInlineSyntaxes,
      blockSyntaxes: const [
        md.HeaderWithIdSyntax(),
        md.SetextHeaderWithIdSyntax(),
      ],
    );
    return document.parseLines(lines);
  }

  /// A block's lines as the parser is to see them.
  List<String> _lines(
    BlockKind kind,
    List<String> raw, {
    required bool rendered,
  }) => switch (kind) {
    BlockKind.frontmatter => const <String>[],
    BlockKind.blank || BlockKind.thematicBreak || BlockKind.indentedCode => raw,
    BlockKind.fencedCode => _block(raw, rendered ? fencedCodeHtml(raw) : ''),
    BlockKind.math => _block(
      raw,
      rendered ? mathBlockHtml(raw.join('\n'), _math) : '',
    ),
    BlockKind.html => _block(
      raw,
      rendered ? htmlSourceHtml(raw.join('\n')) : '',
    ),
    BlockKind.quote => _quote(raw, rendered: rendered),
    BlockKind.paragraph ||
    BlockKind.heading ||
    BlockKind.listItem ||
    BlockKind.table => _masked(raw.join('\n'), rendered: rendered).split('\n'),
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
  List<String> _quote(List<String> raw, {required bool rendered}) {
    final firstLevel = _quoteLevel.firstMatch(raw.first);
    final callout = firstLevel == null
        ? null
        : Callout.of(raw.first.substring(firstLevel.end));
    if (callout != null) {
      final inner = [
        for (final line in raw.skip(1)) line.replaceFirst(_quoteLevel, ''),
      ].join('\n');
      return _block(raw, rendered ? calloutHtml(callout, _render(inner)) : '');
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
    final masked = _masked(content, rendered: rendered).split('\n');
    return <String>[
      for (var at = 0; at < masked.length; at++)
        '${marks[at < marks.length ? at : marks.length - 1]}${masked[at]}',
    ];
  }

  /// [text] with the constructs the read view draws itself replaced by
  /// tokens.
  String _masked(String text, {required bool rendered}) {
    final spans = _masker.mask(text).spans;
    if (spans.isEmpty) return text;
    final out = StringBuffer();
    var at = 0;
    for (final span in spans) {
      out
        ..write(text.substring(at, span.start))
        ..write(
          _tokenFor(rendered ? _spans.render(span) : (html: '', plain: '')),
        );
      at = span.end;
    }
    out.write(text.substring(at));
    return out.toString();
  }

  /// [text] with the token sentinels it literally holds replaced by tokens
  /// that give them back as the characters they are.
  String _escapeSentinels(String text) {
    if (!text.contains(_open) && !text.contains(_close)) return text;
    final out = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (char == _open || char == _close) {
        out.write(_tokenFor((html: escapeHtml(char), plain: char)));
      } else {
        out.write(char);
      }
    }
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
      if (node.tag == 'a' &&
          !_repoint(node, 'href', source.links) &&
          _isNoteLink(node.attributes['href'])) {
        // A Markdown link to a note the page has no target for shows the
        // text it wrote, as a wikilink does: `[x](other.md)` on a one-note
        // export pointed at a file the page does not carry (E4).
        final replacement = md.Element('span', node.children);
        nodes[at] = replacement;
        final replacementChildren = replacement.children;
        if (replacementChildren != null) _rewrite(replacementChildren);
        continue;
      }
      final children = node.children;
      if (children != null) _rewrite(children);
    }
  }

  /// A paragraph's token alone in it: the block, unwrapped; null when the
  /// text only looks like one.
  String? _onlyToken(md.Element element) {
    if (element.tag != 'p') return null;
    final children = element.children;
    if (children == null || children.length != 1) return null;
    final child = children.single;
    if (child is! md.Text) return null;
    final match = _token.firstMatch(child.text.trim());
    if (match == null || match.group(0) != child.text.trim()) return null;
    final piece = _pieceOf(match.group(1)!);
    if (piece == null) return null;
    return piece.plain.isEmpty ? piece.html : null;
  }

  /// The piece a token's number names, or null when it names none: the
  /// note's own text may hold the sentinel pair, and that is text, not a
  /// construct of ours.
  HtmlSpan? _pieceOf(String number) {
    final at = int.tryParse(number);
    if (at == null || at < 0 || at >= _pieces.length) return null;
    return _pieces[at];
  }

  String _content(String text) => text.replaceAllMapped(_token, (match) {
    final piece = _pieceOf(match.group(1)!);
    return piece?.html ?? match.group(0)!;
  });

  String _attribute(String value) => value.replaceAllMapped(_token, (match) {
    final piece = _pieceOf(match.group(1)!);
    return piece == null ? match.group(0)! : escapeAttribute(piece.plain);
  });

  /// Points [element]'s [attribute] at what [targets] has for it, as written
  /// or as the parser percent-encoded it; false when there is no target.
  static bool _repoint(
    md.Element element,
    String attribute,
    Map<String, String> targets,
  ) {
    final written = element.attributes[attribute];
    if (written == null) return false;
    var target = targets[written];
    if (target == null) {
      try {
        target = targets[Uri.decodeFull(written)];
      } on FormatException {
        return false;
      }
    }
    if (target == null) return false;
    element.attributes[attribute] = target;
    return true;
  }

  /// Whether [href] names a local Markdown note, by its path; a fragment or
  /// a query does not change that, and an absolute URL is not one.
  static bool _isNoteLink(String? href) {
    if (href == null || href.isEmpty) return false;
    final lower = href.toLowerCase();
    if (lower.startsWith('#') ||
        lower.startsWith('mailto:') ||
        lower.startsWith('data:') ||
        lower.contains('://')) {
      return false;
    }
    return _noteHref.hasMatch(lower);
  }
}
