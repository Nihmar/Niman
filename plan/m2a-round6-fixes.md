# M2a round 6 — highlight inset + tap-row diagnostics (Geometria 1)

**Status:** Done (`2dd3f92` T3, `6877069` S3) · device re-pass (R6) done 2026-09-08 (user) · **Depends on:** round 5 (`9e4396f`, `51e5a2d` — T1 logging, T2 custom balls, S1+S2 stock drag rule + freeze + pointer tracking, S4 line-bounded search, S5 show gating, int handle logs, `editor-r5` tag; all on-device in the 130930 log) · **Evidence:** `copist-debug-log-2026-09-06-130930.880.txt` (44-key burst @ ~1 ms/key, 164 ms off-isolate save, KB pushes, live deltas) + screenshots 12:34:10 (caret), 12:34:21 (handles), 12:34:46 (burst landed + `saved`) + user reports: caret cuts mid-`t` (exact at col 0, grows rightward); lateral highlight overhangs glyphs · **Decisions locked:** (a) keep all diagnostic log lines permanently; (b) stock-editor drag rule with freeze-until-lift (no scroll handoff); custom balls spec kept from round 5 (shipped — visual confirmation pending in R6 screenshots).

## Standing results (do not regress)

Typing burst, off-isolate saves, windowed IME, jitter gate, int handle logs, fingerprint, ⏎ Enter, custom balls + toolbar rendering, T1 caret invariant (`caret o… r… c… x…/grid…`) in every gesture log (the 130930 log shows drawn == grid everywhere, so painter == grid on-device and the mid-`t` remainder is offset-side or render-side — the col-0/20/40 device experiment + S3 diagnostics below settle it). S1+S2/S4/S5 behavior already shipped in round 5.

## T3 — tighter selection highlight

- `CaretGeometry.selectionRects`: start/end row edges from the painter (`RowTextMetrics.caretX` over the row slice, max 2 layouts per paint — bounded) instead of advance multiples, plus a ~1 px horizontal inset on every rect. Middle rows stay full-width grid (frame path).
- Update `caret_geometry_test.dart` expectations (inset values); painter test unaffected in spirit.
- AC: highlight hugs glyphs on an `istruzione`-class line in the next screenshot.

## S3 — tap-row diagnostics (hit row vs resolved row)

- Log content-y, hit row, and resolved row on every tap/long-press; warning when hit row ≠ resolved row (adjudicates the +1-row pattern seen across the 121736/123451/130930 taps without guessing). Bump fingerprint to `metrics(editor-r6)`.
- AC: next log either shows agreement (mapping exonerated → focus shifts to render) or a systematic shift with exact inputs.

## R6 — device re-pass

Col-0/20/40 taps (caret numbers decide T1 remainder), selection-active drag while the list wants to scroll, two-finger touch mid-drag, balls + highlight screenshots, 20-char burst, save. Pass: caret on-glyph, intended words, KB pushes, zero vsync > 200 ms, `saved`.

## Order + risks

Order: plan (this file) → T3 → S3 → R6. Main risk: the highlight inset is pure presentation over the same (possibly still shifted) columns — if T1/S3 show the columns themselves are off, T3's hug follows the wrong edges; the inset value then gets revisited with the numbers, not by eye.
