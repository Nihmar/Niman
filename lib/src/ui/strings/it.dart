// The Italian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class ItalianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  @override
  List<String> get monthNamesShort => const [
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];
  @override
  List<String> get weekdayNames => const [
    'lunedì',
    'martedì',
    'mercoledì',
    'giovedì',
    'venerdì',
    'sabato',
    'domenica',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'lun',
    'mar',
    'mer',
    'gio',
    'ven',
    'sab',
    'dom',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Cestino';
  @override
  String get trashSubtitle =>
      'Gli elementi eliminati vanno in .trash/ (off = eliminazione '
      'definitiva)';
  @override
  String get trashAutoEmptyTitle => 'Svuotamento automatico del cestino';
  @override
  String get trashAutoEmptySubtitle =>
      'Le eliminazioni più vecchie spariscono all’apertura';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Mai'
      : days == 1
      ? '1 giorno'
      : '$days giorni';
  @override
  String get debugLogsTitle => 'Log di debug';
  @override
  String get debugLogsSubtitle =>
      'Registra gli eventi dell’app in un buffer in memoria';
  @override
  String get lineNumbersTitle => 'Numeri di riga';
  @override
  String get lineNumbersSubtitle =>
      'Mostra la colonna dei numeri di riga nell’editor';
  @override
  String get readableLineLengthTitle => 'Lunghezza di riga leggibile';
  @override
  String get readableLineLengthSubtitle =>
      'Tieni il testo della nota in una colonna centrata invece che su tutta '
      'la larghezza della finestra';
  @override
  String get noteColumnWidthTitle => 'Larghezza della colonna';
  @override
  String get noteColumnWidthSubtitle =>
      'Quanto è larga la colonna della nota, in pixel';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Tastiera all’apertura';
  @override
  String get keyboardOnOpenSubtitle =>
      'Mostra la tastiera appena si apre una nota (off = al primo tocco)';
  @override
  String get editorKindSource => 'Sorgente Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Sorgente Markdown, così com\u2019è scritta';
  @override
  String get editorKindWysiwygSubtitle =>
      'Testo formattato, modificato sul posto';
  @override
  String get settingsFolderToCreate => 'da creare';
  @override
  String get settingsSearchHint => 'Cerca nelle impostazioni';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 impostazione trovata' : '$count impostazioni trovate';
  @override
  String get settingsToggleOn => 'Attivo';
  @override
  String get settingsToggleOff => 'Non attivo';
  @override
  String get settingsPreviewEnabledTitle => 'Anteprima';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Mostra la nota renderizzata accanto all’editor sorgente';
  @override
  String get switchToWysiwygTooltip => 'Passa all’editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Passa al sorgente Markdown';
  @override
  String get switchToSourceLabel => 'Sorgente';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Questa nota è troppo grande per l’editor WYSIWYG. Aprila nel sorgente '
      'Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aspetto';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Libreria';
  @override
  String get settingsSectionReminders => 'Promemoria';
  @override
  String get settingsSectionShortcuts => 'Tastiera';
  @override
  String get keyboardShortcutsTitle => 'Scorciatoie da tastiera';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Libreria $name';
  @override
  String get settingsGroupLibraryHint => 'vale solo per questa libreria';
  @override
  String get settingsGroupMaintenance => 'Manutenzione';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Cartelle e percorsi';
  @override
  String get settingsAreaTrashHistory => 'Cestino e cronologia';
  @override
  String get settingsAreaDiagnostics => 'Diagnostica e info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Serve una tastiera fisica collegata';
  @override
  String get settingsSectionUpdates => 'Aggiornamenti';
  @override
  String get autoUpdateTitle => 'Aggiornamenti automatici';
  @override
  String get autoUpdateSubtitle =>
      'Controlla GitHub Releases all’avvio e ogni 6 ore';
  @override
  String get checkForUpdatesTitle => 'Controlla aggiornamenti';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version è disponibile';
  @override
  String get updateUpToDate => 'Niman è aggiornato';
  @override
  String get updateCheckFailed => 'Controllo aggiornamenti non riuscito';
  @override
  String updateSavedTo(Object path) => 'Aggiornamento salvato in $path';
  @override
  String get updateInstallerStarted => 'Programma di installazione avviato';
  @override
  String get settingsSectionDiagnostics => 'Diagnostica';
  @override
  String get settingsSpellCheckTitle => 'Controlla ortografia';
  @override
  String get settingsSpellCheckSubtitle =>
      'Sottolinea le parole errate mentre scrivi.';
  @override
  String get spellCheckDictionaryTitle => 'Dizionario';
  @override
  String get spellCheckDictionarySystem => 'Predefinito di sistema';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Scegli dizionari';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Scegli ogni lingua in cui è scritta questa libreria. Una parola è '
      'corretta se la conosce almeno un dizionario scelto; senza scelte '
      'decide la lingua di sistema.';
  @override
  String get spellCheckNoDictionaries =>
      'Nessun dizionario trovato su questo sistema.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Controlla ortografia';
  @override
  String get spellCheckTitle => 'Ortografia';
  @override
  String get spellCheckEmpty => 'Nessun errore di ortografia.';
  @override
  String get spellCheckUnavailable =>
      'hunspell non è installato su questo sistema.';
  @override
  String get spellCheckNoSuggestions => 'Nessun suggerimento';
  @override
  String spellCheckCount(int count) => '$count da rivedere';
  @override
  String spellCheckLine(int line) => 'riga $line';
  @override
  String get addWordToDictionary => 'Aggiungi al dizionario';

  @override
  String indentWidthValue(int spaces) => '$spaces spazi';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Luminosità';
  @override
  String get themeBrightnessSubtitle =>
      'Chiara, scura o quella impostata sul dispositivo';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Chiara';
  @override
  String get themeBrightnessNight => 'Scura';
  @override
  String get themePaletteTitle => 'Palette';
  @override
  String get themePaletteSubtitle => 'I colori dell’interfaccia e della nota';
  @override
  String get themePaletteSystem => 'Sistema';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Dimensione del testo dell’interfaccia';
  @override
  String get uiTextScaleSubtitle =>
      'L’albero, le schede e i dialoghi; oltre all’impostazione di '
      'sistema';
  @override
  String get noteTextScaleTitle => 'Dimensione del testo delle note';
  @override
  String get noteTextScaleSubtitle =>
      'L’editor e l’anteprima, che restano d’accordo';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Modalità anteprima';
  @override
  String get previewModeSubtitle =>
      'Se l’anteprima divide lo schermo con l’editor o lo sostituisce';
  @override
  String get previewModeAuto => 'Affiancata';
  @override
  String get previewModeSwitch => 'A tutto schermo';
  @override
  String get splitRatioTitle => 'Larghezza divisione';
  @override
  String get splitRatioSubtitle =>
      'La quota dell’editor quando l’anteprima è affiancata';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formato dei link';
  @override
  String get linkTypeSubtitle => 'Cosa inserisce il pulsante link dell’editor';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Crea le note mancanti in';
  @override
  String get missingNoteLocationRoot => 'Radice della libreria';
  @override
  String get missingNoteLocationCurrentFolder => 'Cartella attuale';
  @override
  String get indentWidthTitle => 'Ampiezza del rientro';
  @override
  String get indentWidthSubtitle =>
      'Spazi aggiunti per ogni livello di rientro nell’editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Lingua';
  @override
  String get languageSubtitle => 'La lingua dei testi dell’app';
  @override
  String get languageSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Aggiungi un elemento';
  @override
  String get listAddTooltip => 'Aggiungi un elemento';
  @override
  String get listEmpty => 'Nessun elemento per ora';
  @override
  String get listDragHandleLabel => 'Riordina l’elemento';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Nessuna registrazione per ora';
  @override
  String get audioRecord => 'Registra';
  @override
  String get audioStop => 'Ferma';
  @override
  String get audioPlay => 'Riproduci';
  @override
  String get audioDelete => 'Elimina registrazione';
  @override
  String get audioImport => 'Importa un file audio';
  @override
  String get audioRecording => 'Registrazione…';
  @override
  String get audioPermissionDenied =>
      'Permesso del microfono negato — serve per registrare.';
  @override
  String get newAudioNoteTitle => 'Nuova nota vocale';
  @override
  String get newAudioNoteDefault => 'La mia registrazione';
  @override
  String get showAudioTooltip => 'Mostra registrazioni';
  @override
  String get audioMessageHint => 'Scrivi una nota…';
  @override
  String get audioSend => 'Invia';
  @override
  String get audioRename => 'Rinomina registrazione';
  @override
  String get audioDescriptionHint => 'Descrivi questa registrazione…';
  @override
  String get audioEditDescription => 'Modifica descrizione';
  @override
  String get audioDeleteNote => 'Elimina nota';
  @override
  String get audioEditNote => 'Modifica nota';
  @override
  String get audioPause => 'Pausa';
  @override
  String get audioEditTitle => 'Modifica titolo';
  @override
  String get audioTitleHint => 'Dai un titolo alla registrazione…';
  @override
  String audioUntitled(int n) => 'Registrazione $n';
  @override
  String get audioMoreActions => 'Altre azioni';
  @override
  String get audioDiscardRecording => 'Scarta registrazione';
  @override
  String get audioPauseRecording => 'Metti in pausa la registrazione';
  @override
  String get audioResumeRecording => 'Riprendi la registrazione';
  @override
  String get audioRecordingPaused => 'In pausa';
  @override
  String get audioSavingRecording => 'Salvataggio…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rapida';
  @override
  String get trayOpen => 'Apri Niman';
  @override
  String get trayQuit => 'Esci';
  @override
  String get closeToTrayTitle => 'Chiudi nell’area di notifica';
  @override
  String get closeToTraySubtitle =>
      'La × della finestra nasconde Niman e lo lascia in esecuzione, così i '
      'promemoria continuano ad arrivare. Si esce dal menu dell’icona.';
  @override
  String get shortcutNewTodo => 'Nuova attività';
  @override
  String get shortcutNewNote => 'Nuova nota';
  @override
  String get shortcutNewList => 'Nuova lista';
  @override
  String get shortcutNewAudio => 'Nuova nota vocale';
  @override
  String get shortcutToggleSidebar => 'Mostra o nascondi l’albero dei file';
  @override
  String get shortcutCloseTab => 'Chiudi la nota corrente';
  @override
  String get shortcutNextTab => 'Nota aperta successiva';
  @override
  String get shortcutPreviousTab => 'Nota aperta precedente';
  @override
  String get shortcutEditorSection => 'Nell’editor';
  @override
  String get shortcutFormatSection => 'Formattazione';
  @override
  String get shortcutFind => 'Trova';
  @override
  String get shortcutReplace => 'Trova e sostituisci';
  @override
  String get shortcutSavingNote =>
      'Le modifiche si salvano da sole: non c’è una scorciatoia per '
      'salvare.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Caricamento…';
  @override
  String get noteStatusSaving => 'Salvataggio…';
  @override
  String get noteStatusUnsaved => 'Non salvato';
  @override
  String get noteStatusSaved => 'Salvato';
  @override
  String get noteStatusError => 'Errore';
  @override
  String get noteNotText =>
      'Questo file non è una nota di testo, quindi '
      'Niman non può mostrarlo qui.';
  @override
  String get noteLoadFailed => 'Impossibile aprire questa nota.';
  @override
  String wordCount(int count) => count == 1 ? '1 parola' : '$count parole';
  @override
  String get outlineTooltip => 'Struttura';
  @override
  String get outlineNoHeadings => 'Nessun titolo';
  @override
  String get outlineNoTitle => '(senza titolo)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Grassetto';
  @override
  String get toolbarItalic => 'Corsivo';
  @override
  String get toolbarStrikethrough => 'Barrato';
  @override
  String get toolbarSuperscript => 'Apice';
  @override
  String get toolbarUnderline => 'Sottolineato';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Blocco di codice';
  @override
  String get toolbarImage => 'Inserisci immagine';
  @override
  String get toolbarHeading => 'Titolo';
  @override
  String get toolbarList => 'Elenco';
  @override
  String get toolbarOrderedList => 'Elenco numerato';
  @override
  String get toolbarQuote => 'Citazione';
  @override
  String get toolbarIndent => 'Aumenta rientro';
  @override
  String get toolbarOutdent => 'Riduci rientro';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Strumenti';
  @override
  String get editorToolsTitle => "Strumenti dell'editor";
  @override
  String get toolCountListTitle => 'Conta una lista';
  @override
  String get toolCountListSubtitle =>
      'Somma quello che le righe elencano, come lista di spunta';
  @override
  String get toolCountListNeedsList =>
      'Questa nota non ha nessuna lista da contare';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Leggi ogni riga come';
  @override
  String get tallyCutDash => 'Nome - valori';
  @override
  String get tallyCutColon => 'Nome: valori';
  @override
  String get tallyCutCommas => 'Valori separati da virgola';
  @override
  String get tallyCutWhole => 'Tutta la riga, come un solo valore';
  @override
  String get tallySortLabel => 'Ordine';
  @override
  String get tallySortCount => 'Prima i più numerosi';
  @override
  String get tallySortAlphabetical => 'Alfabetico';
  @override
  String get tallySortFirstSeen => "Nell'ordine della lista";
  @override
  String get tallyInsert => 'Inserisci';
  @override
  String get tallyUpdate => 'Aggiorna';
  @override
  String get tallyNothingToCount => "Qui non c'è niente da contare";
  @override
  String get headingDialogTitle => 'Livello del titolo';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Barra dell’editor';
  @override
  String get toolbarSettingsHint =>
      'Trascina per riordinare; l’occhio mostra o nasconde un pulsante.';
  @override
  String get toolbarShowButton => 'Mostra';
  @override
  String get toolbarHideButton => 'Nascondi';
  @override
  String get toolbarResetOrder => 'Ripristina predefiniti';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Mostra anteprima';
  @override
  String get showEditorTooltip => 'Mostra editor';
  @override
  String get enterFullScreenTooltip => 'Schermo intero';
  @override
  String get exitFullScreenTooltip => 'Esci da schermo intero';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tabella HTML grezza)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Cerca nelle note';
  @override
  String get searchModeWords => 'Parole';
  @override
  String get searchModeContains => 'Contiene';
  @override
  String get searchEmptyHint =>
      'Scrivi per cercare nella libreria, oppure chiave = valore per '
      'filtrare per frontmatter';
  @override
  String get searchTooShortHint => 'Scrivi almeno 2 caratteri';
  @override
  String get searchNoMatches => 'Nessuna corrispondenza';
  @override
  String get searchLoadMore => 'Mostra altri';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Sostituisci…';
  @override
  String get replaceInNoteAction => 'Sostituisci in questa nota…';
  @override
  String get replaceInThisNote => 'Sostituisci in questa nota';
  @override
  String get replaceWithLabel => 'Sostituisci con';
  @override
  String get replaceCaseSensitive => 'Distingui maiuscole';
  @override
  String get replaceWholeWordsHint =>
      'si sostituiscono solo le parole intere esatte';
  @override
  String get replaceConfirm => 'Sostituisci';
  @override
  String get replaceCancel => 'Chiudi';
  @override
  String get replaceUnavailable => 'La sostituzione non è disponibile ora';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Trova nella nota';
  @override
  String get editorFindHint => 'Trova';
  @override
  String get editorReplaceHint => 'Sostituisci';
  @override
  String get editorFindCaseTooltip => 'Distingui maiuscole';
  @override
  String get editorFindPreviousTooltip => 'Corrispondenza precedente';
  @override
  String get editorFindNextTooltip => 'Corrispondenza successiva';
  @override
  String get editorFindCloseTooltip => 'Chiudi la ricerca';
  @override
  String get editorFindReplaceModeTooltip => 'Modalità sostituzione';
  @override
  String get editorReplaceOneTooltip => 'Sostituisci questa';
  @override
  String get editorReplaceAllTooltip => 'Sostituisci tutte';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tag';
  @override
  String get tagsTitle => 'Tag';
  @override
  String get tagsEmpty =>
      'Nessun tag per ora — aggiungi un #tag o i tag nel frontmatter';
  @override
  String get tagsBackTooltip => 'Torna alla ricerca';
  @override
  String get tagsNotesEmpty => 'Nessuna nota con questo tag';
  @override
  String tagsNotesCapped(int limit) =>
      'Sono elencate solo le prime $limit — cerca il tag per restringere';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Link non trovato';
  @override
  String get headingNotFoundTitle => 'Titolo non trovato';
  @override
  String get ambiguousLinkTitle => 'Più note corrispondono';
  @override
  String get openLinkFailed => 'Impossibile aprire il link';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'La nota non esiste';
  @override
  String missingNoteDialogBody(String path) => 'Creare «$path»?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'La cartella «$folder» non esiste';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Da fare';
  @override
  String get todoDone => 'Fatte';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Tutte le date';
  @override
  String get todoFilter => 'Filtra';
  @override
  String get todoNoTokens => 'Nessun token in questa lista';
  @override
  String get todoCountOpen => 'da fare';
  @override
  String get todoCountDone => 'fatte';
  @override
  String get todoEmptyOpen => 'Nessuna attività da fare';
  @override
  String get todoEmptyDone => 'Niente di completato per ora';
  @override
  String get todoEmptyFiltered => 'Nessuna attività corrisponde';
  @override
  String get todoTitle => 'Attività';
  @override
  String get todoAddTooltip => 'Aggiungi attività';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Il formato todo.txt';
  @override
  String get todoHelpTooltip => 'Guida al formato';
  @override
  String get todoHelpIntro =>
      'Le tue attività sono un unico file di testo, una per riga. Niman '
      'scrive la sintassi per te, ma non nasconde niente: puoi '
      'modificare il file in qualsiasi editor e Niman lo rilegge.';
  @override
  String get todoHelpFilesTitle => 'I due file';
  @override
  String get todoHelpFilesBody =>
      'Le attività da fare stanno in todo.txt alla radice della libreria. '
      'Completandone una, la riga passa in done.txt, così todo.txt '
      'resta corto. Se una riga completata torna in todo.txt, Niman '
      'la archivia alla lettura successiva.';
  @override
  String get todoHelpLineTitle => 'Anatomia di una riga';
  @override
  String get todoHelpLineBody =>
      'Tutto ciò che precede la descrizione è facoltativo e va in '
      'quest’ordine:';
  @override
  String get todoHelpDoneBody =>
      'Segna l’attività come fatta. Niman la aggiunge quando spunti la '
      'casella.';
  @override
  String get todoHelpPriority => 'da (A) a (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priorità. A è la più alta. Compare come pastiglia nella lista.';
  @override
  String get todoHelpDatesBody =>
      'Data di completamento, poi data di creazione. Con una sola data è '
      'quella di creazione, a meno che la riga inizi con x.';
  @override
  String get todoHelpTokensTitle => 'Progetti, contesti e tag';
  @override
  String get todoHelpTokensBody =>
      'In qualsiasi punto della descrizione, una parola con uno di questi '
      'prefissi diventa una pastiglia con cui filtrare. Niente è '
      'predefinito: un token esiste appena lo scrivi.';
  @override
  String get todoHelpProjectBody =>
      'Di cosa fa parte l’attività, per esempio +cucina o +tesi.';
  @override
  String get todoHelpContextBody =>
      'Dove o come la farai, per esempio @casa o @telefonate.';
  @override
  String get todoHelpHashtagBody =>
      'Un’etichetta libera, per tutto ciò che gli altri due non coprono.';
  @override
  String get todoHelpTagsTitle => 'Date e promemoria';
  @override
  String get todoHelpTagsBody =>
      'Sono tag chiave:valore. Niman li scrive dalla finestra '
      'dell’attività e li legge ovunque compaiano nella riga.';
  @override
  String get todoHelpDueBody =>
      'La scadenza. Guida la pastiglia colorata e i filtri per data.';
  @override
  String get todoHelpRemBody =>
      'Quando inviare una notifica, nella tua ora locale. Arriva anche a '
      'schermo spento e con l’app chiusa.';
  @override
  String get todoHelpRemDesktop =>
      'Su desktop Niman deve essere aperto al momento giusto: il promemoria '
      'compare mentre l’app è aperta, e nulla scatta a app chiusa.';
  @override
  String get todoHelpOtherBody =>
      'Conservati esattamente come scritti, così i tag di altre app '
      'todo.txt sopravvivono al giro. Niman non li interpreta, rec: '
      'compreso: un’attività ricorrente non viene ancora ripetuta.';
  @override
  String get todoHelpEditTitle => 'Modifiche fuori da Niman';
  @override
  String get todoHelpEditBody =>
      'Un’attività che non hai toccato viene riscritta byte per byte, '
      'spaziature strane comprese. Se modifichi una riga, Niman '
      'riscrive solo quella in forma canonica e lascia stare il resto.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Aggiungi attività';
  @override
  String get todoEditTitle => 'Modifica attività';
  @override
  String get todoDescriptionHint => 'Descrizione';
  @override
  String get todoCancel => 'Annulla';
  @override
  String get todoSave => 'Salva';
  @override
  String get todoEditAction => 'Modifica';
  @override
  String get todoDeleteAction => 'Elimina';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Scadute';
  @override
  String get todoDueToday => 'Oggi';
  @override
  String get todoDueNext7 => 'Prossimi 7 giorni';
  @override
  String get todoDueNoDate => 'Senza data';
  @override
  String get todoRowDue => 'Scade';
  @override
  String get todoRowDueToday => 'Scade oggi';
  @override
  String get todoSortTooltip => 'Ordina';
  @override
  String get todoSortDue => 'Scadenza';
  @override
  String get todoSortPriority => 'Priorità';
  @override
  String get todoSortCreation => 'Data di creazione';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Nessuna priorità';
  @override
  String get todoNoPriorityShort => 'Nessuna';
  @override
  String get todoMorePriorities => 'Altre…';
  @override
  String get todoPriorityTitle => 'Priorità';
  @override
  String get todoNoDueDate => 'Nessuna scadenza';
  @override
  String get todoNoReminder => 'Nessun promemoria';
  @override
  String get todoAddProject => '+ Progetto';
  @override
  String get todoAddContext => '@ Contesto';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Promemoria attività';
  @override
  String get todoReminderChannelDescription =>
      'Avvisi programmati per le attività con un orario di promemoria.';
  @override
  String get todoReminderBody => 'Promemoria';
  @override
  String get todoReminderFallbackTitle => 'Promemoria attività';
  @override
  String get todoReminderBlocked =>
      'Le notifiche sono disattivate, quindi i promemoria non compaiono.';
  @override
  String get todoReminderBattery =>
      'L’ottimizzazione della batteria è attiva per Niman. Il sistema può '
      'sospendere l’app e perdere i promemoria in attesa.';
  @override
  String get todoReminderInexact =>
      'Questo dispositivo non consente sveglie esatte, quindi un '
      'promemoria può arrivare con qualche minuto di ritardo a schermo '
      'spento.';
  @override
  String get reminderShowTokensTitle => 'Tag nelle notifiche dei promemoria';
  @override
  String get reminderShowTokensSubtitle =>
      'Mantiene +progetto, @contesto e #tag nel testo della notifica. Off '
      'mostra solo l’attività che hai scritto.';
  @override
  String get todoReminderFixAction => 'Apri impostazioni';
  @override
  String get todoReminderDismissAction => 'Ignora';
  @override
  String get todoReminderDue => 'Scade';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Annulla';
  @override
  String get actionCreate => 'Crea';
  @override
  String get actionNew => 'Nuovo';
  @override
  String get actionSave => 'Salva';
  @override
  String get actionClear => 'Svuota';
  @override
  String get actionChoose => 'Scegli';
  @override
  String get actionDelete => 'Elimina';
  @override
  String get actionRename => 'Rinomina';
  @override
  String get actionMove => 'Sposta';
  @override
  String get saveAndClose => 'Salva e chiudi';
  @override
  String get closeUnsavedTitle => 'Modifiche non salvate';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return "'${names.first}' ha modifiche non ancora salvate. "
          'Salvarle prima di chiudere?';
    }
    return '${names.length} note hanno modifiche non ancora salvate. '
        'Salvarle prima di chiudere?';
  }

  @override
  String get closeSaveFailed => 'Salvataggio fallito: ancora aperta.';
  @override
  String get actionRestore => 'Ripristina';
  @override
  String get actionEmpty => 'Svuota';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Nascondi il pannello (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Mostra il pannello (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Riduci a icona';
  @override
  String get windowMaximizeTooltip => 'Ingrandisci';
  @override
  String get windowRestoreTooltip => 'Ripristina';
  @override
  String get windowCloseTooltip => 'Chiudi';
  @override
  String get tabFiles => 'File';
  @override
  String get tabSearch => 'Cerca';
  @override
  String get tabSettings => 'Impostazioni';
  @override
  String get quickNoteTitle => 'Nota rapida';
  @override
  String get treeEmpty => 'Nessuna nota';
  @override
  String get selectANote => 'Seleziona una nota';
  @override
  String get showListTooltip => 'Mostra elenco';
  @override
  String get editRawTooltip => 'Modifica il sorgente';
  @override
  String get sortAscTooltip => 'Ordina A-Z';
  @override
  String get sortDescTooltip => 'Ordina Z-A';
  @override
  String get newNoteTitle => 'Nuova nota';
  @override
  String get newItemTooltip => 'Nuovo';
  @override
  String get closeMenuTooltip => 'Chiudi';
  @override
  String get newFolderTitle => 'Nuova cartella';
  @override
  String get newNoteSameFolder => 'Nuova nota nella stessa cartella';
  @override
  String get newFromTemplateSameFolder =>
      'Nuova da modello nella stessa cartella';
  @override
  String trashOriginalPath(String path) => 'era in $path';
  @override
  String get trashOriginalRoot => 'era in radice della libreria';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 elemento' : '$count elementi';
  @override
  String get newNoteHere => 'Nuova nota qui';
  @override
  String get newFolderHere => 'Nuova cartella qui';
  @override
  String get newListNoteTitle => 'Nuova lista';
  @override
  String get newListNoteDefault => 'La mia lista';
  @override
  String get setAsQuickNote => 'Imposta come nota rapida';
  @override
  String get currentQuickNote => 'Nota rapida attuale';
  @override
  String get pinnedSection => 'Fissate';
  @override
  String pinnedSectionCount(int count) => 'Fissate · $count';
  @override
  String get templateFolderTitle => 'Cartella dei modelli';
  @override
  String get newFromTemplateTitle => 'Nuova da modello';
  @override
  String get newFromTemplateHere => 'Nuova da modello qui';
  @override
  String get templateFormTitle => 'Compila il modello';
  @override
  String get templateFormBacklink => 'Collegata da';
  @override
  String get templateFormNoNote => 'Nessuna nota';
  @override
  String get templateFormPickNote => 'Scegli la nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Segnaposto dei modelli';
  @override
  String get templateHelpSubtitle =>
      'Data, titolo e gli altri valori da sostituire';
  @override
  String get quickNoteSubtitle => 'La nota che apre la scheda Nota rapida';
  @override
  String get listFolderSubtitle => 'Le nuove liste di cose da fare';
  @override
  String get templateFolderSubtitle => 'Da cui pesca «Nuova da modello»';
  @override
  String get attachmentsFolderSubtitle =>
      'Immagini e audio inseriti in una nota';
  @override
  String get templateHelpIntro =>
      'Un modello è una nota come le altre, con dei buchi dentro. Creare '
      'una nota da un modello ne copia il testo e riempie i buchi.';
  @override
  String get templateHelpUnknown =>
      'Un segnaposto che Niman non conosce resta scritto com’è, così un '
      'errore di battitura si vede nella nota invece di mangiarsi una '
      'riga in silenzio.';
  @override
  String get templateHelpValuesTitle => 'Valori';
  @override
  String get templateHelpTitleBody =>
      'Il nome con cui la nota sta per essere creata.';
  @override
  String get templateHelpDateBody =>
      'Oggi, e l’ora adesso. Entrambi accettano un formato: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'La data e l’ora insieme.';
  @override
  String get templateHelpUuidBody =>
      'Un identificatore nuovo, diverso a ogni occorrenza.';
  @override
  String get templateHelpCounterBody =>
      'Un numero che cresce per nome, conservato tra i riavvii: la prima '
      'nota scrive 1, la successiva 2. Lo stesso nome in una nota scrive '
      'lo stesso numero; da combinare con |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Mette il cursore qui quando la nota viene creata; il marcatore non '
      'viene scritto. Vince il primo marcatore, niente filtri, solo note '
      'nuove — e la tastiera si apre anche con auto-focus spento.';
  @override
  String get templateHelpDatesTitle => 'Scrivere una data';
  @override
  String get templateHelpDatesBody =>
      'Questi stanno per le parti della data dentro un formato. Tutto il '
      'resto è letterale, e anche il testo fra apici singoli lo è. I '
      'nomi di mese e di giorno seguono la lingua dell’app.';
  @override
  String get templateHelpYear => 'l’anno: 2026, 26';
  @override
  String get templateHelpMonth => 'il mese: 03, 3, marzo, mar';
  @override
  String get templateHelpDay => 'il giorno: 09, 9, lunedì, lun';
  @override
  String get templateHelpTime => 'ore, minuti, secondi';
  @override
  String get templateHelpWeek => 'la settimana ISO e il trimestre: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtri';
  @override
  String get templateHelpFiltersBody =>
      'Un valore può essere seguito da filtri, applicati da sinistra a '
      'destra.';
  @override
  String get templateHelpCaseBody =>
      'Maiuscolo, minuscolo, e l’iniziale di ogni parola — una parola che '
      'hai scritto tu con la maiuscola resta com’è.';
  @override
  String get templateHelpSlugBody =>
      'La forma da link del testo, per costruire un wikilink.';
  @override
  String get templateHelpPadBody =>
      'Toglie gli spazi ai lati; riempie di zeri fino a una larghezza; usa '
      'un ripiego quando il valore è vuoto.';
  @override
  String get templateHelpShiftBody =>
      'Sposta una data di giorni, settimane, mesi o anni — la lezione della '
      'settimana prossima, il file del mese scorso.';
  @override
  String get templateHelpSnapBody =>
      'Porta una data all’inizio o alla fine della sua settimana, del mese '
      'o dell’anno.';
  @override
  String get templateHelpAskTitle => 'Chiedere qualcosa';
  @override
  String get templateHelpAskBody =>
      'Prima che la nota venga creata compare un modulo, una casella per '
      'domanda, più una per il collegamento se il modello lo vuole. '
      'La stessa etichetta due volte è una domanda sola, e la '
      'risposta riempie ogni occorrenza — cartella e nome del file '
      'compresi.';
  @override
  String get templateHelpAskFieldBody =>
      'Una casella in cui scrivere; il testo dopo i secondi due punti è '
      'quello con cui parte.';
  @override
  String get templateHelpChoiceBody =>
      'Una scelta da una lista, separata da virgole.';
  @override
  String get templateHelpWhereTitle => 'Dove va la nota';
  @override
  String get templateHelpWhereBody =>
      'Questi non sono testo: sono istruzioni, e stanno in un blocco '
      'niman: nel frontmatter del modello stesso. Il blocco viene '
      'eseguito e poi rimosso, quindi non compare mai nella nota. I '
      'loro valori possono contenere segnaposto.';
  @override
  String get templateHelpFolderBody =>
      'La cartella in cui la nota viene creata, creata se non esiste. Senza '
      'di essa la nota finisce dove eri tu.';
  @override
  String get templateHelpFilenameBody =>
      'Come si chiama la nota. A un modello che lo dichiara non viene '
      'chiesto il nome.';
  @override
  String get templateHelpAppendBody =>
      'Aggiunge alla nota se esiste già, invece di crearne una seconda. È '
      'quello che trasforma un mese di riunioni in un solo file.';
  @override
  String get templateHelpOpenBody =>
      'Cosa succede quando la nota esiste: l’editor (il valore '
      'predefinito), l’anteprima, o niente — la nota viene archiviata e '
      'tu resti dove eri.';
  @override
  String get templateHelpAroundTitle => 'Da dove arriva';
  @override
  String get templateHelpParentBody =>
      'Una nota che scegli nel modulo, che ti propone quella sullo schermo; '
      'scrivi [[{{parent}}]] per un link che ci riporta.';
  @override
  String get templateHelpFolderValueBody =>
      'La cartella in cui la nota è finita.';
  @override
  String get templateHelpClipboardBody =>
      'Cosa c’è negli appunti, e la selezione dell’editor se la nota è '
      'partita da una.';
  @override
  String get templateHelpIncludeTitle => 'Riusare un pezzo';
  @override
  String get templateHelpIncludeBody =>
      'Incolla un altro modello, così dieci modelli possono condividere una '
      'sola checklist. Viene cercato prima nella cartella dei modelli, e '
      'il .md si può omettere. Le sue domande finiscono nello stesso '
      'modulo.';
  @override
  String get templateHelpExampleTitle => 'Tutto insieme';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nessun modello “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” include sé stesso';
  @override
  String includeTooDeep(String path) =>
      '⚠ “$path” è annidato troppo in profondità';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter non letto: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Il frontmatter di “$template” non è stato letto, quindi la sua '
      'cartella e il nome del file non hanno fatto nulla: $reason';
  @override
  String get templatePickerTitle => 'Scegli un modello';
  @override
  String templatePickerEmpty(String folder) =>
      'Nessun modello. Metti una nota in $folder/ e diventa un modello.';

  // Tree actions.
  @override
  String get actionPin => 'Fissa in alto';
  @override
  String get actionUnpin => 'Non fissare più';
  @override
  String get pinToWidget => 'Fissa nel widget';
  @override
  String get pinnedForWidget =>
      'Fissata: ora aggiungi il widget Nota alla schermata home';
  @override
  String get pinWidgetUnavailable => 'I widget sono disponibili su Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Mostra nel file manager';
  @override
  String get openInDefaultApp => 'Apri con l’app predefinita';
  @override
  String get newNoteTabTooltip => 'Nuova nota in una nuova scheda';
  @override
  String get openNotesTooltip => 'Note aperte';
  @override
  String get closeTabTooltip => 'Chiudi';
  @override
  String get openInNewTab => 'Apri in una nuova scheda';
  @override
  String get splitRight => 'Dividi a destra';
  @override
  String get splitDown => 'Dividi in basso';
  @override
  String get moveToOtherPane => 'Sposta nell’altro pannello';
  @override
  String get openBeside => 'Apri di lato';
  @override
  String get closeAllNotes => 'Chiudi tutte';
  @override
  String get sidePanelTooltip => 'Mostra o nascondi il pannello laterale';
  @override
  String get historyAllVersions => 'Tutte le versioni';
  @override
  String get commandPaletteTitle => 'Palette dei comandi';
  @override
  String get goToNoteTitle => 'Vai alla nota';
  @override
  String get paletteGroupNote => 'Nota';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Vista';
  @override
  String get paletteGroupLibrary => 'Libreria';
  @override
  String get paletteGroupGoTo => 'Vai a';
  @override
  String get commandsTitle => 'Comandi';
  @override
  String get commandsIntro =>
      'La palette dei comandi offre solo i comandi che si possono eseguire '
      'dove sei. Qui ci sono tutti, e quando compare ciascuno.';
  @override
  String get commandNeedNone => 'Sempre disponibile';
  @override
  String get commandNeedOpenNote => 'Serve una nota aperta';
  @override
  String get commandNeedWideWindow => 'Solo con finestra larga';
  @override
  String get commandNeedDockRoom =>
      'Serve una finestra larga abbastanza per il pannello laterale';
  @override
  String get commandNeedDesktop => 'Solo desktop';
  @override
  String get commandNeedNotInZen => 'Non in modalità Zen';
  @override
  String get commandNeedZenRoom => 'Desktop, con una nota aperta in una scheda';
  @override
  String get commandNeedPreview =>
      "Con l'anteprima attiva, su una nota di testo";
  @override
  String get commandNeedTwoEditors => 'Con entrambi gli editor abilitati';
  @override
  String get paletteHint => 'Cerca comandi e note';
  @override
  String get paletteNoResults => 'Nessun risultato';
  @override
  String get paletteCommands => 'Comandi';
  @override
  String get paletteNotes => 'Note';
  @override
  String get paletteFooter =>
      '↑↓ per spostarti · ↵ per usare · esc per chiudere';
  @override
  String get paletteFooterTouch =>
      'Tocca per usare · la puntina lo tiene in cima';
  @override
  String get palettePinned => 'Fissati';
  @override
  String get palettePin => 'Fissa';
  @override
  String get paletteUnpin => 'Togli';
  @override
  String get palettePinFooter => 'alt+P per fissare';
  @override
  String get spellCheckScanning => 'Controllo della nota…';
  @override
  String get spellCheckAgain => 'Controlla di nuovo';
  @override
  String spellCheckCapped(int count) =>
      'Sono elencati i primi $count: correggine alcuni, poi controlla di '
      'nuovo per gli altri';
  @override
  String get dropHint =>
      'Rilascia file Markdown per aprirli, o una cartella per importarla';
  @override
  String get dropNothing =>
      'Il sistema non ha passato nessun file per quel trascinamento.';
  @override
  String get importFolderAction => 'Importa';
  @override
  String dropRejected(String names) =>
      'Qui si aprono solo file Markdown e cartelle: $names';
  @override
  String importFolderTitle(String name) => 'Importare «$name»?';
  @override
  String importFolderBody(int count) =>
      'I suoi file Markdown ($count) vengono copiati in una nuova cartella '
      'della libreria. La cartella rilasciata resta com’è.';
  @override
  String importFolderDone(String folder) => 'Importata in $folder';
  @override
  String importFolderEmpty(String name) => 'Nessun file Markdown in $name';
  @override
  String get openFileTitle => 'Apri file';
  @override
  String get outsideFileNote =>
      'Fuori da ogni libreria: salvato dov’è, non indicizzato, senza '
      'cronologia, link non seguiti';
  @override
  String get typewriterOn => 'Attiva la modalità macchina da scrivere';
  @override
  String get typewriterOff => 'Disattiva la modalità macchina da scrivere';
  @override
  String get typewriterTitle => 'Modalità macchina da scrivere';
  @override
  String get formatNoteTitle => 'Sistema il Markdown';
  @override
  String get formatNoteDone => 'Nota sistemata.';
  @override
  String get formatNoteAlreadyTidy => 'La nota era già a posto.';
  @override
  String get typewriterSubtitle =>
      'Tieni la riga che stai scrivendo al centro dell’editor';
  @override
  String get zenMode => 'Modalità Zen';
  @override
  String get zenModeEnter => 'Entra in modalità Zen';
  @override
  String get zenModeLeave => 'Esci dalla modalità Zen';
  @override
  String get keySpace => 'Spazio';
  @override
  String get keyEnter => 'Invio';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Backspace';
  @override
  String get keyDelete => 'Canc';
  @override
  String get keyArrowUp => 'Su';
  @override
  String get keyArrowDown => 'Giù';
  @override
  String get keyArrowLeft => 'Sinistra';
  @override
  String get keyArrowRight => 'Destra';
  @override
  String get keyHome => 'Home';
  @override
  String get keyEnd => 'Fine';
  @override
  String get keyPageUp => 'Pag su';
  @override
  String get keyPageDown => 'Pag giù';
  @override
  String get keyInsert => 'Ins';
  @override
  String get shortcutNone => 'Nessuna scorciatoia';
  @override
  String get shortcutRestoreDefaults => 'Ripristina predefinite';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Rimettere tutte le scorciatoie come le fornisce Niman?';
  @override
  String get shortcutRevert => 'Torna alla predefinita';
  @override
  String get shortcutClear => 'Rimuovi la scorciatoia';
  @override
  String get shortcutCapturePrompt =>
      'Premi i tasti. Anche Esc e Tab vengono presi: si esce con Annulla.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Aggiungi Ctrl, Alt o Meta: un tasto da solo serve per scrivere.';
  @override
  String get shortcutMove => 'Spostala';
  @override
  String get shortcutUseAnyway => 'Usa comunque';
  @override
  String get shortcutUndo => 'Annulla';
  @override
  String get shortcutRedo => 'Ripeti';
  @override
  String get shortcutChange => 'Cambia la scorciatoia';
  @override
  String shortcutCaptureTitle(String command) => 'Tasti per $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys è già di $other. Spostarla qui? $other resterà senza scorciatoia.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys è anche $what nei campi di testo e nell’editor. Lì la prenderà '
      'il tuo comando.';
  @override
  String get openFileMissing => 'Il file di questa nota non è sul disco';
  @override
  String get openFileFailed => 'Impossibile aprire questa nota fuori da Niman';

  @override
  String get movedToTrash => 'Spostato nel cestino';
  @override
  String get deletedMessage => 'Eliminato';
  @override
  String deleteToTrashConfirm(String name) => '$name verrà spostato in .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name verrà eliminato definitivamente';
  @override
  String get chooseDestination => 'Scegli la destinazione';
  @override
  String get libraryRoot => 'Radice della libreria';
  @override
  String moveTitle(String name) => 'Sposta $name';
  @override
  String headingLevelLabel(int level) => 'Titolo $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Nessuna nota rapida. Scegline una esistente o creane una nuova: '
      'la nota rapida si apre qui.';
  @override
  String get quickNoteChooseAction => 'Scegli una nota…';
  @override
  String get quickNoteCreateAction => 'Crea una nuova nota…';
  @override
  String get quickNoteNewTitle => 'Nuova nota rapida';
  @override
  String get quickNotePickerTitle => 'Scegli la nota rapida';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nuova cartella';
  @override
  String get folderPickerEmpty => 'Nessuna cartella';
  @override
  String get listFolderTitle => 'Cartella delle liste';
  @override
  String get attachmentsFolderTitle => 'Cartella degli allegati';

  // Trash (M1).
  @override
  String get trashEmpty => 'Il cestino è vuoto';
  @override
  String get trashEmptyAction => 'Svuota il cestino';
  @override
  String get trashEmptyConfirm =>
      'Elimina definitivamente tutto ciò che è nel cestino, compreso '
      'ciò che non ci ha messo Niman.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name verrà eliminato definitivamente, senza ripristino';
  @override
  String get trashDeletePermanently => 'Elimina definitivamente';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Apri una cartella di note Markdown come libreria';
  @override
  String get openLibraryExisting => 'Apri esistente';
  @override
  String get openLibraryCreate => 'Creane una nuova';
  @override
  String get openLibraryCreateTitle => 'Crea una nuova libreria';
  @override
  String get openLibraryFolderName => 'Nome della cartella';
  @override
  String get openLibraryChooseFolder => 'Scegli la cartella della libreria';
  @override
  String get openLibraryChooseParent =>
      'Scegli la cartella in cui creare la libreria';
  @override
  String get openLibraryUnsupported =>
      'Quella cartella non è supportata. Scegline una nella memoria del '
      'dispositivo.';
  @override
  String indexingCount(int done, int total) => '$done di $total note';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Le tue librerie';
  @override
  String get libraryUnreachable => 'Non raggiungibile';
  @override
  String get libraryOpenedToday => 'Aperta oggi';
  @override
  String get libraryOpenedYesterday => 'Aperta ieri';
  @override
  String libraryOpenedDaysAgo(int days) => 'Aperta $days giorni fa';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Aperta il $d/$m/${when.year}';
  }

  @override
  String get libraryOpenNow => 'Aperta ora';
  @override
  String get switchLibraryTitle => 'Cambia libreria';
  @override
  String get libraryForget => 'Dimentica';
  @override
  String libraryForgetTitle(String name) => 'Dimenticare «$name»?';
  @override
  String get libraryForgetExplained =>
      'Sparisce da questo elenco. La cartella, le note e le impostazioni '
      'della libreria restano dove sono, e riaprendola torna '
      'nell’elenco.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Concedi l’accesso ai file';
  @override
  String get storageAccessNeeded =>
      'Senza l’accesso a tutti i file Niman non può leggere le tue '
      'note. Concedilo per aprire una libreria.';
  @override
  String get storageAccessExplained =>
      'Niman legge le note come file normali, quindi Android deve '
      'concedergli l’accesso a tutti i file. Non viene caricato '
      'niente, e viene letta solo la cartella che scegli.';
  @override
  String folderAccessDenied(Object error) =>
      'Il sistema non ha dato accesso alla cartella: $error';
  @override
  String folderPickFailed(Object error) =>
      'Impossibile scegliere una cartella: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Impostazioni';
  @override
  String get libraryPathTitle => 'Percorso della libreria';
  @override
  String get reindexTitle => 'Reindicizza ora';
  @override
  String get reindexDone => 'Reindicizzazione completata';
  @override
  String get closeLibraryTitle => 'Chiudi la libreria';
  @override
  String get exportLogTitle => 'Esporta il log di debug';
  @override
  String get exportLogSubtitle =>
      'Salva gli eventi registrati in un file a tua scelta';
  @override
  String get exportLogEmpty => 'Il buffer del log di debug è vuoto';
  @override
  String get quickNoteUnset => 'Non impostata';
  @override
  String exportLogDone(Object target) => 'Log di debug esportato in $target';
  @override
  String exportLogFailed(Object error) => 'Esportazione non riuscita: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) => 'Nessuna parola intera "$term" trovata';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Sostituite $occurrences occorrenze di "$term" in $notes note';
  @override
  String replaceSkipped(int skipped) => ' ($skipped note aperte saltate)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nessuna parola intera esatta "$term" '
      '${only == null ? 'trovata' : 'trovata in $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Informazioni';
  @override
  String get versionTitle => 'Versione';
  @override
  String get changelogTitle => 'Registro delle modifiche';
  @override
  String get changelogEmpty => 'Nessuna voce del registro disponibile';
  @override
  String changelogWhatsNew(String version) => 'Novità nella versione $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Cronologia';
  @override
  String get noteMenuTooltip => 'Azioni sulla nota';
  @override
  String get historyCurrentVersion => 'Versione attuale';
  @override
  String get historyCurrentSubtitle => 'La nota com’è adesso';
  @override
  String get historyToday => 'Oggi';
  @override
  String get historyYesterday => 'Ieri';
  @override
  String get historyReasonSession => 'prima delle modifiche';
  @override
  String get historyReasonInterval => 'durante la modifica';
  @override
  String get historyReasonRestore => 'prima del ripristino';
  @override
  String get historyReasonSync => 'prima del sync';
  @override
  String get historyReasonReplace => 'prima di sostituisci';
  @override
  String get historyReasonUnknown => 'recuperata';
  @override
  String get historySyncBase => 'base sync';
  @override
  String get historyEmpty =>
      'Ancora nessuna versione. Niman ne conserva una quando inizi a '
      'modificare la nota, poi al massimo una ogni pochi minuti mentre scrivi.';
  @override
  String historyKept(int kept, int limit) => '$kept versioni su $limit';
  @override
  String get historyBaseKept => 'La base sync resta anche oltre il limite.';
  @override
  String get historyOff =>
      'La cronologia è disattivata per questa libreria '
      '(Impostazioni, Libreria).';
  @override
  String get historyLoadFailed => 'Impossibile leggere la cronologia';
  @override
  String get historyCompareSubtitle => 'Confrontata con la versione attuale';
  @override
  String get historyTabChanges => 'Differenze';
  @override
  String get historyTabVersion => 'Versione';
  @override
  String get historyNoChanges => 'Stesso testo della versione attuale.';
  @override
  String get historyRestoreAction => 'Ripristina questa versione';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Ripristinare la versione di $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Il testo attuale viene prima salvato nella cronologia, quindi puoi '
      'sempre tornare indietro.';
  @override
  String get historyRestoreConfirm => 'Ripristina';
  @override
  String historyRestored(String when) => 'Ripristinata la versione di $when';
  @override
  String get historyRestoreFailed => 'Impossibile ripristinare la versione';
  @override
  String get actionUndo => 'Annulla';
  @override
  String diffLineRange(int start, int end) => 'Righe $start–$end';
  @override
  String diffLineSingle(int line) => 'Riga $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 riga invariata' : '$count righe invariate';
  @override
  String get historyTakeHunk => 'Ripristina qui';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Ripristina 1 modifica' : 'Ripristina $count modifiche';
  @override
  String get historyRestoreSelectedConfirmBody =>
      "Le modifiche scelte tornano al testo di questa versione. La nota com'è "
      'ora viene prima conservata come versione, così puoi annullare.';
  @override
  String get historyNoteChangedReloaded =>
      'La nota è cambiata mentre eri qui: il confronto è stato aggiornato.';
  @override
  String get historyVersionsTitle => 'Versioni da conservare';
  @override
  String get historyVersionsSubtitle => 'Per ogni nota, in .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Nessuna' : '$count';
  @override
  String get historyIntervalTitle => 'Nuova versione al massimo ogni';
  @override
  String get historyIntervalSubtitle =>
      'Mentre scrivi; iniziare a modificare una nota ne conserva sempre una';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Trascrizione';
  @override
  String get transcriptionModelTitle => 'Modello';
  @override
  String get transcriptionModelNone => 'Nessuno';
  @override
  String get transcriptionLanguageTitle => 'Lingua';
  @override
  String get transcriptionLanguageSubtitle =>
      'La lingua parlata nelle registrazioni. Indicarla è più preciso che '
      'rilevarla.';
  @override
  String transcriptionLanguageApp(String language) => "Come l'app ($language)";
  @override
  String get transcriptionLanguageDetect => 'Rileva automaticamente';
  @override
  String get transcriptionModelsTitle => 'Modelli di trascrizione';
  @override
  String transcriptionModelsUsed(String size) => '$size usati';
  @override
  String get transcriptionModelsInstalled => 'Scaricati';
  @override
  String get transcriptionModelsDownloading => 'In download';
  @override
  String get transcriptionModelsAvailable => 'Disponibili';
  @override
  String get transcriptionModelsFooter =>
      "I modelli restano nella memoria dell'app su questo dispositivo. Non "
      'vengono copiati nella libreria né sincronizzati.';
  @override
  String get transcriptionModelDefault => 'Predefinito';
  @override
  String get transcriptionModelSlow => 'Lento';
  @override
  String get transcriptionModelHintTiny => 'Il più veloce, il meno preciso';
  @override
  String get transcriptionModelHintBase =>
      'Buon equilibrio tra velocità e precisione';
  @override
  String get transcriptionModelHintSmall => 'Più preciso, circa 3× più lento';
  @override
  String get transcriptionModelHintMedium =>
      'Molto preciso, lento sul telefono';
  @override
  String get transcriptionModelHintLarge =>
      'Il più preciso, richiede molta memoria';
  @override
  String get transcriptionModelDownload => 'Scarica';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Eliminare il modello $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Libera $size. Potrai scaricare di nuovo il modello in seguito.';
  @override
  String get transcriptionModelFailed =>
      'Download non riuscito. Controlla la connessione e riprova.';
  @override
  String get actionRetry => 'Riprova';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Connessione persa, nuovo tentativo…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'In pausa a $progress';
  @override
  String get actionResume => 'Riprendi';
  @override
  String get audioTranscribe => 'Trascrivi';
  @override
  String get audioTranscribeUnsupported =>
      'Solo registrazioni WAV su questo dispositivo';
  @override
  String get transcriptionQueued => 'In coda';
  @override
  String get transcriptionPreparing => "Preparo l'audio…";
  @override
  String transcriptionRunning(int percent) => 'Trascrizione… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Scarico $model · $percent%';
  @override
  String get transcriptionSaved => 'Trascrizione aggiunta alla descrizione';
  @override
  String get transcriptionNoSpeech =>
      'Nessun parlato riconosciuto in questa registrazione';
  @override
  String get transcriptionFailed => 'Trascrizione non riuscita';
  @override
  String get transcriptionPickModelTitle => 'Scegli un modello';
  @override
  String get transcriptionPickModelBody =>
      'La trascrizione avviene su questo dispositivo e la registrazione non '
      'viene mai inviata. Il modello si scarica una volta sola.';
  @override
  String get transcriptionPickModelAction => 'Scarica e trascrivi';
  @override
  String get transcriptionModelRecommended => 'Consigliato';
  @override
  String get transcriptionExistingTitle =>
      'La registrazione ha già una descrizione';
  @override
  String get transcriptionExistingBody =>
      'Sostituirla con la trascrizione o aggiungere la trascrizione in fondo?';
  @override
  String get transcriptionAppend => 'Aggiungi in fondo';
  @override
  String get transcriptionReplace => 'Sostituisci';
  @override
  String get settingsSectionSync => 'Sincronizzazione';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Non configurata per questa libreria';
  @override
  String get syncNeverSynced => 'Mai sincronizzata';
  @override
  String syncLastSynced(String when) => 'Sincronizzata $when';
  @override
  String get syncRunning => 'Sincronizzazione in corso…';
  @override
  String syncScreenSubtitle(String library) => 'Libreria $library';
  @override
  String get syncUrlLabel => 'Indirizzo della cartella';
  @override
  String get syncUrlRequired => 'Inserisci l’indirizzo del server';
  @override
  String get syncUrlHint =>
      "La cartella deve esistere. Copia l'indirizzo come lo "
      'mostra il server.';
  @override
  String get syncHttpWarning =>
      'Connessione non cifrata: va bene in VPN o in rete locale.';
  @override
  String get syncUserLabel => 'Utente';
  @override
  String get syncUserHint => 'Vuoto se il server non chiede credenziali.';
  @override
  String get syncPasswordLabel => 'Password';
  @override
  String get syncPasswordHint =>
      'Salvata nel portachiavi del dispositivo, mai nei file '
      'della libreria.';
  @override
  String get syncPasswordKeepHint => 'Lascia vuoto per tenere quella salvata.';
  @override
  String get syncShowPassword => 'Mostra password';
  @override
  String get syncHidePassword => 'Nascondi password';
  @override
  String get syncTestAction => 'Prova connessione';
  @override
  String get syncTesting => 'Prova in corso…';
  @override
  String get syncRetargetWarning =>
      'Con un altro indirizzo o utente il prossimo sync riparte '
      'come primo sync.';
  @override
  String get syncTestOk => 'Connessione riuscita';
  @override
  String get syncModeFull => 'Modalità completa';
  @override
  String get syncModeCompatible => 'Modalità compatibile';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lettura, scrittura e cancellazione';
  @override
  String get syncCapEtags => 'Impronte dei file (ETag)';
  @override
  String get syncCapNoEtags => 'Nessuna impronta dei file (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Confronto dimensione e data; in caso di dubbio riscarico';
  @override
  String get syncCapGuarded => 'Scritture protette';
  @override
  String get syncCapUnguarded => 'Scritture non protette';
  @override
  String get syncCapUnguardedDetail =>
      'Controllo il file sul server subito prima di scrivere';
  @override
  String get syncCapMove => 'Rinomina senza ricaricare';
  @override
  String get syncCapNoMove => 'Nessuna rinomina sul server';
  @override
  String get syncCapNoMoveDetail =>
      'Una rinomina diventa eliminazione e nuovo caricamento';
  @override
  String get syncCompatibleNote =>
      'In modalità compatibile il sync funziona uguale, con '
      'qualche richiesta in più.';
  @override
  String get syncTestInvalidUrl => 'Indirizzo non valido';
  @override
  String get syncTestInvalidUrlHint =>
      'Scrivi un indirizzo http:// o https:// senza utente e '
      'password dentro.';
  @override
  String get syncTestOffline => 'Server non raggiungibile';
  @override
  String get syncTestOfflineHint =>
      'La VPN è attiva? Un indirizzo 10.x o 192.168.x si '
      'raggiunge solo dalla stessa rete.';
  @override
  String get syncTestAuth => 'Utente o password rifiutati';
  @override
  String get syncTestAuthHint => 'Controllali e prova di nuovo.';
  @override
  String get syncTestNotFound => 'La cartella non esiste';
  @override
  String get syncTestNotFoundHint =>
      "Creala sul server o correggi l'indirizzo.";
  @override
  String get syncTestUnsupported => 'Non è una cartella WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'Il server risponde, ma non come WebDAV.';
  @override
  String get syncTestFailed => 'Prova non riuscita';
  @override
  String get syncNowAction => 'Sincronizza ora';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Indirizzo, utente e password';
  @override
  String get syncRetestTitle => 'Prova di nuovo il server';
  @override
  String syncProbedAgo(String when) => 'Ultima prova $when';
  @override
  String get syncDisconnectTitle => 'Scollega questa libreria';
  @override
  String get syncDisconnectSubtitle => 'I file restano qui e sul server';
  @override
  String get syncDisconnectConfirmTitle => 'Scollegare la sincronizzazione?';
  @override
  String get syncDisconnectConfirmBody =>
      'La libreria smette di sincronizzarsi su questo '
      'dispositivo. Nessun file viene eliminato, né qui né sul '
      'server. Se la ricolleghi, il primo sync riparte da capo.';
  @override
  String get syncDisconnectConfirm => 'Scollega';
  @override
  String get syncFirstTitle => 'Prima sincronizzazione';
  @override
  String get syncFirstIntro =>
      'Ho confrontato la libreria con la cartella sul server:';
  @override
  String get syncFirstUpload => 'Da caricare';
  @override
  String get syncFirstDownload => 'Da scaricare';
  @override
  String get syncFirstBoth => 'Su entrambi';
  @override
  String get syncFirstBothHint =>
      'Uguali: nessun trasferimento. Diversi: da risolvere';
  @override
  String get syncFirstNoDelete =>
      'Il primo sync non elimina nulla, né qui né sul server.';
  @override
  String get syncStartAction => 'Avvia';
  @override
  String syncMassTrashTitle(int count) => 'Spostare $count file nel cestino?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Sul server mancano $count dei $total file sincronizzati. '
      'Di solito vuol dire indirizzo sbagliato, disco del NAS '
      'non montato o cartella svuotata per errore.';
  @override
  String get syncMassTrashHint =>
      'Se li hai eliminati davvero da un altro dispositivo, '
      'conferma: qui finiscono nel cestino.';
  @override
  String get syncMassTrashConfirm => 'Sposta nel cestino';
  @override
  String syncMassDeleteTitle(int count) => 'Eliminare $count file dal server?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Qui mancano $count dei $total file sincronizzati. Se non '
      'li hai eliminati tu, annulla e controlla la cartella '
      'della libreria.';
  @override
  String get syncMassDeleteConfirm => 'Elimina dal server';
  @override
  String get syncTooltip => 'Sincronizza';
  @override
  String get syncStageConnecting => 'Connessione al server…';
  @override
  String get syncStageComparing => 'Confronto con il server…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sincronizzazione · $done di $total';
  @override
  String get syncStatusWarnings => 'Sincronizzata con avvisi';
  @override
  String syncConflictsHeader(int count) =>
      'Modificati qui e sul server · $count';
  @override
  String get syncConflictHint => 'Nessuna delle due versioni è stata toccata';
  @override
  String get syncResolveAction => 'Risolvi';
  @override
  String syncFailuresHeader(int count) => 'Non riusciti · $count';
  @override
  String get syncFailuresHint => 'Riprovati al prossimo sync';
  @override
  String get syncAbortAuth => 'Password rifiutata dal server';
  @override
  String get syncAbortMissingPassword => 'Nessuna password salvata';
  @override
  String get syncAbortOffline => 'Server non raggiungibile';
  @override
  String get syncAbortRemoteMissing => "La cartella sul server non c'è più";
  @override
  String get syncAbortUnsupported => 'Il server non risponde più come WebDAV';
  @override
  String get syncAbortFailed => 'Sincronizzazione non riuscita';
  @override
  String get syncAbortNotConfirmed => 'Sincronizzazione annullata';
  @override
  String get syncAbortNothingTouched =>
      'Nessun file è stato toccato. Le modifiche restano qui '
      'fino al prossimo sync riuscito.';
  @override
  String syncLastSuccess(String when) => 'Ultimo sync riuscito $when';
  @override
  String get syncNoSuccessYet => 'Nessun sync riuscito finora';
  @override
  String get syncUpdatePasswordAction => 'Aggiorna password';
  @override
  String get syncRetryAction => 'Riprova';
  @override
  String get syncOpenSettingsAction => 'Impostazioni';
  @override
  String get syncCloseAction => 'Chiudi';
  @override
  String get syncDoneSnack => 'Sincronizzata';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sincronizzata · 1 file eliminato altrove è nel cestino'
      : 'Sincronizzata · $count file eliminati altrove sono nel '
            'cestino';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sincronizzata · 1 conflitto da risolvere'
      : 'Sincronizzata · $count conflitti da risolvere';
  @override
  String get syncShowAction => 'Mostra';
  @override
  String get syncConflictTitle => 'Risolvi conflitto';
  @override
  String get syncConflictLegend =>
      'Le righe con − sono del server, quelle con + di questo '
      'dispositivo.';
  @override
  String get syncConflictBinary =>
      'Non è un file di testo: scegli quale copia tenere.';
  @override
  String get syncConflictKeepNote =>
      'La copia che non tieni resta nella cronologia della nota.';
  @override
  String get syncKeepLocal => 'Tieni questo dispositivo';
  @override
  String get syncKeepRemote => 'Tieni la versione del server';
  @override
  String get syncConflictIdentical => 'Le due versioni sono identiche';
  @override
  String get syncConflictLoadFailed => 'Non riesco a leggere le due versioni';
  @override
  String get syncResolveFailed => 'Risoluzione non riuscita';
  @override
  String get syncResolved => 'Conflitto risolto';
  @override
  String get syncSectionWhen => 'Quando sincronizzare';
  @override
  String get syncAutoTitle => 'Automaticamente';
  @override
  String get syncAutoSubtitle =>
      "Dopo le modifiche, all'apertura e a intervalli";
  @override
  String get syncIntervalTitle => 'Controlla il server ogni';
  @override
  String get syncIntervalSubtitle => "Solo con l'app aperta";
  @override
  String get syncIntervalDialogBody =>
      "Per vedere le modifiche fatte su altri dispositivi mentre l'app è "
      "aperta. Con «Mai», solo dopo le modifiche e all'apertura.";
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minuto' : '$count minuti';
  @override
  String get syncIntervalNever => 'Mai';
  @override
  String get syncWifiOnlyTitle => 'Solo con Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Con i dati mobili sincronizza solo a mano';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 modifica in attesa' : '$count modifiche in attesa';
  @override
  String syncRetryIn(String wait) => 'nuovo tentativo tra $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'In attesa del Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'In attesa della connessione';
  @override
  String get syncMobileDataHint =>
      '«Sincronizza ora» usa comunque i dati mobili.';
  @override
  String get syncQueueKeptHint =>
      "Le modifiche restano qui, anche se chiudi l'app, e ripartono da sole "
      'quando il server risponde.';
  @override
  String get syncAutoPaused => 'Sync automatico in pausa';
  @override
  String get syncPausedAuthHint =>
      'Riprende quando aggiorni la password o sincronizzi a mano.';
  @override
  String get syncPausedServerHint =>
      "Riprende quando correggi l'indirizzo o sincronizzi a mano.";
  @override
  String get syncPausedConfirmHint =>
      '«Sincronizza ora» mostra cosa verrebbe eliminato e chiede conferma.';
  @override
  String get syncNeedsConfirmation => 'Serve una conferma';
  @override
  String get syncMergeIntro =>
      'Le modifiche che non si sovrappongono sono già unite; scegli cosa '
      'tenere dove si sovrappongono.';
  @override
  String get syncMergeClean =>
      "Le due versioni si uniscono da sole: non c'è nulla che si sovrappone.";
  @override
  String get syncMergeNoBase =>
      "Non c'è una versione comune su cui unire, quindi si sceglie il file "
      'intero.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Sovrapposizione $index di $total';
  @override
  String get syncMergeFromLocal => 'Da questo dispositivo';
  @override
  String get syncMergeFromRemote => 'Dal server';
  @override
  String get syncMergeRemovedLines => 'Righe rimosse';
  @override
  String get syncMergeKeepLocal => 'Le mie';
  @override
  String get syncMergeKeepRemote => 'Del server';
  @override
  String get syncMergeKeepBoth => 'Entrambe';
  @override
  String get syncMergeSave => "Salva l'unione";
  @override
  String get syncMergeKeepWhole => 'Oppure tieni una copia intera';
}
