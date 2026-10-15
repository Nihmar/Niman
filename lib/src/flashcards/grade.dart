/// How well a card was remembered (#533): the four buttons of a review.
library;

/// A review's answer, each with the SM-2 quality it stands for.
enum Grade {
  /// Forgotten: quality 1.
  again(1),

  /// Remembered with effort: quality 3.
  hard(3),

  /// Remembered: quality 4.
  good(4),

  /// Remembered at once: quality 5.
  easy(5);

  new(this.quality);

  /// SM-2's quality of response, 0 to 5.
  final int quality;
}
