// The unpacker of a downloaded pack (#1382): the archive came from the
// network, so what it will not write matters as much as what it does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/tar_unpacker.dart';
import 'package:path/path.dart' as p;

import 'pack_tar.dart';

void main() {
  late Directory dir;
  late Directory out;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_tar');
    out = Directory(p.join(dir.path, 'out'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  File write(List<int> bytes) =>
      File(p.join(dir.path, 'a.tar'))..writeAsBytesSync(bytes);

  void expectRefused(File archive, [bool Function(String)? accepts]) {
    expect(
      () => TarUnpacker.unpackSync(archive, out, accepts: accepts),
      throwsA(isA<FormatException>()),
    );
  }

  test('a pack as the pipeline archives it is unpacked file by file', () async {
    final tar = await fixtureTar(dir);
    final names = TarUnpacker.unpackSync(tar, out);
    expect(names, [
      'niman-it.ifo',
      'niman-it.idx',
      'niman-it.syn',
      'niman-it.dict.dz',
    ]);
    for (final name in names) {
      final source = File(
        p.join('test', 'fixtures', 'dictionary', 'niman-it', name),
      );
      expect(
        File(p.join(out.path, name)).readAsBytesSync(),
        source.readAsBytesSync(),
        reason: name,
      );
    }
  });

  test('a member bigger than the copy buffer arrives whole', () {
    final big = List<int>.generate((1 << 20) * 2 + 777, (i) => i % 251);
    final names = TarUnpacker.unpackSync(
      write(
        tarBytes([
          (name: 'big.bin', data: big),
          (name: 'b', data: [1]),
        ]),
      ),
      out,
    );
    expect(names, ['big.bin', 'b']);
    expect(File(p.join(out.path, 'big.bin')).readAsBytesSync(), big);
  });

  test('an archive cut inside a member is refused', () async {
    final bytes = (await fixtureTar(dir)).readAsBytesSync();
    expectRefused(write(bytes.sublist(0, 512 + 700)));
    expectRefused(write(bytes.sublist(0, bytes.length - 2000)));
  });

  test('an archive cut at a member boundary has no end marker: refused', () {
    final bytes = tarBytes([
      (name: 'a', data: [1, 2, 3]),
    ], endMarker: false);
    expectRefused(write(bytes));
    expectRefused(write(bytes.sublist(0, 100)));
    expectRefused(write(const []));
  });

  test('a damaged header is refused', () {
    expectRefused(
      write(
        tarBytes([
          (name: 'a', data: [1]),
        ], corruptChecksum: true),
      ),
    );
  });

  test('only plain files with a bare name are written', () {
    for (final name in [
      '../evil',
      'sub/dir',
      r'sub\dir',
      'C:evil',
      '.hidden',
    ]) {
      expectRefused(
        write(
          tarBytes([
            (name: name, data: [1]),
          ]),
        ),
      );
    }
    // A directory, a symbolic link, an extended header.
    for (final type in ['5', '2', 'x']) {
      expectRefused(write(tarBytes([(name: 'a', data: const [])], type: type)));
    }
    expect(File(p.join(dir.path, 'evil')).existsSync(), isFalse);
  });

  test('a name the caller does not expect is refused before it is written', () {
    final archive = write(
      tarBytes([
        (name: 'niman-it.ifo', data: [1]),
        (name: 'surprise.exe', data: [2]),
      ]),
    );
    expectRefused(archive, (name) => name.startsWith('niman-it.'));
    expect(File(p.join(out.path, 'surprise.exe')).existsSync(), isFalse);
  });

  test('a member named twice is refused', () {
    expectRefused(
      write(
        tarBytes([
          (name: 'a', data: [1]),
          (name: 'a', data: [2]),
        ]),
      ),
    );
  });
}
