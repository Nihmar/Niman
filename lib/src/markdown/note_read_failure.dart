/// A note that could not be read as one (issue #156).
///
/// It used to come back as a `'__error__|detail'` string, which a caller
/// expecting text could not tell from text: the read of a `.jpg` opened as
/// a note whose only line was the exception, and reported it saved. A type
/// of its own cannot be mistaken for a result.
///
/// Sendable by construction: plain fields, returned from the isolate that
/// read the file.
library;

import 'dart:io';

/// Why a note could not be opened (#1059): what the error pane says, so a
/// person can tell a file that is gone from one that is only busy.
enum NoteReadReason {
  /// The file was read and is not text at all.
  notText,

  /// The file is not there (moved, deleted, a drive that went away).
  missing,

  /// The system refused the read (a permission, a revoked storage grant).
  denied,

  /// Another program holds the file for the moment (a sharing violation, a
  /// sync client mid-write): trying again shortly usually works.
  locked,

  /// Anything else.
  other;

  /// The reason [error] stands for: a [NoteReadFailure]'s own, or the one a
  /// [FileSystemException] amounts to by its type and its OS error code.
  static NoteReadReason of(Object error) {
    if (error is NoteReadFailure) return error.reason;
    if (error is PathNotFoundException) return missing;
    if (error is PathAccessException) return denied;
    if (error is FileSystemException) {
      final code = error.osError?.errorCode;
      if (code == null) return other;
      // The codes mean different things per system: 5 is access denied on
      // Windows and an I/O error elsewhere.
      if (Platform.isWindows) {
        return switch (code) {
          // ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND.
          2 || 3 => missing,
          // ERROR_ACCESS_DENIED.
          5 => denied,
          // ERROR_SHARING_VIOLATION, ERROR_LOCK_VIOLATION.
          32 || 33 => locked,
          _ => other,
        };
      }
      return switch (code) {
        // ENOENT.
        2 => missing,
        // EPERM, EACCES.
        1 || 13 => denied,
        // EBUSY, ETXTBSY.
        16 || 26 => locked,
        _ => other,
      };
    }
    return other;
  }
}

/// Why a note's file could not be read as a note.
final class NoteReadFailure implements Exception {
  /// A failure described by [detail]; [notText] when the file was read and
  /// is not text at all, else by [reason].
  const new(this.detail, {bool notText = false, NoteReadReason? reason})
    : reason =
          reason ?? (notText ? NoteReadReason.notText : NoteReadReason.other);

  /// The error as the reader saw it: for the log, never for the user.
  final String detail;

  /// What kind of failure it was, for the words the pane puts to the user.
  final NoteReadReason reason;

  /// The file was read but is not text — a binary file (a NUL byte, or
  /// mostly undecodable bytes), an attachment rather than a note. A note
  /// whose bytes are not UTF-8 is text on every path since #353.
  bool get notText => reason == NoteReadReason.notText;

  @override
  String toString() => 'NoteReadFailure($detail)';
}
