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

/// An [UnsavedNote] whose pending writes can be dropped because the note is
/// being deleted (#1321): its text goes to the trash with the file, and a
/// write that came after the delete would only bring the note back.
abstract interface class UnsavedNoteDiscard {
  /// Stops writing: no save is made from here on, and the note reads as
  /// saved. Completes when a write already running has ended — the delete
  /// must come after it, not race it.
  Future<void> discard();

  /// The delete did not happen: the note holds what it held, writes again,
  /// and a note with edits is saved.
  void restore();
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

  final StreamController<String> _heldFailures =
      StreamController<String>.broadcast(sync: true);

  /// The note at each path whose held write failed (#1363): a note switched
  /// away from or closed whose text the disk would not take. Said once per
  /// run of failures, as the editor says it of the note on screen; the text
  /// is kept and retried, and the note reads as unsaved until it lands.
  Stream<String> get heldWriteFailures => _heldFailures.stream;

  @override
  void dispose() {
    unawaited(_heldFailures.close());
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
      onWritten: (save) {
        final key = p.canonicalize(path);
        _landed[key] = (_landed[key] ?? 0) + 1;
        unregister(save);
      },
      onFailed: (save) => _heldFailures.add(save.path),
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

  /// Writes the pending edits of every note at [path] or under it — an open
  /// editor, a write held for a note switched away from — and completes when
  /// they are on disk, so a delete of [path] sends the latest text to the
  /// trash and loses none of it (#1321). Edits typed while it waits are
  /// written too. Throws [SaveUnderFailed] for the first note that will not
  /// save: nothing is to be deleted then.
  Future<void> saveUnder(String path) async {
    while (true) {
      final dirty = [
        for (final note in _notes.toList())
          if (note.unsaved && _isAt(note, path)) note,
      ];
      if (dirty.isEmpty) return;
      for (final note in dirty) {
        try {
          await note.save();
        } on Object catch (error) {
          throw SaveUnderFailed(note.path, error);
        }
      }
    }
  }

  /// Drops what is left of the pending writes of every note at [path] or
  /// under it (an open editor, a write held for a note switched away from),
  /// once [saveUnder] has written them and just before [path] is deleted
  /// (#1321): after the delete nothing may write the path again. Completes
  /// when the writes already running have ended. A failed delete calls
  /// [restoreUnder].
  Future<void> discardUnder(String path) async {
    final ended = <Future<void>>[
      for (final note in _notes.toList())
        if (note is UnsavedNoteDiscard && _isAt(note, path))
          (note as UnsavedNoteDiscard).discard(),
    ];
    _publish();
    await Future.wait(ended);
  }

  /// The delete of [path] failed: what [discardUnder] dropped is owed again.
  void restoreUnder(String path) {
    for (final note in _notes.toList()) {
      if (note is UnsavedNoteDiscard && _isAt(note, path)) {
        (note as UnsavedNoteDiscard).restore();
      }
    }
    _publish();
  }

  static bool _isAt(UnsavedNote note, String path) =>
      p.equals(note.path, path) || p.isWithin(path, note.path);

  /// Completes when the writes held for the note at [path] that are running
  /// have ended: what an editor opening the note waits for before it reads the
  /// file, so a read cannot see the text from before a write that is about to
  /// land (#1360).
  Future<void> writesSettled(String path) => Future.wait([
    for (final note in _notes.toList())
      if (note is DetachedSave && p.equals(note.path, path)) note.settled,
  ]);

  final Map<String, DateTime> _restored = <String, DateTime>{};

  /// A version was just restored into the note at the absolute [path] (#1361).
  /// The open editor of it, asked to re-read the file next, shows the restored
  /// text even if it holds edits ([takeRestored]).
  void restored(String path) =>
      _restored[p.canonicalize(path)] = DateTime.now();

  /// Whether a restore into the note at [path] was announced in the last few
  /// seconds, taken once: what is left over is not a later reload's.
  bool takeRestored(String path) {
    final at = _restored.remove(p.canonicalize(path));
    return at != null &&
        DateTime.now().difference(at) < const Duration(seconds: 10);
  }

  final Map<String, int> _landed = <String, int>{};

  /// How many held writes of the note at [path] have landed so far: an editor
  /// whose read of the file spans a change of it reads again (#1360).
  int landings(String path) => _landed[p.canonicalize(path)] ?? 0;

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

/// A note about to be deleted would not save ([UnsavedTracker.saveUnder]).
final class SaveUnderFailed implements Exception {
  /// The note at the absolute [path] failed to save with [error].
  const new(this.path, this.error);

  /// The note that would not save.
  final String path;

  /// What the write threw.
  final Object error;

  @override
  String toString() => 'SaveUnderFailed: "$path" ($error)';
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
