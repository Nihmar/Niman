/// A library's Home on disk (#535): `<library>/.niman/home.json`, one of the
/// sync's library state files.
///
/// Nothing is cached: the Home reads the file each time it loads, so a copy
/// the sync just brought is what the next load shows. The writes of one
/// library run one after the other, each reading the file afresh, and they
/// run on a background isolate (every open is a FUSE round trip on
/// Android).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:path/path.dart' as p;

/// The Home file of the library at [root].
final class HomeFile {
  /// The file of the library whose absolute path is [root].
  const new(this.root);

  /// The library's absolute path.
  final String root;

  /// The file, library-relative.
  static const String filePath = '.niman/home.json';

  static const AppLogger _log = AppLogger(name: 'home');

  /// The writes still running, by file: each waits for the one before.
  static final Map<String, Future<void>> _queues = {};

  String get _path => p.join(root, filePath);

  /// The Home the file holds; null when there is no file, or it does not
  /// read as one — the library then shows [HomeLayout.defaults].
  ///
  /// It waits for the writes still running, or it reads the file from
  /// before them (#691).
  Future<HomeLayout?> read() async {
    if (_queues[_path] case final pending?) await pending;
    return await _readNow();
  }

  Future<HomeLayout?> _readNow() async => (await _load()).layout;

  /// The file's layout, and whether there is a file that does not read
  /// as one.
  Future<({HomeLayout? layout, bool unreadable})> _load() async {
    final path = _path;
    final bytes = await Isolate.run(() => _readBytes(path));
    if (bytes == null) return (layout: null, unreadable: false);
    try {
      final layout = HomeLayout.fromJson(jsonDecode(utf8.decode(bytes)));
      if (layout != null) return (layout: layout, unreadable: false);
      _log.warning('$filePath holds no object');
    } on FormatException catch (error) {
      _log.warning('$filePath does not read: $error');
    }
    return (layout: null, unreadable: true);
  }

  /// Where a file that does not read is set aside before a write replaces
  /// it (#694): a hand edit with a stray comma is the user's Home still.
  /// Not a library state file, so it stays on this device.
  static const String asidePath = '$filePath.bad';

  /// Writes [layout] whole.
  Future<void> write(HomeLayout layout) => _update((_) => layout);

  /// Writes what [change] makes of the Home the file holds when its turn
  /// comes — [HomeLayout.defaults] for no file — and returns it.
  Future<HomeLayout> update(
    HomeLayout Function(HomeLayout current) change,
  ) async {
    late HomeLayout written;
    await _update(
      (current) => written = change(current ?? HomeLayout.defaults),
    );
    return written;
  }

  /// Rewrites the actions' paths after the item at [from] moved to [to];
  /// whether the file changed. No file, or none pointing there, is no
  /// write.
  Future<bool> moved(String from, String to, {required bool isDir}) async {
    var changed = false;
    await _update((current) {
      if (current == null) return null;
      final next = current.renamed(from, to, isDir: isDir);
      if (identical(next, current)) return null;
      changed = true;
      return next;
    });
    return changed;
  }

  /// Runs [change] over the file's layout after every earlier write of
  /// this library, and writes what it returns; null writes nothing.
  Future<void> _update(HomeLayout? Function(HomeLayout? current) change) async {
    final key = _path;
    final before = _queues[key];
    final done = Completer<void>();
    _queues[key] = done.future;
    try {
      if (before != null) await before;
      final current = await _load();
      final next = change(current.layout);
      if (next == null) return;
      if (current.unreadable) {
        final aside = p.join(root, asidePath);
        await Isolate.run(() => _setAside(key, aside));
        _log.warning('$filePath set aside as $asidePath before a write');
      }
      final json = next.toJson();
      await Isolate.run(() => _writeJson(key, json));
    } finally {
      done.complete();
      if (identical(_queues[key], done.future)) unawaited(_queues.remove(key));
    }
  }
}

/// Moves the file at [path] to [aside], over an older one.
Future<void> _setAside(String path, String aside) async {
  await File(path).rename(aside);
}

Future<List<int>?> _readBytes(String path) async {
  try {
    return await File(path).readAsBytes();
  } on FileSystemException {
    return null;
  }
}

/// Encodes [json] and writes it whole, two-space indented like the
/// library's other state files. Top level for `Isolate.run`.
Future<void> _writeJson(String path, Map<String, Object?> json) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  final text = const JsonEncoder.withIndent('  ').convert(json);
  await writeFileAtomically(file, utf8.encode('$text\n'));
}
