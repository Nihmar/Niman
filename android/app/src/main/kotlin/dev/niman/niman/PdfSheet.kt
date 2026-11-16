package dev.niman.niman

import kotlin.math.roundToInt

/** 18 mm in thousandths of an inch. */
const val PDF_MARGIN_MILS = 709

/**
 * The sheet a page is printed on (issues #534, #1170 and #1285): what the
 * `paper` argument of the `niman/pdf` channel names — `portrait`,
 * `landscape` or `slides` — with the sheet's `width` and `height` as it
 * lies, in PDF points. Kept apart from the WebView so the reading is
 * testable on the JVM.
 */
data class PdfSheet(
    /** The name the Dart side sends (`PdfPaper.name`). */
    val key: String,
    /** Whether the sheet lies on its long side. */
    val landscape: Boolean,
    /** The margin all round, in thousandths of an inch. */
    val marginMils: Int,
    /** The width as it lies, in thousandths of an inch. */
    val widthMils: Int,
    /** The height as it lies, in thousandths of an inch. */
    val heightMils: Int,
) {
    /** Whether this is a slides note's 16:9 sheet, edge to edge. */
    val slides: Boolean get() = key == "slides"

    /** The short side, in thousandths of an inch. */
    val shortMils: Int get() = minOf(widthMils, heightMils)

    /** The long side, in thousandths of an inch. */
    val longMils: Int get() = maxOf(widthMils, heightMils)

    companion object {
        /** A4 standing up with the note's margin. */
        val A4 = PdfSheet("portrait", false, PDF_MARGIN_MILS, 8268, 11693)

        /** A4 on its side with the same margin: a wide kanban board. */
        val A4_LANDSCAPE = PdfSheet("landscape", true, PDF_MARGIN_MILS, 11693, 8268)

        /** A slide's 16:9 sheet, edge to edge. */
        val SLIDES = PdfSheet("slides", true, 0, 10000, 5625)

        /** Points (1/72 in) to thousandths of an inch. */
        fun mils(points: Double): Int = (points * 1000 / 72).roundToInt()

        /**
         * The sheet [paper] names, [width] × [height] points as it lies. The
         * names a Dart side before #1285 sent (`a4`, `a4Landscape`) are A4;
         * a missing name, one this side does not know, or a size that is not
         * one, is a portrait A4, as a channel older than the name was.
         */
        fun of(paper: String?, width: Double?, height: Double?): PdfSheet {
            when (paper) {
                "slides" -> return SLIDES
                "a4" -> return A4
                "a4Landscape" -> return A4_LANDSCAPE
            }
            if (paper != "portrait" && paper != "landscape") return A4
            if (width == null || height == null || width <= 0 || height <= 0) {
                return if (paper == "landscape") A4_LANDSCAPE else A4
            }
            return PdfSheet(paper, paper == "landscape", PDF_MARGIN_MILS, mils(width), mils(height))
        }
    }
}
