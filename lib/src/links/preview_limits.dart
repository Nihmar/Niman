/// How much of a note a preview reads.
abstract final class PreviewLimits {
  /// The bytes read off the front of a note: a card shows a screenful and the
  /// heading or block it was asked for, and a novel-length note is not read
  /// whole to show them. A heading past this is not found (the card shows the
  /// top).
  static const int bytes = 256 * 1024;

  /// How many previews are kept, by note and revision.
  static const int kept = 16;
}
