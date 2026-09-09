# Copist — Open Issues Fix Plan

> Source: [Nihmar/Copist open issues](https://github.com/Nihmar/Copist/issues)
>
> Generated: 2026-09-08
>
> Scope: all currently open issues in the repository at the time of writing.
>
> The repository currently has four open issues, all filed on September 8, 2026. They are all bugs and are focused on the editor/preview UI, fullscreen layout, Quick Note transitions, and checklist editing.

---

## Overview

| Priority | Issue | Area | Status |
|---|---:|---|---|
| P0 | [#2](https://github.com/Nihmar/Copist/issues/2) Fullscreen preview overlaps status bar | Android / fullscreen preview | Open |
| P0 | [#3](https://github.com/Nihmar/Copist/issues/3) Excessive empty space on the bottom in fullscreen preview | Android / fullscreen preview | Open |
| P1 | [#5](https://github.com/Nihmar/Copist/issues/5) Can't input new checklist item after editing one | Editor / checklist / keyboard | Open |
| P1 | [#4](https://github.com/Nihmar/Copist/issues/4) Black Flash when switching to Quick Note | Navigation / transitions | Open |

### Recommended implementation order

1. **Fix #2 and #3 together** — both concern the fullscreen preview's system-bar/layout handling and should be solved as one coherent layout pass.
2. **Fix #5** — restore the checklist editing flow without requiring the user to leave and reopen the note.
3. **Fix #4** — remove the visible black frame during Quick Note transitions.
4. Run the complete check suite and device verification after each logical change.

The first two issues should be treated as one implementation area even though they remain separate GitHub issues.

---

# 1. Fullscreen Preview Layout

## Issues

- [#2 — Fullscreen preview overlaps status bar](https://github.com/Nihmar/Copist/issues/2)
- [#3 — Excessive empty space on the bottom in fullscreen preview](https://github.com/Nihmar/Copist/issues/3)

## Problem

The fullscreen note preview currently has two related layout problems:

### #2 — Status-bar overlap

When a note is displayed in fullscreen preview:

- the preview's **background** is allowed to extend behind the system status bar;
- the **rendered text/content must remain below the status bar**;
- currently, the preview content can reach/overlap the status-bar area.

Expected behavior:

```text
┌──────────────────────────────┐
│       system status bar      │  ← background may extend here
├──────────────────────────────┤
│                              │
│  Markdown preview content    │  ← content starts below status bar
│                              │
│                              │
├──────────────────────────────┤
│ TOC   words   save status    │
└──────────────────────────────┘
```

### #3 — Excessive bottom gap

There is a sizeable empty region between:

- the end of the rendered note content, and
- the bottom toolbar containing the TOC, word count, and save status.

The toolbar should remain positioned correctly, but the preview content area should not create an unnecessary large visual gap.

## Likely root cause

Treat these as one fullscreen layout/insets problem rather than two unrelated visual bugs.

Investigate:

- fullscreen/system UI configuration;
- `SafeArea` / `MediaQuery` handling;
- status-bar edge-to-edge configuration;
- the fullscreen preview's parent `Scaffold`/layout constraints;
- bottom padding/insets applied to the Markdown preview;
- whether the preview content and bottom toolbar are being laid out in the same unconstrained vertical region;
- any duplicated top/bottom system padding.

Do **not** solve #2 by simply adding a fixed top padding. The solution should work across different Android screen sizes and status-bar heights.

## Implementation plan

### Step 1 — Identify the fullscreen preview layout

Locate the widget/state responsible for the Android phone fullscreen Edit/Preview switch.

Trace:

```text
fullscreen mode
    ↓
preview screen/container
    ↓
system-bar configuration
    ↓
Markdown renderer
    ↓
bottom preview toolbar
```

Determine which widget currently owns:

- system-bar styling;
- safe-area handling;
- preview scrolling;
- the bottom toolbar.

### Step 2 — Separate background coverage from content insets

The fullscreen background should be allowed to paint behind the status bar.

The actual preview content should respect the top system inset.

Prefer a structure conceptually equivalent to:

```text
fullscreen background
├── edge-to-edge system background
└── content-safe area
    ├── scrollable preview
    └── bottom toolbar
```

The status-bar inset should therefore affect **content positioning**, not the background.

### Step 3 — Correct the vertical constraint

Ensure the preview's scrollable region occupies exactly the space between:

```text
top content inset
        ↓
preview content
        ↓
bottom toolbar
```

Avoid adding arbitrary fixed bottom padding to compensate for the toolbar.

If the Markdown renderer requires bottom padding so the final line can be scrolled above the toolbar, calculate that padding from the actual toolbar height/inset rather than a large constant.

### Step 4 — Verify scrolling behavior

The final line of a note must be able to scroll above the bottom toolbar.

Verify:

- short note;
- medium note;
- long note;
- heading at the end;
- code block at the end;
- list/task item at the end;
- note ending with an image;
- empty note.

### Step 5 — Test device variations

At minimum verify:

- Android phone in portrait;
- Android phone in landscape if supported by the app;
- device with a normal status bar;
- device with a larger/dynamic status-bar inset;
- light and dark themes.

## Acceptance criteria

- [ ] Preview text never overlaps the status bar.
- [ ] Preview background can extend behind the status bar.
- [ ] The first line of the note starts below the status-bar content area.
- [ ] The bottom toolbar remains visible and correctly positioned.
- [ ] No excessive empty region exists between the final rendered content and toolbar.
- [ ] The final line of a long note can be scrolled into a comfortable visible position above the toolbar.
- [ ] No fixed device-specific padding is introduced.
- [ ] Existing editor/preview switching behavior remains unchanged.

## Tests

Add or update widget/integration tests where practical for:

- fullscreen preview layout;
- system inset handling;
- bottom toolbar positioning.

The visual portions should additionally be verified on a real Android device because system-bar behavior is platform-dependent.

---

# 2. Checklist Editing / New Item Input

## Issue

[#5 — Can't input new checklist item after editing one](https://github.com/Nihmar/Copist/issues/5)

## Problem

In a `type: list` note:

1. The user edits an existing checklist/list row.
2. The keyboard is open.
3. The user finishes editing.
4. The input used to add a new row becomes hidden.
5. The user has to use the Android back gesture to close the keyboard.
6. The new-row input still does not recover correctly.
7. The user is forced to leave the note and re-enter it before they can continue adding items.

This breaks a core list-editing workflow.

## Expected behavior

After editing an existing row, the user should be able to:

```text
edit existing row
       ↓
finish editing
       ↓
keyboard closes / editing focus changes
       ↓
new-item input remains available
       ↓
tap/type next checklist item
```

The user should never need to exit and reopen the note.

## Likely root cause

Investigate the interaction between:

- row editing state;
- focused text field;
- keyboard/IME visibility;
- list input visibility;
- focus/unfocus callbacks;
- rebuilds triggered by list item updates;
- Android back handling.

Pay particular attention to whether the "add new row" field is conditionally rendered based on focus/keyboard state.

Do not make the new-row field permanently visible as a superficial workaround if the current design intentionally hides it during editing.

## Implementation plan

### Step 1 — Trace the list editor state

Find the implementation for `type: list` editing and identify:

- the state representing the currently edited row;
- the controller/focus node for that row;
- the new-row input controller/focus node;
- the code that persists row changes;
- the code that responds to keyboard dismissal.

Document the state transitions before changing them.

### Step 2 — Reproduce with explicit state transitions

Test these sequences:

1. Edit row → press Enter.
2. Edit row → tap another row.
3. Edit row → dismiss keyboard using Android back.
4. Edit row → use swipe-back gesture.
5. Edit row → modify text → save/rebuild.
6. Edit row → delete/empty the row.
7. Edit row → immediately tap new-row input.

Identify exactly which state transition causes the new-row input to disappear.

### Step 3 — Decouple keyboard visibility from input availability

The existence of the new-row input should not depend directly on whether the keyboard is currently visible.

Keyboard visibility is transient UI state.

The ability to add another list item is editor state.

Keep those concepts separate.

### Step 4 — Preserve focus correctly

When an existing row loses focus:

- commit its current value;
- clear/update the edited-row state;
- preserve the list's ability to create a new row;
- do not accidentally dispose the new-row controller/focus node.

Avoid recreating controllers unnecessarily during rebuilds.

### Step 5 — Add regression tests

Create a widget test covering the exact reported flow:

```text
open list note
→ edit existing item
→ dismiss keyboard/focus
→ verify add-item input is present
→ enter new item
→ verify item is added
```

Also test the flow after a rebuild/state update.

## Acceptance criteria

- [ ] Editing an existing checklist item never permanently hides the new-item input.
- [ ] The Android back gesture can dismiss the keyboard without breaking list editing.
- [ ] The user can immediately add another item after editing an existing item.
- [ ] Existing list items are saved correctly when focus changes.
- [ ] No controller/focus-node leaks are introduced.
- [ ] A regression test covers the reported sequence.

---

# 3. Quick Note Black Flash

## Issue

[#4 — Black Flash when switching to Quick Note](https://github.com/Nihmar/Copist/issues/4)

## Problem

Switching to Quick Note currently produces a visible black frame/flash.

Expected behavior is a seamless transition with no black frame.

## Likely root cause

Investigate whether the flash occurs because of:

- a route transition;
- a new fullscreen/modal route being pushed;
- a temporary absence of the Quick Note background;
- Android window/background color;
- a Flutter widget being mounted one frame after the route appears;
- an animated transition revealing the underlying/default window background.

The first objective is to determine whether the black frame originates from Flutter's widget tree or from the Android window itself.

## Implementation plan

### Step 1 — Reproduce under different themes

Check:

- light theme;
- dark theme;
- system theme;
- Quick Note opened from the main editor;
- Quick Note opened from another screen if supported.

If the flash is always black regardless of theme, this strongly suggests a window/route transition issue.

### Step 2 — Inspect navigation architecture

Determine whether Quick Note is implemented as:

- a route;
- a modal route;
- an overlay;
- a separate window;
- an Android platform surface.

Inspect:

- route transition animation;
- page background;
- modal barrier;
- Android window background;
- initialization timing.

### Step 3 — Eliminate the intermediate frame

Prefer keeping a correctly colored/opaque surface present for the entire transition.

Potential approaches, depending on the existing architecture:

- use a transition with no transparent intermediate frame;
- provide an explicit page/modal background;
- initialize the Quick Note surface before revealing it;
- use a fade/scale transition that never exposes the default window background.

Do not simply disable all animations unless the existing UX/design calls for that.

### Step 4 — Check cold and warm opening

Verify both:

```text
first Quick Note opening
subsequent Quick Note openings
```

The first opening may expose initialization-specific behavior that later openings do not.

## Acceptance criteria

- [ ] No visible black frame when opening Quick Note.
- [ ] Behavior is correct in light and dark themes.
- [ ] First opening is also free of the flash.
- [ ] Subsequent openings remain correct.
- [ ] Existing Quick Note animation/interaction remains intact unless the animation itself is the source of the bug.

## Tests

Where possible, add a widget test for the Quick Note route/background.

The actual frame-level visual behavior should be verified manually on Android because route/window rendering can differ from widget-test behavior.

---

# 4. Cross-Issue Verification

After implementing the fixes, run the repository's normal verification workflow.

Per `AGENTS.md`:

```bash
./scripts/copist.sh check
```

This runs analysis and tests.

For Android verification:

```bash
./scripts/copist.sh apk
```

Verify the resulting release APK on a real Android device.

## Required regression pass

### Fullscreen preview

- [ ] Open note.
- [ ] Switch to fullscreen preview.
- [ ] Confirm content starts below status bar.
- [ ] Confirm background reaches status bar.
- [ ] Confirm bottom toolbar position.
- [ ] Confirm no excessive bottom gap.
- [ ] Scroll long note to bottom.
- [ ] Return to editor.
- [ ] Repeat several times.

### Checklist editor

- [ ] Open `type: list` note.
- [ ] Add several items.
- [ ] Edit an existing item.
- [ ] Dismiss keyboard with Android back.
- [ ] Add another item.
- [ ] Edit another item.
- [ ] Repeat without leaving the note.

### Quick Note

- [ ] Open Quick Note from the normal editor.
- [ ] Confirm no black flash.
- [ ] Close Quick Note.
- [ ] Reopen it.
- [ ] Repeat several times.
- [ ] Test both light and dark themes.

---

# Definition of Done

All four open issues are considered resolved only when:

- [ ] #2 behavior is fixed and manually verified on Android.
- [ ] #3 behavior is fixed and manually verified on Android.
- [ ] #5 has a regression test and is manually verified on Android.
- [ ] #4 is manually verified on Android in light and dark themes.
- [ ] `./scripts/copist.sh check` passes.
- [ ] Android release build succeeds.
- [ ] No unrelated behavior regressions are introduced.
- [ ] Each fix is committed as a separate logical change.
- [ ] GitHub issues #2, #3, #4 and #5 can be closed with references to the corresponding commits.

---

## Issue Reference

- [#2 — Fullscreen preview overlaps status bar](https://github.com/Nihmar/Copist/issues/2)
- [#3 — Excessive empty space on the bottom in fullscreen preview](https://github.com/Nihmar/Copist/issues/3)
- [#4 — Black Flash when switching to Quick Note](https://github.com/Nihmar/Copist/issues/4)
- [#5 — Can't input new checklist item after editing one](https://github.com/Nihmar/Copist/issues/5)
