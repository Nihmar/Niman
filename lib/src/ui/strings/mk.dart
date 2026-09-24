// The Macedonian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class MacedonianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'јануари',
    'февруари',
    'март',
    'април',
    'мај',
    'јуни',
    'јули',
    'август',
    'септември',
    'октомври',
    'ноември',
    'декември',
  ];
  @override
  List<String> get monthNamesShort => const [
    'јан',
    'фев',
    'мар',
    'апр',
    'мај',
    'јун',
    'јул',
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
    'среда',
    'четврток',
    'петок',
    'сабота',
    'недела',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'пон',
    'вто',
    'сре',
    'чет',
    'пет',
    'саб',
    'нед',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Корпа';
  @override
  String get trashSubtitle =>
      'Избришаните елементи се преместуваат во .trash/ (исклучено = '
      'трајно брисање)';
  @override
  String get trashAutoEmptyTitle => 'Автоматско празнење на корпата';
  @override
  String get trashAutoEmptySubtitle =>
      'Постарите бришења исчезнуваат засекогаш при отворање на библиотеката';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Никогаш'
      : days == 1
      ? '1 ден'
      : '$days дена';
  @override
  String get debugLogsTitle => 'Дневници за откланување грешки';
  @override
  String get debugLogsSubtitle =>
      'Записува настани на апликацијата во мемориски буфер';
  @override
  String get lineNumbersTitle => 'Броеви на редови';
  @override
  String get lineNumbersSubtitle =>
      'Го прикажува столбчето со броеви на редови во уредникот';
  @override
  String get readableLineLengthTitle => 'Читлива должина на ред';
  @override
  String get readableLineLengthSubtitle =>
      'Текстот на белешката да стои во центрирана колона наместо низ целата '
      'ширина на прозорецот';
  @override
  String get noteColumnWidthTitle => 'Ширина на колоната';
  @override
  String get noteColumnWidthSubtitle =>
      'Колку е широка колоната на белешката, во пиксели';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Тастатура при отворање';
  @override
  String get keyboardOnOpenSubtitle =>
      'Ја прикажува тастатурата веднаш што белешката ќе се отвори '
      '(исклучено = при прв допир)';
  @override
  String get editorKindSource => 'Markdown извор';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown извор, како што е напишан';
  @override
  String get editorKindWysiwygSubtitle =>
      'Форматиран текст, се уредува директно';
  @override
  String get settingsFolderToCreate => 'за создавање';
  @override
  String get settingsSearchHint => 'Пребарај поставки';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 пронајдена поставка' : '$count пронајдени поставки';
  @override
  String get settingsToggleOn => 'Вклучено';
  @override
  String get settingsToggleOff => 'Исклучено';
  @override
  String get switchToWysiwygTooltip => 'Префрли на WYSIWYG уредник';
  @override
  String get switchToSourceTooltip => 'Префрли на Markdown изворот';
  @override
  String get switchToSourceLabel => 'Извор';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Изглед';
  @override
  String get settingsSectionEditor => 'Уредник';
  @override
  String get settingsSectionLibrary => 'Библиотека';
  @override
  String get settingsSectionReminders => 'Подсетници';
  @override
  String get settingsSectionShortcuts => 'Тастатура';
  @override
  String get keyboardShortcutsTitle => 'Тастатурски прецици';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Библиотека $name';
  @override
  String get settingsGroupLibraryHint => 'важи само за оваа библиотека';
  @override
  String get settingsGroupMaintenance => 'Одржување';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Папки и патеши';
  @override
  String get settingsAreaTrashHistory => 'Корпа и хронологија';
  @override
  String get settingsAreaDiagnostics => 'Дијагностика и инфо';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Потребна е поврзана физичка тастатура';
  @override
  String get settingsSectionUpdates => 'Ажурирања';
  @override
  String get autoUpdateTitle => 'Автоматски ажурирања';
  @override
  String get autoUpdateSubtitle =>
      'Проверува GitHub Releases при стартување и на секои 6 часа';
  @override
  String get checkForUpdatesTitle => 'Провери за ажурирања';
  @override
  String updateAvailableMessage(Object version) => 'Достапен е Niman $version';
  @override
  String get updateUpToDate => 'Niman е ажуриран';
  @override
  String get updateCheckFailed => 'Проверката за ажурирања не успеа';
  @override
  String updateSavedTo(Object path) => 'Ажурирањето е зачувано во $path';
  @override
  String get updateInstallerStarted => 'Инсталерот е стартуван';
  @override
  String get settingsSectionDiagnostics => 'Дијагностика';
  @override
  String get settingsSpellCheckTitle => 'Проверка на правопис';
  @override
  String get settingsSpellCheckSubtitle =>
      'Подвлекува погрешно напишани зборови додека пишете.';
  @override
  String get spellCheckDictionaryTitle => 'Речник';
  @override
  String get spellCheckDictionarySystem => 'Системот по подразбирање';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Одбери речници';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Одберете го секој јазик на кој е напишана оваа библиотека. Зборот '
      'минува кога еден од избраните речници го препознава; без избрани, '
      'го одлучува системот.';
  @override
  String get spellCheckNoDictionaries =>
      'Нема пронајдени речници на овој систем.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Проверка на правопис';
  @override
  String get spellCheckTitle => 'Правопис';
  @override
  String get spellCheckEmpty => 'Нема грешки во правописот.';
  @override
  String get spellCheckUnavailable =>
      'hunspell не е инсталиран на овој систем.';
  @override
  String get spellCheckNoSuggestions => 'Нема предлози';
  @override
  String spellCheckCount(int count) => '$count за преглед';
  @override
  String spellCheckLine(int line) => 'ред $line';
  @override
  String get addWordToDictionary => 'Додади во речник';

  @override
  String indentWidthValue(int spaces) => '$spaces празнини';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Јасноста';
  @override
  String get themeBrightnessSubtitle =>
      'Светло, темно или онака како што е поставен уредникот';
  @override
  String get themeBrightnessSystem => 'Систем';
  @override
  String get themeBrightnessDay => 'Светло';
  @override
  String get themeBrightnessNight => 'Темно';
  @override
  String get themeTitle => 'Тема';
  @override
  String get themeSubtitle => 'Бои на интерфејсот и на белешката';
  @override
  String get themePaletteSystem => 'Систем';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Теми';
  @override
  String get themesInUse => 'Се користи';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Нова тема';
  @override
  String get themeNewName => 'Име';
  @override
  String get themeNewStartFrom => 'Почеток од';
  @override
  String get themeNewRandom => 'Случајни бои';
  @override
  String get themeNameTaken => 'Веќе постои тема со тоа име';
  @override
  String themeDeleteBody(String name) =>
      'Да се избрише „$name“? Неговите бои исчезнуваат засекогаш.';
  @override
  String get themeDuplicate => 'Дуплирај';
  @override
  String get themeMenuTooltip => 'Дејства за тема';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Уреди';
  @override
  String get themeEditorTitle => 'Уреди тема';
  @override
  String get themeEditorChrome => 'Интерфејс';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Листи со задачи (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Секоја боја е именувана како во извезената датотека';
  @override
  String get themeEditorDiscardTitle => 'Отфрли ги промените';
  @override
  String get themeEditorDiscardBody => 'Боите што ги сменивте не се зачувуваат';
  @override
  String get themeEditorDiscard => 'Отфрли';
  @override
  String get themeEditorBadColor => 'Користи #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Извези';
  @override
  String themeExportDone(String where) => 'Темата е извезена во $where';
  @override
  String themeFileFailed(String error) =>
      'Темата не можеше да се пренесе: $error';
  @override
  String get themeImport => 'Увези';
  @override
  String get themeImportInvalid => 'Оваа датотека не е тема на Niman';
  @override
  String themeImportVersion(int version) =>
      'Оваа тема е од понова верзија на Niman (верзија $version)';
  @override
  String themeImportBadRole(String role) =>
      'Датотеката не дава боја за „$role“';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Големина на текст на интерфејсот';
  @override
  String get uiTextScaleSubtitle =>
      'Дрвото, картичките и дијалозите; над системската поставка';
  @override
  String get noteTextScaleTitle => 'Големина на текст на белешката';
  @override
  String get noteTextScaleSubtitle =>
      'Уредникот и прегледот, кои секогаш се усогласени';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Формат на врска';
  @override
  String get linkTypeSubtitle => 'Што копчето за врски во уредникот вметнува';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Креирање недостапни белешки во';
  @override
  String get missingNoteLocationRoot => 'Корен на библиотеката';
  @override
  String get missingNoteLocationCurrentFolder => 'Тековна папка';
  @override
  String get indentWidthTitle => 'Ширина на вовлечување';
  @override
  String get indentWidthSubtitle =>
      'Празнини што се додаваат по ниво на вовлечување во уредникот';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Јазик';
  @override
  String get languageSubtitle => 'Јазик на текстот на самата апликација';
  @override
  String get languageSystem => 'Систем';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Додај ставка';
  @override
  String get listAddTooltip => 'Додај ставка';
  @override
  String get listEmpty => 'Сè уште нема ставки';
  @override
  String get listDragHandleLabel => 'Прередиј ја ставка';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Сè уште нема снимки';
  @override
  String get audioRecord => 'Сними';
  @override
  String get audioStop => 'Запри';
  @override
  String get audioPlay => 'Пушти';
  @override
  String get audioDelete => 'Избриши снимка';
  @override
  String get audioImport => 'Увези аудио датотека';
  @override
  String get audioRecording => 'Се снима…';
  @override
  String get audioPermissionDenied =>
      'Дозволата за микрофонот е одбиена — потребна е за снимање.';
  @override
  String get newAudioNoteTitle => 'Нова гласовна белешка';
  @override
  String get newAudioNoteDefault => 'Моја снимка';
  @override
  String get showAudioTooltip => 'Прикажи снимки';
  @override
  String get audioMessageHint => 'Напишете белешка…';
  @override
  String get audioSend => 'Испрати';
  @override
  String get audioRename => 'Промени име на снимката';
  @override
  String get audioDescriptionHint => 'Опишете ја оваа снимка…';
  @override
  String get audioEditDescription => 'Уреди опис';
  @override
  String get audioDeleteNote => 'Избриши белешка';
  @override
  String get audioEditNote => 'Уреди белешка';
  @override
  String get audioPause => 'Пауза';
  @override
  String get audioEditTitle => 'Уреди наслов';
  @override
  String get audioTitleHint => 'Наслов на снимката…';
  @override
  String audioUntitled(int n) => 'Снимка $n';
  @override
  String get audioMoreActions => 'Повеќе дејства';
  @override
  String get audioDiscardRecording => 'Отфрли ја снимката';
  @override
  String get audioPauseRecording => 'Паузирај го снимањето';
  @override
  String get audioResumeRecording => 'Продолжи го снимањето';
  @override
  String get audioRecordingPaused => 'Паузирано';
  @override
  String get audioSavingRecording => 'Се зачувува…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Брзо белешко';
  @override
  String get trayOpen => 'Отвори Niman';
  @override
  String get trayQuit => 'Излези';
  @override
  String get closeToTrayTitle => 'Затвори во лентата со известувања';
  @override
  String get closeToTraySubtitle =>
      '× на прозорецот го крие Niman и го остава да работи, па потсетниците '
      'сè уште доаѓаат. Се излегува од менито на иконата.';
  @override
  String get shortcutNewTodo => 'Нова задача';
  @override
  String get shortcutNewNote => 'Нова белешка';
  @override
  String get shortcutNewList => 'Нова листа';
  @override
  String get shortcutNewAudio => 'Нова гласовна белешка';
  @override
  String get shortcutToggleSidebar =>
      'Прикажи или скриј го стаблото на датотеките';
  @override
  String get shortcutCloseTab => 'Затвори ја тековната белешка';
  @override
  String get shortcutNextTab => 'Следна отворена белешка';
  @override
  String get shortcutPreviousTab => 'Претходна отворена белешка';
  @override
  String get shortcutEditorSection => 'Во уредникот';
  @override
  String get shortcutFormatSection => 'Форматирање';
  @override
  String get shortcutFind => 'Барај';
  @override
  String get shortcutReplace => 'Најди и замени';
  @override
  String get shortcutSavingNote =>
      'Уредувањата се зачувуваат автоматски, па нема прекица за '
      'зачувување.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Вчитување…';
  @override
  String get noteStatusSaving => 'Зачувување…';
  @override
  String get noteStatusUnsaved => 'Незачувано';
  @override
  String get noteStatusSaved => 'Зачувано';
  @override
  String get noteStatusError => 'Грешка';
  @override
  String get noteNotText =>
      'Оваа датотека не е текстуална белешка, па '
      'Niman не може да ја прикаже тука.';
  @override
  String get noteLoadFailed => 'Оваа белешка не можеше да се отвори.';
  @override
  String wordCount(int count) =>
      count % 10 == 1 && count % 100 != 11 ? '$count збор' : '$count зборови';
  @override
  String get outlineTooltip => 'Содржина';
  @override
  String get outlineNoHeadings => 'Нема наслови';
  @override
  String get outlineNoTitle => '(без наслов)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Поембено';
  @override
  String get toolbarItalic => 'Курсив';
  @override
  String get toolbarStrikethrough => 'Пречртано';

  @override
  String get toolbarHighlight => 'Истакнато';
  @override
  String get toolbarSuperscript => 'Суперскрипт';
  @override
  String get toolbarUnderline => 'Подвлечено';
  @override
  String get toolbarLink => 'Врска';
  @override
  String get toolbarCode => 'Блок код';
  @override
  String get toolbarImage => 'Вметни слика';
  @override
  String get toolbarTable => 'Табела';
  @override
  String get tableRow => 'Ред';
  @override
  String get tableColumn => 'Колона';
  @override
  String get tableAddRowAbove => 'Вметни ред над';
  @override
  String get tableAddRowBelow => 'Вметни ред под';
  @override
  String get tableMoveRowUp => 'Помести го редот нагоре';
  @override
  String get tableMoveRowDown => 'Помести го редот надолу';
  @override
  String get tableDuplicateRow => 'Удвои го редот';
  @override
  String get tableDeleteRow => 'Избриши го редот';
  @override
  String get tableAddColumnLeft => 'Вметни колона лево';
  @override
  String get tableAddColumnRight => 'Вметни колона десно';
  @override
  String get tableMoveColumnLeft => 'Помести ја колоната лево';
  @override
  String get tableMoveColumnRight => 'Помести ја колоната десно';
  @override
  String get tableAlignLeft => 'Порамни лево';
  @override
  String get tableAlignCenter => 'Центрирај';
  @override
  String get tableAlignRight => 'Порамни десно';
  @override
  String get tableDuplicateColumn => 'Удвои ја колоната';
  @override
  String get tableDeleteColumn => 'Избриши ја колоната';
  @override
  String get tableSortAscending => 'Подреди по колона (А → Ш)';
  @override
  String get tableSortDescending => 'Подреди по колона (Ш → А)';
  @override
  String get tableAddRow => 'Додај ред';
  @override
  String get tableAddColumn => 'Додај колона';
  @override
  String get cheatsheetTitle => 'Потсетник за Markdown';
  @override
  String get cheatsheetCopy => 'Копирај';
  @override
  String get cheatsheetCopied => 'Копирано';
  @override
  String get cheatsheetInsert => 'Вметни во белешката';
  @override
  String get cheatsheetWritten => 'Напишано';
  @override
  String get cheatsheetShown => 'Прикажано';
  @override
  String get cheatHeadings => 'Наслови';
  @override
  String get cheatEmphasis => 'Задебелено, курзив, прецртано';
  @override
  String get cheatHtmlFormats => 'Потцртано, горен индекс, долен индекс';
  @override
  String get cheatLists => 'Листи';
  @override
  String get cheatChecklists => 'Листи за проверка';
  @override
  String get cheatQuotes => 'Цитати';

  @override
  String get cheatCallouts => 'Истакнати блокови';
  @override
  String get cheatLinks => 'Врски';
  @override
  String get cheatWikilinks => 'Врски до белешки';
  @override
  String get cheatEmbeds => 'Слики и вградувања';
  @override
  String get cheatTags => 'Ознаки';
  @override
  String get cheatInlineCode => 'Код во реченица';
  @override
  String get cheatCodeBlocks => 'Блокови код';
  @override
  String get cheatMath => 'Математика';
  @override
  String get cheatTables => 'Табели';
  @override
  String get cheatFootnotes => 'Фусноти';
  @override
  String get cheatRule => 'Хоризонтална линија';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Резервирани места во шаблоните';
  @override
  String get menuAddLink => 'Додај врска';
  @override
  String get menuAddExternalLink => 'Додај надворешна врска';
  @override
  String get menuFormat => 'Формат';
  @override
  String get menuParagraph => 'Пасус';
  @override
  String get menuInsert => 'Вметни';
  @override
  String get menuBody => 'Обичен текст';
  @override
  String get formatSubscript => 'Долен индекс';
  @override
  String get formatInlineCode => 'Код';
  @override
  String get insertFootnote => 'Фуснота';
  @override
  String get insertRule => 'Хоризонтална линија';
  @override
  String get insertCodeBlock => 'Блок код';
  @override
  String get insertMathBlock => 'Математички блок';
  @override
  String get menuHeadingWord => 'Наслов';
  @override
  String get toolbarHeading => 'Наслов';
  @override
  String get toolbarList => 'Листа';
  @override
  String get toolbarOrderedList => 'Бројчана листа';
  @override
  String get toolbarChecklist => 'Листа за проверка';
  @override
  String get toolbarQuote => 'Цитат';
  @override
  String get toolbarIndent => 'Вовлечи';
  @override
  String get toolbarOutdent => 'Намали вовлечување';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Алатки';
  @override
  String get editorToolsTitle => 'Алатки на уредувачот';
  @override
  String get toolCountListTitle => 'Изброј список';
  @override
  String get toolCountListSubtitle =>
      'Собира што наведуваат редовите, како список со штиклирање';
  @override
  String get toolCountListNeedsList => 'Оваа белешка нема список за броење';
  @override
  String get tallySourceLabel => 'Список';
  @override
  String get tallyCutLabel => 'Читај го секој ред како';
  @override
  String get tallyCutDash => 'Име - вредности';
  @override
  String get tallyCutColon => 'Име: вредности';
  @override
  String get tallyCutCommas => 'Вредности одделени со запирка';
  @override
  String get tallyCutWhole => 'Целиот ред како една вредност';
  @override
  String get tallySortLabel => 'Редослед';
  @override
  String get tallySortCount => 'Најмногу прво';
  @override
  String get tallySortAlphabetical => 'По азбучен ред';
  @override
  String get tallySortFirstSeen => 'Како се наведени';
  @override
  String get tallyInsert => 'Вметни';
  @override
  String get tallyUpdate => 'Ажурирај';
  @override
  String get tallyNothingToCount => 'Тука нема што да се брои';
  @override
  String get headingDialogTitle => 'Ниво на наслов';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Уредничка лента';
  @override
  String get toolbarSettingsHint =>
      'Влечете за преуредување; окото прикажува или скрие копче.';
  @override
  String get toolbarShowButton => 'Прикажи';
  @override
  String get toolbarHideButton => 'Скриј';
  @override
  String get toolbarResetOrder => 'Врати ги основните';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Прикажи преглед';
  @override
  String get showEditorTooltip => 'Прикажи уредник';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(сурва HTML табела)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Барање белешки';
  @override
  String get searchModeWords => 'Зборови';
  @override
  String get searchModeContains => 'Содержи';
  @override
  String get searchEmptyHint =>
      'Пишете за да барате во библиотеката, или key = value за '
      'филтрирање по frontmatter';
  @override
  String get searchTooShortHint => 'Пишете барем 2 знака';
  @override
  String get searchNoMatches => 'Нема совпаѓања';
  @override
  String get searchLoadMore => 'Прикажи повеќе';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Замени…';
  @override
  String get replaceInNoteAction => 'Замени во оваа белешка…';
  @override
  String get replaceInThisNote => 'Замени во оваа белешка';
  @override
  String get replaceWithLabel => 'Замени со';
  @override
  String get replaceCaseSensitive => 'Разликува големи и мали букви';
  @override
  String get replaceWholeWordsHint =>
      'се заменуваат само точни совпаѓања на цели зборови';
  @override
  String get replaceConfirm => 'Замени';
  @override
  String get replaceCancel => 'Затвори';
  @override
  String get replaceUnavailable => 'Заменувањето моментално не е достапно';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Најди во белешката';
  @override
  String get editorFindHint => 'Најди';
  @override
  String get editorReplaceHint => 'Замени';
  @override
  String get editorFindCaseTooltip => 'Совпаѓање големина на букви';
  @override
  String get editorFindPreviousTooltip => 'Претходно совпаѓање';
  @override
  String get editorFindNextTooltip => 'Следно совпаѓање';
  @override
  String get editorFindCloseTooltip => 'Затвори барање';
  @override
  String get editorFindReplaceModeTooltip => 'Режим на замена';
  @override
  String get editorReplaceOneTooltip => 'Замени го ова совпаѓање';
  @override
  String get editorReplaceAllTooltip => 'Замени ги сите совпаѓања';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Ознаки';
  @override
  String get tagsTitle => 'Оознаки';
  @override
  String get tagsEmpty =>
      'Сè уште нема ознаки — додајте #ознака или tags во frontmatter';
  @override
  String get tagsBackTooltip => 'Назад на барање';
  @override
  String get tagsNotesEmpty => 'Нема белешки со оваа ознака';
  @override
  String tagsNotesCapped(int limit) =>
      'Се наведуваат само првите $limit — барајте ја ознаката за да '
      'сузите';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Врската не е пронајдена';
  @override
  String get headingNotFoundTitle => 'Насловот не е пронајден';
  @override
  String get ambiguousLinkTitle => 'Повеќе белешки совпаѓаат';
  @override
  String get openLinkFailed => 'Не може да се отвори врската';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Белешката не постои';
  @override
  String missingNoteDialogBody(String path) => 'Да се креира „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Папката „$folder“ не постои';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Отворено';
  @override
  String get todoDone => 'Завршено';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Сите датуми';
  @override
  String get todoFilter => 'Филтер';
  @override
  String get todoNoTokens => 'Нема токени во оваа листа';
  @override
  String get todoCountOpen => 'отворено';
  @override
  String get todoCountDone => 'завршено';
  @override
  String get todoEmptyOpen => 'Сè уште нема отворени задачи';
  @override
  String get todoEmptyDone => 'Сè уште ништо не е завршено';
  @override
  String get todoEmptyFiltered => 'Нема задачи што совпаѓаат';
  @override
  String get todoTitle => 'Задачи';
  @override
  String get todoAddTooltip => 'Додај задача';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt формат';
  @override
  String get todoHelpTooltip => 'Помош за форматот';
  @override
  String get todoHelpIntro =>
      'Вашите задачи се една обична текстуална датотека, една задача по '
      'ред. Niman ја пишува синтаксата за вас, но ништо не е скриено: '
      'можете да ја уредувате датотеката во било кој уредник, а Niman ќе '
      'ја прочита назад.';
  @override
  String get todoHelpFilesTitle => 'Две датотеки';
  @override
  String get todoHelpFilesBody =>
      'Отворените задачи се во todo.txt во коренот на библиотеката. '
      'Завршувањето на една го преместува нејзиниот ред во done.txt, па '
      'todo.txt останува краток. Ако завршен ред пак заврши во todo.txt, '
      'Niman ја архивира следниот пат кога ги чита датотеките.';
  @override
  String get todoHelpLineTitle => 'Атомия на ред';
  @override
  String get todoHelpLineBody =>
      'Сè пред описот е опционално и мора да дојде во овој редослед:';
  @override
  String get todoHelpDoneBody =>
      'Ја означува задачата завршена. Niman ја додава кога ќе го '
      'штикнете квадратчето.';
  @override
  String get todoHelpPriority => '(A) до (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Приоритет. A е највисок. Се прикажува како значка во листата.';
  @override
  String get todoHelpDatesBody =>
      'Датум на завршување, па датум на креирање. Со само еден датум тоа '
      'е датум на креирање, освен ако редот не почнува со x.';
  @override
  String get todoHelpTokensTitle => 'Проекти, контексти и ознаки';
  @override
  String get todoHelpTokensBody =>
      'Каде и да е во описот, збор со еден од овие префикси станува чип '
      'со кој можете да филтрирате. Ништо не е унапред дефинирано: '
      'токенот постои чим го напишете.';
  @override
  String get todoHelpProjectBody =>
      'Од што е дел задачата, на пример +градба или +теза.';
  @override
  String get todoHelpContextBody =>
      'Каде или како ќе ја извршите, на пример @дома или @повици.';
  @override
  String get todoHelpHashtagBody =>
      'Слободна ознака, за сè што другите две не го покриваат';
  @override
  String get todoHelpTagsTitle => 'Датуми и подсетници';
  @override
  String get todoHelpTagsBody =>
      'Овие се key:value ознаки. Niman ги пишува од дијалогот на '
      'задачата, и ги чита каде и да се појават во редот.';
  @override
  String get todoHelpDueBody =>
      'Датум на доспевање. Ја води бојата на значката и филтерите за '
      'доспевање.';
  @override
  String get todoHelpRemBody =>
      'Кога да се испрати известување, во ваше локално време. Се пушта и '
      'со исклушен екран и со затворена апликација.';
  @override
  String get todoHelpRemDesktop =>
      'На десктоп, Niman мора да работи кога ќе настане времето: '
      'подсетникот се прикажува додека апликацијата е отворена, а кога е '
      'затворена ништо не се пушта.';
  @override
  String get todoHelpOtherBody =>
      'Се зачувува точно како што е напишано, па ознаките од други todo.txt '
      'апликации го преживуваат вратокот. Niman не делува на нив, rec: '
      'included: повторувачка задача сè уште не се повторува.';
  @override
  String get todoHelpEditTitle => 'Уредување надвор од Niman';
  @override
  String get todoHelpEditBody =>
      'Задача што не сте ја допреале се врати бајт по бајт, вклучувајќи '
      'чудни разминувања. Уредете еден ред, и Niman го преписува само тој '
      'ред во неговата канонска форма, оставајќи го остатокот од '
      'датотеката на мир.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Додај задача';
  @override
  String get todoEditTitle => 'Уреди задача';
  @override
  String get todoDescriptionHint => 'Опис';
  @override
  String get todoCancel => 'Откажи';
  @override
  String get todoSave => 'Зачувај';
  @override
  String get todoEditAction => 'Уреди';
  @override
  String get todoDeleteAction => 'Избриши';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Закасно';
  @override
  String get todoDueToday => 'Денес';
  @override
  String get todoDueNext7 => 'Следните 7 дена';
  @override
  String get todoDueNoDate => 'Без датум';
  @override
  String get todoRowDue => 'Доспевање';
  @override
  String get todoRowDueToday => 'Доспевање денес';
  @override
  String get todoSortTooltip => 'Сортирај';
  @override
  String get todoSortDue => 'Датум на доспевање';
  @override
  String get todoSortPriority => 'Приоритет';
  @override
  String get todoSortCreation => 'Датум на креирање';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Без приоритет';
  @override
  String get todoNoPriorityShort => 'Нема';
  @override
  String get todoMorePriorities => 'Повеќе…';
  @override
  String get todoPriorityTitle => 'Приоритет';
  @override
  String get todoNoDueDate => 'Без датум на доспевање';
  @override
  String get todoNoReminder => 'Без подсетник';
  @override
  String get todoAddProject => '+ Проект';
  @override
  String get todoAddContext => '@ Контекст';
  @override
  String get todoAddHashtag => '# Ознака';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Подсетници за задачи';
  @override
  String get todoReminderChannelDescription =>
      'Распоредени аларми за задачи со време на подсетник.';
  @override
  String get todoReminderBody => 'Подсетник за задача';
  @override
  String get todoReminderFallbackTitle => 'Подсетник за задача';
  @override
  String get todoReminderBlocked =>
      'Известувањата се исклучени, па подсетниците нема да се појават.';
  @override
  String get todoReminderBattery =>
      'Оптимизацијата на батеријата е вклучена за Niman. Системот може да '
      'го стави апликацијата во сон и да ги испусти очекуваните подсетници.';
  @override
  String get todoReminderInexact =>
      'Овој уред не дозволува прецизни аларми, па подсетникот може да '
      'стигне за неколку минути подоцна со исклушен екран.';
  @override
  String get reminderShowTokensTitle => 'Ознаки во известувањата на подсетници';
  @override
  String get reminderShowTokensSubtitle =>
      'Ги зачувува +проект, @контекст и #ознака во текстот на '
      'известувањето. Исклучено прикажува само задача што сте ја наведеле.';
  @override
  String get todoReminderFixAction => 'Отвори поставки';
  @override
  String get todoReminderDismissAction => 'Одбаци';
  @override
  String get todoReminderDue => 'Доспевање';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Откажи';
  @override
  String get actionCreate => 'Креирај';
  @override
  String get actionNew => 'Ново';
  @override
  String get actionSave => 'Зачувај';
  @override
  String get actionClear => 'Исчисти';
  @override
  String get actionChoose => 'Одбери';
  @override
  String get actionDelete => 'Избриши';
  @override
  String get actionRename => 'Промени име';
  @override
  String get actionMove => 'Премести';
  @override
  String get saveAndClose => 'Зачувај и затвори';
  @override
  String get closeUnsavedTitle => 'Незачувани уредувања';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}“ има уредувања што сè уште не се зачувани. '
          'Зачувајте пред затворање?';
    }
    return 'Во ${names.length} белешки има уредувања што сè уште не се '
        'зачувани. Зачувајте ги пред затворање?';
  }

  @override
  String get closeSaveFailed => 'Не може да се зачува; сè уште е отворена.';
  @override
  String get actionRestore => 'Врати';
  @override
  String get actionEmpty => 'Испразни';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Скриј го страничниот панел (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Прикажи го страничниот панел (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Минимизирај';
  @override
  String get windowMaximizeTooltip => 'Максимизирај';
  @override
  String get windowRestoreTooltip => 'Врати';
  @override
  String get windowCloseTooltip => 'Затвори';
  @override
  String get tabFiles => 'Датотеки';
  @override
  String get tabSearch => 'Барај';
  @override
  String get tabSettings => 'Поставки';
  @override
  String get quickNoteTitle => 'Брзо белешко';
  @override
  String get treeEmpty => 'Сè уште нема белешки';
  @override
  String get selectANote => 'Одбери белешка';
  @override
  String get showListTooltip => 'Прикажи листа';
  @override
  String get editRawTooltip => 'Уреди сурово';
  @override
  String get sortAscTooltip => 'Сортирај А-Џ';
  @override
  String get sortDescTooltip => 'Сортирај Џ-А';
  @override
  String get newNoteTitle => 'Нова белешка';
  @override
  String get newItemTooltip => 'Ново';
  @override
  String get closeMenuTooltip => 'Затвори';
  @override
  String get newFolderTitle => 'Нова папка';
  @override
  String get newNoteSameFolder => 'Нова белешка во истата папка';
  @override
  String get newFromTemplateSameFolder => 'Нова од шаблон во истата папка';
  @override
  String trashOriginalPath(String path) => 'беше во $path';
  @override
  String get trashOriginalRoot => 'беше во коренот на библиотеката';
  @override
  String trashItemCount(int count) => count == 1
      ? '1 \u0441\u0442\u0430\u0432\u043a\u0430'
      : '$count \u0441\u0442\u0430\u0432\u043a\u0438';
  @override
  String get newNoteHere => 'Нова белешка овде';
  @override
  String get newFolderHere => 'Нова папка овде';
  @override
  String get newListNoteTitle => 'Нова белешка-листа';
  @override
  String get newListNoteDefault => 'Моја листа';
  @override
  String get setAsQuickNote => 'Постави како брзо белешко';
  @override
  String get currentQuickNote => 'Тековно брзо белешко';
  @override
  String get pinnedSection => 'Заквакани';
  @override
  String pinnedSectionCount(int count) => 'Заквакани · $count';
  @override
  String get templateFolderTitle => 'Папка со шаблони';
  @override
  String get newFromTemplateTitle => 'Ново од шаблон';
  @override
  String get newFromTemplateHere => 'Ново од шаблон овде';
  @override
  String get templateFormTitle => 'Пополни го шаблон';
  @override
  String get templateFormBacklink => 'Поврзано од';
  @override
  String get templateFormNoNote => 'Без белешка';
  @override
  String get templateFormPickNote => 'Одбери белешка';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Места за замена во шаблон';
  @override
  String get templateHelpSubtitle =>
      'Датум, наслов и другите вредности за пополнување';
  @override
  String get quickNoteSubtitle =>
      'Белешката што ја отвора картичката за брза белешка';
  @override
  String get listFolderSubtitle => 'Новите листи на задачи';
  @override
  String get templateFolderSubtitle => 'Изворот на „Ново од шаблон“';
  @override
  String get attachmentsFolderSubtitle => 'Слики и аудио вметнати во белешка';
  @override
  String get templateHelpIntro =>
      'Шаблон е обична белешка со дупки. Креирање белешка од него ја '
      'копира неговата текстуа и ги пополнува дупките.';
  @override
  String get templateHelpUnknown =>
      'Место за замена што Niman не го препознава останува точно како '
      'што е напишано, па грешка во пишувањето се гледа во белешката '
      'наместо да го проголува редот.';
  @override
  String get templateHelpValuesTitle => 'Вредности';
  @override
  String get templateHelpTitleBody => 'Името под кое се креира белешката.';
  @override
  String get templateHelpDateBody =>
      'Денес, и моментално време. Двата земаат формат: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Датум и време заедно.';
  @override
  String get templateHelpUuidBody =>
      'Свеж идентификатор, различен на секоја појава.';
  @override
  String get templateHelpCounterBody =>
      'Број што се зголемува по име, зачуван преку рестарти: првата '
      'белешка пишува 1, следнава 2. Истото име во една белешка пишува '
      'истот број; комбинаирајте со |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Го сместа кацачкото тука кога ќе се креира белешката; маркерот сам '
      'по себе не се пишува. Првиот маркер победува, без филтри, само '
      'нови белешки — и тастатурата се отвора дури и кога автофокусот е '
      'исклучен.';
  @override
  String get templateHelpDatesTitle => 'Пишување датум';
  @override
  String get templateHelpDatesBody =>
      'Овие стојат за делови од датумот во формат. Сè останато е буквално, '
      'и текст во едноставни наводи е исто така буквално. Имената на '
      'месеци и денови следат го јазикот на апликацијата.';
  @override
  String get templateHelpYear => 'година: 2026, 26';
  @override
  String get templateHelpMonth => 'месец: 03, 3, Март, Мар';
  @override
  String get templateHelpDay => 'ден: 09, 9, Понеделник, Пон';
  @override
  String get templateHelpTime => 'часови, минути, секунди';
  @override
  String get templateHelpWeek => 'ISO недела и квартал: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Филтери';
  @override
  String get templateHelpFiltersBody =>
      'Вредноста може да и следат филтери, примени од лево на десно.';
  @override
  String get templateHelpCaseBody =>
      'Големо, мало и прва буква на секој збор — збор што сте го '
      'напишеле сами со голема буква останува на мир.';
  @override
  String get templateHelpSlugBody =>
      'Формата на текст за врски, за градба на wikilink.';
  @override
  String get templateHelpPadBody =>
      'Го одсеци крајот; пополнувај со нули до ширина; користи резерва '
      'кога вредноста е празна.';
  @override
  String get templateHelpShiftBody =>
      'Го поместува датумот за денови, недели, месеци или години — '
      'предавање следната недела, датотека од минатиот месец.';
  @override
  String get templateHelpSnapBody =>
      'Го прицврстува датумот на почетокот или крајот на неговата недела, '
      'месец или година.';
  @override
  String get templateHelpAskTitle => 'Нешто ве прашува';
  @override
  String get templateHelpAskBody =>
      'Форма се појавува пред белешката да се креира, едно поле по '
      'прашање — и едно за повратна врска, кога шаблонот сака едно. '
      'Истата ознака двапати е едно прашање, и негов одговор ги '
      'пополнува сите појави — папка и име датотека вклучени.';
  @override
  String get templateHelpAskFieldBody =>
      'Поле за пишување; текстот по вторите два двојточки е она со што '
      'почнува.';
  @override
  String get templateHelpChoiceBody => 'Избор од листа, разделена со зајди.';
  @override
  String get templateHelpWhereTitle => 'Каде оди белешката';
  @override
  String get templateHelpWhereBody =>
      'Ова не е текст: тоа се упатства, и живеат во niman: блок во самиот '
      'frontmatter на шаблонот. Блокот се почитува и потоа се отстранува, '
      'па никогаш не се појавува во белешката. Нивните вредности може да '
      'содржат места за замена.';
  @override
  String get templateHelpFolderBody =>
      'Папката во која се креира белешката, се прави ако не постои. Без '
      'него, белешката оди таму каде што сте биле.';
  @override
  String get templateHelpFilenameBody =>
      'Кака се вика белешката. Шаблон што го вели тоа не се прашува за '
      'име.';
  @override
  String get templateHelpAppendBody =>
      'Додај во белешката ако таа веќе постои, наместо да направи втора. '
      'Ова го претвора месец од состаноци во една датотека.';
  @override
  String get templateHelpOpenBody =>
      'Што се случува откако белешката постои: уредник (по подразбирање), '
      'преглед или ништо — белешката се подложува и вие останува каде '
      'што сте биле.';
  @override
  String get templateHelpAroundTitle => 'Од каде дојде';
  @override
  String get templateHelpParentBody =>
      'Белешка што ја одбирате во формата, која предлаже она на екранот; '
      'напишете [[{{parent}}]] за врска назад кон неа.';
  @override
  String get templateHelpFolderValueBody => 'Папката во која белешката заврши.';
  @override
  String get templateHelpClipboardBody =>
      'Што е на меѓуспој, и селекцијата на уредник кога белешката е '
      'започната од неа.';
  @override
  String get templateHelpIncludeTitle => 'Повторна употреба на дел';
  @override
  String get templateHelpIncludeBody =>
      'Ја вметнува друг шаблон, па десет шаблони може да делат еден '
      'checklist. Се бара прво во папката на шаблони, и .md може да се '
      'изостави. Неговите прашања се придружуваат на истата форма.';
  @override
  String get templateHelpExampleTitle => 'Сè заедно';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ нема шаблон „$path"';
  @override
  String includeCycle(String path) => '⚠ „$path" го вклучува самото себе';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path" е вгнездено премногу длабоко';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter не е прочитан: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter на „$template" не е прочитан, па неговата папка и '
      'име датотека ништо не сториле: $reason';
  @override
  String get templatePickerTitle => 'Одбери шаблон';
  @override
  String templatePickerEmpty(String folder) =>
      'Сè уште нема шаблони. Ставете белешка во $folder/ и ќе стане еден.';

  // Tree actions.
  @override
  String get actionPin => 'Заквакај';
  @override
  String get actionUnpin => 'Откаквај';
  @override
  String get pinToWidget => 'Заквиј на домашен виджет';
  @override
  String get pinnedForWidget =>
      'Заквиено: сега постави го виджетот Белешка на домашниот екран';
  @override
  String get pinWidgetUnavailable =>
      'Виджетите на домашниот екран се достапни на Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Прикажи во управувачот на датотеки';
  @override
  String get openInDefaultApp => 'Отвори со стандардната апликација';
  @override
  String get newNoteTabTooltip => 'Нова белешка во нов јазичок';
  @override
  String get openNotesTooltip => 'Отворени белешки';
  @override
  String get closeTabTooltip => 'Затвори';
  @override
  String get openInNewTab => 'Отвори во нов јазичок';
  @override
  String get splitRight => 'Подели десно';
  @override
  String get splitDown => 'Подели надолу';
  @override
  String get moveToOtherPane => 'Премести во другиот панел';
  @override
  String get openBeside => 'Отвори странично';
  @override
  String get closeAllNotes => 'Затвори ги сите';
  @override
  String get sidePanelTooltip => 'Прикажи или скриј го страничниот панел';
  @override
  String get historyAllVersions => 'Сите верзии';
  @override
  String get commandPaletteTitle => 'Палета со команди';
  @override
  String get goToNoteTitle => 'Оди на белешка';
  @override
  String get paletteGroupNote => 'Белешка';
  @override
  String get paletteGroupEditor => 'Уредувач';
  @override
  String get paletteGroupView => 'Приказ';
  @override
  String get paletteGroupLibrary => 'Библиотека';
  @override
  String get paletteGroupGoTo => 'Оди на';
  @override
  String get paletteGroupJournal => 'Дневник';
  @override
  String get journalToday => 'Денешен запис';
  @override
  String get journalPrevious => 'Претходен запис';
  @override
  String get journalNext => 'Следен запис';
  @override
  String get commandNeedJournalEntry => 'Потребен е отворен запис од дневникот';
  @override
  String journalCreateAsk(String day) =>
      'Сè уште нема запис за $day. Да се создаде?';
  @override
  String journalTemplateMissing(String path) =>
      'Шаблонот на дневникот $path не можеше да се прочита: записот е '
      'создаден без него.';
  @override
  String get journalIntro =>
      'Една белешка дневно, создадена од шаблон кога тој ден го отвораш прв '
      'пат. Овие поставки патуваат со библиотеката.';
  @override
  String get journalFolderTitle => 'Папка на дневникот';
  @override
  String get journalFolderSubtitle => 'Каде одат записите';
  @override
  String get journalEntryNameTitle => 'Име на записот';
  @override
  String get journalEntryNameSubtitle =>
      'YYYY, MM или M, DD или D за датумот; / создава папка; текстот во '
      "'наводници' останува каков што е";
  @override
  String journalEntryNamePreview(String path) => 'Денешен запис: $path';
  @override
  String get journalEntryNameInvalid =>
      'Потребни се YYYY, месец (MM или M) и ден (DD или D), и ништо што името '
      'на датотека не смее да го содржи';
  @override
  String get journalTemplateTitle => 'Шаблон';
  @override
  String get journalTemplateSubtitle => 'Со што започнува нов запис';
  @override
  String get journalTemplateNone => 'Никој: наслов со датумот';
  @override
  String get journalDayStartTitle => 'Нов ден започнува во';
  @override
  String get journalDayStartSubtitle =>
      'Доцна легнуваш? Во 04:00 ноќта останува на претходниот ден';
  @override
  String get journalRecent => 'Неодамнешни';
  @override
  String get journalNoEntry => 'Нема запис за овој ден';
  @override
  String get journalOpenEntry => 'Отвори';
  @override
  String get journalShowCalendar => 'Прикажи го календарот';
  @override
  String get journalFabToday => 'Денешен запис во дневникот';
  @override
  String journalDueOn(String day) => 'Рок $day';
  @override
  String get commandsTitle => 'Команди';
  @override
  String get commandsIntro =>
      'Палетата со команди нуди само команди што може да се извршат таму каде '
      'што сте. Тука се сите, и кога се појавува секоја.';
  @override
  String get commandsKeysNote =>
      'Тука ништо не се менува. Копчињата се оние поставени во делот '
      '„Тастатурски прецици“ и ја следат секоја промена направена таму.';
  @override
  String get commandsOpenShortcuts =>
      'Промени ги копчињата во делот „Тастатурски прецици“';
  @override
  String get commandsChangeKeyTooltip =>
      'Промени во делот „Тастатурски прецици“';
  @override
  String get commandsSubtitle =>
      'Што може да изврши палетата со команди, и кога';
  @override
  String get keyboardShortcutsSubtitle =>
      'Промени ги копчињата на секоја команда';
  @override
  String get commandNeedNone => 'Секогаш достапно';
  @override
  String get commandNeedOpenNote => 'Потребна е отворена белешка';
  @override
  String get commandNeedTextNote => 'Потребна е отворена текстуална белешка';
  @override
  String get commandNeedWideWindow => 'Само во широк прозорец';
  @override
  String get commandNeedDockRoom =>
      'Потребен е прозорец доволно широк за страничниот панел';
  @override
  String get commandNeedDesktop => 'Само на компјутер';
  @override
  String get commandNeedNotInZen => 'Не во Зен режим';
  @override
  String get commandNeedZenRoom => 'Компјутер, со белешка отворена во јазиче';
  @override
  String get commandNeedPreview => 'Со вклучен преглед, на текстуална белешка';
  @override
  String get commandNeedTwoEditors => 'Со двата вклучени уредувачи';
  @override
  String get paletteHint => 'Барај команди и белешки';
  @override
  String get paletteNoResults => 'Нема совпаѓања';
  @override
  String get paletteCommands => 'Команди';
  @override
  String get paletteNotes => 'Белешки';
  @override
  String get paletteFooter => '↑↓ за движење · ↵ за избор · esc за затворање';
  @override
  String get paletteFooterTouch =>
      'Допрете за да го користите · иглата го држи на врв';
  @override
  String get palettePinned => 'Прикачено';
  @override
  String get palettePin => 'Прикачи';
  @override
  String get paletteUnpin => 'Откачи';
  @override
  String get palettePinFooter => 'alt+P прикачува';
  @override
  String get spellCheckScanning => 'Се проверува белешката…';
  @override
  String get spellCheckAgain => 'Провери повторно';
  @override
  String spellCheckCapped(int count) =>
      'Прикажани се првите $count: поправете неколку, па проверете повторно '
      'за останатите';
  @override
  String get dropHint =>
      'Пуштете Markdown датотеки за да ги отворите или папка за да ја увезете';
  @override
  String get dropNothing =>
      'Работната површина не предаде ниту една датотека при тоа спуштање.';
  @override
  String get importFolderAction => 'Увези';
  @override
  String dropRejected(String names) =>
      'Тука се отвораат само Markdown датотеки и папки: $names';
  @override
  String importFolderTitle(String name) => 'Да се увезе „$name“?';
  @override
  String importFolderBody(int count) =>
      'Нејзините Markdown датотеки ($count) се копираат во нова папка на '
      'библиотеката. Пуштената папка останува каква што е.';
  @override
  String importFolderDone(String folder) => 'Увезено во $folder';
  @override
  String importFolderEmpty(String name) => 'Нема Markdown датотеки во $name';
  @override
  String get openFileTitle => 'Отвори датотека';
  @override
  String get outsideFileNote =>
      'Надвор од библиотека: се зачувува каде што е, без индекс, без '
      'историја, врските не се следат';
  @override
  String get typewriterOn => 'Вклучи режим на машина за пишување';
  @override
  String get typewriterOff => 'Исклучи режим на машина за пишување';
  @override
  String get typewriterTitle => 'Режим на машина за пишување';
  @override
  String get formatNoteTitle => 'Средиго Markdown';
  @override
  String get formatNoteDone => 'Белешката е средена.';
  @override
  String get formatNoteAlreadyTidy => 'Белешката веќе беше средена.';
  @override
  String get tidyOnCloseTitle => 'Средување на Markdown при затворање';
  @override
  String get tidyOnCloseSubtitle =>
      'Кога ќе затворите белешка што сте ја уредувале, нејзиниот Markdown '
      'се средува како со командата „Средиго Markdown“. Белешките поголеми '
      'од 4 МБ остануваат какви што се.';
  @override
  String get typewriterSubtitle =>
      'Редот што го пишувате останува во средината на уредувачот';
  @override
  String get zenMode => 'Зен режим';
  @override
  String get zenModeEnter => 'Влези во зен режим';
  @override
  String get zenModeLeave => 'Излези од зен режим';
  @override
  String get keySpace => 'Празно место';
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
  String get keyArrowUp => 'Горе';
  @override
  String get keyArrowDown => 'Долу';
  @override
  String get keyArrowLeft => 'Лево';
  @override
  String get keyArrowRight => 'Десно';
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
  String get shortcutNone => 'Нема кратенка';
  @override
  String get shortcutRestoreDefaults => 'Врати стандардни';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Да се вратат сите кратенки како ги испорачува Niman?';
  @override
  String get shortcutRevert => 'Врати на стандардната';
  @override
  String get shortcutClear => 'Отстрани кратенка';
  @override
  String get shortcutCapturePrompt =>
      'Притиснете ги копчињата. И Esc и Tab се запишуваат: излезете со Откажи.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Додајте Ctrl, Alt или Meta: едно копче само е за пишување.';
  @override
  String get shortcutMove => 'Премести';
  @override
  String get shortcutUseAnyway => 'Сепак користи';
  @override
  String get shortcutUndo => 'Врати';
  @override
  String get shortcutRedo => 'Повтори';
  @override
  String get shortcutChange => 'Промени кратенка';
  @override
  String shortcutCaptureTitle(String command) => 'Копчиња за „$command“';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys веќе е на „$other“. Да се премести тука? „$other“ ќе остане без '
      'кратенка.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys е и „$what“ во текстуалните полиња и уредувачот. Таму ќе ја '
      'преземе вашата команда.';
  @override
  String get openFileMissing => 'Датотеката на оваа белешка не е на дискот';
  @override
  String get openFileFailed =>
      'Белешката не можеше да се отвори надвор од Niman';
  @override
  String get attachmentUnreadable => 'Оваа датотека не можеше да се прикаже.';
  @override
  String get attachmentMissing => 'Оваа датотека не е на дискот.';
  @override
  String get attachmentOpenFailed =>
      'Датотеката не можеше да се отвори надвор од Niman.';

  @override
  String get movedToTrash => 'Преместено во корпа';
  @override
  String get deletedMessage => 'Избришано';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name ќе биде преместено во .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name ќе биде трајно избришано';
  @override
  String get chooseDestination => 'Одбери одредиште';
  @override
  String get libraryRoot => 'Корен на библиотека';
  @override
  String moveTitle(String name) => 'Премести $name';
  @override
  String headingLevelLabel(int level) => 'Ниво на наслов $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Сè уште нема брзо белешко. Одберте постојана белешка или креирајте '
      'нова — брзото белешко се отвора тука.';
  @override
  String get quickNoteChooseAction => 'Одбери белешка…';
  @override
  String get quickNoteCreateAction => 'Креирај нова белешка…';
  @override
  String get quickNoteNewTitle => 'Ново брзо белешко';
  @override
  String get quickNotePickerTitle => 'Одбери брзо белешко';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Нова папка';
  @override
  String get folderPickerEmpty => 'Сè уште нема папки';
  @override
  String get listFolderTitle => 'Папка на листа';
  @override
  String get attachmentsFolderTitle => 'Папка со прилози';

  // Trash (M1).
  @override
  String get trashEmpty => 'Корпата е празна';
  @override
  String get trashEmptyAction => 'Испразни корпа';
  @override
  String get trashEmptyConfirm =>
      'Ова трајно ги брише сите нешта во папката на корпа, вклучувајќи '
      'предмети што Niman не ги ставил таму.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name ќе биде трајно избришано (без враќање)';
  @override
  String get trashDeletePermanently => 'Избриши трајно';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Отворете папка со Markdown белешки како ваша библиотека';
  @override
  String get openLibraryExisting => 'Отвори постојана';
  @override
  String get openLibraryCreate => 'Креирај нова';
  @override
  String get openLibraryCreateTitle => 'Креирај нова библиотека';
  @override
  String get openLibraryFolderName => 'Име на папка';
  @override
  String get openLibraryChooseFolder => 'Одбери папка на библиотека';
  @override
  String get openLibraryChooseParent =>
      'Одбери папка во која ќе се креира библиотека';
  @override
  String get openLibraryUnsupported =>
      'Таа папка не се поддржува. Одредете папка на складиштето на '
      'уредникот.';
  @override
  String indexingCount(int done, int total) => '$done од $total белешки';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Ваши библиотеки';
  @override
  String get libraryUnreachable => 'Недоступна';
  @override
  String get libraryOpenedToday => 'Отворена денес';
  @override
  String get libraryOpenedYesterday => 'Отворена вчера';
  @override
  String libraryOpenedDaysAgo(int days) => 'Отворена пред $days дена';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Отворена на ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Отвори сега';
  @override
  String get switchLibraryTitle => 'Смени библиотека';
  @override
  String get libraryForget => 'Заборави';
  @override
  String libraryForgetTitle(String name) => 'Заборави „$name"?';
  @override
  String get libraryForgetExplained =>
      'Таа оди од овој список. Папката, белешките и поставките на '
      'библиотеката во неа остануваат на мир, и повторно отворање ја '
      'враќа на место.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Дозволи пристап до датотеките';
  @override
  String get storageAccessNeeded =>
      'Niman не може да ги чита вашите белешки без „пристап до сите '
      'датотеки". Дозволете го за да отворите библиотека.';
  @override
  String get storageAccessExplained =>
      'Niman ги чита вашите белешки како обични датотеки, па Android мора '
      'да го дозволи пристап до сите датотеки. Ништо не се качува, и се '
      'чита само папката на библиотеката што ја одбирате.';
  @override
  String folderAccessDenied(Object error) =>
      'Системот не дал пристап до папката: $error';
  @override
  String folderPickFailed(Object error) => 'Не може да се одбере папка: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Поставки';
  @override
  String get libraryPathTitle => 'Патешка на библиотека';
  @override
  String get reindexTitle => 'Повторно индексирај сега';
  @override
  String get reindexDone => 'Повторно индексирано';
  @override
  String get closeLibraryTitle => 'Затвори библиотека';
  @override
  String get exportLogTitle => 'Извези дневник за откланување грешки';
  @override
  String get exportLogSubtitle =>
      'Зачувај ги забележани настани во датотека што ја одбирате';
  @override
  String get exportLogEmpty =>
      'Буферот на дневник за откланување грешки е празен';
  @override
  String get quickNoteUnset => 'Сè уште не е поставено';
  @override
  String exportLogDone(Object target) => 'Дневникот е извезен во $target';
  @override
  String exportLogFailed(Object error) => 'Извозот не успеа: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Не е пронајдено точно совпаѓање на цел збор „$term"';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Заметени $occurrences појави на „$term" во $notes белешки';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped отворени белешки пропуснати)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Нема точно совпаѓање на цел збор „$term"'
      '${only == null ? 'не е пронајдено' : 'пронајдено во $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'За';
  @override
  String get versionTitle => 'Верзија';
  @override
  String get changelogTitle => 'Дневник на промени';
  @override
  String get changelogEmpty => 'Нема достапни записи во дневникот';
  @override
  String changelogWhatsNew(String version) => 'Ново во верзијата $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Историја';
  @override
  String get noteMenuTooltip => 'Дејства за белешката';
  @override
  String get historyCurrentVersion => 'Тековна верзија';
  @override
  String get historyCurrentSubtitle => 'Белешката каква што е сега';
  @override
  String get historyToday => 'Денес';
  @override
  String get historyYesterday => 'Вчера';
  @override
  String get historyReasonSession => 'пред уредување';
  @override
  String get historyReasonInterval => 'при уредување';
  @override
  String get historyReasonRestore => 'пред враќање';
  @override
  String get historyReasonSync => 'пред синхронизација';
  @override
  String get historyReasonReplace => 'пред замена';
  @override
  String get historyReasonUnknown => 'пронајдена';
  @override
  String get historySyncBase => 'основа за синхронизација';
  @override
  String get historyEmpty =>
      'Сè уште нема верзии. Niman зачувува една кога ќе почнете да ја '
      'уредувате белешката, а потоа најмногу една на секои неколку минути '
      'додека пишувате.';
  @override
  String historyKept(int kept, int limit) => 'Зачувани верзии: $kept од $limit';
  @override
  String get historyBaseKept =>
      'Основата за синхронизација се чува и над ограничувањето.';
  @override
  String get historyOff =>
      'Историјата е исклучена за оваа библиотека (Поставки, Библиотека).';
  @override
  String get historyLoadFailed => 'Не може да се прочита историјата';
  @override
  String get historyCompareSubtitle => 'Споредено со тековната верзија';
  @override
  String get historyTabChanges => 'Промени';
  @override
  String get historyTabVersion => 'Верзија';
  @override
  String get historyNoChanges => 'Ист текст како тековната верзија.';
  @override
  String get historyRestoreAction => 'Врати ја оваа верзија';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Да се врати верзијата зачувана $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Тековниот текст прво се зачувува во историјата, па секогаш можете '
      'да се вратите.';
  @override
  String get historyRestoreConfirm => 'Врати';
  @override
  String historyRestored(String when) => 'Вратена е верзијата зачувана $when';
  @override
  String get historyRestoreFailed => 'Не може да се врати верзијата';
  @override
  String get actionUndo => 'Поништи';
  @override
  String diffLineRange(int start, int end) => 'Редови $start–$end';
  @override
  String diffLineSingle(int line) => 'Ред $line';
  @override
  String diffUnchanged(int count) => count % 10 == 1 && count % 100 != 11
      ? '$count непроменет ред'
      : '$count непроменети редови';
  @override
  String get historyTakeHunk => 'Врати овде';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Врати 1 промена' : 'Врати $count промени';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Избраните промени се враќаат на текстот на оваа верзија. Белешката во '
      'сегашната форма прво се чува како верзија, па ова можеш да го поништиш.';
  @override
  String get historyNoteChangedReloaded =>
      'Белешката се смени додека беше тука — споредбата е освежена.';
  @override
  String get historyVersionsTitle => 'Број на зачувани верзии';
  @override
  String get historyVersionsSubtitle => 'За секоја белешка, во .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Ниедна' : '$count';
  @override
  String get historyIntervalTitle => 'Нова верзија најмногу на секои';
  @override
  String get historyIntervalSubtitle =>
      'Додека пишувате; почнувањето со уредување секогаш зачувува една';
  @override
  String historyIntervalValue(int minutes) => '$minutes мин';
  @override
  String get settingsSectionTranscription => 'Транскрипција';
  @override
  String get transcriptionModelTitle => 'Модел';
  @override
  String get transcriptionModelNone => 'Нема';
  @override
  String get transcriptionLanguageTitle => 'Јазик';
  @override
  String get transcriptionLanguageSubtitle =>
      'Јазикот што се зборува во вашите снимки. Да го наведете е попрецизно '
      'од автоматското препознавање.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Како апликацијата ($language)';
  @override
  String get transcriptionLanguageDetect => 'Препознај автоматски';
  @override
  String get transcriptionModelsTitle => 'Модели за транскрипција';
  @override
  String transcriptionModelsUsed(String size) => 'Зафатено $size';
  @override
  String get transcriptionModelsInstalled => 'Преземени';
  @override
  String get transcriptionModelsDownloading => 'Се преземаат';
  @override
  String get transcriptionModelsAvailable => 'Достапни';
  @override
  String get transcriptionModelsFooter =>
      'Моделите остануваат во складиштето на апликацијата на овој уред. Не се '
      'копираат во библиотеката и не се синхронизираат.';
  @override
  String get transcriptionModelDefault => 'Стандарден';
  @override
  String get transcriptionModelSlow => 'Бавен';
  @override
  String get transcriptionModelHintTiny => 'Најбрз, најмалку прецизен';
  @override
  String get transcriptionModelHintBase =>
      'Добра рамнотежа меѓу брзина и прецизност';
  @override
  String get transcriptionModelHintSmall => 'Попрецизен, околу 3× побавен';
  @override
  String get transcriptionModelHintMedium => 'Многу прецизен, бавен на телефон';
  @override
  String get transcriptionModelHintLarge => 'Најпрецизен, бара многу меморија';
  @override
  String get transcriptionModelDownload => 'Преземи';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Да се избрише моделот $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Ќе се ослободат $size. Моделот можете повторно да го преземете '
      'подоцна.';
  @override
  String get transcriptionModelFailed =>
      'Преземањето не успеа. Проверете ја врската и обидете се повторно.';
  @override
  String get actionRetry => 'Обиди се повторно';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Врската е прекината, нов обид…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Паузирано на $progress';
  @override
  String get actionResume => 'Продолжи';
  @override
  String get audioTranscribe => 'Транскрибирај';
  @override
  String get audioTranscribeUnsupported => 'На овој уред само WAV снимки';
  @override
  String get transcriptionQueued => 'Во редица';
  @override
  String get transcriptionPreparing => 'Се подготвува звукот…';
  @override
  String transcriptionRunning(int percent) => 'Транскрипција… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Се презема $model · $percent%';
  @override
  String get transcriptionSaved => 'Транскрипцијата е додадена во описот';
  @override
  String get transcriptionNoSpeech => 'Во оваа снимка не е препознаен говор';
  @override
  String get transcriptionFailed => 'Транскрипцијата не успеа';
  @override
  String get transcriptionPickModelTitle => 'Изберете модел';
  @override
  String get transcriptionPickModelBody =>
      'Транскрипцијата се извршува на овој уред и снимката никогаш не се '
      'испраќа. Моделот се презема само еднаш.';
  @override
  String get transcriptionPickModelAction => 'Преземи и транскрибирај';
  @override
  String get transcriptionModelRecommended => 'Препорачано';
  @override
  String get transcriptionExistingTitle => 'Оваа снимка веќе има опис';
  @override
  String get transcriptionExistingBody =>
      'Да се замени со транскрипцијата или транскрипцијата да се додаде '
      'подолу?';
  @override
  String get transcriptionAppend => 'Додај подолу';
  @override
  String get transcriptionReplace => 'Замени';
  @override
  String get settingsSectionSync => 'Синхронизација';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Не е поставена за оваа библиотека';
  @override
  String get syncNeverSynced => 'Никогаш не е синхронизирана';
  @override
  String syncLastSynced(String when) => 'Синхронизирана $when';
  @override
  String get syncRunning => 'Се синхронизира…';
  @override
  String syncScreenSubtitle(String library) => 'Библиотека $library';
  @override
  String get syncUrlLabel => 'Адреса на папката';
  @override
  String get syncUrlRequired => 'Внесете ја адресата на серверот';
  @override
  String get syncUrlHint =>
      'Папката мора да постои. Копирајте ја адресата како што ја '
      'прикажува серверот.';
  @override
  String get syncHttpWarning =>
      'Нешифрирана врска: во ред е преку VPN или во локална '
      'мрежа.';
  @override
  String get syncUserLabel => 'Корисник';
  @override
  String get syncUserHint =>
      'Оставете празно ако серверот не бара податоци за најава.';
  @override
  String get syncPasswordLabel => 'Лозинка';
  @override
  String get syncPasswordHint =>
      'Се чува во складиштето за клучеви на уредот, никогаш во '
      'датотеките на библиотеката.';
  @override
  String get syncPasswordKeepHint =>
      'Оставете празно за да ја задржите зачуваната лозинка.';
  @override
  String get syncShowPassword => 'Прикажи лозинка';
  @override
  String get syncHidePassword => 'Скриј лозинка';
  @override
  String get syncTestAction => 'Тестирај врска';
  @override
  String get syncTesting => 'Се тестира…';
  @override
  String get syncRetargetWarning =>
      'Со нова адреса или корисник, следната синхронизација '
      'почнува од почеток како прва.';
  @override
  String get syncTestOk => 'Врската работи';
  @override
  String get syncModeFull => 'Целосен режим';
  @override
  String get syncModeCompatible => 'Компатибилен режим';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Читање, запишување и бришење';
  @override
  String get syncCapEtags => 'Отпечатоци на датотеки (ETag)';
  @override
  String get syncCapNoEtags => 'Без отпечатоци на датотеки (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Ги споредува големината и датумот; при сомнеж презема '
      'повторно';
  @override
  String get syncCapGuarded => 'Заштитено запишување';
  @override
  String get syncCapUnguarded => 'Незаштитено запишување';
  @override
  String get syncCapUnguardedDetail =>
      'Ја проверува датотеката на серверот непосредно пред '
      'запишување';
  @override
  String get syncCapMove => 'Преименува без повторно качување';
  @override
  String get syncCapNoMove => 'Без преименување на серверот';
  @override
  String get syncCapNoMoveDetail =>
      'Преименувањето станува бришење и ново качување';
  @override
  String get syncCompatibleNote =>
      'Во компатибилен режим синхронизацијата работи исто, со '
      'малку повеќе барања.';
  @override
  String get syncTestInvalidUrl => 'Невалидна адреса';
  @override
  String get syncTestInvalidUrlHint =>
      'Внесете адреса http:// или https://, без корисник и '
      'лозинка во неа.';
  @override
  String get syncTestOffline => 'Серверот не е достапен';
  @override
  String get syncTestOfflineHint =>
      'Дали VPN е вклучен? Адреса 10.x или 192.168.x работи само '
      'од истата мрежа.';
  @override
  String get syncTestAuth => 'Корисникот или лозинката се одбиени';
  @override
  String get syncTestAuthHint => 'Проверете ги, па тестирајте повторно.';
  @override
  String get syncTestNotFound => 'Папката не постои';
  @override
  String get syncTestNotFoundHint =>
      'Создајте ја на серверот или поправете ја адресата.';
  @override
  String get syncTestUnsupported => 'Не е WebDAV папка';
  @override
  String get syncTestUnsupportedHint => 'Серверот одговара, но не како WebDAV.';
  @override
  String get syncTestFailed => 'Тестот не успеа';
  @override
  String get syncNowAction => 'Синхронизирај сега';
  @override
  String get syncSectionServer => 'Сервер';
  @override
  String get syncServerRow => 'Адреса, корисник и лозинка';
  @override
  String get syncRetestTitle => 'Тестирај го серверот повторно';
  @override
  String syncProbedAgo(String when) => 'Последен тест $when';
  @override
  String get syncDisconnectTitle => 'Исклучи ја оваа библиотека';
  @override
  String get syncDisconnectSubtitle =>
      'Датотеките остануваат тука и на серверот';
  @override
  String get syncDisconnectConfirmTitle => 'Да се исклучи синхронизацијата?';
  @override
  String get syncDisconnectConfirmBody =>
      'Оваа библиотека престанува да се синхронизира на овој '
      'уред. Ниедна датотека не се брише, ни тука ни на '
      'серверот. Ако повторно ја поврзете, првата синхронизација '
      'почнува од почеток.';
  @override
  String get syncDisconnectConfirm => 'Исклучи';
  @override
  String get syncFirstTitle => 'Прва синхронизација';
  @override
  String get syncFirstIntro =>
      'Библиотеката е споредена со папката на серверот:';
  @override
  String get syncFirstUpload => 'За качување';
  @override
  String get syncFirstDownload => 'За преземање';
  @override
  String get syncFirstBoth => 'На двете страни';
  @override
  String get syncFirstBothHint => 'Исти: без пренос. Различни: за решавање';
  @override
  String get syncFirstNoDelete =>
      'Првата синхронизација не брише ништо, ни тука ни на '
      'серверот.';
  @override
  String get syncStartAction => 'Започни';
  @override
  String syncMassTrashTitle(int count) =>
      'Да се преместат датотеки во корпата ($count)?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'На серверот недостасуваат $count од $total синхронизирани '
      'датотеки. Тоа обично значи погрешна адреса, немонтиран '
      'NAS диск или папка испразнета по грешка.';
  @override
  String get syncMassTrashHint =>
      'Ако навистина сте ги избришале на друг уред, потврдете: '
      'тука одат во корпата.';
  @override
  String get syncMassTrashConfirm => 'Премести во корпа';
  @override
  String syncMassDeleteTitle(int count) =>
      'Да се избришат датотеки од серверот ($count)?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Тука недостасуваат $count од $total синхронизирани '
      'датотеки. Ако не сте ги избришале, откажете и проверете '
      'ја папката на библиотеката.';
  @override
  String get syncMassDeleteConfirm => 'Избриши од серверот';
  @override
  String get syncTooltip => 'Синхронизирај';
  @override
  String get syncStageConnecting => 'Поврзување со серверот…';
  @override
  String get syncStageComparing => 'Споредување со серверот…';
  @override
  String syncStageApplying(int done, int total) =>
      'Синхронизација · $done од $total';
  @override
  String get syncStatusWarnings => 'Синхронизирана со предупредувања';
  @override
  String syncConflictsHeader(int count) =>
      'Променети тука и на серверот · $count';
  @override
  String get syncConflictHint => 'Ниедна верзија не е допрена';
  @override
  String get syncResolveAction => 'Реши';
  @override
  String syncFailuresHeader(int count) => 'Не се синхронизирани · $count';
  @override
  String get syncFailuresHint => 'Нов обид при следната синхронизација';
  @override
  String get syncAbortAuth => 'Серверот ја одби лозинката';
  @override
  String get syncAbortMissingPassword => 'Нема зачувана лозинка';
  @override
  String get syncAbortOffline => 'Серверот не е достапен';
  @override
  String get syncAbortRemoteMissing => 'Папката на серверот повеќе не постои';
  @override
  String get syncAbortUnsupported => 'Серверот повеќе не работи како WebDAV';
  @override
  String get syncAbortFailed => 'Синхронизацијата не успеа';
  @override
  String get syncAbortNotConfirmed => 'Синхронизацијата е откажана';
  @override
  String get syncAbortNothingTouched =>
      'Ниедна датотека не е допрена. Вашите промени остануваат '
      'тука до следната успешна синхронизација.';
  @override
  String syncLastSuccess(String when) =>
      'Последна успешна синхронизација $when';
  @override
  String get syncNoSuccessYet => 'Сè уште нема успешна синхронизација';
  @override
  String get syncUpdatePasswordAction => 'Ажурирај лозинка';
  @override
  String get syncRetryAction => 'Обиди се повторно';
  @override
  String get syncOpenSettingsAction => 'Поставки';
  @override
  String get syncCloseAction => 'Затвори';
  @override
  String get syncDoneSnack => 'Синхронизирана';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Синхронизирана · $count датотека избришана на друго место '
            'е во корпата'
      : 'Синхронизирана · $count датотеки избришани на друго место '
            'се во корпата';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Синхронизирана · $count конфликт за решавање'
      : 'Синхронизирана · $count конфликти за решавање';
  @override
  String get syncShowAction => 'Прикажи';
  @override
  String get syncConflictTitle => 'Реши конфликт';
  @override
  String get syncConflictBinary =>
      'Не е текстуална датотека: изберете која копија да ја '
      'задржите.';
  @override
  String get syncConflictKeepNote =>
      'Копијата што не ја задржувате останува во историјата на '
      'белешката.';
  @override
  String get syncKeepLocal => 'Задржи ја од овој уред';
  @override
  String get syncKeepRemote => 'Задржи ја од серверот';
  @override
  String get syncConflictLoadFailed => 'Не може да се прочитаат двете верзии';
  @override
  String get syncResolveFailed => 'Не може да се реши конфликтот';
  @override
  String get syncResolved => 'Конфликтот е решен';
  @override
  String get syncConflictMoved =>
      'Една од верзиите во меѓувреме се промени: конфликтот е повторно '
      'вчитан, изберете повторно.';
  @override
  String get syncSectionWhen => 'Кога да се синхронизира';
  @override
  String get syncAutoTitle => 'Автоматски';
  @override
  String get syncAutoSubtitle => 'По уредувања, при отворање и на интервали';
  @override
  String get syncIntervalTitle => 'Проверувај го серверот на секои';
  @override
  String get syncIntervalSubtitle => 'Само додека апликацијата е отворена';
  @override
  String get syncIntervalDialogBody =>
      'За да ги гледате промените направени на други уреди додека апликацијата '
      'е отворена. Со „Никогаш“ — само по уредувања и при отворање.';
  @override
  String syncIntervalMinutes(int count) =>
      count % 10 == 1 && count % 100 != 11 ? '$count минута' : '$count минути';
  @override
  String get syncIntervalNever => 'Никогаш';
  @override
  String get syncWifiOnlyTitle => 'Само преку Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Со мобилни податоци синхронизирај само рачно';
  @override
  String syncPendingChanges(int count) => count % 10 == 1 && count % 100 != 11
      ? '$count промена чека'
      : '$count промени чекаат';
  @override
  String syncRetryIn(String wait) => 'нов обид за $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds с';
  @override
  String syncWaitMinutes(int minutes) => '$minutes мин';
  @override
  String get syncWaitingForWifi => 'Се чека Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Се чека врска';
  @override
  String get syncMobileDataHint =>
      '„Синхронизирај сега“ сепак користи мобилни податоци.';
  @override
  String get syncQueueKeptHint =>
      'Промените остануваат тука, дури и ако ја затворите апликацијата, и '
      'заминуваат сами кога серверот ќе одговори.';
  @override
  String get syncAutoPaused => 'Автоматската синхронизација е паузирана';
  @override
  String get syncPausedAuthHint =>
      'Продолжува кога ќе ја ажурирате лозинката или ќе синхронизирате рачно.';
  @override
  String get syncPausedServerHint =>
      'Продолжува кога ќе ја поправите адресата или ќе синхронизирате рачно.';
  @override
  String get syncPausedConfirmHint =>
      '„Синхронизирај сега“ покажува што би било отстрането и прво прашува.';
  @override
  String get syncNeedsConfirmation => 'Се чека вашата потврда';
  @override
  String get syncMergeIntro =>
      'Измените што не се преклопуваат се веќе споени; таму каде што се '
      'преклопуваат, изберете што да задржите.';
  @override
  String get syncMergeClean =>
      'Двете верзии се спојуваат сами: ништо не се преклопува.';
  @override
  String get syncMergeNoBase =>
      'Нема заедничка верзија за спојување: каде и да се разликуваат двете '
      'копии, избирате вие.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Преклопување $index од $total';
  @override
  String get syncMergeFromLocal => 'Од овој уред';
  @override
  String get syncMergeFromRemote => 'Од серверот';
  @override
  String get syncMergeRemovedLines => 'Отстранети редови';
  @override
  String get syncMergeAbsentLines => 'Ги нема во оваа копија';
  @override
  String get syncMergeKeepLocal => 'Моите';
  @override
  String get syncMergeKeepRemote => 'На серверот';
  @override
  String get syncMergeKeepBoth => 'И двете';
  @override
  String get syncMergeSave => 'Зачувај го спојувањето';
  @override
  String get syncMergeKeepWhole => 'Или задржете една цела копија';
}
