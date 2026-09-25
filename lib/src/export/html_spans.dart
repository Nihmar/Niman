/// Niman's own inline constructs on an exported page (#24): what the read
/// view draws a code span, a formula, a wikilink, an embed and a tag as.
///
/// They are found by the preview's own rule (`ExtensionMasker`), never by a
/// second one, so the page and the note agree on where each one is.
library;

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/extension_span.dart';

/// One construct as HTML, and as the plain text an attribute can hold.
typedef HtmlSpan = ({String html, String plain});

/// Draws the constructs of one page.
final class HtmlSpans {
  /// Spans of the page built from [source], formulas through [math].
  const new(this.source, this.math);

  /// What the page is built from: its pictures and its links.
  final NoteHtmlSource source;

  /// The page's formula renderer.
  final MathSvg math;

  /// [span] on the page.
  HtmlSpan render(ExtensionSpan span) => switch (span.kind) {
    ExtensionKind.codeSpan => (
      html: '<code>${escapeHtml(_codeContent(span.text))}</code>',
      plain: _codeContent(span.text),
    ),
    ExtensionKind.inlineMath => _math(span.inner, span.text, display: false),
    // `$$…$$` sharing a line with prose: set in the line, as the read view
    // sets it.
    ExtensionKind.displayMath => _math(span.inner, span.text, display: true),
    ExtensionKind.wikilink => _wikilink(span.inner),
    ExtensionKind.embed => _embed(span.inner),
    ExtensionKind.tag => (
      html: '<span class="tag">${escapeHtml(span.text)}</span>',
      plain: span.text,
    ),
  };

  HtmlSpan _math(String tex, String written, {required bool display}) {
    final svg = math.render(tex.trim(), display: display);
    return (
      html: svg ?? '<code class="math-source">${escapeHtml(written)}</code>',
      plain: written,
    );
  }

  HtmlSpan _wikilink(String inner) {
    final ref = parseWikiRef(inner);
    final plain = wikiDisplayText(inner);
    final shown = escapeHtml(plain);
    final href = source.links[ref.target];
    if (href == null) {
      return (html: '<span class="wikilink">$shown</span>', plain: plain);
    }
    final heading = ref.heading;
    final anchor = heading == null ? '' : '#${headingAnchor(heading)}';
    return (
      html:
          '<a class="wikilink" href="${escapeAttribute('$href$anchor')}">'
          '$shown</a>',
      plain: plain,
    );
  }

  HtmlSpan _embed(String inner) {
    final ref = parseWikiRef(inner);
    final pipe = inner.indexOf('|');
    final shown = (pipe >= 0 ? inner.substring(pipe + 1) : inner).trim();
    final data = source.images[ref.target];
    if (data == null) {
      // What the read view shows for an embed it cannot draw.
      final written = '![[${pipe >= 0 ? shown : inner}]]';
      return (
        html: '<span class="embed">${escapeHtml(written)}</span>',
        plain: written,
      );
    }
    return (
      html: '<img class="embed" src="$data" alt="${escapeAttribute(shown)}">',
      plain: shown,
    );
  }
}

/// The `id` a heading reading [text] gets on the page: the Markdown
/// package's own rule, so `[[Note#Part]]` lands on `Part`.
String headingAnchor(String text) =>
    md.BlockSyntax.generateAnchorHash(md.Element('h1', [md.Text(text)]));

/// A code span's content: its backtick runs off, and one space off each end
/// when both ends have one and it is not all spaces (CommonMark 6.1).
String _codeContent(String written) {
  var run = 0;
  while (run < written.length && written.codeUnitAt(run) == 0x60) {
    run++;
  }
  var content = written.substring(run, written.length - run);
  content = content.replaceAll('\n', ' ');
  if (content.length >= 2 &&
      content.startsWith(' ') &&
      content.endsWith(' ') &&
      content.trim().isNotEmpty) {
    content = content.substring(1, content.length - 1);
  }
  return content;
}
