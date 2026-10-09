/// How one step of a sync run ended.
enum SyncStepOutcome {
  /// The step was carried out.
  done,

  /// A side changed during the run: the path is decided again next time.
  skipped,

  /// The path was left for the merge; the report carries it.
  conflict,
}
