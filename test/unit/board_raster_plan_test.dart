// Which cards go on which page of a rastered kanban board (#1170): a page
// never cuts a card, and a lane that has more goes on, head and all, on the
// next page.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/board_raster_plan.dart';

BoardLaneMeasure _lane(List<double> items, {double head = 10}) =>
    BoardLaneMeasure(head: head, items: items, chrome: 4);

/// What [pages] draws, as `band:lane:from-to` for every visible lane.
List<List<String>> _shape(List<List<BoardBandSlice>> pages) => [
  for (final page in pages)
    [
      for (final band in page)
        for (final lane in band.lanes)
          if (lane.visible) '${band.band}:${lane.lane}:${lane.from}-${lane.to}',
    ],
];

void main() {
  test('a board that fits is one page', () {
    final pages = planBoardPages(
      bands: [
        [
          _lane([20, 20]),
          _lane([30]),
        ],
      ],
      pageHeight: 200,
      bandGap: 5,
    );
    expect(_shape(pages), [
      ['0:0:0-2', '0:1:0-1'],
    ]);
  });

  test('each column pages on its own, a card kept whole', () {
    // Page room is 100: the first column holds 3 of its 4 cards (4 + 10 +
    // 3 × 25 = 89), the second all of its 2.
    final pages = planBoardPages(
      bands: [
        [
          _lane([25, 25, 25, 25]),
          _lane([40, 40]),
        ],
      ],
      pageHeight: 100,
      bandGap: 5,
    );
    expect(_shape(pages), [
      ['0:0:0-3', '0:1:0-2'],
      ['0:0:3-4'],
    ]);
    // The head comes back on the page a column goes on.
    expect(pages[1].single.lanes[0].head, isTrue);
  });

  test('no page holds more than its height, a card at a time', () {
    final heights = <double>[for (var i = 0; i < 40; i++) 17.0 + (i * 7) % 23];
    final pages = planBoardPages(
      bands: [
        [_lane(heights)],
        [_lane(heights), _lane(heights.reversed.toList())],
      ],
      pageHeight: 150,
      bandGap: 6,
    );
    final lanes = [
      [heights],
      [heights, heights.reversed.toList()],
    ];
    final seen = <String, int>{};
    for (final page in pages) {
      var used = 0.0;
      for (final band in page) {
        var tallest = 0.0;
        for (final lane in band.lanes) {
          if (!lane.visible) continue;
          var h = 4.0 + 10.0;
          for (var i = lane.from; i < lane.to; i++) {
            h += lanes[band.band][lane.lane][i];
          }
          if (h > tallest) tallest = h;
          final key = '${band.band}:${lane.lane}';
          // Every card is on exactly one page: the slices are contiguous.
          expect(lane.from, seen[key] ?? 0);
          seen[key] = lane.to;
        }
        used += tallest + (used == 0 ? 0 : 6);
      }
      expect(used, lessThanOrEqualTo(150));
    }
    expect(seen, {'0:0': 40, '1:0': 40, '1:1': 40});
  });

  test('a row goes on the same page as the one before while it fits', () {
    final pages = planBoardPages(
      bands: [
        [
          _lane([30]),
          _lane([30]),
        ],
        [
          _lane([30]),
        ],
        [
          _lane([90]),
        ],
      ],
      pageHeight: 120,
      bandGap: 6,
    );
    // 44 + 6 + 44 fits; the third row (104) does not follow it.
    expect(_shape(pages), [
      ['0:0:0-1', '0:1:0-1', '1:0:0-1'],
      ['2:0:0-1'],
    ]);
  });

  test('a card taller than a page takes a page and is cut there', () {
    final pages = planBoardPages(
      bands: [
        [
          _lane([300, 20]),
        ],
      ],
      pageHeight: 100,
      bandGap: 5,
    );
    expect(_shape(pages), [
      ['0:0:0-1'],
      ['0:0:1-2'],
    ]);
  });

  test('an empty column is drawn once, with its head', () {
    final pages = planBoardPages(
      bands: [
        [
          _lane(const []),
          _lane([20]),
        ],
      ],
      pageHeight: 100,
      bandGap: 5,
    );
    expect(_shape(pages), [
      ['0:0:0-0', '0:1:0-1'],
    ]);
  });

  test('a board with nothing in it is still a page', () {
    expect(
      planBoardPages(bands: [], pageHeight: 100, bandGap: 5),
      hasLength(1),
    );
  });
}
