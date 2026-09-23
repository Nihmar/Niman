/// The bridge: a masked block in, styled runs with source offsets out.
///
/// The package parses the masked text and hands back a syntax tree, and the
/// tree carries no offsets — its `Text` nodes are pieces of source with the
/// markup taken out, in document order. So the tree is walked *alongside* the
/// masked text with a cursor: each `Text` node is found at or after the cursor,
/// its range recorded, and the cursor moved past it. A construct's own range is
/// then its children's, widened over the markers the parser dropped, which is
/// what makes a run cover `**bold**` rather than `bold`.
///
/// That walk is exact for everything a note normally holds. It can be off when
/// the parser *rewrites* text rather than dropping markup from it, and
/// character references (`&amp;` becoming `&`) are the one case of that; the
/// bridge tries the source form of the reference before giving up, and marks
/// the block [ParsedBlock.approximate] if even that fails, so a caller that
/// must not act on an uncertain range can refuse rather than guess.
///
/// Blocks that have no inline content — a fence, an indented block, a math
/// block, the frontmatter, a rule, a blank line — come back with no runs: the
/// renderer draws those from the block itself.
library;

import 'package:markdown/markdown.dart' as md;
import 'package:meta/meta.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/masked_block.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';

/// Turns blocks into styled runs.
///
/// Holds one parse per block, dropped as soon as the buffer's revision moves:
/// the inline phase is the expensive half of the parse (378 ms for the whole
/// geometry note, against 14 ms for the blocks), so it is done per visible
/// block and kept only while it is still true.
final class BlockParser {
  /// Creates a parser over its own caches.
  new({this._masker = const ExtensionMasker()});

  final ExtensionMasker _masker;
  final Map<int, ParsedBlock> _cache = <int, ParsedBlock>{};
  SourceBuffer? _source;
  int _revision = -1;
  int _parses = 0;

  /// The definitions last scanned, or null before the first. Set from
  /// outside when they were scanned elsewhere (in the background), so the
  /// parse does not scan for them again.
  DocumentScope? scope;

  /// How many blocks have actually been parsed, for the tests and the bench:
  /// the point of the cache is that this stays near the visible count.
  int get parseCount => _parses;

  /// The parsed form of [block], cached until the buffer changes.
  ParsedBlock of(Block block, SourceBuffer buffer) {
    if (!identical(_source, buffer) || _revision != buffer.revision) {
      _cache.clear();
      _source = buffer;
      _revision = buffer.revision;
    }
    final key = Object.hash(block.startLine, block.endLine, block.kind);
    final cached = _cache[key];
    if (cached != null) return cached;
    final parsed = parse(block, buffer);
    _cache[key] = parsed;
    return parsed;
  }

  /// Parses [block] without consulting the cache.
  ParsedBlock parse(Block block, SourceBuffer buffer) =>
      parseText(block, blockText(block, buffer), () => _scopeOf(buffer));

