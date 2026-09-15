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
  String get settingsPreviewEnabledTitle => 'Преглед';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Го прикажува форматираното белешко покрај уредникот на изворот';
  @override
  String get switchToWysiwygTooltip => 'Префрли на WYSIWYG уредник';
  @override
  String get switchToSourceTooltip => 'Префрли на Markdown изворот';
  @override
  String get wysiwygTooLarge =>
      'Оваа белешка е премногу голема за WYSIWYG уредникот. Отвори ја во '
      'Markdown изворот.';

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
  String get themePaletteTitle => 'Палета';
  @override
  String get themePaletteSubtitle => 'Бои на интерфејсот и на белешката';
  @override
  String get themePaletteSystem => 'Систем';

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
  @override
  String get previewModeTitle => 'Начин на преглед';
  @override
  String get previewModeSubtitle =>
      'Дали прегледот го дели екранот со уредникот или го заменува';
  @override
  String get previewModeAuto => 'Еден до друг';
  @override
  String get previewModeSwitch => 'Цел екран';
  @override
  String get splitRatioTitle => 'Ширина на поделба';
  @override
  String get splitRatioSubtitle => 'Удел на уредникот кога прегледот е до него';

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
  String get shortcutQuickNote => 'Брзо белешко';
  @override
  String get shortcutNewTodo => 'Нова задача';
  @override
  String get shortcutNewNote => 'Нова белешка';
  @override
  String get shortcutNewList => 'Нова листа';
  @override
  String get shortcutNewAudio => 'New voice note';
  @override
  String get shortcutToggleSidebar =>
      'Прикажи или скриј го стаблото на датотеките';
  @override
  String get shortcutEditorSection => 'Во уредникот';
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
  String get toolbarHeading => 'Наслов';
  @override
  String get toolbarList => 'Листа';
  @override
  String get toolbarOrderedList => 'Бројчана листа';
  @override
  String get toolbarQuote => 'Цитат';
  @override
  String get toolbarIndent => 'Вовлечи';
  @override
  String get toolbarOutdent => 'Намали вовлечување';
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
  @override
  String get enterFullScreenTooltip => 'Цел екран';
  @override
  String get exitFullScreenTooltip => 'Изијди од цел екран';

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
  String get newFolderTitle => 'Нова папка';
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
  String get attachmentsFolderTitle => 'Attachments folder';

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
}
