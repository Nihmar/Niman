import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_disk.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:niman/src/ui/note_stats.dart';
import 'package:niman/src/ui/note_text_cache.dart';

/// What a change of the open note was, for the view that listens (#1257).
enum NoteEvent {
  /// A load started: the note that went is no note's text any more.
  loading,

  /// The loaded note has its surface: the place, the find bar and the
  /// spelling are the new note's from here.
  surfaced,

  /// The load landed: the note is on screen, ready to edit.
  opened,

  /// The load failed: [NoteSession.error] says why.
  failed,

  /// The disk's text changed under a clean note, and the note took it.
  reread,

  /// An edit changed the note's kind (the frontmatter `type`).
  kindChanged,
}

/// The open note's lifecycle (#1257): its load, its reload when the disk
/// changed under it, loading / ready / failed, its kind, the surface its
/// text is edited on, and whether it was edited since it opened.
///
/// Each transition says what it was ([event]) to the view, which does the
/// drawing, the focus and the panes; this holds no widget.
final class NoteSession extends ChangeNotifier {
  /// The lifecycle of the note read through [disk] and saved through
  /// [saves], its text kept in [text].
  new({
    required this.disk,
    required this.saves,
    required this.text,
    required this.newSurface,
    required this.takeOver,
    required this.alive,
  });

  static const AppLogger _log = AppLogger(name: 'editor');

  /// The note's file.
  final NoteDisk disk;

  /// How the note reaches the disk.
  final NoteSavePipeline saves;

  /// The note's text as its surface has it.
  final NoteTextCache text;

  /// A surface over [SourceBuffer], its caret at the offset given, wired to
  /// report its edits.
  final MarkdownSurfaceController Function(SourceBuffer buffer, int caret)
  newSurface;

  /// Text the app still owes the note at a path, an earlier write the disk
  /// would not take (#1054), taken once.
  final String? Function(String path) takeOver;

  /// Whether the view is still up.
  final bool Function() alive;

  /// Whether a load is in flight, or a reload mutes the buffer's edits.
  bool get loading => _loading;
  bool _loading = true;

  /// Whether the note is loaded and editable.
  bool get ready => _ready;
  bool _ready = false;

  /// Why the note could not be opened, in the user's words; the raw error
  /// goes to the log only (issue #156).
  String? get error => _error;
  String? _error;

  /// Whether the failed file is not text at all: the error pane offers it
  /// to the OS instead.
  bool get notText => _notText;
  bool _notText = false;

  /// The loaded note's kind (the frontmatter `type` value, null = plain
  /// note); null again while a load is in flight.
  String? get kind => _kind;
  String? _kind;

  /// The note on its surface: its buffer, its undo history and the door
  /// every command comes in through. None while a load is in flight.
  MarkdownSurfaceController? get surface => _surface;
  MarkdownSurfaceController? _surface;

  /// What the change being notified was; null outside a notification.
  NoteEvent? get event => _event;
  NoteEvent? _event;

  /// The path the session holds, as it was opened or moved to.
  String? _path;

  /// Which load is the current one (#1059): counted up as each starts, and
  /// compared after every await, so a load the reader has moved on from —
  /// another note, the same note asked for again — changes nothing when it
  /// ends, whether it ends well or not.
  int _generation = 0;

  /// Whether the note was edited since it was opened.
  bool _edited = false;

  /// Whether the session holds the loaded note [moved]'s editor can keep.
  bool get holdsNote => _ready && !_loading && _surface != null;

  /// The note's surface, made over [text] when it has none yet: a pane
  /// built before any load landed edits that text from its start.
  MarkdownSurfaceController ensureSurface() {
    if (_surface case final surface?) return surface;
    final body = text.text;
    final surface = newSurface(SourceBuffer.fromText(body), 0);
    adoptWords(surface);
    _surface = surface;
    text.text = body;
    return surface;
  }

  /// Opens the note at [path], its caret at [caret].
  ///
  /// The note that went stops being any note's text first: its save
  /// already left with its own path and text, and the incoming note is not
  /// read yet, so nothing is owed to the disk (#156). Its text goes now,
  /// before the next note is read (#1202): kept until the new one landed, a
  /// switch between two long notes held both at its peak.
  Future<void> open(String path, {int caret = 0}) async {
    _path = path;
    final generation = ++_generation;
    saves.markClean();
    _surface = null;
    text.text = '';
    _loading = true;
    _ready = false;
    _error = null;
    _notText = false;
    _kind = null;
    _notify(NoteEvent.loading);
    try {
      final opened = await disk.open(path);
      final ready = opened.ready;
      if (!alive() || generation != _generation) return;
      // The buffer uses LF: normalize line endings on load.
      final onDisk = ready?.text ?? normalizedLineEndings(opened.content);
      // Text the app still owes this note's file is the note's text, ahead
      // of the file's (#1054). It is taken only here, once this load is the
      // one that lands, so a load the reader moved on from does not carry
      // it off. It is edits of this session the disk does not have: the
      // buffer starts from it and is unsaved, so its own pipeline writes it.
      final held = takeOver(path);
      final body = held ?? onDisk;
      final restored = held != null && held != onDisk;
      // The note kind (T-TK-02): detection scans the leading block only,
      // never the whole text.
      _kind = frontmatterTypeOf(body);
      final surface = newSurface(
        (restored ? null : ready?.buffer) ?? SourceBuffer.fromText(body),
        caret.clamp(0, body.length),
      );
      adoptWords(surface);
      _surface = surface;
      disk.adoptOpened(opened);
      text.text = body;
      _notify(NoteEvent.surfaced);
      saves.markClean();
      final session = saves.newSession();
      _log.debug('edit session $session: $path');
      if (restored) {
        _log.info('note opened with its unsaved text back: $path');
        _edited = true;
        saves.edited();
      }
      _loading = false;
      _ready = true;
      _error = null;
      _notify(NoteEvent.opened);
    } on Object catch (error) {
      // A load the reader moved on from reports nothing: its failure is not
      // this note's (#1059).
      if (!alive() || generation != _generation) return;
      // A file that is not text is an attachment, not a broken note: it
      // says so, and nothing about it is ever reported saved (#156).
      final reason = NoteReadReason.of(error);
      _loading = false;
      _notText = reason == NoteReadReason.notText;
      _error = NoteDisk.failureMessage(reason);
      _log.error('note load failed: $path ($error)');
      _notify(NoteEvent.failed);
    }
  }

