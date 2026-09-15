import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:niman/src/transcription/wav_resampler.dart';

/// The sample rate whisper.cpp reads (anything else is rejected).
const int whisperSampleRate = 16000;

/// What [convertWavForWhisper] did, for the log.
typedef WavConversion = ({
  int sampleRate,
  int channels,
  int bits,
  int inputFrames,
  int outputFrames,
  int bytesIn,
  int bytesOut,
  int readMs,
  int dspMs,
  int writeMs,
  int totalMs,
});

/// A file [convertWavForWhisper] cannot read; [reason] is short and safe
/// to log.
final class UnsupportedAudioException implements Exception {
  /// Creates the failure with [reason].
  const new(this.reason);

  /// What the file is missing.
  final String reason;

  @override
  String toString() => 'UnsupportedAudioException: $reason';
}

/// Writes [source], a WAV file, to [target] as the 16 kHz mono PCM16 WAV
/// whisper.cpp accepts, off the UI isolate.
///
/// The app records with the `record` defaults (44.1 kHz), and whisper.cpp
/// refuses any other rate (docs/dev/transcription.md). Integer PCM of 8,
/// 16, 24 or 32 bits and 32/64-bit float are read, any channel count is
/// averaged to mono, and the rate is converted with a windowed-sinc
/// filter whose cutoff sits below the new Nyquist frequency, so speech
/// above 8 kHz does not fold back as noise. The file is streamed in
/// blocks: memory does not grow with the recording's length.
Future<WavConversion> convertWavForWhisper({
  required String source,
  required String target,
}) => Isolate.run(() => _convert(source, target));

Future<WavConversion> _convert(String source, String target) async {
  final total = Stopwatch()..start();
  final read = Stopwatch();
  final dsp = Stopwatch();
  final write = Stopwatch();
  final input = await File(source).open();
  RandomAccessFile? output;
  try {
    final format = await _readFormat(input);
    await input.setPosition(format.dataOffset);
    output = await File(target).open(mode: FileMode.write);
    await output.writeFrom(_header(0));

    final frameBytes = format.channels * format.bytesPerSample;
    final resampler = WavResampler(format.sampleRate, whisperSampleRate);
    var remaining = format.dataBytes - format.dataBytes % frameBytes;
    var bytesIn = 0;
    var carry = Uint8List(0);
    const blockFrames = 16384;
    while (remaining > 0) {
      read.start();
      final chunk = await input.read(
        math.min(remaining, blockFrames * frameBytes),
      );
      read.stop();
      if (chunk.isEmpty) break;
      remaining -= chunk.length;
      bytesIn += chunk.length;

      dsp.start();
      final bytes = carry.isEmpty
          ? chunk
          : (BytesBuilder(copy: false)
                  ..add(carry)
                  ..add(chunk))
                .takeBytes();
      final whole = bytes.length - bytes.length % frameBytes;
      carry = Uint8List.fromList(bytes.sublist(whole));
      final samples = resampler.push(
        _decodeMono(Uint8List.sublistView(bytes, 0, whole), format),
      );
      dsp.stop();

      write.start();
      if (samples.isNotEmpty) {
        await output.writeFrom(samples.buffer.asUint8List());
      }
      write.stop();
    }
    dsp.start();
    final tail = resampler.finish();
    dsp.stop();
    write.start();
    if (tail.isNotEmpty) await output.writeFrom(tail.buffer.asUint8List());
    final dataBytes = resampler.outputFrames * 2;
    await output.setPosition(0);
    await output.writeFrom(_header(dataBytes));
    write.stop();
    return (
      sampleRate: format.sampleRate,
      channels: format.channels,
      bits: format.bitsPerSample,
      inputFrames: resampler.inputFrames,
      outputFrames: resampler.outputFrames,
      bytesIn: bytesIn,
      bytesOut: 44 + dataBytes,
      readMs: read.elapsedMilliseconds,
      dspMs: dsp.elapsedMilliseconds,
      writeMs: write.elapsedMilliseconds,
      totalMs: total.elapsedMilliseconds,
    );
  } finally {
    await input.close();
    await output?.close();
  }
}

typedef _Format = ({
  int code,
  int channels,
  int sampleRate,
  int bitsPerSample,
  int bytesPerSample,
  int dataOffset,
  int dataBytes,
});

const int _pcm = 1;
const int _float = 3;
const int _extensible = 0xFFFE;

