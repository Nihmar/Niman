/// The unit a recurrence rule counts its interval in.
library;

/// What `N` counts in `rec:Nd`, `Nw`, `Nm`, `Ny` and `Nb`.
enum RecurrenceUnit {
  /// Calendar days (`d`).
  day('d'),

  /// Weeks (`w`), Monday to Sunday.
  week('w'),

  /// Calendar months (`m`); a short month clamps to its last day.
  month('m'),

  /// Years (`y`); 29 February clamps to 28 in a common year.
  year('y'),

  /// Business days (`b`): Monday to Friday, no holidays.
  businessDay('b');

  new(this.letter);

  /// The letter that ends the interval in a `rec:` value.
  final String letter;

  /// The unit written with [letter] (lower case), or null.
  static RecurrenceUnit? fromLetter(String letter) {
    for (final unit in values) {
      if (unit.letter == letter) return unit;
    }
    return null;
  }
}
