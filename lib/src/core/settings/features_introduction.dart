/// Which introduction the Features screen opens with (#1109).
library;

/// The card above the presets of Settings → Features, if any.
enum FeaturesIntroduction {
  /// None: the screen is opened for its own sake, or the library has been
  /// through the introduction already.
  none,

  /// A library that existed before the switches did: *Niman now lets you
  /// choose what this library uses*, with **Done**.
  existing,

  /// A library being created: *What is this library for?*, the presets as
  /// large cards in place of the chip row.
  created,
}
