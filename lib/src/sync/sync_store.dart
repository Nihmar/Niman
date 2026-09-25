import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

/// What a queued hint says happened to a path (docs/records/sync.md, "Queue
/// and triggers").
enum SyncOpKind {
  /// Created or edited.
  changed,

  /// Deleted (moved to the trash or removed).
  deleted,

  /// Renamed or moved from `fromPath`.
  moved;

  /// The kind stored as [name]; unknown text reads as [changed], the hint
  /// that makes the reconcile look at the path without assuming anything.
  static SyncOpKind parse(String name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return changed;
  }
}

/// How long a hint waits after its [failures]-th failed run: 5 s, 10 s,
/// 20 s, … capped at 10 minutes; zero before any failure.
Duration syncBackoff(int failures) {
  if (failures <= 0) return Duration.zero;
  const first = Duration(seconds: 5);
  const cap = Duration(minutes: 10);
  // 2^8 · 5 s already passes the cap; the clamp keeps the shift small.
  final factor = 1 << math.min(failures - 1, 8);
  final wait = first * factor;
  return wait > cap ? cap : wait;
}

/// The sync state of the app database (docs/records/sync.md): destinations,
/// agreed item states and the hint queue, for any number of libraries.
///
/// Every library path is normalized on the way in, like the rest of the
/// app-side tables. Writes are logged under `sync`; nothing here ever
/// sees a password.
final class SyncStore {
  /// A store over [_db]; [now] is the clock for queue times (tests).
  new(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  static const _log = AppLogger(name: 'sync');

  int get _nowMs => _now().millisecondsSinceEpoch;

  // --- destinations ---------------------------------------------------------

  /// [libraryPath]'s destination, or null when it has none.
  Future<SyncDestination?> destination(String libraryPath) =>
      (_db.select(_db.syncDestinations)
            ..where((t) => t.libraryPath.equals(p.normalize(libraryPath))))
          .getSingleOrNull();

  /// Every configured destination.
  Future<List<SyncDestination>> destinations() =>
      _db.select(_db.syncDestinations).get();

  /// Creates or updates [libraryPath]'s destination.
  ///
  /// Pointing it at another [url] or [username] makes the recorded state
  /// meaningless — it describes a different remote — so the items and the
  /// probed capabilities are cleared and the next sync is a first sync
  /// (which never deletes). The queued hints stay: they describe the
  /// local side.
  Future<void> saveDestination({
    required String libraryPath,
    required Uri url,
    String username = '',
    bool enabled = true,
    bool autoSync = true,
    int intervalSeconds = 60,
    bool wifiOnly = false,
  }) async {
    final path = p.normalize(libraryPath);
    final text = url.toString().endsWith('/') ? '$url' : '$url/';
    await _db.transaction(() async {
      final existing = await destination(path);
      final retarget =
          existing != null &&
          (existing.url != text || existing.username != username);
      if (retarget) {
        final cleared = await _deleteItems(path);
        _log.info(
          'destination: $path now points elsewhere; cleared $cleared items '
          'and the capabilities, next sync is a first sync',
        );
      }
      await _db
          .into(_db.syncDestinations)
          .insertOnConflictUpdate(
            SyncDestinationsCompanion.insert(
              libraryPath: path,
              url: text,
              username: Value(username),
              enabled: Value(enabled),
              autoSync: Value(autoSync),
              intervalSeconds: Value(math.max(0, intervalSeconds)),
              wifiOnly: Value(wifiOnly),
              capabilities: existing == null || retarget
                  ? const Value('{}')
                  : Value(existing.capabilities),
              lastSyncAtMs: existing == null || retarget
                  ? const Value(null)
                  : Value(existing.lastSyncAtMs),
              lastError: existing == null || retarget
                  ? const Value(null)
                  : Value(existing.lastError),
            ),
          );
    });
    _log.info(
      'destination: saved for $path: ${url.scheme}://${url.host}'
      '${url.hasPort ? ':${url.port}' : ''}${url.path}, '
      '${username.isEmpty ? 'no user' : 'user set'}, '
      'enabled $enabled, auto $autoSync, every ${intervalSeconds}s, '
      'wifi only $wifiOnly',
    );
  }

  /// Changes [libraryPath]'s trigger options, leaving the rest (and the
  /// recorded state) alone. Returns false when it has no destination.
  Future<bool> setTriggers(
    String libraryPath, {
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  }) async {
    final path = p.normalize(libraryPath);
    final changed =
        await (_db.update(
          _db.syncDestinations,
        )..where((t) => t.libraryPath.equals(path))).write(
          SyncDestinationsCompanion(
            autoSync: autoSync == null ? const Value.absent() : Value(autoSync),
            intervalSeconds: intervalSeconds == null
                ? const Value.absent()
                : Value(math.max(0, intervalSeconds)),
            wifiOnly: wifiOnly == null ? const Value.absent() : Value(wifiOnly),
          ),
        );
    final parts = [
      if (autoSync != null) 'auto $autoSync',
      if (intervalSeconds != null) 'every ${intervalSeconds}s',
      if (wifiOnly != null) 'wifi only $wifiOnly',
    ];
    _log.info(
      'destination: triggers of $path: ${parts.join(', ')}'
      '${changed == 0 ? ' (no destination)' : ''}',
    );
    return changed > 0;
  }

  /// Stores the probe result for [libraryPath].
  Future<void> setCapabilities(
    String libraryPath,
    WebDavCapabilities capabilities,
  ) async {
    final path = p.normalize(libraryPath);
    await (_db.update(
      _db.syncDestinations,
    )..where((t) => t.libraryPath.equals(path))).write(
      SyncDestinationsCompanion(capabilities: Value(capabilities.encode())),
    );
    _log.info(
      'destination: capabilities for $path: ${capabilities.describe()}',
    );
  }

  /// The stored probe result of [libraryPath], or null when never probed.
  Future<WebDavCapabilities?> capabilities(String libraryPath) async {
    final row = await destination(libraryPath);
    return row == null ? null : WebDavCapabilities.decode(row.capabilities);
  }

  /// Records how a sync of [libraryPath] ended: without [error], a success
  /// at [at] (now by default) that clears the last error; with one, the
  /// error, keeping the last success.
  Future<void> recordSyncResult(
    String libraryPath, {
    String? error,
    DateTime? at,
  }) async {
    final path = p.normalize(libraryPath);
    await (_db.update(
      _db.syncDestinations,
    )..where((t) => t.libraryPath.equals(path))).write(
      error == null
          ? SyncDestinationsCompanion(
              lastSyncAtMs: Value((at ?? _now()).millisecondsSinceEpoch),
              lastError: const Value(null),
            )
          : SyncDestinationsCompanion(lastError: Value(error)),
    );
    if (error == null) {
      _log.info('destination: sync of $path succeeded');
    } else {
      _log.warning('destination: sync of $path failed: $error');
    }
  }

  /// Forgets everything about [libraryPath]'s sync: destination, items and
  /// queue. The password is the caller's (`SyncSecretStore`).
  Future<void> removeLibrary(String libraryPath) async {
    final path = p.normalize(libraryPath);
    final (destinations, items, ops) = await _db.transaction(() async {
      final destinations = await (_db.delete(
        _db.syncDestinations,
      )..where((t) => t.libraryPath.equals(path))).go();
      final items = await _deleteItems(path);
      final ops = await (_db.delete(
        _db.syncOps,
      )..where((t) => t.libraryPath.equals(path))).go();
      return (destinations, items, ops);
    });
    _log.info(
      'removed sync state of $path: $destinations destination, '
      '$items items, $ops queued hints',
    );
  }

  Future<int> _deleteItems(String path) => (_db.delete(
    _db.syncItems,
  )..where((t) => t.libraryPath.equals(path))).go();

  // --- items ----------------------------------------------------------------

  /// Every agreed item of [libraryPath], by path.
  Future<Map<String, SyncItem>> items(String libraryPath) async {
    final rows = await (_db.select(
      _db.syncItems,
    )..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))).get();
    return {for (final row in rows) row.path: row};
  }

  /// The agreed item at [path], or null.
  Future<SyncItem?> item(String libraryPath, String path) =>
      (_db.select(_db.syncItems)..where(
            (t) =>
                t.libraryPath.equals(p.normalize(libraryPath)) &
                t.path.equals(path),
          ))
          .getSingleOrNull();

  /// Records [items] (replacing rows at the same paths) in one batch.
  ///
  /// Their `libraryPath` is normalized; everything else is stored as
  /// given.
  Future<void> putItems(Iterable<SyncItem> items) async {
    final rows = [
      for (final item in items)
        item.copyWith(libraryPath: p.normalize(item.libraryPath)),
    ];
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.syncItems, rows);
    });
    _log.debug(
      'items: recorded ${rows.length} '
      '(${rows.take(3).map((r) => r.path).join(', ')}'
      '${rows.length > 3 ? ', …' : ''})',
    );
  }

  /// Drops the rows at [paths] (files; see [removeItemsUnder] for
  /// folders).
  Future<void> removeItems(String libraryPath, Iterable<String> paths) async {
    final list = paths.toList();
    if (list.isEmpty) return;
    final root = p.normalize(libraryPath);
    final removed = await (_db.delete(
      _db.syncItems,
    )..where((t) => t.libraryPath.equals(root) & t.path.isIn(list))).go();
    _log.debug('items: removed $removed of ${list.length} requested');
  }

  /// Drops the rows of every file under [folder].
  Future<void> removeItemsUnder(String libraryPath, String folder) async {
    final root = p.normalize(libraryPath);
    final removed = await (_db.delete(
      _db.syncItems,
    )..where((t) => t.libraryPath.equals(root) & _under(t.path, folder))).go();
    _log.debug('items: removed $removed under $folder');
  }

  /// Re-paths the row at [from] — or, when [from] is a folder, every row
  /// under it — to [to], replacing rows already there. For a remote
  /// `MOVE` that succeeded: the agreed state moves with the file.
  Future<void> moveItems(String libraryPath, String from, String to) async {
    final root = p.normalize(libraryPath);
    final moved = await _db.transaction(() async {
      final rows =
          await (_db.select(_db.syncItems)..where(
                (t) =>
                    t.libraryPath.equals(root) &
                    (t.path.equals(from) | _under(t.path, from)),
              ))
              .get();
      if (rows.isEmpty) return 0;
      await (_db.delete(_db.syncItems)..where(
            (t) =>
                t.libraryPath.equals(root) &
                (t.path.equals(from) | _under(t.path, from)),
          ))
          .go();
      final renamed = [
        for (final row in rows)
          row.copyWith(path: '$to${row.path.substring(from.length)}'),
      ];
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.syncItems, renamed);
      });
      return rows.length;
    });
    _log.info('items: moved $moved from $from to $to');
  }

  /// `path` lies strictly under [folder] (a literal prefix match: `LIKE`
  /// would treat `_` and `%` in folder names as wildcards).
  static Expression<bool> _under(GeneratedColumn<String> path, String folder) {
    final prefix = '$folder/';
    return path.substr(1, prefix.length).equals(prefix) &
        path.length.isBiggerThanValue(prefix.length);
  }

  // --- queue ----------------------------------------------------------------

  /// Queues a hint that [path] [kind] ([fromPath] for [SyncOpKind.moved]).
  ///
  /// One hint per path; a new one coalesces with what is queued:
  ///
  /// - `changed` onto a `moved` keeps the move (the content is checked at
  ///   the target anyway); onto anything else it becomes `changed`.
  /// - `deleted` onto a `moved` also queues `deleted` for the move's source
  ///   (the remote still has the file there) unless that path has its own
  ///   hint.
  /// - `moved` from a path with a hint takes it over: a `moved` source
  ///   chains (A→B then B→C is A→C, and A→B→A is `changed` at A), anything
  ///   else is dropped. Hints under a moved folder move with it.
  ///
  /// A rewrite keeps the hint's backoff (a new edit during an outage does
  /// not hammer the server; the network coming back calls [retryNow]) and
  /// always advances `created_at_ms`, which is what [completeOp] and
  /// [failOp] check.
  Future<void> enqueue(
    String libraryPath,
    String path,
    SyncOpKind kind, {
    String? fromPath,
  }) async {
    if (kind == SyncOpKind.moved && (fromPath == null || fromPath == path)) {
      throw ArgumentError('A move needs a different fromPath');
    }
    final root = p.normalize(libraryPath);
    final note = await _db.transaction(() async {
      var effectiveKind = kind;
      var effectiveFrom = kind == SyncOpKind.moved ? fromPath : null;
      final notes = <String>[];

      if (kind == SyncOpKind.moved) {
        final source = await _op(root, fromPath!);
        if (source != null) {
          await _deleteOp(source.id);
          if (SyncOpKind.parse(source.kind) == SyncOpKind.moved) {
            effectiveFrom = source.fromPath;
            notes.add('chains ${source.fromPath} → $fromPath');
            if (effectiveFrom == path) {
              effectiveKind = SyncOpKind.changed;
              effectiveFrom = null;
              notes.add('moved back: changed');
            }
          } else {
            notes.add('takes over ${source.kind} at $fromPath');
          }
        }
        final nested = await _reparentOps(root, fromPath, path);
        if (nested > 0) notes.add('$nested hints under it moved too');
      }

      final existing = await _op(root, path);
      if (existing != null) {
        final previous = SyncOpKind.parse(existing.kind);
        if (previous == SyncOpKind.moved && kind == SyncOpKind.changed) {
          effectiveKind = SyncOpKind.moved;
          effectiveFrom = existing.fromPath;
          notes.add('keeps the move from ${existing.fromPath}');
        } else if (previous == SyncOpKind.moved && kind == SyncOpKind.deleted) {
          final source = existing.fromPath;
          if (source != null && await _op(root, source) == null) {
            await _insertOp(root, source, SyncOpKind.deleted, null, null);
            notes.add('queued deleted for the move source $source');
          }
        }
        if (previous != effectiveKind) {
          notes.add('replaces ${existing.kind}');
        }
      }
      await _insertOp(root, path, effectiveKind, effectiveFrom, existing);
      return '${effectiveKind.name} $path'
          '${effectiveFrom == null ? '' : ' from $effectiveFrom'}'
          '${notes.isEmpty ? '' : ' (${notes.join('; ')})'}';
    });
    _log.info('queue: $note');
  }

  /// Every queued hint of [libraryPath], oldest first.
  Future<List<SyncOp>> pendingOps(String libraryPath) =>
      (_db.select(_db.syncOps)
            ..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// The hints of [libraryPath] whose backoff has run out.
  Future<List<SyncOp>> dueOps(String libraryPath) {
    final now = _nowMs;
    return (_db.select(_db.syncOps)
          ..where(
            (t) =>
                t.libraryPath.equals(p.normalize(libraryPath)) &
                t.nextAttemptAtMs.isSmallerOrEqualValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// When the earliest hint of [libraryPath] that is still backing off
  /// becomes due, or null when none is waiting.
  Future<DateTime?> nextRetryAt(String libraryPath) async {
    final now = _nowMs;
    final row =
        await (_db.select(_db.syncOps)
              ..where(
                (t) =>
                    t.libraryPath.equals(p.normalize(libraryPath)) &
                    t.nextAttemptAtMs.isBiggerThanValue(now),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.nextAttemptAtMs)])
              ..limit(1))
            .getSingleOrNull();
    return row == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.nextAttemptAtMs);
  }

  /// Removes [op] once its path reconciled. Returns false — and removes
  /// nothing — when the hint was rewritten after [op] was read: the newer
  /// hint still needs a sync.
  Future<bool> completeOp(SyncOp op) async {
    final removed =
        await (_db.delete(_db.syncOps)..where(
              (t) => t.id.equals(op.id) & t.createdAtMs.equals(op.createdAtMs),
            ))
            .go();
    _log.debug(
      removed == 1
          ? 'queue: done ${op.kind} ${op.path}'
          : 'queue: ${op.kind} ${op.path} was rewritten meanwhile, kept',
    );
    return removed == 1;
  }

  /// Records a failed run of [op]: one more attempt, the next one after
  /// [syncBackoff]. Returns the updated hint, or null when it was
  /// rewritten or removed after [op] was read (then its backoff is left
  /// alone).
  Future<SyncOp?> failOp(SyncOp op, String error) async {
    final attempts = op.attempts + 1;
    final wait = syncBackoff(attempts);
    final next = _nowMs + wait.inMilliseconds;
    final updated =
        await (_db.update(_db.syncOps)..where(
              (t) => t.id.equals(op.id) & t.createdAtMs.equals(op.createdAtMs),
            ))
            .write(
              SyncOpsCompanion(
                attempts: Value(attempts),
                nextAttemptAtMs: Value(next),
                lastError: Value(error),
              ),
            );
    if (updated == 0) {
      _log.debug('queue: ${op.kind} ${op.path} failed but was rewritten');
      return null;
    }
    _log.warning(
      'queue: ${op.kind} ${op.path} failed (attempt $attempts), '
      'retry in ${wait.inSeconds}s: $error',
    );
    return op.copyWith(
      attempts: attempts,
      nextAttemptAtMs: next,
      lastError: Value(error),
    );
  }

  /// Makes every hint of [libraryPath] due now (the network came back, or
  /// the user asked for a sync), keeping the attempt counts.
  Future<void> retryNow(String libraryPath) async {
    final count =
        await (_db.update(_db.syncOps)..where(
              (t) =>
                  t.libraryPath.equals(p.normalize(libraryPath)) &
                  t.nextAttemptAtMs.isBiggerThanValue(0),
            ))
            .write(const SyncOpsCompanion(nextAttemptAtMs: Value(0)));
    if (count > 0) _log.info('queue: $count hints of $libraryPath due now');
  }

  Future<SyncOp?> _op(String root, String path) =>
      (_db.select(_db.syncOps)
            ..where((t) => t.libraryPath.equals(root) & t.path.equals(path)))
          .getSingleOrNull();

  Future<void> _deleteOp(int id) =>
      (_db.delete(_db.syncOps)..where((t) => t.id.equals(id))).go();

  /// Writes the hint at [path], replacing [existing] (keeping its row id,
  /// attempts and backoff) with a strictly newer `created_at_ms`.
  Future<void> _insertOp(
    String root,
    String path,
    SyncOpKind kind,
    String? fromPath,
    SyncOp? existing,
  ) async {
    final created = existing == null
        ? _nowMs
        : math.max(_nowMs, existing.createdAtMs + 1);
    if (existing == null) {
      await _db
          .into(_db.syncOps)
          .insert(
            SyncOpsCompanion.insert(
              libraryPath: root,
              path: path,
              kind: kind.name,
              fromPath: Value(fromPath),
              createdAtMs: created,
            ),
          );
      return;
    }
    await (_db.update(
      _db.syncOps,
    )..where((t) => t.id.equals(existing.id))).write(
      SyncOpsCompanion(
        kind: Value(kind.name),
        fromPath: Value(fromPath),
        createdAtMs: Value(created),
      ),
    );
  }

  /// Moves the hints under folder [from] to [to]; returns how many.
  Future<int> _reparentOps(String root, String from, String to) async {
    final rows = await (_db.select(
      _db.syncOps,
    )..where((t) => t.libraryPath.equals(root) & _under(t.path, from))).get();
    for (final row in rows) {
      final target = '$to${row.path.substring(from.length)}';
      await (_db.delete(
        _db.syncOps,
      )..where((t) => t.libraryPath.equals(root) & t.path.equals(target))).go();
      await (_db.update(_db.syncOps)..where((t) => t.id.equals(row.id))).write(
        SyncOpsCompanion(
          path: Value(target),
          createdAtMs: Value(math.max(_nowMs, row.createdAtMs + 1)),
        ),
      );
    }
    return rows.length;
  }
}
