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
  String get trashTitle => 'Косът';
  @override
  String get trashSubtitle =>
      'Изтритите елементи се преместват в .trash/ (изключено = окончателно '
      'изтриване)';
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
  @override
  String get settingsSectionUpdates => 'Updates';
  @override
  String get autoUpdateTitle => 'Automatic updates';
  @override
  String get autoUpdateSubtitle =>
      'Check GitHub Releases at launch and every 6 hours';
  @override
  String get checkForUpdatesTitle => 'Check for updates';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version is available';
  @override
  String get updateUpToDate => 'Niman is up to date';
  @override
  String get updateCheckFailed => 'Update check failed';
  @override
  String updateSavedTo(Object path) => 'Update saved to $path';
  @override
  String get updateInstallerStarted => 'Installer started';
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

  // Audio note kind (issue #56): English fallback until translated.
  @override
  String get audioEmpty => 'No recordings yet';
  @override
  String get audioRecord => 'Record';
  @override
  String get audioStop => 'Stop';
  @override
  String get audioPlay => 'Play';
  @override
  String get audioStopPlayback => 'Stop playback';
  @override
  String get audioDelete => 'Delete recording';
  @override
  String get audioImport => 'Import an audio file';
  @override
  String get audioRecording => 'Recording…';
  @override
  String get audioPlaying => 'Playing';
  @override
  String get audioPermissionDenied =>
      'Microphone permission denied — recording needs it.';
  @override
  String get newAudioNoteTitle => 'New voice note';
  @override
  String get newAudioNoteDefault => 'My recording';
  @override
  String get showAudioTooltip => 'Show recordings';
  @override
  String get audioMessageHint => 'Write a note…';
  @override
  String get audioSend => 'Send';
  @override
  String get audioRename => 'Rename recording';
  @override
  String get audioDescriptionHint => 'Describe this recording…';
  @override
  String get audioEditDescription => 'Edit description';
  @override
  String get audioDeleteNote => 'Delete note';
  @override
  String get audioEditNote => 'Edit note';

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
  String get shortcutNewAudio => 'New voice note';
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
  String get replaceCancel => 'Заключи';
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
  String get editorFindCloseTooltip => 'Заключи търсенето';
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
  String get saveAndClose => 'Запази и заключи';
  @override
  String get closeUnsavedTitle => 'Незапазени промени';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” има незапазени промени. '
          'Да се запази ли преди заключване?';
    }
    return '${names.length} бележки имат незапазени промени. '
        'Да се запази ли преди заключване?';
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
  String get windowCloseTooltip => 'Заключи';
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
  String get newFolderTitle => 'Нова папка';
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
  @override
  String get movedToTrash => 'Преместен в коса';
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
  String get attachmentsFolderTitle => 'Attachments folder';

  // Trash (M1).
  @override
  String get trashEmpty => 'Косът е празен';
  @override
  String get trashEmptyAction => 'Изпразни коса';
  @override
  String get trashEmptyConfirm =>
      'Това окончателно ще изтрие всичко в коса, включително елементи, '
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
  String get closeLibraryTitle => 'Заключи библиотеката';
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

  // Note history (issues #13, #55, #67): English until translated.
  @override
  String get noteHistoryTitle => 'History';
  @override
  String get noteMenuTooltip => 'Note actions';
  @override
  String get historyCurrentVersion => 'Current version';
  @override
  String get historyCurrentSubtitle => 'The note as it is now';
  @override
  String get historyToday => 'Today';
  @override
  String get historyYesterday => 'Yesterday';
  @override
  String get historyReasonSession => 'before editing';
  @override
  String get historyReasonInterval => 'while editing';
  @override
  String get historyReasonRestore => 'before restore';
  @override
  String get historyReasonSync => 'before sync';
  @override
  String get historyReasonReplace => 'before replace';
  @override
  String get historyReasonUnknown => 'recovered';
  @override
  String get historySyncBase => 'sync base';
  @override
  String get historyEmpty =>
      'No versions yet. Niman keeps one when you start editing the note, '
      'then at most one every few minutes while you write.';
  @override
  String historyKept(int kept, int limit) => '$kept of $limit versions kept';
  @override
  String get historyBaseKept => 'The sync base is kept beyond the limit.';
  @override
  String get historyOff =>
      'History is off for this library (Settings, Library).';
  @override
  String get historyLoadFailed => 'Could not read the history';
  @override
  String get historyCompareSubtitle => 'Compared with the current version';
  @override
  String get historyTabChanges => 'Changes';
  @override
  String get historyTabVersion => 'Version';
  @override
  String get historyNoChanges => 'Same text as the current version.';
  @override
  String get historyRestoreAction => 'Restore this version';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Restore the version of $when?';
  @override
  String get historyRestoreConfirmBody =>
      'The current text is kept in the history first, so you can always '
      'go back.';
  @override
  String get historyRestoreConfirm => 'Restore';
  @override
  String historyRestored(String when) => 'Restored the version of $when';
  @override
  String get historyRestoreFailed => 'Could not restore the version';
  @override
  String get actionUndo => 'Undo';
  @override
  String diffLineRange(int start, int end) => 'Lines $start–$end';
  @override
  String diffLineSingle(int line) => 'Line $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 unchanged line' : '$count unchanged lines';
  @override
  String get historyVersionsTitle => 'Versions to keep';
  @override
  String get historyVersionsSubtitle => 'Per note, in .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'None' : '$count';
  @override
  String get historyIntervalTitle => 'New version at most every';
  @override
  String get historyIntervalSubtitle =>
      'While you write; starting to edit a note always keeps one';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
}
