/// The ways an HTML page's conversion into a note (#1293) ends without a
/// note: refused for the page's own sake, stopped from the outside, told
/// not to finish, or failed for another reason.
library;

/// Why a file could not be converted.
enum HtmlRefusal {
  /// Not a file: gone, or a folder.
  notAFile,

  /// The file could not be read.
  unreadable,

  /// More bytes than a page the app converts may have.
  tooLarge,

  /// Written in a charset the app does not decode (anything but UTF-8,
  /// UTF-16, ASCII, Latin-1 and Windows-1252).
  unsupportedCharset,
}

/// A page the conversion refuses, and why. A [FormatException], as the
/// book's refusals are.
final class HtmlRefused extends FormatException {
  /// Refuses a page for [reason]; [detail] is for the log.
  const new(this.reason, String detail) : super(detail);

  /// Why.
  final HtmlRefusal reason;

  /// What exactly, for the log.
  String get detail => message;

  @override
  String toString() => 'HtmlRefused(${reason.name}): $message';
}

/// A conversion that was stopped before it moved anything in: the library
/// holds nothing of it.
final class HtmlConvertCancelled implements Exception {
  /// Stopped.
  const new();
}

/// A conversion that failed for a reason other than the page's own.
final class HtmlConvertFailed implements Exception {
  /// Failed with [message], for the log.
  const new(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'HtmlConvertFailed: $message';
}

/// A conversion told not to finish: its writes are deleted on the way out.
final class HtmlConvertStopped implements Exception {
  /// Stopped.
  const new();
}
