/// A note's tags and links, read the way the unified engine reads the note.
///
/// What the index keeps of a note besides its text is its inline tags and its
/// links, and nothing else a parse makes. A whole-note parse — the legacy
/// tokenizer's or the Markdown package's — pays for every run of every line:
/// two minutes on the 247 MB stress note, for the 3 % of its lines that have
/// a `#` or a `[` (`docs/dev/huge-notes.md`, item 8). So each layer is asked
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
  const masker = ExtensionMasker();
  final parser = BlockParser();
  DocumentScope? scope;
  final tags = <String>{};
  final links = <ParsedLink>[];
  for (final block in blocks) {
    if (!_hasInlineText(block.kind)) continue;
    final raw = BlockParser.blockText(block, buffer);
    if (!raw.contains('#') && !raw.contains('[')) continue;
    final at = buffer.offsetOfLine(block.startLine);
    final masked = masker.mask(_contentText(block, raw));
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
            WikiLink(start: at + span.start, end: at + span.end, ref: ref),
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
    if (!masked.text.contains('[')) continue;
    final parsed = parser.parseText(
      block,
      _footnoteBodyAsText(raw),
      () => scope ??= DocumentScope.scan(buffer, buffer.revision),
    );
    for (final run in parsed.runs) {
      final href = run.href;
      if (run.kind != StyleKind.link || href == null) continue;
      // A footnote reference is drawn as a link to its note, and is none.
      if (href.startsWith('#fn-')) continue;
      links.add(
        MarkdownLink(
          start: at + run.start,
          end: at + run.end,
          text: parsed.text.substring(run.innerStart, run.innerEnd).trim(),
          href: href,
        ),
      );
    }
  }
  links.sort((a, b) => a.start.compareTo(b.start));
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

/// [raw] without its quote marks, as the parser reads a quote's block.
String _contentText(Block block, String raw) {
  if (block.quoteDepth <= 0) return raw;
  return <String>[
    for (final line in raw.split('\n'))
      line.substring(BlockParser.quotePrefixLength(line, block.quoteDepth)),
  ].join('\n');
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
