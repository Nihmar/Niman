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
    _parses++;
    final parsed = parse(block, buffer);
    _cache[key] = parsed;
    return parsed;
  }

  /// Parses [block] without consulting the cache.
  ParsedBlock parse(Block block, SourceBuffer buffer) {
    final text = _contentText(block, blockText(block, buffer));
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
    final nodes = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored)
        .parseLines(masked.text.split('\n'));
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
      var line = lines[at];
      for (var level = 0; level < block.quoteDepth; level++) {
        line = _withoutQuoteMark(line);
      }
      lines[at] = line;
    }
    return lines.join('\n');
  }

  /// [line] with one `>` and the space after it taken off, when it has them.
  static String _withoutQuoteMark(String line) {
    var at = 0;
    while (at < line.length && at < 3 && line[at] == ' ') {
      at++;
    }
    if (at >= line.length || line[at] != '>') return line;
    at++;
    if (at < line.length && line[at] == ' ') at++;
    return line.substring(at);
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
    covered ??= kind == StyleKind.image || kind == StyleKind.link
        ? _locateByHref(node)
        : null;
    if (covered == null) return null;

    final widened = _widen(node.tag, covered);
    runs
      ..add(
        StyleRun(
          kind: kind,
          start: widened.$1,
          end: widened.$2,
          depth: depth,
          href: _href(node),
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
      default:
        return inner;
    }
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
