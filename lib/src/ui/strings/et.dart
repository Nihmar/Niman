// The Estonian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class EstonianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'jaanuar',
    'veebruar',
    'märts',
    'aprill',
    'mai',
    'juuni',
    'juuli',
    'august',
    'september',
    'oktoober',
    'november',
    'detsember',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jaan',
    'veebr',
    'märts',
    'apr',
    'mai',
    'juuni',
    'juuli',
    'aug',
    'sep',
    'okt',
    'nov',
    'dets',
  ];
  @override
  List<String> get weekdayNames => const [
    'esmaspäev',
    'teisipäev',
    'kolmapäev',
    'neljapäev',
    'reede',
    'laupäev',
    'pühapäev',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'E',
    'T',
    'K',
    'N',
    'R',
    'L',
    'P',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Prügikast';
  @override
  String get trashSubtitle =>
      'Kustutatud elemendid liigutatakse .trash/-i (välja lülitatud = püsiv '
      'kustutamine)';
  @override
  String get trashAutoEmptyTitle => 'Prügikasti automaatne tühjendamine';
  @override
  String get trashAutoEmptySubtitle =>
      'Vanemad kustutamised kaovad jäädavalt kogu avamisel';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Mitte kunagi'
      : days == 1
      ? '1 päev'
      : '$days päeva';
  @override
  String get debugLogsTitle => 'Silumise logid';
  @override
  String get debugLogsSubtitle => 'Logib rakenduse sündmused mälupufferis';
  @override
  String get lineNumbersTitle => 'Ridade numbrid';
  @override
  String get lineNumbersSubtitle => 'Kuvab numbrite veeru märgiste redaktoris';
  @override
  String get readableLineLengthTitle => 'Loetav reapikkus';
  @override
  String get readableLineLengthSubtitle =>
      'Hoia märkme tekst keskel veerus, mitte kogu akna laiuses';
  @override
  String get noteColumnWidthTitle => 'Veeru laius';
  @override
  String get noteColumnWidthSubtitle => 'Kui lai on märkme veerg, pikslites';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Klaviatuur avamisel';
  @override
  String get keyboardOnOpenSubtitle =>
      'Kuvab klaviatuuri märgise avamisel (välja lülitatud = esimesel '
      'puudutusel)';
  @override
  String get editorKindSource => 'Markdowni allikas';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdowni lähtekood, nagu kirjutatud';
  @override
  String get editorKindWysiwygSubtitle => 'Vormindatud tekst, muudetakse otse';
  @override
  String get settingsFolderToCreate => 'luua';
  @override
  String get settingsSearchHint => 'Otsi seadetest';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 seade leitud' : '$count seadet leitud';
  @override
  String get settingsToggleOn => 'Sees';
  @override
  String get settingsToggleOff => 'Väljas';
  @override
  String get switchToWysiwygTooltip => 'Lülita WYSIWYG-redaktorile';
  @override
  String get switchToSourceTooltip => 'Lülita Markdowni allikale';
  @override
  String get switchToSourceLabel => 'Lähe';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Välimus';
  @override
  String get settingsSectionEditor => 'Redaktor';
  @override
  String get settingsSectionLibrary => 'Kogu';
  @override
  String get settingsSectionReminders => 'Meeldetuletused';
  @override
  String get settingsSectionShortcuts => 'Klaviatuur';
  @override
  String get keyboardShortcutsTitle => 'Klaviatuuri lühendid';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Kogu $name';
  @override
  String get settingsGroupLibraryHint => 'kehtib ainult selle kogu puhul';
  @override
  String get settingsGroupMaintenance => 'Hooldamine';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Kaustad ja aadressid';
  @override
  String get settingsAreaTrashHistory => 'Prügikast ja ajalugu';
  @override
  String get settingsAreaDiagnostics => 'Diagnostika ja info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Vajab ühendatud füüsilist klaviatuuri';
  @override
  String get settingsSectionUpdates => 'Uuendused';
  @override
  String get autoUpdateTitle => 'Automaatsed uuendused';
  @override
  String get autoUpdateSubtitle =>
      'Kontrolli GitHub Releases uuendusi käivitamisel ja iga 6 tunni järel';
  @override
  String get checkForUpdatesTitle => 'Otsi uuendusi';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version on saadaval';
  @override
  String get updateUpToDate => 'Niman on ajakohane';
  @override
  String get updateCheckFailed => 'Uuenduste kontroll ebaõnnestus';
  @override
  String updateSavedTo(Object path) => 'Uuendus salvestati asukohta $path';
  @override
  String get updateInstallerStarted => 'Paigaldusprogramm käivitati';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Õigekirjapide';
  @override
  String get settingsSpellCheckSubtitle =>
      'Allkirjeldab õigekirjavigad kirjutamisel.';
  @override
  String get spellCheckDictionaryTitle => 'Sõnaraamat';
  @override
  String get spellCheckDictionarySystem => 'Süsteemi vaike';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Sõnaraamatute valik';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Valige kõik keeled, milles kogu on kirjutatud. Sõna läbib, kui üks '
      'valitud sõnaraamatutest seda tunneb; ilma valikuta otsustab süsteemi '
      'keel.';
  @override
  String get spellCheckNoDictionaries =>
      'Selles süsteemis ei leitud sõnaraamatuid.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Õigekirjapide';
  @override
  String get spellCheckTitle => 'Õigekiri';
  @override
  String get spellCheckEmpty => 'Õigekirjavigade pole.';
  @override
  String get spellCheckUnavailable =>
      'hunspell pole selles süsteemis installitud.';
  @override
  String get spellCheckNoSuggestions => 'Soovitused puuduvad';
  @override
  String spellCheckCount(int count) => '$count kontrollimiseks';
  @override
  String spellCheckLine(int line) => 'rida $line';
  @override
  String get addWordToDictionary => 'Lisa sõnaraamatusse';

  @override
  String indentWidthValue(int spaces) => '$spaces tühikut';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Heledus';
  @override
  String get themeBrightnessSubtitle => 'Hele, tume või seadme seadistus';
  @override
  String get themeBrightnessSystem => 'Süsteem';
  @override
  String get themeBrightnessDay => 'Hele';
  @override
  String get themeBrightnessNight => 'Tume';
  @override
  String get themePaletteTitle => 'Värvipaleett';
  @override
  String get themePaletteSubtitle => 'Kasutajaliides ja märgiste värvid';
  @override
  String get themePaletteSystem => 'Süsteem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Kasutajaliidese teksti suurus';
  @override
  String get uiTextScaleSubtitle =>
      'Puus, kaardid ja dialoogid; süsteemi seadistuse kohal';
  @override
  String get noteTextScaleTitle => 'Märgiste teksti suurus';
  @override
  String get noteTextScaleSubtitle =>
      'Redaktor ja eelvaade on alati sünkroonis';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Viide formaat';
  @override
  String get linkTypeSubtitle => 'Mida viide nupp redaktorisse kirjutab';
  @override
  String get linkTypeWikilink => 'Viikiviide';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Loo puuduvad märkmed kausta';
  @override
  String get missingNoteLocationRoot => 'Biblioteka juur';
  @override
  String get missingNoteLocationCurrentFolder => 'Praegune kaust';
  @override
  String get indentWidthTitle => 'Taande laius';
  @override
  String get indentWidthSubtitle =>
      'Taande iga taseme lisandatud tühikute arv redaktoris';
  @override
  String get languageTitle => 'Keel';
  @override
  String get languageSubtitle => 'Rakenduse enda teksti keel';
  @override
  String get languageSystem => 'Süsteem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Lisa element';
  @override
  String get listAddTooltip => 'Lisa element';
  @override
  String get listEmpty => 'Elemente veel pole';
  @override
  String get listDragHandleLabel => 'Muuda elemendi järjekorda';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Salvestisi veel pole';
  @override
  String get audioRecord => 'Salvesta';
  @override
  String get audioStop => 'Peata';
  @override
  String get audioPlay => 'Esita';
  @override
  String get audioDelete => 'Kustuta salvestis';
  @override
  String get audioImport => 'Impordi helifail';
  @override
  String get audioRecording => 'Salvestamine…';
  @override
  String get audioPermissionDenied =>
      'Mikrofoni luba keelatud — salvestamiseks on see vajalik.';
  @override
  String get newAudioNoteTitle => 'Uus häälmärge';
  @override
  String get newAudioNoteDefault => 'Minu salvestis';
  @override
  String get showAudioTooltip => 'Kuva salvestised';
  @override
  String get audioMessageHint => 'Kirjuta märge…';
  @override
  String get audioSend => 'Saada';
  @override
  String get audioRename => 'Muuda salvestise nime';
  @override
  String get audioDescriptionHint => 'Kirjelda seda salvestist…';
  @override
  String get audioEditDescription => 'Muuda kirjeldust';
  @override
  String get audioDeleteNote => 'Kustuta märge';
  @override
  String get audioEditNote => 'Muuda märget';
  @override
  String get audioPause => 'Paus';
  @override
  String get audioEditTitle => 'Muuda pealkirja';
  @override
  String get audioTitleHint => 'Anna salvestisele pealkiri…';
  @override
  String audioUntitled(int n) => 'Salvestis $n';
  @override
  String get audioMoreActions => 'Rohkem toiminguid';
  @override
  String get audioDiscardRecording => 'Loobu salvestisest';
  @override
  String get audioPauseRecording => 'Peata salvestamine';
  @override
  String get audioResumeRecording => 'Jätka salvestamist';
  @override
  String get audioRecordingPaused => 'Peatatud';
  @override
  String get audioSavingRecording => 'Salvestamine…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Kiirmärge';
  @override
  String get trayOpen => 'Ava Niman';
  @override
  String get trayQuit => 'Välju';
  @override
  String get closeToTrayTitle => 'Sule teavitusalale';
  @override
  String get closeToTraySubtitle =>
      'Akna × peidab Nimani ja jätab selle tööle, nii et meeldetuletused '
      'tulevad edasi. Väljumine ikooni menüüst.';
  @override
  String get shortcutNewTodo => 'Uus ülesanne';
  @override
  String get shortcutNewNote => 'Uus märge';
  @override
  String get shortcutNewList => 'Uus loetelu';
  @override
  String get shortcutNewAudio => 'Uus häälmärge';
  @override
  String get shortcutToggleSidebar => 'Kuva või peida filter';
  @override
  String get shortcutCloseTab => 'Sulge praegune märge';
  @override
  String get shortcutNextTab => 'Järgmine avatud märge';
  @override
  String get shortcutPreviousTab => 'Eelmine avatud märge';
  @override
  String get shortcutEditorSection => 'Redaktoris';
  @override
  String get shortcutFormatSection => 'Vormindus';
  @override
  String get shortcutFind => 'Otsing';
  @override
  String get shortcutReplace => 'Otsi ja asenda';
  @override
  String get shortcutSavingNote =>
      'Muudused salvestatakse automaatselt, seega salvestamise lühendit ei '
      'ole.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Laadimine…';
  @override
  String get noteStatusSaving => 'Salvestamine…';
  @override
  String get noteStatusUnsaved => 'Salvestamata';
  @override
  String get noteStatusSaved => 'Salvestatud';
  @override
  String get noteStatusError => 'Viga';
  @override
  String get noteNotText =>
      'See fail ei ole tekstimärge, seega ei saa Niman seda siin näidata.';
  @override
  String get noteLoadFailed => 'Seda märget ei õnnestunud avada.';
  @override
  String wordCount(int count) => '$count sõna';
  @override
  String get outlineTooltip => 'Struktuur';
  @override
  String get outlineNoHeadings => 'Pealkirju pole';
  @override
  String get outlineNoTitle => '(pealkirjata)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Rasvane';
  @override
  String get toolbarItalic => 'Kalded';
  @override
  String get toolbarStrikethrough => 'Läbijoonitud';
  @override
  String get toolbarSuperscript => 'Üleind';
  @override
  String get toolbarUnderline => 'Alljoonitud';
  @override
  String get toolbarLink => 'Viide';
  @override
  String get toolbarCode => 'Koodiplokk';
  @override
  String get toolbarImage => 'Sisesta pilt';
  @override
  String get toolbarTable => 'Tabel';
  @override
  String get tableRow => 'Rida';
  @override
  String get tableColumn => 'Veerg';
  @override
  String get tableAddRowAbove => 'Lisa rida üles';
  @override
  String get tableAddRowBelow => 'Lisa rida alla';
  @override
  String get tableMoveRowUp => 'Liiguta rida üles';
  @override
  String get tableMoveRowDown => 'Liiguta rida alla';
  @override
  String get tableDuplicateRow => 'Kopeeri rida';
  @override
  String get tableDeleteRow => 'Kustuta rida';
  @override
  String get tableAddColumnLeft => 'Lisa veerg vasakule';
  @override
  String get tableAddColumnRight => 'Lisa veerg paremale';
  @override
  String get tableMoveColumnLeft => 'Liiguta veergu vasakule';
  @override
  String get tableMoveColumnRight => 'Liiguta veergu paremale';
  @override
  String get tableAlignLeft => 'Joonda vasakule';
  @override
  String get tableAlignCenter => 'Joonda keskele';
  @override
  String get tableAlignRight => 'Joonda paremale';
  @override
  String get tableDuplicateColumn => 'Kopeeri veerg';
  @override
  String get tableDeleteColumn => 'Kustuta veerg';
  @override
  String get tableSortAscending => 'Sordi veeru järgi (A → Z)';
  @override
  String get tableSortDescending => 'Sordi veeru järgi (Z → A)';
  @override
  String get tableAddRow => 'Lisa rida';
  @override
  String get tableAddColumn => 'Lisa veerg';
  @override
  String get cheatsheetTitle => 'Markdowni spikker';
  @override
  String get cheatsheetCopy => 'Kopeeri';
  @override
  String get cheatsheetCopied => 'Kopeeritud';
  @override
  String get cheatsheetInsert => 'Lisa märkmesse';
  @override
  String get cheatsheetWritten => 'Kirjutatud';
  @override
  String get cheatsheetShown => 'Näidatud';
  @override
  String get cheatHeadings => 'Pealkirjad';
  @override
  String get cheatEmphasis => 'Paks, kaldkiri, läbikriipsutatud';
  @override
  String get cheatHtmlFormats => 'Allajoonitud, ülaindeks, alaindeks';
  @override
  String get cheatLists => 'Loendid';
  @override
  String get cheatChecklists => 'Kontrollnimekirjad';
  @override
  String get cheatQuotes => 'Tsitaadid';
  @override
  String get cheatLinks => 'Lingid';
  @override
  String get cheatWikilinks => 'Lingid märkmetele';
  @override
  String get cheatEmbeds => 'Pildid ja manused';
  @override
  String get cheatTags => 'Sildid';
  @override
  String get cheatInlineCode => 'Kood lauses';
  @override
  String get cheatCodeBlocks => 'Koodiplokid';
  @override
  String get cheatMath => 'Matemaatika';
  @override
  String get cheatTables => 'Tabelid';
  @override
  String get cheatFootnotes => 'Joonealused märkused';
  @override
  String get cheatRule => 'Horisontaaljoon';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Mallide kohatäited';
  @override
  String get menuAddLink => 'Lisa link';
  @override
  String get menuAddExternalLink => 'Lisa väline link';
  @override
  String get menuFormat => 'Vorming';
  @override
  String get menuParagraph => 'Lõik';
  @override
  String get menuInsert => 'Lisa';
  @override
  String get menuBody => 'Põhitekst';
  @override
  String get formatSubscript => 'Alaindeks';
  @override
  String get formatInlineCode => 'Kood';
  @override
  String get insertFootnote => 'Joonealune märkus';
  @override
  String get insertRule => 'Horisontaaljoon';
  @override
  String get insertCodeBlock => 'Koodiplokk';
  @override
  String get insertMathBlock => 'Matemaatikaplokk';
  @override
  String get menuHeadingWord => 'Pealkiri';
  @override
  String get toolbarHeading => 'Pealkiri';
  @override
  String get toolbarList => 'Loetelu';
  @override
  String get toolbarOrderedList => 'Numbreeritud loetelu';
  @override
  String get toolbarChecklist => 'Kontrollnimekiri';
  @override
  String get toolbarQuote => 'Tsitaat';
  @override
  String get toolbarIndent => 'Taande';
  @override
  String get toolbarOutdent => 'Tühista taande';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Tööriistad';
  @override
  String get editorToolsTitle => 'Redaktori tööriistad';
  @override
  String get toolCountListTitle => 'Loenda loend';
  @override
  String get toolCountListSubtitle =>
      'Liidab kokku selle, mida read loetlevad, märkeloendina';
  @override
  String get toolCountListNeedsList =>
      'Selles märkmes pole loendit, mida loendada';
  @override
  String get tallySourceLabel => 'Loend';
  @override
  String get tallyCutLabel => 'Loe iga rida kui';
  @override
  String get tallyCutDash => 'Nimi - väärtused';
  @override
  String get tallyCutColon => 'Nimi: väärtused';
  @override
  String get tallyCutCommas => 'Komadega eraldatud väärtused';
  @override
  String get tallyCutWhole => 'Terve rida ühe väärtusena';
  @override
  String get tallySortLabel => 'Järjestus';
  @override
  String get tallySortCount => 'Kõige rohkem esimesena';
  @override
  String get tallySortAlphabetical => 'Tähestikuliselt';
  @override
  String get tallySortFirstSeen => 'Loendi järjekorras';
  @override
  String get tallyInsert => 'Lisa';
  @override
  String get tallyUpdate => 'Uuenda';
  @override
  String get tallyNothingToCount => 'Siin pole midagi loendada';
  @override
  String get headingDialogTitle => 'Pealkirja tase';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Redaktori tööriistapaneel';
  @override
  String get toolbarSettingsHint =>
      'Lohista järjekorra muutmiseks; silm kuvab või peidab nupu.';
  @override
  String get toolbarShowButton => 'Kuva';
  @override
  String get toolbarHideButton => 'Peida';
  @override
  String get toolbarResetOrder => 'Taasta vaikimisi';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Kuva eelvaadet';
  @override
  String get showEditorTooltip => 'Kuva redaktorit';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(toore HTML-tabel)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Otsi märgistest';
  @override
  String get searchModeWords => 'Sõnad';
  @override
  String get searchModeContains => 'Sisaldab';
  @override
  String get searchEmptyHint =>
      'Kirjuta kogus otsimiseks või võti = väärtus frontmatteri '
      'filtreerimiseks';
  @override
  String get searchTooShortHint => 'Kirjuta vähemalt 2 tähte';
  @override
  String get searchNoMatches => 'Tulemusi pole';
  @override
  String get searchLoadMore => 'Kuva rohkem';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Asenda …';
  @override
  String get replaceInNoteAction => 'Asenda selle märgise sees …';
  @override
  String get replaceInThisNote => 'Asenda selle märgise sees';
  @override
  String get replaceWithLabel => 'Asenda';
  @override
  String get replaceCaseSensitive => 'Suur- ja väiketundlik';
  @override
  String get replaceWholeWordsHint =>
      'asendatakse ainult täpsed täissõnade vasted';
  @override
  String get replaceConfirm => 'Asenda';
  @override
  String get replaceCancel => 'Sulge';
  @override
  String get replaceUnavailable => 'Asendus hetkel ei ole saadaval';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Otsi märgisest';
  @override
  String get editorFindHint => 'Otsi';
  @override
  String get editorReplaceHint => 'Asenda';
  @override
  String get editorFindCaseTooltip => 'Suur- ja väiketundlik';
  @override
  String get editorFindPreviousTooltip => 'Eelmine tulemus';
  @override
  String get editorFindNextTooltip => 'Järgmine tulemus';
  @override
  String get editorFindCloseTooltip => 'Sulge otsing';
  @override
  String get editorFindReplaceModeTooltip => 'Asendamisrežiim';
  @override
  String get editorReplaceOneTooltip => 'Asenda see tulemus';
  @override
  String get editorReplaceAllTooltip => 'Asenda kõik tulemused';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Sildid';
  @override
  String get tagsTitle => 'Sildid';
  @override
  String get tagsEmpty =>
      'Sildid pole veel — lisa #sild või sildid frontmatterisse';
  @override
  String get tagsBackTooltip => 'Tagasi otsingusse';
  @override
  String get tagsNotesEmpty => 'Selle sildiga märgist ei ole';
  @override
  String tagsNotesCapped(int limit) =>
      'Kuvatakse ainult esimesed $limit — otsige silti, et kitsendada';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Viidet ei leitud';
  @override
  String get headingNotFoundTitle => 'Pealkirja ei leitud';
  @override
  String get ambiguousLinkTitle => 'Mitu märgist vastab';
  @override
  String get openLinkFailed => 'Viidet ei õnnestunud avada';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Märkme pole olemas';
  @override
  String missingNoteDialogBody(String path) => 'Loo „$path“?';
  @override
  String missingNoteFolderMissing(String folder) => 'Kaust „$folder“ puudub';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Avatud';
  @override
  String get todoDone => 'Lõpetatud';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Kõik kuupäevad';
  @override
  String get todoFilter => 'Filtreeri';
  @override
  String get todoNoTokens => 'Selles loetelus pole tokeneid';
  @override
  String get todoCountOpen => 'avatud';
  @override
  String get todoCountDone => 'lõpetatud';
  @override
  String get todoEmptyOpen => 'Avatud ülesandeid pole veel';
  @override
  String get todoEmptyDone => 'Lõpetatud ei ole veel';
  @override
  String get todoEmptyFiltered => 'Ülesanne ei vasta';
  @override
  String get todoTitle => 'Ülesanded';
  @override
  String get todoAddTooltip => 'Lisa ülesanne';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt formaat';
  @override
  String get todoHelpTooltip => 'Formaati infot';
  @override
  String get todoHelpIntro =>
      'Teie ülesanded on tavaline tekstifail, üks ülesanne rida kohta. Niman '
      'kirjutab süntaksit teie eest, kuid ei peida midagi: faili saab muuta '
      'mis tahes redaktoris ja Niman loeb selle uuesti.';
  @override
  String get todoHelpFilesTitle => 'Kaks faili';
  @override
  String get todoHelpFilesBody =>
      'Avatud ülesanded elavad kogu juures olevas todo.txt-is. Lõpetades '
      'ühe, liigutatakse rida done.txt-i, et todo.txt jääks lühikeseks. '
      'Lõpetatud rida, mis uuesti todo.txt-sse satub, arhiveerib Niman '
      'järgmisel failide lugemisel.';
  @override
  String get todoHelpLineTitle => 'Rida anatoomia';
  @override
  String get todoHelpLineBody =>
      'Kõik, mis on kirjelduse ees, on valikuline ja peab tulema selles '
      'järjekorras:';
  @override
  String get todoHelpDoneBody =>
      'Tähistab ülesande lõpetatuna. Niman lisab selle, kui kontrollite kasti.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioriteet. A on kõige kõrgem. Kuvatakse embleemina loetelus.';
  @override
  String get todoHelpDatesBody =>
      'Lõpp, seejärel loomise kuupäev. Ühe kuupäevaga on see loomise '
      'kuupäev, kui rida ei algne tähe x-iga.';
  @override
  String get todoHelpTokensTitle => 'Projektid, kontekstid ja sildid';
  @override
  String get todoHelpTokensBody =>
      'Iga sõna kirjelduses, millel on üks neist eesliitest, muutub '
      'filtreeritavaks sildiks. Midagi ei ole eeldefineeritud: token '
      'eksisteerib, kuni seda kirjutatakse.';
  @override
  String get todoHelpProjectBody =>
      'Millisele projektile ülesanne kuulub, nt +köök või +töö.';
  @override
  String get todoHelpContextBody =>
      'Kus või kuidas seda tehakse, nt @kodu või @kohtumised.';
  @override
  String get todoHelpHashtagBody =>
      'Vaba sild selle jaoks, mida esimesed kaks ei kata.';
  @override
  String get todoHelpTagsTitle => 'Kuupäevad ja meeldetuletused';
  @override
  String get todoHelpTagsBody =>
      'Need on võti:väärtus sildid. Niman kirjutab need ülesannete dialoogist '
      'ja loeb neid, kuhu iganes need ridadel ilmuvad.';
  @override
  String get todoHelpDueBody =>
      'Lõpp. Juhib embleemi värvi ja kuupäevafiltreid.';
  @override
  String get todoHelpRemBody =>
      'Millal tuleks teavitus saata, teie ajavöös. Käivitub, kui ekraan on '
      'välja lülitatud ja rakendus suletud.';
  @override
  String get todoHelpRemDesktop =>
      'Arvutis peab Niman töötama, kui aeg on käes: meeldetuletus kuvatakse, '
      'kui rakendus on avatud, ja käivitamist ei toimu, kui see on suletud.';
  @override
  String get todoHelpOtherBody =>
      'Säilitatakse täpselt kirjutatud kujul, et muude todo.txt rakenduste '
      'sildid saaksid teekonda ellu jääda. Niman ei kasuta neid, rec: '
      'included: korduv ülesanne ei kordu veel.';
  @override
  String get todoHelpEditTitle => 'Muutmine Nimanis';
  @override
  String get todoHelpEditBody =>
      'Ridad, mida ei puudutatud, säilitatakse baitide kaupa. Muudetud rida '
      'kirjutab Niman ainult selle rida kanonilises vormis, muu osa failist '
      'jääb puutumatuks.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Lisa ülesanne';
  @override
  String get todoEditTitle => 'Muuda ülesannet';
  @override
  String get todoDescriptionHint => 'Kirjeldus';
  @override
  String get todoCancel => 'Tühista';
  @override
  String get todoSave => 'Salvesta';
  @override
  String get todoEditAction => 'Muuda';
  @override
  String get todoDeleteAction => 'Kustuta';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Aegumiskäik möödas';
  @override
  String get todoDueToday => 'Täna';
  @override
  String get todoDueNext7 => 'Järgmise 7 päeva';
  @override
  String get todoDueNoDate => 'Kuupäevata';
  @override
  String get todoRowDue => 'Lõpp';
  @override
  String get todoRowDueToday => 'Lõpp täna';
  @override
  String get todoSortTooltip => 'Sorteeri';
  @override
  String get todoSortDue => 'Lõppkuupäev';
  @override
  String get todoSortPriority => 'Prioriteet';
  @override
  String get todoSortCreation => 'Loomise kuupäev';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Prioriteedita';
  @override
  String get todoNoPriorityShort => 'Puudub';
  @override
  String get todoMorePriorities => 'Rohkem …';
  @override
  String get todoPriorityTitle => 'Prioriteet';
  @override
  String get todoNoDueDate => 'Lõputa';
  @override
  String get todoNoReminder => 'Meeldetuletuseta';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Sild';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Ülesannete meeldetuletused';
  @override
  String get todoReminderChannelDescription =>
      'Planeeritud teavitused ülesannete jaoks, millel on meeldetuletuse aeg.';
  @override
  String get todoReminderBody => 'Ülesande meeldetuletus';
  @override
  String get todoReminderFallbackTitle => 'Ülesande meeldetuletus';
  @override
  String get todoReminderBlocked =>
      'Teavitused on välja lülitatud, seega meeldetuletusi ei kuvata.';
  @override
  String get todoReminderBattery =>
      'Aku optimeerimine on Niman jaoks sisse lülitatud. Süsteem võib '
      'rakenduse kuhjata ja ootavad meeldetuletused kaotada.';
  @override
  String get todoReminderInexact =>
      'See seade ei toeta täpseid alarme, seega meeldetuletus võib tulla '
      'paar minutit hiljem, kui ekraan on välja lülitatud.';
  @override
  String get reminderShowTokensTitle => 'Sildid meeldetuletuse teavitustes';
  @override
  String get reminderShowTokensSubtitle =>
      'Jätke +projekt, @kontekst ja #sild teavituse teksti. Välja lülitatud '
      'kuvab ainult ülesande, mille te kirjutasite.';
  @override
  String get todoReminderFixAction => 'Ava seaded';
  @override
  String get todoReminderDismissAction => 'Aldesta';
  @override
  String get todoReminderDue => 'Lõpp';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Tühista';
  @override
  String get actionCreate => 'Loo';
  @override
  String get actionNew => 'Uus';
  @override
  String get actionSave => 'Salvesta';
  @override
  String get actionClear => 'Tühjendi';
  @override
  String get actionChoose => 'Vali';
  @override
  String get actionDelete => 'Kustuta';
  @override
  String get actionRename => 'Nime muuda';
  @override
  String get actionMove => 'Liiguta';
  @override
  String get saveAndClose => 'Salvesta ja sulge';
  @override
  String get closeUnsavedTitle => 'Salvestamata muudused';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” on salvestamata muudused. '
          'Kas salvestada enne sulgemist?';
    }
    return '${names.length} märgist on salvestamata muudused. '
        'Kas salvestada enne sulgemist?';
  }

  @override
  String get closeSaveFailed => 'Salvestamine ebaõnnestus; märge jääb avatuks.';
  @override
  String get actionRestore => 'Taasta';
  @override
  String get actionEmpty => 'Tühjendi';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Peida külgpaneel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Kuva külgpaneel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimeeri';
  @override
  String get windowMaximizeTooltip => 'Maksimeeri';
  @override
  String get windowRestoreTooltip => 'Taasta';
  @override
  String get windowCloseTooltip => 'Sulge';
  @override
  String get tabFiles => 'Failid';
  @override
  String get tabSearch => 'Otsing';
  @override
  String get tabSettings => 'Seaded';
  @override
  String get quickNoteTitle => 'Kiirmärge';
  @override
  String get treeEmpty => 'Märgist ei ole veel';
  @override
  String get selectANote => 'Vali märge';
  @override
  String get showListTooltip => 'Kuva loetelu';
  @override
  String get editRawTooltip => 'Muuda toorelt';
  @override
  String get sortAscTooltip => 'Sorteeri A–Z';
  @override
  String get sortDescTooltip => 'Sorteeri Z–A';
  @override
  String get newNoteTitle => 'Uus märge';
  @override
  String get newItemTooltip => 'Uus';
  @override
  String get closeMenuTooltip => 'Sulge';
  @override
  String get newFolderTitle => 'Uus kaust';
  @override
  String get newNoteSameFolder => 'Uus märkmik samas kaustas';
  @override
  String get newFromTemplateSameFolder => 'Uus mallist samas kaustas';
  @override
  String trashOriginalPath(String path) => 'asus siin: $path';
  @override
  String get trashOriginalRoot => 'oli kogu juurkataloogis';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 \u00fcksus' : '$count \u00fcksust';
  @override
  String get newNoteHere => 'Uus märge siia';
  @override
  String get newFolderHere => 'Uus kaust siia';
  @override
  String get newListNoteTitle => 'Uus märge loeteluga';
  @override
  String get newListNoteDefault => 'Minu loetelu';
  @override
  String get setAsQuickNote => 'Määra kiirmärgiks';
  @override
  String get currentQuickNote => 'Aktuaalne kiirmärge';
  @override
  String get pinnedSection => 'Kinnitatud';
  @override
  String pinnedSectionCount(int count) => 'Kinnitatud · $count';
  @override
  String get templateFolderTitle => 'Šabloonide kaust';
  @override
  String get newFromTemplateTitle => 'Uus šabloonist';
  @override
  String get newFromTemplateHere => 'Uus šabloonist siia';
  @override
  String get templateFormTitle => 'Täita šabloon';
  @override
  String get templateFormBacklink => 'Tagasiviide';
  @override
  String get templateFormNoNote => 'Märgita';
  @override
  String get templateFormPickNote => 'Vali märge';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Šablooni asendused';
  @override
  String get templateHelpSubtitle =>
      'Kuupäev, pealkiri ja muud täidetavad väärtused';
  @override
  String get quickNoteSubtitle => 'Märkus, mille avab kiirmenüü kaart';
  @override
  String get listFolderSubtitle => 'Uued ülesandeloendid';
  @override
  String get templateFolderSubtitle => 'Mallist uue allikas';
  @override
  String get attachmentsFolderSubtitle => 'Märkusesse lisatud pildid ja heli';
  @override
  String get templateHelpIntro =>
      'Šabloon on tavaline märge, millel on augud. Märgise loomine sellest '
      'kopioneerib teksti ja täidab augud.';
  @override
  String get templateHelpUnknown =>
      'Asendus, mida Niman ei tunne, jääb täpselt kirjutatud kujul, et '
      'vigad näeksid välja märge, mitte et vaikselt katkeks rida.';
  @override
  String get templateHelpValuesTitle => 'Väärtused';
  @override
  String get templateHelpTitleBody => 'Nimi, mille all märge tuleb luua.';
  @override
  String get templateHelpDateBody =>
      'Täna ja aktuaalne aeg. Mõlemad acceptuju formaati: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Kuupäev ja aeg koos.';
  @override
  String get templateHelpUuidBody =>
      'Uus identifikaator, iga kasutamise jaoks erinev.';
  @override
  String get templateHelpCounterBody =>
      'Nime järgi lugemis hoiab arvu käikude vahel: esimene märge kirjutab '
      '1, järgmine 2. Sama nimi märgist kirjutab sama arvu; kombineerige '
      '|pad:3-ga.';
  @override
  String get templateHelpCursorBody =>
      'Pange kursor siia märgise loomisel; märk ei kirjutata. Esimene märk '
      'võidab, filtreerimata, ainult uued märgid — ja klaviatuur avaneb ka, '
      'kui autofocus on välja lülitatud.';
  @override
  String get templateHelpDatesTitle => 'Kuupäeva kirjutamine';
  @override
  String get templateHelpDatesBody =>
      'Need tähistavad formaadis kuupäeva osi. Kõik, mis ei ole, on '
      'kirjaviisne, kaasa arvatud teksti ühekordses ümbermõõdus. Kuu- ja '
      'päevanimed järgnevad rakenduse keelt.';
  @override
  String get templateHelpYear => 'aasta: 2026, 26';
  @override
  String get templateHelpMonth => 'kuu: 03, 3, märts, mär';
  @override
  String get templateHelpDay => 'päev: 09, 9, esmaspäev, E';
  @override
  String get templateHelpTime => 'tunnid, minutid, sekundid';
  @override
  String get templateHelpWeek => 'ISO nädal ja kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtrid';
  @override
  String get templateHelpFiltersBody =>
      'Väärtusele järgnevad filtrid, mis rakendatakse vasakult paremale.';
  @override
  String get templateHelpCaseBody =>
      'Suurkirjad, väikekirjad ja igas sõnas esimene täht — suurekirjaga '
      'kirjutatud sõna ei muutu.';
  @override
  String get templateHelpSlugBody => 'Teksti viidevorm, viikiviide luumiseks.';
  @override
  String get templateHelpPadBody =>
      'Lõigake otsad; täitke nullidega soovitud laiusele; alternatiiv, kui '
      'väärtus on tühi.';
  @override
  String get templateHelpShiftBody =>
      'Liigutage kuupäeva päevi, nädalaid, kuud või aastaid — konverents '
      'nädala pärast, dokument eelmisest kuust.';
  @override
  String get templateHelpSnapBody =>
      'Kinnitage kuupäev nädala, kuu või aasta algusse või lõppu.';
  @override
  String get templateHelpAskTitle => 'Küsim teile midagi';
  @override
  String get templateHelpAskBody =>
      'Enne märgise loomist kuvatakse vorm, küsimuse väljad — ja üks '
      'tagasiviide, kui šabloon seda nõuab. Sama märk kaks korda on küsimus '
      'ja selle vastus täidab kõik esinemised — kausta ja failinime.';
  @override
  String get templateHelpAskFieldBody =>
      'Kirjutamise väli; tekst teise koma järel on algus.';
  @override
  String get templateHelpChoiceBody => 'Valik loetelust, komaga eraldatud.';
  @override
  String get templateHelpWhereTitle => 'Kuhu märge jõuab';
  @override
  String get templateHelpWhereBody =>
      'See ei ole tekst: need on juhised, mis elavad šablooni frontmatteri '
      'niman: blokkis. Blokk käivitatakse ja kustutatakse, et see kunagi '
      'märgis ei kuvata. Väärtus võib sisaldada asendusi.';
  @override
  String get templateHelpFolderBody =>
      'Kaust, kuhu märge luuakse, luuakse, kui see ei eksisteeri. Ilma '
      'selleeta jõuab märge sinna, kus te olite.';
  @override
  String get templateHelpFilenameBody =>
      'Kuidas märge nimetatakse. Šabloon, mis selle ütleb, ei küsi nime.';
  @override
  String get templateHelpAppendBody =>
      'Lisatakse märgise juurde, kui see juba eksisteerib, uue loomise '
      'asemel. Nii saab kuu kokkusaamistest ühest failist.';
  @override
  String get templateHelpOpenBody =>
      'Mis juhtub, kui märge eksisteerib: redaktor (vaike), eelvaade või '
      'midagi — märge arhiveeritakse ja te jääte sinna, kus olite.';
  @override
  String get templateHelpAroundTitle => 'Kust see tuleb';
  @override
  String get templateHelpParentBody =>
      'Märge, mille te vormis valite, kuvatakse ekraanil; kirjutage '
      '[[{{parent}}]] tagasiviidena.';
  @override
  String get templateHelpFolderValueBody => 'Kaust, kuhu märge jõuab.';
  @override
  String get templateHelpClipboardBody =>
      'Mis on lõikepuhvris ja valik redaktoris, kui märge sealt alustas.';
  @override
  String get templateHelpIncludeTitle => 'Osade korduvkasutus';
  @override
  String get templateHelpIncludeBody =>
      'Sisestage teine šabloon, et kümme šabloon jagaks ühte kontrollloetelu. '
      'Otsing toimub esmalt šabloonide kaustas, .md võib puududa. Selle '
      'omased küsimused lähevad samasse vormi.';
  @override
  String get templateHelpExampleTitle => 'Kõik ühes kohas';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ šabloon „$path” ei eksisteeri';
  @override
  String includeCycle(String path) => '⚠ „$path” sisestub iseendasse';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path” on liiga sügavalt sisestatud';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatteri ei õnnestunud lugeda: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Šablooni „$template” frontmatteri ei õnnestunud lugeda, seega kaust ja '
      'failinime ei toimeta midagi: $reason';
  @override
  String get templatePickerTitle => 'Šabloonide valik';
  @override
  String templatePickerEmpty(String folder) =>
      'Šabloonid pole veel. Sisestage märge $folder/ ja see on šabloon.';

  // Tree actions.
  @override
  String get actionPin => 'Kinnita';
  @override
  String get actionUnpin => 'Eemalda kinnitus';
  @override
  String get pinToWidget => 'Kinnita avakuva vidžetisse';
  @override
  String get pinnedForWidget =>
      'Kinnitatud: paiguta nüüd Märkuse vidžet avakuvale';
  @override
  String get pinWidgetUnavailable => 'Avakuva vidžetid on Androidis saadaval';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Näita failihalduris';
  @override
  String get openInDefaultApp => 'Ava vaikerakenduses';
  @override
  String get newNoteTabTooltip => 'Uus märge uuel vahekaardil';
  @override
  String get openNotesTooltip => 'Avatud märkmed';
  @override
  String get closeTabTooltip => 'Sulge';
  @override
  String get openInNewTab => 'Ava uuel vahekaardil';
  @override
  String get splitRight => 'Jaga paremale';
  @override
  String get splitDown => 'Jaga alla';
  @override
  String get moveToOtherPane => 'Teisalda teisele paanile';
  @override
  String get openBeside => 'Ava kõrval';
  @override
  String get closeAllNotes => 'Sulge kõik';
  @override
  String get sidePanelTooltip => 'Näita või peida külgpaneel';
  @override
  String get historyAllVersions => 'Kõik versioonid';
  @override
  String get commandPaletteTitle => 'Käsupalett';
  @override
  String get goToNoteTitle => 'Mine märkmele';
  @override
  String get paletteGroupNote => 'Märge';
  @override
  String get paletteGroupEditor => 'Redaktor';
  @override
  String get paletteGroupView => 'Vaade';
  @override
  String get paletteGroupLibrary => 'Teek';
  @override
  String get paletteGroupGoTo => 'Mine';
  @override
  String get commandsTitle => 'Käsud';
  @override
  String get commandsIntro =>
      'Käsupalett pakub ainult käske, mida saab seal, kus sa oled, käivitada. '
      'Siin on need kõik ja millal igaüks ilmub.';
  @override
  String get commandsKeysNote =>
      'Siin ei muudeta midagi. Klahvid on need, mis on määratud jaotises '
      '„Klaviatuuri lühendid“, ja järgivad iga seal tehtud muudatust.';
  @override
  String get commandsOpenShortcuts =>
      'Muuda klahve jaotises „Klaviatuuri lühendid“';
  @override
  String get commandsChangeKeyTooltip =>
      'Muuda jaotises „Klaviatuuri lühendid“';
  @override
  String get commandsSubtitle => 'Mida käsupalett saab käivitada, ja millal';
  @override
  String get keyboardShortcutsSubtitle => 'Muuda iga käsu klahve';
  @override
  String get commandNeedNone => 'Alati saadaval';
  @override
  String get commandNeedOpenNote => 'Vajab avatud märget';
  @override
  String get commandNeedWideWindow => 'Ainult laias aknas';
  @override
  String get commandNeedDockRoom =>
      'Vajab külgpaneeli jaoks piisavalt laia akent';
  @override
  String get commandNeedDesktop => 'Ainult arvutis';
  @override
  String get commandNeedNotInZen => 'Mitte Zen-režiimis';
  @override
  String get commandNeedZenRoom => 'Arvuti, märge avatud vahekaardil';
  @override
  String get commandNeedPreview => 'Eelvaade sees, tekstimärkmel';
  @override
  String get commandNeedTwoEditors => 'Kui mõlemad redaktorid on lubatud';
  @override
  String get paletteHint => 'Otsi käske ja märkmeid';
  @override
  String get paletteNoResults => 'Midagi ei leitud';
  @override
  String get paletteCommands => 'Käsud';
  @override
  String get paletteNotes => 'Märkmed';
  @override
  String get paletteFooter =>
      '↑↓ liikumiseks · ↵ kasutamiseks · esc sulgemiseks';
  @override
  String get paletteFooterTouch =>
      'Puuduta kasutamiseks · nööpnõel hoiab selle üleval';
  @override
  String get palettePinned => 'Kinnitatud';
  @override
  String get palettePin => 'Kinnita';
  @override
  String get paletteUnpin => 'Eemalda';
  @override
  String get palettePinFooter => 'alt+P kinnitab';
  @override
  String get spellCheckScanning => 'Märkme kontrollimine…';
  @override
  String get spellCheckAgain => 'Kontrolli uuesti';
  @override
  String spellCheckCapped(int count) =>
      'Näidatakse esimesed $count: paranda mõned ja kontrolli ülejäänute '
      'jaoks uuesti';
  @override
  String get dropHint =>
      'Lohista Markdowni failid avamiseks või kaust importimiseks';
  @override
  String get dropNothing =>
      'Töölaud ei andnud selle lohistamisega ühtegi faili.';
  @override
  String get importFolderAction => 'Impordi';
  @override
  String dropRejected(String names) =>
      'Siin avanevad ainult Markdowni failid ja kaustad: $names';
  @override
  String importFolderTitle(String name) => 'Kas importida „$name“?';
  @override
  String importFolderBody(int count) =>
      'Selle Markdowni failid ($count) kopeeritakse raamatukogu uude kausta. '
      'Lohistatud kaust jääb samaks.';
  @override
  String importFolderDone(String folder) => 'Imporditud kausta $folder';
  @override
  String importFolderEmpty(String name) => 'Kaustas $name pole Markdowni faile';
  @override
  String get openFileTitle => 'Ava fail';
  @override
  String get outsideFileNote =>
      'Väljaspool raamatukogu: salvestatakse oma kohale, indekseerimata, '
      'ajaloota, linke ei järgita';
  @override
  String get typewriterOn => 'Lülita kirjutusmasina režiim sisse';
  @override
  String get typewriterOff => 'Lülita kirjutusmasina režiim välja';
  @override
  String get typewriterTitle => 'Kirjutusmasina režiim';
  @override
  String get formatNoteTitle => 'Korrasta Markdown';
  @override
  String get formatNoteDone => 'Märge korrastati.';
  @override
  String get formatNoteAlreadyTidy => 'Märge oli juba korras.';
  @override
  String get typewriterSubtitle =>
      'Rida, mida kirjutad, püsib redaktori keskel';
  @override
  String get zenMode => 'Zen-režiim';
  @override
  String get zenModeEnter => 'Lülitu zen-režiimi';
  @override
  String get zenModeLeave => 'Välju zen-režiimist';
  @override
  String get keySpace => 'Tühik';
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
  String get keyArrowUp => 'Üles';
  @override
  String get keyArrowDown => 'Alla';
  @override
  String get keyArrowLeft => 'Vasakule';
  @override
  String get keyArrowRight => 'Paremale';
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
  String get shortcutNone => 'Kiirklahv puudub';
  @override
  String get shortcutRestoreDefaults => 'Taasta vaikeväärtused';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Kas panna kõik kiirklahvid tagasi nii, nagu Niman need tarnib?';
  @override
  String get shortcutRevert => 'Tagasi vaikeväärtusele';
  @override
  String get shortcutClear => 'Eemalda kiirklahv';
  @override
  String get shortcutCapturePrompt =>
      'Vajuta klahve. Ka Esc ja Tab salvestatakse: välju nupuga Loobu.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Lisa Ctrl, Alt või Meta: üksik klahv on trükkimiseks.';
  @override
  String get shortcutMove => 'Teisalda';
  @override
  String get shortcutUseAnyway => 'Kasuta siiski';
  @override
  String get shortcutUndo => 'Võta tagasi';
  @override
  String get shortcutRedo => 'Tee uuesti';
  @override
  String get shortcutChange => 'Muuda kiirklahvi';
  @override
  String shortcutCaptureTitle(String command) => 'Klahvid: $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys kuulub juba käsule $other. Kas teisaldada siia? $other jääb '
      'kiirklahvita.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys on tekstiväljades ja redaktoris ka $what. Seal võtab selle üle '
      'sinu käsk.';
  @override
  String get openFileMissing => 'Selle märkme faili kettal ei ole';
  @override
  String get openFileFailed =>
      'Seda märget ei saanud Nimanist väljaspool avada';

  @override
  String get movedToTrash => 'Liigutatud prügikastu';
  @override
  String get deletedMessage => 'Kustutatud';
  @override
  String deleteToTrashConfirm(String name) => '$name liigutatakse .trash/-i';
  @override
  String deleteForeverConfirm(String name) => '$name kustutatakse püsivalt';
  @override
  String get chooseDestination => 'Vali sihtkoht';
  @override
  String get libraryRoot => 'Kogu juur';
  @override
  String moveTitle(String name) => 'Liiguta $name';
  @override
  String headingLevelLabel(int level) => 'Pealkiri taseme $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Kiirmärgi pole veel. Valige olemasolev märge või looge uue — kiirmärge '
      'avaneb siin.';
  @override
  String get quickNoteChooseAction => 'Vali märge …';
  @override
  String get quickNoteCreateAction => 'Loo uus märge …';
  @override
  String get quickNoteNewTitle => 'Uus kiirmärge';
  @override
  String get quickNotePickerTitle => 'Kiirmärgi valik';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Uus kaust';
  @override
  String get folderPickerEmpty => 'Kaustu pole veel';
  @override
  String get listFolderTitle => 'Loetelute kaust';
  @override
  String get attachmentsFolderTitle => 'Manuste kaust';

  // Trash (M1).
  @override
  String get trashEmpty => 'Prügikast on tühi';
  @override
  String get trashEmptyAction => 'Tühjendi prügikasti';
  @override
  String get trashEmptyConfirm =>
      'See kustutab püsivalt kõik, mis prügikastus on, kaasa arvatud '
      'elemendid, mida Niman sinna ei pannud.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name kustutatakse püsivalt (taastamata)';
  @override
  String get trashDeletePermanently => 'Kustuta püsivalt';

  // The open/create library screen.
  @override
  String get openLibraryIntro => 'Ava Markdowni märkiste kaust kogu';
  @override
  String get openLibraryExisting => 'Ava olemasolev';
  @override
  String get openLibraryCreate => 'Loo uus';
  @override
  String get openLibraryCreateTitle => 'Loo uus kogu';
  @override
  String get openLibraryFolderName => 'Kausta nimi';
  @override
  String get openLibraryChooseFolder => 'Vali kogu kaust';
  @override
  String get openLibraryChooseParent => 'Vali kaust, kuhu kogu luuakse';
  @override
  String get openLibraryUnsupported =>
      'Seda kausta ei toetata. Valige seadme hoiukohast kaust.';
  @override
  String indexingCount(int done, int total) => '$done / $total märgist';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Teie kogud';
  @override
  String get libraryUnreachable => 'Saavutamatu';
  @override
  String get libraryOpenedToday => 'Avatud täna';
  @override
  String get libraryOpenedYesterday => 'Avatud eile';
  @override
  String libraryOpenedDaysAgo(int days) => 'Avatud $days päeva eest';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Avatud ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Avatud hetkel';
  @override
  String get switchLibraryTitle => 'Lülita kogu';
  @override
  String get libraryForget => 'Unusta';
  @override
  String libraryForgetTitle(String name) => 'Unustada „$name”?';
  @override
  String get libraryForgetExplained =>
      'Kaob sellest loetelust. Kaust, märgid ja koguse seaded jäävad '
      'puutumatuks ja uuesti avamine viib kohale.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Luba failidele ligipääs';
  @override
  String get storageAccessNeeded =>
      'Niman ei saa teie märgisi lugeda ilma „Kõikide failide juurdepääs”eta. '
      'Lubage see kogu avamiseks.';
  @override
  String get storageAccessExplained =>
      'Niman loeb teie märgisi tavalistena failidena, seega peab Android '
      'andma kõigi failide juurdepääsu. Midagi ei saadeta ja luuakse ainult '
      'valitud kogu kaust.';
  @override
  String folderAccessDenied(Object error) =>
      'Süsteem ei lubanud kausta ligipääsu: $error';
  @override
  String folderPickFailed(Object error) => 'Kausta valik ebaõnnestus: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Seaded';
  @override
  String get libraryPathTitle => 'Kogu aadress';
  @override
  String get reindexTitle => 'Indekseeri uuesti hetkel';
  @override
  String get reindexDone => 'Uuesti indekseerimine lõpetatud';
  @override
  String get closeLibraryTitle => 'Sulge kogu';
  @override
  String get exportLogTitle => 'Ekspordi silumise logid';
  @override
  String get exportLogSubtitle =>
      'Salvestage registreeritud sündmused faili, mille te valite';
  @override
  String get exportLogEmpty => 'Logi bufer on tühi';
  @override
  String get quickNoteUnset => 'Määramata';
  @override
  String exportLogDone(Object target) => 'Logid eksporditud $target';
  @override
  String exportLogFailed(Object error) => 'Ekspordi ebaõnnestus: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) => '„$term” täpset täissõna vastet ei ole';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Asendatud $occurrences esinemised „$term” $notes märgist';
  @override
  String replaceSkipped(int skipped) => ' ($skipped avatud märgist jäetud)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '„$term” täpset täissõna vastet ei ole'
      '${only == null ? '' : ' ei leitud $only-s'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Rakendusest';
  @override
  String get versionTitle => 'Versioon';
  @override
  String get changelogTitle => 'Muudatuste logi';
  @override
  String get changelogEmpty => 'Muudatuste logis ei ole kirjeid';
  @override
  String changelogWhatsNew(String version) => 'Uut versioonis $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Ajalugu';
  @override
  String get noteMenuTooltip => 'Märkme toimingud';
  @override
  String get historyCurrentVersion => 'Praegune versioon';
  @override
  String get historyCurrentSubtitle => 'Märge praegusel kujul';
  @override
  String get historyToday => 'Täna';
  @override
  String get historyYesterday => 'Eile';
  @override
  String get historyReasonSession => 'enne muutmist';
  @override
  String get historyReasonInterval => 'muutmise ajal';
  @override
  String get historyReasonRestore => 'enne taastamist';
  @override
  String get historyReasonSync => 'enne sünkroonimist';
  @override
  String get historyReasonReplace => 'enne asendamist';
  @override
  String get historyReasonUnknown => 'taasleitud';
  @override
  String get historySyncBase => 'sünkroonimisalus';
  @override
  String get historyEmpty =>
      'Versioone veel pole. Niman salvestab ühe, kui hakkad märget muutma, '
      'ning seejärel kirjutamise ajal kõige rohkem ühe iga paari minuti järel.';
  @override
  String historyKept(int kept, int limit) =>
      'Säilitatud versioone: $kept/$limit';
  @override
  String get historyBaseKept =>
      'Sünkroonimisalus säilitatakse ka üle piirangu.';
  @override
  String get historyOff =>
      'Ajalugu on selles kogus välja lülitatud (Seaded, Kogu).';
  @override
  String get historyLoadFailed => 'Ajalugu ei õnnestunud lugeda';
  @override
  String get historyCompareSubtitle => 'Võrreldud praeguse versiooniga';
  @override
  String get historyTabChanges => 'Muudatused';
  @override
  String get historyTabVersion => 'Versioon';
  @override
  String get historyNoChanges => 'Sama tekst mis praeguses versioonis.';
  @override
  String get historyRestoreAction => 'Taasta see versioon';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Kas taastada versioon $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Praegune tekst salvestatakse enne ajalukku, nii et saad alati tagasi '
      'minna.';
  @override
  String get historyRestoreConfirm => 'Taasta';
  @override
  String historyRestored(String when) => 'Versioon $when taastati';
  @override
  String get historyRestoreFailed => 'Versiooni ei õnnestunud taastada';
  @override
  String get actionUndo => 'Võta tagasi';
  @override
  String diffLineRange(int start, int end) => 'Read $start–$end';
  @override
  String diffLineSingle(int line) => 'Rida $line';
  @override
  String diffUnchanged(int count) => '$count muutmata rida';
  @override
  String get historyTakeHunk => 'Taasta siin';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Taasta 1 muudatus' : 'Taasta $count muudatust';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Valitud muudatused pöörduvad tagasi selle versiooni teksti juurde. '
      'Märkme praegune kuju säilitatakse enne versioonina, nii et saad selle '
      'tagasi võtta.';
  @override
  String get historyNoteChangedReloaded =>
      'Märge muutus, kui sa siin olid — võrdlus on värskendatud.';
  @override
  String get historyVersionsTitle => 'Säilitatavad versioonid';
  @override
  String get historyVersionsSubtitle => 'Iga märkme kohta, kaustas .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Pole' : '$count';
  @override
  String get historyIntervalTitle => 'Versioonide vähim vahe';
  @override
  String get historyIntervalSubtitle =>
      'Kirjutamise ajal; märkme muutmise alustamine salvestab alati ühe';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkriptsioon';
  @override
  String get transcriptionModelTitle => 'Mudel';
  @override
  String get transcriptionModelNone => 'Puudub';
  @override
  String get transcriptionLanguageTitle => 'Keel';
  @override
  String get transcriptionLanguageSubtitle =>
      'Keel, mida su salvestistes räägitakse. Selle määramine on täpsem kui '
      'tuvastamine.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Nagu rakendus ($language)';
  @override
  String get transcriptionLanguageDetect => 'Tuvasta automaatselt';
  @override
  String get transcriptionModelsTitle => 'Transkriptsioonimudelid';
  @override
  String transcriptionModelsUsed(String size) => 'Kasutusel $size';
  @override
  String get transcriptionModelsInstalled => 'Allalaaditud';
  @override
  String get transcriptionModelsDownloading => 'Allalaadimisel';
  @override
  String get transcriptionModelsAvailable => 'Saadaval';
  @override
  String get transcriptionModelsFooter =>
      'Mudelid jäävad selle seadme rakenduse salvestusruumi. Neid ei '
      'kopeerita teeki ega sünkroonita.';
  @override
  String get transcriptionModelDefault => 'Vaikimisi';
  @override
  String get transcriptionModelSlow => 'Aeglane';
  @override
  String get transcriptionModelHintTiny => 'Kiireim, kõige ebatäpsem';
  @override
  String get transcriptionModelHintBase =>
      'Hea tasakaal kiiruse ja täpsuse vahel';
  @override
  String get transcriptionModelHintSmall => 'Täpsem, umbes 3× aeglasem';
  @override
  String get transcriptionModelHintMedium => 'Väga täpne, telefonis aeglane';
  @override
  String get transcriptionModelHintLarge => 'Kõige täpsem, vajab palju mälu';
  @override
  String get transcriptionModelDownload => 'Laadi alla';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Kas kustutada mudel $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'See vabastab $size. Saad mudeli hiljem uuesti alla laadida.';
  @override
  String get transcriptionModelFailed =>
      'Allalaadimine ebaõnnestus. Kontrolli ühendust ja proovi uuesti.';
  @override
  String get actionRetry => 'Proovi uuesti';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Ühendus katkes, proovitakse uuesti…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Peatatud: $progress';
  @override
  String get actionResume => 'Jätka';
  @override
  String get audioTranscribe => 'Transkribeeri';
  @override
  String get audioTranscribeUnsupported =>
      'Selles seadmes ainult WAV-salvestised';
  @override
  String get transcriptionQueued => 'Järjekorras';
  @override
  String get transcriptionPreparing => 'Heli ettevalmistamine…';
  @override
  String transcriptionRunning(int percent) => 'Transkribeerimine… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Mudeli $model allalaadimine · $percent%';
  @override
  String get transcriptionSaved => 'Transkriptsioon lisati kirjeldusse';
  @override
  String get transcriptionNoSpeech => 'Selles salvestises kõnet ei tuvastatud';
  @override
  String get transcriptionFailed => 'Transkribeerimine ebaõnnestus';
  @override
  String get transcriptionPickModelTitle => 'Vali mudel';
  @override
  String get transcriptionPickModelBody =>
      'Transkribeerimine toimub selles seadmes ja salvestist ei saadeta '
      'kuhugi. Mudel laaditakse alla vaid korra.';
  @override
  String get transcriptionPickModelAction => 'Laadi alla ja transkribeeri';
  @override
  String get transcriptionModelRecommended => 'Soovitatud';
  @override
  String get transcriptionExistingTitle =>
      'Sellel salvestisel on juba kirjeldus';
  @override
  String get transcriptionExistingBody =>
      'Kas asendada see transkriptsiooniga või lisada transkriptsioon selle '
      'alla?';
  @override
  String get transcriptionAppend => 'Lisa alla';
  @override
  String get transcriptionReplace => 'Asenda';
  @override
  String get settingsSectionSync => 'Sünkroonimine';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Selle kogu jaoks pole seadistatud';
  @override
  String get syncNeverSynced => 'Pole kunagi sünkroonitud';
  @override
  String syncLastSynced(String when) => 'Sünkroonitud: $when';
  @override
  String get syncRunning => 'Sünkroonimine…';
  @override
  String syncScreenSubtitle(String library) => 'Kogu $library';
  @override
  String get syncUrlLabel => 'Kausta aadress';
  @override
  String get syncUrlRequired => 'Sisestage serveri aadress';
  @override
  String get syncUrlHint =>
      'Kaust peab olemas olema. Kopeeri aadress nii, nagu server '
      'seda näitab.';
  @override
  String get syncHttpWarning =>
      'Krüptimata ühendus: sobib VPN-i kaudu või kohtvõrgus.';
  @override
  String get syncUserLabel => 'Kasutaja';
  @override
  String get syncUserHint =>
      'Jäta tühjaks, kui server kasutajatunnuseid ei küsi.';
  @override
  String get syncPasswordLabel => 'Parool';
  @override
  String get syncPasswordHint =>
      'Hoitakse selle seadme võtmehoidjas, mitte kunagi kogu '
      'failides.';
  @override
  String get syncPasswordKeepHint =>
      'Jäta tühjaks, et salvestatud parool alles jääks.';
  @override
  String get syncShowPassword => 'Kuva parool';
  @override
  String get syncHidePassword => 'Peida parool';
  @override
  String get syncTestAction => 'Testi ühendust';
  @override
  String get syncTesting => 'Testimine…';
  @override
  String get syncRetargetWarning =>
      'Uue aadressi või kasutajaga algab järgmine sünkroonimine '
      'otsast peale, nagu esimene sünkroonimine.';
  @override
  String get syncTestOk => 'Ühendus töötab';
  @override
  String get syncModeFull => 'Täisrežiim';
  @override
  String get syncModeCompatible => 'Ühilduvusrežiim';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lugemine, kirjutamine ja kustutamine';
  @override
  String get syncCapEtags => 'Failide sõrmejäljed (ETag)';
  @override
  String get syncCapNoEtags => 'Failide sõrmejälgi pole (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Võrdlen suurust ja kuupäeva; kahtluse korral laadin '
      'uuesti alla';
  @override
  String get syncCapGuarded => 'Kaitstud kirjutamine';
  @override
  String get syncCapUnguarded => 'Kaitseta kirjutamine';
  @override
  String get syncCapUnguardedDetail =>
      'Kontrollin faili serveris vahetult enne kirjutamist';
  @override
  String get syncCapMove => 'Ümbernimetamine ilma uuesti üles laadimata';
  @override
  String get syncCapNoMove => 'Serveris ümbernimetamist pole';
  @override
  String get syncCapNoMoveDetail =>
      'Ümbernimetamisest saab kustutamine ja uus üleslaadimine';
  @override
  String get syncCompatibleNote =>
      'Ühilduvusrežiimis töötab sünkroonimine samamoodi, '
      'lihtsalt mõne päringu võrra rohkem.';
  @override
  String get syncTestInvalidUrl => 'Sobimatu aadress';
  @override
  String get syncTestInvalidUrlHint =>
      'Sisesta http:// või https:// aadress, ilma kasutaja ja '
      'paroolita.';
  @override
  String get syncTestOffline => 'Server pole kättesaadav';
  @override
  String get syncTestOfflineHint =>
      'Kas VPN on sees? Aadress 10.x või 192.168.x töötab ainult '
      'samast võrgust.';
  @override
  String get syncTestAuth => 'Kasutaja või parool lükati tagasi';
  @override
  String get syncTestAuthHint => 'Kontrolli neid ja testi uuesti.';
  @override
  String get syncTestNotFound => 'Kausta pole olemas';
  @override
  String get syncTestNotFoundHint => 'Loo see serveris või paranda aadress.';
  @override
  String get syncTestUnsupported => 'See pole WebDAV-kaust';
  @override
  String get syncTestUnsupportedHint => 'Server vastab, aga mitte WebDAV-ina.';
  @override
  String get syncTestFailed => 'Test ei õnnestunud';
  @override
  String get syncNowAction => 'Sünkrooni kohe';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Aadress, kasutaja ja parool';
  @override
  String get syncRetestTitle => 'Testi serverit uuesti';
  @override
  String syncProbedAgo(String when) => 'Viimane test: $when';
  @override
  String get syncDisconnectTitle => 'Katkesta selle kogu ühendus';
  @override
  String get syncDisconnectSubtitle => 'Failid jäävad siia ja serverisse';
  @override
  String get syncDisconnectConfirmTitle => 'Kas katkestada sünkroonimine?';
  @override
  String get syncDisconnectConfirmBody =>
      'See kogu ei sünkrooni enam selles seadmes. Ühtegi faili '
      'ei kustutata, ei siin ega serveris. Kui ühendad selle '
      'uuesti, algab esimene sünkroonimine otsast peale.';
  @override
  String get syncDisconnectConfirm => 'Katkesta ühendus';
  @override
  String get syncFirstTitle => 'Esimene sünkroonimine';
  @override
  String get syncFirstIntro => 'Võrdlesin kogu serveris oleva kaustaga:';
  @override
  String get syncFirstUpload => 'Üles laadida';
  @override
  String get syncFirstDownload => 'Alla laadida';
  @override
  String get syncFirstBoth => 'Mõlemal pool';
  @override
  String get syncFirstBothHint =>
      'Samad: ülekannet pole. Erinevad: vaja lahendada';
  @override
  String get syncFirstNoDelete =>
      'Esimene sünkroonimine ei kustuta midagi, ei siin ega '
      'serveris.';
  @override
  String get syncStartAction => 'Alusta';
  @override
  String syncMassTrashTitle(int count) => 'Kas viia $count faili prügikasti?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Serverist puudub $total sünkroonitud failist $count. '
      'Tavaliselt tähendab see valet aadressi, ühendamata NAS-i '
      'ketast või kogemata tühjendatud kausta.';
  @override
  String get syncMassTrashHint =>
      'Kui kustutasid need tõesti mõnes teises seadmes, kinnita: '
      'siin lähevad need prügikasti.';
  @override
  String get syncMassTrashConfirm => 'Vii prügikasti';
  @override
  String syncMassDeleteTitle(int count) =>
      'Kas kustutada serverist $count faili?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Siin puudub $total sünkroonitud failist $count. Kui sa '
      'neid ei kustutanud, tühista ja kontrolli kogu kausta.';
  @override
  String get syncMassDeleteConfirm => 'Kustuta serverist';
  @override
  String get syncTooltip => 'Sünkrooni';
  @override
  String get syncStageConnecting => 'Serveriga ühendamine…';
  @override
  String get syncStageComparing => 'Serveriga võrdlemine…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sünkroonimine · $done/$total';
  @override
  String get syncStatusWarnings => 'Sünkroonitud hoiatustega';
  @override
  String syncConflictsHeader(int count) => 'Muudetud siin ja serveris · $count';
  @override
  String get syncConflictHint => 'Kumbagi versiooni ei puudutatud';
  @override
  String get syncResolveAction => 'Lahenda';
  @override
  String syncFailuresHeader(int count) => 'Sünkroonimata · $count';
  @override
  String get syncFailuresHint => 'Proovitakse uuesti järgmisel sünkroonimisel';
  @override
  String get syncAbortAuth => 'Server lükkas parooli tagasi';
  @override
  String get syncAbortMissingPassword => 'Parooli pole salvestatud';
  @override
  String get syncAbortOffline => 'Server pole kättesaadav';
  @override
  String get syncAbortRemoteMissing => 'Serveris olevat kausta enam pole';
  @override
  String get syncAbortUnsupported => 'Server ei tööta enam WebDAV-ina';
  @override
  String get syncAbortFailed => 'Sünkroonimine ei õnnestunud';
  @override
  String get syncAbortNotConfirmed => 'Sünkroonimine tühistati';
  @override
  String get syncAbortNothingTouched =>
      'Ühtegi faili ei puudutatud. Sinu muudatused jäävad siia '
      'kuni järgmise õnnestunud sünkroonimiseni.';
  @override
  String syncLastSuccess(String when) =>
      'Viimane õnnestunud sünkroonimine: $when';
  @override
  String get syncNoSuccessYet => 'Õnnestunud sünkroonimist veel pole';
  @override
  String get syncUpdatePasswordAction => 'Uuenda parooli';
  @override
  String get syncRetryAction => 'Proovi uuesti';
  @override
  String get syncOpenSettingsAction => 'Seaded';
  @override
  String get syncCloseAction => 'Sulge';
  @override
  String get syncDoneSnack => 'Sünkroonitud';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sünkroonitud · 1 mujal kustutatud fail on prügikastis'
      : 'Sünkroonitud · $count mujal kustutatud faili on '
            'prügikastis';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sünkroonitud · 1 lahendamata konflikt'
      : 'Sünkroonitud · $count lahendamata konflikti';
  @override
  String get syncShowAction => 'Kuva';
  @override
  String get syncConflictTitle => 'Lahenda konflikt';
  @override
  String get syncConflictLegend =>
      'Märgiga − read on serveri omad, märgiga + read selle '
      'seadme omad.';
  @override
  String get syncConflictBinary =>
      'See pole tekstifail: vali, milline koopia alles jätta.';
  @override
  String get syncConflictKeepNote =>
      'Koopia, mida alles ei jäta, jääb märkme ajalukku.';
  @override
  String get syncKeepLocal => 'Jäta selle seadme oma';
  @override
  String get syncKeepRemote => 'Jäta serveri oma';
  @override
  String get syncConflictIdentical => 'Mõlemad versioonid on samad';
  @override
  String get syncConflictLoadFailed => 'Mõlemat versiooni ei õnnestunud lugeda';
  @override
  String get syncResolveFailed => 'Konflikti ei õnnestunud lahendada';
  @override
  String get syncResolved => 'Konflikt lahendatud';
  @override
  String get syncSectionWhen => 'Millal sünkroonida';
  @override
  String get syncAutoTitle => 'Automaatselt';
  @override
  String get syncAutoSubtitle =>
      'Pärast muudatusi, avamisel ja kindla intervalliga';
  @override
  String get syncIntervalTitle => 'Serveri kontrollimise intervall';
  @override
  String get syncIntervalSubtitle => 'Ainult siis, kui rakendus on avatud';
  @override
  String get syncIntervalDialogBody =>
      'Et näha teistes seadmetes tehtud muudatusi, kui rakendus on avatud. '
      'Valikuga „Mitte kunagi“ ainult pärast muudatusi ja avamisel.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minut' : '$count minutit';
  @override
  String get syncIntervalNever => 'Mitte kunagi';
  @override
  String get syncWifiOnlyTitle => 'Ainult Wi-Fi kaudu';
  @override
  String get syncWifiOnlySubtitle =>
      'Mobiilse andmesidega sünkrooni ainult käsitsi';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 muudatus ootab' : '$count muudatust ootab';
  @override
  String syncRetryIn(String wait) => 'uus katse $wait pärast';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Ootab Wi-Fi-ühendust';
  @override
  String get syncWaitingForNetwork => 'Ootab ühendust';
  @override
  String get syncMobileDataHint =>
      '„Sünkrooni kohe“ kasutab siiski mobiilset andmesidet.';
  @override
  String get syncQueueKeptHint =>
      'Muudatused jäävad siia ka siis, kui rakenduse sulged, ja saadetakse '
      'ise ära, kui server vastab.';
  @override
  String get syncAutoPaused => 'Automaatne sünkroonimine on peatatud';
  @override
  String get syncPausedAuthHint =>
      'See jätkub, kui uuendad parooli või sünkroonid käsitsi.';
  @override
  String get syncPausedServerHint =>
      'See jätkub, kui parandad aadressi või sünkroonid käsitsi.';
  @override
  String get syncPausedConfirmHint =>
      '„Sünkrooni kohe“ näitab, mis eemaldataks, ja küsib enne kinnitust.';
  @override
  String get syncNeedsConfirmation => 'Ootab sinu kinnitust';
  @override
  String get syncMergeIntro =>
      'Muudatused, mis ei kattu, on juba ühendatud; seal, kus need kattuvad, '
      'vali, mis alles jätta.';
  @override
  String get syncMergeClean => 'Kaks versiooni ühinevad ise: miski ei kattu.';
  @override
  String get syncMergeNoBase =>
      'Ühist versiooni, mille peal ühendada, pole, seega tuleb valida kogu '
      'fail.';
  @override
  String syncMergeOverlap(int index, int total) => 'Kattuvus $index / $total';
  @override
  String get syncMergeFromLocal => 'Sellest seadmest';
  @override
  String get syncMergeFromRemote => 'Serverist';
  @override
  String get syncMergeRemovedLines => 'Eemaldatud read';
  @override
  String get syncMergeKeepLocal => 'Minu';
  @override
  String get syncMergeKeepRemote => 'Serveri';
  @override
  String get syncMergeKeepBoth => 'Mõlemad';
  @override
  String get syncMergeSave => 'Salvesta ühendamine';
  @override
  String get syncMergeKeepWhole => 'Või jäta alles üks terve koopia';
}
