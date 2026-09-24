// The Slovak strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class SlovakStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'január',
    'február',
    'marec',
    'apríl',
    'máj',
    'jún',
    'júl',
    'august',
    'september',
    'október',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mar',
    'apr',
    'máj',
    'jún',
    'júl',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'pondelok',
    'utorok',
    'streda',
    'štvrtok',
    'piatok',
    'sobota',
    'nedeľa',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'po',
    'ut',
    'st',
    'št',
    'pi',
    'so',
    'ne',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Kôš';
  @override
  String get trashSubtitle =>
      'Smazané prvky sa presunú do .trash/ (vypnuté = trvalé vymazanie)';
  @override
  String get trashAutoEmptyTitle => 'Automatické vyprázdnenie koša';
  @override
  String get trashAutoEmptySubtitle =>
      'Staršie zmazané položky zmiznú natrvalo pri otvorení knižnice';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nikdy'
      : switch (days) {
          1 => '1 deň',
          >= 2 && <= 4 => '$days dni',
          _ => '$days dní',
        };
  @override
  String get debugLogsTitle => 'Diagnostické záznamy';
  @override
  String get debugLogsSubtitle =>
      'Ukladá udalosti aplikácie do pamäťového bufferu';
  @override
  String get lineNumbersTitle => 'Čísla riadkov';
  @override
  String get lineNumbersSubtitle =>
      'Zobraziť stĺpec čísel riadkov v editori poznámky';
  @override
  String get readableLineLengthTitle => 'Čitateľná dĺžka riadka';
  @override
  String get readableLineLengthSubtitle =>
      'Držať text poznámky vo vycentrovanom stĺpci namiesto celej šírky okna';
  @override
  String get noteColumnWidthTitle => 'Šírka stĺpca';
  @override
  String get noteColumnWidthSubtitle =>
      'Aký široký je stĺpec poznámky, v pixeloch';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Klávesnica pri otvorení';
  @override
  String get keyboardOnOpenSubtitle =>
      'Zobraziť klávesnicu pri otvorení poznámky (vypnuté = pri prvom '
      'dotyku)';
  @override
  String get editorKindSource => 'Markdown zdroj';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Zdroj Markdown, tak ako je napísaný';
  @override
  String get editorKindWysiwygSubtitle => 'Formátovaný text, upravovaný priamo';
  @override
  String get settingsFolderToCreate => 'na vytvorenie';
  @override
  String get settingsSearchHint => 'Hľadať v nastaveniach';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 nájdené nastavenie' : '$count nájdených nastavení';
  @override
  String get settingsToggleOn => 'Zapnuté';
  @override
  String get settingsToggleOff => 'Vypnuté';
  @override
  String get switchToWysiwygTooltip => 'Prepnúť na WYSIWYG editor';
  @override
  String get switchToSourceTooltip => 'Prepnúť na Markdown zdroj';
  @override
  String get switchToSourceLabel => 'Zdroj';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Vzhľad';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Knižnica';
  @override
  String get settingsSectionReminders => 'Pripomienky';
  @override
  String get settingsSectionShortcuts => 'Klávesnica';
  @override
  String get keyboardShortcutsTitle => 'Klávesové skratky';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Knižnica $name';
  @override
  String get settingsGroupLibraryHint => 'platí len pre túto knižnicu';
  @override
  String get settingsGroupMaintenance => 'Údržba';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Priečinky a cesty';
  @override
  String get settingsAreaTrashHistory => 'Kôš a kronológia';
  @override
  String get settingsAreaDiagnostics => 'Diagnostika a info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Vyžaduje pripojenú fyzickú klávesnicu';
  @override
  String get settingsSectionUpdates => 'Aktualizácie';
  @override
  String get autoUpdateTitle => 'Automatické aktualizácie';
  @override
  String get autoUpdateSubtitle =>
      'Kontroluje GitHub Releases pri spustení a každých 6 hodín';
  @override
  String get checkForUpdatesTitle => 'Skontrolovať aktualizácie';
  @override
  String updateAvailableMessage(Object version) =>
      'K dispozícii je Niman $version';
  @override
  String get updateUpToDate => 'Niman je aktuálny';
  @override
  String get updateCheckFailed => 'Kontrola aktualizácií zlyhala';
  @override
  String updateSavedTo(Object path) => 'Aktualizácia uložená do $path';
  @override
  String get updateInstallerStarted => 'Inštalátor spustený';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Kontrola pravopisu';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podčiarkuje pravopisné chyby počas písania.';
  @override
  String get spellCheckDictionaryTitle => 'Slovník';
  @override
  String get spellCheckDictionarySystem => 'Systémové predvolené';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Výber slovníkov';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Vyberte všetky jazyky, v ktorých je knižnica napísaná. Slovo prejde, '
      'ak ho pozná niektorý z vybraných slovníkov; bez výberu rozhoduje '
      'jazyk systému.';
  @override
  String get spellCheckNoDictionaries =>
      'Na tomto systéme sa nenašli slovníky.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Kontrola pravopisu';
  @override
  String get spellCheckTitle => 'Pravopis';
  @override
  String get spellCheckEmpty => 'Žiadne pravopisné chyby.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nie je nainštalovaný na tomto systéme.';
  @override
  String get spellCheckNoSuggestions => 'Žiadne návrhy';
  @override
  String spellCheckCount(int count) => '$count na kontrolu';
  @override
  String spellCheckLine(int line) => 'riadok $line';
  @override
  String get addWordToDictionary => 'Pridať do slovníka';

  @override
  String indentWidthValue(int spaces) => '$spaces medzier';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Jas';
  @override
  String get themeBrightnessSubtitle =>
      'Svetlé, tmavé alebo nastavenie zariadenia';
  @override
  String get themeBrightnessSystem => 'Systém';
  @override
  String get themeBrightnessDay => 'Svetlé';
  @override
  String get themeBrightnessNight => 'Tmavé';
  @override
  String get themeTitle => 'Téma';
  @override
  String get themeSubtitle => 'Farby rozhrania a poznámky';
  @override
  String get themePaletteSystem => 'Systém';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Témy';
  @override
  String get themesInUse => 'Používa sa';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Nový motív';
  @override
  String get themeNewName => 'Názov';
  @override
  String get themeNewStartFrom => 'Začať od';
  @override
  String get themeNewRandom => 'Náhodné farby';
  @override
  String get themeNameTaken => 'Motív s týmto názvom už existuje';
  @override
  String themeDeleteBody(String name) =>
      'Odstrániť „$name“? Jeho farby zmiznú navždy.';
  @override
  String get themeDuplicate => 'Duplikovať';
  @override
  String get themeMenuTooltip => 'Akcie motívu';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Upraviť';
  @override
  String get themeEditorTitle => 'Upraviť motív';
  @override
  String get themeEditorChrome => 'Rozhranie';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Zoznamy úloh (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Každá farba sa volá ako v exportovanom súbore';
  @override
  String get themeEditorDiscardTitle => 'Zahodiť zmeny';
  @override
  String get themeEditorDiscardBody => 'Farby, ktoré ste zmenili, sa neuložia';
  @override
  String get themeEditorDiscard => 'Zahodiť';
  @override
  String get themeEditorBadColor => 'Použite #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Exportovať';
  @override
  String themeExportDone(String where) => 'Motív exportovaný do $where';
  @override
  String themeFileFailed(String error) =>
      'Motív sa nepodarilo preniesť: $error';
  @override
  String get themeImport => 'Importovať';
  @override
  String get themeImportInvalid => 'Tento súbor nie je motív Niman';
  @override
  String themeImportVersion(int version) =>
      'Tento motív je z novšieho Nimanu (verzia $version)';
  @override
  String themeImportBadRole(String role) => 'Súbor neuvádza farbu pre „$role“';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Veľkosť textu rozhrania';
  @override
  String get uiTextScaleSubtitle =>
      'Strom, záložky a dialógy; nad nastavením systému';
  @override
  String get noteTextScaleTitle => 'Veľkosť textu poznámky';
  @override
  String get noteTextScaleSubtitle => 'Editor a náhľad sú vždy v súlade';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formát odkazu';
  @override
  String get linkTypeSubtitle => 'Čo gumb odkazu napíše do editora';
  @override
  String get linkTypeWikilink => 'Wiki odkaz';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Vytvárať chýbajúce poznámky v';
  @override
  String get missingNoteLocationRoot => 'Koreň knižnice';
  @override
  String get missingNoteLocationCurrentFolder => 'Aktuálny priečinok';
  @override
  String get indentWidthTitle => 'Šírka odsadenia';
  @override
  String get indentWidthSubtitle =>
      'Počet medzier pridaných na každú úroveň odsadenia v editore';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Jazyk';
  @override
  String get languageSubtitle => 'Jazyk vlastného textu aplikácie';
  @override
  String get languageSystem => 'Systém';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Pridať položku';
  @override
  String get listAddTooltip => 'Pridať položku';
  @override
  String get listEmpty => 'Zatiaľ žiadne položky';
  @override
  String get listDragHandleLabel => 'Zmeniť poradie položky';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Zatiaľ žiadne nahrávky';
  @override
  String get audioRecord => 'Nahrať';
  @override
  String get audioStop => 'Zastaviť';
  @override
  String get audioPlay => 'Prehrať';
  @override
  String get audioDelete => 'Vymazať nahrávku';
  @override
  String get audioImport => 'Importovať zvukový súbor';
  @override
  String get audioRecording => 'Nahráva sa…';
  @override
  String get audioPermissionDenied =>
      'Povolenie na mikrofón bolo zamietnuté — nahrávanie ho vyžaduje.';
  @override
  String get newAudioNoteTitle => 'Nová hlasová poznámka';
  @override
  String get newAudioNoteDefault => 'Moja nahrávka';
  @override
  String get showAudioTooltip => 'Zobraziť nahrávky';
  @override
  String get audioMessageHint => 'Napíšte poznámku…';
  @override
  String get audioSend => 'Odoslať';
  @override
  String get audioRename => 'Premenovať nahrávku';
  @override
  String get audioDescriptionHint => 'Opíšte túto nahrávku…';
  @override
  String get audioEditDescription => 'Upraviť popis';
  @override
  String get audioDeleteNote => 'Vymazať poznámku';
  @override
  String get audioEditNote => 'Upraviť poznámku';
  @override
  String get audioPause => 'Pozastaviť';
  @override
  String get audioEditTitle => 'Upraviť názov';
  @override
  String get audioTitleHint => 'Názov tejto nahrávky…';
  @override
  String audioUntitled(int n) => 'Nahrávka $n';
  @override
  String get audioMoreActions => 'Ďalšie akcie';
  @override
  String get audioDiscardRecording => 'Zahodiť nahrávku';
  @override
  String get audioPauseRecording => 'Pozastaviť nahrávanie';
  @override
  String get audioResumeRecording => 'Pokračovať v nahrávaní';
  @override
  String get audioRecordingPaused => 'Pozastavené';
  @override
  String get audioSavingRecording => 'Ukladanie…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Rýchla poznámka';
  @override
  String get trayOpen => 'Otvoriť Niman';
  @override
  String get trayQuit => 'Ukončiť';
  @override
  String get closeToTrayTitle => 'Zavrieť do oblasti upozornení';
  @override
  String get closeToTraySubtitle =>
      '× okna skryje Niman a nechá ho bežať, takže pripomienky stále '
      'prichádzajú. Ukončenie z ponuky ikony.';
  @override
  String get shortcutNewTodo => 'Nová úloha';
  @override
  String get shortcutNewNote => 'Nová poznámka';
  @override
  String get shortcutNewList => 'Nový zoznam';
  @override
  String get shortcutNewAudio => 'Nová hlasová poznámka';
  @override
  String get shortcutToggleSidebar => 'Zobraziť alebo skryť filter';
  @override
  String get shortcutCloseTab => 'Zavrieť aktuálnu poznámku';
  @override
  String get shortcutNextTab => 'Ďalšia otvorená poznámka';
  @override
  String get shortcutPreviousTab => 'Predchádzajúca otvorená poznámka';
  @override
  String get shortcutEditorSection => 'V editore';
  @override
  String get shortcutFormatSection => 'Formátovanie';
  @override
  String get shortcutFind => 'Hľadať';
  @override
  String get shortcutReplace => 'Hľadať a nahradiť';
  @override
  String get shortcutSavingNote =>
      'Zmeny sa ukladajú automaticky, takže neexistuje skratka na uloženie.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Načítava sa…';
  @override
  String get noteStatusSaving => 'Ukladá sa…';
  @override
  String get noteStatusUnsaved => 'Neuložené';
  @override
  String get noteStatusSaved => 'Uložené';
  @override
  String get noteStatusError => 'Chyba';
  @override
  String get noteNotText =>
      'Tento súbor nie je textová poznámka, preto ho Niman nemôže zobraziť tu.';
  @override
  String get noteLoadFailed => 'Túto poznámku sa nepodarilo otvoriť.';
  @override
  String wordCount(int count) => switch (count) {
    1 => '1 slovo',
    >= 2 && <= 4 => '$count slová',
    _ => '$count slov',
  };
  @override
  String get outlineTooltip => 'Štruktúra';
  @override
  String get outlineNoHeadings => 'Žiadne nadpisy';
  @override
  String get outlineNoTitle => '(bez nadpisu)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Tučné';
  @override
  String get toolbarItalic => 'Kurzíva';
  @override
  String get toolbarStrikethrough => 'Prečiarknuté';

  @override
  String get toolbarHighlight => 'Zvýraznenie';
  @override
  String get toolbarSuperscript => 'Horný index';
  @override
  String get toolbarUnderline => 'Podčiarknuté';
  @override
  String get toolbarLink => 'Odkaz';
  @override
  String get toolbarCode => 'Kódový blok';
  @override
  String get toolbarImage => 'Vložiť obrázok';
  @override
  String get toolbarTable => 'Tabuľka';
  @override
  String get tableRow => 'Riadok';
  @override
  String get tableColumn => 'Stĺpec';
  @override
  String get tableAddRowAbove => 'Vložiť riadok nad';
  @override
  String get tableAddRowBelow => 'Vložiť riadok pod';
  @override
  String get tableMoveRowUp => 'Posunúť riadok nahor';
  @override
  String get tableMoveRowDown => 'Posunúť riadok nadol';
  @override
  String get tableDuplicateRow => 'Duplikovať riadok';
  @override
  String get tableDeleteRow => 'Odstrániť riadok';
  @override
  String get tableAddColumnLeft => 'Vložiť stĺpec vľavo';
  @override
  String get tableAddColumnRight => 'Vložiť stĺpec vpravo';
  @override
  String get tableMoveColumnLeft => 'Posunúť stĺpec doľava';
  @override
  String get tableMoveColumnRight => 'Posunúť stĺpec doprava';
  @override
  String get tableAlignLeft => 'Zarovnať vľavo';
  @override
  String get tableAlignCenter => 'Na stred';
  @override
  String get tableAlignRight => 'Zarovnať vpravo';
  @override
  String get tableDuplicateColumn => 'Duplikovať stĺpec';
  @override
  String get tableDeleteColumn => 'Odstrániť stĺpec';
  @override
  String get tableSortAscending => 'Zoradiť podľa stĺpca (A → Z)';
  @override
  String get tableSortDescending => 'Zoradiť podľa stĺpca (Z → A)';
  @override
  String get tableAddRow => 'Pridať riadok';
  @override
  String get tableAddColumn => 'Pridať stĺpec';
  @override
  String get cheatsheetTitle => 'Ťahák k Markdownu';
  @override
  String get cheatsheetCopy => 'Kopírovať';
  @override
  String get cheatsheetCopied => 'Skopírované';
  @override
  String get cheatsheetInsert => 'Vložiť do poznámky';
  @override
  String get cheatsheetWritten => 'Zápis';
  @override
  String get cheatsheetShown => 'Zobrazenie';
  @override
  String get cheatHeadings => 'Nadpisy';
  @override
  String get cheatEmphasis => 'Tučné, kurzíva, prečiarknuté';
  @override
  String get cheatHtmlFormats => 'Podčiarknuté, horný index, dolný index';
  @override
  String get cheatLists => 'Zoznamy';
  @override
  String get cheatChecklists => 'Kontrolné zoznamy';
  @override
  String get cheatQuotes => 'Citáty';

  @override
  String get cheatCallouts => 'Zvýraznené bloky';
  @override
  String get cheatLinks => 'Odkazy';
  @override
  String get cheatWikilinks => 'Odkazy na poznámky';
  @override
  String get cheatEmbeds => 'Obrázky a vloženia';
  @override
  String get cheatTags => 'Štítky';
  @override
  String get cheatInlineCode => 'Kód vo vete';
  @override
  String get cheatCodeBlocks => 'Bloky kódu';
  @override
  String get cheatMath => 'Matematika';
  @override
  String get cheatTables => 'Tabuľky';
  @override
  String get cheatFootnotes => 'Poznámky pod čiarou';
  @override
  String get cheatRule => 'Vodorovná čiara';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Zástupné symboly šablón';
  @override
  String get menuAddLink => 'Pridať odkaz';
  @override
  String get menuAddExternalLink => 'Pridať externý odkaz';
  @override
  String get menuFormat => 'Formát';
  @override
  String get menuParagraph => 'Odsek';
  @override
  String get menuInsert => 'Vložiť';
  @override
  String get menuBody => 'Bežný text';
  @override
  String get formatSubscript => 'Dolný index';
  @override
  String get formatInlineCode => 'Kód';
  @override
  String get insertFootnote => 'Poznámka pod čiarou';
  @override
  String get insertRule => 'Vodorovná čiara';
  @override
  String get insertCodeBlock => 'Blok kódu';
  @override
  String get insertMathBlock => 'Matematický blok';
  @override
  String get menuHeadingWord => 'Nadpis';
  @override
  String get toolbarHeading => 'Nadpis';
  @override
  String get toolbarList => 'Zoznam';
  @override
  String get toolbarOrderedList => 'Číslovaný zoznam';
  @override
  String get toolbarChecklist => 'Kontrolný zoznam';
  @override
  String get toolbarQuote => 'Citát';
  @override
  String get toolbarIndent => 'Odsadenie';
  @override
  String get toolbarOutdent => 'Zrušiť odsadenie';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Nástroje';
  @override
  String get editorToolsTitle => 'Nástroje editora';
  @override
  String get toolCountListTitle => 'Spočítať zoznam';
  @override
  String get toolCountListSubtitle =>
      'Sčíta, čo riadky vymenúvajú, ako zaškrtávací zoznam';
  @override
  String get toolCountListNeedsList =>
      'Táto poznámka nemá zoznam na spočítanie';
  @override
  String get tallySourceLabel => 'Zoznam';
  @override
  String get tallyCutLabel => 'Čítať každý riadok ako';
  @override
  String get tallyCutDash => 'Meno - hodnoty';
  @override
  String get tallyCutColon => 'Meno: hodnoty';
  @override
  String get tallyCutCommas => 'Hodnoty oddelené čiarkou';
  @override
  String get tallyCutWhole => 'Celý riadok ako jedna hodnota';
  @override
  String get tallySortLabel => 'Poradie';
  @override
  String get tallySortCount => 'Najčastejšie prvé';
  @override
  String get tallySortAlphabetical => 'Abecedne';
  @override
  String get tallySortFirstSeen => 'Ako sú uvedené';
  @override
  String get tallyInsert => 'Vložiť';
  @override
  String get tallyUpdate => 'Aktualizovať';
  @override
  String get tallyNothingToCount => 'Tu nie je čo počítať';
  @override
  String get headingDialogTitle => 'Úroveň nadpisu';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Panel nástrojov editora';
  @override
  String get toolbarSettingsHint =>
      'Potiahnite na zmenu poradia; oko zobrazí alebo skryje gumb.';
  @override
  String get toolbarShowButton => 'Zobraziť';
  @override
  String get toolbarHideButton => 'Skryť';
  @override
  String get toolbarResetOrder => 'Obnoviť predvolené';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Zobraziť náhľad';
  @override
  String get showEditorTooltip => 'Zobraziť editor';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(hrubá HTML tabuľka)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Hľadať v poznámkach';
  @override
  String get searchModeWords => 'Slová';
  @override
  String get searchModeContains => 'Obsahuje';
  @override
  String get searchEmptyHint =>
      'Napíšte pre vyhľadávanie v knižnici, alebo kľúč = hodnota pre '
      'filtrovanie podľa frontmatteru';
  @override
  String get searchTooShortHint => 'Napíšte aspoň 2 znaky';
  @override
  String get searchNoMatches => 'Žiadne výsledky';
  @override
  String get searchLoadMore => 'Zobraziť viac';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Nahradiť…';
  @override
  String get replaceInNoteAction => 'Nahradiť v tejto poznámke…';
  @override
  String get replaceInThisNote => 'Nahradiť v tejto poznámke';
  @override
  String get replaceWithLabel => 'Nahradiť na';
  @override
  String get replaceCaseSensitive => 'Rozlišovať veľké a malé písmená';
  @override
  String get replaceWholeWordsHint =>
      'nahrádzajú sa len presné zhody celých slov';
  @override
  String get replaceConfirm => 'Nahradiť';
  @override
  String get replaceCancel => 'Zavrieť';
  @override
  String get replaceUnavailable => 'Náhrada momentálne nie je dostupná';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Hľadať v poznámke';
  @override
  String get editorFindHint => 'Hľadať';
  @override
  String get editorReplaceHint => 'Nahradiť';
  @override
  String get editorFindCaseTooltip => 'Rozlišovať veľké a malé písmená';
  @override
  String get editorFindPreviousTooltip => 'Predchádzajúci výsledok';
  @override
  String get editorFindNextTooltip => 'Nasledujúci výsledok';
  @override
  String get editorFindCloseTooltip => 'Zavrieť vyhľadávanie';
  @override
  String get editorFindReplaceModeTooltip => 'Režim nahradzovania';
  @override
  String get editorReplaceOneTooltip => 'Nahradiť tento výsledok';
  @override
  String get editorReplaceAllTooltip => 'Nahradiť všetky výsledky';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Značky';
  @override
  String get tagsTitle => 'Značky';
  @override
  String get tagsEmpty =>
      'Zatiaľ žiadna značka — pridajte #značku alebo značky do frontmatteru';
  @override
  String get tagsBackTooltip => 'Späť do vyhľadávania';
  @override
  String get tagsNotesEmpty => 'Žiadna poznámka s touto značkou';
  @override
  String tagsNotesCapped(int limit) =>
      'Zobrazujú sa len prvé $limit — vyhľadajte značku na ohraničenie';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Odkaz sa nenašiel';
  @override
  String get headingNotFoundTitle => 'Nadpis sa nenašiel';
  @override
  String get ambiguousLinkTitle => 'Viac poznámok zodpovedá';
  @override
  String get openLinkFailed => 'Odkaz sa nedal otvoriť';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Poznámka neexistuje';
  @override
  String missingNoteDialogBody(String path) => 'Vytvoriť „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Priečinok „$folder“ neexistuje';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Otvorené';
  @override
  String get todoDone => 'Hotové';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Všetky dátumy';
  @override
  String get todoFilter => 'Filtrovať';
  @override
  String get todoNoTokens => 'Žiadne tokeny v tomto zozname';
  @override
  String get todoCountOpen => 'otvorené';
  @override
  String get todoCountDone => 'hotové';
  @override
  String get todoEmptyOpen => 'Zatiaľ žiadne otvorené úlohy';
  @override
  String get todoEmptyDone => 'Zatiaľ žiadne hotové';
  @override
  String get todoEmptyFiltered => 'Žiadna úloha nezodpovedá';
  @override
  String get todoTitle => 'Úlohy';
  @override
  String get todoAddTooltip => 'Pridať úlohu';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Formát todo.txt';
  @override
  String get todoHelpTooltip => 'Informácie o formáte';
  @override
  String get todoHelpIntro =>
      'Vaše úlohy sú obyčajný textový súbor, jedna úloha na riadok. Niman '
      'píše syntaxu za vás, ale nič neskrýva: súbor môžete upraviť v '
      'ľubovoľnom editore a Niman ho prečíta znova.';
  @override
  String get todoHelpFilesTitle => 'Dva súbory';
  @override
  String get todoHelpFilesBody =>
      'Otvorené úlohy žijú v todo.txt v koreni knižnice. Ak dokončíte '
      'jednu, riadok sa presunie do done.txt, aby todo.txt zostal krátky. '
      'Hotový riadok, ktorý sa znova ocitne v todo.txt, Niman archivuje pri '
      'ďalšom čítaní súborov.';
  @override
  String get todoHelpLineTitle => 'Anatómia riadku';
  @override
  String get todoHelpLineBody =>
      'Všetko, čo je pred popisom, je voliteľné a musí prísť v tomto '
      'poradí:';
  @override
  String get todoHelpDoneBody =>
      'Označí úlohu ako hotovú. Niman ju pridá, keď zaškrtnete políčko.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priorita. A je najvyššia. Zobrazuje sa ako emblém v zozname.';
  @override
  String get todoHelpDatesBody =>
      'Termín, potom dátum vytvorenia. S jedným dátumom je to dátum '
      'vytvorenia, pokiaľ riadok nezačína x.';
  @override
  String get todoHelpTokensTitle => 'Projekty, kontexty a značky';
  @override
  String get todoHelpTokensBody =>
      'Akékoľvek slovo v popise s ktorýmkoľvek z týchto predpon sa stane '
      'filtroiteľnou značkou. Nič nie je preddefnované: token existuje, '
      'kým ho píšete.';
  @override
  String get todoHelpProjectBody =>
      'K ktorému projektu úloha patrí, napr. +kuchyňa alebo +práca.';
  @override
  String get todoHelpContextBody =>
      'Kde alebo ako ju robíte, napr. @domov alebo @stretnutia.';
  @override
  String get todoHelpHashtagBody =>
      'Svobodná značka na to, čo nekrývajú prvé dve.';
  @override
  String get todoHelpTagsTitle => 'Dátumy a pripomienky';
  @override
  String get todoHelpTagsBody =>
      'Tieto sú kľúč:hodnota značky. Niman ich píše z dialógu úloh a číta '
      'ich kdekoľvek sa objavia na riadku.';
  @override
  String get todoHelpDueBody =>
      'Termín. Riadi farbu emblému a dátumové filtre.';
  @override
  String get todoHelpRemBody =>
      'Kedy by sa mala odoslať notifikácia, vo vašom časovom pásme. Spustí '
      'sa, keď je obrazovka vypnutá a aplikácia zatvorená.';
  @override
  String get todoHelpRemDesktop =>
      'Na počítači musí Niman bežať, keď nastane čas: pripomienka sa '
      'zobrazí, kým je aplikácia otvorená, a nič sa nespustí, keď je '
      'zatvorená.';
  @override
  String get todoHelpOtherBody =>
      'Udržiava sa presne tak, ako bolo napísané, aby značky iných todo.txt '
      'aplikácií prežili cestu. Niman ich nepoužíva, rec: included: opätovná '
      'úloha sa ešte neopakuje.';
  @override
  String get todoHelpEditTitle => 'Upravenie mimo Niman';
  @override
  String get todoHelpEditBody =>
      'Riadky, ktoré nedotknete, sa zachujú bajt po bajte. Ak upravíte '
      'riadok, Niman prepíše len ten riadok v jeho kanonickom tvare a '
      'ostane ostatok súboru nedotknutý.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Pridať úlohu';
  @override
  String get todoEditTitle => 'Upraviť úlohu';
  @override
  String get todoDescriptionHint => 'Popis';
  @override
  String get todoCancel => 'Zrušiť';
  @override
  String get todoSave => 'Uložiť';
  @override
  String get todoEditAction => 'Upraviť';
  @override
  String get todoDeleteAction => 'Vymazať';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Po lehote';
  @override
  String get todoDueToday => 'Dnes';
  @override
  String get todoDueNext7 => 'Nasledujúcich 7 dní';
  @override
  String get todoDueNoDate => 'Bez dátumu';
  @override
  String get todoRowDue => 'Termín';
  @override
  String get todoRowDueToday => 'Termín dnes';
  @override
  String get todoSortTooltip => 'Zoradiť';
  @override
  String get todoSortDue => 'Dátum termínu';
  @override
  String get todoSortPriority => 'Priorita';
  @override
  String get todoSortCreation => 'Dátum vytvorenia';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez priority';
  @override
  String get todoNoPriorityShort => 'Žiadna';
  @override
  String get todoMorePriorities => 'Viac…';
  @override
  String get todoPriorityTitle => 'Priorita';
  @override
  String get todoNoDueDate => 'Bez termínu';
  @override
  String get todoNoReminder => 'Bez pripomienky';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontext';
  @override
  String get todoAddHashtag => '# Značka';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Pripomienky úloh';
  @override
  String get todoReminderChannelDescription =>
      'Zaplanované notifikácie pre úlohy s časom pripomienky.';
  @override
  String get todoReminderBody => 'Pripomienka úlohy';
  @override
  String get todoReminderFallbackTitle => 'Pripomienka úlohy';
  @override
  String get todoReminderBlocked =>
      'Notifikácie sú vypnuté, takže sa pripomienky nezobrazia.';
  @override
  String get todoReminderBattery =>
      'Optimalizácia batérie je aktivovaná pre Niman. Systém môže zavesiť '
      'aplikáciu a stratiť čakajúce pripomienky.';
  @override
  String get todoReminderInexact =>
      'Toto zariadenie nepodporuje presné alarmy, takže pripomienka môže '
      'prísť o niekoľko minút neskôr, keď je obrazovka vypnutá.';
  @override
  String get reminderShowTokensTitle => 'Značky v notifikáciách pripomienok';
  @override
  String get reminderShowTokensSubtitle =>
      'Nechajte +projekt, @kontext a #značku v texte notifikácie. Vypnuté '
      'zobrazí len úlohu, ktorú ste napísali.';
  @override
  String get todoReminderFixAction => 'Otvoriť nastavenia';
  @override
  String get todoReminderDismissAction => 'Odhodiť';
  @override
  String get todoReminderDue => 'Termín';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Zrušiť';
  @override
  String get actionCreate => 'Vytvoriť';
  @override
  String get actionNew => 'Nové';
  @override
  String get actionSave => 'Uložiť';
  @override
  String get actionClear => 'Vyčistiť';
  @override
  String get actionChoose => 'Vybrať';
  @override
  String get actionDelete => 'Vymazať';
  @override
  String get actionRename => 'Premenovať';
  @override
  String get actionMove => 'Presunúť';
  @override
  String get saveAndClose => 'Uložiť a uzavrieť';
  @override
  String get closeUnsavedTitle => 'Neuložené zmeny';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” má neuložené zmeny. '
          'Uložiť ich pred zavrením?';
    }
    return '${names.length} poznámok má neuložené zmeny. '
        'Uložiť ich pred zavrením?';
  }

  @override
  String get closeSaveFailed => 'Uloženie zlyhalo; poznámka zostáva otvorená.';
  @override
  String get actionRestore => 'Obnoviť';
  @override
  String get actionEmpty => 'Vyprázdniť';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Skryť bočný panel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Zobraziť bočný panel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimalizovať';
  @override
  String get windowMaximizeTooltip => 'Maximalizovať';
  @override
  String get windowRestoreTooltip => 'Obnoviť';
  @override
  String get windowCloseTooltip => 'Zavrieť';
  @override
  String get tabFiles => 'Súbor';
  @override
  String get tabSearch => 'Vyhľadávanie';
  @override
  String get tabSettings => 'Nastavenia';
  @override
  String get quickNoteTitle => 'Rýchla poznámka';
  @override
  String get treeEmpty => 'Zatiaľ žiadna poznámka';
  @override
  String get selectANote => 'Vybrať poznámku';
  @override
  String get showListTooltip => 'Zobraziť zoznam';
  @override
  String get editRawTooltip => 'Upraviť hrubo';
  @override
  String get sortAscTooltip => 'Zoradiť A–Z';
  @override
  String get sortDescTooltip => 'Zoradiť Z–A';
  @override
  String get newNoteTitle => 'Nová poznámka';
  @override
  String get newItemTooltip => 'Nový';
  @override
  String get closeMenuTooltip => 'Zavrieť';
  @override
  String get newFolderTitle => 'Nový priečinok';
  @override
  String get newNoteSameFolder => 'Nová poznámka v rovnakom priečinku';
  @override
  String get newFromTemplateSameFolder =>
      'Nová zo šablóny v rovnakom priečinku';
  @override
  String trashOriginalPath(String path) => 'bola v $path';
  @override
  String get trashOriginalRoot => 'bolo v koreni kni\u017enice';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 polo\u017eka' : '$count polo\u017eiek';
  @override
  String get newNoteHere => 'Nová poznámka sem';
  @override
  String get newFolderHere => 'Nový priečinok sem';
  @override
  String get newListNoteTitle => 'Nová poznámka so zoznamom';
  @override
  String get newListNoteDefault => 'Moj zoznam';
  @override
  String get setAsQuickNote => 'Nastaviť ako rýchlu poznámku';
  @override
  String get currentQuickNote => 'Aktuálna rýchla poznámka';
  @override
  String get pinnedSection => 'Pripnuté';
  @override
  String pinnedSectionCount(int count) => 'Pripnuté · $count';
  @override
  String get templateFolderTitle => 'Priečinok šablón';
  @override
  String get newFromTemplateTitle => 'Nové zo šablóny';
  @override
  String get newFromTemplateHere => 'Nové zo šablóny sem';
  @override
  String get templateFormTitle => 'Vyplniť šablónu';
  @override
  String get templateFormBacklink => 'Odkaz späť';
  @override
  String get templateFormNoNote => 'Bez poznámky';
  @override
  String get templateFormPickNote => 'Vybrať poznámku';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Zástupné znaky šablóny';
  @override
  String get templateHelpSubtitle =>
      'Dátum, názov a ďalšie hodnoty na vyplnenie';
  @override
  String get quickNoteSubtitle =>
      'Poznámka, ktorú otvára karta Rýchla poznámka';
  @override
  String get listFolderSubtitle => 'Nové zoznamy úloh';
  @override
  String get templateFolderSubtitle => 'Zdroj pre „Nový zo šablóny“';
  @override
  String get attachmentsFolderSubtitle => 'Obrázky a zvuk vložené do poznámky';
  @override
  String get templateHelpIntro =>
      'Šablóna je obyčajná poznámka s dierami. Vytvorením poznámky z nej sa '
      'skopíruje text a vyplnia sa diery.';
  @override
  String get templateHelpUnknown =>
      'Zástupný znak, ktorý Niman nepozná, zostane presne tak, ako je '
      'napísaný, aby sa klávesnica videla v poznámke, nie aby ticho '
      'roztrhala riadok.';
  @override
  String get templateHelpValuesTitle => 'Hodnoty';
  @override
  String get templateHelpTitleBody =>
      'Názov, pod ktorým sa má vytvoriť poznámka.';
  @override
  String get templateHelpDateBody =>
      'Dnes a aktuálny čas. Obe acceptujú formát: {{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Dátum a čas spolu.';
  @override
  String get templateHelpUuidBody =>
      'Nový identifikátor, odlišný pri každom použití.';
  @override
  String get templateHelpCounterBody =>
      'Číslo, ktoré sa počíta podľa názvu, uchováva sa medzi spusteniami: '
      'prvá poznámka napíše 1, ďalšia 2. Ten istý názov v poznámke napíše '
      'to iste číslo; skombinujte s |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Zastavte kurzor tu pri vytvorení poznámky; značka sa nezapíše. Prvá '
      'značka vyhráva, bez filtrov, len nové poznámky — a klávesnica sa '
      'otvorí aj keď je autofocus vypnutý.';
  @override
  String get templateHelpDatesTitle => 'Zapisovanie dátumu';
  @override
  String get templateHelpDatesBody =>
      'Tieto označujú časti dátumu vo formáte. Čokoľvek, čo nie je, je '
      'doslova, vrátane textu v jednoduchých úvodzovkách. Názvy mesiacov a '
      'dní v týždni nasledujú jazyk aplikácie.';
  @override
  String get templateHelpYear => 'rok: 2026, 26';
  @override
  String get templateHelpMonth => 'mesiac: 03, 3, marec, mar';
  @override
  String get templateHelpDay => 'deň: 09, 9, pondelok, po';
  @override
  String get templateHelpTime => 'hodiny, minúty, sekundy';
  @override
  String get templateHelpWeek => 'ISO týždeň a kvartál: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtre';
  @override
  String get templateHelpFiltersBody =>
      'Hodnotu môžu nasledovať filtre, ktoré sa aplikujú zľava doprava.';
  @override
  String get templateHelpCaseBody =>
      'Veľké písmená, malé písmená a prvé písmeno každého slova — slovo, '
      'ktoré ste napísali veľkým, sa nemení.';
  @override
  String get templateHelpSlugBody =>
      'Odkažovací tvar textu, na vytvorenie wiki odkazu.';
  @override
  String get templateHelpPadBody =>
      'Orežte konce; doplňte nulami na požadovanú šírku; alternatíva, keď '
      'je hodnota prázdna.';
  @override
  String get templateHelpShiftBody =>
      'Posuňte dátum o dni, týždne, mesiace alebo roky — konferencia o '
      'týždeň, súbor z minulého mesiaca.';
  @override
  String get templateHelpSnapBody =>
      'Pripnite dátum na začiatok alebo koniec týždňa, mesiaca alebo roka.';
  @override
  String get templateHelpAskTitle => 'Pýtame sa vás na niečo';
  @override
  String get templateHelpAskBody =>
      'Pred vytvorením poznámky sa zobrazí formulár, poľa na otázku — a '
      'jedno na spätný odkaz, ak šablóna žiada. Tá istá značka dvakrát je '
      'otázka a jej odpoveď vyplní všetky výskyty — priečinok aj názov '
      'súboru.';
  @override
  String get templateHelpAskFieldBody =>
      'Poliečko na zápis; text po druhom dvojbode je začiatok.';
  @override
  String get templateHelpChoiceBody => 'Výber zo zoznamu, oddelený čiarkou.';
  @override
  String get templateHelpWhereTitle => 'Kam poznámka prichádza';
  @override
  String get templateHelpWhereBody =>
      'Toto nie je text: sú to inštrukcie, ktoré žijú v niman: bloku '
      'frontmatteru šablóny. Blok sa spustí a vymaže, takže sa nikdy '
      'nezobrazí v poznámke. Hodnota môže obsahovať zástupné znaky.';
  @override
  String get templateHelpFolderBody =>
      'Priečinok, do ktorého sa vytvorí poznámka, vytvorí sa, ak neexistuje. '
      'Bez neho poznámka príde, kde ste boli.';
  @override
  String get templateHelpFilenameBody =>
      'Ako sa poznámke nazve. Šablóna, ktorá to povie, nepýta na názov.';
  @override
  String get templateHelpAppendBody =>
      'Pridá k poznámke, ak už existuje, namiesto vytvorenia novej. Tak '
      'mesiac schôdzok sa stane jedným súborom.';
  @override
  String get templateHelpOpenBody =>
      'Čo sa stane, ak poznámka existuje: editor (predvolené), náhľad, alebo '
      'nič — poznámka sa archivuje a ostávate tam, kde ste boli.';
  @override
  String get templateHelpAroundTitle => 'Odkiaľ to prišlo';
  @override
  String get templateHelpParentBody =>
      'Poznámka, ktorú vyberiete vo formulári, ponúkaná na obrazovke; '
      'napíšte [[{{parent}}]] ako spätný odkaz.';
  @override
  String get templateHelpFolderValueBody =>
      'Priečinok, do ktorého poznámka prišla.';
  @override
  String get templateHelpClipboardBody =>
      'Čo je v schránke a výber v editore, keď poznámka začala odtiaľ.';
  @override
  String get templateHelpIncludeTitle => 'Opätovné použitie časti';
  @override
  String get templateHelpIncludeBody =>
      'Vložte ďalšiu šablónu, aby desať šablón mohlo zdieľať jeden '
      'kontrolný zoznam. Hľadanie sa vykoná najprv v priečinku šablón, .md '
      'môže chýbať. Jej vlastné otázky idú do toho istého formulára.';
  @override
  String get templateHelpExampleTitle => 'Všetko na jednom mieste';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ neexistuje šablóna „$path”';
  @override
  String includeCycle(String path) => '⚠ „$path” sa vkladá do seba';
  @override
  String includeTooDeep(String path) => '⚠ „$path” je príliš hlboko vložené';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter sa nedal prečítať: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter šablóny „$template” sa nedal prečítať, takže priečinok a '
      'názov súboru nič neurobili: $reason';
  @override
  String get templatePickerTitle => 'Výber šablóny';
  @override
  String templatePickerEmpty(String folder) =>
      'Zatiaľ žiadna šablóna. Vložte poznámku do $folder/ a bude šablónou.';

  // Tree actions.
  @override
  String get actionPin => 'Pripnúť';
  @override
  String get actionUnpin => 'Odpnúť';
  @override
  String get pinToWidget => 'Pripnúť k vidžetu na ploche';
  @override
  String get pinnedForWidget =>
      'Pripnuté: umiestnite vidžet Poznámka na plochu';
  @override
  String get pinWidgetUnavailable =>
      'Vidžety na ploche sú k dispozícii v Androide';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Zobraziť v správcovi súborov';
  @override
  String get openInDefaultApp => 'Otvoriť v predvolenej aplikácii';
  @override
  String get newNoteTabTooltip => 'Nová poznámka na novej karte';
  @override
  String get openNotesTooltip => 'Otvorené poznámky';
  @override
  String get closeTabTooltip => 'Zavrieť';
  @override
  String get openInNewTab => 'Otvoriť na novej karte';
  @override
  String get splitRight => 'Rozdeliť doprava';
  @override
  String get splitDown => 'Rozdeliť nadol';
  @override
  String get moveToOtherPane => 'Presunúť do druhého panela';
  @override
  String get openBeside => 'Otvoriť vedľa';
  @override
  String get closeAllNotes => 'Zavrieť všetky';
  @override
  String get sidePanelTooltip => 'Zobraziť alebo skryť bočný panel';
  @override
  String get historyAllVersions => 'Všetky verzie';
  @override
  String get commandPaletteTitle => 'Paleta príkazov';
  @override
  String get goToNoteTitle => 'Prejsť na poznámku';
  @override
  String get paletteGroupNote => 'Poznámka';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Zobrazenie';
  @override
  String get paletteGroupLibrary => 'Knižnica';
  @override
  String get paletteGroupGoTo => 'Prejsť na';
  @override
  String get paletteGroupJournal => 'Denník';
  @override
  String get journalToday => 'Dnešný záznam';
  @override
  String get journalPrevious => 'Predchádzajúci záznam';
  @override
  String get journalNext => 'Ďalší záznam';
  @override
  String get commandNeedJournalEntry => 'Vyžaduje otvorený záznam denníka';
  @override
  String journalCreateAsk(String day) =>
      'Pre $day zatiaľ nie je záznam. Vytvoriť?';
  @override
  String journalTemplateMissing(String path) =>
      'Šablónu denníka $path sa nepodarilo prečítať: záznam bol vytvorený bez '
      'nej.';
  @override
  String get journalIntro =>
      'Jedna poznámka denne, vytvorená zo šablóny pri prvom otvorení daného '
      'dňa. Tieto nastavenia cestujú s knižnicou.';
  @override
  String get journalFolderTitle => 'Priečinok denníka';
  @override
  String get journalFolderSubtitle => 'Kam idú záznamy';
  @override
  String get journalEntryNameTitle => 'Názov záznamu';
  @override
  String get journalEntryNameSubtitle =>
      'YYYY, MM alebo M, DD alebo D pre dátum; / vytvorí priečinok; text v '
      "'úvodzovkách' zostane, ako je";
  @override
  String journalEntryNamePreview(String path) => 'Dnešný záznam: $path';
  @override
  String get journalEntryNameInvalid =>
      'Potrebuje YYYY, mesiac (MM alebo M) a deň (DD alebo D), a nič, čo '
      'názov súboru nesmie obsahovať';
  @override
  String get journalTemplateTitle => 'Šablóna';
  @override
  String get journalTemplateSubtitle => 'Čím nový záznam začína';
  @override
  String get journalTemplateNone => 'Žiadna: nadpis s dátumom';
  @override
  String get journalDayStartTitle => 'Nový deň začína o';
  @override
  String get journalDayStartSubtitle =>
      'Ponocujete? O 04:00 noc ešte patrí predchádzajúcemu dňu';
  @override
  String get journalRecent => 'Nedávne';
  @override
  String get journalNoEntry => 'Pre tento deň nie je záznam';
  @override
  String get journalOpenEntry => 'Otvoriť';
  @override
  String get journalShowCalendar => 'Zobraziť kalendár';
  @override
  String get journalFabToday => 'Dnešný záznam denníka';
  @override
  String journalDueOn(String day) => 'Termín $day';
  @override
  String get commandsTitle => 'Príkazy';
  @override
  String get commandsIntro =>
      'Paleta príkazov ponúka len príkazy, ktoré sa dajú spustiť tam, kde '
      'práve ste. Tu sú všetky a kedy sa ktorý zobrazí.';
  @override
  String get commandsKeysNote =>
      'Tu sa nič nemení. Klávesy sú tie nastavené v sekcii „Klávesové '
      'skratky“ a riadia sa každou zmenou tam.';
  @override
  String get commandsOpenShortcuts =>
      'Zmeniť klávesy v sekcii „Klávesové skratky“';
  @override
  String get commandsChangeKeyTooltip => 'Zmeniť v sekcii „Klávesové skratky“';
  @override
  String get commandsSubtitle => 'Čo môže paleta príkazov spustiť, a kedy';
  @override
  String get keyboardShortcutsSubtitle => 'Zmeňte klávesy každého príkazu';
  @override
  String get commandNeedNone => 'Vždy k dispozícii';
  @override
  String get commandNeedOpenNote => 'Vyžaduje otvorenú poznámku';
  @override
  String get commandNeedWideWindow => 'Len v širokom okne';
  @override
  String get commandNeedDockRoom => 'Vyžaduje okno dosť široké pre bočný panel';
  @override
  String get commandNeedDesktop => 'Len na počítači';
  @override
  String get commandNeedNotInZen => 'Nie v režime Zen';
  @override
  String get commandNeedZenRoom => 'Počítač, s poznámkou otvorenou na karte';
  @override
  String get commandNeedPreview =>
      'So zapnutým náhľadom, pri textovej poznámke';
  @override
  String get commandNeedTwoEditors => 'So zapnutými oboma editormi';
  @override
  String get paletteHint => 'Hľadať príkazy a poznámky';
  @override
  String get paletteNoResults => 'Nič nezodpovedá';
  @override
  String get paletteCommands => 'Príkazy';
  @override
  String get paletteNotes => 'Poznámky';
  @override
  String get paletteFooter => '↑↓ pohyb · ↵ použiť · esc zavrieť';
  @override
  String get paletteFooterTouch => 'Klepnutím spustíte · špendlík drží hore';
  @override
  String get palettePinned => 'Pripnuté';
  @override
  String get palettePin => 'Pripnúť';
  @override
  String get paletteUnpin => 'Odopnúť';
  @override
  String get palettePinFooter => 'alt+P pripne';
  @override
  String get spellCheckScanning => 'Kontrola poznámky…';
  @override
  String get spellCheckAgain => 'Skontrolovať znova';
  @override
  String spellCheckCapped(int count) =>
      'Zobrazených je prvých $count: niektoré opravte a skontrolujte znova '
      'kvôli zvyšku';
  @override
  String get dropHint =>
      'Pretiahnite súbory Markdown na otvorenie alebo priečinok na import';
  @override
  String get dropNothing =>
      'Prostredie pri tomto pustení neodovzdalo žiadne súbory.';
  @override
  String get importFolderAction => 'Importovať';
  @override
  String dropRejected(String names) =>
      'Tu sa otvárajú len súbory Markdown a priečinky: $names';
  @override
  String importFolderTitle(String name) => 'Importovať „$name“?';
  @override
  String importFolderBody(int count) =>
      'Jeho súbory Markdown ($count) sa skopírujú do nového priečinka '
      'knižnice. Pretiahnutý priečinok zostane bez zmeny.';
  @override
  String importFolderDone(String folder) => 'Importované do $folder';
  @override
  String importFolderEmpty(String name) =>
      'V priečinku $name nie sú súbory Markdown';
  @override
  String get openFileTitle => 'Otvoriť súbor';
  @override
  String get outsideFileNote =>
      'Mimo knižnice: ukladá sa na mieste, bez indexu, bez histórie, odkazy '
      'sa nesledujú';
  @override
  String get typewriterOn => 'Zapnúť režim písacieho stroja';
  @override
  String get typewriterOff => 'Vypnúť režim písacieho stroja';
  @override
  String get typewriterTitle => 'Režim písacieho stroja';
  @override
  String get formatNoteTitle => 'Upratať Markdown';
  @override
  String get formatNoteDone => 'Poznámka bola upratená.';
  @override
  String get formatNoteAlreadyTidy => 'Poznámka už bola upratená.';
  @override
  String get tidyOnCloseTitle => 'Upratať Markdown pri zatvorení';
  @override
  String get tidyOnCloseSubtitle =>
      'Keď zatvoríte poznámku, ktorú ste upravovali, jej Markdown sa uprace '
      'ako príkazom „Upratať Markdown“. Poznámky väčšie ako 4 MB zostanú '
      'tak, ako sú.';
  @override
  String get typewriterSubtitle =>
      'Riadok, ktorý píšete, zostáva v strede editora';
  @override
  String get zenMode => 'Režim zen';
  @override
  String get zenModeEnter => 'Prejsť do režimu zen';
  @override
  String get zenModeLeave => 'Opustiť režim zen';
  @override
  String get keySpace => 'Medzerník';
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
  String get keyArrowUp => 'Hore';
  @override
  String get keyArrowDown => 'Dole';
  @override
  String get keyArrowLeft => 'Doľava';
  @override
  String get keyArrowRight => 'Doprava';
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
  String get shortcutNone => 'Bez skratky';
  @override
  String get shortcutRestoreDefaults => 'Obnoviť predvolené';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Vrátiť všetky skratky tak, ako ich dodáva Niman?';
  @override
  String get shortcutRevert => 'Späť na predvolenú';
  @override
  String get shortcutClear => 'Odstrániť skratku';
  @override
  String get shortcutCapturePrompt =>
      'Stlačte klávesy. Zaznamenajú sa aj Esc a Tab: odísť sa dá cez Zrušiť.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Pridajte Ctrl, Alt alebo Meta: samotný kláves slúži na písanie.';
  @override
  String get shortcutMove => 'Presunúť';
  @override
  String get shortcutUseAnyway => 'Aj tak použiť';
  @override
  String get shortcutUndo => 'Späť';
  @override
  String get shortcutRedo => 'Znova';
  @override
  String get shortcutChange => 'Zmeniť skratku';
  @override
  String shortcutCaptureTitle(String command) => 'Klávesy pre $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys už patrí k $other. Presunúť sem? $other zostane bez skratky.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys je aj $what v textových poliach a editore. Tam ju prevezme váš '
      'príkaz.';
  @override
  String get openFileMissing => 'Súbor tejto poznámky na disku nie je';
  @override
  String get openFileFailed =>
      'Túto poznámku sa nepodarilo otvoriť mimo Nimanu';
  @override
  String get attachmentUnreadable => 'Tento súbor sa nepodarilo zobraziť.';
  @override
  String get attachmentMissing => 'Tento súbor na disku nie je.';
  @override
  String get attachmentOpenFailed =>
      'Tento súbor sa nepodarilo otvoriť mimo Nimanu.';

  @override
  String get movedToTrash => 'Presunuté do koša';
  @override
  String get deletedMessage => 'Vymazané';
  @override
  String deleteToTrashConfirm(String name) => '$name sa presunie do .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name sa trvalo vymaže';
  @override
  String get chooseDestination => 'Vybrať cieľ';
  @override
  String get libraryRoot => 'Koreň knižnice';
  @override
  String moveTitle(String name) => 'Presunúť $name';
  @override
  String headingLevelLabel(int level) => 'Nadpis úrovne $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Zatiaľ žiadna rýchla poznámka. Vyberte existujúcu poznámku alebo '
      'vytvorte novú — rýchla poznámka sa otvorí tu.';
  @override
  String get quickNoteChooseAction => 'Vybrať poznámku…';
  @override
  String get quickNoteCreateAction => 'Vytvoriť novú poznámku…';
  @override
  String get quickNoteNewTitle => 'Nová rýchla poznámka';
  @override
  String get quickNotePickerTitle => 'Výber rýchlej poznámky';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nový priečinok';
  @override
  String get folderPickerEmpty => 'Zatiaľ žiadny priečinok';
  @override
  String get listFolderTitle => 'Priečinok zoznamov';
  @override
  String get attachmentsFolderTitle => 'Priečinok príloh';

  // Trash (M1).
  @override
  String get trashEmpty => 'Kôš je prázdny';
  @override
  String get trashEmptyAction => 'Vyprázdniť koš';
  @override
  String get trashEmptyConfirm =>
      'Toto trvalo vymaže všetko, čo je v koši, vrátane prvkov, ktoré Niman '
      'tam nedal.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name sa trvalo vymaže (bez obnovenia)';
  @override
  String get trashDeletePermanently => 'Trvalo vymazať';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Otvorte priečinok Markdown poznámok ako knižnicu';
  @override
  String get openLibraryExisting => 'Otvoriť existujúcu';
  @override
  String get openLibraryCreate => 'Vytvoriť novú';
  @override
  String get openLibraryCreateTitle => 'Vytvoriť novú knižnicu';
  @override
  String get openLibraryFolderName => 'Názov priečinoku';
  @override
  String get openLibraryChooseFolder => 'Vybrať priečinok knižnice';
  @override
  String get openLibraryChooseParent =>
      'Vybrať priečinok, do ktorého sa knižnica vytvorí';
  @override
  String get openLibraryUnsupported =>
      'Tento priečinok nie je podporovaný. Vyberte priečinok z úložiska '
      'zariadenia.';
  @override
  String indexingCount(int done, int total) => '$done / $total poznámok';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Vaše knižnice';
  @override
  String get libraryUnreachable => 'Nedostupná';
  @override
  String get libraryOpenedToday => 'Otvorené dnes';
  @override
  String get libraryOpenedYesterday => 'Otvorené včera';
  @override
  String libraryOpenedDaysAgo(int days) => 'Otvorené pred $days dňami';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Otvorené ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Otvorené teraz';
  @override
  String get switchLibraryTitle => 'Prepnúť knižnicu';
  @override
  String get libraryForget => 'Zabudnúť';
  @override
  String libraryForgetTitle(String name) => 'Zabudnúť na „$name”?';
  @override
  String get libraryForgetExplained =>
      'Zmizne z tohto zoznamu. Priečinok, poznámky a nastavenia knižnice '
      'zostanú nedotknuté, a opätovné otvorenie vráti na miesto.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Povoliť prístup k súborom';
  @override
  String get storageAccessNeeded =>
      'Niman nemôže čítať vaše poznámky bez „Prístup ku všetkým súborom”. '
      'Povolete ho na otvorenie knižnice.';
  @override
  String get storageAccessExplained =>
      'Niman číta vaše poznámky ako obyčajné súbory, takže Android musí dať '
      'prístup ku všetkým súborom. Niečo sa neposiela a číta sa len priečinok '
      'vybranej knižnice.';
  @override
  String folderAccessDenied(Object error) =>
      'Systém nepovolil prístup k priečinku: $error';
  @override
  String folderPickFailed(Object error) => 'Výber priečinku zlyhal: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Nastavenia';
  @override
  String get libraryPathTitle => 'Cesta knižnice';
  @override
  String get reindexTitle => 'Preindexovať teraz';
  @override
  String get reindexDone => 'Preindexovanie dokončené';
  @override
  String get closeLibraryTitle => 'Zavrieť knižnicu';
  @override
  String get exportLogTitle => 'Exportovať diagnostické záznamy';
  @override
  String get exportLogSubtitle =>
      'Uložte zaznamenané udalosti do súboru, ktorý vyberiete';
  @override
  String get exportLogEmpty => 'Buffer diagnostických záznamov je prázdny';
  @override
  String get quickNoteUnset => 'Nenastavené';
  @override
  String exportLogDone(Object target) =>
      'Diagnostické záznamy exportované do $target';
  @override
  String exportLogFailed(Object error) => 'Export zlyhal: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Žiadny presný výsledok celého slova pre „$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Nahrádzané $occurrences výskytov „$term” v $notes poznámkach';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped otvorených poznámok vynechaných)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Žiadny presný výsledok celého slova pre „$term”'
      '${only == null ? '' : ' sa nenašiel v $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'O aplikácii';
  @override
  String get versionTitle => 'Verzia';
  @override
  String get changelogTitle => 'Changelog';
  @override
  String get changelogEmpty => 'Záznamy changelogu nie sú dostupné';
  @override
  String changelogWhatsNew(String version) => 'Novinky vo verzii $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'História';
  @override
  String get noteMenuTooltip => 'Akcie poznámky';
  @override
  String get historyCurrentVersion => 'Aktuálna verzia';
  @override
  String get historyCurrentSubtitle => 'Poznámka v súčasnej podobe';
  @override
  String get historyToday => 'Dnes';
  @override
  String get historyYesterday => 'Včera';
  @override
  String get historyReasonSession => 'pred úpravami';
  @override
  String get historyReasonInterval => 'počas úprav';
  @override
  String get historyReasonRestore => 'pred obnovením';
  @override
  String get historyReasonSync => 'pred synchronizáciou';
  @override
  String get historyReasonReplace => 'pred nahradením';
  @override
  String get historyReasonUnknown => 'nájdená';
  @override
  String get historySyncBase => 'základ synchronizácie';
  @override
  String get historyEmpty =>
      'Zatiaľ žiadne verzie. Niman jednu uchová, keď začnete poznámku '
      'upravovať, a potom najviac jednu za pár minút, kým píšete.';
  @override
  String historyKept(int kept, int limit) => 'Uchované verzie: $kept z $limit';
  @override
  String get historyBaseKept => 'Základ synchronizácie sa uchová aj nad limit.';
  @override
  String get historyOff =>
      'História je pre túto knižnicu vypnutá (Nastavenia, Knižnica).';
  @override
  String get historyLoadFailed => 'Históriu sa nepodarilo načítať';
  @override
  String get historyCompareSubtitle => 'Porovnané s aktuálnou verziou';
  @override
  String get historyTabChanges => 'Zmeny';
  @override
  String get historyTabVersion => 'Verzia';
  @override
  String get historyNoChanges => 'Rovnaký text ako aktuálna verzia.';
  @override
  String get historyRestoreAction => 'Obnoviť túto verziu';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Obnoviť verziu uloženú $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Aktuálny text sa najprv uloží do histórie, takže sa môžete '
      'kedykoľvek vrátiť.';
  @override
  String get historyRestoreConfirm => 'Obnoviť';
  @override
  String historyRestored(String when) => 'Obnovená verzia uložená $when';
  @override
  String get historyRestoreFailed => 'Verziu sa nepodarilo obnoviť';
  @override
  String get actionUndo => 'Späť';
  @override
  String diffLineRange(int start, int end) => 'Riadky $start–$end';
  @override
  String diffLineSingle(int line) => 'Riadok $line';
  @override
  String diffUnchanged(int count) => switch (count) {
    1 => '1 nezmenený riadok',
    >= 2 && <= 4 => '$count nezmenené riadky',
    _ => '$count nezmenených riadkov',
  };
  @override
  String get historyTakeHunk => 'Obnoviť tu';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Obnoviť 1 zmenu' : 'Obnoviť $count zmien';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Vybrané zmeny sa vrátia k textu tejto verzie. Poznámka v súčasnej '
      'podobe sa najprv uchová ako verzia, takže to môžeš vrátiť späť.';
  @override
  String get historyNoteChangedReloaded =>
      'Poznámka sa zmenila, kým si tu bol — porovnanie bolo aktualizované.';
  @override
  String get historyVersionsTitle => 'Počet uchovaných verzií';
  @override
  String get historyVersionsSubtitle => 'Pre každú poznámku, v .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Žiadne' : '$count';
  @override
  String get historyIntervalTitle => 'Nová verzia najviac každých';
  @override
  String get historyIntervalSubtitle =>
      'Počas písania; začiatok úprav poznámky vždy jednu uchová';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Prepis';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Žiadny';
  @override
  String get transcriptionLanguageTitle => 'Jazyk';
  @override
  String get transcriptionLanguageSubtitle =>
      'Jazyk, ktorým sa vo vašich nahrávkach hovorí. Zadať ho je presnejšie '
      'ako ho nechať rozpoznať.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Ako aplikácia ($language)';
  @override
  String get transcriptionLanguageDetect => 'Rozpoznať automaticky';
  @override
  String get transcriptionModelsTitle => 'Modely prepisu';
  @override
  String transcriptionModelsUsed(String size) => 'Využité $size';
  @override
  String get transcriptionModelsInstalled => 'Stiahnuté';
  @override
  String get transcriptionModelsDownloading => 'Sťahuje sa';
  @override
  String get transcriptionModelsAvailable => 'Dostupné';
  @override
  String get transcriptionModelsFooter =>
      'Modely zostávajú v úložisku aplikácie v tomto zariadení. Nekopírujú sa '
      'do knižnice ani sa nesynchronizujú.';
  @override
  String get transcriptionModelDefault => 'Predvolený';
  @override
  String get transcriptionModelSlow => 'Pomalý';
  @override
  String get transcriptionModelHintTiny => 'Najrýchlejší, najmenej presný';
  @override
  String get transcriptionModelHintBase => 'Dobrý pomer rýchlosti a presnosti';
  @override
  String get transcriptionModelHintSmall => 'Presnejší, približne 3× pomalší';
  @override
  String get transcriptionModelHintMedium => 'Veľmi presný, v telefóne pomalý';
  @override
  String get transcriptionModelHintLarge =>
      'Najpresnejší, potrebuje veľa pamäte';
  @override
  String get transcriptionModelDownload => 'Stiahnuť';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Odstrániť model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Uvoľní sa $size. Model si môžete neskôr stiahnuť znova.';
  @override
  String get transcriptionModelFailed =>
      'Stiahnutie zlyhalo. Skontrolujte pripojenie a skúste to znova.';
  @override
  String get actionRetry => 'Skúsiť znova';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Pripojenie sa prerušilo, skúša sa znova…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pozastavené na $progress';
  @override
  String get actionResume => 'Pokračovať';
  @override
  String get audioTranscribe => 'Prepísať';
  @override
  String get audioTranscribeUnsupported => 'V tomto zariadení len nahrávky WAV';
  @override
  String get transcriptionQueued => 'V poradí';
  @override
  String get transcriptionPreparing => 'Pripravuje sa zvuk…';
  @override
  String transcriptionRunning(int percent) => 'Prepisuje sa… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Sťahuje sa $model · $percent %';
  @override
  String get transcriptionSaved => 'Prepis bol pridaný do popisu';
  @override
  String get transcriptionNoSpeech =>
      'V tejto nahrávke sa nerozpoznala žiadna reč';
  @override
  String get transcriptionFailed => 'Prepis zlyhal';
  @override
  String get transcriptionPickModelTitle => 'Vyberte model';
  @override
  String get transcriptionPickModelBody =>
      'Prepis prebieha v tomto zariadení a nahrávka sa nikam neodosiela. '
      'Model sa sťahuje len raz.';
  @override
  String get transcriptionPickModelAction => 'Stiahnuť a prepísať';
  @override
  String get transcriptionModelRecommended => 'Odporúčaný';
  @override
  String get transcriptionExistingTitle => 'Táto nahrávka už má popis';
  @override
  String get transcriptionExistingBody =>
      'Nahradiť ho prepisom, alebo prepis pridať pod neho?';
  @override
  String get transcriptionAppend => 'Pridať pod';
  @override
  String get transcriptionReplace => 'Nahradiť';
  @override
  String get settingsSectionSync => 'Synchronizácia';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Pre túto knižnicu nie je nastavená';
  @override
  String get syncNeverSynced => 'Ešte nesynchronizovaná';
  @override
  String syncLastSynced(String when) => 'Synchronizovaná $when';
  @override
  String get syncRunning => 'Synchronizuje sa…';
  @override
  String syncScreenSubtitle(String library) => 'Knižnica $library';
  @override
  String get syncUrlLabel => 'Adresa priečinka';
  @override
  String get syncUrlRequired => 'Zadajte adresu servera';
  @override
  String get syncUrlHint =>
      'Priečinok musí existovať. Skopírujte adresu tak, ako ju '
      'zobrazuje server.';
  @override
  String get syncHttpWarning =>
      'Nešifrované pripojenie: v poriadku cez VPN alebo v '
      'lokálnej sieti.';
  @override
  String get syncUserLabel => 'Používateľ';
  @override
  String get syncUserHint =>
      'Nechajte prázdne, ak server nevyžaduje prihlasovacie '
      'údaje.';
  @override
  String get syncPasswordLabel => 'Heslo';
  @override
  String get syncPasswordHint =>
      'Uložené v kľúčenke tohto zariadenia, nikdy v súboroch '
      'knižnice.';
  @override
  String get syncPasswordKeepHint =>
      'Nechajte prázdne, ak chcete ponechať uložené heslo.';
  @override
  String get syncShowPassword => 'Zobraziť heslo';
  @override
  String get syncHidePassword => 'Skryť heslo';
  @override
  String get syncTestAction => 'Otestovať pripojenie';
  @override
  String get syncTesting => 'Testuje sa…';
  @override
  String get syncRetargetWarning =>
      'S novou adresou alebo používateľom začne ďalšia '
      'synchronizácia odznova ako prvá.';
  @override
  String get syncTestOk => 'Pripojenie funguje';
  @override
  String get syncModeFull => 'Úplný režim';
  @override
  String get syncModeCompatible => 'Kompatibilný režim';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Čítanie, zápis a mazanie';
  @override
  String get syncCapEtags => 'Odtlačky súborov (ETag)';
  @override
  String get syncCapNoEtags => 'Bez odtlačkov súborov (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Porovnáva veľkosť a dátum; pri pochybnostiach sťahuje '
      'znova';
  @override
  String get syncCapGuarded => 'Chránené zápisy';
  @override
  String get syncCapUnguarded => 'Nechránené zápisy';
  @override
  String get syncCapUnguardedDetail =>
      'Tesne pred zápisom skontroluje súbor na serveri';
  @override
  String get syncCapMove => 'Premenúva bez opätovného nahrávania';
  @override
  String get syncCapNoMove => 'Bez premenovania na serveri';
  @override
  String get syncCapNoMoveDetail =>
      'Premenovanie sa zmení na vymazanie a nové nahranie';
  @override
  String get syncCompatibleNote =>
      'V kompatibilnom režime funguje synchronizácia rovnako, '
      'len s niekoľkými požiadavkami navyše.';
  @override
  String get syncTestInvalidUrl => 'Neplatná adresa';
  @override
  String get syncTestInvalidUrlHint =>
      'Zadajte adresu http:// alebo https:// bez používateľa a '
      'hesla.';
  @override
  String get syncTestOffline => 'Server je nedostupný';
  @override
  String get syncTestOfflineHint =>
      'Je zapnutá VPN? Adresa 10.x alebo 192.168.x funguje len z '
      'tej istej siete.';
  @override
  String get syncTestAuth => 'Používateľ alebo heslo boli odmietnuté';
  @override
  String get syncTestAuthHint => 'Skontrolujte ich a otestujte znova.';
  @override
  String get syncTestNotFound => 'Priečinok neexistuje';
  @override
  String get syncTestNotFoundHint =>
      'Vytvorte ho na serveri alebo opravte adresu.';
  @override
  String get syncTestUnsupported => 'Nie je to priečinok WebDAV';
  @override
  String get syncTestUnsupportedHint => 'Server odpovedá, ale nie ako WebDAV.';
  @override
  String get syncTestFailed => 'Test sa nepodaril';
  @override
  String get syncNowAction => 'Synchronizovať teraz';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresa, používateľ a heslo';
  @override
  String get syncRetestTitle => 'Otestovať server znova';
  @override
  String syncProbedAgo(String when) => 'Posledný test $when';
  @override
  String get syncDisconnectTitle => 'Odpojiť túto knižnicu';
  @override
  String get syncDisconnectSubtitle => 'Súbory zostanú tu aj na serveri';
  @override
  String get syncDisconnectConfirmTitle => 'Odpojiť synchronizáciu?';
  @override
  String get syncDisconnectConfirmBody =>
      'Táto knižnica sa na tomto zariadení prestane '
      'synchronizovať. Nevymaže sa žiadny súbor, ani tu, ani na '
      'serveri. Ak ju znova pripojíte, prvá synchronizácia začne '
      'odznova.';
  @override
  String get syncDisconnectConfirm => 'Odpojiť';
  @override
  String get syncFirstTitle => 'Prvá synchronizácia';
  @override
  String get syncFirstIntro => 'Knižnica porovnaná s priečinkom na serveri:';
  @override
  String get syncFirstUpload => 'Na nahratie';
  @override
  String get syncFirstDownload => 'Na stiahnutie';
  @override
  String get syncFirstBoth => 'Na oboch stranách';
  @override
  String get syncFirstBothHint =>
      'Rovnaké: bez prenosu. Rozdielne: na vyriešenie';
  @override
  String get syncFirstNoDelete =>
      'Prvá synchronizácia nič nevymaže, ani tu, ani na serveri.';
  @override
  String get syncStartAction => 'Spustiť';
  @override
  String syncMassTrashTitle(int count) => count == 1
      ? 'Presunúť 1 súbor do koša?'
      : count >= 2 && count <= 4
      ? 'Presunúť $count súbory do koša?'
      : 'Presunúť $count súborov do koša?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Na serveri chýba $count z $total synchronizovaných '
      'súborov. Zvyčajne to znamená nesprávnu adresu, '
      'nepripojený disk NAS alebo omylom vyprázdnený priečinok.';
  @override
  String get syncMassTrashHint =>
      'Ak ste ich naozaj vymazali na inom zariadení, potvrďte: '
      'tu sa presunú do koša.';
  @override
  String get syncMassTrashConfirm => 'Presunúť do koša';
  @override
  String syncMassDeleteTitle(int count) => count == 1
      ? 'Vymazať 1 súbor zo servera?'
      : count >= 2 && count <= 4
      ? 'Vymazať $count súbory zo servera?'
      : 'Vymazať $count súborov zo servera?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Tu chýba $count z $total synchronizovaných súborov. Ak '
      'ste ich nevymazali vy, zrušte akciu a skontrolujte '
      'priečinok knižnice.';
  @override
  String get syncMassDeleteConfirm => 'Vymazať zo servera';
  @override
  String get syncTooltip => 'Synchronizácia';
  @override
  String get syncStageConnecting => 'Pripája sa k serveru…';
  @override
  String get syncStageComparing => 'Porovnáva sa so serverom…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synchronizácia · $done z $total';
  @override
  String get syncStatusWarnings => 'Synchronizovaná s upozorneniami';
  @override
  String syncConflictsHeader(int count) => 'Zmenené tu aj na serveri · $count';
  @override
  String get syncConflictHint => 'Žiadna z verzií nebola zmenená';
  @override
  String get syncResolveAction => 'Vyriešiť';
  @override
  String syncFailuresHeader(int count) => 'Nesynchronizované · $count';
  @override
  String get syncFailuresHint => 'Skúsia sa znova pri ďalšej synchronizácii';
  @override
  String get syncAbortAuth => 'Server odmietol heslo';
  @override
  String get syncAbortMissingPassword => 'Nie je uložené žiadne heslo';
  @override
  String get syncAbortOffline => 'Server je nedostupný';
  @override
  String get syncAbortRemoteMissing => 'Priečinok na serveri už neexistuje';
  @override
  String get syncAbortUnsupported => 'Server už nefunguje ako WebDAV';
  @override
  String get syncAbortFailed => 'Synchronizácia sa nepodarila';
  @override
  String get syncAbortNotConfirmed => 'Synchronizácia zrušená';
  @override
  String get syncAbortNothingTouched =>
      'Žiadny súbor nebol zmenený. Vaše zmeny zostanú tu až do '
      'ďalšej úspešnej synchronizácie.';
  @override
  String syncLastSuccess(String when) =>
      'Posledná úspešná synchronizácia $when';
  @override
  String get syncNoSuccessYet => 'Zatiaľ žiadna úspešná synchronizácia';
  @override
  String get syncUpdatePasswordAction => 'Aktualizovať heslo';
  @override
  String get syncRetryAction => 'Skúsiť znova';
  @override
  String get syncOpenSettingsAction => 'Nastavenia';
  @override
  String get syncCloseAction => 'Zavrieť';
  @override
  String get syncDoneSnack => 'Synchronizovaná';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synchronizovaná · 1 súbor vymazaný inde je v koši'
      : count >= 2 && count <= 4
      ? 'Synchronizovaná · $count súbory vymazané inde sú v koši'
      : 'Synchronizovaná · $count súborov vymazaných inde je v koši';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synchronizovaná · 1 konflikt na vyriešenie'
      : count >= 2 && count <= 4
      ? 'Synchronizovaná · $count konflikty na vyriešenie'
      : 'Synchronizovaná · $count konfliktov na vyriešenie';
  @override
  String get syncShowAction => 'Zobraziť';
  @override
  String get syncConflictTitle => 'Vyriešiť konflikt';
  @override
  String get syncConflictBinary =>
      'Nie je to textový súbor: vyberte, ktorú kópiu ponechať.';
  @override
  String get syncConflictKeepNote =>
      'Kópia, ktorú neponecháte, zostane v histórii poznámky.';
  @override
  String get syncKeepLocal => 'Ponechať verziu zariadenia';
  @override
  String get syncKeepRemote => 'Ponechať verziu servera';
  @override
  String get syncConflictLoadFailed => 'Obe verzie sa nepodarilo načítať';
  @override
  String get syncResolveFailed => 'Konflikt sa nepodarilo vyriešiť';
  @override
  String get syncResolved => 'Konflikt vyriešený';
  @override
  String get syncConflictMoved =>
      'Jedna z verzií sa medzitým zmenila: konflikt bol načítaný znova, '
      'vyberte znova.';
  @override
  String get syncSectionWhen => 'Kedy synchronizovať';
  @override
  String get syncAutoTitle => 'Automaticky';
  @override
  String get syncAutoSubtitle => 'Po úpravách, pri otvorení a v intervaloch';
  @override
  String get syncIntervalTitle => 'Kontrolovať server každých';
  @override
  String get syncIntervalSubtitle => 'Len keď je aplikácia otvorená';
  @override
  String get syncIntervalDialogBody =>
      'Aby ste videli zmeny urobené na iných zariadeniach, kým je aplikácia '
      'otvorená. Pri „Nikdy” len po úpravách a pri otvorení.';
  @override
  String syncIntervalMinutes(int count) => switch (count) {
    1 => '1 minúta',
    >= 2 && <= 4 => '$count minúty',
    _ => '$count minút',
  };
  @override
  String get syncIntervalNever => 'Nikdy';
  @override
  String get syncWifiOnlyTitle => 'Len cez Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Na mobilných dátach synchronizovať len ručne';
  @override
  String syncPendingChanges(int count) => switch (count) {
    1 => '1 zmena čaká',
    >= 2 && <= 4 => '$count zmeny čakajú',
    _ => '$count zmien čaká',
  };
  @override
  String syncRetryIn(String wait) => 'ďalší pokus o $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Čaká sa na Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Čaká sa na pripojenie';
  @override
  String get syncMobileDataHint =>
      '„Synchronizovať teraz” aj tak použije mobilné dáta.';
  @override
  String get syncQueueKeptHint =>
      'Zmeny tu zostanú, aj keď aplikáciu zavriete, a odídu samy, keď server '
      'odpovie.';
  @override
  String get syncAutoPaused => 'Automatická synchronizácia je pozastavená';
  @override
  String get syncPausedAuthHint =>
      'Pokračuje, keď aktualizujete heslo alebo synchronizujete ručne.';
  @override
  String get syncPausedServerHint =>
      'Pokračuje, keď opravíte adresu alebo synchronizujete ručne.';
  @override
  String get syncPausedConfirmHint =>
      '„Synchronizovať teraz” ukáže, čo by sa odstránilo, a najprv sa spýta.';
  @override
  String get syncNeedsConfirmation => 'Čaká sa na vaše potvrdenie';
  @override
  String get syncMergeIntro =>
      'Úpravy, ktoré sa neprekrývajú, sú už zlúčené; tam, kde sa prekrývajú, '
      'vyberte, čo ponechať.';
  @override
  String get syncMergeClean => 'Obe verzie sa zlúčia samy: nič sa neprekrýva.';
  @override
  String get syncMergeNoBase =>
      'Chýba spoločná verzia na zlúčenie: všade, kde sa obe kópie líšia, '
      'vyberáte vy.';
  @override
  String syncMergeOverlap(int index, int total) => 'Prekryv $index z $total';
  @override
  String get syncMergeFromLocal => 'Z tohto zariadenia';
  @override
  String get syncMergeFromRemote => 'Zo servera';
  @override
  String get syncMergeRemovedLines => 'Odstránené riadky';
  @override
  String get syncMergeAbsentLines => 'Nie je v tejto kópii';
  @override
  String get syncMergeKeepLocal => 'Moje';
  @override
  String get syncMergeKeepRemote => 'Servera';
  @override
  String get syncMergeKeepBoth => 'Oboje';
  @override
  String get syncMergeSave => 'Uložiť zlúčenie';
  @override
  String get syncMergeKeepWhole => 'Alebo ponechať jednu celú kópiu';
}
