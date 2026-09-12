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
  String get settingsPreviewEnabledTitle => 'Náhled';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Zobrazí renderovanou poznámku vedle zdrojového editoru';
  @override
  String get switchToWysiwygTooltip => 'Přepnout na editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Přepnout na zdrojový Markdown';
  @override
  String get wysiwygTooLarge =>
      'Tato poznámka je příliš velká pro editor WYSIWYG. Otevřete ji ve '
      'zdrojovém Markdown.';

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
  @override
  String get previewModeTitle => 'Režim náhledu';
  @override
  String get previewModeSubtitle =>
      'Zda náhled sdílí obrazovku s editorem nebo ho nahrazuje';
  @override
  String get previewModeAuto => 'Po bocích';
  @override
  String get previewModeSwitch => 'Celá obrazovka';
  @override
  String get splitRatioTitle => 'Šířka rozdělení';
  @override
  String get splitRatioSubtitle => 'Podíl editoru, když je náhled po bocích';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Rychlá poznámka';
  @override
  String get shortcutNewTodo => 'Nový úkol';
  @override
  String get shortcutNewNote => 'Nová poznámka';
  @override
  String get shortcutNewList => 'Nový seznam';
  @override
  String get shortcutToggleSidebar => 'Zobrazit nebo skrýt filtr';
  @override
  String get shortcutEditorSection => 'V editoru';
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
  String get toolbarHeading => 'Nadpis';
  @override
  String get toolbarList => 'Seznam';
  @override
  String get toolbarOrderedList => 'Očíslovaný seznam';
  @override
  String get toolbarQuote => 'Citace';
  @override
  String get toolbarIndent => 'Odsadit';
  @override
  String get toolbarOutdent => 'Zmenšit odsazení';
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
  @override
  String get enterFullScreenTooltip => 'Celá obrazovka';
  @override
  String get exitFullScreenTooltip => 'Opuštět celou obrazovku';

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
  String get newFolderTitle => 'Nová složka';
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
}
