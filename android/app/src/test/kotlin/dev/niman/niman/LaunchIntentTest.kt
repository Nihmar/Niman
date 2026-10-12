package dev.niman.niman

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The launching intent of an activity, handled once (#721, #757).
 *
 * The reported faults: a share that started the app ran again when the
 * task was restored (#721) or relaunched from Recents (#757), and a
 * second, different share was dropped because it looked like the first
 * (#757). An Android share or widget tap is the activity's launching
 * intent and is handled on every engine creation, and Android hands that
 * same intent back when it rebuilds the activity.
 */
class LaunchIntentTest {
    @Test
    fun `a launch is taken once`() {
        val launch = LaunchIntent()
        assertTrue(launch.take(fromHistory = false))
        assertFalse("the same launch is not taken twice", launch.take(fromHistory = false))
        assertTrue(launch.handled())
    }

    @Test
    fun `a restored activity takes nothing`() {
        val launch = LaunchIntent()
        launch.restore(true)
        assertFalse(launch.take(fromHistory = false))
        // And the bundle keeps saying so, however the activity came back.
        assertTrue(launch.handled())
    }

    @Test
    fun `a relaunch from Recents takes nothing`() {
        // No saved state: the activity was finished, and the system
        // relaunches the task's base intent with the history flag.
        val launch = LaunchIntent()
        assertFalse(launch.take(fromHistory = true))
        assertTrue(launch.handled())
    }

    @Test
    fun `a new activity takes its launch however alike the last one was`() {
        // A second share of the same kind starts a new activity: nothing
        // carries over from the one before it.
        assertTrue(LaunchIntent().take(fromHistory = false))
        assertTrue(LaunchIntent().take(fromHistory = false))
    }

    @Test
    fun `an untaken launch saves nothing`() {
        assertFalse(LaunchIntent().handled())
    }
}
