/// One span of a block that the Markdown package must not interpret.
///
/// Niman's notes carry four things CommonMark has never heard of — inline and
/// display math, wikilinks, inline tags — and one it has, code spans, whose
/// contents must not be read as any of the others. Each is recorded as a span
/// with its absolute offsets, so the renderer can put it back exactly where the
/// parser saw a placeholder.
///
/// The offsets are the *contract*: a span's range and the placeholder run that
/// replaced it are the same length, so every offset in the masked text is the
/// offset it was in the source. That is what lets the block layer parse masked
/// text and map the answer back without a translation table.
library;

import 'package:meta/meta.dart';

/// What a masked span is.
enum ExtensionKind {
  /// `$…$`.
  inlineMath,

  /// `$$…$$` inside a block, which the block scanner usually lifts into a block
  /// of its own; masked here for the cases it does not.
  displayMath,

  /// `[[target]]` and its `|alias` / `#heading` forms.
  wikilink,

  /// `![[target]]`: an embed, which the app shows rather than links.
  embed,

  /// `#tag`, the inline form the index and the tag panel read.
  tag,

  /// A code span, masked for one reason only: so that a `$` or a `[[` inside
  /// it is not mistaken for one of the others.
  codeSpan,
}

/// A masked span of a block.
@immutable
final class ExtensionSpan {
  /// Creates a span covering `[start, end)` of the block's text.
  const new({
    required this.kind,
    required this.start,
    required this.end,
    required this.text,
  });

  /// What it is.
  final ExtensionKind kind;

  /// Its first offset in the block's text.
  final int start;

  /// One past its last offset.
  final int end;

  /// The source text it covers, markers included.
  final String text;

  /// How many characters it covers.
  int get length => end - start;

  /// The text without its delimiters, for the kinds that have them.
  ///
  /// `$x$` gives `x`, `[[a|b]]` gives `a|b`, `![[a]]` gives `a`, `` `x` ``
  /// gives `x`. A tag has no delimiter to strip, so it gives itself.
  String get inner => switch (kind) {
    ExtensionKind.inlineMath ||
    ExtensionKind.displayMath ||
    ExtensionKind.codeSpan => text.substring(1, text.length - 1),
    ExtensionKind.wikilink => text.substring(2, text.length - 2),
    ExtensionKind.embed => text.substring(3, text.length - 2),
    ExtensionKind.tag => text,
  };

  @override
  String toString() => '${kind.name}[$start..$end] ${text.length} chars';
}
