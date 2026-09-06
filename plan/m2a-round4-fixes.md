# M2a round 4 — keyboard re-show, grid metrics lock, selection slop (Geometria 1)

**Status:** Planned · **Depends on:** M2a fix P0–P4 (committed: `542585b` + `7551eae`) · **Evidence:** `copist-debug-log-2026-09-06-121736.027.txt` (931581 chars; pushes now `2224 chars (window) in 0.2–0.6 ms`, no ~2 s stalls) + user reports: keyboard showed once then never again (Enter key itself correct); caret renders mid-glyph; selection never matches intent; taps never land where tapped · **Decisions locked:** user font size = system minimum (~0.85×); editor grid owns its metrics (`TextScaler.noScaling` on rows); tap = keyboard; plain-drag persists + tap clears (unchanged).

## Why a new round

P2 fixed the performance stalls (log proves it: windowed pushes, worst frame 32 ms). What remains is all interaction-layer: the log contains **zero** `ime delta` / `keystroke` lines across 25+ taps, so the typing path is untested — the keyboard never returned. The caret/tap/selection symptoms share one confirmed root (system-minimum scaler vs. fixed 21 px grid) plus two independent defects (dead connection handling, jitter-as-drag).

## R1 — keyboard never returns after system dismiss

- Root: `_focusEditor()` (`lib/src/editor/note_editor.dart:357-361`) only calls `requestFocus()` when `!hasFocus`. A system-back/gesture keyboard dismiss keeps Flutter focus while killing the platform connection, so later taps do nothing. `_onConnectionClosed` (`:485-487`) is an empty no-op: never nulls `_connection`, never logs, never re-shows. The log shows exactly this: one `ime focus: attached`, no `connectionClosed`, no re-attach.
- Fix:
  - `_onConnectionClosed`: null `_connection`, log it, and if still focused re-attach + `show()`.
  - `_focusEditor()`: ensure *connection + show*, not just focus — if focused but `_connection == null`, re-attach and `show()`.
  - Log every `connection.show()` call and every focus loss.
- Tests (widget): system-dismiss simulation (close connection while focused) → tap re-attaches and shows; `receiveAction(done)` path unchanged.
- AC: dismiss via system back → tap brings keyboard back; log shows `connectionClosed` + re-`attached`; typing produces `ime delta` lines.

## R2 — grid metrics lock (caret mid-glyph + taps landing elsewhere)

- Root (confirmed by minimum-font report): `measureCharWidth()` measures `'0'` at scaler 1.0 with no width constraint (`virtualized_text_view.dart:53-59`) and `rowHeight = 21` is fixed, but row `Text` widgets inherit the ~0.85× system scaler → real glyphs ~10 px, real rows ~18 px. Both caret x (`leftPadding + col * charWidth`) and tap mapping (`(x / charWidth).round()`, `(y / 21).floor()` in `hit_test.dart:33-40`) share the error, growing with column/row — matches col-50 taps and deep-page drift in the log.
- Fix:
  - Pin rows: `textScaler: TextScaler.noScaling` on both row `Text` branches in `VirtualizedTextView.build` (grid owns metrics; app chrome keeps respecting system size). Document the cost: editor renders designed 12 px even at minimum system size.
  - Correct x: caret x and tap columns via a `TextPainter.getOffsetForCaret / getPositionForOffset` over the actual row slice (O(row), tap-only, never per frame); keep the row model for y only. This also absorbs math/Unicode fallback-advance error (second-order suspect on Geometria spans).
- Tests: widget test with forced `MediaQuery(textScaler: 0.85)` — tap a far-right column lands the caret on the glyph (round-trip: tap same pixel → `(unchanged)`); caret rect for col 40+ within half a glyph of the painter-computed offset.
- AC: tap-to-caret round-trips at col 40+ and row 20+; caret visually on-glyph in screenshots at minimum font size.

## R3 — selection slop + handle observability

- Root (in-log): `longPress → 410..417` followed by `longPressDrag` at *identical* coordinates shrinking to `410..412` — sub-slop touch jitter is treated as drag-extend. Handle drags emit no log lines, so handle behavior is unverifiable.
- Fix:
  - Gate `longPressDrag` behind touch slop from the press point (ignore moves < slop; record press point in `_handleLongPressStart`).
  - Log handle drag start/update/end with offsets in `SelectionHandles`.
  - Keep `selectWordAt` left-first rule (already U+202F-aware); re-test specifically on Geometria French/math text.
- Tests: jitter-without-move keeps `410..417`; move past slop extends; existing persistence tests stay green.
- AC: long-press without moving keeps the word; device pass selects the intended word 3/3 tries.

## R4 — scripted re-verification (Geometria 1, release APK, export log)

1. Open note (load + `editor ready` + re-wrap). 2. Tap mid-paragraph → caret + keyboard. 3. System-back dismiss → tap → keyboard returns (R1). 4. Tap far-right column + deep row → caret on glyph; re-tap → `(unchanged)` (R2). 5. Long-press word, hold still → word kept; drag → extends; lift → persists (R3). 6. Drag each handle → only its edge moves. 7. Type 20 chars fast → `ime delta` lines, KB pushes, no vsync > 200 ms. 8. Fast scroll → no sustained slow frames. 9. Background/foreground + pause → save without freeze.
- Pass: keyboard returns; caret-on-glyph; intended-word selection 3/3; KB pushes; zero vsync > 200 ms in 7–8; ⏎ still correct. Record push sizes, save ms, `charWidth` + scaler init line into the M2a E9 notes.

## Order + risks

Order: R1 + R3-slop (independent, small) → R2 grid lock + painter-x → R4 device pass. Main risk: `noScaling` makes editor text larger than the user's minimum-size preference elsewhere — accepted per decision above; alternative (scale grid by scaler) breaks the 21 px integer-extent invariant and is explicitly deferred. Second risk: per-row painter x must use the exact row slice + style or it reintroduces its own mismatch — unit-test it against the builder output.
