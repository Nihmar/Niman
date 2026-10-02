/// The in-memory cache of laid-out diagrams (#530).
///
/// Keyed by the source and the style's numbers, so a note scrolled past
/// again does not re-parse, and a theme change (which changes the style)
/// does not serve the old one. There is one, the read view's and `live`'s
/// alike: a drawing is a pure function of its source and style, so any
/// surface may have any other's, and nothing of it is persisted — the
/// library's index holds no diagram, and an export draws its own.
library;

import 'dart:collection';

import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';

/// The cache every surface draws its diagrams from.
final DiagramCache diagramCache = DiagramCache();

/// A bounded LRU of resolved diagrams.
final class DiagramCache {
  /// Creates a cache of at most [capacity] drawings.
  new({this.capacity = 64});

  /// How many drawings are kept before the oldest is dropped.
  final int capacity;

  final LinkedHashMap<String, DiagramResult> _results =
      LinkedHashMap<String, DiagramResult>();

  /// The [source]'s drawing at [style], computing and remembering it on a
  /// miss.
  DiagramResult resolve(String source, DiagramStyle style) {
    final key = '${style.cacheKey}\u0000$source';
    final hit = _results.remove(key);
    if (hit != null) {
      _results[key] = hit;
      return hit;
    }
    final result = resolveDiagram(source, style);
    _results[key] = result;
    while (_results.length > capacity) {
      _results.remove(_results.keys.first);
    }
    return result;
  }
}