  /// Parses [block], whose source text is [raw], with the definitions
  /// [scope] answers — asked only when the block has inline content.
  ///
  /// The source view's way in: it keeps the definitions itself, because
  /// scanning the note for them is O(note) and a keystroke must not be.
  ParsedBlock parseText(
    Block block,
    String raw,
    DocumentScope Function() scope,
  ) {
    _parses++;
    final text = _contentText(block, raw);
    if (!_hasInlineContent(block.kind)) {
      return ParsedBlock(
        block: block,
        text: text,
        masked: MaskedBlock(text: text, spans: const []),
        runs: const <StyleRun>[],
      );
    }
    final masked = _masker.mask(text);
    final walk = _Walk(masked);
    final definitions = scope();
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: _htmlStyleSyntaxes,
    );
    // The two constructs that are a *document's*, not a block's. A link
    // reference and a footnote definition are written in one block and used in
    // another, and the package keeps them on its `Document` — which a per-block
    // parse builds fresh. Seeding them from a scan of the whole note is what
    // makes `[^1]` a superscript and `[text][label]` a link.
    document.linkReferences.addAll(definitions.links);
    document.footnoteReferences.addAll(definitions.footnoteCounts);
    document.footnoteLabels.addAll(definitions.footnoteLabels);
    final nodes = document.parseLines(masked.text.split('\n'));
    for (final node in nodes) {
      walk.visit(node, 0);
    }
    return ParsedBlock(
      block: block,
      text: text,
      masked: masked,
      runs: _joinSchemeLinks(walk.runs, masked.text),
      approximate: walk.approximate,
    );
  }

  /// Joins a scheme the parser left behind to the link it belongs to.
  ///
  /// The package's autolink extension links the address but not the scheme, so
  /// `mailto:foo@bar.baz` arrives as the text `mailto:` followed by a link over
  /// `foo@bar.baz` whose own target *is* `mailto:foo@bar.baz`. GFM renders the
  /// whole thing as one link with the scheme in its text, and this is the layer
  /// that knows what the whole construct is — so the two runs become one.
  ///
  /// It is the only place the engine corrects the parser, and it is worth
  /// saying why it is here rather than in the package: the scheme is part of
  /// what the note *means*, the run model is ours, and a fix here cannot be
  /// lost by a dependency bump.
  static List<StyleRun> _joinSchemeLinks(List<StyleRun> runs, String text) {
    final out = <StyleRun>[];
    for (final run in runs) {
      final previous = out.isEmpty ? null : out.last;
      if (previous != null &&
          previous.kind == StyleKind.plain &&
          run.kind == StyleKind.link &&
          run.start == previous.end &&
          run.href != null) {
        final scheme = _trailingScheme(text, previous);
        if (scheme != null && run.href!.startsWith('$scheme:')) {
          out
            ..removeLast()
            ..add(
              StyleRun(
                kind: StyleKind.link,
                start: previous.start,
                end: run.end,
                depth: previous.depth,
                href: run.href,
                innerStart: previous.start,
                innerEnd: run.end,
              ),
            );
          continue;
        }
      }
      out.add(run);
    }
    return out;
  }

  /// The `scheme:` a run ends with, or null.
  static String? _trailingScheme(String text, StyleRun run) {
    final slice = text.substring(run.start, run.end);
    final colon = slice.lastIndexOf(':');
    if (colon <= 0) return null;
    var start = colon;
    while (start > 0) {
      final char = slice.codeUnitAt(start - 1);
      final isSchemeChar =
          (char >= 0x61 && char <= 0x7A) ||
          (char >= 0x41 && char <= 0x5A) ||
          (char >= 0x30 && char <= 0x39) ||
          char == 0x2B ||
          char == 0x2D ||
          char == 0x2E;
      if (!isSchemeChar) break;
      start--;
    }
    if (start == colon) return null;
    // Only a scheme the engine knows is a link: `note:something` in prose is
    // not one, and treating it as one would join runs that do not belong.
    final scheme = slice.substring(start, colon).toLowerCase();
    return scheme == 'mailto' || scheme == 'xmpp' ? scheme : null;
  }

  /// The footnotes of [buffer], in citation order.
  ///
  /// The renderer needs the definitions as well as the references: the package
  /// ends a document with a list of them, and the read view draws that list as
  /// a section of its own — so unlike the references, these are not merely
  /// seeded into a document and forgotten.
  List<Footnote> footnotesOf(SourceBuffer buffer) => _scopeOf(buffer).footnotes;

  /// The document-scoped definitions, scanned once per revision.
  DocumentScope _scopeOf(SourceBuffer buffer) {
    final cached = scope;
    if (cached != null &&
        identical(cached.source, buffer) &&
        cached.revision == buffer.revision) {
      return cached;
    }
    return scope = DocumentScope.scan(buffer, buffer.revision);
  }

  /// The block's text with its containers' syntax taken off.
  ///
  /// **Quotes, and only quotes — which is a finding, not an oversight.** The
  /// `>` is pure syntax: the block scanner has already said this is a quote and
  /// the renderer draws the bar itself, so the parser must see the content and
  /// nothing else. Without this a `Text` node of `a\nb` cannot be found in the
  /// source `> a\n> b`, the walk falls back to an estimate — the
  /// [ParsedBlock.approximate] flag is exactly that — and the run then covers
  /// the raw `> b`, putting a stray `>` on screen.
  ///
  /// A list marker is *not* the same kind of thing and is left alone: the
  /// package needs it to know the line is an item at all, and `[x] …` without
  /// its `-` is a paragraph whose text is `[x] …`, so the task box would come
  /// back as those three characters.
  static String _contentText(Block block, String raw) {
    if (block.quoteDepth <= 0) return raw;
    final lines = raw.split('\n');
    for (var at = 0; at < lines.length; at++) {
      final line = lines[at];
      lines[at] = line.substring(quotePrefixLength(line, block.quoteDepth));
    }
    return lines.join('\n');
  }

  /// How much of [line] its [depth] quote marks take — each `>` with the up
  /// to three spaces before it and the one after — as far as the line has
  /// them: what the parse takes off a quote's lines, so a reader can put the
  /// parse's offsets back on the line.
  static int quotePrefixLength(String line, int depth) {
    var from = 0;
    for (var level = 0; level < depth; level++) {
      var at = from;
      while (at < line.length && at - from < 3 && line.codeUnitAt(at) == 0x20) {
        at++;
      }
      if (at >= line.length || line.codeUnitAt(at) != 0x3E) return from;
      at++;
      if (at < line.length && line.codeUnitAt(at) == 0x20) at++;
      from = at;
    }
    return from;
  }

  /// The block's own text, its lines joined with `\n`.
  static String blockText(Block block, SourceBuffer buffer) {
    final parts = <String>[];
    for (var line = block.startLine; line < block.endLine; line++) {
      parts.add(buffer.lineAt(line));
    }
    return parts.join('\n');
  }

  /// Whether a block kind has inline content to parse.
  static bool _hasInlineContent(BlockKind kind) => switch (kind) {
    BlockKind.paragraph ||
    BlockKind.heading ||
    BlockKind.listItem ||
    BlockKind.quote ||
    BlockKind.table => true,
    BlockKind.fencedCode ||
    BlockKind.indentedCode ||
    BlockKind.math ||
    BlockKind.frontmatter ||
    BlockKind.html ||
    BlockKind.thematicBreak ||
    BlockKind.blank => false,
  };
}

