package dev.niman.niman

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.storage.StorageManager
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
    private var finished = false
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
            WidgetDebugLog.log(this, "config aborted: no appWidgetId extra")
            finish()
            return
        }
        isTodo = intent?.component?.className != NOTE_ALIAS
        WidgetDebugLog.log(
            this,
            "config start: kind=${if (isTodo) "todo" else "note"} widget=$appWidgetId",
        )
        savedInstanceState?.let {
            val path = it.getString(STATE_LIBRARY_PATH)
            val name = it.getString(STATE_LIBRARY_NAME)
            if (path != null && name != null) {
                pendingLibrary = MirrorLibrary(path, name, "")
                WidgetDebugLog.log(this, "restored pending library: $path")
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

    /**
     * The durable record that the dialog ended without a choice: the
     * logcat line alone would be gone by the time a log is exported.
     */
    override fun finish() {
        if (!finished) {
            WidgetDebugLog.log(
                this,
                "config aborted without a choice: widget=$appWidgetId",
            )
            finished = true
        }
        super.finish()
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
        val libraries = readMirror()
        WidgetDebugLog.log(
            this,
            "mirror: ${libraries.size} librar${if (libraries.size == 1) "y" else "ies"}",
        )
        when {
            libraries.isEmpty() -> {
                // The restored pick (if any) is moot: there is nothing to
                // pick from.
                pendingLibrary = null
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
                // A visible chooser resets the pending pick: the user
                // starts over. The single-library branches above must NOT
                // clear it, or a pick restored from the saved state
                // (activity recreation) would be lost before the picker's
                // result arrives.
                pendingLibrary = null
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
        val initial = initialUriFor(library.path)
        WidgetDebugLog.log(
            this,
            "note picker: library=${library.path} initialUri=$initial",
        )
        val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            initial?.let { putExtra(DocumentsContract.EXTRA_INITIAL_URI, it) }
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
            WidgetDebugLog.log(
                this,
                "picker incomplete: result=$resultCode, " +
                    "uri=${data?.data ?: "-"}, library=${library != null}",
            )
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
     * storage; null otherwise, and the picker opens wherever it was
     * last.
     */
    private fun initialUriFor(libraryPath: String): Uri? {
        val docId = externalStorageDocId(libraryPath) ?: return null
        val uri = DocumentsContract.buildDocumentUri(
            EXTERNAL_STORAGE_AUTHORITY,
            docId,
        )
        // The id is only a guess until the provider confirms the folder
        // (a missing document throws FileNotFoundException).
        return if (runCatching {
            DocumentsContract.getDocumentMetadata(contentResolver, uri)
        }.isSuccess) uri else null
    }

    /**
     * The `ExternalStorageProvider` document id of [libraryPath], or null
     * when the library is not on a shared storage volume.
     *
     * The id is `volumeId:rest-of-path`: `primary` is the volume id of
     * the primary emulated volume (`/storage/emulated/0`), other volumes
     * use their storage UUID. Parsing the first path segment as the
     * volume is wrong -- `/storage/emulated/0/...` belongs to `primary`,
     * not to an `emulated:0` volume -- which is why a picked note's
     * docId never matched and every pick was rejected.
     */
    private fun externalStorageDocId(libraryPath: String): String? {
        val storage = getSystemService(StorageManager::class.java) ?: return null
        for (volume in storage.storageVolumes) {
            val root = volume.directory?.path ?: continue
            if (root.length <= 1) continue
            val id = if (volume.isPrimary) "primary" else volume.uuid
            if (libraryPath == root) {
                return id
            }
            if (libraryPath.startsWith("$root/")) {
                val rest = libraryPath.removePrefix(root).removePrefix("/")
                return "$id:$rest"
            }
        }
        return null
    }

    /**
     * Maps a picked document to its library-relative `.md` path, or null
     * (with the reason logged) when the file is not usable: another
     * provider, outside the library, not Markdown.
     */
    private fun notePathIn(libraryPath: String, uri: Uri): String? {
        if (uri.authority != EXTERNAL_STORAGE_AUTHORITY) {
            WidgetDebugLog.log(
                this,
                "note pick rejected: authority ${uri.authority} " +
                    "(expected $EXTERNAL_STORAGE_AUTHORITY)",
            )
            return null
        }
        val docId = runCatching { DocumentsContract.getDocumentId(uri) }.getOrNull()
        if (docId == null) {
            WidgetDebugLog.log(
                this,
                "note pick rejected: unreadable document id in $uri",
            )
            return null
        }
        val libDocId = externalStorageDocId(libraryPath)
        if (libDocId == null) {
            WidgetDebugLog.log(
                this,
                "note pick rejected: library path not on external storage: $libraryPath",
            )
            return null
        }
        // A library at the volume root is a bare volume id (`primary`)
        // whose children use `:`; deeper ones use `/` before the child.
        val boundary = if (libDocId.contains(':')) "/" else ":"
        if (!docId.startsWith("$libDocId$boundary")) {
            WidgetDebugLog.log(this, "note pick rejected: $docId is outside $libDocId")
            return null
        }
        val relative = docId.removePrefix("$libDocId$boundary")
        if (relative.isEmpty()) {
            WidgetDebugLog.log(
                this,
                "note pick rejected: the library root itself was picked",
            )
            return null
        }
        // A ".." SEGMENT would escape the library; consecutive dots
        // inside a name ("note..md") are legitimate, so scan segments,
        // not the whole string.
        if (relative.split('/').any { it == ".." }) {
            WidgetDebugLog.log(
                this,
                "note pick rejected: path escapes the library: $relative",
            )
            return null
        }
        if (!relative.endsWith(".md", ignoreCase = true)) {
            WidgetDebugLog.log(
                this,
                "note pick rejected: not a note file: $relative",
            )
            return null
        }
        WidgetDebugLog.log(this, "note pick accepted: $relative in $libDocId")
        return relative
    }

    /** Writes the per-instance choice and places the widget. */
    private fun finishOk(choice: Map<String, String>, isTodo: Boolean) {
        val key = if (isTodo) "todo_$appWidgetId" else "note_$appWidgetId"
        val json = JSONObject(choice).toString()
        HomeWidgetPlugin.getData(this).edit().putString("${key}_config", json).apply()
        WidgetDebugLog.log(
            this,
            "config finished: widget=$appWidgetId " +
                "library=${choice["library"] ?: "-"} note=${choice["note"] ?: "-"}",
        )
        finished = true
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
