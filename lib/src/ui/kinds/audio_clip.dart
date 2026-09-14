/// One voice recording linked from an audio note's body.
library;

/// A single clip of an `type: audio` note: a Markdown audio embed
/// (`![](assets/clip.wav)`) on [line].
final class AudioClip {
  /// Creates a clip.
  const new({required this.line, required this.start, required this.target});

  /// The 0-based index of the embed's line in the note text (split on
  /// `\n`).
  final int line;

  /// The offset of the embed's `!` within the line.
  final int start;

  /// The embed target as written (`assets/clip-01.wav`).
  final String target;

  /// The file name of the clip (`clip-01.wav`).
  String get name {
    final cut = target.lastIndexOf('/');
    return cut < 0 ? target : target.substring(cut + 1);
  }
}
