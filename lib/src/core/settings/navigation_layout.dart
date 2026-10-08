/// The order of the navigation and which of its destinations are hidden
/// (#536): the phone's bottom bar and the desktop's rail, per library.
///
/// Kept by name, never by position: a destination's place is the user's,
/// its identity is the app's, and a build that adds one (Home #535, Study
/// #533) must not shift the ones a layout already placed.
library;

import 'package:meta/meta.dart';

/// One destination as a layout places it.
typedef PlacedDestination = ({String name, bool hidden});

/// The navigation's order and its hidden destinations.
@immutable
final class NavigationLayout {
  /// A layout with [order] and [hidden]; the empty one is the defaults.
  const new({this.order = const [], this.hidden = const {}});

  /// Reads the `settings.json` value; anything else than the object
  /// [toJson] writes reads as the defaults, the settings file's rule.
  factory fromJson(Object? json) {
    if (json is! Map) return const NavigationLayout();
    final order = json['order'];
    final hidden = json['hidden'];
    return NavigationLayout(
      order: [
        if (order is List)
          for (final name in order)
            if (name is String) name,
      ],
      hidden: {
        if (hidden is List)
          for (final name in hidden)
            if (name is String) name,
      },
    );
  }

  /// The destinations' names in the order the user left them. A name a
  /// build does not know is kept, so a newer build's survives an older
  /// one; a destination missing from it is one the layout never saw.
  final List<String> order;

  /// The names of the destinations turned off.
  final Set<String> hidden;

  /// [defaults], in their default order, placed by this layout.
  ///
  /// Names in [order] come first, in that order; a default it does not
  /// name (one added since the layout was saved) goes in after its
  /// default predecessor, with its visibility from [defaultHidden]. A
  /// name in [locked] is never hidden. Names [defaults] does not hold are
  /// left out.
  List<PlacedDestination> place(
    List<String> defaults, {
    Set<String> defaultHidden = const {},
    Set<String> locked = const {},
  }) {
    final known = defaults.toSet();
    final names = <String>[
      for (final name in order.toSet())
        if (known.contains(name)) name,
    ];
    for (var i = 0; i < defaults.length; i++) {
      final name = defaults[i];
      if (names.contains(name)) continue;
      final before = i == 0 ? -1 : names.indexOf(defaults[i - 1]);
      names.insert(before + 1, name);
    }
    final named = order.toSet();
    return [
      for (final name in names)
        (
          name: name,
          hidden:
              !locked.contains(name) &&
              (named.contains(name)
                  ? hidden.contains(name)
                  : defaultHidden.contains(name)),
        ),
    ];
  }

  /// The layout that keeps [placed] as it stands, with the names this
  /// build does not know left where [order] had them, at the end.
  NavigationLayout keep(List<PlacedDestination> placed) {
    final known = {for (final d in placed) d.name};
    return NavigationLayout(
      order: [
        for (final d in placed) d.name,
        for (final name in order)
          if (!known.contains(name)) name,
      ],
      hidden: {
        for (final d in placed)
          if (d.hidden) d.name,
        for (final name in hidden)
          if (!known.contains(name)) name,
      },
    );
  }

  /// The value `settings.json` holds.
  Map<String, Object?> toJson() => {
    'order': order,
    'hidden': [
      for (final name in order)
        if (hidden.contains(name)) name,
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is NavigationLayout &&
      _sameList(order, other.order) &&
      hidden.length == other.hidden.length &&
      hidden.containsAll(other.hidden);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(order), Object.hashAllUnordered(hidden));
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
