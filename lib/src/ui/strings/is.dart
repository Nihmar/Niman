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
  String get debugLogsTitle => 'Aflausningarskrá';
  @override
  String get debugLogsSubtitle => 'Skrar atburði forritins í minnisbuffer';
  @override
  String get lineNumbersTitle => 'Línurit';
  @override
  String get lineNumbersSubtitle => 'Sýnir dálkinn með línuröðunum í ritaranum';
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
  String get settingsPreviewEnabledTitle => 'Forsýning';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Sýnir formgerða athugasraðuna við hlið ritara upprunatextans';
  @override
  String get switchToWysiwygTooltip => 'Skipta yfir í WYSIWYG ritara';
  @override
  String get switchToSourceTooltip => 'Skipta yfir í Markdown upprunatexta';
  @override
  String get wysiwygTooLarge =>
      'Þessi athugasrafa er of stór fyrir WYSIWYG ritara. Opnaðu í '
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
  String get themePaletteTitle => 'Litapalletta';
  @override
  String get themePaletteSubtitle => 'Litir viðkomumlegs og athugasraðans';
  @override
  String get themePaletteSystem => 'Kerfi';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Stærð viðkomu texta';
  @override
  String get uiTextScaleSubtitle => 'Tré, kort og ræður; yfir kerfistilltanum';
  @override
  String get noteTextScaleTitle => 'Stærð athugasrafatextans';
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
  String get newAudioNoteTitle => 'Ný raddathugasrafa';
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
  String get shortcutQuickNote => 'Hraðathugasrafa';
  @override
  String get shortcutNewTodo => 'Ný verkefni';
  @override
  String get shortcutNewNote => 'Ný athugasrafa';
  @override
  String get shortcutNewList => 'Nýr listi';
  @override
  String get shortcutNewAudio => 'Ný raddathugasrafa';
  @override
  String get shortcutToggleSidebar => 'Sýna eða fela skjalatré';
  @override
  String get shortcutEditorSection => 'Í ritara';
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
  String get searchHint => 'Leita að athugasrafum';
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
  String get replaceInNoteAction => 'Skipta út í þessa athugasrafa…';
  @override
  String get replaceInThisNote => 'Skipta út í þessa athugasrafa';
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
  String get findInNoteTooltip => 'Finna í athugasrafnu';
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
  String get tagsNotesEmpty => 'Engar athugasrafnir með þessu marki';
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
  String get ambiguousLinkTitle => 'Fleiri athugasrafnir passa';
  @override
  String get openLinkFailed => 'Það gekk ekki að opna tengilinn';

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
    return 'Í ${names.length} athugasrafum eru breytingar sem enn eru '
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
  String get quickNoteTitle => 'Hraðathugasrafa';
  @override
  String get treeEmpty => 'Engar athugasrafnir enn';
  @override
  String get selectANote => 'Velja athugasrafa';
  @override
  String get showListTooltip => 'Sýna list';
  @override
  String get editRawTooltip => 'Breyta hrátt';
  @override
  String get sortAscTooltip => 'Raða A-Ö';
  @override
  String get sortDescTooltip => 'Raða Ö-A';
  @override
  String get newNoteTitle => 'Ný athugasrafa';
  @override
  String get newFolderTitle => 'Ný mappa';
  @override
  String get newNoteHere => 'Ný athugasrafa hér';
  @override
  String get newFolderHere => 'Ný mappa hér';
  @override
  String get newListNoteTitle => 'Ný athugasrafa-listi';
  @override
  String get newListNoteDefault => 'Listi minn';
  @override
  String get setAsQuickNote => 'Stilla sem hraðathugasrafa';
  @override
  String get currentQuickNote => 'Núverandi hraðathugasrafa';
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
  String get templateFormNoNote => 'Án athugasrafnar';
  @override
  String get templateFormPickNote => 'Velja athugasrafa';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Stafsetningar staðir í smíð';
  @override
  String get templateHelpIntro =>
      'Smíð er venjuleg athugasrafa með holur. Búin athugasrafar frá '
      'henni kopíar textann og fyllir holurnar.';
  @override
  String get templateHelpUnknown =>
      'Stafsetningsstaður sem Niman ekki þekkir heldst nákvæmlega eins '
      'og skrifuð, svo stafvilla birtist í athugasrafnu en ekki broti '
      'línu.';
  @override
  String get templateHelpValuesTitle => 'Gildi';
  @override
  String get templateHelpTitleBody => 'Hefið undir sem athugasrafan er búin.';
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
      'athugasrafn skrifar 1, næsta 2. Sama nafn í einni athugasrafn '
      'skrifar sama tölu; samsettu með |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Setur pílann hér þegar athugasrafn er búin; merkjað sjálft er '
      'ekki skrifuð. Fyrsta merkið vinnur, án sila, aðeins nýjar '
      'athugasrafnir — og lyklaborð opnast jafnvel þegar sjálfvirkur '
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
      'Form birtist fyrir því að athugasrafn er búin, eitt svið fyrir '
      'hverjar spurningar — og eitt fyrir tengil aftur, þegar smíðin '
      'biðst eitt. Sama merkið tvisvar er ein spurning, og svör hennar '
      'fyllir alla birta — mappa og heiti skjals innifalið.';
  @override
  String get templateHelpAskFieldBody =>
      'Skriftsvid; texti eftir tvær semmur er það sem hefur að fara.';
  @override
  String get templateHelpChoiceBody => 'Val úr listanum, aðskilin með kommu.';
  @override
  String get templateHelpWhereTitle => 'Hvar á að fara athugasrafan';
  @override
  String get templateHelpWhereBody =>
      'Þetta er ekki texti: það er leiðbeiningar, og lifir í niman: '
      'blokk í sama frontmatter smíðans. Blokk er virkjað og síðan er '
      'hún fjarlægð, svo hún birtist aldrei í athugasrafn. Gildi '
      'þeirra geta innihaldið stafsetningar staði.';
  @override
  String get templateHelpFolderBody =>
      'Mappa þar sem athugasrafn er búin, búin ef hún ekki er til. Án '
      'hennar, athugasrafn fer þar sem þú varst.';
  @override
  String get templateHelpFilenameBody =>
      'Hvað athugasrafn er kallað. Smíð sem segir það ekki er ekki '
      'spurð um nafn.';
  @override
  String get templateHelpAppendBody =>
      'Bæti við athugasrafn ef hún er þegar til, í stað þess að búa '
      'aðra. Þetta gerir mánuð af fundum í eitt skjal.';
  @override
  String get templateHelpOpenBody =>
      'Hvað gerist eftir að athugasrafn er til: ritari (stillan), '
      'forsýning eða ekkert — athugasrafn er undirstrikuð og þú heldst '
      'þar sem þú varst.';
  @override
  String get templateHelpAroundTitle => 'Hvar kemur það frá';
  @override
  String get templateHelpParentBody =>
      'Athugasrafn sem þú velur í formu, sem tillagar það sem er á '
      'skjánum; skrifa [[{{parent}}]] fyrir tengil aftur til hennar.';
  @override
  String get templateHelpFolderValueBody => 'Mappa þar sem athugasrafn endar.';
  @override
  String get templateHelpClipboardBody =>
      'Hvað er í millistofu, og valrit ritara þegar athugasrafn hefst '
      'frá henni.';
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
      'Engar smíðar enn. Setja athugasrafa í $folder/ og hún verður '
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
      'Engin hraðathugasrafa enn. Velja varanlega athugasrafa eða búa '
      'til nýja — hraðathugasrafn opnaðst hér.';
  @override
  String get quickNoteChooseAction => 'Velja athugasrafa…';
  @override
  String get quickNoteCreateAction => 'Búa til nýja athugasrafa…';
  @override
  String get quickNoteNewTitle => 'Ný hraðathugasrafa';
  @override
  String get quickNotePickerTitle => 'Velja hraðathugasrafa';

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
      'Opnaðu mappu með Markdown athugasrafnir sem bókasafn þitt';
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
  String indexingCount(int done, int total) => '$done af $total athugasrafnir';

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
      'Hún kemur úr þessari listanum. Mappa, athugasrafnir og stilling '
      'bókasafns í henni haldast óbreytt, og enduropnun setur henni '
      'aftur á stað.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Leyfa aðgang að skjölum';
  @override
  String get storageAccessNeeded =>
      'Niman getur ekki lesið athugasrafnir þínar án „aðgang að öllum '
      'skjölum". Leyfa til að opna bókasafn.';
  @override
  String get storageAccessExplained =>
      'Niman les athugasrafnir þínar sem venjuleg skjal, svo Android '
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
      'Skipti $occurrences birtum af „$term" í $notes athugasrafnir';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped opnatheldar athugasrafnir sleppt)';
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
  String get noteMenuTooltip => 'Aðgerðir athugasrafnar';
  @override
  String get historyCurrentVersion => 'Núverandi útgáfa';
  @override
  String get historyCurrentSubtitle => 'Athugasrafan eins og hún er núna';
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
      'athugasrafnu, síðan í mesta lagi eina á nokkurra mínútna fresti meðan '
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
  String get historyVersionsTitle => 'Fjöldi geymdra útgáfna';
  @override
  String get historyVersionsSubtitle => 'Fyrir hverja athugasrafa, í .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Engar' : '$count';
  @override
  String get historyIntervalTitle => 'Minnsta bil milli útgáfna';
  @override
  String get historyIntervalSubtitle =>
      'Meðan þú skrifar; alltaf er ein geymd þegar byrjað er að breyta '
      'athugasrafnu';
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
}
