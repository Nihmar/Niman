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
  String get trashAutoEmptyTitle => '自动清空回收站';
  @override
  String get trashAutoEmptySubtitle => '打开文库时，较早删除的内容将被永久清除';
  @override
  String trashAutoEmptyValue(int days) => days == 0 ? '从不' : '$days 天';
  @override
  String get debugLogsTitle => '调试日志';
  @override
  String get debugLogsSubtitle => '将应用事件记录到内存缓冲区';
  @override
  String get lineNumbersTitle => '行号';
  @override
  String get lineNumbersSubtitle => '在编辑器中显示行号栏';
  @override
  String get readableLineLengthTitle => '易读行宽';
  @override
  String get readableLineLengthSubtitle => '将笔记正文保持在居中的一栏内，而不是铺满整个窗口';
  @override
  String get noteColumnWidthTitle => '栏宽';
  @override
  String get noteColumnWidthSubtitle => '笔记栏的宽度（像素）';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => '打开时弹出键盘';
  @override
  String get keyboardOnOpenSubtitle => '打开笔记时立即弹出键盘（关闭 = 首次输入时弹出）';
  @override
  String get editorKindSource => 'Markdown 源码';
  @override
  String get editorKindWysiwyg => '所见即所得';
  @override
  String get editorKindSourceSubtitle => '按原样显示的 Markdown 源码';
  @override
  String get editorKindWysiwygSubtitle => '就地编辑的格式化文本';
  @override
  String get settingsFolderToCreate => '待创建';
  @override
  String get settingsSearchHint => '搜索设置';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '找到 1 个设置' : '找到 $count 个设置';
  @override
  String get settingsToggleOn => '开';
  @override
  String get settingsToggleOff => '关';
  @override
  String get settingsPreviewEnabledTitle => '预览';
  @override
  String get settingsPreviewEnabledSubtitle => '在源码编辑器旁边显示渲染后的笔记';
  @override
  String get switchToWysiwygTooltip => '切换到所见即所得编辑器';
  @override
  String get switchToSourceTooltip => '切换到 Markdown 源码';
  @override
  String get switchToSourceLabel => '源码';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => '文库 $name';
  @override
  String get settingsGroupLibraryHint => '仅适用于此文库';
  @override
  String get settingsGroupMaintenance => '维护';

  // Settings home rows.
  @override
  String get settingsAreaFolders => '文件夹和路径';
  @override
  String get settingsAreaTrashHistory => '回收站和版本';
  @override
  String get settingsAreaDiagnostics => '诊断和信息';
  @override
  String get settingsAreaKeyboardDisabled => '需要连接的物理键盘';
  @override
  String get settingsSectionUpdates => '更新';
  @override
  String get autoUpdateTitle => '自动更新';
  @override
  String get autoUpdateSubtitle => '启动时及每 6 小时检查 GitHub Releases';
  @override
  String get checkForUpdatesTitle => '检查更新';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version 已发布';
  @override
  String get updateUpToDate => 'Niman 已是最新版本';
  @override
  String get updateCheckFailed => '检查更新失败';
  @override
  String updateSavedTo(Object path) => '更新已保存到 $path';
  @override
  String get updateInstallerStarted => '安装程序已启动';
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
  String get addWordToDictionary => '加入词典';

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
  String get missingNoteLocationTitle => '在以下位置创建缺失的笔记';
  @override
  String get missingNoteLocationRoot => '库根目录';
  @override
  String get missingNoteLocationCurrentFolder => '当前文件夹';
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

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => '还没有录音';
  @override
  String get audioRecord => '录音';
  @override
  String get audioStop => '停止';
  @override
  String get audioPlay => '播放';
  @override
  String get audioDelete => '删除录音';
  @override
  String get audioImport => '导入音频文件';
  @override
  String get audioRecording => '正在录音…';
  @override
  String get audioPermissionDenied => '麦克风权限被拒绝 — 录音需要此权限。';
  @override
  String get newAudioNoteTitle => '新建语音笔记';
  @override
  String get newAudioNoteDefault => '我的录音';
  @override
  String get showAudioTooltip => '显示录音';
  @override
  String get audioMessageHint => '添加备注…';
  @override
  String get audioSend => '发送';
  @override
  String get audioRename => '重命名录音';
  @override
  String get audioDescriptionHint => '描述此录音…';
  @override
  String get audioEditDescription => '编辑描述';
  @override
  String get audioDeleteNote => '删除备注';
  @override
  String get audioEditNote => '编辑备注';
  @override
  String get audioPause => '暂停';
  @override
  String get audioEditTitle => '编辑标题';
  @override
  String get audioTitleHint => '为这段录音添加标题…';
  @override
  String audioUntitled(int n) => '录音 $n';
  @override
  String get audioMoreActions => '更多操作';
  @override
  String get audioDiscardRecording => '放弃录音';
  @override
  String get audioPauseRecording => '暂停录音';
  @override
  String get audioResumeRecording => '继续录音';
  @override
  String get audioRecordingPaused => '已暂停';
  @override
  String get audioSavingRecording => '正在保存…';

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
  String get shortcutNewAudio => '新建语音笔记';
  @override
  String get shortcutToggleSidebar => '显示或隐藏文件树';
  @override
  String get shortcutCloseTab => '关闭当前笔记';
  @override
  String get shortcutNextTab => '下一个打开的笔记';
  @override
  String get shortcutPreviousTab => '上一个打开的笔记';
  @override
  String get shortcutEditorSection => '编辑器内';
  @override
  String get shortcutFormatSection => '格式';
  @override
  String get shortcutFind => '查找';
  @override
  String get shortcutReplace => '查找并替换';
  @override
  String get shortcutSavingNote => '修改会自动保存：没有保存快捷键。';

  // Editor status bar.
  @override
  String get noteStatusLoading => '加载中…';
  @override
  String get noteStatusSaving => '保存中…';
  @override
  String get noteStatusUnsaved => '未保存';
  @override
  String get noteStatusSaved => '已保存';
  @override
  String get noteStatusError => '错误';
  @override
  String get noteNotText => '此文件不是文本笔记，因此 Niman 无法在此显示。';
  @override
  String get noteLoadFailed => '无法打开此笔记。';
  @override
  String wordCount(int count) => '$count 词';
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

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => '工具';
  @override
  String get editorToolsTitle => '编辑器工具';
  @override
  String get toolCountListTitle => '统计列表';
  @override
  String get toolCountListSubtitle => '把各行列出的内容汇总成清单';
  @override
  String get toolCountListNeedsList => '这条笔记里没有可统计的列表';
  @override
  String get tallySourceLabel => '列表';
  @override
  String get tallyCutLabel => '每行读作';
  @override
  String get tallyCutDash => '名称 - 值';
  @override
  String get tallyCutColon => '名称: 值';
  @override
  String get tallyCutCommas => '逗号分隔的值';
  @override
  String get tallyCutWhole => '整行作为一个值';
  @override
  String get tallySortLabel => '排序';
  @override
  String get tallySortCount => '最多的在前';
  @override
  String get tallySortAlphabetical => '按字母顺序';
  @override
  String get tallySortFirstSeen => '按列表顺序';
  @override
  String get tallyInsert => '插入';
  @override
  String get tallyUpdate => '更新';
  @override
  String get tallyNothingToCount => '这里没有可统计的内容';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => '笔记不存在';
  @override
  String missingNoteDialogBody(String path) => '创建"$path"？';
  @override
  String missingNoteFolderMissing(String folder) => '文件夹"$folder"不存在';

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
  String get newItemTooltip => '新建';
  @override
  String get closeMenuTooltip => '关闭';
  @override
  String get newFolderTitle => '新建文件夹';
  @override
  String get newNoteSameFolder => '在同一文件夹中新建笔记';
  @override
  String get newFromTemplateSameFolder => '在同一文件夹中从模板新建';
  @override
  String trashOriginalPath(String path) => '原位置：$path';
  @override
  String get trashOriginalRoot => '\u4f4d\u4e8e\u6587\u5e93\u6839\u76ee\u5f55';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 \u4e2a\u9879\u76ee' : '$count \u4e2a\u9879\u76ee';
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
  String get templateHelpSubtitle => '日期、标题和其他待填值';
  @override
  String get quickNoteSubtitle => '快捷笔记选项卡打开的笔记';
  @override
  String get listFolderSubtitle => '新的任务列表';
  @override
  String get templateFolderSubtitle => '从模板新建的来源';
  @override
  String get attachmentsFolderSubtitle => '插入到笔记中的图片和音频';
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
  String get pinToWidget => '固定到主屏幕组件';
  @override
  String get pinnedForWidget => '已固定：现在请将笔记组件放到主屏幕';
  @override
  String get pinWidgetUnavailable => '主屏幕组件可在 Android 上使用';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => '在文件管理器中显示';
  @override
  String get openInDefaultApp => '用默认应用打开';
  @override
  String get newNoteTabTooltip => '在新标签页中新建笔记';
  @override
  String get openNotesTooltip => '打开的笔记';
  @override
  String get closeTabTooltip => '关闭';
  @override
  String get openInNewTab => '在新标签页中打开';
  @override
  String get splitRight => '向右拆分';
  @override
  String get splitDown => '向下拆分';
  @override
  String get moveToOtherPane => '移到另一个窗格';
  @override
  String get openBeside => '在侧边打开';
  @override
  String get closeAllNotes => '全部关闭';
  @override
  String get sidePanelTooltip => '显示或隐藏侧边栏';
  @override
  String get historyAllVersions => '所有版本';
  @override
  String get commandPaletteTitle => '命令面板';
  @override
  String get goToNoteTitle => '转到笔记';
  @override
  String get paletteGroupNote => '笔记';
  @override
  String get paletteGroupEditor => '编辑器';
  @override
  String get paletteGroupView => '视图';
  @override
  String get paletteGroupLibrary => '资料库';
  @override
  String get paletteGroupGoTo => '转到';
  @override
  String get commandsTitle => '命令';
  @override
  String get commandsIntro => '命令面板只列出在当前位置可以运行的命令。这里是全部命令，以及每条命令何时出现。';
  @override
  String get commandNeedNone => '始终可用';
  @override
  String get commandNeedOpenNote => '需要打开一条笔记';
  @override
  String get commandNeedWideWindow => '仅限宽窗口';
  @override
  String get commandNeedDockRoom => '需要足够容纳侧边面板的宽窗口';
  @override
  String get commandNeedDesktop => '仅限桌面端';
  @override
  String get commandNeedNotInZen => '不在禅模式下';
  @override
  String get commandNeedZenRoom => '桌面端，且有笔记在标签页中打开';
  @override
  String get commandNeedPreview => '预览已开启，且为文本笔记';
  @override
  String get commandNeedTwoEditors => '两个编辑器均已启用';
  @override
  String get paletteHint => '搜索命令和笔记';
  @override
  String get paletteNoResults => '没有匹配项';
  @override
  String get paletteCommands => '命令';
  @override
  String get paletteNotes => '笔记';
  @override
  String get paletteFooter => '↑↓ 移动 · ↵ 使用 · esc 关闭';
  @override
  String get palettePinned => '已固定';
  @override
  String get palettePin => '固定';
  @override
  String get paletteUnpin => '取消固定';
  @override
  String get palettePinFooter => 'alt+P 固定';
  @override
  String get spellCheckScanning => '正在检查笔记…';
  @override
  String get spellCheckAgain => '重新检查';
  @override
  String spellCheckCapped(int count) => '已列出前 $count 个：先修正一些，再重新检查其余的';
  @override
  String get dropHint => '拖放 Markdown 文件以打开，或拖放文件夹以导入';
  @override
  String get importFolderAction => '导入';
  @override
  String dropRejected(String names) => '这里只能打开 Markdown 文件和文件夹：$names';
  @override
  String importFolderTitle(String name) => '导入“$name”？';
  @override
  String importFolderBody(int count) =>
      '其中的 Markdown 文件（$count）会复制到资料库的新文件夹中。拖入的文件夹保持不变。';
  @override
  String importFolderDone(String folder) => '已导入到 $folder';
  @override
  String importFolderEmpty(String name) => '$name 中没有 Markdown 文件';
  @override
  String get openFileTitle => '打开文件';
  @override
  String get outsideFileNote => '不属于任何资料库：原地保存，不建索引，无历史，不跟随链接';
  @override
  String get typewriterOn => '开启打字机模式';
  @override
  String get typewriterOff => '关闭打字机模式';
  @override
  String get typewriterTitle => '打字机模式';
  @override
  String get typewriterSubtitle => '让正在书写的行保持在编辑器中央';
  @override
  String get zenMode => '禅模式';
  @override
  String get zenModeEnter => '进入禅模式';
  @override
  String get zenModeLeave => '退出禅模式';
  @override
  String get keySpace => '空格';
  @override
  String get keyEnter => '回车';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => '退格';
  @override
  String get keyDelete => '删除';
  @override
  String get keyArrowUp => '上';
  @override
  String get keyArrowDown => '下';
  @override
  String get keyArrowLeft => '左';
  @override
  String get keyArrowRight => '右';
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
  String get shortcutNone => '无快捷键';
  @override
  String get shortcutRestoreDefaults => '恢复默认';
  @override
  String get shortcutRestoreDefaultsConfirm => '要把所有快捷键恢复为 Niman 的默认设置吗？';
  @override
  String get shortcutRevert => '恢复为默认';
  @override
  String get shortcutClear => '移除快捷键';
  @override
  String get shortcutCapturePrompt => '请按下按键。Esc 和 Tab 也会被记录：请用“取消”退出。';
  @override
  String get shortcutCaptureNeedsModifier => '请加上 Ctrl、Alt 或 Meta：单独一个键用于输入。';
  @override
  String get shortcutMove => '移过来';
  @override
  String get shortcutUseAnyway => '仍然使用';
  @override
  String get shortcutUndo => '撤销';
  @override
  String get shortcutRedo => '重做';
  @override
  String get shortcutChange => '更改快捷键';
  @override
  String shortcutCaptureTitle(String command) => '“$command”的按键';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys 已属于“$other”。要移到这里吗？“$other”将没有快捷键。';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys 在文本框和编辑器中也是“$what”。在那里将由你的命令接管。';
  @override
  String get openFileMissing => '这篇笔记的文件不在磁盘上';
  @override
  String get openFileFailed => '无法在 Niman 之外打开这篇笔记';

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
  @override
  String get attachmentsFolderTitle => '附件文件夹';

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

  // About (issue #80).
  @override
  String get settingsSectionAbout => '关于';
  @override
  String get versionTitle => '版本';
  @override
  String get changelogTitle => '更新日志';
  @override
  String get changelogEmpty => '暂无更新日志内容';
  @override
  String changelogWhatsNew(String version) => '$version 的新内容';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => '历史记录';
  @override
  String get noteMenuTooltip => '笔记操作';
  @override
  String get historyCurrentVersion => '当前版本';
  @override
  String get historyCurrentSubtitle => '笔记的当前内容';
  @override
  String get historyToday => '今天';
  @override
  String get historyYesterday => '昨天';
  @override
  String get historyReasonSession => '编辑前';
  @override
  String get historyReasonInterval => '编辑中';
  @override
  String get historyReasonRestore => '恢复前';
  @override
  String get historyReasonSync => '同步前';
  @override
  String get historyReasonReplace => '替换前';
  @override
  String get historyReasonUnknown => '已找回';
  @override
  String get historySyncBase => '同步基准';
  @override
  String get historyEmpty =>
      '暂无版本。开始编辑笔记时 Niman 会保留一个版本，之后在书写期间'
      '最多每隔几分钟保留一个。';
  @override
  String historyKept(int kept, int limit) => '已保留 $kept 个版本（上限 $limit 个）';
  @override
  String get historyBaseKept => '同步基准不受上限限制，始终保留。';
  @override
  String get historyOff => '此文库的历史记录已关闭（设置，文库）。';
  @override
  String get historyLoadFailed => '无法读取历史记录';
  @override
  String get historyCompareSubtitle => '与当前版本比较';
  @override
  String get historyTabChanges => '更改';
  @override
  String get historyTabVersion => '版本';
  @override
  String get historyNoChanges => '文本与当前版本相同。';
  @override
  String get historyRestoreAction => '恢复此版本';
  @override
  String historyRestoreConfirmTitle(String when) => '恢复 $when 的版本？';
  @override
  String get historyRestoreConfirmBody => '当前文本会先保存到历史记录中，因此随时可以回退。';
  @override
  String get historyRestoreConfirm => '恢复';
  @override
  String historyRestored(String when) => '已恢复 $when 的版本';
  @override
  String get historyRestoreFailed => '无法恢复该版本';
  @override
  String get actionUndo => '撤销';
  @override
  String diffLineRange(int start, int end) => '第 $start–$end 行';
  @override
  String diffLineSingle(int line) => '第 $line 行';
  @override
  String diffUnchanged(int count) => '$count 行未更改';
  @override
  String get historyTakeHunk => '恢复此处';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? '恢复 1 处更改' : '恢复 $count 处更改';
  @override
  String get historyRestoreSelectedConfirmBody =>
      '所选更改将回到此版本的文本。笔记的当前内容会先保存为一个版本，因此可以撤销。';
  @override
  String get historyNoteChangedReloaded => '你在此期间笔记发生了变化 — 比较已刷新。';
  @override
  String get historyVersionsTitle => '保留版本数';
  @override
  String get historyVersionsSubtitle => '每篇笔记，存于 .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? '无' : '$count';
  @override
  String get historyIntervalTitle => '新版本最短间隔';
  @override
  String get historyIntervalSubtitle => '书写期间生效；开始编辑笔记时总会保留一个版本';
  @override
  String historyIntervalValue(int minutes) => '$minutes 分钟';
  @override
  String get settingsSectionTranscription => '转写';
  @override
  String get transcriptionModelTitle => '模型';
  @override
  String get transcriptionModelNone => '无';
  @override
  String get transcriptionLanguageTitle => '语言';
  @override
  String get transcriptionLanguageSubtitle => '录音中所说的语言。指定语言比自动检测更准确。';
  @override
  String transcriptionLanguageApp(String language) => '与应用相同（$language）';
  @override
  String get transcriptionLanguageDetect => '自动检测';
  @override
  String get transcriptionModelsTitle => '转写模型';
  @override
  String transcriptionModelsUsed(String size) => '已使用 $size';
  @override
  String get transcriptionModelsInstalled => '已下载';
  @override
  String get transcriptionModelsDownloading => '正在下载';
  @override
  String get transcriptionModelsAvailable => '可下载';
  @override
  String get transcriptionModelsFooter => '模型保存在本设备的应用存储中，不会复制到笔记库，也不会同步。';
  @override
  String get transcriptionModelDefault => '默认';
  @override
  String get transcriptionModelSlow => '较慢';
  @override
  String get transcriptionModelHintTiny => '最快，准确度最低';
  @override
  String get transcriptionModelHintBase => '速度与准确度兼顾';
  @override
  String get transcriptionModelHintSmall => '更准确，约慢 3 倍';
  @override
  String get transcriptionModelHintMedium => '非常准确，在手机上较慢';
  @override
  String get transcriptionModelHintLarge => '最准确，需要大量内存';
  @override
  String get transcriptionModelDownload => '下载';
  @override
  String transcriptionModelDeleteTitle(String model) => '删除 $model 模型？';
  @override
  String transcriptionModelDeleteBody(String size) => '将释放 $size。之后可以重新下载该模型。';
  @override
  String get transcriptionModelFailed => '下载失败。请检查网络连接后重试。';
  @override
  String get actionRetry => '重试';
  @override
  String get decimalSeparator => '.';
  @override
  String get transcriptionModelRetrying => '连接中断，正在重试…';
  @override
  String transcriptionModelInterrupted(String progress) => '已暂停：$progress';
  @override
  String get actionResume => '继续';
  @override
  String get audioTranscribe => '转写';
  @override
  String get audioTranscribeUnsupported => '此设备仅支持 WAV 录音';
  @override
  String get transcriptionQueued => '排队中';
  @override
  String get transcriptionPreparing => '正在准备音频…';
  @override
  String transcriptionRunning(int percent) => '正在转写… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '正在下载 $model · $percent%';
  @override
  String get transcriptionSaved => '转写内容已添加到描述';
  @override
  String get transcriptionNoSpeech => '此录音中未识别到语音';
  @override
  String get transcriptionFailed => '转写失败';
  @override
  String get transcriptionPickModelTitle => '选择模型';
  @override
  String get transcriptionPickModelBody => '转写在本设备上进行，录音不会上传。模型只需下载一次。';
  @override
  String get transcriptionPickModelAction => '下载并转写';
  @override
  String get transcriptionModelRecommended => '推荐';
  @override
  String get transcriptionExistingTitle => '此录音已有描述';
  @override
  String get transcriptionExistingBody => '用转写内容替换它，还是将转写内容添加在下方？';
  @override
  String get transcriptionAppend => '添加在下方';
  @override
  String get transcriptionReplace => '替换';
  @override
  String get settingsSectionSync => '同步';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => '此文库尚未设置同步';
  @override
  String get syncNeverSynced => '从未同步';
  @override
  String syncLastSynced(String when) => '同步于 $when';
  @override
  String get syncRunning => '正在同步…';
  @override
  String syncScreenSubtitle(String library) => '文库 $library';
  @override
  String get syncUrlLabel => '文件夹地址';
  @override
  String get syncUrlRequired => '输入服务器地址';
  @override
  String get syncUrlHint => '文件夹必须已存在。请按服务器显示的样子复制地址。';
  @override
  String get syncHttpWarning => '未加密的连接：在 VPN 或本地网络中使用没有问题。';
  @override
  String get syncUserLabel => '用户';
  @override
  String get syncUserHint => '如果服务器不要求凭据，请留空。';
  @override
  String get syncPasswordLabel => '密码';
  @override
  String get syncPasswordHint => '保存在此设备的钥匙串中，绝不写入文库文件。';
  @override
  String get syncPasswordKeepHint => '留空则保留已保存的密码。';
  @override
  String get syncShowPassword => '显示密码';
  @override
  String get syncHidePassword => '隐藏密码';
  @override
  String get syncTestAction => '测试连接';
  @override
  String get syncTesting => '正在测试…';
  @override
  String get syncRetargetWarning => '更换地址或用户后，下次同步将作为首次同步重新开始。';
  @override
  String get syncTestOk => '连接正常';
  @override
  String get syncModeFull => '完整模式';
  @override
  String get syncModeCompatible => '兼容模式';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => '读取、写入和删除';
  @override
  String get syncCapEtags => '文件指纹（ETag）';
  @override
  String get syncCapNoEtags => '无文件指纹（ETag）';
  @override
  String get syncCapNoEtagsDetail => '比较大小和日期；有疑问时重新下载';
  @override
  String get syncCapGuarded => '受保护的写入';
  @override
  String get syncCapUnguarded => '不受保护的写入';
  @override
  String get syncCapUnguardedDetail => '写入前先检查服务器上的文件';
  @override
  String get syncCapMove => '重命名无需重新上传';
  @override
  String get syncCapNoMove => '服务器不支持重命名';
  @override
  String get syncCapNoMoveDetail => '重命名会变为删除加重新上传';
  @override
  String get syncCompatibleNote => '兼容模式下同步效果相同，只是请求会多一些。';
  @override
  String get syncTestInvalidUrl => '地址无效';
  @override
  String get syncTestInvalidUrlHint =>
      '请输入 http:// 或 https:// 地址，地址中不要包含用户名或密码。';
  @override
  String get syncTestOffline => '无法连接服务器';
  @override
  String get syncTestOfflineHint => 'VPN 已开启吗？10.x 或 192.168.x 地址只能在同一网络内访问。';
  @override
  String get syncTestAuth => '用户或密码被拒绝';
  @override
  String get syncTestAuthHint => '请检查后再次测试。';
  @override
  String get syncTestNotFound => '文件夹不存在';
  @override
  String get syncTestNotFoundHint => '请在服务器上创建它，或修正地址。';
  @override
  String get syncTestUnsupported => '不是 WebDAV 文件夹';
  @override
  String get syncTestUnsupportedHint => '服务器有响应，但不是 WebDAV。';
  @override
  String get syncTestFailed => '测试失败';
  @override
  String get syncNowAction => '立即同步';
  @override
  String get syncSectionServer => '服务器';
  @override
  String get syncServerRow => '地址、用户和密码';
  @override
  String get syncRetestTitle => '重新测试服务器';
  @override
  String syncProbedAgo(String when) => '上次测试 $when';
  @override
  String get syncDisconnectTitle => '断开此文库';
  @override
  String get syncDisconnectSubtitle => '文件会保留在本地和服务器上';
  @override
  String get syncDisconnectConfirmTitle => '断开同步？';
  @override
  String get syncDisconnectConfirmBody =>
      '此文库将不再在此设备上同步。不会删除任何文件，本地和服务器上都不会。如果重新连接，首次同步会从头开始。';
  @override
  String get syncDisconnectConfirm => '断开';
  @override
  String get syncFirstTitle => '首次同步';
  @override
  String get syncFirstIntro => '已将文库与服务器上的文件夹进行比较：';
  @override
  String get syncFirstUpload => '待上传';
  @override
  String get syncFirstDownload => '待下载';
  @override
  String get syncFirstBoth => '两边都有';
  @override
  String get syncFirstBothHint => '相同：无需传输。不同：需要解决';
  @override
  String get syncFirstNoDelete => '首次同步不会删除任何内容，本地和服务器上都不会。';
  @override
  String get syncStartAction => '开始';
  @override
  String syncMassTrashTitle(int count) => '将 $count 个文件移入回收站？';
  @override
  String syncMassTrashBody(int count, int total) =>
      '在已同步的 $total 个文件中，有 $count 个在服务器上缺失。这通常意味着地址错误、NAS '
      '磁盘未挂载，或文件夹被误清空。';
  @override
  String get syncMassTrashHint => '如果你确实在其他设备上删除了它们，请确认：它们在这里会移入回收站。';
  @override
  String get syncMassTrashConfirm => '移入回收站';
  @override
  String syncMassDeleteTitle(int count) => '从服务器删除 $count 个文件？';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '在已同步的 $total 个文件中，有 $count 个在本地缺失。如果不是你删除的，请取消并检查文库文件夹。';
  @override
  String get syncMassDeleteConfirm => '从服务器删除';
  @override
  String get syncTooltip => '同步';
  @override
  String get syncStageConnecting => '正在连接服务器…';
  @override
  String get syncStageComparing => '正在与服务器比较…';
  @override
  String syncStageApplying(int done, int total) => '正在同步 · $done / $total';
  @override
  String get syncStatusWarnings => '已同步，但有警告';
  @override
  String syncConflictsHeader(int count) => '本地和服务器上都有更改 · $count';
  @override
  String get syncConflictHint => '两个版本都未被改动';
  @override
  String get syncResolveAction => '解决';
  @override
  String syncFailuresHeader(int count) => '未同步 · $count';
  @override
  String get syncFailuresHint => '将在下次同步时重试';
  @override
  String get syncAbortAuth => '服务器拒绝了密码';
  @override
  String get syncAbortMissingPassword => '没有保存的密码';
  @override
  String get syncAbortOffline => '无法连接服务器';
  @override
  String get syncAbortRemoteMissing => '服务器上的文件夹已不存在';
  @override
  String get syncAbortUnsupported => '服务器不再以 WebDAV 方式工作';
  @override
  String get syncAbortFailed => '同步失败';
  @override
  String get syncAbortNotConfirmed => '同步已取消';
  @override
  String get syncAbortNothingTouched => '没有改动任何文件。你的更改会保留在本地，直到下次同步成功。';
  @override
  String syncLastSuccess(String when) => '上次成功同步 $when';
  @override
  String get syncNoSuccessYet => '尚无成功的同步';
  @override
  String get syncUpdatePasswordAction => '更新密码';
  @override
  String get syncRetryAction => '重试';
  @override
  String get syncOpenSettingsAction => '设置';
  @override
  String get syncCloseAction => '关闭';
  @override
  String get syncDoneSnack => '已同步';
  @override
  String syncTrashedSnack(int count) => '已同步 · $count 个在其他地方删除的文件已移入回收站';
  @override
  String syncConflictsSnack(int count) => '已同步 · $count 个冲突待解决';
  @override
  String get syncShowAction => '显示';
  @override
  String get syncConflictTitle => '解决冲突';
  @override
  String get syncConflictLegend => '标记为 − 的行来自服务器，标记为 + 的行来自此设备。';
  @override
  String get syncConflictBinary => '不是文本文件：请选择要保留的副本。';
  @override
  String get syncConflictKeepNote => '未保留的副本会留在笔记的历史记录中。';
  @override
  String get syncKeepLocal => '保留此设备的版本';
  @override
  String get syncKeepRemote => '保留服务器的版本';
  @override
  String get syncConflictIdentical => '两个版本完全相同';
  @override
  String get syncConflictLoadFailed => '无法读取两个版本';
  @override
  String get syncResolveFailed => '无法解决冲突';
  @override
  String get syncResolved => '冲突已解决';
  @override
  String get syncSectionWhen => '何时同步';
  @override
  String get syncAutoTitle => '自动';
  @override
  String get syncAutoSubtitle => '编辑后、打开时及定期同步';
  @override
  String get syncIntervalTitle => '服务器检查间隔';
  @override
  String get syncIntervalSubtitle => '仅在应用打开时';
  @override
  String get syncIntervalDialogBody =>
      '用于在应用打开时看到其他设备上的更改。选择「从不」时，仅在编辑后和打开时同步。';
  @override
  String syncIntervalMinutes(int count) => '$count 分钟';
  @override
  String get syncIntervalNever => '从不';
  @override
  String get syncWifiOnlyTitle => '仅限 Wi-Fi';
  @override
  String get syncWifiOnlySubtitle => '使用移动数据时仅手动同步';
  @override
  String syncPendingChanges(int count) => '$count 项更改待同步';
  @override
  String syncRetryIn(String wait) => '$wait后重试';
  @override
  String syncWaitSeconds(int seconds) => '$seconds 秒';
  @override
  String syncWaitMinutes(int minutes) => '$minutes 分钟';
  @override
  String get syncWaitingForWifi => '正在等待 Wi-Fi';
  @override
  String get syncWaitingForNetwork => '正在等待网络连接';
  @override
  String get syncMobileDataHint => '「立即同步」仍会使用移动数据。';
  @override
  String get syncQueueKeptHint => '更改会保留在这里，即使关闭应用也不会丢失，服务器响应后会自动发送。';
  @override
  String get syncAutoPaused => '自动同步已暂停';
  @override
  String get syncPausedAuthHint => '更新密码或手动同步后即可恢复。';
  @override
  String get syncPausedServerHint => '修正地址或手动同步后即可恢复。';
  @override
  String get syncPausedConfirmHint => '「立即同步」会先显示将被删除的内容，并请求确认。';
  @override
  String get syncNeedsConfirmation => '等待你的确认';
  @override
  String get syncMergeIntro => '不重叠的更改已自动合并；重叠的部分请选择保留哪一边。';
  @override
  String get syncMergeClean => '两个版本可以自动合并：没有重叠。';
  @override
  String get syncMergeNoBase => '没有可供合并的共同版本，因此需要选择整个文件。';
  @override
  String syncMergeOverlap(int index, int total) => '第 $index 处重叠，共 $total 处';
  @override
  String get syncMergeFromLocal => '来自此设备';
  @override
  String get syncMergeFromRemote => '来自服务器';
  @override
  String get syncMergeRemovedLines => '已删除的行';
  @override
  String get syncMergeKeepLocal => '我的';
  @override
  String get syncMergeKeepRemote => '服务器的';
  @override
  String get syncMergeKeepBoth => '两者';
  @override
  String get syncMergeSave => '保存合并结果';
  @override
  String get syncMergeKeepWhole => '或保留其中一个完整副本';
}
