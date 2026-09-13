package dev.niman.niman

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.ListView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.io.File

/**
 * Placement screens for both widgets (round 2, R1/R4): which library a
 * fresh instance reads, and which note for the note widget.
 *
 * One class, two launcher entries ([TodoWidgetConfig]/[NoteWidgetConfig]
 * aliases below): the alias component names the kind. No Dart engine
 * runs at placement, so everything here reads the `SharedPreferences`
 * mirror (`known_libraries`, written by Dart on every open) and the
 * per-library index files read-only. Choices land in per-instance
 * `*_config` prefs keys; Dart adopts them on the next refresh and owns
 * every database write.
 *
 * A single known library skips its step; nothing known shows how to get
 * one instead of an empty list.
 */
class WidgetConfigActivity : Activity() {

    companion object {
        /** Alias serving the todo widget. */
        const val TODO_ALIAS = "dev.niman.niman.TodoWidgetConfig"

        /** Alias serving the note widget. */
        const val NOTE_ALIAS = "dev.niman.niman.NoteWidgetConfig"

        /** Cap for the note list: the UI says so when it hits. */
        const val NOTE_LIMIT = 1000
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var isTodo = true

    private lateinit var titleView: TextView
    private lateinit var messageView: TextView
    private lateinit var searchView: EditText
    private lateinit var listView: ListView
    private lateinit var openAppButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appWidgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        isTodo = intent?.component?.className != NOTE_ALIAS
        setContentView(R.layout.widget_config)
        titleView = findViewById(R.id.widget_config_title)
        messageView = findViewById(R.id.widget_config_message)
        searchView = findViewById(R.id.widget_config_search)
        listView = findViewById(R.id.widget_config_list)
        openAppButton = findViewById(R.id.widget_config_open_app)
        openAppButton.setOnClickListener {
            startActivity(packageManager.getLaunchIntentForPackage(packageName))
            finish()
        }
        showLibraries()
    }

    /** The library step (R1): zero, one or many known libraries. */
    private fun showLibraries() {
        val libraries = readMirror()
        when {
            libraries.isEmpty() -> {
                titleView.text = if (isTodo) "Niman Todos" else "Niman Note"
                messageView.visibility = View.VISIBLE
                messageView.text = "No libraries yet. Open Niman, open a " +
                    "library, then place the widget again."
                listView.visibility = View.GONE
                openAppButton.visibility = View.VISIBLE
            }
            libraries.size == 1 && isTodo -> {
                finishOk(mapOf("library" to libraries[0].path), isTodo)
            }
            libraries.size == 1 -> {
                showNotes(libraries[0])
            }
            else -> {
                titleView.text = "Choose library"
                val adapter = ArrayAdapter(
                    this,
                    android.R.layout.simple_list_item_2,
                    android.R.id.text1,
                    libraries.map { "${it.name}\n${it.path}" },
                )
                listView.adapter = adapter
                listView.setOnItemClickListener { _, _, position, _ ->
                    val picked = libraries[position]
                    if (isTodo) {
                        finishOk(mapOf("library" to picked.path), isTodo = true)
                    } else {
                        showNotes(picked)
                    }
                }
            }
        }
    }

    /** The note step (R4): searchable `.md` list of [library]. */
    private fun showNotes(library: MirrorLibrary) {
        titleView.text = "Choose note"
        searchView.visibility = View.VISIBLE
        messageView.visibility = View.VISIBLE
        messageView.text = "Loading notes…"
        listView.visibility = View.GONE
        Thread {
            val paths = queryNotes(library.index)
            runOnUiThread {
                if (isFinishing || isDestroyed) return@runOnUiThread
                messageView.visibility = View.GONE
                if (paths.isEmpty()) {
                    messageView.visibility = View.VISIBLE
                    messageView.text = "No notes in ${library.name} yet."
                    return@runOnUiThread
                }
                if (paths.size > NOTE_LIMIT) {
                    messageView.visibility = View.VISIBLE
                    messageView.text =
                        "Showing first $NOTE_LIMIT — refine the search."
                }
                listView.visibility = View.VISIBLE
                val adapter = ArrayAdapter(
                    this,
                    android.R.layout.simple_list_item_1,
                    paths,
                )
                listView.adapter = adapter
                listView.setOnItemClickListener { _, _, position, _ ->
                    val picked = adapter.getItem(position) ?: return@setOnItemClickListener
                    finishOk(
                        mapOf("library" to library.path, "note" to picked),
                        isTodo = false,
                    )
                }
                searchView.addTextChangedListener(object : TextWatcher {
                    override fun beforeTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) = Unit
                    override fun onTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) = Unit
                    override fun afterTextChanged(s: Editable?) {
                        adapter.filter.filter(s?.toString().orEmpty())
                    }
                })
            }
        }.start()
    }

    /**
     * Reads `.md` notes of the index at [indexPath], newest names first
     * capped (the UI says when the cap hits). Read-only and off the UI
     * thread: the table can be large and the drift writer may hold it.
     */
    private fun queryNotes(indexPath: String): List<String> {
        if (!File(indexPath).exists()) return emptyList()
        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(indexPath, null, SQLiteDatabase.OPEN_READONLY)
            val out = ArrayList<String>()
            db.rawQuery(
                "SELECT path FROM notes WHERE is_dir = 0 AND name LIKE '%.md' ESCAPE '\\' " +
                    "ORDER BY name LIMIT ${NOTE_LIMIT + 1}",
                null,
            ).use { cursor ->
                val column = cursor.getColumnIndexOrThrow("path")
                while (cursor.moveToNext() && out.size <= NOTE_LIMIT) {
                    out.add(cursor.getString(column))
                }
            }
            return out
        } catch (e: Exception) {
            return emptyList()
        } finally {
            try {
                db?.close()
            } catch (e: Exception) {
                // Best effort.
            }
        }
    }

    /** Writes the per-instance choice and places the widget. */
    private fun finishOk(choice: Map<String, String>, isTodo: Boolean) {
        val key = if (isTodo) "todo_$appWidgetId" else "note_$appWidgetId"
        val json = JSONObject(choice).toString()
        HomeWidgetPlugin.getData(this).edit().putString("${key}_config", json).apply()
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, result)
        finish()
    }

    /** The mirror Dart maintains; empty when nothing was ever opened. */
    private fun readMirror(): List<MirrorLibrary> {
        val raw = HomeWidgetPlugin.getData(this).getString("known_libraries", null)
            ?: return emptyList()
        return runCatching {
            val libraries = JSONObject(raw).optJSONArray("libraries")
                ?: return emptyList()
            List(libraries.length()) { i ->
                val entry = libraries.optJSONObject(i) ?: return@List null
                val path = entry.optString("path", "")
                val index = entry.optString("index", "")
                if (path.isEmpty() || index.isEmpty()) {
                    return@List null
                }
                MirrorLibrary(
                    path,
                    entry.optString("name", "").ifEmpty { path },
                    index,
                )
            }.filterNotNull()
        }.getOrDefault(emptyList())
    }

    private data class MirrorLibrary(val path: String, val name: String, val index: String)
}
