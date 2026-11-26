/// The pairs of segments Brandes and Köpf's alignment must not join (#530).
///
/// A long edge drawn as one straight line, and a cluster's side drawn as
/// one, are what the alignment is for. Where such a straight run — a chain
/// of stand-ins, or a chain of a cluster's border nodes — would cross a
/// segment that is not part of one, the crossing segment loses: it is marked
/// as a conflict, and the alignment leaves it bent.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_segments.dart';

/// The segments marked as conflicts, by their two ends.
final class LayeredConflicts {
  /// Creates an empty set for a graph of [_count] nodes.
  new(this._count);

  final int _count;
  final Set<int> _marked = {};

  /// Marks the segment between the nodes [a] and [b].
  void add(int a, int b) => _marked.add(_key(a, b));

  /// Whether the segment between [a] and [b] is marked.
  bool has(int a, int b) => _marked.contains(_key(a, b));

  int _key(int a, int b) => a < b ? a * _count + b : b * _count + a;
}

/// Marks the conflicts of the ranks [layers], each rank left to right.
///
/// A type 1 conflict is a segment that is not between two stand-ins or
/// border nodes crossing one that is. A type 2 conflict is a segment between
/// two stand-ins crossing a cluster's side. [isStand] is set for a node that
/// is not a box, and [isBorder] for a border node; [order] is the place of
/// every node in its rank.
LayeredConflicts findConflicts(
  List<Int32List> layers,
  LayeredSegments segments,
  Uint8List isStand,
  Uint8List isBorder,
  Int32List order,
) {
  final conflicts = LayeredConflicts(order.length);
  var anyBorder = false;
  for (final flag in isBorder) {
    if (flag == 1) {
      anyBorder = true;
      break;
    }
  }
  for (var r = 1; r < layers.length; r++) {
    _typeOne(layers[r - 1], layers[r], segments, isStand, order, conflicts);
    if (anyBorder) {
      _typeTwo(
        layers[r - 1],
        layers[r],
        segments,
        isStand,
        isBorder,
        order,
        conflicts,
      );
    }
  }
  return conflicts;
}

void _typeOne(
  Int32List north,
  Int32List south,
  LayeredSegments segments,
  Uint8List isStand,
  Int32List order,
  LayeredConflicts conflicts,
) {
  // The last node of the rank above that an inner segment so far ends at,
  // and the first node of this rank not looked at yet.
  var lowerBound = 0;
  var scanned = 0;
  for (var i = 0; i < south.length; i++) {
    final node = south[i];
    final inner = _innerNeighbour(node, segments, isStand);
    final upperBound = inner >= 0 ? order[inner] : north.length;
    if (inner >= 0 || i == south.length - 1) {
      for (var k = scanned; k <= i; k++) {
        final scan = south[k];
        for (
          var s = segments.upStart[scan];
          s < segments.upStart[scan + 1];
          s++
        ) {
          final above = segments.upNodes[s];
          final at = order[above];
          if ((at < lowerBound || upperBound < at) &&
              !(isStand[above] == 1 && isStand[scan] == 1)) {
            conflicts.add(above, scan);
          }
        }
      }
      scanned = i + 1;
      lowerBound = upperBound;
    }
  }
}

/// The node above [node] that [node] is joined to by an inner segment, or -1.
int _innerNeighbour(int node, LayeredSegments segments, Uint8List isStand) {
  if (isStand[node] == 0) return -1;
  for (var s = segments.upStart[node]; s < segments.upStart[node + 1]; s++) {
    if (isStand[segments.upNodes[s]] == 1) return segments.upNodes[s];
  }
  return -1;
}

void _typeTwo(
  Int32List north,
  Int32List south,
  LayeredSegments segments,
  Uint8List isStand,
  Uint8List isBorder,
  Int32List order,
  LayeredConflicts conflicts,
) {
  void scan(int from, int to, int lowerBorder, int upperBorder) {
    for (var i = from; i < to; i++) {
      final node = south[i];
      if (isStand[node] == 0) continue;
      for (
        var s = segments.upStart[node];
        s < segments.upStart[node + 1];
        s++
      ) {
        final above = segments.upNodes[s];
        if (isStand[above] == 1 &&
            (order[above] < lowerBorder || order[above] > upperBorder)) {
          conflicts.add(above, node);
        }
      }
    }
  }

  var previous = -1;
  var next = -1;
  var from = 0;
  for (var i = 0; i < south.length; i++) {
    final node = south[i];
    if (isBorder[node] == 1 &&
        segments.upStart[node] < segments.upStart[node + 1]) {
      next = order[segments.upNodes[segments.upStart[node]]];
      scan(from, i, previous, next);
      from = i;
      previous = next;
    }
  }
  scan(from, south.length, next, north.length);
}
