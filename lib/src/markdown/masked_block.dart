/// A block's text with its extension spans replaced by placeholders.
///
/// The parser reads `text`; the renderer reads `spans`. The two agree character
/// for character, which is the whole point: a placeholder run is exactly as
/// long as the span it stands for, so nothing has to be translated between what
/// the parser saw and where the note's own constructs are.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/extension_span.dart';

/// A block, ready for the parser, with its own constructs set aside.
@immutable
final class MaskedBlock {
  /// Creates a masked block.
  const new({required this.text, required this.spans});

  /// The text to hand the parser: the block's own, with every span replaced by
  /// placeholders of the same length.
  final String text;

  /// The spans that were masked, in offset order and non-overlapping.
  final List<ExtensionSpan> spans;

  /// Whether anything was masked.
  bool get isMasked => spans.isNotEmpty;

  /// The span covering [offset], or null — a binary search, since a caller maps
  /// a parsed position back to a span on every inline visit.
  ExtensionSpan? spanAt(int offset) {
    var low = 0;
    var high = spans.length - 1;
    while (low <= high) {
      final middle = (low + high) >> 1;
      final span = spans[middle];
      if (span.end <= offset) {
        low = middle + 1;
      } else if (span.start > offset) {
        high = middle - 1;
      } else {
        return span;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'MaskedBlock(${spans.length} spans, ${text.length} chars)';
}
