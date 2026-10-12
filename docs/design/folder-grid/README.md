# Folder grid — the screens, and the decisions

The mockups #727 was agreed against (2026-10-12), before any code: seven
desktop screens and four phone screens, in `html/`. They are drawn to look
like Niman, in the Night palette of `lib/src/ui/theme/niman.dart`; where a
mockup and the app disagree, the app is what ships. The grid is a second
view of the Files sidebar (the Files tab on a phone), switchable with the
tree; the tree itself does not change.

| Screen | Desktop | Phone |
|---|---|---|
| The grid of a folder: folders first, notes, a picture with its outline icon, a pinned note, an OCR sidecar dimmed, `index.md` as a plain tile; the breadcrumb with **Up**; the **List \| Grid** pair, Grid on; the open note's tile selected | [Desktop-1-Grid](html/Desktop-1-Grid.html) | [Phone-1-Grid](html/Phone-1-Grid.html) |
| The sidebar at its 200 px minimum: two columns, the breadcrumb folded into **…**, **New** without its label | [Desktop-2-Narrow](html/Desktop-2-Narrow.html) | — |
| A tile's states: normal, hover, selected, keyboard focus, selected and focused, drop target, being dragged, multi-selected (reserved), pinned, sidecar; the pair in both states; **Up** disabled at the root | [Desktop-3-States](html/Desktop-3-States.html) | — |
| The menus: a tile's own row menu at the cursor, and the background menu of the grid's empty space | [Desktop-4-Menu](html/Desktop-4-Menu.html) | [Phone-3-Sheet](html/Phone-3-Sheet.html) (long press: the row sheet) |
| Rename in place: the tree's rename field laid over the tile, wider than it, with its error line | [Desktop-5-Rename](html/Desktop-5-Rename.html) | — (the dialog, as today) |
| Moving up: a tile dragged onto a breadcrumb crumb, the crumb lit | [Desktop-6-Drag](html/Desktop-6-Drag.html) | — |
| The switch: the list view — the tree as it is today — with List on | [Desktop-7-List](html/Desktop-7-List.html) | [Phone-2-SortMenu](html/Phone-2-SortMenu.html) (**View: List / Grid** in the sort menu) |
| An empty folder: the breadcrumb, an invitation, the **+** | — | [Phone-4-Empty](html/Phone-4-Empty.html) |

## Decided with them

- **Both the phone and the desktop.** Every platform ships every feature,
  and the Files tab has the room. On a phone the grid is three columns at
  about 360 dp, the breadcrumb sits under the app bar, the system Back
  walks up one folder, a long press opens the row sheet, a hold that moves
  drags, and a rename stays the dialog. The switch is a **View: List /
  Grid** group at the top of the sort menu, because the app bar has no room
  for another pair; on the desktop it is in the tree footer.
- **A single click on a folder's tile enters it**, as a single click opens
  a row in the tree. A middle click (or Ctrl+click) on a note opens it in a
  new tab. The keyboard focus is a ring of its own, apart from the
  selection's fill, so the two can be told apart and worn together.
- **A tile's date is the field the folder is sorted by**: the modified day,
  or the created day when sorting by Date created. The Name and Size orders
  show the modified day — a size says less than a day on a tile.
- **No "folder note", ever.** `index.md` is an ordinary note; its only
  special use is the metadata of an EPUB export. In the grid it is a tile
  like any other inside its folder, and the grid will not grow an
  affordance to open a folder "as its note": a folder's tile enters the
  folder, and nothing else.
- **The grid's current folder is kept in memory only**, like the tree's
  expanded folders; only the view (list or grid) is remembered, per device
  (the device key `treeView`). A library opened again starts the grid from
  the tree's selection.
- **No thumbnails.** Every tile is drawn from the SQLite index alone — name,
  kind, date, size, extension → icon. No file is read or stat'ed to draw
  the grid, which keeps it fast on a large folder and spares Android the
  FUSE round trips; a picture wears its outline icon.
- **Multi-select belongs to #712's item 2.1**, with one selection model
  shared by the list and the grid. The grid only reserves its look now —
  the selection's fill plus a filled check in the corner (Desktop-3) — so
  it is agreed before that work starts.
- **The current folder is the grid's own state, written through to the
  tree**: entering a folder selects it in the tree and expands it, so
  switching back finds it open. Opening a note from search, a tab or the
  palette does not move the grid. Switching from the tree to the grid
  starts in the selected folder, or in the selected note's folder, every
  time — the grid's own folder is what it holds while it is the pane on
  screen.
- **Pinned notes get a filled pin on their tile**, in their own folder; an
  OCR sidecar keeps its place right after its file, as in the tree, drawn
  dimmed with the scanner icon.
- **Drops**: a drop on a folder's tile moves into it; a drop on the grid's
  empty space is the folder shown, so nothing moves; the breadcrumb's
  crumbs take drops, and are how something is moved up.
- **The current folder follows its renames and moves**; deleted, the grid
  falls back to the nearest ancestor that still exists.
- **Rename in place on a tile** is the tree's own rename field and error
  line (#707), laid over the tile's label as an overlay at least ~220 px
  wide, growing past the tile over its neighbours.
- **The desktop keyboard**: the arrows, Home/End and PgUp/PgDn move the
  focus; Enter opens a note or enters a folder; Backspace or Alt+Up goes up;
  F2 renames and Delete deletes the *focused* tile.
- **The footer at 200 px**: below about 260 px the **New** button drops its
  label (the plus and the arrow stay, the tooltip says New), so the footer
  fits New, sync, trash, the **List | Grid** pair and sort.
- **The switch is an outline list / grid icon pair**, beside the sort
  chevron; the icon of the view that is on is filled, per the icon rule
  (a filled icon says a state is on).

## Drawn here, and confirmed (2026-10-12)

- **The background menu of the grid** is the tree's, with "here" meaning
  the folder shown: New note here, New from template here, New folder here,
  and **Export folder…** (**Export library…** at the library's root).
- **Up is disabled at the root, not hidden**, so the crumbs never move
  under the pointer.
- **The grid has no pinned block**: the pinned notes stay at the top of the
  list view; in the grid a pinned note is found by its badge, in its folder.
- **The breadcrumb's first crumb reads "Library"**, and a narrow sidebar
  folds the middle crumbs into **…**, which opens them as a menu.
- **The empty folder's words** on a phone: "Nothing in *folder* yet" and
  "Tap + to make a note or a folder here."

## After the mockups (the review of #727)

- **The walk is the pane's, not the grid's.** The mockups gave the grid a
  keyboard and left the list view without one; that is a gap, not a shape.
  Both views take the keyboard the same way — a click puts the cursor on
  the row or the tile, the arrows and Home/End/PgUp/PgDn move it, Enter
  opens, F2 and Delete act on it. The tree's left and right arrows close
  and open folders, which a flat grid has no use for.
- **A modified key is the app's.** Alt+Left/Right walk the notes' history
  and Ctrl+Shift+PageUp/PageDown the journal, even while the pane holds
  the cursor, so the walk claims the plain key or none (Alt+Up stays the
  grid's own way up).
- **The switch starts in the tree's selection every time**, not only the
  first: the grid's own folder is what it holds while it is the pane on
  screen, and the two never drift apart across switches.