/// One walk of a syntax tree alongside its masked text.
final class _Walk {
  new(this.masked);

  final MaskedBlock masked;

  /// The runs found so far, in the order they were closed.
  final List<StyleRun> runs = <StyleRun>[];

  /// Whether any node had to be placed by estimate.
  bool approximate = false;

  /// Where the next `Text` node is expected.
  int _cursor = 0;

  /// Walks [node], which sits [depth] constructs deep, and answers the range it
  /// covered — or null when nothing of it could be placed.
  (int, int)? visit(md.Node node, int depth) {
    if (node is md.Text) return _text(node, depth);
    if (node is! md.Element) return null;

    final children = node.children;
    final kind = _kindOf(node);
    final childRuns = <StyleRun>[];
    (int, int)? covered;
    if (children != null) {
      for (final child in children) {
        final before = runs.length;
        final range = visit(child, kind == null ? depth : depth + 1);
        childRuns.addAll(runs.sublist(before));
        if (range != null) {
          covered = covered == null
              ? range
              : (
                  range.$1 < covered.$1 ? range.$1 : covered.$1,
                  range.$2 > covered.$2 ? range.$2 : covered.$2,
                );
        }
      }
      runs.removeRange(runs.length - childRuns.length, runs.length);
    }

    if (kind == null) {
      runs.addAll(childRuns);
      return covered;
    }
    if (kind == StyleKind.hardBreak) {
      runs.add(
        StyleRun(kind: kind, start: _cursor, end: _cursor, depth: depth),
      );
      return (_cursor, _cursor);
    }
    // An image has no children — its alt text is an attribute — so the range
    // comes from its own target in the text instead.
    var inner = covered;
    if (covered == null &&
        (kind == StyleKind.image || kind == StyleKind.link)) {
      final located = _locateByHref(node);
      if (located != null) {
        covered = located;
        // `[` or `![` to `](`: the text between them, which an image's alt is.
        final open = masked.text.codeUnitAt(located.$1) == 0x21 ? 2 : 1;
        final close = masked.text.lastIndexOf('](', located.$2);
        inner = (
          located.$1 + open,
          close < located.$1 + open ? located.$1 + open : close,
        );
      }
    }
    if (covered == null) return null;

    final widened = _widen(node.tag, covered);
    final text = inner ?? covered;
    runs
      ..add(
        StyleRun(
          kind: kind,
          start: widened.$1,
          end: widened.$2,
          depth: depth,
          href: _href(node),
          innerStart: text.$1,
          innerEnd: text.$2,
        ),
      )
      ..addAll(childRuns);
    return widened;
  }

