/// How a row of note columns shares its width (#729,
/// `docs/records/note-columns.md`, "Width and wrapping"): the rule the app
/// lays columns out by, and the one the exported CSS writes —
/// `flex: <share> 1 0` with `min-width: min(16em, 100%)` and a 1.5 em gap,
/// worked out here as a browser works it out.
library;

import 'dart:math' as math;

/// The widths of a row of columns.
abstract final class ColumnLayout {
  /// How many ems a column is at least, before the row wraps it.
  static const double minEms = 16;

  /// How many ems separate two columns, and two rows of them.
  static const double gapEms = 1.5;

  /// Each column's share of a row, from the `width`s written: a column
  /// with one has its percentage, the others split what the widths leave
  /// equally — or `100 / N` each when they leave nothing.
  static List<double> shares(List<double?> widths) {
    if (widths.isEmpty) return const <double>[];
    var given = 0.0;
    var open = 0;
    for (final width in widths) {
      if (width == null) {
        open++;
      } else {
        given += width;
      }
    }
    final left = 100 - given;
    final each = open == 0
        ? 0.0
        : left > 0
        ? left / open
        : 100 / widths.length;
    return [for (final width in widths) width ?? each];
  }

  /// The rows the columns of [shares] fall into in [width], each a list of
  /// column indices in order: a row holds columns while each would get its
  /// minimum, [minimum] wide — `min(16em, 100%)` — with [gap] between
  /// them. The flex-wrap rule: a column's size before the row is filled is
  /// its basis, 0, raised to its minimum.
  static List<List<int>> rows(
    int count, {
    required double width,
    required double minimum,
    required double gap,
  }) {
    final least = math.min(minimum, width);
    final rows = <List<int>>[];
    var row = <int>[];
    var used = 0.0;
    for (var at = 0; at < count; at++) {
      final need = row.isEmpty ? least : used + gap + least;
      if (row.isNotEmpty && need > width + _tolerance) {
        rows.add(row);
        row = <int>[];
        used = least;
      } else {
        used = need;
      }
      row.add(at);
    }
    if (row.isNotEmpty) rows.add(row);
    return rows;
  }

  /// The widths of a row whose columns have [shares], in [width] with
  /// [gap] between them: what is left after the gaps, split by share, no
  /// column below [minimum] (`min(16em, 100%)`) — a browser's flexible
  /// lengths, a column held at its minimum taken out and the rest split
  /// again.
  static List<double> widths(
    List<double> shares, {
    required double width,
    required double minimum,
    required double gap,
  }) {
    if (shares.isEmpty) return const <double>[];
    final least = math.min(minimum, width);
    final room = math.max<double>(0, width - gap * (shares.length - 1));
    final out = List<double?>.filled(shares.length, null);
    while (true) {
      var left = room;
      var grow = 0.0;
      for (var at = 0; at < shares.length; at++) {
        final fixed = out[at];
        if (fixed != null) {
          left -= fixed;
        } else {
          grow += shares[at];
        }
      }
      var frozen = false;
      for (var at = 0; at < shares.length; at++) {
        if (out[at] != null) continue;
        final size = grow <= 0
            ? 0.0
            : math.max<double>(0, left) * shares[at] / grow;
        if (size < least - _tolerance) {
          out[at] = least;
          frozen = true;
        }
      }
      if (frozen) continue;
      return [
        for (var at = 0; at < shares.length; at++)
          out[at] ??
              (grow <= 0 ? 0.0 : math.max<double>(0, left) * shares[at] / grow),
      ];
    }
  }

  /// Whether columns laid out in [rows] sit side by side anywhere: some
  /// row holds more than one. When none does, each column is a row of its
  /// own, which is the columns stacked.
  static bool sideBySide(List<List<int>> rows) =>
      rows.any((row) => row.length > 1);

  static const double _tolerance = 0.01;
}
