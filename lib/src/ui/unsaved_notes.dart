import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/note_view.dart' show NoteView;

/// A note whose buffer may hold edits the disk does not have yet
/// (T-PP-11).
///
/// The adapter is a read/write view of the note's own save state (the
/// revision pair) — it holds no copy of the text, so it cannot drift.
abstract interface class UnsavedNote {
  /// The note's absolute path (its identity).
  String get path;

  /// True while the buffer holds edits the disk does not have yet.
  bool get unsaved;

  /// Writes the buffer to disk. Completes when the disk holds the latest
  /// edit (including saves that were already in flight), or with the
  /// write's error.
  Future<void> save();
}

/// The app-level view of which open notes hold unsaved edits (T-PP-11).
///
/// The source of truth is each [NoteView]'s revision state; the tracker
/// only publishes it, so the window's close request can act on it without
/// reading editor state itself. One tracker per app session
/// ([unsavedTrackerProvider]).
final class UnsavedTracker extends ChangeNotifier {
  static const AppLogger _log = AppLogger(name: 'unsaved');

  /// Insertion-ordered (a LinkedHashSet), so [unsavedPaths] reads in open
  /// order and a duplicate registration is a no-op.
  final Set<UnsavedNote> _notes = <UnsavedNote>{};

  /// True while any tracked note holds edits the disk does not have.
  bool get hasUnsaved => _notes.any((note) => note.unsaved);

  /// The unsaved notes' absolute paths, in open order.
  List<String> get unsavedPaths {
    return [
      for (final note in _notes)
        if (note.unsaved) note.path,
    ];
  }

  /// Writes every unsaved note to disk. Completes when the disk holds each
  /// note's latest edit, or with the first write error (then the caller
  /// must not close: the edits are still only in the buffers).
  Future<void> saveAll() async {
    final dirty = [
      for (final note in _notes)
        if (note.unsaved) note.save(),
    ];
    _log.info('save-all: ${dirty.length} note(s)');
    await Future.wait(dirty);
  }

  /// Tracks [note]; it reads its dirty state live until [unregister].
  /// Registering the same note twice is a no-op.
  void register(UnsavedNote note) {
    if (_notes.add(note)) notifyListeners();
  }

  /// Stops tracking [note].
  void unregister(UnsavedNote note) {
    if (_notes.remove(note)) notifyListeners();
  }

  /// A note's revision or a save landed (the note's state calls this on
  /// the keystroke/save paths), so the dirty set may have changed.
  void noteChanged() => notifyListeners();
}

/// The single tracker for the app session.
final unsavedTrackerProvider = Provider<UnsavedTracker>((ref) {
  final tracker = UnsavedTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});
