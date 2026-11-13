package dev.niman.niman

import java.util.Locale

/**
 * Which of the device's voices read a book aloud (#1276): those of the
 * book's language, installed, the book's own country first, then the ones
 * that work offline, then by name.
 *
 * Plain JVM code over [Candidate], apart from `android.speech.tts.Voice`,
 * so the Android unit tests check it without a device.
 */
object ReadAloudVoices {
    /** A voice as the engine lists it. */
    data class Candidate(
        val name: String,
        val locale: Locale,
        val network: Boolean,
        val installed: Boolean,
    )

    /** The slowest and the fastest pace the reader asks for. */
    const val MIN_RATE = 0.5f
    const val MAX_RATE = 2f

    /** The locale a book's language tag names, the device's for none. */
    fun localeOf(tag: String?, fallback: Locale = Locale.getDefault()): Locale {
        if (tag.isNullOrBlank()) return fallback
        val locale = Locale.forLanguageTag(tag.trim().replace('_', '-'))
        return if (locale.language.isEmpty()) fallback else locale
    }

    /** The voices of [candidates] that read [locale]'s language, best first. */
    fun of(candidates: Collection<Candidate>, locale: Locale): List<Candidate> {
        val language = iso3(locale)
        return candidates
            .filter { it.installed && iso3(it.locale) == language }
            .sortedWith(
                compareBy<Candidate>(
                    { if (locale.country.isNotEmpty() && it.locale.country == locale.country) 0 else 1 },
                    { if (it.network) 1 else 0 },
                    { it.name },
                ),
            )
    }

    /** [rate] within what the reader offers. */
    fun clampRate(rate: Double?): Float =
        (rate?.toFloat() ?: 1f).coerceIn(MIN_RATE, MAX_RATE)

    private fun iso3(locale: Locale): String =
        try {
            locale.isO3Language
        } catch (_: java.util.MissingResourceException) {
            locale.language
        }
}
