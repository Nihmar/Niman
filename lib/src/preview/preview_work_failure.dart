/// A [PreviewWork] task that did not produce its result (issue #156).
///
/// It used to come back as a `'__error__|detail'` string, which a caller
/// expecting text could not tell from text: the `read` of a `.jpg` opened
/// as a note whose only line was the exception, and reported it saved. A
/// type of its own cannot be mistaken for a result.
///
/// Sendable by construction: two plain fields, and the worker runs in the
/// caller's isolate group.
library;

import 'package:niman/src/preview/preview_work.dart';

/// Why a [PreviewWork] task failed.
final class PreviewWorkFailure implements Exception {
  /// A failure described by [detail]; [notText] when the task was a read
  /// and the file is not UTF-8 text.
  const new(this.detail, {this.notText = false});

  /// The error as the worker saw it: for the log, never for the user.
  final String detail;

  /// The file was read but is not UTF-8 text — an attachment, not a note.
  final bool notText;

  @override
  String toString() => 'PreviewWorkFailure($detail)';
}
