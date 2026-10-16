package dev.niman.niman

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.time.ZoneId

/**
 * Arms the alarm that wakes [DayChangeReceiver] at the next local
 * midnight (#1018).
 *
 * An inexact, doze-friendly alarm, re-armed each time it fires: it needs
 * no exact-alarm access (a few minutes' slack at midnight is nothing to a
 * widget heading) and, unlike the implicit `DATE_CHANGED` broadcast, it
 * does not depend on the system delivering that implicit broadcast to a
 * manifest-declared receiver. Arming is idempotent (one pending intent,
 * `FLAG_UPDATE_CURRENT`), so the provider calls it on every update.
 */
object DayChangeScheduler {
    /** The action of the alarm's own intent. */
    const val ACTION_ALARM = "dev.niman.niman.action.DAY_CHANGE_ALARM"

    /** Arms (or re-arms) the alarm for the next local midnight. */
    fun schedule(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val at = DayBoundary.nextMillis(System.currentTimeMillis(), ZoneId.systemDefault())
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context))
    }

    /** Cancels the alarm (the last todo widget is gone). */
    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(pending(context))
    }

    private fun pending(context: Context): PendingIntent {
        val intent = Intent(context, DayChangeReceiver::class.java).setAction(ACTION_ALARM)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
