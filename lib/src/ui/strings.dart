/// The single file for UI strings — every user-visible label lives here,
/// in both languages the app speaks.
library;

import 'package:copist/src/core/language.dart';

/// All user-visible app strings, English and Italian side by side.
///
/// One file for every label, so a translation (and any renaming) touches
/// exactly this file. Each entry is a getter rather than a constant
/// because the answer depends on the active language; call sites never
/// pass a locale and never need a `BuildContext`.
///
/// The constants need no per-member docs: their values ARE their
/// documentation.
// ignore_for_file: public_member_api_docs
final class AppStrings {
  const new _();

  /// The English or the Italian text, per [AppLanguages].
  static String _t(String en, String it) => AppLanguages.isItalian ? it : en;

  // Settings: editor toggles.
  static String get trashTitle => _t('Trash', 'Cestino');
  static String get trashSubtitle => _t(
    'Deletions move to .trash/ (off = hard delete)',
    'Gli elementi eliminati vanno in .trash/ (off = eliminazione definitiva)',
  );
  static String get debugLogsTitle => _t('Debug logs', 'Log di debug');
  static String get debugLogsSubtitle => _t(
    'Record app events in an in-memory buffer',
    'Registra gli eventi dell’app in un buffer in memoria',
  );
  static String get lineNumbersTitle => _t('Line numbers', 'Numeri di riga');
  static String get lineNumbersSubtitle => _t(
    'Show the row-number column in the note editor',
    'Mostra la colonna dei numeri di riga nell’editor',
  );
  static String get keyboardOnOpenTitle =>
      _t('Keyboard on open', 'Tastiera all’apertura');
  static String get keyboardOnOpenSubtitle => _t(
    'Show the keyboard as soon as a note opens (off = on first tap)',
    'Mostra la tastiera appena si apre una nota (off = al primo tocco)',
  );

  // Settings: the section headings the list is grouped under.
  static String get settingsSectionAppearance => _t('Appearance', 'Aspetto');
  static String get settingsSectionEditor => _t('Editor', 'Editor');
  static String get settingsSectionLibrary => _t('Library', 'Libreria');
  static String get settingsSectionReminders => _t('Reminders', 'Promemoria');
  static String get settingsSectionDiagnostics =>
      _t('Diagnostics', 'Diagnostica');

  /// The indent width as a row's value, e.g. "4 spaces".
  static String indentWidthValue(int spaces) =>
      _t('$spaces spaces', '$spaces spazi');

  /// The editor's share of a split, as a row's value, e.g. "50%".
  static String splitRatioValue(double ratio) => '${(ratio * 100).round()}%';

  // Settings: preview mode.
  static String get previewModeTitle =>
      _t('Preview mode', 'Modalità anteprima');
  static String get previewModeSubtitle => _t(
    'How the preview sits next to the editor (auto = by width)',
    'Come sta l’anteprima accanto all’editor (auto = secondo la larghezza)',
  );
  static String get previewModeAuto => _t('Auto', 'Auto');
  static String get previewModeSplit => _t('Side by side', 'Affiancata');
  static String get previewModeSwitch => _t('Full screen', 'A tutto schermo');
  static String get splitRatioTitle => _t('Split width', 'Larghezza divisione');
  static String get splitRatioSubtitle => _t(
    'The editor’s share when the preview is side by side',
    'La quota dell’editor quando l’anteprima è affiancata',
  );

  // Settings: editor formatting.
  static String get linkTypeTitle => _t('Link format', 'Formato dei link');
  static String get linkTypeSubtitle => _t(
    'What the link button in the editor inserts',
    'Cosa inserisce il pulsante link dell’editor',
  );
  static String get linkTypeWikilink => _t('Wikilink', 'Wikilink');
  static String get linkTypeMarkdown => _t('Markdown', 'Markdown');
  static String get indentWidthTitle =>
      _t('Indent width', 'Ampiezza del rientro');
  static String get indentWidthSubtitle => _t(
    'Spaces added per indent level in the editor',
    'Spazi aggiunti per ogni livello di rientro nell’editor',
  );

