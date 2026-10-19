/// Fitting a table's columns to the pane (#337, #1108): the one rule the
/// read view and `live` share, so the two surfaces lay a table out the
/// same way.
library;

/// The width a fitted column keeps at least when its widest word is not
/// known.
const double tableMinCellWidth = 12;

/// The fitted widths of columns that want [natural] and keep their widest
/// word at least, inside [budget], each column keeping [pad] either side.
///
/// A column that fits keeps its natural width. When the table is wider
/// than [budget], every column keeps its widest word where the pane can
/// give it, and the rest of the room is shared by what the columns want.
/// When even the widest words do not fit, the room is shared by those
/// words — not by the whole cells, which let one long paragraph squeeze a
/// short column down to a few characters (#1108) — and no column takes
/// more than the level the others leave it (see [_shareByLevel]), so a
/// column that cannot break (a long address) does not take the pane
/// either. Only the longest words break.
List<double> fitTableColumns({
  required List<double> natural,
  required List<double> least,
  required double pad,
  required double budget,
}) {
  final count = natural.length;
  final fit = List<double>.filled(count, 0);
  if (count == 0) return fit;
  final room = budget - 2 * pad * count;
  final total = natural.fold<double>(0, (sum, width) => sum + width);
  if (total <= 0 || room <= 0) {
    // Nothing to go round: the pane is all padding, so the cells take none.
    return fit;
  }
  // Each column keeps at least its widest word, where the pane can give
  // it: a fitted table breaks a line between words, as the read view
  // does, and only a word wider than its whole column is broken itself.
  // The floor is the column's own — capping it at an even share would
  // break the words of a column the pane gave more room to than the
  // others — and the branch above is what answers for floors that do not
  // fit together at all.
  final floor = <double>[
    for (var at = 0; at < count; at++)
      if (least[at] > 0) least[at] else tableMinCellWidth,
  ];
  final words = floor.fold<double>(0, (sum, width) => sum + width);
  if (words > room) return _shareByLevel(floor, room);
  final pinned = List<bool>.filled(count, false);
  var taken = 0.0;
  var pool = total;
  for (var pass = 0; pass < count; pass++) {
    var pinnedNow = false;
    for (var at = 0; at < count; at++) {
      if (pinned[at] || pool <= 0) continue;
      if ((room - taken) * natural[at] / pool < floor[at]) {
        pinned[at] = true;
        fit[at] = floor[at];
        taken += floor[at];
        pool -= natural[at];
        pinnedNow = true;
      }
    }
    if (!pinnedNow) break;
  }
  for (var at = 0; at < count; at++) {
    if (pinned[at]) continue;
    fit[at] = pool <= 0 ? 0 : (room - taken) * natural[at] / pool;
  }
  return fit;
}

/// Shares [room] among columns whose [floor]s do not fit in it: every column
/// takes its whole floor up to a common level, and the level is the one at
/// which the room is spent.
///
/// A column whose widest word is below the level keeps it whole; the columns
/// above it are cut to the level, so one floor far wider than the rest — a
/// long address, a path, a word with no place to break — cannot take the
/// room the others' words need. Shared in proportion to the floors, such a
/// column would take nearly the whole pane (#1108). With floors that add up
/// to [room] exactly, the level is the widest floor and every column keeps
/// its own: this is the branch above's answer, continued.
List<double> _shareByLevel(List<double> floor, double room) {
  final fit = List<double>.filled(floor.length, 0);
  final order = List<int>.generate(floor.length, (at) => at)
    ..sort((a, b) => floor[a].compareTo(floor[b]));
  var left = room;
  for (var rank = 0; rank < order.length; rank++) {
    final at = order[rank];
    final level = left / (order.length - rank);
    if (floor[at] > level) {
      // This column and every wider one take the level.
      for (var rest = rank; rest < order.length; rest++) {
        fit[order[rest]] = level;
      }
      return fit;
    }
    fit[at] = floor[at];
    left -= floor[at];
  }
  return fit;
}