  /// A `Text` node: found at or after the cursor, and the cursor moved past it.
  (int, int)? _text(md.Text node, int depth) {
    final text = node.text;
    if (text.isEmpty) return null;
    var at = masked.text.indexOf(text, _cursor);
    if (at < 0) {
      // The parser decodes character references, so the node's text is not
      // always what the source says. Its source form is tried before giving up.
      final encoded = _encode(text);
      if (encoded != text) at = masked.text.indexOf(encoded, _cursor);
      final found = at >= 0;
      if (!found) {
        approximate = true;
        at = _cursor;
      }
      final end = at + (found ? encoded.length : text.length);
      _cursor = end > masked.text.length ? masked.text.length : end;
      if (depth == 0) {
        runs.add(StyleRun(kind: StyleKind.plain, start: at, end: _cursor));
      }
      return (at, _cursor);
    }
    final end = at + text.length;
    _cursor = end;
    // Text inside a construct is not a run of its own: the construct's run
    // covers it, and emitting both would paint the same characters twice. What
    // a construct's *visible* text is — its range minus its children's — is the
    // renderer's to derive, which is also how it knows which characters are the
    // markers `live` mode hides.
    if (depth == 0) {
      runs.add(StyleRun(kind: StyleKind.plain, start: at, end: end));
    }
    return (at, end);
  }

  /// Widens a construct's inner range over the markers the parser dropped.
  (int, int) _widen(String tag, (int, int) inner) {
    final text = masked.text;
    switch (tag) {
      case 'em' || 'strong':
        return _overMarkers(text, inner, const <int>[0x2A, 0x5F]);
      case 'del':
        return _overMarkers(text, inner, const <int>[0x7E]);
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        return _widenHeading(text, inner);
      case 'a' || 'img':
        return _overLink(text, inner);
      case 'u' || 'sup' || 'sub':
        return _overTags(text, inner, tag);
      default:
        return inner;
    }
  }

  /// Grows a range over the `<tag>` before it and the `</tag>` after it.
  static (int, int) _overTags(String text, (int, int) inner, String tag) {
    final open = '<$tag>';
    final close = '</$tag>';
    final start = inner.$1 - open.length;
    final end = inner.$2 + close.length;
    if (start < 0 || end > text.length) return inner;
    if (text.substring(start, inner.$1).toLowerCase() != open ||
        text.substring(inner.$2, end).toLowerCase() != close) {
      return inner;
    }
    return (start, end);
  }

  /// Grows a range over a run of marker characters on each side, when one is
  /// there to grow over.
  static (int, int) _overMarkers(
    String text,
    (int, int) inner,
    List<int> chars,
  ) {
    var start = inner.$1;
    var end = inner.$2;
    while (start > 0 && chars.contains(text.codeUnitAt(start - 1))) {
      start--;
    }
    while (end < text.length && chars.contains(text.codeUnitAt(end))) {
      end++;
    }
    return (start, end);
  }

  /// Grows a heading's text back over its markers and forward to the line end.
  static (int, int) _widenHeading(String text, (int, int) inner) {
    var start = inner.$1;
    while (start > 0) {
      final char = text.codeUnitAt(start - 1);
      if (char == 0x23 || char == 0x20 || char == 0x09) {
        start--;
      } else {
        break;
      }
    }
    var end = inner.$2;
    while (end < text.length) {
      final char = text.codeUnitAt(end);
      if (char == 0x0A) break;
      end++;
    }
    return (start, end);
  }

