package dev.niman.niman

/**
 * A task's launching intent, handled once (#721).
 *
 * Android hands the activity the same launching intent again when it
 * rebuilds it, and the share, shortcut or widget tap that started the
 * app must not run a second time. Nothing in the intent's payload says it
 * was handled: a share into Niman looked exactly like a share into Niman
 * that never happened. Two things tell a rebuild from a launch:
 *
 * * the **saved state**, which the system hands back whenever it
 *   rebuilds an activity it took down itself — a task restored after the
 *   process was killed, an activity recreated in a live process — once
 *   the launch was taken, every bundle that comes back says so;
 * * **`FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`**, which the system adds when
 *   it relaunches a task from Recents whose activity was finished (Back
 *   is `finish()` in FlutterActivity): no saved state then, in a new
 *   process or a live one, only the task's base intent with that flag
 *   (#757). flutter_local_notifications ignores such an intent for the
 *   same reason.
 *
 * A fresh activity carries neither, so it always takes its launch: a
 * second share of the same file, or of the same page after a cancelled
 * first one, is a new share (#757). The identity of the intent is no
 * guide — `Intent.toUri` leaves out Parcelable extras and ClipData, so
 * two different files shared alike look the same, and it includes the
 * launch flags, so a relaunch from Recents looks new.
 *
 * A delivery to a live activity does not come through here at all:
 * `onNewIntent` carries it to the bridges directly.
 */
class LaunchIntent {
    /** The saved state said the activity's launch was already handled. */
    private var restored = false

    /** The launch was looked at, whether it was taken or not. */
    private var taken = false

    /** What the saved state carried: the launch was handled. */
    fun restore(handled: Boolean) {
        restored = handled
    }

    /** Whether the saved state should carry that the launch was handled. */
    fun handled(): Boolean = restored || taken

    /**
     * Whether the launching intent is to be handled now — not when the
     * saved state said it was, nor when the system relaunched it
     * [fromHistory] — and marks it handled either way, so the next look
     * says no.
     */
    fun take(fromHistory: Boolean): Boolean {
        val fresh = !restored && !taken && !fromHistory
        taken = true
        return fresh
    }
}
