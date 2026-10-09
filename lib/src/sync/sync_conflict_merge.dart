import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/diff/record_merge.dart';
import 'package:niman/src/diff/three_way.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/state_merge.dart';
import 'package:niman/src/sync/sync_conflict.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_step_failure.dart';
import 'package:niman/src/sync/sync_step_outcome.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:path/path.dart' as p;

/// Carries out a run's conflict decisions: a path both sides changed is
/// recorded when the contents agree, merged by itself when it can be —
/// the library state files key by key, the task files record by record,
/// notes over the pinned base — and otherwise left for the merge screen.
final class SyncConflictMerger {
  /// A merger for the library at [root].
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this.sides,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's operations: merged texts are written through them.
  final NoteOps ops;

  /// The sync state, where the agreed rows go.
  final SyncStore store;

  /// Reads, checks and records both sides of a path.
  final SyncSides sides;

  static const _log = AppLogger(name: 'sync');

  /// Settles the conflict decision [d]: fetches the server's copy, then
  /// records, merges or reports the path.
  Future<SyncStepOutcome> conflict(
    SyncRunContext c,
    SyncDecision d,
  ) => sides.guarded(() async {
    final local = (await sides.localStillAsPlanned(c, d.path))!;
    final localSha = sides.localShaOf(c, d.path);
    final fetched = await sides.fetch(c, d.path);
    // The fetch wrote the remote body into a temp next to the target,
    // and every end below — the swapped-in download, the merge's
    // write-back through the temp, the path left for the merge screen —
    // consumes it or deletes it. What none of them covered was stopping
    // between the two: a merge the guard stops on a `_ChangedDuringSync`
    // threw past them all and left the full remote body in the library
    // folder as `.x.md.niman-tmp-sync-<µs>`, one more on every retry
    // until the next open's sweep (#495). The temp is this method's to
    // clean up whatever it returns or throws.
    try {
      final remote = sides.remoteFrom(c, d.path, fetched.download);
      final remoteSha = fetched.download.sha256;

      if (remoteSha == localSha) {
        await store.putItems([
          await sides.row(
            c,
            d.path,
            sha: localSha,
            local: local,
            remote: remote,
          ),
        ]);
        _log.info('conflict ${d.path}: same content on both sides, recorded');
        return SyncStepOutcome.done;
      }

      if (d.path.startsWith('.niman/')) {
        // Settings and counters are JSON: merged key by key, not by line,
        // which could break them. A side that does not parse is not a
        // merge: taking the newer file whole replaced the other device's
        // copy — and this device's good copy on the run after — with no
        // history and no way back (#336), so both sides are left as they
        // are and the path is reported like any other conflict.
        final merge = await _mergeState(
          c,
          d,
          fetched.temp,
          remote,
          remoteSha: remoteSha,
        );
        switch (merge) {
          case _StateMerge.merged:
            return SyncStepOutcome.done;
          case _StateMerge.notJson:
            return sides.reportConflict(
              c,
              d,
              localSha: localSha,
              remoteSha: remoteSha,
              why: 'a side is not a JSON object',
            );
          case _StateMerge.clockDecides:
            return sides.reportConflict(
              c,
              d,
              localSha: localSha,
              remoteSha: remoteSha,
              why:
                  'a key both sides changed, which no device clock can '
                  'decide',
            );
        }
      }

      // Both sides changed: with the version they last agreed on, the
      // edits that do not overlap merge without asking anyone
      // (docs/records/sync.md, "Conflicts").
      final merge = await _tryMerge(
        c,
        d,
        fetched.temp,
        remote,
        remoteSha: remoteSha,
      );
      if (merge != null) {
        c.report
          ..merged.add(d.path)
          ..changedLocally.addAll(merge.changedLocally ? [d.path] : const []);
        return SyncStepOutcome.done;
      }

      final conflict = SyncConflict(
        path: d.path,
        localSha256: localSha,
        remoteSha256: remoteSha,
        baseVersion: d.baseVersion,
      );
      c.report.conflicts.add(conflict);
      _log.warning(
        'conflict ${d.path}: both changed (local ${_short(localSha)}, '
        'remote ${_short(remoteSha)}, base ${d.baseVersion ?? 'none'}); '
        'left for the merge',
      );
      return SyncStepOutcome.conflict;
    } finally {
      if (fetched.temp.existsSync()) await fetched.temp.delete();
    }
  });

