# Issue triage for 0.0.9

The issues the 0.0.9 branch should close, each with the evidence in the
tree. `integration/unmerged`, from `main` @ `16691f72` (0.0.8) to
`ebd14287` (395 commits).

**How to use it.** Run the check under a box, tick the box, and leave a
word when it fails. When the boxes are settled, one commit closes the
ticked issues with a comment citing the evidence, and the hashes land in
the log at the end. A box left empty is an issue kept open, with the
reason noted under it.

Release title for 0.0.9 (decided): **A homegrown editor, and a lot more
to play with.** — see [releasing](docs/dev/releasing.md).

## A. To close — this branch implemented them

- [x] **#7 — Daily Notes/Journal.** Journal merged (`feat/journal-7`);
  [journal](docs/user/journal.md). `0737231e`, `de1d8346`, `2496394c`.
- [x] **#243 — Markdown surface, phase 1: the engine, measured (no UI).**
  The unified surface is in the tree (`lib/src/markdown/`).
- [x] **#245 — phase 3: `source` mode replaces `re_editor`.** `re_editor`
  is gone; the source surface is `a6138374` and the commits around it.
- [x] **#246 — phase 4: `live` mode replaces `flutter_quill`.**
  `flutter_quill` is gone; `live` is `a427f893` and the commits around it.
- [x] **#247 — phase 5: delete the old world.** `2f06f6ea`.
- [x] **#248 — One Markdown surface.** `19f0b841` (`MarkdownSurface`),
  `2f06f6ea`.
- [x] **#260 — Group the editor's context menu.** `2b9f3dbd`.
- [x] **#261 — Live mode: practical table editing.** `d561f4fd`,
  `fb350c24`.
- [x] **#262 — Insert a table from the toolbar and the context menu.**
  `7a837959`.
- [x] **#263 — Insert a checkbox list.** `d526c885`.
- [x] **#264 — Commands is the palette's reference.** `b13b820a`.
- [x] **#265 — In-app Markdown cheatsheet.** `d4d5937d`.
- [x] **#267 — Todo description wraps and grows downward.** `dfb0354b`.
- [x] **#268 — Todo date and reminder picked in the dialog.** `3dba81a8`.
- [x] **#269 — Themes page with custom themes.** `a4f61ebb`, `49306181`,
  `7c11ce47`, `2b0f2745`, `86759450`.
- [x] **#279 — `==highlight==` and callouts in every mode.** `3cf9b5b1`,
  `d67e4655`.
- [x] **#280 — EPUB in the attachment viewer.** `846dff2c`, `c9c7fe83`,
  `f739e749`.
- [x] **#281 — Books and PDFs reopen where they were left.** `343ff8f4`,
  `1198da6b`.
- [x] **#282 — Links into a book or a PDF.** `e4655a94`, `29b9c9de`,
  `b7ef3f03`, `2fa33721`.
- [x] **#283 — Select part of a paragraph in the read view.** `f434ab52`.
- [x] **#284 — Annotate a book or a PDF in a companion note.** `bbefe5d1`,
  `093c6f0d`, `fbf3c7c8`.
- [x] **#285 — Marks where a book or PDF was annotated.** `f14da2ac`,
  `33df5232`.
- [x] **#286 — Forget library, the open one too.** `75a86441`, branch
  `feat/forget-open-library`.
- [x] **#228 — WYSIWYG: tables as tables.** Superseded: `live` draws and
  edits tables (#261).
- [x] **#8 — Smart table creation.** Covered by #261 (rows and columns,
  menu, Tab).

## B. To verify before closing — probably moot or superseded

- [x] **#253 — Display math inside a blockquote or a list item.** The
  read/live parity aligned a quote's content; check the display-math case
  specifically.
- [x] **#254 — The WYSIWYG costs a 2.1 s frame on a 931 KB note.** That
  WYSIWYG (`flutter_quill`) is gone; if `live` is fine on the fixture,
  close it (or replace it with a fresh measurement).
- [x] **#255 — A legacy preview is mounted and thrown away.** The legacy
  preview is deleted (phase 5).
- [x] **#231 — Android: the selection menu stays after tapping
  elsewhere.** The old selection toolbar is gone; check the new surface.
- [x] **#49 — List parser: benchmark before optimizing.** The old parser
  is gone; the surface scans incrementally.
- [x] **#48 — Keep hidden tab bodies laid out.** The workspace keeps the
  recent tabs mounted; check the "no `build` > 12 ms" criterion.
- [ ] **#95 — Prompt to exempt Niman from battery optimization.** The
  warning and its battery page are in (`fix(android): the battery warning
  opens Niman's own battery page`); check on an OEM build. --> situazione migliorata, ma non è sufficiente, il toggle della schermata che viene aperta non è sufficiente a far sparire la l'avviso... Manca il "Consenti attività in bakground". inoltre, se non sono consentite le notifiche, la schermata todo dovrebbe avvisare anche di quello
- [x] **#36 — Documented release procedure.** `docs/dev/releasing.md` and
  the README's "Release".
- [x] **#33 — Android release-signed APK + AAB.** The signed APK ships;
  no `.aab` is produced (the workflow builds `apk` only) — decide whether
  the store bundle is still wanted before closing. --> no store bundle
- [x] **#31 — M7: Packaging & Release.** The artifacts ship; tied to
  #33's AAB.

## C. Not closed — not done here

Kept for the record, no box:

Import #25 · Export #24 · PDF export #63 · Encryption #26 · Onboarding
#27 · Guided tour #266 · Frontmatter editing #157 · Git sync #74 ·
Markdown linter #72 --> in realtà c'è un markdown linter · Template syntax checker #71 · Log note type #57 ·
Android share-in #40 · Platform parity #39 --> raggiunta con la 0.0.8 direi · Scale #22/#21 --> raggiunta con i vari lavori su huge notes · Performance
#45 --> raggiunta con i vari lavori su huge notes · Desktop perf audit #62 --> raggiunta con i vari lavori su huge notes · Source font setting #259 · Drag-drop on
KDE #224 · `.txt`/`[-]`/PATH #233 · Split files #50/#51/#100 · First
tagged release #38 --> fatta, era la 0.0.1 · Open-source readiness #37 --> manca il contributing · Scale tests #30  --> raggiunta con i vari lavori su huge notes · the
on-device verification set #270–#278 --> manca solo da testare IME diversi da GBoard.

Already closed by earlier commits (referenced but not open): #256, #257,
#258.

## D. Already resolved before this branch — still open, close them too

- [x] **#151 — Custom title bar on Windows.** Shipped in 0.0.7/0.0.8.
- [x] **#152 — Desktop UI redesign: mockups before code.**
  `docs/design/desktop-0.0.8/`.
- [x] **#153 — 0.0.8, the desktop round.** 0.0.8 released.
- [x] **#34 — Linux packaging.** `.tar.gz`, `.AppImage`, `.pkg.tar.zst`.
- [x] **#35 — Windows packaging.** Inno Setup installer, portable `.zip`.
- [x] **#32 — Final branding.** Name and icon.
- [x] **#160 — Android auto-update signing.** Fixed with the 0.0.7 key.
- [x] **#6 — Home-screen widgets.** Both ship; only two list-note row
  operations remain — close, or split those out first. --> close

## Closure log

Filled in when the boxes above are settled: issue → the commit or comment
that closed it.

_(empty)_
