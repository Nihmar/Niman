# Copist plan

Detailed execution plan for **Copist**, the multiplatform Markdown note-taking
app. Companion to [`Copist - spec & plan.md`](../Copist%20-%20spec%20%26%20plan.md),
which is the **source of truth for requirements**; this folder plans the work.

## Index

| File | Milestone | Status |
|------|-----------|--------|
| [design.md](design.md) | Shared architecture & conventions | — |
| [m0-scaffold.md](m0-scaffold.md) | M0 — Scaffold | **In progress** |
| [m1-library-core.md](m1-library-core.md) | M1 — Library core | Planned |
| [m2-editor-preview.md](m2-editor-preview.md) | M2 — Editor + preview | Planned |
| [m3-links-search.md](m3-links-search.md) | M3 — Links & search | Planned |
| [m4-frontmatter-templates.md](m4-frontmatter-templates.md) | M4 — Frontmatter & templates | Planned |
| [m5-sync.md](m5-sync.md) | M5 — Sync | Planned |
| [m6-scale-polish.md](m6-scale-polish.md) | M6 — Scale & polish | Planned |
| [m7-packaging-release.md](m7-packaging-release.md) | M7 — Packaging & release | Planned |

## Conventions

- **Task IDs:** `T-M{n}-{num}` (e.g. `T-M5-07`); checkboxes track completion.
- **Milestone files** share one structure: Purpose → Current state → Tasks →
  Technical design → Exit criteria → Risks / open questions.
- **Cross-cutting architecture** (module layout, drift schema, sync state
  machine, theming, testing, performance) lives in [design.md](design.md);
  milestone files reference it and detail only their own slice.
- **Requirements** are cited from the spec, not restated; if a milestone file
  and the spec disagree, the spec wins.

## Dependencies

```
M0 → M1 → M2 → M3 → M4 → M5 → M6 → M7
```

Strictly sequential: each milestone builds on the previous one's modules
(`lib/src/…`) and tests. Stretch goals are not on the critical path.

## Stretch goals (ordered)

| # | Goal | Status |
|---|------|--------|
| 1 | Mermaid diagrams (bundled offline webview renderer) | Backlog |
| 2 | PDF export | Backlog |
| 3 | LaTeX autocomplete | Backlog |
| 4 | Linux spellcheck | Backlog |
| 5 | E2E (next-level end-to-end coverage) | Backlog |
