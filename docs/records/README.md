# Design records

These are the design, research and measurement records behind Niman's
features — not how-to documentation, and not kept current with the code.
Each was written while a feature was designed or a decision was taken, and
says what was measured, which options were rejected and why. They are kept
because the numbers and the reasons are the argument a later change has to
answer.

**Moved here from `docs/dev/` on 2026-09-25.** `docs/dev/` now holds only
the living documentation — architecture, building, conventions, memory, the
documentation site and the release process. The records' content is
unchanged apart from the links that followed the move; the code and the
tests cite them by path in comments (`docs/records/<name>.md`). The three
block-parser plans followed on 2026-11-26.

| Record | What it covers |
|--------|----------------|
| [unified-surface.md](unified-surface.md) | Research and design for one Markdown surface — built (#247) |
| [editor-alternatives.md](editor-alternatives.md) | The WYSIWYG packages measured and rejected before that decision |
| [block-tree.md](block-tree.md) | One block tree and an inline parser of our own, to `cmark-gfm`'s reading: the plan, its phases and the oracle (the specifications' own examples) — built, replacing `package:markdown` |
| [block-scanner-containers.md](block-scanner-containers.md) | The block scanner taken to CommonMark's containers, proved by a differential test against `package:markdown` — superseded by block-tree, kept for its evidence |
| [block-scanner-indent-model.md](block-scanner-indent-model.md) | The indentation model designed for the scanner's remaining repros — superseded by block-tree, kept for its evidence |
| [read-live-parity.md](read-live-parity.md) | Where the read view and `live` stand, and the decisions that aligned them |
| [huge-notes.md](huge-notes.md) | The 246 MB note: what was measured and what changed because of it |
| [desktop-performance.md](desktop-performance.md) | The desktop audit (#62): the cold-start and integration-test baseline, the animation inventory and the proposed policy |
| [performance-audit.md](performance-audit.md) | The performance baseline (#1135): the scenarios, Android's numbers from the device logs, the Linux perf suite, a million notes, the APK's libraries, and the prioritized list |
| [memory-usage.md](memory-usage.md) | Where the running app's RAM goes: the log's resident set, a retention probe, nine holders ranked with their fixes, and what was ruled out (#511, #1144) |
| [tree-window.md](tree-window.md) | The note tree bounded by what is on screen: a model of the visible rows from counts, pages around the viewport, the flows that read the whole list, measured over a million rows (#1200) |
| [workspace.md](workspace.md) | The open-note model — tabs and panes (#23) |
| [epub-reader.md](epub-reader.md) | Reading an EPUB into Markdown (#280) |
| [annotations.md](annotations.md) | Annotating a PDF or a book in a companion note (#284) |
| [dictionary.md](dictionary.md) | Looking up a selected word's meaning in packs built from Wiktionary, downloaded per language: the sources weighed, the owner's decisions, the 35 packs, the engine, the pipeline, the phases |
| [sync.md](sync.md) | Note history and WebDAV sync: the decisions, settled before the code |
| [history-store.md](history-store.md) | The history as objects, deltas and an append-only log, with nothing flushed on a save's path (#1148) |
| [index-reconcile.md](index-reconcile.md) | The index scan, a directory at a time with bounded memory (#302) |
| [transcription.md](transcription.md) | On-device speech-to-text with `whisper_ggml` |
| [ocr.md](ocr.md) | Text recognition with Tesseract, engine and languages downloaded on demand (#532) |
| [web-capture.md](web-capture.md) | Capturing a web page or a selection as Markdown, with a Dart port of Readability (#531) |
| [flashcards.md](flashcards.md) | Decks of flashcards in notes, reviewed with SM-2, the review state in `.niman/review.json` (#533) |
| [export.md](export.md) | The working plan for exporting a note, a folder or the library as Markdown, HTML, PDF and EPUB (#24, #63, #303) |
| [flowchart-layout.md](flowchart-layout.md) | Why a flowchart with subgraphs drew them in one row, and the compound layered layout after dagre that replaced the first one (#530) |
| [kanban.md](kanban.md) | A note as a board of columns and cards, shown and edited as a board on a phone, a tablet and the desktop (#1154) — built in 0.3.0 |
| [calendar-txt.md](calendar-txt.md) | Reading and writing `calendar.txt` beside `todo.txt`: the journal's events, the line-wise sync merge, reminders on an event (#730) |
| [recurring-tasks.md](recurring-tasks.md) | Recurring tasks: the `rec:` grammar shared with events, the copy completing one makes, its reminder and the sync merge (#1153) — built in 0.3.2 |
| [recurring-events.md](recurring-events.md) | Recurring events in `calendar.txt`: a rule on the event read virtually, `except:`/`until:`, the reminder horizon, the merge's rule pairing (#1153) — built in 0.3.2 |
| [todo-note-links.md](todo-note-links.md) | Tasks and notes linked both ways: a wikilink in a task, a note's tasks in its panel, a `todo` query block, Move to tasks (#1152) — built in 0.3.0 |
| [note-columns.md](note-columns.md) | Columns of blocks side by side with Pandoc's fenced divs, editable in `live` (#729) |
| [library-features.md](library-features.md) | A per-library switchboard for the macro features: the model, the gating seam, the introduction, the phases (#1109) — built in 0.2.6 |
| [apple-platforms.md](apple-platforms.md) | The plan for macOS and iOS: storage grants, the Mac desktop, widgets, signing, CI, phases and the owner's decisions — built in 0.3.0 (preview) |
| [review-v0.1.3.md](review-v0.1.3.md) | Code review of everything merged after v0.1.3: what was fixed, what is open |