  // Settings: language (T-L10N-04).
  static String get languageTitle => _t('Language', 'Lingua');
  static String get languageSubtitle =>
      _t('The language of the app’s own text', 'La lingua dei testi dell’app');
  static String get languageSystem => _t('System', 'Sistema');
  // Language names stay in their own language: someone who landed in the
  // wrong one has to be able to find their way back.
  static String get languageEnglish => 'English';
  static String get languageItalian => 'Italiano';

  // List note kind (T-TK-02).
  static String get listAddHint => _t('Add an item', 'Aggiungi un elemento');
  static String get listAddTooltip => _t('Add an item', 'Aggiungi un elemento');
  static String get listEmpty => _t('No items yet', 'Nessun elemento per ora');
  static String get listDragHandleLabel =>
      _t('Reorder item', 'Riordina l’elemento');

  // Launcher quick actions (T-SC-02), in the order they are published.
  static String get shortcutQuickNote => _t('Quick note', 'Nota rapida');
  static String get shortcutNewTodo => _t('New todo', 'Nuova attività');
  static String get shortcutNewNote => _t('New note', 'Nuova nota');
  static String get shortcutNewList => _t('New list', 'Nuova lista');

  // Editor status bar.
  static String get outlineTooltip => _t('Outline', 'Struttura');
  static String get outlineNoHeadings => _t('No headings', 'Nessun titolo');
  static String get outlineNoTitle => _t('(no title)', '(senza titolo)');

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  static String get toolbarBold => _t('Bold', 'Grassetto');
  static String get toolbarItalic => _t('Italic', 'Corsivo');
  static String get toolbarStrikethrough => _t('Strikethrough', 'Barrato');
  static String get toolbarSuperscript => _t('Superscript', 'Apice');
  static String get toolbarUnderline => _t('Underline', 'Sottolineato');
  static String get toolbarLink => _t('Link', 'Link');
  static String get toolbarCode => _t('Code block', 'Blocco di codice');
  static String get toolbarImage => _t('Insert image', 'Inserisci immagine');
  static String get toolbarHeading => _t('Heading', 'Titolo');
  static String get toolbarList => _t('List', 'Elenco');
  static String get toolbarOrderedList =>
      _t('Numbered list', 'Elenco numerato');
  static String get toolbarQuote => _t('Quote', 'Citazione');
  static String get toolbarIndent => _t('Indent', 'Aumenta rientro');
  static String get toolbarOutdent => _t('Outdent', 'Riduci rientro');
  static String get headingDialogTitle =>
      _t('Heading level', 'Livello del titolo');

  // Toolbar settings (T-TB-05).
  static String get toolbarSettingsTitle =>
      _t('Editor toolbar', 'Barra dell’editor');
  static String get toolbarSettingsSubtitle => _t(
    'Order the buttons and hide the ones you do not use',
    'Ordina i pulsanti e nascondi quelli che non usi',
  );
  static String get toolbarSettingsHint => _t(
    'Drag to reorder; the eye shows or hides a button.',
    'Trascina per riordinare; l’occhio mostra o nasconde un pulsante.',
  );
  static String get toolbarShowButton => _t('Show', 'Mostra');
  static String get toolbarHideButton => _t('Hide', 'Nascondi');
  static String get toolbarResetOrder =>
      _t('Restore defaults', 'Ripristina predefiniti');

  // Preview switch (phone mode).
  static String get showPreviewTooltip =>
      _t('Show preview', 'Mostra anteprima');
  static String get showEditorTooltip => _t('Show editor', 'Mostra editor');
  static String get enterFullScreenTooltip =>
      _t('Full screen', 'Schermo intero');
  static String get exitFullScreenTooltip =>
      _t('Exit full screen', 'Esci da schermo intero');

  // Raw-HTML table fallback.
  static String get htmlTableFallback =>
      _t('(raw HTML table)', '(tabella HTML grezza)');

