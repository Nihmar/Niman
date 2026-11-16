/// The paper a PDF export is printed on (#1285): an app-wide setting, A4
/// unless another is picked, for every engine — the desktop browsers, the
/// system WebViews and the raster writer — alike.
library;

/// A sheet of paper, by its size standing up.
enum PaperSize {
  /// ISO A0, 841 × 1189 mm.
  a0(841, 1189),

  /// ISO A1, 594 × 841 mm.
  a1(594, 841),

  /// ISO A2, 420 × 594 mm.
  a2(420, 594),

  /// ISO A3, 297 × 420 mm.
  a3(297, 420),

  /// ISO A4, 210 × 297 mm: what an export was printed on before there was
  /// a choice, and still the default.
  a4(210, 297),

  /// ISO A5, 148 × 210 mm.
  a5(148, 210),

  /// US Letter, 8.5 × 11 in.
  letter(215.9, 279.4),

  /// US Legal, 8.5 × 14 in.
  legal(215.9, 355.6),

  /// US Tabloid, 11 × 17 in.
  tabloid(279.4, 431.8);

  new(this.widthMm, this.heightMm);

  /// The short side, in millimetres.
  final double widthMm;

  /// The long side, in millimetres.
  final double heightMm;

  /// Whether it is one of the US sizes, measured in inches.
  bool get inches => this == letter || this == legal || this == tabloid;

  /// The size with this [name]; anything unknown is [a4], as an export
  /// was before the setting.
  static PaperSize fromName(Object? name) {
    for (final size in values) {
      if (size.name == name) return size;
    }
    return a4;
  }
}

/// PDF points (1/72 inch) in a millimetre.
const double pointsPerMm = 72 / 25.4;
