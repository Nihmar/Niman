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
  String get noteColumnWidthSubtitle =>
      'Kui lai on märkme veerg; 100% on vaikimisi';
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
  String get settingsSectionReminders => 'Meeldetuletused';
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
  String get themeTitle => 'Teema';
  @override
  String get themePaletteSystem => 'Süsteem';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Teemad';
  @override
  String get themesInUse => 'Kasutusel';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Uus teema';
  @override
  String get themeNewName => 'Nimi';
  @override
  String get themeNewStartFrom => 'Alusta';
  @override
  String get themeNewRandom => 'Juhuslikud värvid';
  @override
  String get themeNameTaken => 'Selle nimega teema on juba olemas';
  @override
  String themeDeleteBody(String name) =>
      'Kas kustutada „$name“? Selle värvid kaovad jäädavalt.';
  @override
  String get themeDuplicate => 'Dubleeri';
  @override
  String get themeMenuTooltip => 'Teema toimingud';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Muuda';
  @override
  String get themeEditorTitle => 'Muuda teemat';
  @override
  String get themeEditorChrome => 'Kasutajaliides';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Ülesannete loendid (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Iga värv on nimetatud nii, nagu seda nimetab eksporditud fail';
  @override
  String get themeEditorDiscardTitle => 'Loobu muudatustest';
  @override
  String get themeEditorDiscardBody => 'Muudetud värve ei salvestata';
  @override
  String get themeEditorDiscard => 'Loobu';
  @override
  String get themeEditorBadColor => 'Kasuta #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Ekspordi';
  @override
  String themeExportDone(String where) => 'Teema eksporditud asukohta $where';
  @override
  String themeFileFailed(String error) => 'Teemat ei saanud teisaldada: $error';
  @override
  String get themeImport => 'Impordi';
  @override
  String get themeImportInvalid => 'See fail ei ole Niman teema';
  @override
  String themeImportVersion(int version) =>
      'See teema on uuemast Nimanist (versioon $version)';
  @override
  String themeImportBadRole(String role) =>
      'Fail ei anna värve rollile „$role“';

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
  @override
  String get sourceFontTitle => 'Lähteteksti redaktori font';
  @override
  String get sourceFontSubtitle =>
      'Font, milles lähteteksti paneel on; eelvaade jätab märkme oma fondi';
  @override
  String get sourceFontMonospace => 'Ühe laiusega';
  @override
  String get sourceFontSansSerif => 'Ilma seriifideta';
  @override
  String get sourceFontSerif => 'Seriifidega';
  @override
  String get epubLookTitle => 'Raamatute välimus';
  @override
  String get epubLookSubtitle =>
      'EPUB-raamatute teema, font ja teksti suurus, märkmetest eraldi';
  @override
  String get epubSameAsApp => 'Nagu rakendus';
  @override
  String get epubFontTitle => 'Font';
  @override
  String get epubFontSerif => 'Seriifidega';
  @override
  String get epubFontSans => 'Seriifideta';
  @override
  String get epubFontMono => 'Püsisammuga';
  @override
  String get epubTextSizeTitle => 'Teksti suurus';

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
  @override
  String get weekStartTitle => 'Nädala esimene päev';
  @override
  String get weekStartSubtitle =>
      'Millest kalendrid nädalat alustavad. Vaikimisi süsteemi oma; siin '
      'valitud päev kehtib kogu teegi seadmetes.';
  @override
  String get weekStartSystem => 'Süsteem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Lisa element';
  @override
  String get listAddTooltip => 'Lisa element';
  @override
  String get listEmpty => 'Elemente veel pole';
  @override
  String get listDragHandleLabel => 'Muuda elemendi järjekorda';
  @override
  String get shoppingListName => 'Ostunimekiri';
  @override
  String get checklistName => 'Kontrollnimekiri';
  @override
  String get shoppingQuantityLabel => 'Kogus';

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
  @override
  String get audioPlayFailed => 'Heli ei õnnestunud esitada';

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
  String get toolbarHighlight => 'Esiletõst';
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
  String get copyCode => 'Kopeeri kood';
  @override
  String get codeCopied => 'Kood kopeeritud';
  @override
  String get cheatsheetInsert => 'Lisa märkmesse';
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
  String get cheatCallouts => 'Esiletõstetud plokid';
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
  String get cheatEpubMetadata => 'EPUB metaandmed';
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
  String get actionDownload => 'Laadi alla';
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
  String get hideSidebarTooltip => 'Peida külgpaneel';
  @override
  String get showSidebarTooltip => 'Kuva külgpaneel';
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
  String get shellActionFailed => 'Toimingut ei õnnestunud lõpetada';
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
  String pinnedSectionCount(int count) => 'Kinnitatud · $count';
  @override
  String get templateFolderTitle => 'Šabloonide kaust';
  @override
  String get newFromTemplateTitle => 'Uus šabloonist';
  @override
  String get newFromTemplateHere => 'Uus šabloonist siia';
  @override
  String get templateOpenFailed => 'Malli ei õnnestunud avada';
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
  String get frontmatterTitle => 'Atribuudid';
  @override
  String get frontmatterPanelTitle => 'Omaduste paneel';
  @override
  String get frontmatterPanelSubtitle =>
      'Näitab märkme omadusi selle kohal. Suletud, kuni selle avad, '
      'ja taandub kerimisel.';
  @override
  String get frontmatterShowRaw => 'Töötlemata YAML';
  @override
  String get frontmatterShowFields => 'Väljad';
  @override
  String get frontmatterAddField => 'Lisa atribuut';
  @override
  String get frontmatterNewField => 'Uus atribuut';
  @override
  String get frontmatterEditField => 'Muuda atribuuti';
  @override
  String get frontmatterKeyLabel => 'Võti';
  @override
  String get frontmatterValueLabel => 'Väärtus';
  @override
  String get frontmatterTypeLabel => 'Tüüp';
  @override
  String get frontmatterListHint => 'Eralda üksused komadega';
  @override
  String get frontmatterRemoveField => 'Eemalda atribuut';
  @override
  String get frontmatterNoFields => 'Atribuute pole';
  @override
  String get frontmatterTypeText => 'tekst';
  @override
  String get frontmatterTypeNumber => 'arv';
  @override
  String get frontmatterTypeDate => 'kuupäev';
  @override
  String get frontmatterTypeBoolean => 'tõeväärtus';
  @override
  String get frontmatterTypeList => 'loend';
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
  String get paletteGroupJournal => 'Päevik';
  @override
  String get journalToday => 'Tänane sissekanne';
  @override
  String get journalPrevious => 'Eelmine sissekanne';
  @override
  String get journalNext => 'Järgmine sissekanne';
  @override
  String get commandNeedJournalEntry => 'Vajab avatud päeviku sissekannet';
  @override
  String journalCreateAsk(String day) =>
      'Päeva $day jaoks pole veel sissekannet. Kas luua?';
  @override
  String journalTemplateMissing(String path) =>
      'Päeviku malli $path ei saanud lugeda: sissekanne loodi ilma selleta.';
  @override
  String get journalIntro =>
      'Üks märkus päevas, mis tehakse mallist, kui avad selle päeva esimest '
      'korda. Need seaded liiguvad koos teegiga.';
  @override
  String get journalFolderTitle => 'Päeviku kaust';
  @override
  String get journalFolderSubtitle => 'Kuhu sissekanded lähevad';
  @override
  String get journalEntryNameTitle => 'Sissekande nimi';
  @override
  String get journalEntryNameSubtitle =>
      "YYYY, MM või M, DD või D kuupäeva jaoks; / loob kausta; 'jutumärkides' "
      'tekst jääb nagu on';
  @override
  String journalEntryNamePreview(String path) => 'Tänane sissekanne: $path';
  @override
  String get journalEntryNameInvalid =>
      'Vajab YYYY-d, kuud (MM või M) ja päeva (DD või D) ning mitte midagi, '
      'mida failinimi ei tohi sisaldada';
  @override
  String get journalTemplateTitle => 'Mall';
  @override
  String get journalTemplateSubtitle => 'Millega uus sissekanne algab';
  @override
  String get journalTemplateNone => 'Puudub: pealkiri kuupäevaga';
  @override
  String get journalDayStartTitle => 'Uus päev algab kell';
  @override
  String get journalDayStartSubtitle =>
      'Hiline? Kell 04:00 jääb öö eelmise päeva juurde';
  @override
  String get journalRecent => 'Viimased';
  @override
  String get journalNoEntry => 'Selle päeva kohta pole sissekannet';
  @override
  String get journalOpenEntry => 'Ava';
  @override
  String get journalShowCalendar => 'Näita kalendrit';
  @override
  String get journalFabToday => 'Tänane päeviku sissekanne';
  @override
  String journalDueOn(String day) => 'Tähtaeg $day';
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
  String get commandNeedTextNote => 'Vajab avatud tekstimärget';
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
  String get notionImportTitle => 'Impordi Notioni eksport';
  @override
  String get notionImportFailed => 'Notioni eksporti ei õnnestunud importida';
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
  String get exportTitle => 'Ekspordi';
  @override
  String get exportFormatMarkdown => 'Markdown';
  @override
  String get exportFormatHtml => 'HTML';
  @override
  String exportDone(String place) => 'Eksporditud asukohta $place';
  @override
  String exportFailed(Object error) => 'Eksport ebaõnnestus: $error';
  @override
  String get exportFolderTitle => 'Ekspordi kaust…';
  @override
  String get exportLibraryTitle => 'Ekspordi teek…';
  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatEpub => 'EPUB';

  @override
  String get exportEpubNoMetadataTitle => 'Raamat ilma metaandmeteta';
  @override
  String get exportEpubNoIndex =>
      'Selles kaustas pole juuretasandil index.md faili. Raamat kannab '
      'kausta nime ning sellel pole autorit, kaant ega sarja.';
  @override
  String get exportEpubNoFrontmatter =>
      'index.md failil pole frontmatterit. Raamat kannab kausta nime '
      'ning sellel pole autorit, kaant ega sarja.';
  @override
  String get exportAnyway => 'Ekspordi siiski';
  @override
  String get exportPdfPicture =>
      'PDF on lehekülgede pilt; valitava teksti saamiseks paigalda brauseri.';

  @override
  String exportPdfEngineFailed(Object reason) =>
      'PDF-mootor ebaõnnestus ($reason): märge joonistati pildina.';

  @override
  String get exportPdfNoEngineTitle => 'PDF pildina';

  @override
  String get exportPdfNoEngine =>
      'Selles arvutis ei leitud brauserit. Märge joonistatakse '
      'lehekülgede pildina: teksti ei saa valida ega otsida ning '
      'pikk märge võtab kauem aega.';
  @override
  String get formatNoteAlreadyTidy => 'Märge oli juba korras.';
  @override
  String get lintRulesTitle => 'Markdowni reeglid';
  @override
  String get lintRulesSubtitle =>
      'Mida korrastamine korda teeb: tühjad read loendites, ülesannete '
      'märkeruudud, tühikud pärast märgist ja koodiplokid.';
  @override
  String get lintRulesReset => 'Lähteväärtuste taastamine';
  @override
  String lintRulesValue(int on, int all) =>
      on >= all ? 'Kõik $all' : '$on / $all';
  @override
  String get lintRuleTightLists => 'Tihedad loendid';
  @override
  String get lintRuleTaskMarker => 'Ülesannete märkeruudud';
  @override
  String get lintRuleListSpacing => 'Loendi vahed';
  @override
  String get lintRuleClosingFence => 'Koodiploki sulgemine';
  @override
  String get lintRuleFenceLanguage => 'Koodiploki keel';
  @override
  String get lintRuleJoinWrappedItems => 'Ühenda murtud loendi üksused';
  @override
  String get lintRuleJoinParagraphLines => 'Ühenda murtud lõigud';
  @override
  String get tidyOnCloseTitle => 'Korrasta Markdown sulgemisel';
  @override
  String get tidyOnCloseSubtitle =>
      'Kui sulged märkme, mida muutsid, korrastatakse selle Markdown nagu '
      'käsuga „Korrasta Markdown“. Üle 4 MB märkmed jäävad nii, nagu need '
      'on.';
  @override
  String get typewriterSubtitle =>
      'Rida, mida kirjutad, püsib redaktori keskel';
  @override
  String get zenMode => 'Zen-režiim';
  @override
  String get zoomIn => 'Suurenda';
  @override
  String get zoomOut => 'Vähenda';
  @override
  String get zoomReset => 'Lähtesta suum';
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
  String get attachmentUnreadable => 'Seda faili ei õnnestunud kuvada.';
  @override
  String get attachmentMissing => 'Seda faili kettal ei ole.';
  @override
  String get attachmentOpenFailed =>
      'Seda faili ei saanud Nimanist väljaspool avada.';
  @override
  String get copyPlaceLink => 'Kopeeri link selle kohani';
  @override
  String get placeLinkCopied => 'Link kopeeritud';
  @override
  String pdfPageLabel(String name, int page) => '$name, lk $page';
  @override
  String get annotationsFolderTitle => 'Märkuste kaust';
  @override
  String get annotationsFolderSubtitle =>
      'PDF-i või raamatu kohta tehtud märkmed';
  @override
  String get annotationNoteSuffix => 'Märkus';
  @override
  String get annotateAction => 'Lisa märkus';
  @override
  String get annotationCommentHint => 'Sinu kommentaar';
  @override
  String get annotationSaved => 'Märkus salvestatud';
  @override
  String get annotationOpenNote => 'Ava märge';
  @override
  String get annotationFailed => 'Märkust ei õnnestunud salvestada';

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
  @override
  String get trashActionFailed => 'Märget ei õnnestunud taastada ega kustutada';
  @override
  String get trashEmptyFailed => 'Prügikasti ei õnnestunud tühjendada';

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

  @override
  String get libraryForgetOpenExplained =>
      'See teek on praegu avatud: see suletakse esmalt ja kaob siis '
      'loendist. Kaust, märkmed ja selles olevad teegi seaded jäävad '
      'puutumata ning uuesti avamine toob selle tagasi.';

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
  String get libraryPathTitle => 'Kogu aadress';
  @override
  String get reindexTitle => 'Indekseeri uuesti hetkel';
  @override
  String get reindexDone => 'Uuesti indekseerimine lõpetatud';
  @override
  String get reindexFailed => 'Kogu ei õnnestunud uuesti lugeda';
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
  @override
  String get replaceScopeWholeLibrary => 'terve kogu';
  @override
  String replaceScopeNote(String note) => 'failis $note';
  @override
  String replaceScopeNotes(int count) =>
      count == 1 ? '1 märkes' : '$count märkides';
  @override
  String replaceWriteFailed(int count) => count == 1
      ? ' (1 märget ei õnnestunud kirjutada)'
      : ' ($count märget ei õnnestunud kirjutada)';

  // About (issue #80).
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
      'Ajalugu on selles kogus välja lülitatud (Seaded, Prügikast ja ajalugu).';
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
  String transcriptionModelDeleteTitle(String model) =>
      'Kas kustutada mudel $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'See vabastab $size. Saad mudeli hiljem uuesti alla laadida.';
  @override
  String get downloadFailed =>
      'Allalaadimine ebaõnnestus. Kontrolli ühendust ja proovi uuesti.';
  @override
  String get actionRetry => 'Proovi uuesti';
  @override
  String get decimalSeparator => ',';
  @override
  String get downloadRetrying => 'Ühendus katkes, proovitakse uuesti…';
  @override
  String downloadPaused(String progress) => 'Peatatud: $progress';
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
  String get syncTestCertificate => 'Sertifikaat ei ole usaldusväärne';
  @override
  String get syncTestCertificateHint =>
      'Sertifikaati ei saa kontrollida. Usalda seda ainult siis, kui selle '
      'sõrmejälg vastab serveri näidatule.';
  @override
  String get syncCertTrustTitle => 'Kas usaldada seda sertifikaati?';
  @override
  String syncCertTrustBody(String host, String fingerprint) =>
      'Sertifikaati hostile $host ei saa kontrollida.\n\nSHA-256 '
      'sõrmejälg:\n$fingerprint\n\nUsalda seda ainult siis, kui see on '
      'oodatud sertifikaat. Niman aktsepteerib selle sihtkoha jaoks '
      'ainult seda üht sertifikaati ja ühtegi teist mitte.';
  @override
  String get syncCertTrustAction => 'Usalda seda sertifikaati';
  @override
  String get syncCertTrustedTitle => 'Sertifikaat on usaldusväärne';
  @override
  String syncCertTrustedSubtitle(String fingerprint) => 'SHA-256 $fingerprint';
  @override
  String get syncCertForgetTitle => 'Kas unustada see sertifikaat?';
  @override
  String get syncCertForgetBody =>
      'Seda sihtkohta kontrollitakse uuesti seadme sertifikaadihoidla vastu ja '
      'iseallkirjastatud sertifikaat tuleb veel kord kinnitada. Muu ei muutu.';
  @override
  String get syncCertForgetAction => 'Unusta';
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
  String get syncConflictLoadFailed => 'Mõlemat versiooni ei õnnestunud lugeda';
  @override
  String get syncResolveFailed => 'Konflikti ei õnnestunud lahendada';
  @override
  String get syncResolved => 'Konflikt lahendatud';
  @override
  String get syncConflictMoved =>
      'Üks versioon muutus vahepeal: konflikt loeti uuesti, vali uuesti.';
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
      'Ühendamiseks pole ühist versiooni: igas kohas, kus kaks koopiat '
      'erinevad, valid sina.';
  @override
  String syncMergeOverlap(int index, int total) => 'Kattuvus $index / $total';
  @override
  String get syncMergeFromLocal => 'Sellest seadmest';
  @override
  String get syncMergeFromRemote => 'Serverist';
  @override
  String get syncMergeRemovedLines => 'Eemaldatud read';
  @override
  String get syncMergeAbsentLines => 'Pole selles koopias';
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

  // The welcome deck and the guided tour (#308).

  @override
  String get welcomeSkip => 'Jäta vahele';
  @override
  String get welcomeNext => 'Edasi';
  @override
  String get welcomeBack => 'Tagasi';
  @override
  String get welcomeStart => 'Alusta kirjutamist';
  @override
  String get welcomeClose => 'Sulge';
  @override
  String get welcomeNotesTitle => 'Sinu märkmed on failid';
  @override
  String get welcomeNotesBody =>
      'Niman hoiab sinu märkmeid tavaliste Markdown-failidena '
      'kaustades, mille valid. Üks märge on üks .md-fail ja kõik, '
      'mida rakendus sulle näitab, on nendest ehitatud. Kontot pole '
      'ja meie oma vormingut, kuhu tagasi pöörduda, pole.';
  @override
  String get welcomeModesTitle => 'Kolm viisi sama märkme kirjutamiseks';
  @override
  String get welcomeModesBody =>
      'Kirjuta Markdown-allikas, kirjuta märge nii, nagu seda '
      'loetakse (otse-redaktor), või loe seda. See on üks märge, '
      'mida iganes kasutad, ja saad vahetada märkme kaupa või kogu '
      'kogu jaoks.';
  @override
  String get welcomeLinksTitle => 'Kõik on seotud';
  @override
  String get welcomeLinksBody =>
      'Wikilingid nagu [[see]] leiavad oma märkme kirjutamise ajal. '
      'Sildid, frontmatter ja mallid hoiavad eemale need osad, mida '
      'ikka ja jälle kirjutad.';
  @override
  String get welcomeFindTitle => 'Leia see uuesti';
  @override
  String get welcomeFindBody =>
      'Täistekstiotsing kogus, käsukataloog kõige jaoks, mida '
      'rakendus oskab, ja kiirmärge ühe klahvi kaugusel.';
  @override
  String get welcomeExportTitle => 'See tuleb sinuga kaasa';
  @override
  String get welcomeExportBody =>
      'Ekspordi märge või terve kaust Markdowni, HTML-i, PDF-i või '
      'EPUB-raamatuna. Too sisse Notioni eksport või ava Obsidiani '
      'hoidla seal, kus see juba on.';
  @override
  String get welcomeTasksTitle => 'Ülesanded ja meeldetuletused';
  @override
  String get welcomeTasksBody =>
      'todo.txt-nimekiri, mida hoiad failina — prioriteedid, '
      'projektid, tähtajad — ja rem:-alarmid, mis hoiatavad, kui '
      'miski on tähtajaline, telefonis ja töölaual.';
  @override
  String get welcomeSyncTitle => 'Sinu masinate vahel';
  @override
  String get welcomeSyncBody =>
      'Suuna kogu WebDAV-kausta — Nextcloud, ownCloud, NAS — ja '
      'muudatused sünkroonitakse mõlemas suunas, rida rea haaval '
      'ühendatud, kui kaks seadet puudutasid sama märget.';
  @override
  String get welcomeDeviceTitle => 'Niman selles seadmes';
  @override
  String get welcomeAndroidBody =>
      'Jaga teksti või faili Nimani mis tahes rakendusest, hoia '
      'märge avaekraanil ja salvesta häälemärge kirjutamise asemel.';
  @override
  String get welcomeDesktopBody =>
      'Vahelehed ja poolitatud paneelid, süsteemisalv, lohistamine '
      'aknale ja .md-failid, mis avavad Nimani.';
  @override
  String get welcomeQuestionTitle => 'Kas oled varem Markdowni kirjutanud?';
  @override
  String get welcomeQuestionNote =>
      'See määrab ainult, kuidas rakendus käivitub. Iga redaktori '
      'saad igal ajal sisse või välja lülitada jaotises Seaded → '
      'Redaktor.';
  @override
  String get welcomeAnswerNone => 'Mitte kunagi';
  @override
  String get welcomeAnswerNoneHint =>
      'Otse-redaktor, ja Markdown-allikat ei pakuta enne, kui selle '
      'sisse lülitad.';
  @override
  String get welcomeAnswerSome => 'Natuke';
  @override
  String get welcomeAnswerSomeHint =>
      'Otse-redaktor avab märkmed; Markdown-allikas on ühe lüliti '
      'kaugusel.';
  @override
  String get welcomeAnswerFluent => 'Kogu aeg';
  @override
  String get welcomeAnswerFluentHint =>
      'Markdown-allikas, nii nagu rakendus tuleb.';
  @override
  String get welcomeTourOffer => 'Näita mulle rakendust';
  @override
  String get welcomeTourOfferNote =>
      'Ringkäik algab, kui sinu esimene kogu on avatud, ja osutab '
      'päris juhtelementidele.';
  @override
  String get welcomeDeckCommand => 'Mida Niman oskab';
  @override
  String get welcomeTourCommand => 'Tee ringkäik';
  @override
  String get tourDone => 'Valmis';
  @override
  String get tourOfferTitle => 'Kas näitan sulle?';
  @override
  String get tourOfferBody =>
      'Mõned sammud läbi rakenduse, osutades päris '
      'juhtelementidele. Võid peatuda mis tahes sammul ja jätkata '
      'hiljem käsukataloogist.';
  @override
  String get tourOfferYes => 'Näita';
  @override
  String get tourOfferNo => 'Mitte praegu';
  @override
  String get tourTreeTitle => 'Sinu kogu';
  @override
  String get tourTreeBody =>
      'See on kaust, mille valisid, kaust kausta haaval. Kõik, mida '
      'teed failiga väljaspool Nimani, ilmub siia kohe, kui see '
      'saabub.';
  @override
  String get tourCreateTitle => 'Loo märge';
  @override
  String get tourCreateBody =>
      'Märkmed, nimekirjad, häälemärkmed, mallid ja kaustad algavad '
      'kõik siit. Sama menüü ilmub telefonis ümmarguse nupuna.';
  @override
  String get tourNoteTitle => 'Üks märge korraga';
  @override
  String get tourNoteBody =>
      'Märge ekraanil; avatud jäävad vahelehtedele selle kohal, ja '
      'laias aknas saab kõrvale avada teise paneeli.';
  @override
  String get tourModesTitle => 'Kolm viisi kirjutada';
  @override
  String get tourModesBody =>
      'Kirjuta Markdown-allikas, kirjuta see nii, nagu loetakse, '
      'või loe seda — see lüliti on märkme kaupa ja kogu seade '
      'otsustab, mis avaneb.';
  @override
  String get tourToolbarTitle => 'Tööriistariba';
  @override
  String get tourToolbarBody =>
      'Vormindus real, kus oled, ja samad toimingud paremklõpsul. '
      'Iga konstruktsioon, mida Niman loeb, on spikris.';
  @override
  String get tourCheatsheetTitle => 'Iga konstruktsioon, kõrvale kirjutatud';
  @override
  String get tourCheatsheetBody =>
      'See on spikker. Iga näidet saab kopeerida ja Sisesta paneb '
      'selle avatud märkmesse.';
  @override
  String get tourCheatsheetOpen => 'Ava see';
  @override
  String get tourTabsTitle => 'Kõik on vaheleht';
  @override
  String get tourTabsBody =>
      'Failid, ülesanded, otsing, kiirmärge, seaded. Käsukataloog '
      'jõuab kõigini ja iga käsuni klaviatuurilt.';
  @override
  String get tourDockTitle => 'Liigendus, sildid, ajalugu';
  @override
  String get tourDockBody =>
      'Märkme liigendus, selle sildid ja varasemad versioonid, '
      'kõrval. Telefonis avab märkme menüü samad kolm.';
  @override
  String welcomePageOf(int page, int of) => '$page / $of';

  // Cascading a checklist tick (#326).

  @override
  String get cascadeChecklistTitle => 'Märgi pesastatud märkeruudud';
  @override
  String get cascadeChecklistSubtitle =>
      'Märkeruudu märkimine märgib ka selle alla pesastatud. Märgi '
      'eemaldamine jätab need puutumata.';

  // Rebuilding the index file (#368).

  @override
  String get rebuildIndexTitle => 'Ehita indeks uuesti üles';

  // What the template checker says in the editor (T-TPL-09).

  @override
  String templateHintDidYouMean(String fix) => 'Kas mõtlesid $fix?';
  @override
  String get templateHintNoFix =>
      'Parandust ei pakuta — tekst jääb kirjutatud kujul.';
  @override
  String get templateHintFixAction => 'Paranda';
  @override
  String get templateHintDismissAction => 'Aldesta';
  @override
  String templateProblems(int count) => count == 1
      ? '1 probleem selles šabloonis'
      : '$count probleemi selles šabloonis';
  // The wikilink panel (#475) and the two book forms it offers after `#`.

  @override
  String wikilinkHeadingsIn(String named) => 'Pealkirjad: $named';
  @override
  String wikilinkPlacesIn(String named) => 'Kohad: $named';
  @override
  String get wikilinkThisNote => 'see märge';
  @override
  String wikilinkNoMatchHeading(String query) =>
      'Ükski pealkiri ei vasta päringule „$query”.';
  @override
  String wikilinkNoMatchNote(String query) =>
      'Ükski märge ei vasta päringule „$query”.';
  @override
  String get wikilinkNoHeading => 'selles märkes pole sellenimelist pealkirja';
  @override
  String get wikilinkNoNote => 'kogus pole midagi selle nime või aliasega';
  @override
  String wikilinkAlias(String alias) => 'alias $alias';
  @override
  String get wikilinkBookNote =>
      'Leht valitakse, mitte ei nimetata nimekirjast: kirjuta selle number.';
  @override
  String get wikilinkFooterMove => 'liiguta';
  @override
  String get wikilinkFooterOr => 'või';
  @override
  String get wikilinkFooterInsert => 'sisesta';
  @override
  String get wikilinkFooterClose => 'sulge';
  @override
  String get suggesterPageHint => 'kirjuta number';
  @override
  String get suggesterChapterHint => 'nimeta fail raamatus';

  // What the template checker found, as the hint writes it (T-TPL-09).

  @override
  String get templateProblemUnclosedBraces =>
      'avatud loogsulud ilma lõputa: miski ei sulge seda kohatäidet';
  @override
  String get templateProblemEmptyPlaceholder =>
      'tühi kohatäide: sulgude vahel pole nime';
  @override
  String templateProblemUnknownPlaceholder(String name) =>
      'tundmatu kohatäide „$name”';
  @override
  String templateProblemAskNoLabel(String name) =>
      '„$name” ilma sildita: see ei küsi midagi ja kohatäide jääb paigale';
  @override
  String templateProblemCounterNoName(String name) =>
      '„$name” ilma nimeta: see ei loenda midagi ja kohatäide jääb paigale';
  @override
  String templateProblemCursorFilters(String name) =>
      '„$name” ei võta filtreid: kursorit ei asetata ja kohatäide jääb paigale';
  @override
  String get templateProblemUnclosedQuote =>
      'sulgemata jutumärk kuupäevaformaatis: kõik selle järel loetakse '
      'tavalise '
      'tekstina';
  @override
  String templateProblemUnknownDateToken(String token) =>
      'tundmatu kuupäevatoken „$token”';
  @override
  String get templateProblemEmptyFilter => 'tühi filter: „|” järel pole nime';
  @override
  String templateProblemDateMove(String filter, String formats) =>
      '„$filter” liigutab kuupäeva: liigutamist võtavad vastu ainult $formats, '
      'ja ainult enne ükskõik millist muud filtrit';
  @override
  String templateProblemNotADateMove(String filter) =>
      '„$filter” ei ole kuupäeva liigutamine: liigutamine on arv ja ühik, nagu '
      '„+7d” või „-1w”';
  @override
  String templateProblemSnapUnit(String filter, String units, String unit) =>
      '„$filter” kinnitub $units külge, mitte „$unit”';
  @override
  String templateProblemPadWidth(String filter, String argument) =>
      '„$filter” vajab laiuse jaoks arvu ja „$argument” pole see';
  @override
  String templateProblemUnknownFilter(String name) => 'tundmatu filter „$name”';
  @override
  String get diagramTitle => 'Diagramm';

  @override
  String get fullScreen => 'Täisekraan';
  @override
  String get commandInsertDiagram => 'Lisa diagramm (Mermaid)';

  @override
  String get commandInsertMindMap => 'Lisa mõttemap';

  @override
  String get commandConvertListToMindMap => 'Teisenda loend mõttemapiks';
  @override
  String get toolMindMapSubtitle => 'Asendab kursoril oleva loendi mõttemapiga';

  @override
  String get toolMindMapNeedsList => 'Kursor ei ole loendis';

  @override
  String ocrEngineName(String version) => 'Tesseract $version';

  @override
  String get settingsSectionTextRecognition => 'Tekstituvastus';

  @override
  String get ocrIntro =>
      'Loeb skannitud PDF-ide ja piltide teksti nende kõrvale '
      'märkmesse. Kõik toimub selles seadmes: mootor ja iga keel '
      'laaditakse alla üks kord, kui neid esimest korda vaja läheb.';

  @override
  String get ocrEngineTitle => 'Mootor';

  @override
  String get ocrEngineSystem => 'Süsteemi teek';

  @override
  String get ocrEngineBundled => 'Rakendusega kaasas';

  @override
  String get ocrEngineUnavailable => 'Selle seadme jaoks pole mootorit';

  @override
  String get ocrEngineDeleteTitle => 'Kas kustutada mootor?';

  @override
  String get ocrQualityTitle => 'Kvaliteet';

  @override
  String get ocrQualityFast => 'Kiire';

  @override
  String get ocrQualityBest => 'Parim';

  @override
  String get ocrQualityHint =>
      'Kiire: 1–4 MB keele kohta, nobe igas seadmes. Parim: 10–15 '
      'MB keele kohta, parem keeruliste skannide puhul, kaks kuni '
      'kolm korda aeglasem. Igal kvaliteedil on oma keeled.';

  @override
  String get ocrLanguageTitle => 'Vaikekeel';

  @override
  String get ocrAlsoTitle => 'Lisaks';

  @override
  String get ocrAlsoSubtitle => 'Lehtedele, kus on segamini kaks keelt';

  @override
  String get ocrAlsoNone => 'Puudub';

  @override
  String ocrOnDevice(String size) => 'Selles seadmes · $size';

  @override
  String get ocrOtherLanguages => 'Muud keeled';

  @override
  String ocrSearchLanguages(int count) => 'Otsi $count keele seast';

  @override
  String get ocrLanguageDefault => 'Vaikimisi';

  @override
  String ocrLanguageDeleteTitle(String language) => 'Kas kustutada $language?';

  @override
  String ocrDeleteBody(String size) =>
      'See vabastab $size. Fail laaditakse uuesti alla, kui '
      'tekstituvastus seda vajab.';

  @override
  String get ocrRecognizeAction => 'Tuvasta tekst';

  @override
  String get ocrPagesTitle => 'Lehed';

  @override
  String ocrPagesAll(int count) => 'Kõik $count';

  @override
  String ocrPagesThis(int page) => 'See leht ($page)';

  @override
  String get ocrPagesFrom => 'Alates';

  @override
  String get ocrPagesTo => 'kuni';

  @override
  String get ocrSavedAs => 'Salvestatakse nimega';

  @override
  String get ocrSavedAsHint =>
      'Märge faili kõrval, iga lehe jaoks üks jaotis. Otsing leiab '
      'selle nagu iga märkme.';

  @override
  String get ocrPdfHasText =>
      'See PDF sisaldab juba teksti: seda ei pruugi olla vaja tuvastada.';

  @override
  String ocrNeedsDownload(String size) => 'Kõigepealt $size allalaadimist';

  @override
  String get ocrNeedsDownloadHint =>
      'Ainult üks kord: siis töötab võrguühenduseta.';

  @override
  String get ocrDownloadAndRecognize => 'Laadi alla ja tuvasta';

  @override
  String ocrRecognizing(int page, int total) => 'Tuvastan lk $page / $total';

  @override
  String get ocrPreparing => 'Laadin alla, mida tekstituvastus vajab…';

  @override
  String ocrRecognized(int words) => 'Tekst tuvastatud · $words sõna';

  @override
  String get ocrOpenText => 'Ava tekst';

  @override
  String get ocrFailed => 'Tekstituvastus nurjus';

  @override
  String get commandNeedOcrFile => 'Vajab ekraanile PDF-i või pilti';

  @override
  String get ocrTextTitle => 'Tekst';

  @override
  String get ocrScanTitle => 'Skann';

  @override
  String get ocrOpenAsNote => 'Ava märkmena';

  @override
  String get ocrShowText => 'Näita teksti';

  @override
  String get ocrHideText => 'Peida tekst';

  @override
  String get ocrCopyText => 'Kopeeri';

  @override
  String ocrLostPlaces(int page, int lines) =>
      'lk $page: $lines rida kaotas oma koha skannil. Märkused seal '
      'kehtivad kogu lehe kohta.';

  @override
  String ocrRecognizeAgain(int page) => 'Tuvasta lk $page uuesti';

  @override
  String get captureWebPage => 'Salvesta veebileht';

  @override
  String get capturePageField => 'Leht';

  @override
  String get captureFromClipboard => 'Võetud lõikelaualt.';

  @override
  String get captureInvalidUrl => 'Veebiaadress algab http:// või https://.';

  @override
  String get captureRead => 'Loe';

  @override
  String get captureDownloading => 'Laadin alla…';

  @override
  String captureDownloaded(String size) => 'Alla laaditud · $size';

  @override
  String captureFewWords(int words) => 'Leiti ainult $words sõna';

  @override
  String get captureRunningBrowser => 'Lehte käitatakse brauseris…';

  @override
  String get captureBrowserPrivacy =>
      'Brauser töötab peidetult, oma profiiliga, mis pärast kustutatakse: '
      'sinu brauserit ja selle sisselogimisi ei puudutata.';

  @override
  String get captureReadInBrowser => 'Loetud pärast lehe käitamist brauseris';

  @override
  String get captureNoArticle =>
      'Artiklit ei leitud: märkmesse jäävad pealkiri, kirjeldus ja link.';

  @override
  String get captureTitleField => 'Pealkiri';

  @override
  String get captureFolderField => 'Kaust';

  @override
  String get captureAddTag => 'Lisa silt';

  @override
  String get capturePreview => 'Eelvaade';

  @override
  String captureWordsMinutes(int words, int minutes) =>
      '$words sõna · $minutes min';

  @override
  String captureDownloadPictures(int count, String folder) =>
      'Laadi $count pilti kausta $folder/';

  @override
  String get captureRemoved => 'Eemaldatud';

  @override
  String captureRemovedCode(int scripts, int styles) =>
      '$scripts skripti ja $styles stiili';

  @override
  String get captureRemovedMenu => 'Navigeerimismenüü';

  @override
  String get captureRemovedBanner => 'Küpsiste bänner';

  @override
  String captureRemovedAround(int words) => 'Ülejäänud leht · $words sõna';

  @override
  String get captureSaveNote => 'Salvesta märge';

  @override
  String get captureSaving => 'Salvestan…';

  @override
  String captureUnreadableNotice(String url) =>
      'Niman ei saanud seda lehte lugeda: see näitab oma teksti alles pärast '
      'sisselogimist või skripti, mida ei õnnestunud käitada. [Ava '
      'link](<$url>), et seda lugeda.';

  @override
  String get captureFailScheme =>
      'Salvestada saab ainult http- ja https-lehti.';

  @override
  String get captureFailRedirects => 'Leht suunab liiga palju kordi ümber.';

  @override
  String get captureFailTimeout => 'Leht ei vastanud õigel ajal.';

  @override
  String get captureFailTooLarge => 'Leht on suurem kui 10 MB.';

  @override
  String get captureFailNotHtml => 'See pole veebileht: fail, PDF või pilt.';

  @override
  String captureFailStatus(String code) => 'Sait vastas veaga ($code).';

  @override
  String get captureFailNetwork =>
      'Lehte ei õnnestunud avada: kontrolli ühendust.';

  @override
  String get captureDropHint => 'Lase lahti, et see leht salvestada';

  @override
  String get captureDropDetail => 'Sellega avaneb salvestamise aken.';

  @override
  String get captureSaveToNiman => 'Salvesta Nimanisse';

  @override
  String get captureBackgroundHint =>
      'Naased brauserisse; teavitus annab teada, kui märge on valmis.';

  @override
  String get captureAppendToNote => 'Lisa märkmele';

  @override
  String get captureAppend => 'Lisa';

  @override
  String captureReadingHost(String host) => 'Loen lehte $host…';

  @override
  String captureSavedTitle(String title) => 'Salvestatud: $title';

  @override
  String captureSavedBody(String folder, int words, int images) =>
      '$folder · $words sõna · $images pilti';

  @override
  String get captureSavedUnreadable => 'Salvestatud ilma artiklita';

  @override
  String captureUnreadableBody(String host) =>
      '$host lugeda ei õnnestunud: alles on pealkiri, kirjeldus ja link';

  @override
  String captureQuoteAdded(String note) => 'Tsitaat lisati märkmele $note';

  @override
  String captureQuoteFrom(String title) => 'lehelt „$title“';

  @override
  String captureFailedTitle(String host) => '$host salvestamine ebaõnnestus';

  @override
  String get captureShowFolder => 'Näita kausta';

  @override
  String get captureOpen => 'Ava';

  @override
  String get captureQuote => 'Tsitaat';

  @override
  String captureNewNoteIn(String folder) => 'Uus märge kaustas $folder';

  @override
  String captureDownloadPicturesTo(String folder) =>
      'Laadi pildid kausta $folder/';

  @override
  String get highlightAction => 'Tõsta esile';

  @override
  String get highlightMark => 'Esiletõst';

  @override
  String get highlightRemove => 'Eemalda esiletõst';

  @override
  String get highlightFailed => 'Esiletõstu ei õnnestunud salvestada';

  @override
  String get highlightYellow => 'Kollane';

  @override
  String get highlightGreen => 'Roheline';

  @override
  String get highlightBlue => 'Sinine';

  @override
  String get highlightPink => 'Roosa';

  @override
  String get highlightCopy => 'Kopeeri';
}
