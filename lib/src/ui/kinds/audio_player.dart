/// The speaker behind the audio note's play buttons (issue #56).
///
/// A seam, not the plugin: widget tests inject a fake, and the production
/// implementation ([AudioplayersClipPlayer]) owns an `audioplayers`
/// player.
library;

import 'package:niman/src/ui/kinds/audioplayers_clip_player.dart'
    show AudioplayersClipPlayer;

/// Plays one clip file at a time.
abstract interface class ClipPlayer {
  /// Plays the file at [absolutePath], stopping any current playback.
  Future<void> play(String absolutePath);

  /// Stops the playback.
  Future<void> stop();

  /// A single event per finished playback (natural end, not [stop]).
  Stream<void> get onFinished;

  /// Releases the player.
  void dispose();
}
