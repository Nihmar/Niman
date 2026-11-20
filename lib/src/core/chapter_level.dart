/// Which heading level a text's chapters open at (#1294): one rule for a
/// page read as a book and a note written as a book.
///
/// The chapters' level is the **shallowest level that occurs at least
/// [minimumChapters] times** — `2` for a text with one `#`, its title, and
/// its chapters under it as `##`; `1` for a text whose chapters are `#` and
/// whose sections inside them are `##`. A level that occurs once or twice is
/// a title or a pair of sections, not a book's chapters.
library;

/// How many headings of a level make it the chapters'.
const int minimumChapters = 3;

/// The chapters' level among the headings of [levels] (one entry per
/// heading, its level), or null when no level repeats enough to be one.
int? chapterLevelOf(Iterable<int> levels) {
  final counts = <int, int>{};
  for (final level in levels) {
    counts[level] = (counts[level] ?? 0) + 1;
  }
  int? best;
  for (final MapEntry(key: level, value: count) in counts.entries) {
    if (count >= minimumChapters && (best == null || level < best)) {
      best = level;
    }
  }
  return best;
}
