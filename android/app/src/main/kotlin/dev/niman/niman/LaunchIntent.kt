package dev.niman.niman

/**
 * A task's launching intent, handled once (#721).
 *
 * Android hands the activity the same launching intent again when it
 * rebuilds it — a task restored after the process was killed, an activity
 * recreated in a live process — and the share, shortcut or widget tap
 * that started the app must not run a second time. Nothing in the intent
 * says it was handled: a share into Niman looked exactly like a share
 * into Niman that never happened.
 *
 * Two memories, because the two rebuilds keep different things:
 *
 * * the **saved state**, which the system hands back when it rebuilds a
 *   task it killed — once the launch was taken, every bundle that comes
 *   back says so;
 * * the **signature** of the handled intent, per task, kept in the
 *   process — an activity recreated in a live process gets the intent
 *   again, but no bundle.
 *
 * A fresh delivery does not come through here at all: `onNewIntent`
 * carries it to the bridges directly.
 */
class LaunchIntent {
    /** The saved state said the task's launch was already handled. */
    private var restored = false

    /** What the saved state carried: the task's launch was handled. */
    fun restore(handled: Boolean) {
        restored = handled
    }

    /** Whether the saved state should carry that the launch was handled. */
    fun handled(): Boolean = restored || handled.isNotEmpty()

    /**
     * Whether the launching intent of [task], whose identity is
     * [signature], is to be handled now — and marks it handled either
     * way, so the next look says no.
     */
    fun take(task: Int, signature: String): Boolean {
        if (restored) return false
        val key = "$task:$signature"
        if (handled.contains(key)) return false
        handled.add(key)
        return true
    }

    private companion object {
        /**
         * The intents this process already handled, as `task:signature`.
         * Static on purpose: an activity recreated in a live process gets
         * a new [LaunchIntent], but not a new process — and the bundle it
         * is rebuilt from carries nothing for this case.
         */
        val handled = mutableSetOf<String>()
    }
}
