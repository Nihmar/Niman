# Performance audit: the baseline (2026-10-21)

Part of #1135, the umbrella for a measured performance baseline. This file
records the scenarios, the machines, what was measured on each and how, the
numbers, and the prioritized list the next optimization is chosen from. Each
gap has an issue of its own; a row with no issue is under its bar.

It extends [desktop-performance.md](desktop-performance.md) (the desktop
cold start and the animation inventory, #62) and
[huge-notes.md](huge-notes.md) (the 246 MB note), and stands beside
[index-reconcile.md](index-reconcile.md) (the scan, a directory at a time).

## The bars

A frame is held to **16.7 ms**, a 60 Hz display's, and that is the bar
every "over budget" below means. A 120 Hz display gives 8.3 ms; the app's
own instrumentation already reports a pane's frame past half of 16 ms
(`FrameCost.frameBarMicros`), which is that budget, so the 120 Hz count is
given beside the 60 Hz one where the data has it. Which of the two a
device's numbers are read against is in its log now (below).

## The machines and the builds

**Linux (the reference host).** Intel Core i5-13400F (6 cores, 12
threads), 32 GB, Linux 7.2 (CachyOS); Flutter 3.47.2 stable, engine
`a804b26164`; commit `2f02d613` (this branch, after #1132's changes).
Every Linux number here is from `flutter test` — the test harness, JIT, no
GPU — because this pass ran with no display: the app itself was not
launched. The ratios carry; the absolutes do not compare with a profile
build's (`desktop-performance.md` has those for cold start).

**Android.** The owner's devices, read off the exported debug logs in
`logs/android/` (seven exports, 2026-10-12 to 2026-10-20): a tablet of
2560×1600 and the libraries named in each header. Those headers said
nothing else — not the version, the commit, the model or the refresh rate —
so the numbers are not tied to a build. **That is fixed by this pass**
(`2f02d613`, `lib/src/core/build_identity.dart`): an exported log now opens
with the version and build number, the channel, the build mode, the commit
(`APP_COMMIT`, from `scripts/niman.sh`, `scripts/niman.bat` and the release
workflow), the system and its cores, the device's maker, model and Android
version, every display's size, density and refresh rate, and whether
`NIMAN_FRAMES` was built in. The next device run is comparable; these are
the last ones that are not.

Only the four exports of 2026-10-12 were made with `NIMAN_FRAMES`; the
three after it were not, so they have no per-region frame lines and no
slow-frame log, only the action timings every build logs.

## The scenarios

Each is repeatable from this list; the command is what produced the
numbers below.

| # | Scenario | Linux | Android |
|---|---|---|---|
| 1 | Open a note (6 KB, 1.5 MB, 21 MB) | `NIMAN_PERF=1 flutter test test/perf/note_open_frames_test.dart`, `note_open_large_test.dart`, `source_edit_timing_test.dart` | `[editor] note open first frame` |
| 2 | Open the read pane beside it | `note_open_frames_test.dart`, `read_view_timing_test.dart` | `[preview] read pane first frame`, `read pane open` window |
| 3 | Type, save, reindex | `save_reindex_quiet_test.dart`, `source_keystroke_path_test.dart`, `edit_history_timing_test.dart` | `[save] saved`, `[save] reindexed`, `[history] snapshot`, `[indexer] rescan` |
| 4 | Tree: flatten, page, refresh | `tree_queries_perf_test.dart`, `test/widget/tree_child_cache_test.dart` | `[tree.ui] flatten` |
| 5 | Library open, first index, rescan | `index_scale_test.dart` (`NIMAN_SCALE=1000000` for the million) | `[session] open`, `[indexer] fullScan`, `first index` |
| 6 | Tab switch | — | `[shell] tab … first frame`, `tab … frames` window |
| 7 | Search | `index_scale_test.dart` (word search) | `[search.ui] results first frame` |
| 8 | Sync transfers | `sync_transfer_test.dart` | `[sync]` lines |
| 9 | Live editing: reveal, tables, columns, lists | `live_reveal_budget_test.dart`, `live_table_scroll_test.dart`, `columns_*_test.dart`, `list_drag_release_test.dart` | `[edit] frame` (`NIMAN_FRAMES`) |

Run the perf files **one at a time** (`flutter test -j 1 test/perf/`, or a
file per command): run together, the files share the CPU and four of them
miss their reference ceilings for that alone.

## Android: the baseline from the device logs

From the three exports of 2026-10-16 to 2026-10-20 (release and beta
builds, frames instrumentation off; 15 684 distinct lines; libraries of up
to 128 entries and a 1.5 MB note). Medians, 90th percentiles and maxima.

| Action | n | median | p90 | max | Over 16.7 ms | Over 8.3 ms |
|---|---:|---:|---:|---:|---:|---:|
| Note open, first frame | 60 | 7.2 ms | 16.1 ms | 20.6 ms | 4 | 28 |
| … of the 1.5 MB note | 7 | 9.1 ms | 20.6 ms | 20.6 ms | | |
| Note load (read and decode) | 60 | 20.5 ms | 38 ms | 81 ms | | |
| Read pane, first frame | 8 | 37.3 ms | 52.2 ms | 52.2 ms | 8 | 8 |
| Tab switch, first frame | 44 | 2.9 ms | 10.0 ms | 11.8 ms | 0 | |
| Tree flatten (≤ 31 rows) | 196 | 19 ms | 40 ms | 90 ms | | |
| Save, the write | 255 | 32 ms | 63 ms | 480 ms | | |
| Save, all of it | 255 | 53 ms | 116 ms | 486 ms | | |
| Reindex after a save | 262 | 34 ms | 59 ms | 995 ms | | |
| History snapshot, first save of a session | 29 | 85 ms | 131 ms | 219 ms | | |
| Full scan (≤ 128 entries) | 111 | 155 ms | 270 ms | 1 498 ms | | |

The frame windows (`FrameProbe`, 43 of them after tab switches and read
pane opens) counted 88 frames over budget in all, the worst build 49.5 ms
and the worst raster 24.8 ms. The background isolates peaked at **2** in
flight (`IsolateGauge`), in every export.

**The 2026-10-12 profile session** (`NIMAN_FRAMES` on, the 1 052-entry
`HelixNotes` library) is set apart: its slow frames — 391, median build
12.3 ms, the worst 285 ms — are dominated by a 6.8 KB note whose table was
measured again on every rebuild, 90–115 ms of layout a second while the
caret blinked. That was #722, fixed the same day (the theme handed to the
table cache by identity); `live_table_scroll_test.dart` holds it.

## Linux: the perf suite

`NIMAN_PERF=1 flutter test -j 1 test/perf/`, commit `2f02d613`. The
numbers each file prints, against the bar it holds.

| Area | Measurement | Number | Bar |
|---|---|---:|---:|
| Open | 1.5 MB note, the open's frame | 51.9 ms | 75 ms |
| Open | 1.5 MB note, the read pane's frame | 33.7 ms | 50 ms |
| Open | 21 MB note, to the first frame | 853 ms | 5 000 ms |
| Open | 200 KB note, cold (scan + tokenize) | 38.2 ms | 239.5 ms |
| Open | height map over 1 M lines, first screen | 0.1 ms | 5 ms |
| Read | first visible content: 50 KB / 200 KB / Geometria | 114–125 / 71–72 / 71–75 ms (was 341 / 83 / 74, #1140) | 250 / 120 / 120 ms |
| Type | a keystroke, data layers | 0.205 ms | 0.507 ms |
| Type | a keystroke to its frame, 20 000 lines | 6.86 ms | ×1 of 400 lines |
| Type | the reveal frame, 20 000 lines | 3.14 ms | 3 ms |
| Type | undo history, 160 000 keys typed / deleted | ×1.3 / ×5.2 of 20 000 | ×14 |
| Save | 1.5 MB, the second of two saves / the first | 0.94× | 2× |
| Save | 1.5 MB, its reindex | 57 ms | — |
| Tree | a page of 2 001 in a 200 000-row root | 13.2 ms | — |
| Tree | pinned notes over 200 000 rows | 0.45 ms | — |
| Index | 50 000 notes: open to ready / first tree read / word search | 115 / 1 / 2–9 ms | — |
| Index | first full scan of 2 000 notes on disk / rescan unchanged | 3 110 / 54 ms | — |
| Live | a fitted table scrolled down / up, median step | 12 / 10–11 ms (was 18–20 / 11, #1141) | 16 ms |
| Live | columns keystroke / read layout / scroll frame | 24.7 / 28 / 1.9 ms | ×1.5 / ×1.3 / ×1.5 |
| Live | list drag, a held frame at 5 000 items | 12.1 ms | ×1 of 500 |
| Sync | large download, busy isolate: the isolate's own work left it | 98 % (old path 29 %, #1142) | 90 % |
| Sync | large upload, busy isolate | 97–99 MiB/s (old path 24–25) | ×2 of the old path |
| Links | rewrite after 100 000 files moved | 389 ms | 1 000 ms |
| Spell | dictionary load / a screen of 60 lines | 7.6 / 0.95 ms | — / 12 ms |

Three bars did not hold on this host, on `main` as on the #1132 branch.
None was the code; each now holds, run twice, alone:

- `read_view_timing_test.dart`, the 50 KB fixture's first content: 341–348
  ms against 250. It was the file's first case, and its warm-up — a heading
  and a paragraph — left KaTeX, the table and the highlighter cold. Warmed
  on one block of each kind its first screen holds, it reads 114–125 ms
  (#1140).
- `live_table_scroll_test.dart`, the median step scrolling down: 18–20 ms
  against a 60 Hz frame. The down leg was the first a file scrolls and paid
  the JIT: a second round of the same note reads 7–11 ms, and a CPU profile
  of the steady state is the surface's rebuild per step, flat, 6.0 ms down
  against 5.4 up. Measured after a round thrown away, 12 ms down and 10–11
  up (#1141).
- `sync_transfer_test.dart`, a large download with the isolate busy: the
  bar asked twice the old path's speed, which a download — no hash, the
  disk's speed on either path — cannot show. What the worker buys a
  download is the isolate: the old path kept its speed by taking it, and
  the load it ran (the app's frames) got 29 % of its ticks; the worker
  leaves it 98 %. The download is held to that share and to its idle speed
  (#1142).

## The million

`NIMAN_PERF=1 NIMAN_SCALE=1000000 flutter test test/perf/index_scale_test.dart`.

All seven of its cases pass their bars. A million notes in one index
(671 MB on disk, built in 84 s by the test's own insert) open to ready in
**103 ms**, and every read the app makes of them stays where a frame can
wait for it:

| Read | 50 000 notes | 1 000 000 notes |
|---|---:|---:|
| open to ready | 115 ms | 103 ms |
| first tree read / top level / a folder's children | 1 / 0 / 12 ms | 5 / 5 / 5 ms |
| the tree with one folder open | 9 ms | 12 ms |
| word search, one hit / every note | 2 / 9 ms | 2 / 27 ms |
| the notes of a tag | 9 ms | 133 ms |
| a first full scan of 2 000 notes on disk / an unchanged rescan | 3 110 / 54 ms | 2 850 / 54 ms |

The notes of a tag is the one read that grows with the library — 15× for
20× the notes — and it is a list a screen asks for, not a frame's work.
A first index of a million notes on Android's FUSE is not measurable here;
it is part of #1145.

## I/O on the UI isolate

The rule is that no disk call runs on the UI isolate: on Android each
`statSync` or `listSync` is a round trip through FUSE. This pass counted
192 synchronous file calls in 58 files of `lib/`, most of them inside an
`Isolate.run`. #1143 moved the rest: since `4b423040` every one runs on a
background isolate, and `test/unit/ui_isolate_io_test.dart` lists the files
allowed one with the isolate each runs it on, so a new one elsewhere fails
the suite. Three of the calls it moved were more than a stat:

- **The trash, on every delete.** The manifest's upkeep stat-ed every item
  it names, twice: a trash of a thousand items cost two thousand round
  trips a delete. One asynchronous listing replaces them.
- **The watcher's batch.** Each changed path was stat-ed twice before its
  sync hint was queued; a folder copied in is hundreds. The batch is
  probed at once, on an isolate.
- **Every atomic write.** Its stamp was a `statSync`, and the free-name
  search of a create, a rename or a trash stat-ed every candidate.

The very_good lint `avoid_slow_async_io` asks for the synchronous calls,
and four places carried an `ignore` against it; it is off, with the
platform rule as the reason. The library picker's reachability check was
a `statSync`, which never throws: an unreachable folder passed it, and now
does not.

## Background work

The logs show at most two background isolates at once. The scan's content
reads, the saves' writes and the reindexes run one per note, and a reindex
is never beside a write of its note (#1132). The tree's warm-up at library
open read the whole root — every row, sent to the UI isolate — to prepare a
statement the tree has not run since it pages (#1064): 850 ms for a root of
200 000 notes on this host. It now prepares the page the first flatten
reads (#1135, this pass).

## Memory

#511 owns the desktop's. For Android (#1144) this pass set what can be set
off the device and made the device run measure the rest.

**A million notes cost the open nothing.** The scale test now measures the
resident memory a library's open adds up to its first tree read: **1 MB at
fifty thousand notes, 2 MB at a million**, on the reference host. The tree
pages and the index stays on disk, so the open is constant in the
library's size, and that is the ceiling `index_scale_test.dart` holds: 32
MB under `NIMAN_PERF`, which an open that brought the rows into Dart (a
million notes are hundreds of MB there) fails many times over. A first
full scan of 2 000 notes on disk adds 8 MB, an unchanged rescan nothing.

**Every action's log line carries the memory.** The first-frame line of
each timed action (a note's open, the read pane, a tab, a search result,
a note's close), the frame window's summary, the library's open and every
rescan now end with `rss <now> MB (peak <max>)`. An exported log of the
#1145 session therefore gives each scenario its memory beside its time,
on a named device and build — opening the 1.5 MB note, the read pane
beside it, five tabs, a first index. The breakdown the log cannot give
(Dart heap, native heap with the bitmaps and PDFium, graphics) is
`adb shell dumpsys meminfo dev.niman.niman.beta`, taken at the same
points; Android Studio's profiler on the profile build shows the isolates'
peaks. Those numbers land here with the device run.

## Third-party surface

`flutter build apk --release --flavor beta --analyze-size
--target-platform android-arm64`: 92.5 MB, of which the native libraries
are 85 MB.

| Library | arm64-v8a | x86_64 |
|---|---:|---:|
| `libapp.so` — the Dart AOT: `package:niman` 12 MB, `flutter` 4 MB, `highlight` 1 MB, `katex_dart` 340 KB, `timezone` 264 KB, `html` 241 KB, `pdfrx` 193 KB, `drift` 188 KB | 28.9 MB | — |
| `libflutter.so` | 11.7 MB | — |
| FFmpeg (`libavcodec`, `libavfilter`, `libavformat`, `libavutil`, `libswscale`, `libswresample`, `libffmpegkit`, …) | ~15 MB | ~16 MB |
| `libpdfium.so` | 6.4 MB | — |
| `libwhisper.so` | 2.9 MB | 3.0 MB |
| `libsqlite3.so` | 1.7 MB | — |
| `libcnativeapi.so` | 1.6 MB | 1.5 MB |

An arm64-only build still carried **20 MB of x86_64 libraries**: the
plugins with prebuilt natives package every ABI they have, whatever
`--target-platform` asks. And the release workflow passed none, so the
release shipped the universal APK, 142.9 MB, with a whole x86_64 copy of the
Dart snapshot and the engine besides.

**After #1146.** A release build drops `x86_64` at packaging, as every build
already dropped `armeabi-v7a`, and the scripts and the release workflow build
for `android-arm64` alone. The beta APK is **71.5 MB**, its native libraries
`arm64-v8a` only (65.1 MiB uncompressed): 21 MB under the arm64 build above,
71 MB under what a release shipped. x86-64 is an emulator's ABI, and a debug
build keeps it, so `flutter run` still installs there; a release no longer
installs on an x86-64 device, a decision recorded in
`docs/user/platforms.md`. What FFmpeg's 15 MB is there for, and what each
plugin costs at startup, is the dependency inventory, #1136.

## What #1132 changed

The device log of 2026-10-20 is the before; the numbers after are this
host's until the next device run.

| What | Before | After |
|---|---|---|
| A reindex beside the next save of a 1.5 MB note | the save's write 123 → 480 ms | the reindex waits 2 s for the note to be quiet, and a save cancels one still reading |
| A reindex due while its note's save ran, and that save failed | dropped: the index stayed on the old text | owed, and run once the chain is idle |
| A note's title typed: the tree's refresh | every open folder read again, 21–35 ms for two | the note's folder and the pinned list alone |
| Opening a 1.5 MB note, its first frame | the whole note's block scan in it: 92 ms here, 20.6 ms on the tablet | its top 512 lines: 52 ms here |
| Opening the read pane | the frontmatter's YAML parsed at every build | parsed once per block text |
| Library open | the root's every row read to warm a statement | the first page's statement |

## The prioritized list

Ordered by what a user feels on the device, then by how much of the app
it reaches.

1. **A device run with `NIMAN_FRAMES` on the tablet** (#1145): a paced
   session through scenarios 1, 2, 4 and 6 on a profile build, the log
   exported with the new header. The read pane's first frame (37 ms
   median, every sample over) and the tree's flatten (19 ms median, 90 ms
   worst) are the two actions that miss the budget at the median; neither
   can be split into build, layout and paint without that run. Everything
   after this item is ordered by guess until it lands.
2. **The read pane's first frame** — 8 of 8 over 16.7 ms on the device.
   This pass took the frontmatter's parse out of it; the rest is the
   source pane re-laying its lines out at the new width and the read pane's
   first build, which the device run has to split.
3. **The history snapshot of a session's first save**: 85 ms median, 219
   ms worst, the same for 10 KB as for 1.5 MB — two flushed writes, the
   version and the manifest. The snapshot line now says which (#1132);
   the fix waits for the device's answer.
4. **Memory on Android** (#1144): the per-action numbers from the device
   run's log, and the `dumpsys` breakdown of the scenarios beside them.
   The million-note open is held (2 MB).
5. **FFmpeg's 15 MB** (#1136): what it is there for. The foreign ABI is
   gone (#1146, 142.9 → 71.5 MB).

Done in this pass's second round: the three bars that did not hold
(#1140, #1141, #1142 — none was the code), the synchronous calls on the UI
isolate (#1143) and the APK's x86_64 libraries (#1146).
