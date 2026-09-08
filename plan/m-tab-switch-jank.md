# Tab-switch jank (reported 2026-09-08)

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
painted through an offscreen pass (transparency). Build alone was taking
13 to 18 ms on Search, which is the tab the stutter was reported on: the
note tree of a 987-entry library was still being built while the search
screen was building too.

The body now uses a slide transition (`AnimatedSwitcher` + `SlideTransition`).
It avoids the offscreen pass of transparency, though it still builds
both bodies. If this still stutters on device, the motion will be removed
entirely.

## Tasks

- [x] **T-TS-01** Make the switch measurable. The shell logs every tab
  change, and the search screen logs its mount time and how long after it
  the source arrived. *AC: an exported log attributes a slow frame to a
  tab instead of leaving it to be guessed from timestamps.* (`36ac98d`)
- [x] **T-TS-02** Remove what the measurement blamed: the cross-fade, and
  the warm-up built on the theory it replaced. *AC: the reported stutter
  goes.* (`6ab0a8e`)
- [x] **T-TS-03** Put the motion back with a slide. Bit less pretty than a
  cross-fade, but cheaper: a translation is just a matrix on a layer that
  already exists. *AC: switching between tabs uses a horizontal slide.*
- [ ] **T-TS-04** The first Search open. Still slightly slow, once per
  run, as the query engine starts up.

## Verification

- `flutter test test/widget/tab_bar_test.dart` (green).
- `flutter analyze --fatal-infos` (clean).
- Artifact: [copist](file:///home/alessandro/Projects/Copist/build/linux/x64/release/bundle/copist).
