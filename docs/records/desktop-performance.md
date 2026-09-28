# Desktop performance and animation: the baseline (2026-09-28)

Part of #62, the desktop performance and animation audit. This file records
what the app does with animation **today**, read off the code, and the
baseline numbers that could be taken on this host: the app's own frame
instrumentation in a profile build, and the two integration tests that
already drive the real app on Linux.

It is the reliable half of the audit, written down first. **The
per-scenario driver #62's "Measure" list asks for is not in this pass** —
it is named at the end of this file as the follow-up, with what it would
have to drive.

## The machine

| | |
|---|---|
| CPU | Intel Core i5-13400F, 12 threads |
| GPU | AMD Radeon RX 9050/9060 XT (Navi 44) |
| RAM | 32 GB |
| Screen | 1920×1080 at 59.96 Hz — a 16.7 ms frame |
| Session | Linux; X11 through XWayland (`DISPLAY=:0`) |
| Renderer | the app's own line, this run: `Using the Impeller rendering backend (OpenGLESSDF)` |
| Flutter | 3.47.2 stable, engine `a804b26164` |

The XWayland detail matters for what follows: the app's frames are handed to
a compositor, so a raster number here is not a raster number on a native
X11 or a Windows desktop.

## How the numbers were taken

- **The app's own instrumentation** — `lib/src/core/frame_cost.dart` (the
  `[edit]`/`[read]`/`[shell]` per-region frame lines), `lib/src/core/frame_log.dart`
  (`logNextFrame`, `FrameProbe`) and `_reportSlowFrames` (`lib/main.dart`),
  all behind `--dart-define=NIMAN_FRAMES=true`, in a **profile** build of the
  testing channel:

  ```
  flutter build linux --profile \
    --dart-define=NIMAN_FRAMES=true --dart-define=APP_CHANNEL=testing
  ./build/linux/x64/profile/bundle/niman        # DISPLAY=:0
  ```

  The app mirrors its log to
  `~/.local/share/dev.niman.niman-testing/niman-log.txt`; the numbers below
  are read from that file (2026-09-28 15:19:19 run; a second sample from the
  11:26 run in the same file).
- **The integration tests**, which drive the real app on Linux:

  ```
  flutter test integration_test/app_boot_test.dart -d linux
  flutter test integration_test/sync_e2e_test.dart -d linux
  ```

## Baseline: cold start to usable

