/// How `DictionaryService.prepare` ended.
enum DictionaryPrepareStatus {
  /// The pack's index is built and the pack is open: a look-up is quick.
  ready,

  /// No pack, usable or not, serves the language.
  noPack,

  /// A pack serves the language and could not be made ready: its index
  /// would not build, or it cannot be opened, or this app cannot read it.
  /// [DictionaryPrepareResult.reason] says why.
  failed,
}

/// What preparing the pack of a language came to: it is never thrown, so a
/// pack that cannot be indexed is told apart from a language with no pack.
final class DictionaryPrepareResult {
  /// A result of [status] for the pack [packId], failed for [reason].
  const new(this.status, {this.packId, this.reason});

  /// How it ended.
  final DictionaryPrepareStatus status;

  /// The pack that was asked (`niman-it`), null when there is none.
  final String? packId;

  /// Why the pack could not be made ready, for
  /// [DictionaryPrepareStatus.failed].
  final String? reason;

  /// Whether the pack is ready.
  bool get isReady => status == DictionaryPrepareStatus.ready;

  /// Whether a pack serves the language and could not be made ready.
  bool get isFailed => status == DictionaryPrepareStatus.failed;
}
