// What the dictionary engine costs at the size of the largest pack
// (docs/records/dictionary.md, "The engine"): the sidecar index built once
// from a pack of a million headwords and a million `.syn` forms, and a
// look-up through the worker isolate after it.
//
// The pack is synthetic, written here into a temporary directory and never
// committed: pseudo-random lowercase keys of 7 to 11 letters, a dictzip
// `.dict.dz` of ~90-byte entries, the `.idx` and `.syn` in no particular
// order (the build sorts them either way, so this is its worst case).
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/dictionary_lookup_perf_test.dart`.
//
// Measured on the reference host (Windows 11, a desktop CPU, the JIT VM
// `flutter test` runs, 2026-11-27): the index of the two million keys builds
// in about a second into 27.6 MB (13.8 bytes a key), and a look-up through
// the worker takes 0.4 ms at the median and 1.7 ms at the 99th percentile,
// whatever the pack's size: a binary search over the block fences in memory
// and about three small reads (an index block, the entry's place, a dictzip
// chunk).
//
// The design's ceiling is a median of 2 ms, a 99th percentile of 10 ms and
// a build of 30 s: a phone is several times slower than the host, and the
// English pack is twice the keys of this one. The backstop is ten times
// that, for a shared runner.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_index.dart';
import 'package:niman/src/dictionary/dictionary_index_job.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:path/path.dart' as p;

import '../unit/dictionary/pack_writer.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// Headwords, and `.syn` forms, in the synthetic pack.
const int _keys = 1000000;

/// How many look-ups of each kind are timed.
const int _lookups = 3000;

/// The key number [n] of kind [salt]: two to five pseudo-random letters (so
/// sorted neighbours share a prefix as a language's words do), then the
/// number in base 26, so no two keys are the same.
String _word(int n, int salt) {
  final hash = ((n + salt * _keys) * 0x1F351D1CA3B5A7) >>> 7;
  final letters = StringBuffer();
  final prefix = 2 + (hash >> 40) % 4;
  for (var i = 0; i < prefix; i++) {
    letters.writeCharCode(97 + ((hash >> (5 * i)) & 0x1F) % 26);
  }
  var rest = n + salt * _keys;
  final tail = List<int>.filled(5, 97);
  for (var i = 4; i >= 0; i--) {
    tail[i] = 97 + rest % 26;
    rest ~/= 26;
  }
  return letters.toString() + String.fromCharCodes(tail);
}

void _be32(BytesBuilder out, int value) => out.add([
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
]);

/// Writes the synthetic pack `niman-xx` into [root]; returns its directory.
String _writePack(String root) {
  final directory = Directory(p.join(root, 'niman-xx'))..createSync();
  final dict = BytesBuilder(copy: false);
  final idx = BytesBuilder(copy: false);
  for (var n = 0; n < _keys; n++) {
    final word = _word(n, 0);
    final html = utf8.encode(
      '<h1>$word</h1><section data-pos="noun"><ol><li>the meaning of '
      '<i>$word</i></li></ol></section>',
    );
    idx
      ..add(utf8.encode(word))
      ..addByte(0);
    _be32(idx, dict.length);
    _be32(idx, html.length);
    dict.add(html);
  }
  final syn = BytesBuilder(copy: false);
  for (var n = 0; n < _keys; n++) {
    syn
      ..add(utf8.encode(_word(n, 1)))
      ..addByte(0);
    _be32(syn, (n * 7919) % _keys);
  }
  String at(String extension) => p.join(directory.path, 'niman-xx.$extension');
  final idxBytes = idx.takeBytes();
  File(at('idx')).writeAsBytesSync(idxBytes);
  File(at('syn')).writeAsBytesSync(syn.takeBytes());
  File(at('dict.dz')).writeAsBytesSync(dictzip(dict.takeBytes(), level: 1));
  File(at('ifo')).writeAsStringSync(
    [
      "StarDict's dict ifo file",
      'version=3.0.0',
      'bookname=Synthetic',
      'wordcount=$_keys',
      'synwordcount=$_keys',
      'idxfilesize=${idxBytes.length}',
      'idxoffsetbits=32',
      'sametypesequence=h',
      'niman-pack=1',
      'languages=xx',
      'definitions=xx',
      'source=synthetic',
      'license=none',
      '',
    ].join('\n'),
  );
  return directory.path;
}

/// The [fraction] percentile of [sorted] (ascending), in milliseconds.
double _percentile(List<int> sorted, double fraction) =>
    sorted[((sorted.length - 1) * fraction).round()] / 1000;

/// Times [selections] as look-ups through [service], in microseconds,
/// ascending, and checks each found what it should.
Future<List<int>> _time(
  DictionaryService service,
  List<String> selections, {
  required DictionaryOutcome expected,
}) async {
  final micros = <int>[];
  final clock = Stopwatch();
  for (final selection in selections) {
    clock
      ..reset()
      ..start();
    final result = await service.lookUp(selection, 'xx');
    clock.stop();
    expect(result.outcome, expected, reason: selection);
    micros.add(clock.elapsedMicroseconds);
  }
  return micros..sort();
}

void main() {
  test('a pack of a million headwords and a million forms: the index builds '
      'once and a look-up is a few reads', () async {
    final root = Directory.systemTemp.createTempSync('niman_dict_perf');
    addTearDown(() => root.deleteSync(recursive: true));

    var clock = Stopwatch()..start();
    final directory = _writePack(root.path);
    final writeMs = clock.elapsedMilliseconds;
    final packBytes = [
      for (final entity in Directory(directory).listSync())
        if (entity is File) entity.lengthSync(),
    ].fold<int>(0, (a, b) => a + b);

    // The index, built on its own isolate as the app builds it.
    var lastProgress = 0.0;
    clock = Stopwatch()..start();
    await buildDictionaryIndexOnIsolate(
      directory: directory,
      id: 'niman-xx',
      onProgress: (fraction) => lastProgress = fraction,
    );
    final buildMs = clock.elapsedMilliseconds;
    final indexBytes = File(DictionaryIndex.pathOf(directory, 'niman-xx'))
        .lengthSync();
    expect(lastProgress, 1);

    final service = DictionaryService(directory: root.path);
    addTearDown(service.dispose);
    // The first look-up opens the pack in the worker: the fences read.
    clock = Stopwatch()..start();
    await service.prepare('xx');
    final openMs = clock.elapsedMilliseconds;

    // Look-ups of headwords and of forms at random places of the pack, and
    // of words that are not in it (the nearest-keys path).
    const stride = _keys ~/ _lookups;
    final headwords = [
      for (var i = 0; i < _lookups; i++)
        _word((i * stride + 17 * i) % _keys, 0),
    ];
    final forms = [
      for (var i = 0; i < _lookups; i++)
        _word((i * stride + 31 * i) % _keys, 1),
    ];
    // A headword with a letter changed is almost never a key.
    final misses = [
      for (var i = 0; i < _lookups ~/ 3; i++)
        '${_word((i * stride + 5 * i) % _keys, 0)}q',
    ];
    // One of each first: the isolates and the JIT warm.
    for (var i = 0; i < 50; i++) {
      await service.lookUp(headwords[i], 'xx');
    }
    final found = await _time(
      service,
      headwords.skip(50).toList(),
      expected: DictionaryOutcome.found,
    );
    final viaForms = await _time(
      service,
      forms,
      expected: DictionaryOutcome.found,
    );
    final notFound = await _time(
      service,
      misses,
      expected: DictionaryOutcome.notFound,
    );

    final medianMs = _percentile(found, 0.5);
    final p99Ms = _percentile(found, 0.99);
    String ms(double value) => value.toStringAsFixed(2);
    const keyCount = 2 * _keys;
    print(
      'dictionary: pack of $_keys headwords + $_keys forms, '
      '${(packBytes / 1e6).toStringAsFixed(0)} MB, written in '
      '${(writeMs / 1000).toStringAsFixed(1)} s (not part of the build)',
    );
    print(
      'dictionary index: built in ${(buildMs / 1000).toStringAsFixed(1)} s, '
      '${(indexBytes / 1e6).toStringAsFixed(1)} MB for $keyCount keys '
      '(${(indexBytes / keyCount).toStringAsFixed(1)} bytes a key), '
      'opened in $openMs ms',
    );
    print(
      'dictionary look-up, headword: median ${ms(medianMs)} ms, '
      'p99 ${ms(p99Ms)} ms | via a form: median '
      '${ms(_percentile(viaForms, 0.5))} ms, p99 '
      '${ms(_percentile(viaForms, 0.99))} ms | not found + nearest keys: '
      'median ${ms(_percentile(notFound, 0.5))} ms, p99 '
      '${ms(_percentile(notFound, 0.99))} ms',
    );

    final medianBar = _referenceHost ? 2.0 : 20.0;
    final p99Bar = _referenceHost ? 10.0 : 100.0;
    final buildBar = _referenceHost ? 30.0 : 300.0;
    print(
      'dictionary bars: median ${ms(medianBar)} ms, p99 ${ms(p99Bar)} ms, '
      'build ${buildBar.toStringAsFixed(0)} s '
      '(${_referenceHost ? 'the design ceiling' : 'the backstop'})',
    );
    expect(medianMs, lessThan(medianBar));
    expect(p99Ms, lessThan(p99Bar));
    expect(_percentile(viaForms, 0.5), lessThan(medianBar));
    expect(_percentile(notFound, 0.5), lessThan(medianBar * 3));
    expect(buildMs / 1000, lessThan(buildBar));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
