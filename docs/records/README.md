# Design records

These are the design, research and measurement records behind Niman's
features — not how-to documentation, and not kept current with the code.
Each was written while a feature was designed or a decision was taken, and
says what was measured, which options were rejected and why. They are kept
because the numbers and the reasons are the argument a later change has to
answer.

**Moved here from `docs/dev/` on 2026-09-25.** `docs/dev/` now holds only
the living documentation — architecture, building, conventions and the
release process. The records' content is unchanged apart from the links
that followed the move; the code and the tests cite them by path in
comments (`docs/records/<name>.md`).

| Record | What it covers |
|--------|----------------|
| [unified-surface.md](unified-surface.md) | Research and design for one Markdown surface — built (#247) |
| [editor-alternatives.md](editor-alternatives.md) | The WYSIWYG packages measured and rejected before that decision |
| [read-live-parity.md](read-live-parity.md) | Where the read view and `live` stand, and the decisions that aligned them |
| [huge-notes.md](huge-notes.md) | The 246 MB note: what was measured and what changed because of it |
| [workspace.md](workspace.md) | The open-note model — tabs and panes (#23) |
| [epub-reader.md](epub-reader.md) | Reading an EPUB into Markdown (#280) |
| [annotations.md](annotations.md) | Annotating a PDF or a book in a companion note (#284) |
| [sync.md](sync.md) | Note history and WebDAV sync: the decisions, settled before the code |
| [transcription.md](transcription.md) | On-device speech-to-text with `whisper_ggml` |
