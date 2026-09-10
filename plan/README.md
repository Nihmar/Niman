# Copist plan

Detailed execution plan for **Copist**, the multiplatform Markdown note-taking
app. Companion to [`Copist - spec & plan.md`](../Copist%20-%20spec%20%26%20plan.md),
which is the **source of truth for requirements**; this folder plans the work.

## Index

| File | Milestone | Status |
|------|-----------|--------|
| [design.md](design.md) | Shared architecture & conventions | — |
| [android.md](android.md) | Cross-cutting — Android storage & startup issues | **Fixed** |
| [m0-scaffold.md](m0-scaffold.md) | M0 — Scaffold | **Done** |
| [m1-library-core.md](m1-library-core.md) | M1 — Library core | **Done** |
| [m1_5-correctness.md](m1_5-correctness.md) | M1.5 — Correctness pass | **Done** |
| [m2-editor-preview.md](m2-editor-preview.md) | M2 — Editor + preview | **Done** |
| [m3-links-search.md](m3-links-search.md) | M3 — Links & search | **Done** |
| [m4-frontmatter-templates.md](m4-frontmatter-templates.md) | M4 — Frontmatter & templates | **Done** |
| [m5-sync.md](m5-sync.md) | M5 — Sync | Planned |
| [m6-scale-polish.md](m6-scale-polish.md) | M6 — Scale & polish | **In progress** |
| [m7-packaging-release.md](m7-packaging-release.md) | M7 — Packaging & release | Planned |
| [ui-mockups.md](ui-mockups.md) | UI — mockup parity (bottom nav, toolbars) | **Done** |

Everything through M4 is done and verified on the user's device: M4 was
tried on 2026-09-09 and the three defects it turned up (the quick-note
flash, the todo priority picker, pinning a `.txt`) are fixed.

### Slices outside the M0→M7 chain

Each one grew out of on-device use and depends on the milestone in its own
header rather than on the next one in the chain.

| File | Slice | Status |
|------|-------|--------|
| [m2a-line-editor.md](m2a-line-editor.md) | M2a — the custom line editor | **Done** |
| [m2a-fix-selection-perf.md](m2a-fix-selection-perf.md) | M2a — selection + perf on a 931 KB note | **Done** |
| [m2a-round4-fixes.md](m2a-round4-fixes.md) … [round7](m2a-round7-fixes.md) | M2a — the four device-feedback rounds | **Done** |
| [todo-tab.md](todo-tab.md) | Todo tab over `todo.txt` + reminders | **Done** |
| [todo-mockup.md](todo-mockup.md) | Todo tab — mockup parity | **Done** |
| [m-type-note-kinds.md](m-type-note-kinds.md) | `type:` note kinds (the `list` GUI) | **Done** |
| [m-app-shortcuts.md](m-app-shortcuts.md) | Launcher quick actions (Android) | **Done** |
| [m-platform-parity.md](m-platform-parity.md) | Platform parity Android ↔ Linux/Windows | **In progress** |
| [m-toolbar-customization.md](m-toolbar-customization.md) | Editor toolbar — user order + hiding | **Done** |
| [m-localization.md](m-localization.md) | Italian + English, chosen in the settings | **Done** |
| [m-multi-library.md](m-multi-library.md) | Several libraries, each describing itself | **Done** |
| [m-template-language.md](m-template-language.md) | Templates — a language worth writing in | **Done** (counter and caret held back) |
| [m-reminder-latency.md](m-reminder-latency.md) | Todo reminders arriving minutes late | Fix in, device check open |
| [m-tab-switch-jank.md](m-tab-switch-jank.md) | What the tab switch cost, and what paid for it | Fix in, device check open |
| [m-cleanups.md](m-cleanups.md) | Quick wins from a review pass | T-CL-03 and T-CL-04 open |

## Conventions

- **Task IDs:** `T-M{n}-{num}` (e.g. `T-M5-07`, `T-M1.5-03`); checkboxes
  track completion.
- **Milestone files** share one structure: Purpose → Current state → Tasks →
  Technical design → Exit criteria → Risks / open questions.
- **Cross-cutting architecture** (module layout, drift schema, sync state
  machine, theming, testing, performance) lives in [design.md](design.md);
  milestone files reference it and detail only their own slice.
- **Requirements** are cited from the spec, not restated; if a milestone file
  and the spec disagree, the spec wins.

## Dependencies

```
M0 → M1 → M1.5 → M2 → M3 → M4 → M5 → M7
                              ↘ M6 ↗
```

Each milestone builds on the previous one's modules (`lib/src/…`) and
tests. The one place the chain forks is M5/M6: sync and scale-and-polish
both sit on M4 and touch nothing of each other's, so M6 is being built
first (user, 2026-09-09). M7 still waits for both. Stretch goals are not
on the critical path.

[ui-mockups.md](ui-mockups.md) is a cross-cutting UI pass, not part of the
M0→M7 chain: it needs M2a's editor surface but can run any time after, and
should land before M6 (polish) so the perf work runs on the final chrome.

M1.5 is not a feature milestone: it closes correctness gaps found in the
M1 indexer once the app ran on a real Android library. It blocks M2
because the tree is the surface everything later renders from, and
because M3's tables cannot key off an index whose row ids are reassigned
on every scan.

## Stretch goals (ordered)

| # | Goal | Status |
|---|------|--------|
| 1 | Mermaid diagrams (bundled offline webview renderer) | Backlog |
| 2 | PDF export | Backlog |
| 3 | LaTeX autocomplete | Backlog |
| 4 | Linux spellcheck | Backlog |
| 5 | E2E (next-level end-to-end coverage) | Backlog |
