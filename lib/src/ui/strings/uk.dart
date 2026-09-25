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
  String get trashAutoEmptyTitle => 'Автоочищення кошика';
  @override
  String get trashAutoEmptySubtitle =>
      'Старіші видалення зникають назавжди під час відкриття бібліотеки';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Ніколи'
      : switch ((days % 10, days % 100)) {
          (_, >= 11 && <= 14) => '$days днів',
          (1, _) => '$days день',
          (>= 2 && <= 4, _) => '$days дні',
          _ => '$days днів',
        };
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
  String get readableLineLengthTitle => 'Зручна довжина рядка';
  @override
  String get readableLineLengthSubtitle =>
      'Тримати текст нотатки в центрованій колонці замість усієї ширини вікна';
  @override
  String get noteColumnWidthTitle => 'Ширина колонки';
  @override
  String get noteColumnWidthSubtitle => 'Ширина колонки нотатки в пікселях';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
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
  String get editorKindSourceSubtitle => 'Джерело Markdown, як написано';
  @override
  String get editorKindWysiwygSubtitle =>
      'Форматований текст, редагується на місці';
  @override
  String get settingsFolderToCreate => 'створити';
  @override
  String get settingsSearchHint => 'Пошук налаштувань';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 налаштування знайдено' : '$count налаштувань знайдено';
  @override
  String get settingsToggleOn => 'Увімк.';
  @override
  String get settingsToggleOff => 'Вимк.';
  @override
  String get switchToWysiwygTooltip => 'Перемкнути на WYSIWYG-редактор';
  @override
  String get switchToSourceTooltip => 'Перемкнути на Markdown-джерело';
  @override
  String get switchToSourceLabel => 'Джерело';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Бібліотека $name';
  @override
  String get settingsGroupLibraryHint =>
      'застосовується лише до цієї бібліотеки';
  @override
  String get settingsGroupMaintenance => 'Обслуговування';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Папки та шляхи';
  @override
  String get settingsAreaTrashHistory => 'Кошик і хронологія';
  @override
  String get settingsAreaDiagnostics => 'Діагностика та інфа';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Потрібна підключена фізична клавіатура';
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
  String get themeTitle => 'Тема';
  @override
  String get themeSubtitle => 'Кольори інтерфейсу та нотаток';
  @override
  String get themePaletteSystem => 'Система';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Теми';
  @override
  String get themesInUse => 'Використовується';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Нова тема';
  @override
  String get themeNewName => 'Назва';
  @override
  String get themeNewStartFrom => 'Почати з';
  @override
  String get themeNewRandom => 'Випадкові кольори';
  @override
  String get themeNameTaken => 'Тема з такою назвою вже є';
  @override
  String themeDeleteBody(String name) =>
      'Видалити «$name»? Його кольори зникнуть назавжди.';
  @override
  String get themeDuplicate => 'Дублювати';
  @override
  String get themeMenuTooltip => 'Дії з темою';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Редагувати';
  @override
  String get themeEditorTitle => 'Редагувати тему';
  @override
  String get themeEditorChrome => 'Інтерфейс';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Списки завдань (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Кожен колір названо так, як у файлі експорту';
  @override
  String get themeEditorDiscardTitle => 'Скасувати зміни';
  @override
  String get themeEditorDiscardBody => 'Кольори, які ви змінили, не збережено';
  @override
  String get themeEditorDiscard => 'Скасувати';
  @override
  String get themeEditorBadColor => 'Використайте #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Експортувати';
  @override
  String themeExportDone(String where) => 'Тему експортовано до $where';
  @override
  String themeFileFailed(String error) => 'Тему не вдалося перенести: $error';
  @override
  String get themeImport => 'Імпортувати';
  @override
  String get themeImportInvalid => 'Цей файл не є темою Niman';
  @override
  String themeImportVersion(int version) =>
      'Ця тема з новішого Niman (версія $version)';
  @override
  String themeImportBadRole(String role) => 'Файл не дає кольору для «$role»';

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
  @override
  String get epubLookTitle => 'Вигляд книжок';
  @override
  String get epubLookSubtitle =>
      'Тема, шрифт і розмір тексту книжок EPUB, окремо від нотаток';
  @override
  String get epubSameAsApp => 'Як у застосунку';
  @override
  String get epubFontTitle => 'Шрифт';
  @override
  String get epubFontSerif => 'Із засічками';
  @override
  String get epubFontSans => 'Без засічок';
  @override
  String get epubFontMono => 'Моноширинний';
  @override
  String get epubTextSizeTitle => 'Розмір тексту';

  // Settings: preview mode.
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
  String get missingNoteLocationTitle => 'Створити відсутні нотатки в';
  @override
  String get missingNoteLocationRoot => 'Корень бібліотеки';
  @override
  String get missingNoteLocationCurrentFolder => 'Поточна папка';
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
  String get trayOpen => 'Відкрити Niman';
  @override
  String get trayQuit => 'Вийти';
  @override
  String get closeToTrayTitle => 'Закривати в область повідомлень';
  @override
  String get closeToTraySubtitle =>
      '× вікна ховає Niman і залишає його працювати, тому нагадування й далі '
      'приходять. Вийти можна з меню значка.';
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
  String get shortcutCloseTab => 'Закрити поточну нотатку';
  @override
  String get shortcutNextTab => 'Наступна відкрита нотатка';
  @override
  String get shortcutPreviousTab => 'Попередня відкрита нотатка';
  @override
  String get shortcutEditorSection => 'У редакторі';
  @override
  String get shortcutFormatSection => 'Форматування';
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
  String get noteStatusLoading => 'Завантаження…';
  @override
  String get noteStatusSaving => 'Збереження…';
  @override
  String get noteStatusUnsaved => 'Не збережено';
  @override
  String get noteStatusSaved => 'Збережено';
  @override
  String get noteStatusError => 'Помилка';
  @override
  String get noteNotText =>
      'Цей файл не є текстовою нотаткою, тож Niman не може показати його тут.';
  @override
  String get noteLoadFailed => 'Не вдалося відкрити цю нотатку.';
  @override
  String wordCount(int count) =>
      switch (count % 100 >= 11 && count % 100 <= 14 ? 0 : count % 10) {
        1 => '$count слово',
        >= 2 && <= 4 => '$count слова',
        _ => '$count слів',
      };
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
  String get toolbarHighlight => 'Виділення';
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
  String get toolbarTable => 'Таблиця';
  @override
  String get tableRow => 'Рядок';
  @override
  String get tableColumn => 'Стовпець';
  @override
  String get tableAddRowAbove => 'Вставити рядок вище';
  @override
  String get tableAddRowBelow => 'Вставити рядок нижче';
  @override
  String get tableMoveRowUp => 'Перемістити рядок вгору';
  @override
  String get tableMoveRowDown => 'Перемістити рядок вниз';
  @override
  String get tableDuplicateRow => 'Дублювати рядок';
  @override
  String get tableDeleteRow => 'Видалити рядок';
  @override
  String get tableAddColumnLeft => 'Вставити стовпець ліворуч';
  @override
  String get tableAddColumnRight => 'Вставити стовпець праворуч';
  @override
  String get tableMoveColumnLeft => 'Перемістити стовпець ліворуч';
  @override
  String get tableMoveColumnRight => 'Перемістити стовпець праворуч';
  @override
  String get tableAlignLeft => 'Вирівняти ліворуч';
  @override
  String get tableAlignCenter => 'По центру';
  @override
  String get tableAlignRight => 'Вирівняти праворуч';
  @override
  String get tableDuplicateColumn => 'Дублювати стовпець';
  @override
  String get tableDeleteColumn => 'Видалити стовпець';
  @override
  String get tableSortAscending => 'Сортувати за стовпцем (А → Я)';
  @override
  String get tableSortDescending => 'Сортувати за стовпцем (Я → А)';
  @override
  String get tableAddRow => 'Додати рядок';
  @override
  String get tableAddColumn => 'Додати стовпець';
  @override
  String get cheatsheetTitle => 'Шпаргалка з Markdown';
  @override
  String get cheatsheetCopy => 'Копіювати';
  @override
  String get cheatsheetCopied => 'Скопійовано';
  @override
  String get cheatsheetInsert => 'Вставити в нотатку';
  @override
  String get cheatsheetWritten => 'Написано';
  @override
  String get cheatsheetShown => 'Показано';
  @override
  String get cheatHeadings => 'Заголовки';
  @override
  String get cheatEmphasis => 'Жирний, курсив, закреслений';
  @override
  String get cheatHtmlFormats => 'Підкреслений, верхній індекс, нижній індекс';
  @override
  String get cheatLists => 'Списки';
  @override
  String get cheatChecklists => 'Контрольні списки';
  @override
  String get cheatQuotes => 'Цитати';

  @override
  String get cheatCallouts => 'Виділені блоки';
  @override
  String get cheatLinks => 'Посилання';
  @override
  String get cheatWikilinks => 'Посилання на нотатки';
  @override
  String get cheatEmbeds => 'Зображення та вбудовування';
  @override
  String get cheatTags => 'Теги';
  @override
  String get cheatInlineCode => 'Код у реченні';
  @override
  String get cheatCodeBlocks => 'Блоки коду';
  @override
  String get cheatMath => 'Математика';
  @override
  String get cheatTables => 'Таблиці';
  @override
  String get cheatFootnotes => 'Виноски';
  @override
  String get cheatRule => 'Горизонтальна лінія';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Заповнювачі шаблонів';
  @override
  String get menuAddLink => 'Додати посилання';
  @override
  String get menuAddExternalLink => 'Додати зовнішнє посилання';
  @override
  String get menuFormat => 'Формат';
  @override
  String get menuParagraph => 'Абзац';
  @override
  String get menuInsert => 'Вставити';
  @override
  String get menuBody => 'Звичайний текст';
  @override
  String get formatSubscript => 'Нижній індекс';
  @override
  String get formatInlineCode => 'Код';
  @override
  String get insertFootnote => 'Виноска';
  @override
  String get insertRule => 'Горизонтальна лінія';
  @override
  String get insertCodeBlock => 'Блок коду';
  @override
  String get insertMathBlock => 'Математичний блок';
  @override
  String get menuHeadingWord => 'Заголовок';
  @override
  String get toolbarHeading => 'Заголовок';
  @override
  String get toolbarList => 'Список';
  @override
  String get toolbarOrderedList => 'Нумерований список';
  @override
  String get toolbarChecklist => 'Контрольний список';
  @override
  String get toolbarQuote => 'Цитата';
  @override
  String get toolbarIndent => 'Відступ';
  @override
  String get toolbarOutdent => 'Прибрати відступ';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Інструменти';
  @override
  String get editorToolsTitle => 'Інструменти редактора';
  @override
  String get toolCountListTitle => 'Порахувати список';
  @override
  String get toolCountListSubtitle =>
      'Підсумовує те, що перелічують рядки, як список із позначками';
  @override
  String get toolCountListNeedsList =>
      'У цій нотатці немає списку для підрахунку';
  @override
  String get tallySourceLabel => 'Список';
  @override
  String get tallyCutLabel => 'Читати кожен рядок як';
  @override
  String get tallyCutDash => "Ім'я - значення";
  @override
  String get tallyCutColon => "Ім'я: значення";
  @override
  String get tallyCutCommas => 'Значення через кому';
  @override
  String get tallyCutWhole => 'Увесь рядок як одне значення';
  @override
  String get tallySortLabel => 'Порядок';
  @override
  String get tallySortCount => 'Спочатку найбільші';
  @override
  String get tallySortAlphabetical => 'За абеткою';
  @override
  String get tallySortFirstSeen => 'У порядку списку';
  @override
  String get tallyInsert => 'Вставити';
  @override
  String get tallyUpdate => 'Оновити';
  @override
  String get tallyNothingToCount => 'Тут немає чого рахувати';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Нотатка не існує';
  @override
  String missingNoteDialogBody(String path) => 'Створити «$path»?';
  @override
  String missingNoteFolderMissing(String folder) => 'Папка «$folder» не існує';

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
  String get newItemTooltip => 'Нове';
  @override
  String get closeMenuTooltip => 'Закрити';
  @override
  String get newFolderTitle => 'Нова папка';
  @override
  String get newNoteSameFolder => 'Нова нотатка в тій самій теці';
  @override
  String get newFromTemplateSameFolder => 'Нова із шаблону в тій самій теці';
  @override
  String trashOriginalPath(String path) => 'була в $path';
  @override
  String get trashOriginalRoot => 'було в корені бібліотеки';
  @override
  String trashItemCount(int count) => count == 1
      ? '1 \u0435\u043b\u0435\u043c\u0435\u043d\u0442'
      : '$count \u0435\u043b\u0435\u043c\u0435\u043d\u0442\u0456\u0432';
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
  String get templateHelpSubtitle =>
      'Дата, назва й інші значення для заповнення';
  @override
  String get quickNoteSubtitle =>
      'Нотатка, яку відкриває вкладка Швидка нотатка';
  @override
  String get listFolderSubtitle => 'Нові списки справ';
  @override
  String get templateFolderSubtitle => 'Джерело для „Нової з шаблону“';
  @override
  String get attachmentsFolderSubtitle =>
      'Зображення й аудіо, вставлені в нотатку';
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

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Показати у файловому менеджері';
  @override
  String get openInDefaultApp => 'Відкрити у типовій програмі';
  @override
  String get newNoteTabTooltip => 'Нова нотатка в новій вкладці';
  @override
  String get openNotesTooltip => 'Відкриті нотатки';
  @override
  String get closeTabTooltip => 'Закрити';
  @override
  String get openInNewTab => 'Відкрити в новій вкладці';
  @override
  String get splitRight => 'Розділити праворуч';
  @override
  String get splitDown => 'Розділити донизу';
  @override
  String get moveToOtherPane => 'Перемістити в іншу панель';
  @override
  String get openBeside => 'Відкрити збоку';
  @override
  String get closeAllNotes => 'Закрити всі';
  @override
  String get sidePanelTooltip => 'Показати або сховати бічну панель';
  @override
  String get historyAllVersions => 'Усі версії';
  @override
  String get commandPaletteTitle => 'Палітра команд';
  @override
  String get goToNoteTitle => 'Перейти до нотатки';
  @override
  String get paletteGroupNote => 'Нотатка';
  @override
  String get paletteGroupEditor => 'Редактор';
  @override
  String get paletteGroupView => 'Вигляд';
  @override
  String get paletteGroupLibrary => 'Бібліотека';
  @override
  String get paletteGroupGoTo => 'Перейти до';
  @override
  String get paletteGroupJournal => 'Щоденник';
  @override
  String get journalToday => 'Сьогоднішній запис';
  @override
  String get journalPrevious => 'Попередній запис';
  @override
  String get journalNext => 'Наступний запис';
  @override
  String get commandNeedJournalEntry => 'Потрібен відкритий запис щоденника';
  @override
  String journalCreateAsk(String day) => 'Для $day ще немає запису. Створити?';
  @override
  String journalTemplateMissing(String path) =>
      'Не вдалося прочитати шаблон щоденника $path: запис створено без нього.';
  @override
  String get journalIntro =>
      'Одна нотатка на день, створена з шаблону, коли ти вперше відкриваєш '
      'цей день. Ці налаштування подорожують разом із бібліотекою.';
  @override
  String get journalFolderTitle => 'Тека щоденника';
  @override
  String get journalFolderSubtitle => 'Куди йдуть записи';
  @override
  String get journalEntryNameTitle => 'Назва запису';
  @override
  String get journalEntryNameSubtitle =>
      "YYYY, MM або M, DD або D для дати; / створює теку; текст у 'лапках' "
      'лишається як є';
  @override
  String journalEntryNamePreview(String path) => 'Сьогоднішній запис: $path';
  @override
  String get journalEntryNameInvalid =>
      'Потрібні YYYY, місяць (MM або M) і день (DD або D), і нічого, чого не '
      'може містити назва файлу';
  @override
  String get journalTemplateTitle => 'Шаблон';
  @override
  String get journalTemplateSubtitle => 'З чого починається новий запис';
  @override
  String get journalTemplateNone => 'Немає: заголовок із датою';
  @override
  String get journalDayStartTitle => 'Новий день починається о';
  @override
  String get journalDayStartSubtitle =>
      'Пізно лягаєш? О 04:00 ніч лишається на попередньому дні';
  @override
  String get journalRecent => 'Нещодавні';
  @override
  String get journalNoEntry => 'Немає запису на цей день';
  @override
  String get journalOpenEntry => 'Відкрити';
  @override
  String get journalShowCalendar => 'Показати календар';
  @override
  String get journalFabToday => 'Сьогоднішній запис щоденника';
  @override
  String journalDueOn(String day) => 'Термін $day';
  @override
  String get commandsTitle => 'Команди';
  @override
  String get commandsIntro =>
      'Палітра команд пропонує лише ті команди, які можна виконати там, де ви '
      "є. Тут усі, і коли кожна з'являється.";
  @override
  String get commandsKeysNote =>
      'Тут нічого не змінюється. Клавіші — це ті, що задані в розділі '
      '«Комбінації клавіш», і вони слідують за кожною зміною там.';
  @override
  String get commandsOpenShortcuts =>
      'Змінити клавіші в розділі «Комбінації клавіш»';
  @override
  String get commandsChangeKeyTooltip =>
      'Змінити в розділі «Комбінації клавіш»';
  @override
  String get commandsSubtitle => 'Що може виконати палітра команд, і коли';
  @override
  String get keyboardShortcutsSubtitle => 'Змінити клавіші кожної команди';
  @override
  String get commandNeedNone => 'Завжди доступно';
  @override
  String get commandNeedOpenNote => 'Потрібна відкрита нотатка';
  @override
  String get commandNeedTextNote => 'Потрібна відкрита текстова нотатка';
  @override
  String get commandNeedWideWindow => 'Лише в широкому вікні';
  @override
  String get commandNeedDockRoom =>
      'Потрібне вікно, достатньо широке для бічної панелі';
  @override
  String get commandNeedDesktop => "Лише на комп'ютері";
  @override
  String get commandNeedNotInZen => 'Не в режимі Дзен';
  @override
  String get commandNeedZenRoom => "Комп'ютер, з нотаткою, відкритою у вкладці";
  @override
  String get commandNeedPreview =>
      'З увімкненим переглядом, у текстовій нотатці';
  @override
  String get commandNeedTwoEditors => 'З обома увімкненими редакторами';
  @override
  String get paletteHint => 'Шукати команди й нотатки';
  @override
  String get paletteNoResults => 'Нічого не знайдено';
  @override
  String get paletteCommands => 'Команди';
  @override
  String get paletteNotes => 'Нотатки';
  @override
  String get paletteFooter => '↑↓ переміщення · ↵ вибрати · esc закрити';
  @override
  String get paletteFooterTouch =>
      'Торкніться, щоб виконати · шпилька тримає вгорі';
  @override
  String get palettePinned => 'Закріплені';
  @override
  String get palettePin => 'Закріпити';
  @override
  String get paletteUnpin => 'Відкріпити';
  @override
  String get palettePinFooter => 'alt+P закріпити';
  @override
  String get spellCheckScanning => 'Перевірка нотатки…';
  @override
  String get spellCheckAgain => 'Перевірити знову';
  @override
  String spellCheckCapped(int count) =>
      'Показано перші $count: виправте кілька, а потім перевірте знову, щоб '
      'побачити решту';
  @override
  String get dropHint =>
      'Перетягніть файли Markdown, щоб відкрити їх, або теку, щоб '
      'імпортувати її';
  @override
  String get dropNothing =>
      'Стільниця не передала жодного файла під час цього перетягування.';
  @override
  String get importFolderAction => 'Імпортувати';
  @override
  String dropRejected(String names) =>
      'Тут відкриваються лише файли Markdown і теки: $names';
  @override
  String importFolderTitle(String name) => 'Імпортувати «$name»?';
  @override
  String importFolderBody(int count) =>
      'Її файли Markdown ($count) буде скопійовано в нову теку бібліотеки. '
      'Перетягнута тека залишиться як є.';
  @override
  String importFolderDone(String folder) => 'Імпортовано до $folder';
  @override
  String importFolderEmpty(String name) => 'У $name немає файлів Markdown';
  @override
  String get openFileTitle => 'Відкрити файл';
  @override
  String get outsideFileNote =>
      'Поза бібліотекою: зберігається на місці, без індексу, без історії, '
      'посилання не відкриваються';
  @override
  String get typewriterOn => 'Увімкнути режим друкарської машинки';
  @override
  String get typewriterOff => 'Вимкнути режим друкарської машинки';
  @override
  String get typewriterTitle => 'Режим друкарської машинки';
  @override
  String get formatNoteTitle => 'Упорядкувати Markdown';
  @override
  String get formatNoteDone => 'Нотатку впорядковано.';
  @override
  String get formatNoteAlreadyTidy => 'Нотатка вже була впорядкована.';
  @override
  String get tidyOnCloseTitle => 'Упорядковувати Markdown під час закриття';
  @override
  String get tidyOnCloseSubtitle =>
      'Коли ви закриваєте нотатку, яку редагували, її Markdown '
      'упорядковується, як командою «Упорядкувати Markdown». Нотатки понад '
      '4 МБ залишаються як є.';
  @override
  String get typewriterSubtitle =>
      'Рядок, який ви пишете, залишається посередині редактора';
  @override
  String get zenMode => 'Режим дзен';
  @override
  String get zenModeEnter => 'Увійти в режим дзен';
  @override
  String get zenModeLeave => 'Вийти з режиму дзен';
  @override
  String get keySpace => 'Пробіл';
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
  String get keyArrowUp => 'Угору';
  @override
  String get keyArrowDown => 'Униз';
  @override
  String get keyArrowLeft => 'Ліворуч';
  @override
  String get keyArrowRight => 'Праворуч';
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
  String get shortcutNone => 'Немає скорочення';
  @override
  String get shortcutRestoreDefaults => 'Відновити типові';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Повернути всі скорочення, як їх постачає Niman?';
  @override
  String get shortcutRevert => 'Повернути типове';
  @override
  String get shortcutClear => 'Видалити скорочення';
  @override
  String get shortcutCapturePrompt =>
      'Натисніть клавіші. Esc і Tab теж записуються: вийти можна кнопкою '
      '«Скасувати».';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Додайте Ctrl, Alt або Meta: одна клавіша — для набору тексту.';
  @override
  String get shortcutMove => 'Перемістити';
  @override
  String get shortcutUseAnyway => 'Усе одно використати';
  @override
  String get shortcutUndo => 'Скасувати дію';
  @override
  String get shortcutRedo => 'Повторити';
  @override
  String get shortcutChange => 'Змінити скорочення';
  @override
  String shortcutCaptureTitle(String command) => 'Клавіші для «$command»';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys уже належить «$other». Перемістити сюди? «$other» залишиться '
      'без скорочення.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys також «$what» у текстових полях і редакторі. Там його візьме '
      'ваша команда.';
  @override
  String get openFileMissing => 'Файлу цієї нотатки немає на диску';
  @override
  String get openFileFailed => 'Не вдалося відкрити цю нотатку поза Niman';
  @override
  String get attachmentUnreadable => 'Не вдалося показати цей файл.';
  @override
  String get attachmentMissing => 'Цього файлу немає на диску.';
  @override
  String get attachmentOpenFailed => 'Не вдалося відкрити цей файл поза Niman.';
  @override
  String get copyPlaceLink => 'Копіювати посилання на це місце';
  @override
  String get placeLinkCopied => 'Посилання скопійовано';
  @override
  String pdfPageLabel(String name, int page) => '$name, с. $page';
  @override
  String get annotationsFolderTitle => 'Тека анотацій';
  @override
  String get annotationsFolderSubtitle =>
      'Нотатки з анотаціями до PDF чи книги';
  @override
  String get annotationNoteSuffix => 'Анотація';
  @override
  String get annotateAction => 'Анотувати';
  @override
  String get annotationCommentHint => 'Ваш коментар';
  @override
  String get annotationSaved => 'Анотацію збережено';
  @override
  String get annotationOpenNote => 'Відкрити нотатку';
  @override
  String get annotationFailed => 'Не вдалося зберегти анотацію';

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
  String get historyTakeHunk => 'Відновити тут';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Відновити 1 зміну' : 'Відновити $count змін';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Вибрані зміни повертаються до тексту цієї версії. Нотатку в її '
      'теперішньому вигляді спершу збережено як версію, тож це можна '
      'скасувати.';
  @override
  String get historyNoteChangedReloaded =>
      'Нотатка змінилася, поки ти був тут — порівняння оновлено.';
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
  @override
  String get settingsSectionTranscription => 'Транскрипція';
  @override
  String get transcriptionModelTitle => 'Модель';
  @override
  String get transcriptionModelNone => 'Немає';
  @override
  String get transcriptionLanguageTitle => 'Мова';
  @override
  String get transcriptionLanguageSubtitle =>
      'Мова, якою говорять у ваших записах. Вказати її точніше, ніж визначати '
      'автоматично.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Як у застосунку ($language)';
  @override
  String get transcriptionLanguageDetect => 'Визначати автоматично';
  @override
  String get transcriptionModelsTitle => 'Моделі транскрипції';
  @override
  String transcriptionModelsUsed(String size) => 'Зайнято $size';
  @override
  String get transcriptionModelsInstalled => 'Завантажені';
  @override
  String get transcriptionModelsDownloading => 'Завантажуються';
  @override
  String get transcriptionModelsAvailable => 'Доступні';
  @override
  String get transcriptionModelsFooter =>
      'Моделі залишаються в сховищі застосунку на цьому пристрої. Вони не '
      'копіюються до бібліотеки і не синхронізуються.';
  @override
  String get transcriptionModelDefault => 'Типова';
  @override
  String get transcriptionModelSlow => 'Повільна';
  @override
  String get transcriptionModelHintTiny => 'Найшвидша, найменш точна';
  @override
  String get transcriptionModelHintBase => 'Добрий баланс швидкості й точності';
  @override
  String get transcriptionModelHintSmall =>
      'Точніша, приблизно в 3× повільніша';
  @override
  String get transcriptionModelHintMedium => 'Дуже точна, повільна на телефоні';
  @override
  String get transcriptionModelHintLarge =>
      "Найточніша, потребує багато пам'яті";
  @override
  String get transcriptionModelDownload => 'Завантажити';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Видалити модель $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Звільниться $size. Ви зможете завантажити модель знову пізніше.';
  @override
  String get transcriptionModelFailed =>
      "Не вдалося завантажити. Перевірте з'єднання і спробуйте ще раз.";
  @override
  String get actionRetry => 'Спробувати ще раз';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      "З'єднання втрачено, повторна спроба…";
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Призупинено на $progress';
  @override
  String get actionResume => 'Продовжити';
  @override
  String get audioTranscribe => 'Транскрибувати';
  @override
  String get audioTranscribeUnsupported => 'На цьому пристрої лише записи WAV';
  @override
  String get transcriptionQueued => 'У черзі';
  @override
  String get transcriptionPreparing => 'Підготовка аудіо…';
  @override
  String transcriptionRunning(int percent) => 'Транскрибування… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Завантаження $model · $percent%';
  @override
  String get transcriptionSaved => 'Транскрипцію додано до опису';
  @override
  String get transcriptionNoSpeech => 'У цьому записі мовлення не розпізнано';
  @override
  String get transcriptionFailed => 'Не вдалося транскрибувати';
  @override
  String get transcriptionPickModelTitle => 'Виберіть модель';
  @override
  String get transcriptionPickModelBody =>
      'Транскрибування відбувається на цьому пристрої, запис ніколи не '
      'надсилається. Модель завантажується лише один раз.';
  @override
  String get transcriptionPickModelAction => 'Завантажити й транскрибувати';
  @override
  String get transcriptionModelRecommended => 'Рекомендовано';
  @override
  String get transcriptionExistingTitle => 'Цей запис уже має опис';
  @override
  String get transcriptionExistingBody =>
      'Замінити його транскрипцією чи додати транскрипцію під ним?';
  @override
  String get transcriptionAppend => 'Додати нижче';
  @override
  String get transcriptionReplace => 'Замінити';
  @override
  String get settingsSectionSync => 'Синхронізація';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Не налаштовано для цієї бібліотеки';
  @override
  String get syncNeverSynced => 'Ще не синхронізовано';
  @override
  String syncLastSynced(String when) => 'Синхронізовано $when';
  @override
  String get syncRunning => 'Синхронізація…';
  @override
  String syncScreenSubtitle(String library) => 'Бібліотека $library';
  @override
  String get syncUrlLabel => 'Адреса папки';
  @override
  String get syncUrlRequired => 'Введіть адресу сервера';
  @override
  String get syncUrlHint =>
      'Папка має існувати. Скопіюйте адресу так, як її показує '
      'сервер.';
  @override
  String get syncHttpWarning =>
      'Незашифроване з’єднання: прийнятно через VPN або в '
      'локальній мережі.';
  @override
  String get syncUserLabel => 'Користувач';
  @override
  String get syncUserHint =>
      'Залиште порожнім, якщо сервер не вимагає облікових даних.';
  @override
  String get syncPasswordLabel => 'Пароль';
  @override
  String get syncPasswordHint =>
      'Зберігається у сховищі ключів цього пристрою, ніколи у '
      'файлах бібліотеки.';
  @override
  String get syncPasswordKeepHint =>
      'Залиште порожнім, щоб лишити збережений пароль.';
  @override
  String get syncShowPassword => 'Показати пароль';
  @override
  String get syncHidePassword => 'Приховати пароль';
  @override
  String get syncTestAction => 'Перевірити з’єднання';
  @override
  String get syncTesting => 'Перевірка…';
  @override
  String get syncRetargetWarning =>
      'З новою адресою чи користувачем наступна синхронізація '
      'почнеться спочатку, як перша.';
  @override
  String get syncTestOk => 'З’єднання працює';
  @override
  String get syncModeFull => 'Повний режим';
  @override
  String get syncModeCompatible => 'Сумісний режим';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Читання, запис і видалення';
  @override
  String get syncCapEtags => 'Відбитки файлів (ETag)';
  @override
  String get syncCapNoEtags => 'Без відбитків файлів (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Порівнює розмір і дату; у разі сумніву завантажує знову';
  @override
  String get syncCapGuarded => 'Захищений запис';
  @override
  String get syncCapUnguarded => 'Незахищений запис';
  @override
  String get syncCapUnguardedDetail =>
      'Перевіряє файл на сервері безпосередньо перед записом';
  @override
  String get syncCapMove => 'Перейменовує без повторного вивантаження';
  @override
  String get syncCapNoMove => 'Без перейменування на сервері';
  @override
  String get syncCapNoMoveDetail =>
      'Перейменування стає видаленням і новим вивантаженням';
  @override
  String get syncCompatibleNote =>
      'У сумісному режимі синхронізація працює так само, лише з '
      'кількома додатковими запитами.';
  @override
  String get syncTestInvalidUrl => 'Недійсна адреса';
  @override
  String get syncTestInvalidUrlHint =>
      'Введіть адресу http:// або https:// без імені користувача '
      'й пароля.';
  @override
  String get syncTestOffline => 'Сервер недоступний';
  @override
  String get syncTestOfflineHint =>
      'VPN увімкнено? Адреса 10.x або 192.168.x працює лише з '
      'тієї самої мережі.';
  @override
  String get syncTestAuth => 'Користувача або пароль відхилено';
  @override
  String get syncTestAuthHint => 'Перевірте їх і спробуйте знову.';
  @override
  String get syncTestNotFound => 'Папки не існує';
  @override
  String get syncTestNotFoundHint =>
      'Створіть її на сервері або виправте адресу.';
  @override
  String get syncTestUnsupported => 'Це не папка WebDAV';
  @override
  String get syncTestUnsupportedHint => 'Сервер відповідає, але не як WebDAV.';
  @override
  String get syncTestFailed => 'Перевірка не вдалася';
  @override
  String get syncNowAction => 'Синхронізувати зараз';
  @override
  String get syncSectionServer => 'Сервер';
  @override
  String get syncServerRow => 'Адреса, користувач і пароль';
  @override
  String get syncRetestTitle => 'Перевірити сервер знову';
  @override
  String syncProbedAgo(String when) => 'Остання перевірка $when';
  @override
  String get syncDisconnectTitle => 'Від’єднати цю бібліотеку';
  @override
  String get syncDisconnectSubtitle => 'Файли лишаються тут і на сервері';
  @override
  String get syncDisconnectConfirmTitle => 'Від’єднати синхронізацію?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ця бібліотека перестане синхронізуватися на цьому '
      'пристрої. Жоден файл не буде видалено ні тут, ні на '
      'сервері. Якщо ви під’єднаєте її знову, перша '
      'синхронізація почнеться спочатку.';
  @override
  String get syncDisconnectConfirm => 'Від’єднати';
  @override
  String get syncFirstTitle => 'Перша синхронізація';
  @override
  String get syncFirstIntro => 'Бібліотеку порівняно з папкою на сервері:';
  @override
  String get syncFirstUpload => 'Вивантажити';
  @override
  String get syncFirstDownload => 'Завантажити';
  @override
  String get syncFirstBoth => 'З обох боків';
  @override
  String get syncFirstBothHint =>
      'Однакові: без передавання. Різні: потрібно розв’язати';
  @override
  String get syncFirstNoDelete =>
      'Перша синхронізація нічого не видаляє ні тут, ні на '
      'сервері.';
  @override
  String get syncStartAction => 'Почати';
  @override
  String syncMassTrashTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Перемістити $count файл у кошик?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Перемістити $count файли у кошик?'
      : 'Перемістити $count файлів у кошик?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'На сервері бракує $count із $total синхронізованих '
      'файлів. Зазвичай це означає хибну адресу, непідключений '
      'диск NAS або випадково спорожнену папку.';
  @override
  String get syncMassTrashHint =>
      'Якщо ви справді видалили їх на іншому пристрої, '
      'підтвердьте: тут вони потраплять у кошик.';
  @override
  String get syncMassTrashConfirm => 'Перемістити в кошик';
  @override
  String syncMassDeleteTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Видалити $count файл із сервера?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Видалити $count файли із сервера?'
      : 'Видалити $count файлів із сервера?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Тут бракує $count із $total синхронізованих файлів. Якщо '
      'ви їх не видаляли, скасуйте й перевірте папку бібліотеки.';
  @override
  String get syncMassDeleteConfirm => 'Видалити із сервера';
  @override
  String get syncTooltip => 'Синхронізувати';
  @override
  String get syncStageConnecting => 'Підключення до сервера…';
  @override
  String get syncStageComparing => 'Порівняння із сервером…';
  @override
  String syncStageApplying(int done, int total) =>
      'Синхронізація · $done із $total';
  @override
  String get syncStatusWarnings => 'Синхронізовано з попередженнями';
  @override
  String syncConflictsHeader(int count) => 'Змінено тут і на сервері · $count';
  @override
  String get syncConflictHint => 'Жодну з версій не змінено';
  @override
  String get syncResolveAction => 'Розв’язати';
  @override
  String syncFailuresHeader(int count) => 'Не синхронізовано · $count';
  @override
  String get syncFailuresHint =>
      'Повторна спроба під час наступної синхронізації';
  @override
  String get syncAbortAuth => 'Сервер відхилив пароль';
  @override
  String get syncAbortMissingPassword => 'Пароль не збережено';
  @override
  String get syncAbortOffline => 'Сервер недоступний';
  @override
  String get syncAbortRemoteMissing => 'Папки на сервері більше немає';
  @override
  String get syncAbortUnsupported => 'Сервер більше не працює як WebDAV';
  @override
  String get syncAbortFailed => 'Синхронізація не вдалася';
  @override
  String get syncAbortNotConfirmed => 'Синхронізацію скасовано';
  @override
  String get syncAbortNothingTouched =>
      'Жоден файл не змінено. Ваші зміни лишаються тут до '
      'наступної успішної синхронізації.';
  @override
  String syncLastSuccess(String when) => 'Остання успішна синхронізація $when';
  @override
  String get syncNoSuccessYet => 'Ще жодної успішної синхронізації';
  @override
  String get syncUpdatePasswordAction => 'Оновити пароль';
  @override
  String get syncRetryAction => 'Спробувати знову';
  @override
  String get syncOpenSettingsAction => 'Налаштування';
  @override
  String get syncCloseAction => 'Закрити';
  @override
  String get syncDoneSnack => 'Синхронізовано';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Синхронізовано · $count файл, видалений деінде, у кошику'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Синхронізовано · $count файли, видалені деінде, у кошику'
      : 'Синхронізовано · $count файлів, видалених деінде, у кошику';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Синхронізовано · $count конфлікт потрібно розв’язати'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Синхронізовано · $count конфлікти потрібно розв’язати'
      : 'Синхронізовано · $count конфліктів потрібно розв’язати';
  @override
  String get syncShowAction => 'Показати';
  @override
  String get syncConflictTitle => 'Розв’язати конфлікт';
  @override
  String get syncConflictBinary =>
      'Це не текстовий файл: виберіть, яку копію залишити.';
  @override
  String get syncConflictKeepNote =>
      'Копія, яку ви не залишите, лишиться в історії нотатки.';
  @override
  String get syncKeepLocal => 'Залишити версію цього пристрою';
  @override
  String get syncKeepRemote => 'Залишити версію сервера';
  @override
  String get syncConflictLoadFailed => 'Не вдалося прочитати обидві версії';
  @override
  String get syncResolveFailed => 'Не вдалося розв’язати конфлікт';
  @override
  String get syncResolved => 'Конфлікт розв’язано';
  @override
  String get syncConflictMoved =>
      'Одна з версій тим часом змінилася: конфлікт прочитано знову, виберіть '
      'ще раз.';
  @override
  String get syncSectionWhen => 'Коли синхронізувати';
  @override
  String get syncAutoTitle => 'Автоматично';
  @override
  String get syncAutoSubtitle =>
      'Після змін, під час відкриття та через проміжки часу';
  @override
  String get syncIntervalTitle => 'Перевіряти сервер кожні';
  @override
  String get syncIntervalSubtitle => 'Лише поки програма відкрита';
  @override
  String get syncIntervalDialogBody =>
      'Щоб бачити зміни, зроблені на інших пристроях, поки програма відкрита. '
      'З «Ніколи» — лише після змін і під час відкриття.';
  @override
  String syncIntervalMinutes(int count) => switch ((count % 10, count % 100)) {
    (_, >= 11 && <= 14) => '$count хвилин',
    (1, _) => '$count хвилина',
    (>= 2 && <= 4, _) => '$count хвилини',
    _ => '$count хвилин',
  };
  @override
  String get syncIntervalNever => 'Ніколи';
  @override
  String get syncWifiOnlyTitle => 'Лише через Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Через мобільні дані синхронізувати лише вручну';
  @override
  String syncPendingChanges(int count) => switch ((count % 10, count % 100)) {
    (_, >= 11 && <= 14) => '$count змін чекає',
    (1, _) => '$count зміна чекає',
    (>= 2 && <= 4, _) => '$count зміни чекають',
    _ => '$count змін чекає',
  };
  @override
  String syncRetryIn(String wait) => 'наступна спроба через $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds с';
  @override
  String syncWaitMinutes(int minutes) => '$minutes хв';
  @override
  String get syncWaitingForWifi => 'Очікування Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Очікування з’єднання';
  @override
  String get syncMobileDataHint =>
      '«Синхронізувати зараз» усе одно використовує мобільні дані.';
  @override
  String get syncQueueKeptHint =>
      'Зміни залишаються тут, навіть якщо ви закриєте програму, і вирушають '
      'самі, коли сервер відповість.';
  @override
  String get syncAutoPaused => 'Автоматична синхронізація призупинена';
  @override
  String get syncPausedAuthHint =>
      'Вона відновиться, коли ви оновите пароль або синхронізуєте вручну.';
  @override
  String get syncPausedServerHint =>
      'Вона відновиться, коли ви виправите адресу або синхронізуєте вручну.';
  @override
  String get syncPausedConfirmHint =>
      '«Синхронізувати зараз» покаже, що буде вилучено, і спершу запитає.';
  @override
  String get syncNeedsConfirmation => 'Очікування вашого підтвердження';
  @override
  String get syncMergeIntro =>
      'Зміни, які не перекриваються, уже об’єднано; там, де перекриваються, '
      'виберіть, що залишити.';
  @override
  String get syncMergeClean =>
      'Дві версії об’єднуються самі: ніщо не перекривається.';
  @override
  String get syncMergeNoBase =>
      'Немає спільної версії для об’єднання: скрізь, де дві копії '
      'відрізняються, вибираєте ви.';
  @override
  String syncMergeOverlap(int index, int total) => 'Перекриття $index з $total';
  @override
  String get syncMergeFromLocal => 'Із цього пристрою';
  @override
  String get syncMergeFromRemote => 'Із сервера';
  @override
  String get syncMergeRemovedLines => 'Вилучені рядки';
  @override
  String get syncMergeAbsentLines => 'Немає в цій копії';
  @override
  String get syncMergeKeepLocal => 'Мої';
  @override
  String get syncMergeKeepRemote => 'Сервера';
  @override
  String get syncMergeKeepBoth => 'Обидва';
  @override
  String get syncMergeSave => 'Зберегти об’єднання';
  @override
  String get syncMergeKeepWhole => 'Або залишити одну цілу копію';
}
