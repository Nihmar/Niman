/// What the part after a link's `#` names inside a note (#844, #845), and
/// the line it lands on.
///
/// A link's fragment travels as the text it was written with — `A#B` for the
/// subheading `B` under `A`, `^37066d` for a block — from the parser through
/// the resolver and the shell to the note it opens. This reads that text:
/// [parseAnchor] says what it is, [headingLineOf] and [blockLineOf] say where
/// it is.
library;

import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/block_id.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/slug.dart';

/// What a link's fragment names.
sealed class LinkAnchor {
  /// Creates an anchor.
  const new();
}

/// A heading, or a path of headings from an outer one to an inner (`A#B`).
final class HeadingAnchor extends LinkAnchor {
  /// Creates a heading anchor for the [path], outermost level first, written
  /// as [whole] (the levels joined by `#` when not given).
  new(this.path, [String? whole]) : whole = whole ?? path.join('#');

  /// The heading levels as written; never empty.
  final List<String> path;

  /// The fragment as one heading's text: `Issue #12` is the path
  /// `[Issue, 12]` and, when no such path exists, the heading `Issue #12`.
  final String whole;
}

/// A block, by the id it ends with.
final class BlockIdAnchor extends LinkAnchor {
  /// Creates a block anchor for [id], without its `^`.
  const new(this.id);

  /// The id, matched literally.
  final String id;
}

/// The anchor [fragment] names, or null for an empty one.
///
/// `^` and a valid id is a block; everything else is a heading path, split at
/// each `#` — the same rule [parseWikiRef] reads a wikilink's by — that also
/// keeps the fragment whole, for a heading with a `#` in its own text.
LinkAnchor? parseAnchor(String fragment) {
  final text = fragment.trim();
  if (text.isEmpty) return null;
  if (text.startsWith('^') && BlockId.isValid(text.substring(1))) {
    return BlockIdAnchor(text.substring(1));
  }
  final path = headingPathOf(text);
  return path.isEmpty ? null : HeadingAnchor(path, text);
}

/// The line of the heading [anchor] names in [outline], or null when no
/// heading does.
///
/// The path is tried first. A path is read by level order: `A#C` is a heading
/// `C` inside a section of a heading `A` — any depth below it, up to the next
/// heading of `A`'s level or higher. Every level is matched by the shared
/// slug, so case and punctuation do not matter. A single level is the first
/// heading of that slug; a path tries every heading of its first level in
/// turn, so a `## Details` that appears under two parents is told apart by
/// the parent.
///
/// When the path names no heading, the whole fragment is tried as one
/// heading's text: a `#` in a heading (`C#`, `Issue #12`) is not a level
/// separator there, as it never was before paths existed.
int? headingLineOf(List<OutlineEntry> outline, HeadingAnchor anchor) {
  final path = anchor.path;
  if (path.isEmpty) return null;
  final byPath = _find(
    outline,
    [for (final l in path) headingSlug(l)],
    0,
    0,
    outline.length,
  );
  if (byPath != null || path.length == 1) return byPath;
  return _find(outline, [headingSlug(anchor.whole)], 0, 0, outline.length);
}

int? _find(
  List<OutlineEntry> outline,
  List<String> slugs,
  int depth,
  int from,
  int to,
) {
  for (var at = from; at < to; at++) {
    final entry = outline[at];
    if (headingSlug(entry.text) != slugs[depth]) continue;
    if (depth == slugs.length - 1) return entry.line;
    // The section of this heading: up to the next one as high as it is.
    var end = at + 1;
    while (end < to && outline[end].level > entry.level) {
      end++;
    }
    final inside = _find(outline, slugs, depth + 1, at + 1, end);
    if (inside != null) return inside;
  }
  return null;
}

/// The line of the block [id] names in [blocks], matched literally, or null.
int? blockLineOf(List<BlockAnchor> blocks, String id) {
  for (final block in blocks) {
    if (block.id == id) return block.line;
  }
  return null;
}
