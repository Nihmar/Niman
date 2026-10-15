package dev.niman.niman

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * The intent that binds a widget's rows service to its ListView (#969).
 *
 * `RemoteViewsService` keeps one factory per `Intent.filterEquals`
 * intent, and `filterEquals` compares action, data, type, class and
 * categories — never extras. An adapter intent that carried the widget id
 * only as an extra was the same intent for every instance of a widget
 * kind, so two Study widgets (two libraries) or two todo widgets (two
 * lists) were served by the one factory built for whichever bound first,
 * and both showed its rows. The id travels in the data URI as well, which
 * is what tells the instances apart; the extra stays for the services,
 * which read their id from it.
 */
object WidgetAdapter {
    const val STUDY = "study"
    const val TODO = "todo"
    const val NOTE = "note"

    private const val SCHEME = "niman-widget"

    /** The URI that makes one widget's adapter intent unique: `niman-widget://<kind>/<id>`. */
    fun uriString(kind: String, widgetId: Int): String = "$SCHEME://$kind/$widgetId"

    fun intent(
        context: Context,
        service: Class<*>,
        kind: String,
        widgetId: Int,
    ): Intent = Intent(context, service)
        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        .setData(Uri.parse(uriString(kind, widgetId)))
}
