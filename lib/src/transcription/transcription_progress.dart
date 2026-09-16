import 'dart:async';

/// The progress shown while whisper runs, in 0..1.
///
/// whisper reports only two or three steps for a short clip, so a bar fed
/// by them alone jumps and stalls. This blends them with an estimate from
/// the clip's length × its real-time factor, ticking every 250 ms and capped
/// at 95% until the text is back.
final class TranscriptionProgress {
  /// Starts estimating [lengthMs] of audio at [realTimeFactor] seconds of
  /// work per second of audio, calling [onChanged] when the value grows.
  new({
    required int lengthMs,
    required double realTimeFactor,
    required void Function(double progress) onChanged,
  }) : expectedMs = lengthMs * realTimeFactor {
    _clock.start();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final guess = expectedMs <= 0
          ? 0.0
          : _clock.elapsedMilliseconds / expectedMs;
      final next = (guess > _reported ? guess : _reported).clamp(0.0, 0.95);
      if (next > _value) {
        _value = next;
        onChanged(next);
      }
    });
  }

  /// How long the estimate expects whisper to take.
  final double expectedMs;

  final Stopwatch _clock = Stopwatch();
  late final Timer _timer;
  double _reported = 0;
  double _value = 0;

  /// The steps whisper reported so far.
  int steps = 0;

  /// Milliseconds since the estimate started.
  int get elapsedMs => _clock.elapsedMilliseconds;

  /// Takes one of whisper's own 0–100 steps.
  void report(int percent) {
    steps++;
    _reported = percent / 100;
  }

  /// Stops ticking.
  void stop() {
    _timer.cancel();
    _clock.stop();
  }
}
