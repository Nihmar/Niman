/// A note's tags and links, read the way the unified engine reads the note.
///
/// What the index keeps of a note besides its text is its inline tags and its
/// links, and nothing else a parse makes. A whole-note parse — the legacy
/// tokenizer's or the Markdown package's — pays for every run of every line:
/// two minutes on the 247 MB stress note, for the 3 % of its lines that have
/// a `#` or a `[` (`docs/records/huge-notes.md`, item 8). So each layer is asked
/// only where its answer can be one:
///
/// * the **block scan** says which blocks have inline text at all — never a
///   fence, a formula, the frontmatter or an HTML block;
/// * the **extension masker** finds the tags and the wikilinks, and sets code
///   spans and inline maths aside, in a block that holds a `#` or a `[`;
/// * the **Markdown parse** runs only on a block where a `[` is left once the
///   masker is done, which is the only place a Markdown link can be.
///
/// The same scanner, masker and parser draw the note, so what the index calls
/// a link is what the note shows as one.
library;

import 'package:niman/src/frontmatter/parser.dart' show normalizeTag;
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';

/// The inline tags and the links of one note.
final class NoteReferences {
  /// Creates the references of a note.
  const new({required this.tags, required this.links});

  /// Its inline `#tags`, normalized, each once, in the order they first
  /// appear.
  final List<String> tags;

  /// Its wikilinks and Markdown links, in document order.
  ///
  /// A link's offsets are where its block's text puts it: exact outside a
  /// quote, and inside one measured without the quote's `>` marks. The
  /// index keeps the kind and the target, never the offsets.
  final List<ParsedLink> links;
}

/// The tags and links of [text]; see the library comment for what is read.
NoteReferences noteReferencesOf(String text) {
  final buffer = SourceBuffer.fromText(text);
  final blocks = BlockScanner(buffer).index.blocks;
  final parser = BlockParser();
  DocumentScope? scope;
  DocumentScope scopeOf() =>
      scope ??= DocumentScope.scan(buffer, buffer.revision);
  return collectReferences([
    for (final block in blocks)
      blockReferencesOf(block, buffer, parser, scopeOf),
  ]);
}

/// The tags and links of one block: what a note's references are made of,
/// block by block, for a reader that keeps them per block and reads again
/// only the blocks an edit changed (`NoteReferenceCache`).
///
/// `scoped` says the answer read the note's link definitions — a
/// Markdown link was parsed, and `[text][label]` is a link or not by them
/// — so it is to be read again when they change.
typedef BlockReferences = ({
  List<String> tags,
  List<ParsedLink> links,
  bool scoped,
});

/// A block with no tag and no link.
const BlockReferences noBlockReferences = (
  tags: <String>[],
  links: <ParsedLink>[],
  scoped: false,
);

/// The references of [block] in [buffer]; [scope] is asked only when a
/// Markdown link can be in it. A link's offsets are where the note had it
/// when the block was read.
BlockReferences blockReferencesOf(
  Block block,
  SourceBuffer buffer,
  BlockParser parser,
  DocumentScope Function() scope,
) {
  if (!_hasInlineText(block.kind)) return noBlockReferences;
  final raw = BlockParser.blockText(block, buffer);
  if (!raw.contains('#') && !raw.contains('[')) return noBlockReferences;
  const masker = ExtensionMasker();
  final tags = <String>[];
  final links = <ParsedLink>[];
  final source = _SourceOffsets(block, raw, buffer);
  final masked = masker.mask(BlockParser.contentText(block, raw));
  for (final span in masked.spans) {
    switch (span.kind) {
      case ExtensionKind.tag:
        tags.add(normalizeTag(span.text));
      case ExtensionKind.wikilink:
        final ref = parseWikiRef(span.inner);
        // `[[]]`, `[[|]]` and `[[#]]` carry nothing to resolve or show.
        if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
          continue;
        }
        links.add(
          WikiLink(
            start: source.of(span.start),
            end: source.of(span.end),
            ref: ref,
          ),
        );
      case ExtensionKind.embed ||
          ExtensionKind.inlineMath ||
          ExtensionKind.displayMath ||
          ExtensionKind.codeSpan:
        break;
    }
  }
  // A Markdown link needs a `[` the masker left: one inside a wikilink, a
  // code span or a formula is not the start of one.
  final scoped = masked.text.contains('[');
  if (scoped) {
    final parsed = parser.parseText(block, _footnoteBodyAsText(raw), scope);
    for (final run in parsed.runs) {
      final href = run.href;
      if (run.kind != StyleKind.link || href == null) continue;
      // A footnote reference is drawn as a link to its note, and is none.
      if (href.startsWith('#fn-')) continue;
      links.add(
        MarkdownLink(
          start: source.of(run.start),
          end: source.of(run.end),
          text: parsed.text.substring(run.innerStart, run.innerEnd).trim(),
          href: href,
        ),
      );
    }
  }
  if (tags.isEmpty && links.isEmpty && !scoped) return noBlockReferences;
  links.sort((a, b) => a.start.compareTo(b.start));
  return (tags: tags, links: links, scoped: scoped);
}

