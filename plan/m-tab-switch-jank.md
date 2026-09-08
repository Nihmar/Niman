# The tab switch — what cost what

**Status:** the reported stutter is gone; T-TS-03 (put motion back with a
slide) is open · **Depends on:** nothing · **Evidence:** three device
logs, 2026-09-08.

## The symptom

Switching between the bottom tabs was smooth "except to and from Search,
which sometimes seems to stutter slightly" (user, 2026-09-08).

## What it turned out to be

Not the search source. That was the first theory: the first
`SearchScreen` asks the session for its source, which creates drift's
background connection, and doing that on the frame that animates the tab
in looked like a plausible stall. A warm-up was shipped (`137fa39`) to
move the work off that frame. **The measurement killed it:**

```text
17:53:43.353 [search] source warmed in 0ms (ready)
17:53:43.489 [shell] tab: todo -> search
17:53:43.490 [search.ui] mount: 0ms
17:53:43.497 [search.ui] source ready 6ms after mount
```

Six milliseconds. Worse, the warm-up did not warm anything:
`NativeDatabase.createInBackground` is lazy, and drift spawns the isolate
on the first real query rather than on creation. Both the theory and its
fix were wrong, and both are gone (`6ab0a8e`).

What the logs actually showed was the cross-fade between tab bodies. It
kept both of them built and painted for its whole 180 ms, and each was
painted through an opacity layer, which forces offscreen compositing per
frame. The signature is unmistakable — eight consecutive frames, raster 9
to 15 ms each, build near zero:

```text
17:43:45.271 slow frame: total 22.3 ms (build 1.1, raster 11.8, vsync 1.2)
17:43:45.271 slow frame: total 16.9 ms (build 2.5, raster 11.0, vsync 1.3)
  ... six more like it
```

Search was the worst case because that library holds 987 entries: its
note tree was still being built and composited while the search screen
was too. But slow frames followed switches to the other tabs as well (16
to 26 ms), so Search was the tip, not the whole thing.

The body now swaps outright, with no transition. Reported after the
change: "less than before", with a little slowness left the *first* time
Search opens — a one-off, which is a different thing from the switch.

## Tasks

- [x] **T-TS-01** Make the switch measurable. The shell logs every tab
  change, and the search screen logs its mount time and how long after it
  the source arrived. *AC: an exported log attributes a slow frame to a
  tab instead of leaving it to be guessed from timestamps.* (`36ac98d`)
- [x] **T-TS-02** Remove what the measurement blamed: the cross-fade, and
  the warm-up built on the theory it replaced. *AC: the reported stutter
  goes.* (`6ab0a8e`)
- [ ] **T-TS-03** Put the motion back, if it can be had cheaply. A fade
  would bring the cost back: transparency is what needed the offscreen
  pass. A slide should not — a translation is a matrix on a layer that is
  already drawn — though it still keeps both bodies built for the
  duration. Try a slide, take a log, compare the frames after a
  `tab:` line against the current build. *AC: with a slide in, no frame
  after a tab switch is worse than it is today with no animation; if one
  is, the slide comes back out and the switch stays instant.*
- [ ] **T-TS-04** The first Search open. Still slightly slow, once per
  run. Two candidates and nothing yet separating them: the first build of
  that screen, or the isolate drift spawns on the first real query. The
  `search.ui` lines already in place will say which, on a log taken
  around a first search rather than a first switch. *AC: the log says
  which, before anything is changed.*

## Notes for whoever picks this up

- The tab-switch line is `DEBUG [shell] tab: <from> -> <to>`. Frames are
  reported in batches, so several switches can share one timestamp;
  correlate on a window after each line rather than expecting one frame
  per switch.
- `vsync` in a slow-frame line is waiting, not work. Only `build` and
  `raster` are Copist's.
- A third option was raised and not taken: keeping all five tab bodies
  mounted (an `IndexedStack`) so a switch rebuilds nothing. It would make
  the switch nearly free and any animation affordable, but it changes
  behaviour — the search query and results would survive a switch, and
  five bodies stay alive. Worth revisiting only if T-TS-03 fails.

## Exit criteria

- Switching between tabs holds 60 Hz, with or without a transition.
- Whatever the first Search open costs is named rather than guessed at.
