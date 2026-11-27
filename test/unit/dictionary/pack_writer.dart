// Writes a dictionary pack, in the format of docs/records/dictionary.md, into
// a directory: the tests build the packs they need with it, and it wrote the
// ones committed under `test/fixtures/dictionary/` (see `fixture_packs.dart`).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// One headword and the HTML of its entry.
typedef PackEntry = ({String headword, String html});

/// The StarDict order of the `.idx`: `g_ascii_strcasecmp`, then `strcmp`.
int starDictCompare(List<int> a, List<int> b) {
  int lower(int c) => c >= 0x41 && c <= 0x5A ? c + 32 : c;
  for (var i = 0; i < a.length && i < b.length; i++) {
    final difference = lower(a[i]) - lower(b[i]);
    if (difference != 0) return difference;
  }
  if (a.length != b.length) return a.length - b.length;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return 0;
}

/// A dictzip file of [data]: the gzip header with the `RA` field, then one
/// raw deflate stream per chunk, each flushed on its own so it inflates
/// alone (what `Z_FULL_FLUSH` gives), and the gzip trailer.
Uint8List dictzip(Uint8List data, {int chunkLength = 58315, int level = 9}) {
  final chunks = <Uint8List>[];
  for (var at = 0; at < data.length || at == 0; at += chunkLength) {
    final end = at + chunkLength < data.length ? at + chunkLength : data.length;
    final last = end >= data.length;
    final filter = RawZLibFilter.deflateFilter(raw: true, level: level)
      ..process(data, at, end);
    final packed = <int>[];
    while (true) {
      final part = filter.processed(flush: !last, end: last);
      if (part == null || part.isEmpty) break;
      packed.addAll(part);
    }
    chunks.add(Uint8List.fromList(packed));
    if (last) break;
  }
  final extra = BytesBuilder()
    ..add([0x52, 0x41])
    ..add(_u16(6 + 2 * chunks.length))
    ..add(_u16(1))
    ..add(_u16(chunkLength))
    ..add(_u16(chunks.length));
  for (final chunk in chunks) {
    extra.add(_u16(chunk.length));
  }
  final extraBytes = extra.takeBytes();
  final out = BytesBuilder()
    ..add([0x1f, 0x8b, 8, 4, 0, 0, 0, 0, 2, 3])
    ..add(_u16(extraBytes.length))
    ..add(extraBytes);
  chunks.forEach(out.add);
  out
    ..add(_u32(_crc32(data)))
    ..add(_u32(data.length));
  return out.takeBytes();
}

Uint8List _u16(int value) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little);

Uint8List _u32(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little);

int _crc32(Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

Uint8List _be(int value, int bytes) {
  final out = Uint8List(bytes);
  for (var i = 0; i < bytes; i++) {
    out[bytes - 1 - i] = (value >> (8 * i)) & 0xFF;
  }
  return out;
}

/// Writes the pack `niman-[code]` into `[root]/niman-[code]/` and returns
/// that directory.
///
/// [forms] maps a `.syn` key to the headwords of the lemmas it leads to (one
/// record each). [nimanPack] and [offsetBits] can be set wrong on purpose,
/// and [compress] false writes a plain `.dict`.
Future<String> writePack(
  String root, {
  required String code,
  required List<PackEntry> entries,
  Map<String, List<String>> forms = const {},
  List<String>? languages,
  String definitions = '',
  int nimanPack = 1,
  int offsetBits = 32,
  bool compress = true,
  int chunkLength = 58315,
  String source = 'test.wiktionary',
  String license = 'CC BY-SA 4.0; GFDL',
  bool writeSyn = true,
}) async {
  final id = 'niman-$code';
  final directory = Directory(p.join(root, id))..createSync(recursive: true);
  final keyed = [for (final e in entries) (utf8.encode(e.headword), e)]
    ..sort((a, b) => starDictCompare(a.$1, b.$1));
  final sorted = [for (final (_, entry) in keyed) entry];
  final dict = BytesBuilder();
  final idx = BytesBuilder();
  final numberOf = <String, int>{};
  for (final (number, entry) in sorted.indexed) {
    final html = utf8.encode(entry.html);
    idx
      ..add(utf8.encode(entry.headword))
      ..addByte(0)
      ..add(_be(dict.length, offsetBits ~/ 8))
      ..add(_be(html.length, 4));
    dict.add(html);
    numberOf[entry.headword] = number;
  }
  final records =
      <(List<int>, int)>[
        for (final MapEntry(:key, :value) in forms.entries)
          for (final lemma in value) (utf8.encode(key), numberOf[lemma]!),
      ]..sort((a, b) {
        final order = starDictCompare(a.$1, b.$1);
        return order != 0 ? order : a.$2 - b.$2;
      });
  final syn = BytesBuilder();
  for (final (key, number) in records) {
    syn
      ..add(key)
      ..addByte(0)
      ..add(_be(number, 4));
  }
  String at(String extension) => p.join(directory.path, '$id.$extension');
  final data = dict.takeBytes();
  final idxBytes = idx.takeBytes();
  File(at('idx')).writeAsBytesSync(idxBytes);
  if (compress) {
    File(at('dict.dz'))
        .writeAsBytesSync(dictzip(data, chunkLength: chunkLength));
  } else {
    File(at('dict')).writeAsBytesSync(data);
  }
  if (writeSyn && records.isNotEmpty) {
    File(at('syn')).writeAsBytesSync(syn.takeBytes());
  }
  File(at('ifo')).writeAsStringSync(
    [
      "StarDict's dict ifo file",
      'version=3.0.0',
      'bookname=Niman $code',
      'wordcount=${sorted.length}',
      if (records.isNotEmpty) 'synwordcount=${records.length}',
      'idxfilesize=${idxBytes.length}',
      'idxoffsetbits=$offsetBits',
      'sametypesequence=h',
      'author=Niman test',
      'website=https://example.invalid',
      'description=A pack written by a test.',
      'date=2026-11-27',
      'niman-pack=$nimanPack',
      'languages=${(languages ?? [code]).join(',')}',
      'definitions=${definitions.isEmpty ? code : definitions}',
      'source=$source',
      'license=$license',
      '',
    ].join('\n'),
  );
  return directory.path;
}
