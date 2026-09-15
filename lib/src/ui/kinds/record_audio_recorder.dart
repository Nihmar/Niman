import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:record/record.dart' as record;

/// The production [VoiceRecorder]: the `record` plugin.
///
/// WAV (PCM 16-bit) is the one encoder the plugin offers on Android,
/// Linux and Windows alike, so a clip recorded on one OS plays on the
/// others with no extra codec — including the Linux build, where encoding
/// rides the system's `ffmpeg`/`parecord`.
final class RecordVoiceRecorder implements VoiceRecorder {
  /// Creates a recorder over the `record` plugin.
  new() : _record = record.AudioRecorder();

  final record.AudioRecorder _record;

  @override
  Future<bool> hasPermission() => _record.hasPermission();

  @override
  Future<void> start({required String path}) {
    return _record.start(
      const record.RecordConfig(encoder: record.AudioEncoder.wav),
      path: path,
    );
  }

  @override
  Future<void> pause() => _record.pause();

  @override
  Future<void> resume() => _record.resume();

  @override
  Future<String?> stop() => _record.stop();

  @override
  Future<void> cancel() => _record.cancel();

  @override
  void dispose() => _record.dispose();
}
