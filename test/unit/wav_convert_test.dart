import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/wav_convert.dart';
import 'package:path/path.dart' as p;

/// A WAV of [seconds] of a [hz] sine at [amplitude], written as
/// [format] (1 = PCM, 3 = float, 0xFFFE = extensible PCM).
Uint8List _sineWav({
  required int rate,
  required int channels,
  required int bits,
  double hz = 440,
  double amplitude = 0.5,
  double seconds = 1,
  int format = 1,
}) {
  final frames = (rate * seconds).round();
  final width = bits ~/ 8;
  final data = ByteData(frames * channels * width);
  var offset = 0;
  for (var f = 0; f < frames; f++) {
    final value = amplitude * math.sin(2 * math.pi * hz * f / rate);
    for (var c = 0; c < channels; c++) {
      switch ((format == 3, bits)) {
        case (true, 32):
          data.setFloat32(offset, value, Endian.little);
        case (_, 16):
          data.setInt16(offset, (value * 32767).round(), Endian.little);
        case (_, 24):
          final v = (value * 8388607).round();
          data
            ..setUint8(offset, v & 0xFF)
            ..setUint8(offset + 1, (v >> 8) & 0xFF)
            ..setUint8(offset + 2, (v >> 16) & 0xFF);
        default:
          throw UnsupportedError('$bits');
      }
      offset += width;
    }
  }
  final extensible = format == 0xFFFE;
  final fmtSize = extensible ? 40 : 16;
  final header = ByteData(12 + 8 + fmtSize + 8);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      header.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  header.setUint32(
    4,
    header.lengthInBytes - 8 + data.lengthInBytes,
    Endian.little,
  );
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header
    ..setUint32(16, fmtSize, Endian.little)
    ..setUint16(20, format, Endian.little)
    ..setUint16(22, channels, Endian.little)
    ..setUint32(24, rate, Endian.little)
    ..setUint32(28, rate * channels * width, Endian.little)
    ..setUint16(32, channels * width, Endian.little)
    ..setUint16(34, bits, Endian.little);
  if (extensible) {
    header
      ..setUint16(36, 22, Endian.little)
      ..setUint16(38, bits, Endian.little)
      ..setUint32(40, 3, Endian.little)
      // Sub-format GUID: the first two bytes are the classic format code.
      ..setUint16(44, 1, Endian.little);
  }
  tag(20 + fmtSize, 'data');
  header.setUint32(24 + fmtSize, data.lengthInBytes, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(data.buffer.asUint8List()))
      .takeBytes();
}

/// The samples of a converted file, after checking its header.
Int16List _readConverted(File file) {
  final bytes = file.readAsBytesSync();
  final header = ByteData.sublistView(bytes, 0, 44);
  expect(String.fromCharCodes(bytes, 0, 4), 'RIFF');
  expect(header.getUint16(20, Endian.little), 1, reason: 'PCM');
  expect(header.getUint16(22, Endian.little), 1, reason: 'mono');
  expect(header.getUint32(24, Endian.little), whisperSampleRate);
  expect(header.getUint16(34, Endian.little), 16);
  final dataBytes = header.getUint32(40, Endian.little);
  expect(dataBytes, bytes.length - 44);
  expect(header.getUint32(4, Endian.little), bytes.length - 8);
  return Int16List.sublistView(
    Uint8List.fromList(bytes.sublist(44)).buffer.asByteData(),
  );
}

/// The RMS of [samples] in -1..1, skipping the filter's edges.
double _rms(Int16List samples) {
  final middle = samples.sublist(800, samples.length - 800);
  var sum = 0.0;
  for (final s in middle) {
    sum += (s / 32768) * (s / 32768);
  }
  return math.sqrt(sum / middle.length);
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_wav_convert_');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<(WavConversion, Int16List)> convert(Uint8List wav) async {
    final source = File(p.join(dir.path, 'in.wav'))..writeAsBytesSync(wav);
    final target = p.join(dir.path, 'out.wav');
    final report = await convertWavForWhisper(
      source: source.path,
      target: target,
    );
    return (report, _readConverted(File(target)));
  }

  test(
    'the app recording format becomes 16 kHz mono at the same level',
    () async {
      final (report, samples) = await convert(
        _sineWav(rate: 44100, channels: 2, bits: 16, seconds: 2),
      );
      expect(report.sampleRate, 44100);
      expect(report.channels, 2);
      expect(report.inputFrames, 88200);
      expect(samples.length, closeTo(32000, 2));
      expect(report.outputFrames, samples.length);
      // A 0.5 sine has an RMS of 0.354; a 440 Hz tone passes the filter.
      expect(_rms(samples), closeTo(0.5 / math.sqrt2, 0.01));
    },
  );

  test('content above the new Nyquist frequency does not fold back', () async {
    final (_, samples) = await convert(
      _sineWav(rate: 44100, channels: 1, bits: 16, hz: 10000),
    );
    // Without the filter, 10 kHz would alias to 6 kHz at full level.
    expect(_rms(samples), lessThan(0.02));
  });

  test('16 kHz mono passes through unchanged in length and level', () async {
    final (report, samples) = await convert(
      _sineWav(rate: 16000, channels: 1, bits: 16, seconds: 1.5),
    );
    expect(report.outputFrames, 24000);
    expect(_rms(samples), closeTo(0.5 / math.sqrt2, 0.005));
  });

  test('24-bit, float and extensible files are read', () async {
    for (final wav in [
      _sineWav(rate: 48000, channels: 1, bits: 24),
      _sineWav(rate: 22050, channels: 2, bits: 32, format: 3),
      _sineWav(rate: 44100, channels: 1, bits: 16, format: 0xFFFE),
    ]) {
      final (_, samples) = await convert(wav);
      expect(samples.length, closeTo(16000, 2));
      expect(_rms(samples), closeTo(0.5 / math.sqrt2, 0.01));
    }
  });

  test('anything but WAV is refused with a reason', () async {
    final source = File(p.join(dir.path, 'clip.m4a'))
      ..writeAsBytesSync(List.filled(100, 7));
    await expectLater(
      convertWavForWhisper(
        source: source.path,
        target: p.join(dir.path, 'out.wav'),
      ),
      throwsA(isA<UnsupportedAudioException>()),
    );
  });
}
