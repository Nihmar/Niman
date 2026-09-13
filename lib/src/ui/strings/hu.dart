// The Hungarian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class HungarianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'január',
    'február',
    'március',
    'április',
    'május',
    'június',
    'július',
    'augusztus',
    'szeptember',
    'október',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'febr',
    'márc',
    'ápr',
    'máj',
    'jún',
    'júl',
    'aug',
    'szept',
    'okt',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'hétfő',
    'kedd',
    'szerda',
    'csütörtök',
    'péntek',
    'szombat',
    'vasárnap',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'h',
    'k',
    'sze',
    'cs',
    'p',
    'szo',
    'v',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Kuka';
  @override
  String get trashSubtitle =>
      'A törölt elemek a .trash/ mappába kerülnek (kikapcsolva = végleges '
      'törlés)';
  @override
  String get debugLogsTitle => 'Hibakeresési naplók';
  @override
  String get debugLogsSubtitle =>
      'Az alkalmazás eseményeinek bufferingje a memóriában';
  @override
  String get lineNumbersTitle => 'Sorszámozás';
  @override
  String get lineNumbersSubtitle =>
      'Sorszámok megjelenítése a jegyzet szerkesztőben';
  @override
  String get keyboardOnOpenTitle => 'Billentyűzet megnyitáskor';
  @override
  String get keyboardOnOpenSubtitle =>
      'Billentyűzet megjelenítése a jegyzet megnyitásakor (kikapcsolva = '
      'első érintésre)';
  @override
  String get editorKindSource => 'Markdown forrás';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Előnézet';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'A renderelt jegyzet megjelenítése a forrásszerkesztő mellett';
  @override
  String get switchToWysiwygTooltip => 'Váltás WYSIWYG szerkesztőre';
  @override
  String get switchToSourceTooltip => 'Váltás Markdown forrásra';
  @override
  String get wysiwygTooLarge =>
      'Ez a jegyzet túl nagy a WYSIWYG szerkesztőhöz. Nyisd meg Markdown '
      'forrásként.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Megjelenés';
  @override
  String get settingsSectionEditor => 'Szerkesztő';
  @override
  String get settingsSectionLibrary => 'Könyvtár';
  @override
  String get settingsSectionReminders => 'Emlékeztetők';
  @override
  String get settingsSectionShortcuts => 'Billentyűzet';
  @override
  String get keyboardShortcutsTitle => 'Billentyűparancsok';
  @override
  String get settingsSectionDiagnostics => 'Diagnosztika';
  @override
  String get settingsSpellCheckTitle => 'Helyesírásellenőrzés';
  @override
  String get settingsSpellCheckSubtitle =>
      'A helyesírási hibák aláhúzása írás közben.';
  @override
  String get spellCheckDictionaryTitle => 'Szótár';
  @override
  String get spellCheckDictionarySystem => 'Rendszer alapértelmezése';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Szótárválasztás';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Válaszd ki az összes nyelvet, amelyben a könyvtár íródott. Ha egy '
      'kiválasztott szótár ismeri, a szó átmegy; kiválasztás nélkül a '
      'rendszer nyelve dönt.';
  @override
  String get spellCheckNoDictionaries =>
      'Nem található szótár ezen a rendszeren.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Helyesírásellenőrzés';
  @override
  String get spellCheckTitle => 'Helyesírás';
  @override
  String get spellCheckEmpty => 'Nincs helyesírási hiba.';
  @override
  String get spellCheckUnavailable =>
      'A hunspell nincs telepítve ezen a rendszeren.';
  @override
  String get spellCheckNoSuggestions => 'Nincs javaslat';
  @override
  String spellCheckCount(int count) => '$count ellenőrizendő';
  @override
  String spellCheckLine(int line) => '$line. sor';

  @override
  String indentWidthValue(int spaces) => '$spaces szóköz';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Világosság';
  @override
  String get themeBrightnessSubtitle =>
      'Világos, sötét vagy a készülék beállítása';
  @override
  String get themeBrightnessSystem => 'Rendszer';
  @override
  String get themeBrightnessDay => 'Világos';
  @override
  String get themeBrightnessNight => 'Sötét';
  @override
  String get themePaletteTitle => 'Színpaletta';
  @override
  String get themePaletteSubtitle => 'A felület és a jegyzet színei';
  @override
  String get themePaletteSystem => 'Rendszer';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Felületi szövegméret';
  @override
  String get uiTextScaleSubtitle =>
      'Fák, fülek, dialógusok; a rendszer beállítása fölé';
  @override
  String get noteTextScaleTitle => 'Jegyzet szövegmérete';
  @override
  String get noteTextScaleSubtitle =>
      'A szerkesztő és az előnézet mindig azonos';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Előnézeti mód';
  @override
  String get previewModeSubtitle =>
      'Hogy az előnézet megosztja-e a képernyőt a szerkesztővel, vagy '
      'lecseréli';
  @override
  String get previewModeAuto => 'Mellette';
  @override
  String get previewModeSwitch => 'Teljes képernyő';
  @override
  String get splitRatioTitle => 'Osztási arány szélessége';
  @override
  String get splitRatioSubtitle =>
      'A szerkesztő aránya, amikor az előnézet mellette van';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Hivatkozás formátuma';
  @override
  String get linkTypeSubtitle => 'Mit ír a hivatkozás gomb a szerkesztőbe';
  @override
  String get linkTypeWikilink => 'Wikihivatkozás';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Behúzás szélessége';
  @override
  String get indentWidthSubtitle =>
      'A szerkesztőben egy-egy behúzási szintre hozzáadott szóközök száma';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Nyelv';
  @override
  String get languageSubtitle => 'Az alkalmazás saját szövegének nyelve';
  @override
  String get languageSystem => 'Rendszer';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Elem hozzáadása';
  @override
  String get listAddTooltip => 'Elem hozzáadása';
  @override
  String get listEmpty => 'Nincs elem';
  @override
  String get listDragHandleLabel => 'Elem sorrendjének módosítása';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Gyorsjegyzet';
  @override
  String get shortcutNewTodo => 'Új feladat';
  @override
  String get shortcutNewNote => 'Új jegyzet';
  @override
  String get shortcutNewList => 'Új lista';
  @override
  String get shortcutToggleSidebar => 'Szűrő megjelenítése vagy elrejtése';
  @override
  String get shortcutEditorSection => 'A szerkesztőben';
  @override
  String get shortcutFind => 'Keresés';
  @override
  String get shortcutReplace => 'Keresés és csere';
  @override
  String get shortcutSavingNote =>
      'A módosítások automatikusan elmentődnek, így nincs mentés parancs.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Struktúra';
  @override
  String get outlineNoHeadings => 'Nincs címsor';
  @override
  String get outlineNoTitle => '(nincs cím)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Félkövér';
  @override
  String get toolbarItalic => 'Dőlt';
  @override
  String get toolbarStrikethrough => 'Áthúzott';
  @override
  String get toolbarSuperscript => 'Felírott';
  @override
  String get toolbarUnderline => 'Aláhúzott';
  @override
  String get toolbarLink => 'Hivatkozás';
  @override
  String get toolbarCode => 'Kódblokk';
  @override
  String get toolbarImage => 'Kép beszúrása';
  @override
  String get toolbarHeading => 'Cím';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Számozott lista';
  @override
  String get toolbarQuote => 'Idézet';
  @override
  String get toolbarIndent => 'Behúzás';
  @override
  String get toolbarOutdent => 'Kibeszúzás';
  @override
  String get headingDialogTitle => 'Címszint';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Szerkesztő eszköztársa';
  @override
  String get toolbarSettingsHint =>
      'Húzd a sorrend módosításához; a szem ikon mutat vagy rejt egy '
      'gombot.';
  @override
  String get toolbarShowButton => 'Megjelenítés';
  @override
  String get toolbarHideButton => 'Elrejtés';
  @override
  String get toolbarResetOrder => 'Visszaállítás alapértelmezettre';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Előnézet megjelenítése';
  @override
  String get showEditorTooltip => 'Szerkesztő megjelenítése';
  @override
  String get enterFullScreenTooltip => 'Teljes képernyő';
  @override
  String get exitFullScreenTooltip => 'Kilépés teljes képernyőből';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(nyers HTML táblázat)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Keresés a jegyzetekben';
  @override
  String get searchModeWords => 'Szavak';
  @override
  String get searchModeContains => 'Tartalmaz';
  @override
  String get searchEmptyHint =>
      'Írj valamit a könyvtár kereséséhez, vagy kulcs = érték a frontmatter '
      'szerinti szűréshez';
  @override
  String get searchTooShortHint => 'Írd be legalább 2 jelet';
  @override
  String get searchNoMatches => 'Nincs találat';
  @override
  String get searchLoadMore => 'Több megjelenítése';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Csere…';
  @override
  String get replaceInNoteAction => 'Csere ebben a jegyzetben…';
  @override
  String get replaceInThisNote => 'Csere ebben a jegyzetben';
  @override
  String get replaceWithLabel => 'Erre cserél';
  @override
  String get replaceCaseSensitive => 'Nagy és kisbetűk megkülönböztetése';
  @override
  String get replaceWholeWordsHint =>
      'csak a pontos, teljes szó találatok cserélődnek';
  @override
  String get replaceConfirm => 'Csere';
  @override
  String get replaceCancel => 'Bezárás';
  @override
  String get replaceUnavailable => 'A cserélés most nem érhető el';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Keresés a jegyzetben';
  @override
  String get editorFindHint => 'Keresés';
  @override
  String get editorReplaceHint => 'Csere';
  @override
  String get editorFindCaseTooltip => 'Nagy és kisbetűk megkülönböztetése';
  @override
  String get editorFindPreviousTooltip => 'Előző találat';
  @override
  String get editorFindNextTooltip => 'Következő találat';
  @override
  String get editorFindCloseTooltip => 'Keresés bezárása';
  @override
  String get editorFindReplaceModeTooltip => 'Csere mód';
  @override
  String get editorReplaceOneTooltip => 'Ez a találat cserélése';
  @override
  String get editorReplaceAllTooltip => 'Minden találat cserélése';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Címkék';
  @override
  String get tagsTitle => 'Címkék';
  @override
  String get tagsEmpty =>
      'Még nincs címke — adj hozzá egy #címkét, vagy címkéket a frontmatterbe';
  @override
  String get tagsBackTooltip => 'Vissza a kereséshez';
  @override
  String get tagsNotesEmpty => 'Nincs jegyzet ezzel a címkével';
  @override
  String tagsNotesCapped(int limit) =>
      'Csak az első $limit jelenik meg — a címkére keress a korlátozáshoz';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'A hivatkozás nem található';
  @override
  String get headingNotFoundTitle => 'A cím nem található';
  @override
  String get ambiguousLinkTitle => 'Több jegyzet is egyezik';
  @override
  String get openLinkFailed => 'A hivatkozás nem nyitható meg';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Nyitottak';
  @override
  String get todoDone => 'Kész';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Minden dátum';
  @override
  String get todoFilter => 'Szűrés';
  @override
  String get todoNoTokens => 'Nincs token ezen a listán';
  @override
  String get todoCountOpen => 'nyitott';
  @override
  String get todoCountDone => 'kész';
  @override
  String get todoEmptyOpen => 'Még nincs nyitott feladat';
  @override
  String get todoEmptyDone => 'Még nincs kész';
  @override
  String get todoEmptyFiltered => 'Nincs illeszkedő feladat';
  @override
  String get todoTitle => 'Teendők';
  @override
  String get todoAddTooltip => 'Feladat hozzáadása';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt formátum';
  @override
  String get todoHelpTooltip => 'Formátum ismertető';
  @override
  String get todoHelpIntro =>
      'A feladataid egy sima szöveges fájl, egy feladat soronként. A Niman a '
      'szintaxisért ír neked, de nem rejti el semmit: bármilyen szerkesztőben '
      'szerkesztheted a fájlt, és a Niman újból elolvassa.';
  @override
  String get todoHelpFilesTitle => 'A két fájl';
  @override
  String get todoHelpFilesBody =>
      'A nyitott feladatok a könyvtár gyökerében lévő todo.txt-ben élnek. '
      'Ha készre jelölsz egyet, a sor a done.txt-be kerül, így a todo.txt '
      'rövid marad. Ha egy kész sor újra a todo.txt-be kerül, a Niman a '
      'következő fájlolvasáskor archiválja.';
  @override
  String get todoHelpLineTitle => 'Egy sor felépítése';
  @override
  String get todoHelpLineBody =>
      'A leírás előtti minden elem opcionális, és ebben a sorrendben kell, '
      'hogy következzen:';
  @override
  String get todoHelpDoneBody =>
      'Készre jelöli a feladatot. A Niman ezt adja hozzá, amikor bejelölöd '
      'a jelölőnégyzetet.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritás. Az A a legmagasabb. Képként jelenik meg a listában.';
  @override
  String get todoHelpDatesBody =>
      'Esedékes dátum, aztán a létrehozás dátuma. Egy dátum esetén az a '
      'létrehozás dátuma, hacsak nem x-sel kezdődik a sor.';
  @override
  String get todoHelpTokensTitle => 'Projektek, kontextusok és címkék';
  @override
  String get todoHelpTokensBody =>
      'A leírásban bármelyik előtaggal kezdődő szó szűrhető címkévé válik. '
      'Semmi nem van előre definiálva: a token létezik, amíg te írod.';
  @override
  String get todoHelpProjectBody =>
      'Melyik projekthez tartozik a feladat, például +konyha vagy +munka.';
  @override
  String get todoHelpContextBody =>
      'Hol vagy hogyan teszed, például @otthon vagy @találkozások.';
  @override
  String get todoHelpHashtagBody =>
      'Szabad címke, amire a másik kettő nem illeszkedik.';
  @override
  String get todoHelpTagsTitle => 'Dátumok és emlékeztetők';
  @override
  String get todoHelpTagsBody =>
      'Ezek kulcs:érték jelölések. A Niman a feladat dialógusból írja őket, '
      'és a sorban bármelyik helyen elolvassa őket.';
  @override
  String get todoHelpDueBody =>
      'Esedékesség. A jelvény színét és a dátumszűrőket uralja.';
  @override
  String get todoHelpRemBody =>
      'Amikor kellene küldeni az értesítést, a helyi időzónádban. Ekkor '
      'cseng, amikor a képernyő ki van kapcsolva és az alkalmazás bezárva '
      'van.';
  @override
  String get todoHelpRemDesktop =>
      'Asztali gépen a Nimanon futnia kell, amikor eljön az idő: az '
      'emlékeztető akkor jelenik meg, amikor az alkalmazás nyitva van, és '
      'semmi sem történik, amikor bezárva van.';
  @override
  String get todoHelpOtherBody =>
      'Pontosan úgy őrződik, ahogy megírták, így más todo.txt alkalmazások '
      'jelöléseit az utazás során is élve hagyják. A Niman nem használja '
      'őket, rec: included: az ismétlődő feladat még nem ismétlődik.';
  @override
  String get todoHelpEditTitle => 'Szerkesztés a Nimanon kívül';
  @override
  String get todoHelpEditBody =>
      'A feladat, amit nem érintesz, byte-nként újraíródik, a furcsa '
      'szóközök is. Ha szerkesztesz egy sort, a Niman csak azt a sort írja '
      'újra a saját kanonikus formában, a fájl többi részét érintetlenül '
      'hagyja.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Feladat hozzáadása';
  @override
  String get todoEditTitle => 'Feladat szerkesztése';
  @override
  String get todoDescriptionHint => 'Leírás';
  @override
  String get todoCancel => 'Mégse';
  @override
  String get todoSave => 'Mentés';
  @override
  String get todoEditAction => 'Szerkesztés';
  @override
  String get todoDeleteAction => 'Törlés';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Lejárt';
  @override
  String get todoDueToday => 'Ma';
  @override
  String get todoDueNext7 => 'Következő 7 nap';
  @override
  String get todoDueNoDate => 'Nincs dátum';
  @override
  String get todoRowDue => 'Esedékesség';
  @override
  String get todoRowDueToday => 'Ma esedékes';
  @override
  String get todoSortTooltip => 'Rendezés';
  @override
  String get todoSortDue => 'Esedékes dátum';
  @override
  String get todoSortPriority => 'Prioritás';
  @override
  String get todoSortCreation => 'Létrehozás dátuma';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Nincs prioritás';
  @override
  String get todoNoPriorityShort => 'Nincs';
  @override
  String get todoMorePriorities => 'Több…';
  @override
  String get todoPriorityTitle => 'Prioritás';
  @override
  String get todoNoDueDate => 'Nincs esedékesség';
  @override
  String get todoNoReminder => 'Nincs emlékeztető';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontextus';
  @override
  String get todoAddHashtag => '# Címke';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Feladatemlékeztetők';
  @override
  String get todoReminderChannelDescription =>
      'Ütemezett értesítések emlékeztetőidős feladatokhoz.';
  @override
  String get todoReminderBody => 'Feladatemlékeztető';
  @override
  String get todoReminderFallbackTitle => 'Feladatemlékeztető';
  @override
  String get todoReminderBlocked =>
      'Az értesítések kikapcsolva vannak, így az emlékeztetők nem jelennek '
      'meg.';
  @override
  String get todoReminderBattery =>
      'A Nimanon aktiválva van az akkumulátoroptimalizálás. A rendszer '
      'felfüggesztheti az alkalmazást, és elveszítheti a várakozó '
      'emlékeztetőket.';
  @override
  String get todoReminderInexact =>
      'Ez a készülék nem támogatja a pontos riasztásokat, így az '
      'emlékeztető néhány perccel később jöhet, amikor a képernyő ki van '
      'kapcsolva.';
  @override
  String get reminderShowTokensTitle => 'Címkék az emlékeztető értesítésekben';
  @override
  String get reminderShowTokensSubtitle =>
      'Hagyja a +projekt, @kontextus és #címke szöveget az értesítésben. '
      'Kikapcsolva csak a megírt feladatot jeleníti.';
  @override
  String get todoReminderFixAction => 'Beállítások megnyitása';
  @override
  String get todoReminderDismissAction => 'Elvetés';
  @override
  String get todoReminderDue => 'Esedékesség';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Mégse';
  @override
  String get actionCreate => 'Létrehozás';
  @override
  String get actionNew => 'Új';
  @override
  String get actionSave => 'Mentés';
  @override
  String get actionClear => 'Törlés';
  @override
  String get actionChoose => 'Választás';
  @override
  String get actionDelete => 'Törlés';
  @override
  String get actionRename => 'Átnevezés';
  @override
  String get actionMove => 'Áthelyezés';
  @override
  String get saveAndClose => 'Mentés és bezárás';
  @override
  String get closeUnsavedTitle => 'Nem mentett módosítások';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” nem mentett módosításokkal rendelkezik. '
          'Kimentjük bezárás előtt?';
    }
    return '${names.length} jegyzet nem mentett módosításokkal '
        'rendelkezik. Kimentjük bezárás előtt?';
  }

  @override
  String get closeSaveFailed => 'A mentés sikertelen; a jegyzet nyitva marad.';
  @override
  String get actionRestore => 'Visszaállítás';
  @override
  String get actionEmpty => 'Üresítés';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Oldalsó sáv elrejtése (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Oldalsó sáv megjelenítése (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Kicsinyítés';
  @override
  String get windowMaximizeTooltip => 'Nagyítás';
  @override
  String get windowRestoreTooltip => 'Visszaállítás';
  @override
  String get windowCloseTooltip => 'Bezárás';
  @override
  String get tabFiles => 'Fájlok';
  @override
  String get tabSearch => 'Keresés';
  @override
  String get tabSettings => 'Beállítások';
  @override
  String get quickNoteTitle => 'Gyorsjegyzet';
  @override
  String get treeEmpty => 'Még nincs jegyzet';
  @override
  String get selectANote => 'Jegyzet kiválasztása';
  @override
  String get showListTooltip => 'Lista megjelenítése';
  @override
  String get editRawTooltip => 'Nyers szerkesztés';
  @override
  String get sortAscTooltip => 'Rendezés A–Z';
  @override
  String get sortDescTooltip => 'Rendezés Z–A';
  @override
  String get newNoteTitle => 'Új jegyzet';
  @override
  String get newFolderTitle => 'Új mappa';
  @override
  String get newNoteHere => 'Új jegyzet ide';
  @override
  String get newFolderHere => 'Új mappa ide';
  @override
  String get newListNoteTitle => 'Új listajegyzet';
  @override
  String get newListNoteDefault => 'A listám';
  @override
  String get setAsQuickNote => 'Beállítás gyorsjegyzetnek';
  @override
  String get currentQuickNote => 'Jelenlegi gyorsjegyzet';
  @override
  String get pinnedSection => 'Rögzített';
  @override
  String pinnedSectionCount(int count) => 'Rögzített · $count';
  @override
  String get templateFolderTitle => 'Sablonmappa';
  @override
  String get newFromTemplateTitle => 'Új sablonból';
  @override
  String get newFromTemplateHere => 'Új sablonból ide';
  @override
  String get templateFormTitle => 'Sablon kitöltése';
  @override
  String get templateFormBacklink => 'Visszahivatkozás';
  @override
  String get templateFormNoNote => 'Nincs jegyzet';
  @override
  String get templateFormPickNote => 'Jegyzet kiválasztása';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Sablon helyőrzők';
  @override
  String get templateHelpIntro =>
      'A sablon egy sima jegyzet lyukakkal. A jegyzet onnan való létrehozása '
      'a szöveget másolja, és kitölti a lyukakat.';
  @override
  String get templateHelpUnknown =>
      'A Niman által nem ismert helyőrző pontosan úgy marad, ahogy megírták, '
      'így a billentyűzet hiba a jegyzetben jelenik meg, nem pedig csendben '
      'egy sort tör.';
  @override
  String get templateHelpValuesTitle => 'Értékek';
  @override
  String get templateHelpTitleBody =>
      'A név, amelyik néven a jegyzet létrehozandó.';
  @override
  String get templateHelpDateBody =>
      'Ma és a jelenlegi idő. Mindkettő elfogad formátumot: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Dátum és idő együtt.';
  @override
  String get templateHelpUuidBody =>
      'Új azonosító, minden használatnál eltérő.';
  @override
  String get templateHelpCounterBody =>
      'Egy szám, amit név szerint számol, indítások között megőrződik: az '
      'első jegyzet 1-et ír, a következő 2-t. Ugyanez a név egy jegyzetben '
      'ugyanazt a számot írja; párosítsd |pad:3-mal.';
  @override
  String get templateHelpCursorBody =>
      'Ide állítsd a kurzort, amikor a jegyzet létrehozódik; a jelölőt nem '
      'írják be. Az első jelölő nyer, szűrők nélkül, csak új jegyzeteken — '
      'és a billentyűzet akkor is megnyílik, ha az autofókusz letiltva.';
  @override
  String get templateHelpDatesTitle => 'Dátum írása';
  @override
  String get templateHelpDatesBody =>
      'Ezek a dátum részeit jelentik egy formátumban. Minden más betű, így '
      'az egybesimás jelek szövege is. A hónapok és a hét napjai nevei '
      'követik az alkalmazás nyelvét.';
  @override
  String get templateHelpYear => 'év: 2026, 26';
  @override
  String get templateHelpMonth => 'hónap: 03, 3, március, már';
  @override
  String get templateHelpDay => 'nap: 09, 9, hétfő, h';
  @override
  String get templateHelpTime => 'órák, percek, másodpercek';
  @override
  String get templateHelpWeek => 'ISO hét és negyedév: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Szűrők';
  @override
  String get templateHelpFiltersBody =>
      'Az értéket szűrők követik, balról jobbra alkalmazva.';
  @override
  String get templateHelpCaseBody =>
      'Nagybetű, kisbetű és minden szó első betűje — egy szó, amit nagybetűvel '
      'írtál, nem változik.';
  @override
  String get templateHelpSlugBody =>
      'A szöveg hivatkozási formája, wikihivatkozás készítéséhez.';
  @override
  String get templateHelpPadBody =>
      'Vágd le a végeket; töltse ki nullákkal a kívánt szélességig; '
      'alternatíva használata, ha az érték üres.';
  @override
  String get templateHelpShiftBody =>
      'Dátum eltolása nap, hét, hónap vagy évvel — a jövő heti konferencia, '
      'a múlt hónap fájlja.';
  @override
  String get templateHelpSnapBody =>
      'Dátum rögzítése a hét, a hónap vagy az év elején vagy végén.';
  @override
  String get templateHelpAskTitle => 'Kérdezünk tőled valamit';
  @override
  String get templateHelpAskBody =>
      'A jegyzet létrehozása előtt űrlap jelenik meg, egy mező '
      'kérdésenként — és egy a visszahivatkozáshoz, ha a sablon megkívánja. '
      'Ugyanez a címke kétszer egy kérdés, és a válasza kitölti az összes '
      'előfordulást — a mappát és a fájlnevet is.';
  @override
  String get templateHelpAskFieldBody =>
      'Írásmező; a második kettőspont utáni szöveg az eleje.';
  @override
  String get templateHelpChoiceBody =>
      'Választás listából, vesszővel elválasztva.';
  @override
  String get templateHelpWhereTitle => 'Hová kerül a jegyzet';
  @override
  String get templateHelpWhereBody =>
      'Ezek nem szöveg: utasítások, a sablon saját frontmatterében lévő '
      'niman: blokkban élnek. A blokk fut, és törölődik, így soha nem '
      'jelenik meg a jegyzetben. Az értéke lehet helyőrző.';
  @override
  String get templateHelpFolderBody =>
      'A mappa, amelybe a jegyzet létrehozódik, létrehozásra, ha nincs. '
      'Enélkül a jegyzet oda kerül, ahol voltál.';
  @override
  String get templateHelpFilenameBody =>
      'Milyen névvel rendelkezik a jegyzet. A sablon, amely ezt mondja, nem '
      'kér név.';
  @override
  String get templateHelpAppendBody =>
      'Ha már létezik, a jegyzethez fűzi, nem pedig újat hoz létre. Így egy '
      'hónap tárgyalás egy fájl lesz.';
  @override
  String get templateHelpOpenBody =>
      'Mi történik, ha a jegyzet létezik: szerkesztő (alapértelmezett), '
      'előnézet, vagy semmi — a jegyzet archiválódik, és ahol voltál, ott '
      'maradsz.';
  @override
  String get templateHelpAroundTitle => 'Honnan jött';
  @override
  String get templateHelpParentBody =>
      'A jegyzet, amelyet az űrlapban választasz, képernyőn nyújtva; írd be '
      '[[{{parent}}]]-t visszahivatkozásként.';
  @override
  String get templateHelpFolderValueBody =>
      'A mappa, amelybe a jegyzet került.';
  @override
  String get templateHelpClipboardBody =>
      'Amit a vágólap tart, és a szerkesztő kijelölése, amikor a jegyzet '
      'onnan indult.';
  @override
  String get templateHelpIncludeTitle => 'Egy rész újrafelhasználása';
  @override
  String get templateHelpIncludeBody =>
      'Más sablon beillesztése, hogy tíz sablon megosszon egy '
      'ellenőrzőlistát. Először a sablonmappában keres, a .md kihagyható. '
      'A saját kérdései ugyanabba az űrlapba kerülnek.';
  @override
  String get templateHelpExampleTitle => 'Mind egyben';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nincs „$path” sablon';
  @override
  String includeCycle(String path) => '⚠ „$path” magába illeszt';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path” túl mélyen egymásba illesztve';
  @override
  String frontmatterInvalid(String reason) =>
      'A frontmatter nem olvasható: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'A „$template” sablon frontmatterje nem olvasható, így a mappát és a '
      'fájlnevet nem tette semmivel: $reason';
  @override
  String get templatePickerTitle => 'Sablonválasztó';
  @override
  String templatePickerEmpty(String folder) =>
      'Még nincs sablon. Helyezzen egy jegyzetet a $folder/ mappába, és az '
      'lesz.';

  // Tree actions.
  @override
  String get actionPin => 'Rögzítés';
  @override
  String get actionUnpin => 'Rögzítés feloldása';
  @override
  String get movedToTrash => 'A kukába került';
  @override
  String get deletedMessage => 'Törölve';
  @override
  String deleteToTrashConfirm(String name) => '$name a .trash/ mappába kerül';
  @override
  String deleteForeverConfirm(String name) => '$name véglegesen törlődik';
  @override
  String get chooseDestination => 'Cél kiválasztása';
  @override
  String get libraryRoot => 'A könyvtár gyökere';
  @override
  String moveTitle(String name) => '$name áthelyezése';
  @override
  String headingLevelLabel(int level) => '$level. szintű cím';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Még nincs gyorsjegyzet. Válassz egy meglévő jegyzetet, vagy hozz '
      'létre egyet — a gyorsjegyzet itt nyílik meg.';
  @override
  String get quickNoteChooseAction => 'Jegyzet kiválasztása…';
  @override
  String get quickNoteCreateAction => 'Új jegyzet létrehozása…';
  @override
  String get quickNoteNewTitle => 'Új gyorsjegyzet';
  @override
  String get quickNotePickerTitle => 'Gyorsjegyzet-választó';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Új mappa';
  @override
  String get folderPickerEmpty => 'Még nincs mappa';
  @override
  String get listFolderTitle => 'Listamappa';

  // Trash (M1).
  @override
  String get trashEmpty => 'A kuka üres';
  @override
  String get trashEmptyAction => 'Kuka kiürítése';
  @override
  String get trashEmptyConfirm =>
      'Ez véglegesen törli mindazt, ami a kukában van, ideértve azokat az '
      'elemeket is, amelyeket a Niman nem rakott ide.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name véglegesen törlődik (visszaállítás nélkül)';
  @override
  String get trashDeletePermanently => 'Végleges törlés';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Nyissa meg a Markdown jegyzetek mappáját könyvtárként';
  @override
  String get openLibraryExisting => 'Meglévő megnyitása';
  @override
  String get openLibraryCreate => 'Új létrehozása';
  @override
  String get openLibraryCreateTitle => 'Új könyvtár létrehozása';
  @override
  String get openLibraryFolderName => 'A mappa neve';
  @override
  String get openLibraryChooseFolder => 'A könyvtár mappájának kiválasztása';
  @override
  String get openLibraryChooseParent =>
      'A mappa kiválasztása, amelybe a könyvtár létrehozandó';
  @override
  String get openLibraryUnsupported =>
      'Ez a mappa nem támogatja. Válassz mappát a készülék tárolóhelyéből.';
  @override
  String indexingCount(int done, int total) => '$done / $total jegyzet';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'A könyvtáraid';
  @override
  String get libraryUnreachable => 'Nem érhető el';
  @override
  String get libraryOpenedToday => 'Ma nyitott';
  @override
  String get libraryOpenedYesterday => 'Tegnap nyitott';
  @override
  String libraryOpenedDaysAgo(int days) => '$days napja ezelőtt nyitott';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Nyitva ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Most nyitva';
  @override
  String get switchLibraryTitle => 'Könyvtár váltása';
  @override
  String get libraryForget => 'Elfelejtés';
  @override
  String libraryForgetTitle(String name) => 'Elfelejtjük: „$name”?';
  @override
  String get libraryForgetExplained =>
      'Ez a listáról eltűnik. A könyvtár mappája, jegyzetei és beállításai '
      'érintetlenül maradnak, az újra megnyitás visszaállítja.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Fájlhozzáférés megadása';
  @override
  String get storageAccessNeeded =>
      'A Niman nem tudja olvasni a jegyzeteidet „Minden fájlhoz hozzáférés” '
      'nélkül. Adja meg a könyvtár megnyitásához.';
  @override
  String get storageAccessExplained =>
      'A Niman a jegyzeteidet sima fájlokként olvassa, így az Androidnak meg '
      'kell adnia neki minden fájlhoz való hozzáférést. Semmit nem küldünk, '
      'és csak a kiválasztott könyvtár mappáját olvassuk.';
  @override
  String folderAccessDenied(Object error) =>
      'A rendszer nem adta meg a mappa hozzáférését: $error';
  @override
  String folderPickFailed(Object error) =>
      'A mappa kiválasztása nem sikerült: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Beállítások';
  @override
  String get libraryPathTitle => 'A könyvtár útvonala';
  @override
  String get reindexTitle => 'Újra indexelés most';
  @override
  String get reindexDone => 'Újra indexelés kész';
  @override
  String get closeLibraryTitle => 'Könyvtár bezárása';
  @override
  String get exportLogTitle => 'Hibakeresési napló exportálása';
  @override
  String get exportLogSubtitle =>
      'A naplózott események mentése egy fájlba, amelyet kiválasztasz';
  @override
  String get exportLogEmpty => 'A hibakeresési napló bufferje üres';
  @override
  String get quickNoteUnset => 'Nincs beállítva';
  @override
  String exportLogDone(Object target) =>
      'A hibakeresési napló ide exportálva: $target';
  @override
  String exportLogFailed(Object error) => 'Az exportálás nem sikerült: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nincs pontos, teljes szó találat a „$term” esetén';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences „$term” előfordulás csere $notes jegyzetben';
  @override
  String replaceSkipped(int skipped) => ' ($skipped nyitott jegyzet kihagyva)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nincs pontos, teljes szó találat a „$term” esetén'
      '${only == null ? '' : ' a $only-ban'}';
}
