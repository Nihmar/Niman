/// Why a card is in the queue.
enum QueueKind {
  /// Reviewed before, its day has come.
  due,

  /// Never reviewed.
  fresh,

  /// Graded Again in this session, asked once more.
  again,
}
