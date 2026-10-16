package dev.niman.niman

import java.time.Instant
import java.time.ZoneId

/**
 * The next local midnight (#1018): when the todo widget's day-bound
 * headings go stale and the app must re-push them.
 *
 * Pure `java.time`, so the DST and zone cases are tested without a
 * device.
 */
object DayBoundary {
    /**
     * A little past midnight, so a clock that fires the alarm a hair
     * early still reads the new day when Dart asks for "now".
     */
    private const val MARGIN_MILLIS = 2_000L

    /**
     * The epoch millis of the first instant of the day after [nowMillis]
     * in [zone] (plus the margin); always strictly after [nowMillis].
     */
    fun nextMillis(nowMillis: Long, zone: ZoneId): Long {
        val today = Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()
        return today.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() + MARGIN_MILLIS
    }
}
