/// What a sweep has decided about the clusters' order (#530).
library;

/// "This cluster stays left of that one": the sibling clusters' order as
/// the ranks already sorted in a sweep have it, so the ranks after it do not
/// swap them.
///
/// Clusters are named by their vertex number, as in the layers. A rank has
/// only some clusters, so a constraint is followed through the clusters a rank
/// lacks: if A stays left of B and B of C, then A stays left of C in a rank
/// that has no B.
final class LayeredConstraints {
  final Map<int, Set<int>> _after = {};

  /// Whether nothing is constrained.
  bool get isEmpty => _after.isEmpty;

  /// Forgets every constraint.
  void clear() => _after.clear();

  /// Records that [left] stays left of [right]. An order that would
  /// contradict one already recorded directly is not recorded.
  void add(int left, int right) {
    if (_after[right]?.contains(left) ?? false) return;
    (_after[left] ??= {}).add(right);
  }

  /// The clusters for which [isPresent] holds that [cluster] stays left of,
  /// the first of each way to get to one: a cluster that is not present is
  /// looked through. In the order they were recorded.
  List<int> successors(int cluster, bool Function(int) isPresent) {
    final found = <int>[];
    final seen = <int>{cluster};
    final stack = <int>[cluster];
    while (stack.isNotEmpty) {
      final next = _after[stack.removeLast()];
      if (next == null) continue;
      // Pushed in reverse, so the first recorded is the first looked at.
      final later = <int>[];
      for (final right in next) {
        if (!seen.add(right)) continue;
        if (isPresent(right)) {
          found.add(right);
        } else {
          later.add(right);
        }
      }
      stack.addAll(later.reversed);
    }
    return found;
  }
}