/// A note's references out of its blocks', given in the blocks' order: each
/// tag once, in the order it first appears, and the links in the order the
/// note has them.
NoteReferences collectReferences(Iterable<BlockReferences> blocks) {
  final tags = <String>{};
  final links = <ParsedLink>[];
  for (final block in blocks) {
    if (identical(block, noBlockReferences)) continue;
    tags.addAll(block.tags);
    links.addAll(block.links);
  }
  return NoteReferences(tags: tags.toList(), links: links);
}

/// Whether a block of [kind] has inline text, where a tag or a link can be.
bool _hasInlineText(BlockKind kind) => switch (kind) {
  BlockKind.paragraph ||
  BlockKind.heading ||
  BlockKind.listItem ||
  BlockKind.quote ||
  BlockKind.table => true,
  _ => false,
};

/// Offsets in a block's text as the parse reads it
/// ([BlockParser.contentText]), put back on the note.
///
/// The parse takes each line's quote marks and a list item's indent off,
/// so an offset past the first line is short by every prefix above it: the
/// offset of a link in a quote's second line used to land that far left of
/// the link, and a rename that rewrote it wrote into the wrong characters.
/// Each line is found by where it starts in the parse's text and put back
/// at where it starts in the note, its prefix added — which also keeps a
/// CRLF note right, whose lines the parse joins with one character.
final class _SourceOffsets {
  new(Block block, String raw, SourceBuffer buffer) {
    final lines = raw.split('\n');
    var content = 0;
    for (var at = 0; at < lines.length; at++) {
      final prefix = BlockParser.linePrefixLength(
        block,
        lines[at],
        BlockParser.listStripOf(block, lines.first, at),
      );
      _contentStarts.add(content);
      _sourceStarts.add(buffer.offsetOfLine(block.startLine + at) + prefix);
      content += lines[at].length - prefix + 1;
    }
  }

  final List<int> _contentStarts = <int>[];
  final List<int> _sourceStarts = <int>[];

  /// Where [offset], in the parse's text, is in the note.
  int of(int offset) {
    var line = 0;
    while (line + 1 < _contentStarts.length &&
        _contentStarts[line + 1] <= offset) {
      line++;
    }
    return _sourceStarts[line] + offset - _contentStarts[line];
  }
}

/// [raw] with a footnote definition's label (`[^1]:`) blanked out, so its
/// body is read as the paragraph it is.
///
/// The Markdown package takes a definition out of the flow and draws it with
/// the note's footnotes, so a parse of its block has no runs — and a link in
/// a footnote is still a link the note makes. The label is overwritten
/// rather than cut, so every offset after it stays where it was.
String _footnoteBodyAsText(String raw) {
  final label = _footnoteLabel.firstMatch(raw);
  if (label == null) return raw;
  return raw.replaceRange(0, label.end, '_' * label.end);
}

/// A footnote definition's opening: `[^label]:` after at most three spaces.
final RegExp _footnoteLabel = RegExp(r'^ {0,3}\[\^[^\]\s]+\]:');
