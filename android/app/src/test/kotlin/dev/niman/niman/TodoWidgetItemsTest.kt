package dev.niman.niman

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The items of the todo widget's list (#1003): section headers and task
 * rows in one flat payload array, and the meta line of a row.
 */
class TodoWidgetItemsTest {
    private fun header(section: String, label: String, count: Int, tone: String? = null) =
        JSONObject()
            .put("kind", "section")
            .put("section", section)
            .put("label", label)
            .put("count", count)
            .also { if (tone != null) it.put("tone", tone) }

    private fun row(
        text: String,
        section: String? = null,
        due: String? = null,
        priority: String? = null,
        showDue: Boolean? = null,
    ) = JSONObject()
        .put("text", text)
        .put("due", due ?: JSONObject.NULL)
        .put("priority", priority ?: JSONObject.NULL)
        .also { if (section != null) it.put("section", section) }
        .also { if (showDue != null) it.put("showDue", showDue) }

    @Test
    fun `a payload array parses into its items in order`() {
        val payload = JSONArray()
            .put(header("due.overdue", "Overdue", 2, "error"))
            .put(row("late", "due.overdue", due = "2026-10-01"))
            .put(row("later", "due.overdue", due = "2026-10-02"))
            .put(header("due.none", "No date", 1))
            .put(row("free", "due.none"))
        val items = TodoWidgetItems.parse(payload)
        assertEquals(5, items.size)
        assertEquals(listOf("Overdue", "", "", "No date", ""), items.map { TodoWidgetItems.sectionLabel(it) })
        assertEquals(
            listOf("late", "later", "free"),
            items.filterNot { TodoWidgetItems.isSection(it) }.map { it.getString("text") },
        )
    }

    @Test
    fun `no array and non-object entries parse to nothing`() {
        assertTrue(TodoWidgetItems.parse(null).isEmpty())
        val items = TodoWidgetItems.parse(JSONArray().put("junk").put(row("a")).put(JSONObject.NULL))
        assertEquals(1, items.size)
    }

    @Test
    fun `a header and a row inflate different layouts`() {
        assertEquals(TodoWidgetItems.VIEW_SECTION, TodoWidgetItems.viewType(header("due.today", "Today", 1)))
        assertEquals(TodoWidgetItems.VIEW_ROW, TodoWidgetItems.viewType(row("task", "due.today")))
        assertEquals(2, TodoWidgetItems.VIEW_TYPE_COUNT)
    }

    @Test
    fun `an old payload without sections is all rows`() {
        // Pushed before the sections: rows only, no kind, no section.
        val old = TodoWidgetItems.parse(
            JSONArray()
                .put(row("first", due = "2026-10-01"))
                .put(row("second")),
        )
        assertEquals(2, old.size)
        assertTrue(old.none { TodoWidgetItems.isSection(it) })
        assertTrue(old.all { TodoWidgetItems.viewType(it) == TodoWidgetItems.VIEW_ROW })
        assertEquals(2, TodoWidgetItems.rowCount(old))
        // And its due date still shows: nothing said a section names it.
        assertEquals("2026-10-01", TodoWidgetItems.metaLine(old.first()))
    }

    @Test
    fun `headers are not counted as rows`() {
        val items = TodoWidgetItems.parse(
            JSONArray()
                .put(header("due.today", "Today", 1))
                .put(row("task", "due.today")),
        )
        assertEquals(2, items.size)
        assertEquals(1, TodoWidgetItems.rowCount(items))
    }

    @Test
    fun `a header carries its label and true count`() {
        val item = header("due.later", "Later", 250)
        assertEquals("Later", TodoWidgetItems.sectionLabel(item))
        assertEquals("250", TodoWidgetItems.sectionCount(item))
    }

    @Test
    fun `a header counts the rows that follow it, not the count it was written with`() {
        // A capped payload: "Later" was written with 250 but 2 rows survived.
        val items = TodoWidgetItems.parse(
            JSONArray()
                .put(header("due.today", "Today", 1))
                .put(row("now", "due.today"))
                .put(header("due.later", "Later", 250))
                .put(row("far", "due.later"))
                .put(row("farther", "due.later")),
        )
        val counts = items.filter { TodoWidgetItems.isSection(it) }.map { TodoWidgetItems.sectionCount(it) }
        assertEquals(listOf("1", "2"), counts)
    }

    @Test
    fun `only the error tone header is drawn in the error color`() {
        assertTrue(TodoWidgetItems.isErrorTone(header("due.overdue", "Overdue", 1, "error")))
        assertFalse(TodoWidgetItems.isErrorTone(header("due.today", "Today", 1)))
        assertFalse(TodoWidgetItems.isErrorTone(header("due.later", "Later", 1, "other")))
    }

    @Test
    fun `the meta line joins priority, due date and markers`() {
        val item = row("call", "due.next7", due = "2026-10-20", priority = "A")
            .put("projects", JSONArray().put("work"))
            .put("contexts", JSONArray().put("home"))
            .put("tags", JSONArray().put("urgent"))
        assertEquals("(A) · 2026-10-20 · +work @home #urgent", TodoWidgetItems.metaLine(item))
    }

    @Test
    fun `a row with nothing to say has an empty meta line`() {
        assertEquals("", TodoWidgetItems.metaLine(row("plain", "due.none")))
    }

    @Test
    fun `a row under Today leaves its date out and keeps the rest`() {
        val item = row("now", "due.today", due = "2026-10-16", priority = "B", showDue = false)
            .put("projects", JSONArray().put("work"))
        assertEquals("(B) · +work", TodoWidgetItems.metaLine(item))
        assertEquals("", TodoWidgetItems.metaLine(row("now", "due.today", due = "2026-10-16", showDue = false)))
    }

    @Test
    fun `an overdue row keeps its date`() {
        assertEquals(
            "2026-10-01",
            TodoWidgetItems.metaLine(row("late", "due.overdue", due = "2026-10-01", showDue = true)),
        )
    }

    @Test
    fun `the error tone follows the theme brightness`() {
        val light = WidgetTheme(false, 0, 0, 0, 0)
        val dark = WidgetTheme(true, 0, 0, 0, 0)
        assertEquals(0xFFB3261E.toInt(), light.error)
        assertEquals(0xFFF2B8B5.toInt(), dark.error)
    }

    @Test
    fun `a JSON null reads as absent, not as the text null`() {
        assertEquals("", TodoWidgetItems.string(row("x"), "due"))
        assertEquals("", TodoWidgetItems.string(row("x"), "missing"))
    }
}
