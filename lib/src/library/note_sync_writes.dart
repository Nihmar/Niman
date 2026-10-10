import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/library/device_home_carry.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

/// The writes the sync makes to the library (docs/records/sync.md): a
/// download swapped in, a merge, a remote delete, a remote rename.
///
/// None of them reports a sync hint — what they write already agrees with
/// the server — and each remembers its paths for [echoWindow], so the file
/// watcher's echo of it stays out of the queue ([changedBySync]).
final class NoteSyncWrites {
  /// Creates the sync writes of the library at [root].
  new({
    required this.root,
    required this.indexer,
    required this.history,
    required this.config,
    required this.writer,
    required this.serialize,
    required this.moveIntoTrash,
    this.carryOutside,
  });

  /// The library settings file, library-relative.
  static const settingsFilePath = '.niman/settings.json';

  /// How long a sync write keeps the file watcher's echo of it out of
  /// the queue.
  static const echoWindow = Duration(seconds: 10);

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer; a trash or a move reaches the index through it.
  final Indexer indexer;

  /// The library's `.history/`, which follows a remote rename.
  final NoteHistory history;

  /// The library settings, reloaded when the sync replaces their file.
  final LibraryConfigRepo config;

  /// The note-text write path, in whose save order a replace or a merge
  /// lands.
  final NoteWriter writer;

  /// The op chain of the library's operations.
  final Serializer serialize;

  /// Moves a path into `.trash/` and returns its absolute trash path,
  /// inside the op chain.
  final Future<String> Function(String path, {required bool isDir})
  moveIntoTrash;

  /// What else, outside the library's own files, names a note by its path
  /// and has to follow a rename or a move (#506): the home-screen note
  /// widgets, kept in the app's database rather than the library's. Null
  /// carries nothing further.
  final Future<void> Function(String from, String to, {required bool isDir})?
  carryOutside;

  /// When each path was last written by a sync operation.
  final Map<String, DateTime> _syncWrites = {};

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Whether [path] keeps history: the text notes the editor saves.
  static bool keepsHistory(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.md') || lower.endsWith('.txt');
  }

  void _markSyncWrite(String path) {
    final now = DateTime.now();
    _syncWrites
      ..removeWhere((_, at) => now.difference(at) > echoWindow)
      ..[path] = now;
  }

  /// Whether a sync operation wrote, trashed or moved [path] within
  /// [echoWindow]: the file watcher's event for it is an echo.
  bool changedBySync(String path) {
    final at = _syncWrites[path];
    return at != null && DateTime.now().difference(at) <= echoWindow;
  }

  /// Swaps the verified sync download at [tempAbs] in for the file at
  /// [path] (new or existing): a note's replaced text becomes a `sync`
  /// version first, and it runs in the note's save order so an editor
  /// save never interleaves. Replacing `.niman/settings.json` drops the
  /// cached settings.
  Future<void> replace(String path, String tempAbs) async {
    _markSyncWrite(path);
    await writer.replaceFromFile(
      path,
      tempAbs,
      forced: keepsHistory(path) ? HistoryReason.sync : null,
    );
    if (path == settingsFilePath) await config.reload();
  }

  /// Writes [text] at [path] because the sync merged both sides of it:
  /// the text being replaced becomes a `sync` history version, and the
  /// write goes through the note's save order like any other.
  Future<void> merge(String path, String text) async {
    _markSyncWrite(path);
    await writer.save(path, text, forced: HistoryReason.sync);
  }

  /// Moves [path] into `.trash/` because the remote deleted it — always
  /// the trash, whatever the trash toggle: a deletion that arrives from
  /// another device must stay recoverable here.
  Future<void> trash(String path) {
    return serialize(() async {
      final abs = _abs(path);
      final isDir = Directory(abs).existsSync();
      if (!isDir && !File(abs).existsSync()) return;
      _markSyncWrite(path);
      final trashAbs = await moveIntoTrash(path, isDir: isDir);
      await indexer.applyEvents(root, [abs, trashAbs]);
    });
  }

  /// Renames the file at [from] to [to] (any folder, created on demand)
  /// because the remote renamed it; the history follows. Throws
  /// [FileSystemException] when [from] is gone or [to] is taken — the
  /// local half of a sync step, the type the step runner catches and
  /// reports as a local failure (#714).
  ///
  /// Carries what sync cannot: this device's own Home (#713) and what
  /// [carryOutside] holds, the home-screen widgets. The settings, Home
  /// file, reading positions and links that name the item arrive as
  /// writes of their own and are not touched here — carrying them again
  /// would race those writes.
  Future<void> move(String from, String to) {
    return serialize(() async {
      final fromAbs = _abs(from);
      final toAbs = _abs(to);
      if (!File(fromAbs).existsSync()) {
        throw FileSystemException('Nothing to move', fromAbs);
      }
      if (File(toAbs).existsSync() || Directory(toAbs).existsSync()) {
        throw FileSystemException('Already taken', toAbs);
      }
      await Directory(p.dirname(toAbs)).create(recursive: true);
      _markSyncWrite(from);
      _markSyncWrite(to);
      await File(fromAbs).rename(toAbs);
      await history.moved(from, to, isDir: false);
      await carryDeviceHome(config, from, to, isDir: false);
      await _carryOutside(from, to);
      await indexer.applyEvents(root, [fromAbs, toAbs]);
    });
  }

  /// Hands the move to [carryOutside] (#506). The move is already done on
  /// disk: a failure there is logged and leaves it standing.
  Future<void> _carryOutside(String from, String to) async {
    final carry = carryOutside;
    if (carry == null) return;
    try {
      await carry(from, to, isDir: false);
    } on Object catch (error) {
      const AppLogger(
        name: 'notes',
      ).warning('could not carry "$from" -> "$to" outside the library: $error');
    }
  }
}
