# M2a round 5 — custom handles, caret numbers, stock-editor drag rule (Geometria 1)

**Status:** Done (`9e4396f`) · device re-pass done 2026-09-08 (user) · **Depends on:** round 4 (R1–R3 in `402d003`, `5135140`) · **Evidence:** `copist-debug-log-2026-09-06-123451.270.txt` (44-key burst @ ~1 ms/key, save 164 ms off-isolate, KB pushes throughout) + 3 screenshots (12:34:10 caret, 12:34:21 handles, 12:34:46 typed burst landed + `saved`) + user reports: caret cuts mid-`t` (correct at col 0, error grows toward line end); handles must be custom (smaller, bottom-hanging, edge-highlighted) · **Decisions locked:** (a) keep all diagnostic log lines permanently; (b) drag rule copies the stock Flutter editor — verified in SDK `text_selection.dart`: touch drags never create selections (`onDragSelectionStart` is documented "when a **mouse** starts dragging"; touch drag = caret-follows via `selectPositionAt`, selection only via long-press/handles) — with the user's refinement: while handles/selection are active, drags extend the selection and the list stays frozen.

## T1 — caret: audit + numbers (no blind fix)

- Audit result (done, recorded here): app theme is default `ThemeData` (no `textTheme` overrides — `lib/src/app.dart`); the editor passes no `highlight` to `VirtualizedTextView`, so rows render the plain `Text(style: rowTextStyle, textScaler: noScaling)` branch — nominally identical to the `RowTextMetrics` painter. The col-0-correct / grows-rightward symptom still points at drawn-x scale, so:
- Log the caret invariant on every tap/long-press (`note_editor.dart`): offset, in-row col, drawn rect x, grid x (`leftPadding + col * charWidth`). The next device log settles grid-vs-painter-vs-row numerically from `col 0`, `col 20`, `col 40` taps.
- AC: one device pass with taps at known columns produces comparable numbers; no behavior change.

## T2 — custom handle controls (user spec)

- New `lib/src/editor/selection_handle_controls.dart`: `CopistSelectionControls extends MaterialTextSelectionControls`, overriding only `buildHandle` (16 px teardrop with edge highlight — bright rim behind the filled ball — tip up) and `getHandleAnchor` (tip at the endpoint, ball hanging below: left → `Offset(size, 0)`, right → `Offset.zero`, same convention as stock so overlay math holds). Toolbar + all other behavior inherited stock.
- `SelectionHandles` uses `const CopistSelectionControls()` instead of `materialTextSelectionControls`.
- Tests: anchor offsets unit test; existing handle widget tests stay green (overlay + toolbar + drag still work through the custom controls).
- AC: screenshot shows smaller bottom-hanging highlighted balls; drag/toolbar behavior unchanged.

## S1+S2 — drag rule + scroll freeze + pointer tracking

- Rule (stock + user refinement): at pointer-down record `_downHadSelection` + `_activePointer` (ignore other pointers entirely — fixes the mid-drag collapse at 123451:362-364 where a second pointer reset the lock and `dragStartAt` collapsed).
  - Selection active → freeze scroll immediately (`NeverScrollableScrollPhysics` for the gesture, restored on up/cancel) and any-axis drag past slop extends the selection.
  - Collapsed → stock: horizontal drag moves the caret collapsed (new `EditorGestures.moveCaretTo`, no selection created); vertical drag belongs to the scrollable (a real `HorizontalDrag`-style split via the existing direction lock; our `Listener` stays out once `scrolling` locks).
- `VirtualizedTextView` gains an optional `physics` param (default preserves current behavior).
- Long-press + handle paths unchanged.
- Tests (widget): selection-active drag freezes scroll offset at 0 while extending; collapsed horizontal drag moves a collapsed caret; second-finger down/up mid-drag preserves the selection; existing scroll test still passes.
- AC: the 123451 drag sequences (scroll running 418→475 while selection frozen; mid-drag `caret 609` + ui-hide) cannot recur.

## S4 — bound the word search to the pressed line

- `selectWordAt` keeps the tested round-3 contracts (blank line → nearest word above, then below; all-whitespace → run; U+202F bound) but the left/right whitespace walks stop at the pressed line's bounds — no more landing lines away from an in-line gap. Existing `composing_input_test.dart` word tests stay green; add: gap press with words lines away stays on its line.
- AC: unit tests green; device long-presses on row 28-class lines resolve locally.

## S5+S3 leftovers

- `show()` only on tap-up + attach/re-attach (pointer-down ensures focus only) — matches stock timing, kills the show-on-every-scroll log spam.
- Handle-drag logs print explicit `start..end` ints (today's `Instance of 'TextSelection'` lines are unreadable); keep every diagnostic line permanently per decision (a).
- Build fingerprint: the `metrics:` init line gains a static round tag (e.g. `editor-r5`), bumped per round, so a log always identifies its APK.
- AC: next log is readable end-to-end (KB pushes, caret numbers, int selections, fingerprint).

## Order + risks

Order: plan (this file) → T2 → T1 → S1+S2 → S4+S5 → device pass (R4 script + drag-while-list-wants-to-scroll + two-finger + col-0/20/40 taps). Main risk: freezing scroll on selection-active pointer-down removes scroll-by-text-drag while selected (tap clears first) — accepted per decision (b). Second risk: caret-follow on collapsed horizontal drag is new behavior over P4's drag-creates-selection; plain-drag selection now comes only from an active selection or long-press — this IS the stock rule the user asked for.
