package dev.niman.niman

import java.time.ZoneId
import java.time.ZonedDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The next local midnight the day-change alarm is armed for (#1018).
 */
class DayBoundaryTest {
    private val rome = ZoneId.of("Europe/Rome")

    private fun millis(zone: ZoneId, y: Int, mo: Int, d: Int, h: Int, mi: Int): Long =
        ZonedDateTime.of(y, mo, d, h, mi, 0, 0, zone).toInstant().toEpochMilli()

    @Test
    fun `an evening arms for the midnight that follows it`() {
        val now = millis(rome, 2026, 10, 16, 23, 59)
        val next = DayBoundary.nextMillis(now, rome)
        val midnight = millis(rome, 2026, 10, 17, 0, 0)
        assertTrue(next > midnight)
        assertTrue(next - midnight < 60_000)
    }

    @Test
    fun `a moment past midnight arms for the next one, not the one just gone`() {
        val now = millis(rome, 2026, 10, 17, 0, 0) + 500
        val next = DayBoundary.nextMillis(now, rome)
        val tomorrow = millis(rome, 2026, 10, 18, 0, 0)
        assertTrue(next > tomorrow)
        assertTrue(next - tomorrow < 60_000)
    }

    @Test
    fun `the day the clocks go back is 25 hours long`() {
        // Europe/Rome leaves summer time on 2026-10-25.
        val now = millis(rome, 2026, 10, 25, 0, 30)
        val next = DayBoundary.nextMillis(now, rome)
        val midnight = millis(rome, 2026, 10, 26, 0, 0)
        assertTrue(next > midnight)
        assertTrue(next - midnight < 60_000)
        // Half an hour into a 25-hour day: 24.5 hours of it remain.
        assertEquals(24.5, (next - now) / 3_600_000.0, 0.05)
    }

    @Test
    fun `the zone decides where midnight is`() {
        val utc = ZoneId.of("UTC")
        val tokyo = ZoneId.of("Asia/Tokyo")
        val now = millis(utc, 2026, 10, 16, 20, 0)
        // 20:00 UTC on the 16th is already 05:00 on the 17th in Tokyo.
        assertEquals(
            millis(tokyo, 2026, 10, 18, 0, 0) + 2_000,
            DayBoundary.nextMillis(now, tokyo),
        )
        assertEquals(
            millis(utc, 2026, 10, 17, 0, 0) + 2_000,
            DayBoundary.nextMillis(now, utc),
        )
    }
}