  /// Finds a construct by the target the parser reported: `](href)` in the
  /// text, then back over the `[` and the `!` of an image.
  (int, int)? _locateByHref(md.Element element) {
    final href = _href(element);
    if (href == null || href.isEmpty) return null;
    final text = masked.text;
    final close = text.indexOf(']($href)', _cursor);
    if (close < 0) return null;
    var start = close;
    while (start > 0 && text.codeUnitAt(start - 1) != 0x5B) {
      start--;
      if (start == 0) return null;
    }
    start--;
    if (start > 0 && text.codeUnitAt(start - 1) == 0x21) start--;
    final end = close + ']($href)'.length;
    _cursor = end;
    return (start, end);
  }

  /// Grows a link's or an image's inner text to the whole `[text](href)`.
  static (int, int) _overLink(String text, (int, int) inner) {
    var start = inner.$1;
    if (start > 0 && text.codeUnitAt(start - 1) == 0x5B) {
      start--;
      if (start > 0 && text.codeUnitAt(start - 1) == 0x21) start--;
    } else {
      // Not the inline form: a reference link, whose destination is defined
      // elsewhere. Its own text is the honest range.
      return inner;
    }
    final close = text.indexOf('](', inner.$2);
    if (close < 0) return (start, inner.$2);
    final paren = text.indexOf(')', close + 2);
    if (paren < 0) return (start, inner.$2);
    return (start, paren + 1);
  }

  /// The style a tag means, or null when it is structural.
  static StyleKind? _kindOf(md.Element element) => switch (element.tag) {
    'em' => StyleKind.emphasis,
    'strong' => StyleKind.strong,
    'del' => StyleKind.strikethrough,
    'u' => StyleKind.underline,
    'sup' => StyleKind.superscript,
    'sub' => StyleKind.subscript,
    'code' => StyleKind.code,
    'a' => StyleKind.link,
    'img' => StyleKind.image,
    'br' => StyleKind.hardBreak,
    'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => StyleKind.heading,
    _ => null,
  };

  static String? _href(md.Element element) =>
      element.attributes['href'] ?? element.attributes['src'];

