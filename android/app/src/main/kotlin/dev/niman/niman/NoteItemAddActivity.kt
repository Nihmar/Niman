package dev.niman.niman

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.net.Uri
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/**
 * The list widget's "+" dialog (issue 6 follow-up): adds an item to the
 * pinned checklist WITHOUT leaving the home screen.
 *
 * RemoteViews cannot capture typed text, so the "+" cannot append blind:
 * it opens this floating activity over the launcher, the user types the
 * item, and the commit fires the same background broadcast the row taps
 * use (`niman://note-row-add` with the typed text). The broadcast wakes
 * the headless Dart engine, which appends the item and re-pushes the
 * payload — the launcher is never left, and no Flutter UI flashes.
 *
 * The note name comes from the payload the provider already rendered
 * (always present when the "+" is on screen); a stale payload without
 * library/note aborts quietly — the header still opens the app.
 */
class NoteItemAddActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val appWidgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        val library = intent?.getStringExtra(WidgetBridge.EXTRA_LIBRARY).orEmpty()
        val note = intent?.getStringExtra(WidgetBridge.EXTRA_NOTE).orEmpty()
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID ||
            library.isEmpty() || note.isEmpty()
        ) {
            WidgetDebugLog.log(
                this,
                "note add aborted: widget=$appWidgetId library=$library note=$note",
            )
            finish()
            return
        }
        setContentView(R.layout.widget_note_add)
        findViewById<TextView>(R.id.widget_note_add_title).text = titleFor(note)
        val field = findViewById<EditText>(R.id.widget_note_add_field)
        val addButton = findViewById<Button>(R.id.widget_note_add_add)
        val cancelButton = findViewById<Button>(R.id.widget_note_add_cancel)
        // The keyboard opens straight away: the whole point is typing from
        // the home screen.
        field.requestFocus()
        field.post {
            imm().showSoftInput(field, InputMethodManager.SHOW_IMPLICIT)
        }
        field.addTextChangedListener(
            object : TextWatcher {
                override fun beforeTextChanged(
                    s: CharSequence?, start: Int, count: Int, after: Int,
                ) = Unit

                override fun onTextChanged(
                    s: CharSequence?, start: Int, before: Int, count: Int,
                ) = Unit

                override fun afterTextChanged(text: Editable?) {
                    addButton.isEnabled = !text.isNullOrBlank()
                }
            },
        )
        field.setOnEditorActionListener { _, actionCode, _ ->
            if (actionCode == EditorInfo.IME_ACTION_DONE) {
                commit(appWidgetId, library, note, field.text.toString())
                true
            } else {
                false
            }
        }
        addButton.setOnClickListener {
            commit(appWidgetId, library, note, field.text.toString())
        }
        cancelButton.setOnClickListener { finish() }
    }

    /**
     * Fires the background add broadcast and closes: the headless engine
     * does the edit and the widget refreshes when the payload lands.
     */
    private fun commit(appWidgetId: Int, library: String, note: String, text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) {
            finish()
            return
        }
        val uri = Uri.Builder()
            .scheme("niman")
            .authority("note-row-add")
            .appendQueryParameter("id", appWidgetId.toString())
            .appendQueryParameter("library", library)
            .appendQueryParameter("note", note)
            .appendQueryParameter("text", trimmed)
            .build()
        val sent = try {
            HomeWidgetBackgroundIntent.getBroadcast(this, uri).send()
        } catch (e: Exception) {
            WidgetDebugLog.log(this, "note add broadcast failed: $e")
            false
        }
        WidgetDebugLog.log(
            this,
            "note add sent=$sent widget=$appWidgetId note=$note",
        )
        finish()
    }

    private fun imm(): InputMethodManager =
        getSystemService(InputMethodManager::class.java)!!

    companion object {
        // The widget title Dart computes for the payload (`Todo.md` →
        // `Todo`); repeated here because no engine runs in this dialog.
        private fun titleFor(note: String): String {
            val base = note.trimEnd('/').substringAfterLast('/')
                .substringAfterLast('\\')
            return if (base.endsWith(".md", ignoreCase = true)) {
                base.dropLast(3)
            } else {
                base
            }.ifEmpty { note }
        }
    }
}
