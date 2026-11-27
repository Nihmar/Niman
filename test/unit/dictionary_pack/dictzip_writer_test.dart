import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/dictzip_writer.dart';

/// Inflates [chunk] on its own, as a dictzip reader does.
List<int> _inflateAlone(List<int> chunk) {
  final filter = RawZLibFilter.inflateFilter(raw: true)
    ..process(chunk, 0, chunk.length);
  final out = <int>[];
  for (;;) {
    final part = filter.processed(flush: false);
    if (part == null || part.isEmpty) break;
    out.addAll(part);
  }
  return out;
}

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_dictzip_test');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  Uint8List sample(int length) {
    final random = Random(3);
    // Text that compresses, with stretches of noise that do not, so the
    // chunks differ in their compressed sizes.
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = (i ~/ 5000).isOdd ? random.nextInt(256) : 97 + (i * 7 % 13);
    }
    return bytes;
  }

  for (final length in [0, 1, dictzipChunkLength, 200000]) {
    test('a dictzip file of $length bytes is gzip and chunked', () {
      final data = sample(length);
      final source = File(p.join(dir.path, 'x.dict'))..writeAsBytesSync(data);
      final target = File(p.join(dir.path, 'x.dict.dz'));
      final result = writeDictzip(source, target, name: 'x.dict');
      final bytes = target.readAsBytesSync();

      expect(result.uncompressed, length);
      expect(result.compressed, bytes.length);
      expect(gzip.decode(bytes), data, reason: 'a plain gunzip reads it');

      final table = readDictzipTable(bytes);
      expect(table.chunkLength, dictzipChunkLength);
      expect(table.sizes, hasLength(result.chunks));
      expect(
        result.chunks,
        length == 0
            ? 1
            : (length + dictzipChunkLength - 1) ~/ dictzipChunkLength,
      );

      var at = table.dataStart;
      for (var i = 0; i < table.sizes.length; i++) {
        final packed = bytes.sublist(at, at + table.sizes[i]);
        at += table.sizes[i];
        final start = i * table.chunkLength;
        final end = min(start + table.chunkLength, length);
        expect(
          _inflateAlone(packed),
          data.sublist(start, end),
          reason: 'chunk $i inflates alone',
        );
        if (i < table.sizes.length - 1) {
          expect(packed.sublist(packed.length - 4), [
            0,
            0,
            0xff,
            0xff,
          ], reason: 'a chunk ends in the empty stored block of a full flush');
        }
      }
      expect(bytes.length - at, 8, reason: 'the CRC-32 and size trailer');
      expect(source.existsSync(), isTrue);
      expect(File('${target.path}.body').existsSync(), isFalse);
    });
  }
}
