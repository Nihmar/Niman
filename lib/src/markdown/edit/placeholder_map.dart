/// The offset arithmetic around a block's inline placeholders
/// (`docs/records/unified-surface.md` §8.6.0, point 3).
library;

import 'package:meta/meta.dart';

/// One drawn span: the offset of the placeholder's own code unit in the block's
/// text, the source offset it stands for, and how many source characters that
/// is.
typedef DrawnSpan = ({int textOffset, int sourceStart, int sourceLength});

/// The table between a block's two offset spaces, for the blocks that have two.
///
/// A `WidgetSpan` — a formula, an image, a checkbox — is **one** code unit in
/// the paragraph where the source it stands for may be five, so a block holding
/// one has a text offset space and a source offset space, and the two part
/// company after it. `source` mode needs none of this: its render map is the
/// identity, which is what [isIdentity] reports, and so is every block with
/// nothing drawn in it.
///
/// Measured (`test/unit/caret_rectangle_test.dart`): the *pixels* around a
/// placeholder are the painter's own once its dimensions are supplied. So what
/// this carries is arithmetic — which text offset is which source range — while
/// measuring the child to supply those dimensions stays the surface's job.
@immutable
final class PlaceholderMap {
  /// The map of a block with [sourceLength] source characters whose drawn spans
  /// are [spans], in text-offset order.
  const new({required this.sourceLength, required this.spans});

  /// A block of [sourceLength] characters with nothing drawn in it.
  const new identity(this.sourceLength) : spans = const [];

  /// How many source characters the block has.
  final int sourceLength;

  /// The drawn spans, in text-offset order.
  final List<DrawnSpan> spans;

  /// Whether the two offset spaces are one and the same.
  bool get isIdentity => spans.isEmpty;

  /// How many code units the block's text has: one per source character, less
  /// what each drawn span stands for, plus one for each span itself.
  int get textLength {
    var length = sourceLength;
    for (final span in spans) {
      length -= span.sourceLength - 1;
    }
    return length < 0 ? 0 : length;
  }

  /// The source offset a [textOffset] answers for.
  int sourceOf(int textOffset) {
    var source = textOffset;
    for (final span in spans) {
      if (span.textOffset >= textOffset) break;
      source += span.sourceLength - 1;
    }
    return _fit(source, sourceLength);
  }

  /// The text offset a [sourceOffset] answers for.
  ///
  /// A source offset inside a drawn span comes back as that span's own offset:
  /// the source of a formula is not text, and a caret cannot rest in it.
  int textOf(int sourceOffset) {
    var text = sourceOffset;
    for (final span in spans) {
      if (sourceOffset >= span.sourceStart + span.sourceLength) {
        text -= span.sourceLength - 1;
      } else if (sourceOffset >= span.sourceStart) {
        return span.textOffset;
      } else {
        break;
      }
    }
    return _fit(text, textLength);
  }

  /// The source range a [textOffset] stands for: the whole of a drawn span when
  /// the offset is the placeholder's own, and the single character it is
  /// otherwise.
  (int, int) sourceRangeOf(int textOffset) {
    for (final span in spans) {
      if (span.textOffset == textOffset) {
        return (span.sourceStart, span.sourceStart + span.sourceLength);
      }
    }
    final start = sourceOf(textOffset);
    return (start, start + 1);
  }

  static int _fit(int offset, int length) =>
      offset < 0 ? 0 : (offset > length ? length : offset);

  @override
  String toString() => isIdentity
      ? 'PlaceholderMap.identity($sourceLength)'
      : 'PlaceholderMap($sourceLength -> $textLength, ${spans.length} drawn)';
}
