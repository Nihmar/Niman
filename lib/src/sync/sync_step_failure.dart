/// A step that cannot complete (nothing listed after an upload, a hash
/// still missing); the path is reported as failed.
final class SyncStepFailure implements Exception {
  /// A failure of the step, saying [message].
  const new(this.message);

  /// What went wrong, for the report.
  final String message;
}
