import 'package:meta/meta.dart';

/// What a downloaded pack still goes through before it can be used.
enum DictionaryPreparationStep {
  /// The archive is being unpacked into the pack's folder.
  unpacking,

  /// The pack's sidecar index is being built.
  indexing,
}

/// Where a pack that has been downloaded is on its way to being usable:
/// unpacked, then indexed (docs/records/dictionary.md, decision 16).
@immutable
final class DictionaryPreparation {
  /// A pack at [step]; [fraction] says how far the index is built, 0 to 1,
  /// and is null while that is not known (unpacking has no count).
  const new(this.step, [this.fraction]);

  /// A pack being unpacked.
  const new unpacking() : this(DictionaryPreparationStep.unpacking);

  /// A pack whose index is [fraction] built.
  const new indexing(double fraction)
    : this(DictionaryPreparationStep.indexing, fraction);

  /// The step the pack is at.
  final DictionaryPreparationStep step;

  /// How far the step has got, or null when it cannot say.
  final double? fraction;

  @override
  bool operator ==(Object other) =>
      other is DictionaryPreparation &&
      other.step == step &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(step, fraction);
}
