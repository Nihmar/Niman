/// Base type for all application-level errors.
///
/// Concrete types added by later milestones extend this so the UI can react
/// to specific failure modes (sync, library, sync conflicts, ...).
sealed class AppError implements Exception {
  /// Creates an app error carrying a human-readable [message].
  const AppError(this.message);

  /// Human-readable description of the error.
  final String message;
}

/// Error used for conditions that do not yet have a dedicated type.
final class UnknownAppError extends AppError {
  /// Creates an unknown app error.
  const UnknownAppError(super.message);
}
