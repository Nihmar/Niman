# M2a fix — slow typing + broken selection on large notes (Geometria 1, 931 KB)

**Status:** Done + verified on device 2026-09-08 (user) · **Depends on:** M2a E8d (NoteEditor wired into NoteView) · **Evidence:** `copist-debug-log-2026-09-06-072437.613.txt` (Geometria 1, 931580 chars) · **Decisions locked:** plain-drag persists + tap clears; windowed IME; target 931 KB @ 60 fps (harder highlight/autosave debounce OK); scripted on-device pass will be run.

## Why

The custom line editor renders fast (load 31 ms, `editor ready` 1.20 ms, one 11.95 ms re-wrap) but editing/selecting a 931 KB note stalls: every tap/selection/keystroke pushes the full 931 KB to the platform (`ime push ... in 30-42 ms` Dart-side, `~1900-2080 ms` vsync stalls platform-side with build 0-3 ms / raster 2-5 ms), saves block the UI for ~4 s (`note saved ... 4159 ms`, encode only 6 ms), and plain-drag selection collapses on lift so selection "doesn't work". The user wants the standard Android selection UI (two draggable balls + toolbar).

## Forensics (log + code)

- Model half is fine: `keystroke: fold 0.25 ms, 0.31 ms total` = `ComposingInput.apply` + `RowModel.sync` only (`lib/src/editor/note_editor.dart:_onChange`).
- Zero `ime delta:` lines despite 4 keystrokes. `NoteEditorClient.updateEditingValueWithDeltas` logs every delta (`lib/src/editor/note_editor_client.dart:68-75`). Cause: `TextInput.attach` uses `TextInputConfiguration(inputType: multiline, enableSuggestions: false)` with no `enableDeltaModel: true` (`lib/src/editor/note_editor.dart:428-434`). Platform sends legacy full-value `updateEditingValue` → `input.reset(value.text)` (`note_editor_client.dart:107-113`) = full `replace(0, len, text)` O(n) per keystroke, clears undo/redo, sets `_needsImeSync`, forces a full `pushValue()` back. Each keystroke = 2x 931 KB platform-channel copies + O(n) joins.
- Per-keystroke O(n) Dart joins outside the measured path: `onTextChanged(_input.text)` (`note_editor.dart:470`), `input.value` (`composing_input.dart:120-124`), `currentTextEditingValue` (`note_editor_client.dart:63`), `NoteSelectionDelegate.textEditingValue` (`selection_delegate.dart:54`), `selectWordAt` via `_buffer.text` (`composing_input.dart:282-340`). The E9 benchmark measures only `apply + sync`.
- Save blocks UI: `NoteView._write` does `utf8.encode` + `writeFileAtomically(File, bytes)` with `flush: true` + `rename` on the UI isolate (`lib/src/ui/note_view.dart:94-109`, `lib/src/core/files.dart:70-84`). 500 ms debounce → every typing pause freezes.
- Selection contracts: plain-drag collapses on release (`note_editor.dart:257-261`, `editor_gestures.dart:51-55`; asserted in `test/widget/note_editor_test.dart:163-168`); `onPan*` fights `CustomScrollView` scroll (no disambiguation); handle drag uses frozen `_dragStartSelection` + `min/max`, cannot cross anchors (`selection_handles.dart:281-305`); anchors go stale on scroll (`_onScroll` only `setState`).

## P0 — delta model + honest instrumentation (no UX change)

