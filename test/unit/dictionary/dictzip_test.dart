// Random access into a `.dict.dz` (docs/records/dictionary.md): the RA
// chunk table of the gzip header, each chunk inflated alone, and the plain
// `.dict` the engine reads too.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictzip_file.dart';
import 'package:path/path.dart' as p;

import 'pack_writer.dart';

/// What `test/fixtures/dictionary/zlib_full_flush.dict.dz` holds: 1,500 lines,
/// compressed by zlib itself with `Z_FULL_FLUSH` between 4,000-byte chunks
/// (Python's `zlib.compressobj`), with a file name in the gzip header.
Uint8List _fixtureData() => Uint8List.fromList(
  utf8.encode(
    [
      for (var i = 0; i < 1500; i++)
        'line $i some repeated text lorem ipsum dolor sit amet\n',
    ].join(),
  ),
);

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('niman_dz'));
  tearDown(() => root.deleteSync(recursive: true));

  test('every entry of a real zlib dictzip reads back, alone or across '
      'chunks', () async {
    final data = _fixtureData();
    final file = await DictzipFile.open(
      p.join('test', 'fixtures', 'dictionary', 'zlib_full_flush.dict.dz'),
    );
    addTearDown(file.close);
    expect(file.chunkLength, 4000);
    expect(file.chunkCount, 21);
    // Inside one chunk, across a boundary, over three chunks, the first
    // and the very last bytes.
    for (final (offset, size) in [
      (0, 10),
      (3995, 10),
      (3000, 9000),
      (data.length - 7, 7),
      (12345, 1),
    ]) {
      expect(
        await file.read(offset, size),
        data.sublist(offset, offset + size),
        reason: '$size bytes at $offset',
      );
    }
  });

  test('a dictzip written by the test helper reads back everywhere', () async {
    final data = Uint8List.fromList([
      for (var i = 0; i < 50000; i++) (i * 7 + i ~/ 13) & 0xFF,
    ]);
    File(p.join(root.path, 'x.dict.dz'))
        .writeAsBytesSync(dictzip(data, chunkLength: 1000));
    final file = await DictzipFile.open(p.join(root.path, 'x.dict.dz'));
    addTearDown(file.close);
    expect(file.chunkCount, 50);
    for (var offset = 0; offset < data.length; offset += 997) {
      final size = (offset + 1500 > data.length) ? data.length - offset : 1500;
      expect(
        await file.read(offset, size),
        data.sublist(offset, offset + size),
      );
    }
    // The same chunk twice (a cache hit) and an empty read.
    expect(await file.read(10, 5), data.sublist(10, 15));
    expect(await file.read(10, 0), isEmpty);
  });

  test('a read past the end is reported', () async {
    final data = Uint8List(2500);
    File(p.join(root.path, 'x.dict.dz'))
        .writeAsBytesSync(dictzip(data, chunkLength: 1000));
    final file = await DictzipFile.open(p.join(root.path, 'x.dict.dz'));
    addTearDown(file.close);
    expect(file.read(2400, 500), throwsA(isA<DictionaryException>()));
  });

  test('a file that is not dictzip is reported when opened', () async {
    final plain = File(p.join(root.path, 'x.dict.dz'))
      ..writeAsBytesSync(utf8.encode('not gzip at all'));
    expect(DictzipFile.open(plain.path), throwsA(isA<DictionaryException>()));
    // Plain gzip, without the RA field.
    plain.writeAsBytesSync(gzip.encode(utf8.encode('plain gzip')));
    expect(DictzipFile.open(plain.path), throwsA(isA<DictionaryException>()));
  });

  test('DictSource opens the compressed data, else the plain one', () async {
    final data = Uint8List.fromList(utf8.encode('hello dictionary world'));
    final dir = Directory(p.join(root.path, 'niman-it'))..createSync();
    expect(await DictSource.open(dir.path, 'niman-it'), isNull);
    File(p.join(dir.path, 'niman-it.dict')).writeAsBytesSync(data);
    final plain = (await DictSource.open(dir.path, 'niman-it'))!;
    expect(utf8.decode(await plain.read(6, 10)), 'dictionary');
    await plain.close();
    File(p.join(dir.path, 'niman-it.dict.dz')).writeAsBytesSync(dictzip(data));
    final packed = (await DictSource.open(dir.path, 'niman-it'))!;
    expect(packed, isA<DictzipFile>());
    expect(utf8.decode(await packed.read(6, 10)), 'dictionary');
    await packed.close();
  });
}
