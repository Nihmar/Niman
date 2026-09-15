import 'package:niman/src/ui/kinds/audio_chat.dart';

/// One parsed chat row with a key that survives line shifts: it names
/// the content, not the position, so bubbles keep their identity (their
/// enter/exit animations, their playback) when the note text is edited.
final class AudioChatRow {
  /// Creates a row.
  const new(this.item, this.key);

  /// The row content: an [AudioChatMessage] or a [TextChatMessage].
  final AudioChatItem item;

  /// A stable identity, e.g. `clip:assets/a.wav#0` or `note:hello#1`.
  final String key;

  /// The occurrence index ending [key], used in widget keys
  /// (`audio-play-0`).
  String get suffix => key.substring(key.lastIndexOf('#') + 1);

  /// The chat rows of [text]: the clip's file names vocals, the note text
  /// names written notes, disambiguated by occurrence.
  static List<AudioChatRow> rowsOf(String text) {
    final rows = <AudioChatRow>[];
    var clips = 0;
    var notes = 0;
    for (final item in parseAudioChat(text)) {
      if (item is AudioChatMessage) {
        rows.add(AudioChatRow(item, 'clip:${item.clip.target}#${clips++}'));
      } else {
        final note = item as TextChatMessage;
        rows.add(AudioChatRow(item, 'note:${note.text}#${notes++}'));
      }
    }
    return rows;
  }
}
