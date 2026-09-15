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
  String get settingsPreviewEnabledTitle => 'Преглед';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Приказује обележану белешку поред уредитеља извора';
  @override
  String get switchToWysiwygTooltip => 'Пређи на WYSIWYG уредитељ';
  @override
  String get switchToSourceTooltip => 'Пређи на Markdown извор';
  @override
  String get wysiwygTooLarge =>
      'Ова белешка је превелика за WYSIWYG уредитељ. Отворите је у '
      'Markdown извору.';

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
  String get themePaletteTitle => 'Палета';
  @override
  String get themePaletteSubtitle => 'Боје сучеља и белешке';
  @override
  String get themePaletteSystem => 'Систем';

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
  @override
  String get previewModeTitle => 'Начин прегледа';
  @override
  String get previewModeSubtitle =>
      'Да ли преглед дели екран са уредитељем или га замењује';
  @override
  String get previewModeAuto => 'Један поред другог';
  @override
  String get previewModeSwitch => 'Цели екран';
  @override
  String get splitRatioTitle => 'Ширина поделе';
  @override
  String get splitRatioSubtitle => 'Удео уредитеља када је преглед поред њега';

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
  String get audioDelete => 'Delete recording';
  @override
  String get audioImport => 'Import an audio file';
  @override
  String get audioRecording => 'Recording…';
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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Брза белешка';
  @override
  String get shortcutNewTodo => 'Нов задатак';
  @override
  String get shortcutNewNote => 'Нова белешка';
  @override
  String get shortcutNewList => 'Нов списак';
  @override
  String get shortcutNewAudio => 'New voice note';
  @override
  String get shortcutToggleSidebar => 'Прикажи или сакриј стабло датотека';
  @override
  String get shortcutEditorSection => 'У уредитељу';
  @override
  String get shortcutFind => 'Претрага';
  @override
  String get shortcutReplace => 'Пронађи и замени';
  @override
  String get shortcutSavingNote =>
      'Измене се аутоматски сачувају, па нема пречице за чување.';

  // Editor status bar.
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
  String get toolbarHeading => 'Наслов';
  @override
  String get toolbarList => 'Списак';
  @override
  String get toolbarOrderedList => 'Бројчани списак';
  @override
  String get toolbarQuote => 'Цитат';
  @override
  String get toolbarIndent => 'Устави';
  @override
  String get toolbarOutdent => 'Смањи уступа';
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
  @override
  String get enterFullScreenTooltip => 'Цели екран';
  @override
  String get exitFullScreenTooltip => 'Изађи из целог екрана';

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
  String get newFolderTitle => 'Нова фасцикла';
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
  String get attachmentsFolderTitle => 'Attachments folder';

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
  String get settingsSectionAbout => 'O aplikaciji';
  @override
  String get versionTitle => 'Verzija';
  @override
  String get changelogTitle => 'Beleške o izmenama';
  @override
  String get changelogEmpty => 'Nema dostupnih zapisa u beleškama';
  @override
  String changelogWhatsNew(String version) => 'Novo u verziji $version';
}
