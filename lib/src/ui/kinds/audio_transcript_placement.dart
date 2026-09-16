import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/ui/kinds/audio_chat.dart';

/// The note text with a finished transcript in its clip's description.
typedef TranscriptEdit = ({
  /// The whole note text after the edit.
  String text,

  /// The clip's description before it.
  String previous,

  /// The clip's description after it.
  String written,

  /// Whether a replace became an append because the description changed
  /// while the transcription ran.
  bool keptEdits,
});

/// Puts [job]'s transcript into its clip's description in [noteText], or
/// returns null when the clip is no longer in the note.
///
/// The clip is found by its embed target, so whatever else changed in the
/// note meanwhile stays. [TranscriptPlacement.replace] replaces the
/// description only while it is still the one the transcription was asked
/// over; if someone edited it in between, the transcript goes below it
/// instead, so no hand-written text is lost. [TranscriptPlacement.append]
/// adds it as a new paragraph (or fills an empty description).
TranscriptEdit? placeTranscript(String noteText, TranscriptionJob job) {
  final transcript = job.text ?? '';
  final vocal = vocalByTarget(noteText, job.clipTarget);
  if (vocal == null) return null;
  final previous = vocal.description;
  final changed = previous.trim() != job.originalDescription.trim();
  final replace = job.placement == TranscriptPlacement.replace && !changed;
  final written = replace || previous.trim().isEmpty
      ? transcript
      : '$previous\n\n$transcript';
  return (
    text: setClipDescription(noteText, vocal.clip, written),
    previous: previous,
    written: written,
    keptEdits: job.placement == TranscriptPlacement.replace && changed,
  );
}

/// The vocal whose clip links [target] in [text], or null.
AudioChatMessage? vocalByTarget(String text, String target) {
  for (final item in parseAudioChat(text)) {
    if (item is AudioChatMessage && item.clip.target == target) return item;
  }
  return null;
}
