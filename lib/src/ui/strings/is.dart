// The Icelandic strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class IcelandicStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'janúar',
    'febrúar',
    'mars',
    'apríl',
    'maí',
    'júní',
    'júlí',
    'ágúst',
    'september',
    'október',
    'nóvember',
    'desember',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mar',
    'apr',
    'maí',
    'jún',
    'júl',
    'ágú',
    'sep',
    'okt',
    'nóv',
    'des',
  ];
  @override
  List<String> get weekdayNames => const [
    'mánudagar',
    'þriðjudagar',
    'miðvikudagar',
    'fimmtudagar',
    'föstudagar',
    'laugardagar',
    'sunnudagar',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'mán',
    'þri',
    'mið',
    'fim',
    'fös',
    'lau',
    'sun',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Korpur';
  @override
  String get trashSubtitle =>
      'Eyddir hlutir fara í .trash/ (óvirkt = varanleg eyðing)';
  @override
  String get trashAutoEmptyTitle => 'Tæma korpu sjálfkrafa';
  @override
  String get trashAutoEmptySubtitle =>
      'Eldri eyðingar hverfa endanlega þegar safnið er opnað';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Aldrei'
      : days == 1
      ? '1 dagur'
      : '$days dagar';
  @override
  String get debugLogsTitle => 'Aflausningarskrá';
  @override
  String get debugLogsSubtitle => 'Skrar atburði forritins í minnisbuffer';
  @override
  String get lineNumbersTitle => 'Línurit';
  @override
  String get lineNumbersSubtitle => 'Sýnir dálkinn með línuröðunum í ritaranum';
  @override
  String get readableLineLengthTitle => 'Læsileg línulengd';
  @override
  String get readableLineLengthSubtitle =>
      'Halda texta minnispunkts í miðjuðum dálki í stað allrar breiddar '
      'gluggans';
  @override
  String get noteColumnWidthTitle => 'Breidd dálks';
  @override
  String get noteColumnWidthSubtitle =>
      'Hversu breiður dálkur minnispunktsins er, í dílum';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Lyklaborð við opnun';
  @override
  String get keyboardOnOpenSubtitle =>
      'Sýnir lyklaborðið þegar athugasraðan er opnuð (óvirkt = við '
      'fyrstu snertingu)';
  @override
  String get editorKindSource => 'Markdown upprunatexti';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Markdown-kóði, eins og hann er skrifaður';
  @override
  String get editorKindWysiwygSubtitle => 'Forsniðinn texti, breytt á staðnum';
  @override
  String get settingsFolderToCreate => 'búa til';
  @override
  String get settingsSearchHint => 'Leita í stillingum';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 stilling fannst' : '$count stillingar fundust';
  @override
  String get settingsToggleOn => 'Kveikt';
  @override
  String get settingsToggleOff => 'Slökkt';
  @override
  String get settingsPreviewEnabledTitle => 'Forsýning';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Sýnir formgerða athugasraðuna við hlið ritara upprunatextans';
  @override
  String get switchToWysiwygTooltip => 'Skipta yfir í WYSIWYG ritara';
  @override
  String get switchToSourceTooltip => 'Skipta yfir í Markdown upprunatexta';
  @override
  String get switchToSourceLabel => 'Kóði';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Þetta minnisblað er of stórt fyrir WYSIWYG-ritilinn. Opnaðu það í '
      'Markdown upprunatexta.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Útlit';
  @override
  String get settingsSectionEditor => 'Ritari';
  @override
  String get settingsSectionLibrary => 'Bókasafn';
  @override
  String get settingsSectionReminders => 'Minnisbrot';
  @override
  String get settingsSectionShortcuts => 'Lyklaborð';
  @override
  String get keyboardShortcutsTitle => 'Lyklaborðssnarstæður';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bókasafn $name';
  @override
  String get settingsGroupLibraryHint => 'gildir eingöngu fyrir þetta bókasafn';
  @override
  String get settingsGroupMaintenance => 'Úthald';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mapar og slóðir';
  @override
  String get settingsAreaTrashHistory => 'Korpur og tímará';
  @override
  String get settingsAreaDiagnostics => 'Greining og upplýsingar';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Þarf eðlilegt lyklaborð sem er tengt';
  @override
  String get settingsSectionUpdates => 'Uppfærslur';
  @override
  String get autoUpdateTitle => 'Sjálfvirkar uppfærslur';
  @override
  String get autoUpdateSubtitle =>
      'Athuga GitHub Releases við ræsingu og á 6 klst. fresti';
  @override
  String get checkForUpdatesTitle => 'Leita að uppfærslum';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version er fáanlegt';
  @override
  String get updateUpToDate => 'Niman er uppfært';
  @override
  String get updateCheckFailed => 'Ekki tókst að leita að uppfærslum';
  @override
  String updateSavedTo(Object path) => 'Uppfærsla vistuð í $path';
  @override
  String get updateInstallerStarted => 'Uppsetningarforrit ræst';
  @override
  String get settingsSectionDiagnostics => 'Greining';
  @override
  String get settingsSpellCheckTitle => 'Stafsetningarprófun';
  @override
  String get settingsSpellCheckSubtitle =>
      'Undirstrikur rangt studdar orð meðan þú skrifar.';
  @override
  String get spellCheckDictionaryTitle => 'Orðabók';
  @override
  String get spellCheckDictionarySystem => 'Kerfisstilltan';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Veldu orðabækur';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Veldu hvert tungumál sem þetta bókasafn er skrifað á. Orðið '
      'gengur þegar einn af valdum orðabókum þekkir það; án veldu, '
      'ákvarðar kerfið.';
  @override
  String get spellCheckNoDictionaries =>
      'Engar orðabækur fundust í þessu kerfi.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Stafsetningarprófun';
  @override
  String get spellCheckTitle => 'Stafsetning';
  @override
  String get spellCheckEmpty => 'Engar stafsetningarvillur.';
  @override
  String get spellCheckUnavailable =>
      'hunspell er ekki sett upp í þessu kerfi.';
  @override
  String get spellCheckNoSuggestions => 'Engar tillagar';
  @override
  String spellCheckCount(int count) => '$count til umskoðunar';
  @override
  String spellCheckLine(int line) => 'lína $line';
  @override
  String get addWordToDictionary => 'Setja í orðbók';

  @override
  String indentWidthValue(int spaces) => '$spaces bil';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Birta';
  @override
  String get themeBrightnessSubtitle =>
      'Ljóst, dimmt eða eins og tækin er stillt';
  @override
  String get themeBrightnessSystem => 'Kerfi';
  @override
  String get themeBrightnessDay => 'Ljóst';
  @override
  String get themeBrightnessNight => 'Dimmt';
  @override
  String get themeTitle => 'Þema';
  @override
  String get themeSubtitle => 'Litir viðkomumlegs og athugasraðans';
  @override
  String get themePaletteSystem => 'Kerfi';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Þemu';
  @override
  String get themesInUse => 'Í notkun';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Nýtt þema';
  @override
  String get themeNewName => 'Heiti';
  @override
  String get themeNewStartFrom => 'Byrja frá';
  @override
  String get themeNewRandom => 'Slemmir litir';
  @override
  String get themeNameTaken => 'Þema með þessu heiti er þegar til';
  @override
  String themeDeleteBody(String name) =>
      'Eyða „$name“? Litirnir hverfa fyrir fullt og allt.';
  @override
  String get themeDuplicate => 'Tvífalda';
  @override
  String get themeMenuTooltip => 'Aðgerðir þema';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Breyta';
  @override
  String get themeEditorTitle => 'Breyta þema';
  @override
  String get themeEditorChrome => 'Viðmót';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorRolesHint =>
      'Hver litur heitir því sem útflutta skráin kallar hann';
  @override
  String get themeEditorDiscardTitle => 'Henda breytingum';
  @override
  String get themeEditorDiscardBody => 'Litirnir sem þú breyttir vistast ekki';
  @override
  String get themeEditorDiscard => 'Henda';
  @override
  String get themeEditorBadColor => 'Nota #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Flytja út';
  @override
  String themeExportDone(String where) => 'Þema flutt út í $where';
  @override
  String themeFileFailed(String error) => 'Ekki tókst að flytja þemað: $error';
  @override
  String get themeImport => 'Flytja inn';
  @override
  String get themeImportInvalid => 'Þessi skrá er ekki Niman-þema';
  @override
  String themeImportVersion(int version) =>
      'Þetta þema kemur frá nýrri Niman (útgáfa $version)';
  @override
  String themeImportBadRole(String role) =>
      'Skráin gefur engan lit fyrir „$role“';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Stærð viðkomu texta';
  @override
  String get uiTextScaleSubtitle => 'Tré, kort og ræður; yfir kerfistilltanum';
  @override
  String get noteTextScaleTitle => 'Stærð texta minnisblaða';
  @override
  String get noteTextScaleSubtitle => 'Ritari og forsýning, alltaf samstilltir';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Forsýningarhamur';
  @override
  String get previewModeSubtitle =>
      'Hvort forsýningin deilir skjánum við ritara eða tekur sæti hans';
  @override
  String get previewModeAuto => 'Hlið við hlið';
  @override
  String get previewModeSwitch => 'Heilskjár';
  @override
  String get splitRatioTitle => 'Skilhlutfall';
  @override
  String get splitRatioSubtitle =>
      'Hluti ritara þegar forsýningin er við hlið hans';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Tengjaform';
  @override
  String get linkTypeSubtitle => 'Hvað tengja hnappurinn í ritara setur inn';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Búa til vanskilin minnisblöð í';
  @override
  String get missingNoteLocationRoot => 'Rót bókasafns';
  @override
  String get missingNoteLocationCurrentFolder => 'Núverandi mappa';
  @override
  String get indentWidthTitle => 'Innhengsbreidd';
  @override
  String get indentWidthSubtitle =>
      'Bil sem bæst við hverja innhengsstig í ritaranum';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Tungumál';
  @override
  String get languageSubtitle => 'Tungumál texta forritsins sjálfs';
  @override
  String get languageSystem => 'Kerfi';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Bæta við lið';
  @override
  String get listAddTooltip => 'Bæta við lið';
  @override
  String get listEmpty => 'Engir liðir enn';
  @override
  String get listDragHandleLabel => 'Raða lið aftur';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Engar upptökur enn';
  @override
  String get audioRecord => 'Taka upp';
  @override
  String get audioStop => 'Stöðva';
  @override
  String get audioPlay => 'Spila';
  @override
  String get audioDelete => 'Eyða upptöku';
  @override
  String get audioImport => 'Flytja inn hljóðskrá';
  @override
  String get audioRecording => 'Tekur upp…';
  @override
  String get audioPermissionDenied =>
      'Aðgangi að hljóðnema hafnað — hann þarf til að taka upp.';
  @override
  String get newAudioNoteTitle => 'Nýtt raddminnisblað';
  @override
  String get newAudioNoteDefault => 'Upptakan mín';
  @override
  String get showAudioTooltip => 'Sýna upptökur';
  @override
  String get audioMessageHint => 'Skrifa athugasröfu…';
  @override
  String get audioSend => 'Senda';
  @override
  String get audioRename => 'Endurheita upptöku';
  @override
  String get audioDescriptionHint => 'Lýsa þessari upptöku…';
  @override
  String get audioEditDescription => 'Breyta lýsingu';
  @override
  String get audioDeleteNote => 'Eyða athugasröfu';
  @override
  String get audioEditNote => 'Breyta athugasröfu';
  @override
  String get audioPause => 'Gera hlé';
  @override
  String get audioEditTitle => 'Breyta titli';
  @override
  String get audioTitleHint => 'Titill upptökunnar…';
  @override
  String audioUntitled(int n) => 'Upptaka $n';
  @override
  String get audioMoreActions => 'Fleiri aðgerðir';
  @override
  String get audioDiscardRecording => 'Henda upptöku';
  @override
  String get audioPauseRecording => 'Gera hlé á upptöku';
  @override
  String get audioResumeRecording => 'Halda upptöku áfram';
  @override
  String get audioRecordingPaused => 'Í hléi';
  @override
  String get audioSavingRecording => 'Vistar…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Hraðminnisblað';
  @override
  String get trayOpen => 'Opna Niman';
  @override
  String get trayQuit => 'Loka';
  @override
  String get closeToTrayTitle => 'Loka í bakkann';
  @override
  String get closeToTraySubtitle =>
      '× á glugganum felur Niman og lætur það halda áfram, svo áminningar '
      'berast enn. Lokað er úr valmynd táknsins.';
  @override
  String get shortcutNewTodo => 'Ný verkefni';
  @override
  String get shortcutNewNote => 'Nýtt minnisblað';
  @override
  String get shortcutNewList => 'Nýr listi';
  @override
  String get shortcutNewAudio => 'Nýtt raddminnisblað';
  @override
  String get shortcutToggleSidebar => 'Sýna eða fela skjalatré';
  @override
  String get shortcutCloseTab => 'Loka núverandi minnispunkti';
  @override
  String get shortcutNextTab => 'Næsti opni minnispunktur';
  @override
  String get shortcutPreviousTab => 'Fyrri opni minnispunktur';
  @override
  String get shortcutEditorSection => 'Í ritara';
  @override
  String get shortcutFormatSection => 'Snið';
  @override
  String get shortcutFind => 'Leita';
  @override
  String get shortcutReplace => 'Finna og skipta út';
  @override
  String get shortcutSavingNote =>
      'Breytingar eru vistaðar sjálvfyrir, svo það er engin snarstaða '
      'fyrir vistun.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Hleð…';
  @override
  String get noteStatusSaving => 'Vista…';
  @override
  String get noteStatusUnsaved => 'Óvistað';
  @override
  String get noteStatusSaved => 'Vistað';
  @override
  String get noteStatusError => 'Villa';
  @override
  String get noteNotText =>
      'Þessi skrá er ekki textaminnispunktur, svo '
      'Niman getur ekki sýnt hana hér.';
  @override
  String get noteLoadFailed => 'Ekki tókst að opna þennan minnispunkt.';
  @override
  String wordCount(int count) => '$count orð';
  @override
  String get outlineTooltip => 'Efni';
  @override
  String get outlineNoHeadings => 'Engar titlar';
  @override
  String get outlineNoTitle => '(án titils)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Kraftótt';
  @override
  String get toolbarItalic => 'Skrátt';
  @override
  String get toolbarStrikethrough => 'Stríkað';
  @override
  String get toolbarSuperscript => 'Ofanastexti';
  @override
  String get toolbarUnderline => 'Undirstrik';
  @override
  String get toolbarLink => 'Tengill';
  @override
  String get toolbarCode => 'Kóðablokk';
  @override
  String get toolbarImage => 'Setja inn mynd';
  @override
  String get toolbarHeading => 'Titill';
  @override
  String get toolbarList => 'Listi';
  @override
  String get toolbarOrderedList => 'Talnalista';
  @override
  String get toolbarQuote => 'Vist';
  @override
  String get toolbarIndent => 'Innhengja';
  @override
  String get toolbarOutdent => 'Minnka innheng';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Verkfæri';
  @override
  String get editorToolsTitle => 'Verkfæri ritils';
  @override
  String get toolCountListTitle => 'Telja lista';
  @override
  String get toolCountListSubtitle =>
      'Leggur saman það sem línurnar telja upp, sem gátlista';
  @override
  String get toolCountListNeedsList =>
      'Þessi minnispunktur hefur engan lista til að telja';
  @override
  String get tallySourceLabel => 'Listi';
  @override
  String get tallyCutLabel => 'Lesa hverja línu sem';
  @override
  String get tallyCutDash => 'Nafn - gildi';
  @override
  String get tallyCutColon => 'Nafn: gildi';
  @override
  String get tallyCutCommas => 'Gildi aðgreind með kommu';
  @override
  String get tallyCutWhole => 'Öll línan sem eitt gildi';
  @override
  String get tallySortLabel => 'Röð';
  @override
  String get tallySortCount => 'Flest fyrst';
  @override
  String get tallySortAlphabetical => 'Í stafrófsröð';
  @override
  String get tallySortFirstSeen => 'Eins og í listanum';
  @override
  String get tallyInsert => 'Setja inn';
  @override
  String get tallyUpdate => 'Uppfæra';
  @override
  String get tallyNothingToCount => 'Hér er ekkert að telja';
  @override
  String get headingDialogTitle => 'Titilstig';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Ritara tólalista';
  @override
  String get toolbarSettingsHint =>
      'Dragðu til að raða; augað sýnir eða felur hnapp.';
  @override
  String get toolbarShowButton => 'Sýna';
  @override
  String get toolbarHideButton => 'Fela';
  @override
  String get toolbarResetOrder => 'Endurstilla';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Sýna forsýningu';
  @override
  String get showEditorTooltip => 'Sýna ritara';
  @override
  String get enterFullScreenTooltip => 'Heilskjár';
  @override
  String get exitFullScreenTooltip => 'Hætta í heilskjá';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(hálfraðinn HTML borð)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Leita í minnisblöðum';
  @override
  String get searchModeWords => 'Orð';
  @override
  String get searchModeContains => 'Innifalið';
  @override
  String get searchEmptyHint =>
      'Skrifa til að leita í bókasafninu, eða key = value til að '
      'sila að frontmatter';
  @override
  String get searchTooShortHint => 'Skrifa að minnsta kosti 2 staf';
  @override
  String get searchNoMatches => 'Engar samanburðar';
  @override
  String get searchLoadMore => 'Sýna fleiri';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Skipta út…';
  @override
  String get replaceInNoteAction => 'Skipta út í þessu minnisblaði…';
  @override
  String get replaceInThisNote => 'Skipta út í þessu minnisblaði';
  @override
  String get replaceWithLabel => 'Skipta út í';
  @override
  String get replaceCaseSensitive => 'Ágreinir hástafir/lágstafir';
  @override
  String get replaceWholeWordsHint =>
      'ekki er ekki skipt um nema nákvæmar heilar orð';
  @override
  String get replaceConfirm => 'Skipta út';
  @override
  String get replaceCancel => 'Loka';
  @override
  String get replaceUnavailable => 'Umskipti er ekki tiltækt núna';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Finna í minnisblaðinu';
  @override
  String get editorFindHint => 'Finna';
  @override
  String get editorReplaceHint => 'Skipta út';
  @override
  String get editorFindCaseTooltip => 'Há/lágstafir';
  @override
  String get editorFindPreviousTooltip => 'Fyrri samanburður';
  @override
  String get editorFindNextTooltip => 'Næsti samanburður';
  @override
  String get editorFindCloseTooltip => 'Loka leit';
  @override
  String get editorFindReplaceModeTooltip => 'Umskiptahamur';
  @override
  String get editorReplaceOneTooltip => 'Skipta út þennan samanburð';
  @override
  String get editorReplaceAllTooltip => 'Skipta út öllum';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Merki';
  @override
  String get tagsTitle => 'Merki';
  @override
  String get tagsEmpty =>
      'Engin merki enn — bættu við #merki eða tags í frontmatter';
  @override
  String get tagsBackTooltip => 'Aftur í leit';
  @override
  String get tagsNotesEmpty => 'Engin minnisblöð með þessu merki';
  @override
  String tagsNotesCapped(int limit) =>
      'Aðeins fyrstu $limit sýndar — leitaðu eftir marki til að '
      'einkavæða';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Tengillinn fannst ekki';
  @override
  String get headingNotFoundTitle => 'Titillinn fannst ekki';
  @override
  String get ambiguousLinkTitle => 'Fleiri minnisblöð passa';
  @override
  String get openLinkFailed => 'Það gekk ekki að opna tengilinn';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Minnisblaðið er ekki til';
  @override
  String missingNoteDialogBody(String path) => 'Búa til „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Mappan „$folder“ er ekki til';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Opið';
  @override
  String get todoDone => 'Lokið';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Allar dagsetningar';
  @override
  String get todoFilter => 'Sil';
  @override
  String get todoNoTokens => 'Engir tokenar í þessari listanum';
  @override
  String get todoCountOpen => 'opið';
  @override
  String get todoCountDone => 'lokið';
  @override
  String get todoEmptyOpen => 'Engin opið verkefni enn';
  @override
  String get todoEmptyDone => 'Ekkert lokið enn';
  @override
  String get todoEmptyFiltered => 'Engin verkefni sem passa';
  @override
  String get todoTitle => 'Verkefni';
  @override
  String get todoAddTooltip => 'Bæta við verkefni';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt form';
  @override
  String get todoHelpTooltip => 'Stuðningur við form';
  @override
  String get todoHelpIntro =>
      'Verkefnin þín er eitt venjulegt textaskjal, eitt verkefni á '
      'línu. Niman skrifar samskiptastefnu fyrir þig, en felur ekkert: '
      'þú getur breytt skjala í hvaða ritara sem er, og Niman skilir '
      'það til baka.';
  @override
  String get todoHelpFilesTitle => 'Tvö skjal';
  @override
  String get todoHelpFilesBody =>
      'Opið verkefni eru í todo.txt í rót bókasafns. Lokað af '
      'verkefni færi línu í done.txt, svo todo.txt heldst stutt. Ef '
      'lokið lína kemur aftur í todo.txt, arkivar Niman hana í næstu '
      'skjallesingu.';
  @override
  String get todoHelpLineTitle => 'Byggingar línu';
  @override
  String get todoHelpLineBody =>
      'Allt fyrir framan lýsingu er valfrjálst og verður að koma í '
      'þessari röð:';
  @override
  String get todoHelpDoneBody =>
      'Býr til lokið verkefni. Niman bæti við því þegar þú merkir '
      'kassann.';
  @override
  String get todoHelpPriority => '(A) til (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Forrangur. A er hærst. Birt sem merki í listanum.';
  @override
  String get todoHelpDatesBody =>
      'Dagsetning lokið, síðan dagsetning búins. Með aðeins einni '
      'dagsetningu er hún dagsetning búins, nema línan byrjar á x.';
  @override
  String get todoHelpTokensTitle => 'Verkefni, aðstæður og merki';
  @override
  String get todoHelpTokensBody =>
      'Hvar sem er í lýsingunni, orð með einum af þessum forsíðum '
      'verður chip sem þú getur silað með. Ekkert er forúthávið: '
      'token er til þegar þú skrifar það.';
  @override
  String get todoHelpProjectBody =>
      'Hvað verkefnið er um, t.d. +bygging eða +ritgerð.';
  @override
  String get todoHelpContextBody =>
      'Hvar eða hvernig þú munt framkvæma það, t.d. @heimili eða @sími';
  @override
  String get todoHelpHashtagBody =>
      'Frjálst merki, fyrir allt sem hin tvö ekkert hafa';
  @override
  String get todoHelpTagsTitle => 'Dagsetningar og minnisbrot';
  @override
  String get todoHelpTagsBody =>
      'Þessar eru key:value merki. Niman skrifar þær frá dialogi '
      'verkefnis og skilar þeim hvar sem þeir birtast á línu.';
  @override
  String get todoHelpDueBody =>
      'Dagsetning lokið. Ákvarðar lit merks og sil lokið.';
  @override
  String get todoHelpRemBody =>
      'Hvenær ábendingin er send, í staðbundinn tíma þíns. Keyrir '
      'jafnvel með slökkuðu skjá og lokuðu forriti.';
  @override
  String get todoHelpRemDesktop =>
      'Á desktop, Niman þarf að keyra þegar tími kominn er: minnisbrot '
      'sýnist meðan forritið er opið, og ef lokuð er keyrir ekkert.';
  @override
  String get todoHelpOtherBody =>
      'Verða vistað nákvæmlega eins og skrifuð, svo merki frá öðrum '
      'todo.txt forritum lifa flutningnum. Niman virkjar ekki á þeim, '
      'rec: included: endurtekinn verkefni endurtekist ekki enn.';
  @override
  String get todoHelpEditTitle => 'Ritun utan Niman';
  @override
  String get todoHelpEditBody =>
      'Verkefni sem þú hafir ekki snertur kemur aftur bit af bit, '
      'með óvenjuleg bil. Breytu einni línu og Niman endurskrifar '
      'aðeins þá línu í formi sínum, og sleppur rest skjalsins.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Bæta við verkefni';
  @override
  String get todoEditTitle => 'Breyta verkefni';
  @override
  String get todoDescriptionHint => 'Lýsing';
  @override
  String get todoCancel => 'Hætta við';
  @override
  String get todoSave => 'Vista';
  @override
  String get todoEditAction => 'Breyta';
  @override
  String get todoDeleteAction => 'Eyða';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Of seint';
  @override
  String get todoDueToday => 'Í dag';
  @override
  String get todoDueNext7 => 'Næstu 7 daga';
  @override
  String get todoDueNoDate => 'Án dagsetningar';
  @override
  String get todoRowDue => 'Lokið';
  @override
  String get todoRowDueToday => 'Lokið í dag';
  @override
  String get todoSortTooltip => 'Raða';
  @override
  String get todoSortDue => 'Dagsetning lokið';
  @override
  String get todoSortPriority => 'Forrangur';
  @override
  String get todoSortCreation => 'Dagsetning búins';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Án forrang';
  @override
  String get todoNoPriorityShort => 'Ekkert';
  @override
  String get todoMorePriorities => 'Fleiri…';
  @override
  String get todoPriorityTitle => 'Forrangur';
  @override
  String get todoNoDueDate => 'Án dagsetningar lokið';
  @override
  String get todoNoReminder => 'Án minnisbrot';
  @override
  String get todoAddProject => '+ Verkefni';
  @override
  String get todoAddContext => '@ Aðstæður';
  @override
  String get todoAddHashtag => '# Merki';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Minnisbrot fyrir verkefni';
  @override
  String get todoReminderChannelDescription =>
      'Áætluð ókallar fyrir verkefni með tíma minnisbrot.';
  @override
  String get todoReminderBody => 'Minnisbrot fyrir verkefni';
  @override
  String get todoReminderFallbackTitle => 'Minnisbrot fyrir verkefni';
  @override
  String get todoReminderBlocked =>
      'Abendingar eru slökktar, svo minnisbrot mun ekki birtast.';
  @override
  String get todoReminderBattery =>
      'Rafhlaðaaðlagning er virk fyrir Niman. Kerfið getur sett forrit '
      'í svefn ástand og tapa fyrir væntum minnisbrotum.';
  @override
  String get todoReminderInexact =>
      'Þetta tæki leyfir ekki nákvæma ókallar, svo minnisbrot gæti '
      'komit nokkrum mínútum seinni með slökkuðu skjá.';
  @override
  String get reminderShowTokensTitle => 'Merki í ábendingum minnisbrot';
  @override
  String get reminderShowTokensSubtitle =>
      'Heldur +verkefni, @aðstæður og #merki í texta ábendingar. Óvirkt '
      'sýnir aðeins verkefnið sem þú stillti.';
  @override
  String get todoReminderFixAction => 'Opna stilling';
  @override
  String get todoReminderDismissAction => 'Hafna';
  @override
  String get todoReminderDue => 'Lokið';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Hætta við';
  @override
  String get actionCreate => 'Búa til';
  @override
  String get actionNew => 'Nýtt';
  @override
  String get actionSave => 'Vista';
  @override
  String get actionClear => 'Hreinsa';
  @override
  String get actionChoose => 'Velja';
  @override
  String get actionDelete => 'Eyða';
  @override
  String get actionRename => 'Endurheita';
  @override
  String get actionMove => 'Færa';
  @override
  String get saveAndClose => 'Vista og loka';
  @override
  String get closeUnsavedTitle => 'Óvistuðar breytingar';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}“ hefur breytingar sem enn eru ekki '
          'vistaðar. Vista fyrir lokun?';
    }
    return 'Í ${names.length} minnisblöðum eru breytingar sem enn eru '
        'ekki vistaðar. Vistuðu fyrir lokun?';
  }

  @override
  String get closeSaveFailed => 'Gat ekki vistað; er enn opið.';
  @override
  String get actionRestore => 'Endurheimta';
  @override
  String get actionEmpty => 'Hæla';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Fela hliðarskjal (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Sýna hliðarskjal (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Lágmarka';
  @override
  String get windowMaximizeTooltip => 'Hámarka';
  @override
  String get windowRestoreTooltip => 'Endurheimta';
  @override
  String get windowCloseTooltip => 'Loka';
  @override
  String get tabFiles => 'Skjal';
  @override
  String get tabSearch => 'Leita';
  @override
  String get tabSettings => 'Stillingar';
  @override
  String get quickNoteTitle => 'Hraðminnisblað';
  @override
  String get treeEmpty => 'Engin minnisblöð enn';
  @override
  String get selectANote => 'Velja minnisblað';
  @override
  String get showListTooltip => 'Sýna list';
  @override
  String get editRawTooltip => 'Breyta hrátt';
  @override
  String get sortAscTooltip => 'Raða A-Ö';
  @override
  String get sortDescTooltip => 'Raða Ö-A';
  @override
  String get newNoteTitle => 'Nýtt minnisblað';
  @override
  String get newItemTooltip => 'Nýtt';
  @override
  String get closeMenuTooltip => 'Loka';
  @override
  String get newFolderTitle => 'Ný mappa';
  @override
  String get newNoteSameFolder => 'Nýtt minnisblað í sömu möppu';
  @override
  String get newFromTemplateSameFolder => 'Nýtt úr sniðmáti í sömu möppu';
  @override
  String trashOriginalPath(String path) => 'var í $path';
  @override
  String get trashOriginalRoot => 'var \u00ed r\u00f3t b\u00f3kasafnsins';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 atri\u00f0i' : '$count atri\u00f0i';
  @override
  String get newNoteHere => 'Nýtt minnisblað hér';
  @override
  String get newFolderHere => 'Ný mappa hér';
  @override
  String get newListNoteTitle => 'Nýtt listaminnisblað';
  @override
  String get newListNoteDefault => 'Listi minn';
  @override
  String get setAsQuickNote => 'Stilla sem hraðminnisblað';
  @override
  String get currentQuickNote => 'Núverandi hraðminnisblað';
  @override
  String get pinnedSection => 'Fastgirt';
  @override
  String pinnedSectionCount(int count) => 'Fastgirt · $count';
  @override
  String get templateFolderTitle => 'Mappa fyrir smíðir';
  @override
  String get newFromTemplateTitle => 'Nýtt frá smíð';
  @override
  String get newFromTemplateHere => 'Nýtt frá smíð hér';
  @override
  String get templateFormTitle => 'Fylla út smíð';
  @override
  String get templateFormBacklink => 'Tengd frá';
  @override
  String get templateFormNoNote => 'Án minnisblaðs';
  @override
  String get templateFormPickNote => 'Velja minnisblað';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Stafsetningar staðir í smíð';
  @override
  String get templateHelpSubtitle =>
      'Dagsetning, titill og önnur gildi til að fylla út';
  @override
  String get quickNoteSubtitle => 'Minnisblaðið sem flipinn Flýtiglós opnar';
  @override
  String get listFolderSubtitle => 'Nýju verkefnalistarnir';
  @override
  String get templateFolderSubtitle => 'Uppspretta „Nýtt úr sniðmáti“';
  @override
  String get attachmentsFolderSubtitle =>
      'Myndir og hljóð sett inn í minnisblað';
  @override
  String get templateHelpIntro =>
      'Smíð er venjulegt minnisblað með holum. Nýtt minnisblað úr '
      'henni fær textann og holurnar eru fylltar.';
  @override
  String get templateHelpUnknown =>
      'Stafsetningsstaður sem Niman ekki þekkir heldst nákvæmlega eins '
      'og skrifuð, svo stafvilla birtist í minnisblaðinu en ekki broti '
      'línu.';
  @override
  String get templateHelpValuesTitle => 'Gildi';
  @override
  String get templateHelpTitleBody => 'Heitið sem minnisblaðið fær.';
  @override
  String get templateHelpDateBody =>
      'Í dag og núverandi tími. Báðar tekja form: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Dagsetning og tími saman.';
  @override
  String get templateHelpUuidBody => 'Ný auðkennsla, ólík í hverjum birtum.';
  @override
  String get templateHelpCounterBody =>
      'Tala sem eykst nafn, vistuð yfir endurræsingar: fyrsta '
      'minnisblaðið fær 1, það næsta 2. Sama nafn í einu minnisblaði '
      'skrifar sama tölu; samsettu með |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Setur bendilinn hér þegar minnisblaðið er búið til; merkið sjálft er '
      'ekki skrifuð. Fyrsta merkið vinnur, án sila, aðeins nýjar '
      'minnisblöð — og lyklaborð opnast jafnvel þegar sjálfvirkur '
      'fókus er slökktur.';
  @override
  String get templateHelpDatesTitle => 'Skrifa dagsetningar';
  @override
  String get templateHelpDatesBody =>
      'Þessar staðar fyrir hlutum dagsetningar í form. Allt annað er '
      'bóstaflengt, og texti í einföldum merkjum er einnig bóstaflengt. '
      'Nöfn mánaða og daga fylgja tungumáli forritsins.';
  @override
  String get templateHelpYear => 'ár: 2026, 26';
  @override
  String get templateHelpMonth => 'mánuður: 03, 3, Mars, Mar';
  @override
  String get templateHelpDay => 'dagur: 09, 9, Mánudagar, Mán';
  @override
  String get templateHelpTime => 'klukkutímar, mínútur, sekúndur';
  @override
  String get templateHelpWeek => 'ISO vika og fjórðungur: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Sil';
  @override
  String get templateHelpFiltersBody =>
      'Gildin geta fylgast af silum, sett frá vinstri á hægri.';
  @override
  String get templateHelpCaseBody =>
      'Há, lág og fyrsti hástafir hvers orðs — orð sem þú hefur '
      'skrifað sjálfur með hástafi heldst óbreytt.';
  @override
  String get templateHelpSlugBody =>
      'Form texta fyrir tengla, til að byggja wikilink.';
  @override
  String get templateHelpPadBody =>
      'Kortar endann; fyllir með núllum upp í breidd; notar forfelling '
      'þegar gildið er tómt.';
  @override
  String get templateHelpShiftBody =>
      'Færi dagsetningu eftir daga, vikur, mánuði eða ár — kynning '
      'næstu viku, skjal af síðasta mánuði.';
  @override
  String get templateHelpSnapBody =>
      'Festu dagsetningu í byrjun eða lok sína viku, mánuð eða ár.';
  @override
  String get templateHelpAskTitle => 'Eitthvað spyr þig';
  @override
  String get templateHelpAskBody =>
      'Form birtist áður en minnisblaðið er búið til, eitt svið fyrir '
      'hverjar spurningar — og eitt fyrir tengil aftur, þegar smíðin '
      'biðst eitt. Sama merkið tvisvar er ein spurning, og svör hennar '
      'fyllir alla birta — mappa og heiti skjals innifalið.';
  @override
  String get templateHelpAskFieldBody =>
      'Skriftsvid; texti eftir tvær semmur er það sem hefur að fara.';
  @override
  String get templateHelpChoiceBody => 'Val úr listanum, aðskilin með kommu.';
  @override
  String get templateHelpWhereTitle => 'Hvert minnisblaðið fer';
  @override
  String get templateHelpWhereBody =>
      'Þetta er ekki texti: það er leiðbeiningar, og lifir í niman: '
      'blokk í sama frontmatter smíðans. Blokk er virkjað og síðan er '
      'hún fjarlægð, svo hún birtist aldrei í minnisblaðinu. Gildi '
      'þeirra geta innihaldið stafsetningar staði.';
  @override
  String get templateHelpFolderBody =>
      'Mappa þar sem minnisblaðið er búið til, búin til ef hún er ekki '
      'til. Án hennar fer minnisblaðið þangað sem þú varst.';
  @override
  String get templateHelpFilenameBody =>
      'Hvað minnisblaðið heitir. Smíð sem segir það ekki er ekki '
      'spurð um nafn.';
  @override
  String get templateHelpAppendBody =>
      'Bætir við minnisblaðið ef það er þegar til, í stað þess að búa '
      'til annað. Þannig safnast mánuður af fundum í eitt skjal.';
  @override
  String get templateHelpOpenBody =>
      'Hvað gerist eftir að minnisblaðið er búið til: ritill (sjálfgefið), '
      'forskoðun eða ekkert — minnisblaðið er auðkennt og þú verður '
      'þar sem þú varst.';
  @override
  String get templateHelpAroundTitle => 'Hvar kemur það frá';
  @override
  String get templateHelpParentBody =>
      'Minnisblaðið sem þú velur í forminu, sjálfgefið það sem er á '
      'skjánum; skrifaðu [[{{parent}}]] fyrir tengil aftur í það.';
  @override
  String get templateHelpFolderValueBody =>
      'Mappan þar sem minnisblaðið lendir.';
  @override
  String get templateHelpClipboardBody =>
      'Það sem er á klemmuspjaldinu, og val ritilsins þegar minnisblaðið '
      'er búið til út frá því.';
  @override
  String get templateHelpIncludeTitle => 'Endurnýting hluta';
  @override
  String get templateHelpIncludeBody =>
      'Setur inn aðra smíð, svo tíu smíðar geta deilt sama checklist. '
      'Leitast fyrst í smíðamappa, og .md getur verið yfirséð. Spurningar '
      'hennar bætast við sama form.';
  @override
  String get templateHelpExampleTitle => 'Allt saman';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ smíð „$path" er ekki til';
  @override
  String includeCycle(String path) => '⚠ „$path" inniheldur sjálfa sig';
  @override
  String includeTooDeep(String path) => '⚠ „$path" er teygð of djúpt';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter ekki skilað: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter „$template" ekki skilað, svo mappa og heiti skjals '
      'hennar gerðu ekkert: $reason';
  @override
  String get templatePickerTitle => 'Velja smíð';
  @override
  String templatePickerEmpty(String folder) =>
      'Engar smíðar enn. Settu minnisblað í $folder/ og það verður '
      'ein.';

  // Tree actions.
  @override
  String get actionPin => 'Fastgripa';
  @override
  String get actionUnpin => 'Leyfa lausa';
  @override
  String get pinToWidget => 'Festu á forsíðu-vísí';
  @override
  String get pinnedForWidget => 'Fest: settu núna vísíð Nota á forsíðuna';
  @override
  String get pinWidgetUnavailable => 'Forsíðu-vísí eru til fáan á Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Sýna í skráastjóra';
  @override
  String get openInDefaultApp => 'Opna í sjálfgefnu forriti';
  @override
  String get newNoteTabTooltip => 'Nýr minnispunktur í nýjum flipa';
  @override
  String get openNotesTooltip => 'Opnir minnispunktar';
  @override
  String get closeTabTooltip => 'Loka';
  @override
  String get openInNewTab => 'Opna í nýjum flipa';
  @override
  String get splitRight => 'Skipta til hægri';
  @override
  String get splitDown => 'Skipta niður';
  @override
  String get moveToOtherPane => 'Færa í hina rúðuna';
  @override
  String get openBeside => 'Opna til hliðar';
  @override
  String get closeAllNotes => 'Loka öllu';
  @override
  String get sidePanelTooltip => 'Sýna eða fela hliðarspjaldið';
  @override
  String get historyAllVersions => 'Allar útgáfur';
  @override
  String get commandPaletteTitle => 'Skipanaspjald';
  @override
  String get goToNoteTitle => 'Fara í minnispunkt';
  @override
  String get paletteGroupNote => 'Minnispunktur';
  @override
  String get paletteGroupEditor => 'Ritill';
  @override
  String get paletteGroupView => 'Sýn';
  @override
  String get paletteGroupLibrary => 'Safn';
  @override
  String get paletteGroupGoTo => 'Fara í';
  @override
  String get commandsTitle => 'Skipanir';
  @override
  String get commandsIntro =>
      'Skipanaspjaldið býður aðeins upp á skipanir sem hægt er að keyra þar '
      'sem þú ert. Hér eru þær allar, og hvenær hver birtist.';
  @override
  String get commandNeedNone => 'Alltaf tiltæk';
  @override
  String get commandNeedOpenNote => 'Krefst opinnar glósu';
  @override
  String get commandNeedWideWindow => 'Aðeins í breiðum glugga';
  @override
  String get commandNeedDockRoom =>
      'Krefst glugga sem er nógu breiður fyrir hliðarspjaldið';
  @override
  String get commandNeedDesktop => 'Aðeins á tölvu';
  @override
  String get commandNeedNotInZen => 'Ekki í Zen-ham';
  @override
  String get commandNeedZenRoom => 'Tölva, með glósu opna í flipa';
  @override
  String get commandNeedPreview => 'Með forskoðun á, í textaglósu';
  @override
  String get commandNeedTwoEditors => 'Með báða ritla virka';
  @override
  String get paletteHint => 'Leita í skipunum og minnispunktum';
  @override
  String get paletteNoResults => 'Ekkert fannst';
  @override
  String get paletteCommands => 'Skipanir';
  @override
  String get paletteNotes => 'Minnispunktar';
  @override
  String get paletteFooter =>
      '↑↓ til að færa · ↵ til að nota · esc til að loka';
  @override
  String get paletteFooterTouch => 'Ýttu til að nota · nælan heldur því efst';
  @override
  String get palettePinned => 'Fest';
  @override
  String get palettePin => 'Festa';
  @override
  String get paletteUnpin => 'Losa';
  @override
  String get palettePinFooter => 'alt+P til að festa';
  @override
  String get spellCheckScanning => 'Athugar minnismiðann…';
  @override
  String get spellCheckAgain => 'Athuga aftur';
  @override
  String spellCheckCapped(int count) =>
      'Fyrstu $count eru sýndar: lagaðu nokkrar og athugaðu svo aftur fyrir '
      'restina';
  @override
  String get dropHint =>
      'Slepptu Markdown-skrám til að opna þær, eða möppu til að flytja hana '
      'inn';
  @override
  String get dropNothing =>
      'Skjáborðið afhenti engar skrár fyrir þetta sleppi.';
  @override
  String get importFolderAction => 'Flytja inn';
  @override
  String dropRejected(String names) =>
      'Hér opnast aðeins Markdown-skrár og möppur: $names';
  @override
  String importFolderTitle(String name) => 'Flytja inn „$name“?';
  @override
  String importFolderBody(int count) =>
      'Markdown-skrár hennar ($count) eru afritaðar í nýja möppu í safninu. '
      'Mappan sem þú slepptir helst óbreytt.';
  @override
  String importFolderDone(String folder) => 'Flutt inn í $folder';
  @override
  String importFolderEmpty(String name) => 'Engar Markdown-skrár í $name';
  @override
  String get openFileTitle => 'Opna skrá';
  @override
  String get outsideFileNote =>
      'Utan safns: vistuð þar sem hún er, ekki í skrá, engin saga, tenglum '
      'ekki fylgt';
  @override
  String get typewriterOn => 'Kveikja á ritvélarham';
  @override
  String get typewriterOff => 'Slökkva á ritvélarham';
  @override
  String get typewriterTitle => 'Ritvélarhamur';
  @override
  String get formatNoteTitle => 'Taka til í Markdown';
  @override
  String get formatNoteDone => 'Tekið var til í glósunni.';
  @override
  String get formatNoteAlreadyTidy => 'Glósan var þegar snyrtileg.';
  @override
  String get typewriterSubtitle =>
      'Línan sem þú skrifar helst fyrir miðju ritilsins';
  @override
  String get zenMode => 'Zen-hamur';
  @override
  String get zenModeEnter => 'Fara í zen-ham';
  @override
  String get zenModeLeave => 'Hætta í zen-ham';
  @override
  String get keySpace => 'Bil';
  @override
  String get keyEnter => 'Enter';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Bakklykill';
  @override
  String get keyDelete => 'Delete';
  @override
  String get keyArrowUp => 'Upp';
  @override
  String get keyArrowDown => 'Niður';
  @override
  String get keyArrowLeft => 'Vinstri';
  @override
  String get keyArrowRight => 'Hægri';
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
  String get shortcutNone => 'Enginn flýtilykill';
  @override
  String get shortcutRestoreDefaults => 'Endurheimta sjálfgefið';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Setja alla flýtilykla aftur eins og Niman afhendir þá?';
  @override
  String get shortcutRevert => 'Aftur í sjálfgefið';
  @override
  String get shortcutClear => 'Fjarlægja flýtilykil';
  @override
  String get shortcutCapturePrompt =>
      'Ýttu á lyklana. Esc og Tab eru líka tekin: Hætta við er leiðin út.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Bættu við Ctrl, Alt eða Meta: stakur lykill er til að skrifa.';
  @override
  String get shortcutMove => 'Færa hann';
  @override
  String get shortcutUseAnyway => 'Nota samt';
  @override
  String get shortcutUndo => 'Afturkalla';
  @override
  String get shortcutRedo => 'Endurtaka';
  @override
  String get shortcutChange => 'Breyta flýtilykli';
  @override
  String shortcutCaptureTitle(String command) => 'Lyklar fyrir $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys tilheyrir þegar $other. Færa hingað? $other verður án '
      'flýtilykils.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys er líka $what í textareitum og ritlinum. Þar tekur skipunin þín '
      'hann.';
  @override
  String get openFileMissing => 'Skrá þessa minnisblaðs er ekki á disknum';
  @override
  String get openFileFailed => 'Ekki tókst að opna þetta minnisblað utan Niman';

  @override
  String get movedToTrash => 'Fært í korpu';
  @override
  String get deletedMessage => 'Eytt';
  @override
  String deleteToTrashConfirm(String name) => '$name verður fært í .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name verður varanlega eytt';
  @override
  String get chooseDestination => 'Velja áfangastað';
  @override
  String get libraryRoot => 'Rót bókasafns';
  @override
  String moveTitle(String name) => 'Færa $name';
  @override
  String headingLevelLabel(int level) => 'Titilstig $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ekkert hraðminnisblað enn. Veldu fast minnisblað eða búðu '
      'til nýtt — hraðminnisblaðið opnast hér.';
  @override
  String get quickNoteChooseAction => 'Velja minnisblað…';
  @override
  String get quickNoteCreateAction => 'Búa til nýtt minnisblað…';
  @override
  String get quickNoteNewTitle => 'Nýtt hraðminnisblað';
  @override
  String get quickNotePickerTitle => 'Velja hraðminnisblað';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Ný mappa';
  @override
  String get folderPickerEmpty => 'Engar mappar enn';
  @override
  String get listFolderTitle => 'Mappa lista';
  @override
  String get attachmentsFolderTitle => 'Mappa fyrir viðhengi';

  // Trash (M1).
  @override
  String get trashEmpty => 'Korpan er tóm';
  @override
  String get trashEmptyAction => 'Hæla korpu';
  @override
  String get trashEmptyConfirm =>
      'Þetta eyðir varanlega öllu því sem er í korpumappanum, innifalið '
      'hluti sem Niman ekki setti þar.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name verður varanlega eytt (án endurheimta)';
  @override
  String get trashDeletePermanently => 'Eyða varanlega';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Opnaðu möppu með Markdown-minnisblöðum sem bókasafnið þitt';
  @override
  String get openLibraryExisting => 'Opna tilverandi';
  @override
  String get openLibraryCreate => 'Búa til nýtt';
  @override
  String get openLibraryCreateTitle => 'Búa til nýtt bókasafn';
  @override
  String get openLibraryFolderName => 'Nafn mappa';
  @override
  String get openLibraryChooseFolder => 'Velja mappa bókasafns';
  @override
  String get openLibraryChooseParent =>
      'Velja mappa þar sem bókasafnið á að búa til';
  @override
  String get openLibraryUnsupported =>
      'Þessi mappa er ekki stuðlað. Veldu mappu í vistun ritara.';
  @override
  String indexingCount(int done, int total) => '$done af $total minnisblöðum';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Bókasöfn þín';
  @override
  String get libraryUnreachable => 'Ónálganlegt';
  @override
  String get libraryOpenedToday => 'Opnað í dag';
  @override
  String get libraryOpenedYesterday => 'Opnað í gær';
  @override
  String libraryOpenedDaysAgo(int days) => 'Opnað $days daga síðar';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Opnað ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Opna nú';
  @override
  String get switchLibraryTitle => 'Skipta um bókasafn';
  @override
  String get libraryForget => 'Gleyma';
  @override
  String libraryForgetTitle(String name) => 'Gleyma „$name"?';
  @override
  String get libraryForgetExplained =>
      'Það hverfur af þessum lista. Mappan, minnisblöðin og stillingar '
      'bókasafnsins haldast óbreytt, og ef það er opnað aftur fer það '
      'aftur á listann.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Leyfa aðgang að skjölum';
  @override
  String get storageAccessNeeded =>
      'Niman getur ekki lesið minnisblöðin þín án „aðgangs að öllum '
      'skjölum". Leyfa til að opna bókasafn.';
  @override
  String get storageAccessExplained =>
      'Niman les minnisblöðin þín sem venjulegar skrár, svo Android '
      'verður að leyfa aðgang að öllum skjölum. Ekkert er haldið uppi, '
      'og aðeins mappa bókasafnsins sem þú velur er lesin.';
  @override
  String folderAccessDenied(Object error) =>
      'Kerfið gaf ekki aðgang að mappanum: $error';
  @override
  String folderPickFailed(Object error) => 'Gat ekki valið mappu: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Stillingar';
  @override
  String get libraryPathTitle => 'Leið bókasafns';
  @override
  String get reindexTitle => 'Endurbygga vísu núna';
  @override
  String get reindexDone => 'Vísu endurbyggt';
  @override
  String get closeLibraryTitle => 'Loka bókasafni';
  @override
  String get exportLogTitle => 'Flytja út aflausningarskrá';
  @override
  String get exportLogSubtitle => 'Vista skráðar atburði í skjal sem þú velur';
  @override
  String get exportLogEmpty => 'Buffer aflausningarskrár er tómur';
  @override
  String get quickNoteUnset => 'Ekkert stillt enn';
  @override
  String exportLogDone(Object target) => 'Skrá flutt út í $target';
  @override
  String exportLogFailed(Object error) => 'Flutningur mistókst: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ekki fannst nákvæmur heilar orð samanburður „$term"';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Skipti $occurrences birtum af „$term" í $notes minnisblöðum';
  @override
  String replaceSkipped(int skipped) => ' ($skipped opnum minnisblöðum sleppt)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ekki nákvæmur heilar orð samanburður „$term"'
      '${only == null ? "ekki fannst" : "fannst í $only"}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Um';
  @override
  String get versionTitle => 'Útgáfa';
  @override
  String get changelogTitle => 'Breytingalogg';
  @override
  String get changelogEmpty => 'Engar færslur í breytingaloggunum';
  @override
  String changelogWhatsNew(String version) => 'Nýtt í útgáfu $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Ferill';
  @override
  String get noteMenuTooltip => 'Aðgerðir minnisblaðs';
  @override
  String get historyCurrentVersion => 'Núverandi útgáfa';
  @override
  String get historyCurrentSubtitle => 'Minnisblaðið eins og það er núna';
  @override
  String get historyToday => 'Í dag';
  @override
  String get historyYesterday => 'Í gær';
  @override
  String get historyReasonSession => 'fyrir breytingar';
  @override
  String get historyReasonInterval => 'við breytingar';
  @override
  String get historyReasonRestore => 'fyrir endurheimt';
  @override
  String get historyReasonSync => 'fyrir samstillingu';
  @override
  String get historyReasonReplace => 'fyrir útskiptingu';
  @override
  String get historyReasonUnknown => 'fundin aftur';
  @override
  String get historySyncBase => 'samstillingargrunnur';
  @override
  String get historyEmpty =>
      'Engar útgáfur enn. Niman geymir eina þegar þú byrjar að breyta '
      'minnisblaði, síðan í mesta lagi eina á nokkurra mínútna fresti meðan '
      'þú skrifar.';
  @override
  String historyKept(int kept, int limit) => 'Geymdar útgáfur: $kept af $limit';
  @override
  String get historyBaseKept =>
      'Samstillingargrunnurinn er geymdur umfram hámarkið.';
  @override
  String get historyOff =>
      'Ferill er óvirkur fyrir þetta bókasafn (Stillingar, Bókasafn).';
  @override
  String get historyLoadFailed => 'Gat ekki lesið ferilinn';
  @override
  String get historyCompareSubtitle => 'Borin saman við núverandi útgáfu';
  @override
  String get historyTabChanges => 'Breytingar';
  @override
  String get historyTabVersion => 'Útgáfa';
  @override
  String get historyNoChanges => 'Sami texti og í núverandi útgáfu.';
  @override
  String get historyRestoreAction => 'Endurheimta þessa útgáfu';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Endurheimta útgáfuna frá $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Núverandi texti er fyrst vistaður í ferlinum, svo þú getur alltaf '
      'farið til baka.';
  @override
  String get historyRestoreConfirm => 'Endurheimta';
  @override
  String historyRestored(String when) => 'Útgáfan frá $when var endurheimt';
  @override
  String get historyRestoreFailed => 'Gat ekki endurheimt útgáfuna';
  @override
  String get actionUndo => 'Afturkalla';
  @override
  String diffLineRange(int start, int end) => 'Línur $start–$end';
  @override
  String diffLineSingle(int line) => 'Lína $line';
  @override
  String diffUnchanged(int count) => count % 10 == 1 && count % 100 != 11
      ? '$count óbreytt lína'
      : '$count óbreyttar línur';
  @override
  String get historyTakeHunk => 'Endurheimta hér';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Endurheimta 1 breytingu' : 'Endurheimta $count breytingar';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Valdar breytingar fara aftur í texta þessarar útgáfu. Minnispunkturinn '
      'eins og hann er núna er fyrst geymdur sem útgáfa, svo þú getur '
      'afturkallað þetta.';
  @override
  String get historyNoteChangedReloaded =>
      'Minnispunkturinn breyttist á meðan þú varst hér — samanburðurinn hefur '
      'verið uppfærður.';
  @override
  String get historyVersionsTitle => 'Fjöldi geymdra útgáfna';
  @override
  String get historyVersionsSubtitle => 'Fyrir hvert minnisblað, í .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Engar' : '$count';
  @override
  String get historyIntervalTitle => 'Minnsta bil milli útgáfna';
  @override
  String get historyIntervalSubtitle =>
      'Meðan þú skrifar; alltaf er ein geymd þegar byrjað er að breyta '
      'minnisblaði';
  @override
  String historyIntervalValue(int minutes) => '$minutes mín';
  @override
  String get settingsSectionTranscription => 'Umritun';
  @override
  String get transcriptionModelTitle => 'Líkan';
  @override
  String get transcriptionModelNone => 'Ekkert';
  @override
  String get transcriptionLanguageTitle => 'Tungumál';
  @override
  String get transcriptionLanguageSubtitle =>
      'Tungumálið sem er talað í upptökunum þínum. Nákvæmara er að velja það '
      'en að láta greina það.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Eins og forritið ($language)';
  @override
  String get transcriptionLanguageDetect => 'Greina sjálfkrafa';
  @override
  String get transcriptionModelsTitle => 'Umritunarlíkön';
  @override
  String transcriptionModelsUsed(String size) => '$size í notkun';
  @override
  String get transcriptionModelsInstalled => 'Sótt';
  @override
  String get transcriptionModelsDownloading => 'Í niðurhali';
  @override
  String get transcriptionModelsAvailable => 'Í boði';
  @override
  String get transcriptionModelsFooter =>
      'Líkönin eru geymd í geymslu forritsins á þessu tæki. Þau eru hvorki '
      'afrituð í safnið né samstillt.';
  @override
  String get transcriptionModelDefault => 'Sjálfgefið';
  @override
  String get transcriptionModelSlow => 'Hægt';
  @override
  String get transcriptionModelHintTiny => 'Hraðast, minnst nákvæmt';
  @override
  String get transcriptionModelHintBase => 'Gott jafnvægi hraða og nákvæmni';
  @override
  String get transcriptionModelHintSmall => 'Nákvæmara, um 3× hægara';
  @override
  String get transcriptionModelHintMedium => 'Mjög nákvæmt, hægt í síma';
  @override
  String get transcriptionModelHintLarge => 'Nákvæmast, þarf mikið minni';
  @override
  String get transcriptionModelDownload => 'Sækja';
  @override
  String transcriptionModelDeleteTitle(String model) => 'Eyða líkaninu $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Þetta losar $size. Þú getur sótt líkanið aftur seinna.';
  @override
  String get transcriptionModelFailed =>
      'Niðurhal mistókst. Athugaðu tenginguna og reyndu aftur.';
  @override
  String get actionRetry => 'Reyna aftur';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Tengingin rofnaði, reynt aftur…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Í bið við $progress';
  @override
  String get actionResume => 'Halda áfram';
  @override
  String get audioTranscribe => 'Umrita';
  @override
  String get audioTranscribeUnsupported => 'Aðeins WAV-upptökur á þessu tæki';
  @override
  String get transcriptionQueued => 'Í biðröð';
  @override
  String get transcriptionPreparing => 'Undirbý hljóðið…';
  @override
  String transcriptionRunning(int percent) => 'Umritar… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Sæki $model · $percent%';
  @override
  String get transcriptionSaved => 'Umrituninni var bætt við lýsinguna';
  @override
  String get transcriptionNoSpeech => 'Ekkert tal greindist í þessari upptöku';
  @override
  String get transcriptionFailed => 'Umritun mistókst';
  @override
  String get transcriptionPickModelTitle => 'Veldu líkan';
  @override
  String get transcriptionPickModelBody =>
      'Umritunin fer fram á þessu tæki og upptakan er aldrei send. Líkanið er '
      'sótt einu sinni.';
  @override
  String get transcriptionPickModelAction => 'Sækja og umrita';
  @override
  String get transcriptionModelRecommended => 'Mælt með';
  @override
  String get transcriptionExistingTitle => 'Þessi upptaka er þegar með lýsingu';
  @override
  String get transcriptionExistingBody =>
      'Skipta henni út fyrir umritunina eða bæta umrituninni fyrir neðan?';
  @override
  String get transcriptionAppend => 'Bæta við fyrir neðan';
  @override
  String get transcriptionReplace => 'Skipta út';
  @override
  String get settingsSectionSync => 'Samstilling';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Ekki sett upp fyrir þetta bókasafn';
  @override
  String get syncNeverSynced => 'Aldrei samstillt';
  @override
  String syncLastSynced(String when) => 'Samstillt: $when';
  @override
  String get syncRunning => 'Samstillir…';
  @override
  String syncScreenSubtitle(String library) => 'Bókasafn $library';
  @override
  String get syncUrlLabel => 'Slóð möppu';
  @override
  String get syncUrlRequired => 'Sláðu inn vistfang þjónsins';
  @override
  String get syncUrlHint =>
      'Mappan verður að vera til. Afritaðu slóðina eins og '
      'netþjónninn sýnir hana.';
  @override
  String get syncHttpWarning =>
      'Ódulkóðuð tenging: í lagi um VPN eða á staðarnetinu þínu.';
  @override
  String get syncUserLabel => 'Notandi';
  @override
  String get syncUserHint =>
      'Skildu eftir autt ef netþjónninn biður ekki um auðkenni.';
  @override
  String get syncPasswordLabel => 'Lykilorð';
  @override
  String get syncPasswordHint =>
      'Geymt í lyklakippu þessa tækis, aldrei í skjölum '
      'bókasafnsins.';
  @override
  String get syncPasswordKeepHint =>
      'Skildu eftir autt til að halda vistaða lykilorðinu.';
  @override
  String get syncShowPassword => 'Sýna lykilorð';
  @override
  String get syncHidePassword => 'Fela lykilorð';
  @override
  String get syncTestAction => 'Prófa tengingu';
  @override
  String get syncTesting => 'Prófar…';
  @override
  String get syncRetargetWarning =>
      'Með nýrri slóð eða notanda byrjar næsta samstilling upp á '
      'nýtt sem fyrsta samstilling.';
  @override
  String get syncTestOk => 'Tengingin virkar';
  @override
  String get syncModeFull => 'Fullur hamur';
  @override
  String get syncModeCompatible => 'Samhæfður hamur';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lestur, skrif og eyðing';
  @override
  String get syncCapEtags => 'Fingraför skjala (ETag)';
  @override
  String get syncCapNoEtags => 'Engin fingraför skjala (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Ber saman stærð og dagsetningu; sækir aftur ef vafi '
      'leikur á';
  @override
  String get syncCapGuarded => 'Varin skrif';
  @override
  String get syncCapUnguarded => 'Óvarin skrif';
  @override
  String get syncCapUnguardedDetail =>
      'Athugar skjalið á netþjóninum rétt áður en skrifað er';
  @override
  String get syncCapMove => 'Endurnefnir án þess að hlaða upp aftur';
  @override
  String get syncCapNoMove => 'Engin endurnefning á netþjóninum';
  @override
  String get syncCapNoMoveDetail =>
      'Endurnefning verður að eyðingu og nýrri upphleðslu';
  @override
  String get syncCompatibleNote =>
      'Í samhæfðum ham virkar samstilling eins, bara með nokkrum '
      'fleiri beiðnum.';
  @override
  String get syncTestInvalidUrl => 'Ógild slóð';
  @override
  String get syncTestInvalidUrlHint =>
      'Sláðu inn http:// eða https:// slóð, án notanda eða '
      'lykilorðs í henni.';
  @override
  String get syncTestOffline => 'Ekki næst í netþjóninn';
  @override
  String get syncTestOfflineHint =>
      'Er kveikt á VPN? 10.x eða 192.168.x slóð virkar aðeins á '
      'sama neti.';
  @override
  String get syncTestAuth => 'Notanda eða lykilorði hafnað';
  @override
  String get syncTestAuthHint => 'Athugaðu þau og prófaðu aftur.';
  @override
  String get syncTestNotFound => 'Mappan er ekki til';
  @override
  String get syncTestNotFoundHint =>
      'Búðu hana til á netþjóninum eða lagaðu slóðina.';
  @override
  String get syncTestUnsupported => 'Ekki WebDAV-mappa';
  @override
  String get syncTestUnsupportedHint =>
      'Netþjónninn svarar, en ekki sem WebDAV.';
  @override
  String get syncTestFailed => 'Prófunin tókst ekki';
  @override
  String get syncNowAction => 'Samstilla núna';
  @override
  String get syncSectionServer => 'Netþjónn';
  @override
  String get syncServerRow => 'Slóð, notandi og lykilorð';
  @override
  String get syncRetestTitle => 'Prófa netþjóninn aftur';
  @override
  String syncProbedAgo(String when) => 'Síðasta prófun: $when';
  @override
  String get syncDisconnectTitle => 'Aftengja þetta bókasafn';
  @override
  String get syncDisconnectSubtitle =>
      'Skjölin verða áfram hér og á netþjóninum';
  @override
  String get syncDisconnectConfirmTitle => 'Aftengja samstillingu?';
  @override
  String get syncDisconnectConfirmBody =>
      'Þetta bókasafn hættir að samstillast á þessu tæki. Engu '
      'skjali er eytt, hvorki hér né á netþjóninum. Ef þú tengir '
      'það aftur byrjar fyrsta samstillingin upp á nýtt.';
  @override
  String get syncDisconnectConfirm => 'Aftengja';
  @override
  String get syncFirstTitle => 'Fyrsta samstilling';
  @override
  String get syncFirstIntro =>
      'Ég bar bókasafnið saman við möppuna á netþjóninum:';
  @override
  String get syncFirstUpload => 'Til að hlaða upp';
  @override
  String get syncFirstDownload => 'Til að sækja';
  @override
  String get syncFirstBoth => 'Á báðum stöðum';
  @override
  String get syncFirstBothHint =>
      'Eins: enginn flutningur. Ólík: þarf að leysa';
  @override
  String get syncFirstNoDelete =>
      'Fyrsta samstillingin eyðir engu, hvorki hér né á '
      'netþjóninum.';
  @override
  String get syncStartAction => 'Byrja';
  @override
  String syncMassTrashTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Færa $count skjal í korpu?'
      : 'Færa $count skjöl í korpu?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Á netþjóninum vantar $count af $total samstilltum '
      'skjölum. Það þýðir yfirleitt ranga slóð, NAS-disk sem er '
      'ekki tengdur eða möppu sem var tæmd fyrir mistök.';
  @override
  String get syncMassTrashHint =>
      'Ef þú eyddir þeim í alvöru á öðru tæki skaltu staðfesta: '
      'hér fara þau í korpu.';
  @override
  String get syncMassTrashConfirm => 'Færa í korpu';
  @override
  String syncMassDeleteTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Eyða $count skjali af netþjóninum?'
      : 'Eyða $count skjölum af netþjóninum?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Hér vantar $count af $total samstilltum skjölum. Ef þú '
      'eyddir þeim ekki skaltu hætta við og athuga möppu '
      'bókasafnsins.';
  @override
  String get syncMassDeleteConfirm => 'Eyða af netþjóni';
  @override
  String get syncTooltip => 'Samstilla';
  @override
  String get syncStageConnecting => 'Tengist netþjóninum…';
  @override
  String get syncStageComparing => 'Ber saman við netþjóninn…';
  @override
  String syncStageApplying(int done, int total) =>
      'Samstillir · $done af $total';
  @override
  String get syncStatusWarnings => 'Samstillt með viðvörunum';
  @override
  String syncConflictsHeader(int count) =>
      'Breytt hér og á netþjóninum · $count';
  @override
  String get syncConflictHint => 'Hvorug útgáfan var snert';
  @override
  String get syncResolveAction => 'Leysa';
  @override
  String syncFailuresHeader(int count) => 'Ekki samstillt · $count';
  @override
  String get syncFailuresHint => 'Reynt aftur við næstu samstillingu';
  @override
  String get syncAbortAuth => 'Netþjónninn hafnaði lykilorðinu';
  @override
  String get syncAbortMissingPassword => 'Ekkert lykilorð vistað';
  @override
  String get syncAbortOffline => 'Ekki næst í netþjóninn';
  @override
  String get syncAbortRemoteMissing => 'Mappan á netþjóninum er horfin';
  @override
  String get syncAbortUnsupported =>
      'Netþjónninn virkar ekki lengur sem WebDAV';
  @override
  String get syncAbortFailed => 'Samstillingin tókst ekki';
  @override
  String get syncAbortNotConfirmed => 'Hætt við samstillingu';
  @override
  String get syncAbortNothingTouched =>
      'Ekkert skjal var snert. Breytingarnar þínar verða áfram '
      'hér fram að næstu vel heppnuðu samstillingu.';
  @override
  String syncLastSuccess(String when) =>
      'Síðasta vel heppnaða samstilling: $when';
  @override
  String get syncNoSuccessYet => 'Engin vel heppnuð samstilling enn';
  @override
  String get syncUpdatePasswordAction => 'Uppfæra lykilorð';
  @override
  String get syncRetryAction => 'Reyna aftur';
  @override
  String get syncOpenSettingsAction => 'Stillingar';
  @override
  String get syncCloseAction => 'Loka';
  @override
  String get syncDoneSnack => 'Samstillt';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Samstillt · $count skjal sem var eytt annars staðar er í '
            'korpunni'
      : 'Samstillt · $count skjöl sem var eytt annars staðar eru í '
            'korpunni';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Samstillt · $count óleystur árekstur'
      : 'Samstillt · $count óleystir árekstrar';
  @override
  String get syncShowAction => 'Sýna';
  @override
  String get syncConflictTitle => 'Leysa árekstur';
  @override
  String get syncConflictLegend =>
      'Línur merktar − eru af netþjóninum, línur merktar + af '
      'þessu tæki.';
  @override
  String get syncConflictBinary =>
      'Ekki textaskjal: veldu hvaða afrit á að halda.';
  @override
  String get syncConflictKeepNote =>
      'Afritið sem þú heldur ekki verður áfram í ferlinum.';
  @override
  String get syncKeepLocal => 'Halda útgáfu þessa tækis';
  @override
  String get syncKeepRemote => 'Halda útgáfu netþjónsins';
  @override
  String get syncConflictIdentical => 'Útgáfurnar tvær eru eins';
  @override
  String get syncConflictLoadFailed => 'Gat ekki lesið báðar útgáfurnar';
  @override
  String get syncResolveFailed => 'Gat ekki leyst áreksturinn';
  @override
  String get syncResolved => 'Árekstur leystur';
  @override
  String get syncSectionWhen => 'Hvenær á að samstilla';
  @override
  String get syncAutoTitle => 'Sjálfvirkt';
  @override
  String get syncAutoSubtitle =>
      'Eftir breytingar, við opnun og með reglulegu millibili';
  @override
  String get syncIntervalTitle => 'Tíðni athugana á netþjóni';
  @override
  String get syncIntervalSubtitle => 'Aðeins meðan forritið er opið';
  @override
  String get syncIntervalDialogBody =>
      'Til að sjá breytingar sem gerðar eru í öðrum tækjum meðan forritið er '
      'opið. Með „Aldrei“ aðeins eftir breytingar og við opnun.';
  @override
  String syncIntervalMinutes(int count) =>
      count % 10 == 1 && count % 100 != 11 ? '$count mínúta' : '$count mínútur';
  @override
  String get syncIntervalNever => 'Aldrei';
  @override
  String get syncWifiOnlyTitle => 'Aðeins á Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Á farsímagögnum er aðeins samstillt handvirkt';
  @override
  String syncPendingChanges(int count) => count % 10 == 1 && count % 100 != 11
      ? '$count breyting bíður'
      : '$count breytingar bíða';
  @override
  String syncRetryIn(String wait) => 'reynt aftur eftir $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes mín';
  @override
  String get syncWaitingForWifi => 'Bíður eftir Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Bíður eftir tengingu';
  @override
  String get syncMobileDataHint => '„Samstilla núna“ notar samt farsímagögn.';
  @override
  String get syncQueueKeptHint =>
      'Breytingarnar verða áfram hér, jafnvel þótt þú lokir forritinu, og '
      'fara sjálfkrafa af stað þegar netþjónninn svarar.';
  @override
  String get syncAutoPaused => 'Sjálfvirk samstilling í bið';
  @override
  String get syncPausedAuthHint =>
      'Hún heldur áfram þegar þú uppfærir lykilorðið eða samstillir '
      'handvirkt.';
  @override
  String get syncPausedServerHint =>
      'Hún heldur áfram þegar þú lagfærir slóðina eða samstillir handvirkt.';
  @override
  String get syncPausedConfirmHint =>
      '„Samstilla núna“ sýnir hvað yrði fjarlægt og spyr fyrst.';
  @override
  String get syncNeedsConfirmation => 'Bíður eftir staðfestingu þinni';
  @override
  String get syncMergeIntro =>
      'Breytingar sem skarast ekki eru þegar sameinaðar; veldu hverju á að '
      'halda þar sem þær skarast.';
  @override
  String get syncMergeClean =>
      'Útgáfurnar tvær sameinast af sjálfu sér: ekkert skarast.';
  @override
  String get syncMergeNoBase =>
      'Engin sameiginleg útgáfa til að sameina á, svo velja verður alla '
      'skrána.';
  @override
  String syncMergeOverlap(int index, int total) => 'Skörun $index af $total';
  @override
  String get syncMergeFromLocal => 'Úr þessu tæki';
  @override
  String get syncMergeFromRemote => 'Frá netþjóninum';
  @override
  String get syncMergeRemovedLines => 'Línur fjarlægðar';
  @override
  String get syncMergeKeepLocal => 'Mínar';
  @override
  String get syncMergeKeepRemote => 'Netþjónsins';
  @override
  String get syncMergeKeepBoth => 'Báðar';
  @override
  String get syncMergeSave => 'Vista sameininguna';
  @override
  String get syncMergeKeepWhole => 'Eða halda einu heilu eintaki';
}
