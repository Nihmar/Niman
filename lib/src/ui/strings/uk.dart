// The Ukrainian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class UkrainianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'січень',
    'лютий',
    'березень',
    'квітень',
    'травень',
    'червень',
    'липень',
    'серпень',
    'вересень',
    'жовтень',
    'листопад',
    'грудень',
  ];
  @override
  List<String> get monthNamesShort => const [
    'січ',
    'лют',
    'бер',
    'квіт',
    'трав',
    'чер',
    'лип',
    'серп',
    'вер',
    'жовт',
    'лист',
    'груд',
  ];
  @override
  List<String> get weekdayNames => const [
    'понеділок',
    'вівторок',
    'середа',
    'четвер',
    'п’ятниця',
    'субота',
    'неділя',
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
  String get trashTitle => 'Кошик';
  @override
  String get trashSubtitle =>
      'Вилучені елементи переміщуються в .trash/ (вимкнено = остаточно '
      'видалення)';
  @override
  String get debugLogsTitle => 'Журнали налагодження';
  @override
  String get debugLogsSubtitle => 'Фіксує події програми в буфері пам’яті';
  @override
  String get lineNumbersTitle => 'Номери рядків';
  @override
  String get lineNumbersSubtitle =>
      'Показує стовпчик номерів рядків у редакторі';
  @override
  String get keyboardOnOpenTitle => 'Клавіатура при відкритті';
  @override
  String get keyboardOnOpenSubtitle =>
      'Показує клавіатуру при відкритті нотатки (вимкнено = при першому '
      'дотику)';
  @override
  String get editorKindSource => 'Markdown-джерело';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Перегляд';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Показує оформлену нотатку поруч із редактором джерела';
  @override
  String get switchToWysiwygTooltip => 'Перемкнути на WYSIWYG-редактор';
  @override
  String get switchToSourceTooltip => 'Перемкнути на Markdown-джерело';
  @override
  String get wysiwygTooLarge =>
      'Ця нотатка занадто велика для WYSIWYG-редактора. Відкрийте її як '
      'Markdown-джерело.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Зовнішній вигляд';
  @override
  String get settingsSectionEditor => 'Редактор';
  @override
  String get settingsSectionLibrary => 'Бібліотека';
  @override
  String get settingsSectionReminders => 'Нагадування';
  @override
  String get settingsSectionShortcuts => 'Клавіатура';
  @override
  String get keyboardShortcutsTitle => 'Комбінації клавіш';
  @override
  String get settingsSectionUpdates => 'Оновлення';
  @override
  String get autoUpdateTitle => 'Автоматичні оновлення';
  @override
  String get autoUpdateSubtitle =>
      'Перевіряти GitHub Releases під час запуску та кожні 6 годин';
  @override
  String get checkForUpdatesTitle => 'Перевірити оновлення';
  @override
  String updateAvailableMessage(Object version) =>
      'Доступна версія Niman $version';
  @override
  String get updateUpToDate => 'У вас остання версія Niman';
  @override
  String get updateCheckFailed => 'Не вдалося перевірити оновлення';
  @override
  String updateSavedTo(Object path) => 'Оновлення збережено в $path';
  @override
  String get updateInstallerStarted => 'Інсталятор запущено';
  @override
  String get settingsSectionDiagnostics => 'Діагностика';
  @override
  String get settingsSpellCheckTitle => 'Перевірка орфографії';
  @override
  String get settingsSpellCheckSubtitle =>
      'Підсвічує орфографічні помилки під час введення.';
  @override
  String get spellCheckDictionaryTitle => 'Словник';
  @override
  String get spellCheckDictionarySystem => 'Системний за замовчуванням';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Вибір словників';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Оберіть усі мови, якими написана бібліотека. Слово проходить, якщо '
      'його впізнає хоча б один обраний словник; без вибору — мова системи.';
  @override
  String get spellCheckNoDictionaries => 'Словники не знайдено в цій системі.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Перевірка орфографії';
  @override
  String get spellCheckTitle => 'Орфографія';
  @override
  String get spellCheckEmpty => 'Орфографічних помилок немає.';
  @override
  String get spellCheckUnavailable => 'hunspell не встановлено в цій системі.';
  @override
  String get spellCheckNoSuggestions => 'Немає пропозицій';
  @override
  String spellCheckCount(int count) => '$count для перегляду';
  @override
  String spellCheckLine(int line) => 'рядок $line';
  @override
  String get addWordToDictionary => 'Додати до словника';

  @override
  String indentWidthValue(int spaces) => '$spaces проміжки';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Світлість';
  @override
  String get themeBrightnessSubtitle =>
      'Світла, темна або налаштування пристрою';
  @override
  String get themeBrightnessSystem => 'Система';
  @override
  String get themeBrightnessDay => 'Світла';
  @override
  String get themeBrightnessNight => 'Темна';
  @override
  String get themePaletteTitle => 'Палітра кольорів';
  @override
  String get themePaletteSubtitle => 'Кольори інтерфейсу та нотаток';
  @override
  String get themePaletteSystem => 'Система';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Розмір тексту інтерфейсу';
  @override
  String get uiTextScaleSubtitle =>
      'Дерево, вкладки та діалоги; над налаштуванням системи';
  @override
  String get noteTextScaleTitle => 'Розмір тексту нотаток';
  @override
  String get noteTextScaleSubtitle =>
      'Редактор і перегляд завжди синхронізовані';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Режим перегляду';
  @override
  String get previewModeSubtitle =>
      'Чи перегляд ділить екран з редактором, чи заміняє його';
  @override
  String get previewModeAuto => 'Поруч';
  @override
  String get previewModeSwitch => 'Весь екран';
  @override
  String get splitRatioTitle => 'Співвідношення розділу';
  @override
  String get splitRatioSubtitle => 'Частка редактора, коли перегляд поруч';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Формат посилання';
  @override
  String get linkTypeSubtitle => 'Що кнопка посилання вставляє в редактор';
  @override
  String get linkTypeWikilink => 'Вікіпосилання';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Ширина відступу';
  @override
  String get indentWidthSubtitle =>
      'Кількість проміжків, що додається на кожен рівень відступу в '
      'редакторі';
  @override
  String get languageTitle => 'Мова';
  @override
  String get languageSubtitle => 'Мова самої програми';
  @override
  String get languageSystem => 'Система';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Додати елемент';
  @override
  String get listAddTooltip => 'Додати елемент';
  @override
  String get listEmpty => 'Елементів ще немає';
  @override
  String get listDragHandleLabel => 'Змінити порядок елементів';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Записів ще немає';
  @override
  String get audioRecord => 'Записати';
  @override
  String get audioStop => 'Зупинити';
  @override
  String get audioPlay => 'Відтворити';
  @override
  String get audioDelete => 'Видалити запис';
  @override
  String get audioImport => 'Імпортувати аудіофайл';
  @override
  String get audioRecording => 'Триває запис…';
  @override
  String get audioPermissionDenied =>
      'Немає дозволу на мікрофон — він потрібен для запису.';
  @override
  String get newAudioNoteTitle => 'Нова голосова нотатка';
  @override
  String get newAudioNoteDefault => 'Мій запис';
  @override
  String get showAudioTooltip => 'Показати записи';
  @override
  String get audioMessageHint => 'Напишіть нотатку…';
  @override
  String get audioSend => 'Надіслати';
  @override
  String get audioRename => 'Перейменувати запис';
  @override
  String get audioDescriptionHint => 'Опишіть цей запис…';
  @override
  String get audioEditDescription => 'Редагувати опис';
  @override
  String get audioDeleteNote => 'Видалити нотатку';
  @override
  String get audioEditNote => 'Редагувати нотатку';
  @override
  String get audioPause => 'Пауза';
  @override
  String get audioEditTitle => 'Редагувати назву';
  @override
  String get audioTitleHint => 'Назва цього запису…';
  @override
  String audioUntitled(int n) => 'Запис $n';
  @override
  String get audioMoreActions => 'Більше дій';
  @override
  String get audioDiscardRecording => 'Відкинути запис';
  @override
  String get audioPauseRecording => 'Призупинити запис';
  @override
  String get audioResumeRecording => 'Продовжити запис';
  @override
  String get audioRecordingPaused => 'Призупинено';
  @override
  String get audioSavingRecording => 'Збереження…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Швидка нотатка';
  @override
  String get shortcutNewTodo => 'Нове завдання';
  @override
  String get shortcutNewNote => 'Нова нотатка';
  @override
  String get shortcutNewList => 'Новий список';
  @override
  String get shortcutNewAudio => 'Нова голосова нотатка';
  @override
  String get shortcutToggleSidebar => 'Показати або приховати фільтр';
  @override
  String get shortcutEditorSection => 'У редакторі';
  @override
  String get shortcutFind => 'Шукати';
  @override
  String get shortcutReplace => 'Знайти і замінити';
  @override
  String get shortcutSavingNote =>
      'Зміни зберігаються автоматично, тому комбінації для збереження '
      'немає.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Структура';
  @override
  String get outlineNoHeadings => 'Заголовків немає';
  @override
  String get outlineNoTitle => '(без заголовка)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Жирний';
  @override
  String get toolbarItalic => 'Курсив';
  @override
  String get toolbarStrikethrough => 'Закреслений';
  @override
  String get toolbarSuperscript => 'Верхній індекс';
  @override
  String get toolbarUnderline => 'Підкреслений';
  @override
  String get toolbarLink => 'Посилання';
  @override
  String get toolbarCode => 'Кодовий блок';
  @override
  String get toolbarImage => 'Вставити зображення';
  @override
  String get toolbarHeading => 'Заголовок';
  @override
  String get toolbarList => 'Список';
  @override
  String get toolbarOrderedList => 'Нумерований список';
  @override
  String get toolbarQuote => 'Цитата';
  @override
  String get toolbarIndent => 'Відступ';
  @override
  String get toolbarOutdent => 'Прибрати відступ';
  @override
  String get headingDialogTitle => 'Рівень заголовка';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Панель інструментів редактора';
  @override
  String get toolbarSettingsHint =>
      'Перетягуйте, щоб змінити порядок; око показує чи приховує кнопку.';
  @override
  String get toolbarShowButton => 'Показати';
  @override
  String get toolbarHideButton => 'Приховати';
  @override
  String get toolbarResetOrder => 'Відновити за замовчуванням';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Показати перегляд';
  @override
  String get showEditorTooltip => 'Показати редактор';
  @override
  String get enterFullScreenTooltip => 'Весь екран';
  @override
  String get exitFullScreenTooltip => 'Вийти з режиму всього екрана';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(необроблена HTML-таблиця)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Шукати в нотатках';
  @override
  String get searchModeWords => 'Слова';
  @override
  String get searchModeContains => 'Містить';
  @override
  String get searchEmptyHint =>
      'Напишіть, щоб шукати в бібліотеці, або ключ = значення, щоб '
      'фільтрувати за метаданими';
  @override
  String get searchTooShortHint => 'Введіть щонайменше 2 символи';
  @override
  String get searchNoMatches => 'Немає результатів';
  @override
  String get searchLoadMore => 'Показати ще';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Замінити…';
  @override
  String get replaceInNoteAction => 'Замінити в цій нотатці…';
  @override
  String get replaceInThisNote => 'Замінити в цій нотатці';
  @override
  String get replaceWithLabel => 'Замінити на';
  @override
  String get replaceCaseSensitive => 'Відмінювати великі та малі літери';
  @override
  String get replaceWholeWordsHint =>
      'замінюються лише точні збіги цілого слова';
  @override
  String get replaceConfirm => 'Замінити';
  @override
  String get replaceCancel => 'Закрити';
  @override
  String get replaceUnavailable => 'Заміна зараз недоступна';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Шукати в нотатці';
  @override
  String get editorFindHint => 'Шукати';
  @override
  String get editorReplaceHint => 'Замінити';
  @override
  String get editorFindCaseTooltip => 'Відмінювати великі та малі літери';
  @override
  String get editorFindPreviousTooltip => 'Попередній результат';
  @override
  String get editorFindNextTooltip => 'Наступний результат';
  @override
  String get editorFindCloseTooltip => 'Закрити пошук';
  @override
  String get editorFindReplaceModeTooltip => 'Режим заміни';
  @override
  String get editorReplaceOneTooltip => 'Замінити цей результат';
  @override
  String get editorReplaceAllTooltip => 'Замінити всі результати';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Мітки';
  @override
  String get tagsTitle => 'Мітки';
  @override
  String get tagsEmpty =>
      'Міток ще немає — додайте #мітку в нотатку чи мітки в метаданих';
  @override
  String get tagsBackTooltip => 'Назад до пошуку';
  @override
  String get tagsNotesEmpty => 'Немає нотаток з цією міткою';
  @override
  String tagsNotesCapped(int limit) =>
      'Показано лише перші $limit — пошукайте за міткою, щоб звузити';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Посилання не знайдено';
  @override
  String get headingNotFoundTitle => 'Заголовок не знайдено';
  @override
  String get ambiguousLinkTitle => 'Кілька нотаток відповідають';
  @override
  String get openLinkFailed => 'Не вдалося відкрити посилання';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Відкриті';
  @override
  String get todoDone => 'Виконані';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Усі дати';
  @override
  String get todoFilter => 'Фільтрувати';
  @override
  String get todoNoTokens => 'У цьому списку немає токенів';
  @override
  String get todoCountOpen => 'відкриті';
  @override
  String get todoCountDone => 'виконані';
  @override
  String get todoEmptyOpen => 'Відкритих завдань ще немає';
  @override
  String get todoEmptyDone => 'Виконаних ще немає';
  @override
  String get todoEmptyFiltered => 'Немає відповідних завдань';
  @override
  String get todoTitle => 'Завдання';
  @override
  String get todoAddTooltip => 'Додати завдання';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Формат todo.txt';
  @override
  String get todoHelpTooltip => 'Інформація про формат';
  @override
  String get todoHelpIntro =>
      'Ваші завдання — звичайний текстовий файл, одне завдання на рядок. '
      'Niman пише синтаксис за вас, але файл можна редагувати в будь-якому '
      'редакторі, і Niman знову його прочитає.';
  @override
  String get todoHelpFilesTitle => 'Два файли';
  @override
  String get todoHelpFilesBody =>
      'Відкриті завдання живуть у todo.txt в корені бібліотеки. Після '
      'виконання рядок переміщується в done.txt, щоб todo.txt залишався '
      'коротким. Виконаний рядок, що знову з’явився в todo.txt, Niman '
      'архівує при наступному читанні файлу.';
  @override
  String get todoHelpLineTitle => 'Анатомія рядка';
  @override
  String get todoHelpLineBody =>
      'Усе до опису — це вибір, і він має бути в такому порядку:';
  @override
  String get todoHelpDoneBody =>
      'Позначає завдання як виконане. Niman додає її, коли ви позначаєте '
      'галочку.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Пріоритет. A — найвищий. Показується як емблема у списку.';
  @override
  String get todoHelpDatesBody =>
      'Строк, а потім дата створення. Якщо одна дата, то це дата створення, '
      'якщо рядок не починається з x.';
  @override
  String get todoHelpTokensTitle => 'Проєкти, контексти та мітки';
  @override
  String get todoHelpTokensBody =>
      'Будь-яке слово в описі з одним із цих префіксів стає фільтрованим '
      'міткою. Нічого не визначено заздалегідь: токен існує, поки його не '
      'напишете.';
  @override
  String get todoHelpProjectBody =>
      'Якому проєкту належить завдання, наприклад +кухня або +робота.';
  @override
  String get todoHelpContextBody =>
      'Де або як його зробити, наприклад @додому або @зустріч.';
  @override
  String get todoHelpHashtagBody =>
      'Вільна мітка для того, що не покривають дві інші.';
  @override
  String get todoHelpTagsTitle => 'Дати та нагадування';
  @override
  String get todoHelpTagsBody =>
      'Це мітки ключ:значення. Niman пише їх із діалогу завдання і читає їх '
      'всюди, де вони з’являються в рядку.';
  @override
  String get todoHelpDueBody =>
      'Строк. Керує кольором емблеми та фільтрами дат.';
  @override
  String get todoHelpRemBody =>
      'Коли надсилити повідомлення у вашому часовому поясі. Працює, коли '
      'екран вимкнено, а програма відкрита.';
  @override
  String get todoHelpRemDesktop =>
      'На комп’ютері Niman має працювати, коли настане час: нагадування '
      'показується, поки програма відкрита, і нічого не відбувається, коли '
      'вона закрита.';
  @override
  String get todoHelpOtherBody =>
      'Вона зберігається саме так, як записана, щоб мітки інших програм '
      'todo.txt пережили перехід. Niman їх не використовує, rec: included: '
      'повторюване завдання поки що не повторюється.';
  @override
  String get todoHelpEditTitle => 'Редагування поза Niman';
  @override
  String get todoHelpEditBody =>
      'Рядки, які ви не торкаєтесь, зберігаються байт за байтом. Niman '
      'переписує лише цей рядок у канонічному порядку, а решта файлу '
      'залишається недоторканою.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Додати завдання';
  @override
  String get todoEditTitle => 'Редагувати завдання';
  @override
  String get todoDescriptionHint => 'Опис';
  @override
  String get todoCancel => 'Скасувати';
  @override
  String get todoSave => 'Зберегти';
  @override
  String get todoEditAction => 'Редагувати';
  @override
  String get todoDeleteAction => 'Видалити';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Строк минув';
  @override
  String get todoDueToday => 'Сьогодні';
  @override
  String get todoDueNext7 => 'Наступні 7 днів';
  @override
  String get todoDueNoDate => 'Без дати';
  @override
  String get todoRowDue => 'Строк';
  @override
  String get todoRowDueToday => 'Строк сьогодні';
  @override
  String get todoSortTooltip => 'Сортувати';
  @override
  String get todoSortDue => 'Дата строку';
  @override
  String get todoSortPriority => 'Пріоритет';
  @override
  String get todoSortCreation => 'Дата створення';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Без пріоритету';
  @override
  String get todoNoPriorityShort => 'Немає';
  @override
  String get todoMorePriorities => 'Більше…';
  @override
  String get todoPriorityTitle => 'Пріоритет';
  @override
  String get todoNoDueDate => 'Без строку';
  @override
  String get todoNoReminder => 'Без нагадування';
  @override
  String get todoAddProject => '+ Проєкт';
  @override
  String get todoAddContext => '@ Контекст';
  @override
  String get todoAddHashtag => '# Мітка';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Нагадування завдань';
  @override
  String get todoReminderChannelDescription =>
      'Заплановані повідомлення для завдань із часом нагадування.';
  @override
  String get todoReminderBody => 'Нагадування завдання';
  @override
  String get todoReminderFallbackTitle => 'Нагадування завдання';
  @override
  String get todoReminderBlocked =>
      'Повідомлення вимкнено, тому нагадування не показуватимуться.';
  @override
  String get todoReminderBattery =>
      'Для Niman увімкнено оптимізацію акумулятора. Система може зупинити '
      'програму і втратити очікувані нагадування.';
  @override
  String get todoReminderInexact =>
      'Цей пристрій не підтримує точні будильники, тому нагадування може '
      'прийти на кілька хвилин пізніше, якщо екран вимкнено.';
  @override
  String get reminderShowTokensTitle => 'Мітки в повідомленнях нагадувань';
  @override
  String get reminderShowTokensSubtitle =>
      'Залиште +проєкт, @контекст і #мітку в тексті повідомлення. '
      'Вимкнене показує лише завдання, яке ви написали.';
  @override
  String get todoReminderFixAction => 'Відкрити налаштування';
  @override
  String get todoReminderDismissAction => 'Закрити';
  @override
  String get todoReminderDue => 'Строк';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Гаразд';
  @override
  String get actionCancel => 'Скасувати';
  @override
  String get actionCreate => 'Створити';
  @override
  String get actionNew => 'Новий';
  @override
  String get actionSave => 'Зберегти';
  @override
  String get actionClear => 'Очистити';
  @override
  String get actionChoose => 'Обрати';
  @override
  String get actionDelete => 'Видалити';
  @override
  String get actionRename => 'Перейменувати';
  @override
  String get actionMove => 'Перемістити';
  @override
  String get saveAndClose => 'Зберегти і закрити';
  @override
  String get closeUnsavedTitle => 'Незбережені зміни';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '«${names.first}» має незбережені зміни. '
          'Зберегти перед закриттям?';
    }
    return 'У ${names.length} нотатках є незбережені зміни. '
        'Зберегти перед закриттям?';
  }

  @override
  String get closeSaveFailed =>
      'Збереження не вдалося; нотатка лишається відкритою.';
  @override
  String get actionRestore => 'Відновити';
  @override
  String get actionEmpty => 'Очистити';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Приховати бічну панель (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Показати бічну панель (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Зменшити';
  @override
  String get windowMaximizeTooltip => 'Збільшити';
  @override
  String get windowRestoreTooltip => 'Відновити';
  @override
  String get windowCloseTooltip => 'Закрити';
  @override
  String get tabFiles => 'Файли';
  @override
  String get tabSearch => 'Пошук';
  @override
  String get tabSettings => 'Налаштування';
  @override
  String get quickNoteTitle => 'Швидка нотатка';
  @override
  String get treeEmpty => 'Нотаток ще немає';
  @override
  String get selectANote => 'Оберіть нотатку';
  @override
  String get showListTooltip => 'Показати список';
  @override
  String get editRawTooltip => 'Редагувати сирий';
  @override
  String get sortAscTooltip => 'Сортувати А–Я';
  @override
  String get sortDescTooltip => 'Сортувати Я–А';
  @override
  String get newNoteTitle => 'Нова нотатка';
  @override
  String get newFolderTitle => 'Нова папка';
  @override
  String get newNoteHere => 'Нова нотатка тут';
  @override
  String get newFolderHere => 'Нова папка тут';
  @override
  String get newListNoteTitle => 'Нова нотатка зі списком';
  @override
  String get newListNoteDefault => 'Мій список';
  @override
  String get setAsQuickNote => 'Задати як швидку нотатку';
  @override
  String get currentQuickNote => 'Поточна швидка нотатка';
  @override
  String get pinnedSection => 'Закріплені';
  @override
  String pinnedSectionCount(int count) => 'Закріплені · $count';
  @override
  String get templateFolderTitle => 'Папка шаблонів';
  @override
  String get newFromTemplateTitle => 'Новий зі шаблону';
  @override
  String get newFromTemplateHere => 'Новий зі шаблону тут';
  @override
  String get templateFormTitle => 'Заповнити шаблон';
  @override
  String get templateFormBacklink => 'Зворотне посилання';
  @override
  String get templateFormNoNote => 'Без нотатки';
  @override
  String get templateFormPickNote => 'Обрати нотатку';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Плейсхолдери шаблону';
  @override
  String get templateHelpIntro =>
      'Шаблон — звичайна нотатка з отворами. При створенні нотатки з нього '
      'текст копіюється, а отвори заповнюються.';
  @override
  String get templateHelpUnknown =>
      'Плейсхолдер, якого Niman не знає, лишається так, як записаний, щоб '
      'помилка з клавіатури була бачною в нотатці, а не тихо видалення '
      'рядка.';
  @override
  String get templateHelpValuesTitle => 'Значення';
  @override
  String get templateHelpTitleBody => 'Ім’я, яким має бути створена нотатка.';
  @override
  String get templateHelpDateBody =>
      'Сьогодні й поточний час. Обидва приймають формат: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Дата й час разом.';
  @override
  String get templateHelpUuidBody =>
      'Новий унікальний ідентифікатор, різний при кожному використанні.';
  @override
  String get templateHelpCounterBody =>
      'Лічильник, що лічить за назвою, зберігається між запусками: перша '
      'нотатка пише 1, наступна — 2. Та сама назва в нотатці пише той самий '
      'лічильник; поєднайте з |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Поставте курсор сюди при створенні нотатки; символ не записується. '
      'Перший символ перемагає, без фільтрів, лише в нових нотатках — і '
      'клавіатура відкривається навіть якщо autofocus вимкнено.';
  @override
  String get templateHelpDatesTitle => 'Записування дати';
  @override
  String get templateHelpDatesBody =>
      'Ці позначають частини дати у форматі. Усе інше — буквально, включно '
      'з текстом у звичайних лапках. Назви місяців і днів тижня '
      'використовують мову програми.';
  @override
  String get templateHelpYear => 'рік: 2026, 26';
  @override
  String get templateHelpMonth => 'місяць: 03, 3, березень, бер';
  @override
  String get templateHelpDay => 'день: 09, 9, понеділок, пн';
  @override
  String get templateHelpTime => 'години, хвилини, секунди';
  @override
  String get templateHelpWeek => 'ISO-тиждень і квартал: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Фільтри';
  @override
  String get templateHelpFiltersBody =>
      'Після значення можуть йти фільтри, що застосовуються зліва направо.';
  @override
  String get templateHelpCaseBody =>
      'ВЕЛИКІ, малі та перша літера кожного слова — слово, записане '
      'великою, лишається незмінним.';
  @override
  String get templateHelpSlugBody =>
      'Форма посилання з тексту, щоб створити вікіпосилання.';
  @override
  String get templateHelpPadBody =>
      'Обрізає краї; доповнює нулями до потрібної ширини; альтернатива, '
      'якщо значення порожнє.';
  @override
  String get templateHelpShiftBody =>
      'Зсуває дату на дні, тижні, місяці або роки — конференція через '
      'тиждень, документ з минулого місяця.';
  @override
  String get templateHelpSnapBody =>
      'Прив’язує дату до початку або кінця тижня, місяця чи року.';
  @override
  String get templateHelpAskTitle => 'Запитати щось';
  @override
  String get templateHelpAskBody =>
      'Перед створенням нотатки показується форма з полями питань — і одне '
      'зворотне посилання, якщо шаблон його вимагає. Той самий символ '
      'двічі — це питання, і його відповідь заповнює всі появи — папку й '
      'ім’я файлу.';
  @override
  String get templateHelpAskFieldBody =>
      'Поле, про яке питають; текст після другої коми — стартове '
      'значення.';
  @override
  String get templateHelpChoiceBody =>
      'Вибір зі списку, відокремленого комами.';
  @override
  String get templateHelpWhereTitle => 'Куди йде нотатка';
  @override
  String get templateHelpWhereBody =>
      'Це не текст: це вказівки, що живуть у блоці niman: метаданих '
      'шаблону. Блок запускається й видаляється, щоб його ніколи не '
      'показували в нотатці. Значення може містити плейсхолдери.';
  @override
  String get templateHelpFolderBody =>
      'Папка, в якій створюється нотатка, створюється, якщо не існує. Без '
      'неї нотатка йде туди, де ви були.';
  @override
  String get templateHelpFilenameBody =>
      'Як називають нотатку. Шаблон, який це вказує, не питає ім’я.';
  @override
  String get templateHelpAppendBody =>
      'Додає до нотатки, якщо вона вже існує, замість створення нової. Так '
      'щомісячна зустріч стає одним файлом.';
  @override
  String get templateHelpOpenBody =>
      'Що стається, якщо нотатка існує: редактор (за замовчуванням), '
      'перегляд або нічого — нотатку архівують, і ви лишаетесь там, де '
      'були.';
  @override
  String get templateHelpAroundTitle => 'Звідки вона приходить';
  @override
  String get templateHelpParentBody =>
      'Нотатка, яку ви обираєте у формі; запишіть [[{{parent}}]] як '
      'зворотне посилання.';
  @override
  String get templateHelpFolderValueBody => 'Папка, куди йде нотатка.';
  @override
  String get templateHelpClipboardBody =>
      'Що в буфері обміну та виділено в редакторі, якщо нотатка почалася '
      'там.';
  @override
  String get templateHelpIncludeTitle => 'Повторне використання частин';
  @override
  String get templateHelpIncludeBody =>
      'Вставте інший шаблон, щоб кілька шаблонів ділили один перевірений '
      'список. Пошук спочатку йде в папці шаблонів, .md можна пропустити. '
      'Ті самі питання йдуть у ту саму форму.';
  @override
  String get templateHelpExampleTitle => 'Усе в одному місці';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ шаблон „$path” не існує';
  @override
  String includeCycle(String path) => '⚠ „$path” включає саме себе';
  @override
  String includeTooDeep(String path) => '⚠ „$path” вкладено надто глибоко';
  @override
  String frontmatterInvalid(String reason) =>
      'Не вдалося прочитати метадані: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Не вдалося прочитати метадані „$template”, тому папка й ім’я файлу '
      'не застосовувалися: $reason';
  @override
  String get templatePickerTitle => 'Вибір шаблону';
  @override
  String templatePickerEmpty(String folder) =>
      'Шаблонів ще немає. Покладіть нотатку в $folder/ і вона стане '
      'шаблоном.';

  // Tree actions.
  @override
  String get actionPin => 'Закріпити';
  @override
  String get actionUnpin => 'Відкріпити';
  @override
  String get pinToWidget => 'Закріпити у віджеті';
  @override
  String get pinnedForWidget =>
      'Закріплено: тепер додайте віджет «Нотатка» на головний екран';
  @override
  String get pinWidgetUnavailable =>
      'Віджети головного екрана доступні в Android';
  @override
  String get movedToTrash => 'Переміщено в кошик';
  @override
  String get deletedMessage => 'Видалено';
  @override
  String deleteToTrashConfirm(String name) => '$name буде переміщено в .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name буде остаточно видалено';
  @override
  String get chooseDestination => 'Обрати призначення';
  @override
  String get libraryRoot => 'Корінь бібліотеки';
  @override
  String moveTitle(String name) => 'Перемістити $name';
  @override
  String headingLevelLabel(int level) => 'Рівень заголовка $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Швидкої нотатки ще немає. Оберіть існуючу нотатку або створіть '
      'нову — швидка нотатка відкриватиметься тут.';
  @override
  String get quickNoteChooseAction => 'Обрати нотатку…';
  @override
  String get quickNoteCreateAction => 'Створити нову нотатку…';
  @override
  String get quickNoteNewTitle => 'Нова швидка нотатка';
  @override
  String get quickNotePickerTitle => 'Вибір швидкої нотатки';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Нова папка';
  @override
  String get folderPickerEmpty => 'Папок ще немає';
  @override
  String get listFolderTitle => 'Папка списків';
  @override
  String get attachmentsFolderTitle => 'Папка вкладень';

  // Trash (M1).
  @override
  String get trashEmpty => 'Кошик порожній';
  @override
  String get trashEmptyAction => 'Очистити кошик';
  @override
  String get trashEmptyConfirm =>
      'Це остаточно видалить усе в кошику, включно з елементами, які Niman '
      'туди не покладав.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name буде остаточно видалено (без відновлення)';
  @override
  String get trashDeletePermanently => 'Видалити остаточно';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Відкрийте папку з Markdown-нотатками як бібліотеку';
  @override
  String get openLibraryExisting => 'Відкрити існуючу';
  @override
  String get openLibraryCreate => 'Створити нову';
  @override
  String get openLibraryCreateTitle => 'Створити нову бібліотеку';
  @override
  String get openLibraryFolderName => 'Назва папки';
  @override
  String get openLibraryChooseFolder => 'Обрати папку бібліотеки';
  @override
  String get openLibraryChooseParent =>
      'Оберіть папку, в якій буде створено бібліотеку';
  @override
  String get openLibraryUnsupported =>
      'Ця папка не підтримується. Оберіть папку зі сховища пристрою.';
  @override
  String indexingCount(int done, int total) => '$done / $total нотаток';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Ваші бібліотеки';
  @override
  String get libraryUnreachable => 'Недоступна';
  @override
  String get libraryOpenedToday => 'Відкрита сьогодні';
  @override
  String get libraryOpenedYesterday => 'Відкрита вчора';
  @override
  String libraryOpenedDaysAgo(int days) => 'Відкрита $days днів тому';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Відкрита ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Зараз відкрита';
  @override
  String get switchLibraryTitle => 'Змінити бібліотеку';
  @override
  String get libraryForget => 'Забути';
  @override
  String libraryForgetTitle(String name) => 'Забути «$name»?';
  @override
  String get libraryForgetExplained =>
      'Вона зникне з цього списку. Папка, нотатки й налаштування '
      'бібліотеки лишаються недоторканими, і повторне відкриття повертає '
      'її на місце.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Дозволити доступ до файлів';
  @override
  String get storageAccessNeeded =>
      'Niman не може читати ваші нотатки без «Доступу до всіх файлів». '
      'Дозвольте це, щоб відкрити бібліотеку.';
  @override
  String get storageAccessExplained =>
      'Niman читає ваші нотатки як звичайні файли, тому Android має дати '
      'доступ до всіх файлів. Нічого не надсилається, і читається лише '
      'обрана папка бібліотеки.';
  @override
  String folderAccessDenied(Object error) =>
      'Система не дозволила доступ до папки: $error';
  @override
  String folderPickFailed(Object error) => 'Вибір папки не вдався: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Налаштування';
  @override
  String get libraryPathTitle => 'Шлях бібліотеки';
  @override
  String get reindexTitle => 'Переіндексувати зараз';
  @override
  String get reindexDone => 'Переіндексацію завершено';
  @override
  String get closeLibraryTitle => 'Закрити бібліотеку';
  @override
  String get exportLogTitle => 'Експортувати журнал налагодження';
  @override
  String get exportLogSubtitle =>
      'Збережіть зареєстровані події у файл, який оберете';
  @override
  String get exportLogEmpty => 'Буфер журналу порожній';
  @override
  String get quickNoteUnset => 'Не задано';
  @override
  String exportLogDone(Object target) => 'Журнал експортовано в $target';
  @override
  String exportLogFailed(Object error) => 'Експорт не вдався: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '«$term» не має точного збігу цілого слова';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Замінено $occurrences появи «$term» у $notes нотатках';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped відкритих нотаток пропущено)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '«$term» не має точного збігу цілого слова'
      '${only == null ? '' : ' — знайдено лише $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Про застосунок';
  @override
  String get versionTitle => 'Версія';
  @override
  String get changelogTitle => 'Журнал змін';
  @override
  String get changelogEmpty => 'Записи журналу змін недоступні';
  @override
  String changelogWhatsNew(String version) => 'Новини у версії $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Історія';
  @override
  String get noteMenuTooltip => 'Дії з нотаткою';
  @override
  String get historyCurrentVersion => 'Поточна версія';
  @override
  String get historyCurrentSubtitle => 'Нотатка в її поточному стані';
  @override
  String get historyToday => 'Сьогодні';
  @override
  String get historyYesterday => 'Вчора';
  @override
  String get historyReasonSession => 'до редагування';
  @override
  String get historyReasonInterval => 'під час редагування';
  @override
  String get historyReasonRestore => 'до відновлення';
  @override
  String get historyReasonSync => 'до синхронізації';
  @override
  String get historyReasonReplace => 'до заміни';
  @override
  String get historyReasonUnknown => 'віднайдена';
  @override
  String get historySyncBase => 'база синхронізації';
  @override
  String get historyEmpty =>
      'Версій ще немає. Niman зберігає одну, коли ви починаєте редагувати '
      'нотатку, а далі щонайбільше одну раз на кілька хвилин, поки ви '
      'пишете.';
  @override
  String historyKept(int kept, int limit) =>
      'Збережено версій: $kept із $limit';
  @override
  String get historyBaseKept => 'База синхронізації зберігається понад ліміт.';
  @override
  String get historyOff =>
      'Історію вимкнено для цієї бібліотеки (Налаштування, Бібліотека).';
  @override
  String get historyLoadFailed => 'Не вдалося прочитати історію';
  @override
  String get historyCompareSubtitle => 'Порівняно з поточною версією';
  @override
  String get historyTabChanges => 'Зміни';
  @override
  String get historyTabVersion => 'Версія';
  @override
  String get historyNoChanges => 'Текст такий самий, як у поточній версії.';
  @override
  String get historyRestoreAction => 'Відновити цю версію';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Відновити версію від $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Спершу поточний текст збережеться в історії, тож ви завжди зможете '
      'повернутися.';
  @override
  String get historyRestoreConfirm => 'Відновити';
  @override
  String historyRestored(String when) => 'Відновлено версію від $when';
  @override
  String get historyRestoreFailed => 'Не вдалося відновити версію';
  @override
  String get actionUndo => 'Скасувати';
  @override
  String diffLineRange(int start, int end) => 'Рядки $start–$end';
  @override
  String diffLineSingle(int line) => 'Рядок $line';
  @override
  String diffUnchanged(int count) => switch ((count % 10, count % 100)) {
    (_, >= 11 && <= 14) => '$count незмінених рядків',
    (1, _) => '$count незмінений рядок',
    (>= 2 && <= 4, _) => '$count незмінені рядки',
    _ => '$count незмінених рядків',
  };
  @override
  String get historyVersionsTitle => 'Скільки версій зберігати';
  @override
  String get historyVersionsSubtitle => 'Для кожної нотатки, у .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Жодної' : '$count';
  @override
  String get historyIntervalTitle => 'Нова версія щонайбільше раз на';
  @override
  String get historyIntervalSubtitle =>
      'Поки ви пишете; на початку редагування нотатки версія зберігається '
      'завжди';
  @override
  String historyIntervalValue(int minutes) => '$minutes хв';
}
