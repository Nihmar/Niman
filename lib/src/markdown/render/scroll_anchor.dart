/// Where a note is scrolled to, in the note's own terms.
library;

/// The source line at the top of a view, and how far into it the view is
/// scrolled: 0 at its top, towards 1 at its bottom.
///
/// Pixels mean nothing across the modes — a heading is taller in `live`
/// than in `source`, a definition takes no room in the read view — so a
/// switch between them hands over this instead, and the view it lands in
/// shows the same line at its top.
typedef ScrollAnchor = ({int line, double fraction});
