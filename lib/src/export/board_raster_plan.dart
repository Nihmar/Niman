/// Which cards go on which page of a rastered kanban board (#1170).
///
/// The printed page lets the engine fragment the board: every column runs
/// down the sheet on its own and a card is kept whole (`break-inside:
/// avoid`). The raster fallback has no engine to do it, and it cannot slice
/// one tall layout as a note's pages are — in a row of columns no cut is
/// clear of every column's cards. So the board is measured first, card by
/// card, and this plan decides what each page holds; each page is then laid
/// out and drawn on its own.
///
/// Pure arithmetic over heights, no widgets: a page never cuts a card, and
/// a card taller than a page, which cannot be kept whole, takes a page to
/// itself and is cut there.
library;

import 'dart:math' as math;

/// One column of a board, as the plan sees it: the heights of what it
/// holds.
final class BoardLaneMeasure {
  /// A lane whose head is [head] tall and whose items — a card, a piece of
  /// prose, each with the space under it — are [items] tall, inside a box
  /// that adds [chrome] to whatever it holds.
  const new({required this.head, required this.items, this.chrome = 0});

  /// The column's head; 0 for a lane with none.
  final double head;

  /// The items, top to bottom.
  final List<double> items;

  /// The box's own padding and border, top and bottom together.
  final double chrome;
}

/// What one lane draws on one page.
final class BoardLaneSlice {
  /// Items [from] to [to] (exclusive) of lane [lane], under its head when
  /// [head].
  const new({
    required this.lane,
    required this.from,
    required this.to,
    required this.head,
  });

  /// The lane's index in its band.
  final int lane;

  /// The first item.
  final int from;

  /// One past the last item.
  final int to;

  /// Whether the head is drawn: on every page a lane has items on, so a
  /// page reads on its own.
  final bool head;

  /// Whether the lane draws anything on this page; a lane that is finished
  /// leaves its place empty.
  bool get visible => head || to > from;
}

/// One band of a page: a row of lanes, or the part of it that fits.
final class BoardBandSlice {
  /// The part of band [band] drawn on a page: [lanes], one per lane of the
  /// band.
  const new({required this.band, required this.lanes});

  /// The band's index.
  final int band;

  /// The lanes' slices.
  final List<BoardLaneSlice> lanes;
}

/// Splits the board into pages of [pageHeight].
///
/// [bands] are the board's rows, top to bottom: every column in one row on
/// a landscape sheet, a few to a row on a portrait one. [bandGap] is the
/// space between two rows on a page. Each page lists the band slices it
/// draws; a band that does not end on a page goes on, lane by lane, on the
/// next.
List<List<BoardBandSlice>> planBoardPages({
  required List<List<BoardLaneMeasure>> bands,
  required double pageHeight,
  required double bandGap,
}) {
  final pages = <List<BoardBandSlice>>[];
  var page = <BoardBandSlice>[];
  var used = 0.0;
  void flush() {
    if (page.isEmpty) return;
    pages.add(page);
    page = <BoardBandSlice>[];
    used = 0;
  }

  for (var index = 0; index < bands.length; index++) {
    final lanes = bands[index];
    if (lanes.isEmpty) continue;
    final cursor = List<int>.filled(lanes.length, 0);
    var first = true;
    while (first || _anyLeft(lanes, cursor)) {
      final gap = page.isEmpty ? 0.0 : bandGap;
      final room = pageHeight - used - gap;
      var taken = _take(lanes, cursor, room, first: first, force: false);
      if (taken == null) {
        // Nothing fits under what the page holds: a new page, or — on an
        // empty one — the cards that are taller than it, cut.
        if (page.isNotEmpty) {
          flush();
          continue;
        }
        taken = _take(lanes, cursor, room, first: first, force: true)!;
      }
      page.add(BoardBandSlice(band: index, lanes: taken.slices));
      used += gap + taken.height;
      for (var lane = 0; lane < lanes.length; lane++) {
        cursor[lane] = taken.slices[lane].to;
      }
      first = false;
      // A band that goes on starts a page of its own: it fills this one.
      if (_anyLeft(lanes, cursor)) flush();
    }
  }
  flush();
  // A board with nothing in it is still a page.
  return pages.isEmpty ? <List<BoardBandSlice>>[<BoardBandSlice>[]] : pages;
}

bool _anyLeft(List<BoardLaneMeasure> lanes, List<int> cursor) {
  for (var lane = 0; lane < lanes.length; lane++) {
    if (cursor[lane] < lanes[lane].items.length) return true;
  }
  return false;
}

/// What a band puts on a page with [room] left, or null when nothing of it
/// fits — unless [force]d, when every lane that has items takes one at
/// least, and a card taller than the page is cut.
///
/// A lane that has no item at all is an empty column, drawn once, on
/// [first]; a lane with items it cannot fit yet waits for the next page.
({List<BoardLaneSlice> slices, double height})? _take(
  List<BoardLaneMeasure> lanes,
  List<int> cursor,
  double room, {
  required bool first,
  required bool force,
}) {
  final slices = <BoardLaneSlice>[];
  var height = 0.0;
  var progress = false;
  for (var index = 0; index < lanes.length; index++) {
    final lane = lanes[index];
    final from = cursor[index];
    var to = from;
    var h = lane.chrome + lane.head;
    while (to < lane.items.length &&
        (h + lane.items[to] <= room || (force && to == from))) {
      h += lane.items[to];
      to++;
    }
    final drawn =
        to > from ||
        (first &&
            lane.items.isEmpty &&
            (force || lane.chrome + lane.head <= room));
    if (drawn) {
      progress = true;
      height = math.max(height, h);
    }
    slices.add(BoardLaneSlice(lane: index, from: from, to: to, head: drawn));
  }
  return progress ? (slices: slices, height: height) : null;
}
