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
  String get trashAutoEmptyTitle => 'ごみ箱の自動削除';
  @override
  String get trashAutoEmptySubtitle => 'ライブラリを開くと、古い削除は完全に消えます';
  @override
  String trashAutoEmptyValue(int days) => days == 0 ? 'しない' : '$days 日';
  @override
  String get debugLogsTitle => 'デバッグログ';
  @override
  String get debugLogsSubtitle => 'アプリのイベントをメモリ上のバッファに記録する';
  @override
  String get lineNumbersTitle => '行番号';
  @override
  String get lineNumbersSubtitle => 'エディタに行番号の列を表示する';
  @override
  String get readableLineLengthTitle => '読みやすい行の長さ';
  @override
  String get readableLineLengthSubtitle => 'ノートの本文をウィンドウの全幅ではなく中央の列に収める';
  @override
  String get noteColumnWidthTitle => '列の幅';
  @override
  String get noteColumnWidthSubtitle => 'ノートの列の幅（ピクセル）';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => '開いたときのキーボード';
  @override
  String get keyboardOnOpenSubtitle => 'ノートを開いた瞬間にキーボードを表示（オフ = 初回入力のとき）';
  @override
  String get editorKindSource => 'Markdown ソース';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => '書いたままのMarkdownソース';
  @override
  String get editorKindWysiwygSubtitle => 'その場で編集する整形済みテキスト';
  @override
  String get settingsFolderToCreate => '未作成';
  @override
  String get settingsSearchHint => '設定を検索';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1件の設定が見つかりました' : '$count件の設定が見つかりました';
  @override
  String get settingsToggleOn => 'オン';
  @override
  String get settingsToggleOff => 'オフ';
  @override
  String get switchToWysiwygTooltip => 'WYSIWYG エディタに切り替え';
  @override
  String get switchToSourceTooltip => 'Markdown ソースに切り替え';
  @override
  String get switchToSourceLabel => 'ソース';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'ライブラリ $name';
  @override
  String get settingsGroupLibraryHint => 'このライブラリにのみ適用';
  @override
  String get settingsGroupMaintenance => 'メンテナンス';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'フォルダとパス';
  @override
  String get settingsAreaTrashHistory => 'ごみ箱と履歴';
  @override
  String get settingsAreaDiagnostics => '診断と情報';
  @override
  String get settingsAreaKeyboardDisabled => '接続された物理キーボードが必要です';
  @override
  String get settingsSectionUpdates => 'アップデート';
  @override
  String get autoUpdateTitle => '自動アップデート';
  @override
  String get autoUpdateSubtitle => '起動時と 6 時間ごとに GitHub Releases を確認';
  @override
  String get checkForUpdatesTitle => 'アップデートを確認';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version が利用可能です';
  @override
  String get updateUpToDate => 'Niman は最新です';
  @override
  String get updateCheckFailed => 'アップデートの確認に失敗しました';
  @override
  String updateSavedTo(Object path) => 'アップデートを $path に保存しました';
  @override
  String get updateInstallerStarted => 'インストーラーを起動しました';
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
  String get addWordToDictionary => '辞書に追加';

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
  String get missingNoteLocationTitle => '存在しないノートを作成する場所';
  @override
  String get missingNoteLocationRoot => 'ライブラリルート';
  @override
  String get missingNoteLocationCurrentFolder => '現在のフォルダ';
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

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => '録音はまだありません';
  @override
  String get audioRecord => '録音';
  @override
  String get audioStop => '停止';
  @override
  String get audioPlay => '再生';
  @override
  String get audioDelete => '録音を削除';
  @override
  String get audioImport => '音声ファイルをインポート';
  @override
  String get audioRecording => '録音中…';
  @override
  String get audioPermissionDenied => 'マイクの権限がありません — 録音に必要です。';
  @override
  String get newAudioNoteTitle => '新しい音声ノート';
  @override
  String get newAudioNoteDefault => '録音';
  @override
  String get showAudioTooltip => '録音を表示';
  @override
  String get audioMessageHint => 'メモを入力…';
  @override
  String get audioSend => '送信';
  @override
  String get audioRename => '録音の名前を変更';
  @override
  String get audioDescriptionHint => 'この録音の説明を入力…';
  @override
  String get audioEditDescription => '説明を編集';
  @override
  String get audioDeleteNote => 'メモを削除';
  @override
  String get audioEditNote => 'メモを編集';
  @override
  String get audioPause => '一時停止';
  @override
  String get audioEditTitle => 'タイトルを編集';
  @override
  String get audioTitleHint => 'この録音のタイトル…';
  @override
  String audioUntitled(int n) => '録音 $n';
  @override
  String get audioMoreActions => 'その他の操作';
  @override
  String get audioDiscardRecording => '録音を破棄';
  @override
  String get audioPauseRecording => '録音を一時停止';
  @override
  String get audioResumeRecording => '録音を再開';
  @override
  String get audioRecordingPaused => '一時停止中';
  @override
  String get audioSavingRecording => '保存中…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'クイックノート';
  @override
  String get trayOpen => 'Niman を開く';
  @override
  String get trayQuit => '終了';
  @override
  String get closeToTrayTitle => '閉じるとトレイに入れる';
  @override
  String get closeToTraySubtitle =>
      'ウィンドウの × で Niman を隠し、実行したままにします。リマインダーはそのまま届きます。終了はトレイのメニューから。';
  @override
  String get shortcutNewTodo => '新しい TODO';
  @override
  String get shortcutNewNote => '新しいノート';
  @override
  String get shortcutNewList => '新しいリスト';
  @override
  String get shortcutNewAudio => '新しい音声ノート';
  @override
  String get shortcutToggleSidebar => 'ファイルツリーの表示 / 非表示';
  @override
  String get shortcutCloseTab => '現在のノートを閉じる';
  @override
  String get shortcutNextTab => '次の開いているノート';
  @override
  String get shortcutPreviousTab => '前の開いているノート';
  @override
  String get shortcutEditorSection => 'エディタ内';
  @override
  String get shortcutFormatSection => '書式';
  @override
  String get shortcutFind => '検索';
  @override
  String get shortcutReplace => '検索して置換';
  @override
  String get shortcutSavingNote => '変更は自動保存されます: 保存のショートカットはありません。';

  // Editor status bar.
  @override
  String get noteStatusLoading => '読み込み中…';
  @override
  String get noteStatusSaving => '保存中…';
  @override
  String get noteStatusUnsaved => '未保存';
  @override
  String get noteStatusSaved => '保存済み';
  @override
  String get noteStatusError => 'エラー';
  @override
  String get noteNotText => 'このファイルはテキストのノートではないため、Niman ではここに表示できません。';
  @override
  String get noteLoadFailed => 'このノートを開けませんでした。';
  @override
  String wordCount(int count) => '$count 語';
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

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'ツール';
  @override
  String get editorToolsTitle => 'エディタのツール';
  @override
  String get toolCountListTitle => 'リストを集計';
  @override
  String get toolCountListSubtitle => '各行が挙げているものを合計し、チェックリストにします';
  @override
  String get toolCountListNeedsList => 'このノートには集計できるリストがありません';
  @override
  String get tallySourceLabel => 'リスト';
  @override
  String get tallyCutLabel => '各行の読み方';
  @override
  String get tallyCutDash => '名前 - 値';
  @override
  String get tallyCutColon => '名前: 値';
  @override
  String get tallyCutCommas => 'カンマ区切りの値';
  @override
  String get tallyCutWhole => '行全体を1つの値として';
  @override
  String get tallySortLabel => '並び順';
  @override
  String get tallySortCount => '多い順';
  @override
  String get tallySortAlphabetical => '名前順';
  @override
  String get tallySortFirstSeen => 'リストの順';
  @override
  String get tallyInsert => '挿入';
  @override
  String get tallyUpdate => '更新';
  @override
  String get tallyNothingToCount => 'ここには集計するものがありません';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'ノートが存在しません';
  @override
  String missingNoteDialogBody(String path) => '"$path" を作成しますか？';
  @override
  String missingNoteFolderMissing(String folder) => 'フォルダ "$folder" は存在しません';

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
  String get newItemTooltip => '新規';
  @override
  String get closeMenuTooltip => '閉じる';
  @override
  String get newFolderTitle => '新しいフォルダ';
  @override
  String get newNoteSameFolder => '同じフォルダーに新規ノート';
  @override
  String get newFromTemplateSameFolder => '同じフォルダーにテンプレートから作成';
  @override
  String trashOriginalPath(String path) => '元の場所: $path';
  @override
  String get trashOriginalRoot => 'ライブラリのルートにあった';
  @override
  String trashItemCount(int count) => count == 1 ? '1\u4ef6' : '$count\u4ef6';
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
  @override
  String get templateHelpSubtitle => '日付、タイトル、その他の入力値';
  @override
  String get quickNoteSubtitle => 'クイックノートタブが開くノート';
  @override
  String get listFolderSubtitle => '新しいタスクリスト';
  @override
  String get templateFolderSubtitle => 'テンプレートから新規の供給元';
  @override
  String get attachmentsFolderSubtitle => 'ノートに挿入された画像と音声';

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
  String get pinToWidget => 'ホームウィジェットにピン留め';
  @override
  String get pinnedForWidget => 'ピン留めしました: ノートウィジェットをホーム画面に配置してください';
  @override
  String get pinWidgetUnavailable => 'ホーム画面のウィジェットはAndroidで利用できます';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'ファイルマネージャーで表示';
  @override
  String get openInDefaultApp => '既定のアプリで開く';
  @override
  String get newNoteTabTooltip => '新しいタブで新しいノート';
  @override
  String get openNotesTooltip => '開いているノート';
  @override
  String get closeTabTooltip => '閉じる';
  @override
  String get openInNewTab => '新しいタブで開く';
  @override
  String get splitRight => '右に分割';
  @override
  String get splitDown => '下に分割';
  @override
  String get moveToOtherPane => 'もう一方のペインへ移動';
  @override
  String get openBeside => '横に開く';
  @override
  String get closeAllNotes => 'すべて閉じる';
  @override
  String get sidePanelTooltip => 'サイドパネルの表示・非表示';
  @override
  String get historyAllVersions => 'すべてのバージョン';
  @override
  String get commandPaletteTitle => 'コマンドパレット';
  @override
  String get goToNoteTitle => 'ノートへ移動';
  @override
  String get paletteGroupNote => 'ノート';
  @override
  String get paletteGroupEditor => 'エディタ';
  @override
  String get paletteGroupView => '表示';
  @override
  String get paletteGroupLibrary => 'ライブラリ';
  @override
  String get paletteGroupGoTo => '移動';
  @override
  String get commandsTitle => 'コマンド';
  @override
  String get commandsIntro =>
      'コマンドパレットには、いまいる場所で実行できるコマンドだけが表示されます。ここにはすべてのコマンドと、それぞれが表示される条件があります。';
  @override
  String get commandNeedNone => '常に利用可能';
  @override
  String get commandNeedOpenNote => 'ノートを開いている必要があります';
  @override
  String get commandNeedWideWindow => '広いウィンドウのみ';
  @override
  String get commandNeedDockRoom => 'サイドパネルが入る幅のウィンドウが必要です';
  @override
  String get commandNeedDesktop => 'デスクトップのみ';
  @override
  String get commandNeedNotInZen => '禅モード以外';
  @override
  String get commandNeedZenRoom => 'デスクトップで、タブにノートを開いているとき';
  @override
  String get commandNeedPreview => 'プレビューが有効で、テキストノートのとき';
  @override
  String get commandNeedTwoEditors => '両方のエディターが有効なとき';
  @override
  String get paletteHint => 'コマンドとノートを検索';
  @override
  String get paletteNoResults => '一致するものがありません';
  @override
  String get paletteCommands => 'コマンド';
  @override
  String get paletteNotes => 'ノート';
  @override
  String get paletteFooter => '↑↓ で移動 · ↵ で実行 · esc で閉じる';
  @override
  String get paletteFooterTouch => 'タップで実行 · ピンで上に固定';
  @override
  String get palettePinned => 'ピン留め';
  @override
  String get palettePin => 'ピン留め';
  @override
  String get paletteUnpin => '解除';
  @override
  String get palettePinFooter => 'alt+P でピン留め';
  @override
  String get spellCheckScanning => 'ノートを確認中…';
  @override
  String get spellCheckAgain => 'もう一度確認';
  @override
  String spellCheckCapped(int count) =>
      '最初の $count 件を表示しています。いくつか直してから、残りのためにもう一度確認してください';
  @override
  String get dropHint => 'Markdown ファイルをドロップして開くか、フォルダーをドロップして読み込みます';
  @override
  String get dropNothing => 'そのドロップでデスクトップからファイルは渡されませんでした。';
  @override
  String get importFolderAction => '読み込む';
  @override
  String dropRejected(String names) =>
      'ここで開けるのは Markdown ファイルとフォルダーだけです：$names';
  @override
  String importFolderTitle(String name) => '「$name」を読み込みますか？';
  @override
  String importFolderBody(int count) =>
      'その Markdown ファイル（$count）がライブラリの新しいフォルダーにコピーされます。ドロップしたフォルダーはそのままです。';
  @override
  String importFolderDone(String folder) => '$folder に読み込みました';
  @override
  String importFolderEmpty(String name) => '$name に Markdown ファイルはありません';
  @override
  String get openFileTitle => 'ファイルを開く';
  @override
  String get outsideFileNote => 'ライブラリ外：その場所に保存。索引なし、履歴なし、リンクはたどりません';
  @override
  String get typewriterOn => 'タイプライターモードをオンにする';
  @override
  String get typewriterOff => 'タイプライターモードをオフにする';
  @override
  String get typewriterTitle => 'タイプライターモード';
  @override
  String get formatNoteTitle => 'Markdown を整える';
  @override
  String get formatNoteDone => 'ノートを整えました。';
  @override
  String get formatNoteAlreadyTidy => 'ノートはすでに整っていました。';
  @override
  String get typewriterSubtitle => '書いている行をエディタの中央に保つ';
  @override
  String get zenMode => 'Zen モード';
  @override
  String get zenModeEnter => 'Zen モードに入る';
  @override
  String get zenModeLeave => 'Zen モードを終了';
  @override
  String get keySpace => 'Space';
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
  String get shortcutNone => 'ショートカットなし';
  @override
  String get shortcutRestoreDefaults => '既定に戻す';
  @override
  String get shortcutRestoreDefaultsConfirm => 'すべてのショートカットを Niman の既定に戻しますか？';
  @override
  String get shortcutRevert => '既定に戻す';
  @override
  String get shortcutClear => 'ショートカットを削除';
  @override
  String get shortcutCapturePrompt =>
      'キーを押してください。Esc と Tab も記録されます。終了は「キャンセル」で。';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Ctrl、Alt、Meta のいずれかを加えてください。単独のキーは入力用です。';
  @override
  String get shortcutMove => '移動する';
  @override
  String get shortcutUseAnyway => 'それでも使う';
  @override
  String get shortcutUndo => '元に戻す';
  @override
  String get shortcutRedo => 'やり直す';
  @override
  String get shortcutChange => 'ショートカットを変更';
  @override
  String shortcutCaptureTitle(String command) => '「$command」のキー';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys はすでに「$other」に割り当てられています。ここへ移動しますか？「$other」はショートカットなしになります。';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys はテキスト欄とエディタでは「$what」でもあります。そこでもあなたのコマンドが優先されます。';
  @override
  String get openFileMissing => 'このノートのファイルがディスクにありません';
  @override
  String get openFileFailed => 'このノートを Niman の外で開けませんでした';

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
  @override
  String get attachmentsFolderTitle => '添付ファイルフォルダ';

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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'アプリについて';
  @override
  String get versionTitle => 'バージョン';
  @override
  String get changelogTitle => '変更履歴';
  @override
  String get changelogEmpty => '変更履歴の項目がありません';
  @override
  String changelogWhatsNew(String version) => 'バージョン $version の新機能';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => '履歴';
  @override
  String get noteMenuTooltip => 'ノートの操作';
  @override
  String get historyCurrentVersion => '現在のバージョン';
  @override
  String get historyCurrentSubtitle => '現在のノートの内容';
  @override
  String get historyToday => '今日';
  @override
  String get historyYesterday => '昨日';
  @override
  String get historyReasonSession => '編集前';
  @override
  String get historyReasonInterval => '編集中';
  @override
  String get historyReasonRestore => '復元前';
  @override
  String get historyReasonSync => '同期前';
  @override
  String get historyReasonReplace => '置換前';
  @override
  String get historyReasonUnknown => '回復';
  @override
  String get historySyncBase => '同期ベース';
  @override
  String get historyEmpty =>
      'まだバージョンはありません。Niman はノートの編集を始めたときに '
      '1 つ保存し、その後は入力中に数分ごとに最大 1 つ保存します。';
  @override
  String historyKept(int kept, int limit) => '$limit 件中 $kept 件のバージョンを保持';
  @override
  String get historyBaseKept => '同期ベースは上限を超えても保持されます。';
  @override
  String get historyOff => 'このライブラリでは履歴がオフです（設定、ライブラリ）。';
  @override
  String get historyLoadFailed => '履歴を読み込めませんでした';
  @override
  String get historyCompareSubtitle => '現在のバージョンとの比較';
  @override
  String get historyTabChanges => '変更点';
  @override
  String get historyTabVersion => 'バージョン';
  @override
  String get historyNoChanges => '現在のバージョンと同じテキストです。';
  @override
  String get historyRestoreAction => 'このバージョンを復元';
  @override
  String historyRestoreConfirmTitle(String when) => '$when のバージョンを復元しますか？';
  @override
  String get historyRestoreConfirmBody => '現在のテキストは先に履歴へ保存されるため、いつでも元に戻せます。';
  @override
  String get historyRestoreConfirm => '復元';
  @override
  String historyRestored(String when) => '$when のバージョンを復元しました';
  @override
  String get historyRestoreFailed => 'バージョンを復元できませんでした';
  @override
  String get actionUndo => '元に戻す';
  @override
  String diffLineRange(int start, int end) => '$start–$end 行目';
  @override
  String diffLineSingle(int line) => '$line 行目';
  @override
  String diffUnchanged(int count) => '変更のない $count 行';
  @override
  String get historyTakeHunk => 'ここを復元';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? '1 件の変更を復元' : '$count 件の変更を復元';
  @override
  String get historyRestoreSelectedConfirmBody =>
      '選んだ変更はこのバージョンの文章に戻ります。現在のノートはまずバージョンとして保存されるので、元に戻せます。';
  @override
  String get historyNoteChangedReloaded => 'ここにいる間にノートが変更されました — 比較を更新しました。';
  @override
  String get historyVersionsTitle => '保持するバージョン数';
  @override
  String get historyVersionsSubtitle => 'ノートごとに .history/ に保存';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'なし' : '$count';
  @override
  String get historyIntervalTitle => '新しいバージョンの最短間隔';
  @override
  String get historyIntervalSubtitle => '入力中に適用。ノートの編集を始めたときは必ず 1 つ保存されます';
  @override
  String historyIntervalValue(int minutes) => '$minutes 分';
  @override
  String get settingsSectionTranscription => '文字起こし';
  @override
  String get transcriptionModelTitle => 'モデル';
  @override
  String get transcriptionModelNone => 'なし';
  @override
  String get transcriptionLanguageTitle => '言語';
  @override
  String get transcriptionLanguageSubtitle =>
      '録音で話されている言語です。自動検出より指定したほうが正確です。';
  @override
  String transcriptionLanguageApp(String language) => 'アプリと同じ（$language）';
  @override
  String get transcriptionLanguageDetect => '自動検出';
  @override
  String get transcriptionModelsTitle => '文字起こしモデル';
  @override
  String transcriptionModelsUsed(String size) => '$size 使用中';
  @override
  String get transcriptionModelsInstalled => 'ダウンロード済み';
  @override
  String get transcriptionModelsDownloading => 'ダウンロード中';
  @override
  String get transcriptionModelsAvailable => '利用可能';
  @override
  String get transcriptionModelsFooter =>
      'モデルはこのデバイスのアプリ用ストレージに保存されます。ライブラリにはコピーも同期もされません。';
  @override
  String get transcriptionModelDefault => 'デフォルト';
  @override
  String get transcriptionModelSlow => '低速';
  @override
  String get transcriptionModelHintTiny => '最速、精度は最も低い';
  @override
  String get transcriptionModelHintBase => '速度と精度のバランスが良い';
  @override
  String get transcriptionModelHintSmall => 'より正確、約 3 倍遅い';
  @override
  String get transcriptionModelHintMedium => 'とても正確、スマートフォンでは遅い';
  @override
  String get transcriptionModelHintLarge => '最も正確、大量のメモリが必要';
  @override
  String get transcriptionModelDownload => 'ダウンロード';
  @override
  String transcriptionModelDeleteTitle(String model) => '$model モデルを削除しますか？';
  @override
  String transcriptionModelDeleteBody(String size) =>
      '$size が解放されます。モデルは後でもう一度ダウンロードできます。';
  @override
  String get transcriptionModelFailed => 'ダウンロードに失敗しました。接続を確認してもう一度お試しください。';
  @override
  String get actionRetry => '再試行';
  @override
  String get decimalSeparator => '.';
  @override
  String get transcriptionModelRetrying => '接続が切れました。再試行しています…';
  @override
  String transcriptionModelInterrupted(String progress) => '一時停止中：$progress';
  @override
  String get actionResume => '再開';
  @override
  String get audioTranscribe => '文字起こし';
  @override
  String get audioTranscribeUnsupported => 'このデバイスでは WAV 録音のみ対応';
  @override
  String get transcriptionQueued => '待機中';
  @override
  String get transcriptionPreparing => '音声を準備しています…';
  @override
  String transcriptionRunning(int percent) => '文字起こし中… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model をダウンロード中 · $percent%';
  @override
  String get transcriptionSaved => '文字起こしを説明に追加しました';
  @override
  String get transcriptionNoSpeech => 'この録音では音声が認識されませんでした';
  @override
  String get transcriptionFailed => '文字起こしに失敗しました';
  @override
  String get transcriptionPickModelTitle => 'モデルを選択';
  @override
  String get transcriptionPickModelBody =>
      '文字起こしはこのデバイス上で行われ、録音がアップロードされることはありません。モデルのダウンロードは一度だけです。';
  @override
  String get transcriptionPickModelAction => 'ダウンロードして文字起こし';
  @override
  String get transcriptionModelRecommended => 'おすすめ';
  @override
  String get transcriptionExistingTitle => 'この録音にはすでに説明があります';
  @override
  String get transcriptionExistingBody => '文字起こしで置き換えますか、それとも下に追加しますか？';
  @override
  String get transcriptionAppend => '下に追加';
  @override
  String get transcriptionReplace => '置き換え';
  @override
  String get settingsSectionSync => '同期';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'このライブラリでは未設定';
  @override
  String get syncNeverSynced => 'まだ同期していません';
  @override
  String syncLastSynced(String when) => '$when に同期';
  @override
  String get syncRunning => '同期中…';
  @override
  String syncScreenSubtitle(String library) => 'ライブラリ $library';
  @override
  String get syncUrlLabel => 'フォルダのアドレス';
  @override
  String get syncUrlRequired => 'サーバーのアドレスを入力';
  @override
  String get syncUrlHint => 'フォルダは作成済みである必要があります。サーバーに表示されるとおりにアドレスをコピーしてください。';
  @override
  String get syncHttpWarning => '暗号化されていない接続です。VPN 経由またはローカルネットワーク内なら問題ありません。';
  @override
  String get syncUserLabel => 'ユーザー';
  @override
  String get syncUserHint => 'サーバーが認証情報を求めない場合は空欄のままにします。';
  @override
  String get syncPasswordLabel => 'パスワード';
  @override
  String get syncPasswordHint => 'このデバイスのキーチェーンに保存され、ライブラリのファイルには保存されません。';
  @override
  String get syncPasswordKeepHint => '保存済みのパスワードを使う場合は空欄のままにします。';
  @override
  String get syncShowPassword => 'パスワードを表示';
  @override
  String get syncHidePassword => 'パスワードを隠す';
  @override
  String get syncTestAction => '接続をテスト';
  @override
  String get syncTesting => 'テスト中…';
  @override
  String get syncRetargetWarning => 'アドレスまたはユーザーを変えると、次回の同期は初回同期としてやり直しになります。';
  @override
  String get syncTestOk => '接続できました';
  @override
  String get syncModeFull => 'フルモード';
  @override
  String get syncModeCompatible => '互換モード';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => '読み取り、書き込み、削除';
  @override
  String get syncCapEtags => 'ファイルの指紋（ETag）';
  @override
  String get syncCapNoEtags => 'ファイルの指紋（ETag）なし';
  @override
  String get syncCapNoEtagsDetail => 'サイズと日付で比較し、不確かなときは再ダウンロードします';
  @override
  String get syncCapGuarded => '保護された書き込み';
  @override
  String get syncCapUnguarded => '保護されない書き込み';
  @override
  String get syncCapUnguardedDetail => '書き込む直前にサーバー上のファイルを確認します';
  @override
  String get syncCapMove => '再アップロードせずに名前変更';
  @override
  String get syncCapNoMove => 'サーバー上での名前変更なし';
  @override
  String get syncCapNoMoveDetail => '名前変更は削除と新規アップロードになります';
  @override
  String get syncCompatibleNote => '互換モードでも同期は同じように動作し、リクエストが少し増えるだけです。';
  @override
  String get syncTestInvalidUrl => '無効なアドレスです';
  @override
  String get syncTestInvalidUrlHint =>
      'http:// または https:// のアドレスを、ユーザーやパスワードを含めずに入力してください。';
  @override
  String get syncTestOffline => 'サーバーに接続できません';
  @override
  String get syncTestOfflineHint =>
      'VPN はオンですか？ 10.x や 192.168.x のアドレスは同じネットワークからしか使えません。';
  @override
  String get syncTestAuth => 'ユーザーまたはパスワードが拒否されました';
  @override
  String get syncTestAuthHint => '確認してから、もう一度テストしてください。';
  @override
  String get syncTestNotFound => 'フォルダが存在しません';
  @override
  String get syncTestNotFoundHint => 'サーバー上で作成するか、アドレスを修正してください。';
  @override
  String get syncTestUnsupported => 'WebDAV フォルダではありません';
  @override
  String get syncTestUnsupportedHint => 'サーバーは応答していますが、WebDAV としてではありません。';
  @override
  String get syncTestFailed => 'テストに失敗しました';
  @override
  String get syncNowAction => '今すぐ同期';
  @override
  String get syncSectionServer => 'サーバー';
  @override
  String get syncServerRow => 'アドレス、ユーザー、パスワード';
  @override
  String get syncRetestTitle => 'サーバーを再テスト';
  @override
  String syncProbedAgo(String when) => '最終テスト: $when';
  @override
  String get syncDisconnectTitle => 'このライブラリの接続を解除';
  @override
  String get syncDisconnectSubtitle => 'ファイルはここにもサーバーにも残ります';
  @override
  String get syncDisconnectConfirmTitle => '同期の接続を解除しますか？';
  @override
  String get syncDisconnectConfirmBody =>
      'このデバイスでのこのライブラリの同期を停止します。'
      'ファイルはここでもサーバーでも削除されません。'
      '再度接続すると、初回同期からやり直しになります。';
  @override
  String get syncDisconnectConfirm => '接続を解除';
  @override
  String get syncFirstTitle => '初回同期';
  @override
  String get syncFirstIntro => 'ライブラリとサーバー上のフォルダを比較しました：';
  @override
  String get syncFirstUpload => 'アップロード';
  @override
  String get syncFirstDownload => 'ダウンロード';
  @override
  String get syncFirstBoth => '両方にある';
  @override
  String get syncFirstBothHint => '同一なら転送なし。異なる場合は解決が必要';
  @override
  String get syncFirstNoDelete => '初回同期では、ここでもサーバーでも何も削除しません。';
  @override
  String get syncStartAction => '開始';
  @override
  String syncMassTrashTitle(int count) => 'ファイル $count 件をごみ箱に移動しますか？';
  @override
  String syncMassTrashBody(int count, int total) =>
      '同期済みの $total 件のファイルのうち $count '
      '件がサーバーにありません。通常は、アドレスの誤り、NAS '
      'ディスクの未マウント、または誤って空にされたフォルダが原因です。';
  @override
  String get syncMassTrashHint => '別のデバイスで本当に削除した場合は確定してください。ここではごみ箱に移動されます。';
  @override
  String get syncMassTrashConfirm => 'ごみ箱に移動';
  @override
  String syncMassDeleteTitle(int count) => 'サーバーからファイル $count 件を削除しますか？';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '同期済みの $total 件のファイルのうち $count '
      '件がここにありません。削除していない場合は、キャンセルしてライブラリのフォルダを確認してください。';
  @override
  String get syncMassDeleteConfirm => 'サーバーから削除';
  @override
  String get syncTooltip => '同期';
  @override
  String get syncStageConnecting => 'サーバーに接続中…';
  @override
  String get syncStageComparing => 'サーバーと比較中…';
  @override
  String syncStageApplying(int done, int total) => '同期中 · $done / $total';
  @override
  String get syncStatusWarnings => '同期完了（警告あり）';
  @override
  String syncConflictsHeader(int count) => 'ここでもサーバーでも変更 · $count';
  @override
  String get syncConflictHint => 'どちらのバージョンも変更していません';
  @override
  String get syncResolveAction => '解決';
  @override
  String syncFailuresHeader(int count) => '未同期 · $count';
  @override
  String get syncFailuresHint => '次回の同期で再試行します';
  @override
  String get syncAbortAuth => 'サーバーがパスワードを拒否しました';
  @override
  String get syncAbortMissingPassword => 'パスワードが保存されていません';
  @override
  String get syncAbortOffline => 'サーバーに接続できません';
  @override
  String get syncAbortRemoteMissing => 'サーバー上のフォルダがなくなりました';
  @override
  String get syncAbortUnsupported => 'サーバーが WebDAV として動作しなくなりました';
  @override
  String get syncAbortFailed => '同期に失敗しました';
  @override
  String get syncAbortNotConfirmed => '同期をキャンセルしました';
  @override
  String get syncAbortNothingTouched =>
      'ファイルは一切変更していません。変更内容は次回の同期が成功するまでここに残ります。';
  @override
  String syncLastSuccess(String when) => '最後に成功した同期: $when';
  @override
  String get syncNoSuccessYet => '成功した同期はまだありません';
  @override
  String get syncUpdatePasswordAction => 'パスワードを更新';
  @override
  String get syncRetryAction => '再試行';
  @override
  String get syncOpenSettingsAction => '設定';
  @override
  String get syncCloseAction => '閉じる';
  @override
  String get syncDoneSnack => '同期しました';
  @override
  String syncTrashedSnack(int count) =>
      '同期しました · 他の場所で削除されたファイル $count 件がごみ箱にあります';
  @override
  String syncConflictsSnack(int count) => '同期しました · 解決が必要な競合が $count 件あります';
  @override
  String get syncShowAction => '表示';
  @override
  String get syncConflictTitle => '競合を解決';
  @override
  String get syncConflictLegend => '− の行はサーバーの内容、+ の行はこのデバイスの内容です。';
  @override
  String get syncConflictBinary => 'テキストファイルではありません。残すコピーを選んでください。';
  @override
  String get syncConflictKeepNote => '残さなかったコピーはノートの履歴に保存されます。';
  @override
  String get syncKeepLocal => 'このデバイスの内容を残す';
  @override
  String get syncKeepRemote => 'サーバーの内容を残す';
  @override
  String get syncConflictIdentical => '2 つのバージョンは同一です';
  @override
  String get syncConflictLoadFailed => '両方のバージョンを読み込めませんでした';
  @override
  String get syncResolveFailed => '競合を解決できませんでした';
  @override
  String get syncResolved => '競合を解決しました';
  @override
  String get syncSectionWhen => '同期のタイミング';
  @override
  String get syncAutoTitle => '自動';
  @override
  String get syncAutoSubtitle => '編集後、起動時、一定の間隔で';
  @override
  String get syncIntervalTitle => 'サーバーの確認間隔';
  @override
  String get syncIntervalSubtitle => 'アプリを開いている間のみ';
  @override
  String get syncIntervalDialogBody =>
      'アプリを開いている間に、他のデバイスで行われた変更を確認するためのものです。「しない」の場合は、編集後と起動時のみ同期します。';
  @override
  String syncIntervalMinutes(int count) => '$count 分';
  @override
  String get syncIntervalNever => 'しない';
  @override
  String get syncWifiOnlyTitle => 'Wi-Fi のみ';
  @override
  String get syncWifiOnlySubtitle => 'モバイルデータ通信では手動でのみ同期';
  @override
  String syncPendingChanges(int count) => '$count 件の変更が待機中';
  @override
  String syncRetryIn(String wait) => '$wait後に再試行';
  @override
  String syncWaitSeconds(int seconds) => '$seconds 秒';
  @override
  String syncWaitMinutes(int minutes) => '$minutes 分';
  @override
  String get syncWaitingForWifi => 'Wi-Fi を待機中';
  @override
  String get syncWaitingForNetwork => '接続を待機中';
  @override
  String get syncMobileDataHint => '「今すぐ同期」はモバイルデータ通信でも同期します。';
  @override
  String get syncQueueKeptHint => '変更はアプリを閉じてもここに残り、サーバーが応答すると自動的に送信されます。';
  @override
  String get syncAutoPaused => '自動同期は一時停止中';
  @override
  String get syncPausedAuthHint => 'パスワードを更新するか手動で同期すると再開します。';
  @override
  String get syncPausedServerHint => 'アドレスを修正するか手動で同期すると再開します。';
  @override
  String get syncPausedConfirmHint => '「今すぐ同期」では、削除される内容が表示され、先に確認を求められます。';
  @override
  String get syncNeedsConfirmation => '確認を待っています';
  @override
  String get syncMergeIntro => '重ならない編集はすでに統合されています。重なっている箇所は、どちらを残すか選んでください。';
  @override
  String get syncMergeClean => '2 つのバージョンはそのまま統合できます。重なりはありません。';
  @override
  String get syncMergeNoBase => '統合の元になる共通のバージョンがないため、ファイル全体を選ぶ必要があります。';
  @override
  String syncMergeOverlap(int index, int total) => '重なり $index / $total';
  @override
  String get syncMergeFromLocal => 'このデバイスから';
  @override
  String get syncMergeFromRemote => 'サーバーから';
  @override
  String get syncMergeRemovedLines => '削除された行';
  @override
  String get syncMergeKeepLocal => 'このデバイス';
  @override
  String get syncMergeKeepRemote => 'サーバー';
  @override
  String get syncMergeKeepBoth => '両方';
  @override
  String get syncMergeSave => '統合を保存';
  @override
  String get syncMergeKeepWhole => 'または、どちらか一方をまるごと残す';
}
