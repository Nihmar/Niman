/// A note read and made ready off the UI isolate, for the unified surface.
///
/// Opening the 246 MB stress note froze the window for seconds after its
/// text arrived (profile, 2026-09-23): the line endings were normalized, the
/// text was split into its 2.76 M lines and the buffer was handed to an
/// isolate for its word count — which *copies* it, on the isolate that sends
/// it — all on the UI isolate. Here one isolate does all of it and answers
/// through `Isolate.exit`, which hands the result over without copying it:
/// the UI isolate receives a note it only has to draw.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/preview_work_failure.dart';

/// A note as the unified surface takes it: its text with the line endings
/// the editor holds, the buffer over that text, and its word count.
final class LoadedNote {
  /// Creates a loaded note.
  const new({required this.text, required this.buffer, required this.words});

  /// The note's text, its line endings `\n`.
  final String text;

  /// The buffer over [text].
  final SourceBuffer buffer;

  /// [buffer]'s word count, counted.
  final WordCount words;
}

/// [text] with its line endings made `\n`, as the editor holds a note —
/// and no pass over it when there is no `\r` to replace.
String normalizedLineEndings(String text) => text.contains('\r')
    ? text.replaceAll('\r\n', '\n').replaceAll('\r', '\n')
    : text;

/// Reads the note at [path] and makes it ready, in an isolate: a
/// [LoadedNote], or a [PreviewWorkFailure] saying the file is not text.
///
/// The closure crosses to the isolate with nothing but [path] in it, which
/// is why this is a top-level function: one made inside a widget's state
/// carries the state with it, and the isolate refuses it.
Future<Object> loadNote(String path) => Isolate.run(() => _loadNote(path));

Object _loadNote(String path) {
  final bytes = File(path).readAsBytesSync();
  final String decoded;
  try {
    decoded = utf8.decode(bytes);
  } on FormatException catch (error) {
    return PreviewWorkFailure('$path: $error', notText: true);
  }
  final text = normalizedLineEndings(decoded);
  final buffer = SourceBuffer.fromText(text);
  return LoadedNote(text: text, buffer: buffer, words: WordCount.of(buffer));
}
