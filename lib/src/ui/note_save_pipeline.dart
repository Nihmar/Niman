import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Saves [content] as the note at absolute [path]; [editSession] is the
/// editor session the save belongs to (one opening of the note).
typedef NoteSaver = Future<void> Function(
  String path,
  String content, {
  required int editSession,
});

/// Saves a note whose text the editor never joins: [content] makes the
/// bytes a slice at a time, and the save answers when the disk holds them.
/// See `NoteView.saveNoteStream`.
///
/// [references] are the note's tags and links as of the text saved, when
/// the editor keeps them (a long note): the index takes them rather than
/// reading the note for them.
typedef NoteStreamSaver = Future<void> Function(
  String path,
  NoteContentProducer content, {
  required int editSession,
  NoteReferences? references,
});

/// How an open note reaches the disk: the revision the editor is at and the
/// one the disk holds, the debounce after an edit, one save at a time with a
/// trailing one for the edits that land meanwhile, and the streaming save
/// that hands a long note over in slices rather than joining it.
///
/// No UI: the note view tells it of each edit, of a note taken from disk
/// ([markClean], [newSession]) and of a note leaving ([saveOutgoing],
/// [close]); it reads the note through the callbacks it is given.
final class NoteSavePipeline {
  /// A pipeline for the note the callbacks read.
  ///
  /// [notePath] is the note on screen, [ready] whether its text is loaded,
  /// [text] the note joined, [buffer] the editor's buffer (null without
  /// one) and [references] the note's tags and links as the editor keeps
  /// them. [saveNote], [writeNote] and [saveNoteStream] are the writers, read
  /// at each save. [onSaved] hears of a save of the note on screen that
  /// reached the disk; [onSettled] of every save that ended, however it did.
  new({
    required this.notePath,
    required this.ready,
    required this.text,
    required this.buffer,
    required this.references,
    required this.saveNote,
    required this.writeNote,
    required this.saveNoteStream,
    required this.onSaved,
    required this.onSettled,
  });

  static const AppLogger _log = AppLogger(name: 'editor');

  /// The note on screen's absolute path.
  final String Function() notePath;

  /// Whether the note at [notePath] is loaded: until it is, the buffer is
  /// not its text.
  final bool Function() ready;

  /// The note's text, joined.
  final String Function() text;

  /// The editor's buffer, or null when there is none.
  final SourceBuffer? Function() buffer;

  /// The note's tags and links as of [buffer], when the editor keeps them.
  final NoteReferences? Function() references;

  /// The library's write path (`NoteView.saveNote`).
  final NoteSaver? Function() saveNote;

  /// The test seam's write (`NoteView.writeNote`).
  final Future<void> Function(String path, String content)? Function()
  writeNote;

  /// The library's streaming write (`NoteView.saveNoteStream`).
  final NoteStreamSaver? Function() saveNoteStream;

  /// The note at the path given reached the disk at the revision the
  /// pipeline now calls saved.
  final void Function(String path) onSaved;

  /// A save ended, written or failed.
  final VoidCallback onSettled;

  /// Text-edit counter; the disk matches [lastSavedRevision]. A saved note
  /// is a revision, not a text copy.
  int get revision => _revision;
  int _revision = 0;

  /// The revision the disk holds.
  int get lastSavedRevision => _lastSavedRevision;
  int _lastSavedRevision = 0;

  /// Whether the editor holds edits the disk does not.
  bool get dirty => _revision != _lastSavedRevision;

  /// Whether a save is in flight.
  bool get saving => _saving;
  bool _saving = false;

  /// Whether a save is in flight or one is owed once it ends.
  bool get busy => _saving || _pending;
  bool _pending = false;

  /// Process-wide source of [editSession] ids.
  static int _editSessions = 0;

  /// The editor session: a new id each time a note's text is taken from
  /// disk (opened, or adopted after an outside change). History keys its
  /// "state before this session's edits" snapshot on it.
  int get editSession => _editSession;
  int _editSession = 0;

