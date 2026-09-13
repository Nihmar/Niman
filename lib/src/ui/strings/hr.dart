// The Croatian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class CroatianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'siječanj',
    'veljača',
    'ožujak',
    'travanj',
    'svibanj',
    'lipanj',
    'srpanj',
    'kolovoz',
    'rujan',
    'listopad',
    'studeni',
    'prosinac',
  ];
  @override
  List<String> get monthNamesShort => const [
    'sij',
    'velj',
    'ožu',
    'tra',
    'svi',
    'lip',
    'srp',
    'kol',
    'ruj',
    'lis',
    'stu',
    'pro',
  ];
  @override
  List<String> get weekdayNames => const [
    'ponedjeljak',
    'utorak',
    'srijeda',
    'četvrtak',
    'petak',
    'subota',
    'nedjelja',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'pon',
    'uto',
    'sri',
    'čet',
    'pet',
    'sub',
    'ned',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Korpa';
  @override
  String get trashSubtitle =>
      'Izbrisani elementi se premještaju u .trash/ (isključeno = trajno '
      'brisanje)';
  @override
  String get debugLogsTitle => 'Dijagnostički dnevnik';
  @override
  String get debugLogsSubtitle =>
      'Pohranjuje događaje aplikacije u memo bufers';
  @override
  String get lineNumbersTitle => 'Brojevi redaka';
  @override
  String get lineNumbersSubtitle =>
      'Prikaži stupac s brojevima redaka u uređivaču napomene';
  @override
  String get keyboardOnOpenTitle => 'Tipkovnica pri otvaranju';
  @override
  String get keyboardOnOpenSubtitle =>
      'Prikaži tipkovnicu pri otvaranju napomene (isključeno = na prvi '
      'dodir)';
  @override
  String get editorKindSource => 'Markdown izvor';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Pregled';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Prikaži renderiranu napomenu pored izvornog uređivača';
  @override
  String get switchToWysiwygTooltip => 'Prebaci na WYSIWYG uređivač';
  @override
  String get switchToSourceTooltip => 'Prebaci na Markdown izvor';
  @override
  String get wysiwygTooLarge =>
      'Ova napomena je prevelika za WYSIWYG uređivač. Otvori je kao '
      'Markdown izvor.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Izgled';
  @override
  String get settingsSectionEditor => 'Uređivač';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'Podsjetnici';
  @override
  String get settingsSectionShortcuts => 'Tipkovnica';
  @override
  String get keyboardShortcutsTitle => 'Tipkovnički prečaci';
  @override
  String get settingsSectionDiagnostics => 'Dijagnostika';
  @override
  String get settingsSpellCheckTitle => 'Kontrola pravopisa';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podcrtava pravopisne greške tijekom pisanja.';
  @override
  String get spellCheckDictionaryTitle => 'Rječnik';
  @override
  String get spellCheckDictionarySystem => 'Podrazumijevano sustava';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Odabir rječnika';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Odaberi sve jezike u kojima je biblioteka napisana. Riječ prolazi '
      'ako je neki od odabranih rječnika prepoznaje; bez odabira, odlučuje '
      'jezik sustava.';
  @override
  String get spellCheckNoDictionaries =>
      'Na ovom sustavu nisu pronađeni rječnici.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Kontrola pravopisa';
  @override
  String get spellCheckTitle => 'Pravopis';
  @override
  String get spellCheckEmpty => 'Nema pravopisnih grešaka.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nije instaliran na ovom sustavu.';
  @override
  String get spellCheckNoSuggestions => 'Nema prijedloga';
  @override
  String spellCheckCount(int count) => '$count za provjeru';
  @override
  String spellCheckLine(int line) => 'redak $line';

  @override
  String indentWidthValue(int spaces) => '$spaces razmaka';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Svijetlost';
  @override
  String get themeBrightnessSubtitle => 'Svijetlo, tamno ili postavka uređaja';
  @override
  String get themeBrightnessSystem => 'Sustav';
  @override
  String get themeBrightnessDay => 'Svijetlo';
  @override
  String get themeBrightnessNight => 'Tamno';
  @override
  String get themePaletteTitle => 'Paleta boja';
  @override
  String get themePaletteSubtitle => 'Boje sučelja i napomene';
  @override
  String get themePaletteSystem => 'Sustav';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Veličina teksta sučelja';
  @override
  String get uiTextScaleSubtitle =>
      'Stablo, kartice i dijalozi; iznad postavke sustava';
  @override
  String get noteTextScaleTitle => 'Veličina teksta napomene';
  @override
  String get noteTextScaleSubtitle => 'Uređivač i pregled su uvijek usklađeni';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Način pregleda';
  @override
  String get previewModeSubtitle =>
      'Podijeli li pregled zaslon s uređivačem ili ga zamijeni';
  @override
  String get previewModeAuto => 'Pored';
  @override
  String get previewModeSwitch => 'Cijeli zaslon';
  @override
  String get splitRatioTitle => 'Širina omjera podjele';
  @override
  String get splitRatioSubtitle => 'Udio uređivača kada je pregled pored';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Format veze';
  @override
  String get linkTypeSubtitle => 'Što gumb veze upisuje u uređivač';
  @override
  String get linkTypeWikilink => 'Wikipoveza';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Širina uvlačenja';
  @override
  String get indentWidthSubtitle =>
      'Broj razmaka dodanih po razini uvlačenja u uređivaču';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Jezik';
  @override
  String get languageSubtitle => 'Jezik vlastitog teksta aplikacije';
  @override
  String get languageSystem => 'Sustav';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Dodaj stavku';
  @override
  String get listAddTooltip => 'Dodaj stavku';
  @override
  String get listEmpty => 'Još nema stavaka';
  @override
  String get listDragHandleLabel => 'Promijeni redoslijed stavke';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Brza napomena';
  @override
  String get shortcutNewTodo => 'Nova zadaća';
  @override
  String get shortcutNewNote => 'Nova napomena';
  @override
  String get shortcutNewList => 'Novi popis';
  @override
  String get shortcutToggleSidebar => 'Prikaži ili sakrij filter';
  @override
  String get shortcutEditorSection => 'U uređivaču';
  @override
  String get shortcutFind => 'Traži';
  @override
  String get shortcutReplace => 'Traži i zamijeni';
  @override
  String get shortcutSavingNote =>
      'Promjene se automatski spremaju, pa ne postoji prečac za spremanje.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Struktura';
  @override
  String get outlineNoHeadings => 'Nema naslova';
  @override
  String get outlineNoTitle => '(bez naslova)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Podebljano';
  @override
  String get toolbarItalic => 'Kurziv';
  @override
  String get toolbarStrikethrough => 'Prekrižano';
  @override
  String get toolbarSuperscript => 'Gornji indeks';
  @override
  String get toolbarUnderline => 'Podvučeno';
  @override
  String get toolbarLink => 'Veza';
  @override
  String get toolbarCode => 'Kodni blok';
  @override
  String get toolbarImage => 'Umetni sliku';
  @override
  String get toolbarHeading => 'Naslov';
  @override
  String get toolbarList => 'Popis';
  @override
  String get toolbarOrderedList => 'Brojčani popis';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Uvlačenje';
  @override
  String get toolbarOutdent => 'Ukloni uvlačenje';
  @override
  String get headingDialogTitle => 'Razina naslova';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Traka alata uređivača';
  @override
  String get toolbarSettingsHint =>
      'Povuci da promijeniš redoslijed; oko prikazuje ili sakriva gumb.';
  @override
  String get toolbarShowButton => 'Prikaži';
  @override
  String get toolbarHideButton => 'Sakrij';
  @override
  String get toolbarResetOrder => 'Vrati podrazumijevano';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Prikaži pregled';
  @override
  String get showEditorTooltip => 'Prikaži uređivač';
  @override
  String get enterFullScreenTooltip => 'Cijeli zaslon';
  @override
  String get exitFullScreenTooltip => 'Izadi iz celog zaslona';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(sirova HTML tablica)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Traži po napomenama';
  @override
  String get searchModeWords => 'Riječi';
  @override
  String get searchModeContains => 'Sadrži';
  @override
  String get searchEmptyHint =>
      'Upiši za pretragu biblioteke, ili ključ = vrijednost za filtriranje '
      'po frontmatteru';
  @override
  String get searchTooShortHint => 'Upiši najmanje 2 znaka';
  @override
  String get searchNoMatches => 'Nema rezultata';
  @override
  String get searchLoadMore => 'Prikaži više';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Zamijeni…';
  @override
  String get replaceInNoteAction => 'Zamijeni u ovoj napomeni…';
  @override
  String get replaceInThisNote => 'Zamijeni u ovoj napomeni';
  @override
  String get replaceWithLabel => 'Zamijeni s';
  @override
  String get replaceCaseSensitive => 'Razlikuj velika i mala slova';
  @override
  String get replaceWholeWordsHint =>
      'zamjenjuju se samo točni rezultati cijelih riječi';
  @override
  String get replaceConfirm => 'Zamijeni';
  @override
  String get replaceCancel => 'Zatvori';
  @override
  String get replaceUnavailable => 'Zamjena trenutno nije dostupna';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Traži po napomeni';
  @override
  String get editorFindHint => 'Traži';
  @override
  String get editorReplaceHint => 'Zamijeni';
  @override
  String get editorFindCaseTooltip => 'Razlikuj velika i mala slova';
  @override
  String get editorFindPreviousTooltip => 'Prethodni rezultat';
  @override
  String get editorFindNextTooltip => 'Sljedeći rezultat';
  @override
  String get editorFindCloseTooltip => 'Zatvori pretragu';
  @override
  String get editorFindReplaceModeTooltip => 'Način zamjene';
  @override
  String get editorReplaceOneTooltip => 'Zamijeni ovaj rezultat';
  @override
  String get editorReplaceAllTooltip => 'Zamijeni sve rezultate';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Oznake';
  @override
  String get tagsTitle => 'Oznake';
  @override
  String get tagsEmpty =>
      'Još nema oznake — dodaj #oznaku ili oznake u frontmatter';
  @override
  String get tagsBackTooltip => 'Natrag na pretragu';
  @override
  String get tagsNotesEmpty => 'Nema napomene s ovom oznakom';
  @override
  String tagsNotesCapped(int limit) =>
      'Prikazuju se samo prve $limit — pretraži oznaku za ograničenje';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Veza nije pronađena';
  @override
  String get headingNotFoundTitle => 'Naslov nije pronađen';
  @override
  String get ambiguousLinkTitle => 'Više napomena odgovara';
  @override
  String get openLinkFailed => 'Veza se nije mogla otvoriti';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Otvorene';
  @override
  String get todoDone => 'Završene';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Svi datumi';
  @override
  String get todoFilter => 'Filtriraj';
  @override
  String get todoNoTokens => 'Nema tokena na ovom popisu';
  @override
  String get todoCountOpen => 'otvoreno';
  @override
  String get todoCountDone => 'završeno';
  @override
  String get todoEmptyOpen => 'Još nema otvorenih zadaća';
  @override
  String get todoEmptyDone => 'Još nema završenih';
  @override
  String get todoEmptyFiltered => 'Nema zadaća koje odgovaraju';
  @override
  String get todoTitle => 'Zadaci';
  @override
  String get todoAddTooltip => 'Dodaj zadaću';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt format';
  @override
  String get todoHelpTooltip => 'Informacije o formatu';
  @override
  String get todoHelpIntro =>
      'Tvoji zadaci su obična tekstualna datoteka, jedan zadatak po retku. '
      'Niman piše sintaksu za tebe, ali ništa ne sakriva: možeš uređivati '
      'datoteku u bilo kojem uređivaču i Niman će je ponovno pročitati.';
  @override
  String get todoHelpFilesTitle => 'Dvije datoteke';
  @override
  String get todoHelpFilesBody =>
      'Otvoreni zadaci žive u todo.txt-u na korijenu biblioteke. Završiš '
      'li jedan, redak se premješta u done.txt, tako da todo.txt ostane '
      'kratak. Završeni redak koji ponovno dođe u todo.txt, Niman arhivira '
      'sljedećem čitanju datoteka.';
  @override
  String get todoHelpLineTitle => 'Anatomija retka';
  @override
  String get todoHelpLineBody =>
      'Sve što je prije opisa je opcionalno i mora doći u ovom '
      'redoslijedu:';
  @override
  String get todoHelpDoneBody =>
      'Označava zadatak kao završen. Niman ga dodaje kada označiš okviricu.';
  @override
  String get todoHelpPriority => '(A) do (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A je najviši. Prikazuje se kao grb u popisu.';
  @override
  String get todoHelpDatesBody =>
      'Rok, a zatim datum izrade. Sa jednim datumom, to je datum izrade, '
      'osim ako redak ne počinje s x.';
  @override
  String get todoHelpTokensTitle => 'Projekti, konteksti i oznake';
  @override
  String get todoHelpTokensBody =>
      'Bilo koja riječ u opisu s bilo kojim od ovih prefikxa postaje '
      'filtrirajuća oznaka. Ništa nije unaprijed definirano: token postoji '
      'dok ga pišeš.';
  @override
  String get todoHelpProjectBody =>
      'Komu projektu zadatak pripada, npr. +kuchinja ili +posao.';
  @override
  String get todoHelpContextBody =>
      'Gdje ga radiš ili kako, npr. @kod kuće ili @susretanja.';
  @override
  String get todoHelpHashtagBody =>
      'Slobodna oznaka za ono što prve dvije ne pokrivaju.';
  @override
  String get todoHelpTagsTitle => 'Datumi i podsjetnici';
  @override
  String get todoHelpTagsBody =>
      'Ove su ključ:vrijednost oznake. Niman ih piše iz dijaloga zadatka i '
      'čita ih bilo gdje se pojave na retku.';
  @override
  String get todoHelpDueBody => 'Rok. Upravlja bojom grba i filterima datuma.';
  @override
  String get todoHelpRemBody =>
      'Kada bi se trebalo poslati obavještenje, u tvojoj vremenskoj zoni. '
      'Okida se kada je zaslon ugašen i aplikacija zatvorena.';
  @override
  String get todoHelpRemDesktop =>
      'Na računaru Niman mora raditi kada dođe vrijeme: podsjetnik se '
      'prikazuje dok je aplikacija otvorena, a ništa se ne okida kada je '
      'zatvorena.';
  @override
  String get todoHelpOtherBody =>
      'Čuva se točno kao što je napisano, tako da oznake drugih todo.txt '
      'aplikacija prežive putovanje. Niman ih ne koristi, rec: included: '
      'ponavljajući se zadatak se još ne ponavlja.';
  @override
  String get todoHelpEditTitle => 'Uređivanje izvan Nimana';
  @override
  String get todoHelpEditBody =>
      'Zadatak koji ne diraš ponovno se piše bajt po bajt, uključujući '
      'čudne razmake. Uređivanjem retka, Niman ponovno piše samo taj redak u '
      'njegovu kanonskom obliku i ostavlja ostatak datoteke netaknutim.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Dodaj zadaću';
  @override
  String get todoEditTitle => 'Uredi zadatak';
  @override
  String get todoDescriptionHint => 'Opis';
  @override
  String get todoCancel => 'Odustani';
  @override
  String get todoSave => 'Spremi';
  @override
  String get todoEditAction => 'Uredi';
  @override
  String get todoDeleteAction => 'Obriši';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Isteklo';
  @override
  String get todoDueToday => 'Danas';
  @override
  String get todoDueNext7 => 'Sljedećih 7 dana';
  @override
  String get todoDueNoDate => 'Bez datuma';
  @override
  String get todoRowDue => 'Rok';
  @override
  String get todoRowDueToday => 'Rok danas';
  @override
  String get todoSortTooltip => 'Sortiraj';
  @override
  String get todoSortDue => 'Datum roka';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Datum izrade';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez prioriteta';
  @override
  String get todoNoPriorityShort => 'Nema';
  @override
  String get todoMorePriorities => 'Više…';
  @override
  String get todoPriorityTitle => 'Prioritet';
  @override
  String get todoNoDueDate => 'Bez roka';
  @override
  String get todoNoReminder => 'Bez podsjetnika';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Oznaka';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Podsjetnici za zadatke';
  @override
  String get todoReminderChannelDescription =>
      'Zakazane obavještenja za zadatke s podsjetničkim vremenom.';
  @override
  String get todoReminderBody => 'Podsjetnik za zadatak';
  @override
  String get todoReminderFallbackTitle => 'Podsjetnik za zadatak';
  @override
  String get todoReminderBlocked =>
      'Obavještenja su isključena, tako da se podsjetnici neće prikazati.';
  @override
  String get todoReminderBattery =>
      'Optimizacija baterije je aktivna za Niman. Sustav može obustaviti '
      'aplikaciju i izgubiti čekajuće podsjetnike.';
  @override
  String get todoReminderInexact =>
      'Ovaj uređaj ne podržava točne alarme, pa podsjetnik može doći '
      'nekoliko minuta kasnije kada je zaslon ugašen.';
  @override
  String get reminderShowTokensTitle => 'Oznake u obavještenjima podsjetnika';
  @override
  String get reminderShowTokensSubtitle =>
      'Ostavi +projekt, @kontekst i #oznaku u tekstu obavještenja. '
      'Isključeno prikazuje samo napisani zadatak.';
  @override
  String get todoReminderFixAction => 'Otvori postavke';
  @override
  String get todoReminderDismissAction => 'Odbaci';
  @override
  String get todoReminderDue => 'Rok';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'U redu';
  @override
  String get actionCancel => 'Odustani';
  @override
  String get actionCreate => 'Kreiraj';
  @override
  String get actionNew => 'Novo';
  @override
  String get actionSave => 'Spremi';
  @override
  String get actionClear => 'Očisti';
  @override
  String get actionChoose => 'Odaberi';
  @override
  String get actionDelete => 'Obriši';
  @override
  String get actionRename => 'Preimenuj';
  @override
  String get actionMove => 'Premjesti';
  @override
  String get saveAndClose => 'Spremi i zatvori';
  @override
  String get closeUnsavedTitle => 'Nespremljene promjene';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” ima nespremljene promjene. '
          'Spremiti ih prije zatvaranja?';
    }
    return '${names.length} napomena ima nespremljene promjene. '
        'Spremiti ih prije zatvaranja?';
  }

  @override
  String get closeSaveFailed =>
      'Spremanje nije uspjelo; napomena ostaje otvorena.';
  @override
  String get actionRestore => 'Vrati';
  @override
  String get actionEmpty => 'Isprazni';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Sakrij bočni panel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Prikaži bočni panel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimiziraj';
  @override
  String get windowMaximizeTooltip => 'Maksimiziraj';
  @override
  String get windowRestoreTooltip => 'Vrati';
  @override
  String get windowCloseTooltip => 'Zatvori';
  @override
  String get tabFiles => 'Datoteke';
  @override
  String get tabSearch => 'Pretraga';
  @override
  String get tabSettings => 'Postavke';
  @override
  String get quickNoteTitle => 'Brza napomena';
  @override
  String get treeEmpty => 'Još nema napomena';
  @override
  String get selectANote => 'Odaberi napomenu';
  @override
  String get showListTooltip => 'Prikaži popis';
  @override
  String get editRawTooltip => 'Uredi sirovo';
  @override
  String get sortAscTooltip => 'Sortiraj A–Z';
  @override
  String get sortDescTooltip => 'Sortiraj Z–A';
  @override
  String get newNoteTitle => 'Nova napomena';
  @override
  String get newFolderTitle => 'Novi direktorij';
  @override
  String get newNoteHere => 'Nova napomena ovdje';
  @override
  String get newFolderHere => 'Novi direktorij ovdje';
  @override
  String get newListNoteTitle => 'Nova popisna napomena';
  @override
  String get newListNoteDefault => 'Moj popis';
  @override
  String get setAsQuickNote => 'Postavi kao brzu napomenu';
  @override
  String get currentQuickNote => 'Trenutna brza napomena';
  @override
  String get pinnedSection => 'Prikvačeno';
  @override
  String pinnedSectionCount(int count) => 'Prikvačeno · $count';
  @override
  String get templateFolderTitle => 'Direktorij predlošaka';
  @override
  String get newFromTemplateTitle => 'Novo iz predloška';
  @override
  String get newFromTemplateHere => 'Novo iz predloška ovdje';
  @override
  String get templateFormTitle => 'Popuni predložak';
  @override
  String get templateFormBacklink => 'Povezano s';
  @override
  String get templateFormNoNote => 'Bez napomene';
  @override
  String get templateFormPickNote => 'Odaberi napomenu';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Zamjenski znaci predloška';
  @override
  String get templateHelpIntro =>
      'Predložak je obična napomena s rupama. Kreiranjem napomene iz njega '
      'kopira se tekst i popunjavaju rupe.';
  @override
  String get templateHelpUnknown =>
      'Zamjenski znak koji Niman ne poznaje ostaje točno kao što je '
      'napisan, tako da se tipkastička greška uočava u napomeni, a ne da '
      'tiho slomi redak.';
  @override
  String get templateHelpValuesTitle => 'Vrijednosti';
  @override
  String get templateHelpTitleBody =>
      'Ime pod kojim bi napomena trebala biti kreirana.';
  @override
  String get templateHelpDateBody =>
      'Danas i trenutno vrijeme. Oboje prihvaćaju format: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum i vrijeme zajedno.';
  @override
  String get templateHelpUuidBody =>
      'Novi identifikator, različit na svakoj upotrebi.';
  @override
  String get templateHelpCounterBody =>
      'Broj koji se broji po imenu, čuva se između pokretanja: prva '
      'napomena piše 1, sljedeća 2. Isto ime u napomeni piše isti broj; '
      'spoji s |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Postavi pokazivač ovdje kada se napomena kreira; oznaka se ne '
      'upisuje. Prvi zamjenski znak pobjeđuje, bez filtera, samo nove '
      'napomene — i tipkovnica se otvara i kada je autofokus isključen.';
  @override
  String get templateHelpDatesTitle => 'Pisanje datuma';
  @override
  String get templateHelpDatesBody =>
      'Ovi označavaju dijelove datuma u formatu. Sve ostalo je doslovno, '
      'uključujući tekst u jednostrukim navodnicima. Imena mjeseci i dana u '
      'tjednu prate jezik aplikacije.';
  @override
  String get templateHelpYear => 'godina: 2026, 26';
  @override
  String get templateHelpMonth => 'mjesec: 03, 3, ožujak, ožu';
  @override
  String get templateHelpDay => 'dan: 09, 9, ponedjeljak, pon';
  @override
  String get templateHelpTime => 'sati, minute, sekunde';
  @override
  String get templateHelpWeek => 'ISO tjedan i kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filteri';
  @override
  String get templateHelpFiltersBody =>
      'Vrijednosti mogu slijediti filteri, primjenjuju se slijeva udesno.';
  @override
  String get templateHelpCaseBody =>
      'Velika slova, mala slova i prvo slovo svake riječi — riječ koju si '
      'napisao velikim slovima ostaje takva.';
  @override
  String get templateHelpSlugBody =>
      'Vezi oblik teksta, da se izgradi wikipoveza.';
  @override
  String get templateHelpPadBody =>
      'Izreži krajeve; ispunjavanje nulama do željene širine; alternativa '
      'kada je vrijednost prazna.';
  @override
  String get templateHelpShiftBody =>
      'Pomakni datum za dane, tjedne, mjeseci ili godine — idući tjedan '
      'konferencija, prošlog mjeseca datoteka.';
  @override
  String get templateHelpSnapBody =>
      'Prikvaci datum na početak ili kraj tjedna, mjeseca ili godine.';
  @override
  String get templateHelpAskTitle => 'Pitamo te nešto';
  @override
  String get templateHelpAskBody =>
      'Prije kreiranja napomene prikazuje se obrazac, jedno polje po '
      'pitanju — i jedno za povratnu vezu, ako predložak traži. Isto ime '
      'dvaput je pitanje, a njegov odgovor popunjava sve pojave — i '
      'direktorij i ime datoteke.';
  @override
  String get templateHelpAskFieldBody =>
      'Polje za upis; tekst nakon dvije dvotočke je početak.';
  @override
  String get templateHelpChoiceBody => 'Odabir iz popisa, odvojen zarezom.';
  @override
  String get templateHelpWhereTitle => 'Kamo napomena dolazi';
  @override
  String get templateHelpWhereBody =>
      'Ovo nije tekst: to su upute koje žive u niman: bloku predloškovog '
      'frontmattera. Blok se izvrši i obriše, tako da se nikad ne prikazuje '
      'u napomeni. Vrijednost može sadržavati zamjenske znake.';
  @override
  String get templateHelpFolderBody =>
      'Direktorij u koji se napomena kreira, kreira se ako ne postoji. Bez '
      'njega, napomena dolazi odakle si bio.';
  @override
  String get templateHelpFilenameBody =>
      'Kako se napomena imenuje. Predložak koji to navede, ne pita za ime.';
  @override
  String get templateHelpAppendBody =>
      'Dodaje u napomenu ako već postoji, umjesto da kreira drugu. Tako '
      'mjesec sastanaka postane jedna datoteka.';
  @override
  String get templateHelpOpenBody =>
      'Što se događa kada napomena postoji: uređivač (podrazumijevano), '
      'pregled ili ništa — napomena se arhivira i ostaješ odakle si bio.';
  @override
  String get templateHelpAroundTitle => 'Odakle je došao';
  @override
  String get templateHelpParentBody =>
      'Napomena koju odabereš u obrascu, ponuđena na zaslonu; upiši '
      '[[{{parent}}]] za povratnu vezu.';
  @override
  String get templateHelpFolderValueBody =>
      'Direktorij u kojem napomena dolazi.';
  @override
  String get templateHelpClipboardBody =>
      'Što je na međuspremniku i izbor u uređivaču kada se napomena odande '
      'pokrenula.';
  @override
  String get templateHelpIncludeTitle => 'Ponovna upotreba dijela';
  @override
  String get templateHelpIncludeBody =>
      'Umetni drugi predložak, tako da deset predložaka može podijeliti '
      'jedan kontrolni popis. Pretražuje se prvo u direktoriju predložaka, '
      '.md može se izostaviti. Njegova vlastita pitanja idu u isti obrazac.';
  @override
  String get templateHelpExampleTitle => 'Sve na jednom mjestu';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ne postoji predložak „$path”';
  @override
  String includeCycle(String path) => '⚠ „$path” uključuje sam sebe';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path” je previše duboko ugniježđen';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter nije pročitiv: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter „$template” predloška nije pročitiv, pa direktorij i '
      'ime datoteke nisu ništa učinili: $reason';
  @override
  String get templatePickerTitle => 'Odabir predloška';
  @override
  String templatePickerEmpty(String folder) =>
      'Još nema predložaka. Stavi napomenu u $folder/ i bit će predložak.';

  // Tree actions.
  @override
  String get actionPin => 'Prikvaci';
  @override
  String get actionUnpin => 'Odkvaci';
  @override
  String get movedToTrash => 'Premješteno u korpu';
  @override
  String get deletedMessage => 'Obrisano';
  @override
  String deleteToTrashConfirm(String name) => '$name se premješta u .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name se trajno briše';
  @override
  String get chooseDestination => 'Odaberi odredište';
  @override
  String get libraryRoot => 'Korijen biblioteke';
  @override
  String moveTitle(String name) => 'Premjesti $name';
  @override
  String headingLevelLabel(int level) => 'Naslov razine $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Još nema brze napomene. Odaberi postojeću napomenu ili kreiraj — '
      'brza napomena će se otvoriti ovdje.';
  @override
  String get quickNoteChooseAction => 'Odaberi napomenu…';
  @override
  String get quickNoteCreateAction => 'Kreiraj novu napomenu…';
  @override
  String get quickNoteNewTitle => 'Nova brza napomena';
  @override
  String get quickNotePickerTitle => 'Odabir brze napomene';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Novi direktorij';
  @override
  String get folderPickerEmpty => 'Još nema direktorija';
  @override
  String get listFolderTitle => 'Direktorij popisa';

  // Trash (M1).
  @override
  String get trashEmpty => 'Korpa je prazna';
  @override
  String get trashEmptyAction => 'Isprazni korpu';
  @override
  String get trashEmptyConfirm =>
      'Ovo trajno briše sve što je u korpi, uključujući elemente koje Niman '
      'nije smjestio.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se trajno briše (bez vraćanja)';
  @override
  String get trashDeletePermanently => 'Trajno obriši';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Otvori direktorij Markdown napomena kao biblioteku';
  @override
  String get openLibraryExisting => 'Otvori postojeću';
  @override
  String get openLibraryCreate => 'Kreiraj novu';
  @override
  String get openLibraryCreateTitle => 'Kreiraj novu biblioteku';
  @override
  String get openLibraryFolderName => 'Ime direktorija';
  @override
  String get openLibraryChooseFolder => 'Odaberi direktorij biblioteke';
  @override
  String get openLibraryChooseParent =>
      'Odaberi direktorij u kojem će se kreirati biblioteka';
  @override
  String get openLibraryUnsupported =>
      'Ovaj direktorij nije podržan. Odaberi direktorij iz pohrane '
      'uređaja.';
  @override
  String indexingCount(int done, int total) => '$done / $total napomena';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Tvoje biblioteke';
  @override
  String get libraryUnreachable => 'Nedostupna';
  @override
  String get libraryOpenedToday => 'Otvoreno danas';
  @override
  String get libraryOpenedYesterday => 'Otvoreno jučer';
  @override
  String libraryOpenedDaysAgo(int days) => 'Otvoreno prije $days dana';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Otvoreno ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Otvoreno sada';
  @override
  String get switchLibraryTitle => 'Promijeni biblioteku';
  @override
  String get libraryForget => 'Zaboravi';
  @override
  String libraryForgetTitle(String name) => 'Zaboraviti „$name”?';
  @override
  String get libraryForgetExplained =>
      'Nestaje s ovog popisa. Direktorij, napomene i postavke biblioteke '
      'ostaju netaknuti, a ponovno otvaranje vraća na mjesto.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Odobri pristup datotekama';
  @override
  String get storageAccessNeeded =>
      'Niman ne može čitati tvoje napomene bez „Pristup svim datotekama”. '
      'Odobri ga za otvaranje biblioteke.';
  @override
  String get storageAccessExplained =>
      'Niman čita tvoje napomene kao obične datoteke, pa Android mora dati '
      'pristup svim datotekama. Ništa se ne šalje, a čita se samo direktorij '
      'odabrane biblioteke.';
  @override
  String folderAccessDenied(Object error) =>
      'Sustav nije odobrio pristup direktoriju: $error';
  @override
  String folderPickFailed(Object error) =>
      'Odabir direktorija nije uspio: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Postavke';
  @override
  String get libraryPathTitle => 'Putanje biblioteke';
  @override
  String get reindexTitle => 'Ponovno indeksiraj odmah';
  @override
  String get reindexDone => 'Ponovno indeksiranje završeno';
  @override
  String get closeLibraryTitle => 'Zatvori biblioteku';
  @override
  String get exportLogTitle => 'Izvezi dijagnostički dnevnik';
  @override
  String get exportLogSubtitle =>
      'Spremi zabilježene događaje u datoteku koju odabereš';
  @override
  String get exportLogEmpty => 'Bufers dijagnostičkog dnevnika je prazan';
  @override
  String get quickNoteUnset => 'Nije postavljeno';
  @override
  String exportLogDone(Object target) =>
      'Dijagnostički dnevnik izvezen u $target';
  @override
  String exportLogFailed(Object error) => 'Izvoz nije uspio: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nema točnog rezultata cijele riječi za „$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Zamijenjeno $occurrences pojava „$term” u $notes napomena';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped otvorenih napomena izostavljeno)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nema točnog rezultata cijele riječi za „$term”'
      '${only == null ? '' : ' u $only'}';
}
