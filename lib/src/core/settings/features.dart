/// The switches of a library's features (#1109), as `settings.json` keeps
/// them.
///
/// Kept by id, never by position, and by exception: only a switch turned
/// off is written, so a library that never opens the screen keeps a
/// `settings.json` byte for byte as it was, and a feature a later build
/// adds is born on.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/library_features.dart';

/// Which features a library has on.
@immutable
final class Features {
  /// Features with `switches` by id; an id missing from it is on, so the
  /// empty value is every feature on.
  const new([this._switches = const {}]);

  /// Reads the `settings.json` value; anything else than the object
  /// [toJson] writes reads as every feature on, the settings file's rule.
  ///
  /// A switch that is not a boolean is dropped, and an id this build does
  /// not know is kept, so a newer build's survives an older one.
  factory fromJson(Object? json) {
    if (json is! Map) return const Features();
    return Features({
      for (final entry in json.entries)
        if (entry.value case final bool on) entry.key.toString(): on,
    });
  }

  final Map<String, bool> _switches;

  /// [feature]'s own switch, whatever its parent says.
  bool own(LibraryFeature feature) => _switches[feature.id] ?? true;

  /// Whether [feature] is on for the library: its own switch and its
  /// parent's. This is the value every surface asks.
  bool isOn(LibraryFeature feature) =>
      own(feature) && (feature.parent == null || isOn(feature.parent!));

  /// These features with [feature]'s own switch set to [on]; the others,
  /// and the ids this build does not know, stay as they are.
  Features withSwitch(LibraryFeature feature, {required bool on}) =>
      Features({..._switches, feature.id: on});

  /// These features with every switch set as [preset] has it. The ids this
  /// build does not know stay as they are.
  Features withPreset(FeaturePreset preset) => Features({
    ..._switches,
    for (final feature in LibraryFeature.values)
      feature.id: preset.leavesOn(feature),
  });

  /// The value `settings.json` holds: the switches that are off, then the
  /// ids this build does not know as they were. Empty for a library with
  /// every feature on, which writes no `features` key at all.
  Map<String, bool> toJson() {
    final known = <String, bool>{
      for (final feature in LibraryFeature.values)
        if (!own(feature)) feature.id: false,
    };
    final unknown = <String, bool>{
      for (final id in _unknownIds) id: _switches[id]!,
    };
    return {...known, ...unknown};
  }

  /// The ids kept that this build does not know, in a stable order.
  List<String> get _unknownIds => [
    for (final id in _switches.keys)
      if (LibraryFeature.fromId(id) == null) id,
  ]..sort();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Features) return false;
    final mine = toJson();
    final theirs = other.toJson();
    if (mine.length != theirs.length) return false;
    for (final entry in mine.entries) {
      if (theirs[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final json = toJson();
    final ids = json.keys.toList()..sort();
    return Object.hashAll([
      for (final id in ids) ...[id, json[id]],
    ]);
  }
}
