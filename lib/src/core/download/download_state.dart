/// Where one downloadable file stands on this device.
sealed class DownloadState {
  const new();
}

/// Not on disk and not downloading.
final class NotDownloaded extends DownloadState {
  /// The absent state.
  const new();
}

/// Downloading: [received] of [total] bytes (the catalog size until the
/// response announces its own). [retrying] is true while waiting to try
/// again after the connection dropped.
final class Downloading extends DownloadState {
  /// A download at [received] of [total] bytes.
  const new({
    required this.received,
    required this.total,
    this.retrying = false,
  });

  /// Bytes on disk so far.
  final int received;

  /// Bytes expected.
  final int total;

  /// Whether the download is waiting to retry.
  final bool retrying;

  /// Progress in 0..1.
  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1);
}

/// On disk, [bytes] long.
final class Downloaded extends DownloadState {
  /// An installed file of [bytes].
  const new(this.bytes);

  /// The file's size.
  final int bytes;
}

/// The download stopped: failed with [reason], or cut off with
/// [received] of [total] bytes kept for resuming.
final class DownloadFailed extends DownloadState {
  /// A stopped download.
  const new(this.reason, {this.received = 0, this.total = 0});

  /// Short, loggable reason.
  final String reason;

  /// Bytes kept in the partial file (0 when there is nothing to resume).
  final int received;

  /// The file's size, when known.
  final int total;

  /// Whether a download of this file resumes rather than starts over.
  bool get resumable => received > 0;

  /// Progress kept, in 0..1.
  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1);
}
