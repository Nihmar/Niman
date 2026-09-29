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
// never dropped. A number is on disk before its note exists, so a creation
// that fails after reserving hands it back ([giveBack]) — only while nothing
// reserved after it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
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

  /// Reserves one number for each of [names] — the `{{counter:…}}` of one
  /// note being created (`counterNames`) — in the library at [root], and
  /// answers the store with the callback the engine reads them through:
  /// every `{{counter:name}}` in the note, directives and body alike, gets
  /// the one number reserved for its name.
  ///
  /// Null when there is nothing to reserve (no names, or no library): a
  /// template with no counter never touches the file. Each reservation is
  /// on disk when this returns (#359), before the note exists, so a
  /// creation that fails afterwards has to [giveBack] the numbers or they
  /// are skipped. Throws what the file does ([use]); the creation flows run
  /// it where their failures are reported.
  static Future<({CounterStore store, int Function(String name) counter})?>
  reserve(String? root, List<String> names) async {
    if (root == null || names.isEmpty) return null;
    final store = await load(root);
    final used = <String, int>{};
    for (final name in names) {
      used[name] = await store.use(name);
    }
    return (store: store, counter: (String name) => used[name]!);
  }

  /// The serialized writer chain of each counters file, keyed by path.
  ///
  /// A store is made per creation, so two over one library are two
  /// objects: the chain lives past either of them so their
  /// read-modify-write steps queue up instead of interleaving.
  static final Map<String, Future<void>> _chains = {};

  static const AppLogger _log = AppLogger(name: 'templates');

  final File? _file;
  final Map<String, int> _values;

  /// The number [use] handed out for each name, and not given back: what
  /// [giveBack] returns.
  final Map<String, int> _taken = {};

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
      return _taken[name] = _values[name] = (_values[name] ?? 0) + 1;
    }
    return await _serialized(file.path, () async {
      final onDisk = await _read(file);
      final held = _values[name] ?? 0;
      final reached = onDisk[name] ?? 0;
      final next = (held > reached ? held : reached) + 1;
      onDisk[name] = next;
      _values[name] = next;
      await _write(file, onDisk);
      _taken[name] = next;
      return next;
    });
  }

  /// Runs [creation], the making of the note [store]'s numbers were reserved
  /// for, and gives the numbers back when it throws (the error still goes
  /// on to the caller). Once the note is made they are used, and nothing
  /// reaches back for them. [store] is null when the template has no
  /// counter.
  static Future<T> whileCreating<T>(
    CounterStore? store,
    Future<T> Function() creation,
  ) async {
    try {
      return await creation();
    } on Object {
      await store?.giveBack();
      rethrow;
    }
  }

  /// Gives back the numbers this store handed out, for a note that was not
  /// made: the next creation takes them again instead of skipping them.
  ///
  /// A name's number goes back only when the file still holds it — nothing
  /// reserved after it. Another creation on top (a second window, a quick
  /// note) may already be using the next number, and lowering the counter
  /// under it would hand the same number out twice; a gap is the lesser
  /// evil, so that number stays taken. It runs on the same chain as [use],
  /// so it sees every reservation that came before it in the queue.
  ///
  /// Never throws: it runs while a creation's own failure is being
  /// reported, which it must not replace. A file that cannot be read or
  /// written leaves the numbers taken, as they were before this existed.
  Future<void> giveBack() async {
    final taken = Map<String, int>.of(_taken);
    _taken.clear();
    if (taken.isEmpty) return;
    final file = _file;
    if (file == null) {
      _takeBack(taken, _values);
      return;
    }
    try {
      await _serialized(file.path, () async {
        final onDisk = await _read(file);
        if (_takeBack(taken, onDisk)) await _write(file, onDisk);
        _takeBack(taken, _values);
      });
    } on Object catch (error) {
      _log.warning('counters: could not give back $taken ($error)');
    }
  }

  /// Lowers each of [taken] in [values] by one where it still stands at the
  /// number taken; drops an entry that goes back to 0. Whether any changed.
  static bool _takeBack(Map<String, int> taken, Map<String, int> values) {
    var changed = false;
    for (final MapEntry(key: name, value: number) in taken.entries) {
      if (values[name] != number) continue;
      if (number > 1) {
        values[name] = number - 1;
      } else {
        values.remove(name);
      }
      changed = true;
    }
    return changed;
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
  ///
  /// A file that is there and cannot be read right now — locked while a
  /// sync renames over it, a FUSE hiccup — is not an empty one: [use]
  /// writes back what it read, so taking it for empty wrote a file holding
  /// the one counter in hand, every other one gone and this one back at 1,
  /// handing out numbers already used. That failure is thrown instead, and
  /// the creation that asked reports it.
  static Future<Map<String, int>> _read(File file) async {
    final String text;
    try {
      text = await file.readAsString();
    } on PathNotFoundException {
      return {};
    } on FileSystemException catch (error) {
      // Bytes that are not UTF-8 are a corrupt file, not a failed read.
      if (error.osError != null) rethrow;
      return {};
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key.toString(): entry.value as int,
      };
    } on FormatException {
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
