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
  String get settingsPreviewEnabledTitle => 'Náhľad';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Zobraziť vykreslenú poznámku vedľa zdrojového editora';
  @override
  String get switchToWysiwygTooltip => 'Prepnúť na WYSIWYG editor';
  @override
  String get switchToSourceTooltip => 'Prepnúť na Markdown zdroj';
  @override
  String get wysiwygTooLarge =>
      'Táto poznámka je príliš veľká na WYSIWYG editor. Otvorte ju ako '
      'Markdown zdroj.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Vzhľad';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Knihovna';
  @override
  String get settingsSectionReminders => 'Pripomienky';
  @override
  String get settingsSectionShortcuts => 'Klávesnica';
  @override
  String get keyboardShortcutsTitle => 'Klávesové skratky';
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
      'Vyberte všetky jazyky, v ktorých je knihovna napísaná. Slovo prejde, '
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
  String get themePaletteTitle => 'Farbová paleta';
  @override
  String get themePaletteSubtitle => 'Farby rozhrania a poznámky';
  @override
  String get themePaletteSystem => 'Systém';

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
  @override
  String get previewModeTitle => 'Režim náhľadu';
  @override
  String get previewModeSubtitle =>
      'Ci náhľad zdieľa obrazovku s editorom, alebo ho nahradí';
  @override
  String get previewModeAuto => 'Vedľa';
  @override
  String get previewModeSwitch => 'Celá obrazovka';
  @override
  String get splitRatioTitle => 'Šírka rozdeľovania';
  @override
  String get splitRatioSubtitle => 'Podiel editora, keď je náhľad vedľa';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Rýchla poznámka';
  @override
  String get shortcutNewTodo => 'Nová úloha';
  @override
  String get shortcutNewNote => 'Nová poznámka';
  @override
  String get shortcutNewList => 'Nový zoznam';
  @override
  String get shortcutToggleSidebar => 'Zobraziť alebo skryť filter';
  @override
  String get shortcutEditorSection => 'V editore';
  @override
  String get shortcutFind => 'Hľadať';
  @override
  String get shortcutReplace => 'Hľadať a nahradiť';
  @override
  String get shortcutSavingNote =>
      'Zmeny sa ukladajú automaticky, takže neexistuje skratka na uloženie.';

  // Editor status bar.
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
  String get toolbarHeading => 'Nadpis';
  @override
  String get toolbarList => 'Zoznam';
  @override
  String get toolbarOrderedList => 'Číslovaný zoznam';
  @override
  String get toolbarQuote => 'Citát';
  @override
  String get toolbarIndent => 'Odsadenie';
  @override
  String get toolbarOutdent => 'Zrušiť odsadenie';
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
  @override
  String get enterFullScreenTooltip => 'Celá obrazovka';
  @override
  String get exitFullScreenTooltip => 'Opustiť celú obrazovku';

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
  String get newFolderTitle => 'Nový priečinok';
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
}
