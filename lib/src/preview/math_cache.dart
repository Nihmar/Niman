import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:katex_dart/katex_dart.dart'
    show BoxNode, KatexOptions, renderToBox;

/// The math render cache (design.md): built output keyed by the exact math
/// string, bounded LRU. The default render is synchronous: one span takes
/// ~0.1 ms, and only the viewport's spans are requested, so there is
/// nothing to offload — and the isolate route proved un-sendable for the
/// closure on AOT devices (the message car the calling zone and every span
/// rendered its red error fallback). [asyncRenderer] remains as the timing
/// seam for the placeholder tests.
///
/// One shared instance per preview (owned by `MarkdownPreview`); editing a
/// note reuses the cached boxes for unchanged spans (the T-M2-05 AC).
/// Errors are remembered but never cached: an errored tex keeps rendering
/// its red fallback instead of poisoning the cache.
final class MathCache extends ChangeNotifier {
  /// Creates a cache with [capacity] entries.
  ///
  /// [renderer] (synchronous seam) and [asyncRenderer] (future seam) replace
  /// the render path for tests; the default renders synchronously with
  /// `katex_dart`.
  new({this.capacity = defaultCapacity, this.renderer, this.asyncRenderer});

  /// The sync render seam; null = [asyncRenderer] or the default render.
  final BoxNode Function(String tex, {required bool displayMode})? renderer;

  /// The async render seam (placeholder tests); null = [renderer] or the
  /// default synchronous render.
  final Future<BoxNode> Function(String tex, {required bool displayMode})?
  asyncRenderer;

  /// Default capacity (design.md's ~512 entries).
  static const int defaultCapacity = 512;

  /// Maximum entries kept (oldest-rendered evicted first).
  final int capacity;
  final LinkedHashMap<String, BoxNode> _boxes =
      LinkedHashMap<String, BoxNode>();
  final Set<String> _errors = <String>{};
  final Map<String, Future<BoxNode?>> _inflight = <String, Future<BoxNode?>>{};
  bool _disposed = false;

  /// Cache-hit counter (the edit-reuse AC measurement).
  int hits = 0;

  /// Cache-miss counter.
  int misses = 0;

  /// Version bumped whenever a render completes (listeners rebuild).
  int generation = 0;

  /// The cache key for [tex]/[displayMode].
  static String keyFor(String tex, {required bool displayMode}) =>
      '${displayMode ? 1 : 0}\u0000$tex';

  /// Whether [tex]/[displayMode] failed to render (false once fixed).
  bool isError(String tex, {required bool displayMode}) =>
      _errors.contains(keyFor(tex, displayMode: displayMode));

  /// Whether a render for [tex]/[displayMode] is in flight.
  bool isPending(String tex, {required bool displayMode}) =>
      _inflight.containsKey(keyFor(tex, displayMode: displayMode));

  /// The cached box, or null (not rendered / not in cache).
  BoxNode? boxFor(String tex, {required bool displayMode}) {
    final key = keyFor(tex, displayMode: displayMode);
    final box = _boxes.remove(key);
    if (box == null) {
      return null;
    }
    // LRU touch.
    _boxes[key] = box;
    return box;
  }

  /// Renders [tex] (or reuses the inflight render), returns the box or null
  /// on error. Unchanged spans never re-render (the AC).
  Future<BoxNode?> ensure(String tex, {required bool displayMode}) {
    final key = keyFor(tex, displayMode: displayMode);
    final cached = boxFor(tex, displayMode: displayMode);
    if (cached != null) {
      hits++;
      return Future<BoxNode?>.value(cached);
    }
    if (_errors.contains(key)) {
      return Future<BoxNode?>.value();
    }
    final pending = _inflight[key];
    if (pending != null) return pending;
    misses++;
    final future = _compute(tex, displayMode);
    _inflight[key] = future;
    return future;
  }

  Future<BoxNode?> _compute(String tex, bool displayMode) {
    final key = keyFor(tex, displayMode: displayMode);
    Future<BoxNode?> compute(Future<BoxNode> Function() render) async {
      BoxNode? box;
      try {
        box = await render();
      } on Object catch (_) {
        box = null;
      }
      if (_disposed) return null;
      if (box == null) {
        _errors.add(key);
      } else {
        _boxes
          ..remove(key)
          ..[key] = box;
        while (_boxes.length > capacity) {
          _boxes.remove(_boxes.keys.first);
        }
        _errors.remove(key);
      }
      _inflight.remove(key)?.ignore();
      generation++;
      notifyListeners();
      return box;
    }

    if (renderer != null) {
      return compute(() async => renderer!(tex, displayMode: displayMode));
    }
    final asyncRenderer = this.asyncRenderer;
    if (asyncRenderer != null) {
      return compute(() => asyncRenderer(tex, displayMode: displayMode));
    }
    // Default: synchronous render (per-span cost ~0.1 ms; only the
    // viewport's spans are ever requested).
    return compute(
      () async =>
          renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
