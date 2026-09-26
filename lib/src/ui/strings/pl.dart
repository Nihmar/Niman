// The Polish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class PolishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'styczeń',
    'luty',
    'marzec',
    'kwiecień',
    'maj',
    'czerwiec',
    'lipiec',
    'sierpień',
    'wrzesień',
    'październik',
    'listopad',
    'grudzień',
  ];
  @override
  List<String> get monthNamesShort => const [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];
  @override
  List<String> get weekdayNames => const [
    'poniedziałek',
    'wtorek',
    'środa',
    'czwartek',
    'piątek',
    'sobota',
    'niedziela',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'pon',
    'wt',
    'śr',
    'czw',
    'pt',
    'sob',
    'niedz',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Kosz';
  @override
  String get trashSubtitle =>
      'Usunięte elementy trafiają do .trash/ (wyłączone = trwałe '
      'usunięcie)';
  @override
  String get trashAutoEmptyTitle => 'Automatyczne opróżnianie kosza';
  @override
  String get trashAutoEmptySubtitle =>
      'Starsze usunięcia znikają na zawsze przy otwarciu biblioteki';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nigdy'
      : days == 1
      ? '1 dzień'
      : '$days dni';
  @override
  String get debugLogsTitle => 'Logi debugowania';
  @override
  String get debugLogsSubtitle =>
      'Zapisuje zdarzenia aplikacji w buforze pamięci';
  @override
  String get lineNumbersTitle => 'Numery linii';
  @override
  String get lineNumbersSubtitle =>
      'Pokaż kolumnę numerów linii w edytorze notatek';
  @override
  String get readableLineLengthTitle => 'Czytelna długość wiersza';
  @override
  String get readableLineLengthSubtitle =>
      'Trzymaj tekst notatki w wyśrodkowanej kolumnie zamiast na całej '
      'szerokości okna';
  @override
  String get noteColumnWidthTitle => 'Szerokość kolumny';
  @override
  String get noteColumnWidthSubtitle =>
      'Jak szeroka jest kolumna notatki, w pikselach';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Klawiatura po otwarciu';
  @override
  String get keyboardOnOpenSubtitle =>
      'Pokaż klawiaturę po otwarciu notatki (wyłączone = przy pierwszym '
      'dotknięciu)';
  @override
  String get editorKindSource => 'Źródło Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Źródło Markdown, tak jak napisane';
  @override
  String get editorKindWysiwygSubtitle =>
      'Tekst sformatowany, edytowany w miejscu';
  @override
  String get settingsFolderToCreate => 'do utworzenia';
  @override
  String get settingsSearchHint => 'Szukaj w ustawieniach';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 znalezione ustawienie' : '$count znalezionych ustawień';
  @override
  String get settingsToggleOn => 'Włączone';
  @override
  String get settingsToggleOff => 'Wyłączone';
  @override
  String get switchToWysiwygTooltip => 'Przełącz na edytor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Przełącz na źródło Markdown';
  @override
  String get switchToSourceLabel => 'Źródło';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Wygląd';
  @override
  String get settingsSectionEditor => 'Edytor';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'Przypomnienia';
  @override
  String get settingsSectionShortcuts => 'Klawiatura';
  @override
  String get keyboardShortcutsTitle => 'Skróty klawiszowe';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteka $name';
  @override
  String get settingsGroupLibraryHint => 'dotyczy tylko tej biblioteki';
  @override
  String get settingsGroupMaintenance => 'Konserwacja';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Foldery i ścieżki';
  @override
  String get settingsAreaTrashHistory => 'Kosz i historia';
  @override
  String get settingsAreaDiagnostics => 'Diagnostyka i info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Wymaga podłączonej fizycznej klawiatury';
  @override
  String get settingsSectionUpdates => 'Aktualizacje';
  @override
  String get autoUpdateTitle => 'Automatyczne aktualizacje';
  @override
  String get autoUpdateSubtitle =>
      'Sprawdza GitHub Releases przy uruchomieniu i co 6 godzin';
  @override
  String get checkForUpdatesTitle => 'Sprawdź aktualizacje';
  @override
  String updateAvailableMessage(Object version) =>
      'Dostępny jest Niman $version';
  @override
  String get updateUpToDate => 'Niman jest aktualny';
  @override
  String get updateCheckFailed => 'Nie udało się sprawdzić aktualizacji';
  @override
  String updateSavedTo(Object path) => 'Aktualizację zapisano w $path';
  @override
  String get updateInstallerStarted => 'Uruchomiono instalator';
  @override
  String get settingsSectionDiagnostics => 'Diagnostyka';
  @override
  String get settingsSpellCheckTitle => 'Sprawdzanie pisowni';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podkreśla błędy ortograficzne podczas pisania.';
  @override
  String get spellCheckDictionaryTitle => 'Słownik';
  @override
  String get spellCheckDictionarySystem => 'Domyślny systemu';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Wybór słowników';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Wybierz wszystkie języki, w których zapisana jest biblioteka. '
      'Słowo przechodzi, gdy choćby jeden z wybranych słowników je zna; '
      'bez wyboru decyduje język systemu.';
  @override
  String get spellCheckNoDictionaries =>
      'Nie znaleziono słowników w tym systemie.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Sprawdzanie pisowni';
  @override
  String get spellCheckTitle => 'Pisownia';
  @override
  String get spellCheckEmpty => 'Brak błędów ortograficznych.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nie jest zainstalowany w tym systemie.';
  @override
  String get spellCheckNoSuggestions => 'Brak sugestii';
  @override
  String spellCheckCount(int count) => '$count do sprawdzenia';
  @override
  String spellCheckLine(int line) => 'linia $line';
  @override
  String get addWordToDictionary => 'Dodaj do słownika';

  @override
  String indentWidthValue(int spaces) => '$spaces spacje';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Tryb jasności';
  @override
  String get themeBrightnessSubtitle =>
      'Jasny, ciemny lub ustawienie urządzenia';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Jasny';
  @override
  String get themeBrightnessNight => 'Ciemny';
  @override
  String get themeTitle => 'Motyw';
  @override
  String get themeSubtitle => 'Kolory interfejsu i notatki';
  @override
  String get themePaletteSystem => 'System';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Motywy';
  @override
  String get themesInUse => 'W użyciu';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Nowy motyw';
  @override
  String get themeNewName => 'Nazwa';
  @override
  String get themeNewStartFrom => 'Zacznij od';
  @override
  String get themeNewRandom => 'Losowe kolory';
  @override
  String get themeNameTaken => 'Motyw o tej nazwie już istnieje';
  @override
  String themeDeleteBody(String name) =>
      'Usunąć „$name”? Jego kolory przepadną na zawsze.';
  @override
  String get themeDuplicate => 'Duplikuj';
  @override
  String get themeMenuTooltip => 'Działania motywu';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Edytuj';
  @override
  String get themeEditorTitle => 'Edytuj motyw';
  @override
  String get themeEditorChrome => 'Interfejs';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Listy zadań (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Każdy kolor nazywa się tak jak w wyeksportowanym pliku';
  @override
  String get themeEditorDiscardTitle => 'Odrzuć zmiany';
  @override
  String get themeEditorDiscardBody => 'Zmienione kolory nie zostaną zapisane';
  @override
  String get themeEditorDiscard => 'Odrzuć';
  @override
  String get themeEditorBadColor => 'Użyj #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Eksportuj';
  @override
  String themeExportDone(String where) => 'Motyw wyeksportowany do $where';
  @override
  String themeFileFailed(String error) =>
      'Nie udało się przenieść motywu: $error';
  @override
  String get themeImport => 'Importuj';
  @override
  String get themeImportInvalid => 'Ten plik nie jest motywem Niman';
  @override
  String themeImportVersion(int version) =>
      'Ten motyw pochodzi z nowszego Nimana (wersja $version)';
  @override
  String themeImportBadRole(String role) =>
      'Plik nie podaje koloru dla „$role”';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Rozmiar tekstu interfejsu';
  @override
  String get uiTextScaleSubtitle =>
      'Drzewo, karty i okna dialogowe; nad ustawieniem systemu';
  @override
  String get noteTextScaleTitle => 'Rozmiar tekstu notatki';
  @override
  String get noteTextScaleSubtitle =>
      'Edytor i podgląd, zawsze zsynchronizowane';
  @override
  String get epubLookTitle => 'Wygląd książek';
  @override
  String get epubLookSubtitle =>
      'Motyw, czcionka i rozmiar tekstu książek EPUB, osobno od notatek';
  @override
  String get epubSameAsApp => 'Jak w aplikacji';
  @override
  String get epubFontTitle => 'Czcionka';
  @override
  String get epubFontSerif => 'Szeryfowa';
  @override
  String get epubFontSans => 'Bezszeryfowa';
  @override
  String get epubFontMono => 'Stałej szerokości';
  @override
  String get epubTextSizeTitle => 'Rozmiar tekstu';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Format linku';
  @override
  String get linkTypeSubtitle => 'Co przycisk linku wstawia do edytora';
  @override
  String get linkTypeWikilink => 'Link wiki';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Utwórz brakujące notatki w';
  @override
  String get missingNoteLocationRoot => 'Korzeń biblioteki';
  @override
  String get missingNoteLocationCurrentFolder => 'Bieżący katalog';
  @override
  String get indentWidthTitle => 'Szerokość wcięcia';
  @override
  String get indentWidthSubtitle =>
      'Liczba spacji dodawanych na każdym poziomie wcięcia w edytorze';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Język';
  @override
  String get languageSubtitle => 'Język właściwego tekstu aplikacji';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Dodaj element';
  @override
  String get listAddTooltip => 'Dodaj element';
  @override
  String get listEmpty => 'Nie ma jeszcze elementów';
  @override
  String get listDragHandleLabel => 'Zmień kolejność elementu';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Nie ma jeszcze nagrań';
  @override
  String get audioRecord => 'Nagraj';
  @override
  String get audioStop => 'Zatrzymaj';
  @override
  String get audioPlay => 'Odtwórz';
  @override
  String get audioDelete => 'Usuń nagranie';
  @override
  String get audioImport => 'Importuj plik audio';
  @override
  String get audioRecording => 'Nagrywanie…';
  @override
  String get audioPermissionDenied =>
      'Brak uprawnienia do mikrofonu — jest potrzebne do nagrywania.';
  @override
  String get newAudioNoteTitle => 'Nowa notatka głosowa';
  @override
  String get newAudioNoteDefault => 'Moje nagranie';
  @override
  String get showAudioTooltip => 'Pokaż nagrania';
  @override
  String get audioMessageHint => 'Napisz notatkę…';
  @override
  String get audioSend => 'Wyślij';
  @override
  String get audioRename => 'Zmień nazwę nagrania';
  @override
  String get audioDescriptionHint => 'Opisz to nagranie…';
  @override
  String get audioEditDescription => 'Edytuj opis';
  @override
  String get audioDeleteNote => 'Usuń notatkę';
  @override
  String get audioEditNote => 'Edytuj notatkę';
  @override
  String get audioPause => 'Wstrzymaj';
  @override
  String get audioEditTitle => 'Edytuj tytuł';
  @override
  String get audioTitleHint => 'Tytuł tego nagrania…';
  @override
  String audioUntitled(int n) => 'Nagranie $n';
  @override
  String get audioMoreActions => 'Więcej działań';
  @override
  String get audioDiscardRecording => 'Odrzuć nagranie';
  @override
  String get audioPauseRecording => 'Wstrzymaj nagrywanie';
  @override
  String get audioResumeRecording => 'Wznów nagrywanie';
  @override
  String get audioRecordingPaused => 'Wstrzymano';
  @override
  String get audioSavingRecording => 'Zapisywanie…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Szybka notatka';
  @override
  String get trayOpen => 'Otwórz Niman';
  @override
  String get trayQuit => 'Zakończ';
  @override
  String get closeToTrayTitle => 'Zamknij do zasobnika';
  @override
  String get closeToTraySubtitle =>
      '× okna ukrywa Niman i zostawia go uruchomionym, więc przypomnienia '
      'nadal przychodzą. Wyjście z menu ikony.';
  @override
  String get shortcutNewTodo => 'Nowe zadanie';
  @override
  String get shortcutNewNote => 'Nowa notatka';
  @override
  String get shortcutNewList => 'Nowa lista';
  @override
  String get shortcutNewAudio => 'Nowa notatka głosowa';
  @override
  String get shortcutToggleSidebar => 'Pokaż lub ukryj filtr';
  @override
  String get shortcutCloseTab => 'Zamknij bieżącą notatkę';
  @override
  String get shortcutNextTab => 'Następna otwarta notatka';
  @override
  String get shortcutPreviousTab => 'Poprzednia otwarta notatka';
  @override
  String get shortcutEditorSection => 'W edytorze';
  @override
  String get shortcutFormatSection => 'Formatowanie';
  @override
  String get shortcutFind => 'Znajdź';
  @override
  String get shortcutReplace => 'Znajdź i zamień';
  @override
  String get shortcutSavingNote =>
      'Zmiany są zapisywane automatycznie, więc nie ma skrótu do '
      'zapisu.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Wczytywanie…';
  @override
  String get noteStatusSaving => 'Zapisywanie…';
  @override
  String get noteStatusUnsaved => 'Niezapisane';
  @override
  String get noteStatusSaved => 'Zapisano';
  @override
  String get noteStatusError => 'Błąd';
  @override
  String get noteNotText =>
      'Ten plik nie jest notatką tekstową, więc Niman nie może go tu pokazać.';
  @override
  String get noteLoadFailed => 'Nie udało się otworzyć tej notatki.';
  @override
  String wordCount(int count) => count == 1
      ? '1 słowo'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            !(count % 100 >= 12 && count % 100 <= 14)
      ? '$count słowa'
      : '$count słów';
  @override
  String get outlineTooltip => 'Struktura';
  @override
  String get outlineNoHeadings => 'Brak nagłówków';
  @override
  String get outlineNoTitle => '(bez tytułu)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Pogrubienie';
  @override
  String get toolbarItalic => 'Kursywa';
  @override
  String get toolbarStrikethrough => 'Przekreślenie';

  @override
  String get toolbarHighlight => 'Wyróżnienie';
  @override
  String get toolbarSuperscript => 'Indeks górny';
  @override
  String get toolbarUnderline => 'Podkreślenie';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Blok kodu';
  @override
  String get toolbarImage => 'Wstaw obraz';
  @override
  String get toolbarTable => 'Tabela';
  @override
  String get tableRow => 'Wiersz';
  @override
  String get tableColumn => 'Kolumna';
  @override
  String get tableAddRowAbove => 'Wstaw wiersz powyżej';
  @override
  String get tableAddRowBelow => 'Wstaw wiersz poniżej';
  @override
  String get tableMoveRowUp => 'Przesuń wiersz w górę';
  @override
  String get tableMoveRowDown => 'Przesuń wiersz w dół';
  @override
  String get tableDuplicateRow => 'Duplikuj wiersz';
  @override
  String get tableDeleteRow => 'Usuń wiersz';
  @override
  String get tableAddColumnLeft => 'Wstaw kolumnę po lewej';
  @override
  String get tableAddColumnRight => 'Wstaw kolumnę po prawej';
  @override
  String get tableMoveColumnLeft => 'Przesuń kolumnę w lewo';
  @override
  String get tableMoveColumnRight => 'Przesuń kolumnę w prawo';
  @override
  String get tableAlignLeft => 'Wyrównaj do lewej';
  @override
  String get tableAlignCenter => 'Wyśrodkuj';
  @override
  String get tableAlignRight => 'Wyrównaj do prawej';
  @override
  String get tableDuplicateColumn => 'Duplikuj kolumnę';
  @override
  String get tableDeleteColumn => 'Usuń kolumnę';
  @override
  String get tableSortAscending => 'Sortuj według kolumny (A → Z)';
  @override
  String get tableSortDescending => 'Sortuj według kolumny (Z → A)';
  @override
  String get tableAddRow => 'Dodaj wiersz';
  @override
  String get tableAddColumn => 'Dodaj kolumnę';
  @override
  String get cheatsheetTitle => 'Ściągawka Markdown';
  @override
  String get cheatsheetCopy => 'Kopiuj';
  @override
  String get cheatsheetCopied => 'Skopiowano';
  @override
  String get cheatsheetInsert => 'Wstaw do notatki';
  @override
  String get cheatsheetWritten => 'Zapis';
  @override
  String get cheatsheetShown => 'Wygląd';
  @override
  String get cheatHeadings => 'Nagłówki';
  @override
  String get cheatEmphasis => 'Pogrubienie, kursywa, przekreślenie';
  @override
  String get cheatHtmlFormats => 'Podkreślenie, indeks górny, indeks dolny';
  @override
  String get cheatLists => 'Listy';
  @override
  String get cheatChecklists => 'Listy kontrolne';
  @override
  String get cheatQuotes => 'Cytaty';

  @override
  String get cheatCallouts => 'Wyróżnione bloki';
  @override
  String get cheatLinks => 'Linki';
  @override
  String get cheatWikilinks => 'Linki do notatek';
  @override
  String get cheatEmbeds => 'Obrazy i osadzenia';
  @override
  String get cheatTags => 'Tagi';
  @override
  String get cheatInlineCode => 'Kod w zdaniu';
  @override
  String get cheatCodeBlocks => 'Bloki kodu';
  @override
  String get cheatMath => 'Matematyka';
  @override
  String get cheatTables => 'Tabele';
  @override
  String get cheatFootnotes => 'Przypisy';
  @override
  String get cheatRule => 'Linia pozioma';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatEpubMetadata => 'Metadane EPUB';
  @override
  String get cheatTemplates => 'Symbole zastępcze szablonów';
  @override
  String get menuAddLink => 'Dodaj link';
  @override
  String get menuAddExternalLink => 'Dodaj link zewnętrzny';
  @override
  String get menuFormat => 'Format';
  @override
  String get menuParagraph => 'Akapit';
  @override
  String get menuInsert => 'Wstaw';
  @override
  String get menuBody => 'Zwykły tekst';
  @override
  String get formatSubscript => 'Indeks dolny';
  @override
  String get formatInlineCode => 'Kod';
  @override
  String get insertFootnote => 'Przypis';
  @override
  String get insertRule => 'Linia pozioma';
  @override
  String get insertCodeBlock => 'Blok kodu';
  @override
  String get insertMathBlock => 'Blok matematyczny';
  @override
  String get menuHeadingWord => 'Nagłówek';
  @override
  String get toolbarHeading => 'Nagłówek';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Lista numerowana';
  @override
  String get toolbarChecklist => 'Lista kontrolna';
  @override
  String get toolbarQuote => 'Cytat';
  @override
  String get toolbarIndent => 'Wcinij';
  @override
  String get toolbarOutdent => 'Usuń wcięcie';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Narzędzia';
  @override
  String get editorToolsTitle => 'Narzędzia edytora';
  @override
  String get toolCountListTitle => 'Policz listę';
  @override
  String get toolCountListSubtitle =>
      'Sumuje to, co wymieniają wiersze, jako listę z polami wyboru';
  @override
  String get toolCountListNeedsList => 'Ta notatka nie ma listy do policzenia';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Czytaj każdy wiersz jako';
  @override
  String get tallyCutDash => 'Nazwa - wartości';
  @override
  String get tallyCutColon => 'Nazwa: wartości';
  @override
  String get tallyCutCommas => 'Wartości oddzielone przecinkami';
  @override
  String get tallyCutWhole => 'Cały wiersz jako jedna wartość';
  @override
  String get tallySortLabel => 'Kolejność';
  @override
  String get tallySortCount => 'Najwięcej najpierw';
  @override
  String get tallySortAlphabetical => 'Alfabetycznie';
  @override
  String get tallySortFirstSeen => 'W kolejności listy';
  @override
  String get tallyInsert => 'Wstaw';
  @override
  String get tallyUpdate => 'Zaktualizuj';
  @override
  String get tallyNothingToCount => 'Tu nie ma czego liczyć';
  @override
  String get headingDialogTitle => 'Poziom nagłówka';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Pasek narzędzi edytora';
  @override
  String get toolbarSettingsHint =>
      'Przeciągnij, aby zmienić kolejność; oko pokazuje lub ukrywa '
      'przycisk.';
  @override
  String get toolbarShowButton => 'Pokaż';
  @override
  String get toolbarHideButton => 'Ukryj';
  @override
  String get toolbarResetOrder => 'Przywróć domyślną';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Pokaż podgląd';
  @override
  String get showEditorTooltip => 'Pokaż edytor';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(surowa tabela HTML)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Szukaj w notatkach';
  @override
  String get searchModeWords => 'Słowa';
  @override
  String get searchModeContains => 'Zawiera';
  @override
  String get searchEmptyHint =>
      'Wpisz, aby przeszukać bibliotekę, lub klucz = wartość, aby '
      'filtrować po frontmatter';
  @override
  String get searchTooShortHint => 'Wpisz co najmniej 2 znaki';
  @override
  String get searchNoMatches => 'Brak wyników';
  @override
  String get searchLoadMore => 'Pokaż więcej';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Zamień…';
  @override
  String get replaceInNoteAction => 'Zamień w tej notatce…';
  @override
  String get replaceInThisNote => 'Zamień w tej notatce';
  @override
  String get replaceWithLabel => 'Zamień na';
  @override
  String get replaceCaseSensitive => 'Uwzględnij wielkość liter';
  @override
  String get replaceWholeWordsHint =>
      'zamieniane są tylko dokładne dopasowania całych słów';
  @override
  String get replaceConfirm => 'Zamień';
  @override
  String get replaceCancel => 'Zamknij';
  @override
  String get replaceUnavailable => 'Zamiana nie jest teraz dostępna';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Szukaj w notatce';
  @override
  String get editorFindHint => 'Szukaj';
  @override
  String get editorReplaceHint => 'Zamień';
  @override
  String get editorFindCaseTooltip => 'Uwzględnij wielkość liter';
  @override
  String get editorFindPreviousTooltip => 'Poprzednie dopasowanie';
  @override
  String get editorFindNextTooltip => 'Następne dopasowanie';
  @override
  String get editorFindCloseTooltip => 'Zamknij wyszukiwanie';
  @override
  String get editorFindReplaceModeTooltip => 'Tryb zamiany';
  @override
  String get editorReplaceOneTooltip => 'Zamień to dopasowanie';
  @override
  String get editorReplaceAllTooltip => 'Zamień wszystkie dopasowania';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tagi';
  @override
  String get tagsTitle => 'Tagi';
  @override
  String get tagsEmpty =>
      'Nie ma jeszcze tagów — dodaj #tag lub tagi w frontmatter';
  @override
  String get tagsBackTooltip => 'Wróć do wyszukiwania';
  @override
  String get tagsNotesEmpty => 'Brak notatek z tym tagiem';
  @override
  String tagsNotesCapped(int limit) =>
      'Pokażono tylko pierwsze $limit — wyszukaj tag, aby zawęzić';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Nie znaleziono linku';
  @override
  String get headingNotFoundTitle => 'Nie znaleziono nagłówka';
  @override
  String get ambiguousLinkTitle => 'Wiele notatek pasuje';
  @override
  String get openLinkFailed => 'Nie udało się otworzyć linku';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Notatka nie istnieje';
  @override
  String missingNoteDialogBody(String path) => 'Utworzyć „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Katalog „$folder“ nie istnieje';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Otwarte';
  @override
  String get todoDone => 'Ukończone';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Wszystkie daty';
  @override
  String get todoFilter => 'Filtruj';
  @override
  String get todoNoTokens => 'Brak tokenów na tej liście';
  @override
  String get todoCountOpen => 'otwarte';
  @override
  String get todoCountDone => 'ukończone';
  @override
  String get todoEmptyOpen => 'Nie ma jeszcze otwartych zadań';
  @override
  String get todoEmptyDone => 'Nic jeszcze nie jest ukończone';
  @override
  String get todoEmptyFiltered => 'Żadne zadanie nie pasuje';
  @override
  String get todoTitle => 'Do zrobienia';
  @override
  String get todoAddTooltip => 'Dodaj zadanie';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Format todo.txt';
  @override
  String get todoHelpTooltip => 'Informacje o formacie';
  @override
  String get todoHelpIntro =>
      'Twoje zadania to zwykły plik tekstowy, jedno zadanie na linię. '
      'Niman pisze składnię za Ciebie, ale nic nie ukrywa: możesz '
      'edytować plik w dowolnym edytorze, a Niman ponownie go odczyta.';
  @override
  String get todoHelpFilesTitle => 'Dwa pliki';
  @override
  String get todoHelpFilesBody =>
      'Otwarte zadania żyją w todo.txt w katalogu głównym biblioteki. '
      'Ukończ jedno, a linia trafi do done.txt, dzięki czemu todo.txt '
      'pozostaje krótkie. Jeśli zakończona linia znów trafi do todo.txt, '
      'Niman zarchiwizuje ją przy następnym odczycie plików.';
  @override
  String get todoHelpLineTitle => 'Anatomia linii';
  @override
  String get todoHelpLineBody =>
      'Wszystko przed opisem jest opcjonalne i musi występować w tej '
      'kolejności:';
  @override
  String get todoHelpDoneBody =>
      'Oznacza zadanie jako ukończone. Niman doda ją, gdy oznaczysz pole '
      'wyboru.';
  @override
  String get todoHelpPriority => '(A) do (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priorytet. A jest najwyższy. Pokazywany jako odznaka na liście.';
  @override
  String get todoHelpDatesBody =>
      'Data ukończenia, potem data utworzenia. Przy jednej dacie jest to '
      'data utworzenia, chyba że linia zaczyna się od x.';
  @override
  String get todoHelpTokensTitle => 'Projekty, konteksty i tagi';
  @override
  String get todoHelpTokensBody =>
      'W całym opisie słowo z dowolnym z tych prefiksów staje się '
      'filtrowalną etykietką. Nic nie jest zdefiniowane z góry: token '
      'istnieje, gdy go napiszesz.';
  @override
  String get todoHelpProjectBody =>
      'Do czego należy zadanie, np. +kuchnia lub +praca.';
  @override
  String get todoHelpContextBody =>
      'Gdzie lub jak to robisz, np. @dom lub @spotkania.';
  @override
  String get todoHelpHashtagBody =>
      'Dowolny tag na wszystko, czego nie obejmują dwie poprzednie.';
  @override
  String get todoHelpTagsTitle => 'Daty i przypomnienia';
  @override
  String get todoHelpTagsBody =>
      'To etykiety klucz:wartość. Niman pisze je z okna zadań i czyta '
      'je tam, gdzie się pojawiają w linii.';
  @override
  String get todoHelpDueBody =>
      'Termin. Steruje kolorem odznaki i filtrami dat.';
  @override
  String get todoHelpRemBody =>
      'Kiedy wysłać powiadomienie, w Twojej strefie czasowej. Zostaje '
      'wysłane, gdy ekran jest wyłączony, a aplikacja zamknięta.';
  @override
  String get todoHelpRemDesktop =>
      'Na komputerze Niman musi działać w momencie terminu: przypomnienie '
      'pokazuje się, gdy aplikacja jest otwarta, i nic się nie '
      'wyświetli, gdy jest zamknięta.';
  @override
  String get todoHelpOtherBody =>
      'Zachowane dokładnie tak, jak zapisano, by etykiety z innych '
      'aplikacji todo.txt przetrwały podróż. Niman nie działa na nich, '
      'rec: included: zadanie cykliczne jeszcze się nie powtarza.';
  @override
  String get todoHelpEditTitle => 'Edycja poza Niman';
  @override
  String get todoHelpEditBody =>
      'Zadanie, którego nie dotkniesz, zostanie przepisane bajt po '
      'bajcie, łącznie ze swoistymi odstępami. Zedytuj linię, a Niman '
      'przepisze tylko tę linię w swoim kanonicznym formacie i zostawi '
      'resztę pliku nietkniętą.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Dodaj zadanie';
  @override
  String get todoEditTitle => 'Edytuj zadanie';
  @override
  String get todoDescriptionHint => 'Opis';
  @override
  String get todoCancel => 'Anuluj';
  @override
  String get todoSave => 'Zapisz';
  @override
  String get todoEditAction => 'Edytuj';
  @override
  String get todoDeleteAction => 'Usuń';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Po terminie';
  @override
  String get todoDueToday => 'Dziś';
  @override
  String get todoDueNext7 => 'Następne 7 dni';
  @override
  String get todoDueNoDate => 'Bez daty';
  @override
  String get todoRowDue => 'Termin';
  @override
  String get todoRowDueToday => 'Termin dziś';
  @override
  String get todoSortTooltip => 'Sortuj';
  @override
  String get todoSortDue => 'Data terminu';
  @override
  String get todoSortPriority => 'Priorytet';
  @override
  String get todoSortCreation => 'Data utworzenia';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez priorytetu';
  @override
  String get todoNoPriorityShort => 'Brak';
  @override
  String get todoMorePriorities => 'Więcej…';
  @override
  String get todoPriorityTitle => 'Priorytet';
  @override
  String get todoNoDueDate => 'Bez daty terminu';
  @override
  String get todoNoReminder => 'Bez przypomnienia';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Przypomnienia zadań';
  @override
  String get todoReminderChannelDescription =>
      'Zaplanowane powiadomienia dla zadań z godziną przypomnienia.';
  @override
  String get todoReminderBody => 'Przypomnienie zadania';
  @override
  String get todoReminderFallbackTitle => 'Przypomnienie zadania';
  @override
  String get todoReminderBlocked =>
      'Powiadomienia są wyłączone, więc przypomnienia nie będą '
      'pokazywane.';
  @override
  String get todoReminderBattery =>
      'Optymalizacja baterii jest włączona dla Niman. System może '
      'wstrzymać aplikację i utracić oczekujące przypomnienia.';
  @override
  String get todoReminderInexact =>
      'To urządzenie nie obsługuje dokładnych alarmów, więc '
      'przypomnienie może przyjść kilka minut później, gdy ekran jest '
      'wyłączony.';
  @override
  String get reminderShowTokensTitle =>
      'Tagi w powiadomieniach o przypomnieniach';
  @override
  String get reminderShowTokensSubtitle =>
      'Zostaw +projekt, @kontekst i #tag w tekście powiadomienia. '
      'Wyłączone pokaże tylko zadanie, które napisałeś.';
  @override
  String get todoReminderFixAction => 'Otwórz ustawienia';
  @override
  String get todoReminderDismissAction => 'Odrzuć';
  @override
  String get todoReminderDue => 'Termin';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Anuluj';
  @override
  String get actionCreate => 'Utwórz';
  @override
  String get actionNew => 'Nowa';
  @override
  String get actionSave => 'Zapisz';
  @override
  String get actionClear => 'Wyczyść';
  @override
  String get actionChoose => 'Wybierz';
  @override
  String get actionDelete => 'Usuń';
  @override
  String get actionRename => 'Zmień nazwę';
  @override
  String get actionMove => 'Przenieś';
  @override
  String get saveAndClose => 'Zapisz i zamknij';
  @override
  String get closeUnsavedTitle => 'Niezapisane zmiany';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” ma niezapisane zmiany. '
          'Zapisz je przed zamknięciem?';
    }
    return '${names.length} notatki mają niezapisane zmiany. '
        'Zapisz je przed zamknięciem?';
  }

  @override
  String get closeSaveFailed => 'Nie udało się zapisać; pozostaje otwarta.';
  @override
  String get actionRestore => 'Przywróć';
  @override
  String get actionEmpty => 'Opróżnij';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ukryj panel boczny (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Pokaż panel boczny (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Zminimalizuj';
  @override
  String get windowMaximizeTooltip => 'Zmaksymalizuj';
  @override
  String get windowRestoreTooltip => 'Przywróć';
  @override
  String get windowCloseTooltip => 'Zamknij';
  @override
  String get tabFiles => 'Pliki';
  @override
  String get tabSearch => 'Szukaj';
  @override
  String get tabSettings => 'Ustawienia';
  @override
  String get quickNoteTitle => 'Szybka notatka';
  @override
  String get treeEmpty => 'Nie ma jeszcze notatek';
  @override
  String get selectANote => 'Wybierz notatkę';
  @override
  String get showListTooltip => 'Pokaż listę';
  @override
  String get editRawTooltip => 'Edytuj surowo';
  @override
  String get sortAscTooltip => 'Sortuj A-Z';
  @override
  String get sortDescTooltip => 'Sortuj Z-A';
  @override
  String get newNoteTitle => 'Nowa notatka';
  @override
  String get newItemTooltip => 'Nowy';
  @override
  String get closeMenuTooltip => 'Zamknij';
  @override
  String get newFolderTitle => 'Nowy katalog';
  @override
  String get newNoteSameFolder => 'Nowa notatka w tym samym folderze';
  @override
  String get newFromTemplateSameFolder =>
      'Nowa z szablonu w tym samym folderze';
  @override
  String trashOriginalPath(String path) => 'była w $path';
  @override
  String get trashOriginalRoot =>
      'by\u0142o w katalogu g\u0142\u00f3wnym biblioteki';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 element' : '$count element\u00f3w';
  @override
  String get newNoteHere => 'Nowa notatka tutaj';
  @override
  String get newFolderHere => 'Nowy katalog tutaj';
  @override
  String get newListNoteTitle => 'Nowa notatka-lista';
  @override
  String get newListNoteDefault => 'Moja lista';
  @override
  String get setAsQuickNote => 'Ustaw jako szybką notatkę';
  @override
  String get currentQuickNote => 'Aktualna szybka notatka';
  @override
  String get pinnedSection => 'Przypięte';
  @override
  String pinnedSectionCount(int count) => 'Przypięte · $count';
  @override
  String get templateFolderTitle => 'Katalog szablonów';
  @override
  String get newFromTemplateTitle => 'Nowa ze szablonu';
  @override
  String get newFromTemplateHere => 'Nowa ze szablonu tutaj';
  @override
  String get templateFormTitle => 'Wypełnij szablon';
  @override
  String get templateFormBacklink => 'Powiązane z';
  @override
  String get templateFormNoNote => 'Bez notatki';
  @override
  String get templateFormPickNote => 'Wybierz notatkę';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Placeholdery szablonu';
  @override
  String get templateHelpSubtitle =>
      'Data, tytuł i pozostałe wartości do wypełnienia';
  @override
  String get quickNoteSubtitle => 'Notatka, którą otwiera karta Szybka notatka';
  @override
  String get listFolderSubtitle => 'Nowe listy zadań';
  @override
  String get templateFolderSubtitle => 'Źródło „Nowa z szablonu“';
  @override
  String get attachmentsFolderSubtitle =>
      'Obrazy i dźwięk wstawione do notatki';
  @override
  String get templateHelpIntro =>
      'Szablon to zwykła notatka z dziurami. Utworzenie notatki z niego '
      'kopiuje tekst i wypełnia dziury.';
  @override
  String get templateHelpUnknown =>
      'Placeholder nieznany Nimanowi pozostaje dokładnie tak, jak '
      'zapisany, więc literówka pojawi się w notatce, zamiast cicho '
      'zepsuć linię.';
  @override
  String get templateHelpValuesTitle => 'Wartości';
  @override
  String get templateHelpTitleBody =>
      'Nazwa, pod którą należy utworzyć notatkę.';
  @override
  String get templateHelpDateBody =>
      'Dziś oraz bieżąca godzina. Oba przyjmują format: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data i godzina razem.';
  @override
  String get templateHelpUuidBody =>
      'Nowy identyfikator, inny przy każdym użyciu.';
  @override
  String get templateHelpCounterBody =>
      'Liczba licząca według nazwy, zachowywana między restartami: '
      'pierwsza notatka zapisze 1, następna 2. Ta sama nazwa w notatce '
      'zapisze tę samą liczbę; połącz z |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Ustaw kursor tutaj przy tworzeniu notatki; znacznik nie jest '
      'zapisywany. Pierwszy znacznik wygrywa, bez filtrów, tylko nowe '
      'notatki — i klawiatura otworzy się też przy wyłączonym '
      'autofokisie.';
  @override
  String get templateHelpDatesTitle => 'Zapisywanie daty';
  @override
  String get templateHelpDatesBody =>
      'One reprezentują części daty w formacie. Wszystko, co nie jest '
      'częścią daty, jest dosłowne, również tekst w pojedynczych '
      'cudzysłowach. Miesiące i dni tygodnia zależą od języka aplikacji.';
  @override
  String get templateHelpYear => 'rok: 2026, 26';
  @override
  String get templateHelpMonth => 'miesiąc: 03, 3, marzec, mar';
  @override
  String get templateHelpDay => 'dzień: 09, 9, poniedziałek, pon';
  @override
  String get templateHelpTime => 'godziny, minuty, sekundy';
  @override
  String get templateHelpWeek => 'tydzień ISO i kwartał: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtry';
  @override
  String get templateHelpFiltersBody =>
      'Wartość może być połączona z filtrami, stosowanymi z lewej na '
      'prawą.';
  @override
  String get templateHelpCaseBody =>
      'Wielkie, małe i wielka pierwsza litera każdego słowa — słowo, '
      'które napisałeś z wielką pierwszą literą, nie jest zmieniane.';
  @override
  String get templateHelpSlugBody =>
      'Postać linku tekstu, by zbudować link wiki.';
  @override
  String get templateHelpPadBody =>
      'Przycinaj końce; dopełniaj zerami do szerokości; używaj '
      'alternatywy, gdy wartość jest pusta.';
  @override
  String get templateHelpShiftBody =>
      'Przesuń datę o dni, tygodnie, miesiące lub lata — konferencja '
      'przyszłego tygodnia, plik z poprzedniego miesiąca.';
  @override
  String get templateHelpSnapBody =>
      'Przypnij datę do początku lub końca tygodnia, miesiąca lub roku.';
  @override
  String get templateHelpAskTitle => 'Pytanie do Ciebie';
  @override
  String get templateHelpAskBody =>
      'Formularz pokazuje się przed utworzeniem notatki, jedno pole na '
      'pytanie — i jedno dla linku powrotnego, gdy szablon tego wymaga. '
      'Ta sama etykieta dwa razy to pytanie, a jej odpowiedź wypełnia '
      'wszystkie wystąpienia — włącznie z katalogiem i nazwą pliku.';
  @override
  String get templateHelpAskFieldBody =>
      'Pole do wpisywania; tekst po drugim dwukropku jest początkiem.';
  @override
  String get templateHelpChoiceBody => 'Wybór z listy, oddzielony przecinkami.';
  @override
  String get templateHelpWhereTitle => 'Gdzie trafi notatka';
  @override
  String get templateHelpWhereBody =>
      'To nie tekst: to instrukcje, które żyją w bloku niman: we '
      'frontmatterze szablonu. Blok wykonuje się i usuwa, więc nigdy nie '
      'jest pokazywany w notatce. Jego wartość może zawierać placeholdery.';
  @override
  String get templateHelpFolderBody =>
      'Katalog, w którym utworzona zostanie notatka, tworzony, jeśli nie '
      'istnieje. Bez niego notatka trafi tam, gdzie byłeś.';
  @override
  String get templateHelpFilenameBody =>
      'Jak ma się nazywać notatka. Szablon, który to mówi, nie prosi o '
      'nazwę.';
  @override
  String get templateHelpAppendBody =>
      'Dopisz do notatki, jeśli już istnieje, zamiast tworzyć kolejną. '
      'To dzięki temu miesiąc spotkań to jeden plik.';
  @override
  String get templateHelpOpenBody =>
      'Co się dzieje, gdy notatka istnieje: edytor (domyślnie), podgląd, '
      'albo nic — notatka jest archiwizowana i zostajesz tam, gdzie '
      'byłeś.';
  @override
  String get templateHelpAroundTitle => 'Skąd przyszła';
  @override
  String get templateHelpParentBody =>
      'Notatka, którą wybierasz w formularzu, oferowana na ekranie; '
      'zapisz [[{{parent}}]], by stworzyć link powrotny.';
  @override
  String get templateHelpFolderValueBody =>
      'Katalog, w którym trafiła notatka.';
  @override
  String get templateHelpClipboardBody =>
      'Co jest w schowku i zaznaczenie w edytorze, gdy notatka '
      'rozpoczęła się z niego.';
  @override
  String get templateHelpIncludeTitle => 'Ponowne użycie części';
  @override
  String get templateHelpIncludeBody =>
      'Wklej inny szablon, tak by dziesięć szablonów mogło dzielić '
      'jedną listę kontrolną. Szukany najpierw w katalogu szablonów, '
      'a .md można pominąć. Jego własne pytania wchodzą do tego samego '
      'formularza.';
  @override
  String get templateHelpExampleTitle => 'Wszystko razem';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nie ma szablonu „$path”';
  @override
  String includeCycle(String path) => '⚠ „$path” zawiera samą siebie';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path” jest zbyt głęboko zagnieżdżony';
  @override
  String frontmatterInvalid(String reason) =>
      'Nieprzeczytany frontmatter: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter „$template” nie mógł zostać przeczytany, więc katalog '
      'i nazwa pliku nie zadziałały: $reason';
  @override
  String get templatePickerTitle => 'Wybór szablonu';
  @override
  String templatePickerEmpty(String folder) =>
      'Nie ma jeszcze szablonów. Włóż notatkę w $folder/ i będzie.';

  // Tree actions.
  @override
  String get actionPin => 'Przypnij';
  @override
  String get actionUnpin => 'Odepnij';
  @override
  String get pinToWidget => 'Przypnij do widgeta ekranu głównego';
  @override
  String get pinnedForWidget =>
      'Przypięto: umieść teraz widget Notatka na ekranie głównym';
  @override
  String get pinWidgetUnavailable =>
      'Widgety ekranu głównego są dostępne w Androidzie';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Pokaż w menedżerze plików';
  @override
  String get openInDefaultApp => 'Otwórz w domyślnej aplikacji';
  @override
  String get newNoteTabTooltip => 'Nowa notatka w nowej karcie';
  @override
  String get openNotesTooltip => 'Otwarte notatki';
  @override
  String get closeTabTooltip => 'Zamknij';
  @override
  String get openInNewTab => 'Otwórz w nowej karcie';
  @override
  String get splitRight => 'Podziel w prawo';
  @override
  String get splitDown => 'Podziel w dół';
  @override
  String get moveToOtherPane => 'Przenieś do drugiego panelu';
  @override
  String get openBeside => 'Otwórz obok';
  @override
  String get closeAllNotes => 'Zamknij wszystkie';
  @override
  String get sidePanelTooltip => 'Pokaż lub ukryj panel boczny';
  @override
  String get historyAllVersions => 'Wszystkie wersje';
  @override
  String get commandPaletteTitle => 'Paleta poleceń';
  @override
  String get goToNoteTitle => 'Przejdź do notatki';
  @override
  String get paletteGroupNote => 'Notatka';
  @override
  String get paletteGroupEditor => 'Edytor';
  @override
  String get paletteGroupView => 'Widok';
  @override
  String get paletteGroupLibrary => 'Biblioteka';
  @override
  String get paletteGroupGoTo => 'Przejdź do';
  @override
  String get paletteGroupJournal => 'Dziennik';
  @override
  String get journalToday => 'Dzisiejszy wpis';
  @override
  String get journalPrevious => 'Poprzedni wpis';
  @override
  String get journalNext => 'Następny wpis';
  @override
  String get commandNeedJournalEntry => 'Wymaga otwartego wpisu dziennika';
  @override
  String journalCreateAsk(String day) =>
      'Brak jeszcze wpisu na $day. Utworzyć?';
  @override
  String journalTemplateMissing(String path) =>
      'Nie udało się odczytać szablonu dziennika $path: wpis utworzono bez '
      'niego.';
  @override
  String get journalIntro =>
      'Jedna notatka dziennie, tworzona z szablonu przy pierwszym otwarciu '
      'danego dnia. Te ustawienia podróżują z biblioteką.';
  @override
  String get journalFolderTitle => 'Folder dziennika';
  @override
  String get journalFolderSubtitle => 'Gdzie trafiają wpisy';
  @override
  String get journalEntryNameTitle => 'Nazwa wpisu';
  @override
  String get journalEntryNameSubtitle =>
      'YYYY, MM lub M, DD lub D dla daty; / tworzy folder; tekst w '
      "'cudzysłowie' zostaje bez zmian";
  @override
  String journalEntryNamePreview(String path) => 'Dzisiejszy wpis: $path';
  @override
  String get journalEntryNameInvalid =>
      'Wymaga YYYY, miesiąca (MM lub M) i dnia (DD lub D), i niczego, czego '
      'nie może zawierać nazwa pliku';
  @override
  String get journalTemplateTitle => 'Szablon';
  @override
  String get journalTemplateSubtitle => 'Od czego zaczyna się nowy wpis';
  @override
  String get journalTemplateNone => 'Brak: nagłówek z datą';
  @override
  String get journalDayStartTitle => 'Nowy dzień zaczyna się o';
  @override
  String get journalDayStartSubtitle =>
      'Późno? O 04:00 noc wciąż należy do poprzedniego dnia';
  @override
  String get journalRecent => 'Ostatnie';
  @override
  String get journalNoEntry => 'Brak wpisu na ten dzień';
  @override
  String get journalOpenEntry => 'Otwórz';
  @override
  String get journalShowCalendar => 'Pokaż kalendarz';
  @override
  String get journalFabToday => 'Dzisiejszy wpis w dzienniku';
  @override
  String journalDueOn(String day) => 'Termin: $day';
  @override
  String get commandsTitle => 'Polecenia';
  @override
  String get commandsIntro =>
      'Paleta poleceń pokazuje tylko polecenia, które można wykonać tam, '
      'gdzie jesteś. Tu są wszystkie i kiedy każde się pojawia.';
  @override
  String get commandsKeysNote =>
      'Tutaj nic się nie zmienia. Klawisze to te ustawione w sekcji „Skróty '
      'klawiszowe” i podążają za każdą zmianą tam.';
  @override
  String get commandsOpenShortcuts =>
      'Zmień klawisze w sekcji „Skróty klawiszowe”';
  @override
  String get commandsChangeKeyTooltip => 'Zmień w sekcji „Skróty klawiszowe”';
  @override
  String get commandsSubtitle => 'Co może uruchomić paleta poleceń, i kiedy';
  @override
  String get keyboardShortcutsSubtitle => 'Zmień klawisze każdego polecenia';
  @override
  String get commandNeedNone => 'Zawsze dostępne';
  @override
  String get commandNeedOpenNote => 'Wymaga otwartej notatki';
  @override
  String get commandNeedTextNote => 'Wymaga otwartej notatki tekstowej';
  @override
  String get commandNeedWideWindow => 'Tylko w szerokim oknie';
  @override
  String get commandNeedDockRoom =>
      'Wymaga okna wystarczająco szerokiego na panel boczny';
  @override
  String get commandNeedDesktop => 'Tylko na komputerze';
  @override
  String get commandNeedNotInZen => 'Nie w trybie Zen';
  @override
  String get commandNeedZenRoom => 'Komputer, z notatką otwartą w karcie';
  @override
  String get commandNeedPreview => 'Z włączonym podglądem, w notatce tekstowej';
  @override
  String get commandNeedTwoEditors => 'Gdy oba edytory są włączone';
  @override
  String get paletteHint => 'Szukaj poleceń i notatek';
  @override
  String get paletteNoResults => 'Brak wyników';
  @override
  String get paletteCommands => 'Polecenia';
  @override
  String get paletteNotes => 'Notatki';
  @override
  String get paletteFooter => '↑↓ aby przejść · ↵ aby użyć · esc aby zamknąć';
  @override
  String get paletteFooterTouch =>
      'Dotknij, aby użyć · pinezka trzyma na górze';
  @override
  String get palettePinned => 'Przypięte';
  @override
  String get palettePin => 'Przypnij';
  @override
  String get paletteUnpin => 'Odepnij';
  @override
  String get palettePinFooter => 'alt+P przypina';
  @override
  String get spellCheckScanning => 'Sprawdzanie notatki…';
  @override
  String get spellCheckAgain => 'Sprawdź ponownie';
  @override
  String spellCheckCapped(int count) =>
      'Wyświetlono pierwsze $count: popraw kilka, a potem sprawdź ponownie '
      'resztę';
  @override
  String get dropHint =>
      'Upuść pliki Markdown, aby je otworzyć, lub folder, aby go zaimportować';
  @override
  String get dropNothing =>
      'Pulpit nie przekazał żadnych plików przy tym upuszczeniu.';
  @override
  String get importFolderAction => 'Importuj';
  @override
  String dropRejected(String names) =>
      'Tu otwierają się tylko pliki Markdown i foldery: $names';
  @override
  String importFolderTitle(String name) => 'Zaimportować „$name”?';
  @override
  String importFolderBody(int count) =>
      'Jego pliki Markdown ($count) zostaną skopiowane do nowego folderu '
      'biblioteki. Upuszczony folder pozostaje bez zmian.';
  @override
  String importFolderDone(String folder) => 'Zaimportowano do $folder';
  @override
  String importFolderEmpty(String name) => 'Brak plików Markdown w $name';
  @override
  String get openFileTitle => 'Otwórz plik';
  @override
  String get outsideFileNote =>
      'Poza biblioteką: zapisywany na miejscu, bez indeksu, bez historii, '
      'łącza nie są otwierane';
  @override
  String get typewriterOn => 'Włącz tryb maszyny do pisania';
  @override
  String get typewriterOff => 'Wyłącz tryb maszyny do pisania';
  @override
  String get typewriterTitle => 'Tryb maszyny do pisania';
  @override
  String get formatNoteTitle => 'Uporządkuj Markdown';
  @override
  String get formatNoteDone => 'Notatka została uporządkowana.';
  @override
  String get exportTitle => 'Eksportuj';
  @override
  String get exportFormatMarkdown => 'Markdown';
  @override
  String get exportFormatHtml => 'HTML';
  @override
  String exportDone(String place) => 'Wyeksportowano do $place';
  @override
  String exportFailed(Object error) => 'Eksport nie powiódł się: $error';
  @override
  String get exportFolderTitle => 'Eksportuj folder…';
  @override
  String get exportLibraryTitle => 'Eksportuj bibliotekę…';
  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatEpub => 'EPUB';

  @override
  String get exportEpubNoMetadataTitle => 'Książka bez metadanych';
  @override
  String get exportEpubNoIndex =>
      'Ten folder nie ma pliku index.md w katalogu głównym. Książka '
      'będzie nosić nazwę folderu i nie będzie mieć autora, okładki '
      'ani serii.';
  @override
  String get exportEpubNoFrontmatter =>
      'index.md nie ma frontmatter. Książka będzie nosić nazwę folderu '
      'i nie będzie mieć autora, okładki ani serii.';
  @override
  String get exportEpubAnyway => 'Eksportuj mimo to';
  @override
  String get exportPdfPicture =>
      'PDF to obraz stron; zainstaluj przeglądarkę, aby tekst można było '
      'zaznaczać.';
  @override
  String get formatNoteAlreadyTidy => 'Notatka była już uporządkowana.';
  @override
  String get lintRulesTitle => 'Reguły Markdown';
  @override
  String get lintRulesSubtitle =>
      'Co porządkuje upraszczanie: puste wiersze na listach, pola zadań, '
      'odstępy po znaczniku i bloki kodu.';
  @override
  String get lintRulesReset => 'Przywróć domyślne';
  @override
  String lintRulesValue(int on, int all) =>
      on >= all ? 'Wszystkie $all' : '$on z $all';
  @override
  String get lintRuleTightLists => 'Zwarte listy';
  @override
  String get lintRuleTaskMarker => 'Pola zadań';
  @override
  String get lintRuleListSpacing => 'Odstępy listy';
  @override
  String get lintRuleClosingFence => 'Zamknięcie bloku kodu';
  @override
  String get lintRuleFenceLanguage => 'Język bloku kodu';
  @override
  String get tidyOnCloseTitle => 'Porządkuj Markdown przy zamykaniu';
  @override
  String get tidyOnCloseSubtitle =>
      'Gdy zamykasz edytowaną notatkę, jej Markdown jest porządkowany jak '
      'poleceniem „Uporządkuj Markdown”. Notatki większe niż 4 MB pozostają '
      'bez zmian.';
  @override
  String get typewriterSubtitle =>
      'Wiersz, który piszesz, zostaje na środku edytora';
  @override
  String get zenMode => 'Tryb zen';
  @override
  String get zenModeEnter => 'Włącz tryb zen';
  @override
  String get zenModeLeave => 'Wyjdź z trybu zen';
  @override
  String get keySpace => 'Spacja';
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
  String get keyArrowUp => 'W górę';
  @override
  String get keyArrowDown => 'W dół';
  @override
  String get keyArrowLeft => 'W lewo';
  @override
  String get keyArrowRight => 'W prawo';
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
  String get shortcutNone => 'Brak skrótu';
  @override
  String get shortcutRestoreDefaults => 'Przywróć domyślne';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Przywrócić wszystkie skróty tak, jak dostarcza je Niman?';
  @override
  String get shortcutRevert => 'Przywróć domyślny';
  @override
  String get shortcutClear => 'Usuń skrót';
  @override
  String get shortcutCapturePrompt =>
      'Naciśnij klawisze. Esc i Tab też są przechwytywane: wyjście przez '
      'Anuluj.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Dodaj Ctrl, Alt lub Meta: sam klawisz służy do pisania.';
  @override
  String get shortcutMove => 'Przenieś';
  @override
  String get shortcutUseAnyway => 'Użyj mimo to';
  @override
  String get shortcutUndo => 'Cofnij';
  @override
  String get shortcutRedo => 'Ponów';
  @override
  String get shortcutChange => 'Zmień skrót';
  @override
  String shortcutCaptureTitle(String command) => 'Klawisze dla: $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys należy już do: $other. Przenieść tutaj? $other zostanie bez '
      'skrótu.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys to także $what w polach tekstowych i edytorze. Tam przejmie go '
      'Twoje polecenie.';
  @override
  String get openFileMissing => 'Pliku tej notatki nie ma na dysku';
  @override
  String get openFileFailed =>
      'Nie udało się otworzyć tej notatki poza Nimanem';
  @override
  String get attachmentUnreadable => 'Nie udało się wyświetlić tego pliku.';
  @override
  String get attachmentMissing => 'Tego pliku nie ma na dysku.';
  @override
  String get attachmentOpenFailed =>
      'Nie udało się otworzyć tego pliku poza Nimanem.';
  @override
  String get copyPlaceLink => 'Kopiuj link do tego miejsca';
  @override
  String get placeLinkCopied => 'Skopiowano link';
  @override
  String pdfPageLabel(String name, int page) => '$name, s. $page';
  @override
  String get annotationsFolderTitle => 'Folder adnotacji';
  @override
  String get annotationsFolderSubtitle =>
      'Notatki z adnotacjami do PDF-a lub książki';
  @override
  String get annotationNoteSuffix => 'Adnotacja';
  @override
  String get annotateAction => 'Dodaj adnotację';
  @override
  String get annotationCommentHint => 'Twój komentarz';
  @override
  String get annotationSaved => 'Zapisano adnotację';
  @override
  String get annotationOpenNote => 'Otwórz notatkę';
  @override
  String get annotationFailed => 'Nie udało się zapisać adnotacji';

  @override
  String get movedToTrash => 'Przeniesiono do kosza';
  @override
  String get deletedMessage => 'Usunięto';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name zostanie przeniesione do .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name zostanie trwale usunięte';
  @override
  String get chooseDestination => 'Wybierz cel';
  @override
  String get libraryRoot => 'Katalog główny biblioteki';
  @override
  String moveTitle(String name) => 'Przenieś $name';
  @override
  String headingLevelLabel(int level) => 'Nagłówek $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Nie ma jeszcze szybkiej notatki. Wybierz istniejącą notatkę lub '
      'utwórz — szybka notatka otworzy się tutaj.';
  @override
  String get quickNoteChooseAction => 'Wybierz notatkę…';
  @override
  String get quickNoteCreateAction => 'Utwórz nową notatkę…';
  @override
  String get quickNoteNewTitle => 'Nowa szybka notatka';
  @override
  String get quickNotePickerTitle => 'Wybór szybkiej notatki';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nowy katalog';
  @override
  String get folderPickerEmpty => 'Nie ma jeszcze katalogów';
  @override
  String get listFolderTitle => 'Katalog list';
  @override
  String get attachmentsFolderTitle => 'Katalog załączników';

  // Trash (M1).
  @override
  String get trashEmpty => 'Kosz jest pusty';
  @override
  String get trashEmptyAction => 'Opróżnij kosz';
  @override
  String get trashEmptyConfirm =>
      'To trwale usunie wszystko, co jest w koszu, również elementy, '
      'których Niman nie umieścił.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name zostanie trwale usunięte (bez przywracania)';
  @override
  String get trashDeletePermanently => 'Usuń trwale';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Otwórz katalog notatek Markdown jako bibliotekę';
  @override
  String get openLibraryExisting => 'Otwórz istniejący';
  @override
  String get openLibraryCreate => 'Utwórz nowy';
  @override
  String get openLibraryCreateTitle => 'Utwórz nową bibliotekę';
  @override
  String get openLibraryFolderName => 'Nazwa katalogu';
  @override
  String get openLibraryChooseFolder => 'Wybierz katalog biblioteki';
  @override
  String get openLibraryChooseParent =>
      'Wybierz katalog, w którym będzie utworzona biblioteka';
  @override
  String get openLibraryUnsupported =>
      'Ten katalog nie jest obsługiwany. Wybierz katalog w pamięci '
      'urządzenia.';
  @override
  String indexingCount(int done, int total) => '$done z $total notatek';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Twoje biblioteki';
  @override
  String get libraryUnreachable => 'Niedostępna';
  @override
  String get libraryOpenedToday => 'Otwarta dziś';
  @override
  String get libraryOpenedYesterday => 'Otwarta wczoraj';
  @override
  String libraryOpenedDaysAgo(int days) => 'Otwarta $days dni temu';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Otwarta ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Otwarta teraz';
  @override
  String get switchLibraryTitle => 'Zmień bibliotekę';
  @override
  String get libraryForget => 'Zapomnij';
  @override
  String libraryForgetTitle(String name) => 'Zapomnieć „$name”?';
  @override
  String get libraryForgetExplained =>
      'Zniknie z tej listy. Katalog, notatki i ustawienia biblioteki '
      'w niej nie zostaną dotknięte, a ponowne otwarcie ją przywróci.';

  @override
  String get libraryForgetOpenExplained =>
      'Ta biblioteka jest teraz otwarta: najpierw zostanie zamknięta, a '
      'potem zniknie z listy. Folder, notatki i ustawienia biblioteki w nim '
      'pozostają nietknięte, a ponowne otwarcie przywróci ją z powrotem.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Udziel dostęp do plików';
  @override
  String get storageAccessNeeded =>
      'Niman nie może czytać Twoich notatek bez „Dostępu do wszystkich '
      'plików”. Udziel go, aby otworzyć bibliotekę.';
  @override
  String get storageAccessExplained =>
      'Niman czyta Twoje notatki jako zwykłe pliki, więc Android musi '
      'udzielić mu dostępu do wszystkich plików. Nic nie jest '
      'wysyłane i tylko katalog biblioteki, który wybierzesz, jest '
      'czytany.';
  @override
  String folderAccessDenied(Object error) =>
      'System nie udzielił dostępu do katalogu: $error';
  @override
  String folderPickFailed(Object error) =>
      'Nie udało się wybrać katalogu: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Ustawienia';
  @override
  String get libraryPathTitle => 'Ścieżka biblioteki';
  @override
  String get reindexTitle => 'Przeindeksuj teraz';
  @override
  String get reindexDone => 'Przeindeksowanie zakończone';
  @override
  String get closeLibraryTitle => 'Zamknij bibliotekę';
  @override
  String get exportLogTitle => 'Eksportuj log debugowania';
  @override
  String get exportLogSubtitle =>
      'Zapisz zarejestrowane zdarzenia w wybranym pliku';
  @override
  String get exportLogEmpty => 'Bufor logu debugowania jest pusty';
  @override
  String get quickNoteUnset => 'Nieustawione';
  @override
  String exportLogDone(Object target) =>
      'Log debugowania wyeksportowany do $target';
  @override
  String exportLogFailed(Object error) => 'Eksport nie powiódł się: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nie znaleziono dokładnego dopasowania całego słowa dla “$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Zamieniono $occurrences wystąpień “$term” w $notes notatkach';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped otwartych notatek pominięto)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nie znaleziono dokładnego dopasowania całego słowa dla “$term”'
      '${only == null ? '' : ' w $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'O aplikacji';
  @override
  String get versionTitle => 'Wersja';
  @override
  String get changelogTitle => 'Dziennik zmian';
  @override
  String get changelogEmpty => 'Brak wpisów w dzienniku zmian';
  @override
  String changelogWhatsNew(String version) => 'Nowości w wersji $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historia';
  @override
  String get noteMenuTooltip => 'Działania na notatce';
  @override
  String get historyCurrentVersion => 'Bieżąca wersja';
  @override
  String get historyCurrentSubtitle => 'Notatka w obecnej postaci';
  @override
  String get historyToday => 'Dzisiaj';
  @override
  String get historyYesterday => 'Wczoraj';
  @override
  String get historyReasonSession => 'przed edycją';
  @override
  String get historyReasonInterval => 'podczas edycji';
  @override
  String get historyReasonRestore => 'przed przywróceniem';
  @override
  String get historyReasonSync => 'przed synchronizacją';
  @override
  String get historyReasonReplace => 'przed zamianą';
  @override
  String get historyReasonUnknown => 'odzyskana';
  @override
  String get historySyncBase => 'baza synchronizacji';
  @override
  String get historyEmpty =>
      'Brak wersji. Niman zachowuje jedną, gdy zaczynasz edytować notatkę, '
      'a potem najwyżej jedną co kilka minut podczas pisania.';
  @override
  String historyKept(int kept, int limit) => 'Zachowano $kept z $limit wersji';
  @override
  String get historyBaseKept =>
      'Baza synchronizacji jest zachowywana ponad limit.';
  @override
  String get historyOff =>
      'Historia jest wyłączona dla tej biblioteki (Ustawienia, Biblioteka).';
  @override
  String get historyLoadFailed => 'Nie udało się odczytać historii';
  @override
  String get historyCompareSubtitle => 'W porównaniu z bieżącą wersją';
  @override
  String get historyTabChanges => 'Zmiany';
  @override
  String get historyTabVersion => 'Wersja';
  @override
  String get historyNoChanges => 'Taki sam tekst jak w bieżącej wersji.';
  @override
  String get historyRestoreAction => 'Przywróć tę wersję';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Przywrócić wersję z $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Bieżący tekst zostanie najpierw zapisany w historii, więc zawsze '
      'możesz wrócić.';
  @override
  String get historyRestoreConfirm => 'Przywróć';
  @override
  String historyRestored(String when) => 'Przywrócono wersję z $when';
  @override
  String get historyRestoreFailed => 'Nie udało się przywrócić wersji';
  @override
  String get actionUndo => 'Cofnij';
  @override
  String diffLineRange(int start, int end) => 'Linie $start–$end';
  @override
  String diffLineSingle(int line) => 'Linia $line';
  @override
  String diffUnchanged(int count) => count == 1
      ? '1 niezmieniona linia'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? '$count niezmienione linie'
      : '$count niezmienionych linii';
  @override
  String get historyTakeHunk => 'Przywróć tutaj';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Przywróć 1 zmianę' : 'Przywróć $count zmian';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Wybrane zmiany wracają do tekstu tej wersji. Notatka w obecnej postaci '
      'jest najpierw zachowywana jako wersja, więc możesz to cofnąć.';
  @override
  String get historyNoteChangedReloaded =>
      'Notatka zmieniła się, gdy tu byłeś — porównanie zostało odświeżone.';
  @override
  String get historyVersionsTitle => 'Liczba wersji do zachowania';
  @override
  String get historyVersionsSubtitle => 'Dla każdej notatki, w .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Brak' : '$count';
  @override
  String get historyIntervalTitle => 'Nowa wersja najwyżej co';
  @override
  String get historyIntervalSubtitle =>
      'Podczas pisania; rozpoczęcie edycji notatki zawsze zachowuje jedną';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkrypcja';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Brak';
  @override
  String get transcriptionLanguageTitle => 'Język';
  @override
  String get transcriptionLanguageSubtitle =>
      'Język, w którym mówisz na nagraniach. Wskazanie go jest dokładniejsze '
      'niż wykrywanie.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Jak w aplikacji ($language)';
  @override
  String get transcriptionLanguageDetect => 'Wykrywaj automatycznie';
  @override
  String get transcriptionModelsTitle => 'Modele transkrypcji';
  @override
  String transcriptionModelsUsed(String size) => 'Zajęte: $size';
  @override
  String get transcriptionModelsInstalled => 'Pobrane';
  @override
  String get transcriptionModelsDownloading => 'Pobieranie';
  @override
  String get transcriptionModelsAvailable => 'Dostępne';
  @override
  String get transcriptionModelsFooter =>
      'Modele pozostają w pamięci aplikacji na tym urządzeniu. Nie są '
      'kopiowane do biblioteki ani synchronizowane.';
  @override
  String get transcriptionModelDefault => 'Domyślny';
  @override
  String get transcriptionModelSlow => 'Wolny';
  @override
  String get transcriptionModelHintTiny => 'Najszybszy, najmniej dokładny';
  @override
  String get transcriptionModelHintBase =>
      'Dobry balans szybkości i dokładności';
  @override
  String get transcriptionModelHintSmall =>
      'Dokładniejszy, około 3× wolniejszy';
  @override
  String get transcriptionModelHintMedium =>
      'Bardzo dokładny, wolny na telefonie';
  @override
  String get transcriptionModelHintLarge =>
      'Najdokładniejszy, wymaga dużo pamięci';
  @override
  String get transcriptionModelDownload => 'Pobierz';
  @override
  String transcriptionModelDeleteTitle(String model) => 'Usunąć model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Zwolni to $size. Model możesz później pobrać ponownie.';
  @override
  String get transcriptionModelFailed =>
      'Nie udało się pobrać. Sprawdź połączenie i spróbuj ponownie.';
  @override
  String get actionRetry => 'Spróbuj ponownie';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Utracono połączenie, ponawianie…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Wstrzymano przy $progress';
  @override
  String get actionResume => 'Wznów';
  @override
  String get audioTranscribe => 'Transkrybuj';
  @override
  String get audioTranscribeUnsupported =>
      'Na tym urządzeniu tylko nagrania WAV';
  @override
  String get transcriptionQueued => 'W kolejce';
  @override
  String get transcriptionPreparing => 'Przygotowywanie dźwięku…';
  @override
  String transcriptionRunning(int percent) => 'Transkrypcja… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Pobieranie $model · $percent%';
  @override
  String get transcriptionSaved => 'Transkrypcję dodano do opisu';
  @override
  String get transcriptionNoSpeech => 'Nie rozpoznano mowy w tym nagraniu';
  @override
  String get transcriptionFailed => 'Transkrypcja nie powiodła się';
  @override
  String get transcriptionPickModelTitle => 'Wybierz model';
  @override
  String get transcriptionPickModelBody =>
      'Transkrypcja odbywa się na tym urządzeniu, a nagranie nigdy nie jest '
      'wysyłane. Model pobierasz tylko raz.';
  @override
  String get transcriptionPickModelAction => 'Pobierz i transkrybuj';
  @override
  String get transcriptionModelRecommended => 'Zalecany';
  @override
  String get transcriptionExistingTitle => 'To nagranie ma już opis';
  @override
  String get transcriptionExistingBody =>
      'Zastąpić go transkrypcją czy dodać transkrypcję pod spodem?';
  @override
  String get transcriptionAppend => 'Dodaj pod spodem';
  @override
  String get transcriptionReplace => 'Zastąp';
  @override
  String get settingsSectionSync => 'Synchronizacja';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Nieskonfigurowana dla tej biblioteki';
  @override
  String get syncNeverSynced => 'Jeszcze nie zsynchronizowano';
  @override
  String syncLastSynced(String when) => 'Zsynchronizowano $when';
  @override
  String get syncRunning => 'Synchronizowanie…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteka $library';
  @override
  String get syncUrlLabel => 'Adres katalogu';
  @override
  String get syncUrlRequired => 'Wpisz adres serwera';
  @override
  String get syncUrlHint =>
      'Katalog musi istnieć. Skopiuj adres tak, jak pokazuje go '
      'serwer.';
  @override
  String get syncHttpWarning =>
      'Połączenie nieszyfrowane: w porządku przez VPN lub w '
      'sieci lokalnej.';
  @override
  String get syncUserLabel => 'Użytkownik';
  @override
  String get syncUserHint =>
      'Zostaw puste, jeśli serwer nie wymaga danych logowania.';
  @override
  String get syncPasswordLabel => 'Hasło';
  @override
  String get syncPasswordHint =>
      'Przechowywane w pęku kluczy tego urządzenia, nigdy w '
      'plikach biblioteki.';
  @override
  String get syncPasswordKeepHint =>
      'Zostaw puste, aby zachować zapisane hasło.';
  @override
  String get syncShowPassword => 'Pokaż hasło';
  @override
  String get syncHidePassword => 'Ukryj hasło';
  @override
  String get syncTestAction => 'Testuj połączenie';
  @override
  String get syncTesting => 'Testowanie…';
  @override
  String get syncRetargetWarning =>
      'Po zmianie adresu lub użytkownika następna synchronizacja '
      'zacznie się od nowa jako pierwsza.';
  @override
  String get syncTestOk => 'Połączenie działa';
  @override
  String get syncModeFull => 'Tryb pełny';
  @override
  String get syncModeCompatible => 'Tryb zgodności';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Odczyt, zapis i usuwanie';
  @override
  String get syncCapEtags => 'Odciski plików (ETag)';
  @override
  String get syncCapNoEtags => 'Brak odcisków plików (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Porównuje rozmiar i datę; w razie wątpliwości pobiera '
      'ponownie';
  @override
  String get syncCapGuarded => 'Chroniony zapis';
  @override
  String get syncCapUnguarded => 'Niechroniony zapis';
  @override
  String get syncCapUnguardedDetail =>
      'Sprawdza plik na serwerze tuż przed zapisem';
  @override
  String get syncCapMove => 'Zmiana nazwy bez ponownego wysyłania';
  @override
  String get syncCapNoMove => 'Brak zmiany nazw na serwerze';
  @override
  String get syncCapNoMoveDetail =>
      'Zmiana nazwy staje się usunięciem i nowym wysłaniem';
  @override
  String get syncCompatibleNote =>
      'W trybie zgodności synchronizacja działa tak samo, z '
      'kilkoma dodatkowymi żądaniami.';
  @override
  String get syncTestInvalidUrl => 'Nieprawidłowy adres';
  @override
  String get syncTestInvalidUrlHint =>
      'Wpisz adres http:// lub https:// bez użytkownika i hasła.';
  @override
  String get syncTestOffline => 'Serwer jest nieosiągalny';
  @override
  String get syncTestOfflineHint =>
      'Czy VPN jest włączony? Adres 10.x lub 192.168.x działa '
      'tylko z tej samej sieci.';
  @override
  String get syncTestAuth => 'Użytkownik lub hasło odrzucone';
  @override
  String get syncTestAuthHint => 'Sprawdź je i przetestuj ponownie.';
  @override
  String get syncTestNotFound => 'Katalog nie istnieje';
  @override
  String get syncTestNotFoundHint => 'Utwórz go na serwerze lub popraw adres.';
  @override
  String get syncTestUnsupported => 'To nie jest katalog WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'Serwer odpowiada, ale nie jako WebDAV.';
  @override
  String get syncTestFailed => 'Test się nie powiódł';
  @override
  String get syncNowAction => 'Synchronizuj teraz';
  @override
  String get syncSectionServer => 'Serwer';
  @override
  String get syncServerRow => 'Adres, użytkownik i hasło';
  @override
  String get syncRetestTitle => 'Przetestuj serwer ponownie';
  @override
  String syncProbedAgo(String when) => 'Ostatni test $when';
  @override
  String get syncDisconnectTitle => 'Odłącz tę bibliotekę';
  @override
  String get syncDisconnectSubtitle => 'Pliki zostają tutaj i na serwerze';
  @override
  String get syncDisconnectConfirmTitle => 'Odłączyć synchronizację?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ta biblioteka przestanie się synchronizować na tym '
      'urządzeniu. Żaden plik nie zostanie usunięty ani tutaj, '
      'ani na serwerze. Jeśli połączysz ją ponownie, pierwsza '
      'synchronizacja zacznie się od nowa.';
  @override
  String get syncDisconnectConfirm => 'Odłącz';
  @override
  String get syncFirstTitle => 'Pierwsza synchronizacja';
  @override
  String get syncFirstIntro => 'Porównano bibliotekę z katalogiem na serwerze:';
  @override
  String get syncFirstUpload => 'Do wysłania';
  @override
  String get syncFirstDownload => 'Do pobrania';
  @override
  String get syncFirstBoth => 'Po obu stronach';
  @override
  String get syncFirstBothHint =>
      'Identyczne: bez przesyłania. Różne: do rozwiązania';
  @override
  String get syncFirstNoDelete =>
      'Pierwsza synchronizacja niczego nie usuwa ani tutaj, ani '
      'na serwerze.';
  @override
  String get syncStartAction => 'Rozpocznij';
  @override
  String syncMassTrashTitle(int count) => 'Przenieść pliki do kosza ($count)?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Na serwerze brakuje $count z $total zsynchronizowanych '
      'plików. Zwykle oznacza to błędny adres, niezamontowany '
      'dysk NAS lub katalog opróżniony przez pomyłkę.';
  @override
  String get syncMassTrashHint =>
      'Jeśli naprawdę zostały usunięte na innym urządzeniu, '
      'potwierdź: tutaj trafią do kosza.';
  @override
  String get syncMassTrashConfirm => 'Przenieś do kosza';
  @override
  String syncMassDeleteTitle(int count) => 'Usunąć pliki z serwera ($count)?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Tutaj brakuje $count z $total zsynchronizowanych plików. '
      'Jeśli nie usunięto ich celowo, anuluj i sprawdź katalog '
      'biblioteki.';
  @override
  String get syncMassDeleteConfirm => 'Usuń z serwera';
  @override
  String get syncTooltip => 'Synchronizuj';
  @override
  String get syncStageConnecting => 'Łączenie z serwerem…';
  @override
  String get syncStageComparing => 'Porównywanie z serwerem…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synchronizowanie · $done z $total';
  @override
  String get syncStatusWarnings => 'Zsynchronizowano z ostrzeżeniami';
  @override
  String syncConflictsHeader(int count) =>
      'Zmienione tutaj i na serwerze · $count';
  @override
  String get syncConflictHint => 'Żadna wersja nie została zmieniona';
  @override
  String get syncResolveAction => 'Rozwiąż';
  @override
  String syncFailuresHeader(int count) => 'Niezsynchronizowane · $count';
  @override
  String get syncFailuresHint => 'Ponowna próba przy następnej synchronizacji';
  @override
  String get syncAbortAuth => 'Serwer odrzucił hasło';
  @override
  String get syncAbortMissingPassword => 'Brak zapisanego hasła';
  @override
  String get syncAbortOffline => 'Serwer jest nieosiągalny';
  @override
  String get syncAbortRemoteMissing => 'Katalogu na serwerze już nie ma';
  @override
  String get syncAbortUnsupported => 'Serwer nie działa już jako WebDAV';
  @override
  String get syncAbortFailed => 'Synchronizacja się nie powiodła';
  @override
  String get syncAbortNotConfirmed => 'Synchronizacja anulowana';
  @override
  String get syncAbortNothingTouched =>
      'Żaden plik nie został zmieniony. Twoje zmiany zostają '
      'tutaj do następnej udanej synchronizacji.';
  @override
  String syncLastSuccess(String when) => 'Ostatnia udana synchronizacja $when';
  @override
  String get syncNoSuccessYet => 'Jeszcze nie było udanej synchronizacji';
  @override
  String get syncUpdatePasswordAction => 'Zaktualizuj hasło';
  @override
  String get syncRetryAction => 'Spróbuj ponownie';
  @override
  String get syncOpenSettingsAction => 'Ustawienia';
  @override
  String get syncCloseAction => 'Zamknij';
  @override
  String get syncDoneSnack => 'Zsynchronizowano';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Zsynchronizowano · 1 plik usunięty gdzie indziej jest w '
            'koszu'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Zsynchronizowano · $count pliki usunięte gdzie indziej są '
            'w koszu'
      : 'Zsynchronizowano · $count plików usuniętych gdzie indziej '
            'jest w koszu';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Zsynchronizowano · 1 konflikt do rozwiązania'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Zsynchronizowano · $count konflikty do rozwiązania'
      : 'Zsynchronizowano · $count konfliktów do rozwiązania';
  @override
  String get syncShowAction => 'Pokaż';
  @override
  String get syncConflictTitle => 'Rozwiąż konflikt';
  @override
  String get syncConflictBinary =>
      'To nie jest plik tekstowy: wybierz, którą kopię zachować.';
  @override
  String get syncConflictKeepNote =>
      'Kopia, której nie zachowasz, zostaje w historii notatki.';
  @override
  String get syncKeepLocal => 'Zachowaj z tego urządzenia';
  @override
  String get syncKeepRemote => 'Zachowaj z serwera';
  @override
  String get syncConflictLoadFailed => 'Nie udało się odczytać obu wersji';
  @override
  String get syncResolveFailed => 'Nie udało się rozwiązać konfliktu';
  @override
  String get syncResolved => 'Konflikt rozwiązany';
  @override
  String get syncConflictMoved =>
      'Jedna z wersji zmieniła się w międzyczasie: konflikt wczytano '
      'ponownie, wybierz jeszcze raz.';
  @override
  String get syncSectionWhen => 'Kiedy synchronizować';
  @override
  String get syncAutoTitle => 'Automatycznie';
  @override
  String get syncAutoSubtitle => 'Po zmianach, przy otwarciu i co jakiś czas';
  @override
  String get syncIntervalTitle => 'Sprawdzaj serwer co';
  @override
  String get syncIntervalSubtitle => 'Tylko gdy aplikacja jest otwarta';
  @override
  String get syncIntervalDialogBody =>
      'Aby widzieć zmiany wprowadzone na innych urządzeniach, gdy aplikacja '
      'jest otwarta. Przy „Nigdy” tylko po zmianach i przy otwarciu.';
  @override
  String syncIntervalMinutes(int count) => count == 1
      ? '1 minuta'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? '$count minuty'
      : '$count minut';
  @override
  String get syncIntervalNever => 'Nigdy';
  @override
  String get syncWifiOnlyTitle => 'Tylko Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Przy danych komórkowych synchronizuj tylko ręcznie';
  @override
  String syncPendingChanges(int count) => count == 1
      ? '1 zmiana czeka'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? '$count zmiany czekają'
      : '$count zmian czeka';
  @override
  String syncRetryIn(String wait) => 'ponowna próba za $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Czekanie na Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Czekanie na połączenie';
  @override
  String get syncMobileDataHint =>
      '„Synchronizuj teraz” i tak używa danych komórkowych.';
  @override
  String get syncQueueKeptHint =>
      'Zmiany zostają tutaj, nawet gdy zamkniesz aplikację, i wychodzą same, '
      'gdy serwer odpowie.';
  @override
  String get syncAutoPaused => 'Automatyczna synchronizacja wstrzymana';
  @override
  String get syncPausedAuthHint =>
      'Wznowi się, gdy zaktualizujesz hasło lub zsynchronizujesz ręcznie.';
  @override
  String get syncPausedServerHint =>
      'Wznowi się, gdy poprawisz adres lub zsynchronizujesz ręcznie.';
  @override
  String get syncPausedConfirmHint =>
      '„Synchronizuj teraz” pokaże, co zostałoby usunięte, i najpierw zapyta.';
  @override
  String get syncNeedsConfirmation => 'Czeka na Twoje potwierdzenie';
  @override
  String get syncMergeIntro =>
      'Zmiany, które się nie nakładają, są już scalone; tam, gdzie się '
      'nakładają, wybierz, co zachować.';
  @override
  String get syncMergeClean =>
      'Obie wersje scalają się same: nic się nie nakłada.';
  @override
  String get syncMergeNoBase =>
      'Brak wspólnej wersji do scalenia: wszędzie, gdzie kopie się różnią, '
      'wybierasz ty.';
  @override
  String syncMergeOverlap(int index, int total) => 'Nakładanie $index z $total';
  @override
  String get syncMergeFromLocal => 'Z tego urządzenia';
  @override
  String get syncMergeFromRemote => 'Z serwera';
  @override
  String get syncMergeRemovedLines => 'Usunięte linie';
  @override
  String get syncMergeAbsentLines => 'Brak w tej kopii';
  @override
  String get syncMergeKeepLocal => 'Moje';
  @override
  String get syncMergeKeepRemote => 'Serwera';
  @override
  String get syncMergeKeepBoth => 'Obie';
  @override
  String get syncMergeSave => 'Zapisz scalenie';
  @override
  String get syncMergeKeepWhole => 'Albo zachowaj jedną całą kopię';
}
