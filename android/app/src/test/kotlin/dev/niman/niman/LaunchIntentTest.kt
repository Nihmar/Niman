package dev.niman.niman

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The launching intent of a task, handled once (#721).
 *
 * The reported fault: a share that started the app ran again when the
 * task was restored. An Android share or widget tap is the activity's
 * launching intent and is handled on every engine creation, and Android
 * hands that same intent back when it rebuilds the activity.
 *
 * A distinct task per test: the handled launches are remembered for the
 * whole process, as they are in the app.
 */
class LaunchIntentTest {
    @Test
    fun `a launch is taken once`() {
        val launch = LaunchIntent()
        assertTrue(launch.take(101, "share:page"))
        assertFalse("the same launch is not taken twice", launch.take(101, "share:page"))
    }

    @Test
    fun `a restored task takes nothing`() {
        val launch = LaunchIntent()
        launch.restore(true)
        assertFalse(launch.take(102, "share:page"))
        // And the bundle keeps saying so, however the activity came back.
        assertTrue(launch.handled())
    }

    @Test
    fun `an activity recreated in the process takes nothing`() {
        // No saved state: a live process rebuilding the activity. The
        // process remembers the launch, the bundle did not.
        LaunchIntent().take(103, "shortcut:new-note")
        val again = LaunchIntent()
        assertFalse(again.take(103, "shortcut:new-note"))
        assertTrue(again.handled())
    }

    @Test
    fun `another intent in the same task is taken`() {
        val launch = LaunchIntent()
        assertTrue(launch.take(104, "share:page"))
        assertTrue("a widget tap is not the share before it", launch.take(104, "widget:todo"))
    }

    @Test
    fun `another task takes its own launch`() {
        val launch = LaunchIntent()
        assertTrue(launch.take(105, "share:page"))
        assertTrue(launch.take(106, "share:page"))
    }
}
