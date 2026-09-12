// The Norwegian (Bokmål) strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class NorwegianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januar',
    'februar',
    'mars',
    'april',
    'mai',
    'juni',
    'juli',
    'august',
    'september',
    'oktober',
    'november',
    'desember',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mar',
    'apr',
    'mai',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'des',
  ];
  @override
  List<String> get weekdayNames => const [
    'mandag',
    'tirsdag',
    'onsdag',
    'torsdag',
    'fredag',
    'lørdag',
    'søndag',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'man',
    'tir',
    'ons',
    'tor',
    'fre',
    'lør',
    'søn',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Papirkorg';
  @override
  String get trashSubtitle =>
      'Slettinger flyttes til .trash/ (av = permanent sletting)';
  @override
  String get debugLogsTitle => 'Feilsøksingslogger';
  @override
  String get debugLogsSubtitle => 'Registrer appens hendelser i en minnebuffer';
  @override
  String get lineNumbersTitle => 'Linjetall';
  @override
  String get lineNumbersSubtitle =>
      'Vis kolonnen med linjetall i notateditoren';
  @override
  String get keyboardOnOpenTitle => 'Tastatur ved åpning';
  @override
  String get keyboardOnOpenSubtitle =>
      'Vis tastaturet så snart et notat åpnes (av = ved første trykk)';
  @override
  String get editorKindSource => 'Markdown-kilde';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Forhåndsvising';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Vis det renderte notatet ved siden av kildeeditoren';
  @override
  String get switchToWysiwygTooltip => 'Bytt til WYSIWYG-editoren';
  @override
  String get switchToSourceTooltip => 'Bytt til Markdown-kilden';
  @override
  String get wysiwygTooLarge =>
      'Dette notatet er for stort for WYSIWYG-editoren. Åpne det i '
      'Markdown-kilden.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Utseende';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliotek';
  @override
  String get settingsSectionReminders => 'Påminnelser';
  @override
  String get settingsSectionShortcuts => 'Tastatur';
  @override
  String get keyboardShortcutsTitle => 'Tastaturforkortelser';
  @override
  String get settingsSectionDiagnostics => 'Diagnostikk';
  @override
  String get settingsSpellCheckTitle => 'Stavekontroll';
  @override
  String get settingsSpellCheckSubtitle =>
      'Understreker feilstavinger mens du skriver.';
  @override
  String get spellCheckDictionaryTitle => 'Ordbok';
  @override
  String get spellCheckDictionarySystem => 'Systemstandard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Velg ordbøker';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Velg alle språkene biblioteket er skrevet på. Et ord går gjennom '
      'når noen av de valgte ordbøkene kjenner det; uten valg bestemmer '
      'systemspråket.';
  @override
  String get spellCheckNoDictionaries =>
      'Ingen ordbøker funnet på dette systemet.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Stavekontroll';
  @override
  String get spellCheckTitle => 'Staving';
  @override
  String get spellCheckEmpty => 'Ingen stavefeil.';
  @override
  String get spellCheckUnavailable =>
      'hunspell er ikke installert på dette systemet.';
  @override
  String get spellCheckNoSuggestions => 'Ingen forslag';
  @override
  String spellCheckCount(int count) => '$count å gjennomgå';
  @override
  String spellCheckLine(int line) => 'linje $line';

  @override
  String indentWidthValue(int spaces) => '$spaces mellomrom';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Lysstyrke';
  @override
  String get themeBrightnessSubtitle =>
      'Lys, mørk eller det enheten er innstilt på';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Lys';
  @override
  String get themeBrightnessNight => 'Mørk';
  @override
  String get themePaletteTitle => 'Fargepalett';
  @override
  String get themePaletteSubtitle => 'Fargene i grensesnittet og i notatet';
  @override
  String get themePaletteSystem => 'System';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Grensesnitttekstens størrelse';
  @override
  String get uiTextScaleSubtitle =>
      'Treet, fanene og dialogene; over systeminnstillingen';
  @override
  String get noteTextScaleTitle => 'Notattekstens størrelse';
  @override
  String get noteTextScaleSubtitle =>
      'Editoren og forhåndsvisingen, som alltid er enige';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Forhåndsvisningsmodus';
  @override
  String get previewModeSubtitle =>
      'Om forhåndsvisingen deler skjermen med editoren eller erstatter '
      'den';
  @override
  String get previewModeAuto => 'Side ved side';
  @override
  String get previewModeSwitch => 'Fullskjerm';
  @override
  String get splitRatioTitle => 'Oppdelingsbredde';
  @override
  String get splitRatioSubtitle =>
      'Editors andel når forhåndsvisingen er side ved side';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Lenkeformat';
  @override
  String get linkTypeSubtitle => 'Hva lenkeknappen i editoren setter inn';
  @override
  String get linkTypeWikilink => 'Wikilenke';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Innrykkingsbredde';
  @override
  String get indentWidthSubtitle =>
      'Mellomrom som legges til per innrykksnivå i editoren';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Språk';
  @override
  String get languageSubtitle => 'Språket i appens egen tekst';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Legg til et element';
  @override
  String get listAddTooltip => 'Legg til et element';
  @override
  String get listEmpty => 'Ingen elementer ennå';
  @override
  String get listDragHandleLabel => 'Endre rekkefølge på elementet';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Hurtignotat';
  @override
  String get shortcutNewTodo => 'Ny oppgave';
  @override
  String get shortcutNewNote => 'Nytt notat';
  @override
  String get shortcutNewList => 'Ny liste';
  @override
  String get shortcutToggleSidebar => 'Vis eller skjul filtreet';
  @override
  String get shortcutEditorSection => 'I editoren';
  @override
  String get shortcutFind => 'Søk';
  @override
  String get shortcutReplace => 'Finn og erstat';
  @override
  String get shortcutSavingNote =>
      'Endringer lagres automatisk, så det finnes ingen '
      'lagringsforkortelse.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Struktur';
  @override
  String get outlineNoHeadings => 'Ingen overskrifter';
  @override
  String get outlineNoTitle => '(uten tittel)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Fet';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'Gjennomstreking';
  @override
  String get toolbarSuperscript => 'Opphøyd';
  @override
  String get toolbarUnderline => 'Understreking';
  @override
  String get toolbarLink => 'Lenke';
  @override
  String get toolbarCode => 'Kodeblokk';
  @override
  String get toolbarImage => 'Sett inn bilde';
  @override
  String get toolbarHeading => 'Overskrift';
  @override
  String get toolbarList => 'Liste';
  @override
  String get toolbarOrderedList => 'Nummerert liste';
  @override
  String get toolbarQuote => 'Sitat';
  @override
  String get toolbarIndent => 'Rykk inn';
  @override
  String get toolbarOutdent => 'Rykk ut';
  @override
  String get headingDialogTitle => 'Overskriftsnivå';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editorverktøylinje';
  @override
  String get toolbarSettingsHint =>
      'Dra for å endre rekkefølge; øyet viser eller skjuler en knapp.';
  @override
  String get toolbarShowButton => 'Vis';
  @override
  String get toolbarHideButton => 'Skjul';
  @override
  String get toolbarResetOrder => 'Gjenopprett standard';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Vis forhåndsvising';
  @override
  String get showEditorTooltip => 'Vis editor';
  @override
  String get enterFullScreenTooltip => 'Fullskjerm';
  @override
  String get exitFullScreenTooltip => 'Forlat fullskjerm';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(rå HTML-tabell)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Søk i notater';
  @override
  String get searchModeWords => 'Ord';
  @override
  String get searchModeContains => 'Inneholder';
  @override
  String get searchEmptyHint =>
      'Skriv for å søke i biblioteket, eller nøkkel = verdi for å filtrere '
      'på frontmatter';
  @override
  String get searchTooShortHint => 'Skriv minst 2 tegn';
  @override
  String get searchNoMatches => 'Ingen treff';
  @override
  String get searchLoadMore => 'Vis mer';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Erstatt…';
  @override
  String get replaceInNoteAction => 'Erstatt i dette notatet…';
  @override
  String get replaceInThisNote => 'Erstatt i dette notatet';
  @override
  String get replaceWithLabel => 'Erstatt med';
  @override
  String get replaceCaseSensitive => 'Skiller store og små bokstaver';
  @override
  String get replaceWholeWordsHint => 'kun eksakte helt-ord-treff erstattes';
  @override
  String get replaceConfirm => 'Erstatt';
  @override
  String get replaceCancel => 'Lukk';
  @override
  String get replaceUnavailable => 'Erstatting er ikke tilgjengelig nå';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Finn i notat';
  @override
  String get editorFindHint => 'Finn';
  @override
  String get editorReplaceHint => 'Erstatt';
  @override
  String get editorFindCaseTooltip => 'Skiller store og små bokstaver';
  @override
  String get editorFindPreviousTooltip => 'Forrige treff';
  @override
  String get editorFindNextTooltip => 'Neste treff';
  @override
  String get editorFindCloseTooltip => 'Lukk søk';
  @override
  String get editorFindReplaceModeTooltip => 'Erstatningsmodus';
  @override
  String get editorReplaceOneTooltip => 'Erstatt dette treffet';
  @override
  String get editorReplaceAllTooltip => 'Erstatt alle treff';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tags';
  @override
  String get tagsTitle => 'Tags';
  @override
  String get tagsEmpty =>
      'Ingen tags ennå — legg til en #tag eller tags i frontmatter';
  @override
  String get tagsBackTooltip => 'Tilbake til søk';
  @override
  String get tagsNotesEmpty => 'Ingen notater med denne taggen';
  @override
  String tagsNotesCapped(int limit) =>
      'Kun de første $limit vises — søk taggen for å innskrenke';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Lenken ble ikke funnet';
  @override
  String get headingNotFoundTitle => 'Overskriften ble ikke funnet';
  @override
  String get ambiguousLinkTitle => 'Flere notater samsvarer';
  @override
  String get openLinkFailed => 'Kunne ikke åpne lenken';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Åpne';
  @override
  String get todoDone => 'Ferdig';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Alle datoer';
  @override
  String get todoFilter => 'Filtrer';
  @override
  String get todoNoTokens => 'Ingen token i denne listen';
  @override
  String get todoCountOpen => 'åpne';
  @override
  String get todoCountDone => 'ferdige';
  @override
  String get todoEmptyOpen => 'Ingen pågående oppgaver ennå';
  @override
  String get todoEmptyDone => 'Ingenting fullført ennå';
  @override
  String get todoEmptyFiltered => 'Ingen oppgaver samsvarer';
  @override
  String get todoTitle => 'Å gjøre';
  @override
  String get todoAddTooltip => 'Legg til oppgave';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt-formatet';
  @override
  String get todoHelpTooltip => 'Formatinformasjon';
  @override
  String get todoHelpIntro =>
      'Oppgavene dine er én vanlig tekstfil, én oppgave per linje. Niman '
      'skriver syntaksen for deg, men ingenting skjules: du kan redigere '
      'filen i redaktøren du vil og Niman leser den igjen.';
  @override
  String get todoHelpFilesTitle => 'De to filene';
  @override
  String get todoHelpFilesBody =>
      'Åpne oppgaver ligger i todo.txt i roten av biblioteket. Fullfør én '
      'og linjen flyttes til done.txt, så todo.txt holdes kort. Hvis en '
      'fullført linje havner tilbake i todo.txt arkiverer Niman den neste '
      'gang den leser filene.';
  @override
  String get todoHelpLineTitle => 'En linjes anatomi';
  @override
  String get todoHelpLineBody =>
      'Alt før beskrivelsen er valgfritt og må komme i denne '
      'rekkefølgen:';
  @override
  String get todoHelpDoneBody =>
      'Markerer oppgaven som ferdig. Niman legger den til når du krysser av '
      'i avmerkingsfeltet.';
  @override
  String get todoHelpPriority => '(A) til (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A er den høyeste. Vises som et merke i listen.';
  @override
  String get todoHelpDatesBody =>
      'Ferdigstillelsesdato, så opprettingsdato. Med bare én dato er det '
      'opprettingsdatoen, med mindre linjen starter med x.';
  @override
  String get todoHelpTokensTitle => 'Prosjekter, kontekster og tags';
  @override
  String get todoHelpTokensBody =>
      'Overalt i beskrivelsen blir et ord med ett av disse prefiksene en '
      'chip du kan filtrere på. Intet er forhåndsdefinert: en token finnes '
      'så snart du skriver den.';
  @override
  String get todoHelpProjectBody =>
      'Hva oppgaven hører til, for eksempel +kjøkken eller +oppgave.';
  @override
  String get todoHelpContextBody =>
      'Hvor eller hvordan du gjør den, for eksempel @hjem eller @samtaler.';
  @override
  String get todoHelpHashtagBody =>
      'Et fritt label, for alt de to andre ikke dekker.';
  @override
  String get todoHelpTagsTitle => 'Datoer og påminnelser';
  @override
  String get todoHelpTagsBody =>
      'Disse er nøkkel:verdi-tags. Niman skriver dem fra '
      'oppgavedialogen og leser dem hvor de enn dukker opp på linjen.';
  @override
  String get todoHelpDueBody =>
      'Fristen. Styrt av det fargede merket og datofiltrene.';
  @override
  String get todoHelpRemBody =>
      'Når et varsel skal sendes, i din lokale tid. Det utløses med '
      'skjermen av og appen lukket.';
  @override
  String get todoHelpRemDesktop =>
      'På skrivebord må Niman kjøre når det er tid: påminnelsen vises mens '
      'appen er åpen, og intet utløses når den er lukket.';
  @override
  String get todoHelpOtherBody =>
      'Beholdt nøyaktig som skrevet, slik at tags fra andre todo.txt-app '
      'overlever en rundtur. Niman handler ikke på dem, rec: included: en '
      'gjentagende oppgave gjentas ennå ikke.';
  @override
  String get todoHelpEditTitle => 'Redigering utenfor Niman';
  @override
  String get todoHelpEditBody =>
      'En oppgave du ikke har rørt skrives tilbake byte for byte, rart '
      'mellomrum medregnet. Rediger en linje og Niman skriver om nettopp '
      'den linjen i sitt kanoniske format og rører resten av filen ikke.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Legg til oppgave';
  @override
  String get todoEditTitle => 'Rediger oppgave';
  @override
  String get todoDescriptionHint => 'Beskrivelse';
  @override
  String get todoCancel => 'Avbryt';
  @override
  String get todoSave => 'Lagre';
  @override
  String get todoEditAction => 'Rediger';
  @override
  String get todoDeleteAction => 'Slett';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Forfalt';
  @override
  String get todoDueToday => 'I dag';
  @override
  String get todoDueNext7 => 'Neste 7 dager';
  @override
  String get todoDueNoDate => 'Ingen dato';
  @override
  String get todoRowDue => 'Forfall';
  @override
  String get todoRowDueToday => 'Forfaller i dag';
  @override
  String get todoSortTooltip => 'Sorter';
  @override
  String get todoSortDue => 'Forfallsdato';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Opprettingsdato';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Ingen prioritet';
  @override
  String get todoNoPriorityShort => 'Ingen';
  @override
  String get todoMorePriorities => 'Flere…';
  @override
  String get todoPriorityTitle => 'Prioritet';
  @override
  String get todoNoDueDate => 'Ingen frist';
  @override
  String get todoNoReminder => 'Ingen påminnelse';
  @override
  String get todoAddProject => '+ Prosjekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Oppgavepåminnelser';
  @override
  String get todoReminderChannelDescription =>
      'Planlagte varsler for oppgaver med påminnelsestid.';
  @override
  String get todoReminderBody => 'Å-gjøre-påminnelse';
  @override
  String get todoReminderFallbackTitle => 'Oppgavepåminnelse';
  @override
  String get todoReminderBlocked =>
      'Varsler er slått av, så påminnelser vises ikke.';
  @override
  String get todoReminderBattery =>
      'Batterioptimering er slått på for Niman. Systemet kan la appen '
      'sovne og miste ventende påminnelser.';
  @override
  String get todoReminderInexact =>
      'Denne enheten tillater ikke nøyaktige alarmer, så en påminnelse kan '
      'ankomme flere minutter seint med skjermen av.';
  @override
  String get reminderShowTokensTitle => 'Tags i påminnelsevarsler';
  @override
  String get reminderShowTokensSubtitle =>
      'Behold +prosjekt, @kontekst og #tag i varslsteksten. Av viser bare '
      'oppgaven du skrev.';
  @override
  String get todoReminderFixAction => 'Åpne innstillinger';
  @override
  String get todoReminderDismissAction => 'Avvis';
  @override
  String get todoReminderDue => 'Forfall';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Avbryt';
  @override
  String get actionCreate => 'Opprett';
  @override
  String get actionNew => 'Ny';
  @override
  String get actionSave => 'Lagre';
  @override
  String get actionClear => 'Tøm';
  @override
  String get actionChoose => 'Velg';
  @override
  String get actionDelete => 'Slett';
  @override
  String get actionRename => 'Endre navn';
  @override
  String get actionMove => 'Flytt';
  @override
  String get saveAndClose => 'Lagre og lukk';
  @override
  String get closeUnsavedTitle => 'Ulagre endringer';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” har endringer som ikke er lagret ennå. '
          'Lagre dem før lukking?';
    }
    return '${names.length} notater har endringer som ikke er lagret '
        'ennå. Lagre dem før lukking?';
  }

  @override
  String get closeSaveFailed => 'Kunne ikke lagre; fortsatt åpen.';
  @override
  String get actionRestore => 'Gjenopprett';
  @override
  String get actionEmpty => 'Tøm';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Skjul sidepanelet (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Vis sidepanelet (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimer';
  @override
  String get windowMaximizeTooltip => 'Maksimer';
  @override
  String get windowRestoreTooltip => 'Gjenopprett';
  @override
  String get windowCloseTooltip => 'Lukk';
  @override
  String get tabFiles => 'Filer';
  @override
  String get tabSearch => 'Søk';
  @override
  String get tabSettings => 'Innstillinger';
  @override
  String get quickNoteTitle => 'Hurtignotat';
  @override
  String get treeEmpty => 'Ingen notater ennå';
  @override
  String get selectANote => 'Velg et notat';
  @override
  String get showListTooltip => 'Vis liste';
  @override
  String get editRawTooltip => 'Rediger rå';
  @override
  String get sortAscTooltip => 'Sorter A-Å';
  @override
  String get sortDescTooltip => 'Sorter Å-A';
  @override
  String get newNoteTitle => 'Nytt notat';
  @override
  String get newFolderTitle => 'Ny mappe';
  @override
  String get newNoteHere => 'Nytt notat her';
  @override
  String get newFolderHere => 'Ny mappe her';
  @override
  String get newListNoteTitle => 'Nytt listenotat';
  @override
  String get newListNoteDefault => 'Min liste';
  @override
  String get setAsQuickNote => 'Sett som hurtignotat';
  @override
  String get currentQuickNote => 'Gjeldende hurtignotat';
  @override
  String get pinnedSection => 'Festet';
  @override
  String pinnedSectionCount(int count) => 'Festet · $count';
  @override
  String get templateFolderTitle => 'Malmappe';
  @override
  String get newFromTemplateTitle => 'Ny fra mal';
  @override
  String get newFromTemplateHere => 'Ny fra mal her';
  @override
  String get templateFormTitle => 'Fyll inn malen';
  @override
  String get templateFormBacklink => 'Lenket fra';
  @override
  String get templateFormNoNote => 'Ingen notat';
  @override
  String get templateFormPickNote => 'Velg notatet';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Mal-plassholdere';
  @override
  String get templateHelpIntro =>
      'En mal er et vanlig notat med hull i. Å opprette et notat fra den '
      'kopierer teksten og fyller hullene.';
  @override
  String get templateHelpUnknown =>
      'En plassholder Niman ikke kjenner til beholdes nøyaktig som '
      'skrevet, så en stavefeil vises i notatet i stedet for å stille '
      'spise en linje.';
  @override
  String get templateHelpValuesTitle => 'Verdier';
  @override
  String get templateHelpTitleBody => 'Navnet notatet skal opprettes med.';
  @override
  String get templateHelpDateBody =>
      'I dag, og klokken nå. Begge tar et format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Dato og klokke sammen.';
  @override
  String get templateHelpUuidBody =>
      'En ny identifikator, en annen ved hver forekomst.';
  @override
  String get templateHelpCounterBody =>
      'Et tall som teller opp per navn, beholdt over omstarter: første '
      'notat skriver 1, neste 2. Samme navn i ett notat skriver samme '
      'tall; kombinér med |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Setter pekeren her når notatet opprettes; markøren selv skrives '
      'ikke. Første markør vinner, ingen filtre, kun nye notater — og '
      'tastaturet åpnes også med autofokus av.';
  @override
  String get templateHelpDatesTitle => 'Skrive en dato';
  @override
  String get templateHelpDatesBody =>
      'Disse står for deler av datoen i et format. Alt annet er '
      'litteralt, og tekst i enkelte anførselstegn er også litteralt. '
      'Måne- og ukedagsnavn følger appens språk.';
  @override
  String get templateHelpYear => 'året: 2026, 26';
  @override
  String get templateHelpMonth => 'måneden: 03, 3, mars, mar';
  @override
  String get templateHelpDay => 'dagen: 09, 9, mandag, man';
  @override
  String get templateHelpTime => 'timer, minutter, sekunder';
  @override
  String get templateHelpWeek => 'ISO-uken og kvartalet: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtre';
  @override
  String get templateHelpFiltersBody =>
      'En verdi kan følges av filtre, påført fra venstre til høyre.';
  @override
  String get templateHelpCaseBody =>
      'Store bokstaver, små bokstaver, og den første bokstaven i hvert '
      'ord — et ord du selv har skrevet med stort forbokstav røres ikke.';
  @override
  String get templateHelpSlugBody =>
      'Lenkeformen av teksten, for å bygge en wikilenke.';
  @override
  String get templateHelpPadBody =>
      'Klipp av endene; fyll med nuller til en bredde; bruk et alternativ '
      'når verdien er tom.';
  @override
  String get templateHelpShiftBody =>
      'Flytt en dato med dager, uker, måneder eller år — neste ukes '
      'forelesning, forrige måneds fil.';
  @override
  String get templateHelpSnapBody =>
      'Sett en dato til starten eller slutten av uken, måneden eller året.';
  @override
  String get templateHelpAskTitle => 'Å spørre deg om noe';
  @override
  String get templateHelpAskBody =>
      'Et skjema vises før notatet opprettes, ett felt per spørsmål — og '
      'ett for tilbakelenken, når malen vil ha en. Den samme etiketten to '
      'gånger er ett spørsmål, og svaret fyller alle forekomster — mappen '
      'og filnavnet medregnet.';
  @override
  String get templateHelpAskFieldBody =>
      'Et felt å skrive i; teksten etter det andre kolontegnet er det den '
      'starter med.';
  @override
  String get templateHelpChoiceBody =>
      'Et valg fra en liste, separert med komma.';
  @override
  String get templateHelpWhereTitle => 'Hvor notatet havner';
  @override
  String get templateHelpWhereBody =>
      'Disse er ikke tekst: de er instruksjoner, og de bor i et niman: '
      'blokk i malens egen frontmatter. Blokken utføres og fjernes '
      'deretter, så den vises aldri i notatet. Verdien deres kan inneholde '
      'plassholdere.';
  @override
  String get templateHelpFolderBody =>
      'Mappen notatet opprettes i, opprettet hvis den ikke finnes. Uten '
      'den havner notatet der du var.';
  @override
  String get templateHelpFilenameBody =>
      'Hva notatet heter. En mal som sier dette blir ikke spurt om et '
      'navn.';
  @override
  String get templateHelpAppendBody =>
      'Legg til i notatet hvis den allerede er der, i stedet for å lage '
      'en annen. Det er dette som gjør en måned av møter til én fil.';
  @override
  String get templateHelpOpenBody =>
      'Hva som skjer når notatet finnes: editoren (standard), '
      'forhåndsvisingen, eller ingenting — notatet arkiveres og du blir '
      'der du var.';
  @override
  String get templateHelpAroundTitle => 'Hvor det kom fra';
  @override
  String get templateHelpParentBody =>
      'Et notat du velger i skjemaet, som foreslår det på skjermen; skriv '
      '[[{{parent}}]] for en lenke tilbake.';
  @override
  String get templateHelpFolderValueBody => 'Mappen notatet havnet i.';
  @override
  String get templateHelpClipboardBody =>
      'Hva som ligger på utklippstavlen, og editorvalget når notatet '
      'startet fra ett.';
  @override
  String get templateHelpIncludeTitle => 'Å gjenbruke en del';
  @override
  String get templateHelpIncludeBody =>
      'Limer inn en annen mal, slik at ti maler kan dele én sjekkliste. '
      'Den letes opp i malmappen først, og .md kan utelates. Dens egne '
      'spørsmål blir med i samme skjema.';
  @override
  String get templateHelpExampleTitle => 'Alt sammen';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ingen mal “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” inkluderer seg selv';
  @override
  String includeTooDeep(String path) => '⚠ “$path” er for dypt nøstet';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter ikke lest: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter i “$template” ble ikke lest, så mappen og filnavnet '
      'gjorde ingenting: $reason';
  @override
  String get templatePickerTitle => 'Velg en mal';
  @override
  String templatePickerEmpty(String folder) =>
      'Ingen maler ennå. Legg et notat i $folder/ og det blir en.';

  // Tree actions.
  @override
  String get actionPin => 'Fest';
  @override
  String get actionUnpin => 'Løs';
  @override
  String get movedToTrash => 'Flyttet til papirkorg';
  @override
  String get deletedMessage => 'Slettet';
  @override
  String deleteToTrashConfirm(String name) => '$name flyttes til .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name slettes permanent';
  @override
  String get chooseDestination => 'Velg mål';
  @override
  String get libraryRoot => 'Bibliotekets rot';
  @override
  String moveTitle(String name) => 'Flytt $name';
  @override
  String headingLevelLabel(int level) => 'Overskrift $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ingen hurtignotat ennå. Velg et eksisterende notat, eller opprett '
      'et nytt — hurtignotatet åpnes her.';
  @override
  String get quickNoteChooseAction => 'Velg et notat…';
  @override
  String get quickNoteCreateAction => 'Opprett et nytt notat…';
  @override
  String get quickNoteNewTitle => 'Nytt hurtignotat';
  @override
  String get quickNotePickerTitle => 'Velg hurtignotat';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Ny mappe';
  @override
  String get folderPickerEmpty => 'Ingen mapper ennå';
  @override
  String get listFolderTitle => 'Listemappe';

  // Trash (M1).
  @override
  String get trashEmpty => 'Papirkorgen er tom';
  @override
  String get trashEmptyAction => 'Tøm papirkorgen';
  @override
  String get trashEmptyConfirm =>
      'Dette sletter alt i papirkorgen permanent, inkludert elementer '
      'Niman ikke la dit.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name slettes permanent (ingen gjenoppretting)';
  @override
  String get trashDeletePermanently => 'Slett permanent';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Åpne en mappe med Markdown-notater som bibliotek';
  @override
  String get openLibraryExisting => 'Åpne eksisterende';
  @override
  String get openLibraryCreate => 'Opprett ny';
  @override
  String get openLibraryCreateTitle => 'Opprett nytt bibliotek';
  @override
  String get openLibraryFolderName => 'Mappenavn';
  @override
  String get openLibraryChooseFolder => 'Velg biblioteksmappen';
  @override
  String get openLibraryChooseParent =>
      'Velg mappen biblioteket skal opprettes i';
  @override
  String get openLibraryUnsupported =>
      'Den mappen støttes ikke. Velg en mappe på enhetens lagring.';
  @override
  String indexingCount(int done, int total) => '$done av $total notater';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Bibliotekene dine';
  @override
  String get libraryUnreachable => 'Unåelig';
  @override
  String get libraryOpenedToday => 'Åpnet i dag';
  @override
  String get libraryOpenedYesterday => 'Åpnet i går';
  @override
  String libraryOpenedDaysAgo(int days) => 'Åpnet for $days dager siden';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Åpnet ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Åpent nå';
  @override
  String get switchLibraryTitle => 'Bytt bibliotek';
  @override
  String get libraryForget => 'Glem';
  @override
  String libraryForgetTitle(String name) => 'Glemme “$name”?';
  @override
  String get libraryForgetExplained =>
      'Den forsvinner fra denne listen. Mappen, notatene og '
      'bibliotekinnstillingene i den røres ikke, og å åpne den igjen tar '
      'den tilbake.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Gi filtilgang';
  @override
  String get storageAccessNeeded =>
      'Niman kan ikke lese notatene dine uten “Tilgang til alle filer”. '
      'Gi den for å åpne et bibliotek.';
  @override
  String get storageAccessExplained =>
      'Niman leser notatene dine som vanlige filer, så Android må gi den '
      'tilgang til alle filer. Intet lastes opp, og kun den '
      'biblioteksmappen du velger leses.';
  @override
  String folderAccessDenied(Object error) =>
      'Systemet ga ikke tilgang til mappen: $error';
  @override
  String folderPickFailed(Object error) => 'Kunne ikke velge en mappe: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Innstillinger';
  @override
  String get libraryPathTitle => 'Bibliotekssti';
  @override
  String get reindexTitle => 'Indeksér om nå';
  @override
  String get reindexDone => 'Omindexering fullført';
  @override
  String get closeLibraryTitle => 'Lukk biblioteket';
  @override
  String get exportLogTitle => 'Eksporter feilsøksingslogg';
  @override
  String get exportLogSubtitle =>
      'Lagre de registrerte hendelsene til en fil du velger';
  @override
  String get exportLogEmpty => 'Feilsøkingsloggbufferen er tom';
  @override
  String get quickNoteUnset => 'Ikke satt ennå';
  @override
  String exportLogDone(Object target) =>
      'Feilsøksingsloggen eksportert til $target';
  @override
  String exportLogFailed(Object error) => 'Eksport mislyktes: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ingen eksakt helt-ord-treff på “$term” ble funnet';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Erstattet $occurrences forekomster av “$term” i $notes notater';
  @override
  String replaceSkipped(int skipped) => ' ($skipped åpne notater hoppet over)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ingen eksakt helt-ord-treff på “$term” '
      '${only == null ? 'ble funnet' : 'funnet i $only'}';
}
