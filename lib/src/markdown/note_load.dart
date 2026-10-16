/// A note read and made ready off the UI isolate, for the unified surface.
///
/// Opening the 246 MB stress note froze the window for seconds after its
/// text arrived (profile, 2026-09-23): the line endings were normalized, the
/// text was split into its 2.76 M lines and the buffer was handed to an
/// isolate for its word count — which *copies* it, on the isolate that sends
/// it — all on the UI isolate. Here one isolate does all of it and answers
/// through `Isolate.exit`, which hands the result over without copying it:
/// the UI isolate receives a note it only has to draw.
///
/// The note's word count is not worked out here: it was ~1 s of the 246 MB
/// note's load, with the note waiting behind it. The note is shown as soon
/// as it is read, and the surface counts it in the background
/// (`MarkdownSurfaceController.buildWords`), the count landing a moment
/// later.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A note as the unified surface takes it: its text with the line endings
/// the editor holds, and the buffer over that text.
final class LoadedNote {
  /// Creates a loaded note.
  const new({required this.text, required this.buffer, this.stamp});

  /// The note's text, its line endings `\n`.
  final String text;

  /// The buffer over [text].
  final SourceBuffer buffer;

  /// What the file looked like **before** it was read (#1060): a change that
  /// lands after the stat leaves a stamp older than the file, so the next
  /// look finds the file different and reads it again; a stamp taken after
  /// the read would match the new file while [text] is the old one, and the
  /// note would never be reloaded. Null when the file could not be stat'ed.
  final DiskStamp? stamp;
}

/// A note's text as it is written, read for a reload: [text] with the
/// [stamp] of the file as it was before the read (see [LoadedNote.stamp]).
final class NoteTextRead {
  /// Creates a read.
  const new({required this.text, required this.stamp});

  /// The text, line endings as on disk.
  final String text;

  /// The file before the read, or null when it could not be stat'ed.
  final DiskStamp? stamp;
}

/// [text] with its line endings made `\n`, as the editor holds a note —
/// and no pass over it when there is no `\r` to replace.
String normalizedLineEndings(String text) => text.contains('\r')
    ? text.replaceAll('\r\n', '\n').replaceAll('\r', '\n')
    : text;

/// Reads the note at [path] and makes it ready, in an isolate: a
/// [LoadedNote], or a [NoteReadFailure] saying the file is not text.
///
/// The closure crosses to the isolate with nothing but [path] in it, which
/// is why this is a top-level function: one made inside a widget's state
/// carries the state with it, and the isolate refuses it.
Future<Object> loadNote(String path) => Isolate.run(() => loadNoteSync(path));

/// Reads the text of the note at [path], in an isolate: a [NoteTextRead] —
/// the text as it is written, with the file's stamp from before the read —
/// or a [NoteReadFailure] saying the file is not text. What a reload compares
/// against the note on screen.
Future<Object> readNoteText(String path) =>
    Isolate.run(() => readNoteTextSync(path));

/// [readNoteText] on the calling isolate: what the isolate runs, kept
/// callable on its own for the test that counts its decodes.
@visibleForTesting
Object readNoteTextSync(
  String path, {
  List<int> Function(String path)? readBytes,
}) {
  // Before the read, not after it (see [LoadedNote.stamp]).
  final stamp = DiskStamp.of(path);
  final String? text;
  try {
    text = decodeNoteTextIfText(
      readBytes?.call(path) ?? File(path).readAsBytesSync(),
    );
  } on FileSystemException catch (error) {
    return _unreadable(path, error);
  }
  if (text == null) return NoteReadFailure('$path: not text', notText: true);
  return NoteTextRead(text: text, stamp: stamp);
}

/// The failure a read that threw amounts to: a value the isolate can send
/// whatever the platform's exception holds, and that the pane can word by
/// its reason (#1059).
NoteReadFailure _unreadable(String path, FileSystemException error) =>
    NoteReadFailure('$path: $error', reason: NoteReadReason.of(error));

/// [loadNote] on the calling isolate: what the isolate runs, kept callable
/// on its own for the test that counts its decodes. [readBytes] is the
/// test's seam for the read itself.
@visibleForTesting
Object loadNoteSync(String path, {List<int> Function(String path)? readBytes}) {
  // Before the read, not after it (see [LoadedNote.stamp]).
  final stamp = DiskStamp.of(path);
  final String? read;
  try {
    read = decodeNoteTextIfText(
      readBytes?.call(path) ?? File(path).readAsBytesSync(),
    );
  } on FileSystemException catch (error) {
    return _unreadable(path, error);
  }
  if (read == null) return NoteReadFailure('$path: not text', notText: true);
  final text = normalizedLineEndings(read);
  return LoadedNote(
    text: text,
    buffer: SourceBuffer.fromText(text),
    stamp: stamp,
  );
}
