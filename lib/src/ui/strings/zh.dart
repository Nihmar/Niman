// The Simplified Chinese strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: missing_whitespace_between_adjacent_strings,
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class ChineseStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ];
  @override
  List<String> get monthNamesShort => const [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];
  @override
  List<String> get weekdayNames => const [
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => '回收站';
  @override
  String get trashSubtitle => '删除的内容移入 .trash/（关闭 = 永久删除）';
  @override
  String get debugLogsTitle => '调试日志';
  @override
  String get debugLogsSubtitle => '将应用事件记录到内存缓冲区';
  @override
  String get lineNumbersTitle => '行号';
  @override
  String get lineNumbersSubtitle => '在编辑器中显示行号栏';
  @override
  String get keyboardOnOpenTitle => '打开时弹出键盘';
  @override
  String get keyboardOnOpenSubtitle => '打开笔记时立即弹出键盘（关闭 = 首次输入时弹出）';
  @override
  String get editorKindSource => 'Markdown 源码';
  @override
  String get editorKindWysiwyg => '所见即所得';
  @override
  String get settingsPreviewEnabledTitle => '预览';
  @override
  String get settingsPreviewEnabledSubtitle => '在源码编辑器旁边显示渲染后的笔记';
  @override
  String get switchToWysiwygTooltip => '切换到所见即所得编辑器';
  @override
  String get switchToSourceTooltip => '切换到 Markdown 源码';
  @override
  String get wysiwygTooLarge => '此笔记对所见即所得编辑器来说太大了。请在 Markdown 源码中打开。';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => '外观';
  @override
  String get settingsSectionEditor => '编辑器';
  @override
  String get settingsSectionLibrary => '文库';
  @override
  String get settingsSectionReminders => '提醒';
  @override
  String get settingsSectionShortcuts => '键盘';
  @override
  String get keyboardShortcutsTitle => '键盘快捷键';
  @override
  String get settingsSectionDiagnostics => '诊断';
  @override
  String get settingsSpellCheckTitle => '拼写检查';
  @override
  String get settingsSpellCheckSubtitle => '输入时把拼错的词加下划线。';
  @override
  String get spellCheckDictionaryTitle => '词典';
  @override
  String get spellCheckDictionarySystem => '系统默认';
  @override
  String get spellCheckDictionaryChoiceTitle => '选择词典';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      '选择本库使用的每种语言。一个词只要被选中的某个词典认识就算正确；'
      '不做选择时由系统语言决定。';
  @override
  String get spellCheckNoDictionaries => '在此系统上未找到任何词典。';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => '拼写检查';
  @override
  String get spellCheckTitle => '拼写';
  @override
  String get spellCheckEmpty => '没有拼写错误。';
  @override
  String get spellCheckUnavailable => '此系统未安装 hunspell。';
  @override
  String get spellCheckNoSuggestions => '没有建议';
  @override
  String spellCheckCount(int count) => '待检查 $count 处';
  @override
  String spellCheckLine(int line) => '第 $line 行';

  @override
  String indentWidthValue(int spaces) => '$spaces 个空格';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => '明暗';
  @override
  String get themeBrightnessSubtitle => '浅色、深色或跟随设备设置';
  @override
  String get themeBrightnessSystem => '跟随系统';
  @override
  String get themeBrightnessDay => '浅色';
  @override
  String get themeBrightnessNight => '深色';
  @override
  String get themePaletteTitle => '配色';
  @override
  String get themePaletteSubtitle => '界面和笔记的颜色';
  @override
  String get themePaletteSystem => '跟随系统';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => '界面文字大小';
  @override
  String get uiTextScaleSubtitle => '文件树、标签页和对话框；叠加在系统设置之上';
  @override
  String get noteTextScaleTitle => '笔记文字大小';
  @override
  String get noteTextScaleSubtitle => '编辑器与预览，两者始终一致';

  // Settings: preview mode.
  @override
  String get previewModeTitle => '预览模式';
  @override
  String get previewModeSubtitle => '预览是与编辑器分屏还是替换编辑器';
  @override
  String get previewModeAuto => '分屏';
  @override
  String get previewModeSwitch => '全屏';
  @override
  String get splitRatioTitle => '分屏宽度';
  @override
  String get splitRatioSubtitle => '预览与编辑器并排时编辑器所占的比例';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => '链接格式';
  @override
  String get linkTypeSubtitle => '编辑器链接按钮插入的内容';
  @override
  String get linkTypeWikilink => '维基链接';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => '缩进宽度';
  @override
  String get indentWidthSubtitle => '编辑器每级缩进添加的空格数';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => '语言';
  @override
  String get languageSubtitle => '应用自身文字的语言';
  @override
  String get languageSystem => '跟随系统';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => '添加条目';
  @override
  String get listAddTooltip => '添加条目';
  @override
  String get listEmpty => '还没有条目';
  @override
  String get listDragHandleLabel => '重新排列条目';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => '快速笔记';
  @override
  String get shortcutNewTodo => '新建待办';
  @override
  String get shortcutNewNote => '新建笔记';
  @override
  String get shortcutNewList => '新建列表';
  @override
  String get shortcutToggleSidebar => '显示或隐藏文件树';
  @override
  String get shortcutEditorSection => '编辑器内';
  @override
  String get shortcutFind => '查找';
  @override
  String get shortcutReplace => '查找并替换';
  @override
  String get shortcutSavingNote => '修改会自动保存：没有保存快捷键。';

  // Editor status bar.
  @override
  String get outlineTooltip => '大纲';
  @override
  String get outlineNoHeadings => '没有标题';
  @override
  String get outlineNoTitle => '（无标题）';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => '粗体';
  @override
  String get toolbarItalic => '斜体';
  @override
  String get toolbarStrikethrough => '删除线';
  @override
  String get toolbarSuperscript => '上标';
  @override
  String get toolbarUnderline => '下划线';
  @override
  String get toolbarLink => '链接';
  @override
  String get toolbarCode => '代码块';
  @override
  String get toolbarImage => '插入图片';
  @override
  String get toolbarHeading => '标题';
  @override
  String get toolbarList => '列表';
  @override
  String get toolbarOrderedList => '编号列表';
  @override
  String get toolbarQuote => '引用';
  @override
  String get toolbarIndent => '增加缩进';
  @override
  String get toolbarOutdent => '减少缩进';
  @override
  String get headingDialogTitle => '标题级别';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => '编辑器工具栏';
  @override
  String get toolbarSettingsHint => '拖动以重新排列；眼睛图标显示或隐藏按钮。';
  @override
  String get toolbarShowButton => '显示';
  @override
  String get toolbarHideButton => '隐藏';
  @override
  String get toolbarResetOrder => '恢复默认顺序';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => '显示预览';
  @override
  String get showEditorTooltip => '显示编辑器';
  @override
  String get enterFullScreenTooltip => '全屏';
  @override
  String get exitFullScreenTooltip => '退出全屏';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '（原始 HTML 表格）';

  // Search (T-M3-05).
  @override
  String get searchHint => '搜索笔记';
  @override
  String get searchModeWords => '词语';
  @override
  String get searchModeContains => '包含';
  @override
  String get searchEmptyHint => '输入以在文库中搜索，或输入 键 = 值 按 frontmatter 筛选';
  @override
  String get searchTooShortHint => '请至少输入 2 个字符';
  @override
  String get searchNoMatches => '没有匹配结果';
  @override
  String get searchLoadMore => '显示更多';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => '替换…';
  @override
  String get replaceInNoteAction => '在此笔记中替换…';
  @override
  String get replaceInThisNote => '在此笔记中替换';
  @override
  String get replaceWithLabel => '替换为';
  @override
  String get replaceCaseSensitive => '区分大小写';
  @override
  String get replaceWholeWordsHint => '只替换整词的完全匹配';
  @override
  String get replaceConfirm => '替换';
  @override
  String get replaceCancel => '关闭';
  @override
  String get replaceUnavailable => '替换功能当前不可用';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => '在笔记中查找';
  @override
  String get editorFindHint => '查找';
  @override
  String get editorReplaceHint => '替换';
  @override
  String get editorFindCaseTooltip => '区分大小写';
  @override
  String get editorFindPreviousTooltip => '上一个匹配';
  @override
  String get editorFindNextTooltip => '下一个匹配';
  @override
  String get editorFindCloseTooltip => '关闭查找';
  @override
  String get editorFindReplaceModeTooltip => '替换模式';
  @override
  String get editorReplaceOneTooltip => '替换此匹配';
  @override
  String get editorReplaceAllTooltip => '替换全部';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => '标签';
  @override
  String get tagsTitle => '标签';
  @override
  String get tagsEmpty => '还没有标签 — 添加 #tag 或 frontmatter 标签';
  @override
  String get tagsBackTooltip => '返回搜索';
  @override
  String get tagsNotesEmpty => '没有带此标签的笔记';
  @override
  String tagsNotesCapped(int limit) => '只列出前 $limit 条 — 搜索该标签以缩小范围';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => '未找到链接目标';
  @override
  String get headingNotFoundTitle => '未找到标题';
  @override
  String get ambiguousLinkTitle => '有多篇笔记匹配';
  @override
  String get openLinkFailed => '无法打开链接';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => '待办';
  @override
  String get todoDone => '已完成';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => '所有日期';
  @override
  String get todoFilter => '筛选';
  @override
  String get todoNoTokens => '此列表中没有标记';
  @override
  String get todoCountOpen => '待办';
  @override
  String get todoCountDone => '已完成';
  @override
  String get todoEmptyOpen => '还没有待办任务';
  @override
  String get todoEmptyDone => '还没有完成的任务';
  @override
  String get todoEmptyFiltered => '没有符合筛选的任务';
  @override
  String get todoTitle => '待办';
  @override
  String get todoAddTooltip => '添加任务';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt 格式';
  @override
  String get todoHelpTooltip => '格式帮助';
  @override
  String get todoHelpIntro =>
      '你的任务是一个纯文本文件，一行一个任务。Niman 替你写下语法，但'
      '一切都不藏：你可以在任何编辑器里改这个文件，Niman 会重新读入。';
  @override
  String get todoHelpFilesTitle => '两个文件';
  @override
  String get todoHelpFilesBody =>
      '未完成任务放在文库根目录的 todo.txt 里。完成时该行移入 done.txt，'
      '让 todo.txt 保持简短。如果一行已完成的任务又回到 todo.txt，Niman '
      '下次读取时会把它归档。';
  @override
  String get todoHelpLineTitle => '一行的结构';
  @override
  String get todoHelpLineBody => '描述之前的内容都是可选的，且按此顺序：';
  @override
  String get todoHelpDoneBody => '把任务标记为已完成。勾选复选框时由 Niman 写入。';
  @override
  String get todoHelpPriority => '从 (A) 到 (Z)';
  @override
  String get todoHelpPriorityBody => '优先级。A 最高。在列表中显示为徽章。';
  @override
  String get todoHelpDatesBody => '完成日期，然后是创建日期。只有一个日期时是创建日期，除非行以 x 开头。';
  @override
  String get todoHelpTokensTitle => '项目、上下文与标签';
  @override
  String get todoHelpTokensBody =>
      '描述中任何带有这些前缀的词都会变成可筛选的芯片。什么都不预设：'
      '你写了，标记就存在。';
  @override
  String get todoHelpProjectBody => '任务属于什么，例如 +厨房 或 +论文。';
  @override
  String get todoHelpContextBody => '在哪里或怎么做，例如 @家 或 @打电话。';
  @override
  String get todoHelpHashtagBody => '自由标签，覆盖上面两类没覆盖的东西。';
  @override
  String get todoHelpTagsTitle => '日期与提醒';
  @override
  String get todoHelpTagsBody =>
      '这些是 键:值 形式的标签。Niman 从任务窗口写入，'
      '并在行中任何位置读回。';
  @override
  String get todoHelpDueBody => '截止日期。决定彩色徽章和按日期的筛选。';
  @override
  String get todoHelpRemBody => '何时发送通知，使用本地时区。锁屏且应用未打开时也会触发。';
  @override
  String get todoHelpRemDesktop =>
      '在桌面端，到点时 Niman 必须处于运行状态：提醒只在应用打开时显示，'
      '应用关闭则不触发。';
  @override
  String get todoHelpOtherBody =>
      '原样保存，让其他 todo.txt 应用的标签能往返。Niman 不处理它们，'
      'rec: 在内：循环任务尚不会循环。';
  @override
  String get todoHelpEditTitle => '在 Niman 之外编辑';
  @override
  String get todoHelpEditBody =>
      '你没有碰过的任务会逐字节原样写回，奇怪的空格也一样。编辑一行，'
      'Niman 只把该行改写为规范形式，其余部分保持不动。';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => '添加任务';
  @override
  String get todoEditTitle => '编辑任务';
  @override
  String get todoDescriptionHint => '描述';
  @override
  String get todoCancel => '取消';
  @override
  String get todoSave => '保存';
  @override
  String get todoEditAction => '编辑';
  @override
  String get todoDeleteAction => '删除';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => '已过期';
  @override
  String get todoDueToday => '今天';
  @override
  String get todoDueNext7 => '未来 7 天';
  @override
  String get todoDueNoDate => '无日期';
  @override
  String get todoRowDue => '截止';
  @override
  String get todoRowDueToday => '今天截止';
  @override
  String get todoSortTooltip => '排序';
  @override
  String get todoSortDue => '截止日期';
  @override
  String get todoSortPriority => '优先级';
  @override
  String get todoSortCreation => '创建日期';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => '无优先级';
  @override
  String get todoNoPriorityShort => '无';
  @override
  String get todoMorePriorities => '更多…';
  @override
  String get todoPriorityTitle => '优先级';
  @override
  String get todoNoDueDate => '无截止日期';
  @override
  String get todoNoReminder => '无提醒';
  @override
  String get todoAddProject => '+ 项目';
  @override
  String get todoAddContext => '@ 上下文';
  @override
  String get todoAddHashtag => '# 标签';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => '任务提醒';
  @override
  String get todoReminderChannelDescription => '为设置了提醒时间的任务发送的定时通知。';
  @override
  String get todoReminderBody => '任务提醒';
  @override
  String get todoReminderFallbackTitle => '任务提醒';
  @override
  String get todoReminderBlocked => '通知已关闭，提醒不会显示。';
  @override
  String get todoReminderBattery => 'Niman 的电池优化处于开启状态。系统可能让应用休眠，使待发送的提醒丢失。';
  @override
  String get todoReminderInexact => '此设备不允许精确闹钟，因此提醒在锁屏时可能晚几分钟到达。';
  @override
  String get reminderShowTokensTitle => '提醒通知中显示标签';
  @override
  String get reminderShowTokensSubtitle =>
      '在通知文字中保留 +项目、@上下文 和 #标签。关闭则只显示你输入的任务。';
  @override
  String get todoReminderFixAction => '打开设置';
  @override
  String get todoReminderDismissAction => '忽略';
  @override
  String get todoReminderDue => '截止';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => '好';
  @override
  String get actionCancel => '取消';
  @override
  String get actionCreate => '创建';
  @override
  String get actionNew => '新建';
  @override
  String get actionSave => '保存';
  @override
  String get actionClear => '清空';
  @override
  String get actionChoose => '选择';
  @override
  String get actionDelete => '删除';
  @override
  String get actionRename => '重命名';
  @override
  String get actionMove => '移动';
  @override
  String get saveAndClose => '保存并关闭';
  @override
  String get closeUnsavedTitle => '有未保存的更改';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '「${names.first}」有尚未保存的更改。关闭前保存吗？';
    }
    return '$names.length 篇笔记有尚未保存的更改。关闭前保存吗？';
  }

  @override
  String get closeSaveFailed => '无法保存；笔记保持打开。';
  @override
  String get actionRestore => '恢复';
  @override
  String get actionEmpty => '清空';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => '隐藏侧栏 (Ctrl+B)';
  @override
  String get showSidebarTooltip => '显示侧栏 (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => '最小化';
  @override
  String get windowMaximizeTooltip => '最大化';
  @override
  String get windowRestoreTooltip => '还原';
  @override
  String get windowCloseTooltip => '关闭';
  @override
  String get tabFiles => '文件';
  @override
  String get tabSearch => '搜索';
  @override
  String get tabSettings => '设置';
  @override
  String get quickNoteTitle => '快速笔记';
  @override
  String get treeEmpty => '还没有笔记';
  @override
  String get selectANote => '选择一篇笔记';
  @override
  String get showListTooltip => '显示列表';
  @override
  String get editRawTooltip => '编辑源码';
  @override
  String get sortAscTooltip => '按 A-Z 排序';
  @override
  String get sortDescTooltip => '按 Z-A 排序';
  @override
  String get newNoteTitle => '新建笔记';
  @override
  String get newFolderTitle => '新建文件夹';
  @override
  String get newNoteHere => '在此新建笔记';
  @override
  String get newFolderHere => '在此新建文件夹';
  @override
  String get newListNoteTitle => '新建列表笔记';
  @override
  String get newListNoteDefault => '我的列表';
  @override
  String get setAsQuickNote => '设为快速笔记';
  @override
  String get currentQuickNote => '当前快速笔记';
  @override
  String get pinnedSection => '已置顶';
  @override
  String pinnedSectionCount(int count) => '已置顶 · $count';
  @override
  String get templateFolderTitle => '模板文件夹';
  @override
  String get newFromTemplateTitle => '从模板新建';
  @override
  String get newFromTemplateHere => '在此从模板新建';
  @override
  String get templateFormTitle => '填写模板';
  @override
  String get templateFormBacklink => '反链自';
  @override
  String get templateFormNoNote => '没有笔记';
  @override
  String get templateFormPickNote => '选择笔记';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => '模板占位符';
  @override
  String get templateHelpIntro => '模板就是一篇带洞的普通笔记。从模板创建笔记会复制它的文字并填上洞。';
  @override
  String get templateHelpUnknown =>
      'Niman 不认识的占位符原样保留，让拼写错误在笔记中可见，而不是'
      '悄悄吞掉一行。';
  @override
  String get templateHelpValuesTitle => '值';
  @override
  String get templateHelpTitleBody => '将用于创建笔记的名称。';
  @override
  String get templateHelpDateBody => '今天，以及现在的时间。两者都接受格式：{{date:YYYY-MM-DD}}。';
  @override
  String get templateHelpNowBody => '日期和时间一起。';
  @override
  String get templateHelpUuidBody => '每次出现都不同的新标识符。';
  @override
  String get templateHelpCounterBody =>
      '按名称计数、跨重启保留的数字：第一篇笔记写 1，下一篇写 2。'
      '同一笔记中的同名写同一个数；可搭配 |pad:3。';
  @override
  String get templateHelpCursorBody =>
      '创建笔记时把光标放在这里；标记本身不写入。第一个标记生效，'
      '无筛选，仅限新建笔记 — 即使自动聚焦关闭，键盘也会弹出。';
  @override
  String get templateHelpDatesTitle => '书写日期';
  @override
  String get templateHelpDatesBody =>
      '这些代表格式中日期的一部分。其余都是字面量，包括单引号内的文字。'
      '月份和星期名称跟随应用语言。';
  @override
  String get templateHelpYear => '年：2026、26';
  @override
  String get templateHelpMonth => '月：03、3、三月、3月';
  @override
  String get templateHelpDay => '日：09、9、星期三、周三';
  @override
  String get templateHelpTime => '时、分、秒';
  @override
  String get templateHelpWeek => 'ISO 周与季度：11、11、1';
  @override
  String get templateHelpFiltersTitle => '过滤器';
  @override
  String get templateHelpFiltersBody => '值后面可以跟过滤器，从左到右依次应用。';
  @override
  String get templateHelpCaseBody => '大写、小写、以及每个词首字母大写 — 你自己大写的词保持原样。';
  @override
  String get templateHelpSlugBody => '文字用于构建维基链接的形式。';
  @override
  String get templateHelpPadBody => '去除两端空格；用零填充到指定宽度；值为空时使用兜底。';
  @override
  String get templateHelpShiftBody => '把日期偏移天、周、月或年 — 下周的课，上个月的归档。';
  @override
  String get templateHelpSnapBody => '把日期对齐到其周、月或年的开始或结束。';
  @override
  String get templateHelpAskTitle => '向你提问';
  @override
  String get templateHelpAskBody =>
      '创建笔记前会显示一个表单，每个问题一个输入框 — 如果模板需要，'
      '还会有一项反链。同一个标签出现两次算一个问题，其答案填入所有'
      '出现处 — 包括文件夹和文件名。';
  @override
  String get templateHelpAskFieldBody => '一个输入框；双冒号后面的文字是它的初始值。';
  @override
  String get templateHelpChoiceBody => '从逗号分隔的列表中选一个。';
  @override
  String get templateHelpWhereTitle => '笔记放在哪里';
  @override
  String get templateHelpWhereBody =>
      '这些不是文字：是指令，写在模板自身 frontmatter 的 niman: 块中。'
      '块执行后被移除，因此不会出现在笔记里。其值可以包含占位符。';
  @override
  String get templateHelpFolderBody => '创建笔记的文件夹，不存在时会自动创建。缺省时笔记落在你当前所在位置。';
  @override
  String get templateHelpFilenameBody => '笔记的名字。声明了它的模板不再询问名称。';
  @override
  String get templateHelpAppendBody => '笔记已存在时追加到它，而不是创建第二篇。这让一个月的会议变成一个文件。';
  @override
  String get templateHelpOpenBody =>
      '笔记已存在时发生什么：编辑器（默认）、预览、或不处理 — '
      '笔记存好，你留在原地。';
  @override
  String get templateHelpAroundTitle => '它从哪里来';
  @override
  String get templateHelpParentBody =>
      '在表单中选择的一篇笔记，默认建议当前屏幕上那篇；'
      '写 [[{{parent}}]] 生成反链。';
  @override
  String get templateHelpFolderValueBody => '笔记最终所在的文件夹。';
  @override
  String get templateHelpClipboardBody => '剪贴板里的内容，以及笔记从另一篇发起时的编辑器选区。';
  @override
  String get templateHelpIncludeTitle => '复用一段内容';
  @override
  String get templateHelpIncludeBody =>
      '粘贴另一个模板，让十个模板共用同一份清单。先在模板文件夹中查找，'
      '.md 可以省略。它自己的问题并入同一个表单。';
  @override
  String get templateHelpExampleTitle => '完整示例';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ 没有模板「$path」';
  @override
  String includeCycle(String path) => '⚠ 「$path」包含自身';
  @override
  String includeTooDeep(String path) => '⚠ 「$path」嵌套过深';
  @override
  String frontmatterInvalid(String reason) => 'frontmatter 未读取：$reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      '「$template」的 frontmatter 未读取，因此其文件夹和文件名没有生效：$reason';
  @override
  String get templatePickerTitle => '选择模板';
  @override
  String templatePickerEmpty(String folder) =>
      '还没有模板。把一篇笔记放进 $folder/，它就会成为模板。';

  // Tree actions.
  @override
  String get actionPin => '置顶';
  @override
  String get actionUnpin => '取消置顶';
  @override
  String get movedToTrash => '已移入回收站';
  @override
  String get deletedMessage => '已删除';
  @override
  String deleteToTrashConfirm(String name) => '$name 将移入 .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name 将被永久删除';
  @override
  String get chooseDestination => '选择目标位置';
  @override
  String get libraryRoot => '文库根目录';
  @override
  String moveTitle(String name) => '移动 $name';
  @override
  String headingLevelLabel(int level) => '标题 $level 级';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty => '还没有快速笔记。选择一篇现有的或新建一篇 — 快速笔记会在这里打开。';
  @override
  String get quickNoteChooseAction => '选择笔记…';
  @override
  String get quickNoteCreateAction => '新建笔记…';
  @override
  String get quickNoteNewTitle => '新建快速笔记';
  @override
  String get quickNotePickerTitle => '选择快速笔记';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => '新建文件夹';
  @override
  String get folderPickerEmpty => '还没有文件夹';
  @override
  String get listFolderTitle => '列表文件夹';

  // Trash (M1).
  @override
  String get trashEmpty => '回收站是空的';
  @override
  String get trashEmptyAction => '清空回收站';
  @override
  String get trashEmptyConfirm => '这将永久删除回收站文件夹里的所有内容，包括 Niman 没有放进去的条目。';
  @override
  String trashDeleteConfirm(String name) => '$name 将被永久删除（无法恢复）';
  @override
  String get trashDeletePermanently => '永久删除';

  // The open/create library screen.
  @override
  String get openLibraryIntro => '把一个 Markdown 笔记文件夹作为文库打开';
  @override
  String get openLibraryExisting => '打开已有的';
  @override
  String get openLibraryCreate => '创建新的';
  @override
  String get openLibraryCreateTitle => '创建新文库';
  @override
  String get openLibraryFolderName => '文件夹名称';
  @override
  String get openLibraryChooseFolder => '选择文库文件夹';
  @override
  String get openLibraryChooseParent => '选择将创建文库的文件夹';
  @override
  String get openLibraryUnsupported => '该文件夹不受支持。请选择设备存储中的文件夹。';
  @override
  String indexingCount(int done, int total) => '已索引 $done / $total 篇笔记';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => '你的文库';
  @override
  String get libraryUnreachable => '无法访问';
  @override
  String get libraryOpenedToday => '今天打开过';
  @override
  String get libraryOpenedYesterday => '昨天打开过';
  @override
  String libraryOpenedDaysAgo(int days) => '$days 天前打开过';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return '${when.year}年$m月$d日打开过';
  }

  @override
  String get libraryOpenNow => '立即打开';
  @override
  String get switchLibraryTitle => '切换文库';
  @override
  String get libraryForget => '移除';
  @override
  String libraryForgetTitle(String name) => '移除「$name」？';
  @override
  String get libraryForgetExplained => '它将从此列表消失。文件夹、笔记和文库设置都留在原地，重新打开即可恢复。';

  // Android storage access.
  @override
  String get storageAccessAction => '授予文件访问权限';
  @override
  String get storageAccessNeeded => '没有「所有文件访问权限」，Niman 无法读取你的笔记。请授权以打开文库。';
  @override
  String get storageAccessExplained =>
      'Niman 把笔记当作普通文件读取，因此 Android 需要授予所有文件访问权限。'
      '不会上传任何东西，且只读取你选择的那个文库文件夹。';
  @override
  String folderAccessDenied(Object error) => '系统未授予该文件夹的访问权限：$error';
  @override
  String folderPickFailed(Object error) => '无法选择文件夹：$error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => '设置';
  @override
  String get libraryPathTitle => '文库路径';
  @override
  String get reindexTitle => '立即重建索引';
  @override
  String get reindexDone => '索引重建完成';
  @override
  String get closeLibraryTitle => '关闭文库';
  @override
  String get exportLogTitle => '导出调试日志';
  @override
  String get exportLogSubtitle => '把已记录的事件保存到你选择的文件';
  @override
  String get exportLogEmpty => '调试日志缓冲区为空';
  @override
  String get quickNoteUnset => '尚未设置';
  @override
  String exportLogDone(Object target) => '调试日志已导出到 $target';
  @override
  String exportLogFailed(Object error) => '导出失败：$error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) => '未找到整词「$term」';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '已在 $notes 篇笔记中替换 $occurrences 处「$term」';
  @override
  String replaceSkipped(int skipped) => '（跳过 $skipped 篇打开的笔记）';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '没有找到整词「$term」的完全匹配'
      '${only == null ? '' : '，$only 中也没有'}';
}