  /// Merges a library state file ([mergeSettingsJson] key by key, for the
  /// settings and for the Home's tiles (#535), [mergeCountersJson],
  /// [mergeWordList] word by word, [mergeReadingJson] book by book) and
  /// writes the result on whichever side lacks it; [_StateMerge.notJson]
  /// when a JSON side does not parse, and [_StateMerge.clockDecides] when
  /// a settings key or a Home tile both sides changed differently, which
  /// only the file mtimes could settle — and the remote one is the
  /// uploading device's clock (#350). Both cases touch nothing and leave
  /// the path to the caller.
  Future<_StateMerge> _mergeState(
    SyncRunContext c,
    SyncDecision d,
    File remoteCopy,
    WebDavResource remote, {
    required String remoteSha,
  }) async {
    final file = File(p.join(root, d.path));
    final localText = utf8.decode(
      await file.readAsBytes(),
      allowMalformed: true,
    );
    final remoteText = utf8.decode(
      await remoteCopy.readAsBytes(),
      allowMalformed: true,
    );
    final base = c.rows[d.path]?.baseText;
    final String? text;
    if (d.path == NoteOps.settingsFilePath || d.path == HomeFile.filePath) {
      // The clock's vote each way: when the two merges differ, the clock
      // was what picked the disputed key's side — no outcome may rest on
      // it, so the key is left for the user instead.
      final asLocal = mergeSettingsJson(
        base: base,
        local: localText,
        remote: remoteText,
        localNewer: true,
      );
      final asRemote = mergeSettingsJson(
        base: base,
        local: localText,
        remote: remoteText,
        localNewer: false,
      );
      if (asLocal == null || asRemote == null) return _StateMerge.notJson;
      if (asLocal != asRemote) {
        _log.info(
          'merge ${d.path}: a key both sides changed, left for the user',
        );
        return _StateMerge.clockDecides;
      }
      text = asLocal;
    } else if (d.path == _personalDictionaryPath) {
      text = mergeWordList(base: base, local: localText, remote: remoteText);
    } else if (d.path == ReadingPositions.filePath) {
      text = mergeReadingJson(base: base, local: localText, remote: remoteText);
    } else {
      text = mergeCountersJson(local: localText, remote: remoteText);
    }
    if (text == null) {
      _log.info('merge ${d.path}: a side is not a JSON object');
      return _StateMerge.notJson;
    }
    final uploads = text != remoteText;
    if (uploads) {
      await sides.guardMergeUpload(c, d, remote, expectedSha: remoteSha);
    }
    final changedLocally = text != localText;
    if (changedLocally) {
      // Through the temp the download left: syncReplace swaps it in the
      // way a download goes, reloading the settings.
      await remoteCopy.writeAsString(text);
      await sides.localStillAsPlanned(c, d.path);
      await ops.syncReplace(d.path, remoteCopy.path);
      c.report.changedLocally.add(d.path);
    } else {
      await remoteCopy.delete();
    }
    var listed = remote;
    if (uploads) {
      await c.client.uploadFile(
        d.path,
        file,
        ifMatch: c.capabilities.ifMatch ? remote.guardEtag : null,
      );
      listed =
          await c.client.stat(d.path) ??
          (throw const SyncStepFailure('merged but not listed'));
    }
    final after = await sides.stat(d.path);
    if (after == null) throw const SyncStepFailure('merged but not on disk');
    final sha = (await sides.hashLocal([d.path]))[d.path];
    if (sha == null) throw const SyncStepFailure('merged but not hashed');
    await store.putItems([
      await sides.row(c, d.path, sha: sha, local: after, remote: listed),
    ]);
    _log.info(
      'merge ${d.path}: ${base == null ? 'no base' : 'on the base'}'
      '${changedLocally ? ', written here' : ''}'
      '${uploads ? ', uploaded' : ''}',
    );
    return _StateMerge.merged;
  }

  static const _personalDictionaryPath = '.niman/dictionary.txt';