- [x] `TextInputConfiguration(..., enableDeltaModel: true)`. Verify `ime delta: insertion ... (oldText ~KB)` per key on Gboard + Linux; legacy `updateEditingValue/reset` path goes cold; undo survives typing.
- [x] **Enter fix** (cause in code: `TextInput.attach` sets `inputType: Multiline` but leaves `textInputAction` at its default, which Gboard renders as the ✓ checkmark, not ⏎; and `_onAction` is an empty stub, so even the right icon did nothing, because Gboard in newline mode sends `performAction(newline)`, not an insertion delta): (1) attach config adds `textInputAction: TextInputAction.newline` (keep multiline + `enableSuggestions: false`; same edit as `enableDeltaModel` above); (2) implement `_onAction`: on `newline` insert `\n` at the caret/selection via the existing direct-edit path (`replaceSelection('\n')` + `commitDirectEdit` + push + caret scroll + change notification, same as paste); on `done`/`go`/`search`/etc. unfocus (hide keyboard). Document that soft-Enter arrives via the action while hardware-Enter arrives as an insertion delta (already handled). Widget tests: extend the multiline attach test to also assert `inputAction == newline`; new tests: `performAction(newline)` inserts a line break and pushes; `performAction(done)` unfocuses.
- [x] Extend `test/unit/m2a_keystroke_benchmark_test.dart` to measure the real `_onChange` path (`apply + sync + text join + value join + onTextChanged`) at 1K/10K/100K lines; assert < 16 ms at Geometria scale.
- [x] Log `text join ms`, `push enqueue ms`, `save encode/write ms` separately per keystroke/save. — Superseded by P1/P3: the per-keystroke join no longer exists (the revision crosses, not text), so the logs are `keystroke: fold X ms, Y ms total`, `ime push: N chars (window), ... in X ms` (the KB window size is the check), and `save write: N bytes (encode X ms, write Y ms, off-isolate)`.
- AC: small-note typing shows deltas, no per-key `reset`; undo intact.

## P1 — kill O(n) Dart joins on the hot path (keystroke < 8 ms Dart-side at 931 KB)

