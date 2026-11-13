package dev.niman.niman

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class ReadAloudVoicesTest {
    private fun voice(name: String, tag: String, network: Boolean = false, installed: Boolean = true) =
        ReadAloudVoices.Candidate(name, Locale.forLanguageTag(tag), network, installed)

    @Test
    fun aBookWithNoLanguageReadsInTheDevices() {
        assertEquals(Locale.ITALY, ReadAloudVoices.localeOf(null, Locale.ITALY))
        assertEquals(Locale.ITALY, ReadAloudVoices.localeOf("  ", Locale.ITALY))
        assertEquals("en", ReadAloudVoices.localeOf("en_GB", Locale.ITALY).language)
        assertEquals("GB", ReadAloudVoices.localeOf("en-GB", Locale.ITALY).country)
    }

    @Test
    fun onlyTheLanguagesInstalledVoicesBookCountryFirstThenOffline() {
        val voices = listOf(
            voice("us-net", "en-US", network = true),
            voice("it", "it-IT"),
            voice("gb", "en-GB"),
            voice("us", "en-US"),
            voice("us-missing", "en-US", installed = false),
        )
        val picked = ReadAloudVoices.of(voices, Locale.forLanguageTag("en-US"))
        assertEquals(listOf("us", "us-net", "gb"), picked.map { it.name })
    }

    @Test
    fun aLanguageWithoutCountryTakesEveryCountry() {
        val voices = listOf(voice("gb", "en-GB"), voice("us", "en-US"))
        assertEquals(listOf("gb", "us"), ReadAloudVoices.of(voices, Locale.ENGLISH).map { it.name })
    }

    @Test
    fun aThreeLetterTagMatchesItsTwoLetterVoice() {
        val voices = listOf(voice("it", "it-IT"))
        assertEquals(1, ReadAloudVoices.of(voices, Locale.forLanguageTag("ita")).size)
    }

    @Test
    fun theRateStaysWithinTheReadersRange() {
        assertEquals(1f, ReadAloudVoices.clampRate(null))
        assertEquals(0.5f, ReadAloudVoices.clampRate(0.1))
        assertEquals(2f, ReadAloudVoices.clampRate(9.0))
        assertEquals(1.25f, ReadAloudVoices.clampRate(1.25))
    }
}
