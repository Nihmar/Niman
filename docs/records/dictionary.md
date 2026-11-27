# Look up: a word's meaning, from dictionaries downloaded per language

Selecting a word in a book, a PDF, a scan's recognized line, a note's read
view or the editor, and reading what it means. Written before the code
(2026-11-27), as the plan the work follows; the screens are in
[docs/design/dictionary](../design/dictionary/README.md).

The constraint that shapes it is the one OCR set: **every platform gets the
same feature, and the app does not grow.** Windows and Linux have no
system dictionary at all, and Android has none an app can read, so the only
way to give all five the same capability is a dictionary of our own, on
the device. It is downloaded per language from inside the app, the first
time it is needed, as the OCR's languages are.

## Where things stood

- **Books, a note's read view and the OCR's Text pane select the same
  way**: `ReadSelectionArea` (`markdown/render/read_selection.dart`),
  Flutter's `SelectionArea` over the blocks. A selection is a
  `ReadSelection` — the block's first line, the start and end in its
  text, the text selected — and its menu offers `ReadSelectionAction`s:
  in a book *Read aloud from here*, *Highlight*, *Annotate* and *Link to
  this place* (`epub_pane_state.dart`), then Flutter's Copy and Select
  all. An action added there reaches all three surfaces.
- A long-press on a phone and a double-click on the desktop already select
  a word; nothing knows "the word under the finger" otherwise.
