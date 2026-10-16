import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/detached_save.dart';
import 'package:niman/src/ui/note_view.dart' show NoteView;
import 'package:path/path.dart' as p;

/// A note whose buffer may hold edits the disk does not have yet
/// (T-PP-11).
///
/// The adapter is a read/write view of the note's own save state (the
/// revision pair) and its buffer — it holds no copy of the text, so it
/// cannot drift.
abstract interface class UnsavedNote {
  /// The note's absolute path (its identity).
  String get path;

  /// True while the buffer holds edits the disk does not have yet.
  bool get unsaved;

  /// The buffer's text now: what the disk will hold once [save] lands.
  String get text;

  /// Writes the buffer to disk. Completes when the disk holds the latest
  /// edit (including saves that were already in flight), or with the
  /// write's error.
  Future<void> save();
}

/// An [UnsavedNote] that can give the front of its buffer without reading
/// all of it: a note of novel length is not joined whole to show its first
/// screenful (#868).
abstract interface class UnsavedNoteHead {
  /// At most the first [maxChars] UTF-16 units of the buffer's text.
  String textHead(int maxChars);
}

/// The app-level view of which open notes hold unsaved edits (T-PP-11).
///
/// The source of truth is each [NoteView]'s revision state; the tracker
/// only publishes it, so the window's close request can act on it without
/// reading editor state itself. One tracker per app session
/// ([unsavedTrackerProvider]).
final class UnsavedTracker extends ChangeNotifier {
  static const AppLogger _log = AppLogger(name: 'unsaved');

  final StreamController<Set<String>> _diskChanges =
      StreamController<Set<String>>.broadcast(sync: true);

  /// The files that changed under the open notes (#1042, #1055): a flow that
  /// rewrote notes behind the editors' backs says so here, and every open
  /// note whose file is among them looks at it and adopts the change when its
  /// buffer holds nothing the disk does not. An empty set means any of them
  /// may have changed.
  Stream<Set<String>> get diskChanges => _diskChanges.stream;

  /// Tells the open notes that the files at the absolute [paths] changed on
  /// disk — or, with none, that any open note's may have.
  void notifyDiskChanged(Set<String> paths) => _diskChanges.add(paths);

  @override
  void dispose() {
    unawaited(_diskChanges.close());
    super.dispose();
  }

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

  /// The buffer text of the open note at absolute [path] while it holds
  /// edits the disk does not have yet, else null: what a reader of the note
  /// shows instead of the disk's older text (a link's preview, #846).
  ///
  /// With [maxChars], only the front of it — at most that many UTF-16 units,
  /// asked of a note that can give them without joining the rest
  /// ([UnsavedNoteHead]); the whole text otherwise.
  String? unsavedTextOf(String path, {int? maxChars}) {
    for (final note in _notes) {
      if (note.unsaved && p.equals(note.path, path)) {
        if (maxChars != null && note is UnsavedNoteHead) {
          return (note as UnsavedNoteHead).textHead(maxChars);
        }
        return note.text;
      }
    }
    return null;
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

  /// The dirty set the listeners were last told about, as [unsavedPaths]
  /// read then: what a call that publishes must differ from.
  List<String> _published = const <String>[];

  /// Holds a write the app owes for the note at [path] after its view has
  /// gone or moved on to another note (#1061, #1054): [write] is started now,
  /// and until it lands the note is unsaved — [saveAll] waits for it, and a
  /// failed one stays, with [text], to be retried. Completes when the write
  /// lands, or with its error.
  Future<void> hold(
    String path,
    String Function() text,
    Future<void> Function() write,
  ) {
    // A newer text of the note replaces an older one still held: the older
    // would write after it, or on top of it when it retries.
    for (final note in _notes.toList()) {
      if (note is DetachedSave && p.equals(note.path, path)) {
        note.supersede();
        _notes.remove(note);
      }
    }
    final save = DetachedSave(
      path: path,
      textOf: text,
      write: write,
      onWritten: unregister,
    );
    register(save);
    return save.start();
  }

  /// The text the app still owes the disk for the note at [path], handed to
  /// the editor that opens it again (#1054), or null when it owes none.
  ///
  /// A note switched away from while the disk would not take its write is
  /// held here with its text. Opening it again reads the disk — the old
  /// text — so the editor takes the held text instead, as unsaved edits of
  /// its own, and the held save is dropped: two owners of one text would
  /// write the older over the newer when the retry came.
  String? takeOver(String path) {
    String? text;
    for (final note in _notes.toList()) {
      if (note is DetachedSave && note.unsaved && p.equals(note.path, path)) {
        // In registration order: the last one is the newest.
        text = note.text;
        note.supersede();
        _notes.remove(note);
      }
    }
    if (text != null) _publish();
    return text;
  }

  /// Tracks [note]; it reads its dirty state live until [unregister].
  /// Registering the same note twice is a no-op.
  void register(UnsavedNote note) {
    if (_notes.add(note)) _publish();
  }

  /// Stops tracking [note].
  void unregister(UnsavedNote note) {
    if (_notes.remove(note)) _publish();
  }

  /// A note's revision or a save landed (the note's state calls this on
  /// the keystroke/save paths), so the dirty set may have changed.
  void noteChanged() => _publish();

  /// Notifies the listeners when the dirty set reads differently from the
  /// one they were last told about.
  ///
  /// [noteChanged] is called on every keystroke, and the set — which notes
  /// hold edits the disk does not have — changes once, when the first of
  /// them lands. Publishing each keystroke rebuilt the tab row it is
  /// merged into, and its labels lay out per build: ten characters typed
  /// into an unmodified note were ten rebuilds of the row a keystroke
  /// spends its frame on (#362).
  void _publish() {
    final paths = unsavedPaths;
    if (listEquals(paths, _published)) return;
    _published = paths;
    notifyListeners();
  }
}

/// The single tracker for the app session.
final unsavedTrackerProvider = Provider<UnsavedTracker>((ref) {
  final tracker = UnsavedTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});

/// Writes every unsaved note before the library is left, and answers the
/// error that stopped it — null when every note is on disk.
///
/// The one way out of a library (#351, #493): the switch screen, the
/// library window, the settings' Close library row and a widget target
/// pointing at another library all take the shell away from the open
/// editors, so each one awaits this first and stays when a write fails.
Future<Object?> saveBeforeLeaving(UnsavedTracker? unsaved) async {
  if (unsaved == null) return null;
  try {
    await unsaved.saveAll();
    return null;
  } on Object catch (error) {
    return error;
  }
}
