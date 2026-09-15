import 'package:niman/src/transcription/transcription_model.dart';

/// Where a [TranscriptionJob] is.
enum TranscriptionPhase {
  /// Its model is still downloading.
  waitingForModel,

  /// Waiting for the job ahead of it.
  queued,

  /// Converting the clip for whisper.
  preparing,

  /// Whisper is running.
  transcribing,

  /// Finished: [TranscriptionJob.text] holds the result.
  done,

  /// Finished without a result: [TranscriptionJob.error] says why.
  failed,
}

/// One clip to transcribe, from the moment it is asked for until the note
/// takes its text.
///
/// The queue updates the mutable fields; everything else reads them.
final class TranscriptionJob {
  /// A job for the clip [clipTarget] of the note at [notePath], whose file
  /// is [audioPath].
  new({
    required this.id,
    required this.notePath,
    required this.clipTarget,
    required this.audioPath,
    required this.model,
    required this.language,
    required this.phase,
  });

  /// Unique within the app session.
  final int id;

  /// The note the clip belongs to.
  final String notePath;

  /// The clip's embed target, as written in the note.
  final String clipTarget;

  /// The clip's absolute file path.
  final String audioPath;

  /// The model to transcribe with.
  final TranscriptionModel model;

  /// The whisper language code (`it`, `auto`, …).
  final String language;

  /// Where the job is.
  TranscriptionPhase phase;

  /// Progress while [TranscriptionPhase.transcribing], in 0..1: whisper's
  /// coarse steps blended with an estimate from the clip's length.
  double progress = 0;

  /// The transcript, once [TranscriptionPhase.done] (may be empty: no
  /// speech).
  String? text;

  /// Why the job failed, short and loggable.
  String? error;

  /// Whether [TranscriptionPhase.done] or [TranscriptionPhase.failed].
  bool get finished =>
      phase == TranscriptionPhase.done || phase == TranscriptionPhase.failed;

  @override
  String toString() =>
      'job $id ($clipTarget, ${model.id}, $language, ${phase.name})';
}