  /// Merges both sides of [d] over the pinned base and writes the result
  /// on both, or returns null when there is no base, the file is not
  /// text, or the edits overlap (then the conflict stays for the user).
  ///
  /// A side that is not valid UTF-8 is not merged either: a lossy decode
  /// would write U+FFFD over bytes nobody touched, here and on the server
  /// (#350). Both sides stay and the path is reported.
  ///
  /// The task files always merge: their lines are records, merged one by
  /// one ([mergeRecords]), and without a base they are the union of both.
  Future<({bool changedLocally})?> _tryMerge(
    SyncRunContext c,
    SyncDecision d,
    File remoteCopy,
    WebDavResource remote, {
    required String remoteSha,
  }) async {
    final base = d.baseVersion;
    final records = _isRecordFile(d.path);
    if (!NoteOps.keepsHistory(d.path)) return null;
    if (base == null && !records) return null;
    var baseText = '';
    if (base != null) {
      try {
        baseText = await ops.readNoteVersion(d.path, base);
      } on Object catch (e) {
        _log.info('merge ${d.path}: base v$base unreadable ($e)');
        if (!records) return null;
      }
    }
    final localText = _decodeUtf8(
      await File(p.join(root, d.path)).readAsBytes(),
    );
    final remoteText = _decodeUtf8(await remoteCopy.readAsBytes());
    if (localText == null || remoteText == null) {
      _log.info('merge ${d.path}: a side is not UTF-8, left for the user');
      return null;
    }
    final String text;
    final String how;
    if (records) {
      text = await _mergeRecordTexts(baseText, localText, remoteText);
      how = 'task lines, ${base == null ? 'no base: union' : 'base v$base'}';
    } else {
      final merge = await _mergeTexts(baseText, localText, remoteText);
      if (!merge.clean) {
        _log.info(
          'merge ${d.path}: ${merge.conflicts.length} overlapping region(s), '
          'left for the user (${merge.describe()})',
        );
        return null;
      }
      text = merge.text();
      how = merge.describe();
    }
    // Guarded before anything is written: a remote that moved since the
    // merge was built would be written over, and on a server without
    // preconditions this is the only guard there is (#350).
    await sides.guardMergeUpload(c, d, remote, expectedSha: remoteSha);
    final changedLocally = text != localText;
    if (changedLocally) await ops.syncMerge(d.path, text);
    // The file on disk is the merge now: hash and stat it as written.
    final local = await sides.stat(d.path);
    if (local == null) throw const SyncStepFailure('merged but not on disk');
    final sha = (await sides.hashLocal([d.path]))[d.path];
    if (sha == null) throw const SyncStepFailure('merged but not hashed');
    await sides.uploadAndRecord(
      c,
      d.path,
      sha: sha,
      local: local,
      notListed: const SyncStepFailure('merged but not listed'),
      ifMatch: c.capabilities.ifMatch ? remote.guardEtag : null,
      modified: DateTime.fromMillisecondsSinceEpoch(local.mtimeMs),
    );
    _log.info('merge ${d.path}: $how, both sides now agree');
    return (changedLocally: changedLocally);
  }

  /// [bytes] as UTF-8, or null when they are not valid UTF-8: merging a
  /// side that decoded only through `allowMalformed` would write U+FFFD
  /// over every invalid byte, in regions nobody touched (#350).
  static String? _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  /// Merges three texts, off the UI isolate when they are long.
  static Future<MergeResult> _mergeTexts(
    String base,
    String local,
    String remote,
  ) {
    final size = base.length + local.length + remote.length;
    if (size <= _inlineMergeLimit) {
      return Future.value(mergeThreeWay(base, local, remote));
    }
    return Isolate.run(() => mergeThreeWay(base, local, remote));
  }

  /// Merges three versions of a task file, off the UI isolate when long.
  static Future<String> _mergeRecordTexts(
    String base,
    String local,
    String remote,
  ) {
    final size = base.length + local.length + remote.length;
    if (size <= _inlineMergeLimit) {
      return Future.value(mergeRecords(base, local, remote));
    }
    return Isolate.run(() => mergeRecords(base, local, remote));
  }

  /// Whether [path] is one of the library's task files, whose lines are
  /// records rather than prose.
  static bool _isRecordFile(String path) =>
      path == todoFileName || path == doneFileName;

  /// Texts up to this many characters (all three together) are merged on
  /// the calling isolate; an isolate costs more than the merge itself.
  static const _inlineMergeLimit = 20000;
}

/// What merging a library state file did.
enum _StateMerge {
  /// The merge went through and the row was recorded.
  merged,

  /// A side is not a JSON object; both sides stay.
  notJson,

  /// A `.niman/settings.json` key both sides changed differently, which
  /// only the file mtimes could settle: both sides stay and the path is
  /// reported (#350).
  clockDecides,
}

String _short(String sha) => sha.length <= 8 ? sha : sha.substring(0, 8);
