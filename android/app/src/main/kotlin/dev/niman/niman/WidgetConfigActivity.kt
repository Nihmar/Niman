package dev.niman.niman

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/**
 * Placement screens for both widgets (round 2, R1/R4): which library a
 * fresh instance reads, and which note for the note widget.
 *
 * One class, two launcher entries ([TodoWidgetConfig]/[NoteWidgetConfig]
 * aliases below): the alias component names the kind. No Dart engine
 * runs at placement, so the library list comes from the
 * `SharedPreferences` mirror (`known_libraries`, written by Dart on
 * every open). Choices land in per-instance `*_config` prefs keys; Dart
 * adopts them on the next refresh and owns every database write.
 *
 * A single known library skips its step; nothing known shows how to get
 * one instead of an empty list. The note itself is picked with the
 * standard Android file picker starting inside the library folder
 * (R4 follow-up): only the resulting path is Niman's business.
 */
class WidgetConfigActivity : Activity() {

    companion object {
        /** Alias serving the todo widget. */
        const val TODO_ALIAS = "dev.niman.niman.TodoWidgetConfig"

        /** Alias serving the note widget. */
        const val NOTE_ALIAS = "dev.niman.niman.NoteWidgetConfig"

        private const val REQUEST_PICK_NOTE = 2
        private const val STATE_LIBRARY_PATH = "pending_library_path"
        private const val STATE_LIBRARY_NAME = "pending_library_name"

        /** The picker only understands this documents provider. */
        private const val EXTERNAL_STORAGE_AUTHORITY =
            "com.android.externalstorage.documents"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var isTodo = true
    private var pendingLibrary: MirrorLibrary? = null

    private lateinit var titleView: TextView
    private lateinit var messageView: TextView
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
        savedInstanceState?.let {
            val path = it.getString(STATE_LIBRARY_PATH)
            val name = it.getString(STATE_LIBRARY_NAME)
            if (path != null && name != null) {
                pendingLibrary = MirrorLibrary(path, name, "")
            }
        }
        setContentView(R.layout.widget_config)
        titleView = findViewById(R.id.widget_config_title)
        messageView = findViewById(R.id.widget_config_message)
        listView = findViewById(R.id.widget_config_list)
        openAppButton = findViewById(R.id.widget_config_open_app)
        openAppButton.setOnClickListener {
            startActivity(packageManager.getLaunchIntentForPackage(packageName))
            finish()
        }
        showLibraries()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        pendingLibrary?.let {
            outState.putString(STATE_LIBRARY_PATH, it.path)
            outState.putString(STATE_LIBRARY_NAME, it.name)
        }
    }

    /** The library step (R1): zero, one or many known libraries. */
    private fun showLibraries() {
        pendingLibrary = null
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
                pickNote(libraries[0])
            }
            else -> {
                titleView.text = "Choose library"
                messageView.visibility = View.GONE
                openAppButton.visibility = View.GONE
                listView.visibility = View.VISIBLE
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
                        pickNote(picked)
                    }
                }
            }
        }
    }

    /**
     * The note step (R4 follow-up): the standard Android file picker,
     * starting inside the library folder. Only `.md` files inside that
     * folder are accepted; anything else explains itself and restarts
     * the library step.
     */
    private fun pickNote(library: MirrorLibrary) {
        pendingLibrary = library
        val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            initialUriFor(library.path)?.let {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, it)
            }
        }
        try {
            startActivityForResult(picker, REQUEST_PICK_NOTE)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "No file picker found.", Toast.LENGTH_LONG).show()
            showLibraries()
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK_NOTE) return
        val library = pendingLibrary
        pendingLibrary = null
        if (resultCode != RESULT_OK || data?.data == null || library == null) {
            showLibraries()
            return
        }
        val note = notePathIn(library.path, data.data!!)
        if (note == null) {
            Toast.makeText(
                this,
                "Pick a .md file inside ${library.name}.",
                Toast.LENGTH_LONG,
            ).show()
            showLibraries()
            return
        }
        finishOk(
            mapOf("library" to library.path, "note" to note),
            isTodo = false,
        )
    }

    /**
     * Starts the picker inside [libraryPath] when it lives on shared
     * storage (`/storage/<volume>/<rest>`); null otherwise, and the
     * picker opens wherever it was last.
     */
    private fun initialUriFor(libraryPath: String): Uri? {
        val match = Regex("^/storage/([^/]+)/?(.*)$").matchEntire(libraryPath)
            ?: return null
        val (volume, rest) = match.destructured
        return DocumentsContract.buildDocumentUri(
            EXTERNAL_STORAGE_AUTHORITY,
            "$volume:$rest",
        )
    }

    /**
     * Maps a picked document to its library-relative `.md` path, or null
     * when the file is not usable: another provider, outside the
     * library, not Markdown.
     */
    private fun notePathIn(libraryPath: String, uri: Uri): String? {
        if (uri.authority != EXTERNAL_STORAGE_AUTHORITY) return null
        val docId = runCatching { DocumentsContract.getDocumentId(uri) }.getOrNull()
            ?: return null
        val libDocId = docIdFor(libraryPath) ?: return null
        if (!docId.startsWith("$libDocId/")) return null
        val relative = docId.removePrefix("$libDocId/")
        if (relative.isEmpty() ||
            relative.contains("..") ||
            !relative.endsWith(".md", ignoreCase = true)
        ) {
            return null
        }
        return relative
    }

    /** The `volume:rest` document id of [libraryPath], if on shared storage. */
    private fun docIdFor(libraryPath: String): String? {
        val match = Regex("^/storage/([^/]+)/?(.*)$").matchEntire(libraryPath)
            ?: return null
        val (volume, rest) = match.destructured
        return "$volume:$rest".trimEnd(':')
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
