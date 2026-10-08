/// The tidy a note gets when it is closed after an edit ([formatMarkdown]),
/// worked out where the note is read: off the UI isolate.
library;

import 'dart:convert';
import 'dart:io';

import 'package:niman/src/editor/markdown_format.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/markdown/note_load.dart';

/// The note at [abs] tidied, or null when there is nothing to write: it is
/// tidy already, it is longer than [limit] bytes, it is not text, or it is
/// gone.
///
/// The note is compared as the editor holds it — its line endings `\n` —
/// so a note whose only untidiness is a Windows line ending is left alone,
/// rather than rewritten for a difference the editor does not show. A
/// note written with Windows line endings that is rewritten is written
/// with them still: tidying is not the place to change them.
///
/// Top-level for an isolate: it carries the path, the limit and the rules.
String? tidiedNoteText(String abs, {required int limit, Set<LintRule>? rules}) {
  final file = File(abs);
  final List<int> bytes;
  try {
    if (file.lengthSync() > limit) return null;
    bytes = file.readAsBytesSync();
  } on FileSystemException {
    return null;
  }
  final String read;
  try {
    read = utf8.decode(bytes);
  } on FormatException {
    return null;
  }
  final text = normalizedLineEndings(read);
  final tidied = formatMarkdown(text, rules: rules);
  if (tidied == text) return null;
  return read.contains('\r\n') ? tidied.replaceAll('\n', '\r\n') : tidied;
}
