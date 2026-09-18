// The Bulgarian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class BulgarianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'януари',
    'февруари',
    'март',
    'април',
    'май',
    'юни',
    'юли',
    'август',
    'септември',
    'октомври',
    'ноември',
    'декември',
  ];
  @override
  List<String> get monthNamesShort => const [
    'ян',
    'фев',
    'март',
    'апр',
    'май',
    'юни',
    'юли',
    'авг',
    'сеп',
    'окт',
    'ное',
    'дек',
  ];
  @override
  List<String> get weekdayNames => const [
    'понеделник',
    'вторник',
    'сряда',
    'четвъртък',
    'петък',
    'събота',
    'неделя',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'пн',
    'вт',
    'ср',
    'чт',
    'пт',
    'сб',
    'нд',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Кошът';
  @override
  String get trashSubtitle =>
      'Изтритите елементи се преместват в .trash/ (изключено = окончателно '
      'изтриване)';
  @override
  String get trashAutoEmptyTitle => 'Автоматично изпразване на коша';
  @override
  String get trashAutoEmptySubtitle =>
      'Старите изтривания изчезват завинаги при отваряне на библиотеката';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Никога'
      : days == 1
      ? '1 ден'
      : '$days дни';
  @override
  String get debugLogsTitle => 'Джурнали за отключване';
  @override
  String get debugLogsSubtitle =>
      'Записва събитията на програмата в буфер в паметта';
  @override
  String get lineNumbersTitle => 'Номера на редовете';
  @override
  String get lineNumbersSubtitle =>
      'Показва колоната с номера на редовете в редактора';
  @override
  String get keyboardOnOpenTitle => 'Клавиатура при отваряне';
  @override
  String get keyboardOnOpenSubtitle =>
      'Показва клавиатурата при отваряне на бележка (изключено = при '
      'първо докосване)';
  @override
  String get editorKindSource => 'Изходен код на Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown изходник, както е написан';
  @override
  String get editorKindWysiwygSubtitle =>
      'Форматиран текст, редактира се директно';
  @override
  String get settingsFolderToCreate => 'за създаване';
  @override
  String get settingsSearchHint => 'Търсене в настройките';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 намерена настройка' : '$count намерени настройки';
  @override
  String get settingsToggleOn => 'Вкл.';
  @override
  String get settingsToggleOff => 'Изкл.';
  @override
  String get settingsPreviewEnabledTitle => 'Преглед';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Показва оформения бележка до редактора на източника';
  @override
  String get switchToWysiwygTooltip => 'Превключване към WYSIWYG редактор';
  @override
  String get switchToSourceTooltip =>
      'Превключване към изходен Markdown '
      'код';
  @override
  String get switchToSourceLabel => 'Изходник';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Тази бележка е твърде голяма за WYSIWYG редактора. Отворете я като '
      'изходен Markdown код.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Външен вид';
  @override
  String get settingsSectionEditor => 'Редактор';
  @override
  String get settingsSectionLibrary => 'Библиотека';
  @override
  String get settingsSectionReminders => 'Напомняния';
  @override
  String get settingsSectionShortcuts => 'Клавиатура';
  @override
  String get keyboardShortcutsTitle => 'Клавишни комбинации';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Библиотека $name';
  @override
  String get settingsGroupLibraryHint => 'важи само за тази библиотека';
  @override
  String get settingsGroupMaintenance => 'Поддръжка';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Папки и пътища';
  @override
  String get settingsAreaTrashHistory => 'Кош и история';
  @override
  String get settingsAreaDiagnostics => 'Диагностика и инфо';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Нужна е свързана физическа клавиатура';
  @override
  String get settingsSectionUpdates => 'Актуализации';
  @override
  String get autoUpdateTitle => 'Автоматични актуализации';
  @override
  String get autoUpdateSubtitle =>
      'Проверява GitHub Releases при стартиране и на всеки 6 часа';
  @override
  String get checkForUpdatesTitle => 'Провери за актуализации';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version е наличен';
  @override
  String get updateUpToDate => 'Niman е актуален';
  @override
  String get updateCheckFailed => 'Проверката за актуализации е неуспешна';
  @override
  String updateSavedTo(Object path) => 'Актуализацията е запазена в $path';
  @override
  String get updateInstallerStarted => 'Инсталаторът е стартиран';
  @override
  String get settingsSectionDiagnostics => 'Диагностика';
  @override
  String get settingsSpellCheckTitle => 'Проверка за правопис';
  @override
  String get settingsSpellCheckSubtitle =>
      'Подчертава правописни грешки докато пишете.';
  @override
  String get spellCheckDictionaryTitle => 'Словар';
  @override
  String get spellCheckDictionarySystem => 'Системен по подразбиране';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Избор на словари';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Изберете всички езици, на които е написана библиотеката. Думата '
      'минава, ако някой от избраните словари я разпознае; без избор — '
      'езикът на системата.';
  @override
  String get spellCheckNoDictionaries =>
      'Не са намерени словари в тази система.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Проверка за правопис';
  @override
  String get spellCheckTitle => 'Правопис';
  @override
  String get spellCheckEmpty => 'Няма правописни грешки.';
  @override
  String get spellCheckUnavailable =>
      'hunspell не е инсталиран в тази система.';
  @override
  String get spellCheckNoSuggestions => 'Няма предложения';
  @override
  String spellCheckCount(int count) => '$count за преглед';
  @override
  String spellCheckLine(int line) => 'ред $line';
  @override
  String get addWordToDictionary => 'Добави в речника';

  @override
  String indentWidthValue(int spaces) => '$spaces интервала';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Яркост';
  @override
  String get themeBrightnessSubtitle =>
      'Светла, тъмна или настройка на устройството';
  @override
  String get themeBrightnessSystem => 'Система';
  @override
  String get themeBrightnessDay => 'Светла';
  @override
  String get themeBrightnessNight => 'Тъмна';
  @override
  String get themePaletteTitle => 'Палитра на цветовете';
  @override
  String get themePaletteSubtitle => 'Цветовете на интерфейса и бележките';
  @override
  String get themePaletteSystem => 'Система';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Размер на текста в интерфейса';
  @override
  String get uiTextScaleSubtitle =>
      'Дървото, картите и диалоговите прозорци; върху системната '
      'настройка';
  @override
  String get noteTextScaleTitle => 'Размер на текста в бележките';
  @override
  String get noteTextScaleSubtitle =>
      'Редакторът и прегледът винаги са синхронизирани';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Режим на преглед';
  @override
  String get previewModeSubtitle =>
      'Прегледът споделя екрана с редактора или го замества';
  @override
  String get previewModeAuto => 'Редом';
  @override
  String get previewModeSwitch => 'Цял екран';
  @override
  String get splitRatioTitle => 'Съотношение на разделението';
  @override
  String get splitRatioSubtitle => 'Дял на редактора, когато прегледът е редом';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Формат на връзката';
  @override
  String get linkTypeSubtitle => 'Какво бутонът за връзка вписва в редактора';
  @override
  String get linkTypeWikilink => 'Вики връзка';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Създаване на липсващи бележки в';
  @override
  String get missingNoteLocationRoot => 'Корен на библиотеката';
  @override
  String get missingNoteLocationCurrentFolder => 'Текуща папка';
  @override
  String get indentWidthTitle => 'Ширина на отстъпа';
  @override
  String get indentWidthSubtitle =>
      'Брой интервали, добавени на всяко ниво на отстъп в редактора';
  @override
  String get languageTitle => 'Език';
  @override
  String get languageSubtitle => 'Език на самата програма';
  @override
  String get languageSystem => 'Система';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Добавете елемент';
  @override
  String get listAddTooltip => 'Добавете елемент';
  @override
  String get listEmpty => 'Все още няма елементи';
  @override
  String get listDragHandleLabel => 'Сменете реда на елементите';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Все още няма записи';
  @override
  String get audioRecord => 'Запиши';
  @override
  String get audioStop => 'Спри';
  @override
  String get audioPlay => 'Пусни';
  @override
  String get audioDelete => 'Изтрий записа';
  @override
  String get audioImport => 'Импортирай аудиофайл';
  @override
  String get audioRecording => 'Записване…';
  @override
  String get audioPermissionDenied =>
      'Достъпът до микрофона е отказан — нужен е за записване.';
  @override
  String get newAudioNoteTitle => 'Нова гласова бележка';
  @override
  String get newAudioNoteDefault => 'Моят запис';
  @override
  String get showAudioTooltip => 'Покажи записите';
  @override
  String get audioMessageHint => 'Напишете бележка…';
  @override
  String get audioSend => 'Изпрати';
  @override
  String get audioRename => 'Презаглави записа';
  @override
  String get audioDescriptionHint => 'Опишете този запис…';
  @override
  String get audioEditDescription => 'Редактирай описанието';
  @override
  String get audioDeleteNote => 'Изтрий бележката';
  @override
  String get audioEditNote => 'Редактирай бележката';
  @override
  String get audioPause => 'Пауза';
  @override
  String get audioEditTitle => 'Редактиране на заглавието';
  @override
  String get audioTitleHint => 'Заглавие на записа…';
  @override
  String audioUntitled(int n) => 'Запис $n';
  @override
  String get audioMoreActions => 'Още действия';
  @override
  String get audioDiscardRecording => 'Отхвърляне на записа';
  @override
  String get audioPauseRecording => 'Пауза на записа';
  @override
  String get audioResumeRecording => 'Продължи записа';
  @override
  String get audioRecordingPaused => 'На пауза';
  @override
  String get audioSavingRecording => 'Запазване…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Бърза бележка';
  @override
  String get shortcutNewTodo => 'Нова задача';
  @override
  String get shortcutNewNote => 'Нова бележка';
  @override
  String get shortcutNewList => 'Нов списък';
  @override
  String get shortcutNewAudio => 'Нова гласова бележка';
  @override
  String get shortcutToggleSidebar => 'Покажи или скрий филтъра';
  @override
  String get shortcutEditorSection => 'В редактора';
  @override
  String get shortcutFind => 'Търси';
  @override
  String get shortcutReplace => 'Намери и замени';
  @override
  String get shortcutSavingNote =>
      'Промените се запазват автоматично, така че няма клавишна комбинация '
      'за записване.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Зареждане…';
  @override
  String get noteStatusSaving => 'Запазване…';
  @override
  String get noteStatusUnsaved => 'Незапазено';
  @override
  String get noteStatusSaved => 'Запазено';
  @override
  String get noteStatusError => 'Грешка';
  @override
  String get noteNotText =>
      'Този файл не е текстова бележка, затова Niman не може да го покаже тук.';
  @override
  String get noteLoadFailed => 'Тази бележка не можа да бъде отворена.';
  @override
  String wordCount(int count) => count == 1 ? '1 дума' : '$count думи';
  @override
  String get outlineTooltip => 'Структура';
  @override
  String get outlineNoHeadings => 'Няма заглавия';
  @override
  String get outlineNoTitle => '(без заглавие)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Получер';
  @override
  String get toolbarItalic => 'Курсив';
  @override
  String get toolbarStrikethrough => 'Зачеркано';
  @override
  String get toolbarSuperscript => 'Надстрочен индекс';
  @override
  String get toolbarUnderline => 'Подчертано';
  @override
  String get toolbarLink => 'Връзка';
  @override
  String get toolbarCode => 'Кодов блок';
  @override
  String get toolbarImage => 'Вмъкване на изображение';
  @override
  String get toolbarHeading => 'Заглавие';
  @override
  String get toolbarList => 'Списък';
  @override
  String get toolbarOrderedList => 'Номериран списък';
  @override
  String get toolbarQuote => 'Цитат';
  @override
  String get toolbarIndent => 'Отстъп';
  @override
  String get toolbarOutdent => 'Премахване на отстъп';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Инструменти';
  @override
  String get editorToolsTitle => 'Инструменти на редактора';
  @override
  String get toolCountListTitle => 'Преброй списък';
  @override
  String get toolCountListSubtitle =>
      'Обобщава изброеното в редовете като списък с отметки';
  @override
  String get toolCountListNeedsList =>
      'Тази бележка няма списък за преброяване';
  @override
  String get tallySourceLabel => 'Списък';
  @override
  String get tallyCutLabel => 'Чети всеки ред като';
  @override
  String get tallyCutDash => 'Име - стойности';
  @override
  String get tallyCutColon => 'Име: стойности';
  @override
  String get tallyCutCommas => 'Стойности, разделени със запетая';
  @override
  String get tallyCutWhole => 'Целият ред като една стойност';
  @override
  String get tallySortLabel => 'Подредба';
  @override
  String get tallySortCount => 'Най-често първо';
  @override
  String get tallySortAlphabetical => 'По азбучен ред';
  @override
  String get tallySortFirstSeen => 'Както са изброени';
  @override
  String get tallyInsert => 'Вмъкни';
  @override
  String get tallyUpdate => 'Обнови';
  @override
  String get tallyNothingToCount => 'Тук няма какво да се брои';
  @override
  String get headingDialogTitle => 'Ниво на заглавието';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Панел на редактора';
  @override
  String get toolbarSettingsHint =>
      'Плъзгайте, за да смените реда; окото показва или скрива бутон.';
  @override
  String get toolbarShowButton => 'Покажи';
  @override
  String get toolbarHideButton => 'Скрий';
  @override
  String get toolbarResetOrder => 'Възстанови по подразбиране';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Покажи преглед';
  @override
  String get showEditorTooltip => 'Покажи редактор';
  @override
  String get enterFullScreenTooltip => 'Цял екран';
  @override
  String get exitFullScreenTooltip => 'Изход от цял екран';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(неоформена HTML таблица)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Търси в бележките';
  @override
  String get searchModeWords => 'Думи';
  @override
  String get searchModeContains => 'Съдържа';
  @override
  String get searchEmptyHint =>
      'Въведете, за да търсете в библиотеката, или ключ = стойност, за да '
      'филтрирате по метаданни';
  @override
  String get searchTooShortHint => 'Въведете поне 2 символа';
  @override
  String get searchNoMatches => 'Няма резултати';
  @override
  String get searchLoadMore => 'Покажи още';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Замени…';
  @override
  String get replaceInNoteAction => 'Замени в тази бележка…';
  @override
  String get replaceInThisNote => 'Замени в тази бележка';
  @override
  String get replaceWithLabel => 'Замени с';
  @override
  String get replaceCaseSensitive => 'Различава главни и малки букви';
  @override
  String get replaceWholeWordsHint =>
      'замества се само точното съвпадение на цялата дума';
  @override
  String get replaceConfirm => 'Замени';
  @override
  String get replaceCancel => 'Затвори';
  @override
  String get replaceUnavailable => 'Заместването не е налично в момента';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Търси в бележката';
  @override
  String get editorFindHint => 'Търси';
  @override
  String get editorReplaceHint => 'Замени';
  @override
  String get editorFindCaseTooltip => 'Различава главни и малки букви';
  @override
  String get editorFindPreviousTooltip => 'Предишен резултат';
  @override
  String get editorFindNextTooltip => 'Следващ резултат';
  @override
  String get editorFindCloseTooltip => 'Затвори търсенето';
  @override
  String get editorFindReplaceModeTooltip => 'Режим на заместване';
  @override
  String get editorReplaceOneTooltip => 'Замени този резултат';
  @override
  String get editorReplaceAllTooltip => 'Замени всички резултати';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Етикети';
  @override
  String get tagsTitle => 'Етикети';
  @override
  String get tagsEmpty =>
      'Все още няма етикети — добавете #етикета в бележка или етикети в '
      'метаданните';
  @override
  String get tagsBackTooltip => 'Назад към търсенето';
  @override
  String get tagsNotesEmpty => 'Няма бележки с този етикет';
  @override
  String tagsNotesCapped(int limit) =>
      'Показват се само първите $limit — потърсете по етикет, за да '
      'стесните';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Връзката не е намерена';
  @override
  String get headingNotFoundTitle => 'Заглавието не е намерено';
  @override
  String get ambiguousLinkTitle => 'Няколко бележки съответстват';
  @override
  String get openLinkFailed => 'Не може да се отвори връзката';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Бележката не съществува';
  @override
  String missingNoteDialogBody(String path) => 'Да се създаде „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Папката „$folder“ не съществува';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Отворени';
  @override
  String get todoDone => 'Завършени';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Всички дати';
  @override
  String get todoFilter => 'Филтрирай';
  @override
  String get todoNoTokens => 'Няма токени в този списък';
  @override
  String get todoCountOpen => 'отворени';
  @override
  String get todoCountDone => 'завършени';
  @override
  String get todoEmptyOpen => 'Все още няма отворени задачи';
  @override
  String get todoEmptyDone => 'Все още няма завършени';
  @override
  String get todoEmptyFiltered => 'Няма съответстващи задачи';
  @override
  String get todoTitle => 'Задачи';
  @override
  String get todoAddTooltip => 'Добавете задача';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Формат на todo.txt';
  @override
  String get todoHelpTooltip => 'Информация за формата';
  @override
  String get todoHelpIntro =>
      'Задачите ви са обикновен текстов файл, една задача на ред. Niman '
      'записва синтаксиса вместо вас, но файлът може да се редактира в '
      'който и да е редактор и Niman ще го прочете отново.';
  @override
  String get todoHelpFilesTitle => 'Два файла';
  @override
  String get todoHelpFilesBody =>
      'Отворените задачи живеят в todo.txt в корена на библиотеката. При '
      'завършване редът се премества в done.txt, за да остане todo.txt '
      'кратък. Завършеният ред, който се появи отново в todo.txt, Niman '
      'архивира при следващото четене на файла.';
  @override
  String get todoHelpLineTitle => 'Анатомия на реда';
  @override
  String get todoHelpLineBody =>
      'Всичко преди описанието е избор и трябва да е в този ред:';
  @override
  String get todoHelpDoneBody =>
      'Означава задачата като завършена. Niman я добавя, когато отметнете '
      'полето.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Приоритет. A е най-висок. Показва се като емблема в списъка.';
  @override
  String get todoHelpDatesBody =>
      'Краен срок, след това дата на създаване. С една дата това е датата '
      'на създаване, ако редът не започва с x.';
  @override
  String get todoHelpTokensTitle => 'Проекти, контексти и етикети';
  @override
  String get todoHelpTokensBody =>
      'Всяка дума в описанието с един от тези префикси става филтрируем '
      'етикет. Нищо не е дефинирано предварително: токенът съществува, '
      'докато не го напишете.';
  @override
  String get todoHelpProjectBody =>
      'Кой проект притежава задачата, напр. +кухня или +работа.';
  @override
  String get todoHelpContextBody =>
      'Къде или как да я направите, напр. @у дома или @среща.';
  @override
  String get todoHelpHashtagBody =>
      'Свободен етикет за това, което другите два не покриват.';
  @override
  String get todoHelpTagsTitle => 'Дати и напомняния';
  @override
  String get todoHelpTagsBody =>
      'Тези са етикети с ключ:стойност. Niman ги записва от диалога за '
      'задачата и ги прочита навсякъде, където се появят в реда.';
  @override
  String get todoHelpDueBody =>
      'Краен срок. Управлява цвета на емблемата и датните филтри.';
  @override
  String get todoHelpRemBody =>
      'Кога да се изпрати известие във вашия часови пояс. Работи, когато '
      'екранът е изключен, а програмата е отворена.';
  @override
  String get todoHelpRemDesktop =>
      'На компютър Niman трябва да се изпълнява, когато настъпи часът: '
      'напомнянето се показва, докато програмата е отворена, и нищо не се '
      'случва, когато е затворена.';
  @override
  String get todoHelpOtherBody =>
      'Той се запазва точно както е записан, така че етикетите от други '
      'todo.txt програми да оцелеят при преминаването. Niman не ги '
      'използва, rec: включено: повтаряща се задача все още не се повтаря.';
  @override
  String get todoHelpEditTitle => 'Редактиране извън Niman';
  @override
  String get todoHelpEditBody =>
      'Редовете, които не докосвате, се запазват байт по байт. Niman '
      'преписва само този ред в каноничен ред, а останалата част от файла '
      'остава непроменена.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Добавете задача';
  @override
  String get todoEditTitle => 'Редактиране на задача';
  @override
  String get todoDescriptionHint => 'Описание';
  @override
  String get todoCancel => 'Отказ';
  @override
  String get todoSave => 'Запази';
  @override
  String get todoEditAction => 'Редактирай';
  @override
  String get todoDeleteAction => 'Изтрий';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Краен срок е просрочен';
  @override
  String get todoDueToday => 'Днес';
  @override
  String get todoDueNext7 => 'Следващите 7 дни';
  @override
  String get todoDueNoDate => 'Без дата';
  @override
  String get todoRowDue => 'Краен срок';
  @override
  String get todoRowDueToday => 'Краен срок днес';
  @override
  String get todoSortTooltip => 'Сортирай';
  @override
  String get todoSortDue => 'Дата на крайния срок';
  @override
  String get todoSortPriority => 'Приоритет';
  @override
  String get todoSortCreation => 'Дата на създаване';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Без приоритет';
  @override
  String get todoNoPriorityShort => 'Няма';
  @override
  String get todoMorePriorities => 'Още…';
  @override
  String get todoPriorityTitle => 'Приоритет';
  @override
  String get todoNoDueDate => 'Без краен срок';
  @override
  String get todoNoReminder => 'Без напомняне';
  @override
  String get todoAddProject => '+ Проект';
  @override
  String get todoAddContext => '@ Контекст';
  @override
  String get todoAddHashtag => '# Етикет';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Напомняния за задачи';
  @override
  String get todoReminderChannelDescription =>
      'Планирани известия за задачи с време за напомняне.';
  @override
  String get todoReminderBody => 'Напомняне за задача';
  @override
  String get todoReminderFallbackTitle => 'Напомняне за задача';
  @override
  String get todoReminderBlocked =>
      'Известията са изключени, така че напомняванията няма да бъдат '
      'показани.';
  @override
  String get todoReminderBattery =>
      'Оптимизацията на батерията е включена за Niman. Системата може да '
      'спре програмата и да загуби очакваните напомняния.';
  @override
  String get todoReminderInexact =>
      'Това устройство не поддържа точни будници, така че напомнянето '
      'може да стигне с няколко минути по-късно, ако екранът е изключен.';
  @override
  String get reminderShowTokensTitle =>
      'Етикети в известията за '
      'напомняне';
  @override
  String get reminderShowTokensSubtitle =>
      'Оставете +проект, @контекст и #етикета в текста на известията. '
      'Изключено показва само задачата, която написахте.';
  @override
  String get todoReminderFixAction => 'Отвори настройките';
  @override
  String get todoReminderDismissAction => 'Отхвърли';
  @override
  String get todoReminderDue => 'Краен срок';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Добре';
  @override
  String get actionCancel => 'Отказ';
  @override
  String get actionCreate => 'Създай';
  @override
  String get actionNew => 'Нов';
  @override
  String get actionSave => 'Запази';
  @override
  String get actionClear => 'Изчисти';
  @override
  String get actionChoose => 'Избери';
  @override
  String get actionDelete => 'Изтрий';
  @override
  String get actionRename => 'Презаглави';
  @override
  String get actionMove => 'Премести';
  @override
  String get saveAndClose => 'Запази и затвори';
  @override
  String get closeUnsavedTitle => 'Незапазени промени';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” има незапазени промени. '
          'Да се запази ли преди затваряне?';
    }
    return '${names.length} бележки имат незапазени промени. '
        'Да се запази ли преди затваряне?';
  }

  @override
  String get closeSaveFailed =>
      'Записването не успя; бележката остава отворена.';
  @override
  String get actionRestore => 'Възстанови';
  @override
  String get actionEmpty => 'Изпразни';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Скрий страничната лента (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Покажи страничната лента (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Минимизиране';
  @override
  String get windowMaximizeTooltip => 'Максимизиране';
  @override
  String get windowRestoreTooltip => 'Възстанови';
  @override
  String get windowCloseTooltip => 'Затвори';
  @override
  String get tabFiles => 'Файлове';
  @override
  String get tabSearch => 'Търсене';
  @override
  String get tabSettings => 'Настройки';
  @override
  String get quickNoteTitle => 'Бърза бележка';
  @override
  String get treeEmpty => 'Все още няма бележки';
  @override
  String get selectANote => 'Изберете бележка';
  @override
  String get showListTooltip => 'Покажи списъка';
  @override
  String get editRawTooltip => 'Редактирай изходен код';
  @override
  String get sortAscTooltip => 'Сортирай А–Я';
  @override
  String get sortDescTooltip => 'Сортирай Я–А';
  @override
  String get newNoteTitle => 'Нова бележка';
  @override
  String get newItemTooltip => 'Ново';
  @override
  String get closeMenuTooltip => 'Затваряне';
  @override
  String get newFolderTitle => 'Нова папка';
  @override
  String get newNoteSameFolder => 'Нова бележка в същата папка';
  @override
  String get newFromTemplateSameFolder => 'Нова от шаблон в същата папка';
  @override
  String trashOriginalPath(String path) => 'беше в $path';
  @override
  String get trashOriginalRoot => 'беше в корена на библиотеката';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 елемент' : '$count елемента';
  @override
  String get newNoteHere => 'Нова бележка тук';
  @override
  String get newFolderHere => 'Нова папка тук';
  @override
  String get newListNoteTitle => 'Нова бележка със списък';
  @override
  String get newListNoteDefault => 'Моят списък';
  @override
  String get setAsQuickNote => 'Задай като бърза бележка';
  @override
  String get currentQuickNote => 'Текуща бърза бележка';
  @override
  String get pinnedSection => 'Закачени';
  @override
  String pinnedSectionCount(int count) => 'Закачени · $count';
  @override
  String get templateFolderTitle => 'Папка за шаблони';
  @override
  String get newFromTemplateTitle => 'Нов от шаблон';
  @override
  String get newFromTemplateHere => 'Нов от шаблон тук';
  @override
  String get templateFormTitle => 'Попълни шаблон';
  @override
  String get templateFormBacklink => 'Обратна връзка';
  @override
  String get templateFormNoNote => 'Без бележка';
  @override
  String get templateFormPickNote => 'Избери бележка';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Замятащи знаци на шаблона';
  @override
  String get templateHelpSubtitle =>
      'Дата, заглавие и останалите стойности за попълване';
  @override
  String get quickNoteSubtitle =>
      'Бележката, която отваря разделът за бърза бележка';
  @override
  String get listFolderSubtitle => 'Новите списъци със задачи';
  @override
  String get templateFolderSubtitle => 'Източникът на „Нова от шаблон“';
  @override
  String get attachmentsFolderSubtitle =>
      'Изображения и звук, вмъкнати в бележка';
  @override
  String get templateHelpIntro =>
      'Шаблонът е обикновена бележка с отвори. При създаване на бележка '
      'от него текстът се копира, а отворите се попълват.';
  @override
  String get templateHelpUnknown =>
      'Замятащ знак, който Niman не познава, остава както е записан, така '
      'че грешката от клавиатурата да се види в бележката, а не да изтрие '
      'реда в мълчание.';
  @override
  String get templateHelpValuesTitle => 'Стойности';
  @override
  String get templateHelpTitleBody =>
      'Име, с което бележката трябва да бъде създадена.';
  @override
  String get templateHelpDateBody =>
      'Днес и текущото време. И двата приемат формата: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Дата и час заедно.';
  @override
  String get templateHelpUuidBody =>
      'Нов уникален идентификатор, различен при всяко използване.';
  @override
  String get templateHelpCounterBody =>
      'Брой, броен по името, запазен между стартовете: първата бележка '
      'записва 1, следващата — 2. Същото име в бележка записва същия '
      'брой; комбинирайте с |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Поставете курсора тук при създаване на бележка; знакът не се '
      'записва. Първият знак печели, без филтри, само в новите бележки — '
      'и клавиатурата се отваря дори ако autofocus е изключен.';
  @override
  String get templateHelpDatesTitle => 'Записване на дата';
  @override
  String get templateHelpDatesBody =>
      'Тези означават части от датата в формата. Всичко останало е '
      'буквално, включително текст в обикновени кавички. Имената на '
      'месеците и дните от седмицата използват езика на програмата.';
  @override
  String get templateHelpYear => 'година: 2026, 26';
  @override
  String get templateHelpMonth => 'месец: 03, 3, март, мар';
  @override
  String get templateHelpDay => 'ден: 09, 9, понеделник, пн';
  @override
  String get templateHelpTime => 'часове, минути, секунди';
  @override
  String get templateHelpWeek => 'ISO седмица и тримесечие: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Филтри';
  @override
  String get templateHelpFiltersBody =>
      'Стойността може да бъде последвана от филтри, приложени от ляво '
      'на дясно.';
  @override
  String get templateHelpCaseBody =>
      'ГОЛЕМИ, малки и всяка дума с главна буква — дума, записана с '
      'главна, остава непроменена.';
  @override
  String get templateHelpSlugBody =>
      'Формата на връзката от текст, за да създаде вики връзка.';
  @override
  String get templateHelpPadBody =>
      'Изрязва краищата; попълва с нули до желаната ширина; алтернатива, '
      'ако стойността е празна.';
  @override
  String get templateHelpShiftBody =>
      'Премести датата с дни, седмици, месеци или години — конференция '
      'след седмица, документ от миналия месец.';
  @override
  String get templateHelpSnapBody =>
      'Закачи датата за началото или края на седмица, месец или година.';
  @override
  String get templateHelpAskTitle => 'Да питаме за нещо';
  @override
  String get templateHelpAskBody =>
      'Преди създаването на бележката се показва форма с полета за '
      'въпроси — и една обратна връзка, ако шаблонът я изисква. Същият '
      'знак два пъти е въпрос и отговорът му попълва всички появления — '
      'папката и името на файла.';
  @override
  String get templateHelpAskFieldBody =>
      'Полето, за което се пита; текстът след втората запетая е начална '
      'стойност.';
  @override
  String get templateHelpChoiceBody => 'Избор от списък, разделен със запетаи.';
  @override
  String get templateHelpWhereTitle => 'Къде бележката отива';
  @override
  String get templateHelpWhereBody =>
      'Това не е текст: това са указания, които живеят в niman: блока на '
      'метаданните на шаблона. Блокът се изпълнява и се маха, така че '
      'никога да не се показва в бележката. Стойността може да съдържа '
      'замятащи знаци.';
  @override
  String get templateHelpFolderBody =>
      'Папката, в която бележката се създава, се създава, ако не '
      'съществува. Без нея бележката отива там, където бяхте.';
  @override
  String get templateHelpFilenameBody =>
      'Как бележката се казва. Шаблонът, който казва това, не пита за '
      'име.';
  @override
  String get templateHelpAppendBody =>
      'Добавете към бележката, ако вече съществува, вместо да създаде '
      'нова. Така месечната среща става един файл.';
  @override
  String get templateHelpOpenBody =>
      'Какво се случва, ако бележката съществува: редактор (по '
      'подразбиране), преглед или нищо — бележката се архивира и вие '
      'оставате там, където бяхте.';
  @override
  String get templateHelpAroundTitle => 'Откъде идва';
  @override
  String get templateHelpParentBody =>
      'Бележка, която изберете в формата; запишете [[{{parent}}]] като '
      'обратна връзка.';
  @override
  String get templateHelpFolderValueBody => 'Папката, в която бележката отива.';
  @override
  String get templateHelpClipboardBody =>
      'Какво е в клипборда и избрано в редактора, ако бележката е '
      'започнала там.';
  @override
  String get templateHelpIncludeTitle => 'Повторно използване на части';
  @override
  String get templateHelpIncludeBody =>
      'Вмъкнете друг шаблон, така че няколко шаблона да споделят един '
      'проверен списък. Търсенето първо става в папката за шаблони, .md '
      'може да е пропуснато. Същите въпроси отиват в същата форма.';
  @override
  String get templateHelpExampleTitle => 'Всичко на едно място';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ шаблонът „$path” не съществува';
  @override
  String includeCycle(String path) => '⚠ „$path” се вмъкнат самите се';
  @override
  String includeTooDeep(String path) => '⚠ „$path” е вмъкната твърде дълбоко';
  @override
  String frontmatterInvalid(String reason) =>
      'Не може да се прочетат метаданните: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Не може да се прочетат метаданните на „$template”, така че папката '
      'и името на файла не се прилагаха: $reason';
  @override
  String get templatePickerTitle => 'Избор на шаблон';
  @override
  String templatePickerEmpty(String folder) =>
      'Все още няма шаблони. Поставете бележка в $folder/ и тя ще бъде.';

  // Tree actions.
  @override
  String get actionPin => 'Закачи';
  @override
  String get actionUnpin => 'Откачи';
  @override
  String get pinToWidget => 'Закачи към домашен виджет';
  @override
  String get pinnedForWidget =>
      'Закачено: поставете виджета „Бележка“ на домашния екран';
  @override
  String get pinWidgetUnavailable =>
      'Виджетите на домашния екран са достъпни в Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Показване във файловия мениджър';
  @override
  String get openInDefaultApp => 'Отваряне с приложението по подразбиране';
  @override
  String get openFileMissing => 'Файлът на тази бележка не е на диска';
  @override
  String get openFileFailed => 'Бележката не можа да бъде отворена извън Niman';

  @override
  String get movedToTrash => 'Преместен в коша';
  @override
  String get deletedMessage => 'Изтрито';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name ще бъде преместен в .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name ще бъде изтрит окончателно';
  @override
  String get chooseDestination => 'Изберете дестинация';
  @override
  String get libraryRoot => 'Корен на библиотеката';
  @override
  String moveTitle(String name) => 'Премести $name';
  @override
  String headingLevelLabel(int level) => 'Ниво на заглавието $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Все още няма бърза бележка. Изберете съществуваща бележка или '
      'създайте нова — бързата бележка ще се отвори тук.';
  @override
  String get quickNoteChooseAction => 'Изберете бележка…';
  @override
  String get quickNoteCreateAction => 'Създайте нова бележка…';
  @override
  String get quickNoteNewTitle => 'Нова бърза бележка';
  @override
  String get quickNotePickerTitle => 'Избор на бърза бележка';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Нова папка';
  @override
  String get folderPickerEmpty => 'Все още няма папки';
  @override
  String get listFolderTitle => 'Папка за списъци';
  @override
  String get attachmentsFolderTitle => 'Папка за прикачени файлове';

  // Trash (M1).
  @override
  String get trashEmpty => 'Кошът е празен';
  @override
  String get trashEmptyAction => 'Изпразни коша';
  @override
  String get trashEmptyConfirm =>
      'Това окончателно ще изтрие всичко в коша, включително елементи, '
      'които Niman не е поставил там.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name ще бъде окончателно изтрит (без възстановяване)';
  @override
  String get trashDeletePermanently => 'Изтрий окончателно';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Отворете папка с Markdown бележки като библиотека';
  @override
  String get openLibraryExisting => 'Отвори съществуваща';
  @override
  String get openLibraryCreate => 'Създайте нова';
  @override
  String get openLibraryCreateTitle => 'Създайте нова библиотека';
  @override
  String get openLibraryFolderName => 'Име на папка';
  @override
  String get openLibraryChooseFolder => 'Изберете папката на библиотеката';
  @override
  String get openLibraryChooseParent =>
      'Изберете папката, в която ще бъде създадена библиотеката';
  @override
  String get openLibraryUnsupported =>
      'Тази папка не се поддържа. Изберете папка от хранилището на '
      'устройството.';
  @override
  String indexingCount(int done, int total) => '$done / $total бележки';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Библиотеки';
  @override
  String get libraryUnreachable => 'Недостъпна';
  @override
  String get libraryOpenedToday => 'Отворена днес';
  @override
  String get libraryOpenedYesterday => 'Отворена вчера';
  @override
  String libraryOpenedDaysAgo(int days) => 'Отворена преди $days дни';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Отворена ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Отворена в момента';
  @override
  String get switchLibraryTitle => 'Смени библиотеката';
  @override
  String get libraryForget => 'Забрави';
  @override
  String libraryForgetTitle(String name) => 'Забравяне на „$name”?';
  @override
  String get libraryForgetExplained =>
      'Тя ще изчезне от този списък. Папката, бележките и настройките на '
      'библиотеката остават непроменени и повторното отваряне я връща на '
      'място.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Разреши достъп до файлове';
  @override
  String get storageAccessNeeded =>
      'Niman не може да чете бележките ви без „Достъп до всички '
      'файлове”. Разрешете го, за да отворите библиотеката.';
  @override
  String get storageAccessExplained =>
      'Niman чете бележките ви като обикновени файлове, така че Android '
      'трябва да даде достъп до всички файлове. Нищо не се изпраща и се '
      'чете само избраната папка на библиотеката.';
  @override
  String folderAccessDenied(Object error) =>
      'Системата не позволи достъп до папката: $error';
  @override
  String folderPickFailed(Object error) => 'Изборът на папка не успя: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Настройки';
  @override
  String get libraryPathTitle => 'Път на библиотеката';
  @override
  String get reindexTitle => 'Презиндексирай сега';
  @override
  String get reindexDone => 'Презиндексирането е завършено';
  @override
  String get closeLibraryTitle => 'Затвори библиотеката';
  @override
  String get exportLogTitle => 'Експортирай джурнала за отключване';
  @override
  String get exportLogSubtitle =>
      'Запазете регистрираните събития във файл, който изберете';
  @override
  String get exportLogEmpty => 'Буферът на джурнала е празен';
  @override
  String get quickNoteUnset => 'Не е зададен';
  @override
  String exportLogDone(Object target) => 'Джурналът е експортиран в $target';
  @override
  String exportLogFailed(Object error) => 'Експортирането не успя: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '„$term” няма точното съвпадение на цялата дума';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Заместени са $occurrences появления „$term” в $notes бележки';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped отворени бележки са пропускнати)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '„$term” няма точното съвпадение на цялата дума'
      '${only == null ? '' : ' — намерено е само $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'За';
  @override
  String get versionTitle => 'Версия';
  @override
  String get changelogTitle => 'Дневник на промените';
  @override
  String get changelogEmpty => 'Няма налични записи в дневника';
  @override
  String changelogWhatsNew(String version) => 'Ново във версия $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'История';
  @override
  String get noteMenuTooltip => 'Действия с бележката';
  @override
  String get historyCurrentVersion => 'Текуща версия';
  @override
  String get historyCurrentSubtitle => 'Бележката в сегашния ѝ вид';
  @override
  String get historyToday => 'Днес';
  @override
  String get historyYesterday => 'Вчера';
  @override
  String get historyReasonSession => 'преди редакция';
  @override
  String get historyReasonInterval => 'по време на редакция';
  @override
  String get historyReasonRestore => 'преди възстановяване';
  @override
  String get historyReasonSync => 'преди синхронизация';
  @override
  String get historyReasonReplace => 'преди замяна';
  @override
  String get historyReasonUnknown => 'открита';
  @override
  String get historySyncBase => 'база за синхронизация';
  @override
  String get historyEmpty =>
      'Все още няма версии. Niman запазва една, когато започнете да '
      'редактирате бележката, а след това най-много по една на няколко '
      'минути, докато пишете.';
  @override
  String historyKept(int kept, int limit) => 'Запазени версии: $kept от $limit';
  @override
  String get historyBaseKept =>
      'Базата за синхронизация се пази и извън лимита.';
  @override
  String get historyOff =>
      'Историята е изключена за тази библиотека (Настройки, Библиотека).';
  @override
  String get historyLoadFailed => 'Не може да се прочете историята';
  @override
  String get historyCompareSubtitle => 'Сравнена с текущата версия';
  @override
  String get historyTabChanges => 'Промени';
  @override
  String get historyTabVersion => 'Версия';
  @override
  String get historyNoChanges => 'Същият текст като текущата версия.';
  @override
  String get historyRestoreAction => 'Възстанови тази версия';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Да се възстанови ли версията, запазена $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Текущият текст първо се запазва в историята, така че винаги можете '
      'да се върнете.';
  @override
  String get historyRestoreConfirm => 'Възстанови';
  @override
  String historyRestored(String when) =>
      'Възстановена е версията, запазена $when';
  @override
  String get historyRestoreFailed => 'Не може да се възстанови версията';
  @override
  String get actionUndo => 'Отмени';
  @override
  String diffLineRange(int start, int end) => 'Редове $start–$end';
  @override
  String diffLineSingle(int line) => 'Ред $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 непроменен ред' : '$count непроменени реда';
  @override
  String get historyTakeHunk => 'Възстанови тук';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Възстанови 1 промяна' : 'Възстанови $count промени';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Избраните промени се връщат към текста на тази версия. Бележката в '
      'сегашния ѝ вид първо се запазва като версия, така че можеш да отмениш '
      'това.';
  @override
  String get historyNoteChangedReloaded =>
      'Бележката се промени, докато беше тук — сравнението е обновено.';
  @override
  String get historyVersionsTitle => 'Брой пазени версии';
  @override
  String get historyVersionsSubtitle => 'За всяка бележка, в .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Няма' : '$count';
  @override
  String get historyIntervalTitle => 'Нова версия най-много на всеки';
  @override
  String get historyIntervalSubtitle =>
      'Докато пишете; започването на редакция винаги запазва една';
  @override
  String historyIntervalValue(int minutes) => '$minutes мин';
  @override
  String get settingsSectionTranscription => 'Транскрипция';
  @override
  String get transcriptionModelTitle => 'Модел';
  @override
  String get transcriptionModelNone => 'Няма';
  @override
  String get transcriptionLanguageTitle => 'Език';
  @override
  String get transcriptionLanguageSubtitle =>
      'Езикът, който се говори във вашите записи. Да го посочите е по-точно '
      'от автоматичното разпознаване.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Като приложението ($language)';
  @override
  String get transcriptionLanguageDetect => 'Автоматично разпознаване';
  @override
  String get transcriptionModelsTitle => 'Модели за транскрипция';
  @override
  String transcriptionModelsUsed(String size) => 'Заети $size';
  @override
  String get transcriptionModelsInstalled => 'Изтеглени';
  @override
  String get transcriptionModelsDownloading => 'Изтеглят се';
  @override
  String get transcriptionModelsAvailable => 'Налични';
  @override
  String get transcriptionModelsFooter =>
      'Моделите остават в хранилището на приложението на това устройство. Не '
      'се копират в библиотеката и не се синхронизират.';
  @override
  String get transcriptionModelDefault => 'По подразбиране';
  @override
  String get transcriptionModelSlow => 'Бавен';
  @override
  String get transcriptionModelHintTiny => 'Най-бърз, най-малко точен';
  @override
  String get transcriptionModelHintBase =>
      'Добър баланс между скорост и точност';
  @override
  String get transcriptionModelHintSmall => 'По-точен, около 3× по-бавен';
  @override
  String get transcriptionModelHintMedium => 'Много точен, бавен на телефон';
  @override
  String get transcriptionModelHintLarge => 'Най-точен, изисква много памет';
  @override
  String get transcriptionModelDownload => 'Изтегляне';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Да се изтрие ли моделът $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Ще се освободят $size. Можете да изтеглите модела отново по-късно.';
  @override
  String get transcriptionModelFailed =>
      'Изтеглянето не бе успешно. Проверете връзката и опитайте отново.';
  @override
  String get actionRetry => 'Опитай отново';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Връзката прекъсна, нов опит…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'На пауза при $progress';
  @override
  String get actionResume => 'Продължи';
  @override
  String get audioTranscribe => 'Транскрибиране';
  @override
  String get audioTranscribeUnsupported => 'На това устройство само WAV записи';
  @override
  String get transcriptionQueued => 'На опашка';
  @override
  String get transcriptionPreparing => 'Аудиото се подготвя…';
  @override
  String transcriptionRunning(int percent) => 'Транскрибиране… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Изтегляне на $model · $percent%';
  @override
  String get transcriptionSaved => 'Транскрипцията е добавена към описанието';
  @override
  String get transcriptionNoSpeech => 'В този запис не е разпозната реч';
  @override
  String get transcriptionFailed => 'Транскрибирането не бе успешно';
  @override
  String get transcriptionPickModelTitle => 'Изберете модел';
  @override
  String get transcriptionPickModelBody =>
      'Транскрибирането става на това устройство и записът никога не се '
      'изпраща. Моделът се изтегля само веднъж.';
  @override
  String get transcriptionPickModelAction => 'Изтегляне и транскрибиране';
  @override
  String get transcriptionModelRecommended => 'Препоръчан';
  @override
  String get transcriptionExistingTitle => 'Този запис вече има описание';
  @override
  String get transcriptionExistingBody =>
      'Да се замени ли с транскрипцията, или транскрипцията да се добави '
      'отдолу?';
  @override
  String get transcriptionAppend => 'Добави отдолу';
  @override
  String get transcriptionReplace => 'Замени';
  @override
  String get settingsSectionSync => 'Синхронизация';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Не е настроена за тази библиотека';
  @override
  String get syncNeverSynced => 'Никога не е синхронизирана';
  @override
  String syncLastSynced(String when) => 'Синхронизирана $when';
  @override
  String get syncRunning => 'Синхронизиране…';
  @override
  String syncScreenSubtitle(String library) => 'Библиотека $library';
  @override
  String get syncUrlLabel => 'Адрес на папката';
  @override
  String get syncUrlRequired => 'Въведете адреса на сървъра';
  @override
  String get syncUrlHint =>
      'Папката трябва да съществува. Копирайте адреса така, '
      'както го показва сървърът.';
  @override
  String get syncHttpWarning =>
      'Нешифрована връзка: подходяща през VPN или в локалната ви '
      'мрежа.';
  @override
  String get syncUserLabel => 'Потребител';
  @override
  String get syncUserHint =>
      'Оставете празно, ако сървърът не иска данни за вход.';
  @override
  String get syncPasswordLabel => 'Парола';
  @override
  String get syncPasswordHint =>
      'Пази се в ключодържателя на това устройство, никога във '
      'файловете на библиотеката.';
  @override
  String get syncPasswordKeepHint =>
      'Оставете празно, за да запазите записаната парола.';
  @override
  String get syncShowPassword => 'Покажи паролата';
  @override
  String get syncHidePassword => 'Скрий паролата';
  @override
  String get syncTestAction => 'Тествай връзката';
  @override
  String get syncTesting => 'Тестване…';
  @override
  String get syncRetargetWarning =>
      'С нов адрес или потребител следващата синхронизация '
      'започва отначало като първа.';
  @override
  String get syncTestOk => 'Връзката работи';
  @override
  String get syncModeFull => 'Пълен режим';
  @override
  String get syncModeCompatible => 'Съвместим режим';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Четене, запис и изтриване';
  @override
  String get syncCapEtags => 'Отпечатъци на файловете (ETag)';
  @override
  String get syncCapNoEtags => 'Без отпечатъци на файловете (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Сравнява размер и дата; при съмнение изтегля отново';
  @override
  String get syncCapGuarded => 'Защитени записи';
  @override
  String get syncCapUnguarded => 'Незащитени записи';
  @override
  String get syncCapUnguardedDetail =>
      'Проверява файла на сървъра точно преди запис';
  @override
  String get syncCapMove => 'Преименува без повторно качване';
  @override
  String get syncCapNoMove => 'Без преименуване на сървъра';
  @override
  String get syncCapNoMoveDetail =>
      'Преименуването става изтриване и ново качване';
  @override
  String get syncCompatibleNote =>
      'В съвместим режим синхронизацията работи по същия начин, '
      'с малко повече заявки.';
  @override
  String get syncTestInvalidUrl => 'Невалиден адрес';
  @override
  String get syncTestInvalidUrlHint =>
      'Въведете адрес с http:// или https://, без потребител и '
      'парола в него.';
  @override
  String get syncTestOffline => 'Сървърът е недостъпен';
  @override
  String get syncTestOfflineHint =>
      'Включена ли е VPN връзката? Адрес 10.x или 192.168.x '
      'работи само от същата мрежа.';
  @override
  String get syncTestAuth => 'Потребителят или паролата са отхвърлени';
  @override
  String get syncTestAuthHint => 'Проверете ги и тествайте отново.';
  @override
  String get syncTestNotFound => 'Папката не съществува';
  @override
  String get syncTestNotFoundHint =>
      'Създайте я на сървъра или поправете адреса.';
  @override
  String get syncTestUnsupported => 'Не е WebDAV папка';
  @override
  String get syncTestUnsupportedHint => 'Сървърът отговаря, но не като WebDAV.';
  @override
  String get syncTestFailed => 'Тестът не успя';
  @override
  String get syncNowAction => 'Синхронизирай сега';
  @override
  String get syncSectionServer => 'Сървър';
  @override
  String get syncServerRow => 'Адрес, потребител и парола';
  @override
  String get syncRetestTitle => 'Тествай сървъра отново';
  @override
  String syncProbedAgo(String when) => 'Последен тест: $when';
  @override
  String get syncDisconnectTitle => 'Разкачи тази библиотека';
  @override
  String get syncDisconnectSubtitle => 'Файловете остават тук и на сървъра';
  @override
  String get syncDisconnectConfirmTitle => 'Да се разкачи ли синхронизацията?';
  @override
  String get syncDisconnectConfirmBody =>
      'Тази библиотека спира да се синхронизира на това '
      'устройство. Не се изтрива нито един файл, нито тук, нито '
      'на сървъра. Ако я свържете отново, първата синхронизация '
      'започва отначало.';
  @override
  String get syncDisconnectConfirm => 'Разкачи';
  @override
  String get syncFirstTitle => 'Първа синхронизация';
  @override
  String get syncFirstIntro => 'Библиотеката е сравнена с папката на сървъра:';
  @override
  String get syncFirstUpload => 'За качване';
  @override
  String get syncFirstDownload => 'За изтегляне';
  @override
  String get syncFirstBoth => 'И от двете страни';
  @override
  String get syncFirstBothHint =>
      'Еднакви: без прехвърляне. Различни: за разрешаване';
  @override
  String get syncFirstNoDelete =>
      'Първата синхронизация не изтрива нищо, нито тук, нито на '
      'сървъра.';
  @override
  String get syncStartAction => 'Започни';
  @override
  String syncMassTrashTitle(int count) => count == 1
      ? 'Да се премести ли 1 файл в коша?'
      : 'Да се преместят ли $count файла в коша?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Липсващи на сървъра: $count от $total синхронизирани '
      'файла. Обикновено това означава грешен адрес, немонтиран '
      'диск на NAS или папка, изпразнена по грешка.';
  @override
  String get syncMassTrashHint =>
      'Ако наистина сте ги изтрили на друго устройство, '
      'потвърдете: тук те отиват в коша.';
  @override
  String get syncMassTrashConfirm => 'Премести в коша';
  @override
  String syncMassDeleteTitle(int count) => count == 1
      ? 'Да се изтрие ли 1 файл от сървъра?'
      : 'Да се изтрият ли $count файла от сървъра?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Липсващи тук: $count от $total синхронизирани файла. Ако '
      'не сте ги изтрили вие, откажете и проверете папката на '
      'библиотеката.';
  @override
  String get syncMassDeleteConfirm => 'Изтрий от сървъра';
  @override
  String get syncTooltip => 'Синхронизирай';
  @override
  String get syncStageConnecting => 'Свързване със сървъра…';
  @override
  String get syncStageComparing => 'Сравняване със сървъра…';
  @override
  String syncStageApplying(int done, int total) =>
      'Синхронизиране · $done от $total';
  @override
  String get syncStatusWarnings => 'Синхронизирана с предупреждения';
  @override
  String syncConflictsHeader(int count) =>
      'Променени тук и на сървъра · $count';
  @override
  String get syncConflictHint => 'Нито една от двете версии не е пипана';
  @override
  String get syncResolveAction => 'Разреши';
  @override
  String syncFailuresHeader(int count) => 'Несинхронизирани · $count';
  @override
  String get syncFailuresHint => 'Нов опит при следващата синхронизация';
  @override
  String get syncAbortAuth => 'Сървърът отхвърли паролата';
  @override
  String get syncAbortMissingPassword => 'Няма записана парола';
  @override
  String get syncAbortOffline => 'Сървърът е недостъпен';
  @override
  String get syncAbortRemoteMissing => 'Папката на сървъра вече я няма';
  @override
  String get syncAbortUnsupported => 'Сървърът вече не работи като WebDAV';
  @override
  String get syncAbortFailed => 'Синхронизацията не успя';
  @override
  String get syncAbortNotConfirmed => 'Синхронизацията е отказана';
  @override
  String get syncAbortNothingTouched =>
      'Нито един файл не е пипан. Промените ви остават тук до '
      'следващата успешна синхронизация.';
  @override
  String syncLastSuccess(String when) =>
      'Последна успешна синхронизация: $when';
  @override
  String get syncNoSuccessYet => 'Все още няма успешна синхронизация';
  @override
  String get syncUpdatePasswordAction => 'Обнови паролата';
  @override
  String get syncRetryAction => 'Опитай отново';
  @override
  String get syncOpenSettingsAction => 'Настройки';
  @override
  String get syncCloseAction => 'Затвори';
  @override
  String get syncDoneSnack => 'Синхронизирана';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Синхронизирана · 1 файл, изтрит другаде, е в коша'
      : 'Синхронизирана · $count файла, изтрити другаде, са в коша';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Синхронизирана · 1 конфликт за разрешаване'
      : 'Синхронизирана · $count конфликта за разрешаване';
  @override
  String get syncShowAction => 'Покажи';
  @override
  String get syncConflictTitle => 'Разреши конфликта';
  @override
  String get syncConflictLegend =>
      'Редовете с − са от сървъра, редовете с + са от това '
      'устройство.';
  @override
  String get syncConflictBinary =>
      'Не е текстов файл: изберете кое копие да запазите.';
  @override
  String get syncConflictKeepNote =>
      'Копието, което не запазите, остава в историята на '
      'бележката.';
  @override
  String get syncKeepLocal => 'Запази версията от това устройство';
  @override
  String get syncKeepRemote => 'Запази версията от сървъра';
  @override
  String get syncConflictIdentical => 'Двете версии са еднакви';
  @override
  String get syncConflictLoadFailed => 'Двете версии не могат да се прочетат';
  @override
  String get syncResolveFailed => 'Конфликтът не може да се разреши';
  @override
  String get syncResolved => 'Конфликтът е разрешен';
  @override
  String get syncSectionWhen => 'Кога да се синхронизира';
  @override
  String get syncAutoTitle => 'Автоматично';
  @override
  String get syncAutoSubtitle => 'След промени, при отваряне и на интервали';
  @override
  String get syncIntervalTitle => 'Проверявай сървъра на всеки';
  @override
  String get syncIntervalSubtitle => 'Само докато програмата е отворена';
  @override
  String get syncIntervalDialogBody =>
      'За да виждате промените, направени на други устройства, докато '
      'програмата е отворена. С „Никога“ — само след промени и при отваряне.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 минута' : '$count минути';
  @override
  String get syncIntervalNever => 'Никога';
  @override
  String get syncWifiOnlyTitle => 'Само през Wi-Fi';
  @override
  String get syncWifiOnlySubtitle => 'С мобилни данни синхронизирай само ръчно';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 промяна чака' : '$count промени чакат';
  @override
  String syncRetryIn(String wait) => 'нов опит след $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds с';
  @override
  String syncWaitMinutes(int minutes) => '$minutes мин';
  @override
  String get syncWaitingForWifi => 'Изчакване на Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Изчакване на връзка';
  @override
  String get syncMobileDataHint =>
      '„Синхронизирай сега“ пак използва мобилни данни.';
  @override
  String get syncQueueKeptHint =>
      'Промените остават тук, дори ако затворите програмата, и тръгват сами, '
      'когато сървърът отговори.';
  @override
  String get syncAutoPaused => 'Автоматичното синхронизиране е на пауза';
  @override
  String get syncPausedAuthHint =>
      'Възобновява се, когато обновите паролата или синхронизирате ръчно.';
  @override
  String get syncPausedServerHint =>
      'Възобновява се, когато поправите адреса или синхронизирате ръчно.';
  @override
  String get syncPausedConfirmHint =>
      '„Синхронизирай сега“ показва какво ще бъде премахнато и първо пита.';
  @override
  String get syncNeedsConfirmation => 'Изчаква вашето потвърждение';
  @override
  String get syncMergeIntro =>
      'Промените, които не се припокриват, вече са слети; там, където се '
      'припокриват, изберете какво да запазите.';
  @override
  String get syncMergeClean =>
      'Двете версии се сливат сами: нищо не се припокрива.';
  @override
  String get syncMergeNoBase =>
      'Няма обща версия, върху която да се слее, затова се избира целият файл.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Припокриване $index от $total';
  @override
  String get syncMergeFromLocal => 'От това устройство';
  @override
  String get syncMergeFromRemote => 'От сървъра';
  @override
  String get syncMergeRemovedLines => 'Премахнати редове';
  @override
  String get syncMergeKeepLocal => 'Моите';
  @override
  String get syncMergeKeepRemote => 'На сървъра';
  @override
  String get syncMergeKeepBoth => 'И двете';
  @override
  String get syncMergeSave => 'Запази сливането';
  @override
  String get syncMergeKeepWhole => 'Или запазете едно цяло копие';
}
