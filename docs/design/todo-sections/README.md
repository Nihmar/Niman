# Todo sections — the screens, and the decisions

The mockups #1003 was agreed against (2026-10-16), before any code: the
phone as it was and as wanted, the desktop panel, and the Android
home-screen widget, in `html/`. They are drawn to look like Niman; where a
mockup and the app disagree, the app is what ships.

| Screen | File |
|---|---|
| The phone before #1003: the Open/Done switch, the date and filter pills, the count on a line of its own | [Phone-0-Now](html/Phone-0-Now.html) |
| The phone sorted by due date: help, Filter and Sort in the app bar; Overdue, Today, Next 7 days, Later and No date with their counts; Done last and folded | [Phone-1-Due](html/Phone-1-Due.html) |
| The phone with a filter on and sorted by priority: the Filter icon in the accent with a dot, the strip with the removable chip, `3 of 6` and Clear; sections by priority | [Phone-2-Filtered](html/Phone-2-Filtered.html) |
| The desktop sorted by due date: Filter and Sort as labelled pills, Add task and help at the end, quick add kept; one-line rows, one of them selected with its `⋯` | [Desktop-1-Due](html/Desktop-1-Due.html) |
| The desktop filtered, sorted by priority, Done open: `Filter · 1`, the strip, done rows checked and struck through with their completion day | [Desktop-2-Filtered](html/Desktop-2-Filtered.html) |
| The home-screen widget at 4×4 and 4×2: the same due sections, no Done | [Widget-1-Sections](html/Widget-1-Sections.html) |

## Decided with them

- **Sections follow the sort key.** By due date: Overdue, Today, Next 7
  days, Later, No date. By priority: one section per letter, then No
  priority. By creation date: a flat list without headers.
- **Done is the last section**, folded by default, and replaces the
  Open/Done switch. The due-range choice moves into the Filter sheet; the
  sections already show the ranges.
- **An empty section is hidden**, not shown with `0`.
- **Folded sections are remembered per device**, per library (a device key
  of the library's settings, never in the library's files).
- **The home-screen widget follows the layout**, always unfolded: its
  section headers are not interactive, since a widget row can only send an
  intent back to the app, and folding is the app's own state.
- **Every platform ships it.** The phone carries the controls in its app
  bar; the desktop panel carries them as pills, or as icons in a pane too
  narrow for the pills.
