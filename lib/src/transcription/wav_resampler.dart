import 'dart:math' as math;
import 'dart:typed_data';

/// A streaming windowed-sinc sample-rate converter to 16-bit output.
///
/// Output sample n sits at input position n × inRate / outRate. Its value
/// is the input around that position weighted by a Hann-windowed sinc
/// whose cutoff is 90% of the lower Nyquist frequency. The weights are
/// precomputed for 256 sub-sample positions and normalized to sum to one,
/// so the filter neither amplifies nor attenuates speech.
final class WavResampler {
  /// A converter from [inRate] to [outRate] samples per second.
  new(this.inRate, this.outRate)
    : _step = inRate / outRate,
      _half = inRate == outRate
          ? 0
          : (_zeroCrossings / (math.min(inRate, outRate) / inRate * 0.9))
                .ceil() {
    if (_half == 0) return;
    final cutoff = math.min(inRate, outRate) / inRate * 0.9;
    final taps = 2 * _half;
    _kernel = Float64List((_phases + 1) * taps);
    for (var phase = 0; phase <= _phases; phase++) {
      final frac = phase / _phases;
      var sum = 0.0;
      for (var j = 0; j < taps; j++) {
        // Tap j covers input sample floor(t) - half + 1 + j.
        final x = (j - _half + 1) - frac;
        final sinc = x == 0
            ? 1.0
            : math.sin(math.pi * cutoff * x) / (math.pi * cutoff * x);
        final window = x.abs() >= _half
            ? 0.0
            : 0.5 + 0.5 * math.cos(math.pi * x / _half);
        final weight = sinc * window;
        _kernel[phase * taps + j] = weight;
        sum += weight;
      }
      for (var j = 0; j < taps; j++) {
        _kernel[phase * taps + j] /= sum;
      }
    }
  }

  static const int _zeroCrossings = 8;
  static const int _phases = 256;

  /// The input rate.
  final int inRate;

  /// The output rate.
  final int outRate;
  final double _step;
  final int _half;
  late final Float64List _kernel;

  Float64List _buffer = Float64List(1 << 16);
  int _bufferStart = 0; // absolute input index of _buffer[0]
  int _bufferLength = 0;

  /// Input frames pushed so far.
  int inputFrames = 0;

  /// Output frames produced so far.
  int outputFrames = 0;

  /// Adds [samples] and returns the output they complete.
  Int16List push(Float64List samples) {
    inputFrames += samples.length;
    if (_half == 0) return _toInt16(samples);
    _append(samples);
    return _produce(end: false);
  }

  /// Returns the output still owed once the input has ended, reading
  /// silence past the last sample.
  Int16List finish() => _half == 0 ? Int16List(0) : _produce(end: true);

  void _append(Float64List samples) {
    if (_bufferLength + samples.length > _buffer.length) {
      final grown = Float64List(
        math.max(_buffer.length * 2, _bufferLength + samples.length),
      )..setRange(0, _bufferLength, _buffer);
      _buffer = grown;
    }
    _buffer.setRange(_bufferLength, _bufferLength + samples.length, samples);
    _bufferLength += samples.length;
  }

  Int16List _produce({required bool end}) {
    final available = _bufferStart + _bufferLength;
    final out = <int>[];
    final taps = 2 * _half;
    while (true) {
      final t = outputFrames * _step;
      if (end ? t >= inputFrames : t.floor() + _half >= available) break;
      final base = t.floor();
      final phase = ((t - base) * _phases).round();
      final row = phase * taps;
      var value = 0.0;
      final first = base - _half + 1;
      for (var j = 0; j < taps; j++) {
        final index = first + j - _bufferStart;
        if (index < 0 || index >= _bufferLength) continue;
        value += _kernel[row + j] * _buffer[index];
      }
      out.add((value * 32767).round().clamp(-32768, 32767));
      outputFrames++;
    }
    // Keep only what the next output sample can still reach.
    final keepFrom = (outputFrames * _step).floor() - _half;
    final drop = (keepFrom - _bufferStart).clamp(0, _bufferLength);
    if (drop > 0) {
      _buffer.setRange(0, _bufferLength - drop, _buffer, drop);
      _bufferLength -= drop;
      _bufferStart += drop;
    }
    return Int16List.fromList(out);
  }

  Int16List _toInt16(Float64List samples) {
    final out = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      out[i] = (samples[i] * 32767).round().clamp(-32768, 32767);
    }
    outputFrames += samples.length;
    return out;
  }
}
