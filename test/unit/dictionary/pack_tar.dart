// The archives the install tests unpack: a fixture pack archived the way the
// pipeline archives a real one (`tool/dictionary_pack/pack_archive.dart`),
// and ustar bytes assembled by hand, so a test can break exactly one thing.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/pack_archive.dart';
import 'fixture_packs.dart';

/// `<out>/<id>.tar`: the fixture pack [id] (`niman-it`) archived as the
/// pipeline publishes it.
Future<File> fixtureTar(Directory out, [String id = 'niman-it']) async {
  final source = Directory(p.join(out.path, 'source'))
    ..createSync(recursive: true);
  await writeFixturePacks(source.path);
  final tar = File(p.join(out.path, '$id.tar'));
  writePackTar(Directory(p.join(source.path, id)), id, tar);
  return tar;
}

/// One member of a hand-made tar.
typedef TarFile = ({String name, List<int> data});

/// A ustar archive of [members]. [type] is the typeflag of every header,
/// [corruptChecksum] spoils the first header's checksum, and [endMarker]
/// false leaves the two closing zero blocks out.
Uint8List tarBytes(
  List<TarFile> members, {
  String type = '0',
  bool corruptChecksum = false,
  bool endMarker = true,
}) {
  final out = BytesBuilder();
  for (final (index, member) in members.indexed) {
    out
      ..add(
        _header(
          member.name,
          member.data.length,
          type,
          corrupt: corruptChecksum && index == 0,
        ),
      )
      ..add(member.data)
      ..add(Uint8List((512 - member.data.length % 512) % 512));
  }
  if (endMarker) out.add(Uint8List(1024));
  return out.takeBytes();
}

Uint8List _header(String name, int size, String type, {bool corrupt = false}) {
  final header = Uint8List(512);
  void put(int offset, String text) =>
      header.setRange(offset, offset + text.length, utf8.encode(text));
  put(0, name);
  put(100, '0000644\u0000');
  put(124, '${size.toRadixString(8).padLeft(11, '0')}\u0000');
  put(148, '        ');
  put(156, type);
  put(257, 'ustar\u0000');
  put(263, '00');
  final sum = header.fold<int>(0, (a, b) => a + b);
  put(
    148,
    '${(corrupt ? sum + 1 : sum).toRadixString(8).padLeft(6, '0')}\u0000 ',
  );
  return header;
}
