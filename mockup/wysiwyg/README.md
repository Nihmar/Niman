# WYSIWYG mockups (T-WYS)

Static, self-contained HTML mockups for the WYSIWYG editor plan
(`plan/m-wysiwyg-editor.md`, branch `feat/wysiwyg-editor`).

Open `index.html` in any browser:

```bash
xdg-open mockup/wysiwyg/index.html
```

No build step, no network, no dependencies — the page is one HTML file with
inline CSS and a few lines of JavaScript.

## What it shows

| Section | Screen |
| --- | --- |
| Android — Settings | the two new rows under **Editor**: **Editor** (source / WYSIWYG, with the picker dialog) and **Preview** (switch). The split-ratio row greys out where the panes cannot split. |
| Android — Editor | three modes via the segmented control: **Source + preview**, **WYSIWYG**, **Preview off**. Shows the toolbar swap, the eye appearing/disappearing, and the opaque "kept verbatim" blocks (table, math, footnote). |
| Desktop — Editor | the same three ideas at wide width: **split** source + preview, full-width **WYSIWYG**, and **Preview off**. The layout menu disappears in WYSIWYG; the eye disappears when the preview is off. |
| Mode matrix | the setting -> screen table in one grid. |

## Notes

- **Dark theme** button in the top bar; colors follow the app's palettes
  (`lib/src/ui/theme/`) and the shipped syntax fallbacks.
- The mockups are **illustrative**: they fix layout and which controls exist,
  not type metrics or exact spacing.
- The opaque shaded boxes are the codec's preserved blocks: read-only, written
  back byte for byte (see the plan's Phase 1).
