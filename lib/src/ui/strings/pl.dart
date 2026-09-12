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
  String get settingsPreviewEnabledTitle => 'Podgląd';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Pokaż wyrenderowaną notatkę obok edytora źródła';
  @override
  String get switchToWysiwygTooltip => 'Przełącz na edytor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Przełącz na źródło Markdown';
  @override
  String get wysiwygTooLarge =>
      'Ta notatka jest zbyt duża dla edytora WYSIWYG. Otwórz ją w '
      'źródle Markdown.';

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
  String get themePaletteTitle => 'Paleta kolorów';
  @override
  String get themePaletteSubtitle => 'Kolory interfejsu i notatki';
  @override
  String get themePaletteSystem => 'System';

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

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Tryb podglądu';
  @override
  String get previewModeSubtitle =>
      'Czy podgląd dzieli ekran z edytorem, czy go zastępuje';
  @override
  String get previewModeAuto => 'Obok siebie';
  @override
  String get previewModeSwitch => 'Pełny ekran';
  @override
  String get splitRatioTitle => 'Szerokość podziału';
  @override
  String get splitRatioSubtitle => 'Część edytora, gdy podgląd jest obok';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Szybka notatka';
  @override
  String get shortcutNewTodo => 'Nowe zadanie';
  @override
  String get shortcutNewNote => 'Nowa notatka';
  @override
  String get shortcutNewList => 'Nowa lista';
  @override
  String get shortcutToggleSidebar => 'Pokaż lub ukryj filtr';
  @override
  String get shortcutEditorSection => 'W edytorze';
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
  String get toolbarHeading => 'Nagłówek';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Lista numerowana';
  @override
  String get toolbarQuote => 'Cytat';
  @override
  String get toolbarIndent => 'Wcinij';
  @override
  String get toolbarOutdent => 'Usuń wcięcie';
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
  @override
  String get enterFullScreenTooltip => 'Pełny ekran';
  @override
  String get exitFullScreenTooltip => 'Opuść pełny ekran';

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
  String get newFolderTitle => 'Nowy katalog';
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
}
