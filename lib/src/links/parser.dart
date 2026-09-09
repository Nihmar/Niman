/// Wikilink and Markdown link parsing (design.md: links/parser.dart).
///
/// The parser is a *reader* over the shared tokenizer
/// (`editor/highlighting.dart`): link tokens are exactly the
/// [TokenKind.wikilink] / [TokenKind.link] ranges the editor paints, so the
/// indexer, the editor Ctrl+click and the preview agree on what is a link —
/// and links inside code fences, math blocks, inline code or the frontmatter
/// are never links, everywhere.
library;

import 'package:copist/src/editor/highlighting.dart';

/// A parsed link occurrence in a document; [start]..[end] are absolute
/// offsets into the source text (`[`, `(`… or `[[`…`]]`).
sealed class ParsedLink {
  /// Creates a parsed link covering [start]..[end] of the source text.
  const new({required this.start, required this.end});

  /// Offset of the first character of the link (`[` or `[[`).
  final int start;

  /// Offset one past the last character (`)` or `]]`).
  final int end;
}

/// A wikilink `[[…]]`.
final class WikiLink extends ParsedLink {
  /// Creates a wikilink with its parsed [ref].
  const new({required super.start, required super.end, required this.ref});

  /// The link's parsed inside.
  final WikiRef ref;
}

/// A standard Markdown link `[text](href)`.
final class MarkdownLink extends ParsedLink {
  /// Creates a Markdown link with its [text] and [href].
  const new({
    required super.start,
    required super.end,
    required this.text,
    required this.href,
  });

  /// The link text between `[` and `]` (trimmed).
  final String text;

  /// The href between `(` and `)` (trimmed): may be a relative `.md` path, a
  /// `#anchor`, an http(s) URL, an image asset path, …
  final String href;
}

/// The inside of `[[…]]`, parsed into target / heading / alias.
///
/// Forms: `target`, `target|alias`, `target#heading`,
/// `target#heading|alias`, `#heading`, `#heading|alias`, `|alias`.
final class WikiRef {
  /// Creates a wiki ref: [target] and optional [heading] / [alias].
  const new({required this.target, this.heading, this.alias});

  /// The note reference before any `#`/`|` (trimmed). Empty for `[[#heading]]`
  /// and `[[|alias]]` — "the current note".
  final String target;

  /// The heading text after `#` (trimmed), or null when absent or empty.
  final String? heading;

  /// The display text after `|` (trimmed), or null when absent or empty.
  final String? alias;
}

/// All links in [text], in document order, with absolute offsets.
///
/// Skips fenced code, math blocks, inline code and the leading frontmatter
/// (via the shared tokenizer), so only links the user would see as links are
/// returned. Markdown images (`![alt](src)`) are not links and are skipped.
List<ParsedLink> parseLinks(String text) {
  return linksInDocument(HighlightDocument.fromText(text));
}

/// The links of an already-tokenized [doc], in document order.
///
/// Same rules as [parseLinks]; callers that need the tokens anyway (the
/// indexer: links + inline tags from one tokenization pass) pass their
/// document in and avoid a second one.
List<ParsedLink> linksInDocument(HighlightDocument doc) {
  final out = <ParsedLink>[];
  var lineStart = 0;
  for (final line in doc.lines) {
    final src = line.text;
    for (final token in line.tokens) {
      if (token.kind == TokenKind.wikilink) {
        // `![[…]]` is an embed-style reference, not a note link (M3 has
        // no embeds), and `[[]]` / `[[|]]` / `[[#]]` carry nothing to
        // resolve or display — skip both.
        final precededByBang =
            token.start > 0 && src.codeUnitAt(token.start - 1) == 0x21;
        if (precededByBang) continue;
        final ref = parseWikiRef(src.substring(token.start + 2, token.end - 2));
        if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
          continue;
        }
        out.add(
          WikiLink(
            start: token.start + lineStart,
            end: token.end + lineStart,
            ref: ref,
          ),
        );
      } else if (token.kind == TokenKind.link) {
        out.add(
          _parseMarkdown(src, token.start, token.end, token.start + lineStart),
        );
      }
    }
    lineStart += line.text.length + 1;
  }
  return out;
}

MarkdownLink _parseMarkdown(String src, int start, int end, int absStart) {
  // The tokenizer guarantees `[text](href)`: text holds no `[`/`]`, so the
  // first `]` closes the text, and href holds no parens, so the last `)`
  // closes the href.
  final close = src.indexOf(']', start);
  final text = close == -1 ? '' : src.substring(start + 1, close).trim();
  final href = src.substring(close + 2, end - 1).trim();
  return MarkdownLink(
    start: absStart,
    end: absStart + (end - start),
    text: text,
    href: href,
  );
}

/// Parses the inside of `[[…]]` (without the brackets).
///
/// Split rules: the first `|` separates the display alias; the first `#`
/// before it separates the heading; everything before `#` is the target.
/// Parts are trimmed; an absent or empty heading/alias is null. This is the
/// single parse rule — the indexer, the editor Ctrl+click and the preview
/// all call it.
WikiRef parseWikiRef(String inner) {
  final s = inner.trim();
  final pipe = s.indexOf('|');
  final before = pipe == -1 ? s : s.substring(0, pipe);
  final aliasText = pipe == -1 ? null : s.substring(pipe + 1).trim();
  final hash = before.indexOf('#');
  final target = (hash == -1 ? before : before.substring(0, hash)).trim();
  final headingText = hash == -1 ? null : before.substring(hash + 1).trim();
  return WikiRef(
    target: target,
    heading: headingText == null || headingText.isEmpty ? null : headingText,
    alias: aliasText == null || aliasText.isEmpty ? null : aliasText,
  );
}
