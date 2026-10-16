package dev.niman.niman

import org.json.JSONArray
import org.json.JSONObject

/**
 * The items of the todo widget's list (#1003): the payload's `rows`
 * array holds section headers and task rows in display order, one
 * collection position each.
 *
 * A header is `{kind: "section", section, label, count, tone?}`; a task
 * row has no `kind`, so a payload from before the sections (all rows)
 * still renders, as one flat list. Plain JVM code over `org.json`: the
 * rules live here, not in the RemoteViews factory, so they are tested
 * without a device.
 *
 * The widget always shows every section expanded and a header is not
 * interactive: a collection row can only fire an intent, and whether a
 * section is folded is the app's per-device state, not the glance
 * surface's.
 */
object TodoWidgetItems {
    /** View type of a task row (`widget_todo_row`). */
    const val VIEW_ROW = 0

    /** View type of a section header (`widget_todo_section`). */
    const val VIEW_SECTION = 1

    /** How many layouts the collection inflates. */
    const val VIEW_TYPE_COUNT = 2

    private const val KIND_SECTION = "section"
    private const val KIND_ROW = "row"
    private const val TONE_ERROR = "error"
    private const val SEPARATOR = " · "

    /**
     * The items of [array] in order; entries that are not objects are
     * skipped, and so is any entry whose `kind` is present and not one
     * this reader draws (a section or a row): a payload from a newer app
     * may carry kinds this one has never heard of, and drawing one as an
     * empty row would leave a dead tap target (#1024). Each header's `count` is set to the rows that follow it,
     * so a header never promises more rows than the list shows under it
     * (#1007), whatever the writer put there.
     */
    fun parse(array: JSONArray?): List<JSONObject> {
        if (array == null) return emptyList()
        val items = (0 until array.length())
            .mapNotNull { array.optJSONObject(it) }
            .filter { isKnownKind(it) }
        recount(items)
        return items
    }

    /** Whether [item] has no `kind` (a row) or one this reader draws. */
    private fun isKnownKind(item: JSONObject): Boolean {
        val kind = string(item, "kind")
        return kind.isEmpty() || kind == KIND_ROW || kind == KIND_SECTION
    }

    private fun recount(items: List<JSONObject>) {
        var header: JSONObject? = null
        var rows = 0
        for (item in items) {
            if (isSection(item)) {
                header?.put("count", rows)
                header = item
                rows = 0
            } else {
                rows++
            }
        }
        header?.put("count", rows)
    }

    /** Whether [item] is a section header. */
    fun isSection(item: JSONObject): Boolean = item.optString("kind") == KIND_SECTION

    /** The layout kind of [item]: [VIEW_SECTION] or [VIEW_ROW]. */
    fun viewType(item: JSONObject): Int = if (isSection(item)) VIEW_SECTION else VIEW_ROW

    /** How many of [items] are task rows (headers do not count). */
    fun rowCount(items: List<JSONObject>): Int = items.count { !isSection(it) }

    /** The heading of a section header. */
    fun sectionLabel(item: JSONObject): String = string(item, "label")

    /** The count a section header shows at its end. */
    fun sectionCount(item: JSONObject): String = item.optInt("count", 0).toString()

    /** Whether a section header is drawn in the error tone (Overdue). */
    fun isErrorTone(item: JSONObject): Boolean = string(item, "tone") == TONE_ERROR

    /**
     * The meta line of a task row: priority, due date and the
     * `+project` / `@context` / `#tag` markers, joined by a middle dot.
     * Empty when the row has none, so the row hides the line and its
     * text aligns with the others.
     *
     * The due date is left out when the payload says its section already
     * names it (`showDue: false`, the Today section); a payload without
     * the field shows it.
     */
    fun metaLine(row: JSONObject): String {
        val tokens = listOf(
            strings(row, "projects").map { "+$it" },
            strings(row, "contexts").map { "@$it" },
            strings(row, "tags").map { "#$it" },
        ).flatten()
        val due = if (row.optBoolean("showDue", true)) string(row, "due") else ""
        return listOfNotNull(
            string(row, "priority").takeIf { it.isNotEmpty() }?.let { "($it)" },
            due.takeIf { it.isNotEmpty() },
            tokens.joinToString(" ").takeIf { it.isNotEmpty() },
        ).joinToString(SEPARATOR)
    }

    /**
     * The [key] string of [item]; an absent key or an explicit JSON null
     * reads as empty (optString would hand back the string "null").
     */
    fun string(item: JSONObject, key: String): String {
        val value = item.opt(key)
        return if (value == null || value == JSONObject.NULL) "" else value.toString()
    }

    /** The [key] string list of [item]; absent, null or non-array reads as empty. */
    private fun strings(item: JSONObject, key: String): List<String> {
        val array = item.optJSONArray(key) ?: return emptyList()
        return (0 until array.length()).mapNotNull {
            val value = array.opt(it)
            if (value == null || value == JSONObject.NULL) {
                null
            } else {
                value.toString().takeIf { text -> text.isNotEmpty() }
            }
        }
    }
}
