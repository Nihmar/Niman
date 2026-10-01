/// The in-memory cache of laid-out diagrams (#530).
///
/// Keyed by the source and the style's numbers, so a note scrolled past
/// again does not re-parse, and a theme change (which changes the style)
/// does not serve the old one. It is the only one: a drawing is a pure
/// function of its source and style, so nothing of it is persisted — the
/// library's index holds no diagram, and an export draws its own.
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';

/// Parses and lays out a diagram, for a test to substitute.
typedef DiagramResolver = DiagramResult Function(
  String source,
  DiagramStyle style,
);

/// The cache a caller without one of its own uses, so the read view can draw
/// a diagram without every call site threading a cache through.
final DiagramCache sharedDiagramCache = DiagramCache();

/// A bounded LRU of resolved diagrams.
final class DiagramCache extends ChangeNotifier {
  /// Creates a cache of at most [capacity] drawings.
  new({this.capacity = 64, DiagramResolver? resolver})
    : _resolver = resolver ?? resolveDiagram;

  /// How many drawings are kept before the oldest is dropped.
  final int capacity;

  final DiagramResolver _resolver;
  final LinkedHashMap<String, DiagramResult> _results =
      LinkedHashMap<String, DiagramResult>();

  /// The number of resolutions answered from the cache.
  int hits = 0;

  /// The number of resolutions that had to be computed.
  int misses = 0;

  /// The [source]'s drawing at [style], computing and remembering it on a
  /// miss.
  DiagramResult resolve(String source, DiagramStyle style) {
    final key = '${style.cacheKey}\u0000$source';
    final hit = _results.remove(key);
    if (hit != null) {
      hits++;
      _results[key] = hit;
      return hit;
    }
    misses++;
    final result = _resolver(source, style);
    _results[key] = result;
    while (_results.length > capacity) {
      _results.remove(_results.keys.first);
    }
    return result;
  }

  /// Forgets everything, after a style or code change.
  void clear() {
    if (_results.isEmpty) return;
    _results.clear();
    notifyListeners();
  }
}