  /// The source form of [text], for the characters the parser decodes.
  static String _encode(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

/// The definitions a note makes that no single block can resolve.
///
/// A link reference (`[label]: destination`) and a footnote (`[^label]: text`
/// with `[^label]` where it is cited) are written in one place and used in
/// another, and the package resolves both from state on its `Document` — which
/// the engine builds per block, deliberately, so that a long note is not
/// re-parsed to scroll it. Scanning the note once per revision and seeding
/// every block's document from the result is what keeps the block-by-block
/// parse honest without giving up the windowing.
///
/// The scan is over the note's text, not over its blocks, because it must be
/// complete: a definition on the last line resolves a reference on the first.
final class DocumentScope {
  /// Wraps an already-scanned scope.
  const new({
    required this.links,
    required this.footnoteCounts,
    required this.footnoteLabels,
    required this.footnotes,
    required this.source,
    required this.revision,
  });

  /// Scans [source]'s lines for both kinds of definition.
  ///
  /// Line by line, and only the lines that can hold one: a definition opens
  /// with `[` after at most three spaces, a reference contains `[^`. The
  /// scan used to run three multi-line patterns over the note's joined text
  /// — 8.5 s on the first frame of a 246 MB note's preview (0.0.9 stress
  /// test) — for definitions a few lines of it make.
  factory scan(SourceBuffer source, int revision) {
    final links = <String, md.LinkReference>{};
    final counts = <String, int>{};
    final bodies = <String, String>{};
    final labels = <String>[];
    final cited = <String>{};
    for (var at = 0; at < source.lineCount; at++) {
      final line = source.lineAt(at);
      if (line.contains('[^')) {
        for (final match in _footnoteReference.allMatches(line)) {
          final label = match.group(1)!;
          if (cited.add(label)) labels.add(label);
        }
      }
      if (!_opensWithBracket(line)) continue;
      final footnote = _footnoteDefinition.firstMatch(line);
      if (footnote != null) {
        final label = footnote.group(1)!;
        counts[label] = (counts[label] ?? 0) + 1;
        final body = (footnote.group(2) ?? '').trim();
        if (body.isNotEmpty) bodies.putIfAbsent(label, () => body);
        continue;
      }
      final link = _linkDefinition.firstMatch(line);
      if (link == null) continue;
      final label = link.group(1)!.trim().toLowerCase();
      if (label.isEmpty) continue;
      links.putIfAbsent(
        label,
        () => md.LinkReference(
          link.group(1)!.trim(),
          link.group(2)!,
          link.group(3),
        ),
      );
    }
    // The section a note ends with, in the order the references are cited —
    // which is the order the package numbers them in, and the order a reader
    // meets them.
    final notes = <Footnote>[];
    for (final label in labels) {
      if (!counts.containsKey(label)) continue;
      notes.add(Footnote(label: label, body: bodies[label] ?? ''));
    }
    return DocumentScope(
      links: links,
      footnoteCounts: counts,
      footnoteLabels: labels,
      footnotes: notes,
      source: source,
      revision: revision,
    );
  }

  /// Whether [line] opens with `[` after at most three spaces: the only
  /// lines a definition can be.
  static bool _opensWithBracket(String line) {
    var at = 0;
    while (at < 3 && at < line.length && line.codeUnitAt(at) == 0x20) {
      at++;
    }
    return at < line.length && line.codeUnitAt(at) == 0x5B;
  }

  /// A link reference definition, in its single-line form.
  static final RegExp _linkDefinition = RegExp(
    r'^ {0,3}\[([^\]^][^\]]*)\]:[ \t]*(\S+)[ \t]*'
    r'(?:["\x27(]([^"\x27)]*)["\x27)])?[ \t]*$',
  );

  /// A footnote definition, in its single-line form: its label and its body.
  static final RegExp _footnoteDefinition = RegExp(
    r'^ {0,3}\[\^([^\]]+)\]:[ \t]*(.*)$',
  );

  /// A footnote reference: `[^label]` that is not a definition.
  static final RegExp _footnoteReference = RegExp(r'\[\^([^\]]+)\](?!:)');

  /// The link references, by label.
  final Map<String, md.LinkReference> links;

  /// How many times each footnote label is defined.
  final Map<String, int> footnoteCounts;

  /// The footnote labels in the order they are first cited, which is the order
  /// the package numbers them in.
  final List<String> footnoteLabels;

  /// The definitions, in citation order, for the section a note ends with.
  final List<Footnote> footnotes;

  /// The buffer this was scanned from.
  final SourceBuffer source;

  /// Its revision.
  final int revision;

  /// The same definitions, as scanned from [buffer] at [revision]: a scope
  /// scanned from a copy of the note, in the background, handed to the note
  /// itself.
  DocumentScope on(SourceBuffer buffer, int revision) => DocumentScope(
    links: links,
    footnoteCounts: footnoteCounts,
    footnoteLabels: footnoteLabels,
    footnotes: footnotes,
    source: buffer,
    revision: revision,
  );
}

/// One footnote: the label it was defined with, and its body.
@immutable
final class Footnote {
  /// Creates a footnote.
  const new({required this.label, required this.body});

  /// The label, without its brackets.
  final String label;

  /// What the definition said, in its single-line form.
  final String body;

  @override
  String toString() => 'Footnote($label: $body)';
}

/// The HTML tags a note uses for what Markdown has no syntax for, read as the
/// constructs they are rather than as raw HTML.
final List<md.InlineSyntax> _htmlStyleSyntaxes = <md.InlineSyntax>[
  for (final tag in const <String>['u', 'sup', 'sub']) _HtmlStyleSyntax(tag),
];

/// `<tag>…</tag>` on one line, as an element whose contents are parsed like
/// any other inline text — so `<u>**x**</u>` is bold and underlined.
///
/// The package reads inline HTML as text it passes through, which a renderer
/// that draws runs cannot draw: the toolbar's underline wrote `<u>` into the
/// note, and both the read view and `live` mode showed the tags.
final class _HtmlStyleSyntax extends md.InlineSyntax {
  new(this.tag)
    : super('<$tag>(.+?)</$tag>', startCharacter: 0x3C, caseSensitive: false);

  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final children = md.InlineParser(match[1]!, parser.document).parse();
    parser.addNode(md.Element(tag, children));
    return true;
  }
}
