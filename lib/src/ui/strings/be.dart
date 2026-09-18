// The Belarusian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class BelarusianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'студзень',
    'люты',
    'сакавік',
    'красавік',
    'травень',
    'чэрвень',
    'ліпень',
    'жнівень',
    'верасень',
    'кастрычнік',
    'лістапад',
    'снежань',
  ];
  @override
  List<String> get monthNamesShort => const [
    'студ',
    'лют',
    'сак',
    'кра',
    'тра',
    'чэр',
    'ліп',
    'жні',
    'вер',
    'кас',
    'ліст',
    'снеж',
  ];
  @override
  List<String> get weekdayNames => const [
    'панядзелак',
    'аўторак',
    'серада',
    'чацвер',
    'пятніца',
    'субота',
    'недзеля',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'пан',
    'аўт',
    'сер',
    'чац',
    'пят',
    'суб',
    'нед',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Кошык';
  @override
  String get trashSubtitle =>
      'Выдаленыя элементы перамяшчаюцца ў .trash/ (адключана = канчатковае '
      'выдаленне)';
  @override
  String get trashAutoEmptyTitle => 'Аўтаачыстка кошыка';
  @override
  String get trashAutoEmptySubtitle =>
      'Старыя выдаленні знікаюць назаўжды пры адкрыцці бібліятэкі';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Ніколі'
      : switch ((days % 10, days % 100)) {
          (1, != 11) => '$days дзень',
          (2 || 3 || 4, < 12 || > 14) => '$days дні',
          _ => '$days дзён',
        };
  @override
  String get debugLogsTitle => 'Журналы адлагоджвання';
  @override
  String get debugLogsSubtitle => 'Фіксуе падзеі праграмы ў буферы памяці';
  @override
  String get lineNumbersTitle => 'Нумары радоў';
  @override
  String get lineNumbersSubtitle => 'Паказвае слупок нумараў радоў у рэдактары';
  @override
  String get readableLineLengthTitle => 'Зручная даўжыня радка';
  @override
  String get readableLineLengthSubtitle =>
      'Трымаць тэкст нататкі ў цэнтраванай калонцы замест усёй шырыні акна';
  @override
  String get noteColumnWidthTitle => 'Шырыня калонкі';
  @override
  String get noteColumnWidthSubtitle => 'Шырыня калонкі нататкі ў пікселях';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Клавіятура пры адкрыцці';
  @override
  String get keyboardOnOpenSubtitle =>
      'Паказвае клавіятуру пры адкрыцці заўвагі (адключана = пры першым '
      'дотыку)';
  @override
  String get editorKindSource => 'Markdown-крэйс';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Зыходнік Markdown, як напісана';
  @override
  String get editorKindWysiwygSubtitle =>
      'Адфарматаваны тэкст, рэдагуецца на месцы';
  @override
  String get settingsFolderToCreate => 'стварыць';
  @override
  String get settingsSearchHint => 'Пошук налад';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 наладу знойдзена' : '$count наладаў знойдзена';
  @override
  String get settingsToggleOn => 'Укл.';
  @override
  String get settingsToggleOff => 'Выкл.';
  @override
  String get settingsPreviewEnabledTitle => 'Прагляд';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Паказвае афармленую заўвагу побач з рэдактарам крыніцы';
  @override
  String get switchToWysiwygTooltip => 'Пераключыць на WYSIWYG-рэдактар';
  @override
  String get switchToSourceTooltip => 'Пераключыць на Markdown-крэйс';
  @override
  String get switchToSourceLabel => 'Крыніца';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Гэтая заўвага занадта вялікая для WYSIWYG-рэдактара. Адкрыйце яе як '
      'Markdown-крэйс.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Знешні выгляд';
  @override
  String get settingsSectionEditor => 'Рэдактар';
  @override
  String get settingsSectionLibrary => 'Бібліятэка';
  @override
  String get settingsSectionReminders => 'Напамінні';
  @override
  String get settingsSectionShortcuts => 'Клавіятура';
  @override
  String get keyboardShortcutsTitle => 'Комбінацыі клавіш';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Бібліятэка $name';
  @override
  String get settingsGroupLibraryHint =>
      'дзейнічае толькі для гэтай бібліятэкі';
  @override
  String get settingsGroupMaintenance => 'Тэхнаабслугоўванне';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Папкі і шляхі';
  @override
  String get settingsAreaTrashHistory => 'Кошык і гісторыя';
  @override
  String get settingsAreaDiagnostics => 'Дыягностыка і інфармацыя';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Патрэбная падлучаная фізічная клавіятура';
  @override
  String get settingsSectionUpdates => 'Абнаўленні';
  @override
  String get autoUpdateTitle => 'Аўтаматычныя абнаўленні';
  @override
  String get autoUpdateSubtitle =>
      'Правяраць GitHub Releases пры запуску і кожныя 6 гадзін';
  @override
  String get checkForUpdatesTitle => 'Праверыць абнаўленні';
  @override
  String updateAvailableMessage(Object version) =>
      'Даступная версія Niman $version';
  @override
  String get updateUpToDate => 'У вас апошняя версія Niman';
  @override
  String get updateCheckFailed => 'Не ўдалося праверыць абнаўленні';
  @override
  String updateSavedTo(Object path) => 'Абнаўленне захавана ў $path';
  @override
  String get updateInstallerStarted => 'Усталёўшчык запушчаны';
  @override
  String get settingsSectionDiagnostics => 'Дыягустыка';
  @override
  String get settingsSpellCheckTitle => 'Праверка арфаграфіі';
  @override
  String get settingsSpellCheckSubtitle =>
      'Падсвечвае арфаграфічныя памылкі падчас уводу.';
  @override
  String get spellCheckDictionaryTitle => 'Словнік';
  @override
  String get spellCheckDictionarySystem => 'Сістэмны па змаўчанні';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Выбар словнікаў';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Абярыце ўсе мовы, на якіх напісана бібліятэка. Слоў праходзіць, калі '
      'яго пазнае хаця б адзін абраны словнік; без выбару — мова сістэмы.';
  @override
  String get spellCheckNoDictionaries =>
      'Словнікі не знойдзены ў гэтай сістэме.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Праверка арфаграфіі';
  @override
  String get spellCheckTitle => 'Арфаграфія';
  @override
  String get spellCheckEmpty => 'Арфаграфічных памылак няма.';
  @override
  String get spellCheckUnavailable => 'hunspell не ўсталяваны ў гэтай сістэме.';
  @override
  String get spellCheckNoSuggestions => 'Няма прапаноў';
  @override
  String spellCheckCount(int count) => '$count для прагляду';
  @override
  String spellCheckLine(int line) => 'радок $line';
  @override
  String get addWordToDictionary => 'Дадаць у слоўнік';

  @override
  String indentWidthValue(int spaces) => '$spaces прабелы';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Святлівасць';
  @override
  String get themeBrightnessSubtitle => 'Светлая, цёмная або налады прыбора';
  @override
  String get themeBrightnessSystem => 'Сістэма';
  @override
  String get themeBrightnessDay => 'Светлая';
  @override
  String get themeBrightnessNight => 'Цёмная';
  @override
  String get themePaletteTitle => 'Палітра колераў';
  @override
  String get themePaletteSubtitle => 'Колеры інтэрфейсу і заўваг';
  @override
  String get themePaletteSystem => 'Сістэма';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Памер тэксту інтэрфейсу';
  @override
  String get uiTextScaleSubtitle =>
      'Дрэва, укладкі ды дыялогі; над наладамі сістэмы';
  @override
  String get noteTextScaleTitle => 'Памер тэксту заўваг';
  @override
  String get noteTextScaleSubtitle =>
      'Рэдактар і прагляд заўсёды сінхранізаваны';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Рэжым прагляду';
  @override
  String get previewModeSubtitle =>
      'Ці прагляд дзеліць экран з рэдактаром, ці замяняе яго';
  @override
  String get previewModeAuto => 'Побач';
  @override
  String get previewModeSwitch => 'Увесь экран';
  @override
  String get splitRatioTitle => 'Спавношэнне падзелу';
  @override
  String get splitRatioSubtitle => 'Частка рэдактара, калі прагляд побач';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Фармат спасылкі';
  @override
  String get linkTypeSubtitle => 'Што кнопка спасылкі ўстаўляе ў рэдактар';
  @override
  String get linkTypeWikilink => 'Вікіспасылка';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Стварыць адсутныя заўвагі ў';
  @override
  String get missingNoteLocationRoot => 'Карань бібліятэкі';
  @override
  String get missingNoteLocationCurrentFolder => 'Поточная папка';
  @override
  String get indentWidthTitle => 'Шырыня відступу';
  @override
  String get indentWidthSubtitle =>
      'Колькасць прабелаў, якія дадаюцца на кожны ўзровень відступу ў '
      'рэдактары';
  @override
  String get languageTitle => 'Мова';
  @override
  String get languageSubtitle => 'Мова самой праграмы';
  @override
  String get languageSystem => 'Сістэма';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Дадаць элемент';
  @override
  String get listAddTooltip => 'Дадаць элемент';
  @override
  String get listEmpty => 'Элементаў яшчэ няма';
  @override
  String get listDragHandleLabel => 'Змяніць парадак элементаў';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Запісаў яшчэ няма';
  @override
  String get audioRecord => 'Запісаць';
  @override
  String get audioStop => 'Спыніць';
  @override
  String get audioPlay => 'Прайграць';
  @override
  String get audioDelete => 'Выдаліць запіс';
  @override
  String get audioImport => 'Імпартаваць аўдыяфайл';
  @override
  String get audioRecording => 'Ідзе запіс…';
  @override
  String get audioPermissionDenied =>
      'Няма дазволу на мікрафон — ён патрэбны для запісу.';
  @override
  String get newAudioNoteTitle => 'Новая галасавая заўвага';
  @override
  String get newAudioNoteDefault => 'Мой запіс';
  @override
  String get showAudioTooltip => 'Паказаць запісы';
  @override
  String get audioMessageHint => 'Напішыце заўвагу…';
  @override
  String get audioSend => 'Адправіць';
  @override
  String get audioRename => 'Перайменаваць запіс';
  @override
  String get audioDescriptionHint => 'Апішыце гэты запіс…';
  @override
  String get audioEditDescription => 'Рэдагаваць апісанне';
  @override
  String get audioDeleteNote => 'Выдаліць заўвагу';
  @override
  String get audioEditNote => 'Рэдагаваць заўвагу';
  @override
  String get audioPause => 'Паўза';
  @override
  String get audioEditTitle => 'Рэдагаваць назву';
  @override
  String get audioTitleHint => 'Назва гэтага запісу…';
  @override
  String audioUntitled(int n) => 'Запіс $n';
  @override
  String get audioMoreActions => 'Больш дзеянняў';
  @override
  String get audioDiscardRecording => 'Адкінуць запіс';
  @override
  String get audioPauseRecording => 'Прыпыніць запіс';
  @override
  String get audioResumeRecording => 'Працягнуць запіс';
  @override
  String get audioRecordingPaused => 'Прыпынена';
  @override
  String get audioSavingRecording => 'Захаванне…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Хуткая заўвага';
  @override
  String get shortcutNewTodo => 'Новае заданне';
  @override
  String get shortcutNewNote => 'Новая заўвага';
  @override
  String get shortcutNewList => 'Новы спіс';
  @override
  String get shortcutNewAudio => 'Новая галасавая заўвага';
  @override
  String get shortcutToggleSidebar => 'Паказаць або схаваць фільтр';
  @override
  String get shortcutCloseTab => 'Закрыць бягучую нататку';
  @override
  String get shortcutNextTab => 'Наступная адкрытая нататка';
  @override
  String get shortcutPreviousTab => 'Папярэдняя адкрытая нататка';
  @override
  String get shortcutEditorSection => 'У рэдактары';
  @override
  String get shortcutFind => 'Шукаць';
  @override
  String get shortcutReplace => 'Знайсці і замяніць';
  @override
  String get shortcutSavingNote =>
      'Змены захоўваюцца аўтаматычна, таму камбінацыі для захавання '
      'няма.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Загрузка…';
  @override
  String get noteStatusSaving => 'Захаванне…';
  @override
  String get noteStatusUnsaved => 'Не захавана';
  @override
  String get noteStatusSaved => 'Захавана';
  @override
  String get noteStatusError => 'Памылка';
  @override
  String get noteNotText =>
      'Гэты файл не тэкставая нататка, таму Niman не можа паказаць яго тут.';
  @override
  String get noteLoadFailed => 'Не ўдалося адкрыць гэту нататку.';
  @override
  String wordCount(int count) =>
      switch (count % 100 >= 11 && count % 100 <= 14 ? 0 : count % 10) {
        1 => '$count слова',
        >= 2 && <= 4 => '$count словы',
        _ => '$count слоў',
      };
  @override
  String get outlineTooltip => 'Структура';
  @override
  String get outlineNoHeadings => 'Загаловакаў няма';
  @override
  String get outlineNoTitle => '(без загаловка)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Тлусты';
  @override
  String get toolbarItalic => 'Курсіў';
  @override
  String get toolbarStrikethrough => 'Закрэслены';
  @override
  String get toolbarSuperscript => 'Верхні індыкс';
  @override
  String get toolbarUnderline => 'Падкрэслены';
  @override
  String get toolbarLink => 'Спасылка';
  @override
  String get toolbarCode => 'Кадавы блок';
  @override
  String get toolbarImage => 'Уставіць выяву';
  @override
  String get toolbarHeading => 'Загаловак';
  @override
  String get toolbarList => 'Спіс';
  @override
  String get toolbarOrderedList => 'Нумараваны спіс';
  @override
  String get toolbarQuote => 'Цытата';
  @override
  String get toolbarIndent => 'Відступ';
  @override
  String get toolbarOutdent => 'Прыбраць відступ';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Інструменты';
  @override
  String get editorToolsTitle => 'Інструменты рэдактара';
  @override
  String get toolCountListTitle => 'Падлічыць спіс';
  @override
  String get toolCountListSubtitle =>
      'Падсумаваць тое, што пералічана ў радках, як спіс з галачкамі';
  @override
  String get toolCountListNeedsList => 'У гэтай нататцы няма спісу для падліку';
  @override
  String get tallySourceLabel => 'Спіс';
  @override
  String get tallyCutLabel => 'Чытаць кожны радок як';
  @override
  String get tallyCutDash => 'Імя - значэнні';
  @override
  String get tallyCutColon => 'Імя: значэнні';
  @override
  String get tallyCutCommas => 'Значэнні праз коску';
  @override
  String get tallyCutWhole => 'Увесь радок як адно значэнне';
  @override
  String get tallySortLabel => 'Парадак';
  @override
  String get tallySortCount => 'Спачатку найбольшыя';
  @override
  String get tallySortAlphabetical => 'Па алфавіце';
  @override
  String get tallySortFirstSeen => 'Як у спісе';
  @override
  String get tallyInsert => 'Уставіць';
  @override
  String get tallyUpdate => 'Абнавіць';
  @override
  String get tallyNothingToCount => 'Тут няма чаго лічыць';
  @override
  String get headingDialogTitle => 'Узровень загаловка';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Панэль інструментаў рэдактара';
  @override
  String get toolbarSettingsHint =>
      'Перацягвайце, каб змяніць парадак; вока паказвае або хавае кнопку.';
  @override
  String get toolbarShowButton => 'Паказаць';
  @override
  String get toolbarHideButton => 'Схаваць';
  @override
  String get toolbarResetOrder => 'Аднавіць па змаўчанні';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Паказаць прагляд';
  @override
  String get showEditorTooltip => 'Паказаць рэдактар';
  @override
  String get enterFullScreenTooltip => 'Увесь экран';
  @override
  String get exitFullScreenTooltip => 'Выйсці з рэжыму ўсяго экрана';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(HTML-табліца без апрацоўкі)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Шукаць у заўвагах';
  @override
  String get searchModeWords => 'Словы';
  @override
  String get searchModeContains => 'Змяшчае';
  @override
  String get searchEmptyHint =>
      'Напішыце, каб шукаць у бібліятэцы, або ключ = значэнне, каб '
      'фільтраваць па метаданных';
  @override
  String get searchTooShortHint => 'Увядзіце прынамсі 2 сімвалы';
  @override
  String get searchNoMatches => 'Няма вынікаў';
  @override
  String get searchLoadMore => 'Паказаць яшчэ';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Замяніць…';
  @override
  String get replaceInNoteAction => 'Замяніць у гэтай заўвазе…';
  @override
  String get replaceInThisNote => 'Замяніць у гэтай заўвазе';
  @override
  String get replaceWithLabel => 'Замяніць на';
  @override
  String get replaceCaseSensitive => 'Адрозніваць вялікія і малыя літары';
  @override
  String get replaceWholeWordsHint =>
      'замяняюцца толькі дакладныя супадзенні цэлага слова';
  @override
  String get replaceConfirm => 'Замяніць';
  @override
  String get replaceCancel => 'Зачыніць';
  @override
  String get replaceUnavailable => 'Замена пакуль недаступная';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Шукаць у заўвазе';
  @override
  String get editorFindHint => 'Шукаць';
  @override
  String get editorReplaceHint => 'Замяніць';
  @override
  String get editorFindCaseTooltip => 'Адрозніваць вялікія і малыя літары';
  @override
  String get editorFindPreviousTooltip => 'Папярэдні вынік';
  @override
  String get editorFindNextTooltip => 'Наступны вынік';
  @override
  String get editorFindCloseTooltip => 'Зачыніць пошук';
  @override
  String get editorFindReplaceModeTooltip => 'Рэжым замены';
  @override
  String get editorReplaceOneTooltip => 'Замяніць гэты вынік';
  @override
  String get editorReplaceAllTooltip => 'Замяніць усе вынікі';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Мэткі';
  @override
  String get tagsTitle => 'Мэткі';
  @override
  String get tagsEmpty =>
      'Мэтак яшчэ няма — дадайце #метку ў заўвагу ці мэткі ў метаданных';
  @override
  String get tagsBackTooltip => 'Назад да пошуку';
  @override
  String get tagsNotesEmpty => 'Няма заўваг з гэтай меткай';
  @override
  String tagsNotesCapped(int limit) =>
      'Паказаны толькі першыя $limit — пошукайце па метцы, каб звузіць';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Спасылка не знойдзена';
  @override
  String get headingNotFoundTitle => 'Загаловак не знойдзены';
  @override
  String get ambiguousLinkTitle => 'Колькі заўваг адпавядаюць';
  @override
  String get openLinkFailed => 'Не ўдалося адкрыць спасылку';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Заўвага не існуе';
  @override
  String missingNoteDialogBody(String path) => "Стварыць '$path'?";
  @override
  String missingNoteFolderMissing(String folder) => "Папка '$folder' не існуе";

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Адкрытыя';
  @override
  String get todoDone => 'Выкананыя';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Усе даты';
  @override
  String get todoFilter => 'Фільтраваць';
  @override
  String get todoNoTokens => 'У гэтым спісе няма токеноў';
  @override
  String get todoCountOpen => 'адкрытыя';
  @override
  String get todoCountDone => 'выкананыя';
  @override
  String get todoEmptyOpen => 'Адкрытых заданняў яшчэ няма';
  @override
  String get todoEmptyDone => 'Выкананых яшчэ няма';
  @override
  String get todoEmptyFiltered => 'Няма адпаведных заданняў';
  @override
  String get todoTitle => 'Заданні';
  @override
  String get todoAddTooltip => 'Дадаць заданне';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Фармат todo.txt';
  @override
  String get todoHelpTooltip => 'Інфармацыя пра фармат';
  @override
  String get todoHelpIntro =>
      'Вашыя заданні — звычайны тэкставы файл, адно заданне на радок. Niman '
      'піша сінтаксіс за вас, але файл можна рэдагаваць у любым рэдактары, '
      'і Niman зноў яго прачытае.';
  @override
  String get todoHelpFilesTitle => 'Два файлы';
  @override
  String get todoHelpFilesBody =>
      'Адкрытыя заданні жывуць у todo.txt у карані бібліятэкі. Пасля '
      'выканання радок перамяшчаецца ў done.txt, каб todo.txt заставаўся '
      'кораткім. Выкананы радок, які зноў з’явіўся ў todo.txt, Niman '
      'арганізуе пры наступным чытанні файла.';
  @override
  String get todoHelpLineTitle => 'Анатомія радка';
  @override
  String get todoHelpLineBody =>
      'Усё да апісання — гэта выбар, і ён павінен быць у такім парадку:';
  @override
  String get todoHelpDoneBody =>
      'Пазначае заданне як выкананае. Niman дадае яе, калі вы адзначаеце '
      'галачку.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Прыярытэт. A — самы высокі. Паказваецца як эмблема ў спісе.';
  @override
  String get todoHelpDatesBody =>
      'Тэрмін, а потым дата стварэння. Калі адна дата, то гэта дата '
      'стварэння, калі радок не пачынаецца з x.';
  @override
  String get todoHelpTokensTitle => 'Праекты, кантэксты і мэткі';
  @override
  String get todoHelpTokensBody =>
      'Будь-якое слова ў апісанні з адным з гэтых прэфіксаў становіцца '
      'фільтраванай меткай. Нішто не вызначана загадзя: токен існуе, пакуль '
      'яго не напішэце.';
  @override
  String get todoHelpProjectBody =>
      'Якому праекту належыць заданне, напрыклад +кухня або +робата.';
  @override
  String get todoHelpContextBody =>
      'Дзе або як яго зрабіць, напрыклад @дома або @сустрэча.';
  @override
  String get todoHelpHashtagBody =>
      'Свабодная метка для таго, што не пакрываюць дзве іншыя.';
  @override
  String get todoHelpTagsTitle => 'Даты і напамінні';
  @override
  String get todoHelpTagsBody =>
      'Гэта мэткі ключ:значэнне. Niman піша іх з дыялога задання і чытае іх '
      'усюды, дзе яны з’яўляюцца ў радку.';
  @override
  String get todoHelpDueBody =>
      'Тэрмін. Кіруе колерам эмблемы і фільтрамі дат.';
  @override
  String get todoHelpRemBody =>
      'Калі адправіць паведамленне ў вашым часовым поясе. Працуе, калі '
      'экран выключаны, а праграма адкрыта.';
  @override
  String get todoHelpRemDesktop =>
      'На камп’ютары Niman павінен працаваць, калі настане час: напамін '
      'паказваецца, пакуль праграма адкрыта, і нічога не адбываецца, калі '
      'яна зачынена.';
  @override
  String get todoHelpOtherBody =>
      'Яна захоўваецца менавіта так, як запісаная, каб мэткі іншых праграм '
      'todo.txt праграм перажылі пераход. Niman іх не '
      'выкарыстоўвае, rec: included: паўтаральнае заданне '
      'пакуль не паўторваецца.';
  @override
  String get todoHelpEditTitle => 'Рэдагаванне па-за Niman';
  @override
  String get todoHelpEditBody =>
      'Радкі, якіх вы не датыкаецеся, захоўваюцца байт за байтам. Niman '
      'перапісвае толькі гэты радок у кананічным парадку, а астатняя частка '
      'файла застаецца недатыканай.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Дадаць заданне';
  @override
  String get todoEditTitle => 'Рэдагаваць заданне';
  @override
  String get todoDescriptionHint => 'Апісанне';
  @override
  String get todoCancel => 'Адмяніць';
  @override
  String get todoSave => 'Захаваць';
  @override
  String get todoEditAction => 'Рэдагаваць';
  @override
  String get todoDeleteAction => 'Выдаліць';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Тэрмін прайшоў';
  @override
  String get todoDueToday => 'Сёння';
  @override
  String get todoDueNext7 => 'Наступныя 7 дзён';
  @override
  String get todoDueNoDate => 'Без даты';
  @override
  String get todoRowDue => 'Тэрмін';
  @override
  String get todoRowDueToday => 'Тэрмін сёння';
  @override
  String get todoSortTooltip => 'Сартаваць';
  @override
  String get todoSortDue => 'Дата тэрміна';
  @override
  String get todoSortPriority => 'Прыярытэт';
  @override
  String get todoSortCreation => 'Дата стварэння';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Без прыярытэту';
  @override
  String get todoNoPriorityShort => 'Няма';
  @override
  String get todoMorePriorities => 'Больш…';
  @override
  String get todoPriorityTitle => 'Прыярытэт';
  @override
  String get todoNoDueDate => 'Без тэрміна';
  @override
  String get todoNoReminder => 'Без напаміну';
  @override
  String get todoAddProject => '+ Праект';
  @override
  String get todoAddContext => '@ Кантэкст';
  @override
  String get todoAddHashtag => '# Метка';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Напамінні заданняў';
  @override
  String get todoReminderChannelDescription =>
      'Запланаваныя паведамленні для заданняў з часам напаміну.';
  @override
  String get todoReminderBody => 'Напамін задання';
  @override
  String get todoReminderFallbackTitle => 'Напамін задання';
  @override
  String get todoReminderBlocked =>
      'Паведамленні выключаны, таму напамінні не будуць паказвацца.';
  @override
  String get todoReminderBattery =>
      'Для Niman уключана аптымізацыя акумулятара. Сістэма можа спыніць '
      'праграму, і чакаваныя напамінні могуць не прыйсці.';
  @override
  String get todoReminderInexact =>
      'Гэты прыбор не падтрымлівае дакладныя напамінні, таму напамін можа '
      'прыйсці на некалькі хвілін пазней, калі экран выключаны.';
  @override
  String get reminderShowTokensTitle => 'Мэткі ў паведамленнях напамінаў';
  @override
  String get reminderShowTokensSubtitle =>
      'Застаўце +праект, @кантэкст і #метку ў тэксце паведамлення. '
      'Калі адключана, паказваецца толькі заданне, якое вы напісалі.';
  @override
  String get todoReminderFixAction => 'Адкрыць налады';
  @override
  String get todoReminderDismissAction => 'Зачыніць';
  @override
  String get todoReminderDue => 'Тэрмін';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Добра';
  @override
  String get actionCancel => 'Адмяніць';
  @override
  String get actionCreate => 'Стварыць';
  @override
  String get actionNew => 'Новы';
  @override
  String get actionSave => 'Захаваць';
  @override
  String get actionClear => 'Ачысціць';
  @override
  String get actionChoose => 'Абраць';
  @override
  String get actionDelete => 'Выдаліць';
  @override
  String get actionRename => 'Перайменаваць';
  @override
  String get actionMove => 'Перамясціць';
  @override
  String get saveAndClose => 'Захаваць і зачыніць';
  @override
  String get closeUnsavedTitle => 'Незахаваныя змены';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '«${names.first}» мае незархаваныя змены. '
          'Захаваць перад зачыненнем?';
    }
    return 'У ${names.length} заўвагах ёсць незархаваныя змены. '
        'Захаваць перад зачыненнем?';
  }

  @override
  String get closeSaveFailed =>
      'Захаванне не ўдалося; заўвага застаецца адкрытай.';
  @override
  String get actionRestore => 'Аднавіць';
  @override
  String get actionEmpty => 'Ачысціць';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Схаваць бакавую панэль (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Паказаць бакавую панэль (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Зменшыць';
  @override
  String get windowMaximizeTooltip => 'Увялічыць';
  @override
  String get windowRestoreTooltip => 'Аднавіць';
  @override
  String get windowCloseTooltip => 'Зачыніць';
  @override
  String get tabFiles => 'Файлы';
  @override
  String get tabSearch => 'Пошук';
  @override
  String get tabSettings => 'Налады';
  @override
  String get quickNoteTitle => 'Хуткая заўвага';
  @override
  String get treeEmpty => 'Заўваг яшчэ няма';
  @override
  String get selectANote => 'Абярыце заўвагу';
  @override
  String get showListTooltip => 'Паказаць спіс';
  @override
  String get editRawTooltip => 'Рэдагаваць сыры тэкст';
  @override
  String get sortAscTooltip => 'Сартаваць А–Я';
  @override
  String get sortDescTooltip => 'Сартаваць Я–А';
  @override
  String get newNoteTitle => 'Новая заўвага';
  @override
  String get newItemTooltip => 'Новае';
  @override
  String get closeMenuTooltip => 'Закрыць';
  @override
  String get newFolderTitle => 'Новая папка';
  @override
  String get newNoteSameFolder => 'Новая нататка ў той жа папцы';
  @override
  String get newFromTemplateSameFolder => 'Новая з шаблону ў той жа папцы';
  @override
  String trashOriginalPath(String path) => 'было ў $path';
  @override
  String get trashOriginalRoot => 'было ў корані бібліятэкі';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 элемент' : '$count элементаў';
  @override
  String get newNoteHere => 'Новая заўвага тут';
  @override
  String get newFolderHere => 'Новая папка тут';
  @override
  String get newListNoteTitle => 'Новая заўвага са спісам';
  @override
  String get newListNoteDefault => 'Мой спіс';
  @override
  String get setAsQuickNote => 'Усталяваць як хуткую заўвагу';
  @override
  String get currentQuickNote => 'Поточная хуткая заўвага';
  @override
  String get pinnedSection => 'Замацаваныя';
  @override
  String pinnedSectionCount(int count) => 'Замацаваныя · $count';
  @override
  String get templateFolderTitle => 'Папка шаблонаў';
  @override
  String get newFromTemplateTitle => 'Новы з шаблона';
  @override
  String get newFromTemplateHere => 'Новы з шаблона тут';
  @override
  String get templateFormTitle => 'Запоўніць шаблон';
  @override
  String get templateFormBacklink => 'Зваротная спасылка';
  @override
  String get templateFormNoNote => 'Без заўвагі';
  @override
  String get templateFormPickNote => 'Абраць заўвагу';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Плейсхолдеры шаблона';
  @override
  String get templateHelpSubtitle =>
      'Дата, назва і іншыя значэнні для запаўнення';
  @override
  String get quickNoteSubtitle =>
      'Нататка, якую адкрывае ўкладка хуткай нататкі';
  @override
  String get listFolderSubtitle => 'Новыя спісы спраў';
  @override
  String get templateFolderSubtitle => 'Крыніца для «Новай з шаблону»';
  @override
  String get attachmentsFolderSubtitle =>
      'Малюнкі і аўдыё, устаўленыя ў нататку';
  @override
  String get templateHelpIntro =>
      'Шаблон — звычайная заўвага з адтулінамі. Пры стварэнні заўвагі з '
      'яго тэкст капіюецца, а адтуліны запаўняюцца.';
  @override
  String get templateHelpUnknown =>
      'Плейсхолдер, які Niman не ведае, застаецца так, як запісаны: '
      'памылка з клавіятуры бачная ў заўвазе, а не выдаляецца ціха';
  @override
  String get templateHelpValuesTitle => 'Значэнні';
  @override
  String get templateHelpTitleBody =>
      'Імя, якое павінна атрымаць створаная заўвага.';
  @override
  String get templateHelpDateBody =>
      'Сёння і бягучы час. Абодва прымаюць фармат: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Дата і час разам.';
  @override
  String get templateHelpUuidBody =>
      'Новы унікальны ідэнтыфікатар, розны пры кожным выкарыстанні.';
  @override
  String get templateHelpCounterBody =>
      'Лічыльнік, які лічыць па назве, захоўваецца паміж запускамі: першая '
      'заўвага піша 1, наступная — 2. Тая ж назва ў заўвазе піша той самы '
      'лічыльнік; спалучце з |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Пастаўце курсор сюды пры стварэнні заўвагі; сімвал не запісваецца. '
      'Першы сімвал перамагае, без фільтраў, толькі ў новых заўвагах — і '
      'клавіятура адкрываецца нават калі autofocus выключаны.';
  @override
  String get templateHelpDatesTitle => 'Запісванне даты';
  @override
  String get templateHelpDatesBody =>
      'Гэтыя пазначаюць часткі даты ў фармаце. Усё астатняе — буквальна, '
      'ўключна з тэкстам у звычайных лапках. Назвы месяцаў і дзён тыжня '
      'выкарыстоўваюць мову праграмы.';
  @override
  String get templateHelpYear => 'год: 2026, 26';
  @override
  String get templateHelpMonth => 'месяц: 03, 3, сакавік, сак';
  @override
  String get templateHelpDay => 'дзень: 09, 9, панядзелак, пан';
  @override
  String get templateHelpTime => 'гадзіны, хвіліны, секунды';
  @override
  String get templateHelpWeek => 'ISO-тыдзень і квартал: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Фільтры';
  @override
  String get templateHelpFiltersBody =>
      'Пасля значэння могуць ісці фільтры, якія застасоўваюцца злева направа.';
  @override
  String get templateHelpCaseBody =>
      'ВЕЛІКІЯ, малыя літары і першая літара кожнага слова. '
      'Слова, запісанае вялікімі літарамі, застаецца незменным.';
  @override
  String get templateHelpSlugBody =>
      'Фарма спасылкі з тэксту, каб стварыць вікіспасылку.';
  @override
  String get templateHelpPadBody =>
      'Абрэзае краі; дапаўняе нулямі да патрэбнай шырыні; альтэрнатыва, '
      'калі значэнне пустое.';
  @override
  String get templateHelpShiftBody =>
      'Зрушвае дату на дні, тыдні, месяцы або гады — канферэнцыя праз '
      'тыдзень, дакумент з мінулага месяца.';
  @override
  String get templateHelpSnapBody =>
      'Прымацавае дату да пачатку або канца тыдня, месяца ці года.';
  @override
  String get templateHelpAskTitle => 'Запытаць нешта';
  @override
  String get templateHelpAskBody =>
      'Перад стварэннем заўвагі паказваецца форма з палямі пытанняў — і '
      'адна зваротная спасылка, калі шаблон яе патрабуе. Той самы сімвал '
      'двойчы — гэта пытанне, і адказ на яго запаўняе ўсе з’яўленні — папку '
      'і імя файла.';
  @override
  String get templateHelpAskFieldBody =>
      'Поле, аб якім пытаюць; тэкст пасля другой коскі — пачатковае '
      'значэнне.';
  @override
  String get templateHelpChoiceBody => 'Выбар са спіса, аддзеленага коскамі.';
  @override
  String get templateHelpWhereTitle => 'Куды ідзе заўвага';
  @override
  String get templateHelpWhereBody =>
      'Гэта не тэкст: гэта кіраванні, якія жывуць у блоку niman: метаданных '
      'шаблону. Блок апрацоўваецца і выдалаецца, каб яго ніколі не паказвалі '
      'у заўвазе. Значэнне можа змяшчаць плейсхолдэры.';
  @override
  String get templateHelpFolderBody =>
      'Папка, у якой ствараецца заўвага; ствараецца, калі не існуе. Без яе '
      'заўвага ідзе туды, дзе вы былі.';
  @override
  String get templateHelpFilenameBody =>
      'Як называюць заўвагу. Шаблон, у якім гэта ўказана, не пытае імя.';
  @override
  String get templateHelpAppendBody =>
      'Дадае да заўвагі, калі яна ўжо існуе, замест стварэння новай. Так '
      'штомесячная сустрэча становіцца адным файлом.';
  @override
  String get templateHelpOpenBody =>
      'Што адбываецца, калі заўвага існуе: рэдактар (па змаўчанні), прагляд '
      'або нічога не адбываецца — заўвага арганізуецца, і вы '
      'застаецеся там, дзе былі.';
  @override
  String get templateHelpAroundTitle => 'Адкуль яна прыходзіць';
  @override
  String get templateHelpParentBody =>
      'Заўвага, якую вы абіраеце ў форме; запішыце [[{{parent}}]] як '
      'зваротную спасылку.';
  @override
  String get templateHelpFolderValueBody => 'Папка, куды ідзе заўвага.';
  @override
  String get templateHelpClipboardBody =>
      'Што ў буферы абмену і вылучана ў рэдактары, калі заўвага пачалася '
      'там.';
  @override
  String get templateHelpIncludeTitle => 'Паўторнае выкарыстанне частак';
  @override
  String get templateHelpIncludeBody =>
      'Уставіце іншы шаблон, каб некалькі шаблонаў дзялілі адзін правераны '
      'спіс. Пошук спачатку ідзе ў папцы шаблонаў, .md можна прапусціць. '
      'Тыя самыя пытанні ідуць у тую саму форму.';
  @override
  String get templateHelpExampleTitle => 'Усё ў адным месцы';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ шаблон „$path” не існуе';
  @override
  String includeCycle(String path) => '⚠ „$path” уключае само сябе';
  @override
  String includeTooDeep(String path) => '⚠ „$path” ўбудавана занадта глыбока';
  @override
  String frontmatterInvalid(String reason) =>
      'Не ўдалося прачытаць метаданныя: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Не ўдалося прачытаць метаданныя „$template”, таму папка і імя файла '
      'не застасоўваліся: $reason';
  @override
  String get templatePickerTitle => 'Выбар шаблона';
  @override
  String templatePickerEmpty(String folder) =>
      'Шаблонаў яшчэ няма. Палажыце заўвагу ў $folder/ і яна стане '
      'шаблонам.';

  // Tree actions.
  @override
  String get actionPin => 'Замацаваць';
  @override
  String get actionUnpin => 'Адмацаваць';
  @override
  String get pinToWidget => 'Замацаваць у віджэце';
  @override
  String get pinnedForWidget =>
      'Замацавана: дадайте віджет «Нотатка» на галоўны экран';
  @override
  String get pinWidgetUnavailable =>
      'Віджэты галоўнага экрана даступныя ў Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Паказаць у файлавым менеджары';
  @override
  String get openInDefaultApp => 'Адкрыць у прадвызначанай праграме';
  @override
  String get newNoteTabTooltip => 'Новая нататка ў новай укладцы';
  @override
  String get openNotesTooltip => 'Адкрытыя нататкі';
  @override
  String get closeTabTooltip => 'Закрыць';
  @override
  String get openInNewTab => 'Адкрыць у новай укладцы';
  @override
  String get splitRight => 'Падзяліць управа';
  @override
  String get splitDown => 'Падзяліць уніз';
  @override
  String get moveToOtherPane => 'Перамясціць у іншую панэль';
  @override
  String get openBeside => 'Адкрыць збоку';
  @override
  String get closeAllNotes => 'Закрыць усе';
  @override
  String get openFileMissing => 'Файла гэтай заўвагі няма на дыску';
  @override
  String get openFileFailed => 'Не ўдалося адкрыць гэтую заўвагу па-за Niman';

  @override
  String get movedToTrash => 'Перамешчана ў кошык';
  @override
  String get deletedMessage => 'Выдалена';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name будзе перамешчана ў .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name будзе канчаткова выдалена';
  @override
  String get chooseDestination => 'Абраць месца';
  @override
  String get libraryRoot => 'Каран бібліятэкі';
  @override
  String moveTitle(String name) => 'Перамясціць $name';
  @override
  String headingLevelLabel(int level) => 'Узровень загаловка $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Хуткай заўвагі яшчэ няма. Абярыце існуючую заўвагу або стварыце '
      'новую — хуткая заўвага будзе адкрывацца тут.';
  @override
  String get quickNoteChooseAction => 'Абраць заўвагу…';
  @override
  String get quickNoteCreateAction => 'Стварыць новую заўвагу…';
  @override
  String get quickNoteNewTitle => 'Новая хуткая заўвага';
  @override
  String get quickNotePickerTitle => 'Выбар хуткай заўвагі';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Новая папка';
  @override
  String get folderPickerEmpty => 'Папак яшчэ няма';
  @override
  String get listFolderTitle => 'Папка спісаў';
  @override
  String get attachmentsFolderTitle => 'Папка ўкладанняў';

  // Trash (M1).
  @override
  String get trashEmpty => 'Кошык пусты';
  @override
  String get trashEmptyAction => 'Ачысціць кошык';
  @override
  String get trashEmptyConfirm =>
      'Гэта канчаткова выдаліць усё ў кошыку, уключна з элементамі, якія '
      'Niman туды не паклаў.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name будзе канчаткова выдалена (без аднаўлення)';
  @override
  String get trashDeletePermanently => 'Выдаліць канчаткова';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Адкрыйце папку з Markdown-заўвагамі як бібліятэку';
  @override
  String get openLibraryExisting => 'Адкрыць існуючую';
  @override
  String get openLibraryCreate => 'Стварыць новую';
  @override
  String get openLibraryCreateTitle => 'Стварыць новую бібліятэку';
  @override
  String get openLibraryFolderName => 'Назва папкі';
  @override
  String get openLibraryChooseFolder => 'Абраць папку бібліятэкі';
  @override
  String get openLibraryChooseParent =>
      'Абярыце папку, у якой будзе створана бібліятэка';
  @override
  String get openLibraryUnsupported =>
      'Гэтая папка не падтрымліваецца. Абярыце папку з сховішча прыбора.';
  @override
  String indexingCount(int done, int total) => '$done / $total заўваг';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Вашыя бібліятэкі';
  @override
  String get libraryUnreachable => 'Недаступная';
  @override
  String get libraryOpenedToday => 'Адкрыта сёння';
  @override
  String get libraryOpenedYesterday => 'Адкрыта ўчора';
  @override
  String libraryOpenedDaysAgo(int days) => 'Адкрыта $days дзён таму';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Адкрыта ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Зараз адкрыта';
  @override
  String get switchLibraryTitle => 'Змяніць бібліятэку';
  @override
  String get libraryForget => 'Забыць';
  @override
  String libraryForgetTitle(String name) => 'Забыць «$name»?';
  @override
  String get libraryForgetExplained =>
      'Яна знікне з гэтага спіса. Папкі, заўвагі і налады бібліятэкі '
      'заостаюцца незмененымі, і паўторнае адкрыццё вяртае яе на '
      'месца.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Дазволіць доступ да файлаў';
  @override
  String get storageAccessNeeded =>
      'Niman не можа чытаць вашыя заўвагі без «Даступу да ўсіх файлаў». '
      'Дазвольце гэта, каб адкрыць бібліятэку.';
  @override
  String get storageAccessExplained =>
      'Niman чытае вашыя заўвагі як звычайныя файлы, таму Android павінен '
      'даць доступ да ўсіх файлаў. Нічога не адсылаецца, і чытаецца толькі '
      'абраная папка бібліятэкі.';
  @override
  String folderAccessDenied(Object error) =>
      'Сістэма не дазволіла доступ да папкі: $error';
  @override
  String folderPickFailed(Object error) => 'Выбар папкі не ўдаўся: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Налады';
  @override
  String get libraryPathTitle => 'Шлях бібліятэкі';
  @override
  String get reindexTitle => 'Пераіндэксаваць зараз';
  @override
  String get reindexDone => 'Пераіндэксацыя завершана';
  @override
  String get closeLibraryTitle => 'Зачыніць бібліятэку';
  @override
  String get exportLogTitle => 'Экспартаваць журнал адлагоджвання';
  @override
  String get exportLogSubtitle =>
      'Захавайце зарэгістраваныя падзеі ў файл, які вы абярэце';
  @override
  String get exportLogEmpty => 'Буфер журнала пусты';
  @override
  String get quickNoteUnset => 'Не ўстаноўлена';
  @override
  String exportLogDone(Object target) => 'Журнал экспартаваны ў $target';
  @override
  String exportLogFailed(Object error) => 'Экспарт не ўдаўся: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '«$term» не мае дакладнага супадзення цэлага слова';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Заменена $occurrences з’яўленняў «$term» у $notes заўвагах';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped адкрытых заўваг прапушчана)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '«$term» не мае дакладнага супадзення цэлага слова'
      '${only == null ? '' : ' — знойдзена толькі $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Пра праграму';
  @override
  String get versionTitle => 'Версія';
  @override
  String get changelogTitle => 'Журнал змен';
  @override
  String get changelogEmpty => 'Запісы журналу змен недаступныя';
  @override
  String changelogWhatsNew(String version) => 'Новае ў версіі $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Гісторыя';
  @override
  String get noteMenuTooltip => 'Дзеянні з заўвагай';
  @override
  String get historyCurrentVersion => 'Бягучая версія';
  @override
  String get historyCurrentSubtitle => 'Заўвага ў цяперашнім выглядзе';
  @override
  String get historyToday => 'Сёння';
  @override
  String get historyYesterday => 'Учора';
  @override
  String get historyReasonSession => 'перад рэдагаваннем';
  @override
  String get historyReasonInterval => 'падчас рэдагавання';
  @override
  String get historyReasonRestore => 'перад аднаўленнем';
  @override
  String get historyReasonSync => 'перад сінхранізацыяй';
  @override
  String get historyReasonReplace => 'перад заменай';
  @override
  String get historyReasonUnknown => 'знойдзеная';
  @override
  String get historySyncBase => 'аснова сінхранізацыі';
  @override
  String get historyEmpty =>
      'Версій пакуль няма. Niman захоўвае адну, калі вы пачынаеце '
      'рэдагаваць заўвагу, а потым не часцей за адну раз на некалькі '
      'хвілін, пакуль вы пішаце.';
  @override
  String historyKept(int kept, int limit) => 'Захавана версій: $kept з $limit';
  @override
  String get historyBaseKept =>
      'Аснова сінхранізацыі захоўваецца і па-за лімітам.';
  @override
  String get historyOff =>
      'Гісторыя выключаная для гэтай бібліятэкі (Налады, Бібліятэка).';
  @override
  String get historyLoadFailed => 'Не ўдалося прачытаць гісторыю';
  @override
  String get historyCompareSubtitle => 'У параўнанні з бягучай версіяй';
  @override
  String get historyTabChanges => 'Змены';
  @override
  String get historyTabVersion => 'Версія';
  @override
  String get historyNoChanges => 'Той жа тэкст, што і ў бягучай версіі.';
  @override
  String get historyRestoreAction => 'Аднавіць гэту версію';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Аднавіць версію, захаваную $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Бягучы тэкст спачатку захоўваецца ў гісторыі, таму вы заўсёды '
      'можаце вярнуцца.';
  @override
  String get historyRestoreConfirm => 'Аднавіць';
  @override
  String historyRestored(String when) => 'Адноўлена версія, захаваная $when';
  @override
  String get historyRestoreFailed => 'Не ўдалося аднавіць версію';
  @override
  String get actionUndo => 'Адрабіць';
  @override
  String diffLineRange(int start, int end) => 'Радкі $start–$end';
  @override
  String diffLineSingle(int line) => 'Радок $line';
  @override
  String diffUnchanged(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count нязменены радок',
    (2 || 3 || 4, < 12 || > 14) => '$count нязмененыя радкі',
    _ => '$count нязмененых радкоў',
  };
  @override
  String get historyTakeHunk => 'Аднавіць тут';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Аднавіць 1 змену' : 'Аднавіць $count змен';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Выбраныя змены вяртаюцца да тэксту гэтай версіі. Нататка ў цяперашнім '
      'выглядзе спачатку захоўваецца як версія, таму гэта можна адмяніць.';
  @override
  String get historyNoteChangedReloaded =>
      'Нататка змянілася, пакуль ты быў тут — параўнанне абноўлена.';
  @override
  String get historyVersionsTitle => 'Колькі версій захоўваць';
  @override
  String get historyVersionsSubtitle => 'Для кожнай заўвагі, у .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Няма' : '$count';
  @override
  String get historyIntervalTitle => 'Новая версія не часцей, чым раз на';
  @override
  String get historyIntervalSubtitle =>
      'Падчас пісьма; пачатак рэдагавання заўвагі заўсёды захоўвае адну';
  @override
  String historyIntervalValue(int minutes) => '$minutes хв';
  @override
  String get settingsSectionTranscription => 'Транскрыпцыя';
  @override
  String get transcriptionModelTitle => 'Мадэль';
  @override
  String get transcriptionModelNone => 'Няма';
  @override
  String get transcriptionLanguageTitle => 'Мова';
  @override
  String get transcriptionLanguageSubtitle =>
      'Мова, на якой гавораць у вашых запісах. Указаць яе дакладней, чым '
      'вызначаць аўтаматычна.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Як у праграме ($language)';
  @override
  String get transcriptionLanguageDetect => 'Вызначаць аўтаматычна';
  @override
  String get transcriptionModelsTitle => 'Мадэлі транскрыпцыі';
  @override
  String transcriptionModelsUsed(String size) => 'Занята $size';
  @override
  String get transcriptionModelsInstalled => 'Спампаваныя';
  @override
  String get transcriptionModelsDownloading => 'Спампоўваюцца';
  @override
  String get transcriptionModelsAvailable => 'Даступныя';
  @override
  String get transcriptionModelsFooter =>
      'Мадэлі застаюцца ў сховішчы праграмы на гэтай прыладзе. Яны не '
      'капіруюцца ў бібліятэку і не сінхранізуюцца.';
  @override
  String get transcriptionModelDefault => 'Прадвызначаная';
  @override
  String get transcriptionModelSlow => 'Павольная';
  @override
  String get transcriptionModelHintTiny => 'Найхутчэйшая, найменш дакладная';
  @override
  String get transcriptionModelHintBase =>
      'Добры баланс хуткасці і дакладнасці';
  @override
  String get transcriptionModelHintSmall =>
      'Больш дакладная, прыблізна ў 3× павольнейшая';
  @override
  String get transcriptionModelHintMedium =>
      'Вельмі дакладная, павольная на тэлефоне';
  @override
  String get transcriptionModelHintLarge =>
      'Найдакладнейшая, патрабуе шмат памяці';
  @override
  String get transcriptionModelDownload => 'Спампаваць';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Выдаліць мадэль $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Вызваліцца $size. Вы зможаце спампаваць мадэль зноў пазней.';
  @override
  String get transcriptionModelFailed =>
      'Не ўдалося спампаваць. Праверце злучэнне і паспрабуйце яшчэ раз.';
  @override
  String get actionRetry => 'Паспрабаваць яшчэ раз';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Злучэнне страчана, паўторная спроба…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Прыпынена на $progress';
  @override
  String get actionResume => 'Працягнуць';
  @override
  String get audioTranscribe => 'Транскрыбаваць';
  @override
  String get audioTranscribeUnsupported =>
      'На гэтай прыладзе толькі запісы WAV';
  @override
  String get transcriptionQueued => 'У чарзе';
  @override
  String get transcriptionPreparing => 'Падрыхтоўка аўдыя…';
  @override
  String transcriptionRunning(int percent) => 'Транскрыбаванне… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Спампоўка $model · $percent%';
  @override
  String get transcriptionSaved => 'Транскрыпцыя дададзена да апісання';
  @override
  String get transcriptionNoSpeech => 'У гэтым запісе маўленне не распазнана';
  @override
  String get transcriptionFailed => 'Не ўдалося транскрыбаваць';
  @override
  String get transcriptionPickModelTitle => 'Выберыце мадэль';
  @override
  String get transcriptionPickModelBody =>
      'Транскрыбаванне адбываецца на гэтай прыладзе, запіс ніколі не '
      'адпраўляецца. Мадэль спампоўваецца толькі адзін раз.';
  @override
  String get transcriptionPickModelAction => 'Спампаваць і транскрыбаваць';
  @override
  String get transcriptionModelRecommended => 'Рэкамендавана';
  @override
  String get transcriptionExistingTitle => 'Гэты запіс ужо мае апісанне';
  @override
  String get transcriptionExistingBody =>
      'Замяніць яго транскрыпцыяй ці дадаць транскрыпцыю пад ім?';
  @override
  String get transcriptionAppend => 'Дадаць ніжэй';
  @override
  String get transcriptionReplace => 'Замяніць';
  @override
  String get settingsSectionSync => 'Сінхранізацыя';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Не наладжана для гэтай бібліятэкі';
  @override
  String get syncNeverSynced => 'Яшчэ не сінхранізавалася';
  @override
  String syncLastSynced(String when) => 'Сінхранізавана $when';
  @override
  String get syncRunning => 'Сінхранізацыя…';
  @override
  String syncScreenSubtitle(String library) => 'Бібліятэка $library';
  @override
  String get syncUrlLabel => 'Адрас папкі';
  @override
  String get syncUrlRequired => 'Увядзіце адрас сервера';
  @override
  String get syncUrlHint =>
      'Папка павінна існаваць. Скапіруйце адрас так, як яго '
      'паказвае сервер.';
  @override
  String get syncHttpWarning =>
      'Незашыфраванае злучэнне: падыходзіць праз VPN або ў '
      'лакальнай сетцы.';
  @override
  String get syncUserLabel => 'Карыстальнік';
  @override
  String get syncUserHint =>
      'Пакіньце пустым, калі сервер не патрабуе ўліковых даных.';
  @override
  String get syncPasswordLabel => 'Пароль';
  @override
  String get syncPasswordHint =>
      'Захоўваецца ў сховішчы ключоў гэтай прылады, ніколі ў '
      'файлах бібліятэкі.';
  @override
  String get syncPasswordKeepHint =>
      'Пакіньце пустым, каб пакінуць захаваны пароль.';
  @override
  String get syncShowPassword => 'Паказаць пароль';
  @override
  String get syncHidePassword => 'Схаваць пароль';
  @override
  String get syncTestAction => 'Праверыць злучэнне';
  @override
  String get syncTesting => 'Праверка…';
  @override
  String get syncRetargetWarning =>
      'З новым адрасам або карыстальнікам наступная '
      'сінхранізацыя пачнецца нанова, як першая.';
  @override
  String get syncTestOk => 'Злучэнне працуе';
  @override
  String get syncModeFull => 'Поўны рэжым';
  @override
  String get syncModeCompatible => 'Сумяшчальны рэжым';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Чытанне, запіс і выдаленне';
  @override
  String get syncCapEtags => 'Адбіткі файлаў (ETag)';
  @override
  String get syncCapNoEtags => 'Без адбіткаў файлаў (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Параўноўвае памер і дату; пры сумненні спампоўвае зноў';
  @override
  String get syncCapGuarded => 'Абароненыя запісы';
  @override
  String get syncCapUnguarded => 'Неабароненыя запісы';
  @override
  String get syncCapUnguardedDetail =>
      'Правярае файл на серверы непасрэдна перад запісам';
  @override
  String get syncCapMove => 'Перайменаванне без паўторнага запампоўвання';
  @override
  String get syncCapNoMove => 'Без перайменавання на серверы';
  @override
  String get syncCapNoMoveDetail =>
      'Перайменаванне становіцца выдаленнем і новым '
      'запампоўваннем';
  @override
  String get syncCompatibleNote =>
      'У сумяшчальным рэжыме сінхранізацыя працуе гэтак жа, '
      'толькі з некалькімі дадатковымі запытамі.';
  @override
  String get syncTestInvalidUrl => 'Няправільны адрас';
  @override
  String get syncTestInvalidUrlHint =>
      'Увядзіце адрас http:// або https:// без імя карыстальніка '
      'і пароля.';
  @override
  String get syncTestOffline => 'Сервер недаступны';
  @override
  String get syncTestOfflineHint =>
      'VPN уключаны? Адрас 10.x або 192.168.x працуе толькі з '
      'той жа сеткі.';
  @override
  String get syncTestAuth => 'Карыстальнік або пароль адхілены';
  @override
  String get syncTestAuthHint => 'Праверце іх і паспрабуйце зноў.';
  @override
  String get syncTestNotFound => 'Папка не існуе';
  @override
  String get syncTestNotFoundHint =>
      'Стварыце яе на серверы або выпраўце адрас.';
  @override
  String get syncTestUnsupported => 'Гэта не папка WebDAV';
  @override
  String get syncTestUnsupportedHint => 'Сервер адказвае, але не як WebDAV.';
  @override
  String get syncTestFailed => 'Праверка не ўдалася';
  @override
  String get syncNowAction => 'Сінхранізаваць зараз';
  @override
  String get syncSectionServer => 'Сервер';
  @override
  String get syncServerRow => 'Адрас, карыстальнік і пароль';
  @override
  String get syncRetestTitle => 'Праверыць сервер зноў';
  @override
  String syncProbedAgo(String when) => 'Апошняя праверка: $when';
  @override
  String get syncDisconnectTitle => 'Адлучыць гэту бібліятэку';
  @override
  String get syncDisconnectSubtitle => 'Файлы застаюцца тут і на серверы';
  @override
  String get syncDisconnectConfirmTitle => 'Адлучыць сінхранізацыю?';
  @override
  String get syncDisconnectConfirmBody =>
      'Гэта бібліятэка перастане сінхранізавацца на гэтай '
      'прыладзе. Ніводзін файл не выдаляецца ні тут, ні на '
      'серверы. Калі вы падключыце яе зноў, першая сінхранізацыя '
      'пачнецца нанова.';
  @override
  String get syncDisconnectConfirm => 'Адлучыць';
  @override
  String get syncFirstTitle => 'Першая сінхранізацыя';
  @override
  String get syncFirstIntro => 'Бібліятэка параўнана з папкай на серверы:';
  @override
  String get syncFirstUpload => 'Запампаваць';
  @override
  String get syncFirstDownload => 'Спампаваць';
  @override
  String get syncFirstBoth => 'На абодвух баках';
  @override
  String get syncFirstBothHint =>
      'Аднолькавыя: без перадачы. Розныя: трэба вырашыць';
  @override
  String get syncFirstNoDelete =>
      'Першая сінхранізацыя нічога не выдаляе ні тут, ні на '
      'серверы.';
  @override
  String get syncStartAction => 'Пачаць';
  @override
  String syncMassTrashTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Перамясціць $count файл у смус?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Перамясціць $count файлы ў смус?'
      : 'Перамясціць $count файлаў у смус?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'На серверы няма $count з $total сінхранізаваных файлаў. '
      'Звычайна гэта азначае памылковы адрас, непадключаны дыск '
      'NAS або выпадкова ачышчаную папку.';
  @override
  String get syncMassTrashHint =>
      'Калі вы сапраўды выдалілі іх на іншай прыладзе, '
      'пацвердзіце: тут яны трапяць у смус.';
  @override
  String get syncMassTrashConfirm => 'Перамясціць у смус';
  @override
  String syncMassDeleteTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Выдаліць $count файл з сервера?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Выдаліць $count файлы з сервера?'
      : 'Выдаліць $count файлаў з сервера?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Тут няма $count з $total сінхранізаваных файлаў. Калі вы '
      'іх не выдалялі, адмяніце і праверце папку бібліятэкі.';
  @override
  String get syncMassDeleteConfirm => 'Выдаліць з сервера';
  @override
  String get syncTooltip => 'Сінхранізаваць';
  @override
  String get syncStageConnecting => 'Злучэнне з серверам…';
  @override
  String get syncStageComparing => 'Параўнанне з серверам…';
  @override
  String syncStageApplying(int done, int total) =>
      'Сінхранізацыя · $done з $total';
  @override
  String get syncStatusWarnings => 'Сінхранізавана з папярэджаннямі';
  @override
  String syncConflictsHeader(int count) => 'Зменена тут і на серверы · $count';
  @override
  String get syncConflictHint => 'Ніводная з версій не кранутая';
  @override
  String get syncResolveAction => 'Вырашыць';
  @override
  String syncFailuresHeader(int count) => 'Не сінхранізавана · $count';
  @override
  String get syncFailuresHint => 'Паўторная спроба пры наступнай сінхранізацыі';
  @override
  String get syncAbortAuth => 'Сервер адхіліў пароль';
  @override
  String get syncAbortMissingPassword => 'Няма захаванага пароля';
  @override
  String get syncAbortOffline => 'Сервер недаступны';
  @override
  String get syncAbortRemoteMissing => 'Папкі на серверы больш няма';
  @override
  String get syncAbortUnsupported => 'Сервер больш не працуе як WebDAV';
  @override
  String get syncAbortFailed => 'Сінхранізацыя не ўдалася';
  @override
  String get syncAbortNotConfirmed => 'Сінхранізацыя скасаваная';
  @override
  String get syncAbortNothingTouched =>
      'Ніводзін файл не крануты. Вашы змены застаюцца тут да '
      'наступнай паспяховай сінхранізацыі.';
  @override
  String syncLastSuccess(String when) =>
      'Апошняя паспяховая сінхранізацыя: $when';
  @override
  String get syncNoSuccessYet => 'Паспяховай сінхранізацыі яшчэ не было';
  @override
  String get syncUpdatePasswordAction => 'Абнавіць пароль';
  @override
  String get syncRetryAction => 'Паспрабаваць зноў';
  @override
  String get syncOpenSettingsAction => 'Налады';
  @override
  String get syncCloseAction => 'Зачыніць';
  @override
  String get syncDoneSnack => 'Сінхранізавана';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Сінхранізавана · $count файл, выдалены ў іншым месцы, у '
            'смусе'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Сінхранізавана · $count файлы, выдаленыя ў іншым месцы, у '
            'смусе'
      : 'Сінхранізавана · $count файлаў, выдаленых у іншым месцы, '
            'у смусе';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Сінхранізавана · $count канфлікт трэба вырашыць'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Сінхранізавана · $count канфлікты трэба вырашыць'
      : 'Сінхранізавана · $count канфліктаў трэба вырашыць';
  @override
  String get syncShowAction => 'Паказаць';
  @override
  String get syncConflictTitle => 'Вырашыць канфлікт';
  @override
  String get syncConflictLegend =>
      'Радкі з − з сервера, радкі з + з гэтай прылады.';
  @override
  String get syncConflictBinary =>
      'Гэта не тэкставы файл: выберыце, якую копію пакінуць.';
  @override
  String get syncConflictKeepNote =>
      'Копія, якую вы не пакінеце, застанецца ў гісторыі заўвагі.';
  @override
  String get syncKeepLocal => 'Пакінуць версію з гэтай прылады';
  @override
  String get syncKeepRemote => 'Пакінуць версію з сервера';
  @override
  String get syncConflictIdentical => 'Абедзве версіі аднолькавыя';
  @override
  String get syncConflictLoadFailed => 'Не ўдалося прачытаць абедзве версіі';
  @override
  String get syncResolveFailed => 'Не ўдалося вырашыць канфлікт';
  @override
  String get syncResolved => 'Канфлікт вырашаны';
  @override
  String get syncSectionWhen => 'Калі сінхранізаваць';
  @override
  String get syncAutoTitle => 'Аўтаматычна';
  @override
  String get syncAutoSubtitle =>
      'Пасля змен, пры адкрыцці і праз прамежкі часу';
  @override
  String get syncIntervalTitle => 'Правяраць сервер кожныя';
  @override
  String get syncIntervalSubtitle => 'Толькі пакуль праграма адкрыта';
  @override
  String get syncIntervalDialogBody =>
      'Каб бачыць змены, зробленыя на іншых прыладах, пакуль праграма адкрыта. '
      'З «Ніколі» — толькі пасля змен і пры адкрыцці.';
  @override
  String syncIntervalMinutes(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count хвіліна',
    (2 || 3 || 4, < 12 || > 14) => '$count хвіліны',
    _ => '$count хвілін',
  };
  @override
  String get syncIntervalNever => 'Ніколі';
  @override
  String get syncWifiOnlyTitle => 'Толькі праз Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Праз мабільныя даныя сінхранізаваць толькі ўручную';
  @override
  String syncPendingChanges(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count змена чакае',
    (2 || 3 || 4, < 12 || > 14) => '$count змены чакаюць',
    _ => '$count змен чакае',
  };
  @override
  String syncRetryIn(String wait) => 'новая спроба праз $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds с';
  @override
  String syncWaitMinutes(int minutes) => '$minutes хв';
  @override
  String get syncWaitingForWifi => 'Чаканне Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Чаканне злучэння';
  @override
  String get syncMobileDataHint =>
      '«Сінхранізаваць зараз» усё роўна выкарыстоўвае мабільныя даныя.';
  @override
  String get syncQueueKeptHint =>
      'Змены застаюцца тут, нават калі вы закрыеце праграму, і адпраўляюцца '
      'самі, калі сервер адкажа.';
  @override
  String get syncAutoPaused => 'Аўтаматычная сінхранізацыя прыпынена';
  @override
  String get syncPausedAuthHint =>
      'Яна адновіцца, калі вы абновіце пароль або сінхранізуеце ўручную.';
  @override
  String get syncPausedServerHint =>
      'Яна адновіцца, калі вы выправіце адрас або сінхранізуеце ўручную.';
  @override
  String get syncPausedConfirmHint =>
      '«Сінхранізаваць зараз» пакажа, што будзе выдалена, і спачатку спытае.';
  @override
  String get syncNeedsConfirmation => 'Чаканне вашага пацвярджэння';
  @override
  String get syncMergeIntro =>
      'Змены, якія не перакрываюцца, ужо аб’яднаны; там, дзе перакрываюцца, '
      'выберыце, што пакінуць.';
  @override
  String get syncMergeClean =>
      'Дзве версіі аб’ядноўваюцца самі: нічога не перакрываецца.';
  @override
  String get syncMergeNoBase =>
      'Няма агульнай версіі для аб’яднання, таму трэба выбраць увесь файл.';
  @override
  String syncMergeOverlap(int index, int total) => 'Перакрыццё $index з $total';
  @override
  String get syncMergeFromLocal => 'З гэтай прылады';
  @override
  String get syncMergeFromRemote => 'З сервера';
  @override
  String get syncMergeRemovedLines => 'Радкі выдалены';
  @override
  String get syncMergeKeepLocal => 'Мае';
  @override
  String get syncMergeKeepRemote => 'Сервера';
  @override
  String get syncMergeKeepBoth => 'Абодва';
  @override
  String get syncMergeSave => 'Захаваць аб’яднанне';
  @override
  String get syncMergeKeepWhole => 'Або пакінуць адну цэлую копію';
}
