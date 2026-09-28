/// Per-library template counters (#52): `{{counter:name}}` hands out 1,
// 2, 3… per name, persisted in `<library>/.niman/counters.json` so the
// sequence survives a restart. One file per library, one entry per name.
//
// The store is made per note creation, [use] hands the number out of the
// file itself, and the reads and writes of one file queue up on one
// serialized chain — so two creations that start together (two windows, a
// quick note and a template) get distinct numbers rather than both
// reading 0 and both writing 1 (#359). The caller reserves each
// `{{counter:name}}` once and reuses it for the rest of the note, and
// [save] merges the file back so a number another writer reached first is
// never dropped.
library;

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

/// The counters of one library.
final class CounterStore {
  new _(this._file, this._values);

  /// Creates a store over an in-memory map (tests).
  @visibleForTesting
  new test(Map<String, int> values)
    : _file = null,
      _values = Map<String, int>.of(values);

  /// Loads the counters of the library at [root], starting empty when
  /// the file is missing or does not parse.
  static Future<CounterStore> load(String root) async {
    final file = _fileFor(root);
    return CounterStore._(file, await _read(file));
  }

  /// The serialized writer chain of each counters file, keyed by path.
  ///
  /// A store is made per creation, so two over one library are two
  /// objects: the chain lives past either of them so their
  /// read-modify-write steps queue up instead of interleaving.
  static final Map<String, Future<void>> _chains = {};

  final File? _file;
  final Map<String, int> _values;

  static File _fileFor(String root) =>
      File(p.join(root, '.niman', 'counters.json'));

  /// Hands out the next value of [name]: one past the highest either this
  /// store or the file already reached, starting at 1.
  ///
  /// The new value is on disk before it is returned, so the next creation
  /// reads it and takes the one after. A test store has no file and hands
  /// out in memory.
  Future<int> use(String name) async {
    final file = _file;
    if (file == null) {
      return _values[name] = (_values[name] ?? 0) + 1;
    }
    return await _serialized(file.path, () async {
      final onDisk = await _read(file);
      final held = _values[name] ?? 0;
      final reached = onDisk[name] ?? 0;
      final next = (held > reached ? held : reached) + 1;
      onDisk[name] = next;
      _values[name] = next;
      await _write(file, onDisk);
      return next;
    });
  }

  /// The last value this store handed out for [name], or 0 when it never
  /// did.
  int current(String name) => _values[name] ?? 0;

  /// Merges the values this store handed out into the file, creating the
  /// `.niman/` folder if needed, so no entry goes below what the file
  /// already holds. A test store has no file and saves nowhere.
  Future<void> save() async {
    final file = _file;
    if (file == null) return;
    await _serialized(file.path, () async {
      final onDisk = await _read(file);
      var changed = false;
      for (final entry in _values.entries) {
        if ((onDisk[entry.key] ?? 0) < entry.value) {
          onDisk[entry.key] = entry.value;
          changed = true;
        }
      }
      if (changed) await _write(file, onDisk);
    });
  }

  /// [action] run after everything already queued on [key], so the reads
  /// and writes of one file never interleave (the chain the note ops and
  /// the todo store use).
  static Future<T> _serialized<T>(
    String key,
    Future<T> Function() action,
  ) async {
    final previous = _chains[key] ?? Future<void>.value();
    final next = previous.then((_) => action());
    final tail = next.then<void>((_) {}, onError: (Object _) {});
    _chains[key] = tail;
    try {
      return await next;
    } finally {
      // The last queued write is done: drop the chain so the map does not
      // keep a path per library for the life of the process.
      if (identical(_chains[key], tail)) {
        _chains.removeWhere((path, _) => path == key);
      }
    }
  }

  /// The counters in [file], or none when it is missing or does not
  /// parse.
  static Future<Map<String, int>> _read(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key.toString(): entry.value as int,
      };
    } on Object catch (_) {
      return {};
    }
  }

  /// Writes [values] to [file] atomically, creating its folder if needed.
  static Future<void> _write(File file, Map<String, int> values) async {
    await file.parent.create(recursive: true);
    final text = const JsonEncoder.withIndent('  ').convert(values);
    await writeFileAtomically(file, utf8.encode('$text\n'));
  }
}
