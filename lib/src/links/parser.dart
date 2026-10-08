/// Wikilink and Markdown link parsing (design.md: links/parser.dart).
///
/// The parser is a *reader* over the shared tokenizer
/// (`editor/highlighting.dart`): link tokens are exactly the
/// [TokenKind.wikilink] / [TokenKind.link] ranges the editor paints, so the
/// indexer, the editor Ctrl+click and the preview agree on what is a link —
/// and links inside code fences, math blocks, inline code or the frontmatter
/// are never links, everywhere.
library;

import 'package:niman/src/editor/highlighting.dart';

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

/// A wikilink `[[…]]`, or the embed `![[…]]` when [embed] is set.
final class WikiLink extends ParsedLink {
  /// Creates a wikilink with its parsed [ref]; [embed] marks `![[…]]`.
  const new({
    required super.start,
    required super.end,
    required this.ref,
    this.embed = false,
  });

  /// The link's parsed inside.
  final WikiRef ref;

  /// Whether it was written as an embed (`![[…]]`), which the app shows
  /// rather than links. A move still has to carry it (#507).
  final bool embed;
}

/// A standard Markdown link `[text](href)`, or the image `![alt](href)` when
/// [embed] is set.
final class MarkdownLink extends ParsedLink {
  /// Creates a Markdown link with its [text] and [href]; [embed] marks an
  /// image (`![…](…)`).
  const new({
    required super.start,
    required super.end,
    required this.text,
    required this.href,
    this.embed = false,
    this.angled = false,
  });

  /// The link text between `[` and `]` (trimmed), the alt text for an image.
  final String text;

  /// The href between `(` and `)` (trimmed): may be a relative `.md` path, a
  /// `#anchor`, an http(s) URL, an image asset path, …
  final String href;

  /// Whether it was written as an image (`![…](…)`), which the app shows
  /// rather than links. A move still has to carry it (#507).
  final bool embed;

  /// Whether the href was written between angle brackets, `(<a b.md>)`:
  /// [href] is without them, and a rewrite puts them back.
  final bool angled;
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
/// returned. Markdown images (`![alt](src)`) and embeds (`![[…]]`) are not
/// links and are skipped; [includeEmbeds] returns them too, marked so a
/// caller that has to carry them on a move (#507) can tell them apart.
List<ParsedLink> parseLinks(String text, {bool includeEmbeds = false}) {
  return linksInDocument(
    HighlightDocument.fromText(text),
    includeEmbeds: includeEmbeds,
  );
}

/// The links of an already-tokenized [doc], in document order.
///
/// Same rules as [parseLinks]; callers that need the tokens anyway (the
/// indexer: links + inline tags from one tokenization pass) pass their
/// document in and avoid a second one.
List<ParsedLink> linksInDocument(
  HighlightDocument doc, {
  bool includeEmbeds = false,
}) {
  final out = <ParsedLink>[];
  var lineStart = 0;
  for (final line in doc.lines) {
    final src = line.text;
    for (final token in line.tokens) {
      if (token.kind == TokenKind.wikilink) {
        // `[[]]` / `[[|]]` / `[[#]]` carry nothing to resolve or display.
        final precededByBang =
            token.start > 0 && src.codeUnitAt(token.start - 1) == 0x21;
        final ref = parseWikiRef(src.substring(token.start + 2, token.end - 2));
        if (precededByBang) {
          // `![[…]]` is an embed, shown rather than linked; it is a reference
          // a move must still carry, so it is only skipped unless asked for.
          if (!includeEmbeds || ref.target.isEmpty) continue;
          out.add(
            WikiLink(
              start: token.start - 1 + lineStart,
              end: token.end + lineStart,
              ref: ref,
              embed: true,
            ),
          );
          continue;
        }
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
      } else if (token.kind == TokenKind.image && includeEmbeds) {
        out.add(
          _parseImage(src, token.start, token.end, token.start + lineStart),
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
  final (href, angled) = _destination(src.substring(close + 2, end - 1));
  return MarkdownLink(
    start: absStart,
    end: absStart + (end - start),
    text: text,
    href: href,
    angled: angled,
  );
}

MarkdownLink _parseImage(String src, int start, int end, int absStart) {
  // The tokenizer guarantees `![alt](href)`: the token starts at `!`, the
  // first `]` closes the alt text, and the last `)` closes the href.
  final close = src.indexOf(']', start);
  final text = close == -1 ? '' : src.substring(start + 2, close).trim();
  final (href, angled) = _destination(src.substring(close + 2, end - 1));
  return MarkdownLink(
    start: absStart,
    end: absStart + (end - start),
    text: text,
    href: href,
    embed: true,
    angled: angled,
  );
}

/// A link's destination as written between its parentheses, without the
/// angle brackets CommonMark allows around it: `<a b.md>` is `a b.md`.
(String, bool) _destination(String written) {
  final trimmed = written.trim();
  if (trimmed.length >= 2 && trimmed.startsWith('<') && trimmed.endsWith('>')) {
    return (trimmed.substring(1, trimmed.length - 1), true);
  }
  return (trimmed, false);
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

/// What a wikilink whose inside is [inner] shows: its alias, else its
/// target without the heading, else [inner] as written.
///
/// One rule for every place a wikilink is drawn — the read view and the
/// export — so a link reads the same in the note and out of it.
String wikiDisplayText(String inner) {
  final pipe = inner.indexOf('|');
  if (pipe >= 0) {
    final alias = inner.substring(pipe + 1).trim();
    if (alias.isNotEmpty) return alias;
  }
  final target = pipe >= 0 ? inner.substring(0, pipe) : inner;
  final hash = target.indexOf('#');
  final name = (hash >= 0 ? target.substring(0, hash) : target).trim();
  return name.isEmpty ? inner : name;
}