/// Walks the RIFF chunks of [file] up to `data`, however many chunks a
/// recorder put before it.
Future<_Format> _readFormat(RandomAccessFile file) async {
  final length = await file.length();
  final riff = await file.read(12);
  if (riff.length < 12 ||
      String.fromCharCodes(riff, 0, 4) != 'RIFF' ||
      String.fromCharCodes(riff, 8, 12) != 'WAVE') {
    throw const UnsupportedAudioException('not a WAV file');
  }
  int? code;
  int? channels;
  int? rate;
  int? bits;
  var position = 12;
  while (position + 8 <= length) {
    await file.setPosition(position);
    final head = await file.read(8);
    if (head.length < 8) break;
    final id = String.fromCharCodes(head, 0, 4);
    final size = ByteData.sublistView(head).getUint32(4, Endian.little);
    final body = position + 8;
    if (id == 'fmt ') {
      final fmt = ByteData.sublistView(await file.read(math.min(size, 40)));
      if (fmt.lengthInBytes < 16) break;
      code = fmt.getUint16(0, Endian.little);
      channels = fmt.getUint16(2, Endian.little);
      rate = fmt.getUint32(4, Endian.little);
      bits = fmt.getUint16(14, Endian.little);
      // WAVE_FORMAT_EXTENSIBLE carries the real format in its sub-format
      // GUID, whose first two bytes are the classic format code.
      if (code == _extensible && fmt.lengthInBytes >= 26) {
        code = fmt.getUint16(24, Endian.little);
      }
    } else if (id == 'data') {
      if (code == null || channels == null || rate == null || bits == null) {
        throw const UnsupportedAudioException('data before the format');
      }
      final supported =
          (code == _pcm && const {8, 16, 24, 32}.contains(bits)) ||
          (code == _float && (bits == 32 || bits == 64));
      if (!supported || channels < 1 || rate < 1) {
        throw UnsupportedAudioException(
          'format $code, $bits bit, $channels ch, $rate Hz',
        );
      }
      final onDisk = length - body;
      // A recorder that never patched the size (0 or 0xFFFFFFFF), or
      // wrote one past the end, leaves the bytes actually there.
      final dataBytes = size == 0 || size == 0xFFFFFFFF || size > onDisk
          ? onDisk
          : size;
      return (
        code: code,
        channels: channels,
        sampleRate: rate,
        bitsPerSample: bits,
        bytesPerSample: bits ~/ 8,
        dataOffset: body,
        dataBytes: dataBytes,
      );
    }
    position = body + size + (size.isOdd ? 1 : 0);
  }
  throw const UnsupportedAudioException('no audio data');
}

/// The frames in [bytes] averaged to one channel, in -1..1.
Float64List _decodeMono(Uint8List bytes, _Format format) {
  final data = ByteData.sublistView(bytes);
  final channels = format.channels;
  final width = format.bytesPerSample;
  final frames = bytes.length ~/ (channels * width);
  final out = Float64List(frames);
  var offset = 0;
  for (var f = 0; f < frames; f++) {
    var sum = 0.0;
    for (var c = 0; c < channels; c++) {
      sum += switch ((format.code, width)) {
        (_pcm, 1) => (data.getUint8(offset) - 128) / 128,
        (_pcm, 2) => data.getInt16(offset, Endian.little) / 32768,
        (_pcm, 3) =>
          (data.getUint8(offset) |
                  data.getUint8(offset + 1) << 8 |
                  data.getInt8(offset + 2) << 16) /
              8388608,
        (_pcm, _) => data.getInt32(offset, Endian.little) / 2147483648,
        (_, 4) => data.getFloat32(offset, Endian.little),
        _ => data.getFloat64(offset, Endian.little),
      };
      offset += width;
    }
    out[f] = sum / channels;
  }
  return out;
}

/// A 44-byte PCM16 mono 16 kHz WAV header for [dataBytes] of samples.
Uint8List _header(int dataBytes) {
  final header = ByteData(44);
  void tag(int at, String value) {
    for (var i = 0; i < 4; i++) {
      header.setUint8(at + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  header.setUint32(4, 36 + dataBytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, _pcm, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, whisperSampleRate, Endian.little)
    ..setUint32(28, whisperSampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, dataBytes, Endian.little);
  return header.buffer.asUint8List();
}
