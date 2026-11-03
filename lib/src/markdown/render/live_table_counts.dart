/// The counters behind `LiveTables.measurements` and `LiveTables.rowsLaid`.
library;

/// The work `live`'s tables have done, counted for the tests that hold a
/// revision and a caret move to it (#494): read and reset through
/// `LiveTables.measurements` and `LiveTables.rowsLaid`.
abstract final class LiveTableCounts {
  /// How many times a cell's text has been laid out for a table.
  static int measurements = 0;

  /// How many rows have been laid out.
  static int rowsLaid = 0;
}
