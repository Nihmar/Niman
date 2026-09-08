# The tab switch — what cost what

**Status:** fix shipped, awaiting device log · **Depends on:** nothing ·
**Evidence:** three device logs, 2026-09-08; `copist-debug-log-2026-09-08-212050.449.txt`.

## The symptom

Switching between the bottom tabs was smooth "except to and from Search,
which sometimes seems to stutter slightly" (user, 2026-09-08).

## Current Investigation

We initially thought the cross-fade and the search warm-up were the issue.
A slide transition was tried but rejected for being "ugly".
We are now back to the **cross-fade** with significantly more logging to identify
exactly what is taking time during the transition.

Suspects:
1.  **Double Build:** During cross-fade, both outgoing and incoming tab bodies are built.
2.  **NoteTree Flattening:** The file tree (if it has many expanded folders) might be
    taking time to flatten even if it only materializes visible rows.
3.  **Search Screen Initial Build:** The search screen might have a heavy first build.

## Fix (T-TS-07)

The `212050` log settled it: `mount: 0ms`, `build: 0ms`, `source ready`
4-8 ms, `flatten` 4-8 ms on 13 rows — yet frames with `build` 14-17 ms
plus `raster` 12-21 ms right after `tab: ... -> search`. The instrumented
`build()` methods only time the widget constructor; the real cost is the
element inflate (a `TextField` + `SegmentedButton` tab built from scratch)
plus the `AnimatedSwitcher` cross-fade keeping both bodies under a
transparency layer for 180 ms, with a second `setState` landing mid-fade
when the source arrives.

* Tab bodies mount lazily on first visit and stay mounted
  (`TabBodyStack`: `Stack` + `Offstage` + fade-in only). Switches flip
  visibility; query, results, and scroll survive, by choice.
* The source-ready `setState` waits 200 ms so it lands after the fade.
  A query typed in the meantime still works (`_runSearch` acquires the
  source on demand).
* Tags mounts once inside the search slot for the same reason.
* The FAB scrim wraps only the Files slot, always (never toggled around
  the stack): `_withFabScrim(enabled: _tab == files)` swapped the stack's
  parent between a `Stack` and the bare child, reparenting and remounting
  every body on each Files switch — the `213516` log proved it (mount
  bursts on Files-involved switches, plain rebuilds otherwise). Hiding via
  `Offstage` skips the anchor lookup while Files is offstage.

## Tasks

- [x] **T-TS-01** Make the switch measurable. The shell logs every tab
  change, and the search screen logs its mount time and how long after it
  the source arrived. (`36ac98d`)
- [x] **T-TS-02** Revert to cross-fade and add detailed logging.
  We want to see the build times of `SearchScreen` and `NoteTree` during the
  transition frames.
- [ ] **T-TS-05** Analyze new logs. Export a log during several switches
  (especially to Search) and correlate `build` durations against the `tap tab:`
  and `transition starts` markers.
- [ ] **T-TS-06** Fix the identified bottleneck. If it's the tree, maybe
  cache the flattened list better; if it's the search build, optimize it.
- [x] **T-TS-07** Keep tab bodies alive and defer the source-ready rebuild
  (see Fix above). *AC: `mount`/`flatten`/`source ready` only on the first
  visit, no `dispose` on switch, and no slow frame with `build` > 12 ms in
  the window after a `tap tab:` line — compare against `212050`.*
  Verified on `214413` for pure tab switches (first Search entry at
  21:44:08 shows zero slow frames; the deferred rebuild lands at
  +213-224 ms every time). Two follow-ups below.
- [ ] **T-TS-08** Keep the tab shell alive under the fullscreen note. The
  `214413` log shows every `build` > 12 ms frame now sits within ~200 ms
  of a note open/close tap (worst: `build` 30.7 ms remounting the whole
  stack on return from the quick note at 21:44:10.536): opening a note
  swaps `tab-shell` out via the outer `AnimatedSwitcher`, disposing all
  five kept-alive bodies, and closing it remounts them all at once. The
  quick-note tile opens the note directly whenever it is set, so that
  loop pays the full remount every time. Fix sketch: a `Stack` overlay —
  tab-shell always mounted (`Offstage` while a note is open), the note
  pushed over it and still disposed on close. *AC: opening/closing a note
  logs no `tree.ui`/`search.ui` mount; the return shows no slow frame
  with `build` > 12 ms.*
- [ ] **T-TS-09** Name the 2-frame residue after pure switches. `214413`
  shows one pair (~19 ms, `build` ~15 ms, no mounts) 176 ms after
  files→settings at 21:44:11.485, plus a lone raster blip a second after
  the last tap. Small and intermittent; measure around the fade end and
  the deferred hidden-search rebuild before changing anything.

## Notes

- The tab-switch starts at `DEBUG [shell] tap tab: <to>`.
- `tree.ui` and `search.ui` now log their build and logic (e.g. `flatten`) durations.