  /// The save in flight, if any: a coalesced [save] hands it back, so a
  /// caller that must know the disk moved ([saveForClose]) awaits the
  /// real write instead of the pending flag.
  Future<void>? _activeSave;

  Timer? _timer;

  /// The note was edited: a new revision, saved after [_saveDelay].
  void edited() {
    _revision++;
    _timer?.cancel();
    _timer = Timer(_saveDelay, save);
  }

  /// The disk holds what the editor does: the note was just taken from it.
  void markClean() => _lastSavedRevision = _revision;

  /// Starts a new editor session, and returns its id.
  int newSession() => _editSession = ++_editSessions;

  /// Drops the save an edit scheduled.
  void cancel() => _timer?.cancel();

  /// How long after the last edit the note is saved.
  ///
  /// Half a second, or a second while a save is in flight (typing fast: one
  /// trailing save, not a queue). A note that size waits for a real pause, as
  /// the statistics do: the save no longer stalls the frames — it goes over
  /// in slices (see [_performSave]) — but it is still a write of hundreds of
  /// megabytes, and there is no reason to make one for every breath between
  /// words.
  Duration get _saveDelay {
    final length = buffer()?.length ?? 0;
    if (length > 16 << 20) return const Duration(seconds: 5);
    if (length > 2 << 20) return const Duration(seconds: 2);
    return _saving
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);
  }

  /// Saves the buffer at most once: a request that finds a save in flight
  /// coalesces into one trailing save (the text is re-read from the buffer
  /// at that point, so nothing is lost) and returns the write already
  /// running, so an awaiting caller still learns when the disk moved.
  Future<void> save({String? path}) {
    // Until the note at notePath is loaded, the buffer is not its text:
    // it is the previous note's, or nothing — and when the load failed,
    // notePath may be a picture. Only a save with its own path (the
    // outgoing note's) may write then (#156).
    if (path == null && !ready()) return Future<void>.value();
    final revision = _revision;
    if (revision == _lastSavedRevision) {
      return Future<void>.value(); // nothing new on disk
    }
    if (path == null && _saving) {
      _pending = true;
      return _activeSave ?? Future<void>.value();
    }
    _saving = true;
    final future = _performSave(revision, path ?? notePath());
    _activeSave = future;
    return future;
  }

  /// The note at [path] is leaving the editor for another one: its edits
  /// are saved under its own path, before the buffer becomes the incoming
  /// note's. Completes once they are on disk.
  ///
  /// Its text is read synchronously at the start of a save, before the
  /// load that follows resets the buffer. A save in flight holds an *older*
  /// revision of it, so the newest one is taken here and its write chained
  /// behind that save — switching during a save dropped every edit made
  /// since it started (#334).
  Future<void> saveOutgoing(String path) {
    _timer?.cancel();
    _pending = false;
    if (!dirty) return _activeSave ?? Future<void>.value();
    if (!_saving) return save(path: path);
    return _saveOutgoingAfter(_activeSave, path);
  }

  /// The editor is going away: whatever it holds is saved, and the returned
  /// future completes when the disk has the note's last edit.
  Future<void> close() {
    _timer?.cancel();
    return dirty ? save() : _activeSave ?? Future<void>.value();
  }

  /// Saves the outgoing note at [target] as it stands *now*, after
  /// [waiting] — the save already running for it — so one note never has
  /// two writes racing for the same path.
  ///
  /// The text, or the streaming save's buffer snapshot, is taken before the
  /// first await: the note switch that calls this replaces the buffer with
  /// the incoming note's, and an edit made during a save would otherwise be
  /// the one nobody writes (#334).
  Future<void> _saveOutgoingAfter(Future<void>? waiting, String target) async {
    final session = _editSession;
    final stream = _takeStreamSave();
    final joined = stream == null ? text() : null;
    if (waiting != null) {
      try {
        await waiting;
      } on Object {
        // The save that was already running reports its own failure; this
        // one still has to try.
      }
    }
    final clock = Stopwatch()..start();
    try {
      if (stream != null) {
        await saveNoteStream()!(
          target,
          (index) => _nextSlice(stream, index),
          editSession: session,
          references: stream.references,
        );
      } else {
        await _write(target, joined!, session);
      }
      _log.info(
        'note saved: $target (outgoing, ${clock.elapsedMilliseconds} ms)',
      );
    } on Object catch (error) {
      _log.error('note save failed: $target ($error)');
      rethrow;
    }
  }

  /// The actual write for [save]; a write error reaches every caller
  /// awaiting the returned future.
  ///
  /// On the unified surface the note is handed over in slices and never
  /// joined whole: the join and the encode of a 246 MB note cost the UI
  /// isolate 300–530 ms in one go (see `docs/records/huge-notes.md`), and both
  /// are cut here into turns of a few milliseconds that leave the frames
  /// their gaps. A note with no streaming writer (a note outside a library, a
  /// test) is joined and saved whole.
  Future<void> _performSave(int revision, String target) async {
    final clock = Stopwatch()..start();
    final stream = _takeStreamSave();
    if (stream != null) {
      // Awaited, not handed over: `_activeSave` must be the write itself, or
      // a caller that awaits a save — the close guard, a note switch (#334) —
      // believes the disk moved while the slices are still going out.
      return await _saveStreamed(stream, revision, target, clock);
    }
    // The full-text join (O(n)) happens here only — the save path, never
    // the keystroke path.
    final joinClock = Stopwatch()..start();
    final joined = text();
    final joinMs = joinClock.elapsedMilliseconds;
    // Read with the text, before the first await: a note switch that
    // saves the outgoing note is followed by a load that starts the next
    // session, and this save belongs to the one it came from.
    final session = _editSession;
    _log.info(
      'save start: $target (${joined.length} chars, join $joinMs ms, '
      'session $session)',
    );
    try {
      await _write(target, joined, session);
      _saved(target, revision);
      _log.info(
        'note saved: $target (${joined.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
    } finally {
      _finishSave();
    }
  }

  /// Saves with the note handed over in slices, off the join.
  ///
  /// The write is away from this isolate, so this only awaits it — after
  /// reading the trailing-save flag the write's own edits may have set,
  /// which is what keeps an edit that landed mid-save from being the one
  /// nobody writes.
  Future<void> _saveStreamed(
    _StreamSave stream,
    int revision,
    String target,
    Stopwatch clock,
  ) async {
    final lines = stream.buffer;
    // Read with the buffer, before the first await: a note switch that
    // saves the outgoing note is followed by a load that starts the next
    // session, and this save belongs to the one it came from.
    final session = _editSession;
    _log.info(
      'save start: $target (${lines.length} chars in '
      '${stream.slices} slices, session $session)',
    );
    try {
      await saveNoteStream()!(
        target,
        (index) => _nextSlice(stream, index),
        editSession: session,
        references: stream.references,
      );
      _saved(target, revision);
      _log.info(
        'note saved: $target (${lines.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
    } on Object catch (error) {
      _log.error('note save failed: $target ($error)');
      rethrow;
    } finally {
      _finishSave();
    }
  }

  /// [target] holds [revision] now: when it is the note on screen, that is
  /// the revision the disk has.
  void _saved(String target, int revision) {
    if (target != notePath()) return;
    _lastSavedRevision = revision;
    onSaved(target);
  }

  /// The save is over, however it ended: the flag goes, the owner is told,
  /// and a save that arrived meanwhile runs its own turn.
  void _finishSave() {
    _saving = false;
    final trailing = _pending;
    _pending = false;
    onSettled();
    if (trailing) unawaited(save());
  }

  /// The note as this save will write it, or null when there is nothing to
  /// stream (no seam, no buffer, an empty note).
  ///
  /// The buffer is taken whole — a copy of the two line lists, O(lines) of
  /// pointers, the strings themselves shared — so an edit that lands
  /// between two slices cannot make the note it writes a different note
  /// from the one it started. It is what a save of a note being typed in
  /// has to be: the writer's own text at one moment, never half of one and
  /// half of another.
  _StreamSave? _takeStreamSave() {
    if (saveNoteStream() == null) return null;
    final lines = buffer();
    if (lines == null || lines.lineCount == 0) return null;
    // The references with the lines, of the same revision: the source
    // pane's scan follows this very buffer.
    return _StreamSave(lines.snapshot(), references: references());
  }

  /// The next slice of [stream]'s buffer, or null when the note is out.
  ///
  /// Each slice is built and encoded here, on the UI isolate, because that
  /// is where the note's strings are — a string is copied between
  /// isolates, never shared, and one copy of the whole note is what this
  /// exists to avoid. Each is small enough that the frame after it is on
  /// time.
  Future<NoteBytes?> _nextSlice(_StreamSave stream, int index) async {
    final first = index * kSaveSliceLines;
    if (first >= stream.buffer.lineCount) return null;
    final slice = stream.buffer.sliceText(
      first,
      first + kSaveSliceLines,
      kSaveSliceChars,
    );
    // Building the first slice is what starts the save; the gap the frames
    // need is the one after it, not before it.
    if (index > 0) await Future<void>.delayed(Duration.zero);
    return utf8.encode(slice);
  }

  /// Lines one slice of a streaming save asks for, and the character count
  /// that cuts it short — a note of very long lines would otherwise build
  /// a slice of megabytes. Around four milliseconds of join and encode per
  /// slice at these figures, measured on the 2.7 M-line fixture.
  static const int kSaveSliceLines = 16384;

  /// The character count that cuts a slice short (see [kSaveSliceLines]).
  static const int kSaveSliceChars = 4 << 20;

  /// The close guard's save (T-PP-11): writes until the disk holds the
  /// latest revision — waiting out a save that was already in flight — and
  /// completes with the write's error when one fails. The caller keeps the
  /// window open on a failure: the edits are still only in the buffer.
  Future<void> saveForClose() async {
    while (dirty) {
      await save();
    }
  }

  Future<void> _write(String path, String content, int editSession) async {
    final saver = saveNote();
    if (saver != null) {
      await saver(path, content, editSession: editSession);
      return;
    }
    final seam = writeNote();
    if (seam != null) {
      await seam(path, content);
      return;
    }
    // Encode + atomic write off the UI isolate: the utf8 encode is an O(n)
    // string pass and the write the FUSE round trips — neither may touch
    // the UI frame.
    final (bytes, encodeMs, writeMs) = await Isolate.run(() async {
      final encodeClock = Stopwatch()..start();
      final encoded = utf8.encode(content);
      final encodeMs = encodeClock.elapsedMilliseconds;
      final writeClock = Stopwatch()..start();
      await writeFileAtomically(File(path), encoded);
      final writeMs = writeClock.elapsedMilliseconds;
      return (encoded.length, encodeMs, writeMs);
    });
    _log.debug(
      'save write: $bytes bytes (encode $encodeMs ms, write $writeMs ms, '
      'off-isolate)',
    );
  }
}

/// What a streaming save holds of the note while it runs: the lines as they
/// were when the save started, which no later edit reaches.
final class _StreamSave {
  /// Saves [buffer]'s lines, slice by slice.
  const new(this.buffer, {this.references});

  /// The note's lines, at the moment the save began.
  final SourceBuffer buffer;

  /// The note's tags and links as of [buffer], when the editor keeps them.
  final NoteReferences? references;

  /// How many slices the save will hand over; for the log only.
  int get slices =>
      (buffer.lineCount + NoteSavePipeline.kSaveSliceLines - 1) ~/
      NoteSavePipeline.kSaveSliceLines;
}
