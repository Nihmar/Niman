/// The ways a book's conversion into notes (#1138) ends without notes:
/// stopped from the outside, told not to finish, or failed for a reason
/// other than the book's own (a book refused is `EpubRefused`).
library;

/// A conversion that was stopped before it moved anything in: the library
/// holds nothing of it.
final class EpubConvertCancelled implements Exception {
  /// Stopped.
  const new();
}

/// A conversion that failed for a reason other than the book's own.
final class EpubConvertFailed implements Exception {
  /// Failed with [message], for the log.
  const new(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'EpubConvertFailed: $message';
}

/// A conversion told not to finish: its writes are deleted on the way out.
final class EpubConvertStopped implements Exception {
  /// Stopped.
  const new();
}
