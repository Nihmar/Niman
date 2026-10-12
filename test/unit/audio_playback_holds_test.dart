// A clip being played is a file the player holds open (#833): an
// operation on it stops the playback first, the player letting go.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/file_holds.dart';
import 'package:niman/src/ui/kinds/audio_playback.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';
import 'package:path/path.dart' as p;

final class _Player implements ClipPlayer {
  final List<String> calls = [];

  @override
  Future<void> play(String absolutePath) async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Stream<void> get onFinished => const Stream.empty();

  @override
  Stream<Duration> get onPosition => const Stream.empty();

  @override
  Stream<Duration> get onDuration => const Stream.empty();

  @override
  void dispose() {}
}

void main() {
  final clip = p.join(p.current, 'library', 'Audio', 'clip.m4a');

  test('an operation on the clip playing stops it first', () async {
    final holds = FileHolds();
    final player = _Player();
    final playback = AudioPlayback(
      () => player,
      ownsPlayer: true,
      holds: holds,
    );
    addTearDown(playback.dispose);

    await playback.toggle('row', clip);
    expect(holds.holding(clip), hasLength(1));

    await holds.around([p.dirname(clip)], () async {
      expect(player.calls.last, 'stop');
    });
    expect(playback.activeKey, isNull);
    // Stopped, it holds nothing until a clip plays again.
    expect(holds.holding(clip), isEmpty);
  });

  test('a paused clip is held too, and a stopped one is not', () async {
    final holds = FileHolds();
    final playback = AudioPlayback(_Player.new, ownsPlayer: true, holds: holds);
    addTearDown(playback.dispose);

    await playback.toggle('row', clip);
    await playback.toggle('row', clip);
    expect(playback.paused, isTrue);
    expect(holds.holding(clip), hasLength(1));

    await playback.stop();
    expect(holds.holding(clip), isEmpty);
  });
}
