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

  Future<HomeLayout?> _readNow() async {
    final path = _path;
    final text = await Isolate.run(() => _readText(path));
    if (text == null) return null;
    try {
      return HomeLayout.fromJson(jsonDecode(text));
    } on FormatException catch (error) {
      _log.warning('$filePath does not read: $error');
      return null;
    }
  }

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
      final next = change(await _readNow());
      if (next == null) return;
      final json = next.toJson();
      await Isolate.run(() => _writeJson(key, json));
    } finally {
      done.complete();
      if (identical(_queues[key], done.future)) unawaited(_queues.remove(key));
    }
  }
}

Future<String?> _readText(String path) async {
  try {
    return await File(path).readAsString();
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
