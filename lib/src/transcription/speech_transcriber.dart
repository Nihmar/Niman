import 'package:niman/src/transcription/transcription_model.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Speech to text over a prepared audio file: whisper in the app, a fake
/// in tests.
abstract interface class SpeechTranscriber {
  /// The raw text spoken in [audioPath] (16 kHz mono PCM16 WAV, or any
  /// format on Android, where the package converts with FFmpeg).
  ///
  /// [language] is an ISO 639-1 code or `auto`; [onProgress] gets coarse
  /// 0–100 steps.
  Future<String> transcribe({
    required TranscriptionModel model,
    required String audioPath,
    required String language,
    void Function(int percent)? onProgress,
  });

  /// Frees the model kept loaded between transcriptions.
  Future<void> release();
}

/// A transcription the engine could not produce; [reason] is short and
/// safe to log.
final class TranscriptionException implements Exception {
  /// Creates the failure with [reason].
  const new(this.reason);

  /// What went wrong.
  final String reason;

  @override
  String toString() => 'TranscriptionException: $reason';
}

/// [SpeechTranscriber] over `whisper_ggml`.
///
/// The model stays loaded after each call (`keepModelLoaded`), so a queue
/// of clips loads it once; the queue calls [release] when it empties.
/// Non-speech tokens (`[BLANK_AUDIO]`, `[MUSIC]`) are suppressed at the
/// source.
final class WhisperTranscriber implements SpeechTranscriber {
  final WhisperController _controller = WhisperController();

  @override
  Future<String> transcribe({
    required TranscriptionModel model,
    required String audioPath,
    required String language,
    void Function(int percent)? onProgress,
  }) async {
    final result = await _controller.transcribe(
      model: model.whisper,
      audioPath: audioPath,
      lang: language,
      suppressNonSpeechTokens: true,
      keepModelLoaded: true,
      onProgress: onProgress,
    );
    // The package swallows the native error and returns null; the reason
    // is only in its debug output.
    if (result == null) {
      throw const TranscriptionException('whisper returned no result');
    }
    return result.transcription.text;
  }

  @override
  Future<void> release() => _controller.releaseModel();
}

/// [raw] as a description: bracketed non-speech markers removed and the
/// segments joined into one paragraph.
String cleanTranscript(String raw) => raw
    .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
