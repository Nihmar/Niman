import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';

/// The production [ClipPlayer]: one `audioplayers` player per audio view.
final class AudioplayersClipPlayer implements ClipPlayer {
  /// Creates a player; [inner] is a test seam.
  new([AudioPlayer? inner])
    : _player = inner ?? AudioPlayer(),
      _done = StreamController<void>.broadcast() {
    _subscription = _player.onPlayerComplete.listen((_) => _done.add(null));
  }

  final AudioPlayer _player;
  final StreamController<void> _done;
  late final StreamSubscription<void> _subscription;

  @override
  Future<void> play(String absolutePath) =>
      _player.play(DeviceFileSource(absolutePath));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get onFinished => _done.stream;

  @override
  Stream<Duration> get onPosition => _player.onPositionChanged;

  @override
  Stream<Duration> get onDuration => _player.onDurationChanged;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_done.close());
    unawaited(_player.dispose());
  }
}
