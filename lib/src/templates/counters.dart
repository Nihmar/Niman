/// Per-library template counters (#52): `{{counter:name}}` hands out 1,
// 2, 3… per name, persisted in `<library>/.niman/counters.json` so the
// sequence survives a restart. One file per library, one entry per name.
//
// The store is used per note creation: [use] hands out memoized values
// in memory (every `{{counter:quest}}` in one note writes the same
// number, and a cancelled creation burns nothing), and [save] persists
// once the note is on disk.
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
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return CounterStore._(file, {});
      return CounterStore._(file, {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key.toString(): entry.value as int,
      });
    } on Object catch (_) {
      return CounterStore._(file, {});
    }
  }

  final File? _file;
  final Map<String, int> _values;

  static File _fileFor(String root) =>
      File(p.join(root, '.niman', 'counters.json'));

  /// The next value of [name]: one past the last handed out, starting at
  /// 1. In memory only — call [save] to persist.
  int use(String name) => _values[name] = (_values[name] ?? 0) + 1;

  /// The last value handed out for [name], or 0 when never used.
  int current(String name) => _values[name] ?? 0;

  /// Writes the counters back, creating the `.niman/` folder if needed.
  /// A test store has no file and saves nowhere.
  Future<void> save() async {
    final file = _file;
    if (file == null) return;
    await file.parent.create(recursive: true);
    final text = const JsonEncoder.withIndent('  ').convert(_values);
    await writeFileAtomically(file, utf8.encode('$text\n'));
  }
}