- **The book's language is known**: `EpubDocument.language`
  (`dc:language`, BCP 47), which picks the read-aloud voice (#1276).
- **PDFs select through pdfrx**: `_selectionMenu` in
  `pdf_document_view_state.dart` adds Highlight and Annotate to pdfrx's
  list, which `pdf_selection_menu.dart` draws compact for a pointer;
  `getSelectedText()` gives the text. **A PDF has no language for us**:
  `pdfrx_engine` 0.9.3 exposes neither the document's metadata nor its
  catalog's `/Lang`.
- **A scan's recognized line is picked whole** (`_lineMenu`, #596): an
  `OcrLine` keeps its text and the line's box, and the `.ocr.md` sidecar
  keeps lines, not words.
- **The editor's context menu** (`editor/editor_context_menu.dart`) has a
  group for the word at the caret, the spelling's suggestions and *Add to
  dictionary*.
- **Flutter already hands a selection to other apps on Android**:
  `SelectableRegion` adds the `ACTION_PROCESS_TEXT` handlers, and the
  manifest has the `<queries>` entry for them, so an installed dictionary
  app already shows in a book's and a note's selection menu (not in the
  PDF's, which pdfrx builds, nor in the editor's). That stays as it is.
- **Downloads have a shape**: `core/download/` (`Downloadable`, the
  downloader) fetches the transcription models and the OCR's engine and
  languages into the support folder, each pinned by size and SHA-256 in a
  generated catalog; the OCR engine is published on a prerelease
  (`ocr-engine-N`).
- **"Dictionary" already means something**: the spelling's personal
  dictionary (`spellcheck/personal_dictionary.dart`, *Add to dictionary*,
  #60).

## What was weighed

| Source | Where | Why not now |
|---|---|---|
| Dictionary Services (`DCSCopyTextDefinition`) and the Look Up panel (`NSView.showDefinition`) | macOS | One platform; no choice of dictionary or language without private API |
| `UIReferenceLibraryViewController` (Flutter's `LookUp.invoke`) | iOS | One platform; a system sheet whose text the app cannot read, so it cannot be annotated |
| `ACTION_PROCESS_TEXT`, the ColorDict intent | Android | Hands the word to whatever app is installed; already offered by Flutter where its selection is used |
| None | Windows | — |
| `dictd` (RFC 2229) | Linux | Rarely installed; `dict.org` is plain TCP |
| Online (Wiktionary REST, `en.wiktionary` only) | all | Sends the word out; the endpoint is in RESTBase's deprecation |
| StarDict / dictd files the user brings | all | Wanted later, not in the first round (decision 3) |

They are not rejected: they are what a later round can add on top of the
packs, each a decision of its own (see *Not now*).

The data the packs are built from is
[wiktextract](https://github.com/tatuylonen/wiktextract)'s extraction of
Wiktionary, published by kaikki.org: definitions, parts of speech,
examples, and the inflected forms with the lemma each belongs to
(`forms`, `form_of`) — the meaning and the lemmatisation from one source.
Its per-language downloads are deprecated; the raw dumps are not
(checked 2026-11-27: the English edition 2.9 GB gzipped, extracted
2026-10-30 from the 2026-10-01 dump, refreshed weekly). Hunspell's `it_IT`
carries no morphology (`st:`/`po:`), and Snowball gives stems, not lemmas,
so neither finds *caminetto* from *caminetti*.

## Decisions (2026-11-27)

1. **One engine, the same on all five platforms**: dictionaries on the
   device, read by Niman. No system dictionary, no network, no other app is
   consulted by the look-up.
2. **Packs downloaded per language** from inside the app — the only source
   in the first round. One pack per language.
3. **Not in the first round**: importing StarDict or dictd files, the
   systems' dictionaries, online look-up. The engine reads StarDict anyway
   (decision 15), so an import, if it comes, does not change it.
4. **The catalog is the app's languages**, the 37 of
   `AppLanguages.supported` (`core/language.dart`), as 35 packs: Croatian,
   Serbian and Bosnian share one Serbo-Croatian pack, as Wiktionary does
   (see *The packs*).
5. **Definitions in the language itself** wherever wiktextract extracts
   that language's own Wiktionary, its inflected forms completed from the
   English edition's where its own lack them; every other language is
   glossed in English, from the English edition. Each catalog row says
   which.
6. **The command is *Significato*** (English *Look up*); **the settings area
   is *Dictionaries***. The personal dictionary stays under Spelling. In
   the vocabulary: *dictionary* is a pack of meanings, *personal
   dictionary* is the spelling's words.
7. ***Significato* is offered for every selection**, not only a single
   word, so a menu never changes shape under the thumb. In a book on a
   phone it comes **first**, where the bar keeps it in sight, and *Read
   aloud from here* moves to second (the book's row keeps its speaker).
   Elsewhere it comes after the surface's own first actions; with a
   pointer it has a shortcut (proposed Ctrl+D / Cmd+D).
8. **The panel**: a sheet at half height on a phone, a panel of about
   380 px under the selection on the desktop, never over the line read;
   Esc or a click outside closes it, and selecting another word while it
   is open updates it. It shows the headword (the lemma), the form read
   that led to it, the language, the senses by part of speech with their
   examples, the forms and the nearby entries (each looks itself up), and
   the pack and its licence.
9. **No definition** shows the nearby entries (*Did you mean*); **no pack
   for the language** offers that pack with its size, downloads it in the
   panel and looks the word up when it ends.
10. **The language**: a book's is `dc:language`; a PDF's is the library's
    first spelling language (`spellDictionaries`) until the panel's chip
    changes it, and the choice is kept for that file; a note's is the
    library's first spelling language. The chip is always there, since a
    book in one language quotes another. No guessing from the text.
11. **The whole selection is looked up first**, since dictionaries have
    entries like *a priori*; failing that, its first word.
12. **The panel's actions are *Copy* and *Annotate with the definition***:
    the annotation sheet opens for the passage with the definition as its
    text. Flashcards come later (*Not now*).
13. **A scan's line in the first round**: *Significato* comes first in the
    line's menu, and the panel opens with the line's words as chips over
    the meaning, the one under the tap chosen, estimated from where the
    tap fell along the line's box. The sidecar's format does not change;
    per-word boxes (`RIL_WORD`) stay a possible refinement.
14. **The packs live in the support folder**, `<support>/dictionary/<id>/`,
    not in a library: they are not notes, a library syncs, and an English
    pack weighs a hundred megabytes. Which packs are installed is read
    from the folder; there is no order to keep, one pack being one
    language.
15. **A pack is a StarDict 3.0.0 dictionary** — `.ifo`, `.idx`,
    `.dict.dz` (dictzip), `.syn` — whose `.syn` carries the inflected
    forms. Its entries are a fixed HTML subset the pipeline writes
    (headword, part of speech, numbered senses, examples, forms), which
    the panel draws with its own widgets; arbitrary HTML waits for an
    import.
16. **The index is a rebuildable sidecar** beside the pack's files, built
    once on an isolate when the pack is installed: deleting it rebuilds
    it. Its shape is the engine's first measurement (see *The engine*).
17. **Published on a prerelease, pinned in the app**, as the OCR engine
    is: a tag `dictionary-pack-N` makes a workflow build every pack and
    publish it; a generated catalog in `lib/src/dictionary/` pins each
    pack's URL, size and SHA-256 for `Downloadable`.
18. **The packs are CC BY-SA 4.0 and GFDL**, Wiktionary's licences, as
    files apart from the MIT code; the attribution is in each `.ifo`, on
    the panel's foot and in the settings, citing wiktextract. No GPL code
    or data is added.

## The packs

The 37 languages and where their definitions come from. *Own edition*
means wiktextract extracts that language's Wiktionary, a "work in
progress" by kaikki's own words: the pipeline measures each, and a
language whose edition does not hold up ships the English-glossed pack
instead — the bar is set in phase 2, from the numbers, and the record is
updated with it. The senses are the English edition's count for the
language (kaikki.org, 2026-10-30), a measure of what an English-glossed
pack would hold.

| Language | App id | Definitions | English edition's senses |
|---|---|---|---|
| English | `en` | own edition | 1,795,048 |
| French | `fr` | own edition (Wiktionnaire, 702 MB gz) | 460,826 |
| German | `de` | own edition (296 MB gz) | 634,188 |
| Spanish | `es` | own edition (98 MB gz) | 879,175 |
| Portuguese | `pt` | own edition (36 MB gz) | 527,775 |
| Chinese | `zh` | own edition (224 MB gz) | 392,965 (+ Mandarin 113,730) |
| Japanese | `ja` | own edition (62 MB gz) | 237,987 |
| Italian | `it` | own edition (42 MB gz) | 720,157 |
| Dutch | `nl` | own edition (129 MB gz) | 190,953 |
| Polish | `pl` | own edition (132 MB gz) | 267,966 |
| Czech | `cs` | own edition (38 MB gz) | 85,607 |
| Greek | `el` | own edition (110 MB gz) | 112,999 |
| Turkish | `tr` | own edition (44 MB gz) | 60,762 |
| Hindi | `hi` | English | 58,698 |
| Swedish | `sv` | English | 347,823 |
| Norwegian | `nb` | English (Bokmål) | 94,218 |
| Danish | `da` | English | 68,361 |
| Basque | `eu` | English | 20,766 |
| Catalan | `ca` | English | 228,485 |
| Galician | `gl` | English | 248,965 |
| Finnish | `fi` | English | 312,312 |
| Romanian | `ro` | English | 148,191 |
| Hungarian | `hu` | English | 90,796 |
| Croatian, Serbian, Bosnian | `hr`, `sr`, `bs` | English (Serbo-Croatian, one pack) | 92,304 |
| Slovak | `sk` | English | 21,613 |
| Slovenian | `sl` | English | 9,553 |
| Estonian | `et` | English | 17,082 |
| Latvian | `lv` | English | 172,708 |
| Lithuanian | `lt` | English | 35,040 |
| Bulgarian | `bg` | English | 76,441 |
| Ukrainian | `uk` | English | 82,051 |
| Belarusian | `be` | English | 17,112 |
| Macedonian | `mk` | English | 76,803 |
| Albanian | `sq` | English | 33,499 |
| Icelandic | `is` | English | 32,882 |

- **One pass over the English edition** (24.8 GB of JSONL, streamed from
  the gzip, never held) splits every language at once: it gives the 22
  English-glossed packs and the forms the 13 own-edition packs borrow.
  Each own edition is a download of its own.
- **Sizes are measured by the pipeline**, not guessed; the settings show
  them before a download. The English pack is the largest by far; if it is
  too large for a phone, the pipeline can leave out what a reader needs
  least (etymologies are never kept; translations into other languages,
  pronunciation and archaic-only senses are candidates), and the record
  says what was cut.
- **A Serbo-Croatian entry is written in both scripts** on Wiktionary, so
  a Serbian book in Cyrillic and a Croatian one in Latin find it; the
  pipeline keeps both spellings as keys.
- **Nynorsk is not one of the app's languages**: a book tagged `nn` finds
  no pack and is offered to change the language.

## The engine — `lib/src/dictionary/`

A new module (added to the layout in `AGENTS.md`).

- `stardict_ifo.dart`, `stardict_reader.dart`: the `.ifo` header, the
  `.idx` entries (32- or 64-bit offsets, `idxoffsetbits`) and the `.syn`
  forms; written by hand, as hunspell's and Tesseract's bindings were,
  with no dependency (`dictd_reader` and `dictzip_reader` on pub.dev are
  GPL-3; `dict_reader` is MIT and may be measured against).
- `dictzip.dart`: random access into `.dict.dz` — the gzip header's `RA`
  field lists the chunks, each inflated alone (`ZLibDecoder(raw: true)`).
- `dictionary_index.dart`: the sidecar. The smallest that serves a binary
  search over the pack's own sorted keys — a table of each key's offset
  in a normalized copy of the keys, a few megabytes for a million
  entries — is tried first, measured on the English pack (a perf test in
  the project's shape: the number printed, the bar behind `NIMAN_PERF`);
  SQLite only if the measurement asks for it. Either way the sidecar is
  rebuilt from the pack's files and nothing else.
- `dictionary_worker.dart`: one long-lived isolate holding the open files,
  as the OCR's worker does; a look-up is a message, and the UI isolate
  never touches the disk. The same look-up is cached in memory while the
  panel is open.
- `lookup_term.dart`: the candidates for a selection, tried in order
  until one is found:
  1. the text cleaned: punctuation and typographic quotes trimmed, soft
     hyphens and a PDF's ligatures (`ﬁ` → `fi`) undone, a word hyphenated
     across a line joined (`cam-␤mino` → `cammino`), NFC;
  2. the elisions of the languages that have them (Italian, French,
     Catalan): `dell'acqua` → `acqua`, `l'homme` → `homme`;
  3. the term exact, then lowercased — Unicode lowercasing with the
     Turkish dotted and dotless *i* handled for `tr`;
  4. the `.syn` forms: `caminetti` → `caminetto`, `andasse` → `andare`;
  5. nothing found: the nearest keys by prefix, *Did you mean*.
- `dictionary_language.dart`: decision 10, from the surface's own
  knowledge, and the per-file choice for a PDF kept with the app's
  settings.
- `dictionary_catalog.dart` (generated by `tool/dictionary_catalog.dart`)
  and `dictionary_pack.dart` (`Downloadable`); `dictionary_installation.dart`
  reads what `<support>/dictionary/` holds, off the UI isolate.
- `dictionary_entry.dart`: what the panel draws — headword, form found,
  language, senses by part of speech with examples, forms, licence.

**Scale.** A look-up is a binary search and a chunk read: no scan, at any
size. The sidecar is built once per pack, on an isolate, with progress.
Chinese and Japanese do not separate words with spaces: the word a
long-press selects is the text engine's word boundary (ICU), and the
whole-selection-first rule (decision 11) lets a reader drag over a longer
word; Japanese conjugations reach their lemma only through the forms the
pipeline carries, measured in phase 2.

## The pipeline — `tool/dictionary_pack.dart`

- Reads wiktextract JSONL as a stream (the English edition's 24.8 GB never
  in memory), keeps the entries of the languages it is building, and
  writes each pack: entries in the HTML subset of decision 15, sorted as
  StarDict sorts, the forms into `.syn`, compressed with dictzip.
- Per own-edition language, merges that edition's entries with the
  English edition's forms for the same language where its own lack them.
- Reports per pack: entries, senses, forms, size, and the own edition's
  coverage against the English one — the numbers the bar of *The packs*
  is set from.
- Runs in `.github/workflows/dictionary-pack.yml` on a
  `dictionary-pack-N` tag, publishing every pack on that prerelease, and
  writes the catalog the app pins. `AGENTS.md`'s *Release* section names
  the tag beside `ocr-engine-N`.
- A small sample of the extraction is a test fixture, so the pipeline is
  tested without the dumps.

## The surfaces

- **`ui/dictionary_lookup_flow.dart`**: from a selection (text, language,
  anchor) to the panel, taking explicit arguments. `epub_pane_state`,
  `pdf_document_view_state`, the read view, the OCR Text pane, the OCR
  line menu and `editor_context_menu` only wire it in.
- **`ui/dictionary_panel.dart`** (the content), with the phone's sheet and
  the desktop's panel around it; **`ui/settings_dictionaries.dart`**.
- **Books, the read view, the OCR Text pane**: a `ReadSelectionAction`.
- **PDFs**: `_selectionMenu` adds it after Annotate; the pointer's menu
  draws it with its shortcut.
- **A scan's line**: `_lineMenu` gains it first (decision 13).
- **The editor**: an entry in the word's group of the context menu, for
  the selection or the word at the caret, as the spelling's entries are.
- Icons are outline; nothing appears or disappears in a row as a state
  changes.

## Not now

- **Flashcards**: *Create a flashcard* adding `- word :: definition` to a
  `type: flashcard` note of the book (`deck: Vocabulary/<book>`), which is
  then also the history of the words looked up, on disk. Decided for a
  later round.
- **Importing StarDict or dictd files**, the **systems' dictionaries**
  (macOS Dictionary Services and Look Up, iOS's reference library, Android
  apps by `PROCESS_TEXT` or the ColorDict intent, a Linux `dictd`), and
  **online look-up**: each a decision of its own, on top of the packs.
- **Per-word boxes on scans**, for a tap that needs no chips.
- **A paragraph's own `xml:lang`** in a book, finer than `dc:language`.

## Phases

Each phase lands on Android, Linux, Windows, macOS and iOS together.

| Phase | What | Size |
|---|---|---|
| 1 | The engine: StarDict, dictzip, the sidecar index and its perf test, the worker, the candidates; no UI | L |
| 2 | The pipeline, the workflow and the first `dictionary-pack-1`; the catalog; the bar for own editions and the measured sizes written back here | L |
| 3 | Settings → Dictionaries: the catalog, download, removal, the PDF language note | M |
| 4 | The panel and the flow; *Significato* in books (first on a phone), the read view, the OCR Text pane and PDFs; the language and its chip; *Copy*, *Annotate with the definition*; no definition, no pack | L |
| 5 | A scan's line: the menu entry and the chips | M |
| 6 | The editor's context menu | S |

Phases 1 and 2 can run side by side (the pipeline's test fixture is a
small pack for the engine's tests); 3 needs 1 and 2; 4 needs 1 and 3; 5
and 6 need 4. The user guide changes with the phase that changes what a
user sees: `organization.md` beside *Annotating* and *Highlighting a PDF
or a book*, `settings.md` for the area, `text-recognition.md` for a
scan's line, `editing.md` for the editor's menu, and `platforms.md`,
which says the feature is the same on all five.

## Risks

- **The own editions are "work in progress"**: one may be thin or
  mis-parsed. The bar of *The packs* is the answer, and English glosses the
  fallback.
- **The English pack's size** on a phone; cut as *The packs* says, and
  measured.
- **CI time and disk**: the English edition is 2.9 GB to download and
  stream on a hosted runner; the workflow runs on a tag only, never on a
  PR.
- **Wiktionary's sort and ours**: StarDict sorts with its own comparison,
  and a key out of order breaks a binary search; the pipeline writes the
  order the engine searches, and a test checks every key is found.
- **CC BY-SA's share-alike** binds the packs, not the app; the packs stay
  separate files with their notice.
