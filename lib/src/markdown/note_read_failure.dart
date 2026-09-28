/// A note that could not be read as one (issue #156).
///
/// It used to come back as a `'__error__|detail'` string, which a caller
/// expecting text could not tell from text: the read of a `.jpg` opened as
/// a note whose only line was the exception, and reported it saved. A type
/// of its own cannot be mistaken for a result.
///
/// Sendable by construction: two plain fields, returned from the isolate
/// that read the file.
library;

/// Why a note's file could not be read as a note.
final class NoteReadFailure implements Exception {
  /// A failure described by [detail]; [notText] when the file was read and
  /// is not text at all.
  const new(this.detail, {this.notText = false});

  /// The error as the reader saw it: for the log, never for the user.
  final String detail;

  /// The file was read but is not text — a binary file (a NUL byte, or
  /// mostly undecodable bytes), an attachment rather than a note. A note
  /// whose bytes are not UTF-8 is text on every path since #353.
  final bool notText;

  @override
  String toString() => 'NoteReadFailure($detail)';
}
