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

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A note as the unified surface takes it: its text with the line endings
/// the editor holds, and the buffer over that text.
final class LoadedNote {
  /// Creates a loaded note.
  const new({required this.text, required this.buffer});

  /// The note's text, its line endings `\n`.
  final String text;

  /// The buffer over [text].
  final SourceBuffer buffer;
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
Future<Object> loadNote(String path) => Isolate.run(() => _loadNote(path));

/// Reads the text of the note at [path], in an isolate: the text as it is
/// written, or a [NoteReadFailure] saying the file is not text. What a
/// reload compares against the note on screen.
Future<Object> readNoteText(String path) => Isolate.run(() => _readText(path));

Object _readText(String path) {
  final bytes = File(path).readAsBytesSync();
  try {
    return utf8.decode(bytes);
  } on FormatException catch (error) {
    return NoteReadFailure('$path: $error', notText: true);
  }
}

Object _loadNote(String path) {
  final bytes = File(path).readAsBytesSync();
  final String decoded;
  try {
    decoded = utf8.decode(bytes);
  } on FormatException catch (error) {
    return NoteReadFailure('$path: $error', notText: true);
  }
  final text = normalizedLineEndings(decoded);
  return LoadedNote(text: text, buffer: SourceBuffer.fromText(text));
}
