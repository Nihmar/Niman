/// One block, masked, parsed, and turned into the runs a renderer draws.
///
/// This is where the three earlier pieces meet: the block scanner said where
/// the block is, the masker set its own constructs aside, and the Markdown
/// package said what the rest of it means. What comes out is a flat list of
/// styled runs in source order, so the renderer never has to see a parse tree
/// or an HTML string.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/masked_block.dart';
import 'package:niman/src/markdown/style_run.dart';

/// A block, ready to draw.
@immutable
final class ParsedBlock {
  /// Creates a parsed block.
  const new({
    required this.block,
    required this.text,
    required this.masked,
    required this.runs,
    this.approximate = false,
  });

  /// The block this came from.
  final Block block;

  /// The block's own source text, lines joined with `\n`.
  final String text;

  /// That text with its extension spans replaced by placeholders.
  final MaskedBlock masked;

  /// The styled runs, in source order.
  final List<StyleRun> runs;

  /// Whether any run's range had to be estimated.
  ///
  /// The package's syntax tree carries no offsets, so a run's range is found by
  /// walking the masked text alongside the tree. That is exact for everything a
  /// note normally holds; it can be off when the parser *rewrites* text rather
  /// than dropping markup from it, which character references are the one case
  /// of. A caller that must not act on an uncertain range — a bulk edit, say —
  /// can refuse when this is true rather than guess.
  final bool approximate;

  /// The extension spans the masker set aside, for a renderer that has to draw
  /// them instead of text.
  List<ExtensionSpan> get extensions => masked.spans;

  /// Whether the block has runs at all.
  bool get isEmpty => runs.isEmpty;

  @override
  String toString() =>
      'ParsedBlock(${block.kind.name}, ${runs.length} runs'
      '${approximate ? ', approximate' : ''})';
}
