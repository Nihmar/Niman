# Home

A library's **Home** is a page of tiles: what you come back to every day —
today's journal entry, the tasks due, the notes you changed last — and
buttons for what you do every day.

## Where it is

Home is one of the destinations of the navigation: in the phone's bottom
bar, and in the desktop's rail (`Ctrl/⌘+6`, or *Go to: Home* in the
command palette). Move or hide it in **Settings → Navigation**, like any
other destination (see [settings](settings.md#navigation)). A library
still opens where it always did.

On a wide window the tiles sit on a grid of four columns, each tile one
to four cells wide and tall. On a phone they stand one under the other,
in an order of their own. An Android tablet in landscape gets the grid:
the shape follows the room on screen, not the system.

## Tiles

- **Actions** — buttons that run something the app already does, with
  what it needs set in advance.
- **Today's journal** — the first lines of today's [journal](journal.md)
  entry; a tap opens it. With no entry yet, *Write today's entry* makes
  it.
- **Tasks due** — the open tasks of `todo.txt`, due soonest first, in the
  order the Todo tab and the home-screen widget use. Check one off right
  there; a tap on a task opens the Todo tab.
- **Recently modified** — the notes changed last, newest first, the
  templates left out: the time for today, the day for older ones.
- **Pinned** — the notes whose frontmatter says `pinned: true`.
- **Journal calendar** — the journal's month, the days with an entry
  marked; a tap opens that day.
- **Top tags** — the twelve tags used most; a tap shows a tag's notes.
- **Random note** — a note picked at random, to read again; ↻ picks
  another.
- **Saved search** — a query of its own and its first results: words, or
  `key = value` as in [search](search.md).

The tiles read the library's index and the task list: they store
nothing. While the Home is on screen, a change in the library shows in
its tiles; a change made while you were elsewhere is there when you come
back.

## Editing the Home

On a wide window, **Edit home** at the top right turns the grid into its
editor, with the tiles to add on the right:

- **Move** a tile by dragging it, **resize** it by dragging its corner.
  The tile you drop keeps its place; a tile it lands on moves down.
  Tiles stay on the row you put them on, so a gap stays until you move
  something into it. On a touch screen, press a tile a moment before you
  drag it, so a plain swipe still scrolls.
- **⋯** on a tile moves or sizes it one cell at a time, without a
  pointer.
- **✕** hides a tile. It waits under *Hidden* in the panel, its settings
  as they were, and comes back from there.
- **Add tiles** lists every kind; one a Home shows once is offered only
  while it has none. A Home can hold several *Actions* and *Saved search*
  tiles.
- **⚙** on a saved search sets its name and its query.
- **Reset** puts the default Home back, after asking.

On a phone, the ✎ beside the date opens the same Home as a list: a handle
to drag each tile up or down, a switch to show or hide it, ⚙ for a saved
search's settings, and the tiles to add at the foot. Every change is kept
as you make it.

A tile hidden here is hidden on every device. A phone that should show
fewer tiles than the desktop uses **Only on this device**, at the top of
either editor: the device keeps its own copy of the Home, starting from
the one on screen, and its changes stay there. **This library** goes back
to the library's Home, after asking, and drops the device's copy.

## Where it is kept

The Home belongs to the library: `.niman/home.json`, one entry per tile,
so it is the same on every device and travels with
[sync](sync.md). A library whose Home you never changed shows the default
one and keeps no file. A device's own Home (*Only on this device*) is
kept on the device, with its other device settings.
