// The Romanian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class RomanianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'ianuarie',
    'februarie',
    'martie',
    'aprilie',
    'mai',
    'iunie',
    'iulie',
    'august',
    'septembrie',
    'octombrie',
    'noiembrie',
    'decembrie',
  ];
  @override
  List<String> get monthNamesShort => const [
    'ian',
    'feb',
    'mar',
    'apr',
    'mai',
    'iun',
    'iul',
    'aug',
    'sept',
    'oct',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'luni',
    'marți',
    'miercuri',
    'joi',
    'vineri',
    'sâmbătă',
    'duminică',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'lun',
    'mar',
    'mie',
    'joi',
    'vin',
    'sâm',
    'dum',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Coș';
  @override
  String get trashSubtitle =>
      'Elementele șterse se mută în .trash/ (dezactivat = ștergere '
      'permanentă)';
  @override
  String get trashAutoEmptyTitle => 'Golire automată a coșului';
  @override
  String get trashAutoEmptySubtitle =>
      'Ștergerile mai vechi dispar definitiv la deschiderea bibliotecii';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Niciodată'
      : days == 1
      ? '1 zi'
      : days % 100 == 0 || days % 100 >= 20
      ? '$days de zile'
      : '$days zile';
  @override
  String get debugLogsTitle => 'Jurnale de depanare';
  @override
  String get debugLogsSubtitle =>
      'Înregistrează evenimentele aplicației într-un buffer de memorie';
  @override
  String get lineNumbersTitle => 'Numerele de linie';
  @override
  String get lineNumbersSubtitle =>
      'Afișează coloana cu numerele de linie în editorul de note';
  @override
  String get readableLineLengthTitle => 'Lungime de rând lizibilă';
  @override
  String get readableLineLengthSubtitle =>
      'Păstrează textul notei într-o coloană centrată în loc de toată lățimea '
      'ferestrei';
  @override
  String get noteColumnWidthTitle => 'Lățimea coloanei';
  @override
  String get noteColumnWidthSubtitle =>
      'Cât de lată este coloana notei, în pixeli';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Tastatura la deschidere';
  @override
  String get keyboardOnOpenSubtitle =>
      'Afișează tastatura la deschiderea unei note (dezactivat = la prima '
      'atingere)';
  @override
  String get editorKindSource => 'Sursă Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Sursă Markdown, așa cum e scrisă';
  @override
  String get editorKindWysiwygSubtitle => 'Text formatat, editat pe loc';
  @override
  String get settingsFolderToCreate => 'de creat';
  @override
  String get settingsSearchHint => 'Caută în setări';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 setare găsită' : '$count setări găsite';
  @override
  String get settingsToggleOn => 'Activat';
  @override
  String get settingsToggleOff => 'Dezactivat';
  @override
  String get switchToWysiwygTooltip => 'Comută la editorul WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Comută la sursa Markdown';
  @override
  String get switchToSourceLabel => 'Sursă';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aspect';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliotecă';
  @override
  String get settingsSectionReminders => 'Mementouri';
  @override
  String get settingsSectionShortcuts => 'Tastatură';
  @override
  String get keyboardShortcutsTitle => 'Scurtături de tastatură';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bibliotecă $name';
  @override
  String get settingsGroupLibraryHint => 'se aplică numai acestei biblioteci';
  @override
  String get settingsGroupMaintenance => 'Mentenanță';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Dosare și căi';
  @override
  String get settingsAreaTrashHistory => 'Coș și cronologie';
  @override
  String get settingsAreaDiagnostics => 'Diagnostic și info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Necesită o tastatură fizică conectată';
  @override
  String get settingsSectionUpdates => 'Actualizări';
  @override
  String get autoUpdateTitle => 'Actualizări automate';
  @override
  String get autoUpdateSubtitle =>
      'Verifică GitHub Releases la pornire și la fiecare 6 ore';
  @override
  String get checkForUpdatesTitle => 'Caută actualizări';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version este disponibil';
  @override
  String get updateUpToDate => 'Niman este actualizat';
  @override
  String get updateCheckFailed => 'Verificarea actualizărilor a eșuat';
  @override
  String updateSavedTo(Object path) => 'Actualizare salvată în $path';
  @override
  String get updateInstallerStarted => 'Programul de instalare a pornit';
  @override
  String get settingsSectionDiagnostics => 'Diagnostic';
  @override
  String get settingsSpellCheckTitle => 'Verificarea ortografiei';
  @override
  String get settingsSpellCheckSubtitle =>
      'Subliniază greșelile de ortografie în timp ce scrii.';
  @override
  String get spellCheckDictionaryTitle => 'Dicționar';
  @override
  String get spellCheckDictionarySystem => 'Implicitul sistemului';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Alegere dicționare';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Alege toate limbile în care este scrisă biblioteca. Un cuvânt '
      'trece dacă oricare dintre dicționarele alese îl cunoaște; fără '
      'selecție, decide limba sistemului.';
  @override
  String get spellCheckNoDictionaries =>
      'Nu s-au găsit dicționare pe acest sistem.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Verificarea ortografiei';
  @override
  String get spellCheckTitle => 'Ortografie';
  @override
  String get spellCheckEmpty => 'Nicio greșeală de ortografie.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nu este instalat pe acest sistem.';
  @override
  String get spellCheckNoSuggestions => 'Nicio sugestie';
  @override
  String spellCheckCount(int count) => '$count de verificat';
  @override
  String spellCheckLine(int line) => 'linia $line';
  @override
  String get addWordToDictionary => 'Adaugă în dicționar';

  @override
  String indentWidthValue(int spaces) => '$spaces spații';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Luminanță';
  @override
  String get themeBrightnessSubtitle =>
      'Clar, întunecat sau setarea dispozitivului';
  @override
  String get themeBrightnessSystem => 'Sistem';
  @override
  String get themeBrightnessDay => 'Clar';
  @override
  String get themeBrightnessNight => 'Întunecat';
  @override
  String get themeTitle => 'Temă';
  @override
  String get themeSubtitle => 'Culorile interfeței și ale notei';
  @override
  String get themePaletteSystem => 'Sistem';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Teme';
  @override
  String get themesInUse => 'În uz';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Temă nouă';
  @override
  String get themeNewName => 'Nume';
  @override
  String get themeNewStartFrom => 'Pornește de la';
  @override
  String get themeNewRandom => 'Culori aleatorii';
  @override
  String get themeNameTaken => 'Există deja o temă cu acest nume';
  @override
  String themeDeleteBody(String name) =>
      'Ștergi „$name”? Culorile se pierd definitiv.';
  @override
  String get themeDuplicate => 'Duplică';
  @override
  String get themeMenuTooltip => 'Acțiuni pentru temă';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Editează';
  @override
  String get themeEditorTitle => 'Editează tema';
  @override
  String get themeEditorChrome => 'Interfață';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Liste de sarcini (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Fiecare culoare poartă numele din fișierul exportat';
  @override
  String get themeEditorDiscardTitle => 'Renunță la modificări';
  @override
  String get themeEditorDiscardBody =>
      'Culorile pe care le-ai modificat nu se salvează';
  @override
  String get themeEditorDiscard => 'Renunță';
  @override
  String get themeEditorBadColor => 'Folosește #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Exportă';
  @override
  String themeExportDone(String where) => 'Tema exportată în $where';
  @override
  String themeFileFailed(String error) => 'Tema nu a putut fi mutată: $error';
  @override
  String get themeImport => 'Importă';
  @override
  String get themeImportInvalid => 'Acest fișier nu este o temă Niman';
  @override
  String themeImportVersion(int version) =>
      'Această temă provine dintr-un Niman mai nou (versiunea $version)';
  @override
  String themeImportBadRole(String role) =>
      'Fișierul nu dă nicio culoare pentru „$role”';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Mărimea textului interfeței';
  @override
  String get uiTextScaleSubtitle =>
      'Arborele, filele și dialogurile; peste setarea sistemului';
  @override
  String get noteTextScaleTitle => 'Mărimea textului notei';
  @override
  String get noteTextScaleSubtitle =>
      'Editorul și previzualizarea, mereu de acord';
  @override
  String get epubLookTitle => 'Aspectul cărților';
  @override
  String get epubLookSubtitle =>
      'Tema, fontul și dimensiunea textului cărților EPUB, separat de note';
  @override
  String get epubSameAsApp => 'Ca aplicația';
  @override
  String get epubFontTitle => 'Font';
  @override
  String get epubFontSerif => 'Serif';
  @override
  String get epubFontSans => 'Sans serif';
  @override
  String get epubFontMono => 'Monospațiat';
  @override
  String get epubTextSizeTitle => 'Dimensiunea textului';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formatul linkului';
  @override
  String get linkTypeSubtitle => 'Ce inserează butonul de link în editor';
  @override
  String get linkTypeWikilink => 'Link wiki';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Creează notele lipsă în';
  @override
  String get missingNoteLocationRoot => 'Rădăcina bibliotecii';
  @override
  String get missingNoteLocationCurrentFolder => 'Dosar curent';
  @override
  String get indentWidthTitle => 'Lățimea indentării';
  @override
  String get indentWidthSubtitle =>
      'Spațiile adăugate pe fiecare nivel de indentare în editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Limba';
  @override
  String get languageSubtitle => 'Limba propriului text al aplicației';
  @override
  String get languageSystem => 'Sistem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Adaugă un element';
  @override
  String get listAddTooltip => 'Adaugă un element';
  @override
  String get listEmpty => 'Niciun element încă';
  @override
  String get listDragHandleLabel => 'Schimbă ordinea elementului';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Nicio înregistrare încă';
  @override
  String get audioRecord => 'Înregistrează';
  @override
  String get audioStop => 'Oprește';
  @override
  String get audioPlay => 'Redă';
  @override
  String get audioDelete => 'Șterge înregistrarea';
  @override
  String get audioImport => 'Importă un fișier audio';
  @override
  String get audioRecording => 'Se înregistrează…';
  @override
  String get audioPermissionDenied =>
      'Permisiunea pentru microfon a fost refuzată — este necesară pentru '
      'înregistrare.';
  @override
  String get newAudioNoteTitle => 'Notă vocală nouă';
  @override
  String get newAudioNoteDefault => 'Înregistrarea mea';
  @override
  String get showAudioTooltip => 'Afișează înregistrările';
  @override
  String get audioMessageHint => 'Scrie o notă…';
  @override
  String get audioSend => 'Trimite';
  @override
  String get audioRename => 'Redenumește înregistrarea';
  @override
  String get audioDescriptionHint => 'Descrie această înregistrare…';
  @override
  String get audioEditDescription => 'Editează descrierea';
  @override
  String get audioDeleteNote => 'Șterge nota';
  @override
  String get audioEditNote => 'Editează nota';
  @override
  String get audioPause => 'Pauză';
  @override
  String get audioEditTitle => 'Editează titlul';
  @override
  String get audioTitleHint => 'Titlul acestei înregistrări…';
  @override
  String audioUntitled(int n) => 'Înregistrarea $n';
  @override
  String get audioMoreActions => 'Mai multe acțiuni';
  @override
  String get audioDiscardRecording => 'Renunță la înregistrare';
  @override
  String get audioPauseRecording => 'Întrerupe înregistrarea';
  @override
  String get audioResumeRecording => 'Reia înregistrarea';
  @override
  String get audioRecordingPaused => 'În pauză';
  @override
  String get audioSavingRecording => 'Se salvează…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Notă rapidă';
  @override
  String get trayOpen => 'Deschide Niman';
  @override
  String get trayQuit => 'Ieși';
  @override
  String get closeToTrayTitle => 'Închide în zona de notificare';
  @override
  String get closeToTraySubtitle =>
      '× al ferestrei ascunde Niman și îl lasă pornit, așa că mementourile '
      'vin în continuare. Se iese din meniul pictogramei.';
  @override
  String get shortcutNewTodo => 'Sarcină nouă';
  @override
  String get shortcutNewNote => 'Notă nouă';
  @override
  String get shortcutNewList => 'Listă nouă';
  @override
  String get shortcutNewAudio => 'Notă vocală nouă';
  @override
  String get shortcutToggleSidebar => 'Afișează sau ascunde filtrul';
  @override
  String get shortcutCloseTab => 'Închide nota curentă';
  @override
  String get shortcutNextTab => 'Nota deschisă următoare';
  @override
  String get shortcutPreviousTab => 'Nota deschisă anterioară';
  @override
  String get shortcutEditorSection => 'În editor';
  @override
  String get shortcutFormatSection => 'Formatare';
  @override
  String get shortcutFind => 'Caută';
  @override
  String get shortcutReplace => 'Caută și înlocuiește';
  @override
  String get shortcutSavingNote =>
      'Modificările se salvează automat, deci nu există scurtătură pentru '
      'salvare.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Se încarcă…';
  @override
  String get noteStatusSaving => 'Se salvează…';
  @override
  String get noteStatusUnsaved => 'Nesalvat';
  @override
  String get noteStatusSaved => 'Salvat';
  @override
  String get noteStatusError => 'Eroare';
  @override
  String get noteNotText =>
      'Acest fișier nu este o notă text, așa că Niman nu îl poate afișa aici.';
  @override
  String get noteLoadFailed => 'Această notă nu a putut fi deschisă.';
  @override
  String wordCount(int count) => count == 1
      ? '1 cuvânt'
      : count % 100 >= 20 || count == 0
      ? '$count de cuvinte'
      : '$count cuvinte';
  @override
  String get outlineTooltip => 'Structură';
  @override
  String get outlineNoHeadings => 'Niciun titlu';
  @override
  String get outlineNoTitle => '(fără titlu)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Îngroșat';
  @override
  String get toolbarItalic => 'Cursiv';
  @override
  String get toolbarStrikethrough => 'Tăiat';

  @override
  String get toolbarHighlight => 'Evidențiat';
  @override
  String get toolbarSuperscript => 'Indice sus';
  @override
  String get toolbarUnderline => 'Subliniat';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Bloc de cod';
  @override
  String get toolbarImage => 'Inserează imagine';
  @override
  String get toolbarTable => 'Tabel';
  @override
  String get tableRow => 'Rând';
  @override
  String get tableColumn => 'Coloană';
  @override
  String get tableAddRowAbove => 'Inserează rând deasupra';
  @override
  String get tableAddRowBelow => 'Inserează rând dedesubt';
  @override
  String get tableMoveRowUp => 'Mută rândul în sus';
  @override
  String get tableMoveRowDown => 'Mută rândul în jos';
  @override
  String get tableDuplicateRow => 'Duplică rândul';
  @override
  String get tableDeleteRow => 'Șterge rândul';
  @override
  String get tableAddColumnLeft => 'Inserează coloană la stânga';
  @override
  String get tableAddColumnRight => 'Inserează coloană la dreapta';
  @override
  String get tableMoveColumnLeft => 'Mută coloana la stânga';
  @override
  String get tableMoveColumnRight => 'Mută coloana la dreapta';
  @override
  String get tableAlignLeft => 'Aliniază la stânga';
  @override
  String get tableAlignCenter => 'Centrează';
  @override
  String get tableAlignRight => 'Aliniază la dreapta';
  @override
  String get tableDuplicateColumn => 'Duplică coloana';
  @override
  String get tableDeleteColumn => 'Șterge coloana';
  @override
  String get tableSortAscending => 'Sortează după coloană (A → Z)';
  @override
  String get tableSortDescending => 'Sortează după coloană (Z → A)';
  @override
  String get tableAddRow => 'Adaugă rând';
  @override
  String get tableAddColumn => 'Adaugă coloană';
  @override
  String get cheatsheetTitle => 'Fițuică Markdown';
  @override
  String get cheatsheetCopy => 'Copiază';
  @override
  String get cheatsheetCopied => 'Copiat';
  @override
  String get cheatsheetInsert => 'Inserează în notă';
  @override
  String get cheatsheetWritten => 'Scris';
  @override
  String get cheatsheetShown => 'Afișat';
  @override
  String get cheatHeadings => 'Titluri';
  @override
  String get cheatEmphasis => 'Aldin, cursiv, tăiat';
  @override
  String get cheatHtmlFormats => 'Subliniat, exponent, indice';
  @override
  String get cheatLists => 'Liste';
  @override
  String get cheatChecklists => 'Liste de verificare';
  @override
  String get cheatQuotes => 'Citate';

  @override
  String get cheatCallouts => 'Casete evidențiate';
  @override
  String get cheatLinks => 'Linkuri';
  @override
  String get cheatWikilinks => 'Linkuri către note';
  @override
  String get cheatEmbeds => 'Imagini și încorporări';
  @override
  String get cheatTags => 'Etichete';
  @override
  String get cheatInlineCode => 'Cod într-o propoziție';
  @override
  String get cheatCodeBlocks => 'Blocuri de cod';
  @override
  String get cheatMath => 'Matematică';
  @override
  String get cheatTables => 'Tabele';
  @override
  String get cheatFootnotes => 'Note de subsol';
  @override
  String get cheatRule => 'Linie orizontală';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Substituenți de șabloane';
  @override
  String get menuAddLink => 'Adaugă link';
  @override
  String get menuAddExternalLink => 'Adaugă link extern';
  @override
  String get menuFormat => 'Format';
  @override
  String get menuParagraph => 'Paragraf';
  @override
  String get menuInsert => 'Inserează';
  @override
  String get menuBody => 'Text normal';
  @override
  String get formatSubscript => 'Indice';
  @override
  String get formatInlineCode => 'Cod';
  @override
  String get insertFootnote => 'Notă de subsol';
  @override
  String get insertRule => 'Linie orizontală';
  @override
  String get insertCodeBlock => 'Bloc de cod';
  @override
  String get insertMathBlock => 'Bloc matematic';
  @override
  String get menuHeadingWord => 'Titlu';
  @override
  String get toolbarHeading => 'Titlu';
  @override
  String get toolbarList => 'Listă';
  @override
  String get toolbarOrderedList => 'Listă numerotată';
  @override
  String get toolbarChecklist => 'Listă de verificare';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Indentare';
  @override
  String get toolbarOutdent => 'Scoate indentarea';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Instrumente';
  @override
  String get editorToolsTitle => 'Instrumentele editorului';
  @override
  String get toolCountListTitle => 'Numără o listă';
  @override
  String get toolCountListSubtitle =>
      'Adună ce enumeră rândurile, ca listă de bifat';
  @override
  String get toolCountListNeedsList =>
      'Această notiță nu are nicio listă de numărat';
  @override
  String get tallySourceLabel => 'Listă';
  @override
  String get tallyCutLabel => 'Citește fiecare rând ca';
  @override
  String get tallyCutDash => 'Nume - valori';
  @override
  String get tallyCutColon => 'Nume: valori';
  @override
  String get tallyCutCommas => 'Valori separate prin virgulă';
  @override
  String get tallyCutWhole => 'Tot rândul, ca o singură valoare';
  @override
  String get tallySortLabel => 'Ordine';
  @override
  String get tallySortCount => 'Cele mai multe întâi';
  @override
  String get tallySortAlphabetical => 'Alfabetic';
  @override
  String get tallySortFirstSeen => 'În ordinea listei';
  @override
  String get tallyInsert => 'Inserează';
  @override
  String get tallyUpdate => 'Actualizează';
  @override
  String get tallyNothingToCount => 'Aici nu e nimic de numărat';
  @override
  String get headingDialogTitle => 'Nivelul titlului';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Bara de unelte a editorului';
  @override
  String get toolbarSettingsHint =>
      'Trage pentru a schimba ordinea; ochiul arată sau ascunde un buton.';
  @override
  String get toolbarShowButton => 'Arată';
  @override
  String get toolbarHideButton => 'Ascunde';
  @override
  String get toolbarResetOrder => 'Restaurează implicitul';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Afișează previzualizarea';
  @override
  String get showEditorTooltip => 'Afișează editorul';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tabel HTML brut)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Caută în note';
  @override
  String get searchModeWords => 'Cuvinte';
  @override
  String get searchModeContains => 'Conține';
  @override
  String get searchEmptyHint =>
      'Scrie pentru a căuta în bibliotecă, sau cheie = valoare pentru a '
      'filtra după frontmatter';
  @override
  String get searchTooShortHint => 'Scrie cel puțin 2 caractere';
  @override
  String get searchNoMatches => 'Niciun rezultat';
  @override
  String get searchLoadMore => 'Afișează mai multe';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Înlocuiește…';
  @override
  String get replaceInNoteAction => 'Înlocuiește în această notă…';
  @override
  String get replaceInThisNote => 'Înlocuiește în această notă';
  @override
  String get replaceWithLabel => 'Înlocuiește cu';
  @override
  String get replaceCaseSensitive => 'Distinge majusculele de minuscule';
  @override
  String get replaceWholeWordsHint =>
      'se înlocuiesc doar potrivirile exacte de cuvinte întregi';
  @override
  String get replaceConfirm => 'Înlocuiește';
  @override
  String get replaceCancel => 'Închide';
  @override
  String get replaceUnavailable => 'Înlocuirea nu este disponibilă acum';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Caută în notă';
  @override
  String get editorFindHint => 'Caută';
  @override
  String get editorReplaceHint => 'Înlocuiește';
  @override
  String get editorFindCaseTooltip => 'Distinge majusculele de minuscule';
  @override
  String get editorFindPreviousTooltip => 'Potrivirea anterioară';
  @override
  String get editorFindNextTooltip => 'Potrivirea următoare';
  @override
  String get editorFindCloseTooltip => 'Închide căutarea';
  @override
  String get editorFindReplaceModeTooltip => 'Modul de înlocuire';
  @override
  String get editorReplaceOneTooltip => 'Înlocuiește această potrivire';
  @override
  String get editorReplaceAllTooltip => 'Înlocuiește toate potrivirile';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etichete';
  @override
  String get tagsTitle => 'Etichete';
  @override
  String get tagsEmpty =>
      'Nicio etichetă încă — adaugă o #etichetă sau etichete în '
      'frontmatter';
  @override
  String get tagsBackTooltip => 'Înapoi la căutare';
  @override
  String get tagsNotesEmpty => 'Nicio notă cu această etichetă';
  @override
  String tagsNotesCapped(int limit) =>
      'Se afișează doar primele $limit — caută eticheta pentru a limita';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Linkul nu a fost găsit';
  @override
  String get headingNotFoundTitle => 'Titlul nu a fost găsit';
  @override
  String get ambiguousLinkTitle => 'Mai multe note se potrivesc';
  @override
  String get openLinkFailed => 'Linkul nu a putut fi deschis';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Notița nu există';
  @override
  String missingNoteDialogBody(String path) => 'Se creează „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Dosarul „$folder“ nu există';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Deschise';
  @override
  String get todoDone => 'Finalizate';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Toate datele';
  @override
  String get todoFilter => 'Filtrează';
  @override
  String get todoNoTokens => 'Niciun token în această listă';
  @override
  String get todoCountOpen => 'deschise';
  @override
  String get todoCountDone => 'finalizate';
  @override
  String get todoEmptyOpen => 'Nicio sarcină deschisă încă';
  @override
  String get todoEmptyDone => 'Niciuna finalizată încă';
  @override
  String get todoEmptyFiltered => 'Nicio sarcină nu se potrivește';
  @override
  String get todoTitle => 'De făcut';
  @override
  String get todoAddTooltip => 'Adaugă sarcină';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Formatul todo.txt';
  @override
  String get todoHelpTooltip => 'Informații despre format';
  @override
  String get todoHelpIntro =>
      'Sarcinile tale sunt un fișier de text obișnuit, o sarcină pe linie. '
      'Niman scrie sintaxa pentru tine, dar nu ascunde nimic: poți edita '
      'fișierul în orice editor și Niman îl citește din nou.';
  @override
  String get todoHelpFilesTitle => 'Cele două fișiere';
  @override
  String get todoHelpFilesBody =>
      'Sarcinile deschise locuiesc în todo.txt din rădăcina bibliotecii. '
      'Finalizează una și linia se mută în done.txt, astfel todo.txt '
      'rămâne scurt. O linie finalizată care ajunge din nou în todo.txt '
      'este arhivată de Niman la următoarea citire a fișierelor.';
  @override
  String get todoHelpLineTitle => 'Anatomia unei linii';
  @override
  String get todoHelpLineBody =>
      'Tot ce este înainte de descriere este opțional și trebuie să vină '
      'în această ordine:';
  @override
  String get todoHelpDoneBody =>
      'Marchează sarcina ca finalizată. Niman o adaugă când bifezi '
      'căsuța.';
  @override
  String get todoHelpPriority => '(A) până la (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritate. A este cea mai înaltă. Se afișează ca emblemă în listă.';
  @override
  String get todoHelpDatesBody =>
      'Data finalizării, apoi data creării. Cu o singură dată, este data '
      'creării, cu excepția cazului în care linia începe cu x.';
  @override
  String get todoHelpTokensTitle => 'Proiecte, contexte și etichete';
  @override
  String get todoHelpTokensBody =>
      'Întreaga descriere, un cuvânt cu oricare dintre aceste prefixe '
      'devine o etichetă care poate fi filtrată. Nimic nu este predefinit: '
      'un token există cât timp îl scrii.';
  @override
  String get todoHelpProjectBody =>
      'La ce proiect aparține sarcina, de exemplu +bucătărie sau +muncă.';
  @override
  String get todoHelpContextBody =>
      'Unde sau cum o faci, de exemplu @acasă sau @întâlniri.';
  @override
  String get todoHelpHashtagBody =>
      'O etichetă liberă pentru orice nu acoperă primele două.';
  @override
  String get todoHelpTagsTitle => 'Date și mementouri';
  @override
  String get todoHelpTagsBody =>
      'Acestea sunt etichete cheie:valoare. Niman le scrie din dialogul de '
      'sarcini și le citește oriunde apar în linie.';
  @override
  String get todoHelpDueBody =>
      'Termenul. Controlează culoarea emblemei și filtrele de date.';
  @override
  String get todoHelpRemBody =>
      'Când ar trebui trimisă notificarea, în fusul tău orar. Se declanșează '
      'când ecranul este stins și aplicația închisă.';
  @override
  String get todoHelpRemDesktop =>
      'Pe desktop, Niman trebuie să ruleze când vine ora: mementorul se '
      'arată cât timp aplicația este deschisă și nimic nu se declanșează '
      'când este închisă.';
  @override
  String get todoHelpOtherBody =>
      'Păstrat exact cum a fost scris, astfel încât etichetele din alte '
      'aplicații todo.txt să supraviețuiască unei călătorii. Niman nu '
      'acționează asupra lor, rec: included: o sarcină recurentă nu se '
      'repetă încă.';
  @override
  String get todoHelpEditTitle => 'Editare în afara Niman';
  @override
  String get todoHelpEditBody =>
      'O sarcină pe care nu o atingi se rescrie byte cu byte, inclusiv '
      'spații ciudate. Editezi o linie și Niman rescrie doar acea linie în '
      'formatul ei canonic și lasă restul fișierului intact.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Adaugă sarcină';
  @override
  String get todoEditTitle => 'Editează sarcină';
  @override
  String get todoDescriptionHint => 'Descriere';
  @override
  String get todoCancel => 'Anulează';
  @override
  String get todoSave => 'Salvează';
  @override
  String get todoEditAction => 'Editează';
  @override
  String get todoDeleteAction => 'Șterge';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Întârziat';
  @override
  String get todoDueToday => 'Astăzi';
  @override
  String get todoDueNext7 => 'Următoarele 7 zile';
  @override
  String get todoDueNoDate => 'Fără dată';
  @override
  String get todoRowDue => 'Termen';
  @override
  String get todoRowDueToday => 'Termen astăzi';
  @override
  String get todoSortTooltip => 'Sortează';
  @override
  String get todoSortDue => 'Data termenului';
  @override
  String get todoSortPriority => 'Prioritate';
  @override
  String get todoSortCreation => 'Data creării';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Fără prioritate';
  @override
  String get todoNoPriorityShort => 'Niciuna';
  @override
  String get todoMorePriorities => 'Mai multe…';
  @override
  String get todoPriorityTitle => 'Prioritate';
  @override
  String get todoNoDueDate => 'Fără termen';
  @override
  String get todoNoReminder => 'Fără mementou';
  @override
  String get todoAddProject => '+ Proiect';
  @override
  String get todoAddContext => '@ Context';
  @override
  String get todoAddHashtag => '# Etichetă';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Mementouri de sarcini';
  @override
  String get todoReminderChannelDescription =>
      'Notificări programate pentru sarcini cu oră de mementou.';
  @override
  String get todoReminderBody => 'Mementou de sarcină';
  @override
  String get todoReminderFallbackTitle => 'Mementou de sarcină';
  @override
  String get todoReminderBlocked =>
      'Notificările sunt dezactivate, deci mementourile nu se vor afișa.';
  @override
  String get todoReminderBattery =>
      'Optimizarea bateriei este activă pentru Niman. Sistemul poate '
      'suspenda aplicația și poate pierde mementouri în așteptare.';
  @override
  String get todoReminderInexact =>
      'Acest dispozitiv nu permite alarme exacte, deci un mementou poate '
      'sosi cu câteva minute mai târziu când ecranul este stins.';
  @override
  String get reminderShowTokensTitle => 'Etichete în notificările de mementou';
  @override
  String get reminderShowTokensSubtitle =>
      'Păstrează +proiect, @context și #etichetă în textul notificării. '
      'Dezactivat arată doar sarcina pe care ai scris-o.';
  @override
  String get todoReminderFixAction => 'Deschide setările';
  @override
  String get todoReminderDismissAction => 'Respinge';
  @override
  String get todoReminderDue => 'Termen';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Anulează';
  @override
  String get actionCreate => 'Creează';
  @override
  String get actionNew => 'Nouă';
  @override
  String get actionSave => 'Salvează';
  @override
  String get actionClear => 'Golește';
  @override
  String get actionChoose => 'Alege';
  @override
  String get actionDelete => 'Șterge';
  @override
  String get actionRename => 'Redenumește';
  @override
  String get actionMove => 'Mută';
  @override
  String get saveAndClose => 'Salvează și închide';
  @override
  String get closeUnsavedTitle => 'Modificări nesalvate';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” are modificări nesalvate. '
          'Salvăm-le înainte de închidere?';
    }
    return '${names.length} note au modificări nesalvate. '
        'Salvăm-le înainte de închidere?';
  }

  @override
  String get closeSaveFailed => 'Salvarea a eșuat; rămâne deschisă.';
  @override
  String get actionRestore => 'Restaurează';
  @override
  String get actionEmpty => 'Golește';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ascunde panoul lateral (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Afișează panoul lateral (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizează';
  @override
  String get windowMaximizeTooltip => 'Maximizează';
  @override
  String get windowRestoreTooltip => 'Restaurează';
  @override
  String get windowCloseTooltip => 'Închide';
  @override
  String get tabFiles => 'Fișiere';
  @override
  String get tabSearch => 'Căutare';
  @override
  String get tabSettings => 'Setări';
  @override
  String get quickNoteTitle => 'Notă rapidă';
  @override
  String get treeEmpty => 'Nicio notă încă';
  @override
  String get selectANote => 'Alege o notă';
  @override
  String get showListTooltip => 'Afișează lista';
  @override
  String get editRawTooltip => 'Editează brut';
  @override
  String get sortAscTooltip => 'Sortează A–Z';
  @override
  String get sortDescTooltip => 'Sortează Z–A';
  @override
  String get newNoteTitle => 'Notă nouă';
  @override
  String get newItemTooltip => 'Nou';
  @override
  String get closeMenuTooltip => 'Închide';
  @override
  String get newFolderTitle => 'Dosar nou';
  @override
  String get newNoteSameFolder => 'Notă nouă în același dosar';
  @override
  String get newFromTemplateSameFolder => 'Nouă din șablon în același dosar';
  @override
  String trashOriginalPath(String path) => 'era în $path';
  @override
  String get trashOriginalRoot => 'era \u00een r\u0103d\u0103cina bibliotecii';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 element' : '$count elemente';
  @override
  String get newNoteHere => 'Notă nouă aici';
  @override
  String get newFolderHere => 'Dosar nou aici';
  @override
  String get newListNoteTitle => 'Notă de listă nouă';
  @override
  String get newListNoteDefault => 'Lista mea';
  @override
  String get setAsQuickNote => 'Setează ca notă rapidă';
  @override
  String get currentQuickNote => 'Notă rapidă curentă';
  @override
  String get pinnedSection => 'Fixate';
  @override
  String pinnedSectionCount(int count) => 'Fixate · $count';
  @override
  String get templateFolderTitle => 'Dosar de șabloane';
  @override
  String get newFromTemplateTitle => 'Nouă din șablon';
  @override
  String get newFromTemplateHere => 'Nouă din șablon aici';
  @override
  String get templateFormTitle => 'Completează șablonul';
  @override
  String get templateFormBacklink => 'Legat de';
  @override
  String get templateFormNoNote => 'Fără notă';
  @override
  String get templateFormPickNote => 'Alege nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Markeri de șablon';
  @override
  String get templateHelpSubtitle =>
      'Data, titlul și celelalte valori de completat';
  @override
  String get quickNoteSubtitle => 'Nota pe care o deschide fila Notă rapidă';
  @override
  String get listFolderSubtitle => 'Noile liste de sarcini';
  @override
  String get templateFolderSubtitle => 'Sursa pentru „Nou din șablon“';
  @override
  String get attachmentsFolderSubtitle =>
      'Imagini și sunet inserate într-o notă';
  @override
  String get templateHelpIntro =>
      'Un șablon este o notă obișnuită cu găuri. Crearea unei note din ea '
      'copiază textul și completează găurile.';
  @override
  String get templateHelpUnknown =>
      'Un marker pe care Niman nu îl cunoaște rămâne exact cum a fost '
      'scris, astfel încât o greșeală de tastare apare în notă, în loc să '
      'rupă în tăcere o linie.';
  @override
  String get templateHelpValuesTitle => 'Valori';
  @override
  String get templateHelpTitleBody => 'Numele sub care trebuie creată nota.';
  @override
  String get templateHelpDateBody =>
      'Astăzi și ora curentă. Ambele acceptă un format: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data și ora împreună.';
  @override
  String get templateHelpUuidBody =>
      'Un identificator nou, diferit la fiecare apariție.';
  @override
  String get templateHelpCounterBody =>
      'Un număr care numără după nume, păstrat între reporniri: prima notă '
      'scrie 1, următoarea 2. Același nume într-o notă scrie același '
      'număr; combină-l cu |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Pune cursorul aici când se creează nota; markerul nu se scrie. '
      'Primul marker câștigă, fără filtre, doar note noi — și tastatura se '
      'deschide și la autofocus dezactivat.';
  @override
  String get templateHelpDatesTitle => 'Scrierea unei date';
  @override
  String get templateHelpDatesBody =>
      'Acestea reprezintă părți ale datei într-un format. Tot restul este '
      'literal, și textul din ghilimele simple. Numele lunilor și ale '
      'zilelor săptămânii urmează limba aplicației.';
  @override
  String get templateHelpYear => 'anul: 2026, 26';
  @override
  String get templateHelpMonth => 'luna: 03, 3, martie, mar';
  @override
  String get templateHelpDay => 'ziua: 09, 9, luni, lun';
  @override
  String get templateHelpTime => 'ore, minute, secunde';
  @override
  String get templateHelpWeek => 'săptămâna ISO și trimestrul: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtre';
  @override
  String get templateHelpFiltersBody =>
      'O valoare poate fi urmată de filtre, aplicate din stânga în dreapta.';
  @override
  String get templateHelpCaseBody =>
      'Majuscule, minuscule și prima literă a fiecărui cuvânt — un cuvânt '
      'pe care l-ai scris cu majuscule nu este atins.';
  @override
  String get templateHelpSlugBody =>
      'Forma de link a textului, pentru a construi un link wiki.';
  @override
  String get templateHelpPadBody =>
      'Taie capetele; completează cu zerouri până la lățimea dorită; '
      'folosește o alternativă când valoarea este goală.';
  @override
  String get templateHelpShiftBody =>
      'Mută o dată cu zile, săptămâni, luni sau ani — conferința de '
      'săptămâna viitoare, fișierul de luna trecută.';
  @override
  String get templateHelpSnapBody =>
      'Fixează o dată la începutul sau sfârșitul săptămânii, lunii sau '
      'anului.';
  @override
  String get templateHelpAskTitle => 'Să te întreb ceva';
  @override
  String get templateHelpAskBody =>
      'Un formular se arată înainte de crearea notei, un câmp pe întrebare '
      '— și unul pentru linkul invers, când șablonul cere. Eticheta aceea '
      'de două ori este o întrebare, iar răspunsul ei completează toate '
      'aparițiile — inclusiv dosarul și numele fișierului.';
  @override
  String get templateHelpAskFieldBody =>
      'Un câmp de scris; textul după al doilea douăpunct este începutul.';
  @override
  String get templateHelpChoiceBody =>
      'O alegere dintr-o listă, separată prin virgule.';
  @override
  String get templateHelpWhereTitle => 'Unde ajunge nota';
  @override
  String get templateHelpWhereBody =>
      'Acestea nu sunt text: sunt instrucțiuni și locuiesc într-un bloc '
      'niman: din propriul frontmatter al șablonului. Blocul se execută și '
      'se șterge, astfel nu se arată niciodată în notă. Valoarea sa poate '
      'conține markeri.';
  @override
  String get templateHelpFolderBody =>
      'Dosarul în care se creează nota, creat dacă nu există. Fără el, nota '
      'ajunge unde erai.';
  @override
  String get templateHelpFilenameBody =>
      'Cum se numește nota. Un șablon care spune asta nu este întrebat de '
      'nume.';
  @override
  String get templateHelpAppendBody =>
      'Adaugă la notă dacă deja există, în loc să creezi alta. Astfel o '
      'lună de întâlniri devine un singur fișier.';
  @override
  String get templateHelpOpenBody =>
      'Ce se întâmplă când nota există: editorul (implicit), previzualizarea, '
      'sau nimic — nota este arhivată și rămâi unde erai.';
  @override
  String get templateHelpAroundTitle => 'De unde a venit';
  @override
  String get templateHelpParentBody =>
      'O notă pe care o alegi în formular, oferită pe ecran; scrie '
      '[[{{parent}}]] pentru un link de întoarcere.';
  @override
  String get templateHelpFolderValueBody => 'Dosarul în care a ajuns nota.';
  @override
  String get templateHelpClipboardBody =>
      'Ce este în clipboard și selecția din editor când nota a pornit de '
      'acolo.';
  @override
  String get templateHelpIncludeTitle => 'Reutilizarea unei părți';
  @override
  String get templateHelpIncludeBody =>
      'Lipește alt șablon, astfel încât zece șabloane să poată împărți o '
      'listă de verificare. Cautat întâi în dosarul de șabloane, .md poate '
      'fi omis. Întrebările sale proprii intră în același formular.';
  @override
  String get templateHelpExampleTitle => 'Totul la un loc';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nu există șablonul “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” se include pe sine';
  @override
  String includeTooDeep(String path) => '⚠ “$path” este înfipt prea adânc';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter necitit: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatterul “$template” nu a putut fi citit, deci dosarul și '
      'numele fișierului nu au făcut nimic: $reason';
  @override
  String get templatePickerTitle => 'Alegere șablon';
  @override
  String templatePickerEmpty(String folder) =>
      'Niciun șablon încă. Pune o notă în $folder/ și va fi șablon.';

  // Tree actions.
  @override
  String get actionPin => 'Fixează';
  @override
  String get actionUnpin => 'Dezfixează';
  @override
  String get pinToWidget => 'Fixează în widgetul de start';
  @override
  String get pinnedForWidget =>
      'Fixat: acum plasează widgetul Notă pe ecranul de start';
  @override
  String get pinWidgetUnavailable =>
      'Widgeturile de pe ecranul de start sunt disponibile pe Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Arată în managerul de fișiere';
  @override
  String get openInDefaultApp => 'Deschide cu aplicația implicită';
  @override
  String get newNoteTabTooltip => 'Notă nouă într-o filă nouă';
  @override
  String get openNotesTooltip => 'Note deschise';
  @override
  String get closeTabTooltip => 'Închide';
  @override
  String get openInNewTab => 'Deschide într-o filă nouă';
  @override
  String get splitRight => 'Împarte la dreapta';
  @override
  String get splitDown => 'Împarte în jos';
  @override
  String get moveToOtherPane => 'Mută în celălalt panou';
  @override
  String get openBeside => 'Deschide alături';
  @override
  String get closeAllNotes => 'Închide toate';
  @override
  String get sidePanelTooltip => 'Afișează sau ascunde panoul lateral';
  @override
  String get historyAllVersions => 'Toate versiunile';
  @override
  String get commandPaletteTitle => 'Paleta de comenzi';
  @override
  String get goToNoteTitle => 'Mergi la notă';
  @override
  String get paletteGroupNote => 'Notă';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Vizualizare';
  @override
  String get paletteGroupLibrary => 'Bibliotecă';
  @override
  String get paletteGroupGoTo => 'Mergi la';
  @override
  String get paletteGroupJournal => 'Jurnal';
  @override
  String get journalToday => 'Intrarea de azi';
  @override
  String get journalPrevious => 'Intrarea anterioară';
  @override
  String get journalNext => 'Intrarea următoare';
  @override
  String get commandNeedJournalEntry => 'Necesită o intrare de jurnal deschisă';
  @override
  String journalCreateAsk(String day) =>
      'Încă nu există o intrare pentru $day. O creezi?';
  @override
  String journalTemplateMissing(String path) =>
      'Șablonul jurnalului $path nu a putut fi citit: intrarea a fost creată '
      'fără el.';
  @override
  String get journalIntro =>
      'O notă pe zi, creată dintr-un șablon prima dată când deschizi ziua '
      'respectivă. Aceste setări călătoresc cu biblioteca.';
  @override
  String get journalFolderTitle => 'Dosarul jurnalului';
  @override
  String get journalFolderSubtitle => 'Unde merg intrările';
  @override
  String get journalEntryNameTitle => 'Numele intrării';
  @override
  String get journalEntryNameSubtitle =>
      'YYYY, MM sau M, DD sau D pentru dată; / creează un dosar; textul între '
      "'ghilimele' rămâne cum este";
  @override
  String journalEntryNamePreview(String path) => 'Intrarea de azi: $path';
  @override
  String get journalEntryNameInvalid =>
      'Necesită YYYY, o lună (MM sau M) și o zi (DD sau D), și nimic ce un '
      'nume de fișier nu poate conține';
  @override
  String get journalTemplateTitle => 'Șablon';
  @override
  String get journalTemplateSubtitle => 'Cu ce începe o intrare nouă';
  @override
  String get journalTemplateNone => 'Niciunul: un titlu cu data';
  @override
  String get journalDayStartTitle => 'O zi nouă începe la';
  @override
  String get journalDayStartSubtitle =>
      'Stai până târziu? La 04:00 noaptea rămâne în ziua dinainte';
  @override
  String get journalRecent => 'Recente';
  @override
  String get journalNoEntry => 'Nicio intrare pentru această zi';
  @override
  String get journalOpenEntry => 'Deschide';
  @override
  String get journalShowCalendar => 'Arată calendarul';
  @override
  String get journalFabToday => 'Intrarea de azi din jurnal';
  @override
  String journalDueOn(String day) => 'Scadent $day';
  @override
  String get commandsTitle => 'Comenzi';
  @override
  String get commandsIntro =>
      'Paleta de comenzi oferă doar comenzile care pot rula acolo unde ești. '
      'Aici sunt toate, și când apare fiecare.';
  @override
  String get commandsKeysNote =>
      'Aici nu se schimbă nimic. Tastele sunt cele setate în „Scurtături de '
      'tastatură” și urmează orice schimbare făcută acolo.';
  @override
  String get commandsOpenShortcuts =>
      'Schimbă tastele în „Scurtături de tastatură”';
  @override
  String get commandsChangeKeyTooltip => 'Schimbă în „Scurtături de tastatură”';
  @override
  String get commandsSubtitle => 'Ce poate rula paleta de comenzi, și când';
  @override
  String get keyboardShortcutsSubtitle => 'Schimbă tastele fiecărei comenzi';
  @override
  String get commandNeedNone => 'Mereu disponibilă';
  @override
  String get commandNeedOpenNote => 'Necesită o notă deschisă';
  @override
  String get commandNeedTextNote => 'Necesită o notă text deschisă';
  @override
  String get commandNeedWideWindow => 'Doar în fereastră lată';
  @override
  String get commandNeedDockRoom =>
      'Necesită o fereastră destul de lată pentru panoul lateral';
  @override
  String get commandNeedDesktop => 'Doar pe desktop';
  @override
  String get commandNeedNotInZen => 'Nu în modul Zen';
  @override
  String get commandNeedZenRoom => 'Desktop, cu o notă deschisă într-o filă';
  @override
  String get commandNeedPreview => 'Cu previzualizarea activă, pe o notă text';
  @override
  String get commandNeedTwoEditors => 'Cu ambele editoare activate';
  @override
  String get paletteHint => 'Caută comenzi și note';
  @override
  String get paletteNoResults => 'Nimic nu se potrivește';
  @override
  String get paletteCommands => 'Comenzi';
  @override
  String get paletteNotes => 'Note';
  @override
  String get paletteFooter =>
      '↑↓ pentru navigare · ↵ pentru a folosi · esc pentru a închide';
  @override
  String get paletteFooterTouch =>
      'Atinge pentru a folosi · pioneza îl ține sus';
  @override
  String get palettePinned => 'Fixate';
  @override
  String get palettePin => 'Fixează';
  @override
  String get paletteUnpin => 'Elimină';
  @override
  String get palettePinFooter => 'alt+P pentru a fixa';
  @override
  String get spellCheckScanning => 'Se verifică nota…';
  @override
  String get spellCheckAgain => 'Verifică din nou';
  @override
  String spellCheckCapped(int count) =>
      'Sunt afișate primele $count: corectează câteva, apoi verifică din nou '
      'pentru rest';
  @override
  String get dropHint =>
      'Plasează fișiere Markdown pentru a le deschide sau un dosar pentru '
      'a-l importa';
  @override
  String get dropNothing =>
      'Desktopul nu a predat niciun fișier la acea plasare.';
  @override
  String get importFolderAction => 'Importă';
  @override
  String dropRejected(String names) =>
      'Aici se deschid doar fișiere Markdown și dosare: $names';
  @override
  String importFolderTitle(String name) => 'Imporți „$name”?';
  @override
  String importFolderBody(int count) =>
      'Fișierele sale Markdown ($count) sunt copiate într-un dosar nou al '
      'bibliotecii. Dosarul plasat rămâne neschimbat.';
  @override
  String importFolderDone(String folder) => 'Importat în $folder';
  @override
  String importFolderEmpty(String name) => 'Niciun fișier Markdown în $name';
  @override
  String get openFileTitle => 'Deschide fișier';
  @override
  String get outsideFileNote =>
      'În afara oricărei biblioteci: salvat unde se află, neindexat, fără '
      'istoric, legăturile nu sunt urmate';
  @override
  String get typewriterOn => 'Activează modul mașină de scris';
  @override
  String get typewriterOff => 'Dezactivează modul mașină de scris';
  @override
  String get typewriterTitle => 'Mod mașină de scris';
  @override
  String get formatNoteTitle => 'Aranjează Markdown-ul';
  @override
  String get formatNoteDone => 'Nota a fost aranjată.';
  @override
  String get formatNoteAlreadyTidy => 'Nota era deja aranjată.';
  @override
  String get tidyOnCloseTitle => 'Aranjează Markdown-ul la închidere';
  @override
  String get tidyOnCloseSubtitle =>
      'Când închizi o notă pe care ai modificat-o, Markdown-ul ei este '
      'aranjat ca prin comanda „Aranjează Markdown-ul”. Notele de peste '
      '4 MB rămân așa cum sunt.';
  @override
  String get typewriterSubtitle =>
      'Rândul pe care scrii rămâne în mijlocul editorului';
  @override
  String get zenMode => 'Mod zen';
  @override
  String get zenModeEnter => 'Intră în modul zen';
  @override
  String get zenModeLeave => 'Ieși din modul zen';
  @override
  String get keySpace => 'Spațiu';
  @override
  String get keyEnter => 'Enter';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Backspace';
  @override
  String get keyDelete => 'Delete';
  @override
  String get keyArrowUp => 'Sus';
  @override
  String get keyArrowDown => 'Jos';
  @override
  String get keyArrowLeft => 'Stânga';
  @override
  String get keyArrowRight => 'Dreapta';
  @override
  String get keyHome => 'Home';
  @override
  String get keyEnd => 'End';
  @override
  String get keyPageUp => 'Page Up';
  @override
  String get keyPageDown => 'Page Down';
  @override
  String get keyInsert => 'Insert';
  @override
  String get shortcutNone => 'Fără scurtătură';
  @override
  String get shortcutRestoreDefaults => 'Restabilește implicitele';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Refaci toate scurtăturile așa cum le livrează Niman?';
  @override
  String get shortcutRevert => 'Înapoi la implicită';
  @override
  String get shortcutClear => 'Elimină scurtătura';
  @override
  String get shortcutCapturePrompt =>
      'Apasă tastele. Și Esc și Tab sunt preluate: ieși cu Anulează.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Adaugă Ctrl, Alt sau Meta: o tastă singură e pentru scris.';
  @override
  String get shortcutMove => 'Mut-o';
  @override
  String get shortcutUseAnyway => 'Folosește oricum';
  @override
  String get shortcutUndo => 'Anulează acțiunea';
  @override
  String get shortcutRedo => 'Refă';
  @override
  String get shortcutChange => 'Schimbă scurtătura';
  @override
  String shortcutCaptureTitle(String command) => 'Taste pentru $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys este deja a $other. O muți aici? $other va rămâne fără '
      'scurtătură.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys este și $what în câmpurile de text și în editor. Acolo o va '
      'prelua comanda ta.';
  @override
  String get openFileMissing => 'Fișierul acestei note nu este pe disc';
  @override
  String get openFileFailed => 'Nota nu a putut fi deschisă în afara Niman';
  @override
  String get attachmentUnreadable => 'Acest fișier nu a putut fi afișat.';
  @override
  String get attachmentMissing => 'Acest fișier nu este pe disc.';
  @override
  String get attachmentOpenFailed =>
      'Fișierul nu a putut fi deschis în afara Niman.';
  @override
  String get copyPlaceLink => 'Copiază linkul către acest loc';
  @override
  String get placeLinkCopied => 'Link copiat';
  @override
  String pdfPageLabel(String name, int page) => '$name, p. $page';
  @override
  String get annotationsFolderTitle => 'Dosarul adnotărilor';
  @override
  String get annotationsFolderSubtitle =>
      'Notițe care adnotează un PDF sau o carte';
  @override
  String get annotationNoteSuffix => 'Adnotare';
  @override
  String get annotateAction => 'Adnotează';
  @override
  String get annotationCommentHint => 'Comentariul tău';
  @override
  String get annotationSaved => 'Adnotare salvată';
  @override
  String get annotationOpenNote => 'Deschide notița';
  @override
  String get annotationFailed => 'Adnotarea nu a putut fi salvată';

  @override
  String get movedToTrash => 'Mutat în coș';
  @override
  String get deletedMessage => 'Șters';
  @override
  String deleteToTrashConfirm(String name) => '$name se mută în .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name se șterge permanent';
  @override
  String get chooseDestination => 'Alege destinația';
  @override
  String get libraryRoot => 'Rădăcina bibliotecii';
  @override
  String moveTitle(String name) => 'Mută $name';
  @override
  String headingLevelLabel(int level) => 'Titlu $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Nicio notă rapidă încă. Alege o notă existentă sau creează — nota '
      'rapidă se va deschide aici.';
  @override
  String get quickNoteChooseAction => 'Alege o notă…';
  @override
  String get quickNoteCreateAction => 'Creează o notă nouă…';
  @override
  String get quickNoteNewTitle => 'Notă rapidă nouă';
  @override
  String get quickNotePickerTitle => 'Alegere notă rapidă';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Dosar nou';
  @override
  String get folderPickerEmpty => 'Niciun dosar încă';
  @override
  String get listFolderTitle => 'Dosar de liste';
  @override
  String get attachmentsFolderTitle => 'Dosar de atașamente';

  // Trash (M1).
  @override
  String get trashEmpty => 'Coșul este gol';
  @override
  String get trashEmptyAction => 'Golește coșul';
  @override
  String get trashEmptyConfirm =>
      'Asta șterge permanent tot ce este în coș, inclusiv elementele pe '
      'care Niman nu le-a pus.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se șterge permanent (fără restaurare)';
  @override
  String get trashDeletePermanently => 'Șterge permanent';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Deschide un dosar de note Markdown ca bibliotecă';
  @override
  String get openLibraryExisting => 'Deschide una existentă';
  @override
  String get openLibraryCreate => 'Creează una nouă';
  @override
  String get openLibraryCreateTitle => 'Creează o bibliotecă nouă';
  @override
  String get openLibraryFolderName => 'Numele dosarului';
  @override
  String get openLibraryChooseFolder => 'Alege dosarul bibliotecii';
  @override
  String get openLibraryChooseParent =>
      'Alege dosarul în care se va crea biblioteca';
  @override
  String get openLibraryUnsupported =>
      'Acest dosar nu este compatibil. Alege un dosar din stocarea '
      'dispozitivului.';
  @override
  String indexingCount(int done, int total) => '$done din $total note';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Bibliotecile tale';
  @override
  String get libraryUnreachable => 'Nedisponibilă';
  @override
  String get libraryOpenedToday => 'Deschisă azi';
  @override
  String get libraryOpenedYesterday => 'Deschisă ieri';
  @override
  String libraryOpenedDaysAgo(int days) => 'Deschisă acum $days zile';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Deschisă ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Deschisă acum';
  @override
  String get switchLibraryTitle => 'Schimbă biblioteca';
  @override
  String get libraryForget => 'Uită';
  @override
  String libraryForgetTitle(String name) => 'Uită „$name”?';
  @override
  String get libraryForgetExplained =>
      'Dispare din această listă. Dosarul, notele și setările bibliotecii '
      'rămân neatinse, iar redeschiderea o pune la loc.';

  @override
  String get libraryForgetOpenExplained =>
      'Această bibliotecă este deschisă acum: se închide mai întâi, apoi '
      'dispare din listă. Folderul, notițele și setările bibliotecii din el '
      'rămân neatinse, iar redeschiderea o aduce înapoi.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dă acces la fișiere';
  @override
  String get storageAccessNeeded =>
      'Niman nu poate citi notele tale fără „Acces la toate fișierele”. '
      'Dă-l pentru a deschide o bibliotecă.';
  @override
  String get storageAccessExplained =>
      'Niman citește notele tale ca fișiere obișnuite, deci Android trebuie '
      'să-i dea acces la toate fișierele. Nimic nu este trimis, și se '
      'citește doar dosarul de bibliotecă pe care îl alegi.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistemul nu a dat acces la dosar: $error';
  @override
  String folderPickFailed(Object error) => 'Dosarul nu a putut fi ales: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Setări';
  @override
  String get libraryPathTitle => 'Calea bibliotecii';
  @override
  String get reindexTitle => 'Reindexează acum';
  @override
  String get reindexDone => 'Reindexare finalizată';
  @override
  String get closeLibraryTitle => 'Închide biblioteca';
  @override
  String get exportLogTitle => 'Exportă jurnalul de depanare';
  @override
  String get exportLogSubtitle =>
      'Salvează evenimentele înregistrate într-un fișier pe care îl alegi';
  @override
  String get exportLogEmpty => 'Bufferul jurnalului de depanare este gol';
  @override
  String get quickNoteUnset => 'Nesetate';
  @override
  String exportLogDone(Object target) =>
      'Jurnalul de depanare exportat în $target';
  @override
  String exportLogFailed(Object error) => 'Exportul a eșuat: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nicio potrivire exactă de cuvânt întreg pentru „$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'S-au înlocuit $occurrences apariții ale „$term” în $notes note';
  @override
  String replaceSkipped(int skipped) => ' ($skipped note deschise omitate)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nicio potrivire exactă de cuvânt întreg pentru „$term”'
      '${only == null ? ' a fost găsită' : ' a fost găsită în $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Despre';
  @override
  String get versionTitle => 'Versiune';
  @override
  String get changelogTitle => 'Jurnalul modificărilor';
  @override
  String get changelogEmpty => 'Nicio intrare în jurnal disponibilă';
  @override
  String changelogWhatsNew(String version) => 'Noutăți în versiunea $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Istoric';
  @override
  String get noteMenuTooltip => 'Acțiuni pentru notă';
  @override
  String get historyCurrentVersion => 'Versiunea curentă';
  @override
  String get historyCurrentSubtitle => 'Nota așa cum este acum';
  @override
  String get historyToday => 'Azi';
  @override
  String get historyYesterday => 'Ieri';
  @override
  String get historyReasonSession => 'înainte de editare';
  @override
  String get historyReasonInterval => 'în timpul editării';
  @override
  String get historyReasonRestore => 'înainte de restaurare';
  @override
  String get historyReasonSync => 'înainte de sincronizare';
  @override
  String get historyReasonReplace => 'înainte de înlocuire';
  @override
  String get historyReasonUnknown => 'recuperată';
  @override
  String get historySyncBase => 'bază de sincronizare';
  @override
  String get historyEmpty =>
      'Încă nicio versiune. Niman păstrează una când începi să editezi '
      'nota, apoi cel mult una la câteva minute cât timp scrii.';
  @override
  String historyKept(int kept, int limit) {
    final noun = limit == 1
        ? 'versiune'
        : limit % 100 == 0 || limit % 100 >= 20
        ? 'de versiuni'
        : 'versiuni';
    return '$kept din $limit $noun păstrate';
  }

  @override
  String get historyBaseKept =>
      'Baza de sincronizare se păstrează și peste limită.';
  @override
  String get historyOff =>
      'Istoricul este dezactivat pentru această bibliotecă '
      '(Setări, Bibliotecă).';
  @override
  String get historyLoadFailed => 'Istoricul nu a putut fi citit';
  @override
  String get historyCompareSubtitle => 'Comparată cu versiunea curentă';
  @override
  String get historyTabChanges => 'Modificări';
  @override
  String get historyTabVersion => 'Versiune';
  @override
  String get historyNoChanges => 'Același text ca în versiunea curentă.';
  @override
  String get historyRestoreAction => 'Restaurează această versiune';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Restaurezi versiunea din $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Textul curent este mai întâi păstrat în istoric, așa că poți reveni '
      'oricând.';
  @override
  String get historyRestoreConfirm => 'Restaurează';
  @override
  String historyRestored(String when) =>
      'Versiunea din $when a fost restaurată';
  @override
  String get historyRestoreFailed => 'Versiunea nu a putut fi restaurată';
  @override
  String get actionUndo => 'Anulează';
  @override
  String diffLineRange(int start, int end) => 'Liniile $start–$end';
  @override
  String diffLineSingle(int line) => 'Linia $line';
  @override
  String diffUnchanged(int count) => count == 1
      ? '1 linie nemodificată'
      : count % 100 == 0 || count % 100 >= 20
      ? '$count de linii nemodificate'
      : '$count linii nemodificate';
  @override
  String get historyTakeHunk => 'Restaurează aici';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Restaurează 1 modificare' : 'Restaurează $count modificări';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Modificările alese revin la textul acestei versiuni. Nota așa cum este '
      'acum este păstrată mai întâi ca versiune, așa că poți anula.';
  @override
  String get historyNoteChangedReloaded =>
      'Nota s-a schimbat cât ai fost aici — comparația a fost actualizată.';
  @override
  String get historyVersionsTitle => 'Versiuni de păstrat';
  @override
  String get historyVersionsSubtitle => 'Pentru fiecare notă, în .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Niciuna' : '$count';
  @override
  String get historyIntervalTitle => 'Versiune nouă cel mult o dată la';
  @override
  String get historyIntervalSubtitle =>
      'Cât timp scrii; începerea editării unei note păstrează mereu una';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcriere';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Niciunul';
  @override
  String get transcriptionLanguageTitle => 'Limbă';
  @override
  String get transcriptionLanguageSubtitle =>
      'Limba vorbită în înregistrările tale. S-o indici e mai precis decât '
      's-o lași detectată.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Ca aplicația ($language)';
  @override
  String get transcriptionLanguageDetect => 'Detectează automat';
  @override
  String get transcriptionModelsTitle => 'Modele de transcriere';
  @override
  String transcriptionModelsUsed(String size) => '$size folosiți';
  @override
  String get transcriptionModelsInstalled => 'Descărcate';
  @override
  String get transcriptionModelsDownloading => 'Se descarcă';
  @override
  String get transcriptionModelsAvailable => 'Disponibile';
  @override
  String get transcriptionModelsFooter =>
      'Modelele rămân în spațiul de stocare al aplicației pe acest '
      'dispozitiv. Nu sunt copiate în bibliotecă și nici sincronizate.';
  @override
  String get transcriptionModelDefault => 'Implicit';
  @override
  String get transcriptionModelSlow => 'Lent';
  @override
  String get transcriptionModelHintTiny =>
      'Cel mai rapid, cel mai puțin precis';
  @override
  String get transcriptionModelHintBase =>
      'Echilibru bun între viteză și precizie';
  @override
  String get transcriptionModelHintSmall => 'Mai precis, de circa 3× mai lent';
  @override
  String get transcriptionModelHintMedium => 'Foarte precis, lent pe telefon';
  @override
  String get transcriptionModelHintLarge =>
      'Cel mai precis, are nevoie de multă memorie';
  @override
  String get transcriptionModelDownload => 'Descarcă';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Ștergi modelul $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Se eliberează $size. Poți descărca modelul din nou mai târziu.';
  @override
  String get transcriptionModelFailed =>
      'Descărcarea a eșuat. Verifică conexiunea și încearcă din nou.';
  @override
  String get actionRetry => 'Încearcă din nou';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Conexiune pierdută, se reîncearcă…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Întrerupt la $progress';
  @override
  String get actionResume => 'Reia';
  @override
  String get audioTranscribe => 'Transcrie';
  @override
  String get audioTranscribeUnsupported =>
      'Doar înregistrări WAV pe acest dispozitiv';
  @override
  String get transcriptionQueued => 'În așteptare';
  @override
  String get transcriptionPreparing => 'Se pregătește sunetul…';
  @override
  String transcriptionRunning(int percent) => 'Se transcrie… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Se descarcă $model · $percent%';
  @override
  String get transcriptionSaved => 'Transcrierea a fost adăugată la descriere';
  @override
  String get transcriptionNoSpeech =>
      'Nu s-a recunoscut vorbire în această înregistrare';
  @override
  String get transcriptionFailed => 'Transcrierea a eșuat';
  @override
  String get transcriptionPickModelTitle => 'Alege un model';
  @override
  String get transcriptionPickModelBody =>
      'Transcrierea se face pe acest dispozitiv, iar înregistrarea nu este '
      'trimisă nicăieri. Modelul se descarcă o singură dată.';
  @override
  String get transcriptionPickModelAction => 'Descarcă și transcrie';
  @override
  String get transcriptionModelRecommended => 'Recomandat';
  @override
  String get transcriptionExistingTitle =>
      'Această înregistrare are deja o descriere';
  @override
  String get transcriptionExistingBody =>
      'O înlocuiești cu transcrierea sau adaugi transcrierea dedesubt?';
  @override
  String get transcriptionAppend => 'Adaugă dedesubt';
  @override
  String get transcriptionReplace => 'Înlocuiește';
  @override
  String get settingsSectionSync => 'Sincronizare';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Neconfigurată pentru această bibliotecă';
  @override
  String get syncNeverSynced => 'Nesincronizată niciodată';
  @override
  String syncLastSynced(String when) => 'Sincronizată $when';
  @override
  String get syncRunning => 'Se sincronizează…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteca $library';
  @override
  String get syncUrlLabel => 'Adresa dosarului';
  @override
  String get syncUrlRequired => 'Introduceți adresa serverului';
  @override
  String get syncUrlHint =>
      'Dosarul trebuie să existe. Copiază adresa așa cum o arată '
      'serverul.';
  @override
  String get syncHttpWarning =>
      'Conexiune necriptată: e în regulă prin VPN sau în rețeaua '
      'locală.';
  @override
  String get syncUserLabel => 'Utilizator';
  @override
  String get syncUserHint =>
      'Lasă gol dacă serverul nu cere date de autentificare.';
  @override
  String get syncPasswordLabel => 'Parolă';
  @override
  String get syncPasswordHint =>
      'Păstrată în depozitul de chei al acestui dispozitiv, '
      'niciodată în fișierele bibliotecii.';
  @override
  String get syncPasswordKeepHint => 'Lasă gol pentru a păstra parola salvată.';
  @override
  String get syncShowPassword => 'Arată parola';
  @override
  String get syncHidePassword => 'Ascunde parola';
  @override
  String get syncTestAction => 'Testează conexiunea';
  @override
  String get syncTesting => 'Se testează…';
  @override
  String get syncRetargetWarning =>
      'Cu o adresă sau un utilizator nou, următoarea '
      'sincronizare o ia de la capăt ca primă sincronizare.';
  @override
  String get syncTestOk => 'Conexiunea funcționează';
  @override
  String get syncModeFull => 'Mod complet';
  @override
  String get syncModeCompatible => 'Mod compatibil';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Citire, scriere și ștergere';
  @override
  String get syncCapEtags => 'Amprente de fișier (ETag)';
  @override
  String get syncCapNoEtags => 'Fără amprente de fișier (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Compară dimensiunea și data; în caz de îndoială descarcă '
      'din nou';
  @override
  String get syncCapGuarded => 'Scrieri protejate';
  @override
  String get syncCapUnguarded => 'Scrieri neprotejate';
  @override
  String get syncCapUnguardedDetail =>
      'Verifică fișierul pe server chiar înainte de scriere';
  @override
  String get syncCapMove => 'Redenumește fără reîncărcare';
  @override
  String get syncCapNoMove => 'Fără redenumire pe server';
  @override
  String get syncCapNoMoveDetail =>
      'O redenumire devine o ștergere și o nouă încărcare';
  @override
  String get syncCompatibleNote =>
      'În modul compatibil sincronizarea funcționează la fel, cu '
      'câteva cereri în plus.';
  @override
  String get syncTestInvalidUrl => 'Adresă nevalidă';
  @override
  String get syncTestInvalidUrlHint =>
      'Introdu o adresă http:// sau https://, fără utilizator '
      'sau parolă în ea.';
  @override
  String get syncTestOffline => 'Serverul nu poate fi accesat';
  @override
  String get syncTestOfflineHint =>
      'VPN-ul este pornit? O adresă 10.x sau 192.168.x '
      'funcționează doar din aceeași rețea.';
  @override
  String get syncTestAuth => 'Utilizator sau parolă respinse';
  @override
  String get syncTestAuthHint => 'Verifică-le, apoi testează din nou.';
  @override
  String get syncTestNotFound => 'Dosarul nu există';
  @override
  String get syncTestNotFoundHint =>
      'Creează-l pe server sau corectează adresa.';
  @override
  String get syncTestUnsupported => 'Nu este un dosar WebDAV';
  @override
  String get syncTestUnsupportedHint => 'Serverul răspunde, dar nu ca WebDAV.';
  @override
  String get syncTestFailed => 'Testul nu a reușit';
  @override
  String get syncNowAction => 'Sincronizează acum';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresă, utilizator și parolă';
  @override
  String get syncRetestTitle => 'Testează din nou serverul';
  @override
  String syncProbedAgo(String when) => 'Ultimul test $when';
  @override
  String get syncDisconnectTitle => 'Deconectează această bibliotecă';
  @override
  String get syncDisconnectSubtitle => 'Fișierele rămân aici și pe server';
  @override
  String get syncDisconnectConfirmTitle => 'Deconectezi sincronizarea?';
  @override
  String get syncDisconnectConfirmBody =>
      'Această bibliotecă nu se mai sincronizează pe acest '
      'dispozitiv. Niciun fișier nu este șters, nici aici, nici '
      'pe server. Dacă o conectezi din nou, prima sincronizare o '
      'ia de la capăt.';
  @override
  String get syncDisconnectConfirm => 'Deconectează';
  @override
  String get syncFirstTitle => 'Prima sincronizare';
  @override
  String get syncFirstIntro =>
      'Biblioteca a fost comparată cu dosarul de pe server:';
  @override
  String get syncFirstUpload => 'De încărcat';
  @override
  String get syncFirstDownload => 'De descărcat';
  @override
  String get syncFirstBoth => 'Pe ambele părți';
  @override
  String get syncFirstBothHint =>
      'Identice: niciun transfer. Diferite: de rezolvat';
  @override
  String get syncFirstNoDelete =>
      'Prima sincronizare nu șterge nimic, nici aici, nici pe '
      'server.';
  @override
  String get syncStartAction => 'Pornește';
  @override
  String syncMassTrashTitle(int count) => count % 100 == 0 || count % 100 >= 20
      ? 'Muți $count de fișiere în coș?'
      : 'Muți $count fișiere în coș?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Fișiere sincronizate care lipsesc de pe server: $count '
      'din $total. De obicei asta înseamnă o adresă greșită, un '
      'disc NAS nemontat sau un dosar golit din greșeală.';
  @override
  String get syncMassTrashHint =>
      'Dacă chiar le-ai șters pe alt dispozitiv, confirmă: aici '
      'ajung în coș.';
  @override
  String get syncMassTrashConfirm => 'Mută în coș';
  @override
  String syncMassDeleteTitle(int count) => count % 100 == 0 || count % 100 >= 20
      ? 'Ștergi $count de fișiere de pe server?'
      : 'Ștergi $count fișiere de pe server?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Fișiere sincronizate care lipsesc aici: $count din '
      '$total. Dacă nu le-ai șters tu, anulează și verifică '
      'dosarul bibliotecii.';
  @override
  String get syncMassDeleteConfirm => 'Șterge de pe server';
  @override
  String get syncTooltip => 'Sincronizează';
  @override
  String get syncStageConnecting => 'Conectare la server…';
  @override
  String get syncStageComparing => 'Comparare cu serverul…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sincronizare · $done din $total';
  @override
  String get syncStatusWarnings => 'Sincronizată cu avertismente';
  @override
  String syncConflictsHeader(int count) =>
      'Modificate aici și pe server · $count';
  @override
  String get syncConflictHint => 'Niciuna dintre versiuni nu a fost atinsă';
  @override
  String get syncResolveAction => 'Rezolvă';
  @override
  String syncFailuresHeader(int count) => 'Nesincronizate · $count';
  @override
  String get syncFailuresHint => 'Se reîncearcă la următoarea sincronizare';
  @override
  String get syncAbortAuth => 'Parolă respinsă de server';
  @override
  String get syncAbortMissingPassword => 'Nicio parolă salvată';
  @override
  String get syncAbortOffline => 'Serverul nu poate fi accesat';
  @override
  String get syncAbortRemoteMissing => 'Dosarul de pe server nu mai există';
  @override
  String get syncAbortUnsupported => 'Serverul nu mai funcționează ca WebDAV';
  @override
  String get syncAbortFailed => 'Sincronizarea nu a reușit';
  @override
  String get syncAbortNotConfirmed => 'Sincronizare anulată';
  @override
  String get syncAbortNothingTouched =>
      'Niciun fișier nu a fost atins. Modificările tale rămân '
      'aici până la următoarea sincronizare reușită.';
  @override
  String syncLastSuccess(String when) => 'Ultima sincronizare reușită $when';
  @override
  String get syncNoSuccessYet => 'Nicio sincronizare reușită încă';
  @override
  String get syncUpdatePasswordAction => 'Actualizează parola';
  @override
  String get syncRetryAction => 'Încearcă din nou';
  @override
  String get syncOpenSettingsAction => 'Setări';
  @override
  String get syncCloseAction => 'Închide';
  @override
  String get syncDoneSnack => 'Sincronizată';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sincronizată · 1 fișier șters în altă parte este în coș'
      : count % 100 == 0 || count % 100 >= 20
      ? 'Sincronizată · $count de fișiere șterse în altă parte '
            'sunt în coș'
      : 'Sincronizată · $count fișiere șterse în altă parte sunt '
            'în coș';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sincronizată · 1 conflict de rezolvat'
      : count % 100 == 0 || count % 100 >= 20
      ? 'Sincronizată · $count de conflicte de rezolvat'
      : 'Sincronizată · $count conflicte de rezolvat';
  @override
  String get syncShowAction => 'Arată';
  @override
  String get syncConflictTitle => 'Rezolvă conflictul';
  @override
  String get syncConflictBinary =>
      'Nu este un fișier text: alege ce copie păstrezi.';
  @override
  String get syncConflictKeepNote =>
      'Copia pe care nu o păstrezi rămâne în istoricul notei.';
  @override
  String get syncKeepLocal => 'Păstrează varianta de pe acest dispozitiv';
  @override
  String get syncKeepRemote => 'Păstrează varianta de pe server';
  @override
  String get syncConflictLoadFailed =>
      'Cele două versiuni nu au putut fi citite';
  @override
  String get syncResolveFailed => 'Conflictul nu a putut fi rezolvat';
  @override
  String get syncResolved => 'Conflict rezolvat';
  @override
  String get syncConflictMoved =>
      'Una dintre versiuni s-a schimbat între timp: conflictul a fost '
      'recitit, alegeți din nou.';
  @override
  String get syncSectionWhen => 'Când se sincronizează';
  @override
  String get syncAutoTitle => 'Automat';
  @override
  String get syncAutoSubtitle =>
      'După modificări, la deschidere și la intervale';
  @override
  String get syncIntervalTitle => 'Verifică serverul la fiecare';
  @override
  String get syncIntervalSubtitle => 'Doar cât timp aplicația e deschisă';
  @override
  String get syncIntervalDialogBody =>
      'Ca să vezi modificările făcute pe alte dispozitive cât timp aplicația '
      'e deschisă. Cu „Niciodată”, doar după modificări și la deschidere.';
  @override
  String syncIntervalMinutes(int count) => count == 1
      ? '1 minut'
      : count % 100 == 0 || count % 100 >= 20
      ? '$count de minute'
      : '$count minute';
  @override
  String get syncIntervalNever => 'Niciodată';
  @override
  String get syncWifiOnlyTitle => 'Doar prin Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Pe date mobile, sincronizează doar manual';
  @override
  String syncPendingChanges(int count) => count == 1
      ? '1 modificare în așteptare'
      : count % 100 == 0 || count % 100 >= 20
      ? '$count de modificări în așteptare'
      : '$count modificări în așteptare';
  @override
  String syncRetryIn(String wait) => 'se reîncearcă în $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Se așteaptă Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Se așteaptă o conexiune';
  @override
  String get syncMobileDataHint =>
      '„Sincronizează acum” folosește tot date mobile.';
  @override
  String get syncQueueKeptHint =>
      'Modificările rămân aici, chiar dacă închizi aplicația, și pleacă '
      'singure când serverul răspunde.';
  @override
  String get syncAutoPaused => 'Sincronizarea automată e în pauză';
  @override
  String get syncPausedAuthHint =>
      'Reia când actualizezi parola sau sincronizezi manual.';
  @override
  String get syncPausedServerHint =>
      'Reia când corectezi adresa sau sincronizezi manual.';
  @override
  String get syncPausedConfirmHint =>
      '„Sincronizează acum” arată ce ar fi șters și întreabă întâi.';
  @override
  String get syncNeedsConfirmation => 'Se așteaptă confirmarea ta';
  @override
  String get syncMergeIntro =>
      'Modificările care nu se suprapun sunt deja îmbinate; alege ce păstrezi '
      'acolo unde se suprapun.';
  @override
  String get syncMergeClean =>
      'Cele două versiuni se îmbină singure: nimic nu se suprapune.';
  @override
  String get syncMergeNoBase =>
      'Nu există o versiune comună pentru îmbinare: alegi tu în fiecare loc '
      'în care cele două copii diferă.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Suprapunerea $index din $total';
  @override
  String get syncMergeFromLocal => 'De pe acest dispozitiv';
  @override
  String get syncMergeFromRemote => 'De pe server';
  @override
  String get syncMergeRemovedLines => 'Linii eliminate';
  @override
  String get syncMergeAbsentLines => 'Nu există în această copie';
  @override
  String get syncMergeKeepLocal => 'Ale mele';
  @override
  String get syncMergeKeepRemote => 'De pe server';
  @override
  String get syncMergeKeepBoth => 'Ambele';
  @override
  String get syncMergeSave => 'Salvează îmbinarea';
  @override
  String get syncMergeKeepWhole => 'Sau păstrează o copie întreagă';
}
