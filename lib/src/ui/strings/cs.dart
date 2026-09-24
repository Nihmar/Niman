// The Czech strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class CzechStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'leden',
    'únor',
    'březen',
    'duben',
    'květen',
    'červen',
    'červenec',
    'srpen',
    'září',
    'říjen',
    'listopad',
    'prosinec',
  ];
  @override
  List<String> get monthNamesShort => const [
    'led',
    'úno',
    'bře',
    'dub',
    'kvě',
    'čvn',
    'čvc',
    'srp',
    'zář',
    'říj',
    'lis',
    'pro',
  ];
  @override
  List<String> get weekdayNames => const [
    'pondělí',
    'úterý',
    'středa',
    'čtvrtek',
    'pátek',
    'sobota',
    'neděle',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'po',
    'út',
    'st',
    'čt',
    'pá',
    'so',
    'ne',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Koš';
  @override
  String get trashSubtitle =>
      'Smazané položky se přesouvají do .trash/ (vypnuto = trvalé smazání)';
  @override
  String get trashAutoEmptyTitle => 'Automatické vyprázdnění koše';
  @override
  String get trashAutoEmptySubtitle =>
      'Starší smazané položky zmizí natrvalo při otevření knihovny';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nikdy'
      : switch (days) {
          1 => '1 den',
          >= 2 && <= 4 => '$days dny',
          _ => '$days dní',
        };
  @override
  String get debugLogsTitle => 'Ladící protokoly';
  @override
  String get debugLogsSubtitle =>
      'Zapisuje události aplikace do paměťového bufferu';
  @override
  String get lineNumbersTitle => 'Čísla řádků';
  @override
  String get lineNumbersSubtitle =>
      'Zobrazí sloupec čísel řádků v editoru poznámek';
  @override
  String get readableLineLengthTitle => 'Čitelná délka řádku';
  @override
  String get readableLineLengthSubtitle =>
      'Držet text poznámky ve vystředěném sloupci místo přes celou šířku okna';
  @override
  String get noteColumnWidthTitle => 'Šířka sloupce';
  @override
  String get noteColumnWidthSubtitle =>
      'Jak široký je sloupec poznámky, v pixelech';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Klávesnice při otevření';
  @override
  String get keyboardOnOpenSubtitle =>
      'Zobrazí klávesnici po otevření poznámky (vypnuto = při prvním '
      'dotyku)';
  @override
  String get editorKindSource => 'Zdrojový Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Zdroj Markdown, tak jak je napsán';
  @override
  String get editorKindWysiwygSubtitle => 'Formátovaný text, upravovaný přímo';
  @override
  String get settingsFolderToCreate => 'k vytvoření';
  @override
  String get settingsSearchHint => 'Hledat v nastavení';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 nalezené nastavení' : '$count nalezená nastavení';
  @override
  String get settingsToggleOn => 'Zapnuto';
  @override
  String get settingsToggleOff => 'Vypnuto';
  @override
  String get switchToWysiwygTooltip => 'Přepnout na editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Přepnout na zdrojový Markdown';
  @override
  String get switchToSourceLabel => 'Zdroj';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Vzhled';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Knihovna';
  @override
  String get settingsSectionReminders => 'Připomínky';
  @override
  String get settingsSectionShortcuts => 'Klávesové zkratky';
  @override
  String get keyboardShortcutsTitle => 'Klávesové zkratky';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Knihovna $name';
  @override
  String get settingsGroupLibraryHint => 'platí jen pro tuto knihovnu';
  @override
  String get settingsGroupMaintenance => 'Údržba';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Složky a cesty';
  @override
  String get settingsAreaTrashHistory => 'Koš a historie';
  @override
  String get settingsAreaDiagnostics => 'Diagnostika a info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Je potřeba připojená fyzická klávesnice';
  @override
  String get settingsSectionUpdates => 'Aktualizace';
  @override
  String get autoUpdateTitle => 'Automatické aktualizace';
  @override
  String get autoUpdateSubtitle =>
      'Kontroluje GitHub Releases při spuštění a každých 6 hodin';
  @override
  String get checkForUpdatesTitle => 'Zkontrolovat aktualizace';
  @override
  String updateAvailableMessage(Object version) =>
      'Je k dispozici Niman $version';
  @override
  String get updateUpToDate => 'Niman je aktuální';
  @override
  String get updateCheckFailed => 'Kontrola aktualizací selhala';
  @override
  String updateSavedTo(Object path) => 'Aktualizace uložena do $path';
  @override
  String get updateInstallerStarted => 'Instalátor spuštěn';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Kontrola pravopisu';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podtrhuje překlepy, zatímco píšete.';
  @override
  String get spellCheckDictionaryTitle => 'Slovník';
  @override
  String get spellCheckDictionarySystem => 'Systémový výchozí';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Výběr slovníků';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Vyberte všechny jazyky, ve kterých je knihovna napsaná. Slovo '
      'projde, když je zná některý z vybraných slovníků; bez výběru '
      'rozhoduje jazyk systému.';
  @override
  String get spellCheckNoDictionaries =>
      'Na tomto systému nebyly nalezeny žádné slovníky.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Kontrola pravopisu';
  @override
  String get spellCheckTitle => 'Pravopis';
  @override
  String get spellCheckEmpty => 'Žádné překlepy.';
  @override
  String get spellCheckUnavailable =>
      'hunspell není nainstalován na tomto systému.';
  @override
  String get spellCheckNoSuggestions => 'Žádné návrhy';
  @override
  String spellCheckCount(int count) => '$count ke kontrole';
  @override
  String spellCheckLine(int line) => 'řádek $line';
  @override
  String get addWordToDictionary => 'Přidat do slovníku';

  @override
  String indentWidthValue(int spaces) => '$spaces mezerníky';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Jasnost';
  @override
  String get themeBrightnessSubtitle => 'Světlý, tmavý nebo nastavení zařízení';
  @override
  String get themeBrightnessSystem => 'Systém';
  @override
  String get themeBrightnessDay => 'Světlý';
  @override
  String get themeBrightnessNight => 'Tmavý';
  @override
  String get themePaletteTitle => 'Barevná paleta';
  @override
  String get themePaletteSubtitle => 'Barvy rozhraní a poznámek';
  @override
  String get themePaletteSystem => 'Systém';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Velikost textu rozhraní';
  @override
  String get uiTextScaleSubtitle =>
      'Strom, záložky a dialogy; nad nastavením systému';
  @override
  String get noteTextScaleTitle => 'Velikost textu poznámek';
  @override
  String get noteTextScaleSubtitle => 'Editor a náhled, vždy v souladu';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formát odkazu';
  @override
  String get linkTypeSubtitle => 'Co tlačítko odkazu vloží do editoru';
  @override
  String get linkTypeWikilink => 'Wiki odkaz';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Vytvořovat chybující poznámky v';
  @override
  String get missingNoteLocationRoot => 'Kořen knihovny';
  @override
  String get missingNoteLocationCurrentFolder => 'Aktuální složka';
  @override
  String get indentWidthTitle => 'Šířka odsazení';
  @override
  String get indentWidthSubtitle =>
      'Počet mezer přidáných na každou úroveň odsazení v editoru';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Jazyk';
  @override
  String get languageSubtitle => 'Jazyk samotného textu aplikace';
  @override
  String get languageSystem => 'Systém';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Přidat položku';
  @override
  String get listAddTooltip => 'Přidat položku';
  @override
  String get listEmpty => 'Zatím žádné položky';
  @override
  String get listDragHandleLabel => 'Změnit pořadí položky';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Zatím žádné nahrávky';
  @override
  String get audioRecord => 'Nahrát';
  @override
  String get audioStop => 'Zastavit';
  @override
  String get audioPlay => 'Přehrát';
  @override
  String get audioDelete => 'Smazat nahrávku';
  @override
  String get audioImport => 'Importovat zvukový soubor';
  @override
  String get audioRecording => 'Nahrávání…';
  @override
  String get audioPermissionDenied =>
      'Oprávnění k mikrofonu bylo zamítnuto — nahrávání ho vyžaduje.';
  @override
  String get newAudioNoteTitle => 'Nová hlasová poznámka';
  @override
  String get newAudioNoteDefault => 'Moje nahrávka';
  @override
  String get showAudioTooltip => 'Zobrazit nahrávky';
  @override
  String get audioMessageHint => 'Napište poznámku…';
  @override
  String get audioSend => 'Odeslat';
  @override
  String get audioRename => 'Přejmenovat nahrávku';
  @override
  String get audioDescriptionHint => 'Popište tuto nahrávku…';
  @override
  String get audioEditDescription => 'Upravit popis';
  @override
  String get audioDeleteNote => 'Smazat poznámku';
  @override
  String get audioEditNote => 'Upravit poznámku';
  @override
  String get audioPause => 'Pozastavit';
  @override
  String get audioEditTitle => 'Upravit název';
  @override
  String get audioTitleHint => 'Název této nahrávky…';
  @override
  String audioUntitled(int n) => 'Nahrávka $n';
  @override
  String get audioMoreActions => 'Další akce';
  @override
  String get audioDiscardRecording => 'Zahodit nahrávku';
  @override
  String get audioPauseRecording => 'Pozastavit nahrávání';
  @override
  String get audioResumeRecording => 'Pokračovat v nahrávání';
  @override
  String get audioRecordingPaused => 'Pozastaveno';
  @override
  String get audioSavingRecording => 'Ukládání…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Rychlá poznámka';
  @override
  String get trayOpen => 'Otevřít Niman';
  @override
  String get trayQuit => 'Ukončit';
  @override
  String get closeToTrayTitle => 'Zavřít do oznamovací oblasti';
  @override
  String get closeToTraySubtitle =>
      '× okna skryje Niman a nechá jej běžet, takže připomínky stále chodí. '
      'Ukončení z nabídky ikony.';
  @override
  String get shortcutNewTodo => 'Nový úkol';
  @override
  String get shortcutNewNote => 'Nová poznámka';
  @override
  String get shortcutNewList => 'Nový seznam';
  @override
  String get shortcutNewAudio => 'Nová hlasová poznámka';
  @override
  String get shortcutToggleSidebar => 'Zobrazit nebo skrýt filtr';
  @override
  String get shortcutCloseTab => 'Zavřít aktuální poznámku';
  @override
  String get shortcutNextTab => 'Další otevřená poznámka';
  @override
  String get shortcutPreviousTab => 'Předchozí otevřená poznámka';
  @override
  String get shortcutEditorSection => 'V editoru';
  @override
  String get shortcutFormatSection => 'Formátování';
  @override
  String get shortcutFind => 'Hledat';
  @override
  String get shortcutReplace => 'Najít a nahradit';
  @override
  String get shortcutSavingNote =>
      'Změny se ukládají automaticky, takže neexistuje zkratka pro '
      'uložení.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Načítání…';
  @override
  String get noteStatusSaving => 'Ukládání…';
  @override
  String get noteStatusUnsaved => 'Neuloženo';
  @override
  String get noteStatusSaved => 'Uloženo';
  @override
  String get noteStatusError => 'Chyba';
  @override
  String get noteNotText =>
      'Tento soubor není textová poznámka, proto ho Niman nemůže zobrazit zde.';
  @override
  String get noteLoadFailed => 'Tuto poznámku se nepodařilo otevřít.';
  @override
  String wordCount(int count) => switch (count) {
    1 => '1 slovo',
    >= 2 && <= 4 => '$count slova',
    _ => '$count slov',
  };
  @override
  String get outlineTooltip => 'Struktura';
  @override
  String get outlineNoHeadings => 'Žádné nadpisy';
  @override
  String get outlineNoTitle => '(bez názvu)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Tučné';
  @override
  String get toolbarItalic => 'Kurzíva';
  @override
  String get toolbarStrikethrough => 'Překreslené';
  @override
  String get toolbarSuperscript => 'Horní index';
  @override
  String get toolbarUnderline => 'Podtržené';
  @override
  String get toolbarLink => 'Odkaz';
  @override
  String get toolbarCode => 'Kódový blok';
  @override
  String get toolbarImage => 'Vložit obrázek';
  @override
  String get toolbarTable => 'Tabulka';
  @override
  String get tableRow => 'Řádek';
  @override
  String get tableColumn => 'Sloupec';
  @override
  String get tableAddRowAbove => 'Vložit řádek nad';
  @override
  String get tableAddRowBelow => 'Vložit řádek pod';
  @override
  String get tableMoveRowUp => 'Posunout řádek nahoru';
  @override
  String get tableMoveRowDown => 'Posunout řádek dolů';
  @override
  String get tableDuplicateRow => 'Duplikovat řádek';
  @override
  String get tableDeleteRow => 'Smazat řádek';
  @override
  String get tableAddColumnLeft => 'Vložit sloupec vlevo';
  @override
  String get tableAddColumnRight => 'Vložit sloupec vpravo';
  @override
  String get tableMoveColumnLeft => 'Posunout sloupec doleva';
  @override
  String get tableMoveColumnRight => 'Posunout sloupec doprava';
  @override
  String get tableAlignLeft => 'Zarovnat vlevo';
  @override
  String get tableAlignCenter => 'Na střed';
  @override
  String get tableAlignRight => 'Zarovnat vpravo';
  @override
  String get tableDuplicateColumn => 'Duplikovat sloupec';
  @override
  String get tableDeleteColumn => 'Smazat sloupec';
  @override
  String get tableSortAscending => 'Seřadit podle sloupce (A → Z)';
  @override
  String get tableSortDescending => 'Seřadit podle sloupce (Z → A)';
  @override
  String get tableAddRow => 'Přidat řádek';
  @override
  String get tableAddColumn => 'Přidat sloupec';
  @override
  String get cheatsheetTitle => 'Tahák k Markdownu';
  @override
  String get cheatsheetCopy => 'Kopírovat';
  @override
  String get cheatsheetCopied => 'Zkopírováno';
  @override
  String get cheatsheetInsert => 'Vložit do poznámky';
  @override
  String get cheatsheetWritten => 'Zápis';
  @override
  String get cheatsheetShown => 'Zobrazení';
  @override
  String get cheatHeadings => 'Nadpisy';
  @override
  String get cheatEmphasis => 'Tučné, kurzíva, přeškrtnuté';
  @override
  String get cheatHtmlFormats => 'Podtržené, horní index, dolní index';
  @override
  String get cheatLists => 'Seznamy';
  @override
  String get cheatChecklists => 'Kontrolní seznamy';
  @override
  String get cheatQuotes => 'Citace';
  @override
  String get cheatLinks => 'Odkazy';
  @override
  String get cheatWikilinks => 'Odkazy na poznámky';
  @override
  String get cheatEmbeds => 'Obrázky a vložení';
  @override
  String get cheatTags => 'Štítky';
  @override
  String get cheatInlineCode => 'Kód ve větě';
  @override
  String get cheatCodeBlocks => 'Bloky kódu';
  @override
  String get cheatMath => 'Matematika';
  @override
  String get cheatTables => 'Tabulky';
  @override
  String get cheatFootnotes => 'Poznámky pod čarou';
  @override
  String get cheatRule => 'Vodorovná čára';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Zástupné symboly šablon';
  @override
  String get menuAddLink => 'Přidat odkaz';
  @override
  String get menuAddExternalLink => 'Přidat externí odkaz';
  @override
  String get menuFormat => 'Formát';
  @override
  String get menuParagraph => 'Odstavec';
  @override
  String get menuInsert => 'Vložit';
  @override
  String get menuBody => 'Běžný text';
  @override
  String get formatSubscript => 'Dolní index';
  @override
  String get formatInlineCode => 'Kód';
  @override
  String get insertFootnote => 'Poznámka pod čarou';
  @override
  String get insertRule => 'Vodorovná čára';
  @override
  String get insertCodeBlock => 'Blok kódu';
  @override
  String get insertMathBlock => 'Matematický blok';
  @override
  String get menuHeadingWord => 'Nadpis';
  @override
  String get toolbarHeading => 'Nadpis';
  @override
  String get toolbarList => 'Seznam';
  @override
  String get toolbarOrderedList => 'Očíslovaný seznam';
  @override
  String get toolbarChecklist => 'Kontrolní seznam';
  @override
  String get toolbarQuote => 'Citace';
  @override
  String get toolbarIndent => 'Odsadit';
  @override
  String get toolbarOutdent => 'Zmenšit odsazení';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Nástroje';
  @override
  String get editorToolsTitle => 'Nástroje editoru';
  @override
  String get toolCountListTitle => 'Spočítat seznam';
  @override
  String get toolCountListSubtitle =>
      'Sečte, co řádky vyjmenovávají, jako zaškrtávací seznam';
  @override
  String get toolCountListNeedsList => 'Tato poznámka nemá seznam ke spočítání';
  @override
  String get tallySourceLabel => 'Seznam';
  @override
  String get tallyCutLabel => 'Číst každý řádek jako';
  @override
  String get tallyCutDash => 'Jméno - hodnoty';
  @override
  String get tallyCutColon => 'Jméno: hodnoty';
  @override
  String get tallyCutCommas => 'Hodnoty oddělené čárkou';
  @override
  String get tallyCutWhole => 'Celý řádek jako jedna hodnota';
  @override
  String get tallySortLabel => 'Pořadí';
  @override
  String get tallySortCount => 'Nejčastější první';
  @override
  String get tallySortAlphabetical => 'Abecedně';
  @override
  String get tallySortFirstSeen => 'Jak jsou uvedeny';
  @override
  String get tallyInsert => 'Vložit';
  @override
  String get tallyUpdate => 'Aktualizovat';
  @override
  String get tallyNothingToCount => 'Tady není co počítat';
  @override
  String get headingDialogTitle => 'Úroveň nadpisu';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Panel nástrojů editoru';
  @override
  String get toolbarSettingsHint =>
      'Přetáhněte pro změnu pořadí; očko zobrazí nebo skrývá tlačítko.';
  @override
  String get toolbarShowButton => 'Zobrazit';
  @override
  String get toolbarHideButton => 'Skrýt';
  @override
  String get toolbarResetOrder => 'Obnovit výchozí';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Zobrazit náhled';
  @override
  String get showEditorTooltip => 'Zobrazit editor';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(surová HTML tabulka)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Hledat v poznámkách';
  @override
  String get searchModeWords => 'Slova';
  @override
  String get searchModeContains => 'Obsahuje';
  @override
  String get searchEmptyHint =>
      'Napište pro hledání v knihovně, nebo klíč = hodnota pro filtrování '
      'podle frontmatteru';
  @override
  String get searchTooShortHint => 'Napište alespoň 2 znaky';
  @override
  String get searchNoMatches => 'Žádná shoda';
  @override
  String get searchLoadMore => 'Zobrazit další';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Nahradit…';
  @override
  String get replaceInNoteAction => 'Nahradit v této poznámce…';
  @override
  String get replaceInThisNote => 'Nahradit v této poznámce';
  @override
  String get replaceWithLabel => 'Nahradit na';
  @override
  String get replaceCaseSensitive => 'Rozlišovat velká a malá písmena';
  @override
  String get replaceWholeWordsHint =>
      'nahrazují se pouze přesné shody celých slov';
  @override
  String get replaceConfirm => 'Nahradit';
  @override
  String get replaceCancel => 'Zavřít';
  @override
  String get replaceUnavailable => 'Nahrazování není nyní k dispozici';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Hledat v poznámce';
  @override
  String get editorFindHint => 'Hledat';
  @override
  String get editorReplaceHint => 'Nahradit';
  @override
  String get editorFindCaseTooltip => 'Rozlišovat velká a malá písmena';
  @override
  String get editorFindPreviousTooltip => 'Předchozí shoda';
  @override
  String get editorFindNextTooltip => 'Následující shoda';
  @override
  String get editorFindCloseTooltip => 'Zavřít hledání';
  @override
  String get editorFindReplaceModeTooltip => 'Režim nahrazování';
  @override
  String get editorReplaceOneTooltip => 'Nahradit tuto shodu';
  @override
  String get editorReplaceAllTooltip => 'Nahradit všechny shody';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Štítky';
  @override
  String get tagsTitle => 'Štítky';
  @override
  String get tagsEmpty =>
      'Zatím žádné štítky — přidejte #štítek nebo štítky do frontmatteru';
  @override
  String get tagsBackTooltip => 'Zpět na hledání';
  @override
  String get tagsNotesEmpty => 'Žádné poznámky s tímto štítkem';
  @override
  String tagsNotesCapped(int limit) =>
      'Zobrazují se pouze první $limit — vyhledejte štítek pro omezení';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Odkaz nebyl nalezen';
  @override
  String get headingNotFoundTitle => 'Nadpis nebyl nalezen';
  @override
  String get ambiguousLinkTitle => 'Více poznámek odpovídá';
  @override
  String get openLinkFailed => 'Odkaz se nepodařilo otevřít';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Poznámka neexistuje';
  @override
  String missingNoteDialogBody(String path) => 'Vytvořit „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Složka „$folder“ neexistuje';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Otevřené';
  @override
  String get todoDone => 'Hotové';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Všechna data';
  @override
  String get todoFilter => 'Filtrovat';
  @override
  String get todoNoTokens => 'Žádné tokeny v tomto seznamu';
  @override
  String get todoCountOpen => 'otevřené';
  @override
  String get todoCountDone => 'hotové';
  @override
  String get todoEmptyOpen => 'Zatím žádné otevřené úkoly';
  @override
  String get todoEmptyDone => 'Zatím nic hotového';
  @override
  String get todoEmptyFiltered => 'Žádný úkol neodpovídá';
  @override
  String get todoTitle => 'K udělání';
  @override
  String get todoAddTooltip => 'Přidat úkol';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Formát todo.txt';
  @override
  String get todoHelpTooltip => 'Informace o formátu';
  @override
  String get todoHelpIntro =>
      'Vaše úkoly jsou obyčejný textový soubor, jeden úkol na řádek. '
      'Niman píše syntaxi za vás, ale nic neskrývá: soubor můžete '
      'upravit v libovolném editoru a Niman ho znovu načte.';
  @override
  String get todoHelpFilesTitle => 'Dva soubory';
  @override
  String get todoHelpFilesBody =>
      'Otevřené úkoly žijí v todo.txt v kořeni knihovny. Dokončíte-li '
      'jeden, řádek se přesune do done.txt, takže todo.txt zůstává '
      'krátké. Dokončený řádek, který se znovu dostane do todo.txt, '
      'Niman při dalším načtení souborů archivuje.';
  @override
  String get todoHelpLineTitle => 'Anatomie řádku';
  @override
  String get todoHelpLineBody =>
      'Vše před popisem je volitelné a musí být v tomto pořadí:';
  @override
  String get todoHelpDoneBody =>
      'Označí úkol jako hotový. Niman ho přidá, když zaškrtnete políčko.';
  @override
  String get todoHelpPriority => '(A) až (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priorita. A je nejvyšší. Zobrazuje se jako odznak v seznamu.';
  @override
  String get todoHelpDatesBody =>
      'Datum dokončení, pak datum vytvoření. Při jediném datu je to datum '
      'vytvoření, pokud řádek nezačíná na x.';
  @override
  String get todoHelpTokensTitle => 'Projekty, kontexty a štítky';
  @override
  String get todoHelpTokensBody =>
      'V celém popisu se slovo s některým z těchto předpon stává '
      'filtrovatelným štítkem. Nic není předem definováno: token '
      'existuje, když ho napíšete.';
  @override
  String get todoHelpProjectBody =>
      'Čemu úkol patří, např. +kuchyně nebo +práce.';
  @override
  String get todoHelpContextBody =>
      'Kde nebo jak ho děláte, např. @domov nebo @schůzky.';
  @override
  String get todoHelpHashtagBody =>
      'Libovolný štítek pro vše, co nepokryjí ostatní dva.';
  @override
  String get todoHelpTagsTitle => 'Data a připomínky';
  @override
  String get todoHelpTagsBody =>
      'To jsou štítky klíč:hodnota. Niman je píše z dialogu úkolů a čte '
      'je, kde se v řádku objeví.';
  @override
  String get todoHelpDueBody => 'Termín. Řídí barvu odznaku a filtry dat.';
  @override
  String get todoHelpRemBody =>
      'Kdy má být odesláno oznámení, ve vašem lokálním čase. Spustí se, '
      'když je obrazovka vypnutá a aplikace zavřená.';
  @override
  String get todoHelpRemDesktop =>
      'Na počítači musí Niman běžet, když přijde čas: připomínka se '
      'zobrazí, když je aplikace otevřená, a nic se nespustí, když je '
      'zavřená.';
  @override
  String get todoHelpOtherBody =>
      'Uloženo přesně tak, jak je napsáno, aby štítky z jiných aplikací '
      'todo.txt přežily cestu. Niman s nimi nepracuje, rec: included: '
      'opakující se úkol se zatím neopakuje.';
  @override
  String get todoHelpEditTitle => 'Úprava mimo Niman';
  @override
  String get todoHelpEditBody =>
      'Úkol, na který nesáhnete, se zapíše znovu byte po bytu, včetně '
      'zvláštních mezer. Upravíte-li řádek, Niman přepíše pouze tento '
      'řádek ve svém kanonickém formátu a zbytek souboru ponechá '
      'nedotčen.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Přidat úkol';
  @override
  String get todoEditTitle => 'Upravit úkol';
  @override
  String get todoDescriptionHint => 'Popis';
  @override
  String get todoCancel => 'Zrušit';
  @override
  String get todoSave => 'Uložit';
  @override
  String get todoEditAction => 'Upravit';
  @override
  String get todoDeleteAction => 'Smazat';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Po termínu';
  @override
  String get todoDueToday => 'Dnes';
  @override
  String get todoDueNext7 => 'Příštích 7 dní';
  @override
  String get todoDueNoDate => 'Bez data';
  @override
  String get todoRowDue => 'Termín';
  @override
  String get todoRowDueToday => 'Termín dnes';
  @override
  String get todoSortTooltip => 'Seřadit';
  @override
  String get todoSortDue => 'Datum termínu';
  @override
  String get todoSortPriority => 'Priorita';
  @override
  String get todoSortCreation => 'Datum vytvoření';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez priority';
  @override
  String get todoNoPriorityShort => 'Žádná';
  @override
  String get todoMorePriorities => 'Více…';
  @override
  String get todoPriorityTitle => 'Priorita';
  @override
  String get todoNoDueDate => 'Bez data termínu';
  @override
  String get todoNoReminder => 'Bez připomínky';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontext';
  @override
  String get todoAddHashtag => '# Štítek';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Připomínky úkolů';
  @override
  String get todoReminderChannelDescription =>
      'Naplánovaná oznámení pro úkoly s časem připomínky.';
  @override
  String get todoReminderBody => 'Připomínka úkolu';
  @override
  String get todoReminderFallbackTitle => 'Připomínka úkolu';
  @override
  String get todoReminderBlocked =>
      'Oznámení jsou vypnutá, takže se připomínky nezobrazí.';
  @override
  String get todoReminderBattery =>
      'Optimalizace baterie je u Nimanu zapnutá. Systém může vypnout '
      'aplikaci a ztratit čekající připomínky.';
  @override
  String get todoReminderInexact =>
      'Toto zařízení nepodporuje přesné alarmy, takže připomínka může '
      'přijít o několik minut později, když je obrazovka vypnutá.';
  @override
  String get reminderShowTokensTitle => 'Štítky v oznámeních o připomínkách';
  @override
  String get reminderShowTokensSubtitle =>
      'Ponechte +projekt, @kontext a #štítek v textu oznámení. Vypnuté '
      'zobrazí pouze úkol, který jste napsali.';
  @override
  String get todoReminderFixAction => 'Otevřít nastavení';
  @override
  String get todoReminderDismissAction => 'Zavřít';
  @override
  String get todoReminderDue => 'Termín';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Zrušit';
  @override
  String get actionCreate => 'Vytvořit';
  @override
  String get actionNew => 'Nová';
  @override
  String get actionSave => 'Uložit';
  @override
  String get actionClear => 'Vymazat';
  @override
  String get actionChoose => 'Vybrat';
  @override
  String get actionDelete => 'Smazat';
  @override
  String get actionRename => 'Přejmenovat';
  @override
  String get actionMove => 'Přesunout';
  @override
  String get saveAndClose => 'Uložit a zavřít';
  @override
  String get closeUnsavedTitle => 'Neuložené změny';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}“ má neuložené změny. '
          'Uložit je před zavřením?';
    }
    return '${names.length} poznámek mají neuložené změny. '
        'Uložit je před zavřením?';
  }

  @override
  String get closeSaveFailed => 'Nepodařilo se uložit; zůstává otevřená.';
  @override
  String get actionRestore => 'Obnovit';
  @override
  String get actionEmpty => 'Vyprázdnit';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Skrýt boční panel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Zobrazit boční panel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimalizovat';
  @override
  String get windowMaximizeTooltip => 'Maximalizovat';
  @override
  String get windowRestoreTooltip => 'Obnovit';
  @override
  String get windowCloseTooltip => 'Zavřít';
  @override
  String get tabFiles => 'Soubory';
  @override
  String get tabSearch => 'Hledat';
  @override
  String get tabSettings => 'Nastavení';
  @override
  String get quickNoteTitle => 'Rychlá poznámka';
  @override
  String get treeEmpty => 'Zatím žádné poznámky';
  @override
  String get selectANote => 'Vybrat poznámku';
  @override
  String get showListTooltip => 'Zobrazit seznam';
  @override
  String get editRawTooltip => 'Upravit surově';
  @override
  String get sortAscTooltip => 'Seřadit A-Z';
  @override
  String get sortDescTooltip => 'Seřadit Z-A';
  @override
  String get newNoteTitle => 'Nová poznámka';
  @override
  String get newItemTooltip => 'Nový';
  @override
  String get closeMenuTooltip => 'Zavřít';
  @override
  String get newFolderTitle => 'Nová složka';
  @override
  String get newNoteSameFolder => 'Nová poznámka ve stejné složce';
  @override
  String get newFromTemplateSameFolder => 'Nová ze šablony ve stejné složce';
  @override
  String trashOriginalPath(String path) => 'bylo v $path';
  @override
  String get trashOriginalRoot => 'bylo v ko\u0159enu knihovny';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 polo\u017eka' : '$count polo\u017eek';
  @override
  String get newNoteHere => 'Nová poznámka zde';
  @override
  String get newFolderHere => 'Nová složka zde';
  @override
  String get newListNoteTitle => 'Nová poznámka se seznamem';
  @override
  String get newListNoteDefault => 'Můj seznam';
  @override
  String get setAsQuickNote => 'Nastavit jako rychlou poznámku';
  @override
  String get currentQuickNote => 'Aktuální rychlá poznámka';
  @override
  String get pinnedSection => 'Připnuté';
  @override
  String pinnedSectionCount(int count) => 'Připnuté · $count';
  @override
  String get templateFolderTitle => 'Složka šablon';
  @override
  String get newFromTemplateTitle => 'Nová ze šablony';
  @override
  String get newFromTemplateHere => 'Nová ze šablony zde';
  @override
  String get templateFormTitle => 'Vyplnit šablonu';
  @override
  String get templateFormBacklink => 'Odkazováno z';
  @override
  String get templateFormNoNote => 'Bez poznámky';
  @override
  String get templateFormPickNote => 'Vybrat poznámku';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Placeholderové značky šablony';
  @override
  String get templateHelpSubtitle => 'Datum, název a další hodnoty k vyplnění';
  @override
  String get quickNoteSubtitle =>
      'Poznámka, kterou otevírá karta Rychlá poznámka';
  @override
  String get listFolderSubtitle => 'Nové seznamy úkolů';
  @override
  String get templateFolderSubtitle => 'Zdroj pro „Nový ze šablony“';
  @override
  String get attachmentsFolderSubtitle => 'Obrázky a zvuk vložené do poznámky';
  @override
  String get templateHelpIntro =>
      'Šablona je obyčejná poznámka se dírami. Vytvoření poznámky z ní '
      'kopíruje text a vyplní díry.';
  @override
  String get templateHelpUnknown =>
      'Placeholder, který Niman nezná, zůstane přesně tak, jak je '
      'napsáno, takže překlep se objeví v poznámce, nikoli v tichém '
      'rozbití řádku.';
  @override
  String get templateHelpValuesTitle => 'Hodnoty';
  @override
  String get templateHelpTitleBody =>
      'Název, pod kterým má být poznámka vytvořena.';
  @override
  String get templateHelpDateBody =>
      'Dnes a aktuální čas. Oba přijímají formát: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum a čas společně.';
  @override
  String get templateHelpUuidBody =>
      'Nový identifikátor, jiný pro každé použití.';
  @override
  String get templateHelpCounterBody =>
      'Číslo počítající podle názvu, zachovávané mezi restarty: první '
      'poznámka zapíše 1, další 2. Stejný název v poznámce zapíše stejné '
      'číslo; skombinujte s |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Umístí kurzor sem při vytváření poznámky; značka se nenapíše. '
      'První značka vyhrává, bez filtrů, pouze nové poznámky — a '
      'klávesnice se otevře i při vypnutém autofokusu.';
  @override
  String get templateHelpDatesTitle => 'Zapisování data';
  @override
  String get templateHelpDatesBody =>
      'Tyto představují části data ve formátu. Vše ostatní je doslovné, '
      'stejně jako text v jednoduchých uvozovkách. Názvy měsíců a dní '
      'týdnu odpovídají jazyku aplikace.';
  @override
  String get templateHelpYear => 'rok: 2026, 26';
  @override
  String get templateHelpMonth => 'měsíc: 03, 3, březen, bře';
  @override
  String get templateHelpDay => 'den: 09, 9, pondělí, po';
  @override
  String get templateHelpTime => 'hodiny, minuty, sekundy';
  @override
  String get templateHelpWeek => 'ISO týden a čtvrtletí: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtry';
  @override
  String get templateHelpFiltersBody =>
      'Hodnotu mohou následovat filtry, aplikované zleva doprava.';
  @override
  String get templateHelpCaseBody =>
      'Velká, malá a první písmeno každého slova — slovo, které jste '
      'napsali s velkou počáteční, se nemění.';
  @override
  String get templateHelpSlugBody =>
      'Forma odkazu textu, pro sestavení wiki odkazu.';
  @override
  String get templateHelpPadBody =>
      'Ořízněte konce; doplňte nulami na šířku; použijte alternativu, '
      'když je hodnota prázdná.';
  @override
  String get templateHelpShiftBody =>
      'Posuňte datum o dny, týdny, měsíce nebo roky — konference '
      'příští týden, soubor z minulého měsíce.';
  @override
  String get templateHelpSnapBody =>
      'Připevněte datum na začátek nebo konec týdne, měsíce nebo roku.';
  @override
  String get templateHelpAskTitle => 'Zeptat se vás';
  @override
  String get templateHelpAskBody =>
      'Před vytvořením poznámky se zobrazí formulář, jedno pole na '
      'otázku — a jedno pro zpětný odkaz, když to šablona vyžaduje. '
      'Stejná značka dvakrát je otázka a její odpověď vyplní všechny '
      'výskyty — včetně složky a názvu souboru.';
  @override
  String get templateHelpAskFieldBody =>
      'Pole pro psaní; text po druhé dvojkolce je začátek.';
  @override
  String get templateHelpChoiceBody => 'Výběr ze seznamu, oddělený čárkami.';
  @override
  String get templateHelpWhereTitle => 'Kde poznámka dopadne';
  @override
  String get templateHelpWhereBody =>
      'Tyto nejsou text: jsou to instrukce a žijí v bloku niman: ve '
      'frontmatteru šablony. Blok se vykoná a smaže, takže se nikdy '
      'nezobrazí v poznámce. Jeho hodnota může obsahovat placeholderové '
      'značky.';
  @override
  String get templateHelpFolderBody =>
      'Složka, ve které se poznámka vytvoří, vytvořená, pokud neexistuje. '
      'Bez toho poznámka dopadne, kde jste byli.';
  @override
  String get templateHelpFilenameBody =>
      'Jak se poznámka bude jmenovat. Šablona, která to říká, se na '
      'název neptá.';
  @override
  String get templateHelpAppendBody =>
      'Přidejte k poznámce, pokud již existuje, místo, abyste vytvořili '
      'další. Díky tomu je měsíc schůzek jediný soubor.';
  @override
  String get templateHelpOpenBody =>
      'Co se stane, když poznámka existuje: editor (výchozí), náhled, '
      'nebo nic — poznámka se archivuje a zůstanete, kde jste byli.';
  @override
  String get templateHelpAroundTitle => 'Odkud přišla';
  @override
  String get templateHelpParentBody =>
      'Poznámka, kterou vyberete ve formuláři, nabídnutá na obrazovce; '
      'napište [[{{parent}}]] pro zpětný odkaz.';
  @override
  String get templateHelpFolderValueBody => 'Složka, kde poznámka dopadla.';
  @override
  String get templateHelpClipboardBody =>
      'Co je v schránce a výběr v editoru, když poznámka začala z něj.';
  @override
  String get templateHelpIncludeTitle => 'Znovu použití části';
  @override
  String get templateHelpIncludeBody =>
      'Vložte jinou šablonu, takže deset šablon může sdílet jeden '
      'kontrolní seznam. Hledá se nejdřív ve složce šablon, .md lze '
      'vynechat. Její vlastní otázky jdou do stejného formuláře.';
  @override
  String get templateHelpExampleTitle => 'Vše dohromady';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ neexistuje šablona „$path“';
  @override
  String includeCycle(String path) => '⚠ „$path“ obsahuje sama sebe';
  @override
  String includeTooDeep(String path) => '⚠ „$path“ je příliš hluboce zanořena';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter se nepodařilo přečíst: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter „$template“ se nepodařilo přečíst, takže složka a '
      'název souboru neměly žádný efekt: $reason';
  @override
  String get templatePickerTitle => 'Výběr šablony';
  @override
  String templatePickerEmpty(String folder) =>
      'Zatím žádné šablony. Vložte poznámku do $folder/ a bude šablonou.';

  // Tree actions.
  @override
  String get actionPin => 'Připnout';
  @override
  String get actionUnpin => 'Odepnout';
  @override
  String get pinToWidget => 'Připnout k vidžetu na ploše';
  @override
  String get pinnedForWidget => 'Připnuto: umístěte vidžet Poznámka na plochu';
  @override
  String get pinWidgetUnavailable =>
      'Vidžety na ploše jsou k dispozici v systému Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Zobrazit ve správci souborů';
  @override
  String get openInDefaultApp => 'Otevřít ve výchozí aplikaci';
  @override
  String get newNoteTabTooltip => 'Nová poznámka v nové kartě';
  @override
  String get openNotesTooltip => 'Otevřené poznámky';
  @override
  String get closeTabTooltip => 'Zavřít';
  @override
  String get openInNewTab => 'Otevřít v nové kartě';
  @override
  String get splitRight => 'Rozdělit doprava';
  @override
  String get splitDown => 'Rozdělit dolů';
  @override
  String get moveToOtherPane => 'Přesunout do druhého panelu';
  @override
  String get openBeside => 'Otevřít vedle';
  @override
  String get closeAllNotes => 'Zavřít vše';
  @override
  String get sidePanelTooltip => 'Zobrazit nebo skrýt boční panel';
  @override
  String get historyAllVersions => 'Všechny verze';
  @override
  String get commandPaletteTitle => 'Paleta příkazů';
  @override
  String get goToNoteTitle => 'Přejít na poznámku';
  @override
  String get paletteGroupNote => 'Poznámka';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Zobrazení';
  @override
  String get paletteGroupLibrary => 'Knihovna';
  @override
  String get paletteGroupGoTo => 'Přejít na';
  @override
  String get commandsTitle => 'Příkazy';
  @override
  String get commandsIntro =>
      'Paleta příkazů nabízí jen příkazy, které lze spustit tam, kde právě '
      'jste. Tady jsou všechny a kdy se který zobrazí.';
  @override
  String get commandsKeysNote =>
      'Zde se nic nemění. Klávesy jsou ty nastavené v sekci „Klávesové '
      'zkratky“ a řídí se každou změnou tam.';
  @override
  String get commandsOpenShortcuts =>
      'Změnit klávesy v sekci „Klávesové zkratky“';
  @override
  String get commandsChangeKeyTooltip => 'Změnit v sekci „Klávesové zkratky“';
  @override
  String get commandsSubtitle => 'Co může paleta příkazů spustit, a kdy';
  @override
  String get keyboardShortcutsSubtitle => 'Změňte klávesy každého příkazu';
  @override
  String get commandNeedNone => 'Vždy k dispozici';
  @override
  String get commandNeedOpenNote => 'Vyžaduje otevřenou poznámku';
  @override
  String get commandNeedWideWindow => 'Jen v širokém okně';
  @override
  String get commandNeedDockRoom => 'Vyžaduje okno dost široké pro boční panel';
  @override
  String get commandNeedDesktop => 'Jen na počítači';
  @override
  String get commandNeedNotInZen => 'Ne v režimu Zen';
  @override
  String get commandNeedZenRoom => 'Počítač, s poznámkou otevřenou na kartě';
  @override
  String get commandNeedPreview => 'Se zapnutým náhledem, u textové poznámky';
  @override
  String get commandNeedTwoEditors => 'Se zapnutými oběma editory';
  @override
  String get paletteHint => 'Hledat příkazy a poznámky';
  @override
  String get paletteNoResults => 'Nic neodpovídá';
  @override
  String get paletteCommands => 'Příkazy';
  @override
  String get paletteNotes => 'Poznámky';
  @override
  String get paletteFooter => '↑↓ pohyb · ↵ použít · esc zavřít';
  @override
  String get paletteFooterTouch => 'Klepnutím spustíte · špendlík drží nahoře';
  @override
  String get palettePinned => 'Připnuté';
  @override
  String get palettePin => 'Připnout';
  @override
  String get paletteUnpin => 'Odepnout';
  @override
  String get palettePinFooter => 'alt+P připne';
  @override
  String get spellCheckScanning => 'Kontrola poznámky…';
  @override
  String get spellCheckAgain => 'Zkontrolovat znovu';
  @override
  String spellCheckCapped(int count) =>
      'Zobrazeno je prvních $count: některé opravte a zkontrolujte znovu '
      'kvůli zbytku';
  @override
  String get dropHint =>
      'Přetáhněte soubory Markdown pro otevření, nebo složku pro import';
  @override
  String get dropNothing =>
      'Prostředí nepředalo při tomto upuštění žádné soubory.';
  @override
  String get importFolderAction => 'Importovat';
  @override
  String dropRejected(String names) =>
      'Zde se otevírají jen soubory Markdown a složky: $names';
  @override
  String importFolderTitle(String name) => 'Importovat „$name“?';
  @override
  String importFolderBody(int count) =>
      'Její soubory Markdown ($count) se zkopírují do nové složky knihovny. '
      'Přetažená složka zůstane beze změny.';
  @override
  String importFolderDone(String folder) => 'Importováno do $folder';
  @override
  String importFolderEmpty(String name) =>
      'Ve složce $name nejsou soubory Markdown';
  @override
  String get openFileTitle => 'Otevřít soubor';
  @override
  String get outsideFileNote =>
      'Mimo knihovnu: ukládá se na místě, bez indexu, bez historie, odkazy '
      'se nesledují';
  @override
  String get typewriterOn => 'Zapnout režim psacího stroje';
  @override
  String get typewriterOff => 'Vypnout režim psacího stroje';
  @override
  String get typewriterTitle => 'Režim psacího stroje';
  @override
  String get formatNoteTitle => 'Uklidit Markdown';
  @override
  String get formatNoteDone => 'Poznámka byla uklizena.';
  @override
  String get formatNoteAlreadyTidy => 'Poznámka už byla uklizená.';
  @override
  String get typewriterSubtitle =>
      'Řádek, který píšete, zůstává uprostřed editoru';
  @override
  String get zenMode => 'Režim zen';
  @override
  String get zenModeEnter => 'Přejít do režimu zen';
  @override
  String get zenModeLeave => 'Opustit režim zen';
  @override
  String get keySpace => 'Mezerník';
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
  String get keyArrowUp => 'Nahoru';
  @override
  String get keyArrowDown => 'Dolů';
  @override
  String get keyArrowLeft => 'Vlevo';
  @override
  String get keyArrowRight => 'Vpravo';
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
  String get shortcutNone => 'Bez zkratky';
  @override
  String get shortcutRestoreDefaults => 'Obnovit výchozí';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Vrátit všechny zkratky tak, jak je dodává Niman?';
  @override
  String get shortcutRevert => 'Zpět na výchozí';
  @override
  String get shortcutClear => 'Odebrat zkratku';
  @override
  String get shortcutCapturePrompt =>
      'Stiskněte klávesy. Zaznamenají se i Esc a Tab: odejít lze přes Zrušit.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Přidejte Ctrl, Alt nebo Meta: samotná klávesa slouží k psaní.';
  @override
  String get shortcutMove => 'Přesunout';
  @override
  String get shortcutUseAnyway => 'Přesto použít';
  @override
  String get shortcutUndo => 'Zpět';
  @override
  String get shortcutRedo => 'Znovu';
  @override
  String get shortcutChange => 'Změnit zkratku';
  @override
  String shortcutCaptureTitle(String command) => 'Klávesy pro $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys už patří k $other. Přesunout sem? $other zůstane bez zkratky.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys je také $what v textových polích a editoru. Tam ji převezme váš '
      'příkaz.';
  @override
  String get openFileMissing => 'Soubor této poznámky na disku není';
  @override
  String get openFileFailed => 'Tuto poznámku se nepodařilo otevřít mimo Niman';

  @override
  String get movedToTrash => 'Přesunuto do koše';
  @override
  String get deletedMessage => 'Smazáno';
  @override
  String deleteToTrashConfirm(String name) => '$name se přesune do .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name se trvale smaže';
  @override
  String get chooseDestination => 'Vybrat cíl';
  @override
  String get libraryRoot => 'Kořen knihovny';
  @override
  String moveTitle(String name) => 'Přesunout $name';
  @override
  String headingLevelLabel(int level) => 'Nadpis $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Zatím žádná rychlá poznámka. Vyberte existující poznámku nebo '
      'vytvořte — rychlá poznámka se otevře zde.';
  @override
  String get quickNoteChooseAction => 'Vybrat poznámku…';
  @override
  String get quickNoteCreateAction => 'Vytvořit novou poznámku…';
  @override
  String get quickNoteNewTitle => 'Nová rychlá poznámka';
  @override
  String get quickNotePickerTitle => 'Výběr rychlé poznámky';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nová složka';
  @override
  String get folderPickerEmpty => 'Zatím žádné složky';
  @override
  String get listFolderTitle => 'Složka seznamů';
  @override
  String get attachmentsFolderTitle => 'Složka příloh';

  // Trash (M1).
  @override
  String get trashEmpty => 'Koš je prázdný';
  @override
  String get trashEmptyAction => 'Vyprázdnit koš';
  @override
  String get trashEmptyConfirm =>
      'Toto trvale smaže vše, co je v koši, včetně položek, které Niman '
      'nepoložil.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se trvale smaže (bez obnovení)';
  @override
  String get trashDeletePermanently => 'Smazat trvale';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Otevřít složku s Markdown poznámkami jako knihovnu';
  @override
  String get openLibraryExisting => 'Otevřít existující';
  @override
  String get openLibraryCreate => 'Vytvořit novou';
  @override
  String get openLibraryCreateTitle => 'Vytvořit novou knihovnu';
  @override
  String get openLibraryFolderName => 'Název složky';
  @override
  String get openLibraryChooseFolder => 'Vybrat složku knihovny';
  @override
  String get openLibraryChooseParent =>
      'Vybrat složku, ve které se knihovna vytvoří';
  @override
  String get openLibraryUnsupported =>
      'Tato složka není podporována. Vyberte složku v úložišti '
      'zařízení.';
  @override
  String indexingCount(int done, int total) => '$done z $total poznámek';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Vaše knihovny';
  @override
  String get libraryUnreachable => 'Nedostupná';
  @override
  String get libraryOpenedToday => 'Otevřeno dnes';
  @override
  String get libraryOpenedYesterday => 'Otevřeno včera';
  @override
  String libraryOpenedDaysAgo(int days) => 'Otevřeno před $days dny';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Otevřeno ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Otevřeno právě teď';
  @override
  String get switchLibraryTitle => 'Přepnout knihovnu';
  @override
  String get libraryForget => 'Zapomenout';
  @override
  String libraryForgetTitle(String name) => 'Zapomenout „$name“?';
  @override
  String get libraryForgetExplained =>
      'Zmizí z tohoto seznamu. Složka, poznámky a nastavení knihovny v '
      'ní zůstanou nedotčená a znovuotevřením se vrátí.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Udělit přístup k souborům';
  @override
  String get storageAccessNeeded =>
      'Niman nemůže číst vaše poznámky bez „Přístupu ke všem souborům“. '
      'Udělte ho pro otevření knihovny.';
  @override
  String get storageAccessExplained =>
      'Niman čte vaše poznámky jako obyčejné soubory, takže Android mu '
      'musí udělit přístup ke všem souborům. Nic se neodesílá a čte se '
      'pouze složka knihovny, kterou vyberete.';
  @override
  String folderAccessDenied(Object error) =>
      'Systém neudělil přístup ke složce: $error';
  @override
  String folderPickFailed(Object error) =>
      'Složku se nepodařilo vybrat: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Nastavení';
  @override
  String get libraryPathTitle => 'Cesta knihovny';
  @override
  String get reindexTitle => 'Přeindexovat nyní';
  @override
  String get reindexDone => 'Přeindexování dokončeno';
  @override
  String get closeLibraryTitle => 'Zavřít knihovnu';
  @override
  String get exportLogTitle => 'Exportovat ladící protokol';
  @override
  String get exportLogSubtitle =>
      'Uložit záznamové události do souboru, který vyberete';
  @override
  String get exportLogEmpty => 'Buffer ladícího protokolu je prázdný';
  @override
  String get quickNoteUnset => 'Nenastaveno';
  @override
  String exportLogDone(Object target) =>
      'Ladící protokol exportován do $target';
  @override
  String exportLogFailed(Object error) => 'Export selhal: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nenalezena přesná shoda celého slova pro „$term“';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Nahrazeno $occurrences výskytů „$term“ v $notes poznámkách';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped otevřených poznámek přeskočeno)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nenalezena přesná shoda celého slova pro „$term“'
      '${only == null ? '' : ' v $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'O aplikaci';
  @override
  String get versionTitle => 'Verze';
  @override
  String get changelogTitle => 'Changelog';
  @override
  String get changelogEmpty => 'Záznamy changelogu nejsou k dispozici';
  @override
  String changelogWhatsNew(String version) => 'Novinky ve verzi $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historie';
  @override
  String get noteMenuTooltip => 'Akce poznámky';
  @override
  String get historyCurrentVersion => 'Aktuální verze';
  @override
  String get historyCurrentSubtitle => 'Poznámka v současné podobě';
  @override
  String get historyToday => 'Dnes';
  @override
  String get historyYesterday => 'Včera';
  @override
  String get historyReasonSession => 'před úpravami';
  @override
  String get historyReasonInterval => 'během úprav';
  @override
  String get historyReasonRestore => 'před obnovením';
  @override
  String get historyReasonSync => 'před synchronizací';
  @override
  String get historyReasonReplace => 'před nahrazením';
  @override
  String get historyReasonUnknown => 'nalezená';
  @override
  String get historySyncBase => 'základ synchronizace';
  @override
  String get historyEmpty =>
      'Zatím žádné verze. Niman jednu uchová, když začnete poznámku '
      'upravovat, a pak nejvýš jednu za pár minut, zatímco píšete.';
  @override
  String historyKept(int kept, int limit) => 'Uchováno verzí: $kept z $limit';
  @override
  String get historyBaseKept => 'Základ synchronizace se uchovává i nad limit.';
  @override
  String get historyOff =>
      'Historie je pro tuto knihovnu vypnutá (Nastavení, Knihovna).';
  @override
  String get historyLoadFailed => 'Historii se nepodařilo načíst';
  @override
  String get historyCompareSubtitle => 'Porovnáno s aktuální verzí';
  @override
  String get historyTabChanges => 'Změny';
  @override
  String get historyTabVersion => 'Verze';
  @override
  String get historyNoChanges => 'Stejný text jako aktuální verze.';
  @override
  String get historyRestoreAction => 'Obnovit tuto verzi';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Obnovit verzi uloženou $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Aktuální text se nejdřív uloží do historie, takže se můžete '
      'kdykoli vrátit.';
  @override
  String get historyRestoreConfirm => 'Obnovit';
  @override
  String historyRestored(String when) => 'Obnovena verze uložená $when';
  @override
  String get historyRestoreFailed => 'Verzi se nepodařilo obnovit';
  @override
  String get actionUndo => 'Zpět';
  @override
  String diffLineRange(int start, int end) => 'Řádky $start–$end';
  @override
  String diffLineSingle(int line) => 'Řádek $line';
  @override
  String diffUnchanged(int count) => switch (count) {
    1 => '1 nezměněný řádek',
    >= 2 && <= 4 => '$count nezměněné řádky',
    _ => '$count nezměněných řádků',
  };
  @override
  String get historyTakeHunk => 'Obnovit zde';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Obnovit 1 změnu' : 'Obnovit $count změn';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Vybrané změny se vrátí k textu této verze. Poznámka v současné podobě '
      'se nejdřív uchová jako verze, takže to můžeš vzít zpět.';
  @override
  String get historyNoteChangedReloaded =>
      'Poznámka se změnila, zatímco jsi tu byl — porovnání bylo aktualizováno.';
  @override
  String get historyVersionsTitle => 'Počet uchovávaných verzí';
  @override
  String get historyVersionsSubtitle => 'Pro každou poznámku, v .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Žádné' : '$count';
  @override
  String get historyIntervalTitle => 'Nová verze nejvýš každých';
  @override
  String get historyIntervalSubtitle =>
      'Během psaní; začátek úprav poznámky vždy jednu uchová';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Přepis';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Žádný';
  @override
  String get transcriptionLanguageTitle => 'Jazyk';
  @override
  String get transcriptionLanguageSubtitle =>
      'Jazyk, kterým se ve vašich nahrávkách mluví. Zadat ho je přesnější než '
      'ho nechat rozpoznat.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Jako aplikace ($language)';
  @override
  String get transcriptionLanguageDetect => 'Rozpoznat automaticky';
  @override
  String get transcriptionModelsTitle => 'Modely přepisu';
  @override
  String transcriptionModelsUsed(String size) => 'Využito $size';
  @override
  String get transcriptionModelsInstalled => 'Stažené';
  @override
  String get transcriptionModelsDownloading => 'Stahuje se';
  @override
  String get transcriptionModelsAvailable => 'Dostupné';
  @override
  String get transcriptionModelsFooter =>
      'Modely zůstávají v úložišti aplikace v tomto zařízení. Nekopírují se '
      'do knihovny ani se nesynchronizují.';
  @override
  String get transcriptionModelDefault => 'Výchozí';
  @override
  String get transcriptionModelSlow => 'Pomalý';
  @override
  String get transcriptionModelHintTiny => 'Nejrychlejší, nejméně přesný';
  @override
  String get transcriptionModelHintBase => 'Dobrý poměr rychlosti a přesnosti';
  @override
  String get transcriptionModelHintSmall => 'Přesnější, zhruba 3× pomalejší';
  @override
  String get transcriptionModelHintMedium => 'Velmi přesný, v telefonu pomalý';
  @override
  String get transcriptionModelHintLarge =>
      'Nejpřesnější, potřebuje hodně paměti';
  @override
  String get transcriptionModelDownload => 'Stáhnout';
  @override
  String transcriptionModelDeleteTitle(String model) => 'Smazat model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Uvolní se $size. Model si můžete později stáhnout znovu.';
  @override
  String get transcriptionModelFailed =>
      'Stažení se nezdařilo. Zkontrolujte připojení a zkuste to znovu.';
  @override
  String get actionRetry => 'Zkusit znovu';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Připojení se přerušilo, zkouší se znovu…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pozastaveno na $progress';
  @override
  String get actionResume => 'Pokračovat';
  @override
  String get audioTranscribe => 'Přepsat';
  @override
  String get audioTranscribeUnsupported => 'V tomto zařízení jen nahrávky WAV';
  @override
  String get transcriptionQueued => 'Ve frontě';
  @override
  String get transcriptionPreparing => 'Připravuje se zvuk…';
  @override
  String transcriptionRunning(int percent) => 'Přepisuje se… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Stahuje se $model · $percent %';
  @override
  String get transcriptionSaved => 'Přepis byl přidán do popisu';
  @override
  String get transcriptionNoSpeech =>
      'V této nahrávce nebyla rozpoznána žádná řeč';
  @override
  String get transcriptionFailed => 'Přepis se nezdařil';
  @override
  String get transcriptionPickModelTitle => 'Vyberte model';
  @override
  String get transcriptionPickModelBody =>
      'Přepis probíhá v tomto zařízení a nahrávka se nikam neodesílá. Model '
      'se stahuje jen jednou.';
  @override
  String get transcriptionPickModelAction => 'Stáhnout a přepsat';
  @override
  String get transcriptionModelRecommended => 'Doporučený';
  @override
  String get transcriptionExistingTitle => 'Tato nahrávka už má popis';
  @override
  String get transcriptionExistingBody =>
      'Nahradit ho přepisem, nebo přepis přidat pod něj?';
  @override
  String get transcriptionAppend => 'Přidat pod';
  @override
  String get transcriptionReplace => 'Nahradit';
  @override
  String get settingsSectionSync => 'Synchronizace';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Pro tuto knihovnu není nastaveno';
  @override
  String get syncNeverSynced => 'Dosud nesynchronizováno';
  @override
  String syncLastSynced(String when) => 'Synchronizováno $when';
  @override
  String get syncRunning => 'Synchronizace…';
  @override
  String syncScreenSubtitle(String library) => 'Knihovna $library';
  @override
  String get syncUrlLabel => 'Adresa složky';
  @override
  String get syncUrlRequired => 'Zadejte adresu serveru';
  @override
  String get syncUrlHint =>
      'Složka musí existovat. Zkopírujte adresu tak, jak ji '
      'zobrazuje server.';
  @override
  String get syncHttpWarning =>
      'Nešifrované připojení: v pořádku přes VPN nebo v místní '
      'síti.';
  @override
  String get syncUserLabel => 'Uživatel';
  @override
  String get syncUserHint =>
      'Nechte prázdné, pokud server nežádá přihlašovací údaje.';
  @override
  String get syncPasswordLabel => 'Heslo';
  @override
  String get syncPasswordHint =>
      'Uloženo v klíčence tohoto zařízení, nikdy v souborech '
      'knihovny.';
  @override
  String get syncPasswordKeepHint =>
      'Nechte prázdné, chcete-li ponechat uložené heslo.';
  @override
  String get syncShowPassword => 'Zobrazit heslo';
  @override
  String get syncHidePassword => 'Skrýt heslo';
  @override
  String get syncTestAction => 'Otestovat připojení';
  @override
  String get syncTesting => 'Testování…';
  @override
  String get syncRetargetWarning =>
      'S novou adresou nebo uživatelem začne příští '
      'synchronizace znovu jako první.';
  @override
  String get syncTestOk => 'Připojení funguje';
  @override
  String get syncModeFull => 'Úplný režim';
  @override
  String get syncModeCompatible => 'Kompatibilní režim';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Čtení, zápis a mazání';
  @override
  String get syncCapEtags => 'Otisky souborů (ETagy)';
  @override
  String get syncCapNoEtags => 'Bez otisků souborů (ETagy)';
  @override
  String get syncCapNoEtagsDetail =>
      'Porovnává velikost a datum; v případě pochybností stáhne '
      'znovu';
  @override
  String get syncCapGuarded => 'Chráněné zápisy';
  @override
  String get syncCapUnguarded => 'Nechráněné zápisy';
  @override
  String get syncCapUnguardedDetail =>
      'Těsně před zápisem zkontroluje soubor na serveru';
  @override
  String get syncCapMove => 'Přejmenování bez nového nahrávání';
  @override
  String get syncCapNoMove => 'Bez přejmenování na serveru';
  @override
  String get syncCapNoMoveDetail =>
      'Přejmenování se provede jako smazání a nové nahrání';
  @override
  String get syncCompatibleNote =>
      'V kompatibilním režimu funguje synchronizace stejně, jen '
      's několika požadavky navíc.';
  @override
  String get syncTestInvalidUrl => 'Neplatná adresa';
  @override
  String get syncTestInvalidUrlHint =>
      'Zadejte adresu http:// nebo https:// bez uživatele a '
      'hesla.';
  @override
  String get syncTestOffline => 'Server je nedostupný';
  @override
  String get syncTestOfflineHint =>
      'Je zapnutá VPN? Adresa 10.x nebo 192.168.x funguje jen ze '
      'stejné sítě.';
  @override
  String get syncTestAuth => 'Uživatel nebo heslo byly odmítnuty';
  @override
  String get syncTestAuthHint => 'Zkontrolujte je a otestujte znovu.';
  @override
  String get syncTestNotFound => 'Složka neexistuje';
  @override
  String get syncTestNotFoundHint =>
      'Vytvořte ji na serveru nebo opravte adresu.';
  @override
  String get syncTestUnsupported => 'Není to složka WebDAV';
  @override
  String get syncTestUnsupportedHint => 'Server odpovídá, ale ne jako WebDAV.';
  @override
  String get syncTestFailed => 'Test se nezdařil';
  @override
  String get syncNowAction => 'Synchronizovat nyní';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresa, uživatel a heslo';
  @override
  String get syncRetestTitle => 'Znovu otestovat server';
  @override
  String syncProbedAgo(String when) => 'Poslední test: $when';
  @override
  String get syncDisconnectTitle => 'Odpojit tuto knihovnu';
  @override
  String get syncDisconnectSubtitle => 'Soubory zůstanou tady i na serveru';
  @override
  String get syncDisconnectConfirmTitle => 'Odpojit synchronizaci?';
  @override
  String get syncDisconnectConfirmBody =>
      'Tato knihovna se na tomto zařízení přestane '
      'synchronizovat. Žádný soubor se nesmaže, tady ani na '
      'serveru. Pokud ji znovu připojíte, první synchronizace '
      'začne od začátku.';
  @override
  String get syncDisconnectConfirm => 'Odpojit';
  @override
  String get syncFirstTitle => 'První synchronizace';
  @override
  String get syncFirstIntro => 'Knihovna byla porovnána se složkou na serveru:';
  @override
  String get syncFirstUpload => 'K nahrání';
  @override
  String get syncFirstDownload => 'Ke stažení';
  @override
  String get syncFirstBoth => 'Na obou stranách';
  @override
  String get syncFirstBothHint => 'Stejné: bez přenosu. Rozdílné: k vyřešení';
  @override
  String get syncFirstNoDelete =>
      'První synchronizace nic nesmaže, tady ani na serveru.';
  @override
  String get syncStartAction => 'Spustit';
  @override
  String syncMassTrashTitle(int count) => count == 1
      ? 'Přesunout 1 soubor do koše?'
      : count >= 2 && count <= 4
      ? 'Přesunout $count soubory do koše?'
      : 'Přesunout $count souborů do koše?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Na serveru chybí $count z $total synchronizovaných '
      'souborů. Obvykle to znamená špatnou adresu, nepřipojený '
      'disk NAS nebo omylem vyprázdněnou složku.';
  @override
  String get syncMassTrashHint =>
      'Pokud jste je opravdu smazali na jiném zařízení, '
      'potvrďte: tady se přesunou do koše.';
  @override
  String get syncMassTrashConfirm => 'Přesunout do koše';
  @override
  String syncMassDeleteTitle(int count) => count == 1
      ? 'Smazat 1 soubor ze serveru?'
      : count >= 2 && count <= 4
      ? 'Smazat $count soubory ze serveru?'
      : 'Smazat $count souborů ze serveru?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Tady chybí $count z $total synchronizovaných souborů. '
      'Pokud jste je nesmazali, zrušte akci a zkontrolujte '
      'složku knihovny.';
  @override
  String get syncMassDeleteConfirm => 'Smazat ze serveru';
  @override
  String get syncTooltip => 'Synchronizovat';
  @override
  String get syncStageConnecting => 'Připojování k serveru…';
  @override
  String get syncStageComparing => 'Porovnávání se serverem…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synchronizace · $done z $total';
  @override
  String get syncStatusWarnings => 'Synchronizováno s upozorněními';
  @override
  String syncConflictsHeader(int count) => 'Změněno tady i na serveru · $count';
  @override
  String get syncConflictHint => 'Žádná z obou verzí nebyla změněna';
  @override
  String get syncResolveAction => 'Vyřešit';
  @override
  String syncFailuresHeader(int count) => 'Nesynchronizováno · $count';
  @override
  String get syncFailuresHint => 'Zkusí se znovu při příští synchronizaci';
  @override
  String get syncAbortAuth => 'Server odmítl heslo';
  @override
  String get syncAbortMissingPassword => 'Není uloženo žádné heslo';
  @override
  String get syncAbortOffline => 'Server je nedostupný';
  @override
  String get syncAbortRemoteMissing => 'Složka na serveru už neexistuje';
  @override
  String get syncAbortUnsupported => 'Server už nefunguje jako WebDAV';
  @override
  String get syncAbortFailed => 'Synchronizace se nezdařila';
  @override
  String get syncAbortNotConfirmed => 'Synchronizace zrušena';
  @override
  String get syncAbortNothingTouched =>
      'Žádný soubor nebyl změněn. Vaše změny zůstanou tady až do '
      'příští úspěšné synchronizace.';
  @override
  String syncLastSuccess(String when) =>
      'Poslední úspěšná synchronizace: $when';
  @override
  String get syncNoSuccessYet => 'Zatím žádná úspěšná synchronizace';
  @override
  String get syncUpdatePasswordAction => 'Aktualizovat heslo';
  @override
  String get syncRetryAction => 'Zkusit znovu';
  @override
  String get syncOpenSettingsAction => 'Nastavení';
  @override
  String get syncCloseAction => 'Zavřít';
  @override
  String get syncDoneSnack => 'Synchronizováno';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synchronizováno · 1 soubor smazaný jinde je v koši'
      : count >= 2 && count <= 4
      ? 'Synchronizováno · $count soubory smazané jinde jsou v koši'
      : 'Synchronizováno · $count souborů smazaných jinde je v koši';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synchronizováno · 1 konflikt k vyřešení'
      : count >= 2 && count <= 4
      ? 'Synchronizováno · $count konflikty k vyřešení'
      : 'Synchronizováno · $count konfliktů k vyřešení';
  @override
  String get syncShowAction => 'Zobrazit';
  @override
  String get syncConflictTitle => 'Vyřešit konflikt';
  @override
  String get syncConflictBinary =>
      'Nejde o textový soubor: vyberte, kterou kopii ponechat.';
  @override
  String get syncConflictKeepNote =>
      'Kopie, kterou neponecháte, zůstane v historii poznámky.';
  @override
  String get syncKeepLocal => 'Ponechat verzi z tohoto zařízení';
  @override
  String get syncKeepRemote => 'Ponechat verzi ze serveru';
  @override
  String get syncConflictLoadFailed => 'Obě verze se nepodařilo načíst';
  @override
  String get syncResolveFailed => 'Konflikt se nepodařilo vyřešit';
  @override
  String get syncResolved => 'Konflikt vyřešen';
  @override
  String get syncConflictMoved =>
      'Jedna z verzí se mezitím změnila: konflikt byl načten znovu, vyberte '
      'znovu.';
  @override
  String get syncSectionWhen => 'Kdy synchronizovat';
  @override
  String get syncAutoTitle => 'Automaticky';
  @override
  String get syncAutoSubtitle => 'Po úpravách, při otevření a v intervalech';
  @override
  String get syncIntervalTitle => 'Kontrolovat server každých';
  @override
  String get syncIntervalSubtitle => 'Jen když je aplikace otevřená';
  @override
  String get syncIntervalDialogBody =>
      'Abyste viděli změny provedené na jiných zařízeních, dokud je aplikace '
      'otevřená. S „Nikdy“ jen po úpravách a při otevření.';
  @override
  String syncIntervalMinutes(int count) => switch (count) {
    1 => '1 minuta',
    >= 2 && <= 4 => '$count minuty',
    _ => '$count minut',
  };
  @override
  String get syncIntervalNever => 'Nikdy';
  @override
  String get syncWifiOnlyTitle => 'Jen přes Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Na mobilních datech synchronizovat jen ručně';
  @override
  String syncPendingChanges(int count) => switch (count) {
    1 => '1 změna čeká',
    >= 2 && <= 4 => '$count změny čekají',
    _ => '$count změn čeká',
  };
  @override
  String syncRetryIn(String wait) => 'další pokus za $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Čeká se na Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Čeká se na připojení';
  @override
  String get syncMobileDataHint =>
      '„Synchronizovat nyní“ i tak použije mobilní data.';
  @override
  String get syncQueueKeptHint =>
      'Změny tu zůstanou, i když aplikaci zavřete, a odejdou samy, jakmile '
      'server odpoví.';
  @override
  String get syncAutoPaused => 'Automatická synchronizace pozastavena';
  @override
  String get syncPausedAuthHint =>
      'Pokračuje, jakmile aktualizujete heslo nebo synchronizujete ručně.';
  @override
  String get syncPausedServerHint =>
      'Pokračuje, jakmile opravíte adresu nebo synchronizujete ručně.';
  @override
  String get syncPausedConfirmHint =>
      '„Synchronizovat nyní“ ukáže, co by se odstranilo, a nejdřív se zeptá.';
  @override
  String get syncNeedsConfirmation => 'Čeká na vaše potvrzení';
  @override
  String get syncMergeIntro =>
      'Úpravy, které se nepřekrývají, jsou už sloučené; tam, kde se '
      'překrývají, vyberte, co ponechat.';
  @override
  String get syncMergeClean => 'Obě verze se sloučí samy: nic se nepřekrývá.';
  @override
  String get syncMergeNoBase =>
      'Chybí společná verze ke sloučení: všude, kde se obě kopie liší, '
      'vybíráte vy.';
  @override
  String syncMergeOverlap(int index, int total) => 'Překryv $index z $total';
  @override
  String get syncMergeFromLocal => 'Z tohoto zařízení';
  @override
  String get syncMergeFromRemote => 'Ze serveru';
  @override
  String get syncMergeRemovedLines => 'Odebrané řádky';
  @override
  String get syncMergeAbsentLines => 'Není v této kopii';
  @override
  String get syncMergeKeepLocal => 'Moje';
  @override
  String get syncMergeKeepRemote => 'Serveru';
  @override
  String get syncMergeKeepBoth => 'Obojí';
  @override
  String get syncMergeSave => 'Uložit sloučení';
  @override
  String get syncMergeKeepWhole => 'Nebo ponechat jednu celou kopii';
}
