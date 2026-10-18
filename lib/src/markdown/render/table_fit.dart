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
/// short column down to a few characters (#1108) — and only the longest
/// words break.
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
  // others — and the branch below is what answers for floors that do not
  // fit together at all.
  final floor = <double>[
    for (var at = 0; at < count; at++)
      if (least[at] > 0) least[at] else tableMinCellWidth,
  ];
  final words = floor.fold<double>(0, (sum, width) => sum + width);
  if (words > room) {
    for (var at = 0; at < count; at++) {
      fit[at] = room * floor[at] / words;
    }
    return fit;
  }
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
