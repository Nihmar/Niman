// The Danish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class DanishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januar',
    'februar',
    'marts',
    'april',
    'maj',
    'juni',
    'juli',
    'august',
    'september',
    'oktober',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mar',
    'apr',
    'maj',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
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
  String get trashTitle => 'Affald';
  @override
  String get trashSubtitle =>
      'Sletninger flyttes til .trash/ (fra = permanent sletning)';
  @override
  String get trashAutoEmptyTitle => 'Tøm affald automatisk';
  @override
  String get trashAutoEmptySubtitle =>
      'Ældre sletninger forsvinder for altid, når biblioteket åbnes';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Aldrig'
      : days == 1
      ? '1 dag'
      : '$days dage';
  @override
  String get debugLogsTitle => 'Fejlfinding-logs';
  @override
  String get debugLogsSubtitle =>
      'Logg appens begivenheder i en buffer i hukommelsen';
  @override
  String get lineNumbersTitle => 'Linjenumre';
  @override
  String get lineNumbersSubtitle =>
      'Vis kolonnen med linjenumre i notateditoren';
  @override
  String get keyboardOnOpenTitle => 'Tastatur ved åbning';
  @override
  String get keyboardOnOpenSubtitle =>
      'Vis tastaturet, så snart en note åbnes (fra = ved første berøring)';
  @override
  String get editorKindSource => 'Markdown-kilde';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Forhåndsvisning';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Vis den renderede note ved siden af kildeeditoren';
  @override
  String get switchToWysiwygTooltip => 'Skift til WYSIWYG-editoren';
  @override
  String get switchToSourceTooltip => 'Skift til Markdown-kilden';
  @override
  String get wysiwygTooLarge =>
      'Denne note er for stor til WYSIWYG-editoren. Åbn den i '
      'Markdown-kilden.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Udseende';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliotek';
  @override
  String get settingsSectionReminders => 'Påmindelser';
  @override
  String get settingsSectionShortcuts => 'Tastatur';
  @override
  String get keyboardShortcutsTitle => 'Genveje';
  @override
  String get settingsSectionUpdates => 'Opdateringer';
  @override
  String get autoUpdateTitle => 'Automatiske opdateringer';
  @override
  String get autoUpdateSubtitle =>
      'Tjek GitHub Releases ved start og hver 6. time';
  @override
  String get checkForUpdatesTitle => 'Søg efter opdateringer';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version er tilgængelig';
  @override
  String get updateUpToDate => 'Niman er opdateret';
  @override
  String get updateCheckFailed => 'Kunne ikke søge efter opdateringer';
  @override
  String updateSavedTo(Object path) => 'Opdatering gemt i $path';
  @override
  String get updateInstallerStarted => 'Installationsprogrammet er startet';
  @override
  String get settingsSectionDiagnostics => 'Diagnostik';
  @override
  String get settingsSpellCheckTitle => 'Stavekontrol';
  @override
  String get settingsSpellCheckSubtitle =>
      'Understreg fejlstavede ord, mens du skriver.';
  @override
  String get spellCheckDictionaryTitle => 'Ordliste';
  @override
  String get spellCheckDictionarySystem => 'Systemstandard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Vælg ordlister';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Vælg alle de sprog, biblioteket er skrevet på. Et ord består, når '
      'en af de valgte ordlister kender det; uden valg afgør '
      'systemsproget.';
  @override
  String get spellCheckNoDictionaries =>
      'Ingen ordlister fundet på dette system.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Stavekontrol';
  @override
  String get spellCheckTitle => 'Stavning';
  @override
  String get spellCheckEmpty => 'Ingen stavefejl.';
  @override
  String get spellCheckUnavailable =>
      'hunspell er ikke installeret på dette system.';
  @override
  String get spellCheckNoSuggestions => 'Ingen forslag';
  @override
  String spellCheckCount(int count) => '$count at gennemgå';
  @override
  String spellCheckLine(int line) => 'linje $line';
  @override
  String get addWordToDictionary => 'Tilføj til ordbog';

  @override
  String indentWidthValue(int spaces) => '$spaces mellemrum';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Lysstyrke';
  @override
  String get themeBrightnessSubtitle =>
      'Lys, mørk eller det enheden er sat til';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Lys';
  @override
  String get themeBrightnessNight => 'Mørk';
  @override
  String get themePaletteTitle => 'Farvepalette';
  @override
  String get themePaletteSubtitle => 'Farverne i grænsefladen og i noten';
  @override
  String get themePaletteSystem => 'System';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Grænsefladetekstets størrelse';
  @override
  String get uiTextScaleSubtitle =>
      'Træet, fanerne og dialogboksene; oven på systemindstillingen';
  @override
  String get noteTextScaleTitle => 'Notetekstets størrelse';
  @override
  String get noteTextScaleSubtitle =>
      'Editoren og forhåndsvisningen, som altid er enige';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Forhåndsvisningstilstand';
  @override
  String get previewModeSubtitle =>
      'Om forhåndsvisningen deler skærmen med editoren eller erstatter '
      'den';
  @override
  String get previewModeAuto => 'Side ved side';
  @override
  String get previewModeSwitch => 'Hel skærm';
  @override
  String get splitRatioTitle => 'Opdelingens bredde';
  @override
  String get splitRatioSubtitle =>
      'Editors andel, når forhåndsvisningen er side ved side';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Linkformat';
  @override
  String get linkTypeSubtitle => 'Hvad linkknappen i editoren indsætter';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Opret manglende noter i';
  @override
  String get missingNoteLocationRoot => 'Bibliotekets rodmappe';
  @override
  String get missingNoteLocationCurrentFolder => 'Nuværende mappe';
  @override
  String get indentWidthTitle => 'Indrykningens bredde';
  @override
  String get indentWidthSubtitle =>
      'Mellemrum, der tilføjes pr. indrykningsniveau i editoren';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Sprog';
  @override
  String get languageSubtitle => 'Sproget på appens egen tekst';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Tilføj et element';
  @override
  String get listAddTooltip => 'Tilføj et element';
  @override
  String get listEmpty => 'Ingen elementer endnu';
  @override
  String get listDragHandleLabel => 'Omordn element';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Ingen optagelser endnu';
  @override
  String get audioRecord => 'Optag';
  @override
  String get audioStop => 'Stop';
  @override
  String get audioPlay => 'Afspil';
  @override
  String get audioDelete => 'Slet optagelse';
  @override
  String get audioImport => 'Importér en lydfil';
  @override
  String get audioRecording => 'Optager…';
  @override
  String get audioPermissionDenied =>
      'Adgang til mikrofonen nægtet — den er nødvendig for at optage.';
  @override
  String get newAudioNoteTitle => 'Ny stemmenote';
  @override
  String get newAudioNoteDefault => 'Min optagelse';
  @override
  String get showAudioTooltip => 'Vis optagelser';
  @override
  String get audioMessageHint => 'Skriv en note…';
  @override
  String get audioSend => 'Send';
  @override
  String get audioRename => 'Omdøb optagelse';
  @override
  String get audioDescriptionHint => 'Beskriv denne optagelse…';
  @override
  String get audioEditDescription => 'Rediger beskrivelse';
  @override
  String get audioDeleteNote => 'Slet note';
  @override
  String get audioEditNote => 'Rediger note';
  @override
  String get audioPause => 'Pause';
  @override
  String get audioEditTitle => 'Rediger titel';
  @override
  String get audioTitleHint => 'Giv optagelsen en titel…';
  @override
  String audioUntitled(int n) => 'Optagelse $n';
  @override
  String get audioMoreActions => 'Flere handlinger';
  @override
  String get audioDiscardRecording => 'Kassér optagelse';
  @override
  String get audioPauseRecording => 'Sæt optagelsen på pause';
  @override
  String get audioResumeRecording => 'Genoptag optagelsen';
  @override
  String get audioRecordingPaused => 'På pause';
  @override
  String get audioSavingRecording => 'Gemmer…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Kviknote';
  @override
  String get shortcutNewTodo => 'Ny opgave';
  @override
  String get shortcutNewNote => 'Ny note';
  @override
  String get shortcutNewList => 'Ny liste';
  @override
  String get shortcutNewAudio => 'Ny stemmenote';
  @override
  String get shortcutToggleSidebar => 'Vis eller skjul filtræet';
  @override
  String get shortcutEditorSection => 'I editoren';
  @override
  String get shortcutFind => 'Find';
  @override
  String get shortcutReplace => 'Find og erstat';
  @override
  String get shortcutSavingNote =>
      'Retninger gemmes automatisk, så der er ingen genvej til at gemme.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Indlæser…';
  @override
  String get noteStatusSaving => 'Gemmer…';
  @override
  String get noteStatusUnsaved => 'Ikke gemt';
  @override
  String get noteStatusSaved => 'Gemt';
  @override
  String get noteStatusError => 'Fejl';
  @override
  String wordCount(int count) => '$count ord';
  @override
  String get outlineTooltip => 'Oversigt';
  @override
  String get outlineNoHeadings => 'Ingen overskrifter';
  @override
  String get outlineNoTitle => '(ingen titel)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Fed';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'Gennemstregning';
  @override
  String get toolbarSuperscript => 'Hævet';
  @override
  String get toolbarUnderline => 'Understregning';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Kodeblok';
  @override
  String get toolbarImage => 'Indsæt billede';
  @override
  String get toolbarHeading => 'Overskrift';
  @override
  String get toolbarList => 'Liste';
  @override
  String get toolbarOrderedList => 'Nummereret liste';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Indryk';
  @override
  String get toolbarOutdent => 'Udryk';
  @override
  String get headingDialogTitle => 'Overskriftsniveau';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editorværktøjslinje';
  @override
  String get toolbarSettingsHint =>
      'Træk for at omordne; øjet viser eller skjuler en knap.';
  @override
  String get toolbarShowButton => 'Vis';
  @override
  String get toolbarHideButton => 'Skjul';
  @override
  String get toolbarResetOrder => 'Gendan standard';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Vis forhåndsvisning';
  @override
  String get showEditorTooltip => 'Vis editor';
  @override
  String get enterFullScreenTooltip => 'Hel skærm';
  @override
  String get exitFullScreenTooltip => 'Forlad hel skærm';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(rå HTML-tabel)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Søg i noter';
  @override
  String get searchModeWords => 'Ord';
  @override
  String get searchModeContains => 'Indeholder';
  @override
  String get searchEmptyHint =>
      'Skriv for at søge i biblioteket, eller nøgle = værdi for at filtrere '
      'på frontmatter';
  @override
  String get searchTooShortHint => 'Skriv mindst 2 tegn';
  @override
  String get searchNoMatches => 'Ingen resultater';
  @override
  String get searchLoadMore => 'Vis mere';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Erstat…';
  @override
  String get replaceInNoteAction => 'Erstat i denne note…';
  @override
  String get replaceInThisNote => 'Erstat i denne note';
  @override
  String get replaceWithLabel => 'Erstat med';
  @override
  String get replaceCaseSensitive => 'Store/små bogstaver';
  @override
  String get replaceWholeWordsHint =>
      'kun præcise helt-ord-matchninger erstattes';
  @override
  String get replaceConfirm => 'Erstat';
  @override
  String get replaceCancel => 'Luk';
  @override
  String get replaceUnavailable => 'Erstatning er ikke tilgængelig lige nu';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Find i note';
  @override
  String get editorFindHint => 'Find';
  @override
  String get editorReplaceHint => 'Erstat';
  @override
  String get editorFindCaseTooltip => 'Store/små bogstaver';
  @override
  String get editorFindPreviousTooltip => 'Forrige match';
  @override
  String get editorFindNextTooltip => 'Næste match';
  @override
  String get editorFindCloseTooltip => 'Luk søgning';
  @override
  String get editorFindReplaceModeTooltip => 'Erstatningstilstand';
  @override
  String get editorReplaceOneTooltip => 'Erstat denne match';
  @override
  String get editorReplaceAllTooltip => 'Erstat alle matcher';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tags';
  @override
  String get tagsTitle => 'Tags';
  @override
  String get tagsEmpty =>
      'Ingen tags endnu — tilføj en #tag eller tags i frontmatter';
  @override
  String get tagsBackTooltip => 'Tilbage til søgning';
  @override
  String get tagsNotesEmpty => 'Ingen noter med denne tag';
  @override
  String tagsNotesCapped(int limit) =>
      'Kun de første $limit vises — søg taggen for at indsnævre';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Linket blev ikke fundet';
  @override
  String get headingNotFoundTitle => 'Overskriften blev ikke fundet';
  @override
  String get ambiguousLinkTitle => 'Flere noter matcher';
  @override
  String get openLinkFailed => 'Kunne ikke åbne linket';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Noten findes ikke';
  @override
  String missingNoteDialogBody(String path) => 'Opret „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Mappen „$folder“ findes ikke';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Åbne';
  @override
  String get todoDone => 'Færdig';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Alle datoer';
  @override
  String get todoFilter => 'Filtrer';
  @override
  String get todoNoTokens => 'Ingen token i denne liste';
  @override
  String get todoCountOpen => 'åbne';
  @override
  String get todoCountDone => 'færdige';
  @override
  String get todoEmptyOpen => 'Ingen åbne opgaver endnu';
  @override
  String get todoEmptyDone => 'Intet fuldført endnu';
  @override
  String get todoEmptyFiltered => 'Ingen opgaver matcher';
  @override
  String get todoTitle => 'At gøre';
  @override
  String get todoAddTooltip => 'Tilføj opgave';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt-formatet';
  @override
  String get todoHelpTooltip => 'Formatinfo';
  @override
  String get todoHelpIntro =>
      'Dine opgaver er én almindelig tekstfil, én opgave pr. linje. Niman '
      'skriver syntaksen for dig, men intet er skjult: du kan redigere '
      'filen i enhver editor, og Niman læser den igen.';
  @override
  String get todoHelpFilesTitle => 'De to filer';
  @override
  String get todoHelpFilesBody =>
      'Åbne opgaver ligger i todo.txt i roden af biblioteket. Fuldfør '
      'én, og linjen flyttes til done.txt, så todo.txt holdes kort. Hvis '
      'en fuldført linje havner tilbage i todo.txt, arkiverer Niman den '
      'næste gang, den læser filerne.';
  @override
  String get todoHelpLineTitle => 'En linjes anatomi';
  @override
  String get todoHelpLineBody =>
      'Alt før beskrivelsen er valgfrit og skal komme i denne '
      'rækkefølge:';
  @override
  String get todoHelpDoneBody =>
      'Markerer opgaven som færdig. Niman tilføjer den, når du afkrydter '
      'afkrydsningsfeltet.';
  @override
  String get todoHelpPriority => '(A) til (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A er den højeste. Vises som badge i listen.';
  @override
  String get todoHelpDatesBody =>
      'Fuldførelsesdato, derefter opretningstidspunkt. Med kun én dato er '
      'det opretningstidspunktet, medmindre linjen starter med x.';
  @override
  String get todoHelpTokensTitle => 'Projekter, kontekster og tags';
  @override
  String get todoHelpTokensBody =>
      'Overalt i beskrivelsen bliver et ord med ét af disse præfikser en '
      'chip, du kan filtrere på. Intet er foruddefineret: en token '
      'eksisterer, så snart du skriver den.';
  @override
  String get todoHelpProjectBody =>
      'Hvad opgaven er en del af, for eksempel +køkken eller +afhandling.';
  @override
  String get todoHelpContextBody =>
      'Hvor eller hvordan du gør den, for eksempel @hjemme eller '
      '@samtaler.';
  @override
  String get todoHelpHashtagBody =>
      'Et frit label, til alt det andre to ikke dækker.';
  @override
  String get todoHelpTagsTitle => 'Datoer og påmindelser';
  @override
  String get todoHelpTagsBody =>
      'Disse er nøgle:værdi-tags. Niman skriver dem fra '
      'opgaveboksen og læser dem, hvor de ender på linjen.';
  @override
  String get todoHelpDueBody =>
      'Fristen. Driver det farvede badge og datofiltrene.';
  @override
  String get todoHelpRemBody =>
      'Når en besked skal sendes, i din lokale tid. Den udløses med '
      'slukket skærm og lukket app.';
  @override
  String get todoHelpRemDesktop =>
      'På desktop skal Niman køre, når tiden kommer: påmindelsen vises, '
      'mens appen er åben, og intet udløses, når den er lukket.';
  @override
  String get todoHelpOtherBody =>
      'Bevaret nøjagtigt, som skrevet, så tags fra andre todo.txt-app '
      'overlever en tur rundt. Niman reagerer ikke på dem, rec: included: '
      'en gentagende opgave gentages endnu ikke.';
  @override
  String get todoHelpEditTitle => 'Redigering uden for Niman';
  @override
  String get todoHelpEditBody =>
      'En opgave, du ikke har rørt, skrives tilbage byte for byte, '
      'mærkelige mellemrum medregnet. Rediger en linje, og Niman omskriver '
      'netop den linje i sin kanoniske form og efterlader resten af filen.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Tilføj opgave';
  @override
  String get todoEditTitle => 'Rediger opgave';
  @override
  String get todoDescriptionHint => 'Beskrivelse';
  @override
  String get todoCancel => 'Annuller';
  @override
  String get todoSave => 'Gem';
  @override
  String get todoEditAction => 'Rediger';
  @override
  String get todoDeleteAction => 'Slet';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Udløbet';
  @override
  String get todoDueToday => 'I dag';
  @override
  String get todoDueNext7 => 'Næste 7 dage';
  @override
  String get todoDueNoDate => 'Ingen dato';
  @override
  String get todoRowDue => 'Frist';
  @override
  String get todoRowDueToday => 'Frist i dag';
  @override
  String get todoSortTooltip => 'Sortér';
  @override
  String get todoSortDue => 'Fristdato';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Opretningstidspunkt';

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
  String get todoNoReminder => 'Ingen påmindelse';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Opgavepåmindelser';
  @override
  String get todoReminderChannelDescription =>
      'Planlagte varsel for opgaver med påmindelsestid.';
  @override
  String get todoReminderBody => 'Todo-påmindelse';
  @override
  String get todoReminderFallbackTitle => 'Opgavepåmindelse';
  @override
  String get todoReminderBlocked =>
      'Varsler er slukket, så påmindelser vises ikke.';
  @override
  String get todoReminderBattery =>
      'Batterioptimering er slået til for Niman. Systemet kan sætte appen '
      'i dvale og droppe ventende påmindelser.';
  @override
  String get todoReminderInexact =>
      'Denne enhed tillader ikke eksakte alarmer, så en påmindelse kan '
      'ankomme flere minutter sent med slukket skærm.';
  @override
  String get reminderShowTokensTitle => 'Tags i påmindelsesvarsler';
  @override
  String get reminderShowTokensSubtitle =>
      'Behold +projekt, @kontekst og #tag i varslsteksten. Fra viser kun '
      'den opgave, du skrev.';
  @override
  String get todoReminderFixAction => 'Åbn indstillinger';
  @override
  String get todoReminderDismissAction => 'Afvis';
  @override
  String get todoReminderDue => 'Frist';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Annuller';
  @override
  String get actionCreate => 'Opret';
  @override
  String get actionNew => 'Ny';
  @override
  String get actionSave => 'Gem';
  @override
  String get actionClear => 'Ryd';
  @override
  String get actionChoose => 'Vælg';
  @override
  String get actionDelete => 'Slet';
  @override
  String get actionRename => 'Omdøb';
  @override
  String get actionMove => 'Flyt';
  @override
  String get saveAndClose => 'Gem og luk';
  @override
  String get closeUnsavedTitle => 'Ugemte ændringer';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” har ændringer, der ikke er gemt endnu. '
          'Gem dem, før du lukker?';
    }
    return '${names.length} noter har ændringer, der ikke er gemt endnu. '
        'Gem dem, før du lukker?';
  }

  @override
  String get closeSaveFailed => 'Kunne ikke gemme; stadig åben.';
  @override
  String get actionRestore => 'Gendan';
  @override
  String get actionEmpty => 'Ryd';

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
  String get windowRestoreTooltip => 'Gendan';
  @override
  String get windowCloseTooltip => 'Luk';
  @override
  String get tabFiles => 'Filer';
  @override
  String get tabSearch => 'Søg';
  @override
  String get tabSettings => 'Indstillinger';
  @override
  String get quickNoteTitle => 'Kviknote';
  @override
  String get treeEmpty => 'Ingen noter endnu';
  @override
  String get selectANote => 'Vælg en note';
  @override
  String get showListTooltip => 'Vis liste';
  @override
  String get editRawTooltip => 'Rediger rå';
  @override
  String get sortAscTooltip => 'Sortér A-Æ';
  @override
  String get sortDescTooltip => 'Sortér Æ-A';
  @override
  String get newNoteTitle => 'Ny note';
  @override
  String get newItemTooltip => 'Ny';
  @override
  String get closeMenuTooltip => 'Luk';
  @override
  String get newFolderTitle => 'Ny mappe';
  @override
  String get newNoteHere => 'Ny note her';
  @override
  String get newFolderHere => 'Ny mappe her';
  @override
  String get newListNoteTitle => 'Ny listenote';
  @override
  String get newListNoteDefault => 'Min liste';
  @override
  String get setAsQuickNote => 'Sæt som kviknote';
  @override
  String get currentQuickNote => 'Aktuel kviknote';
  @override
  String get pinnedSection => 'Fastgjort';
  @override
  String pinnedSectionCount(int count) => 'Fastgjort · $count';
  @override
  String get templateFolderTitle => 'Skabelonmappe';
  @override
  String get newFromTemplateTitle => 'Ny fra skabelon';
  @override
  String get newFromTemplateHere => 'Ny fra skabelon her';
  @override
  String get templateFormTitle => 'Udfyld skabelonen';
  @override
  String get templateFormBacklink => 'Linket fra';
  @override
  String get templateFormNoNote => 'Ingen note';
  @override
  String get templateFormPickNote => 'Vælg noten';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Skabelon-pladsholdere';
  @override
  String get templateHelpIntro =>
      'En skabelon er en almindelig note med huller i. At oprette en note '
      'fra den kopierer teksten og fylder hullerne.';
  @override
  String get templateHelpUnknown =>
      'En pladsholder Niman ikke kender beholdes nøjagtigt, som skrevet, '
      'så en stavefejl ses i noten i stedet for at stille spise en linje.';
  @override
  String get templateHelpValuesTitle => 'Værdier';
  @override
  String get templateHelpTitleBody => 'Det navn, noten oprettes med.';
  @override
  String get templateHelpDateBody =>
      'I dag, og klokken nu. Begge tager et format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Dato og klokke sammen.';
  @override
  String get templateHelpUuidBody =>
      'En ny identifikator, en anden ved hver forekomst.';
  @override
  String get templateHelpCounterBody =>
      'Et tal, der tæller op pr. navn, bevarer over genstarter: den første '
      'note skriver 1, den næste 2. Samme navn i én note skriver samme '
      'tal; kombinér med |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Sætter markøren her, når noten oprettes; markøren skrives ikke '
      'selv. Første markør vinder, ingen filtre, kun nye noter — og '
      'tastaturet åbnes også med autofokus fra.';
  @override
  String get templateHelpDatesTitle => 'At skrive en dato';
  @override
  String get templateHelpDatesBody =>
      'Disse står for dele af datoen i et format. Alt andet er '
      'bogstaveligt, og tekst i enkelte anførselstegn er også '
      'bogstaveligt. Måned- og ugedagsnavn følger appens sprog.';
  @override
  String get templateHelpYear => 'året: 2026, 26';
  @override
  String get templateHelpMonth => 'måneden: 03, 3, marts, mar';
  @override
  String get templateHelpDay => 'dagen: 09, 9, mandag, man';
  @override
  String get templateHelpTime => 'timer, minutter, sekunder';
  @override
  String get templateHelpWeek => 'ISO-ugen og kvartalet: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtre';
  @override
  String get templateHelpFiltersBody =>
      'En værdi kan efterfølges af filtre, anvendt fra venstre mod højre.';
  @override
  String get templateHelpCaseBody =>
      'Store bogstaver, små bogstaver, og den første bogstav i hvert ord '
      '— et ord, du selv har versalforset, efterlades.';
  @override
  String get templateHelpSlugBody =>
      'Linkformen af teksten, til at bygge et wikilink.';
  @override
  String get templateHelpPadBody =>
      'Klip enderne; udfyld med nuller til en bredde; brug et alternativ, '
      'når værdien er tom.';
  @override
  String get templateHelpShiftBody =>
      'Flyt en dato med dage, uger, måneder eller år — næste uges '
      'forelæsning, sidste måneds fil.';
  @override
  String get templateHelpSnapBody =>
      'Placér en dato i starten eller slutningen af ugen, måneden eller '
      'året.';
  @override
  String get templateHelpAskTitle => 'At spørge dig noget';
  @override
  String get templateHelpAskBody =>
      'En formular vises, inden noten oprettes, én boks pr. spørgsmål — og '
      'én til backlink, når skabelonen vil have en. Den samme etiket to '
      'gange er ét spørgsmål, og svaret fylder alle forekomster — mappen '
      'og filnavnet medregnet.';
  @override
  String get templateHelpAskFieldBody =>
      'En boks at skrive i; teksten efter det andet kolontegn er, den '
      'starter med.';
  @override
  String get templateHelpChoiceBody =>
      'Et valg fra en liste, adskilt med komma.';
  @override
  String get templateHelpWhereTitle => 'Hvor noten havner';
  @override
  String get templateHelpWhereBody =>
      'Disse er ikke tekst: de er instruktioner, og de lever i en niman: '
      'blok i skabelonens egen frontmatter. Blokken føres ud og fjernes '
      'derefter, så den vises aldrig i noten. Værdierne kan indeholde '
      'pladsholdere.';
  @override
  String get templateHelpFolderBody =>
      'Mappen, noten oprettes i, oprettes, hvis den ikke findes. Uden den '
      'havner noten, hvor du var.';
  @override
  String get templateHelpFilenameBody =>
      'Hvad noten hedder. En skabelon, der siger dette, spurges ikke om '
      'et navn.';
  @override
  String get templateHelpAppendBody =>
      'Tilføj til noten, hvis den allerede er der, i stedet for at lave '
      'en anden. Det er det, der forvandler en måned af møder til én fil.';
  @override
  String get templateHelpOpenBody =>
      'Hvad der sker, når noten findes: editoren (standard), '
      'forhåndsvisningen, eller intet — noten arkiveres, og du bliver, '
      'hvor du var.';
  @override
  String get templateHelpAroundTitle => 'Hvor den kom fra';
  @override
  String get templateHelpParentBody =>
      'En note, du vælger i formularen, der foreslår den på skærmen; skriv '
      '[[{{parent}}]] for et link tilbage.';
  @override
  String get templateHelpFolderValueBody => 'Mappen, noten havnede i.';
  @override
  String get templateHelpClipboardBody =>
      'Hvad der ligger på udklippet, og editorvalget, når noten startedes '
      'fra en.';
  @override
  String get templateHelpIncludeTitle => 'At genbruge et stykke';
  @override
  String get templateHelpIncludeBody =>
      'Indsætter en anden skabelon, så ti skabeloner kan dele én '
      'tjekliste. Den søges først i skabelonmappen, og .md kan forlades. '
      'Dens egne spørgsmål deltager i samme formular.';
  @override
  String get templateHelpExampleTitle => 'Alt sammen';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ingen skabelon “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” inkluderer sig selv';
  @override
  String includeTooDeep(String path) => '⚠ “$path” er for dybt nystet';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter blev ikke læst: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter for “$template” blev ikke læst, så mappen og filnavnet '
      'gjorde intet: $reason';
  @override
  String get templatePickerTitle => 'Vælg en skabelon';
  @override
  String templatePickerEmpty(String folder) =>
      'Ingen skabeloner endnu. Læg en note i $folder/, og den bliver én.';

  // Tree actions.
  @override
  String get actionPin => 'Fastgør';
  @override
  String get actionUnpin => 'Løs';
  @override
  String get pinToWidget => 'Fastgør til startskærmswidget';
  @override
  String get pinnedForWidget =>
      'Fastgjort: placer nu Notits-widgeten på startskærmen';
  @override
  String get pinWidgetUnavailable =>
      'Startskærmswidgets er tilgængelige på Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Vis i filhåndtering';
  @override
  String get openInDefaultApp => 'Åbn i standardappen';
  @override
  String get openFileMissing => 'Denne notes fil findes ikke på disken';
  @override
  String get openFileFailed => 'Noten kunne ikke åbnes uden for Niman';

  @override
  String get movedToTrash => 'Flyttet til affald';
  @override
  String get deletedMessage => 'Slettet';
  @override
  String deleteToTrashConfirm(String name) => '$name flyttes til .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name slettes permanent';
  @override
  String get chooseDestination => 'Vælg destination';
  @override
  String get libraryRoot => 'Bibliotekets rod';
  @override
  String moveTitle(String name) => 'Flyt $name';
  @override
  String headingLevelLabel(int level) => 'Overskrift $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ingen kviknote endnu. Vælg en eksisterende note eller opret en '
      'ny — kviknoten åbnes her.';
  @override
  String get quickNoteChooseAction => 'Vælg en note…';
  @override
  String get quickNoteCreateAction => 'Opret en ny note…';
  @override
  String get quickNoteNewTitle => 'Ny kviknote';
  @override
  String get quickNotePickerTitle => 'Vælg kviknote';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Ny mappe';
  @override
  String get folderPickerEmpty => 'Ingen mapper endnu';
  @override
  String get listFolderTitle => 'Listemappe';
  @override
  String get attachmentsFolderTitle => 'Mappe til vedhæftninger';

  // Trash (M1).
  @override
  String get trashEmpty => 'Affaldet er tomt';
  @override
  String get trashEmptyAction => 'Ryd affald';
  @override
  String get trashEmptyConfirm =>
      'Dette sletter alt i affaldsmappen permanent, inklusive elementer '
      'Niman ikke lagde dertil.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name slettes permanent (ingen gendannelse)';
  @override
  String get trashDeletePermanently => 'Slet permanent';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Åbn en mappe med Markdown-noter som bibliotek';
  @override
  String get openLibraryExisting => 'Åbn eksisterende';
  @override
  String get openLibraryCreate => 'Opret ny';
  @override
  String get openLibraryCreateTitle => 'Opret nyt bibliotek';
  @override
  String get openLibraryFolderName => 'Mappenavn';
  @override
  String get openLibraryChooseFolder => 'Vælg biblioteksmappen';
  @override
  String get openLibraryChooseParent => 'Vælg mappen, biblioteket oprettes i';
  @override
  String get openLibraryUnsupported =>
      'Den mappe understøttes ikke. Vælg en mappe på enhedens lagring.';
  @override
  String indexingCount(int done, int total) => '$done af $total noter';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Dine biblioteker';
  @override
  String get libraryUnreachable => 'Unåelig';
  @override
  String get libraryOpenedToday => 'Åbnet i dag';
  @override
  String get libraryOpenedYesterday => 'Åbnet i går';
  @override
  String libraryOpenedDaysAgo(int days) => 'Åbnet for $days dage siden';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Åbnet ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Åben nu';
  @override
  String get switchLibraryTitle => 'Skift bibliotek';
  @override
  String get libraryForget => 'Glem';
  @override
  String libraryForgetTitle(String name) => 'Glemme “$name”?';
  @override
  String get libraryForgetExplained =>
      'Den forsvinder fra denne liste. Mappen, noter og '
      'biblioteksindstillinger i den røres ikke, og at åbne den igen '
      'bringer den tilbage.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Giv filadgang';
  @override
  String get storageAccessNeeded =>
      'Niman kan ikke læse dine noter uden “Adgang til alle filer”. Giv '
      'den for at åbne et bibliotek.';
  @override
  String get storageAccessExplained =>
      'Niman læser dine noter som almindelige filer, så Android skal give '
      'den adgang til alle filer. Intet uploades, og kun den '
      'biblioteksmappe, du vælger, læses.';
  @override
  String folderAccessDenied(Object error) =>
      'Systemet gav ikke adgang til mappen: $error';
  @override
  String folderPickFailed(Object error) => 'Kunne ikke vælge en mappe: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Indstillinger';
  @override
  String get libraryPathTitle => 'Bibliotekssti';
  @override
  String get reindexTitle => 'Indeksér om nu';
  @override
  String get reindexDone => 'Omindexering fuldført';
  @override
  String get closeLibraryTitle => 'Luk biblioteket';
  @override
  String get exportLogTitle => 'Eksportér fejlfinding-log';
  @override
  String get exportLogSubtitle =>
      'Gem de loggede begivenheder til en fil, du vælger';
  @override
  String get exportLogEmpty => 'Fejlfinding-logbufferen er tom';
  @override
  String get quickNoteUnset => 'Ikke sat endnu';
  @override
  String exportLogDone(Object target) =>
      'Fejlfinding-log eksporteret til $target';
  @override
  String exportLogFailed(Object error) => 'Eksport mislykkedes: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ingen præcis helt-ord-match på “$term” blev fundet';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Erstattet $occurrences forekomster af “$term” i $notes noter';
  @override
  String replaceSkipped(int skipped) => ' ($skipped åbne noter sprunget over)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ingen præcis helt-ord-match på “$term” '
      '${only == null ? 'blev fundet' : 'fundet i $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Om';
  @override
  String get versionTitle => 'Version';
  @override
  String get changelogTitle => 'Ændringslog';
  @override
  String get changelogEmpty => 'Ingen ændringslogposter tilgængelige';
  @override
  String changelogWhatsNew(String version) => 'Ny i version $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historik';
  @override
  String get noteMenuTooltip => 'Notehandlinger';
  @override
  String get historyCurrentVersion => 'Aktuel version';
  @override
  String get historyCurrentSubtitle => 'Noten, som den er nu';
  @override
  String get historyToday => 'I dag';
  @override
  String get historyYesterday => 'I går';
  @override
  String get historyReasonSession => 'før redigering';
  @override
  String get historyReasonInterval => 'under redigering';
  @override
  String get historyReasonRestore => 'før gendannelse';
  @override
  String get historyReasonSync => 'før synk';
  @override
  String get historyReasonReplace => 'før erstatning';
  @override
  String get historyReasonUnknown => 'genfundet';
  @override
  String get historySyncBase => 'synkbase';
  @override
  String get historyEmpty =>
      'Ingen versioner endnu. Niman gemmer en, når du begynder at redigere '
      'noten, og derefter højst én med få minutters mellemrum, mens du '
      'skriver.';
  @override
  String historyKept(int kept, int limit) => '$kept af $limit versioner gemt';
  @override
  String get historyBaseKept => 'Synkbasen bevares ud over grænsen.';
  @override
  String get historyOff =>
      'Historik er slået fra for dette bibliotek (Indstillinger, Bibliotek).';
  @override
  String get historyLoadFailed => 'Kunne ikke læse historikken';
  @override
  String get historyCompareSubtitle => 'Sammenlignet med den aktuelle version';
  @override
  String get historyTabChanges => 'Ændringer';
  @override
  String get historyTabVersion => 'Version';
  @override
  String get historyNoChanges => 'Samme tekst som den aktuelle version.';
  @override
  String get historyRestoreAction => 'Gendan denne version';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Gendan versionen fra $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Den aktuelle tekst gemmes først i historikken, så du altid kan gå '
      'tilbage.';
  @override
  String get historyRestoreConfirm => 'Gendan';
  @override
  String historyRestored(String when) => 'Versionen fra $when er gendannet';
  @override
  String get historyRestoreFailed => 'Kunne ikke gendanne versionen';
  @override
  String get actionUndo => 'Fortryd';
  @override
  String diffLineRange(int start, int end) => 'Linjer $start–$end';
  @override
  String diffLineSingle(int line) => 'Linje $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 uændret linje' : '$count uændrede linjer';
  @override
  String get historyTakeHunk => 'Gendan her';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Gendan 1 ændring' : 'Gendan $count ændringer';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'De valgte ændringer vender tilbage til denne versions tekst. Noten som '
      'den er nu gemmes først som en version, så du kan fortryde det.';
  @override
  String get historyNoteChangedReloaded =>
      'Noten blev ændret, mens du var her — sammenligningen er opdateret.';
  @override
  String get historyVersionsTitle => 'Versioner, der gemmes';
  @override
  String get historyVersionsSubtitle => 'Pr. note, i .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Ingen' : '$count';
  @override
  String get historyIntervalTitle => 'Ny version højst hver';
  @override
  String get historyIntervalSubtitle =>
      'Mens du skriver; når du begynder at redigere en note, gemmes der '
      'altid én';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transskription';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Ingen';
  @override
  String get transcriptionLanguageTitle => 'Sprog';
  @override
  String get transcriptionLanguageSubtitle =>
      'Sproget, der tales i dine optagelser. Det er mere præcist at angive '
      'det end at lade det genkende.';
  @override
  String transcriptionLanguageApp(String language) => 'Som appen ($language)';
  @override
  String get transcriptionLanguageDetect => 'Genkend automatisk';
  @override
  String get transcriptionModelsTitle => 'Transskriptionsmodeller';
  @override
  String transcriptionModelsUsed(String size) => '$size brugt';
  @override
  String get transcriptionModelsInstalled => 'Downloadet';
  @override
  String get transcriptionModelsDownloading => 'Downloader';
  @override
  String get transcriptionModelsAvailable => 'Tilgængelige';
  @override
  String get transcriptionModelsFooter =>
      'Modellerne ligger i appens lager på denne enhed. De kopieres ikke til '
      'biblioteket og synkroniseres ikke.';
  @override
  String get transcriptionModelDefault => 'Standard';
  @override
  String get transcriptionModelSlow => 'Langsom';
  @override
  String get transcriptionModelHintTiny => 'Hurtigst, mindst præcis';
  @override
  String get transcriptionModelHintBase =>
      'God balance mellem hastighed og præcision';
  @override
  String get transcriptionModelHintSmall => 'Mere præcis, cirka 3× langsommere';
  @override
  String get transcriptionModelHintMedium =>
      'Meget præcis, langsom på en telefon';
  @override
  String get transcriptionModelHintLarge =>
      'Mest præcis, kræver meget hukommelse';
  @override
  String get transcriptionModelDownload => 'Download';
  @override
  String transcriptionModelDeleteTitle(String model) => 'Slet modellen $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Det frigør $size. Du kan downloade modellen igen senere.';
  @override
  String get transcriptionModelFailed =>
      'Download mislykkedes. Tjek forbindelsen, og prøv igen.';
  @override
  String get actionRetry => 'Prøv igen';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Forbindelsen blev afbrudt, prøver igen…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Sat på pause ved $progress';
  @override
  String get actionResume => 'Genoptag';
  @override
  String get audioTranscribe => 'Transskriber';
  @override
  String get audioTranscribeUnsupported => 'Kun WAV-optagelser på denne enhed';
  @override
  String get transcriptionQueued => 'I kø';
  @override
  String get transcriptionPreparing => 'Forbereder lyden…';
  @override
  String transcriptionRunning(int percent) => 'Transskriberer… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Downloader $model · $percent %';
  @override
  String get transcriptionSaved => 'Transskriptionen er føjet til beskrivelsen';
  @override
  String get transcriptionNoSpeech =>
      'Der blev ikke genkendt tale i denne optagelse';
  @override
  String get transcriptionFailed => 'Transskriptionen mislykkedes';
  @override
  String get transcriptionPickModelTitle => 'Vælg en model';
  @override
  String get transcriptionPickModelBody =>
      'Transskriptionen sker på denne enhed, og optagelsen uploades aldrig. '
      'Modellen downloades kun én gang.';
  @override
  String get transcriptionPickModelAction => 'Download og transskriber';
  @override
  String get transcriptionModelRecommended => 'Anbefalet';
  @override
  String get transcriptionExistingTitle =>
      'Optagelsen har allerede en beskrivelse';
  @override
  String get transcriptionExistingBody =>
      'Erstat den med transskriptionen, eller tilføj transskriptionen '
      'nedenunder?';
  @override
  String get transcriptionAppend => 'Tilføj nedenunder';
  @override
  String get transcriptionReplace => 'Erstat';
  @override
  String get settingsSectionSync => 'Synkronisering';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Ikke sat op for dette bibliotek';
  @override
  String get syncNeverSynced => 'Aldrig synkroniseret';
  @override
  String syncLastSynced(String when) => 'Synkroniseret $when';
  @override
  String get syncRunning => 'Synkroniserer…';
  @override
  String syncScreenSubtitle(String library) => 'Bibliotek $library';
  @override
  String get syncUrlLabel => 'Mappens adresse';
  @override
  String get syncUrlHint =>
      'Mappen skal findes. Kopiér adressen, som serveren viser '
      'den.';
  @override
  String get syncHttpWarning =>
      'Ukrypteret forbindelse: fint over en VPN eller på dit '
      'lokale netværk.';
  @override
  String get syncUserLabel => 'Bruger';
  @override
  String get syncUserHint =>
      'Lad feltet stå tomt, hvis serveren ikke beder om login.';
  @override
  String get syncPasswordLabel => 'Adgangskode';
  @override
  String get syncPasswordHint =>
      'Gemmes i denne enheds nøglering, aldrig i bibliotekets '
      'filer.';
  @override
  String get syncPasswordKeepHint =>
      'Lad feltet stå tomt for at beholde den gemte adgangskode.';
  @override
  String get syncShowPassword => 'Vis adgangskode';
  @override
  String get syncHidePassword => 'Skjul adgangskode';
  @override
  String get syncTestAction => 'Test forbindelsen';
  @override
  String get syncTesting => 'Tester…';
  @override
  String get syncRetargetWarning =>
      'Med en ny adresse eller bruger starter næste '
      'synkronisering forfra som en første synkronisering.';
  @override
  String get syncTestOk => 'Forbindelsen virker';
  @override
  String get syncModeFull => 'Fuld tilstand';
  @override
  String get syncModeCompatible => 'Kompatibel tilstand';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Læse, skrive og slette';
  @override
  String get syncCapEtags => 'Filfingeraftryk (ETags)';
  @override
  String get syncCapNoEtags => 'Ingen filfingeraftryk (ETags)';
  @override
  String get syncCapNoEtagsDetail =>
      'Sammenligner størrelse og dato; henter igen ved tvivl';
  @override
  String get syncCapGuarded => 'Beskyttede skrivninger';
  @override
  String get syncCapUnguarded => 'Ubeskyttede skrivninger';
  @override
  String get syncCapUnguardedDetail =>
      'Tjekker filen på serveren lige før der skrives';
  @override
  String get syncCapMove => 'Omdøber uden at uploade igen';
  @override
  String get syncCapNoMove => 'Ingen omdøbning på serveren';
  @override
  String get syncCapNoMoveDetail =>
      'En omdøbning bliver til en sletning og en ny upload';
  @override
  String get syncCompatibleNote =>
      'I kompatibel tilstand virker synkroniseringen på samme '
      'måde, bare med lidt flere forespørgsler.';
  @override
  String get syncTestInvalidUrl => 'Ikke en gyldig adresse';
  @override
  String get syncTestInvalidUrlHint =>
      'Skriv en http://- eller https://-adresse uden bruger '
      'eller adgangskode i.';
  @override
  String get syncTestOffline => 'Serveren kan ikke nås';
  @override
  String get syncTestOfflineHint =>
      'Er VPN slået til? En 10.x- eller 192.168.x-adresse virker '
      'kun fra samme netværk.';
  @override
  String get syncTestAuth => 'Bruger eller adgangskode afvist';
  @override
  String get syncTestAuthHint => 'Tjek dem, og test igen.';
  @override
  String get syncTestNotFound => 'Mappen findes ikke';
  @override
  String get syncTestNotFoundHint =>
      'Opret den på serveren, eller ret adressen.';
  @override
  String get syncTestUnsupported => 'Ikke en WebDAV-mappe';
  @override
  String get syncTestUnsupportedHint => 'Serveren svarer, men ikke som WebDAV.';
  @override
  String get syncTestFailed => 'Testen virkede ikke';
  @override
  String get syncNowAction => 'Synkronisér nu';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresse, bruger og adgangskode';
  @override
  String get syncRetestTitle => 'Test serveren igen';
  @override
  String syncProbedAgo(String when) => 'Seneste test: $when';
  @override
  String get syncDisconnectTitle => 'Afbryd dette bibliotek';
  @override
  String get syncDisconnectSubtitle => 'Filerne bliver her og på serveren';
  @override
  String get syncDisconnectConfirmTitle => 'Afbryd synkronisering?';
  @override
  String get syncDisconnectConfirmBody =>
      'Dette bibliotek holder op med at synkronisere på denne '
      'enhed. Ingen filer slettes, hverken her eller på '
      'serveren. Hvis du forbinder det igen, starter den første '
      'synkronisering forfra.';
  @override
  String get syncDisconnectConfirm => 'Afbryd';
  @override
  String get syncFirstTitle => 'Første synkronisering';
  @override
  String get syncFirstIntro =>
      'Jeg har sammenlignet biblioteket med mappen på serveren:';
  @override
  String get syncFirstUpload => 'Skal uploades';
  @override
  String get syncFirstDownload => 'Skal downloades';
  @override
  String get syncFirstBoth => 'På begge sider';
  @override
  String get syncFirstBothHint =>
      'Ens: ingen overførsel. Forskellige: skal løses';
  @override
  String get syncFirstNoDelete =>
      'Den første synkronisering sletter intet, hverken her '
      'eller på serveren.';
  @override
  String get syncStartAction => 'Start';
  @override
  String syncMassTrashTitle(int count) => 'Flyt $count filer til affald?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count af de $total synkroniserede filer mangler på '
      'serveren. Det skyldes som regel en forkert adresse, en '
      'NAS-disk, der ikke er monteret, eller en mappe, der er '
      'tømt ved en fejl.';
  @override
  String get syncMassTrashHint =>
      'Hvis du virkelig har slettet dem på en anden enhed, så '
      'bekræft: her havner de i affald.';
  @override
  String get syncMassTrashConfirm => 'Flyt til affald';
  @override
  String syncMassDeleteTitle(int count) => 'Slet $count filer fra serveren?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count af de $total synkroniserede filer mangler her. '
      'Hvis du ikke har slettet dem, så annuller og tjek '
      'biblioteksmappen.';
  @override
  String get syncMassDeleteConfirm => 'Slet fra serveren';
  @override
  String get syncTooltip => 'Synkronisér';
  @override
  String get syncStageConnecting => 'Forbinder til serveren…';
  @override
  String get syncStageComparing => 'Sammenligner med serveren…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synkroniserer · $done af $total';
  @override
  String get syncStatusWarnings => 'Synkroniseret med advarsler';
  @override
  String syncConflictsHeader(int count) => 'Ændret her og på serveren · $count';
  @override
  String get syncConflictHint => 'Ingen af versionerne blev rørt';
  @override
  String get syncResolveAction => 'Løs';
  @override
  String syncFailuresHeader(int count) => 'Ikke synkroniseret · $count';
  @override
  String get syncFailuresHint => 'Forsøges igen ved næste synkronisering';
  @override
  String get syncAbortAuth => 'Serveren afviste adgangskoden';
  @override
  String get syncAbortMissingPassword => 'Ingen gemt adgangskode';
  @override
  String get syncAbortOffline => 'Serveren kan ikke nås';
  @override
  String get syncAbortRemoteMissing => 'Mappen på serveren er væk';
  @override
  String get syncAbortUnsupported => 'Serveren virker ikke længere som WebDAV';
  @override
  String get syncAbortFailed => 'Synkroniseringen virkede ikke';
  @override
  String get syncAbortNotConfirmed => 'Synkronisering annulleret';
  @override
  String get syncAbortNothingTouched =>
      'Ingen filer blev rørt. Dine ændringer bliver her til '
      'næste vellykkede synkronisering.';
  @override
  String syncLastSuccess(String when) =>
      'Seneste vellykkede synkronisering: $when';
  @override
  String get syncNoSuccessYet => 'Ingen vellykket synkronisering endnu';
  @override
  String get syncUpdatePasswordAction => 'Opdater adgangskode';
  @override
  String get syncRetryAction => 'Prøv igen';
  @override
  String get syncOpenSettingsAction => 'Indstillinger';
  @override
  String get syncCloseAction => 'Luk';
  @override
  String get syncDoneSnack => 'Synkroniseret';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synkroniseret · 1 fil slettet et andet sted ligger i '
            'affald'
      : 'Synkroniseret · $count filer slettet et andet sted ligger '
            'i affald';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synkroniseret · 1 konflikt at løse'
      : 'Synkroniseret · $count konflikter at løse';
  @override
  String get syncShowAction => 'Vis';
  @override
  String get syncConflictTitle => 'Løs konflikt';
  @override
  String get syncConflictLegend =>
      'Linjer markeret med − er serverens, linjer markeret med + '
      'er denne enheds.';
  @override
  String get syncConflictBinary =>
      'Ikke en tekstfil: vælg, hvilken kopi du vil beholde.';
  @override
  String get syncConflictKeepNote =>
      'Den kopi, du ikke beholder, bliver i notens historik.';
  @override
  String get syncKeepLocal => 'Behold denne enheds';
  @override
  String get syncKeepRemote => 'Behold serverens';
  @override
  String get syncConflictIdentical => 'De to versioner er ens';
  @override
  String get syncConflictLoadFailed => 'Kunne ikke læse begge versioner';
  @override
  String get syncResolveFailed => 'Kunne ikke løse konflikten';
  @override
  String get syncResolved => 'Konflikt løst';
  @override
  String get syncSectionWhen => 'Hvornår der synkroniseres';
  @override
  String get syncAutoTitle => 'Automatisk';
  @override
  String get syncAutoSubtitle =>
      'Efter ændringer, ved åbning og med faste mellemrum';
  @override
  String get syncIntervalTitle => 'Interval for servertjek';
  @override
  String get syncIntervalSubtitle => 'Kun mens appen er åben';
  @override
  String get syncIntervalDialogBody =>
      'For at se ændringer fra andre enheder, mens appen er åben. Med '
      '»Aldrig« kun efter ændringer og ved åbning.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minut' : '$count minutter';
  @override
  String get syncIntervalNever => 'Aldrig';
  @override
  String get syncWifiOnlyTitle => 'Kun Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'På mobildata synkroniseres der kun manuelt';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 ændring venter' : '$count ændringer venter';
  @override
  String syncRetryIn(String wait) => 'nyt forsøg om $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Venter på Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Venter på forbindelse';
  @override
  String get syncMobileDataHint => '»Synkronisér nu« bruger stadig mobildata.';
  @override
  String get syncQueueKeptHint =>
      'Ændringerne bliver her, også hvis du lukker appen, og sendes af sig '
      'selv, når serveren svarer.';
  @override
  String get syncAutoPaused => 'Automatisk synkronisering sat på pause';
  @override
  String get syncPausedAuthHint =>
      'Den genoptages, når du opdaterer adgangskoden eller synkroniserer '
      'manuelt.';
  @override
  String get syncPausedServerHint =>
      'Den genoptages, når du retter adressen eller synkroniserer manuelt.';
  @override
  String get syncPausedConfirmHint =>
      '»Synkronisér nu« viser, hvad der ville blive fjernet, og spørger '
      'først.';
  @override
  String get syncNeedsConfirmation => 'Venter på din bekræftelse';
  @override
  String get syncMergeIntro =>
      'Ændringer, der ikke overlapper, er allerede flettet; vælg, hvad du vil '
      'beholde, hvor de overlapper.';
  @override
  String get syncMergeClean =>
      'De to versioner flettes af sig selv: intet overlapper.';
  @override
  String get syncMergeNoBase =>
      'Der er ingen fælles version at flette på, så hele filen skal vælges.';
  @override
  String syncMergeOverlap(int index, int total) => 'Overlap $index af $total';
  @override
  String get syncMergeFromLocal => 'Fra denne enhed';
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
  String get syncMergeSave => 'Gem fletningen';
  @override
  String get syncMergeKeepWhole => 'Eller behold én hel kopi';
}
