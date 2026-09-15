// The audio note shows each recording's length before it is played: WAV
// headers are read off the UI isolate.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/wav_duration.dart';
import 'package:path/path.dart' as p;

/// A PCM WAV file: [dataBytes] of silence at [byteRate], with the `data`
/// size field set to [declared] (defaults to the real size), after an
/// optional odd-sized `LIST` chunk.
Uint8List _wav({
  required int dataBytes,
  int byteRate = 32000,
  int? declared,
  bool listChunk = false,
}) {
  final builder = BytesBuilder();
  void tag(String s) => builder.add(s.codeUnits);
  void u32(int v) => builder.add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );
  void u16(int v) => builder.add(
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List(),
  );
  tag('RIFF');
  u32(0);
  tag('WAVE');
  tag('fmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(byteRate ~/ 2);
  u32(byteRate);
  u16(2);
  u16(16);
  if (listChunk) {
    tag('LIST');
    u32(3);
    builder.add([1, 2, 3, 0]);
  }
  tag('data');
  u32(declared ?? dataBytes);
  builder.add(Uint8List(dataBytes));
  return builder.toBytes();
}

void main() {
  group('wavDurationOf', () {
    test('reads the data size over the byte rate', () {
      final bytes = _wav(dataBytes: 48000);
      expect(
        wavDurationOf(bytes, bytes.length),
        const Duration(milliseconds: 1500),
      );
    });

    test('skips odd-sized chunks before data', () {
      final bytes = _wav(dataBytes: 16000, listChunk: true);
      expect(
        wavDurationOf(bytes, bytes.length),
        const Duration(milliseconds: 500),
      );
    });

    test('an unpatched data size falls back to the bytes on disk', () {
      final bytes = _wav(dataBytes: 32000, declared: 0xFFFFFFFF);
      expect(wavDurationOf(bytes, bytes.length), const Duration(seconds: 1));
    });

    test('a non-WAV header has no length', () {
      final bytes = Uint8List.fromList('ID3 not a wav file at all'.codeUnits);
      expect(wavDurationOf(bytes, bytes.length), isNull);
    });
  });

  test('readWavDurations probes WAV files and skips the rest', () async {
    final dir = await Directory.systemTemp.createTemp('niman_wav_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Windows may still hold the handle for a moment.
      }
    });
    final wav = p.join(dir.path, 'a.wav');
    await File(wav).writeAsBytes(_wav(dataBytes: 64000));
    final mp3 = p.join(dir.path, 'b.mp3');
    await File(mp3).writeAsBytes([1, 2, 3]);
    final missing = p.join(dir.path, 'gone.wav');

    final durations = await readWavDurations([wav, mp3, missing]);
    expect(durations, {wav: const Duration(seconds: 2)});
  });
}
