/// Niman's own inline constructs on an exported page (#24): what the read
/// view draws a formula, a wikilink, an embed and a tag as.
///
/// They are found by the read view's own parser, never by a second rule,
/// so the page and the note agree on where each one is.
library;

import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/links/parser.dart';

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

  /// A tag, `#` and all, as [written].
  HtmlSpan tag(String written) =>
      (html: '<span class="tag">${escapeHtml(written)}</span>', plain: written);

  /// A formula of [tex], [written] with its dollars; [display] for `$$…$$`
  /// sharing a line with prose, set in the line as the read view sets it.
  HtmlSpan formula(String tex, String written, {required bool display}) {
    final svg = math.render(tex.trim(), display: display);
    return (
      html: svg ?? '<code class="math-source">${escapeHtml(written)}</code>',
      plain: written,
    );
  }

  /// A wikilink whose inside is [inner].
  HtmlSpan wikilink(String inner) {
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

  /// An embed whose inside is [inner].
  HtmlSpan embed(String inner) {
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
      html: '<img class="embed" src="$data" alt="${escapeAttribute(shown)}" />',
      plain: shown,
    );
  }
}

/// The `id` a heading reading [text], as written, gets on the page, so
/// `[[Note#Part]]` lands on `Part`: lowercased, all but `a`-`z`, digits,
/// `_`, `-` and spaces taken out, each space a `-` — the rule pages exported
/// before kept (`package:markdown`'s), so their links still land.
String headingAnchor(String text) => text
    .toLowerCase()
    .trim()
    .replaceAll(_notInAnchor, '')
    .replaceAll(_space, '-');

final RegExp _notInAnchor = RegExp('[^a-z0-9 _-]');
final RegExp _space = RegExp(r'\s');
