/// One styled run of a block, with the source range it came from.
///
/// A run is what the renderer needs and nothing more: a kind, a range in the
/// block's own text, and how deeply it is nested. The range covers the
/// construct *with its markers* — `**bold**` is one [StyleKind.strong] run over
/// all eight characters, not over the four inside — because the marker is part
/// of what `live` mode hides and part of what an edit has to be able to reach.
///
/// Runs are flat and ordered, and nesting is a field rather than a tree: a
/// paragraph is built from a flat span list, and a renderer that paints from
/// outermost to innermost is what a flat list with depths describes.
library;

import 'package:meta/meta.dart';

/// What a run is.
enum StyleKind {
  /// Text with no construct on it.
  plain,

  /// `*x*` or `_x_`.
  emphasis,

  /// `**x**` or `__x__`.
  strong,

  /// `~~x~~`.
  strikethrough,

  /// A code span, backticks included.
  ///
  /// Never produced by the parser: the extension masker sets code spans aside
  /// before the parser sees the block, precisely so that a `$` or a `[[` inside
  /// one is not read as anything else. A renderer drawing from a
  /// `ParsedBlock` draws it from the masker's span of kind `codeSpan`; the name
  /// lives here so both halves of the engine call it the same thing.
  code,

  /// `[text](href)`, the whole construct.
  link,

  /// `![alt](src)`.
  image,

  /// A heading's text, so a renderer can size a whole run at once.
  heading,

  /// A hard line break (two trailing spaces or a backslash).
  hardBreak,
}

/// One styled run of a block.
@immutable
final class StyleRun {
  /// Creates a run.
  const new({
    required this.kind,
    required this.start,
    required this.end,
    this.depth = 0,
    this.href,
    int? innerStart,
    int? innerEnd,
  }) : innerStart = innerStart ?? start,
       innerEnd = innerEnd ?? end;

  /// What it is.
  final StyleKind kind;

  /// Its first offset in the block's text.
  final int start;

  /// One past its last offset.
  final int end;

  /// How deeply it is nested: 0 is the outermost run of the block.
  final int depth;

  /// The link or image target, when [kind] is [StyleKind.link] or
  /// [StyleKind.image].
  final String? href;

  /// Where the text the construct marks starts: past its opening marker —
  /// the `**` of a bold run, the `[` of a link, a heading's `# `. [start]
  /// for a run that has none.
  ///
  /// `[start, innerStart)` and `[innerEnd, end)` are the markers, which is
  /// what `live` mode hides and what source mode dims.
  final int innerStart;

  /// Where the text the construct marks ends: before its closing marker —
  /// the `**`, or the `](href)` of a link. [end] for a run that has none.
  final int innerEnd;

  /// Whether the run has markers of its own around its text.
  bool get hasMarkers => innerStart > start || innerEnd < end;

  /// How many characters it covers.
  int get length => end - start;

  /// Whether [offset] is inside the run.
  bool contains(int offset) => offset >= start && offset < end;

  @override
  String toString() =>
      '${kind.name}[$start..$end${depth > 0 ? ' d$depth' : ''}'
      '${hasMarkers ? ' inner $innerStart..$innerEnd' : ''}'
      '${href != null ? ' -> $href' : ''}]';
}
