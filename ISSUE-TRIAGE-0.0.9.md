# Issue triage for 0.0.9

The issues the 0.0.9 branch closes, and the ones it leaves open, each with
the evidence in the tree. `integration/unmerged`, from `main` @ `16691f72`
(0.0.8) to this commit.

**State: verified and closed.** The boxes were checked on 2026-09-25 and
**45 issues were closed** on the evidence below, each with a comment on
the issue citing it. The last two — **#95** and **#287** — were worked
and closed after that first pass. Everything in section C stays open (the
user's reading of each is kept there).

Release title for 0.0.9 (decided): **A homegrown editor, and a lot more
to play with.** — see [releasing](docs/dev/releasing.md).

## A. Closed — this branch implemented them

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

## B. Closed after a check

- [x] **#253 — Display math inside a blockquote or a list item.** The
  read/live parity aligned a quote's content; checked and closed.
- [x] **#254 — The WYSIWYG costs a 2.1 s frame on a 931 KB note.** That
  WYSIWYG (`flutter_quill`) is gone; the unified `live` mode replaces it.
- [x] **#255 — A legacy preview is mounted and thrown away.** The legacy
  preview is deleted (phase 5).
- [x] **#231 — Android: the selection menu stays after tapping
  elsewhere.** The old selection toolbar is gone; the unified surface
  selection replaces it.
- [x] **#49 — List parser: benchmark before optimizing.** The old parser
  is gone; the surface scans incrementally.
- [x] **#48 — Keep hidden tab bodies laid out.** The workspace keeps the
  recent tabs mounted; checked against the "no `build` > 12 ms"
  criterion.
- [x] **#95 — Prompt to exempt Niman from battery optimization.** Closed
after a second pass. The warning follows the switches the system shows:
the background restriction (`isBackgroundRestricted`), not Doze
(`isIgnoringBatteryOptimizations`, which the page Niman opened did not
control, so the switch the user could reach never cleared the banner);
the notification check now feeds the banner without asking, so it warns
before the first reminder; the task dialog warns where the reminder is
set; and **Open settings** opens the App info page.
- [x] **#36 — Documented release procedure.** `docs/dev/releasing.md` and
  the README's "Release".
- [x] **#33 — Android release-signed APK + AAB.** The signed APK ships;
  the store bundle (`.aab`) is **decided against**. Closed.
- [x] **#31 — M7: Packaging & Release.** The artifacts ship.

## C. Left open — not done here

The user's reading of each, noted while checking:

- **#25 Import · #24 Export · #63 PDF export** — not done.
- **#26 Encryption · #27 Onboarding · #266 Guided tour** — not done.
- **#157 Frontmatter editing · #74 Git sync · #71 Template syntax checker
  · #57 Log note type** — not done.
- **#72 Markdown linter** — the user notes a linter exists; what ships is
  *Tidy the Markdown*, a formatter, not the configurable inline linter
  #72 asks for. Left open.
- **#40 Android share-in** — not done. **#39 Platform parity** — the user
  reads it as reached with 0.0.8, but #40 is the piece still out, so the
  epic stays open.
- **#22/#21 Scale · #45 Performance · #62 Desktop perf audit · #30 Scale
  tests** — the user reads these as reached by the huge-notes work; they
  keep open sub-issues (IME, import/export, encryption), so they stay open
  until those are settled.
- **#259 Source font setting · #224 Drag-drop on KDE · #233
  `.txt`/`[-]`/PATH · #50/#51/#100 Split files · #47 Shell alive under
  fullscreen notes · #109 `File.rename` on Windows · #169 Windows Snap
  Layouts** — not done. (#287, the scrolling titles, was worked and closed
  after the triage.)
- **#37 Open-source readiness** — CONTRIBUTING is missing.
- **#270–#278 On-device verification** — only IMEs other than GBoard are
  left to test.

Already closed by earlier commits (referenced but not open): #256, #257,
#258.

## D. Closed — resolved before this branch

- [x] **#151 — Custom title bar on Windows.** Shipped in 0.0.7/0.0.8.
- [x] **#152 — Desktop UI redesign: mockups before code.**
  `docs/design/desktop-0.0.8/`.
- [x] **#153 — 0.0.8, the desktop round.** 0.0.8 released.
- [x] **#34 — Linux packaging.** `.tar.gz`, `.AppImage`, `.pkg.tar.zst`.
- [x] **#35 — Windows packaging.** Inno Setup installer, portable `.zip`.
- [x] **#32 — Final branding.** Name and icon.
- [x] **#160 — Android auto-update signing.** Fixed with the 0.0.7 key.
- [x] **#6 — Home-screen widgets.** Both ship; the two missing list-note
  row operations are accepted as out.
- [x] **#38 — First tagged release (v1.0.0).** Releases have shipped since
  0.0.1; the project is already officially released, no v1.0.0 tag needed.

## Closure log

Closed on 2026-09-25, each with a comment on the issue citing the
evidence in this file:

- **A (25):** #7, #243, #245, #246, #247, #248, #260, #261, #262, #263,
  #264, #265, #267, #268, #269, #279, #280, #281, #282, #283, #284, #285,
  #286, #228, #8.
- **B (9):** #253, #254, #255, #231, #49, #48, #36, #33, #31.
- **D (9):** #151, #152, #153, #34, #35, #32, #160, #6, #38.
- **After the pass (2):** #95, #287.

**Left open:** every issue in section C.
