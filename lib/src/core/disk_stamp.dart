import 'dart:io';

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
final class DiskStamp {
  /// Records [size] and [modified].
  const new({required this.size, required this.modified});

  /// The file's size in bytes.
  final int size;

  /// When it was last written, to the millisecond.
  final DateTime modified;

  /// What the file at [path] looks like now, or null when there is nothing
  /// to stamp — the file is gone, or the filesystem will not answer.
  ///
  /// `statSync` answers for a missing file too, with a `notFound` type and a
  /// zero size: stamping that would make a deleted note look unchanged.
  static DiskStamp? of(String path) {
    try {
      final stat = File(path).statSync();
      if (stat.type == FileSystemEntityType.notFound) return null;
      return DiskStamp(size: stat.size, modified: stat.modified);
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
      return DiskStamp(size: stat.size, modified: stat.modified);
    } on Object {
      return null;
    }
  }

  /// Whether [other] is the same size and time as this stamp.
  ///
  /// Size and time together: a write that lands in the same second and
  /// changes the size is caught by the size, and one that keeps the size is
  /// caught by the time. A file whose bytes changed with both unchanged is
  /// the one case this cannot see, and no watcher reports it either.
  bool sameAs(DiskStamp? other) =>
      other != null &&
      other.size == size &&
      other.modified.millisecondsSinceEpoch == modified.millisecondsSinceEpoch;

  /// Whether the file at [path] is still the one this stamped.
  bool matches(String path) => sameAs(DiskStamp.of(path));

  /// [matches], without blocking this isolate (see [ofAsync]).
  Future<bool> matchesAsync(String path) async => sameAs(await ofAsync(path));
}
