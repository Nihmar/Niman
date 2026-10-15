/// Day arithmetic on the calendar rather than on the clock.
library;

/// The local midnight [days] calendar days from [day]'s date (negative
/// goes back), whatever time of day [day] carries.
///
/// Not `day.add(Duration(days: n))`, which adds `24 * n` elapsed hours: the
/// day a clock falls back is 25 hours long and the day it springs forward
/// is 23, so from a local midnight that lands on 23:00 of the same date
/// (or a day off the one meant) and a due date written from it is wrong
/// (#957). The constructor normalises the overflowing day field itself,
/// months and years included.
DateTime addCalendarDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
