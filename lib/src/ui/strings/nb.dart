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
  String get trashAutoEmptyTitle => 'Tøm papirkorgen automatisk';
  @override
  String get trashAutoEmptySubtitle =>
      'Eldre slettinger forsvinner for godt når biblioteket åpnes';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Aldri'
      : days == 1
      ? '1 dag'
      : '$days dager';
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
  String get readableLineLengthTitle => 'Lesbar linjelengde';
  @override
  String get readableLineLengthSubtitle =>
      'Hold notatets tekst i en sentrert kolonne i stedet for hele '
      'vindusbredden';
  @override
  String get noteColumnWidthTitle => 'Kolonnebredde';
  @override
  String get noteColumnWidthSubtitle => 'Hvor bred notatkolonnen er, i piksler';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
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
  String get editorKindSourceSubtitle => 'Markdown-kilde, som skrevet';
  @override
  String get editorKindWysiwygSubtitle => 'Formatert tekst, redigeres direkte';
  @override
  String get settingsFolderToCreate => 'opprettes';
  @override
  String get settingsSearchHint => 'Søk i innstillinger';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 innstilling funnet' : '$count innstillinger funnet';
  @override
  String get settingsToggleOn => 'På';
  @override
  String get settingsToggleOff => 'Av';
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
  String get switchToSourceLabel => 'Kilde';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bibliotek $name';
  @override
  String get settingsGroupLibraryHint => 'gjelder bare for dette biblioteket';
  @override
  String get settingsGroupMaintenance => 'Vedlikehold';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mapper og stier';
  @override
  String get settingsAreaTrashHistory => 'Papirkorg og historikk';
  @override
  String get settingsAreaDiagnostics => 'Diagnostikk og info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Krever et tilkoblet fysisk tastatur';
  @override
  String get settingsSectionUpdates => 'Oppdateringer';
  @override
  String get autoUpdateTitle => 'Automatiske oppdateringer';
  @override
  String get autoUpdateSubtitle =>
      'Sjekk GitHub Releases ved oppstart og hver 6. time';
  @override
  String get checkForUpdatesTitle => 'Se etter oppdateringer';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version er tilgjengelig';
  @override
  String get updateUpToDate => 'Niman er oppdatert';
  @override
  String get updateCheckFailed => 'Kunne ikke se etter oppdateringer';
  @override
  String updateSavedTo(Object path) => 'Oppdateringen er lagret i $path';
  @override
  String get updateInstallerStarted => 'Installasjonsprogrammet er startet';
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
  String get addWordToDictionary => 'Legg til i ordbogen';

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
  String get themeTitle => 'Tema';
  @override
  String get themeSubtitle => 'Fargene i grensesnittet og i notatet';
  @override
  String get themePaletteSystem => 'System';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Temaer';
  @override
  String get themesInUse => 'I bruk';

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
  String get missingNoteLocationTitle => 'Opprett manglende notater i';
  @override
  String get missingNoteLocationRoot => 'Bibliotekets rotmappe';
  @override
  String get missingNoteLocationCurrentFolder => 'Nuværende mappe';
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

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Ingen opptak ennå';
  @override
  String get audioRecord => 'Ta opp';
  @override
  String get audioStop => 'Stopp';
  @override
  String get audioPlay => 'Spill av';
  @override
  String get audioDelete => 'Slett opptak';
  @override
  String get audioImport => 'Importer en lydfil';
  @override
  String get audioRecording => 'Tar opp…';
  @override
  String get audioPermissionDenied =>
      'Mikrofontillatelse avslått — opptak krever den.';
  @override
  String get newAudioNoteTitle => 'Nytt talenotat';
  @override
  String get newAudioNoteDefault => 'Mitt opptak';
  @override
  String get showAudioTooltip => 'Vis opptak';
  @override
  String get audioMessageHint => 'Skriv et notat…';
  @override
  String get audioSend => 'Send';
  @override
  String get audioRename => 'Endre navn på opptak';
  @override
  String get audioDescriptionHint => 'Beskriv dette opptaket…';
  @override
  String get audioEditDescription => 'Rediger beskrivelse';
  @override
  String get audioDeleteNote => 'Slett notat';
  @override
  String get audioEditNote => 'Rediger notat';
  @override
  String get audioPause => 'Pause';
  @override
  String get audioEditTitle => 'Rediger tittel';
  @override
  String get audioTitleHint => 'Gi opptaket en tittel…';
  @override
  String audioUntitled(int n) => 'Opptak $n';
  @override
  String get audioMoreActions => 'Flere handlinger';
  @override
  String get audioDiscardRecording => 'Forkast opptak';
  @override
  String get audioPauseRecording => 'Sett opptaket på pause';
  @override
  String get audioResumeRecording => 'Fortsett opptaket';
  @override
  String get audioRecordingPaused => 'Pauset';
  @override
  String get audioSavingRecording => 'Lagrer…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Hurtignotat';
  @override
  String get trayOpen => 'Åpne Niman';
  @override
  String get trayQuit => 'Avslutt';
  @override
  String get closeToTrayTitle => 'Lukk til systemkurven';
  @override
  String get closeToTraySubtitle =>
      'Vinduets × skjuler Niman og lar det kjøre, så påminnelser fortsatt '
      'kommer. Avslutt fra ikonets meny.';
  @override
  String get shortcutNewTodo => 'Ny oppgave';
  @override
  String get shortcutNewNote => 'Nytt notat';
  @override
  String get shortcutNewList => 'Ny liste';
  @override
  String get shortcutNewAudio => 'Nytt talenotat';
  @override
  String get shortcutToggleSidebar => 'Vis eller skjul filtreet';
  @override
  String get shortcutCloseTab => 'Lukk det gjeldende notatet';
  @override
  String get shortcutNextTab => 'Neste åpne notat';
  @override
  String get shortcutPreviousTab => 'Forrige åpne notat';
  @override
  String get shortcutEditorSection => 'I editoren';
  @override
  String get shortcutFormatSection => 'Formatering';
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
  String get noteStatusLoading => 'Laster…';
  @override
  String get noteStatusSaving => 'Lagrer…';
  @override
  String get noteStatusUnsaved => 'Ikke lagret';
  @override
  String get noteStatusSaved => 'Lagret';
  @override
  String get noteStatusError => 'Feil';
  @override
  String get noteNotText =>
      'Denne filen er ikke et tekstnotat, så Niman kan ikke vise den her.';
  @override
  String get noteLoadFailed => 'Notatet kunne ikke åpnes.';
  @override
  String wordCount(int count) => '$count ord';
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

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Verktøy';
  @override
  String get editorToolsTitle => 'Redigeringsverktøy';
  @override
  String get toolCountListTitle => 'Tell en liste';
  @override
  String get toolCountListSubtitle =>
      'Summerer det radene lister opp, som en sjekkliste';
  @override
  String get toolCountListNeedsList => 'Dette notatet har ingen liste å telle';
  @override
  String get tallySourceLabel => 'Liste';
  @override
  String get tallyCutLabel => 'Les hver rad som';
  @override
  String get tallyCutDash => 'Navn - verdier';
  @override
  String get tallyCutColon => 'Navn: verdier';
  @override
  String get tallyCutCommas => 'Verdier atskilt med komma';
  @override
  String get tallyCutWhole => 'Hele raden som én verdi';
  @override
  String get tallySortLabel => 'Rekkefølge';
  @override
  String get tallySortCount => 'Flest først';
  @override
  String get tallySortAlphabetical => 'Alfabetisk';
  @override
  String get tallySortFirstSeen => 'Som oppført';
  @override
  String get tallyInsert => 'Sett inn';
  @override
  String get tallyUpdate => 'Oppdater';
  @override
  String get tallyNothingToCount => 'Her er det ingenting å telle';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Notatet finnes ikke';
  @override
  String missingNoteDialogBody(String path) => 'Opprette „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Mappen „$folder“ finnes ikke';

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
  String get newItemTooltip => 'Ny';
  @override
  String get closeMenuTooltip => 'Lukk';
  @override
  String get newFolderTitle => 'Ny mappe';
  @override
  String get newNoteSameFolder => 'Nytt notat i samme mappe';
  @override
  String get newFromTemplateSameFolder => 'Nytt fra mal i samme mappe';
  @override
  String trashOriginalPath(String path) => 'lå i $path';
  @override
  String get trashOriginalRoot => 'var i roten av biblioteket';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 element' : '$count elementer';
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
  String get templateHelpSubtitle =>
      'Dato, tittel og de øvrige verdiene å fylle ut';
  @override
  String get quickNoteSubtitle => 'Notatet Hurtiglapp-fanen åpner';
  @override
  String get listFolderSubtitle => 'De nye oppgavelistene';
  @override
  String get templateFolderSubtitle => 'Kilden til „Ny fra mal“';
  @override
  String get attachmentsFolderSubtitle => 'Bilder og lyd satt inn i et notat';
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
  String get pinToWidget => 'Fest til startskjermwidgeten';
  @override
  String get pinnedForWidget => 'Festet: legg nå Notat-widgeten på startsiden';
  @override
  String get pinWidgetUnavailable =>
      'Startskjermwidgets er tilgjengelige på Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Vis i filbehandler';
  @override
  String get openInDefaultApp => 'Åpne i standardappen';
  @override
  String get newNoteTabTooltip => 'Nytt notat i ny fane';
  @override
  String get openNotesTooltip => 'Åpne notater';
  @override
  String get closeTabTooltip => 'Lukk';
  @override
  String get openInNewTab => 'Åpne i ny fane';
  @override
  String get splitRight => 'Del til høyre';
  @override
  String get splitDown => 'Del nedover';
  @override
  String get moveToOtherPane => 'Flytt til den andre ruten';
  @override
  String get openBeside => 'Åpne ved siden av';
  @override
  String get closeAllNotes => 'Lukk alle';
  @override
  String get sidePanelTooltip => 'Vis eller skjul sidepanelet';
  @override
  String get historyAllVersions => 'Alle versjoner';
  @override
  String get commandPaletteTitle => 'Kommandopalett';
  @override
  String get goToNoteTitle => 'Gå til notat';
  @override
  String get paletteGroupNote => 'Notat';
  @override
  String get paletteGroupEditor => 'Redigering';
  @override
  String get paletteGroupView => 'Visning';
  @override
  String get paletteGroupLibrary => 'Bibliotek';
  @override
  String get paletteGroupGoTo => 'Gå til';
  @override
  String get commandsTitle => 'Kommandoer';
  @override
  String get commandsIntro =>
      'Kommandopaletten tilbyr bare kommandoene som kan kjøres der du er. Her '
      'er alle, og når hver av dem vises.';
  @override
  String get commandNeedNone => 'Alltid tilgjengelig';
  @override
  String get commandNeedOpenNote => 'Krever et åpent notat';
  @override
  String get commandNeedWideWindow => 'Bare i bredt vindu';
  @override
  String get commandNeedDockRoom =>
      'Krever et vindu som er bredt nok for sidepanelet';
  @override
  String get commandNeedDesktop => 'Bare på datamaskin';
  @override
  String get commandNeedNotInZen => 'Ikke i Zen-modus';
  @override
  String get commandNeedZenRoom => 'Datamaskin, med et notat åpent i en fane';
  @override
  String get commandNeedPreview => 'Med forhåndsvisning på, på et tekstnotat';
  @override
  String get commandNeedTwoEditors =>
      'Med begge redigeringsprogrammene slått på';
  @override
  String get paletteHint => 'Søk i kommandoer og notater';
  @override
  String get paletteNoResults => 'Ingen treff';
  @override
  String get paletteCommands => 'Kommandoer';
  @override
  String get paletteNotes => 'Notater';
  @override
  String get paletteFooter =>
      '↑↓ for å flytte · ↵ for å bruke · esc for å lukke';
  @override
  String get paletteFooterTouch =>
      'Trykk for å bruke · nålen holder den øverst';
  @override
  String get palettePinned => 'Festet';
  @override
  String get palettePin => 'Fest';
  @override
  String get paletteUnpin => 'Løsne';
  @override
  String get palettePinFooter => 'alt+P for å feste';
  @override
  String get spellCheckScanning => 'Kontrollerer notatet…';
  @override
  String get spellCheckAgain => 'Kontroller igjen';
  @override
  String spellCheckCapped(int count) =>
      'De første $count vises: rett noen, og kontroller igjen for resten';
  @override
  String get dropHint =>
      'Slipp Markdown-filer for å åpne dem, eller en mappe for å importere den';
  @override
  String get dropNothing => 'Skrivebordet leverte ingen filer for det slippet.';
  @override
  String get importFolderAction => 'Importer';
  @override
  String dropRejected(String names) =>
      'Bare Markdown-filer og mapper åpnes her: $names';
  @override
  String importFolderTitle(String name) => 'Importere «$name»?';
  @override
  String importFolderBody(int count) =>
      'Markdown-filene ($count) kopieres til en ny mappe i biblioteket. '
      'Mappen du slapp, forblir som den er.';
  @override
  String importFolderDone(String folder) => 'Importert til $folder';
  @override
  String importFolderEmpty(String name) => 'Ingen Markdown-filer i $name';
  @override
  String get openFileTitle => 'Åpne fil';
  @override
  String get outsideFileNote =>
      'Utenfor biblioteker: lagres der den ligger, ikke indeksert, ingen '
      'historikk, lenker følges ikke';
  @override
  String get typewriterOn => 'Slå på skrivemaskinmodus';
  @override
  String get typewriterOff => 'Slå av skrivemaskinmodus';
  @override
  String get typewriterTitle => 'Skrivemaskinmodus';
  @override
  String get formatNoteTitle => 'Rydd opp i Markdown';
  @override
  String get formatNoteDone => 'Notatet ble ryddet.';
  @override
  String get formatNoteAlreadyTidy => 'Notatet var allerede ryddig.';
  @override
  String get typewriterSubtitle =>
      'Hold linjen du skriver på midt i redigeringsfeltet';
  @override
  String get zenMode => 'Zen-modus';
  @override
  String get zenModeEnter => 'Gå til zen-modus';
  @override
  String get zenModeLeave => 'Gå ut av zen-modus';
  @override
  String get keySpace => 'Mellomrom';
  @override
  String get keyEnter => 'Enter';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Tilbake';
  @override
  String get keyDelete => 'Delete';
  @override
  String get keyArrowUp => 'Opp';
  @override
  String get keyArrowDown => 'Ned';
  @override
  String get keyArrowLeft => 'Venstre';
  @override
  String get keyArrowRight => 'Høyre';
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
  String get shortcutNone => 'Ingen snarvei';
  @override
  String get shortcutRestoreDefaults => 'Gjenopprett standard';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Sette alle snarveier tilbake slik Niman leverer dem?';
  @override
  String get shortcutRevert => 'Tilbake til standard';
  @override
  String get shortcutClear => 'Fjern snarveien';
  @override
  String get shortcutCapturePrompt =>
      'Trykk tastene. Esc og Tab tas også opp: Avbryt er veien ut.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Legg til Ctrl, Alt eller Meta: en tast alene er for å skrive.';
  @override
  String get shortcutMove => 'Flytt den';
  @override
  String get shortcutUseAnyway => 'Bruk likevel';
  @override
  String get shortcutUndo => 'Angre';
  @override
  String get shortcutRedo => 'Gjør om';
  @override
  String get shortcutChange => 'Endre snarveien';
  @override
  String shortcutCaptureTitle(String command) => 'Taster for $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys tilhører allerede $other. Flytte den hit? $other får ingen '
      'snarvei.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys er også $what i tekstfelt og redigeringen. Der tar kommandoen '
      'din den.';
  @override
  String get openFileMissing => 'Filen til dette notatet finnes ikke på disken';
  @override
  String get openFileFailed => 'Notatet kunne ikke åpnes utenfor Niman';

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
  @override
  String get attachmentsFolderTitle => 'Vedleggsmappe';

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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Om';
  @override
  String get versionTitle => 'Versjon';
  @override
  String get changelogTitle => 'Endringslogg';
  @override
  String get changelogEmpty => 'Ingen endringsloggposter tilgjengelig';
  @override
  String changelogWhatsNew(String version) => 'Nyhet i versjon $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historikk';
  @override
  String get noteMenuTooltip => 'Notathandlinger';
  @override
  String get historyCurrentVersion => 'Gjeldende versjon';
  @override
  String get historyCurrentSubtitle => 'Notatet slik det er nå';
  @override
  String get historyToday => 'I dag';
  @override
  String get historyYesterday => 'I går';
  @override
  String get historyReasonSession => 'før redigering';
  @override
  String get historyReasonInterval => 'under redigering';
  @override
  String get historyReasonRestore => 'før gjenoppretting';
  @override
  String get historyReasonSync => 'før synk';
  @override
  String get historyReasonReplace => 'før erstatning';
  @override
  String get historyReasonUnknown => 'gjenfunnet';
  @override
  String get historySyncBase => 'synkbase';
  @override
  String get historyEmpty =>
      'Ingen versjoner ennå. Niman tar vare på én når du begynner å redigere '
      'notatet, og deretter høyst én med noen minutters mellomrom mens du '
      'skriver.';
  @override
  String historyKept(int kept, int limit) =>
      '$kept av $limit versjoner beholdt';
  @override
  String get historyBaseKept => 'Synkbasen beholdes utover grensen.';
  @override
  String get historyOff =>
      'Historikk er slått av for dette biblioteket '
      '(Innstillinger, Bibliotek).';
  @override
  String get historyLoadFailed => 'Kunne ikke lese historikken';
  @override
  String get historyCompareSubtitle => 'Sammenlignet med gjeldende versjon';
  @override
  String get historyTabChanges => 'Endringer';
  @override
  String get historyTabVersion => 'Versjon';
  @override
  String get historyNoChanges => 'Samme tekst som gjeldende versjon.';
  @override
  String get historyRestoreAction => 'Gjenopprett denne versjonen';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Gjenopprette versjonen fra $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Gjeldende tekst lagres først i historikken, så du kan alltid gå '
      'tilbake.';
  @override
  String get historyRestoreConfirm => 'Gjenopprett';
  @override
  String historyRestored(String when) => 'Gjenopprettet versjonen fra $when';
  @override
  String get historyRestoreFailed => 'Kunne ikke gjenopprette versjonen';
  @override
  String get actionUndo => 'Angre';
  @override
  String diffLineRange(int start, int end) => 'Linjer $start–$end';
  @override
  String diffLineSingle(int line) => 'Linje $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 uendret linje' : '$count uendrede linjer';
  @override
  String get historyTakeHunk => 'Gjenopprett her';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Gjenopprett 1 endring' : 'Gjenopprett $count endringer';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'De valgte endringene går tilbake til teksten i denne versjonen. Notatet '
      'slik det er nå beholdes først som en versjon, så du kan angre.';
  @override
  String get historyNoteChangedReloaded =>
      'Notatet ble endret mens du var her — sammenligningen er oppdatert.';
  @override
  String get historyVersionsTitle => 'Versjoner som beholdes';
  @override
  String get historyVersionsSubtitle => 'Per notat, i .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Ingen' : '$count';
  @override
  String get historyIntervalTitle => 'Ny versjon høyst hver';
  @override
  String get historyIntervalSubtitle =>
      'Mens du skriver; når du begynner å redigere et notat, lagres alltid én';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkribering';
  @override
  String get transcriptionModelTitle => 'Modell';
  @override
  String get transcriptionModelNone => 'Ingen';
  @override
  String get transcriptionLanguageTitle => 'Språk';
  @override
  String get transcriptionLanguageSubtitle =>
      'Språket som snakkes i opptakene dine. Å oppgi det er mer nøyaktig enn '
      'å la det gjenkjennes.';
  @override
  String transcriptionLanguageApp(String language) => 'Som appen ($language)';
  @override
  String get transcriptionLanguageDetect => 'Gjenkjenn automatisk';
  @override
  String get transcriptionModelsTitle => 'Transkriberingsmodeller';
  @override
  String transcriptionModelsUsed(String size) => '$size brukt';
  @override
  String get transcriptionModelsInstalled => 'Lastet ned';
  @override
  String get transcriptionModelsDownloading => 'Lastes ned';
  @override
  String get transcriptionModelsAvailable => 'Tilgjengelige';
  @override
  String get transcriptionModelsFooter =>
      'Modellene ligger i appens lagring på denne enheten. De kopieres ikke '
      'til biblioteket og synkroniseres ikke.';
  @override
  String get transcriptionModelDefault => 'Standard';
  @override
  String get transcriptionModelSlow => 'Treg';
  @override
  String get transcriptionModelHintTiny => 'Raskest, minst nøyaktig';
  @override
  String get transcriptionModelHintBase =>
      'God balanse mellom fart og nøyaktighet';
  @override
  String get transcriptionModelHintSmall => 'Mer nøyaktig, omtrent 3× tregere';
  @override
  String get transcriptionModelHintMedium => 'Svært nøyaktig, treg på telefon';
  @override
  String get transcriptionModelHintLarge => 'Mest nøyaktig, trenger mye minne';
  @override
  String get transcriptionModelDownload => 'Last ned';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Slette modellen $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Dette frigjør $size. Du kan laste ned modellen igjen senere.';
  @override
  String get transcriptionModelFailed =>
      'Nedlastingen mislyktes. Sjekk tilkoblingen og prøv igjen.';
  @override
  String get actionRetry => 'Prøv igjen';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Tilkoblingen ble brutt, prøver igjen…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Satt på pause ved $progress';
  @override
  String get actionResume => 'Fortsett';
  @override
  String get audioTranscribe => 'Transkriber';
  @override
  String get audioTranscribeUnsupported => 'Bare WAV-opptak på denne enheten';
  @override
  String get transcriptionQueued => 'I kø';
  @override
  String get transcriptionPreparing => 'Klargjør lyden…';
  @override
  String transcriptionRunning(int percent) => 'Transkriberer… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Laster ned $model · $percent %';
  @override
  String get transcriptionSaved =>
      'Transkripsjonen ble lagt til i beskrivelsen';
  @override
  String get transcriptionNoSpeech =>
      'Ingen tale ble gjenkjent i dette opptaket';
  @override
  String get transcriptionFailed => 'Transkriberingen mislyktes';
  @override
  String get transcriptionPickModelTitle => 'Velg en modell';
  @override
  String get transcriptionPickModelBody =>
      'Transkriberingen skjer på denne enheten, og opptaket lastes aldri opp. '
      'Modellen lastes ned én gang.';
  @override
  String get transcriptionPickModelAction => 'Last ned og transkriber';
  @override
  String get transcriptionModelRecommended => 'Anbefalt';
  @override
  String get transcriptionExistingTitle =>
      'Opptaket har allerede en beskrivelse';
  @override
  String get transcriptionExistingBody =>
      'Erstatte den med transkripsjonen, eller legge transkripsjonen til '
      'under?';
  @override
  String get transcriptionAppend => 'Legg til under';
  @override
  String get transcriptionReplace => 'Erstatt';
  @override
  String get settingsSectionSync => 'Synkronisering';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Ikke satt opp for dette biblioteket';
  @override
  String get syncNeverSynced => 'Aldri synkronisert';
  @override
  String syncLastSynced(String when) => 'Synkronisert $when';
  @override
  String get syncRunning => 'Synkroniserer…';
  @override
  String syncScreenSubtitle(String library) => 'Bibliotek $library';
  @override
  String get syncUrlLabel => 'Mappeadresse';
  @override
  String get syncUrlRequired => 'Skriv inn serveradressen';
  @override
  String get syncUrlHint =>
      'Mappen må finnes. Kopier adressen slik serveren viser den.';
  @override
  String get syncHttpWarning =>
      'Ukryptert tilkobling: greit over VPN eller på det lokale '
      'nettverket.';
  @override
  String get syncUserLabel => 'Bruker';
  @override
  String get syncUserHint =>
      'La stå tomt hvis serveren ikke ber om '
      'påloggingsinformasjon.';
  @override
  String get syncPasswordLabel => 'Passord';
  @override
  String get syncPasswordHint =>
      'Lagres i nøkkelringen på denne enheten, aldri i '
      'bibliotekfilene.';
  @override
  String get syncPasswordKeepHint =>
      'La stå tomt for å beholde det lagrede passordet.';
  @override
  String get syncShowPassword => 'Vis passord';
  @override
  String get syncHidePassword => 'Skjul passord';
  @override
  String get syncTestAction => 'Test tilkoblingen';
  @override
  String get syncTesting => 'Tester…';
  @override
  String get syncRetargetWarning =>
      'Med ny adresse eller bruker starter neste synk på nytt '
      'som en første synk.';
  @override
  String get syncTestOk => 'Tilkoblingen virker';
  @override
  String get syncModeFull => 'Full modus';
  @override
  String get syncModeCompatible => 'Kompatibel modus';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lese, skrive og slette';
  @override
  String get syncCapEtags => 'Filfingeravtrykk (ETag)';
  @override
  String get syncCapNoEtags => 'Ingen filfingeravtrykk (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Sammenligner størrelse og dato; laster ned på nytt ved '
      'tvil';
  @override
  String get syncCapGuarded => 'Beskyttet skriving';
  @override
  String get syncCapUnguarded => 'Ubeskyttet skriving';
  @override
  String get syncCapUnguardedDetail =>
      'Sjekker filen på serveren rett før skriving';
  @override
  String get syncCapMove => 'Endrer navn uten ny opplasting';
  @override
  String get syncCapNoMove => 'Ingen navneendring på serveren';
  @override
  String get syncCapNoMoveDetail =>
      'En navneendring blir en sletting og en ny opplasting';
  @override
  String get syncCompatibleNote =>
      'I kompatibel modus fungerer synk likt, med noen flere '
      'forespørsler.';
  @override
  String get syncTestInvalidUrl => 'Ikke en gyldig adresse';
  @override
  String get syncTestInvalidUrlHint =>
      'Skriv inn en adresse med http:// eller https://, uten '
      'bruker eller passord i den.';
  @override
  String get syncTestOffline => 'Serveren kan ikke nås';
  @override
  String get syncTestOfflineHint =>
      'Er VPN på? En adresse på 10.x eller 192.168.x virker bare '
      'fra samme nettverk.';
  @override
  String get syncTestAuth => 'Bruker eller passord avvist';
  @override
  String get syncTestAuthHint => 'Sjekk dem, og test igjen.';
  @override
  String get syncTestNotFound => 'Mappen finnes ikke';
  @override
  String get syncTestNotFoundHint =>
      'Opprett den på serveren eller rett adressen.';
  @override
  String get syncTestUnsupported => 'Ikke en WebDAV-mappe';
  @override
  String get syncTestUnsupportedHint => 'Serveren svarer, men ikke som WebDAV.';
  @override
  String get syncTestFailed => 'Testen mislyktes';
  @override
  String get syncNowAction => 'Synkroniser nå';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresse, bruker og passord';
  @override
  String get syncRetestTitle => 'Test serveren igjen';
  @override
  String syncProbedAgo(String when) => 'Siste test $when';
  @override
  String get syncDisconnectTitle => 'Koble fra dette biblioteket';
  @override
  String get syncDisconnectSubtitle =>
      'Filene blir liggende her og på serveren';
  @override
  String get syncDisconnectConfirmTitle => 'Koble fra synk?';
  @override
  String get syncDisconnectConfirmBody =>
      'Dette biblioteket slutter å synkronisere på denne '
      'enheten. Ingen filer slettes, verken her eller på '
      'serveren. Kobler du det til igjen, starter første synk på '
      'nytt.';
  @override
  String get syncDisconnectConfirm => 'Koble fra';
  @override
  String get syncFirstTitle => 'Første synk';
  @override
  String get syncFirstIntro =>
      'Biblioteket er sammenlignet med mappen på serveren:';
  @override
  String get syncFirstUpload => 'Skal lastes opp';
  @override
  String get syncFirstDownload => 'Skal lastes ned';
  @override
  String get syncFirstBoth => 'På begge sider';
  @override
  String get syncFirstBothHint => 'Like: ingen overføring. Ulike: må løses';
  @override
  String get syncFirstNoDelete =>
      'Første synk sletter ingenting, verken her eller på '
      'serveren.';
  @override
  String get syncStartAction => 'Start';
  @override
  String syncMassTrashTitle(int count) =>
      'Flytte $count filer til papirkorgen?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count av de $total synkroniserte filene mangler på '
      'serveren. Det betyr som regel feil adresse, en NAS-disk '
      'som ikke er montert, eller en mappe som er tømt ved en '
      'feil.';
  @override
  String get syncMassTrashHint =>
      'Hvis du virkelig slettet dem på en annen enhet, bekreft: '
      'her havner de i papirkorgen.';
  @override
  String get syncMassTrashConfirm => 'Flytt til papirkorgen';
  @override
  String syncMassDeleteTitle(int count) => 'Slette $count filer fra serveren?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count av de $total synkroniserte filene mangler her. '
      'Hvis du ikke slettet dem, avbryt og sjekk bibliotekmappen.';
  @override
  String get syncMassDeleteConfirm => 'Slett fra serveren';
  @override
  String get syncTooltip => 'Synkroniser';
  @override
  String get syncStageConnecting => 'Kobler til serveren…';
  @override
  String get syncStageComparing => 'Sammenligner med serveren…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synkroniserer · $done av $total';
  @override
  String get syncStatusWarnings => 'Synkronisert med advarsler';
  @override
  String syncConflictsHeader(int count) => 'Endret her og på serveren · $count';
  @override
  String get syncConflictHint => 'Ingen av versjonene ble rørt';
  @override
  String get syncResolveAction => 'Løs';
  @override
  String syncFailuresHeader(int count) => 'Ikke synkronisert · $count';
  @override
  String get syncFailuresHint => 'Prøves igjen ved neste synk';
  @override
  String get syncAbortAuth => 'Passordet ble avvist av serveren';
  @override
  String get syncAbortMissingPassword => 'Ingen passord lagret';
  @override
  String get syncAbortOffline => 'Serveren kan ikke nås';
  @override
  String get syncAbortRemoteMissing => 'Mappen på serveren er borte';
  @override
  String get syncAbortUnsupported => 'Serveren virker ikke lenger som WebDAV';
  @override
  String get syncAbortFailed => 'Synk mislyktes';
  @override
  String get syncAbortNotConfirmed => 'Synk avbrutt';
  @override
  String get syncAbortNothingTouched =>
      'Ingen filer ble rørt. Endringene dine blir liggende her '
      'til neste vellykkede synk.';
  @override
  String syncLastSuccess(String when) => 'Siste vellykkede synk $when';
  @override
  String get syncNoSuccessYet => 'Ingen vellykket synk ennå';
  @override
  String get syncUpdatePasswordAction => 'Oppdater passord';
  @override
  String get syncRetryAction => 'Prøv igjen';
  @override
  String get syncOpenSettingsAction => 'Innstillinger';
  @override
  String get syncCloseAction => 'Lukk';
  @override
  String get syncDoneSnack => 'Synkronisert';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synkronisert · 1 fil slettet et annet sted ligger i '
            'papirkorgen'
      : 'Synkronisert · $count filer slettet et annet sted ligger '
            'i papirkorgen';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synkronisert · 1 konflikt å løse'
      : 'Synkronisert · $count konflikter å løse';
  @override
  String get syncShowAction => 'Vis';
  @override
  String get syncConflictTitle => 'Løs konflikt';
  @override
  String get syncConflictLegend =>
      'Linjer merket − er fra serveren, linjer merket + er fra '
      'denne enheten.';
  @override
  String get syncConflictBinary =>
      'Ikke en tekstfil: velg hvilken kopi du vil beholde.';
  @override
  String get syncConflictKeepNote =>
      'Kopien du ikke beholder, blir liggende i historikken til '
      'notatet.';
  @override
  String get syncKeepLocal => 'Behold denne enhetens';
  @override
  String get syncKeepRemote => 'Behold serverens';
  @override
  String get syncConflictIdentical => 'De to versjonene er identiske';
  @override
  String get syncConflictLoadFailed => 'Kunne ikke lese begge versjonene';
  @override
  String get syncResolveFailed => 'Kunne ikke løse konflikten';
  @override
  String get syncResolved => 'Konflikten er løst';
  @override
  String get syncSectionWhen => 'Når det skal synkroniseres';
  @override
  String get syncAutoTitle => 'Automatisk';
  @override
  String get syncAutoSubtitle =>
      'Etter endringer, ved åpning og med jevne mellomrom';
  @override
  String get syncIntervalTitle => 'Intervall for serversjekk';
  @override
  String get syncIntervalSubtitle => 'Bare mens appen er åpen';
  @override
  String get syncIntervalDialogBody =>
      'For å se endringer gjort på andre enheter mens appen er åpen. Med '
      '«Aldri» bare etter endringer og ved åpning.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minutt' : '$count minutter';
  @override
  String get syncIntervalNever => 'Aldri';
  @override
  String get syncWifiOnlyTitle => 'Bare på Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'På mobildata synkroniseres det bare manuelt';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 endring venter' : '$count endringer venter';
  @override
  String syncRetryIn(String wait) => 'nytt forsøk om $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Venter på Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Venter på tilkobling';
  @override
  String get syncMobileDataHint => '«Synkroniser nå» bruker likevel mobildata.';
  @override
  String get syncQueueKeptHint =>
      'Endringene blir liggende her, også om du lukker appen, og sendes av '
      'seg selv når serveren svarer.';
  @override
  String get syncAutoPaused => 'Automatisk synk satt på pause';
  @override
  String get syncPausedAuthHint =>
      'Den fortsetter når du oppdaterer passordet eller synkroniserer '
      'manuelt.';
  @override
  String get syncPausedServerHint =>
      'Den fortsetter når du retter adressen eller synkroniserer manuelt.';
  @override
  String get syncPausedConfirmHint =>
      '«Synkroniser nå» viser hva som ville blitt fjernet, og spør først.';
  @override
  String get syncNeedsConfirmation => 'Venter på bekreftelsen din';
  @override
  String get syncMergeIntro =>
      'Endringer som ikke overlapper, er allerede flettet; velg hva du vil '
      'beholde der de overlapper.';
  @override
  String get syncMergeClean =>
      'De to versjonene flettes av seg selv: ingenting overlapper.';
  @override
  String get syncMergeNoBase =>
      'Ingen felles versjon å flette på, så hele filen må velges.';
  @override
  String syncMergeOverlap(int index, int total) => 'Overlapp $index av $total';
  @override
  String get syncMergeFromLocal => 'Fra denne enheten';
  @override
  String get syncMergeFromRemote => 'Fra serveren';
  @override
  String get syncMergeRemovedLines => 'Linjer fjernet';
  @override
  String get syncMergeKeepLocal => 'Mine';
  @override
  String get syncMergeKeepRemote => 'Serverens';
  @override
  String get syncMergeKeepBoth => 'Begge';
  @override
  String get syncMergeSave => 'Lagre flettingen';
  @override
  String get syncMergeKeepWhole => 'Eller behold én hel kopi';
}
