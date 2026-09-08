# M2a round 7 — selection-UX corrections (133116 log + screenshots)

**Status:** Done · R7 device re-pass done 2026-09-08 (user) · **Depends on:** round 6 (T3 reverted to stock
full-advance in `98e65d2`; stale-HitTest fix in `517ff16`) · **Evidence:**
`copist-debug-log-2026-09-06-133116.618.txt` + screenshots 13:29–13:31

## Findings (133116)

- A long-press selects a word (`612..622`), then every content drag
  stretches it across paragraphs (`dragStart`/`drag:` ×100+, scroll frozen
  at 118.8/247.0). The user only ever drags content — no `handleDrag*`
  lines — so the select-on-drag mode fights scrolling.
- `ROW MISMATCH` lines persist because the on-device APK predates the
  stale-HitTest fix (`editor-r6` tag). This round bumps the tag to
  `editor-r7` so the next log identifies the fixed mapping.
- Screenshots: handle balls float mid-glyph (endpoints were the row top)
  with bright white rims; keyboard is up on every screenshot.

## Changes

1. **Content drags never change a selection** — only the selection balls
   (and the long-press gesture) do. With a selection active every drag
   axis scrolls; the list is never frozen. Collapsed keeps the stock rule
   (horizontal caret-follow, vertical scroll). Replaces the round-5
   select-mode + freeze.
2. **Handles hang below the word**: endpoints move from the row top to the
   row bottom (stock convention); ball rendering loses the bright rim
   (flat fill + stem).
3. **Keyboard only on explicit tap/long-press**: pointer-down no longer
   requests focus, so opening a file or scrolling never summons it.
4. Tag `metrics(editor-r7)`.

## R7 — device re-pass

Long-press a word, drag content (selection must not move, list scrolls),
drag each ball (selection follows, IME commit on release), open a note
(keyboard stays hidden until a tap), balls below the word with no rims.
Pass: intended words, KB pushes, `saved`, no `ROW MISMATCH`.
