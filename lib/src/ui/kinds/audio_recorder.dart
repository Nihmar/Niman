/// The microphone behind the audio note's record button (issue #56).
///
/// A seam, not the plugin: widget tests inject a fake, and the production
/// implementation ([RecordVoiceRecorder]) owns the `record` plugin.
library;

import 'package:niman/src/ui/kinds/record_audio_recorder.dart'
    show RecordVoiceRecorder;

/// Starts and stops one voice recording.
abstract interface class VoiceRecorder {
  /// Whether the microphone may be used (asks the OS when needed).
  Future<bool> hasPermission();

  /// Starts recording to [path] (a `.wav` file).
  Future<void> start({required String path});

  /// Stops the recording; returns the file path, or null when nothing was
  /// recorded.
  Future<String?> stop();

  /// Cancels the recording, deleting the file.
  Future<void> cancel();

  /// Releases the recorder.
  void dispose();
}
