package dev.niman.niman

/**
 * 18 mm in thousandths of an inch. Top level, not in the companion: an enum
 * entry cannot read its own companion while the entries are being made.
 */
const val PDF_MARGIN_MILS = 709

/**
 * The sheet a page is printed on (issues #534 and #1170): what the `paper`
 * argument of the `niman/pdf` channel names, kept apart from the WebView so
 * the choice is testable on the JVM.
 */
enum class PdfSheet(
    /** The name the Dart side sends (`PdfPaper.name`). */
    val key: String,
    /** Whether the sheet lies on its long side. */
    val landscape: Boolean,
    /** The margin all round, in thousandths of an inch. */
    val marginMils: Int,
) {
    /** A4 with the note's margin. */
    A4("a4", false, PDF_MARGIN_MILS),

    /** A4 on its side with the same margin: a wide kanban board. */
    A4_LANDSCAPE("a4Landscape", true, PDF_MARGIN_MILS),

    /** A slide's 16:9 sheet, edge to edge. */
    SLIDES("slides", true, 0);

    companion object {
        /**
         * The sheet named [paper]. A missing name or one this side does not
         * know is A4, as a channel older than the name was.
         */
        fun forName(paper: String?): PdfSheet =
            entries.firstOrNull { it.key == paper } ?: A4
    }
}