- [x] `onTextChanged`: send `(revision, caret)` / dirty flag, not full `String`. `NoteView` reads `input.text` only when the save fires. Removes 1x join + `_text` hold + parent `setState` per key (`note_editor.dart:470`, `note_view.dart:141-148`). — `onTextChanged` is now `ValueChanged<int>` (the revision); `NoteView` owns the buffer and reads `.text` only in `_save`.
- [x] `NoteSelectionDelegate.textEditingValue` + `currentTextEditingValue`: return lightweight value (empty text + real selection) except during an actual IME resync. Toolbar only needs selection/clipboard status. — delegate returns empty text + real selection/composing (copy/cut text comes from the buffer's `selectionText`); `currentTextEditingValue` is P2's windowed value (the legitimate resync path).
- [x] `selectWordAt`: rewrite via `lineAt`/`lineLength`/`offsetOf`/`locationOf` only — O(word), never `_buffer.text`. — `_codeAt(offset)` via `locationOf`+`lineAt` (a line's trailing break maps to `col == lineLength` → real 0x0A); algorithm unchanged, all existing tests pass.
- [x] Keep `_resetPositions` + `RowModel.sync` O(lines) for this fix (0.3 ms at 15K lines, inside budget). File in-place `_lineStarts` shift + incremental re-wrap as the pre-1M-line follow-up.
- AC: benchmark with joins < 8 ms avg at 100K lines; long-press word select logs no `text join`.

## P2 — windowed IME buffer (the typing-stall fix)

`ComposingInput`/`LineBuffer` stay the full-file source of truth; only the platform view shrinks.

- [x] Add `ImeWindow { windowStart, windowText, windowSelection, windowComposing }` in `ime_bridge.dart` / `note_editor_client.dart`: expose the caret's paragraph (±2K chars, clamped to line boundaries), not 931 KB. — `ImeWindow.around(input)`: caret/selection lines ±1 margin line (backspace-at-line-start / Delete-at-line-end stay expressible), expanded to ≥2048 chars, clamped to line starts; a selection wider than the budget (select-all on a novel) falls back to the full buffer so an edit on the whole selection stays expressible.
- [x] `currentTextEditingValue` / pushes return the window. `updateEditingValueWithDeltas` translates offsets by `+windowStart` before `input.apply`. Re-center on caret crossing a boundary (tap / handle drag / arrows) = one KB-sized push + `commitDirectEdit`. Lockstep invariant becomes "platform oldText == window text"; reuse `_needsImeSync` re-anchor on window moves. — `apply(delta, anchor:)` translates every offset; the re-anchor degrades to a region replace (lost edit, never a corrupt buffer, on the forgotten-push case); the client tracks `_windowStart`/`_platformLength`, re-centers after each delta batch when the window start moved, and the legacy full-update path re-anchors the window region (`replaceRegion`) instead of resetting the buffer.
- [x] Keep `enableSuggestions: false` for the Geometria pass; re-enable as an experiment once pushes are KB-sized. — unchanged (config already sets it); pushes are now KB-sized, so re-enabling is a one-line on-device experiment.
- Fallback (only if translation proves too risky): single-line overlay field on the caret row (IME sees one line).
- AC: `ime push: N chars` shows KB, not 931K; 20-char burst shows no `slow frame` vsync > 100 ms; deltas carry `oldText ~KB`.

## P3 — unblock saves (the 4 s freeze)

- [x] Move `utf8.encode` + `writeFileAtomically` into `Isolate.run` (read already is). No file IO on UI isolate. — the whole encode + atomic write runs in one `Isolate.run`; `save write: N bytes (encode X ms, write Y ms, off-isolate)`.
- [x] Coalesce: if a save is in flight, mark dirty + run one trailing save; lengthen debounce while typing fast (1-2 s); keep save-on-focus-loss / pause / dispose immediate. — `_save` re-reads the buffer at fire time, `path == null && _saving` coalesces into one trailing save, debounce is 1 s while a save is in flight; focus-loss / pause / dispose still save immediately.
- [x] Skip save when `revision` unchanged; drop per-keystroke `setState` in `_onUserEdit` (status line follows save state only). — `_onUserEdit` takes the revision and does no `setState`; dirty flag is `revision != _lastSavedRevision` shown in the status line.
- AC: `note saved (... ms)` with no overlapping `slow frame vsync ~2000 ms`; typing through a save stays fluid.

## P4 — standard Android selection UI that persists

- [x] Plain drag persists: `dragEnd` no longer collapses; lift leaves `TextSelection(start, end)` + handles + toolbar. Plain tap collapses/clears. Update the two widget tests asserting collapse. (Done: `dragEnd`/`collapseSelection` removed from the delegate; the two old tests now assert persistence; `drag extends the selection (M2a fix P4 — no collapse on end)` covers it.)
- [x] Scroll-vs-select disambiguation: horizontal/short drag = select, vertical/long drag = scroll (slop + direction lock). Long-press-drag keeps extend behavior, persists on release. (Done: raw-pointer `Listener` + `_DragKind` direction lock in `note_editor.dart` — a vertical move cancels the pending long-press *without* collapsing and the scrollable owns the drag; `a vertical drag scrolls, not selects (M2a fix P4)` covers it.)
- [x] Handles: keep `SelectionOverlay` + `materialTextSelectionControls` (the standard balls + toolbar); fix anchoring (recompute `_endpoints` on scroll change, leaders in scrolling content), support anchor crossing (track dragged handle, allow flip), push windowed selection once per drag end. (Shipped in the round-3 commit `422beda` — `SelectionOverlay` + `SelectionHandleDragState` flip + `onScrollDelta` recompute + viewport leaders; drag pushes once per end via the persist paths.)
- [x] Toolbar via `NoteSelectionDelegate` (copy/cut/select-all/paste) — cheap after P1 (no full-text `value`). (Shipped in `422beda`; after P2 the pushes are windowed, so the toolbar path costs a ≤2KB push.)
- AC (widget + device): long-press selects the word (never `\n\n`); plain drag leaves selection + two draggable balls; each ball moves only its edge; tap clears; toolbar round-trips; next typed char replaces the selection.

## P5 — scripted on-device verification (Geometria 1, release APK, export log)

1. Open note (load + `editor ready` + re-wrap lines). 2. Tap mid-paragraph → caret, no freeze. 3. Long-press word → word + handles + toolbar. 4. Drag each handle → follows, lift → persists. 5. Type 20 chars fast → no lag (`ime push: N chars` KB, any `slow:` lines). 6. Fast scroll → no sustained slow frames. 7. Background/foreground + 2 s pause → save, no 2 s stall. 8. Keyboard shows ⏎ (not the ✓ checkmark); pressing it splits the line and moves the caret; hardware Ctrl+Enter / USB-keyboard Enter still insert a newline.
- Pass: pushes in KB, zero vsync > 200 ms during 4-6, save without freeze, P4 behavior holds, ⏎ (not ✓) and Enter splits the line. Record window size, push sizes, save ms into the M2a E9 notes.

## Order + risks

Order: P0 → P1 + P3 (independent, headless) → P2 (needs P0) → P4 (needs P1+P2) → P5. Main risk: P2 offset translation for multi-line compositions spanning the window edge — mitigate by line-boundary windows with margin; on mismatch re-center + resync (lose the edge keystroke, never corrupt).
