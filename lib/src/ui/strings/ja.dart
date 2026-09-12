// The Japanese strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: missing_whitespace_between_adjacent_strings,
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class JapaneseStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
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
    '月曜日',
    '火曜日',
    '水曜日',
    '木曜日',
    '金曜日',
    '土曜日',
    '日曜日',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
    '日',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'ごみ箱';
  @override
  String get trashSubtitle => '削除したものを .trash/ に移動（オフ = 完全に削除）';
  @override
  String get debugLogsTitle => 'デバッグログ';
  @override
  String get debugLogsSubtitle => 'アプリのイベントをメモリ上のバッファに記録する';
  @override
  String get lineNumbersTitle => '行番号';
  @override
  String get lineNumbersSubtitle => 'エディタに行番号の列を表示する';
  @override
  String get keyboardOnOpenTitle => '開いたときのキーボード';
  @override
  String get keyboardOnOpenSubtitle => 'ノートを開いた瞬間にキーボードを表示（オフ = 初回入力のとき）';
  @override
  String get editorKindSource => 'Markdown ソース';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'プレビュー';
  @override
  String get settingsPreviewEnabledSubtitle => 'ソースエディタの横にレンダリング済みノートを表示する';
  @override
  String get switchToWysiwygTooltip => 'WYSIWYG エディタに切り替え';
  @override
  String get switchToSourceTooltip => 'Markdown ソースに切り替え';
  @override
  String get wysiwygTooLarge =>
      'このノートは WYSIWYG エディタが大きすぎます。Markdown ソースで開いてください。';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => '外観';
  @override
  String get settingsSectionEditor => 'エディタ';
  @override
  String get settingsSectionLibrary => 'ライブラリ';
  @override
  String get settingsSectionReminders => 'リマインダー';
  @override
  String get settingsSectionShortcuts => 'キーボード';
  @override
  String get keyboardShortcutsTitle => 'キーボードショートカット';
  @override
  String get settingsSectionDiagnostics => '診断';
  @override
  String get settingsSpellCheckTitle => 'スペルチェック';
  @override
  String get settingsSpellCheckSubtitle => '入力しながらスペルミスに下線をつけます。';
  @override
  String get spellCheckDictionaryTitle => '辞書';
  @override
  String get spellCheckDictionarySystem => 'システム既定';
  @override
  String get spellCheckDictionaryChoiceTitle => '辞書を選択';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'このライブラリに使われる各言語を選択してください。単語は選択した辞書のどれかに存在すれば正しく、選択がなければシステム言語が判断します。';
  @override
  String get spellCheckNoDictionaries => 'このシステムで辞書が見つかりませんでした。';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'スペルチェック';
  @override
  String get spellCheckTitle => 'スペル';
  @override
  String get spellCheckEmpty => 'スペルミスはありません。';
  @override
  String get spellCheckUnavailable => 'hunspell がこのシステムにインストールされていません。';
  @override
  String get spellCheckNoSuggestions => '候補なし';
  @override
  String spellCheckCount(int count) => '未確認 $count 件';
  @override
  String spellCheckLine(int line) => '$line 行目';

  @override
  String indentWidthValue(int spaces) => 'スペース $spaces 個';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => '明度';
  @override
  String get themeBrightnessSubtitle => 'ライト、ダーク、またはデバイスの設定に従う';
  @override
  String get themeBrightnessSystem => 'システム';
  @override
  String get themeBrightnessDay => 'ライト';
  @override
  String get themeBrightnessNight => 'ダーク';
  @override
  String get themePaletteTitle => 'カラーパレット';
  @override
  String get themePaletteSubtitle => 'UI とノートの色';
  @override
  String get themePaletteSystem => 'システム';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'UI の文字サイズ';
  @override
  String get uiTextScaleSubtitle => 'ツリー、タブ、ダイアログ; システム設定の上に重ねます';
  @override
  String get noteTextScaleTitle => 'ノートの文字サイズ';
  @override
  String get noteTextScaleSubtitle => 'エディタとプレビューは常に同じです';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'プレビューモード';
  @override
  String get previewModeSubtitle => 'プレビューが画面をエディタと分かち合うか置き換えるか';
  @override
  String get previewModeAuto => '並列表示';
  @override
  String get previewModeSwitch => '全画面';
  @override
  String get splitRatioTitle => '分割幅';
  @override
  String get splitRatioSubtitle => 'プレビューが横にあるときのエディタの比率';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'リンクの形式';
  @override
  String get linkTypeSubtitle => 'エディタのリンクボタンが挿入するもの';
  @override
  String get linkTypeWikilink => 'ウィキリンク';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'インデント幅';
  @override
  String get indentWidthSubtitle => 'エディタでインデント 1 段あたりのスペース数';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => '言語';
  @override
  String get languageSubtitle => 'アプリ自身のテキストの言語';
  @override
  String get languageSystem => 'システム';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => '項目を追加';
  @override
  String get listAddTooltip => '項目を追加';
  @override
  String get listEmpty => 'まだ項目がありません';
  @override
  String get listDragHandleLabel => '項目を並べ替え';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'クイックノート';
  @override
  String get shortcutNewTodo => '新しい TODO';
  @override
  String get shortcutNewNote => '新しいノート';
  @override
  String get shortcutNewList => '新しいリスト';
  @override
  String get shortcutToggleSidebar => 'ファイルツリーの表示 / 非表示';
  @override
  String get shortcutEditorSection => 'エディタ内';
  @override
  String get shortcutFind => '検索';
  @override
  String get shortcutReplace => '検索して置換';
  @override
  String get shortcutSavingNote => '変更は自動保存されます: 保存のショートカットはありません。';

  // Editor status bar.
  @override
  String get outlineTooltip => 'アウトライン';
  @override
  String get outlineNoHeadings => '見出しなし';
  @override
  String get outlineNoTitle => '（無題）';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => '太字';
  @override
  String get toolbarItalic => '斜体';
  @override
  String get toolbarStrikethrough => '取り消し線';
  @override
  String get toolbarSuperscript => '上付き文字';
  @override
  String get toolbarUnderline => '下線';
  @override
  String get toolbarLink => 'リンク';
  @override
  String get toolbarCode => 'コードブロック';
  @override
  String get toolbarImage => '画像の挿入';
  @override
  String get toolbarHeading => '見出し';
  @override
  String get toolbarList => 'リスト';
  @override
  String get toolbarOrderedList => '番号付きリスト';
  @override
  String get toolbarQuote => '引用';
  @override
  String get toolbarIndent => 'インデントを拡大';
  @override
  String get toolbarOutdent => 'インデントを縮小';
  @override
  String get headingDialogTitle => '見出しレベル';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'エディタツールバー';
  @override
  String get toolbarSettingsHint => 'ドラッグして並べ替え、目アイコンでボタンを表示 / 非表示にします。';
  @override
  String get toolbarShowButton => '表示';
  @override
  String get toolbarHideButton => '非表示';
  @override
  String get toolbarResetOrder => '既定に戻す';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'プレビューを表示';
  @override
  String get showEditorTooltip => 'エディタを表示';
  @override
  String get enterFullScreenTooltip => '全画面';
  @override
  String get exitFullScreenTooltip => '全画面を終了';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '（生の HTML テーブル）';

  // Search (T-M3-05).
  @override
  String get searchHint => 'ノートを検索';
  @override
  String get searchModeWords => '単語';
  @override
  String get searchModeContains => '含む';
  @override
  String get searchEmptyHint => '入力してライブラリを検索、または key = value でフロントマターを絞り込み';
  @override
  String get searchTooShortHint => '少なくとも 2 文字入力してください';
  @override
  String get searchNoMatches => '一致はありません';
  @override
  String get searchLoadMore => 'もっと表示';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => '置換…';
  @override
  String get replaceInNoteAction => 'このノートで置換…';
  @override
  String get replaceInThisNote => 'このノートで置換';
  @override
  String get replaceWithLabel => '置換先のテキスト';
  @override
  String get replaceCaseSensitive => '大文字 / 小文字を区別';
  @override
  String get replaceWholeWordsHint => '完全一致の語のみ置換されます';
  @override
  String get replaceConfirm => '置換';
  @override
  String get replaceCancel => '閉じる';
  @override
  String get replaceUnavailable => '現在置換は利用できません';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'ノート内で検索';
  @override
  String get editorFindHint => '検索';
  @override
  String get editorReplaceHint => '置換';
  @override
  String get editorFindCaseTooltip => '大文字 / 小文字を区別';
  @override
  String get editorFindPreviousTooltip => '前の一致';
  @override
  String get editorFindNextTooltip => '次の一致';
  @override
  String get editorFindCloseTooltip => '検索を閉じる';
  @override
  String get editorFindReplaceModeTooltip => '置換モード';
  @override
  String get editorReplaceOneTooltip => 'この一致を置換';
  @override
  String get editorReplaceAllTooltip => 'すべて置換';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'タグ';
  @override
  String get tagsTitle => 'タグ';
  @override
  String get tagsEmpty => 'まだタグがありません — #tag またはフロントマターのタグを追加してください';
  @override
  String get tagsBackTooltip => '検索に戻る';
  @override
  String get tagsNotesEmpty => 'このタグのノートはありません';
  @override
  String tagsNotesCapped(int limit) => '最初の $limit 件のみ表示 — タグを検索して絞り込みしてください';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'リンク先が見つかりません';
  @override
  String get headingNotFoundTitle => '見出しが見つかりません';
  @override
  String get ambiguousLinkTitle => '複数のノートが一致します';
  @override
  String get openLinkFailed => 'リンクを開けませんでした';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => '未完了';
  @override
  String get todoDone => '完了済み';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'すべての日付';
  @override
  String get todoFilter => '絞り込み';
  @override
  String get todoNoTokens => 'このリストにトークンはありません';
  @override
  String get todoCountOpen => '未完了';
  @override
  String get todoCountDone => '完了済み';
  @override
  String get todoEmptyOpen => 'まだ未完了タスクがありません';
  @override
  String get todoEmptyDone => 'まだ完了はありません';
  @override
  String get todoEmptyFiltered => '該当するタスクがありません';
  @override
  String get todoTitle => 'タスク';
  @override
  String get todoAddTooltip => 'タスクを追加';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt フォーマット';
  @override
  String get todoHelpTooltip => 'フォーマット解説';
  @override
  String get todoHelpIntro =>
      'タスクはプレーンテキストの 1 つのファイルで、1 行 1 タスクです。'
      'Niman は文法を書き込みますが、何も隠しません: どのエディタでも'
      '編集でき、Niman はそれを再読み込みします。';
  @override
  String get todoHelpFilesTitle => '2 つのファイル';
  @override
  String get todoHelpFilesBody =>
      '未完了タスクはライブラリ直下の todo.txt にあります。完了すると行は '
      'done.txt に移動し、todo.txt を短く保ちます。完了済みの行が todo.txt '
      'に戻ると、次の読み取り時に Niman がアーカイブします。';
  @override
  String get todoHelpLineTitle => '1 行の構成';
  @override
  String get todoHelpLineBody => '説明より前の中身はすべて任意で、この順序で並べます:';
  @override
  String get todoHelpDoneBody => 'タスクを完了とマークします。チェックボックスにチェックすると Niman が書きます。';
  @override
  String get todoHelpPriority => '(A) から (Z) まで';
  @override
  String get todoHelpPriorityBody => '優先度。A が最高。リストにバッジとして表示されます。';
  @override
  String get todoHelpDatesBody =>
      '完了日、それから作成日。日付が 1 つの場合は作成日を指し、行が x '
      'で始まる場合を除きます。';
  @override
  String get todoHelpTokensTitle => 'プロジェクト、コンテキスト、タグ';
  @override
  String get todoHelpTokensBody =>
      '説明のどこでも、これらのプレフィックス付きの単語は絞り込み可能なチップになります。'
      '何も予約されていません: 書いた瞬間にトークンとして存在します。';
  @override
  String get todoHelpProjectBody => 'タスクが属するもの。例: +キッチン や +論文。';
  @override
  String get todoHelpContextBody => 'どこで / どのようにやるか。例: @自宅 や @電話。';
  @override
  String get todoHelpHashtagBody => '上記 2 つで足りないものを扱う自由なラベル。';
  @override
  String get todoHelpTagsTitle => '日付とリマインダー';
  @override
  String get todoHelpTagsBody =>
      'これらは key:value のタグです。Niman はタスクのダイアログから書き込み、'
      '行のどこに書いてあっても読み込みます。';
  @override
  String get todoHelpDueBody => '期限日。色のバッジと日付の絞り込みを司ります。';
  @override
  String get todoHelpRemBody => '通知を送る時刻（ローカル時間）。画面をロックしてアプリを閉じていても発火します。';
  @override
  String get todoHelpRemDesktop =>
      'デスクトップでは、時刻に達した時点で Niman が起動していないといけない: '
      'リマインダーはアプリが開いている間のみ表示され、閉じているときは発火しません。';
  @override
  String get todoHelpOtherBody =>
      '他の todo.txt アプリのタグが行き来に耐えるよう、書いたままに保存されます。'
      'Niman はこれらに対応しません。rec: を含む: 繰り返しタスクはまだ繰り返しになりません。';
  @override
  String get todoHelpEditTitle => 'Niman の外で編集する';
  @override
  String get todoHelpEditBody =>
      '触っていないタスクは、変なスペースも含めバイト単位でそのまま書き戻されます。'
      '1 行を編集すると、Niman は正規形にしてその行だけを書き直し、'
      'ファイルの残りはそのままにします。';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'タスクを追加';
  @override
  String get todoEditTitle => 'タスクを編集';
  @override
  String get todoDescriptionHint => '説明';
  @override
  String get todoCancel => 'キャンセル';
  @override
  String get todoSave => '保存';
  @override
  String get todoEditAction => '編集';
  @override
  String get todoDeleteAction => '削除';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => '期限超過';
  @override
  String get todoDueToday => '今日';
  @override
  String get todoDueNext7 => '今後 7 日間';
  @override
  String get todoDueNoDate => '日付なし';
  @override
  String get todoRowDue => '期限';
  @override
  String get todoRowDueToday => '今日の期限';
  @override
  String get todoSortTooltip => '並び替え';
  @override
  String get todoSortDue => '期限日';
  @override
  String get todoSortPriority => '優先度';
  @override
  String get todoSortCreation => '作成日';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => '優先度なし';
  @override
  String get todoNoPriorityShort => 'なし';
  @override
  String get todoMorePriorities => 'もっと…';
  @override
  String get todoPriorityTitle => '優先度';
  @override
  String get todoNoDueDate => '期限日なし';
  @override
  String get todoNoReminder => 'リマインダーなし';
  @override
  String get todoAddProject => '+ プロジェクト';
  @override
  String get todoAddContext => '@ コンテキスト';
  @override
  String get todoAddHashtag => '# タグ';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'タスクのリマインダー';
  @override
  String get todoReminderChannelDescription => 'リマインダー時刻付きのタスクへのスケジュール通知。';
  @override
  String get todoReminderBody => 'タスクのリマインダー';
  @override
  String get todoReminderFallbackTitle => 'タスクのリマインダー';
  @override
  String get todoReminderBlocked => '通知がオフなので、リマインダーは表示されません。';
  @override
  String get todoReminderBattery =>
      'Niman のバッテリー最適化が有効です。システムがアプリをスリープさせ、'
      '保留中のリマインダーを失わせる可能性があります。';
  @override
  String get todoReminderInexact =>
      'このデバイスは精密なアラームを許さないので、画面ロック中にもリマインダーは数分遅れて届くことがあります。';
  @override
  String get reminderShowTokensTitle => 'リマインダー通知にタグを含める';
  @override
  String get reminderShowTokensSubtitle =>
      '+プロジェクト、@コンテキスト、#tag を通知テキストに残します。'
      'オフだと入力したタスクのみ表示されます。';
  @override
  String get todoReminderFixAction => '設定を開く';
  @override
  String get todoReminderDismissAction => '破棄';
  @override
  String get todoReminderDue => '期限';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'キャンセル';
  @override
  String get actionCreate => '作成';
  @override
  String get actionNew => '新規';
  @override
  String get actionSave => '保存';
  @override
  String get actionClear => 'クリア';
  @override
  String get actionChoose => '選択';
  @override
  String get actionDelete => '削除';
  @override
  String get actionRename => '名前変更';
  @override
  String get actionMove => '移動';
  @override
  String get saveAndClose => '保存して閉じる';
  @override
  String get closeUnsavedTitle => '未保存の変更があります';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '「${names.first}」にはまだ保存されていない変更があります。'
          '閉じる前に保存しますか?';
    }
    return '$names.length 件のノートにまだ保存されていない変更があります。'
        '閉じる前に保存しますか?';
  }

  @override
  String get closeSaveFailed => '保存できません; ノートは開いたままにします。';
  @override
  String get actionRestore => '復元';
  @override
  String get actionEmpty => '全削除';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'サイドバーを非表示 (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'サイドバーを表示 (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => '最小化';
  @override
  String get windowMaximizeTooltip => '最大化';
  @override
  String get windowRestoreTooltip => '元に戻す';
  @override
  String get windowCloseTooltip => '閉じる';
  @override
  String get tabFiles => 'ファイル';
  @override
  String get tabSearch => '検索';
  @override
  String get tabSettings => '設定';
  @override
  String get quickNoteTitle => 'クイックノート';
  @override
  String get treeEmpty => 'まだノートがありません';
  @override
  String get selectANote => 'ノートを選択してください';
  @override
  String get showListTooltip => 'リストを表示';
  @override
  String get editRawTooltip => 'ソースを編集';
  @override
  String get sortAscTooltip => 'A-Z に並べ替え';
  @override
  String get sortDescTooltip => 'Z-A に並べ替え';
  @override
  String get newNoteTitle => '新しいノート';
  @override
  String get newFolderTitle => '新しいフォルダ';
  @override
  String get newNoteHere => 'ここに新しいノート';
  @override
  String get newFolderHere => 'ここに新しいフォルダ';
  @override
  String get newListNoteTitle => '新しいリストノート';
  @override
  String get newListNoteDefault => 'マイリスト';
  @override
  String get setAsQuickNote => 'クイックノートに設定';
  @override
  String get currentQuickNote => '現在のクイックノート';
  @override
  String get pinnedSection => 'ピン留め';
  @override
  String pinnedSectionCount(int count) => 'ピン留め · $count';
  @override
  String get templateFolderTitle => 'テンプレートフォルダ';
  @override
  String get newFromTemplateTitle => 'テンプレートから新規作成';
  @override
  String get newFromTemplateHere => 'ここにテンプレートから新規作成';
  @override
  String get templateFormTitle => 'テンプレートを埋める';
  @override
  String get templateFormBacklink => 'バックリンク元';
  @override
  String get templateFormNoNote => 'ノートなし';
  @override
  String get templateFormPickNote => 'ノートを選ぶ';
  @override
  String get templateHelpTitle => 'テンプレートのプレースホルダー';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpIntro =>
      'テンプレートは穴だらけの普通のノートです。テンプレートからノートを作ると'
      'そのテキストをコピーして穴を埋めます。';
  @override
  String get templateHelpUnknown =>
      'Niman が知らないプレースホルダーは書いたままにされます。'
      'タイプミスをノート内で顕在化させ、1 行を静かに飲み込まないようにするためです。';
  @override
  String get templateHelpValuesTitle => '値';
  @override
  String get templateHelpTitleBody => 'ノートを作成するときの名前。';
  @override
  String get templateHelpDateBody =>
      '今日、そして現在の時刻。どちらもフォーマットを受け入れます: '
      '{{date:YYYY-MM-DD}}。';
  @override
  String get templateHelpNowBody => '日付と時刻を合わせます。';
  @override
  String get templateHelpUuidBody => '毎回違う新しい識別子。';
  @override
  String get templateHelpCounterBody =>
      '名前ごとに増え、再起動を跨っても保持される数字: 最初のノートは 1、'
      '次は 2 を書きます。同じノート内の同名は同じ数を書きます; '
      '|pad:3 と組み合わせられます。';
  @override
  String get templateHelpCursorBody =>
      'ノートを作成するときにここにカーソルを置きます; マーカー自体は書きません。'
      '最初のマーカーが優先され、フィルターはありません、新規ノートのみです — '
      'オートフォーカスがオフでもキーボードが開きます。';
  @override
  String get templateHelpDatesTitle => '日付の書き方';
  @override
  String get templateHelpDatesBody =>
      'これらはフォーマット内の日付の一部を表します。それ以外はすべてリテラルです、'
      '単一引用符でくくったテキストも同様です。月や曜日の名前はアプリの言語に従います。';
  @override
  String get templateHelpYear => '年: 2026, 26';
  @override
  String get templateHelpMonth => '月: 03, 3, 3月, 03月';
  @override
  String get templateHelpDay => '日: 09, 9, 水曜日, 水';
  @override
  String get templateHelpTime => '時, 分, 秒';
  @override
  String get templateHelpWeek => 'ISO 週と四半期: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'フィルター';
  @override
  String get templateHelpFiltersBody => '値の後ろにフィルターを付けられます。左から右へ適用されます。';
  @override
  String get templateHelpCaseBody =>
      '大文字、小文字、各語の頭文字を大文字に — '
      '自分で大文字にした語はそのままにします。';
  @override
  String get templateHelpSlugBody => 'テキストのリンク用形式。ウィキリンクを作るのに使います。';
  @override
  String get templateHelpPadBody => '両端のスペースを削除; 幅までゼロ埋め; 値が空ならフォールバックを使います。';
  @override
  String get templateHelpShiftBody => '日付を日・週・月・年でずらす — 来週の授業、先月のアーカイブ。';
  @override
  String get templateHelpSnapBody => '日付をその週・月・年の始まりまたは終わりに合わせます。';
  @override
  String get templateHelpAskTitle => 'あなたに何かを尋ねる';
  @override
  String get templateHelpAskBody =>
      'ノートを作る前にフォームが表示され、質問ごとに 1 つの入力枠です — '
      'テンプレートが必要ならバックリンクの項目もあります。'
      '同じラベルを 2 回書くのは質問が 1 つで、その答えはすべての出現箇所 — '
      'フォルダ名やファイル名も含む — に埋められます。';
  @override
  String get templateHelpAskFieldBody => '入力するための枠です; 二重コロンの後ろのテキストが開始値です。';
  @override
  String get templateHelpChoiceBody => 'カンマ区切りのリストから選ぶ。';
  @override
  String get templateHelpWhereTitle => 'ノートの行き先';
  @override
  String get templateHelpWhereBody =>
      'これらはテキストではありません: 指示です、テンプレートのフロントマターの '
      'niman: ブロックの中に置きます。ブロックは実行された後に削除され、'
      'ノートに現れません。その値にはプレースホルダーを含められます。';
  @override
  String get templateHelpFolderBody =>
      'ノートを作成するフォルダ; 存在しなければ作成されます。'
      'ない場合はノートが現在の場所に置かれます。';
  @override
  String get templateHelpFilenameBody =>
      'ノートの名前です; それを宣言したテンプレートには名前を聞かれなくなります。';
  @override
  String get templateHelpAppendBody =>
      'ノートがすでに存在する場合は 2 番目に作成せず追加します。'
      '1 ヶ月の会議を 1 ファイルにするのはこれです。';
  @override
  String get templateHelpOpenBody =>
      'ノートがすでに存在するとき、何をするか: エディタ（既定）、プレビュー、'
      'または何もしない — ノートは保存され、あなたは現在の場所にとどまります。';
  @override
  String get templateHelpAroundTitle => 'どこから来ているか';
  @override
  String get templateHelpParentBody =>
      'フォームで選ぶノート; 画面に映っているものを提案します; '
      '[[{{parent}}]] と書くとバックリンクになります。';
  @override
  String get templateHelpFolderValueBody => 'ノートの行き先になったフォルダ。';
  @override
  String get templateHelpClipboardBody =>
      'クリップボードの中身と、ノートが別のノートから始まったときのエディタの選択範囲。';
  @override
  String get templateHelpIncludeTitle => '部分を再利用する';
  @override
  String get templateHelpIncludeBody =>
      '別のテンプレートを貼り付け、10 個のテンプレートが 1 つのチェックリストを共有できるようにします。'
      'まずテンプレートフォルダで検索し、.md を省略できます。'
      'そのテンプレート自身の質問は同じフォームに合流します。';
  @override
  String get templateHelpExampleTitle => 'すべてを合わせて';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ テンプレート「$path」がありません';
  @override
  String includeCycle(String path) => '⚠ 「$path」は自分自身を含んでいます';
  @override
  String includeTooDeep(String path) => '⚠ 「$path」のネストが深すぎます';
  @override
  String frontmatterInvalid(String reason) => 'フロントマターを読み込めませんでした: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      '「$template」のフロントマターを読み込めなかったため、'
      'そのフォルダやファイル名は何も効果がありません: $reason';
  @override
  String get templatePickerTitle => 'テンプレートを選ぶ';
  @override
  String templatePickerEmpty(String folder) =>
      'まだテンプレートはありません。$folder/ にノートを入れるとテンプレートになります。';

  // Tree actions.
  @override
  String get actionPin => 'ピン留め';
  @override
  String get actionUnpin => 'ピン留めを解除';
  @override
  String get movedToTrash => 'ごみ箱に移動しました';
  @override
  String get deletedMessage => '削除しました';
  @override
  String deleteToTrashConfirm(String name) => '$name を .trash/ に移動します';
  @override
  String deleteForeverConfirm(String name) => '$name を完全に削除します';
  @override
  String get chooseDestination => '移動先を選ぶ';
  @override
  String get libraryRoot => 'ライブラリのルート';
  @override
  String moveTitle(String name) => '$name を移動';
  @override
  String headingLevelLabel(int level) => '見出しレベル $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'まだクイックノートがありません。既存のノートを選ぶか新規作成してください — '
      'クイックノートはここで開きます。';
  @override
  String get quickNoteChooseAction => 'ノートを選ぶ…';
  @override
  String get quickNoteCreateAction => '新しいノートを作成…';
  @override
  String get quickNoteNewTitle => '新しいクイックノート';
  @override
  String get quickNotePickerTitle => 'クイックノートを選ぶ';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => '新しいフォルダ';
  @override
  String get folderPickerEmpty => 'まだフォルダがありません';
  @override
  String get listFolderTitle => 'リストフォルダ';

  // Trash (M1).
  @override
  String get trashEmpty => 'ごみ箱は空です';
  @override
  String get trashEmptyAction => 'ごみ箱を空にする';
  @override
  String get trashEmptyConfirm =>
      'ごみ箱フォルダの中身をすべて完全に削除します。'
      'Niman がそこに置かなかった項目も含みます。';
  @override
  String trashDeleteConfirm(String name) => '$name を完全に削除します（復元できません）';
  @override
  String get trashDeletePermanently => '完全に削除';

  // The open/create library screen.
  @override
  String get openLibraryIntro => 'Markdown ノートのフォルダをライブラリとして開く';
  @override
  String get openLibraryExisting => '既存のを開く';
  @override
  String get openLibraryCreate => '新規作成';
  @override
  String get openLibraryCreateTitle => '新しいライブラリを作成';
  @override
  String get openLibraryFolderName => 'フォルダ名';
  @override
  String get openLibraryChooseFolder => 'ライブラリのフォルダを選ぶ';
  @override
  String get openLibraryChooseParent => 'ライブラリを作成するフォルダを選ぶ';
  @override
  String get openLibraryUnsupported =>
      'そのフォルダはサポートされていません。デバイス保存内のフォルダを選んでください。';
  @override
  String indexingCount(int done, int total) => '$done / $total 件のノート';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'あなたのライブラリ';
  @override
  String get libraryUnreachable => 'アクセスできません';
  @override
  String get libraryOpenedToday => '今日開いた';
  @override
  String get libraryOpenedYesterday => '昨日開いた';
  @override
  String libraryOpenedDaysAgo(int days) => '$days 日前に開いた';
  @override
  String libraryOpenedOn(DateTime when) =>
      '${when.year} 年 ${when.month} 月 ${when.day} 日に開いた';
  @override
  String get libraryOpenNow => '今開く';
  @override
  String get switchLibraryTitle => 'ライブラリを切り替え';
  @override
  String get libraryForget => '忘れる';
  @override
  String libraryForgetTitle(String name) => '「$name」を忘れませんか?';
  @override
  String get libraryForgetExplained =>
      'このリストから消えます。フォルダ、ノート、ライブラリ設定はそのままに、'
      '再度開くと戻ります。';

  // Android storage access.
  @override
  String get storageAccessAction => 'ファイルアクセスを許可';
  @override
  String get storageAccessNeeded =>
      '「すべてのファイルへのアクセス」がないと、Niman はあなたのノートを読み取れません。'
      'ライブラリを開くため許可してください。';
  @override
  String get storageAccessExplained =>
      'Niman はノートを普通のファイルとして読むため、Android にすべてのファイルへのアクセスを許可する必要があります。'
      '何もアップロードされず、選択したライブラリフォルダのみが読み取られます。';
  @override
  String folderAccessDenied(Object error) =>
      'システムがフォルダへのアクセスを許可しませんでした: $error';
  @override
  String folderPickFailed(Object error) => 'フォルダの選択に失敗しました: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => '設定';
  @override
  String get libraryPathTitle => 'ライブラリのパス';
  @override
  String get reindexTitle => '今すぐ再インデックス';
  @override
  String get reindexDone => '再インデックス完了';
  @override
  String get closeLibraryTitle => 'ライブラリを閉じる';
  @override
  String get exportLogTitle => 'デバッグログをエクスポート';
  @override
  String get exportLogSubtitle => '記録されたイベントを選択したファイルに保存';
  @override
  String get exportLogEmpty => 'デバッグログバッファは空です';
  @override
  String get quickNoteUnset => '未設定';
  @override
  String exportLogDone(Object target) => 'デバッグログを $target にエクスポートしました';
  @override
  String exportLogFailed(Object error) => 'エクスポートに失敗しました: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) => '語全体として「$term」が見つかりません';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '「$term」の $occurrences 箇所を $notes 件のノートに置換しました';
  @override
  String replaceSkipped(int skipped) => '（$skipped 件の開いているノートをスキップ）';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '語全体「$term」の完全一致はありません'
      '${only == null ? '' : ' — $only 内には'}';
}
