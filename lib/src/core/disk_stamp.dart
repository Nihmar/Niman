import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// What a file looked like when it was last read or written: its size and
/// its modification time.
///
/// A watcher reports that something happened to a path, not that the note
/// changed: a touch, a rescan, a copy of the same content and an event
/// already acted on all arrive as "changed". Comparing what is on disk now
/// against what was last seen is O(1) — a stat — and it is what tells the two
/// apart without reading the file back and comparing its text, which on a
/// note of hundreds of megabytes is hundreds of milliseconds (see
/// `docs/records/huge-notes.md`).
///
/// A modification time is only as fine as the file system's clock (#1365):
/// FAT keeps it to two seconds, HFS+ to one, exFAT and the clocks of Windows
/// and of a Linux kernel to a few milliseconds. Another program that writes
/// the same number of bytes within the tick the file was last written in
/// leaves the same size and the same time. Such a change can only come
/// while the stamp is **ambiguous** — it was taken within a tick of the
/// file's time ([isAmbiguous]) — so then the stamp is vouched for by the
/// content, not by the stat alone ([vouches]).
final class DiskStamp {
  /// Records [size] and [modified], and when they were [taken] and the
  /// sha256 of the content they stand for ([digest]), where those are known.
  const new({
    required this.size,
    required this.modified,
    this.taken,
    this.digest,
  });

  /// The file's size in bytes.
  final int size;

  /// When it was last written, to the millisecond.
  final DateTime modified;

  /// When the file was observed: the moment of the stat, or of the write
  /// that left it. Null when it is not known, which is read as the worst
  /// case (the stamp is ambiguous).
  final DateTime? taken;

  /// The sha256 (hex) of the file's content when it was observed, kept by
  /// the read or the write that made the stamp: what an ambiguous stamp is
  /// vouched for by. Null when nothing kept it.
  final String? digest;

  /// How fine a clock marks a time with no fraction of a second: such a time
  /// comes from FAT (two seconds) or HFS+ (one), where a change within the
  /// tick of the last write leaves the same time.
  static const Duration coarseTick = Duration(seconds: 2);

  /// The coarsest tick among the file systems that do keep fractions: the
  /// Windows system clock (15.6 ms), a Linux kernel's timestamp clock
  /// (up to 10 ms) and exFAT (10 ms).
  static const Duration fineTick = Duration(milliseconds: 20);

  /// The tick of the clock that wrote [modified]: a time with no fraction of
  /// a second is a coarse file system's, any other a fine one's.
  Duration get tick =>
      modified.microsecondsSinceEpoch % 1000000 == 0 ? coarseTick : fineTick;

  /// Whether a change of the file could have kept this stamp: the file was
  /// observed less than a [tick] after its time, so another write in the
  /// same tick leaves the same size and time. A file observed later than
  /// that cannot be written again in the tick it carries.
  bool get isAmbiguous => (taken ?? modified).difference(modified) < tick;

  /// This stamp with the [digest] of the content it stands for.
  DiskStamp withDigest(String digest) =>
      DiskStamp(size: size, modified: modified, taken: taken, digest: digest);

  /// The sha256 (hex) of [bytes], the form [digest] has.
  static String digestOfBytes(List<int> bytes) =>
      sha256.convert(bytes).toString();

  /// What the file at [path] looks like now, or null when there is nothing
  /// to stamp — the file is gone, or the filesystem will not answer.
  ///
  /// `statSync` answers for a missing file too, with a `notFound` type and a
  /// zero size: stamping that would make a deleted note look unchanged.
  static DiskStamp? of(String path) {
    try {
      final stat = File(path).statSync();
      if (stat.type == FileSystemEntityType.notFound) return null;
      return DiskStamp(
        size: stat.size,
        modified: stat.modified,
        taken: DateTime.now(),
      );
    } on Object {
      return null;
    }
  }

  /// [of], asked of the file system without blocking this isolate: the
  /// stat runs on the I/O threads. What the UI isolate asks with — a
  /// `statSync` there is a FUSE round trip per call on Android (#1060).
  static Future<DiskStamp?> ofAsync(String path) async {
    try {
      final stat = await FileStat.stat(path);
      if (stat.type == FileSystemEntityType.notFound) return null;
      return DiskStamp(
        size: stat.size,
        modified: stat.modified,
        taken: DateTime.now(),
      );
    } on Object {
      return null;
    }
  }

  /// Whether [other] is the same size and time as this stamp: the stat alone,
  /// which cannot tell a change within the clock's tick ([vouches] does).
  bool sameAs(DiskStamp? other) =>
      other != null &&
      other.size == size &&
      other.modified.millisecondsSinceEpoch == modified.millisecondsSinceEpoch;

  /// Whether this stamp, of a file found at [path] with the same size and
  /// time ([sameAs]), still stands for its content: a stamp that is not
  /// [isAmbiguous] does, and an ambiguous one does when the file hashes to
  /// its [digest] — and does not when it has none, for then nothing says the
  /// content is the one it saw.
  bool vouches(String path) {
    if (!isAmbiguous) return true;
    final known = digest;
    if (known == null) return false;
    try {
      return digestOfBytes(File(path).readAsBytesSync()) == known;
    } on Object {
      return false;
    }
  }

  /// [vouches], without blocking this isolate: the file is hashed in a
  /// short-lived one, a chunk at a time.
  Future<bool> vouchesAsync(String path) async {
    if (!isAmbiguous) return true;
    final known = digest;
    if (known == null) return false;
    try {
      return await Isolate.run(() => _digestOfFile(path)) == known;
    } on Object {
      return false;
    }
  }

  /// Whether the file at [path] is still the one this stamped.
  bool matches(String path) => sameAs(DiskStamp.of(path)) && vouches(path);

  /// [matches], without blocking this isolate (see [ofAsync]).
  Future<bool> matchesAsync(String path) async =>
      sameAs(await ofAsync(path)) && await vouchesAsync(path);
}

/// The sha256 (hex) of the file at [path], read a chunk at a time.
Future<String> _digestOfFile(String path) async =>
    (await sha256.bind(File(path).openRead()).first).toString();
