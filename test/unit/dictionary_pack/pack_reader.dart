// A reader of a pack's files for the tests, written from the format's
// description alone (docs/records/dictionary.md): the tests check the
// pipeline's output against the contract, not against the pipeline's own code.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/dictzip_writer.dart';
import '../../../tool/dictionary_pack/star_dict_order.dart';

/// One `.idx` entry.
typedef IdxEntry = ({String word, Uint8List key, int offset, int size});

/// One `.syn` record.
typedef SynRecord = ({String word, Uint8List key, int index});

/// A pack read back.
final class TestPack {
  new _(this.dir, this.id, this.ifo, this.idx, this.syn, this.idxBytes);

  /// Reads the pack [id] in [dir].
  factory read(Directory dir, String id) {
    File file(String extension) => File(p.join(dir.path, '$id.$extension'));
    final ifo = <String, String>{};
    final lines = file('ifo').readAsStringSync().split('\n');
    expectFirstLine(lines.first);
    for (final line in lines.skip(1)) {
      final equals = line.indexOf('=');
      if (equals > 0) {
        ifo[line.substring(0, equals)] = line.substring(equals + 1);
      }
    }
    final idxBytes = file('idx').readAsBytesSync();
    final idx = <IdxEntry>[];
    for (var at = 0; at < idxBytes.length;) {
      final end = idxBytes.indexOf(0, at);
      final key = Uint8List.sublistView(idxBytes, at, end);
      final numbers = ByteData.sublistView(idxBytes, end + 1, end + 9);
      idx.add((
        word: utf8.decode(key),
        key: key,
        offset: numbers.getUint32(0),
        size: numbers.getUint32(4),
      ));
      at = end + 9;
    }
    final synBytes = file('syn').readAsBytesSync();
    final syn = <SynRecord>[];
    for (var at = 0; at < synBytes.length;) {
      final end = synBytes.indexOf(0, at);
      final key = Uint8List.sublistView(synBytes, at, end);
      syn.add((
        word: utf8.decode(key),
        key: key,
        index: ByteData.sublistView(synBytes, end + 1, end + 5).getUint32(0),
      ));
      at = end + 5;
    }
    return TestPack._(dir, id, ifo, idx, syn, idxBytes);
  }

  static void expectFirstLine(String line) {
    if (line != "StarDict's dict ifo file") {
      throw StateError('Not an .ifo: $line');
    }
  }

  final Directory dir;
  final String id;
  final Map<String, String> ifo;
  final List<IdxEntry> idx;
  final List<SynRecord> syn;
  final Uint8List idxBytes;

  File file(String extension) => File(p.join(dir.path, '$id.$extension'));

  /// The whole `.dict`, from the dictzip file or the plain one.
  Uint8List get dict {
    final dz = file('dict.dz');
    return dz.existsSync()
        ? Uint8List.fromList(gzip.decode(dz.readAsBytesSync()))
        : file('dict').readAsBytesSync();
  }

  /// The entry of [word] by binary search over the `.idx`, as a reader that
  /// never scans would find it, or null.
  IdxEntry? find(String word) => _search(idx.map((e) => e.key).toList(), word);

  IdxEntry? _search(List<Uint8List> keys, String word) {
    final wanted = Uint8List.fromList(utf8.encode(word));
    var low = 0;
    var high = keys.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final order = compareStarDictKeys(keys[mid], wanted);
      if (order == 0) return idx[mid];
      if (order < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  /// The `.syn` records of [word]: the lemmas it points at.
  List<String> lemmasOf(String word) => [
    for (final record in syn)
      if (record.word == word) idx[record.index].word,
  ];

  /// The HTML of the entry [word].
  String html(String word) {
    final entry = find(word);
    if (entry == null) throw StateError('No entry "$word".');
    return utf8.decode(
      Uint8List.sublistView(dict, entry.offset, entry.offset + entry.size),
    );
  }

  /// The entry [entry] as a dictzip reader gets it: only the chunks it
  /// spans are inflated, each alone.
  String htmlByChunks(IdxEntry entry) {
    final bytes = file('dict.dz').readAsBytesSync();
    final table = readDictzipTable(bytes);
    final first = entry.offset ~/ table.chunkLength;
    final last = (entry.offset + entry.size - 1) ~/ table.chunkLength;
    var at = table.dataStart;
    for (var i = 0; i < first; i++) {
      at += table.sizes[i];
    }
    final out = <int>[];
    for (var i = first; i <= last; i++) {
      final packed = bytes.sublist(at, at + table.sizes[i]);
      at += table.sizes[i];
      final filter = RawZLibFilter.inflateFilter(raw: true)
        ..process(packed, 0, packed.length);
      for (;;) {
        final part = filter.processed(flush: false);
        if (part == null || part.isEmpty) break;
        out.addAll(part);
      }
    }
    final from = entry.offset - first * table.chunkLength;
    return utf8.decode(out.sublist(from, from + entry.size));
  }
}