  /// Opens the note at [path] again after a load that failed: the error
  /// pane's Retry, and the next reload trigger while it is up (#1059).
  void retry(String path) {
    if (_loading) return;
    unawaited(open(path));
  }

  /// Adopts the disk's text of the note at [path] when it changed under it
  /// (a home-screen widget toggle edits the file in a background isolate,
  /// like any other external edit).
  ///
  /// Only when the buffer is clean: a save in flight, a pending save, or
  /// unsaved edits keep the user's text — the disk converges on the next
  /// save instead. Identical content is a no-op, so a resume without an
  /// external edit never disturbs the caret. [checkStamp] first asks
  /// whether the file changed at all, which a test's injected reader cannot
  /// answer.
  Future<void> reload(String path, {required bool checkStamp}) async {
    // A note that failed to open has nothing on screen to protect: the next
    // trigger — a resume, a sync that touched it — is a new try (#1059).
    if (_error != null && !_notText) return retry(path);
    if (_loading || saves.busy) {
      _log.debug('reload skipped (busy): $path');
      return;
    }
    if (saves.dirty) {
      _log.debug('reload skipped (unsaved edits): $path');
      return;
    }
    final generation = _generation;
    // What the file looked like when it was last read or written, before
    // the read: O(1) against 250 ms of joining and comparing, and O(1)
    // against the read itself.
    if (checkStamp && await disk.unchanged(path)) {
      _log.debug('reload skipped (the file did not change): $path');
      return;
    }
    // The reader may have typed, or moved on, while the file was asked.
    if (!_current(path, generation)) return;
    final read = await disk.reread(path);
    if (read == null || !_current(path, generation)) return;
    final body = normalizedLineEndings(read.content);
    // The file is what the pane has, or is about to be: either way this is
    // the file that was looked at, so the next look can stop at the stamp
    // instead of reading it again (#1060).
    disk.adoptReread(read);
    if (body == text.text) return;
    // The buffer's own report of the change is muted, as a load's is.
    _loading = true;
    if (_surface case final surface?) {
      surface.replaceAll(body);
      adoptWords(surface);
    }
    saves.markClean();
    // Text taken from disk again: edits from here on are a new session.
    final session = saves.newSession();
    _log.debug('edit session $session: $path (adopted disk text)');
    _kind = frontmatterTypeOf(body);
    _loading = false;
    _notify(NoteEvent.reread);
    _log.info('note reloaded: $path (external change, ${body.length} chars)');
  }

  /// Whether a reload begun for [path] at [generation] still speaks for the
  /// note: the view is up, on that note, with nothing typed meanwhile.
  bool _current(String path, int generation) =>
      alive() &&
      _path == path &&
      generation == _generation &&
      !_loading &&
      !saves.busy &&
      !saves.dirty;

  /// The loaded note's file moved to [path] (#1076): its editor stays as
  /// it is, and the edits from here on are saved under the new name, as a
  /// new session.
  void moved(String path) {
    _path = path;
    saves.newSession();
  }

  /// The note was edited.
  void markEdited() => _edited = true;

  /// Whether the note was edited since it opened, once: the note is being
  /// closed.
  bool takeEdited() {
    final edited = _edited;
    _edited = false;
    return edited;
  }

  /// The note's text is now [body], by an edit that may change its kind:
  /// says so when it did.
  void kindEdited(String body) {
    final kind = frontmatterTypeOf(body);
    final changed = kind != _kind;
    _kind = kind;
    _notify(changed ? NoteEvent.kindChanged : null);
  }

  /// Gives [surface] its word count, here for a note small enough to walk
  /// and in the background for one that is not (see `WordCount`).
  ///
  /// It has to be there before the first edit: the count follows the lines
  /// an edit touched, and one that is not built yet has no lines to follow.
  static void adoptWords(MarkdownSurfaceController surface) {
    if (surface.words.isCounted) return;
    final buffer = surface.buffer;
    if (buffer.length > NoteStatsController.syncWorkLimit) {
      unawaited(surface.buildWords());
      return;
    }
    surface.words.adopt(buffer);
  }

  void _notify(NoteEvent? event) {
    _event = event;
    try {
      notifyListeners();
    } finally {
      _event = null;
    }
  }
}
