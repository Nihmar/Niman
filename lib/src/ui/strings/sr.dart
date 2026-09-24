// The Serbian strings (Cyrillic).
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class SerbianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'јануар',
    'фебруар',
    'март',
    'април',
    'мај',
    'јун',
    'јул',
    'август',
    'септембар',
    'октобар',
    'новембар',
    'децембар',
  ];
  @override
  List<String> get monthNamesShort => const [
    'јан',
    'феб',
    'мар',
    'апр',
    'мај',
    'јун',
    'јул',
    'авг',
    'сеп',
    'окт',
    'нов',
    'дек',
  ];
  @override
  List<String> get weekdayNames => const [
    'понедељак',
    'уторак',
    'среда',
    'четвртак',
    'петак',
    'субота',
    'недеља',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'пон',
    'уто',
    'сре',
    'чет',
    'пет',
    'суб',
    'нед',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Кош';
  @override
  String get trashSubtitle =>
      'Обрисани елементи се премештају у .trash/ (искључено = трајно '
      'брисање)';
  @override
  String get trashAutoEmptyTitle => 'Аутоматско пражњење коша';
  @override
  String get trashAutoEmptySubtitle =>
      'Старија брисања нестају заувек при отварању библиотеке';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Никад'
      : switch ((days % 10, days % 100)) {
          (1, != 11) => '$days дан',
          _ => '$days дана',
        };
  @override
  String get debugLogsTitle => 'Дневници за отклањање грешака';
  @override
  String get debugLogsSubtitle =>
      'Бележи догађаје апликације у меморијском буферу';
  @override
  String get lineNumbersTitle => 'Бројеви редова';
  @override
  String get lineNumbersSubtitle =>
      'Приказује колону бројева редова у уредитељу';
  @override
  String get readableLineLengthTitle => 'Читљива дужина реда';
  @override
  String get readableLineLengthSubtitle =>
      'Текст белешке држи у центрираној колони уместо преко целе ширине '
      'прозора';
  @override
  String get noteColumnWidthTitle => 'Ширина колоне';
  @override
  String get noteColumnWidthSubtitle =>
      'Колико је широка колона белешке, у пикселима';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Тастатура при отварању';
  @override
  String get keyboardOnOpenSubtitle =>
      'Приказује тастатуру чим се белешка отвори (искључено = по првом '
      'додиром)';
  @override
  String get editorKindSource => 'Markdown извор';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown извор, како је написано';
  @override
  String get editorKindWysiwygSubtitle =>
      'Форматирани текст, уређује се директно';
  @override
  String get settingsFolderToCreate => 'за прављење';
  @override
  String get settingsSearchHint => 'Претражи поставке';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 пронађена поставка' : '$count пронађених поставки';
  @override
  String get settingsToggleOn => 'Укључено';
  @override
  String get settingsToggleOff => 'Искључено';
  @override
  String get switchToWysiwygTooltip => 'Пређи на WYSIWYG уредитељ';
  @override
  String get switchToSourceTooltip => 'Пређи на Markdown извор';
  @override
  String get switchToSourceLabel => 'Извор';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Изглед';
  @override
  String get settingsSectionEditor => 'Уредитељ';
  @override
  String get settingsSectionLibrary => 'Библиотека';
  @override
  String get settingsSectionReminders => 'Подсећања';
  @override
  String get settingsSectionShortcuts => 'Тастатура';
  @override
  String get keyboardShortcutsTitle => 'Пречице на тастатури';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Библиотека $name';
  @override
  String get settingsGroupLibraryHint => 'важи само за ову библиотеку';
  @override
  String get settingsGroupMaintenance => 'Одржавање';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Фасцикле и путање';
  @override
  String get settingsAreaTrashHistory => 'Кош и хронологија';
  @override
  String get settingsAreaDiagnostics => 'Дијагностика и инфо';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Потребна је повезана физичка тастатура';
  @override
  String get settingsSectionUpdates => 'Ажурирања';
  @override
  String get autoUpdateTitle => 'Аутоматска ажурирања';
  @override
  String get autoUpdateSubtitle =>
      'Проверава GitHub Releases при покретању и сваких 6 сати';
  @override
  String get checkForUpdatesTitle => 'Провери ажурирања';
  @override
  String updateAvailableMessage(Object version) => 'Доступан је Niman $version';
  @override
  String get updateUpToDate => 'Niman је ажуран';
  @override
  String get updateCheckFailed => 'Провера ажурирања није успела';
  @override
  String updateSavedTo(Object path) => 'Ажурирање сачувано у $path';
  @override
  String get updateInstallerStarted => 'Инсталер је покренут';
  @override
  String get settingsSectionDiagnostics => 'Диагностика';
  @override
  String get settingsSpellCheckTitle => 'Провера правописа';
  @override
  String get settingsSpellCheckSubtitle =>
      'Подвлачи погрешно писане речи док пишете.';
  @override
  String get spellCheckDictionaryTitle => 'Речник';
  @override
  String get spellCheckDictionarySystem => 'Подразумевани системски';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Изабери речнике';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Изаберите сваки језик на коме је ова библиотека написана. Реч '
      'пролази када један изабраних речника препознаје; без изабраних '
      'одлучује системски језик.';
  @override
  String get spellCheckNoDictionaries =>
      'Ниједан речник није пронађен на овом систему.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Провера правописа';
  @override
  String get spellCheckTitle => 'Правопис';
  @override
  String get spellCheckEmpty => 'Нема грешака у правопису.';
  @override
  String get spellCheckUnavailable =>
      'hunspell није инсталиран на овом систему.';
  @override
  String get spellCheckNoSuggestions => 'Нема предлога';
  @override
  String spellCheckCount(int count) => '$count за преглед';
  @override
  String spellCheckLine(int line) => 'ред $line';
  @override
  String get addWordToDictionary => 'Додај у речник';

  @override
  String indentWidthValue(int spaces) => '$spaces размака';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Осветљење';
  @override
  String get themeBrightnessSubtitle =>
      'Светла, тамна или онакво као што је уређај подешен';
  @override
  String get themeBrightnessSystem => 'Систем';
  @override
  String get themeBrightnessDay => 'Светла';
  @override
  String get themeBrightnessNight => 'Тамна';
  @override
  String get themeTitle => 'Тема';
  @override
  String get themeSubtitle => 'Боје сучеља и белешке';
  @override
  String get themePaletteSystem => 'Систем';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Теме';
  @override
  String get themesInUse => 'У употреби';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Нова тема';
  @override
  String get themeNewName => 'Назив';
  @override
  String get themeNewStartFrom => 'Почетак од';
  @override
  String get themeNewRandom => 'Случајне боје';
  @override
  String get themeNameTaken => 'Већ постоји тема са тим именом';
  @override
  String themeDeleteBody(String name) =>
      'Обрисати „$name“? Његове боје нестају заувек.';
  @override
  String get themeDuplicate => 'Дуплирај';
  @override
  String get themeMenuTooltip => 'Радње за тему';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Уреди';
  @override
  String get themeEditorTitle => 'Уреди тему';
  @override
  String get themeEditorChrome => 'Сучеље';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Листе задатака (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Свака боја носи име које користи извезена датотека';
  @override
  String get themeEditorDiscardTitle => 'Одбаци измене';
  @override
  String get themeEditorDiscardBody => 'Боје које сте изменили нису сачуване';
  @override
  String get themeEditorDiscard => 'Одбаци';
  @override
  String get themeEditorBadColor => 'Користи #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Извези';
  @override
  String themeExportDone(String where) => 'Тема извезена у $where';
  @override
  String themeFileFailed(String error) =>
      'Тему није било могуће пренети: $error';
  @override
  String get themeImport => 'Увези';
  @override
  String get themeImportInvalid => 'Ова датотека није Niman тема';
  @override
  String themeImportVersion(int version) =>
      'Ова тема је из новијег Niman-а (верзија $version)';
  @override
  String themeImportBadRole(String role) => 'Датотека не даје боју за „$role“';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Величина текста сучеља';
  @override
  String get uiTextScaleSubtitle =>
      'Стабло, картице и дијалоги; изнад системског подешавања';
  @override
  String get noteTextScaleTitle => 'Величина текста белешке';
  @override
  String get noteTextScaleSubtitle =>
      'Уредитељ и преглед, који су увек у складу';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Формат везе';
  @override
  String get linkTypeSubtitle => 'Шта тастер за везе у уредитељу уметне';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Креирање недостајућих белешки у';
  @override
  String get missingNoteLocationRoot => 'Корен библиотеке';
  @override
  String get missingNoteLocationCurrentFolder => 'Тренутна фасцикла';
  @override
  String get indentWidthTitle => 'Ширина уступа';
  @override
  String get indentWidthSubtitle =>
      'Размака који се додаје по нивоу уступа у уредитељу';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Језик';
  @override
  String get languageSubtitle => 'Језик текста саме апликације';
  @override
  String get languageSystem => 'Систем';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Додај ставку';
  @override
  String get listAddTooltip => 'Додај ставку';
  @override
  String get listEmpty => 'Још нема ставки';
  @override
  String get listDragHandleLabel => 'Преређуј ставку';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Још нема снимака';
  @override
  String get audioRecord => 'Сними';
  @override
  String get audioStop => 'Заустави';
  @override
  String get audioPlay => 'Пусти';
  @override
  String get audioDelete => 'Обриши снимак';
  @override
  String get audioImport => 'Увези аудио фајл';
  @override
  String get audioRecording => 'Снимање…';
  @override
  String get audioPermissionDenied =>
      'Дозвола за микрофон је одбијена — потребна је за снимање.';
  @override
  String get newAudioNoteTitle => 'Нова гласовна белешка';
  @override
  String get newAudioNoteDefault => 'Мој снимак';
  @override
  String get showAudioTooltip => 'Прикажи снимке';
  @override
  String get audioMessageHint => 'Напишите белешку…';
  @override
  String get audioSend => 'Пошаљи';
  @override
  String get audioRename => 'Промени име снимка';
  @override
  String get audioDescriptionHint => 'Опишите овај снимак…';
  @override
  String get audioEditDescription => 'Уреди опис';
  @override
  String get audioDeleteNote => 'Обриши белешку';
  @override
  String get audioEditNote => 'Уреди белешку';
  @override
  String get audioPause => 'Пауза';
  @override
  String get audioEditTitle => 'Уреди наслов';
  @override
  String get audioTitleHint => 'Наслов овог снимка…';
  @override
  String audioUntitled(int n) => 'Снимак $n';
  @override
  String get audioMoreActions => 'Још радњи';
  @override
  String get audioDiscardRecording => 'Одбаци снимак';
  @override
  String get audioPauseRecording => 'Паузирај снимање';
  @override
  String get audioResumeRecording => 'Настави снимање';
  @override
  String get audioRecordingPaused => 'Паузирано';
  @override
  String get audioSavingRecording => 'Чување…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Брза белешка';
  @override
  String get trayOpen => 'Отвори Niman';
  @override
  String get trayQuit => 'Изађи';
  @override
  String get closeToTrayTitle => 'Затвори у траку обавештења';
  @override
  String get closeToTraySubtitle =>
      '× прозора скрива Niman и оставља га покренутим, па подсетници и даље '
      'долазе. Излази се из менија иконе.';
  @override
  String get shortcutNewTodo => 'Нов задатак';
  @override
  String get shortcutNewNote => 'Нова белешка';
  @override
  String get shortcutNewList => 'Нов списак';
  @override
  String get shortcutNewAudio => 'Нова гласовна белешка';
  @override
  String get shortcutToggleSidebar => 'Прикажи или сакриј стабло датотека';
  @override
  String get shortcutCloseTab => 'Затвори тренутну белешку';
  @override
  String get shortcutNextTab => 'Следећа отворена белешка';
  @override
  String get shortcutPreviousTab => 'Претходна отворена белешка';
  @override
  String get shortcutEditorSection => 'У уредитељу';
  @override
  String get shortcutFormatSection => 'Обликовање';
  @override
  String get shortcutFind => 'Претрага';
  @override
  String get shortcutReplace => 'Пронађи и замени';
  @override
  String get shortcutSavingNote =>
      'Измене се аутоматски сачувају, па нема пречице за чување.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Учитавање…';
  @override
  String get noteStatusSaving => 'Чување…';
  @override
  String get noteStatusUnsaved => 'Несачувано';
  @override
  String get noteStatusSaved => 'Сачувано';
  @override
  String get noteStatusError => 'Грешка';
  @override
  String get noteNotText =>
      'Ова датотека није текстуална белешка, па је '
      'Niman не може приказати овде.';
  @override
  String get noteLoadFailed => 'Ова белешка није могла да се отвори.';
  @override
  String wordCount(int count) =>
      count % 10 == 1 && count % 100 != 11 ? '$count реч' : '$count речи';
  @override
  String get outlineTooltip => 'Садржај';
  @override
  String get outlineNoHeadings => 'Нема наслова';
  @override
  String get outlineNoTitle => '(без наслова)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Подебљано';
  @override
  String get toolbarItalic => 'Курсиво';
  @override
  String get toolbarStrikethrough => 'Пречртано';

  @override
  String get toolbarHighlight => 'Истакнуто';
  @override
  String get toolbarSuperscript => 'Суперскрипт';
  @override
  String get toolbarUnderline => 'Подвучено';
  @override
  String get toolbarLink => 'Веза';
  @override
  String get toolbarCode => 'Блок кода';
  @override
  String get toolbarImage => 'Уметни слику';
  @override
  String get toolbarTable => 'Табела';
  @override
  String get tableRow => 'Ред';
  @override
  String get tableColumn => 'Колона';
  @override
  String get tableAddRowAbove => 'Уметни ред изнад';
  @override
  String get tableAddRowBelow => 'Уметни ред испод';
  @override
  String get tableMoveRowUp => 'Помери ред горе';
  @override
  String get tableMoveRowDown => 'Помери ред доле';
  @override
  String get tableDuplicateRow => 'Дуплирај ред';
  @override
  String get tableDeleteRow => 'Обриши ред';
  @override
  String get tableAddColumnLeft => 'Уметни колону лево';
  @override
  String get tableAddColumnRight => 'Уметни колону десно';
  @override
  String get tableMoveColumnLeft => 'Помери колону лево';
  @override
  String get tableMoveColumnRight => 'Помери колону десно';
  @override
  String get tableAlignLeft => 'Поравнај лево';
  @override
  String get tableAlignCenter => 'Центрирај';
  @override
  String get tableAlignRight => 'Поравнај десно';
  @override
  String get tableDuplicateColumn => 'Дуплирај колону';
  @override
  String get tableDeleteColumn => 'Обриши колону';
  @override
  String get tableSortAscending => 'Сортирај по колони (А → Ш)';
  @override
  String get tableSortDescending => 'Сортирај по колони (Ш → А)';
  @override
  String get tableAddRow => 'Додај ред';
  @override
  String get tableAddColumn => 'Додај колону';
  @override
  String get cheatsheetTitle => 'Подсетник за Markdown';
  @override
  String get cheatsheetCopy => 'Копирај';
  @override
  String get cheatsheetCopied => 'Копирано';
  @override
  String get cheatsheetInsert => 'Уметни у белешку';
  @override
  String get cheatsheetWritten => 'Написано';
  @override
  String get cheatsheetShown => 'Приказано';
  @override
  String get cheatHeadings => 'Наслови';
  @override
  String get cheatEmphasis => 'Подебљано, курзив, прецртано';
  @override
  String get cheatHtmlFormats => 'Подвучено, експонент, индекс';
  @override
  String get cheatLists => 'Листе';
  @override
  String get cheatChecklists => 'Контролне листе';
  @override
  String get cheatQuotes => 'Цитати';

  @override
  String get cheatCallouts => 'Истакнути блокови';
  @override
  String get cheatLinks => 'Везе';
  @override
  String get cheatWikilinks => 'Везе ка белешкама';
  @override
  String get cheatEmbeds => 'Слике и уграђивања';
  @override
  String get cheatTags => 'Ознаке';
  @override
  String get cheatInlineCode => 'Кôд у реченици';
  @override
  String get cheatCodeBlocks => 'Блокови кôда';
  @override
  String get cheatMath => 'Математика';
  @override
  String get cheatTables => 'Табеле';
  @override
  String get cheatFootnotes => 'Фусноте';
  @override
  String get cheatRule => 'Хоризонтална линија';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Чувари места у шаблонима';
  @override
  String get menuAddLink => 'Додај везу';
  @override
  String get menuAddExternalLink => 'Додај спољну везу';
  @override
  String get menuFormat => 'Формат';
  @override
  String get menuParagraph => 'Пасус';
  @override
  String get menuInsert => 'Уметни';
  @override
  String get menuBody => 'Обичан текст';
  @override
  String get formatSubscript => 'Индекс';
  @override
  String get formatInlineCode => 'Кôд';
  @override
  String get insertFootnote => 'Фуснота';
  @override
  String get insertRule => 'Хоризонтална линија';
  @override
  String get insertCodeBlock => 'Блок кôда';
  @override
  String get insertMathBlock => 'Математички блок';
  @override
  String get menuHeadingWord => 'Наслов';
  @override
  String get toolbarHeading => 'Наслов';
  @override
  String get toolbarList => 'Списак';
  @override
  String get toolbarOrderedList => 'Бројчани списак';
  @override
  String get toolbarChecklist => 'Контролна листа';
  @override
  String get toolbarQuote => 'Цитат';
  @override
  String get toolbarIndent => 'Устави';
  @override
  String get toolbarOutdent => 'Смањи уступа';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Алати';
  @override
  String get editorToolsTitle => 'Алати уређивача';
  @override
  String get toolCountListTitle => 'Преброј листу';
  @override
  String get toolCountListSubtitle =>
      'Сабира оно што редови наводе, као листу са квачицама';
  @override
  String get toolCountListNeedsList => 'Ова белешка нема листу за бројање';
  @override
  String get tallySourceLabel => 'Листа';
  @override
  String get tallyCutLabel => 'Читај сваки ред као';
  @override
  String get tallyCutDash => 'Име - вредности';
  @override
  String get tallyCutColon => 'Име: вредности';
  @override
  String get tallyCutCommas => 'Вредности одвојене зарезом';
  @override
  String get tallyCutWhole => 'Цео ред као једна вредност';
  @override
  String get tallySortLabel => 'Редослед';
  @override
  String get tallySortCount => 'Највише прво';
  @override
  String get tallySortAlphabetical => 'Азбучно';
  @override
  String get tallySortFirstSeen => 'Како су наведени';
  @override
  String get tallyInsert => 'Уметни';
  @override
  String get tallyUpdate => 'Ажурирај';
  @override
  String get tallyNothingToCount => 'Овде нема шта да се броји';
  @override
  String get headingDialogTitle => 'Ниво наслова';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Уредитељска трака';
  @override
  String get toolbarSettingsHint =>
      'Превуците за преуређивање; око приказује или сакрива тастер.';
  @override
  String get toolbarShowButton => 'Прикажи';
  @override
  String get toolbarHideButton => 'Сакриј';
  @override
  String get toolbarResetOrder => 'Врати основно';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Прикажи преглед';
  @override
  String get showEditorTooltip => 'Прикажи уредитељ';
  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(HTML табела извора)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Претрага белешки';
  @override
  String get searchModeWords => 'Речи';
  @override
  String get searchModeContains => 'Садржи';
  @override
  String get searchEmptyHint =>
      'Укуцајте за претрагу библиотеке, или key = value за филтрирање '
      'по frontmatter';
  @override
  String get searchTooShortHint => 'Укуцајте бар 2 знака';
  @override
  String get searchNoMatches => 'Нема поклапања';
  @override
  String get searchLoadMore => 'Прикажи више';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Замени…';
  @override
  String get replaceInNoteAction => 'Замени у овој белешци…';
  @override
  String get replaceInThisNote => 'Замени у овој белешци';
  @override
  String get replaceWithLabel => 'Замени са';
  @override
  String get replaceCaseSensitive => 'Разликуј велика и мала слова';
  @override
  String get replaceWholeWordsHint =>
      'само тачна поклапања целих речи се замењују';
  @override
  String get replaceConfirm => 'Замени';
  @override
  String get replaceCancel => 'Затвори';
  @override
  String get replaceUnavailable => 'Замена тренутно није доступна';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Пронађи у белешци';
  @override
  String get editorFindHint => 'Пронађи';
  @override
  String get editorReplaceHint => 'Замени';
  @override
  String get editorFindCaseTooltip => 'Разликуј величину слова';
  @override
  String get editorFindPreviousTooltip => 'Претходно поклапање';
  @override
  String get editorFindNextTooltip => 'Следње поклапање';
  @override
  String get editorFindCloseTooltip => 'Затвори претрагу';
  @override
  String get editorFindReplaceModeTooltip => 'Начин замене';
  @override
  String get editorReplaceOneTooltip => 'Замени ово поклапање';
  @override
  String get editorReplaceAllTooltip => 'Замени сва поклапања';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Означења';
  @override
  String get tagsTitle => 'Означења';
  @override
  String get tagsEmpty =>
      'Још нема означања — додајте #ознаку или tags у frontmatter';
  @override
  String get tagsBackTooltip => 'Назад на претрагу';
  @override
  String get tagsNotesEmpty => 'Нема белешки са овим означањем';
  @override
  String tagsNotesCapped(int limit) =>
      'Наведено је само првих $limit — претражите ознаку да сузите';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Веза није пронађена';
  @override
  String get headingNotFoundTitle => 'Наслов није пронађен';
  @override
  String get ambiguousLinkTitle => 'Више белешки поклапа';
  @override
  String get openLinkFailed => 'Веза се не може отворити';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Белешка не постоји';
  @override
  String missingNoteDialogBody(String path) => 'Креирај „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Фасцикла „$folder“ не постоји';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Отворено';
  @override
  String get todoDone => 'Завршено';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Сви датуми';
  @override
  String get todoFilter => 'Филтер';
  @override
  String get todoNoTokens => 'Нема токена у овом списку';
  @override
  String get todoCountOpen => 'отворено';
  @override
  String get todoCountDone => 'завршено';
  @override
  String get todoEmptyOpen => 'Још нема отворених задатака';
  @override
  String get todoEmptyDone => 'Још ништа завршено';
  @override
  String get todoEmptyFiltered => 'Нема задатака који поклапају';
  @override
  String get todoTitle => 'Задаци';
  @override
  String get todoAddTooltip => 'Додај задатак';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt формат';
  @override
  String get todoHelpTooltip => 'Помоћ о формату';
  @override
  String get todoHelpIntro =>
      'Ваши задаци један су обичан текст-фајл, један задатак по реду. '
      'Niman за вас пише синтаксу, али ништа није сакривено: можете '
      'уређивати фајл у било ком уредитељу, а Niman ће га прочитати '
      'назад.';
  @override
  String get todoHelpFilesTitle => 'Два фајла';
  @override
  String get todoHelpFilesBody =>
      'Отворени задаци стоје у todo.txt у корену библиотеке. '
      'Завршавање једнога премешта његов ред у done.txt, па todo.txt '
      'остаје кратак. Ако завршен ред опет заврши у todo.txt, Niman '
      'га архивира следећи пут када чита фајлове.';
  @override
  String get todoHelpLineTitle => 'Анатомија реда';
  @override
  String get todoHelpLineBody =>
      'Све пре описа је опционо и мора доћи у овом редоследу:';
  @override
  String get todoHelpDoneBody =>
      'Означава задатак завршеним. Niman га додаје када откукате '
      'кутију.';
  @override
  String get todoHelpPriority => '(A) до (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Приоритет. A је највиши. Приказан као значка у списку.';
  @override
  String get todoHelpDatesBody =>
      'Датум завршетка, па датум креирања. Са само једним датумом то је '
      'датум креирања, осим ако ред не почине са x.';
  @override
  String get todoHelpTokensTitle => 'Проекти, контексти и означења';
  @override
  String get todoHelpTokensBody =>
      'Биле где у опису, реч са једним од ових префикса постаје чип '
      'којим можете филтрирати. Ништа није унапред дефинисано: токен '
      'постоји чим га наведете.';
  @override
  String get todoHelpProjectBody =>
      'Одељак задатка, на пример +градња или +теза.';
  @override
  String get todoHelpContextBody =>
      'Где или како ћете га обавити, на пример @дома или @позиви.';
  @override
  String get todoHelpHashtagBody =>
      'Слободна ознака, за све што друге два не покривају.';
  @override
  String get todoHelpTagsTitle => 'Датуми и подсећања';
  @override
  String get todoHelpTagsBody =>
      'Ово су key:value ознаке. Niman их пише из дијалога задатка, '
      'и чита их где год се појаве у реду.';
  @override
  String get todoHelpDueBody =>
      'Датум доспећа. Води боју значке и филтере за доспеће.';
  @override
  String get todoHelpRemBody =>
      'Кад да се пошаље обавештење, у вашем локалном времену. Пусти '
      'се и са угашеним екраном и затвореном апликацијом.';
  @override
  String get todoHelpRemDesktop =>
      'На десктопу Niman мора да ради када дође време: подсећање се '
      'приказује док је апликација отворена, а када је затворена ништа '
      'се не пушта.';
  @override
  String get todoHelpOtherBody =>
      'Чува се тачно као што је написано, па означења из других todo.txt '
      'апликација преживљају повратак. Niman на њих не делује, rec: '
      'included: поновљиви задатак се још не понавља.';
  @override
  String get todoHelpEditTitle => 'Уређивање ван Nimana';
  @override
  String get todoHelpEditBody =>
      'Задатак који нисте додирнули врати се бајт за бајт, са свим '
      'необичним размацима. Уредите ред, па Niman преписује само тај '
      'ред у свом канонском облику, остављајући остатак фајла по стране.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Додај задатак';
  @override
  String get todoEditTitle => 'Уреди задатак';
  @override
  String get todoDescriptionHint => 'Опис';
  @override
  String get todoCancel => 'Откажи';
  @override
  String get todoSave => 'Сачувај';
  @override
  String get todoEditAction => 'Уреди';
  @override
  String get todoDeleteAction => 'Обриши';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Закаснело';
  @override
  String get todoDueToday => 'Данас';
  @override
  String get todoDueNext7 => 'Следећих 7 дана';
  @override
  String get todoDueNoDate => 'Без датума';
  @override
  String get todoRowDue => 'Доспеће';
  @override
  String get todoRowDueToday => 'Доспеће данас';
  @override
  String get todoSortTooltip => 'Сортирај';
  @override
  String get todoSortDue => 'Датум доспећа';
  @override
  String get todoSortPriority => 'Приоритет';
  @override
  String get todoSortCreation => 'Датум креирања';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Без приоритета';
  @override
  String get todoNoPriorityShort => 'Ниједан';
  @override
  String get todoMorePriorities => 'Више…';
  @override
  String get todoPriorityTitle => 'Приоритет';
  @override
  String get todoNoDueDate => 'Без датума доспећа';
  @override
  String get todoNoReminder => 'Без подсећања';
  @override
  String get todoAddProject => '+ Пројекат';
  @override
  String get todoAddContext => '@ Контекст';
  @override
  String get todoAddHashtag => '# Ознака';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Подсећања о задацима';
  @override
  String get todoReminderChannelDescription =>
      'Расписани аларми за задатке са временом подсећања.';
  @override
  String get todoReminderBody => 'Подсећање о задатку';
  @override
  String get todoReminderFallbackTitle => 'Подсећање о задатку';
  @override
  String get todoReminderBlocked =>
      'Обавештења су искључена, па подсећања неће изаћи.';
  @override
  String get todoReminderBattery =>
      'Оптимизација батерије је укључена за Niman. Систем може да заспи '
      'апликацију и одбаци недовршена подсећања.';
  @override
  String get todoReminderInexact =>
      'Овај уређај не допушта прецизне аларме, па подсећање може '
      'стигнути за неколико минута касније са угашеним екраном.';
  @override
  String get reminderShowTokensTitle => 'Означења у обавештењима подсећања';
  @override
  String get reminderShowTokensSubtitle =>
      'Чува +пројекат, @контекст и #ознаку у тексту обавештења. '
      'Искључено приказује само задатак који сте навели.';
  @override
  String get todoReminderFixAction => 'Отвори подешавања';
  @override
  String get todoReminderDismissAction => 'Одбаци';
  @override
  String get todoReminderDue => 'Доспеће';

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
  String get actionSave => 'Сачувај';
  @override
  String get actionClear => 'Очисти';
  @override
  String get actionChoose => 'Изабери';
  @override
  String get actionDelete => 'Обриши';
  @override
  String get actionRename => 'Промени име';
  @override
  String get actionMove => 'Премести';
  @override
  String get saveAndClose => 'Сачувај и затвори';
  @override
  String get closeUnsavedTitle => 'Несачуване измене';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '«${names.first}» има измене које још нису сачуване. '
          'Сачувати пре затварања?';
    }
    return 'У ${names.length} белешки има измена које још нису '
        'сачуване. Сачувати пре затварања?';
  }

  @override
  String get closeSaveFailed =>
      'Није могуће сачувавање; белешка је још отворена.';
  @override
  String get actionRestore => 'Врати';
  @override
  String get actionEmpty => 'Очисти';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Сакриј бочни панел (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Прикажи бочни панел (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Минимизирај';
  @override
  String get windowMaximizeTooltip => 'Максимизирај';
  @override
  String get windowRestoreTooltip => 'Врати';
  @override
  String get windowCloseTooltip => 'Затвори';
  @override
  String get tabFiles => 'Датотеке';
  @override
  String get tabSearch => 'Претрага';
  @override
  String get tabSettings => 'Подешавања';
  @override
  String get quickNoteTitle => 'Брза белешка';
  @override
  String get treeEmpty => 'Још нема белешки';
  @override
  String get selectANote => 'Изабери белешку';
  @override
  String get showListTooltip => 'Прикажи списак';
  @override
  String get editRawTooltip => 'Уреди сирово';
  @override
  String get sortAscTooltip => 'Сортирај A-џ';
  @override
  String get sortDescTooltip => 'Сортирај џ-A';
  @override
  String get newNoteTitle => 'Нова белешка';
  @override
  String get newItemTooltip => 'Ново';
  @override
  String get closeMenuTooltip => 'Затвори';
  @override
  String get newFolderTitle => 'Нова фасцикла';
  @override
  String get newNoteSameFolder => 'Нова белешка у истој фасцикли';
  @override
  String get newFromTemplateSameFolder => 'Нова из шаблона у истој фасцикли';
  @override
  String trashOriginalPath(String path) => 'било у $path';
  @override
  String get trashOriginalRoot => 'било је у корену библиотеке';
  @override
  String trashItemCount(int count) => count == 1
      ? '1 \u0441\u0442\u0430\u0432\u043a\u0430'
      : '$count \u0441\u0442\u0430\u0432\u043a\u0438';
  @override
  String get newNoteHere => 'Нова белешка овде';
  @override
  String get newFolderHere => 'Нова фасцикла овде';
  @override
  String get newListNoteTitle => 'Нова белешка-списак';
  @override
  String get newListNoteDefault => 'Мој списак';
  @override
  String get setAsQuickNote => 'Постави као брзу белешку';
  @override
  String get currentQuickNote => 'Тренутна брза белешка';
  @override
  String get pinnedSection => 'Прикачени';
  @override
  String pinnedSectionCount(int count) => 'Прикачени · $count';
  @override
  String get templateFolderTitle => 'Фасцикла шаблона';
  @override
  String get newFromTemplateTitle => 'Ново из шаблона';
  @override
  String get newFromTemplateHere => 'Ново из шаблона овде';
  @override
  String get templateFormTitle => 'Испуни шаблон';
  @override
  String get templateFormBacklink => 'Повезано из';
  @override
  String get templateFormNoNote => 'Без белешке';
  @override
  String get templateFormPickNote => 'Изабери белешку';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Заменска места шаблона';
  @override
  String get templateHelpSubtitle =>
      'Датум, наслов и остале вредности за попуну';
  @override
  String get quickNoteSubtitle => 'Белешка коју отвара картица брзе белешке';
  @override
  String get listFolderSubtitle => 'Нове листе задатака';
  @override
  String get templateFolderSubtitle => 'Извор за „Ново из шаблона“';
  @override
  String get attachmentsFolderSubtitle => 'Слике и звук уметнути у белешку';
  @override
  String get templateHelpIntro =>
      'Шаблон је обична белешка са рупама. Креирање белешке из њега '
      'копира њен текст и испуњује рупе.';
  @override
  String get templateHelpUnknown =>
      'Заменско место које Niman не препознаје остаје тачно као што је '
      'написано, па грешка у куцању види се у белешки уместо да тихо '
      'поједе ред.';
  @override
  String get templateHelpValuesTitle => 'Вредности';
  @override
  String get templateHelpTitleBody => 'Име под којим се белешка креира.';
  @override
  String get templateHelpDateBody =>
      'Данас, и тренутно време. Оба узимају формат: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Датум и време заједно.';
  @override
  String get templateHelpUuidBody =>
      'Свеж идентификатор, другачији на сваком појављивању.';
  @override
  String get templateHelpCounterBody =>
      'Број који се повећава по имену, и чува се кроз поновна '
      'покретања: прва белешка пише 1, следећа 2. Исто име у једној '
      'белешци пише исти број; спојите са |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Смести каричну овде када се белешка креира; сам маркер се не '
      'пише. Први маркер побеђује, без филтера, само нове белешке — и '
      'тастатура се отвара чак и када је аутофокус искључен.';
  @override
  String get templateHelpDatesTitle => 'Писање датума';
  @override
  String get templateHelpDatesBody =>
      'Ови стоје за делове датума у формату. Све остало је литерално, и '
      'текст у једним наводницима је такође литерално. Називи месеца и '
      'дана у недељи прате језик апликације.';
  @override
  String get templateHelpYear => 'година: 2026, 26';
  @override
  String get templateHelpMonth => 'месец: 03, 3, Март, Мар';
  @override
  String get templateHelpDay => 'дан: 09, 9, Понедељак, Пон';
  @override
  String get templateHelpTime => 'сати, минути, секунде';
  @override
  String get templateHelpWeek => 'ISO недеља и квартал: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Филтери';
  @override
  String get templateHelpFiltersBody =>
      'Вредности могу да прате филтери, примењени лево на десно.';
  @override
  String get templateHelpCaseBody =>
      'Велика слова, мала слова и прво слово сваке речи — реч коју сте '
      'сами писали великим словом остаје по стране.';
  @override
  String get templateHelpSlugBody =>
      'Облик текста за везе, за грађење wikilink-а.';
  @override
  String get templateHelpPadBody =>
      'Одсеци крајеве; попуни нулама до ширине; користи резерву када је '
      'вредност празна.';
  @override
  String get templateHelpShiftBody =>
      'Помери датум за дане, недеље, месеце или године — лекција '
      'следеће недеље, фајл прошлог месеца.';
  @override
  String get templateHelpSnapBody =>
      'Усклади датум на почетак или крај своје недеље, месеца или '
      'године.';
  @override
  String get templateHelpAskTitle => 'Нешто вас пита';
  @override
  String get templateHelpAskBody =>
      'Форма се појављује пре креирања белешке, једно поље по питању — '
      'и једно за повратну везу, када шаблон то жели. Иста ознака двапут '
      'једно је питање, и његов одговор испуњава сва појављивања — '
      'фасциклу и име фајла укључујући.';
  @override
  String get templateHelpAskFieldBody =>
      'Поље за куцање; текст после друге двотачке је оно чим почиње.';
  @override
  String get templateHelpChoiceBody => 'Избор из списка, раздвојеног зарезима.';
  @override
  String get templateHelpWhereTitle => 'Где белешка иде';
  @override
  String get templateHelpWhereBody =>
      'Ово није текст: то су упутства, и живе у niman: блоку у самом '
      'frontmatter шаблона. Блок се поштује и онда се уклања, па се '
      'никад не појављује у белешци. Њихове вредности могу држати '
      'заменска места.';
  @override
  String get templateHelpFolderBody =>
      'Фасцикла у којој се белешка креира, прави се ако не постоји. Без '
      'ње белешка слети тамо где сте били.';
  @override
  String get templateHelpFilenameBody =>
      'Како се белешка зове. Шаблон који то наведе не бива питан за име.';
  @override
  String get templateHelpAppendBody =>
      'Додај белешци ако већ постоји, уместо да прави другу. Ово '
      'претвара месец састанака у један фајл.';
  @override
  String get templateHelpOpenBody =>
      'Што се дешава кад белешка постоји: уредитељ (подразумевано), '
      'преглед или ништа — белешка се подврже, и ви остате где сте '
      'били.';
  @override
  String get templateHelpAroundTitle => 'Одавде је дошла';
  @override
  String get templateHelpParentBody =>
      'Белешка коју изберете у форми, која сугерише онају на екрану; '
      'напишите [[{{parent}}]] за везу назад на њу.';
  @override
  String get templateHelpFolderValueBody =>
      'Фасцикла у којој се белешка завршила.';
  @override
  String get templateHelpClipboardBody =>
      'Шта је на међуспоју, и селекција уредитеља када је белешка '
      'започета из ње.';
  @override
  String get templateHelpIncludeTitle => 'Поновна употреба дела';
  @override
  String get templateHelpIncludeBody =>
      'Уметне други шаблон, па десет шаблона може да дели један списак '
      'задака. Прво се тражи у фасцикли шаблона, и .md се може '
      'изоставити. Његова питања се придружују истој форми.';
  @override
  String get templateHelpExampleTitle => 'Све заједно';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ не постоји шаблон „$path"';
  @override
  String includeCycle(String path) => '⚠ „$path" укључује само себе';
  @override
  String includeTooDeep(String path) => '⚠ „$path" је увучено превише дубоко';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter није прочитан: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter од „$template" није прочитан, па његова фасцикла и '
      'име фајла нису ништа учинили: $reason';
  @override
  String get templatePickerTitle => 'Изабери шаблон';
  @override
  String templatePickerEmpty(String folder) =>
      'Још нема шаблона. Ставите белешку у $folder/ и постаће тај.';

  // Tree actions.
  @override
  String get actionPin => 'Прикачи';
  @override
  String get actionUnpin => 'Откачи';
  @override
  String get pinToWidget => 'Закочи у виџет';
  @override
  String get pinnedForWidget =>
      'Закачено: сада постави виџет Белешке на почетни екран';
  @override
  String get pinWidgetUnavailable =>
      'Виџети почетног екрана доступни су на Андроиду';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Прикажи у управљачу датотека';
  @override
  String get openInDefaultApp => 'Отвори подразумеваном апликацијом';
  @override
  String get newNoteTabTooltip => 'Нова белешка у новој картици';
  @override
  String get openNotesTooltip => 'Отворене белешке';
  @override
  String get closeTabTooltip => 'Затвори';
  @override
  String get openInNewTab => 'Отвори у новој картици';
  @override
  String get splitRight => 'Подели десно';
  @override
  String get splitDown => 'Подели доле';
  @override
  String get moveToOtherPane => 'Премести у друго окно';
  @override
  String get openBeside => 'Отвори са стране';
  @override
  String get closeAllNotes => 'Затвори све';
  @override
  String get sidePanelTooltip => 'Прикажи или сакриј бочну таблу';
  @override
  String get historyAllVersions => 'Све верзије';
  @override
  String get commandPaletteTitle => 'Палета команди';
  @override
  String get goToNoteTitle => 'Иди на белешку';
  @override
  String get paletteGroupNote => 'Белешка';
  @override
  String get paletteGroupEditor => 'Уређивач';
  @override
  String get paletteGroupView => 'Приказ';
  @override
  String get paletteGroupLibrary => 'Библиотека';
  @override
  String get paletteGroupGoTo => 'Иди на';
  @override
  String get paletteGroupJournal => 'Дневник';
  @override
  String get journalToday => 'Данашњи унос';
  @override
  String get journalPrevious => 'Претходни унос';
  @override
  String get journalNext => 'Следећи унос';
  @override
  String get commandNeedJournalEntry => 'Потребан је отворен унос дневника';
  @override
  String journalCreateAsk(String day) =>
      'За $day још нема уноса. Направити га?';
  @override
  String journalTemplateMissing(String path) =>
      'Шаблон дневника $path није могао да се прочита: унос је направљен без '
      'њега.';
  @override
  String get journalIntro =>
      'Једна белешка дневно, направљена из шаблона када тај дан први пут '
      'отвориш. Ова подешавања путују са библиотеком.';
  @override
  String get journalFolderTitle => 'Фасцикла дневника';
  @override
  String get journalFolderSubtitle => 'Где иду уноси';
  @override
  String get journalEntryNameTitle => 'Назив уноса';
  @override
  String get journalEntryNameSubtitle =>
      'YYYY, MM или M, DD или D за датум; / прави фасциклу; текст у '
      "'наводницима' остаје какав јесте";
  @override
  String journalEntryNamePreview(String path) => 'Данашњи унос: $path';
  @override
  String get journalEntryNameInvalid =>
      'Потребни су YYYY, месец (MM или M) и дан (DD или D), и ништа што назив '
      'датотеке не сме да садржи';
  @override
  String get journalTemplateTitle => 'Шаблон';
  @override
  String get journalTemplateSubtitle => 'Чиме почиње нови унос';
  @override
  String get journalTemplateNone => 'Ниједан: наслов са датумом';
  @override
  String get journalDayStartTitle => 'Нови дан почиње у';
  @override
  String get journalDayStartSubtitle =>
      'Касно лежеш? У 04:00 ноћ остаје на претходном дану';
  @override
  String get journalRecent => 'Недавно';
  @override
  String get journalNoEntry => 'Нема уноса за овај дан';
  @override
  String get journalOpenEntry => 'Отвори';
  @override
  String get journalShowCalendar => 'Прикажи календар';
  @override
  String get journalFabToday => 'Данашњи унос у дневник';
  @override
  String journalDueOn(String day) => 'Рок $day';
  @override
  String get commandsTitle => 'Команде';
  @override
  String get commandsIntro =>
      'Палета команди нуди само команде које могу да се покрену тамо где сте. '
      'Овде су све, и када се која приказује.';
  @override
  String get commandsKeysNote =>
      'Овде се ништа не мења. Тастери су они подешени у одељку „Пречице на '
      'тастатури“ и прате сваку промену направљену тамо.';
  @override
  String get commandsOpenShortcuts =>
      'Промени тастере у одељку „Пречице на тастатури“';
  @override
  String get commandsChangeKeyTooltip =>
      'Промени у одељку „Пречице на тастатури“';
  @override
  String get commandsSubtitle => 'Шта палета команди може да покрене, и када';
  @override
  String get keyboardShortcutsSubtitle => 'Промени тастере сваке команде';
  @override
  String get commandNeedNone => 'Увек доступно';
  @override
  String get commandNeedOpenNote => 'Потребна је отворена белешка';
  @override
  String get commandNeedWideWindow => 'Само у широком прозору';
  @override
  String get commandNeedDockRoom =>
      'Потребан је прозор довољно широк за бочни панел';
  @override
  String get commandNeedDesktop => 'Само на рачунару';
  @override
  String get commandNeedNotInZen => 'Не у Зен режиму';
  @override
  String get commandNeedZenRoom => 'Рачунар, са белешком отвореном у картици';
  @override
  String get commandNeedPreview =>
      'Са укљученим прегледом, на текстуалној белешци';
  @override
  String get commandNeedTwoEditors => 'Са оба укључена уређивача';
  @override
  String get paletteHint => 'Тражи команде и белешке';
  @override
  String get paletteNoResults => 'Нема резултата';
  @override
  String get paletteCommands => 'Команде';
  @override
  String get paletteNotes => 'Белешке';
  @override
  String get paletteFooter => '↑↓ за кретање · ↵ за избор · esc за затварање';
  @override
  String get paletteFooterTouch =>
      'Додирните за покретање · чиода држи на врху';
  @override
  String get palettePinned => 'Закачено';
  @override
  String get palettePin => 'Закачи';
  @override
  String get paletteUnpin => 'Откачи';
  @override
  String get palettePinFooter => 'alt+P закачи';
  @override
  String get spellCheckScanning => 'Провера белешке…';
  @override
  String get spellCheckAgain => 'Провери поново';
  @override
  String spellCheckCapped(int count) =>
      'Приказано је првих $count: исправите неке, па поново проверите за '
      'остале';
  @override
  String get dropHint =>
      'Испустите Markdown датотеке да их отворите или фасциклу да је увезете';
  @override
  String get dropNothing =>
      'Радна површина није предала ниједну датотеку при том испуштању.';
  @override
  String get importFolderAction => 'Увези';
  @override
  String dropRejected(String names) =>
      'Овде се отварају само Markdown датотеке и фасцикле: $names';
  @override
  String importFolderTitle(String name) => 'Увести „$name“?';
  @override
  String importFolderBody(int count) =>
      'Њене Markdown датотеке ($count) копирају се у нову фасциклу '
      'библиотеке. Испуштена фасцикла остаје каква јесте.';
  @override
  String importFolderDone(String folder) => 'Увезено у $folder';
  @override
  String importFolderEmpty(String name) => 'Нема Markdown датотека у $name';
  @override
  String get openFileTitle => 'Отвори датотеку';
  @override
  String get outsideFileNote =>
      'Ван библиотеке: чува се где јесте, без индекса, без историје, везе се '
      'не прате';
  @override
  String get typewriterOn => 'Укључи режим писаће машине';
  @override
  String get typewriterOff => 'Искључи режим писаће машине';
  @override
  String get typewriterTitle => 'Режим писаће машине';
  @override
  String get formatNoteTitle => 'Сложи Markdown';
  @override
  String get formatNoteDone => 'Белешка је сложена.';
  @override
  String get formatNoteAlreadyTidy => 'Белешка је већ била сложена.';
  @override
  String get tidyOnCloseTitle => 'Сложи Markdown при затварању';
  @override
  String get tidyOnCloseSubtitle =>
      'Када затворите белешку коју сте уређивали, њен Markdown се сложи као '
      'командом „Сложи Markdown“. Белешке веће од 4 МБ остају какве јесу.';
  @override
  String get typewriterSubtitle => 'Ред који пишете остаје у средини уређивача';
  @override
  String get zenMode => 'Зен режим';
  @override
  String get zenModeEnter => 'Уђи у зен режим';
  @override
  String get zenModeLeave => 'Изађи из зен режима';
  @override
  String get keySpace => 'Размак';
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
  String get keyArrowDown => 'Доле';
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
  String get shortcutNone => 'Без пречице';
  @override
  String get shortcutRestoreDefaults => 'Врати подразумеване';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Вратити све пречице како их Niman испоручује?';
  @override
  String get shortcutRevert => 'Врати на подразумевану';
  @override
  String get shortcutClear => 'Уклони пречицу';
  @override
  String get shortcutCapturePrompt =>
      'Притисните тастере. И Esc и Tab се бележе: излаз је Откажи.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Додајте Ctrl, Alt или Meta: сам тастер је за куцање.';
  @override
  String get shortcutMove => 'Премести';
  @override
  String get shortcutUseAnyway => 'Ипак користи';
  @override
  String get shortcutUndo => 'Опозови';
  @override
  String get shortcutRedo => 'Понови';
  @override
  String get shortcutChange => 'Промени пречицу';
  @override
  String shortcutCaptureTitle(String command) => 'Тастери за „$command“';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys већ припада „$other“. Преместити овде? „$other“ остаје без '
      'пречице.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys је и „$what“ у текстуалним пољима и уређивачу. Тамо ће је '
      'преузети ваша команда.';
  @override
  String get openFileMissing => 'Датотека ове белешке није на диску';
  @override
  String get openFileFailed =>
      'Није било могуће отворити ову белешку изван Нимана';
  @override
  String get attachmentUnreadable => 'Ова датотека није могла да се прикаже.';
  @override
  String get attachmentMissing => 'Ова датотека није на диску.';
  @override
  String get attachmentOpenFailed =>
      'Није било могуће отворити ову датотеку изван Нимана.';

  @override
  String get movedToTrash => 'Премештено у кош';
  @override
  String get deletedMessage => 'Обрисано';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name ће бити премештено у .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name ће бити трајно обрисано';
  @override
  String get chooseDestination => 'Изабери одредиште';
  @override
  String get libraryRoot => 'Корен библиотеке';
  @override
  String moveTitle(String name) => 'Премести $name';
  @override
  String headingLevelLabel(int level) => 'Ниво наслова $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Још нема брзе белешке. Изаберите постојећу белешку или креирајте '
      'нову — брза белешка се отвара овде.';
  @override
  String get quickNoteChooseAction => 'Изабери белешку…';
  @override
  String get quickNoteCreateAction => 'Креирај нову белешку…';
  @override
  String get quickNoteNewTitle => 'Нова брза белешка';
  @override
  String get quickNotePickerTitle => 'Изабери брзу белешку';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Нова фасцикла';
  @override
  String get folderPickerEmpty => 'Још нема фасцикли';
  @override
  String get listFolderTitle => 'Фасцикла списка';
  @override
  String get attachmentsFolderTitle => 'Фасцикла прилога';

  // Trash (M1).
  @override
  String get trashEmpty => 'Кош је празан';
  @override
  String get trashEmptyAction => 'Очисти кош';
  @override
  String get trashEmptyConfirm =>
      'Ово трајно брише све у фасцикли коша, укључујући ставке које '
      'Niman није тамо ставио.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name ће бити трајно обрисано (без вратења)';
  @override
  String get trashDeletePermanently => 'Обриши трајно';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Отворите фасциклу Markdown белешки као своју библиотеку';
  @override
  String get openLibraryExisting => 'Отвори постојећу';
  @override
  String get openLibraryCreate => 'Креирај нову';
  @override
  String get openLibraryCreateTitle => 'Креирај нову библиотеку';
  @override
  String get openLibraryFolderName => 'Име фасцикле';
  @override
  String get openLibraryChooseFolder => 'Изабери фасциклу библиотеке';
  @override
  String get openLibraryChooseParent =>
      'Изабери фасциклу у којој ће библиотека бити креирана';
  @override
  String get openLibraryUnsupported =>
      'Та фасцикла није подржана. Изаберите фасциклу на складишту '
      'уређаја.';
  @override
  String indexingCount(int done, int total) => '$done од $total белешки';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Ваше библиотеке';
  @override
  String get libraryUnreachable => 'Недоступна';
  @override
  String get libraryOpenedToday => 'Отворена данас';
  @override
  String get libraryOpenedYesterday => 'Отворена јуче';
  @override
  String libraryOpenedDaysAgo(int days) => 'Отворена пре $days дана';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Отворена ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Отвори сада';
  @override
  String get switchLibraryTitle => 'Промени библиотеку';
  @override
  String get libraryForget => 'Заборави';
  @override
  String libraryForgetTitle(String name) => 'Заборавити „$name"?';
  @override
  String get libraryForgetExplained =>
      'Она иде ван овог списка. Фасцикла, белешке и подешавања '
      'библиотеке у њој остају по стране, и поновно отварање враћа је '
      'на место.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Дај приступ фајловима';
  @override
  String get storageAccessNeeded =>
      'Niman не може да чита ваше белешке без „приступа свим фајловима". '
      'Дозволите га да бисте отворили библиотеку.';
  @override
  String get storageAccessExplained =>
      'Niman чита ваше белешке као обичне фајлове, па Android мора да му '
      'дозволи приступ свим фајловима. Ништа се не уцељује, и чита се '
      'само фасцикла библиотеке коју изберете.';
  @override
  String folderAccessDenied(Object error) =>
      'Систем није дао приступ фасцикли: $error';
  @override
  String folderPickFailed(Object error) =>
      'Није могуће изабрати фасциклу: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Подешавања';
  @override
  String get libraryPathTitle => 'Путања библиотеке';
  @override
  String get reindexTitle => 'Поново индексирај сада';
  @override
  String get reindexDone => 'Поново индексирано';
  @override
  String get closeLibraryTitle => 'Затвори библиотеку';
  @override
  String get exportLogTitle => 'Извези дневник за отклањање грешака';
  @override
  String get exportLogSubtitle =>
      'Сачувај забележене догађаје у фајл који изберете';
  @override
  String get exportLogEmpty => 'Буфер дневника за отклањање грешака је празан';
  @override
  String get quickNoteUnset => 'Још није постављено';
  @override
  String exportLogDone(Object target) => 'Дневник је извезен у $target';
  @override
  String exportLogFailed(Object error) => 'Извоз није успео: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Није пронађено тачно поклапање целих речи за „$term"';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Замењено $occurrences појављивања „$term" у $notes белешки';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped отворених белешака занемарено)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Нема тачног поклапања целих речи за „$term"'
      '${only == null ? 'није пронађено' : 'пронађено у $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'О апликацији';
  @override
  String get versionTitle => 'Верзија';
  @override
  String get changelogTitle => 'Белешке о изменама';
  @override
  String get changelogEmpty => 'Нема доступних записа у белешкама';
  @override
  String changelogWhatsNew(String version) => 'Novo u verziji $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Историја';
  @override
  String get noteMenuTooltip => 'Радње са белешком';
  @override
  String get historyCurrentVersion => 'Тренутна верзија';
  @override
  String get historyCurrentSubtitle => 'Белешка каква је сада';
  @override
  String get historyToday => 'Данас';
  @override
  String get historyYesterday => 'Јуче';
  @override
  String get historyReasonSession => 'пре уређивања';
  @override
  String get historyReasonInterval => 'током уређивања';
  @override
  String get historyReasonRestore => 'пре враћања';
  @override
  String get historyReasonSync => 'пре синхронизације';
  @override
  String get historyReasonReplace => 'пре замене';
  @override
  String get historyReasonUnknown => 'пронађена';
  @override
  String get historySyncBase => 'основа синхронизације';
  @override
  String get historyEmpty =>
      'Још нема верзија. Niman чува једну када почнете да уређујете '
      'белешку, а затим највише једну на сваких неколико минута док пишете.';
  @override
  String historyKept(int kept, int limit) =>
      'Сачуване верзије: $kept од $limit';
  @override
  String get historyBaseKept =>
      'Основа синхронизације се чува и преко ограничења.';
  @override
  String get historyOff =>
      'Историја је искључена за ову библиотеку (Подешавања, Библиотека).';
  @override
  String get historyLoadFailed => 'Историја се не може прочитати';
  @override
  String get historyCompareSubtitle => 'У поређењу са тренутном верзијом';
  @override
  String get historyTabChanges => 'Измене';
  @override
  String get historyTabVersion => 'Верзија';
  @override
  String get historyNoChanges => 'Исти текст као тренутна верзија.';
  @override
  String get historyRestoreAction => 'Врати ову верзију';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Вратити верзију сачувану $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Тренутни текст се прво чува у историји, па увек можете да се '
      'вратите.';
  @override
  String get historyRestoreConfirm => 'Врати';
  @override
  String historyRestored(String when) => 'Враћена верзија сачувана $when';
  @override
  String get historyRestoreFailed => 'Верзија се не може вратити';
  @override
  String get actionUndo => 'Поништи';
  @override
  String diffLineRange(int start, int end) => 'Редови $start–$end';
  @override
  String diffLineSingle(int line) => 'Ред $line';
  @override
  String diffUnchanged(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count непромењен ред',
    (2 || 3 || 4, < 12 || > 14) => '$count непромењена реда',
    _ => '$count непромењених редова',
  };
  @override
  String get historyTakeHunk => 'Врати овде';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Врати 1 промену' : 'Врати $count промена';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Изабране промене враћају се на текст ове верзије. Белешка у тренутном '
      'облику прво се чува као верзија, па ово можеш да опозовеш.';
  @override
  String get historyNoteChangedReloaded =>
      'Белешка се променила док си био овде — поређење је освежено.';
  @override
  String get historyVersionsTitle => 'Број чуваних верзија';
  @override
  String get historyVersionsSubtitle => 'По белешци, у .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Ниједна' : '$count';
  @override
  String get historyIntervalTitle => 'Нова верзија највише на сваких';
  @override
  String get historyIntervalSubtitle =>
      'Док пишете; почетак уређивања белешке увек чува једну';
  @override
  String historyIntervalValue(int minutes) => '$minutes мин';
  @override
  String get settingsSectionTranscription => 'Транскрипција';
  @override
  String get transcriptionModelTitle => 'Модел';
  @override
  String get transcriptionModelNone => 'Ниједан';
  @override
  String get transcriptionLanguageTitle => 'Језик';
  @override
  String get transcriptionLanguageSubtitle =>
      'Језик којим се говори у вашим снимцима. Навести га је тачније него '
      'препуштати препознавању.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Као апликација ($language)';
  @override
  String get transcriptionLanguageDetect => 'Препознај аутоматски';
  @override
  String get transcriptionModelsTitle => 'Модели за транскрипцију';
  @override
  String transcriptionModelsUsed(String size) => 'Заузето $size';
  @override
  String get transcriptionModelsInstalled => 'Преузети';
  @override
  String get transcriptionModelsDownloading => 'Преузимање';
  @override
  String get transcriptionModelsAvailable => 'Доступни';
  @override
  String get transcriptionModelsFooter =>
      'Модели остају у складишту апликације на овом уређају. Не копирају се у '
      'библиотеку и не синхронизују се.';
  @override
  String get transcriptionModelDefault => 'Подразумевани';
  @override
  String get transcriptionModelSlow => 'Спор';
  @override
  String get transcriptionModelHintTiny => 'Најбржи, најмање тачан';
  @override
  String get transcriptionModelHintBase => 'Добар однос брзине и тачности';
  @override
  String get transcriptionModelHintSmall => 'Тачнији, око 3× спорији';
  @override
  String get transcriptionModelHintMedium => 'Веома тачан, спор на телефону';
  @override
  String get transcriptionModelHintLarge => 'Најтачнији, треба много меморије';
  @override
  String get transcriptionModelDownload => 'Преузми';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Избрисати модел $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Ослобађа се $size. Модел можете касније поново да преузмете.';
  @override
  String get transcriptionModelFailed =>
      'Преузимање није успело. Проверите везу и покушајте поново.';
  @override
  String get actionRetry => 'Покушај поново';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Веза је прекинута, поновни покушај…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Паузирано на $progress';
  @override
  String get actionResume => 'Настави';
  @override
  String get audioTranscribe => 'Транскрибуј';
  @override
  String get audioTranscribeUnsupported => 'На овом уређају само WAV снимци';
  @override
  String get transcriptionQueued => 'У реду';
  @override
  String get transcriptionPreparing => 'Припрема звука…';
  @override
  String transcriptionRunning(int percent) => 'Транскрипција… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Преузимање модела $model · $percent%';
  @override
  String get transcriptionSaved => 'Транскрипција је додата у опис';
  @override
  String get transcriptionNoSpeech => 'У овом снимку није препознат говор';
  @override
  String get transcriptionFailed => 'Транскрипција није успела';
  @override
  String get transcriptionPickModelTitle => 'Изаберите модел';
  @override
  String get transcriptionPickModelBody =>
      'Транскрипција се обавља на овом уређају и снимак се никад не шаље. '
      'Модел се преузима само једном.';
  @override
  String get transcriptionPickModelAction => 'Преузми и транскрибуј';
  @override
  String get transcriptionModelRecommended => 'Препоручено';
  @override
  String get transcriptionExistingTitle => 'Овај снимак већ има опис';
  @override
  String get transcriptionExistingBody =>
      'Заменити га транскрипцијом или додати транскрипцију испод?';
  @override
  String get transcriptionAppend => 'Додај испод';
  @override
  String get transcriptionReplace => 'Замени';
  @override
  String get settingsSectionSync => 'Синхронизација';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Није подешена за ову библиотеку';
  @override
  String get syncNeverSynced => 'Још није синхронизована';
  @override
  String syncLastSynced(String when) => 'Синхронизована $when';
  @override
  String get syncRunning => 'Синхронизација у току…';
  @override
  String syncScreenSubtitle(String library) => 'Библиотека $library';
  @override
  String get syncUrlLabel => 'Адреса фасцикле';
  @override
  String get syncUrlRequired => 'Унесите адресу сервера';
  @override
  String get syncUrlHint =>
      'Фасцикла мора да постоји. Копирајте адресу онако како је '
      'приказује сервер.';
  @override
  String get syncHttpWarning =>
      'Нешифрована веза: у реду уз VPN или у локалној мрежи.';
  @override
  String get syncUserLabel => 'Корисник';
  @override
  String get syncUserHint => 'Оставите празно ако сервер не тражи акредитиве.';
  @override
  String get syncPasswordLabel => 'Лозинка';
  @override
  String get syncPasswordHint =>
      'Чува се у привеску кључева овог уређаја, никад у '
      'фајловима библиотеке.';
  @override
  String get syncPasswordKeepHint =>
      'Оставите празно да бисте задржали сачувану лозинку.';
  @override
  String get syncShowPassword => 'Прикажи лозинку';
  @override
  String get syncHidePassword => 'Сакриј лозинку';
  @override
  String get syncTestAction => 'Тестирај везу';
  @override
  String get syncTesting => 'Тестирање…';
  @override
  String get syncRetargetWarning =>
      'Са новом адресом или корисником следећа синхронизација '
      'почиње испочетка, као прва.';
  @override
  String get syncTestOk => 'Веза ради';
  @override
  String get syncModeFull => 'Пун режим';
  @override
  String get syncModeCompatible => 'Компатибилни режим';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Читање, писање и брисање';
  @override
  String get syncCapEtags => 'Отисци фајлова (ETag)';
  @override
  String get syncCapNoEtags => 'Без отисака фајлова (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Пореди величину и датум; у случају сумње поново преузима';
  @override
  String get syncCapGuarded => 'Заштићени уписи';
  @override
  String get syncCapUnguarded => 'Незаштићени уписи';
  @override
  String get syncCapUnguardedDetail =>
      'Проверава фајл на серверу непосредно пре уписа';
  @override
  String get syncCapMove => 'Преименује без поновног отпремања';
  @override
  String get syncCapNoMove => 'Без преименовања на серверу';
  @override
  String get syncCapNoMoveDetail =>
      'Преименовање постаје брисање и ново отпремање';
  @override
  String get syncCompatibleNote =>
      'У компатибилном режиму синхронизација ради исто, уз нешто '
      'више захтева.';
  @override
  String get syncTestInvalidUrl => 'Неважећа адреса';
  @override
  String get syncTestInvalidUrlHint =>
      'Унесите адресу http:// или https:// без корисника и '
      'лозинке у њој.';
  @override
  String get syncTestOffline => 'Сервер није доступан';
  @override
  String get syncTestOfflineHint =>
      'Да ли је VPN укључен? Адреса 10.x или 192.168.x ради само '
      'из исте мреже.';
  @override
  String get syncTestAuth => 'Корисник или лозинка су одбијени';
  @override
  String get syncTestAuthHint => 'Проверите их, па тестирајте поново.';
  @override
  String get syncTestNotFound => 'Фасцикла не постоји';
  @override
  String get syncTestNotFoundHint =>
      'Направите је на серверу или исправите адресу.';
  @override
  String get syncTestUnsupported => 'Није WebDAV фасцикла';
  @override
  String get syncTestUnsupportedHint => 'Сервер одговара, али не као WebDAV.';
  @override
  String get syncTestFailed => 'Тест није успео';
  @override
  String get syncNowAction => 'Синхронизуј сада';
  @override
  String get syncSectionServer => 'Сервер';
  @override
  String get syncServerRow => 'Адреса, корисник и лозинка';
  @override
  String get syncRetestTitle => 'Поново тестирај сервер';
  @override
  String syncProbedAgo(String when) => 'Последњи тест $when';
  @override
  String get syncDisconnectTitle => 'Искључи ову библиотеку';
  @override
  String get syncDisconnectSubtitle => 'Фајлови остају овде и на серверу';
  @override
  String get syncDisconnectConfirmTitle => 'Искључити синхронизацију?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ова библиотека престаје да се синхронизује на овом '
      'уређају. Ниједан фајл се не брише, ни овде ни на серверу. '
      'Ако је поново повежете, прва синхронизација почиње '
      'испочетка.';
  @override
  String get syncDisconnectConfirm => 'Искључи';
  @override
  String get syncFirstTitle => 'Прва синхронизација';
  @override
  String get syncFirstIntro =>
      'Библиотека је упоређена са фасциклом на серверу:';
  @override
  String get syncFirstUpload => 'За отпремање';
  @override
  String get syncFirstDownload => 'За преузимање';
  @override
  String get syncFirstBoth => 'На обе стране';
  @override
  String get syncFirstBothHint => 'Исти: без преноса. Различити: за решавање';
  @override
  String get syncFirstNoDelete =>
      'Прва синхронизација ништа не брише, ни овде ни на серверу.';
  @override
  String get syncStartAction => 'Покрени';
  @override
  String syncMassTrashTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Преместити $count фајл у кош?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Преместити $count фајла у кош?'
      : 'Преместити $count фајлова у кош?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'На серверу недостаје $count од $total синхронизованих '
      'фајлова. То обично значи погрешну адресу, немонтиран NAS '
      'диск или фасциклу испражњену грешком.';
  @override
  String get syncMassTrashHint =>
      'Ако сте их заиста обрисали на другом уређају, потврдите: '
      'овде иду у кош.';
  @override
  String get syncMassTrashConfirm => 'Премести у кош';
  @override
  String syncMassDeleteTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Обрисати $count фајл са сервера?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Обрисати $count фајла са сервера?'
      : 'Обрисати $count фајлова са сервера?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Овде недостаје $count од $total синхронизованих фајлова. '
      'Ако их нисте ви обрисали, откажите и проверите фасциклу '
      'библиотеке.';
  @override
  String get syncMassDeleteConfirm => 'Обриши са сервера';
  @override
  String get syncTooltip => 'Синхронизуј';
  @override
  String get syncStageConnecting => 'Повезивање са сервером…';
  @override
  String get syncStageComparing => 'Поређење са сервером…';
  @override
  String syncStageApplying(int done, int total) =>
      'Синхронизација · $done од $total';
  @override
  String get syncStatusWarnings => 'Синхронизована уз упозорења';
  @override
  String syncConflictsHeader(int count) =>
      'Измењено овде и на серверу · $count';
  @override
  String get syncConflictHint => 'Ниједна верзија није дирана';
  @override
  String get syncResolveAction => 'Реши';
  @override
  String syncFailuresHeader(int count) => 'Није синхронизовано · $count';
  @override
  String get syncFailuresHint => 'Нови покушај при следећој синхронизацији';
  @override
  String get syncAbortAuth => 'Сервер је одбио лозинку';
  @override
  String get syncAbortMissingPassword => 'Нема сачуване лозинке';
  @override
  String get syncAbortOffline => 'Сервер није доступан';
  @override
  String get syncAbortRemoteMissing => 'Фасцикла на серверу више не постоји';
  @override
  String get syncAbortUnsupported => 'Сервер више не ради као WebDAV';
  @override
  String get syncAbortFailed => 'Синхронизација није успела';
  @override
  String get syncAbortNotConfirmed => 'Синхронизација је отказана';
  @override
  String get syncAbortNothingTouched =>
      'Ниједан фајл није диран. Ваше измене остају овде до '
      'следеће успешне синхронизације.';
  @override
  String syncLastSuccess(String when) =>
      'Последња успешна синхронизација $when';
  @override
  String get syncNoSuccessYet => 'Још нема успешне синхронизације';
  @override
  String get syncUpdatePasswordAction => 'Ажурирај лозинку';
  @override
  String get syncRetryAction => 'Покушај поново';
  @override
  String get syncOpenSettingsAction => 'Подешавања';
  @override
  String get syncCloseAction => 'Затвори';
  @override
  String get syncDoneSnack => 'Синхронизовано';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Синхронизовано · $count фајл обрисан другде је у кошу'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Синхронизовано · $count фајла обрисана другде су у кошу'
      : 'Синхронизовано · $count фајлова обрисаних другде је у кошу';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Синхронизовано · $count конфликт за решавање'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Синхронизовано · $count конфликта за решавање'
      : 'Синхронизовано · $count конфликата за решавање';
  @override
  String get syncShowAction => 'Прикажи';
  @override
  String get syncConflictTitle => 'Реши конфликт';
  @override
  String get syncConflictBinary =>
      'Није текстуални фајл: изаберите коју копију да задржите.';
  @override
  String get syncConflictKeepNote =>
      'Копија коју не задржите остаје у историји белешке.';
  @override
  String get syncKeepLocal => 'Задржи верзију овог уређаја';
  @override
  String get syncKeepRemote => 'Задржи верзију са сервера';
  @override
  String get syncConflictLoadFailed => 'Није могуће прочитати обе верзије';
  @override
  String get syncResolveFailed => 'Није могуће решити конфликт';
  @override
  String get syncResolved => 'Конфликт је решен';
  @override
  String get syncConflictMoved =>
      'Једна од верзија се у међувремену променила: сукоб је поново учитан, '
      'изаберите поново.';
  @override
  String get syncSectionWhen => 'Када синхронизовати';
  @override
  String get syncAutoTitle => 'Аутоматски';
  @override
  String get syncAutoSubtitle => 'После измена, при отварању и у размацима';
  @override
  String get syncIntervalTitle => 'Провери сервер сваких';
  @override
  String get syncIntervalSubtitle => 'Само док је апликација отворена';
  @override
  String get syncIntervalDialogBody =>
      'Да бисте видели измене направљене на другим уређајима док је апликација '
      'отворена. Уз „Никад“ — само после измена и при отварању.';
  @override
  String syncIntervalMinutes(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count минут',
    (2 || 3 || 4, < 12 || > 14) => '$count минута',
    _ => '$count минута',
  };
  @override
  String get syncIntervalNever => 'Никад';
  @override
  String get syncWifiOnlyTitle => 'Само Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'На мобилним подацима синхронизуј само ручно';
  @override
  String syncPendingChanges(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count измена чека',
    (2 || 3 || 4, < 12 || > 14) => '$count измене чекају',
    _ => '$count измена чека',
  };
  @override
  String syncRetryIn(String wait) => 'нови покушај за $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds с';
  @override
  String syncWaitMinutes(int minutes) => '$minutes мин';
  @override
  String get syncWaitingForWifi => 'Чека се Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Чека се веза';
  @override
  String get syncMobileDataHint =>
      '„Синхронизуј сада“ ипак користи мобилне податке.';
  @override
  String get syncQueueKeptHint =>
      'Измене остају овде, чак и ако затворите апликацију, и саме одлазе када '
      'сервер одговори.';
  @override
  String get syncAutoPaused => 'Аутоматска синхронизација је паузирана';
  @override
  String get syncPausedAuthHint =>
      'Наставља се када ажурирате лозинку или синхронизујете ручно.';
  @override
  String get syncPausedServerHint =>
      'Наставља се када исправите адресу или синхронизујете ручно.';
  @override
  String get syncPausedConfirmHint =>
      '„Синхронизуј сада“ показује шта би било уклоњено и прво пита.';
  @override
  String get syncNeedsConfirmation => 'Чека вашу потврду';
  @override
  String get syncMergeIntro =>
      'Измене које се не преклапају већ су спојене; тамо где се преклапају, '
      'изаберите шта да задржите.';
  @override
  String get syncMergeClean =>
      'Две верзије се спајају саме: ништа се не преклапа.';
  @override
  String get syncMergeNoBase =>
      'Нема заједничке верзије за спајање: где год се две копије разликују, '
      'бираш ти.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Преклапање $index од $total';
  @override
  String get syncMergeFromLocal => 'Са овог уређаја';
  @override
  String get syncMergeFromRemote => 'Са сервера';
  @override
  String get syncMergeRemovedLines => 'Уклоњени редови';
  @override
  String get syncMergeAbsentLines => 'Нема у овој копији';
  @override
  String get syncMergeKeepLocal => 'Моји';
  @override
  String get syncMergeKeepRemote => 'Серверови';
  @override
  String get syncMergeKeepBoth => 'Оба';
  @override
  String get syncMergeSave => 'Сачувај спајање';
  @override
  String get syncMergeKeepWhole => 'Или задржите једну целу копију';
}
