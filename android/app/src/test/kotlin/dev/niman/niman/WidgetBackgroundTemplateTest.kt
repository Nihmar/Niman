package dev.niman.niman

import android.app.PendingIntent
import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetBackgroundTemplateTest {
    @Test
    fun `FLAG_MUTABLE is added from Android 12`() {
        assertEquals(PendingIntent.FLAG_MUTABLE, WidgetBackgroundTemplate.mutableFlag(31))
        assertEquals(PendingIntent.FLAG_MUTABLE, WidgetBackgroundTemplate.mutableFlag(36))
    }

    @Test
    fun `nothing is added on Android 11, which has no such flag`() {
        assertEquals(0, WidgetBackgroundTemplate.mutableFlag(30))
    }
}
