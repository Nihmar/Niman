package dev.niman.niman

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Re-pushes the todo widgets when the local day turns over (#1018).
 *
 * A todo payload is bucketed against the day it was pushed, so a widget
 * left overnight keeps yesterday's Overdue / Today split. This receiver
 * wakes at the midnight alarm ([DayChangeScheduler]) and on the events
 * that move midnight or lose the alarm (the clock or time zone changed,
 * a reboot), re-arms the alarm, and fires the background Dart callback
 * once per placed todo widget with a `niman://todo-refresh` URI; Dart
 * re-reads the library's todo files and pushes the payload against the
 * new day, with the app closed. Nothing happens, and nothing stays
 * armed, while no todo widget is placed.
 */
class DayChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetDebugLog.log(context, "day change: ${intent.action}")
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, TodoWidgetProvider::class.java))
        if (ids.isEmpty()) {
            DayChangeScheduler.cancel(context)
            return
        }
        DayChangeScheduler.schedule(context)
        val data = HomeWidgetPlugin.getData(context)
        for (id in ids) {
            val payload = data.getString(TodoDayRefresh.payloadKey(id), null)
            val uri = TodoDayRefresh.uriString(id, payload) ?: continue
            val work = Intent(DayChangeScheduler.ACTION_ALARM).setData(Uri.parse(uri))
            WidgetBackgroundWork.enqueue(context, work)
        }
    }
}
