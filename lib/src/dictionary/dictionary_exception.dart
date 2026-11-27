/// A dictionary pack the engine cannot read: a truncated file, a header it
/// does not know, an index that cannot be built.
///
/// The look-up's callers never see it: the facade turns it into a result
/// that says the pack is unavailable (docs/records/dictionary.md).
final class DictionaryException implements Exception {
  /// The failure, short and loggable.
  const new(this.reason);

  /// What went wrong.
  final String reason;

  @override
  String toString() => 'DictionaryException: $reason';
}
