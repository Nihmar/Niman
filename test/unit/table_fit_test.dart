// The one rule that fits a table's columns to the pane (#337, #1108): the
// read view and `live` both call it, so the cases are pinned on it directly.

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/table_fit.dart';

double _sum(List<double> widths) => widths.fold(0, (sum, w) => sum + w);

List<double> _fit(
  List<double> natural,
  List<double> least, {
  double budget = 300,
  double pad = 5,
}) => fitTableColumns(natural: natural, least: least, pad: pad, budget: budget);

void main() {
  test('no column is no width', () {
    expect(_fit(const [], const []), isEmpty);
  });

  test('columns that want nothing take nothing', () {
    expect(_fit(const [0, 0], const [0, 0]), const [0, 0]);
  });

  test('a pane that is all padding gives the cells nothing', () {
    expect(_fit(const [100, 100], const [20, 20], budget: 20), const [0, 0]);
    expect(_fit(const [100, 100], const [20, 20], budget: 5), const [0, 0]);
  });

  test('a column with no word known keeps the minimum cell width', () {
    // Room for the minimum and nothing else: both empty columns keep it.
    final fit = _fit(const [90, 90], const [0, 0], budget: 24 + 20);
    expect(fit, const [tableMinCellWidth, tableMinCellWidth]);
  });

  test('the room is spent: the fitted table ends on the budget', () {
    final fit = _fit(const [400, 300, 20], const [50, 40, 15], budget: 250);
    expect(_sum(fit) + 2 * 5 * 3, closeTo(250, 0.001));
  });

  test('every column keeps its widest word when the words fit', () {
    final fit = _fit(const [400, 300, 20], const [50, 40, 15], budget: 250);
    expect(fit[0], greaterThanOrEqualTo(50));
    expect(fit[1], greaterThanOrEqualTo(40));
    expect(fit[2], greaterThanOrEqualTo(15));
  });

  test('a short column keeps its word beside a long paragraph', () {
    // The reported shape (#1108): the room shared by whole cells gave the
    // first column a few characters.
    final fit = _fit(const [60, 600, 500, 40], const [45, 90, 80, 35]);
    expect(fit.first, greaterThanOrEqualTo(45));
    expect(fit.last, greaterThanOrEqualTo(35));
  });

  test('when the words just fit, every column is exactly its word', () {
    final fit = _fit(const [500, 400, 30], const [100, 80, 30], budget: 240);
    // 100 + 80 + 30 + 3 * 10 = 240.
    expect(fit[0], closeTo(100, 0.001));
    expect(fit[1], closeTo(80, 0.001));
    expect(fit[2], closeTo(30, 0.001));
  });

  test(
    'the fit is continuous across the point where the words stop fitting',
    () {
      // The words fit when the room is 210 (100 + 80 + 30) and not at 209.9:
      // one hair of room moves no column by more than a hair.
      const natural = [500.0, 400.0, 30.0];
      const least = [100.0, 80.0, 30.0];
      final fits = _fit(natural, least, budget: 240);
      final short = _fit(natural, least, budget: 239.9);
      for (var at = 0; at < 3; at++) {
        expect((fits[at] - short[at]).abs(), lessThan(0.2), reason: '$at');
      }
      expect(_sum(short) + 30, closeTo(239.9, 0.001));
    },
  );

  test('words that do not fit: the small ones stay whole', () {
    // Floors 30, 150, 160, 20 do not fit in 300: the level is 125, and the
    // two short columns keep their words.
    final fit = _fit(
      const [60, 900, 800, 40],
      const [30, 150, 160, 20],
      budget: 300 + 40,
    );
    expect(fit[0], closeTo(30, 0.001));
    expect(fit[3], closeTo(20, 0.001));
    expect(fit[1], closeTo(125, 0.001));
    expect(fit[2], closeTo(125, 0.001));
  });

  test('one huge floor among small ones does not take the pane', () {
    // A long address that has no place to break: its floor is its whole
    // width. Shared by floors it took 97 % of the room and left the other
    // three columns a few dp each.
    final fit = _fit(const [900, 80, 70, 60], const [900, 40, 35, 30]);
    expect(fit[1], closeTo(40, 0.001));
    expect(fit[2], closeTo(35, 0.001));
    expect(fit[3], closeTo(30, 0.001));
    // What the three words leave is the address's: 260 - 105.
    expect(fit[0], closeTo(155, 0.001));
  });
}
