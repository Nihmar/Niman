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
  String get keyboardOnOpenTitle => 'Tastiera all’apertura';
  @override
  String get keyboardOnOpenSubtitle =>
      'Mostra la tastiera appena si apre una nota (off = al primo tocco)';
  @override
  String get editorKindSource => 'Sorgente Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rapida';
  @override
  String get shortcutNewTodo => 'Nuova attività';
  @override
  String get shortcutNewNote => 'Nuova nota';
  @override
  String get shortcutNewList => 'Nuova lista';
  @override
  String get shortcutToggleSidebar => 'Mostra o nascondi l’albero dei file';
  @override
  String get shortcutEditorSection => 'Nell’editor';
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
  String get newFolderTitle => 'Nuova cartella';
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
}
