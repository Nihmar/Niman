# The tab switch — what cost what

**Status:** investigation ongoing; cross-fade restored with extra logging · **Depends on:** nothing · **Evidence:** three device
logs, 2026-09-08.

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

## Notes

- The tab-switch starts at `DEBUG [shell] tap tab: <to>`.
- `tree.ui` and `search.ui` now log their build and logic (e.g. `flatten`) durations.
