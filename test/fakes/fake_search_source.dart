import 'dart:async';

import 'package:niman/src/search/search_repo.dart';

/// In-memory [SearchSource] for widget tests.
///
/// [hits] is returned for every word query (non-empty); contains mode
/// filters hits whose title, path or snippet contain the pattern
/// (case-insensitive) — the UI behaviors under test: debounce, supersede,
/// rendering, mode toggle and open-on-click.
final class FakeSearchSource implements SearchSource {
  /// Creates a fake source over [hits].
  new({List<SearchHit>? hits}) : hits = hits ?? [];

  /// The hits every word query returns (writable, so tests can reshuffle).
  List<SearchHit> hits;

  /// While set, a word search waits for it to complete: a query that takes
  /// its time.
  Completer<void>? searchGate;

  /// Which queries have been started, in order (for debounce assertions).
  final List<String> queries = [];

  int _invocation = 0;

  @override
  int begin() => ++_invocation;

  @override
  bool isCurrent(int id) => id == _invocation;

  @override
  Future<List<SearchHit>> search(
    String? query, {
    required int? id,
    int limit = 200,
  }) async {
    queries.add(query ?? '');
    await searchGate?.future;
    if (id != null && !isCurrent(id)) return const [];
    if (query == null || query.trim().isEmpty) return const [];
    return hits;
  }

  @override
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  }) async {
    queries.add(pattern);
    if (!isCurrent(id)) return const [];
    if (pattern.isEmpty) return const [];
    final lower = pattern.toLowerCase();
    return [
      for (final hit in hits)
        if (hit.title.toLowerCase().contains(lower) ||
            hit.path.toLowerCase().contains(lower) ||
            hit.snippet.toLowerCase().contains(lower))
          hit,
    ];
  }

  /// The excerpts a word result's row reads, by path; none by default.
  final Map<String, String> excerpts = {};

  /// Holds a path's excerpt until its completer completes (the excerpt of
  /// a big note takes its time); a path without a gate answers at once.
  final Map<String, Completer<void>> excerptGates = {};

  @override
  Future<String> excerpt(SearchHit hit, String userText) async {
    await excerptGates[hit.path]?.future;
    return excerpts[hit.path] ?? '';
  }
}
