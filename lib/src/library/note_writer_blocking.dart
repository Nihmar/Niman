import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/creation_time.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/snapshot_policy.dart';

// The writes of `note_writer.dart` that block: each runs on a background
// isolate (an `existsSync` or `statSync` is a FUSE round trip on Android,
// #1143), which `ui_isolate_io_test.dart` holds this file to.

/// What [writeNoteFile] did: the bytes written, whether the file is new,
/// where the time went, and the history snapshot taken before the write
/// (or why it failed — a failed snapshot never stops the save).
///
/// `sha256` is the digest of the bytes written, made as they were, and
/// `modified` the file's time once in place: what the reindex behind the
/// save takes instead of hashing the note again (`KnownContent`).
typedef NoteWriteResult = ({
  int bytes,
  bool created,
  int encodeMs,
  int writeMs,
  SnapshotOutcome? snapshot,
  String? snapshotError,
  String sha256,
  DateTime modified,
});

/// Renames the finished file [tempAbs] over [abs] (creating missing
/// folders), after keeping the replaced content as a history version when
/// [snapshot] says so. The temp file is deleted when the rename fails.
///
/// Top-level so `Isolate.run` can take it. The isolate is here for
/// [snapshotBeforeWrite], which reads and copies the note being replaced;
/// an attachment has no snapshot and takes `swapFileIn` instead.
Future<({bool created, SnapshotOutcome? snapshot, String? snapshotError})>
replaceFileFrom(
  String abs,
  String tempAbs, {
  String? root,
  String? rel,
  SnapshotRequest? snapshot,
}) async {
  SnapshotOutcome? outcome;
  String? snapshotError;
  if (snapshot != null && root != null && rel != null) {
    try {
      outcome = snapshotBeforeWrite(root, rel, snapshot);
    } on Object catch (e) {
      snapshotError = '$e';
    }
  }
  final file = File(abs);
  final created = !file.existsSync();
  try {
    if (created) {
      await file.parent.create(recursive: true);
    } else {
      keepCreationTime(target: abs, replacement: tempAbs);
    }
    await File(tempAbs).rename(abs);
  } on Object {
    final temp = File(tempAbs);
    if (temp.existsSync()) await temp.delete();
    rethrow;
  }
  return (created: created, snapshot: outcome, snapshotError: snapshotError);
}

/// Encodes [content] and writes it atomically to [abs], creating missing
/// folders. With [snapshot] (and the note's [root] and library-relative
/// [rel]) the text being replaced is first kept as a history version when
/// the request says so.
///
/// Top-level so `Isolate.run` can take it: the message carries plain
/// values only.
Future<NoteWriteResult> writeNoteFile(
  String abs,
  String content, {
  String? root,
  String? rel,
  SnapshotRequest? snapshot,
}) async {
  SnapshotOutcome? outcome;
  String? snapshotError;
  if (snapshot != null && root != null && rel != null) {
    try {
      outcome = snapshotBeforeWrite(root, rel, snapshot);
    } on Object catch (e) {
      snapshotError = '$e';
    }
  }
  final encodeClock = Stopwatch()..start();
  final encoded = utf8.encode(content);
  final encodeMs = encodeClock.elapsedMilliseconds;
  final writeClock = Stopwatch()..start();
  final file = File(abs);
  final created = !file.existsSync();
  if (created) await file.parent.create(recursive: true);
  final stamp = await writeFileAtomically(file, encoded);
  return (
    bytes: encoded.length,
    created: created,
    encodeMs: encodeMs,
    writeMs: writeClock.elapsedMilliseconds,
    snapshot: outcome,
    snapshotError: snapshotError,
    sha256: sha256.convert(encoded).toString(),
    // The temp file's stamp, not the renamed-over path's — see
    // [publishTempFile]: on Android the path's stat can still answer the
    // replaced file's attributes, and a save that stored them reported its
    // own next write as another program's (#1055).
    modified: stamp?.modified ?? file.statSync().modified,
  );
}
