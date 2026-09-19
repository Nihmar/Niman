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
  String get trashAutoEmptyTitle => 'Kuka automatikus ürítése';
  @override
  String get trashAutoEmptySubtitle =>
      'A régebbi törlések véglegesen eltűnnek a könyvtár megnyitásakor';
  @override
  String trashAutoEmptyValue(int days) => days == 0 ? 'Soha' : '$days nap';
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
  String get readableLineLengthTitle => 'Olvasható sorhossz';
  @override
  String get readableLineLengthSubtitle =>
      'A jegyzet szövege középre igazított oszlopban maradjon az ablak teljes '
      'szélessége helyett';
  @override
  String get noteColumnWidthTitle => 'Oszlopszélesség';
  @override
  String get noteColumnWidthSubtitle =>
      'Milyen széles a jegyzet oszlopa, pixelben';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
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
  String get editorKindSourceSubtitle => 'Markdown-forrás, ahogy írva van';
  @override
  String get editorKindWysiwygSubtitle =>
      'Formázott szöveg, helyben szerkesztve';
  @override
  String get settingsFolderToCreate => 'létrehozandó';
  @override
  String get settingsSearchHint => 'Keresés a beállításokban';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 beállítás található' : '$count beállítás található';
  @override
  String get settingsToggleOn => 'Be';
  @override
  String get settingsToggleOff => 'Ki';
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
  String get switchToSourceLabel => 'Forrás';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Könyvtár $name';
  @override
  String get settingsGroupLibraryHint => 'csak ehhez a könyvtárhoz van';
  @override
  String get settingsGroupMaintenance => 'Karbantartás';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mappák és útvonalak';
  @override
  String get settingsAreaTrashHistory => 'Kuka és kronológia';
  @override
  String get settingsAreaDiagnostics => 'Diagnosztika és infó';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Csatlakoztatott fizikai billentyűzet szükséges';
  @override
  String get settingsSectionUpdates => 'Frissítések';
  @override
  String get autoUpdateTitle => 'Automatikus frissítések';
  @override
  String get autoUpdateSubtitle =>
      'GitHub Releases ellenőrzése indításkor és 6 óránként';
  @override
  String get checkForUpdatesTitle => 'Frissítések keresése';
  @override
  String updateAvailableMessage(Object version) => 'Elérhető a Niman $version';
  @override
  String get updateUpToDate => 'A Niman naprakész';
  @override
  String get updateCheckFailed => 'A frissítések ellenőrzése nem sikerült';
  @override
  String updateSavedTo(Object path) => 'Frissítés mentve ide: $path';
  @override
  String get updateInstallerStarted => 'A telepítő elindult';
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
  String get addWordToDictionary => 'Hozzáadás a szótárhoz';

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
  String get missingNoteLocationTitle => 'Hiányzó jegyzetek létrehozása';
  @override
  String get missingNoteLocationRoot => 'A könyvtár gyökerében';
  @override
  String get missingNoteLocationCurrentFolder => 'A jelenlegi mappában';
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

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Még nincs felvétel';
  @override
  String get audioRecord => 'Felvétel';
  @override
  String get audioStop => 'Leállítás';
  @override
  String get audioPlay => 'Lejátszás';
  @override
  String get audioDelete => 'Felvétel törlése';
  @override
  String get audioImport => 'Hangfájl importálása';
  @override
  String get audioRecording => 'Felvétel folyamatban…';
  @override
  String get audioPermissionDenied =>
      'Mikrofonhozzáférés megtagadva — a felvételhez szükséges.';
  @override
  String get newAudioNoteTitle => 'Új hangjegyzet';
  @override
  String get newAudioNoteDefault => 'A felvételem';
  @override
  String get showAudioTooltip => 'Felvételek megjelenítése';
  @override
  String get audioMessageHint => 'Írj egy jegyzetet…';
  @override
  String get audioSend => 'Küldés';
  @override
  String get audioRename => 'Felvétel átnevezése';
  @override
  String get audioDescriptionHint => 'Írd le ezt a felvételt…';
  @override
  String get audioEditDescription => 'Leírás szerkesztése';
  @override
  String get audioDeleteNote => 'Jegyzet törlése';
  @override
  String get audioEditNote => 'Jegyzet szerkesztése';
  @override
  String get audioPause => 'Szünet';
  @override
  String get audioEditTitle => 'Cím szerkesztése';
  @override
  String get audioTitleHint => 'A felvétel címe…';
  @override
  String audioUntitled(int n) => '$n. felvétel';
  @override
  String get audioMoreActions => 'További műveletek';
  @override
  String get audioDiscardRecording => 'Felvétel elvetése';
  @override
  String get audioPauseRecording => 'Felvétel szüneteltetése';
  @override
  String get audioResumeRecording => 'Felvétel folytatása';
  @override
  String get audioRecordingPaused => 'Szüneteltetve';
  @override
  String get audioSavingRecording => 'Mentés…';

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
  String get shortcutNewAudio => 'Új hangjegyzet';
  @override
  String get shortcutToggleSidebar => 'Szűrő megjelenítése vagy elrejtése';
  @override
  String get shortcutCloseTab => 'Az aktuális jegyzet bezárása';
  @override
  String get shortcutNextTab => 'Következő megnyitott jegyzet';
  @override
  String get shortcutPreviousTab => 'Előző megnyitott jegyzet';
  @override
  String get shortcutEditorSection => 'A szerkesztőben';
  @override
  String get shortcutFormatSection => 'Formázás';
  @override
  String get shortcutFind => 'Keresés';
  @override
  String get shortcutReplace => 'Keresés és csere';
  @override
  String get shortcutSavingNote =>
      'A módosítások automatikusan elmentődnek, így nincs mentés parancs.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Betöltés…';
  @override
  String get noteStatusSaving => 'Mentés…';
  @override
  String get noteStatusUnsaved => 'Nincs mentve';
  @override
  String get noteStatusSaved => 'Mentve';
  @override
  String get noteStatusError => 'Hiba';
  @override
  String get noteNotText =>
      'Ez a fájl nem szöveges jegyzet, ezért a '
      'Niman itt nem tudja megjeleníteni.';
  @override
  String get noteLoadFailed => 'Ezt a jegyzetet nem sikerült megnyitni.';
  @override
  String wordCount(int count) => '$count szó';
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

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Eszközök';
  @override
  String get editorToolsTitle => 'Szerkesztő eszközei';
  @override
  String get toolCountListTitle => 'Lista megszámlálása';
  @override
  String get toolCountListSubtitle =>
      'Összesíti, amit a sorok felsorolnak, jelölőlistaként';
  @override
  String get toolCountListNeedsList =>
      'Ebben a jegyzetben nincs megszámlálható lista';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Minden sor olvasása így';
  @override
  String get tallyCutDash => 'Név - értékek';
  @override
  String get tallyCutColon => 'Név: értékek';
  @override
  String get tallyCutCommas => 'Vesszővel elválasztott értékek';
  @override
  String get tallyCutWhole => 'A teljes sor egyetlen értékként';
  @override
  String get tallySortLabel => 'Sorrend';
  @override
  String get tallySortCount => 'A legtöbb elöl';
  @override
  String get tallySortAlphabetical => 'Betűrendben';
  @override
  String get tallySortFirstSeen => 'A lista sorrendjében';
  @override
  String get tallyInsert => 'Beszúrás';
  @override
  String get tallyUpdate => 'Frissítés';
  @override
  String get tallyNothingToCount => 'Itt nincs mit megszámlálni';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'A jegyzet nem létezik';
  @override
  String missingNoteDialogBody(String path) => 'Létrehozás: „$path"?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'A „$folder" mappa nem létezik';

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
  String get newItemTooltip => 'Új';
  @override
  String get closeMenuTooltip => 'Bezárás';
  @override
  String get newFolderTitle => 'Új mappa';
  @override
  String get newNoteSameFolder => 'Új jegyzet ugyanabban a mappában';
  @override
  String get newFromTemplateSameFolder => 'Új sablonból ugyanabban a mappában';
  @override
  String trashOriginalPath(String path) => 'itt volt: $path';
  @override
  String get trashOriginalRoot =>
      'a k\u00f6nyvt\u00e1r gy\u00f6ker\u00e9ben volt';
  @override
  String trashItemCount(int count) => count == 1 ? '1 elem' : '$count elem';
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
  String get templateHelpSubtitle => 'Dátum, cím és a többi kitöltendő érték';
  @override
  String get quickNoteSubtitle =>
      'A jegyzet, amelyet a Gyorsjegyzet lap megnyit';
  @override
  String get listFolderSubtitle => 'Az új feladatlisták';
  @override
  String get templateFolderSubtitle => 'A „Új sablonból” forrása';
  @override
  String get attachmentsFolderSubtitle => 'Jegyzetbe illesztett képek és hang';
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
  String get pinToWidget => 'Rögzítés widgetre';
  @override
  String get pinnedForWidget =>
      'Rögzítve: most addja a Megjegyzés-widgetet a kezdőképernyőhöz';
  @override
  String get pinWidgetUnavailable =>
      'A kezdőképernyő-widgetek Androidon érhetők el';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Megjelenítés a fájlkezelőben';
  @override
  String get openInDefaultApp => 'Megnyitás az alapértelmezett alkalmazással';
  @override
  String get newNoteTabTooltip => 'Új jegyzet új lapon';
  @override
  String get openNotesTooltip => 'Megnyitott jegyzetek';
  @override
  String get closeTabTooltip => 'Bezárás';
  @override
  String get openInNewTab => 'Megnyitás új lapon';
  @override
  String get splitRight => 'Felosztás jobbra';
  @override
  String get splitDown => 'Felosztás lefelé';
  @override
  String get moveToOtherPane => 'Áthelyezés a másik ablaktáblába';
  @override
  String get openBeside => 'Megnyitás mellette';
  @override
  String get closeAllNotes => 'Összes bezárása';
  @override
  String get sidePanelTooltip => 'Oldalsó panel megjelenítése vagy elrejtése';
  @override
  String get historyAllVersions => 'Összes verzió';
  @override
  String get commandPaletteTitle => 'Parancspaletta';
  @override
  String get goToNoteTitle => 'Ugrás jegyzetre';
  @override
  String get paletteGroupNote => 'Jegyzet';
  @override
  String get paletteGroupEditor => 'Szerkesztő';
  @override
  String get paletteGroupView => 'Nézet';
  @override
  String get paletteGroupLibrary => 'Könyvtár';
  @override
  String get paletteGroupGoTo => 'Ugrás';
  @override
  String get commandsTitle => 'Parancsok';
  @override
  String get commandsIntro =>
      'A parancspaletta csak azokat a parancsokat kínálja, amelyek ott '
      'futtathatók, ahol éppen vagy. Itt van mind, és hogy melyik mikor '
      'jelenik meg.';
  @override
  String get commandNeedNone => 'Mindig elérhető';
  @override
  String get commandNeedOpenNote => 'Nyitott jegyzet kell hozzá';
  @override
  String get commandNeedWideWindow => 'Csak széles ablakban';
  @override
  String get commandNeedDockRoom =>
      'Az oldalsó panelhez elég széles ablak kell';
  @override
  String get commandNeedDesktop => 'Csak asztali gépen';
  @override
  String get commandNeedNotInZen => 'Nem Zen módban';
  @override
  String get commandNeedZenRoom =>
      'Asztali gép, jegyzettel egy lapon megnyitva';
  @override
  String get commandNeedPreview => 'Bekapcsolt előnézettel, szöveges jegyzeten';
  @override
  String get commandNeedTwoEditors => 'Mindkét szerkesztő bekapcsolásával';
  @override
  String get paletteHint => 'Parancsok és jegyzetek keresése';
  @override
  String get paletteNoResults => 'Nincs találat';
  @override
  String get paletteCommands => 'Parancsok';
  @override
  String get paletteNotes => 'Jegyzetek';
  @override
  String get paletteFooter => '↑↓ mozgás · ↵ használat · esc bezárás';
  @override
  String get palettePinned => 'Kitűzve';
  @override
  String get palettePin => 'Kitűzés';
  @override
  String get paletteUnpin => 'Levétel';
  @override
  String get palettePinFooter => 'alt+P a kitűzéshez';
  @override
  String get spellCheckScanning => 'Jegyzet ellenőrzése…';
  @override
  String get spellCheckAgain => 'Ellenőrzés újra';
  @override
  String spellCheckCapped(int count) =>
      'Az első $count látható: javíts ki néhányat, majd ellenőrizz újra a '
      'többiért';
  @override
  String get dropHint =>
      'Húzz ide Markdown-fájlokat a megnyitáshoz, vagy egy mappát az '
      'importáláshoz';
  @override
  String get importFolderAction => 'Importálás';
  @override
  String dropRejected(String names) =>
      'Itt csak Markdown-fájlok és mappák nyílnak meg: $names';
  @override
  String importFolderTitle(String name) => 'Importálod: „$name”?';
  @override
  String importFolderBody(int count) =>
      'A Markdown-fájljai ($count) a könyvtár egy új mappájába másolódnak. A '
      'behúzott mappa változatlan marad.';
  @override
  String importFolderDone(String folder) => 'Importálva ide: $folder';
  @override
  String importFolderEmpty(String name) => 'Nincs Markdown-fájl itt: $name';
  @override
  String get openFileTitle => 'Fájl megnyitása';
  @override
  String get outsideFileNote =>
      'Könyvtáron kívül: a helyén mentődik, nincs indexelve, nincs előzmény, '
      'a hivatkozások nem nyílnak meg';
  @override
  String get typewriterOn => 'Írógépmód bekapcsolása';
  @override
  String get typewriterOff => 'Írógépmód kikapcsolása';
  @override
  String get typewriterTitle => 'Írógépmód';
  @override
  String get typewriterSubtitle =>
      'Az éppen írt sor a szerkesztő közepén marad';
  @override
  String get zenMode => 'Zen mód';
  @override
  String get zenModeEnter => 'Zen mód bekapcsolása';
  @override
  String get zenModeLeave => 'Kilépés a zen módból';
  @override
  String get keySpace => 'Szóköz';
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
  String get keyArrowUp => 'Fel';
  @override
  String get keyArrowDown => 'Le';
  @override
  String get keyArrowLeft => 'Balra';
  @override
  String get keyArrowRight => 'Jobbra';
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
  String get shortcutNone => 'Nincs billentyűparancs';
  @override
  String get shortcutRestoreDefaults => 'Alapértékek visszaállítása';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Visszaállítod az összes billentyűparancsot úgy, ahogy a Niman '
      'szállítja?';
  @override
  String get shortcutRevert => 'Vissza az alapértékre';
  @override
  String get shortcutClear => 'Billentyűparancs eltávolítása';
  @override
  String get shortcutCapturePrompt =>
      'Nyomd le a billentyűket. Az Esc és a Tab is rögzül: a Mégse gombbal '
      'léphetsz ki.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Adj hozzá Ctrl-t, Alt-ot vagy Metát: egy billentyű magában gépelésre '
      'való.';
  @override
  String get shortcutMove => 'Áthelyezés';
  @override
  String get shortcutUseAnyway => 'Használat mégis';
  @override
  String get shortcutUndo => 'Visszavonás';
  @override
  String get shortcutRedo => 'Ismétlés';
  @override
  String get shortcutChange => 'Billentyűparancs módosítása';
  @override
  String shortcutCaptureTitle(String command) => 'Billentyűk: $command';
  @override
  String shortcutConflict(String keys, String other) =>
      'A(z) $keys már a(z) $other parancsé. Áthelyezed ide? A(z) $other '
      'billentyűparancs nélkül marad.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      'A(z) $keys a szövegmezőkben és a szerkesztőben $what is. Ott a '
      'parancsod veszi át.';
  @override
  String get openFileMissing => 'Ennek a jegyzetnek a fájlja nincs a lemezen';
  @override
  String get openFileFailed =>
      'A jegyzetet nem sikerült a Nimanon kívül megnyitni';

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
  @override
  String get attachmentsFolderTitle => 'Mellékletmappa';

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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Névjegy';
  @override
  String get versionTitle => 'Verzió';
  @override
  String get changelogTitle => 'Változási napló';
  @override
  String get changelogEmpty => 'Nincs elérhető naplóbejegyzés';
  @override
  String changelogWhatsNew(String version) =>
      'Újdonságok a(z) $version verzióban';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Előzmények';
  @override
  String get noteMenuTooltip => 'Jegyzetműveletek';
  @override
  String get historyCurrentVersion => 'Jelenlegi verzió';
  @override
  String get historyCurrentSubtitle => 'A jegyzet jelenlegi állapota';
  @override
  String get historyToday => 'Ma';
  @override
  String get historyYesterday => 'Tegnap';
  @override
  String get historyReasonSession => 'szerkesztés előtt';
  @override
  String get historyReasonInterval => 'szerkesztés közben';
  @override
  String get historyReasonRestore => 'visszaállítás előtt';
  @override
  String get historyReasonSync => 'szinkronizálás előtt';
  @override
  String get historyReasonReplace => 'csere előtt';
  @override
  String get historyReasonUnknown => 'helyreállított';
  @override
  String get historySyncBase => 'szinkronalap';
  @override
  String get historyEmpty =>
      'Még nincsenek verziók. A Niman ment egyet, amikor elkezded szerkeszteni '
      'a jegyzetet, majd írás közben legfeljebb néhány percenként egyet.';
  @override
  String historyKept(int kept, int limit) => '$kept/$limit verzió megőrizve';
  @override
  String get historyBaseKept => 'A szinkronalap a korláton felül is megmarad.';
  @override
  String get historyOff =>
      'Az előzmények ki vannak kapcsolva ebben a könyvtárban '
      '(Beállítások, Könyvtár).';
  @override
  String get historyLoadFailed => 'Az előzmények nem olvashatók';
  @override
  String get historyCompareSubtitle => 'Összevetve a jelenlegi verzióval';
  @override
  String get historyTabChanges => 'Változások';
  @override
  String get historyTabVersion => 'Verzió';
  @override
  String get historyNoChanges =>
      'Ugyanaz a szöveg, mint a jelenlegi verzióban.';
  @override
  String get historyRestoreAction => 'Visszaállítás erre a verzióra';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Visszaállítod ezt a verziót: $when?';
  @override
  String get historyRestoreConfirmBody =>
      'A jelenlegi szöveg előbb bekerül az előzményekbe, így bármikor '
      'visszatérhetsz.';
  @override
  String get historyRestoreConfirm => 'Visszaállítás';
  @override
  String historyRestored(String when) => 'Verzió visszaállítva: $when';
  @override
  String get historyRestoreFailed => 'A verzió nem állítható vissza';
  @override
  String get actionUndo => 'Visszavonás';
  @override
  String diffLineRange(int start, int end) => '$start–$end. sor';
  @override
  String diffLineSingle(int line) => '$line. sor';
  @override
  String diffUnchanged(int count) => '$count változatlan sor';
  @override
  String get historyTakeHunk => 'Visszaállítás itt';
  @override
  String historyRestoreSelectedAction(int count) => count == 1
      ? '1 változás visszaállítása'
      : '$count változás visszaállítása';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'A kiválasztott változások visszatérnek ennek a verziónak a szövegéhez. '
      'A jegyzet mostani állapota előbb verzióként megmarad, így vissza tudod '
      'vonni.';
  @override
  String get historyNoteChangedReloaded =>
      'A jegyzet megváltozott, amíg itt voltál — az összehasonlítás frissült.';
  @override
  String get historyVersionsTitle => 'Megőrzendő verziók';
  @override
  String get historyVersionsSubtitle => 'Jegyzetenként, a .history/ mappában';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Nincs' : '$count';
  @override
  String get historyIntervalTitle => 'Új verzió legfeljebb';
  @override
  String get historyIntervalSubtitle =>
      'Írás közben; a szerkesztés megkezdésekor mindig készül egy';
  @override
  String historyIntervalValue(int minutes) => '$minutes percenként';
  @override
  String get settingsSectionTranscription => 'Átirat';
  @override
  String get transcriptionModelTitle => 'Modell';
  @override
  String get transcriptionModelNone => 'Nincs';
  @override
  String get transcriptionLanguageTitle => 'Nyelv';
  @override
  String get transcriptionLanguageSubtitle =>
      'A felvételeiden beszélt nyelv. Megadni pontosabb, mint felismertetni.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Mint az alkalmazás ($language)';
  @override
  String get transcriptionLanguageDetect => 'Automatikus felismerés';
  @override
  String get transcriptionModelsTitle => 'Átiratmodellek';
  @override
  String transcriptionModelsUsed(String size) => '$size foglalt';
  @override
  String get transcriptionModelsInstalled => 'Letöltve';
  @override
  String get transcriptionModelsDownloading => 'Letöltés folyamatban';
  @override
  String get transcriptionModelsAvailable => 'Elérhető';
  @override
  String get transcriptionModelsFooter =>
      'A modellek az alkalmazás tárhelyén maradnak ezen az eszközön. Nem '
      'kerülnek a könyvtárba, és nem szinkronizálódnak.';
  @override
  String get transcriptionModelDefault => 'Alapértelmezett';
  @override
  String get transcriptionModelSlow => 'Lassú';
  @override
  String get transcriptionModelHintTiny => 'A leggyorsabb, a legkevésbé pontos';
  @override
  String get transcriptionModelHintBase =>
      'Jó egyensúly a sebesség és a pontosság között';
  @override
  String get transcriptionModelHintSmall => 'Pontosabb, nagyjából 3× lassabb';
  @override
  String get transcriptionModelHintMedium => 'Nagyon pontos, telefonon lassú';
  @override
  String get transcriptionModelHintLarge =>
      'A legpontosabb, sok memóriát igényel';
  @override
  String get transcriptionModelDownload => 'Letöltés';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Törlöd a(z) $model modellt?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Ezzel $size szabadul fel. A modellt később újra letöltheted.';
  @override
  String get transcriptionModelFailed =>
      'A letöltés sikertelen. Ellenőrizd a kapcsolatot, és próbáld újra.';
  @override
  String get actionRetry => 'Újra';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Megszakadt a kapcsolat, újrapróbálkozás…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Szüneteltetve: $progress';
  @override
  String get actionResume => 'Folytatás';
  @override
  String get audioTranscribe => 'Átírás';
  @override
  String get audioTranscribeUnsupported =>
      'Ezen az eszközön csak WAV-felvételek';
  @override
  String get transcriptionQueued => 'Sorban áll';
  @override
  String get transcriptionPreparing => 'Hang előkészítése…';
  @override
  String transcriptionRunning(int percent) => 'Átírás… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model letöltése · $percent%';
  @override
  String get transcriptionSaved => 'Az átirat bekerült a leírásba';
  @override
  String get transcriptionNoSpeech =>
      'Ebben a felvételben nem sikerült beszédet felismerni';
  @override
  String get transcriptionFailed => 'Az átírás sikertelen';
  @override
  String get transcriptionPickModelTitle => 'Válassz modellt';
  @override
  String get transcriptionPickModelBody =>
      'Az átírás ezen az eszközön történik, a felvétel sosem kerül '
      'feltöltésre. A modellt csak egyszer kell letölteni.';
  @override
  String get transcriptionPickModelAction => 'Letöltés és átírás';
  @override
  String get transcriptionModelRecommended => 'Ajánlott';
  @override
  String get transcriptionExistingTitle =>
      'Ennek a felvételnek már van leírása';
  @override
  String get transcriptionExistingBody =>
      'Lecseréled az átiratra, vagy alá írod az átiratot?';
  @override
  String get transcriptionAppend => 'Hozzáadás alá';
  @override
  String get transcriptionReplace => 'Csere';
  @override
  String get settingsSectionSync => 'Szinkronizálás';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Ehhez a könyvtárhoz nincs beállítva';
  @override
  String get syncNeverSynced => 'Még sosem szinkronizált';
  @override
  String syncLastSynced(String when) => 'Szinkronizálva: $when';
  @override
  String get syncRunning => 'Szinkronizálás…';
  @override
  String syncScreenSubtitle(String library) => 'Könyvtár: $library';
  @override
  String get syncUrlLabel => 'Mappa címe';
  @override
  String get syncUrlRequired => 'Adja meg a kiszolgáló címét';
  @override
  String get syncUrlHint =>
      'A mappának léteznie kell. Másold ki a címet úgy, ahogy a '
      'szerver mutatja.';
  @override
  String get syncHttpWarning =>
      'Titkosítatlan kapcsolat: VPN-en vagy helyi hálózaton '
      'rendben van.';
  @override
  String get syncUserLabel => 'Felhasználó';
  @override
  String get syncUserHint =>
      'Hagyd üresen, ha a szerver nem kér hitelesítő adatokat.';
  @override
  String get syncPasswordLabel => 'Jelszó';
  @override
  String get syncPasswordHint =>
      'A készülék kulcstartójában tárolódik, sosem a könyvtár '
      'fájljaiban.';
  @override
  String get syncPasswordKeepHint =>
      'Hagyd üresen a mentett jelszó megtartásához.';
  @override
  String get syncShowPassword => 'Jelszó megjelenítése';
  @override
  String get syncHidePassword => 'Jelszó elrejtése';
  @override
  String get syncTestAction => 'Kapcsolat tesztelése';
  @override
  String get syncTesting => 'Tesztelés…';
  @override
  String get syncRetargetWarning =>
      'Új címmel vagy felhasználóval a következő szinkronizálás '
      'elölről indul, első szinkronizálásként.';
  @override
  String get syncTestOk => 'A kapcsolat működik';
  @override
  String get syncModeFull => 'Teljes mód';
  @override
  String get syncModeCompatible => 'Kompatibilis mód';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Olvasás, írás és törlés';
  @override
  String get syncCapEtags => 'Fájlujjlenyomatok (ETag)';
  @override
  String get syncCapNoEtags => 'Nincsenek fájlujjlenyomatok (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Méretet és dátumot hasonlítok össze; kétség esetén újra '
      'letöltöm';
  @override
  String get syncCapGuarded => 'Védett írás';
  @override
  String get syncCapUnguarded => 'Védtelen írás';
  @override
  String get syncCapUnguardedDetail =>
      'Közvetlenül írás előtt ellenőrzöm a fájlt a szerveren';
  @override
  String get syncCapMove => 'Átnevezés újrafeltöltés nélkül';
  @override
  String get syncCapNoMove => 'Nincs átnevezés a szerveren';
  @override
  String get syncCapNoMoveDetail =>
      'Az átnevezésből törlés és új feltöltés lesz';
  @override
  String get syncCompatibleNote =>
      'Kompatibilis módban a szinkronizálás ugyanúgy működik, '
      'csak néhány kéréssel többel.';
  @override
  String get syncTestInvalidUrl => 'Érvénytelen cím';
  @override
  String get syncTestInvalidUrlHint =>
      'Adj meg egy http:// vagy https:// címet, felhasználó és '
      'jelszó nélkül.';
  @override
  String get syncTestOffline => 'A szerver nem érhető el';
  @override
  String get syncTestOfflineHint =>
      'Be van kapcsolva a VPN? Egy 10.x vagy 192.168.x cím csak '
      'ugyanarról a hálózatról működik.';
  @override
  String get syncTestAuth => 'Elutasított felhasználó vagy jelszó';
  @override
  String get syncTestAuthHint => 'Ellenőrizd őket, majd teszteld újra.';
  @override
  String get syncTestNotFound => 'A mappa nem létezik';
  @override
  String get syncTestNotFoundHint =>
      'Hozd létre a szerveren, vagy javítsd a címet.';
  @override
  String get syncTestUnsupported => 'Nem WebDAV-mappa';
  @override
  String get syncTestUnsupportedHint =>
      'A szerver válaszol, de nem WebDAV-ként.';
  @override
  String get syncTestFailed => 'A teszt nem sikerült';
  @override
  String get syncNowAction => 'Szinkronizálás most';
  @override
  String get syncSectionServer => 'Szerver';
  @override
  String get syncServerRow => 'Cím, felhasználó és jelszó';
  @override
  String get syncRetestTitle => 'Szerver újratesztelése';
  @override
  String syncProbedAgo(String when) => 'Utolsó teszt: $when';
  @override
  String get syncDisconnectTitle => 'Könyvtár leválasztása';
  @override
  String get syncDisconnectSubtitle =>
      'A fájlok itt és a szerveren is megmaradnak';
  @override
  String get syncDisconnectConfirmTitle => 'Leválasztod a szinkronizálást?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ez a könyvtár nem szinkronizál többé ezen a készüléken. '
      'Egyetlen fájl sem törlődik, sem itt, sem a szerveren. Ha '
      'újra összekapcsolod, az első szinkronizálás elölről '
      'kezdődik.';
  @override
  String get syncDisconnectConfirm => 'Leválasztás';
  @override
  String get syncFirstTitle => 'Első szinkronizálás';
  @override
  String get syncFirstIntro =>
      'Összehasonlítottam a könyvtárat a szerveren lévő mappával:';
  @override
  String get syncFirstUpload => 'Feltöltendő';
  @override
  String get syncFirstDownload => 'Letöltendő';
  @override
  String get syncFirstBoth => 'Mindkét oldalon';
  @override
  String get syncFirstBothHint =>
      'Azonosak: nincs átvitel. Eltérők: feloldandó';
  @override
  String get syncFirstNoDelete =>
      'Az első szinkronizálás semmit sem töröl, sem itt, sem a '
      'szerveren.';
  @override
  String get syncStartAction => 'Indítás';
  @override
  String syncMassTrashTitle(int count) => 'Áthelyezel $count fájlt a kukába?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$total szinkronizált fájlból $count hiányzik a '
      'szerverről. Ez általában hibás címet, csatolatlan '
      'NAS-lemezt vagy véletlenül kiürített mappát jelent.';
  @override
  String get syncMassTrashHint =>
      'Ha tényleg törölted őket egy másik készüléken, erősítsd '
      'meg: itt a kukába kerülnek.';
  @override
  String get syncMassTrashConfirm => 'Áthelyezés a kukába';
  @override
  String syncMassDeleteTitle(int count) => 'Törölsz $count fájlt a szerverről?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$total szinkronizált fájlból $count itt hiányzik. Ha nem '
      'te törölted őket, válaszd a Mégse gombot, és ellenőrizd a '
      'könyvtár mappáját.';
  @override
  String get syncMassDeleteConfirm => 'Törlés a szerverről';
  @override
  String get syncTooltip => 'Szinkronizálás';
  @override
  String get syncStageConnecting => 'Csatlakozás a szerverhez…';
  @override
  String get syncStageComparing => 'Összehasonlítás a szerverrel…';
  @override
  String syncStageApplying(int done, int total) =>
      'Szinkronizálás · $done/$total';
  @override
  String get syncStatusWarnings => 'Szinkronizálva, figyelmeztetésekkel';
  @override
  String syncConflictsHeader(int count) =>
      'Itt és a szerveren is módosult · $count';
  @override
  String get syncConflictHint => 'Egyik verzió sem változott';
  @override
  String get syncResolveAction => 'Feloldás';
  @override
  String syncFailuresHeader(int count) => 'Nem szinkronizált · $count';
  @override
  String get syncFailuresHint => 'Újrapróbálás a következő szinkronizáláskor';
  @override
  String get syncAbortAuth => 'A szerver elutasította a jelszót';
  @override
  String get syncAbortMissingPassword => 'Nincs mentett jelszó';
  @override
  String get syncAbortOffline => 'A szerver nem érhető el';
  @override
  String get syncAbortRemoteMissing => 'A mappa már nincs meg a szerveren';
  @override
  String get syncAbortUnsupported => 'A szerver már nem működik WebDAV-ként';
  @override
  String get syncAbortFailed => 'A szinkronizálás nem sikerült';
  @override
  String get syncAbortNotConfirmed => 'Szinkronizálás megszakítva';
  @override
  String get syncAbortNothingTouched =>
      'Egyetlen fájl sem változott. A módosításaid itt maradnak '
      'a következő sikeres szinkronizálásig.';
  @override
  String syncLastSuccess(String when) => 'Utolsó sikeres szinkronizálás: $when';
  @override
  String get syncNoSuccessYet => 'Még nem volt sikeres szinkronizálás';
  @override
  String get syncUpdatePasswordAction => 'Jelszó frissítése';
  @override
  String get syncRetryAction => 'Próbáld újra';
  @override
  String get syncOpenSettingsAction => 'Beállítások';
  @override
  String get syncCloseAction => 'Bezárás';
  @override
  String get syncDoneSnack => 'Szinkronizálva';
  @override
  String syncTrashedSnack(int count) =>
      'Szinkronizálva · $count máshol törölt fájl a kukába került';
  @override
  String syncConflictsSnack(int count) =>
      'Szinkronizálva · $count feloldandó ütközés';
  @override
  String get syncShowAction => 'Megjelenítés';
  @override
  String get syncConflictTitle => 'Ütközés feloldása';
  @override
  String get syncConflictLegend =>
      'A − jelű sorok a szerveréi, a + jelűek ezé a készüléké.';
  @override
  String get syncConflictBinary =>
      'Nem szövegfájl: válaszd ki, melyik példányt tartod meg.';
  @override
  String get syncConflictKeepNote =>
      'A meg nem tartott példány a jegyzet előzményeiben marad.';
  @override
  String get syncKeepLocal => 'A készülék változatának megtartása';
  @override
  String get syncKeepRemote => 'A szerver változatának megtartása';
  @override
  String get syncConflictIdentical => 'A két verzió azonos';
  @override
  String get syncConflictLoadFailed => 'Nem sikerült mindkét verziót beolvasni';
  @override
  String get syncResolveFailed => 'Nem sikerült feloldani az ütközést';
  @override
  String get syncResolved => 'Ütközés feloldva';
  @override
  String get syncSectionWhen => 'Mikor szinkronizáljon';
  @override
  String get syncAutoTitle => 'Automatikusan';
  @override
  String get syncAutoSubtitle =>
      'Módosítások után, megnyitáskor és időközönként';
  @override
  String get syncIntervalTitle => 'A szerver ellenőrzése';
  @override
  String get syncIntervalSubtitle => 'Csak amíg az alkalmazás nyitva van';
  @override
  String get syncIntervalDialogBody =>
      'Hogy lásd a más készülékeken végzett módosításokat, amíg az '
      'alkalmazás nyitva van. „Soha” esetén csak módosítások után és '
      'megnyitáskor.';
  @override
  String syncIntervalMinutes(int count) => '$count percenként';
  @override
  String get syncIntervalNever => 'Soha';
  @override
  String get syncWifiOnlyTitle => 'Csak Wi-Fi-n';
  @override
  String get syncWifiOnlySubtitle => 'Mobiladaton csak kézi szinkronizálás';
  @override
  String syncPendingChanges(int count) => '$count módosítás várakozik';
  @override
  String syncRetryIn(String wait) => 'újrapróbálás $wait múlva';
  @override
  String syncWaitSeconds(int seconds) => '$seconds mp';
  @override
  String syncWaitMinutes(int minutes) => '$minutes perc';
  @override
  String get syncWaitingForWifi => 'Várakozás Wi-Fi-re';
  @override
  String get syncWaitingForNetwork => 'Várakozás kapcsolatra';
  @override
  String get syncMobileDataHint =>
      'A „Szinkronizálás most” mobiladaton is működik.';
  @override
  String get syncQueueKeptHint =>
      'A módosítások itt maradnak akkor is, ha bezárod az alkalmazást, és '
      'maguktól elmennek, amikor a szerver válaszol.';
  @override
  String get syncAutoPaused => 'Az automatikus szinkronizálás szünetel';
  @override
  String get syncPausedAuthHint =>
      'Folytatódik, ha frissíted a jelszót, vagy kézzel szinkronizálsz.';
  @override
  String get syncPausedServerHint =>
      'Folytatódik, ha kijavítod a címet, vagy kézzel szinkronizálsz.';
  @override
  String get syncPausedConfirmHint =>
      'A „Szinkronizálás most” megmutatja, mi törlődne, és előbb '
      'rákérdez.';
  @override
  String get syncNeedsConfirmation => 'A megerősítésedre vár';
  @override
  String get syncMergeIntro =>
      'Az egymást nem átfedő módosítások már össze vannak fésülve; '
      'ahol átfedik egymást, válaszd ki, mi maradjon.';
  @override
  String get syncMergeClean =>
      'A két verzió magától összeáll: semmi sem fedi egymást.';
  @override
  String get syncMergeNoBase =>
      'Nincs közös verzió, amelyre össze lehetne fésülni, ezért a '
      'teljes fájlt kell választani.';
  @override
  String syncMergeOverlap(int index, int total) => 'Átfedés $index / $total';
  @override
  String get syncMergeFromLocal => 'Erről a készülékről';
  @override
  String get syncMergeFromRemote => 'A szerverről';
  @override
  String get syncMergeRemovedLines => 'Törölt sorok';
  @override
  String get syncMergeKeepLocal => 'Enyém';
  @override
  String get syncMergeKeepRemote => 'Szerveré';
  @override
  String get syncMergeKeepBoth => 'Mindkettő';
  @override
  String get syncMergeSave => 'Összefésülés mentése';
  @override
  String get syncMergeKeepWhole => 'Vagy tarts meg egy teljes példányt';
}
