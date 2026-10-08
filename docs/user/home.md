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

## Where it is kept

The Home belongs to the library: `.niman/home.json`, one entry per tile,
so it is the same on every device and travels with
[sync](sync.md). A library whose Home you never changed shows the default
one and keeps no file.
