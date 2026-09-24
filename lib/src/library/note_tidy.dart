/// The tidy a note gets when it is closed after an edit ([formatMarkdown]),
/// worked out where the note is read: off the UI isolate.
library;

import 'dart:convert';
import 'dart:io';

import 'package:niman/src/editor/markdown_format.dart';
import 'package:niman/src/markdown/note_load.dart';

/// The note at [abs] tidied, or null when there is nothing to write: it is
/// tidy already, it is longer than [limit] bytes, it is not text, or it is
/// gone.
///
/// The note is compared as the editor holds it — its line endings `\n` —
/// so a note whose only untidiness is a Windows line ending is left alone,
/// rather than rewritten for a difference the editor does not show.
///
/// Top-level for an isolate: it carries the path and the limit.
String? tidiedNoteText(String abs, {required int limit}) {
  final file = File(abs);
  final List<int> bytes;
  try {
    if (file.lengthSync() > limit) return null;
    bytes = file.readAsBytesSync();
  } on FileSystemException {
    return null;
  }
  final String text;
  try {
    text = normalizedLineEndings(utf8.decode(bytes));
  } on FormatException {
    return null;
  }
  final tidied = formatMarkdown(text);
  return tidied == text ? null : tidied;
}
