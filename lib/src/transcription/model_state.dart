/// Where one transcription model stands on this device.
sealed class ModelState {
  const new();
}

/// Not on disk and not downloading.
final class ModelAbsent extends ModelState {
  /// The absent state.
  const new();
}

/// Downloading: [received] of [total] bytes (the catalog size until the
/// response announces its own).
final class ModelDownloading extends ModelState {
  /// A download at [received] of [total] bytes.
  const new({required this.received, required this.total});

  /// Bytes written so far.
  final int received;

  /// Bytes expected.
  final int total;

  /// Progress in 0..1.
  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1);
}

/// On disk, [bytes] long.
final class ModelInstalled extends ModelState {
  /// An installed model of [bytes].
  const new(this.bytes);

  /// The model file's size.
  final int bytes;
}

/// The last download failed with [reason]; nothing is on disk.
final class ModelFailed extends ModelState {
  /// A failed download.
  const new(this.reason);

  /// Short, loggable reason.
  final String reason;
}
