/// One line Tesseract recognized: its text, and where it sits on the page
/// in fractions of the page's width and height (0..1), so the place holds
/// at any rendering size.
final class OcrLine {
  /// A line reading [text], boxed by [left], [top], [right], [bottom];
  /// [paragraphStart] when a new paragraph begins with it.
  const new(
    this.text, {
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.paragraphStart = false,
  });

  /// The recognized text, without its line break.
  final String text;

  /// Left edge, a fraction of the page's width.
  final double left;

  /// Top edge, a fraction of the page's height.
  final double top;

  /// Right edge, a fraction of the page's width.
  final double right;

  /// Bottom edge, a fraction of the page's height.
  final double bottom;

  /// Whether a paragraph starts here.
  final bool paragraphStart;

  @override
  String toString() =>
      'OcrLine(${paragraphStart ? '¶ ' : ''}$text '
      '[$left, $top, $right, $bottom])';
}