A profile build (AOT), the library on disk resumed at startup — 7 files,
5 directories. The wall clock is from process exec (the shell's clock) to
the line the app wrote itself:

| the app's own line | from exec |
|---|---|
| `[log] log file attached` (engine and VM up, `main` running) | 0.53 s |
| `[tray] tray ready` | 0.62 s |
| `[window] window controller ready` | 0.71 s |
| `[session] index warm-up: 88 ms` | 0.71 s |
| `[session] open complete: ready root=…` | **0.72 s** |
| `[tree.ui] flatten: 13ms (9 rows, 1 pinned)` | 0.74 s |
| `[spellcheck] hunspell ready … in 17 ms` | 0.75 s |
| `[editor] note loaded: …/Geometria 1.md (931945 chars, 13 ms)` | 0.77 s |
| `[editor] note open first frame (931945 chars): first frame 2.46ms after call` | 0.78 s |
| `[read] first content: 1 blocks, 1 built, 71ms after the view was created` | 0.88 s |

So: **the library is usable 0.72 s after the process starts**, and with a
931 945-character note open in it the whole cold start reaches its first
painted note at 0.78 s and the read pane's first content at 0.88 s, on this
host — 0.53 s of the 0.72 s being the engine and the Dart VM, which is not
the app's work.

`[session] index warm-up: 88 ms`, the tree's first flatten 13 ms for 9 rows,
hunspell's dictionary 17 ms, and the note's 931 945 characters read in 13 ms
are on the startup path as well; the earlier run in the same log read the
same library with a colder cache and had **109 ms** for the tree's flatten
against today's 13 ms, which is what a first-time cost looks like.

## Baseline: frames

The app logs a line only for frames that miss the 16 ms budget
(`_reportSlowFrames`, and `FrameCost`'s per-region lines for the frames a
pane's own share misses) — it deliberately logs nothing about the frames
that are fine, because a line per frame charges the frames it measures and
fills the log buffer in minutes. What follows is therefore *the jank*, not
the frame rate.

In the 15:19 run, the whole 31-second life of the process:

| | |
|---|---|
| slow frames | **2** |
| the smaller | total 17.5 ms (build 6.8, raster 6.4, vsync 4.2) |
| the larger | **total 112.1 ms (build 105.4, raster 3.9, vsync 2.7)** |
| when | both inside the half second in which the library and its note open |
| after that | nothing: the app sat idle for 25 s with no frame over 16 ms |

The largest frame of the run is **112.1 ms, 105.4 ms of it the UI isolate's
build — 6.7× the 16.7 ms frame** — and it lands on the cold start, not on an
animation and not while the app is in use. The pane lines in the same second
are the read pane's first content: `[edit] frame: edit 0.0 ms, build 0.0 ms,
layout 42.3 ms, paint 0.2 ms (42.5 ms here)`.

A second run, written into the same log file earlier the same day (11:26, a
second note of 668 characters open beside the geometry one), read **three**
slow frames: 22.3, 64.9 and 166.8 ms, all in the opening second.
Both runs agree on the shape — a handful of long frames while the library
and its notes are read and laid out, then nothing.

Two things this baseline is not:

- It is not per scenario. It says the cold start has one big frame in it; it
  does not say what a tab switch, a scroll or search-as-you-type cost, which
  is exactly what #62's measure list asks for (see *The follow-up*).
- It is a *profile* build's numbers and a single run each. The engine's
  timings arrive in batches and a cold process plans differently from a warm
  one.

## Baseline: the integration tests

Both run the real app on a real device, debug builds:

| test | tests | wall clock | what it drives |
|---|---|---|---|
| `integration_test/app_boot_test.dart -d linux` | 2 | **2 s** | cold boot to the open-library screen, and to the welcome deck with an unanswered Markdown question |
| `integration_test/sync_e2e_test.dart -d linux` | 1 | **18 s** | the WebDAV flow end to end: a real library on disk with the real `LibraryController`, a note written, the destination set from the settings screen, a sync from the icon, then a conflict resolved in the merge screen |

The 2 s and the 18 s include the app's own boot, its databases, the UI's
first frames and, in the sync case, a loopback WebDAV server in the same
process. The sync test needs a display; here it runs against `DISPLAY=:0`
with the session's `XAUTHORITY`. Neither test reads the frame
instrumentation, so neither says what its frames cost — the flow, not the
frame data.

## The animation inventory

Every animated transition in the app, from the code. `file:line` is the
site; the duration and curve are the ones written there. The rating is what
the code and the numbers above let me say, and **"a guess" says so**: no
scenario here was measured per animation, so a rating is a reading of the
code, not a measurement, unless the row says otherwise.

| # | where | what | duration | curve | trigger | rating |
|---|---|---|---|---|---|---|
| 1 | `ui/tab_body_stack.dart:46` | `AnimatedOpacity` over a kept-alive tab body, `TickerMode` gating the hidden ones | 180 ms | easeOutCubic | a tab switch (phone layout) | smooth — paint-only, on kept-alive bodies; the outgoing body goes `Offstage` in the same frame, so the fade is entry-only (a guess) |
| 2 | `ui/shell_layout.dart:256`, fade constant `ui/shell.dart:1038` | `AnimatedSwitcher` + `FadeTransition`: the full-screen note page over the tab shell | 220 ms | easeOutCubic | opening/closing a note (phone) | smooth (a guess); the shell's own hide waits the fade out (`shell.dart:1017`) |
| 3 | `ui/note_view.dart:2333` | `AnimatedSize` — the toolbar growing/shrinking as preview mode flips | 200 ms | easeOutCubic | preview toggle (phone; on desktop the toolbar is a fixed row) | smooth (a guess): one row's height, `topCenter` |
| 4 | `ui/new_item_fab.dart:137` | `AnimatedSwitcher` — the `+`/`×` glyph | 150 ms | the default fade, linear (`AnimatedSwitcher.defaultTransitionBuilder` is a `FadeTransition`) | FAB menu opened/closed | smooth (a guess) |
| 5 | `ui/new_item_fab.dart:181` | `AnimatedScale` + `AnimatedOpacity` — the six mini FABs revealing | 150 ms | easeOut (scale) and linear (opacity: no curve is passed) | FAB menu opened/closed | smooth (a guess); they stay in the tree at scale 0, so no layout jump |
| 6 | `ui/new_item_fab.dart:252` | `TweenAnimationBuilder` + `CustomPaint` — the scrim circle growing from the FAB over the body | 200 ms | easeOut | FAB menu opened/closed | unmeasured; the only animation here that repaints a full-screen area each frame (a guess — a circle over the body, `Colors.black26`) |
| 7 | `ui/kinds/list_note.dart:105` | `AnimationController` → `SizeTransition` + `FadeTransition` — the add-item row stepping aside | 180 ms | easeOutCubic / easeInCubic (reverse) | a list row entering in-place editing | smooth (a guess): a one-row subtree |
| 8 | `ui/kinds/list_note.dart:204` | `ScrollController.animateTo`, then a `jumpTo` correction if the estimated extent moved | 200 ms | easeOutCubic | a list item added | smooth then a snap at the end by design (a guess) |
| 9 | `ui/kinds/list_item_row.dart:233` | `AnimatedContainer` — drop-target tint and the row's indent | 120 ms | linear (the implicit animation's default; no curve is passed) | a row dragged under another, or re-indented | smooth (a guess) |
| 10 | `ui/shell_tree_footer.dart:77` | `PopupMenuButton.popUpAnimationStyle` — the New menu | 120 ms | easeOut | the New menu opened | *deliberately shortened* from Material's 300 ms: "a desktop menu should appear, not perform" |
| 11 | `ui/shell_tree_footer.dart:191` | `AnimatedRotation` — the sort chevron turning | 180 ms | linear (implicit default) | sort order toggled | smooth (a guess) |
| 12 | `ui/marquee_text.dart:64` | `AnimationController` + `Transform.translate` inside a `ClipRect` — an overflowing name sliding and resting | one pass = 2×1200 ms pauses + 2×travel, travel from the text's width (clamped 200–20000 ms); 3 passes then rest | linear with rests (`_offsetAt`) | a title/label wider than its room (tree, title bar, tab, list row) | unmeasured; transform-only, but a clip per frame and it runs for as long as the 3 passes take (a guess) |
| 13 | `ui/sync/spinning_sync_icon.dart:25` | `AnimationController.repeat` → `RotationTransition` | 1400 ms a turn | — | a sync in flight | smooth (a guess); it holds still under reduced motion |
| 14 | `ui/note_tab_bar.dart:122` | `Scrollable.ensureVisible` — the active tab revealed in a scrolling row | 150 ms | ease (the parameter's default) | a tab activated, or a note opened | smooth (a guess) |
| 15 | `ui/settings_area.dart:80` | `Scrollable.ensureVisible` to a searched row, plus a highlight that **snaps** on and off | 300 ms (scroll, ease); the flash 2 s, no fade | ease | a Settings search result opened | the scroll is smooth; the flash is a snap (a guess) |
| 16 | `editor/typewriter_scroll.dart:28` | `animateTo` — the note gliding so the caret's row is centred | 100 ms | easeOut | typewriter mode, caret moving to a new row | smooth by design ("short enough never to fall behind typing") |
| 17 | `ui/welcome/welcome_screen.dart:146` | `AnimatedSwitcher` — deck pages | 200 ms | the default fade, linear | Next/Back on the first-run deck | smooth (a guess) |
| 18 | `ui/floating_window.dart:52` | `RawDialogRoute` + `FadeTransition` — a settings panel from the rail | 120 ms | linear (the route's own) | a library window opened | smooth, deliberately short (a guess) |
| 19 | `ui/palette/command_palette.dart:92` | `showGeneralDialog`, no transition builder → the framework's fade | 120 ms | linear | the palette (Ctrl+P, two-finger swipe) | smooth, deliberately short (a guess) |
| 20 | `ui/tour/tour_overlay.dart:49` | `PageRouteBuilder` with **no** `transitionBuilder` | 150 ms declared | — | the tour started | nothing animates: the overlay appears instantly, and the 150 ms only bounds the route's own animation — the one place whose duration reads as a promise the code does not keep |
| 21 | `ui/kinds/audio_composer.dart:123`, `ui/kinds/audio_note.dart:184` | `ScaleTransition` over a `TweenSequence` 1 → 1.12 → 1 — the record button's swell when the microphone goes live | 700 ms, once | weights 0.4/0.6 | recording started | smooth (a guess) |
| 22 | `ui/kinds/audio_recording_bar.dart:46` | `AnimationController.repeat(reverse)` → `FadeTransition` — the "breath" of the recording bar | 900 ms | linear (the `Tween`'s own) | recording | smooth (a guess) |
| 23 | `ui/kinds/audio_note.dart:481` | `AnimatedOpacity` — the empty hint leaving as the first bubble arrives | 200 ms | linear (implicit default) | the first audio row | smooth (a guess) |
| 24 | `ui/kinds/audio_chat_list.dart:96` | `animateTo` to the bottom | 300 ms | easeOut | a row added | smooth (a guess) |
| 25 | `ui/kinds/audio_chat_list.dart:107` | `AnimatedList` with `FadeTransition` + `SizeTransition` — a bubble arriving or leaving | the framework's 300 ms insert/remove default | easeOut | a row inserted/removed | the list's own insert animation (a guess) |
| 26 | `ui/kinds/audio_clip_bubble.dart:182` | `AnimatedSwitcher` — the play/pause glyph | 150 ms | the default fade, linear | a clip started/paused | smooth (a guess) |
| 27 | `ui/kinds/audio_composer.dart:148`, `:179` | `AnimatedSwitcher` — the mic/send/stop glyph, and the composer ↔ recording bar swap | 150 ms and 200 ms | the default fade, linear; `ScaleTransition` for the glyph | typing, recording, saving | smooth (a guess) |
| 28 | the framework's defaults, **not overridden** (`lib/src/app.dart:76` sets only `theme`, `darkTheme`, `themeMode`) | any `Navigator.push`: `ZoomPageTransitionsBuilder` on Linux and Windows; a dialog 150 ms; a modal sheet 250 ms in / 200 ms out; a snack bar 250 ms; a popup menu 300 ms (shortened at #10); the indeterminate progress indicators' own loops | 450 ms for a page push | framework's own | every settings screen, the trash, history, an epub, a diff | unmeasured, and the one I would measure first: it is by far the longest animation in the app, and the zoom transition rasterises the outgoing page into a snapshot to run (a guess) |
| 29 | `markdown/render/content_clamp_physics.dart:23` | deliberately **no** animation: a position left past the end by an estimate is put back on the end at once, where the platform's physics would spring it back | — | — | a jump landing on a changed extent (Ctrl+End, an outline jump) | this is the "snap" the design asks for; the platform's half-second spring is what it replaces |
| 30 | scroll and fling | the platform's own ballistic simulation, `ClampingScrollPhysics` on Linux/Windows (the app overrides no `ScrollBehavior`) | — | — | wheel, trackpad, drag, fling | the one place a "missing" animation would be wrong: a fling without its simulation is not a scroll |

**30 places**, of which 29 are animations and one (#29) is the deliberate
absence of one.

### What snaps today

Snapping is the app's default, and for the big surfaces it is deliberate —
`tab_body_stack.dart` says why in so many words ("switching tabs only flips
visibility and fades the incoming body in, instead of disposing one `State`
and inflating another mid-animation"). Everything below changes in one
frame, with no animation at all, and it is verified in the code:

- **A tab switch on the desktop.** The wide layout's slots are `Offstage`
  (`shell.dart:2490`), so Search, Settings, Todo and Files appear instantly;
  the fade at #1 belongs to the phone's stack. The tab body changes and only
  the incoming one is drawn, in that frame.
- **The editor ↔ preview flip** (`note_view.dart:2265`): both panes stay
  mounted and one is `Offstage`; the preview appears in the frame the flag
  flips, keeping its parse and its scroll position.
- **`source` ↔ `live`** (`note_view.dart:2269`): a different `KeyedSubtree`
  key in the same slot — an instant remount of the pane.
- **One note for another** in a pane, and the pane's own memento restore.
- **The tree**: selecting a row, expanding a folder, the rows a scan
  refreshes, the sort flip's *content*. (The chevron animates; the rows
  under it do not.) The first flatten of 9 rows took 13 ms here and 109 ms
  on the colder run — the rows arrive, they do not animate in, and when the
  arrival itself is late an entry animation would only make it later.
- **Search results**, tags, the outline, the history list, the todo rows:
  the list appears when the (debounced, 150 ms) query returns.
- **The sidebar toggle, the dock panes (outline, tags, history) opening,
  Zen mode** — pane geometry changes in one frame; there is no
  `AnimatedSize`/`AnimatedContainer` anywhere in `shell.dart`.
- **A theme change** — light/dark or a new palette rebuilds `MaterialApp`,
  and no `AnimatedTheme` is in the tree: the whole window changes colour in
  one frame.
- **A window resize**, and the phone/desktop breakpoint crossing.
- **The caret** (`markdown/render/source_view.dart:2698`): a 550 ms timer
  toggles it, so it blinks by snapping, not by fading.
- **Table hover** (`source_view.dart:3132`, `:3140`): the table's handles are put
  on the pointer's table and cleared 200 ms after it leaves — both in one
  frame, no fade.
- **Drag and drop of a note or a tab**: the feedback follows the pointer and
  the drop marker appears; the only animated part is the list row's tint
  (#9).
- **The dialog, the sheet, the menu and the page push** are the framework's
  own (#28) — the app adds no animation to them and no override of them.

## The policy — a proposal for the maintainer

Not a decision taken; a reading of the code and the numbers above. The issue
asks which interactions should animate and which should stay instant:

1. **Anything that changes what the page *is* stays instant**: a tab switch
   (desktop), the editor ↔ preview flip, `source` ↔ `live`, one note for
   another, the dock panes, the sidebar, Zen, a theme change. All of them are
   the writer's own act, the content that arrives is the feedback, and a
   100–450 ms wait between the intention and the page is a tax charged on
   every use of the app's most-used controls.
2. **Animation is for the small, self-contained change**, where it says what
   happened without the page waiting: a glyph inside a button (FAB, audio),
   a row stepping aside, a chip revealed in a row, a menu, a palette or a
   dialog appearing at ≤150 ms, the sort chevron, the typewriter glide. That
   is what most of the inventory above already is — the policy mostly
   describes what is there.
3. **Nothing animates a big list, and no long surface animates its
   arrival.** The animation is where the jank would live, and the tree's
   first flatten (13–109 ms) shows the arrival is the part worth fixing.
4. **No animation inside a frame's layout of a whole pane.** Every existing
   one animates a transform, an opacity or one row's height; #6, the scrim,
   is the only one that repaints a full-screen area, and #28, the zoom page
   push, is the only one that rasterises a whole page.
5. **Reduced motion is honoured, and only twice** — the marquee and the
   spinning sync icon read `MediaQuery.disableAnimationsOf`. The implicit
   animations (FAB, menu, tab fade) do not. Whatever policy is taken, that
   should read the same everywhere.
6. **The instrumentation stays**: `NIMAN_FRAMES` off in a release build, the
   `[frames]`/`[shell]`/pane lines as they are, and every new animation
   measured with the scenario driver below before it is called smooth.

## What was not measured

- **Windows.** No host here. #62 asks for it; it did not happen in this
  pass.
- **DevTools.** Not attached: the app's own timings (`NIMAN_FRAMES`) were
  used instead, which report the engine's `FrameTiming` breakdown
  (build/raster/vsync) but no raster-level detail, no shader compilation
  trace and no per-frame widget rebuild counts.
- **The scenario list of #62, one by one**: library open/reindex at the 1M
  notes target, open + scroll of a novel-length note in `source` and `live`,
  tab switch, list scroll, search-as-you-type, the spell-check panel, the
  preview of a big note. None of these was driven and timed; the cold-start
  numbers are the only frame data here.
- **Any animation, individually.** No row of the inventory is a measurement.
  Every rating marked "a guess" is a reading of the code; the ones not
  marked are the ones whose own code or doc says why they are short.
- **The 246 MB note** (`huge-notes.md`'s `Quicknote.md`): not on this host in
  this pass.
- **`live` at scale**, and the row-wise reveal that mode still owes.
- **hunspell was present** — `hunspell ready: …/.local/share/hunspell/en_US.dic
  in 17 ms` — so the spell-check path had a real dictionary; but the
  spell-check *panel* itself was not driven.
- **Android, macOS**, and any phone.
- **The animation *perception*** the issue is really about: whether 450 ms of
  zoom on a settings push feels slow, and whether an instant tab switch feels
  abrupt, are questions about a person's hand, not about a frame log. The
  numbers here constrain the answer; they do not give it.

## The follow-up (what this pass does not have)

**A per-scenario driver.** One scripted run, on a real desktop device, that
drives each item of #62's measure list in turn — with enough quiet between
two actions for the engine's batched frame timings to belong to the action
that caused them (`frame_log.dart` says why: a window shorter than that
latency reads the previous action's frames) — and reads the app's own lines
for each: `[frames] slow frame` for the whole frame, `[shell]`, `[edit]` and
`[read]` for the region that spent it, and `FrameProbe`'s per-action summary
(`frame_log.dart`), which already wraps a tab switch (`shell.dart:627`) and a
preview open (`note_view.dart:761`) and can be pointed at a scroll and at
search-as-you-type with the same one call.

Without it, this file answers "what animates and what snaps" from the code
and gives the cold start a shape. With it, each animation in the table above
gets the rating it is owed, and #45's fixes get a baseline to beat.
