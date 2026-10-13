/// The beginning of a note, read for a preview card (#846).
library;

import 'dart:async' show unawaited;

import 'package:meta/meta.dart' show visibleForTesting;
import 'package:niman/src/core/lru_cache.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/link_preview.dart';

/// Reads the beginning of a note for a preview card.
abstract interface class PreviewSource {
  /// The beginning of the note at library-relative [path], for a preview
  /// card (#846): read off the UI isolate, kept by the note's revision so a
  /// sweep of hovers over the same link is one read. Null when the note is
  /// not in the index or cannot be read.
  Future<NotePreviewText?> previewText(String path);
}

/// [PreviewSource] over the index and a reader of note files.
final class PreviewReader implements PreviewSource {
  /// Reads through [_read] (off the UI isolate; null reads none) the notes
  /// the index [_db] holds.
  new(this._db, {this._read});

  final IndexDatabase _db;
  final Future<NotePreviewText?> Function(String path)? _read;

  /// The previews read or being read, by note and revision (its mtime and
  /// size, as the index records it).
  final LruCache<(int, DateTime, int), Future<NotePreviewText?>> _kept =
      LruCache<(int, DateTime, int), Future<NotePreviewText?>>(
        PreviewLimits.kept,
      );

  @override
  Future<NotePreviewText?> previewText(String path) async {
    final read = _read;
    final note = await NoteDao(_db).find(path);
    if (read == null || note == null || note.isDir) return null;
    final key = (note.id, note.modified, note.size);
    // A hit — a read done, or one under way that this shares — is a use.
    final kept = _kept[key];
    if (kept != null) return await kept;
    final reading = read(path);
    _kept[key] = reading;
    try {
      final text = await reading;
      if (text == null) unawaited(_kept.remove(key));
      return text;
    } on Object {
      // A note gone since the index heard of it: nothing is kept for it.
      unawaited(_kept.remove(key));
      return null;
    }
  }

  /// How many previews are kept now, for the test that holds the cache to
  /// [PreviewLimits.kept].
  @visibleForTesting
  int get held => _kept.length;
}

/// [PreviewSource] that shows a note open with unsaved edits as its buffer
/// holds it, not as the disk still does: the edits are what the note says
/// now, and the card shows the note (#846). Every other note is read from
/// [_disk].
final class UnsavedFirstPreviews implements PreviewSource {
  /// Reads the notes [_unsaved] has no buffer text for (null) from [_disk].
  new(this._disk, this._unsaved);

  final PreviewSource _disk;

  /// The unsaved buffer text of the note at a library-relative path, or
  /// null.
  final String? Function(String path) _unsaved;

  @override
  Future<NotePreviewText?> previewText(String path) {
    final text = _unsaved(path);
    if (text != null) return Future.value(NotePreviewText.of(text));
    return _disk.previewText(path);
  }
}
