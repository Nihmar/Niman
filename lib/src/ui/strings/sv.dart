// The Swedish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class SwedishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januari',
    'februari',
    'mars',
    'april',
    'maj',
    'juni',
    'juli',
    'augusti',
    'september',
    'oktober',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mars',
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
    'måndag',
    'tisdag',
    'onsdag',
    'torsdag',
    'fredag',
    'lördag',
    'söndag',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'mån',
    'tis',
    'ons',
    'tors',
    'fre',
    'lör',
    'sön',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Papperskorgen';
  @override
  String get trashSubtitle =>
      'Borttagningar flyttas till .trash/ (av = permanent radering)';
  @override
  String get trashAutoEmptyTitle => 'Töm papperskorgen automatiskt';
  @override
  String get trashAutoEmptySubtitle =>
      'Äldre raderingar försvinner för gott när biblioteket öppnas';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Aldrig'
      : days == 1
      ? '1 dag'
      : '$days dagar';
  @override
  String get debugLogsTitle => 'Felsökningsloggar';
  @override
  String get debugLogsSubtitle =>
      'Registrera appens händelser i en buffert i minnet';
  @override
  String get lineNumbersTitle => 'Radnummer';
  @override
  String get lineNumbersSubtitle =>
      'Visa radnumrerkolumnen i anteckningseditorn';
  @override
  String get readableLineLengthTitle => 'Läsbar radlängd';
  @override
  String get readableLineLengthSubtitle =>
      'Håll anteckningens text i en centrerad kolumn i stället för hela '
      'fönstrets bredd';
  @override
  String get noteColumnWidthTitle => 'Kolumnbredd';
  @override
  String get noteColumnWidthSubtitle =>
      'Hur bred anteckningens kolumn är, i pixlar';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Tangentbord vid öppning';
  @override
  String get keyboardOnOpenSubtitle =>
      'Visa tangentbordet så snart en anteckning öppnas (av = vid första '
      'beröringen)';
  @override
  String get editorKindSource => 'Markdown-källa';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown-källa, som skriven';
  @override
  String get editorKindWysiwygSubtitle => 'Formaterad text, redigeras direkt';
  @override
  String get settingsFolderToCreate => 'skapas';
  @override
  String get settingsSearchHint => 'Sök i inställningar';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 inställning hittades' : '$count inställningar hittades';
  @override
  String get settingsToggleOn => 'På';
  @override
  String get settingsToggleOff => 'Av';
  @override
  String get settingsPreviewEnabledTitle => 'Förhandsvisning';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Visa den renderade anteckningen bredvid källtexteditorn';
  @override
  String get switchToWysiwygTooltip => 'Byt till WYSIWYG-editorn';
  @override
  String get switchToSourceTooltip => 'Byt till Markdown-källan';
  @override
  String get switchToSourceLabel => 'Källa';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Denna anteckning är för stor för WYSIWYG-editorn. Öppna den i '
      'Markdown-källan.';

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
  String get settingsSectionShortcuts => 'Tangentbord';
  @override
  String get keyboardShortcutsTitle => 'Tangentbordsgenvägar';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bibliotek $name';
  @override
  String get settingsGroupLibraryHint => 'gäller bara för det här biblioteket';
  @override
  String get settingsGroupMaintenance => 'Underhåll';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mappar och sökvägar';
  @override
  String get settingsAreaTrashHistory => 'Papperskorgen och kronologi';
  @override
  String get settingsAreaDiagnostics => 'Diagnostik och info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Kräver ett anslutet fysiskt tangentbord';
  @override
  String get settingsSectionUpdates => 'Uppdateringar';
  @override
  String get autoUpdateTitle => 'Automatiska uppdateringar';
  @override
  String get autoUpdateSubtitle =>
      'Kontrollera GitHub Releases vid start och var 6:e timme';
  @override
  String get checkForUpdatesTitle => 'Sök efter uppdateringar';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version finns tillgänglig';
  @override
  String get updateUpToDate => 'Niman är uppdaterad';
  @override
  String get updateCheckFailed => 'Det gick inte att söka efter uppdateringar';
  @override
  String updateSavedTo(Object path) => 'Uppdateringen sparades i $path';
  @override
  String get updateInstallerStarted => 'Installationsprogrammet har startats';
  @override
  String get settingsSectionDiagnostics => 'Diagnostik';
  @override
  String get settingsSpellCheckTitle => 'Stavkontroll';
  @override
  String get settingsSpellCheckSubtitle =>
      'Understryka felstavningar medan du skriver.';
  @override
  String get spellCheckDictionaryTitle => 'Ordbok';
  @override
  String get spellCheckDictionarySystem => 'Systemstandard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Välj ordböcker';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Välj alla språk som biblioteket är skrivet på. Ett ord går igenom '
      'när någon vald ordbok känner till det; utan val avgör '
      'systemspråket.';
  @override
  String get spellCheckNoDictionaries =>
      'Inga ordböcker hittades på det här systemet.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Stavkontroll';
  @override
  String get spellCheckTitle => 'Stavning';
  @override
  String get spellCheckEmpty => 'Inga stavfel.';
  @override
  String get spellCheckUnavailable =>
      'hunspell är inte installerad på det här systemet.';
  @override
  String get spellCheckNoSuggestions => 'Inga förslag';
  @override
  String spellCheckCount(int count) => '$count att granska';
  @override
  String spellCheckLine(int line) => 'rad $line';
  @override
  String get addWordToDictionary => 'Lägg till i ordboken';

  @override
  String indentWidthValue(int spaces) => '$spaces mellanslag';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Ljusstyrka';
  @override
  String get themeBrightnessSubtitle =>
      'Ljus, mörk eller vad enheten är inställd på';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Ljus';
  @override
  String get themeBrightnessNight => 'Mörk';
  @override
  String get themePaletteTitle => 'Färgpalett';
  @override
  String get themePaletteSubtitle =>
      'Färgerna i gränssnittet och i anteckningen';
  @override
  String get themePaletteSystem => 'System';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Gränssnittstextens storlek';
  @override
  String get uiTextScaleSubtitle =>
      'Trädet, flikarna och dialogrutor; ovanpå systeminställningen';
  @override
  String get noteTextScaleTitle => 'Anteckningarnas textstorlek';
  @override
  String get noteTextScaleSubtitle =>
      'Editorn och förhandsvisningen, som alltid håller ihop';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Förhandsvisningsläge';
  @override
  String get previewModeSubtitle =>
      'Huru förhandsvisningen delar skärmen med editorn eller ersätter '
      'den';
  @override
  String get previewModeAuto => 'Sida vid sida';
  @override
  String get previewModeSwitch => 'Helskärm';
  @override
  String get splitRatioTitle => 'Utdelningsbredd';
  @override
  String get splitRatioSubtitle =>
      'Editorns andel när förhandsvisningen är sida vid sida';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Länkformat';
  @override
  String get linkTypeSubtitle => 'Vad länkknappen i editorn inserar';
  @override
  String get linkTypeWikilink => 'Wikilänk';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Skapa saknade anteckningar i';
  @override
  String get missingNoteLocationRoot => 'Bibliotekets rotmapp';
  @override
  String get missingNoteLocationCurrentFolder => 'Aktuell mapp';
  @override
  String get indentWidthTitle => 'Indenteringsbredd';
  @override
  String get indentWidthSubtitle =>
      'Mellanslag som läggs till per indenteringsnivå i editorn';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Språk';
  @override
  String get languageSubtitle => 'Språket på appens egen text';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Lägg till ett objekt';
  @override
  String get listAddTooltip => 'Lägg till ett objekt';
  @override
  String get listEmpty => 'Inga objekt ännu';
  @override
  String get listDragHandleLabel => 'Byt ordning på objektet';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Inga inspelningar ännu';
  @override
  String get audioRecord => 'Spela in';
  @override
  String get audioStop => 'Stoppa';
  @override
  String get audioPlay => 'Spela upp';
  @override
  String get audioDelete => 'Ta bort inspelning';
  @override
  String get audioImport => 'Importera en ljudfil';
  @override
  String get audioRecording => 'Spelar in…';
  @override
  String get audioPermissionDenied =>
      'Mikrofonåtkomst nekad — den behövs för inspelning.';
  @override
  String get newAudioNoteTitle => 'Ny röstanteckning';
  @override
  String get newAudioNoteDefault => 'Min inspelning';
  @override
  String get showAudioTooltip => 'Visa inspelningar';
  @override
  String get audioMessageHint => 'Skriv en anteckning…';
  @override
  String get audioSend => 'Skicka';
  @override
  String get audioRename => 'Byt namn på inspelning';
  @override
  String get audioDescriptionHint => 'Beskriv den här inspelningen…';
  @override
  String get audioEditDescription => 'Redigera beskrivning';
  @override
  String get audioDeleteNote => 'Ta bort anteckning';
  @override
  String get audioEditNote => 'Redigera anteckning';
  @override
  String get audioPause => 'Pausa';
  @override
  String get audioEditTitle => 'Redigera titel';
  @override
  String get audioTitleHint => 'Ge inspelningen en titel…';
  @override
  String audioUntitled(int n) => 'Inspelning $n';
  @override
  String get audioMoreActions => 'Fler åtgärder';
  @override
  String get audioDiscardRecording => 'Kasta inspelning';
  @override
  String get audioPauseRecording => 'Pausa inspelningen';
  @override
  String get audioResumeRecording => 'Återuppta inspelningen';
  @override
  String get audioRecordingPaused => 'Pausad';
  @override
  String get audioSavingRecording => 'Sparar…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Snabbanteckning';
  @override
  String get shortcutNewTodo => 'Ny uppgift';
  @override
  String get shortcutNewNote => 'Ny anteckning';
  @override
  String get shortcutNewList => 'Ny lista';
  @override
  String get shortcutNewAudio => 'Ny röstanteckning';
  @override
  String get shortcutToggleSidebar => 'Visa eller dölj filträdet';
  @override
  String get shortcutCloseTab => 'Stäng den aktuella anteckningen';
  @override
  String get shortcutNextTab => 'Nästa öppna anteckning';
  @override
  String get shortcutPreviousTab => 'Föregående öppna anteckning';
  @override
  String get shortcutEditorSection => 'I editorn';
  @override
  String get shortcutFind => 'Sök';
  @override
  String get shortcutReplace => 'Sök och ersätt';
  @override
  String get shortcutSavingNote =>
      'Ändringar sparas automatiskt, så det finns ingen genväg för att '
      'spara.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Läser in…';
  @override
  String get noteStatusSaving => 'Sparar…';
  @override
  String get noteStatusUnsaved => 'Osparat';
  @override
  String get noteStatusSaved => 'Sparat';
  @override
  String get noteStatusError => 'Fel';
  @override
  String get noteNotText =>
      'Den här filen är inte en textanteckning, så '
      'Niman kan inte visa den här.';
  @override
  String get noteLoadFailed => 'Anteckningen kunde inte öppnas.';
  @override
  String wordCount(int count) => '$count ord';
  @override
  String get outlineTooltip => 'Struktur';
  @override
  String get outlineNoHeadings => 'Inga rubriker';
  @override
  String get outlineNoTitle => '(ingen titel)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Fet';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'Genomstrykning';
  @override
  String get toolbarSuperscript => 'Upphöjd';
  @override
  String get toolbarUnderline => 'Understrykning';
  @override
  String get toolbarLink => 'Länk';
  @override
  String get toolbarCode => 'Kodblock';
  @override
  String get toolbarImage => 'Infoga bild';
  @override
  String get toolbarHeading => 'Rubrik';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Numrerad lista';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Indentera';
  @override
  String get toolbarOutdent => 'Ta bort indentering';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Verktyg';
  @override
  String get editorToolsTitle => 'Redigerarverktyg';
  @override
  String get toolCountListTitle => 'Räkna en lista';
  @override
  String get toolCountListSubtitle =>
      'Summerar det raderna räknar upp, som en checklista';
  @override
  String get toolCountListNeedsList =>
      'Den här anteckningen har ingen lista att räkna';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Läs varje rad som';
  @override
  String get tallyCutDash => 'Namn - värden';
  @override
  String get tallyCutColon => 'Namn: värden';
  @override
  String get tallyCutCommas => 'Värden åtskilda med komma';
  @override
  String get tallyCutWhole => 'Hela raden, som ett värde';
  @override
  String get tallySortLabel => 'Ordning';
  @override
  String get tallySortCount => 'Flest först';
  @override
  String get tallySortAlphabetical => 'Alfabetisk';
  @override
  String get tallySortFirstSeen => 'Som de står';
  @override
  String get tallyInsert => 'Infoga';
  @override
  String get tallyUpdate => 'Uppdatera';
  @override
  String get tallyNothingToCount => 'Här finns inget att räkna';
  @override
  String get headingDialogTitle => 'Rubriknivå';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editorverktygsfält';
  @override
  String get toolbarSettingsHint =>
      'Dra för att byta ordning; ögat visar eller döljer en knapp.';
  @override
  String get toolbarShowButton => 'Visa';
  @override
  String get toolbarHideButton => 'Dölj';
  @override
  String get toolbarResetOrder => 'Återställ standard';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Visa förhandsvisning';
  @override
  String get showEditorTooltip => 'Visa editor';
  @override
  String get enterFullScreenTooltip => 'Helskärm';
  @override
  String get exitFullScreenTooltip => 'Lämnar helskärm';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(rå HTML-tabell)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Sök i anteckningar';
  @override
  String get searchModeWords => 'Ord';
  @override
  String get searchModeContains => 'Innehåller';
  @override
  String get searchEmptyHint =>
      'Skriv för att söka i biblioteket, eller nyckel = värde för att '
      'filtrera på frontmatter';
  @override
  String get searchTooShortHint => 'Skriv minst 2 tecken';
  @override
  String get searchNoMatches => 'Inga träffar';
  @override
  String get searchLoadMore => 'Visa mer';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Ersätt…';
  @override
  String get replaceInNoteAction => 'Ersätt i den här anteckningen…';
  @override
  String get replaceInThisNote => 'Ersätt i den här anteckningen';
  @override
  String get replaceWithLabel => 'Ersätt med';
  @override
  String get replaceCaseSensitive => 'Skiftlägeskänsligt';
  @override
  String get replaceWholeWordsHint => 'bara exakta helt-ord-träffar ersätts';
  @override
  String get replaceConfirm => 'Ersätt';
  @override
  String get replaceCancel => 'Stäng';
  @override
  String get replaceUnavailable => 'Ersätt är inte tillgängligt just nu';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Sök i anteckning';
  @override
  String get editorFindHint => 'Sök';
  @override
  String get editorReplaceHint => 'Ersätt';
  @override
  String get editorFindCaseTooltip => 'Skiftlägeskänsligt';
  @override
  String get editorFindPreviousTooltip => 'Föregående träff';
  @override
  String get editorFindNextTooltip => 'Nästa träff';
  @override
  String get editorFindCloseTooltip => 'Stäng sök';
  @override
  String get editorFindReplaceModeTooltip => 'Ersättningsläge';
  @override
  String get editorReplaceOneTooltip => 'Ersätt den här träffen';
  @override
  String get editorReplaceAllTooltip => 'Ersätt alla träffar';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Taggar';
  @override
  String get tagsTitle => 'Taggar';
  @override
  String get tagsEmpty =>
      'Inga taggar ännu — lägg till en #tag eller taggar i frontmatter';
  @override
  String get tagsBackTooltip => 'Tillbaka till sökning';
  @override
  String get tagsNotesEmpty => 'Inga anteckningar med den här taggen';
  @override
  String tagsNotesCapped(int limit) =>
      'Bara de första $limit listas — sök taggen för att begränsa';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Länken hittades inte';
  @override
  String get headingNotFoundTitle => 'Rubriken hittades inte';
  @override
  String get ambiguousLinkTitle => 'Flera anteckningar matchar';
  @override
  String get openLinkFailed => 'Kunde inte öppna länken';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Anteckningen finns inte';
  @override
  String missingNoteDialogBody(String path) => 'Skapa „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Mappen „$folder“ finns inte';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Öppna';
  @override
  String get todoDone => 'Klart';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Alla datum';
  @override
  String get todoFilter => 'Filtrera';
  @override
  String get todoNoTokens => 'Inga token i den här listan';
  @override
  String get todoCountOpen => 'öppna';
  @override
  String get todoCountDone => 'klar';
  @override
  String get todoEmptyOpen => 'Inga pågående uppgifter ännu';
  @override
  String get todoEmptyDone => 'Inget slutfört ännu';
  @override
  String get todoEmptyFiltered => 'Inga uppgifter matchar';
  @override
  String get todoTitle => 'Att göra';
  @override
  String get todoAddTooltip => 'Lägg till uppgift';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt-formatet';
  @override
  String get todoHelpTooltip => 'Formatinformation';
  @override
  String get todoHelpIntro =>
      'Dina uppgifter är en vanlig textfil, en uppgift per rad. Niman '
      'skriver syntaxen åt dig, men ingenting göms: du kan redigera filen '
      'i valfri editor och Niman läser den igen.';
  @override
  String get todoHelpFilesTitle => 'De två filerna';
  @override
  String get todoHelpFilesBody =>
      'Öppna uppgifter ligger i todo.txt i roten av biblioteket. '
      'Slutför en och raden flyttas till done.txt, så att todo.txt hålls '
      'kort. Om en slutförd rad hamnar tillbaka i todo.txt arkiverar '
      'Niman den nästa gång den läser filerna.';
  @override
  String get todoHelpLineTitle => 'En rads anatomi';
  @override
  String get todoHelpLineBody =>
      'Allt före beskrivningen är valfritt och måste komma i denna '
      'ordning:';
  @override
  String get todoHelpDoneBody =>
      'Markerar uppgiften som klar. Niman lägger till den när du bockar i '
      'rutchen.';
  @override
  String get todoHelpPriority => '(A) till (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A är den högsta. Visas som en märke i listan.';
  @override
  String get todoHelpDatesBody =>
      'Slutdatum, sedan skapadatum. Med bara ett datum är det skapadatum, '
      'om raden inte börjar med x.';
  @override
  String get todoHelpTokensTitle => 'Projekt, kontexter och taggar';
  @override
  String get todoHelpTokensBody =>
      'Var som helst i beskrivningen blir ett ord med ett av dessa prefix '
      'en chip du kan filtrera på. Inget är fördefinierat: ett token finns '
      'så snart du skriver det.';
  @override
  String get todoHelpProjectBody =>
      'Vad uppgiften ingår i, till exempel +kök eller +examensarbete.';
  @override
  String get todoHelpContextBody =>
      'Var eller hur du kommer att göra den, till exempel @hemma eller '
      '@samtal.';
  @override
  String get todoHelpHashtagBody =>
      'En fri etikett, för allt det andra två inte täcker.';
  @override
  String get todoHelpTagsTitle => 'Datum och påminnelser';
  @override
  String get todoHelpTagsBody =>
      'De här är nyckel: värde-taggar. Niman skriver dem från '
      'uppgiftdialogen och läser dem var de än förekommer på raden.';
  @override
  String get todoHelpDueBody =>
      'Förfallsdatumet. Styrs av den färgade märken och datumfilterna.';
  @override
  String get todoHelpRemBody =>
      'När en avisering ska skickas, i din lokala tid. Den utlöses med '
      'skärmen avstängd och appen stängd.';
  @override
  String get todoHelpRemDesktop =>
      'På skrivbord måste Niman vara i gång när tiden är inne: påminnelsen '
      'visas medan appen är öppen, och ingenting utlöses när den är '
      'stängd.';
  @override
  String get todoHelpOtherBody =>
      'Bevaras exakt som skrivet, så att taggar från andra todo.txt-appar '
      'överlever en omväg. Niman agerar inte på dem, rec: included: en '
      'återkommande uppgift upprepas inte än.';
  @override
  String get todoHelpEditTitle => 'Redigering utanför Niman';
  @override
  String get todoHelpEditBody =>
      'En uppgift du inte rört skrivs tillbaka byte för byte, konstiga '
      'avstånd medräknade. Redigera en rad och Niman skriver om just den '
      'raden i sin kanoniska form och rör inte resten av filen.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Lägg till uppgift';
  @override
  String get todoEditTitle => 'Redigera uppgift';
  @override
  String get todoDescriptionHint => 'Beskrivning';
  @override
  String get todoCancel => 'Avbryt';
  @override
  String get todoSave => 'Spara';
  @override
  String get todoEditAction => 'Redigera';
  @override
  String get todoDeleteAction => 'Ta bort';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Över tid';
  @override
  String get todoDueToday => 'Idag';
  @override
  String get todoDueNext7 => 'Nästa 7 dagar';
  @override
  String get todoDueNoDate => 'Inget datum';
  @override
  String get todoRowDue => 'Förfällig';
  @override
  String get todoRowDueToday => 'Förfällig idag';
  @override
  String get todoSortTooltip => 'Sortera';
  @override
  String get todoSortDue => 'Förfallsdatum';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Skapadatum';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Ingen prioritet';
  @override
  String get todoNoPriorityShort => 'Ingen';
  @override
  String get todoMorePriorities => 'Fler…';
  @override
  String get todoPriorityTitle => 'Prioritet';
  @override
  String get todoNoDueDate => 'Inget förfallsdatum';
  @override
  String get todoNoReminder => 'Ingen påminnelse';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontext';
  @override
  String get todoAddHashtag => '# Tagg';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Uppgiftspåminnelser';
  @override
  String get todoReminderChannelDescription =>
      'Schemalagda aviseringar för uppgifter med påminnelsestid.';
  @override
  String get todoReminderBody => 'Att-göra-påminnelse';
  @override
  String get todoReminderFallbackTitle => 'Uppgiftspåminnelse';
  @override
  String get todoReminderBlocked =>
      'Aviseringar är avstängda, så påminnelser visas inte.';
  @override
  String get todoReminderBattery =>
      'Batterioptimering är påslagen för Niman. Systemet kan låta appen '
      'sova och tappa väntande påminnelser.';
  @override
  String get todoReminderInexact =>
      'Den här enheten tillåter inte exakta alarmer, så en påminnelse kan '
      'komma flera minuter sent med skärmen avstängd.';
  @override
  String get reminderShowTokensTitle => 'Taggar i påminnelseaviseringar';
  @override
  String get reminderShowTokensSubtitle =>
      'Behåll +projekt, @kontext och #tag i aviseringstexten. Av visar '
      'bara den uppgift du skrev.';
  @override
  String get todoReminderFixAction => 'Öppna inställningar';
  @override
  String get todoReminderDismissAction => 'Ignorera';
  @override
  String get todoReminderDue => 'Förfällig';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Avbryt';
  @override
  String get actionCreate => 'Skapa';
  @override
  String get actionNew => 'Ny';
  @override
  String get actionSave => 'Spara';
  @override
  String get actionClear => 'Rensa';
  @override
  String get actionChoose => 'Välj';
  @override
  String get actionDelete => 'Ta bort';
  @override
  String get actionRename => 'Byt namn';
  @override
  String get actionMove => 'Flytta';
  @override
  String get saveAndClose => 'Spara och stäng';
  @override
  String get closeUnsavedTitle => 'OSparade ändringar';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” har ändringar som inte är sparade ännu. '
          'Spara dem innan stängning?';
    }
    return '${names.length} anteckningar har ändringar som inte är sparade '
        'ännu. Spara dem innan stängning?';
  }

  @override
  String get closeSaveFailed => 'Kunde inte spara; fortfarande öppen.';
  @override
  String get actionRestore => 'Återställ';
  @override
  String get actionEmpty => 'Töm';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Dölj sidopanelen (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Visa sidopanelen (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimera';
  @override
  String get windowMaximizeTooltip => 'Maximera';
  @override
  String get windowRestoreTooltip => 'Återställ';
  @override
  String get windowCloseTooltip => 'Stäng';
  @override
  String get tabFiles => 'Filer';
  @override
  String get tabSearch => 'Sök';
  @override
  String get tabSettings => 'Inställningar';
  @override
  String get quickNoteTitle => 'Snabbanteckning';
  @override
  String get treeEmpty => 'Inga anteckningar ännu';
  @override
  String get selectANote => 'Välj en anteckning';
  @override
  String get showListTooltip => 'Visa lista';
  @override
  String get editRawTooltip => 'Redigera rå';
  @override
  String get sortAscTooltip => 'Sortera A-Ö';
  @override
  String get sortDescTooltip => 'Sortera Ö-A';
  @override
  String get newNoteTitle => 'Ny anteckning';
  @override
  String get newItemTooltip => 'Ny';
  @override
  String get closeMenuTooltip => 'Stäng';
  @override
  String get newFolderTitle => 'Ny mapp';
  @override
  String get newNoteSameFolder => 'Ny anteckning i samma mapp';
  @override
  String get newFromTemplateSameFolder => 'Ny från mall i samma mapp';
  @override
  String trashOriginalPath(String path) => 'låg i $path';
  @override
  String get trashOriginalRoot => 'var i bibliotekets rot';
  @override
  String trashItemCount(int count) => count == 1 ? '1 objekt' : '$count objekt';
  @override
  String get newNoteHere => 'Ny anteckning här';
  @override
  String get newFolderHere => 'Ny mapp här';
  @override
  String get newListNoteTitle => 'Ny listaanteckning';
  @override
  String get newListNoteDefault => 'Min lista';
  @override
  String get setAsQuickNote => 'Sätt som snabbanteckning';
  @override
  String get currentQuickNote => 'Aktuell snabbanteckning';
  @override
  String get pinnedSection => 'Fästa';
  @override
  String pinnedSectionCount(int count) => 'Fästa · $count';
  @override
  String get templateFolderTitle => 'Mallmapp';
  @override
  String get newFromTemplateTitle => 'Ny från mall';
  @override
  String get newFromTemplateHere => 'Ny från mall här';
  @override
  String get templateFormTitle => 'Fyll i mallen';
  @override
  String get templateFormBacklink => 'Länkad från';
  @override
  String get templateFormNoNote => 'Ingen anteckning';
  @override
  String get templateFormPickNote => 'Välj anteckningen';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Mallplatshållare';
  @override
  String get templateHelpSubtitle =>
      'Datum, titel och övriga värden att fylla i';
  @override
  String get quickNoteSubtitle =>
      'Anteckningen som fliken Snabbanteckning öppnar';
  @override
  String get listFolderSubtitle => 'De nya uppgiftslistorna';
  @override
  String get templateFolderSubtitle => 'Källan till „Ny från mall“';
  @override
  String get attachmentsFolderSubtitle =>
      'Bilder och ljud infogade i en anteckning';
  @override
  String get templateHelpIntro =>
      'En mall är en vanlig anteckning med hål i. Att skapa en anteckning '
      'ur en kopierar texten och fyller hålen.';
  @override
  String get templateHelpUnknown =>
      'En platshållare Niman inte känner till lämnas exakt som skrivet, '
      'så ett stavfel syns i anteckningen i stället för att tyst äta en '
      'rad.';
  @override
  String get templateHelpValuesTitle => 'Värden';
  @override
  String get templateHelpTitleBody => 'Namnet anteckningen skapas med.';
  @override
  String get templateHelpDateBody =>
      'Idag, och klockan nu. Båda tar ett format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum och klocka tillsammans.';
  @override
  String get templateHelpUuidBody =>
      'En ny identifierare, en annan vid varje förekomst.';
  @override
  String get templateHelpCounterBody =>
      'Ett tal som räknar upp per namn, bevarat över omstartar: den första '
      'anteckningen skriver 1, nästa 2. Samma namn i en anteckning skriver '
      'samma tal; kombinera med |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Sätter markören här när anteckningen skapas; markören själv '
      'skrivs inte. Första markören vinner, inga filter, bara nya '
      'anteckningar — och tangentbordet öppnas även med autofokus '
      'avstängt.';
  @override
  String get templateHelpDatesTitle => 'Att skriva ett datum';
  @override
  String get templateHelpDatesBody =>
      'De här står för delar av datumen i ett format. Allt annat är '
      'bokstavligt, och text i enkelcitat är också bokstavligt. Månads- '
      'och veckodagsnamn följer appens språk.';
  @override
  String get templateHelpYear => 'året: 2026, 26';
  @override
  String get templateHelpMonth => 'månaden: 03, 3, mars, mar';
  @override
  String get templateHelpDay => 'dagen: 09, 9, måndag, mån';
  @override
  String get templateHelpTime => 'timmar, minuter, sekunder';
  @override
  String get templateHelpWeek => 'ISO-vecka och kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filter';
  @override
  String get templateHelpFiltersBody =>
      'Ett värde kan följas av filter, tillämpade vänster till höger.';
  @override
  String get templateHelpCaseBody =>
      'Versaler, gemener och den första bokstaven i varje ord — ett ord '
      'du själv högbokstävat lämnas orört.';
  @override
  String get templateHelpSlugBody =>
      'Länkformen av texten, för att bygga en wikilänk.';
  @override
  String get templateHelpPadBody =>
      'Boka av ändarna; fylla med nollor till en bredd; använd ett '
      'alternativ när värdet är tomt.';
  @override
  String get templateHelpShiftBody =>
      'Flytta ett datum med dagar, veckor, månader eller år — nästa '
      'veckas föreläsning, förra månadens fil.';
  @override
  String get templateHelpSnapBody =>
      'Ställ in ett datum på början eller slutet av dess vecka, månad '
      'eller år.';
  @override
  String get templateHelpAskTitle => 'Att fråga dig något';
  @override
  String get templateHelpAskBody =>
      'Ett formulär visas innan anteckningen skapas, en ruta per fråga — '
      'och en för baklänken, när mallen vill ha en. Samma etikett två '
      'gånger är en fråga, och svaret fyller varje förekomst — mapp och '
      'filnamn medräknade.';
  @override
  String get templateHelpAskFieldBody =>
      'En ruta att skriva i; texten efter det andra kolontecknet är vad '
      'den börjar med.';
  @override
  String get templateHelpChoiceBody =>
      'Ett val ur en lista, separerat med kommas.';
  @override
  String get templateHelpWhereTitle => 'Vär anteckningen hamnar';
  @override
  String get templateHelpWhereBody =>
      'De här är inte text: de är instruktioner, och de bor i en niman: '
      'block i mallens egen frontmatter. Blocket lydnas och tas sedan '
      'bort, så det visas aldrig i anteckningen. Deras värden kan '
      'innehålla platshållare.';
  @override
  String get templateHelpFolderBody =>
      'Mappen anteckningen skapas i, skapas om den inte finns. Utan den '
      'landar anteckningen där du var.';
  @override
  String get templateHelpFilenameBody =>
      'Vad anteckningen heter. En mall som anger det här frågas inte om '
      'ett namn.';
  @override
  String get templateHelpAppendBody =>
      'Lägg till i anteckningen om den redan finns, i stället för att '
      'göra en andra. Det är det som gör en månad av möten till en fil.';
  @override
  String get templateHelpOpenBody =>
      'Vad som händer när anteckningen finns: editorn (standard), '
      'förhandsvisningen, eller ingenting — anteckningen arkiveras och du '
      'stannar där du var.';
  @override
  String get templateHelpAroundTitle => 'Var det kom ifrån';
  @override
  String get templateHelpParentBody =>
      'En anteckning du väljer i formuläret, som föreslår den på skärmen; '
      'skriv [[{{parent}}]] för en länk tillbaka.';
  @override
  String get templateHelpFolderValueBody => 'Mappen anteckningen hamnade i.';
  @override
  String get templateHelpClipboardBody =>
      'Vad som ligger i klippbordet, och editorvalen när anteckningen '
      'startades från en.';
  @override
  String get templateHelpIncludeTitle => 'Återanvända ett stycke';
  @override
  String get templateHelpIncludeBody =>
      'Klistrar in en annan mall, så tio mallar kan dela en checklista. '
      'Den söks upp i mallmappen först, och .md kan utelämnas. Dens egna '
      'frågor går med i samma formulär.';
  @override
  String get templateHelpExampleTitle => 'Allt tillsammans';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ingen mall “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” inkluderar sig själv';
  @override
  String includeTooDeep(String path) => '⚠ “$path” är för djupt nästlad';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter inte läst: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter för “$template” lästes inte, så mapp och filnamn gjorde '
      'ingenting: $reason';
  @override
  String get templatePickerTitle => 'Välj en mall';
  @override
  String templatePickerEmpty(String folder) =>
      'Inga mallar ännu. Lägg en anteckning i $folder/ och den blir en.';

  // Tree actions.
  @override
  String get actionPin => 'Fäst';
  @override
  String get actionUnpin => 'Lösen';
  @override
  String get pinToWidget => 'Fäst på startskärmswidget';
  @override
  String get pinnedForWidget =>
      'Fäst: placera nu Notis-widgeten på startskärmen';
  @override
  String get pinWidgetUnavailable =>
      'Startskärmswidgets är tillgängliga på Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Visa i filhanteraren';
  @override
  String get openInDefaultApp => 'Öppna i standardappen';
  @override
  String get newNoteTabTooltip => 'Ny anteckning i en ny flik';
  @override
  String get openNotesTooltip => 'Öppna anteckningar';
  @override
  String get closeTabTooltip => 'Stäng';
  @override
  String get openInNewTab => 'Öppna i ny flik';
  @override
  String get splitRight => 'Dela åt höger';
  @override
  String get splitDown => 'Dela nedåt';
  @override
  String get moveToOtherPane => 'Flytta till den andra rutan';
  @override
  String get openBeside => 'Öppna vid sidan';
  @override
  String get closeAllNotes => 'Stäng alla';
  @override
  String get sidePanelTooltip => 'Visa eller dölj sidopanelen';
  @override
  String get historyAllVersions => 'Alla versioner';
  @override
  String get commandPaletteTitle => 'Kommandopalett';
  @override
  String get goToNoteTitle => 'Gå till anteckning';
  @override
  String get paletteGroupNote => 'Anteckning';
  @override
  String get paletteGroupEditor => 'Redigerare';
  @override
  String get paletteGroupView => 'Visning';
  @override
  String get paletteGroupLibrary => 'Bibliotek';
  @override
  String get paletteGroupGoTo => 'Gå till';
  @override
  String get paletteHint => 'Sök kommandon och anteckningar';
  @override
  String get paletteNoResults => 'Inga träffar';
  @override
  String get paletteCommands => 'Kommandon';
  @override
  String get paletteNotes => 'Anteckningar';
  @override
  String get paletteFooter =>
      '↑↓ för att flytta · ↵ för att använda · esc för att stänga';
  @override
  String get typewriterOn => 'Slå på skrivmaskinsläge';
  @override
  String get typewriterOff => 'Slå av skrivmaskinsläge';
  @override
  String get typewriterTitle => 'Skrivmaskinsläge';
  @override
  String get typewriterSubtitle =>
      'Håll raden du skriver på mitt i redigeraren';
  @override
  String get zenMode => 'Zenläge';
  @override
  String get zenModeEnter => 'Gå till zenläge';
  @override
  String get zenModeLeave => 'Lämna zenläge';
  @override
  String get keySpace => 'Blanksteg';
  @override
  String get keyEnter => 'Enter';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Backsteg';
  @override
  String get keyDelete => 'Delete';
  @override
  String get keyArrowUp => 'Upp';
  @override
  String get keyArrowDown => 'Ned';
  @override
  String get keyArrowLeft => 'Vänster';
  @override
  String get keyArrowRight => 'Höger';
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
  String get shortcutNone => 'Inget kortkommando';
  @override
  String get shortcutRestoreDefaults => 'Återställ standard';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Sätta tillbaka alla kortkommandon som Niman levererar dem?';
  @override
  String get shortcutRevert => 'Tillbaka till standard';
  @override
  String get shortcutClear => 'Ta bort kortkommandot';
  @override
  String get shortcutCapturePrompt =>
      'Tryck på tangenterna. Även Esc och Tab fångas: Avbryt är vägen ut.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Lägg till Ctrl, Alt eller Meta: en tangent ensam är för att skriva.';
  @override
  String get shortcutMove => 'Flytta det';
  @override
  String get shortcutUseAnyway => 'Använd ändå';
  @override
  String get shortcutUndo => 'Ångra';
  @override
  String get shortcutRedo => 'Gör om';
  @override
  String get shortcutChange => 'Ändra kortkommandot';
  @override
  String shortcutCaptureTitle(String command) => 'Tangenter för $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys tillhör redan $other. Flytta hit? $other får inget kortkommando.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys är även $what i textfält och redigeraren. Där tar ditt kommando '
      'det.';
  @override
  String get openFileMissing =>
      'Den här anteckningens fil finns inte på disken';
  @override
  String get openFileFailed =>
      'Det gick inte att öppna anteckningen utanför Niman';

  @override
  String get movedToTrash => 'Flyttad till papperskorgen';
  @override
  String get deletedMessage => 'Togs bort';
  @override
  String deleteToTrashConfirm(String name) => '$name flyttas till .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name tas bort permanent';
  @override
  String get chooseDestination => 'Välj mål';
  @override
  String get libraryRoot => 'Bibliotekets rot';
  @override
  String moveTitle(String name) => 'Flytta $name';
  @override
  String headingLevelLabel(int level) => 'Rubrik $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ingen snabbanteckning ännu. Välj en befintlig anteckning, eller '
      'skapa en ny — snabbanteckningen öppnas här.';
  @override
  String get quickNoteChooseAction => 'Välj en anteckning…';
  @override
  String get quickNoteCreateAction => 'Skapa en ny anteckning…';
  @override
  String get quickNoteNewTitle => 'Ny snabbanteckning';
  @override
  String get quickNotePickerTitle => 'Välj snabbanteckning';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Ny mapp';
  @override
  String get folderPickerEmpty => 'Inga mappar ännu';
  @override
  String get listFolderTitle => 'Listmapp';
  @override
  String get attachmentsFolderTitle => 'Mapp för bilagor';

  // Trash (M1).
  @override
  String get trashEmpty => 'Papperskorgen är tom';
  @override
  String get trashEmptyAction => 'Töm papperskorgen';
  @override
  String get trashEmptyConfirm =>
      'Det här raderar allt i papperskorgen permanent, inklusive objekt '
      'Niman inte lagt dit.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name raderas permanent (ingen återställning)';
  @override
  String get trashDeletePermanently => 'Radera permanent';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Öppna en mapp med Markdown-anteckningar som bibliotek';
  @override
  String get openLibraryExisting => 'Öppna befintlig';
  @override
  String get openLibraryCreate => 'Skapa ny';
  @override
  String get openLibraryCreateTitle => 'Skapa nytt bibliotek';
  @override
  String get openLibraryFolderName => 'Mappnamn';
  @override
  String get openLibraryChooseFolder => 'Välj biblioteksmappen';
  @override
  String get openLibraryChooseParent => 'Välj mappen biblioteket ska skapas i';
  @override
  String get openLibraryUnsupported =>
      'Den mappen stöds inte. Välj en mapp i enhetens lagring.';
  @override
  String indexingCount(int done, int total) => '$done av $total anteckningar';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Dina bibliotek';
  @override
  String get libraryUnreachable => 'Onåbar';
  @override
  String get libraryOpenedToday => 'Öppnad idag';
  @override
  String get libraryOpenedYesterday => 'Öppnad igår';
  @override
  String libraryOpenedDaysAgo(int days) => 'Öppnad för $days dagar sedan';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Öppnad ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Öppen nu';
  @override
  String get switchLibraryTitle => 'Byt bibliotek';
  @override
  String get libraryForget => 'Glöm';
  @override
  String libraryForgetTitle(String name) => 'Glömma “$name”?';
  @override
  String get libraryForgetExplained =>
      'Den försvinner ur den här listan. Mappen, anteckningarna och '
      'biblioteksinställningarna i den rör inte, och att öppna den igen '
      'tar den tillbaka.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Bevilja filåtkomst';
  @override
  String get storageAccessNeeded =>
      'Niman kan inte läsa dina anteckningar utan “All filåtkomst”. '
      'Bevilja det för att öppna ett bibliotek.';
  @override
  String get storageAccessExplained =>
      'Niman läser dina anteckningar som vanliga filer, så Android behöver '
      'ge det åtkomst till alla filer. Inget laddas upp, och bara den '
      'biblioteksmapp du väljer läses.';
  @override
  String folderAccessDenied(Object error) =>
      'Systemet gav ingen åtkomst till mappen: $error';
  @override
  String folderPickFailed(Object error) => 'Kunde inte välja en mapp: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Inställningar';
  @override
  String get libraryPathTitle => 'Bibliotekspath';
  @override
  String get reindexTitle => 'Indexera om nu';
  @override
  String get reindexDone => 'Omindexering klar';
  @override
  String get closeLibraryTitle => 'Stäng biblioteket';
  @override
  String get exportLogTitle => 'Exportera felsökningsloggen';
  @override
  String get exportLogSubtitle =>
      'Spara de registrerade händelserna till en fil du väljer';
  @override
  String get exportLogEmpty => 'Felsökningsloggbufferten är tom';
  @override
  String get quickNoteUnset => 'Inte satt ännu';
  @override
  String exportLogDone(Object target) =>
      'Felsökningsloggen exporterad till $target';
  @override
  String exportLogFailed(Object error) => 'Exporten misslyckades: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ingen exakt helt-ord-träff på “$term” hittades';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Ersatte $occurrences förekomster av “$term” i $notes anteckningar';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped öppna anteckningar hoppade över)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ingen exakt helt-ord-träff på “$term” '
      '${only == null ? 'hittades' : 'hittad i $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Om';
  @override
  String get versionTitle => 'Version';
  @override
  String get changelogTitle => 'Ändringslogg';
  @override
  String get changelogEmpty => 'Inga ändringsloggsposter tillgängliga';
  @override
  String changelogWhatsNew(String version) => 'Nytt i version $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historik';
  @override
  String get noteMenuTooltip => 'Anteckningsåtgärder';
  @override
  String get historyCurrentVersion => 'Aktuell version';
  @override
  String get historyCurrentSubtitle => 'Anteckningen som den är nu';
  @override
  String get historyToday => 'I dag';
  @override
  String get historyYesterday => 'I går';
  @override
  String get historyReasonSession => 'före redigering';
  @override
  String get historyReasonInterval => 'under redigering';
  @override
  String get historyReasonRestore => 'före återställning';
  @override
  String get historyReasonSync => 'före synk';
  @override
  String get historyReasonReplace => 'före ersättning';
  @override
  String get historyReasonUnknown => 'återfunnen';
  @override
  String get historySyncBase => 'synkbas';
  @override
  String get historyEmpty =>
      'Inga versioner än. Niman sparar en när du börjar redigera anteckningen '
      'och sedan högst en med några minuters mellanrum medan du skriver.';
  @override
  String historyKept(int kept, int limit) =>
      '$kept av $limit versioner sparade';
  @override
  String get historyBaseKept => 'Synkbasen sparas även utöver gränsen.';
  @override
  String get historyOff =>
      'Historiken är avstängd för det här biblioteket '
      '(Inställningar, Bibliotek).';
  @override
  String get historyLoadFailed => 'Kunde inte läsa historiken';
  @override
  String get historyCompareSubtitle => 'Jämförd med den aktuella versionen';
  @override
  String get historyTabChanges => 'Ändringar';
  @override
  String get historyTabVersion => 'Version';
  @override
  String get historyNoChanges => 'Samma text som den aktuella versionen.';
  @override
  String get historyRestoreAction => 'Återställ den här versionen';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Återställa versionen från $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Den aktuella texten sparas först i historiken, så du kan alltid gå '
      'tillbaka.';
  @override
  String get historyRestoreConfirm => 'Återställ';
  @override
  String historyRestored(String when) => 'Versionen från $when återställdes';
  @override
  String get historyRestoreFailed => 'Kunde inte återställa versionen';
  @override
  String get actionUndo => 'Ångra';
  @override
  String diffLineRange(int start, int end) => 'Rader $start–$end';
  @override
  String diffLineSingle(int line) => 'Rad $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 oförändrad rad' : '$count oförändrade rader';
  @override
  String get historyTakeHunk => 'Återställ här';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Återställ 1 ändring' : 'Återställ $count ändringar';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'De valda ändringarna går tillbaka till den här versionens text. '
      'Anteckningen som den är nu sparas först som en version, så du kan ångra '
      'det.';
  @override
  String get historyNoteChangedReloaded =>
      'Anteckningen ändrades medan du var här — jämförelsen har uppdaterats.';
  @override
  String get historyVersionsTitle => 'Versioner att spara';
  @override
  String get historyVersionsSubtitle => 'Per anteckning, i .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Inga' : '$count';
  @override
  String get historyIntervalTitle => 'Ny version högst var';
  @override
  String get historyIntervalSubtitle =>
      'Medan du skriver; när du börjar redigera en anteckning sparas alltid en';
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
      'Språket som talas i dina inspelningar. Att ange det är mer exakt än '
      'att låta det identifieras.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Samma som appen ($language)';
  @override
  String get transcriptionLanguageDetect => 'Identifiera automatiskt';
  @override
  String get transcriptionModelsTitle => 'Transkriberingsmodeller';
  @override
  String transcriptionModelsUsed(String size) => '$size används';
  @override
  String get transcriptionModelsInstalled => 'Nedladdade';
  @override
  String get transcriptionModelsDownloading => 'Laddas ned';
  @override
  String get transcriptionModelsAvailable => 'Tillgängliga';
  @override
  String get transcriptionModelsFooter =>
      'Modellerna ligger i appens lagring på den här enheten. De kopieras '
      'inte till biblioteket och synkas inte.';
  @override
  String get transcriptionModelDefault => 'Standard';
  @override
  String get transcriptionModelSlow => 'Långsam';
  @override
  String get transcriptionModelHintTiny => 'Snabbast, minst exakt';
  @override
  String get transcriptionModelHintBase =>
      'Bra balans mellan hastighet och precision';
  @override
  String get transcriptionModelHintSmall => 'Mer exakt, ungefär 3× långsammare';
  @override
  String get transcriptionModelHintMedium =>
      'Mycket exakt, långsam på en telefon';
  @override
  String get transcriptionModelHintLarge => 'Mest exakt, kräver mycket minne';
  @override
  String get transcriptionModelDownload => 'Ladda ned';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Ta bort modellen $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Det frigör $size. Du kan ladda ned modellen igen senare.';
  @override
  String get transcriptionModelFailed =>
      'Nedladdningen misslyckades. Kontrollera anslutningen och försök igen.';
  @override
  String get actionRetry => 'Försök igen';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Anslutningen bröts, försöker igen…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pausad vid $progress';
  @override
  String get actionResume => 'Återuppta';
  @override
  String get audioTranscribe => 'Transkribera';
  @override
  String get audioTranscribeUnsupported =>
      'Endast WAV-inspelningar på den här enheten';
  @override
  String get transcriptionQueued => 'I kö';
  @override
  String get transcriptionPreparing => 'Förbereder ljudet…';
  @override
  String transcriptionRunning(int percent) => 'Transkriberar… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Laddar ned $model · $percent %';
  @override
  String get transcriptionSaved =>
      'Transkriberingen lades till i beskrivningen';
  @override
  String get transcriptionNoSpeech =>
      'Inget tal kändes igen i den här inspelningen';
  @override
  String get transcriptionFailed => 'Transkriberingen misslyckades';
  @override
  String get transcriptionPickModelTitle => 'Välj en modell';
  @override
  String get transcriptionPickModelBody =>
      'Transkriberingen sker på den här enheten och inspelningen laddas '
      'aldrig upp. Modellen laddas ned en gång.';
  @override
  String get transcriptionPickModelAction => 'Ladda ned och transkribera';
  @override
  String get transcriptionModelRecommended => 'Rekommenderad';
  @override
  String get transcriptionExistingTitle =>
      'Inspelningen har redan en beskrivning';
  @override
  String get transcriptionExistingBody =>
      'Ersätta den med transkriberingen, eller lägga till transkriberingen '
      'under?';
  @override
  String get transcriptionAppend => 'Lägg till under';
  @override
  String get transcriptionReplace => 'Ersätt';
  @override
  String get settingsSectionSync => 'Synkronisering';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Inte konfigurerad för det här biblioteket';
  @override
  String get syncNeverSynced => 'Aldrig synkat';
  @override
  String syncLastSynced(String when) => 'Synkat $when';
  @override
  String get syncRunning => 'Synkar…';
  @override
  String syncScreenSubtitle(String library) => 'Bibliotek $library';
  @override
  String get syncUrlLabel => 'Mappens adress';
  @override
  String get syncUrlRequired => 'Ange serverns adress';
  @override
  String get syncUrlHint =>
      'Mappen måste finnas. Kopiera adressen så som servern '
      'visar den.';
  @override
  String get syncHttpWarning =>
      'Okrypterad anslutning: okej via VPN eller i ditt lokala '
      'nätverk.';
  @override
  String get syncUserLabel => 'Användare';
  @override
  String get syncUserHint =>
      'Lämna tomt om servern inte kräver inloggningsuppgifter.';
  @override
  String get syncPasswordLabel => 'Lösenord';
  @override
  String get syncPasswordHint =>
      'Sparas i enhetens nyckelring, aldrig i bibliotekets filer.';
  @override
  String get syncPasswordKeepHint =>
      'Lämna tomt för att behålla det sparade lösenordet.';
  @override
  String get syncShowPassword => 'Visa lösenord';
  @override
  String get syncHidePassword => 'Dölj lösenord';
  @override
  String get syncTestAction => 'Testa anslutningen';
  @override
  String get syncTesting => 'Testar…';
  @override
  String get syncRetargetWarning =>
      'Med en ny adress eller användare börjar nästa synk om som '
      'en första synk.';
  @override
  String get syncTestOk => 'Anslutningen fungerar';
  @override
  String get syncModeFull => 'Fullständigt läge';
  @override
  String get syncModeCompatible => 'Kompatibelt läge';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Läsa, skriva och ta bort';
  @override
  String get syncCapEtags => 'Filfingeravtryck (ETag)';
  @override
  String get syncCapNoEtags => 'Inga filfingeravtryck (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Jämför storlek och datum; laddar ner igen vid tvekan';
  @override
  String get syncCapGuarded => 'Skyddade skrivningar';
  @override
  String get syncCapUnguarded => 'Oskyddade skrivningar';
  @override
  String get syncCapUnguardedDetail =>
      'Kontrollerar filen på servern precis innan den skrivs';
  @override
  String get syncCapMove => 'Byter namn utan att ladda upp igen';
  @override
  String get syncCapNoMove => 'Inga namnbyten på servern';
  @override
  String get syncCapNoMoveDetail =>
      'Ett namnbyte blir en borttagning och en ny uppladdning';
  @override
  String get syncCompatibleNote =>
      'I kompatibelt läge fungerar synken likadant, med några '
      'fler anrop.';
  @override
  String get syncTestInvalidUrl => 'Ogiltig adress';
  @override
  String get syncTestInvalidUrlHint =>
      'Ange en adress med http:// eller https://, utan användare '
      'eller lösenord i den.';
  @override
  String get syncTestOffline => 'Servern kan inte nås';
  @override
  String get syncTestOfflineHint =>
      'Är VPN på? En adress som 10.x eller 192.168.x fungerar '
      'bara från samma nätverk.';
  @override
  String get syncTestAuth => 'Användare eller lösenord avvisades';
  @override
  String get syncTestAuthHint => 'Kontrollera dem och testa igen.';
  @override
  String get syncTestNotFound => 'Mappen finns inte';
  @override
  String get syncTestNotFoundHint =>
      'Skapa den på servern eller rätta adressen.';
  @override
  String get syncTestUnsupported => 'Inte en WebDAV-mapp';
  @override
  String get syncTestUnsupportedHint => 'Servern svarar, men inte som WebDAV.';
  @override
  String get syncTestFailed => 'Testet fungerade inte';
  @override
  String get syncNowAction => 'Synka nu';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adress, användare och lösenord';
  @override
  String get syncRetestTitle => 'Testa servern igen';
  @override
  String syncProbedAgo(String when) => 'Senaste test $when';
  @override
  String get syncDisconnectTitle => 'Koppla från det här biblioteket';
  @override
  String get syncDisconnectSubtitle => 'Filerna finns kvar här och på servern';
  @override
  String get syncDisconnectConfirmTitle => 'Koppla från synken?';
  @override
  String get syncDisconnectConfirmBody =>
      'Det här biblioteket slutar synkas på den här enheten. '
      'Ingen fil tas bort, varken här eller på servern. Om du '
      'ansluter det igen börjar den första synken om.';
  @override
  String get syncDisconnectConfirm => 'Koppla från';
  @override
  String get syncFirstTitle => 'Första synken';
  @override
  String get syncFirstIntro =>
      'Jag jämförde biblioteket med mappen på servern:';
  @override
  String get syncFirstUpload => 'Att ladda upp';
  @override
  String get syncFirstDownload => 'Att ladda ner';
  @override
  String get syncFirstBoth => 'På båda sidor';
  @override
  String get syncFirstBothHint =>
      'Identiska: ingen överföring. Olika: att lösa';
  @override
  String get syncFirstNoDelete =>
      'Den första synken tar inte bort något, varken här eller '
      'på servern.';
  @override
  String get syncStartAction => 'Starta';
  @override
  String syncMassTrashTitle(int count) => count == 1
      ? 'Flytta 1 fil till papperskorgen?'
      : 'Flytta $count filer till papperskorgen?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count av de $total synkade filerna saknas på servern. '
      'Det betyder oftast en felaktig adress, en NAS-disk som '
      'inte är monterad eller en mapp som tömts av misstag.';
  @override
  String get syncMassTrashHint =>
      'Om du verkligen tog bort dem på en annan enhet, bekräfta: '
      'här hamnar de i papperskorgen.';
  @override
  String get syncMassTrashConfirm => 'Flytta till papperskorgen';
  @override
  String syncMassDeleteTitle(int count) => count == 1
      ? 'Ta bort 1 fil från servern?'
      : 'Ta bort $count filer från servern?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count av de $total synkade filerna saknas här. Om du '
      'inte tog bort dem, avbryt och kontrollera '
      'biblioteksmappen.';
  @override
  String get syncMassDeleteConfirm => 'Ta bort från servern';
  @override
  String get syncTooltip => 'Synka';
  @override
  String get syncStageConnecting => 'Ansluter till servern…';
  @override
  String get syncStageComparing => 'Jämför med servern…';
  @override
  String syncStageApplying(int done, int total) => 'Synkar · $done av $total';
  @override
  String get syncStatusWarnings => 'Synkat med varningar';
  @override
  String syncConflictsHeader(int count) =>
      'Ändrade här och på servern · $count';
  @override
  String get syncConflictHint => 'Ingen av versionerna har rörts';
  @override
  String get syncResolveAction => 'Lös';
  @override
  String syncFailuresHeader(int count) => 'Inte synkade · $count';
  @override
  String get syncFailuresHint => 'Försöker igen vid nästa synk';
  @override
  String get syncAbortAuth => 'Servern avvisade lösenordet';
  @override
  String get syncAbortMissingPassword => 'Inget sparat lösenord';
  @override
  String get syncAbortOffline => 'Servern kan inte nås';
  @override
  String get syncAbortRemoteMissing => 'Mappen på servern finns inte längre';
  @override
  String get syncAbortUnsupported => 'Servern fungerar inte längre som WebDAV';
  @override
  String get syncAbortFailed => 'Synken fungerade inte';
  @override
  String get syncAbortNotConfirmed => 'Synken avbröts';
  @override
  String get syncAbortNothingTouched =>
      'Ingen fil har rörts. Dina ändringar finns kvar här till '
      'nästa lyckade synk.';
  @override
  String syncLastSuccess(String when) => 'Senaste lyckade synk $when';
  @override
  String get syncNoSuccessYet => 'Ingen lyckad synk än';
  @override
  String get syncUpdatePasswordAction => 'Uppdatera lösenord';
  @override
  String get syncRetryAction => 'Försök igen';
  @override
  String get syncOpenSettingsAction => 'Inställningar';
  @override
  String get syncCloseAction => 'Stäng';
  @override
  String get syncDoneSnack => 'Synkat';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synkat · 1 fil som tagits bort på annat håll ligger i '
            'papperskorgen'
      : 'Synkat · $count filer som tagits bort på annat håll '
            'ligger i papperskorgen';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synkat · 1 konflikt att lösa'
      : 'Synkat · $count konflikter att lösa';
  @override
  String get syncShowAction => 'Visa';
  @override
  String get syncConflictTitle => 'Lös konflikt';
  @override
  String get syncConflictLegend =>
      'Rader märkta − är serverns, rader märkta + är den här '
      'enhetens.';
  @override
  String get syncConflictBinary =>
      'Inte en textfil: välj vilken kopia du vill behålla.';
  @override
  String get syncConflictKeepNote =>
      'Kopian du inte behåller finns kvar i anteckningens '
      'historik.';
  @override
  String get syncKeepLocal => 'Behåll den här enhetens';
  @override
  String get syncKeepRemote => 'Behåll serverns';
  @override
  String get syncConflictIdentical => 'De två versionerna är identiska';
  @override
  String get syncConflictLoadFailed => 'Kunde inte läsa båda versionerna';
  @override
  String get syncResolveFailed => 'Kunde inte lösa konflikten';
  @override
  String get syncResolved => 'Konflikten är löst';
  @override
  String get syncSectionWhen => 'När det ska synkas';
  @override
  String get syncAutoTitle => 'Automatiskt';
  @override
  String get syncAutoSubtitle =>
      'Efter ändringar, vid öppning och med jämna mellanrum';
  @override
  String get syncIntervalTitle => 'Intervall för serverkontroll';
  @override
  String get syncIntervalSubtitle => 'Bara medan appen är öppen';
  @override
  String get syncIntervalDialogBody =>
      'För att se ändringar från andra enheter medan appen är öppen. Med '
      '”Aldrig” bara efter ändringar och vid öppning.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minut' : '$count minuter';
  @override
  String get syncIntervalNever => 'Aldrig';
  @override
  String get syncWifiOnlyTitle => 'Bara via wifi';
  @override
  String get syncWifiOnlySubtitle => 'På mobildata synkas det bara manuellt';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 ändring väntar' : '$count ändringar väntar';
  @override
  String syncRetryIn(String wait) => 'nytt försök om $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Väntar på wifi';
  @override
  String get syncWaitingForNetwork => 'Väntar på anslutning';
  @override
  String get syncMobileDataHint => '”Synka nu” använder ändå mobildata.';
  @override
  String get syncQueueKeptHint =>
      'Ändringarna finns kvar här, även om du stänger appen, och skickas av '
      'sig själva när servern svarar.';
  @override
  String get syncAutoPaused => 'Automatisk synk pausad';
  @override
  String get syncPausedAuthHint =>
      'Den återupptas när du uppdaterar lösenordet eller synkar manuellt.';
  @override
  String get syncPausedServerHint =>
      'Den återupptas när du rättar adressen eller synkar manuellt.';
  @override
  String get syncPausedConfirmHint =>
      '”Synka nu” visar vad som skulle tas bort och frågar först.';
  @override
  String get syncNeedsConfirmation => 'Väntar på din bekräftelse';
  @override
  String get syncMergeIntro =>
      'Ändringar som inte överlappar är redan sammanfogade; välj vad du vill '
      'behålla där de överlappar.';
  @override
  String get syncMergeClean =>
      'De två versionerna sammanfogas av sig själva: inget överlappar.';
  @override
  String get syncMergeNoBase =>
      'Det finns ingen gemensam version att sammanfoga på, så hela filen måste '
      'väljas.';
  @override
  String syncMergeOverlap(int index, int total) => 'Överlapp $index av $total';
  @override
  String get syncMergeFromLocal => 'Från den här enheten';
  @override
  String get syncMergeFromRemote => 'Från servern';
  @override
  String get syncMergeRemovedLines => 'Rader borttagna';
  @override
  String get syncMergeKeepLocal => 'Mina';
  @override
  String get syncMergeKeepRemote => 'Serverns';
  @override
  String get syncMergeKeepBoth => 'Båda';
  @override
  String get syncMergeSave => 'Spara sammanfogningen';
  @override
  String get syncMergeKeepWhole => 'Eller behåll en hel kopia';
}