  // Search (T-M3-05).
  static String get searchHint => _t('Search notes', 'Cerca nelle note');
  static String get searchModeWords => _t('Words', 'Parole');
  static String get searchModeContains => _t('Contains', 'Contiene');
  static String get searchEmptyHint =>
      _t('Type to search the library', 'Scrivi per cercare nella libreria');
  static String get searchTooShortHint =>
      _t('Type at least 2 characters', 'Scrivi almeno 2 caratteri');
  static String get searchNoMatches =>
      _t('No matches', 'Nessuna corrispondenza');
  static String get searchLoadMore => _t('Show more', 'Mostra altri');

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  static String get replaceTooltip => _t('Replace…', 'Sostituisci…');
  static String get replaceInNoteAction =>
      _t('Replace in this note…', 'Sostituisci in questa nota…');
  static String get replaceInThisNote =>
      _t('Replace in this note', 'Sostituisci in questa nota');
  static String get replaceWithLabel => _t('Replace with', 'Sostituisci con');
  static String get replaceCaseSensitive =>
      _t('Case-sensitive', 'Distingui maiuscole');
  static String get replaceWholeWordsHint => _t(
    'only exact whole-word matches are replaced',
    'si sostituiscono solo le parole intere esatte',
  );
  static String get replaceConfirm => _t('Replace', 'Sostituisci');
  static String get replaceCancel => _t('Close', 'Chiudi');
  static String get replaceUnavailable => _t(
    'Replace is unavailable right now',
    'La sostituzione non è disponibile ora',
  );

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + CopistFindPanel).
  static String get findInNoteTooltip => _t('Find in note', 'Trova nella nota');
  static String get editorFindHint => _t('Find', 'Trova');
  static String get editorReplaceHint => _t('Replace', 'Sostituisci');
  static String get editorFindCaseTooltip =>
      _t('Match case', 'Distingui maiuscole');
  static String get editorFindPreviousTooltip =>
      _t('Previous match', 'Corrispondenza precedente');
  static String get editorFindNextTooltip =>
      _t('Next match', 'Corrispondenza successiva');
  static String get editorFindCloseTooltip =>
      _t('Close find', 'Chiudi la ricerca');
  static String get editorFindReplaceModeTooltip =>
      _t('Replace mode', 'Modalità sostituzione');
  static String get editorReplaceOneTooltip =>
      _t('Replace this match', 'Sostituisci questa');
  static String get editorReplaceAllTooltip =>
      _t('Replace all matches', 'Sostituisci tutte');

  // Tags (T-M3-06).
  static String get openTagsTooltip => _t('Tags', 'Tag');
  static String get tagsTitle => _t('Tags', 'Tag');
  static String get tagsEmpty => _t(
    'No tags yet — add a #tag or frontmatter tags',
    'Nessun tag per ora — aggiungi un #tag o i tag nel frontmatter',
  );
  static String get tagsBackTooltip =>
      _t('Back to search', 'Torna alla ricerca');
  static String get tagsNotesEmpty =>
      _t('No notes with this tag', 'Nessuna nota con questo tag');

  // Link navigation (T-M3-07).
  static String get unresolvedLinkTitle =>
      _t('Link not found', 'Link non trovato');
  static String get headingNotFoundTitle =>
      _t('Heading not found', 'Titolo non trovato');
  static String get ambiguousLinkTitle =>
      _t('Several notes match', 'Più note corrispondono');
  static String get openLinkFailed =>
      _t('Could not open link', 'Impossibile aprire il link');
  static String get chooseNote => _t('Choose a note', 'Scegli una nota');

  // Task lists (T-TD-04).
  static String get todoOpen => _t('Open', 'Da fare');
  static String get todoDone => _t('Done', 'Fatte');

  // Filter row + sheet (plan/todo-mockup.md T-TDM-03).
  static String get todoAllDates => _t('All dates', 'Tutte le date');
  static String get todoFilter => _t('Filter', 'Filtra');
  static String get todoNoTokens =>
      _t('No tokens in this list', 'Nessun token in questa lista');

  // The "N open" / "N done" count (T-TDM-03).
  static String get todoCountOpen => _t('open', 'da fare');
  static String get todoCountDone => _t('done', 'fatte');
  static String get todoEmptyOpen =>
      _t('No open tasks yet', 'Nessuna attività da fare');
  static String get todoEmptyDone =>
      _t('Nothing completed yet', 'Niente di completato per ora');
  static String get todoEmptyFiltered =>
      _t('No tasks match', 'Nessuna attività corrisponde');
  static String get todoTitle => _t('Todo', 'Attività');
  static String get todoAddTooltip => _t('Add task', 'Aggiungi attività');

  // The todo.txt format help (T-TD-08).
  static String get todoHelpTitle =>
      _t('The todo.txt format', 'Il formato todo.txt');
  static String get todoHelpTooltip => _t('Format help', 'Guida al formato');
  static String get todoHelpIntro => _t(
    'Your tasks are one plain text file, one task per line. Copist '
        'writes the syntax for you, but nothing is hidden: you can edit '
        'the file in any editor and Copist will read it back.',
    'Le tue attività sono un unico file di testo, una per riga. Copist '
        'scrive la sintassi per te, ma non nasconde niente: puoi '
        'modificare il file in qualsiasi editor e Copist lo rilegge.',
  );
  static String get todoHelpFilesTitle => _t('The two files', 'I due file');
  static String get todoHelpFilesBody => _t(
    'Open tasks live in todo.txt at the root of your library. '
        'Completing one moves its line to done.txt, so todo.txt stays '
        'short. If a completed line ends up back in todo.txt, Copist '
        'archives it the next time it reads the files.',
    'Le attività da fare stanno in todo.txt alla radice della libreria. '
        'Completandone una, la riga passa in done.txt, così todo.txt '
        'resta corto. Se una riga completata torna in todo.txt, Copist '
        'la archivia alla lettura successiva.',
  );
  static String get todoHelpLineTitle =>
      _t('Anatomy of a line', 'Anatomia di una riga');
  static String get todoHelpLineBody => _t(
    'Everything before the description is optional and must come in '
        'this order:',
    'Tutto ciò che precede la descrizione è facoltativo e va in '
        'quest’ordine:',
  );
  static String get todoHelpDone => 'x';
  static String get todoHelpDoneBody => _t(
    'Marks the task done. Copist adds it when you tick the checkbox.',
    'Segna l’attività come fatta. Copist la aggiunge quando spunti la '
        'casella.',
  );
  static String get todoHelpPriority => _t('(A) to (Z)', 'da (A) a (Z)');
  static String get todoHelpPriorityBody => _t(
    'Priority. A is the highest. Shown as a badge in the list.',
    'Priorità. A è la più alta. Compare come pastiglia nella lista.',
  );
  static String get todoHelpDates => '2026-09-08 2026-09-01';
  static String get todoHelpDatesBody => _t(
    'Completion date, then creation date. With only one date it is the '
        'creation date, unless the line starts with x.',
    'Data di completamento, poi data di creazione. Con una sola data è '
        'quella di creazione, a meno che la riga inizi con x.',
  );
  static String get todoHelpTokensTitle =>
      _t('Projects, contexts and tags', 'Progetti, contesti e tag');
  static String get todoHelpTokensBody => _t(
    'Anywhere in the description, a word with one of these prefixes '
        'becomes a chip you can filter by. Nothing is predefined: a token '
        'exists as soon as you write it.',
    'In qualsiasi punto della descrizione, una parola con uno di questi '
        'prefissi diventa una pastiglia con cui filtrare. Niente è '
        'predefinito: un token esiste appena lo scrivi.',
  );
  static String get todoHelpProject => '+project';
  static String get todoHelpProjectBody => _t(
    'What the task is part of, for example +kitchen or +thesis.',
    'Di cosa fa parte l’attività, per esempio +cucina o +tesi.',
  );
  static String get todoHelpContext => '@context';
  static String get todoHelpContextBody => _t(
    'Where or how you will do it, for example @home or @calls.',
    'Dove o come la farai, per esempio @casa o @telefonate.',
  );
  static String get todoHelpHashtag => '#tag';
  static String get todoHelpHashtagBody => _t(
    'A free label, for anything the other two do not cover.',
    'Un’etichetta libera, per tutto ciò che gli altri due non coprono.',
  );
  static String get todoHelpTagsTitle =>
      _t('Dates and reminders', 'Date e promemoria');
  static String get todoHelpTagsBody => _t(
    'These are key:value tags. Copist writes them from the task dialog, '
        'and reads them wherever they appear on the line.',
    'Sono tag chiave:valore. Copist li scrive dalla finestra '
        'dell’attività e li legge ovunque compaiano nella riga.',
  );
  static String get todoHelpDue => 'due:2026-09-09';
  static String get todoHelpDueBody => _t(
    'The due date. Drives the coloured badge and the due filters.',
    'La scadenza. Guida la pastiglia colorata e i filtri per data.',
  );
  static String get todoHelpRem => 'rem:2026-09-08T14:30';
  static String get todoHelpRemBody => _t(
    'When to send a notification, in your local time. It fires with '
        'the screen off and the app closed.',
    'Quando inviare una notifica, nella tua ora locale. Arriva anche a '
        'schermo spento e con l’app chiusa.',
  );
  static String get todoHelpOther => 'anything:else';
  static String get todoHelpOtherBody => _t(
    'Kept exactly as written, so tags from other todo.txt apps survive '
        'a round trip. Copist does not act on them, rec: included: a '
        'recurring task is not repeated yet.',
    'Conservati esattamente come scritti, così i tag di altre app '
        'todo.txt sopravvivono al giro. Copist non li interpreta, rec: '
        'compreso: un’attività ricorrente non viene ancora ripetuta.',
  );
  static String get todoHelpEditTitle =>
      _t('Editing outside Copist', 'Modifiche fuori da Copist');
  static String get todoHelpEditBody => _t(
    'A task you have not touched is written back byte for byte, odd '
        'spacing included. Edit a line and Copist rewrites that one line in '
        'its canonical form, leaving the rest of the file alone.',
    'Un’attività che non hai toccato viene riscritta byte per byte, '
        'spaziature strane comprese. Se modifichi una riga, Copist '
        'riscrive solo quella in forma canonica e lascia stare il resto.',
  );
  static String get todoAddTitle => _t('Add task', 'Aggiungi attività');
  static String get todoEditTitle => _t('Edit task', 'Modifica attività');
  static String get todoDescriptionHint => _t('Description', 'Descrizione');
  static String get todoCancel => _t('Cancel', 'Annulla');
  static String get todoSave => _t('Save', 'Salva');
  static String get todoEditAction => _t('Edit', 'Modifica');
  static String get todoDeleteAction => _t('Delete', 'Elimina');
  static String get todoHasReminder => _t('Has reminder', 'Con promemoria');

  // Task filters (T-TD-05).
  static String get todoDueOverdue => _t('Overdue', 'Scadute');
  static String get todoDueToday => _t('Today', 'Oggi');
  static String get todoDueNext7 => _t('Next 7 days', 'Prossimi 7 giorni');
  static String get todoDueNoDate => _t('No date', 'Senza data');
  // The row's due labels (the range menu above names the ranges): the
  // prefix keeps the due date from being read as the reminder's date.
  static String get todoRowDue => _t('Due', 'Scade');
  static String get todoRowDueToday => _t('Due today', 'Scade oggi');
  static String get todoSortTooltip => _t('Sort', 'Ordina');
  static String get todoSortDue => _t('Due date', 'Scadenza');
  static String get todoSortPriority => _t('Priority', 'Priorità');
  static String get todoSortCreation =>
      _t('Creation date', 'Data di creazione');

  // Task dialog pickers (T-TD-06).
  static String get todoNoPriority => _t('No priority', 'Nessuna priorità');
  static String get todoNoDueDate => _t('No due date', 'Nessuna scadenza');
  static String get todoNoReminder => _t('No reminder', 'Nessun promemoria');
  static String get todoAddProject => _t('+ Project', '+ Progetto');
  static String get todoAddContext => _t('@ Context', '@ Contesto');
  static String get todoAddHashtag => _t('# Tag', '# Tag');

  // Task reminders (T-TD-07).
  static String get todoReminderChannel =>
      _t('Task reminders', 'Promemoria attività');
  static String get todoReminderChannelDescription => _t(
    'Scheduled alerts for tasks with a reminder time.',
    'Avvisi programmati per le attività con un orario di promemoria.',
  );
  static String get todoReminderBody => _t('Todo reminder', 'Promemoria');
  static String get todoReminderFallbackTitle =>
      _t('Task reminder', 'Promemoria attività');
  static String get todoReminderBlocked => _t(
    'Notifications are off, so reminders will not appear.',
    'Le notifiche sono disattivate, quindi i promemoria non compaiono.',
  );
  static String get todoReminderBattery => _t(
    'Battery optimization is on for Copist. The system may sleep the '
        'app and drop pending reminders.',
    'L’ottimizzazione della batteria è attiva per Copist. Il sistema può '
        'sospendere l’app e perdere i promemoria in attesa.',
  );
  static String get todoReminderInexact => _t(
    'This device does not allow exact alarms, so a reminder can arrive '
        'several minutes late with the screen off.',
    'Questo dispositivo non consente sveglie esatte, quindi un '
        'promemoria può arrivare con qualche minuto di ritardo a schermo '
        'spento.',
  );
  static String get reminderShowTokensTitle => _t(
    'Tags in reminder notifications',
    'Tag nelle notifiche dei promemoria',
  );
  static String get reminderShowTokensSubtitle => _t(
    'Keep +project, @context and #tag in the notification text. Off '
        'shows only the task you typed.',
    'Mantiene +progetto, @contesto e #tag nel testo della notifica. Off '
        'mostra solo l’attività che hai scritto.',
  );
  static String get todoReminderFixAction =>
      _t('Open settings', 'Apri impostazioni');
  static String get todoReminderDismissAction => _t('Dismiss', 'Ignora');
  static String get todoReminderDue => _t('Due', 'Scade');

  // Actions and buttons shared by the dialogs (T-L10N-06).
  static String get actionOk => _t('OK', 'OK');
  static String get actionCancel => _t('Cancel', 'Annulla');
  static String get actionCreate => _t('Create', 'Crea');
  static String get actionSave => _t('Save', 'Salva');
  static String get actionChoose => _t('Choose', 'Scegli');
  static String get actionDelete => _t('Delete', 'Elimina');
  static String get actionRename => _t('Rename', 'Rinomina');
  static String get actionMove => _t('Move', 'Sposta');
  static String get actionRestore => _t('Restore', 'Ripristina');
  static String get actionEmpty => _t('Empty', 'Svuota');

  // The shell: app bar, tabs and tree actions.
  static const String appTitle = 'Copist';
  static String get tabFiles => _t('Files', 'File');
  static String get tabSearch => _t('Search', 'Cerca');
  static String get tabSettings => _t('Settings', 'Impostazioni');
  static String get quickNoteTitle => _t('Quick note', 'Nota rapida');
  static String get treeEmpty => _t('No notes yet', 'Nessuna nota');
  static String get selectANote => _t('Select a note', 'Seleziona una nota');
  static String get showListTooltip => _t('Show list', 'Mostra elenco');
  static String get editRawTooltip => _t('Edit raw', 'Modifica il sorgente');
  static String get sortAscTooltip => _t('Sort A-Z', 'Ordina A-Z');
  static String get sortDescTooltip => _t('Sort Z-A', 'Ordina Z-A');
  static String get newNoteTitle => _t('New note', 'Nuova nota');
  static String get newFolderTitle => _t('New folder', 'Nuova cartella');
  static String get newNoteHere => _t('New note here', 'Nuova nota qui');
  static String get newFolderHere =>
      _t('New folder here', 'Nuova cartella qui');
  static String get newListNoteTitle => _t('New list note', 'Nuova lista');
  static String get newListNoteDefault => _t('My list', 'La mia lista');
  static String get setAsQuickNote =>
      _t('Set as quick note', 'Imposta come nota rapida');
  static String get currentQuickNote =>
      _t('Current quick note', 'Nota rapida attuale');
  static String get movedToTrash =>
      _t('Moved to trash', 'Spostato nel cestino');
  static String get deletedMessage => _t('Deleted', 'Eliminato');
  static String deleteToTrashConfirm(String name) =>
      _t('$name will be moved to .trash/', '$name verrà spostato in .trash/');
  static String deleteForeverConfirm(String name) => _t(
    '$name will be permanently deleted',
    '$name verrà eliminato definitivamente',
  );
  static String get chooseDestination =>
      _t('Choose destination', 'Scegli la destinazione');
  static String get libraryRoot => _t('Library root', 'Radice della libreria');
  static String moveTitle(String name) => _t('Move $name', 'Sposta $name');
  static String headingLevelLabel(int level) =>
      _t('Heading $level', 'Titolo $level');

  // Quick note tab and picker.
  static String get quickNoteEmpty => _t(
    'No quick note yet. Choose an existing note, or create a new '
        'one — the quick note opens here.',
    'Nessuna nota rapida. Scegline una esistente o creane una nuova: '
        'la nota rapida si apre qui.',
  );
  static String get quickNoteChooseAction =>
      _t('Choose a note…', 'Scegli una nota…');
  static String get quickNoteCreateAction =>
      _t('Create a new note…', 'Crea una nuova nota…');
  static String get quickNoteNewTitle =>
      _t('New quick note', 'Nuova nota rapida');
  static String get quickNotePickerTitle =>
      _t('Choose quick note', 'Scegli la nota rapida');

  // Folder picker (T-TK-07).
  static String get folderPickerNewFolder => _t('New folder', 'Nuova cartella');
  static String get folderPickerEmpty =>
      _t('No folders yet', 'Nessuna cartella');
  static String get listFolderTitle =>
      _t('List folder', 'Cartella delle liste');

  // Trash (M1).
  static String get trashEmpty => _t('Trash is empty', 'Il cestino è vuoto');
  static String get trashEmptyAction => _t('Empty trash', 'Svuota il cestino');
  static String get trashEmptyConfirm => _t(
    'This deletes everything in the trash folder permanently, '
        'including items Copist did not put there.',
    'Elimina definitivamente tutto ciò che è nel cestino, compreso '
        'ciò che non ci ha messo Copist.',
  );
  static String trashDeleteConfirm(String name) => _t(
    '$name will be deleted permanently (no restore)',
    '$name verrà eliminato definitivamente, senza ripristino',
  );
  static String get trashDeletePermanently =>
      _t('Delete permanently', 'Elimina definitivamente');

  // The open/create library screen.
  static String get openLibraryIntro => _t(
    'Open a folder of Markdown notes as your library',
    'Apri una cartella di note Markdown come libreria',
  );
  static String get openLibraryExisting =>
      _t('Open existing', 'Apri esistente');
  static String get openLibraryCreate => _t('Create new', 'Creane una nuova');
  static String get openLibraryCreateTitle =>
      _t('Create new library', 'Crea una nuova libreria');
  static String get openLibraryFolderName =>
      _t('Folder name', 'Nome della cartella');
  static String get openLibraryChooseFolder =>
      _t('Choose the library folder', 'Scegli la cartella della libreria');
  static String get openLibraryChooseParent => _t(
    'Choose the folder the library will be created in',
    'Scegli la cartella in cui creare la libreria',
  );
  static String get openLibraryUnsupported => _t(
    'That folder is not supported. Pick a folder on the device storage.',
    'Quella cartella non è supportata. Scegline una nella memoria del '
        'dispositivo.',
  );

  /// The first index's counter, e.g. "412 of 10000 notes".
  static String indexingCount(int done, int total) =>
      _t('$done of $total notes', '$done di $total note');

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  static String get knownLibrariesTitle =>
      _t('Your libraries', 'Le tue librerie');
  static String get libraryUnreachable =>
      _t('Not reachable', 'Non raggiungibile');
  static String get libraryOpenedToday => _t('Opened today', 'Aperta oggi');
  static String get libraryOpenedYesterday =>
      _t('Opened yesterday', 'Aperta ieri');
  static String libraryOpenedDaysAgo(int days) =>
      _t('Opened $days days ago', 'Aperta $days giorni fa');
  static String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return _t('Opened on ${when.year}-$m-$d', 'Aperta il $d/$m/${when.year}');
  }

  static String get libraryOpenNow => _t('Open now', 'Aperta ora');
  static String get switchLibraryTitle =>
      _t('Switch library', 'Cambia libreria');
  static String get libraryForget => _t('Forget', 'Dimentica');
  static String libraryForgetTitle(String name) =>
      _t('Forget "$name"?', 'Dimenticare «$name»?');
  static String get libraryForgetExplained => _t(
    'It goes off this list. The folder, the notes and the library '
        'settings inside it are left alone, and opening it again brings '
        'it back.',
    'Sparisce da questo elenco. La cartella, le note e le impostazioni '
        'della libreria restano dove sono, e riaprendola torna '
        'nell’elenco.',
  );

  static String get storageAccessAction =>
      _t('Grant file access', 'Concedi l’accesso ai file');
  static String get storageAccessNeeded => _t(
    'Copist cannot read your notes without "All files access". Grant it '
        'to open a library.',
    'Senza l’accesso a tutti i file Copist non può leggere le tue '
        'note. Concedilo per aprire una libreria.',
  );
  static String get storageAccessExplained => _t(
    'Copist reads your notes as ordinary files, so Android needs to '
        'allow it access to all files. Nothing is uploaded, and only the '
        'library folder you pick is read.',
    'Copist legge le note come file normali, quindi Android deve '
        'concedergli l’accesso a tutti i file. Non viene caricato '
        'niente, e viene letta solo la cartella che scegli.',
  );
  static String folderAccessDenied(Object error) => _t(
    'The system did not give access to the folder: $error',
    'Il sistema non ha dato accesso alla cartella: $error',
  );
  static String folderPickFailed(Object error) => _t(
    'Could not pick a folder: $error',
    'Impossibile scegliere una cartella: $error',
  );

  // Settings screen rows and messages.
  static String get settingsTitle => _t('Settings', 'Impostazioni');
  static String get libraryPathTitle =>
      _t('Library path', 'Percorso della libreria');
  static String get reindexTitle => _t('Re-index now', 'Reindicizza ora');
  static String get reindexDone =>
      _t('Re-index complete', 'Reindicizzazione completata');
  static String get closeLibraryTitle =>
      _t('Close library', 'Chiudi la libreria');
  static String get exportLogTitle =>
      _t('Export debug log', 'Esporta il log di debug');
  static String get exportLogSubtitle => _t(
    'Save the recorded events to a file you choose',
    'Salva gli eventi registrati in un file a tua scelta',
  );
  static String get exportLogEmpty =>
      _t('The debug log buffer is empty', 'Il buffer del log di debug è vuoto');
  static String get quickNoteUnset => _t('Not set yet', 'Non impostata');
  static String exportLogDone(Object target) =>
      _t('Debug log exported to $target', 'Log di debug esportato in $target');
  static String exportLogFailed(Object error) =>
      _t('Export failed: $error', 'Esportazione non riuscita: $error');

  // Replace results (T-M3-10).
  static String replaceNoMatch(String term) => _t(
    'No whole-word match of "$term" was found',
    'Nessuna parola intera "$term" trovata',
  );
  static String replaceDone(int occurrences, String term, int notes) => _t(
    'Replaced $occurrences occurrence(s) of "$term" in $notes note(s)',
    'Sostituite $occurrences occorrenze di "$term" in $notes note',
  );
  static String replaceSkipped(int skipped) =>
      _t(' ($skipped open note(s) skipped)', ' ($skipped note aperte saltate)');
  static String replacePreviewEmpty(String term, String? only) => _t(
    'No exact whole-word match of "$term" '
        '${only == null ? 'was found' : 'found in $only'}',
    'Nessuna parola intera esatta "$term" '
        '${only == null ? 'trovata' : 'trovata in $only'}',
  );

  /// The short month names used by the task rows, January first.
  static List<String> get monthNames => AppLanguages.isItalian
      ? const [
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
        ]
      : const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
}
