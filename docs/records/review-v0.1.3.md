# Code review of `v0.1.3..main` — 2026-09-28

A review of everything merged after the v0.1.3 tag: 187 commits, about
21,000 lines changed under `lib/`. It ran in three passes. The first read
the riskiest logic (sync, WebDAV, files, watcher, template counters, index
rebuild, wikilink suggester); its fixes are in PR #487. The second split
the rest of the diff into four areas (editor, UI and frontmatter, spelling
/ templates / watcher / todo, sync and storage), each read by a separate
reviewer; its fixes are in PR #489. The third read `main` after #489 in
seven areas, translations and user docs among them.

Line numbers refer to `main` at `0771606e`. **Verified** means the wrong
result was reproduced by running the code (a throwaway probe or test);
**read** means it was traced through the code, not run.

## First pass — status

| # | Finding | Status |
|---|---------|--------|
| 1 | Weak ETag: `If-Match` dropped by the client while the planner and the merge guard still count on it, so a write on Nextcloud could overwrite an edit made during the run | Fixed, `1c81b470` |
| 2 | Body timeout bounded the whole transfer, so a large file on a slow link never synced | Fixed, `8ffdaff0` |
| 3 | Wikilink suggester wrote the bare name even when another note shares it | Fixed, `45a13a34` |
| 4 | A resumed or switched library opened empty on an index with no rows (never indexed here, or rebuilt after corruption) | Fixed, `40885eff` |
| 5 | Counter reservation (file I/O) ran outside the creation flows' guard | Fixed, `8fb64e50` |
| 6 | A counters file the OS refused to read was taken for empty and rewritten, wiping other counters | Fixed, `73b425be` |
| 7 | Stale-temp sweep walks the whole library, `.history/` included, on every open | Open — the periodic rescan already walks the tree every 5 minutes; reducing it is a design choice |
| 8 | Index warm-up awaited on the open path (was overlapped, #315) | Open — after fix 4 the first index query is needed right away; not changed without a measurement |
| 9 | Counter reservation copied in two flows | Fixed with 5 (`CounterStore.reserve`) |
| 10 | `source_view.dart` is 6,123 lines with 13 classes, against the "no god classes" rule | Deferred on purpose |

Known limit left by fix 3: with `Notes.md` at the root and
`Archive/Notes.md`, no target names the root note alone, because the
resolver matches any path ending in what is written. Making an exact path
win is a change to link semantics.

## Second pass — findings

Ordered by severity inside each group.

### Data loss or a corrupted note

1. **Frontmatter: a text value ending in `:` is written unquoted.**
   `lib/src/frontmatter/typed_fields.dart:193` — `_needsQuotes` checks
   `': '` but not a trailing `:`. Setting `title` to `Todo:` writes
   `title: Todo:`; the block stops parsing and every field turns into the
   error panel. *Verified.*
2. **Frontmatter: list items holding a comma are split on rewrite.**
   `typed_fields.dart:171`, `ui/frontmatter_field_dialog.dart:79`,
   `ui/frontmatter_fields.dart:328` — items are emitted as plain flow
   scalars and only their first character is checked. From
   `authors: ["Doe, J", "Roe, K", x]`, deleting `x` writes
   `authors: [Doe, J, Roe, K]`: four items. The `+` dialog joins on `, `
   and splits on `,`, the same fault. *Verified.*
3. **Frontmatter: editing a multi-line value corrupts it.**
   `typed_fields.dart:186` with `edit.dart:107` — `description: |` over two
   lines is saved as `"line one` + newline + `line two"` at column 0: the
   newline is lost, and the next edit of the key leaves `line two"` behind
   and the block no longer parses. *Verified.*
4. **Frontmatter: editing a field whose key is quoted adds a duplicate.**
   `typed_fields.dart:83` with `edit.dart:104` — `"due date": 2026-01-01`
   is shown as `due date`; `_entryRange` looks for the unquoted text, finds
   nothing and appends `due date: …`; the block fails with "Duplicate
   mapping key". *Verified.*
5. **Frontmatter: a list edit changes items nobody touched.**
   `typed_fields.dart:116-119, 146-153, 171` — items round-trip as text:
   `ids: [1, 2, 3]` minus `2` becomes `["1", "3"]`; booleans and dates are
   quoted too; nested items are dropped (`[{name: A}, B]` minus `B` becomes
   `[]`); deleting one of two equal chips removes both
   (`frontmatter_fields.dart:332`). *Read.*
6. **Invalid UTF-8 is rewritten as U+FFFD by a save and by bulk replace.**
   `lib/src/markdown/note_load.dart:62,70` and
   `lib/src/search/replace.dart:386,411` — both now decode with
   `allowMalformed` and write the whole text back. A Latin-1 `caffè` (byte
   `0xE8`) becomes `EF BF BD` on disk after one keystroke elsewhere in the
   note, or after a Replace All that matched another word; v0.1.3 refused
   such a file instead. History keeps the raw bytes only when it is on.
   One cause, two places. *Read.*
7. **A local `.niman/*.json` that does not parse is still uploaded.**
   `lib/src/sync/sync_engine.dart:1385` — the #336 guard covers the
   download only. A hand-edited `settings.json` with a syntax error goes up
   over the good remote copy, and `.niman/` has no history. *Read.*
8. **Rename in a case-sensitive Windows folder can replace another note.**
   `lib/src/core/files.dart:347` — `_excludedEntry` returns early on
   `p.equals`, which ignores case on Windows. In a folder made
   case-sensitive (WSL, `fsutil`) holding `A.md` and `a.md`, renaming `A.md`
   to `a` picks `a.md`, and the rename replaces it. Rare setup, data loss.
   *Read.*
9. **The merge guard reads the old row's `remoteUnverified`.**
   `sync_engine.dart:1257` — the row describes the remote version before
   the change being merged. On a server without ETags, a row recorded as
   verified skips the hash even when the current listing is in the same
   second as a second same-size rewrite, which the merge then overwrites
   (it survives only in the other device's history). *Read.*

### Certificates and credentials

10. **The sync settings screen keeps a forgotten certificate trust in
    memory.** `lib/src/ui/sync/sync_settings_screen.dart:229` with `:304`,
    `:362` — `_forgetCertificate` and `_disconnect` do not clear
    `_trustedFingerprint`, and `_retest` prefers it to the stored value.
    After "Forget certificate" a retest trusts the old certificate, sends
    Basic auth to it and reports OK while the stored value is null; after
    disconnect, Test + Save stores it again without the confirmation
    dialog. *Read.*
11. **A redirect target's certificate is shown as the base host's, and
    trusting it never works.** `lib/src/sync/webdav/webdav_client.dart:194-202`,
    `:750` — the callback records the refused fingerprint for any host,
    the failure names `baseUrl.host`, and the callback accepts it only for
    `baseUrl.host`. A valid `nas.local` redirecting to a self-signed
    `nas.lan:5006` prompts for `nas.local` with `nas.lan`'s fingerprint,
    forever. *Read.*

### Crashes and behaviour that is plainly wrong

12. **The template checker crashes on `{{{title}}}`.**
    `lib/src/templates/checker.dart:152` — `_checkBraces(source, 0, 1)`
    sees `{{` at 0 and calls `substring(2, 1)`: `RangeError`. It runs in a
    `Timer`, so the error is uncaught and the previous error list stays on
    screen. *Verified.*
13. **Desktop reminders fire again on every reconcile for an hour.**
    `lib/src/todo/reminders.dart:426` with
    `todo/reminder_backend_desktop.dart:75-87` — scheduling never checks
    `_fired`; a reminder fired at 10:00 is still inside `reminderGrace` at
    10:20 and `firesOverdue`, so any todo edit or focus regain notifies
    again, until 11:00. *Read.*
14. **Ticking a task inside a quote or callout in the read view does
    nothing** (regression). `lib/src/ui/note_view.dart:1530` —
    `taskBoxOffset` runs on the raw line and cannot get past `>`; the old
    code used the tokenizer's box. `> - [ ] task` never ticks. *Verified.*
15. **The wikilink panel opens whenever the caret enters an existing link,
    and takes keys.** `lib/src/markdown/render/source_view.dart:3697`,
    `:3985` — arrowing down onto `See [[Project plan]]` lands inside it and
    the next Down moves the panel instead of the caret; Enter or Tab there
    writes `[[Project plan]]ect plan]]`. *Read.*
16. **Enter or Tab can accept a stale suggestion of the wrong kind.**
    `source_view.dart:3763`, `:3868-3891` — the old rows stay while the new
    query loads. `[[Pro`, then `#`, then Tab before the headings arrive
    writes `[[Projects/Plan]]` and drops the `#`; `[[A#` changed to `[[B#`
    can insert one of A's headings into B's link. *Read.*
17. **Wrapped table rows break at the wrong places when a cell has hidden
    marks.** `lib/src/markdown/render/live_tables.dart:384` — line
    boundaries come back in visible-text positions and are added to a
    source offset, so each break shifts by the hidden characters before
    it: words split mid-word and the last piece can spill into the next
    column. *Verified.*
18. **Setext headings are detected where they are not.**
    `lib/src/markdown/block_scanner.dart:856`, `:891` — `---` under a table
    becomes a one-line heading instead of a rule; `> quote` + `lazy` +
    `---` becomes a heading inside the quote; `one` + `two` + `---` makes
    only `two` the heading, while the export makes `one two` one `<h2>`.
    *Verified.*
19. **The checklist cascade does nothing below a quote's first line.**
    `lib/src/markdown/task_cascade.dart:36` — a quoted list is one block,
    so `parent.startLine != line` empties the branch for every later item;
    ticking `> - [ ] b` leaves `>   - [ ] b1` unticked. *Verified.*
20. **The template checker misses what the engine leaves unrendered.**
    `checker.dart:299`, `:304-315` against `templates/engine.dart:373-382`,
    `:413-434` — `{{title|+1d}}`, `{{date|upper|+1d}}`, `{{title|}}`,
    `{{counter}}` with no name and `{{cursor|upper}}` all check clean and
    all stay standing in the note. *Verified.*
21. **The caret is drawn in the wrong cell on a wrapped row's separator.**
    `source_view.dart:2460` — an offset on `|` or its padding matches no
    piece and falls back to the first one; Right from the end of cell 1
    shows the caret in cell 1 for two presses. *Read.*
22. **A tab's "missing" mark is cleared by an unrelated removal.**
    `lib/src/workspace/workspace.dart:340-345` — `withMissing` takes the
    set it gets as complete, but each re-index sends only its own removals:
    delete A outside the app, then B, and A's tab no longer shows missing.
    *Read.*
23. **Changes made while the watcher restarts are lost until the periodic
    rescan.** `lib/src/library/file_watcher.dart:187-222` — the stream is
    resubscribed after 1–30 s with no resync of the root, so a save in
    that window waits up to five minutes. *Read.*
24. **Switching dictionaries during a spelling pass caches false
    "correct" verdicts.** `lib/src/spellcheck/editor_spell_check.dart:138-140`,
    `:363-364`, `:518` — the running pass keeps the disposed checker, whose
    `isCorrect` answers true, into the new cache, and nothing clears it
    when the new engine arrives. *Read.*
25. **A spelling pass can wait on a superseded load and report the note
    clean.** `editor_spell_check.dart:517` — the panel opens while the
    first load runs, `setDictionaries` starts another, the pass's
    `engineReady` returns early and `_checker` is still null. Short window.
    *Read.*
26. **`sanitizeName` can end a name with a dot or a space.**
    `lib/src/core/files.dart:56`, `:274-276` — `_trailingDots` needs two
    dots, and truncation to 200 bytes runs after the trim. `Draft.` stays
    `Draft.`; Windows creates `Draft` while the index holds `Draft.`, and a
    folder ending in a space cannot hold notes there. Folders only (notes
    get `.md`). *Verified* (the output).
27. **An escaped pipe at a row's end is taken for its edge.**
    `live_tables.dart:568` — `| a | b \|` is `b \` in live mode and `b \|`
    in the table model, so widths and edits disagree. Rare. *Read.*

### Lower priority

- Saving a frontmatter field rewrites untouched values in normal form:
  `1.10` → `1.1`, `007` → `7`, and a timestamp with an offset becomes UTC
  (`typed_fields.dart:104, 111, 139`).
- `trashFileName` / `trashDirName` (`files.dart:487`, `:505`) check only an
  entry of the same kind: trashing a file `X` while `.trash/X` is a folder
  fails the delete (nothing lost).
- The sync URL field's listener (`sync_settings_screen.dart:77`) fires on a
  caret move too, so tapping the field drops a loaded trust — the safe
  direction; the certificate is simply asked again.

### Second pass — status

Fixed on `fix/review-pass2` (2026-09-29), one commit per fix, each with a
test that failed on the code before it. Hashes are that branch's.

| # | Status |
|---|--------|
| 1 | Fixed, `c8f20819` — quoting is decided by reading the plain form back with the parser |
| 2 | Fixed, `c8f20819` (the rewrite) and `851c7079` (the list editor reads items as a flow list) |
| 3 | Fixed, `c8f20819` (a line break is escaped) and `ae45fd29` (an entry's lines come from the parser's spans) |
| 4 | Fixed, `ae45fd29` |
| 5 | Fixed, `851c7079` — items keep their own YAML, a chip is deleted by its place, a list a chip row cannot show has no row |
| 6 | Fixed, `c99369f1` — a byte outside UTF-8 is read as its Windows-1252 character on every path (decided with the user: saving writes UTF-8) |
| 7 | Fixed, `632fa831` |
| 8 | Fixed, `1b0f5760` |
| 9 | Fixed, `0c915947`. Left: the server clock is the one at the check, not at the download |
| 10 | Fixed, `d5ac9893` |
| 11 | Fixed, `f84d4aef` — a refusal on another host names that host and offers nothing to trust |
| 12 | Fixed, `196a1df9` |
| 13 | Fixed, `2ba8b38e`. Left: the "already shown" record lasts while the app runs, so a restart within the grace hour shows it again |
| 14 | Fixed, `065a241e` — one way to find a box on a line, quotes included |
| 15 | Fixed, `9efa5f2f` (only typing opens the panel) and `9f71580a` (a completion replaces the whole target) |
| 16 | Fixed, `3c590983` |
| 17 | Fixed, `74d889c9` |
| 18 | Fixed, `22a8a56f` — all three cases, `one` + `two` + `---` included. Left: `_quoteDepthAfter` keeps a quote open over a lazy line, and a list item swallows a `---` at the margin |
| 19 | Fixed, `5229f589` |
| 20 | Fixed, `d1622d13` — the engine's filter rules are functions the checker calls. Left: `{{include:A\|B}}` is reported wrongly and `{{include:}}` not at all (the rule is in `includes.dart`); a huge move count still throws when a note is made |
| 21 | Fixed, `080b7ae7`; and `7297ce98`, found alongside: in source mode a wide table's caret past its first piece was not drawn |
| 22 | Fixed, `94dd279c` |
| 23 | Fixed, `53886af4`. Left: the sync queue gets no hints for what changed while the watch was down; a stream *error* still triggers no rescan |
| 24, 25 | Fixed together, `980e91b3` |
| 26 | Fixed, `d6f78071` |
| 27 | Fixed, `89d05651` — live mode uses the table model's splitter. Left: the read view's `_tableRows` still has its own |
| Lower priority | The normalization on save: fixed with 5 (`851c7079`). The trash names: fixed, `670b2c90` (and the same fault in `uniqueFolderName`). The URL listener: left, it fails safe |

Found on the way and fixed apart: two export tests that could not run on
a Windows disk (`d454132b`). Still open: a migration test's teardown on
Windows (`database_migration_test.dart`, the database left open).

### Checked and found sound

Switch-during-save ordering (#334), the unsaved-notes tracker, saving
before a library switch or forget, the drop service, the tree sort cache,
the replace preview, `template_hint`, frontmatter head-range math with
CRLF; the certificate column migration, the redirect credential rule, the
certificate callback never landing on a shared client, crash reports kept
out of the library (#383); hunspell over FFI released on dispose, DST in
the date filters, the watcher's batch caps; a frontmatter fence never read
as a setext underline, the scanner's incremental rebuild over both setext
lines, checklist lines in fences never ticked, one undo step per cascade,
the shared `LineState.initial`, surrogate pairs in the tag masker.

## Third pass — findings

`v0.1.3..main` at `327a3008` (PR #489 merged), read in seven areas: the
source editor, Markdown parsing and links, sync and the updater, library
and files, templates / todo / frontmatter, the app shell, translations and
user docs. Nothing listed above — fixed or left open — is repeated.
**Read** as above; **plausible** means traced but not certain the failing
path is reached. Line numbers are at `327a3008`.

### Broken behaviour

1. **Windows: the caption buttons' hit areas outlive the title bar.**
   `ui/title_bar.dart:260` with `windows/runner/flutter_window.cpp:297` —
   `_WindowButtonsState` reports its rectangles and never withdraws them.
   Below 600 px the narrow layout draws no `AppTitleBar`, but the runner
   still answers `HTCLOSE` / `HTMAXBUTTON` / `HTMINBUTTON` at the old right
   edge: a click on an app-bar action there closes, maximizes or minimizes
   the window. Nothing sets a minimum window width. *Read.*
2. **A relative Markdown link no longer resolves.** `links/resolver.dart:282`
   — the #330 change keeps the one-candidate shortcut for bare stems only,
   and nothing normalizes `..` or a leading `/`. `[x](../Notes/a.md)` from
   `Sub/b.md` is unresolved even when `a.md` is the only one; the indexer's
   `resolveBatch` shares the tail, so these links also leave the link index.
   *Read.*
3. **The index connection leaks when its first query fails for another
   reason than damage.** `library/library_state.dart:1612` — `_openIndex`
   rethrows before `_indexDb` is set, so `_teardown` finds nothing to close.
   A locked file or a full disk leaves the connection and its isolate open;
   on Windows the file stays locked, and every retry adds one. *Read.*
4. **The spell-check rows vanish after a dictionary is picked.**
   `ui/settings_editor.dart:695` — `setDictionaries` restarts the engines,
   `available` is false until the load lands, and the screen listens to
   nothing, so the switch and the dictionary rows stay gone until it is
   reopened. *Read.*
5. **A wrapped table row anchors handles, the suggester and template hints
   on its first piece.** `markdown/render/source_view.dart:4331`
   (`_caretRectAt`) and `:2316` (`_templateSpanRect`) still use
   `_paragraphAt(line)`, which for a wrapped live-table row is piece 0; the
   piece-aware `caretRect` fix missed them. *Read.*
6. **A desktop reminder shows again after its task is edited.**
   `todo/reminder_backend_desktop.dart:88` — the "already shown" record is
   keyed by the reminder id, a hash of the whole description; changing the
   text (or `due:`) inside the grace hour makes a new id and a second
   notification. *Read.*
7. **`[[Aux]]` creates `_Aux.md`, which the link never finds.**
   `core/files.dart:292` — `sanitizeName` prefixes a Windows device stem on
   every platform (deliberately), but the resolver does not apply the same
   mapping, so the missing-note offer repeats and makes `_Aux_1.md`. *Read.*
8. **A stalled download can throw out of the sync run.**
   `sync/webdav/webdav_client.dart:370` with `sync/sync_engine.dart:1472` —
   on a body stall the client gives up while `pipe` may still hold the sink;
   `IOSink.close()` on a bound sink throws synchronously, so `.catchError`
   never attaches and a `StateError` replaces the retryable failure. Nothing
   records the error, and on Windows the temp file stays open.
   *Plausible.*
9. **Completing a book form overwrites the number typed after it.**
   `source_view.dart:3934` — accepting `page=` reopens the panel for the same
   book, and Enter or Tab after `12` writes `page=` again. *Read.*
10. **"Close library" in Settings does not save the open notes.**
    `ui/settings_maintenance.dart:212`, and `ui/shell_home_widgets.dart:177`
    (a widget or launch pointing at another library) — the #351 save ran
    only on the switch screen. *Plausible.*
11. **"Rebuild index" can run twice at once.**
    `ui/settings_maintenance.dart:68` — no busy state; a second tap tears
    down and deletes the index the first is opening, and on Windows the
    failed delete closes the library. *Plausible.*
12. **Replace All rewrites a file the editor refuses as binary.**
    `search/replace.dart:319`, `:387` — no `looksBinary` check; a UTF-16
    note is rewritten as mojibake. *Plausible.*
13. **A frontmatter edit drops the entry's indentation, anchor and comment.**
    `frontmatter/edit.dart:55` — an indented block stops parsing after an
    edit, `tags: &t [a, b]` loses `&t` and its alias breaks the panel,
    `title: A # keep` loses the comment. *Read.*
14. **The suggester stays open over a swapped buffer.**
    `source_view.dart:765` — `didUpdateWidget` does not close it, and a
    completion writes at the old offsets. *Plausible.*
15. **The suggester opens inside code.** `source_view.dart:3736` — `[[` in a
    fence or inline code offers notes and inserts one. *Read.*
16. **A note name holding `#`, `|` or `]]` is inserted as a broken link.**
    `links/suggester.dart:255` — `C# tips` is written `[[C# tips]]`, read
    back as target `c`. *Read.*
17. **Reading positions drop another device's entry.**
    `reading/reading_positions.dart:145` — pruning removes a book whose file
    has not arrived yet, and the next sync deletes the position. *Plausible.*
18. **The Windows rename fallback renames again, with no timeout.**
    `library/note_writer.dart:563` — `copyFileOver` ends in
    `staged.rename(abs)`, the call it exists to avoid (#103). *Plausible.*
19. **A merge the guard stops leaves the fetched temp behind.**
    `sync/sync_engine.dart:1744`, `:1843` — `_ChangedDuringSync` after
    `_fetch`; `.x.md.niman-tmp-sync-*` stays until the next open. *Read.*
20. **An interrupted update download keeps the installer's name.**
    `update/update_service.dart` (`downloadAsset`) — only a digest mismatch
    deletes the file, and the body has no stall timeout. *Read.*
21. **Cancelling the name dialog burns a counter.**
    `ui/shell_template_flow.dart:164` — the reservation now comes before
    the dialog. *Read.*
22. **A reminder whose notification failed is never retried.**
    `reminder_backend_desktop.dart:96` — shown is recorded before `show`.
    *Plausible.*
23. **A stray `}}` is reported as a template error.** `templates/checker.dart:178`
    — the engine keeps it as text; LaTeX and JSON in a template get a
    problem mark. *Read.*
24. **The typewriter row highlight ignores a wrapped row's piece shift.**
    `source_view.dart:6064`. Cosmetic. *Read.*
25. **The Notion import's size budget trusts declared sizes.**
    `import/notion.dart:88` — entries are inflated with `readBytes()`
    after a check on what the archive claims. *Plausible.*

### Hot paths

26. **Live tables measure every word of the table on each revision.**
    `markdown/render/live_tables.dart:586` — `_leastWidth` runs one painter
    per word even when the table fits, and the cache clears on every edit
    and every reveal change.
27. **Headings are read from disk on every key after `#`.**
    `links/suggester.dart:285` — the whole target note is read, decoded and
    outlined on the UI isolate per keystroke.
28. **Every line indented four spaces is a definition candidate.**
    `markdown/block_parser.dart:739` (`mayHold`) with
    `markdown/source_styler.dart:222` — an edit to such a line rescans all
    of them: O(n) per keystroke in code or verse.
29. **The suggester's `%q%` query sorts every match before its limit.**
    `links/suggester.dart:211` — a computed `ORDER BY` defeats the cap.
30. **`looksBinary` walks the bytes twice in Dart before the native
    decode.** `markdown/note_bytes.dart:63` — and one U+0000 refuses a note
    the index and replace accept.
31. **The installer is hashed on the UI isolate.** `update/update_service.dart`
    (`_verifyDownload`) with `core/files.dart:239` — a 100 MB file, read
    synchronously.
32. **A case-only rename lists the whole folder on the UI isolate** (Windows,
    macOS). `core/files.dart:356`.

### Translations and user docs

33. **43 keys added since v0.1.3 are English in the locales.** The
    properties panel, the source font, the certificate dialog in all 36;
    ten failure snackbars in all but Italian.
34. **New UI text is written in English in the code.** The wikilink panel
    (`wikilink_panel.dart:119`, `:364`), the book-place hints
    (`suggester.dart:302`), the template checker's messages
    (`checker.dart:169`, `:463`).
35. **`templateProblems` says "1 …" for 21, 31, …** in `uk`, `lt`, `be`;
    `hr`, `bs`, `sr` test only `count == 1`.
36. **The docs name settings sections that no longer exist.** "Settings →
    About" (`getting-started.md:43`, `settings.md:168`, the `CHANGELOG.md`
    header shown in the app), "Settings → Library" (`organization.md:41`,
    `:414`), "Settings → Auto-empty trash" (`organization.md:9`).
37. **`organization.md:86` places the fields panel in the read pane and the
    live editor**; it is above the note in both editors.
38. **Fourteen string keys are never read** (`settingsSectionAbout`,
    `settingsSectionLibrary`, `syncDoneSnack`, …).
39. **`historyOff` sends the user to "Settings, Library".**
40. **The sidebar tooltip hard-codes Ctrl+B**, which can be rebound.

Left out: `{{date:YYYY-'W'WW}}` gives the calendar year beside an ISO week
at the turn of the year — true, but already so in v0.1.3.

### Third pass — checked and found sound

Certificate pinning scope, the redirect credential rule, weak-ETag
guarding, the scheduler's joined runs, the updater's asset choice and
digest compare; the app-DB v32 migration, history sha checks, watcher
batching, pair-rename indexing; unsaved edits on a note switch, hunspell
handles, `mounted` guards in the shell diff; counter serialization, the
checker reading the engine's own rules, Android alarms skipping overdue
ones; setext rework, `cellRangesOf`, the streaming decoder, `embed_path`'s
confinement; interpolation parameters across every locale.

### Third pass — issues

Tracked as issues, to be fixed on `fix/review-pass3`:

| Issue | Findings |
|-------|----------|
| #490 | 1 |
| #491 | 2, 7, 16, 27, 29 |
| #492 | 3, 17, 18, 25, 32 |
| #493 | 4, 10, 11 |
| #494 | 5, 9, 14, 15, 24, 26 |
| #495 | 8, 19, 20, 31 |
| #496 | 12, 28, 30 |
| #497 | 6, 13, 21, 22, 23 |
| #498 | 33–40 |

### Third pass — status

Fixed on `fix/review-pass3` (2026-09-29), one commit per finding, each with a
test that failed on the code before it. Hashes are that branch's.

| # | Status |
|---|--------|
| 1 | Fixed, `01a3896d` |
| 2 | Fixed, `ba6d2e87` |
| 3 | Fixed, `740391a3` |
| 4 | Fixed, `e3e2089a` |
| 5 | Fixed, `9d9181b3` |
| 6 | Fixed, `aad27780` |
| 7 | Fixed, `b4b1f162` |
| 8 | Fixed, `eda51ebb`. Left: the escape needs a response whose socket cannot be detached (the test's fake models one); with a plain `HttpClient` the pre-fix code passes |
| 9 | Fixed, `ef0ae189` |
| 10 | Fixed, `8e44001d`; the widget target's blocked switch says so, `6d983faf` |
| 11 | Fixed, `11ec0038` |
| 12 | Fixed, `bd0304dc`. Left: the indexer, export and the other readers still accept a file the loader refuses |
| 13 | Fixed, `7535e938` |
| 14 | Fixed, `2e9d6615` |
| 15 | Fixed, `bf4bd391` |
| 16 | Fixed, `e267184a` |
| 17 | Fixed, `5aaa9b40`. Left: a book deleted while the index has no row for it (never indexed here, or rebuilt) leaves its position behind, because nothing observes that deletion. No sound fix: on disk the entry looks the same as a position the sync brought for a book whose file has not arrived, and telling them apart would need a device-local record of the files this device knew, which the rebuild that causes the gap also loses. The entry is a few bytes, and it is dropped when the file is deleted with the index intact |
| 18 | Fixed, `9dc5b2c8`; the staged file's delete after the guarded rename has the same timeout, `af5d54bf` |
| 19 | Fixed, `7f8f3ef5` |
| 20 | Fixed, `627508be` |
| 21 | Fixed, `65d1becf` |
| 22 | Fixed, `5ddba0d8` |
| 23 | Fixed, `6c8827eb` — the problem kind and its key went with it when the branch met #498 (`f073ba12`) |
| 24 | Fixed, `2f90c8a6` |
| 25 | Fixed, `987da2b3` and `e6942019` — `package:archive` does not stop at the declared size, and on `dart:io` it hands its output to a sink only after inflating the whole stream, so the first fix refused after the allocation; the entry is now inflated in chunks that stop at the budget. An entry with no content is skipped again, `cb5b8f7f`. Left: a symlink entry is inflated by `ZipDecoder.decodeStream` itself, before any budget applies |
| 26 | Fixed, `8c6c0266`. Left: a revision still clears the measurements — an edit re-measures each table once, not per word |
| 27 | Fixed, `ea1a5022`. Left: the cache is keyed on the index's revision, so headings are as of the last index run |
| 28 | Fixed, `f32fcf44` |
| 29 | Fixed, `37a51774` |
| 30 | Fixed, `7ff51222`. Left: the rule is the loader's and the replace pass's, not yet every reader's |
| 31 | Fixed, `f8390862` |
| 32 | Fixed, `2407d53c`. Left: the lookup still walks the folder, now off the UI isolate — `dart:io` has no per-name call that returns the stored case |
| 33 | Fixed, `43d46e58` |
| 34 | Fixed, `f073ba12` |
| 35 | Fixed, `9730ce2a` |
| 36 | Fixed, `87da485e` |
| 37 | Fixed, `bbeffe78` |
| 38 | Fixed, `69fa6654` — with a test that fails when a contract key is read nowhere under `lib/` |
| 39 | Fixed, `c8841d9a` |
| 40 | Fixed, `888a4f82` |

Crossings found while merging: #491's `readHeadings` seam against #498's
book-hints test (`1a6c05ac`), and #497's removal of the stray-`}}` report
against #498's externalization of the checker's messages — the `closingBraces`
kind lost its only raiser and went with its key. The analyzer infos the
index-leak and reading fixes left are cleaned in `bb86683f`.
