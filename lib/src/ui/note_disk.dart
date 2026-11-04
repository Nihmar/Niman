/// The open note's file: reading it off the UI isolate, and what it looked
/// like when it was last read or written (issue #100 moved it out of
/// `note_view.dart`).
library;

import 'package:niman/src/core/disk_stamp.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/markdown/line_ending.dart';
import 'package:niman/src/markdown/note_framing.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/ui/strings.dart';

/// A note read to be opened: its `content`, and the note made ready off the
/// UI isolate — its buffer with its text — when it was read from the disk
/// rather than the test seam.
typedef NoteOpened = ({String content, LoadedNote? ready});

/// A note read again to see whether it changed: its `content`, with the
/// file's stamp and framing when it was read from the disk.
typedef NoteReread = ({String content, DiskStamp? stamp, NoteFraming? framing});

/// Reads the note's file and remembers what it looked like.
final class NoteDisk {
  /// The file reader; [readNote] answers the test seam, or null for the disk.
  new({required this.readNote});

  static const AppLogger _log = AppLogger(name: 'editor');

  /// Reads a note's content instead of the disk (`NoteView.readNote`, a test
  /// seam), or null.
  final Future<String> Function(String path)? Function() readNote;

  /// What the note's file looked like when it was last read or written.
  ///
  /// A reload is asked for by a watcher, and a watcher is not a promise: a
  /// touch, a rescan, or a change to a file that was already saved all arrive
  /// as "the note changed". Knowing the file's size and time is O(1), and it
  /// is what tells a real change from an event — the read, the normalize and
  /// the comparison against the pane's text are what cost on a 246 MB note
  /// (208 ms to join the pane's text, 734 ms to normalize a fresh read, 44 ms
  /// to compare; measured 2026-09-22).
  ///
  /// Never stat'ed here (#1060): a read brings the stamp of the file from
  /// before it was read, a save brings the one of the file it left, and a
  /// look at the file asks the I/O threads ([DiskStamp.ofAsync]).
  DiskStamp? stamp;

  /// The line ending and byte order mark the note's file has (#1056). The
  /// buffer holds `\n` lines and no mark whatever the file had; a save writes
  /// these back.
  NoteFraming framing = NoteFraming.plain;

  /// Reads the note at [path] to open it; throws what the read failed with.
  Future<NoteOpened> open(String path) async {
    final seam = readNote();
    if (seam != null) {
      // The test seam: content per the injected reader.
      return (content: await seam(path), ready: null);
    }
    final loaded = await loadNote(path);
    if (loaded is NoteReadFailure) throw loaded;
    final ready = loaded as LoadedNote;
    return (content: ready.text, ready: ready);
  }

  /// Takes the stamp and framing of the note [opened] read.
  void adoptOpened(NoteOpened opened) {
    // The test seam reads nothing, so it has no stamp to keep.
    stamp = opened.ready?.stamp;
    // The seam's content is text already: whatever mark it holds is in it.
    framing =
        opened.ready?.framing ??
        NoteFraming(lineEnding: LineEnding.dominantOf(opened.content));
  }

  /// Reads the note at [path] again; null when there is nothing to adopt —
  /// the read failed, or found no text.
  Future<NoteReread?> reread(String path) async {
    try {
      final seam = readNote();
      if (seam != null) {
        return (content: await seam(path), stamp: null, framing: null);
      }
      final loaded = await readNoteText(path);
      if (loaded is! NoteTextRead) return null;
      return (
        content: loaded.text,
        stamp: loaded.stamp,
        framing: loaded.framing,
      );
    } on Object catch (error) {
      _log.warning('reload read failed: $path ($error)');
      return null;
    }
  }

  /// Takes the stamp and framing of the note [read] read again.
  void adoptReread(NoteReread read) {
    stamp = read.stamp;
    framing =
        read.framing ??
        NoteFraming(lineEnding: LineEnding.dominantOf(read.content));
  }

  /// Whether the file at [path] is the one [stamp] recorded.
  ///
  /// A file that cannot be stat'ed, or one nothing recorded, is read: the
  /// fallback is the comparison this stands in front of.
  Future<bool> unchanged(String path) async =>
      await stamp?.matchesAsync(path) ?? false;

  /// Why a note could not be opened, in the user's words, for the [reason]
  /// its read failed with; the raw error goes to the log only (issue #156).
  static String failureMessage(NoteReadReason reason) => switch (reason) {
    NoteReadReason.notText => AppStrings.noteNotText,
    NoteReadReason.missing => AppStrings.noteLoadMissing,
    NoteReadReason.denied => AppStrings.noteLoadDenied,
    NoteReadReason.locked => AppStrings.noteLoadLocked,
    NoteReadReason.other => AppStrings.noteLoadFailed,
  };
}
