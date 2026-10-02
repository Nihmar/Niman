/// Where each service of an architecture diagram sits (#530): a cell of a
/// grid, told by the sides its edges leave by.
///
/// `db:L -- R:server` puts server one cell left of db, and `disk:T -- B:db`
/// puts db one cell above disk: from a placed service, each edge places
/// the one at its other end a cell away on the side it leaves by, and a
/// cell already taken sends it on in the same direction to the next free
/// one. A service no edge reaches yet starts a part of its own, a column
/// clear of the parts before it.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/architecture_model.dart';

/// The cell (column, row) of every service and junction of [diagram], the
/// smallest column and row 0.
Map<String, (int, int)> placeArchitecture(ArchitectureDiagram diagram) {
  final next = <String, List<(String, (int, int))>>{
    for (final service in diagram.services) service.id: [],
  };
  for (final edge in diagram.edges) {
    next[edge.from]!.add((edge.to, edge.fromSide.step));
    next[edge.to]!.add((edge.from, edge.toSide.step));
  }
  final cells = <String, (int, int)>{};
  final taken = <(int, int)>{};
  void place(String id, (int, int) cell) {
    cells[id] = cell;
    taken.add(cell);
  }

  var column = 0;
  for (final service in diagram.services) {
    if (cells.containsKey(service.id)) continue;
    place(service.id, (column, 0));
    final queue = [service.id];
    for (var head = 0; head < queue.length; head++) {
      final at = queue[head];
      final (x, y) = cells[at]!;
      for (final (other, (dx, dy)) in next[at]!) {
        if (cells.containsKey(other)) continue;
        var cell = (x + dx, y + dy);
        while (taken.contains(cell)) {
          cell = (cell.$1 + dx, cell.$2 + dy);
        }
        place(other, cell);
        queue.add(other);
      }
    }
    column = cells.values.fold(column, (most, c) => math.max(most, c.$1)) + 2;
  }
  final left = cells.values.fold(0, (least, c) => math.min(least, c.$1));
  final top = cells.values.fold(0, (least, c) => math.min(least, c.$2));
  return {
    for (final MapEntry(:key, value: (x, y)) in cells.entries)
      key: (x - left, y - top),
  };
}
