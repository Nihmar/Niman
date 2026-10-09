/// The contract every language file of `ui/strings/` implements.
///
/// One abstract member per user-visible label. A locale that forgets a
/// translation is a compile error, which is what keeps "every label
/// resolves in every locale" true: there is no English fallback to hide
/// behind.
library;

// The members need no per-member docs: their names are the labels', and
// the implementations in `ui/strings/<locale>.dart` answer them.
// ignore_for_file: public_member_api_docs

/// Every user-visible label, in the language of one implementation.
///
/// Implementations live in `ui/strings/<locale>.dart`, one class per
/// file; `ui/strings.dart` (the `AppStrings` facade) dispatches to the
/// one that matches the active language.
abstract base class Strings {
  const new();

  // Dates written out (template placeholders, T-TPL-01). Indexed from
  // zero: month 1 is [0], and [weekdayNames] is Monday first as
  // `DateTime.weekday` counts: weekday 1 is [0].
  List<String> get monthNames;
  List<String> get monthNamesShort;
  List<String> get weekdayNames;
  List<String> get weekdayNamesShort;

  // Settings: editor toggles.
  String get trashTitle;
  String get trashSubtitle;
  String get trashAutoEmptyTitle;
  String get trashAutoEmptySubtitle;
  // Zero days = never, the way `historyVersionsValue(0)` is "none".
  String trashAutoEmptyValue(int days);
  String get debugLogsTitle;
  String get debugLogsSubtitle;
  String get lineNumbersTitle;
  String get lineNumbersSubtitle;
  String get readableLineLengthTitle;
  String get readableLineLengthSubtitle;
  String get noteColumnWidthTitle;
  String get noteColumnWidthSubtitle;
  String get keyboardOnOpenTitle;
  String get keyboardOnOpenSubtitle;
  String get editorKindSource;
  String get editorKindWysiwyg;
  String get editorKindSourceSubtitle;
  String get editorKindWysiwygSubtitle;
  String get settingsFolderToCreate;
  String get settingsSearchHint;
  String settingsSearchResults(int count);
  String get settingsToggleOn;
  String get settingsToggleOff;
  String get switchToWysiwygTooltip;
  String get switchToSourceTooltip;
  String get switchToSourceLabel;
  String get switchToWysiwygLabel;

  // Settings: the section headings the list is grouped under.
  String get settingsSectionAppearance;
  String get settingsSectionEditor;
  String get settingsSectionReminders;
  String get keyboardShortcutsTitle;

  // Settings home (issue #104): the groups the areas sit under.
  String get settingsGroupApp;
  String settingsGroupLibrary(String name);
  String get settingsGroupLibraryHint;
  String get settingsGroupMaintenance;

  // Settings home rows.
  String get settingsAreaFolders;
  String get settingsAreaTrashHistory;
  String get settingsAreaDiagnostics;
  String get settingsAreaKeyboardDisabled;
  String get settingsSectionUpdates;
  String get autoUpdateTitle;
  String get autoUpdateSubtitle;
  String get checkForUpdatesTitle;
  String updateAvailableMessage(Object version);
  String get updateUpToDate;
  String get updateCheckFailed;
  String updateSavedTo(Object path);
  String get updateInstallerStarted;
  String get settingsSpellCheckTitle;
  String get settingsSpellCheckSubtitle;
  String get spellCheckDictionaryTitle;
  String get spellCheckDictionarySystem;
  String get spellCheckDictionaryChoiceTitle;
  String get spellCheckDictionaryChoiceSubtitle;
  String get spellCheckNoDictionaries;

  // Spelling review (T-PP-09).
  String get spellCheckTooltip;
  String get spellCheckTitle;
  String get spellCheckEmpty;
  String get spellCheckUnavailable;
  String get spellCheckNoSuggestions;
  String spellCheckCount(int count);
  String spellCheckLine(int line);

  /// The context-menu entry that adds a word to the personal dictionary
  /// (issue #60).
  String get addWordToDictionary;

  /// The indent width as a row's value, e.g. "4 spaces".
  String indentWidthValue(int spaces);

  // Settings: theme (T-M6-05).
  String get themeBrightnessTitle;
  String get themeBrightnessSubtitle;
  String get themeBrightnessSystem;
  String get themeBrightnessDay;
  String get themeBrightnessNight;
  String get themeTitle;

  /// The settings area the colors live in, and the mark on the
  /// theme in use (issue #269).
  String get settingsSectionThemes;
  String get themesInUse;
  String get themeNewTitle;
  String get themeNewName;
  String get themeNewStartFrom;
  String get themeNewRandom;
  String get themeNameTaken;
  String themeDeleteBody(String name);
  String get themeDuplicate;
  String get themeMenuTooltip;
  String get themeEdit;
  String get themeEditorTitle;
  String get themeEditorChrome;
  String get themeEditorMarkdown;
  String get themeEditorTaskLists;
  String get themeEditorRolesHint;
  String get themeEditorDiscardTitle;
  String get themeEditorDiscardBody;
  String get themeEditorDiscard;
  String get themeEditorBadColor;
  String get themeExport;
  String themeExportDone(String where);
  String themeFileFailed(String error);
  String get themeImport;
  String get themeImportInvalid;
  String themeImportVersion(int version);
  String themeImportBadRole(String role);
  String get themePaletteSystem;

  // Settings: text size (T-M6-12).
  String get uiTextScaleTitle;
  String get uiTextScaleSubtitle;
  String get noteTextScaleTitle;
  String get noteTextScaleSubtitle;
  String get sourceFontTitle;
  String get sourceFontSubtitle;
  String get sourceFontMonospace;
  String get sourceFontSansSerif;
  String get sourceFontSerif;
  String get epubLookTitle;
  String get epubLookSubtitle;
  String get epubSameAsApp;
  String get epubFontTitle;
  String get epubFontSerif;
  String get epubFontSans;
  String get epubFontMono;
  String get epubTextSizeTitle;

  // Settings: preview mode.
  // Settings: editor formatting.
  String get linkTypeTitle;
  String get linkTypeSubtitle;
  String get linkTypeWikilink;
  String get linkTypeMarkdown;
  String get indentWidthTitle;
  String get indentWidthSubtitle;

  // Settings: language (T-L10N-04).
  String get languageTitle;
  String get languageSubtitle;
  String get languageSystem;
  String get weekStartTitle;
  String get weekStartSubtitle;
  String get weekStartSystem;

  // List note kind (T-TK-02).
  String get listAddHint;
  String get listAddTooltip;
  String get listEmpty;
  String get listDragHandleLabel;
  // The shopping-list subtype: the ⋮ entries that turn a list into one
  // and back, and the quantity a shopping item carries.
  String get shoppingListName;
  String get checklistName;
  String get shoppingQuantityLabel;

  // Audio note kind (issue #56).
  String get audioEmpty;
  String get audioRecord;
  String get audioStop;
  String get audioPlay;
  String get audioDelete;
  String get audioImport;
  String get audioRecording;
  String get audioPermissionDenied;
  String get newAudioNoteTitle;
  String get newAudioNoteDefault;
  String get showAudioTooltip;
  String get audioMessageHint;
  String get audioSend;
  String get audioRename;
  String get audioDescriptionHint;
  String get audioEditDescription;
  String get audioDeleteNote;
  String get audioEditNote;
  String get audioPause;
  String get audioEditTitle;
  String get audioTitleHint;
  String audioUntitled(int n);
  String get audioMoreActions;
  String get audioDiscardRecording;
  String get audioPauseRecording;
  String get audioResumeRecording;
  String get audioRecordingPaused;
  String get audioSavingRecording;

  /// A recording that would not play (#381): the error itself names a
  /// class and a stack, so it goes to the log and this sentence goes on
  /// screen.
  String get audioPlayFailed;

  // Launcher quick actions (T-SC-02), in the order they are published.
  String get shortcutQuickNote;
  String get trayOpen;
  String get trayQuit;
  String get closeToTrayTitle;
  String get closeToTraySubtitle;

  String get shortcutNewTodo;
  String get shortcutNewNote;
  String get shortcutNewList;
  String get shortcutNewAudio;
  String get shortcutToggleSidebar;
  String get shortcutCloseTab;
  String get shortcutNextTab;
  String get shortcutPreviousTab;
  String get shortcutNoteBack;
  String get shortcutNoteForward;
  String get shortcutEditorSection;
  String get shortcutFormatSection;
  String get shortcutFind;
  String get shortcutReplace;
  String get shortcutSavingNote;

  // Editor status bar.
  String get noteStatusLoading;
  String get noteStatusSaving;
  String get noteStatusUnsaved;
  String get noteStatusSaved;
  String get noteStatusError;
  String get noteNotText;
  String get noteLoadFailed;
  String wordCount(int count);
  String get outlineTooltip;
  String get outlineNoHeadings;
  String get outlineNoTitle;

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  String get toolbarBold;
  String get toolbarItalic;
  String get toolbarStrikethrough;
  String get toolbarHighlight;
  String get toolbarSuperscript;
  String get toolbarUnderline;
  String get toolbarLink;
  String get toolbarCode;
  String get toolbarImage;
  String get toolbarTable;
  String get tableRow;
  String get tableColumn;
  String get tableAddRowAbove;
  String get tableAddRowBelow;
  String get tableMoveRowUp;
  String get tableMoveRowDown;
  String get tableDuplicateRow;
  String get tableDeleteRow;
  String get tableAddColumnLeft;
  String get tableAddColumnRight;
  String get tableMoveColumnLeft;
  String get tableMoveColumnRight;
  String get tableAlignLeft;
  String get tableAlignCenter;
  String get tableAlignRight;
  String get tableDuplicateColumn;
  String get tableDeleteColumn;
  String get tableSortAscending;
  String get tableSortDescending;
  String get tableAddRow;
  String get tableAddColumn;
  String get cheatsheetTitle;
  String get cheatsheetCopy;
  String get cheatsheetCopied;
  String get copyCode;
  String get codeCopied;
  String get cheatsheetInsert;
  String get cheatHeadings;
  String get cheatEmphasis;
  String get cheatHtmlFormats;
  String get cheatLists;
  String get cheatChecklists;
  String get cheatQuotes;
  String get cheatCallouts;
  String get cheatLinks;
  String get cheatWikilinks;
  String get cheatEmbeds;
  String get cheatTags;
  String get cheatInlineCode;
  String get cheatCodeBlocks;
  String get cheatMath;
  String get cheatTables;
  String get cheatFootnotes;
  String get cheatRule;
  String get cheatFrontmatter;
  String get cheatEpubMetadata;
  String get cheatTemplates;
  String get menuAddLink;
  String get menuAddExternalLink;
  String get menuFormat;
  String get menuParagraph;
  String get menuInsert;
  String get menuBody;
  String get formatSubscript;
  String get formatInlineCode;
  String get insertFootnote;
  String get insertRule;
  String get insertCodeBlock;
  String get insertMathBlock;
  String get menuHeadingWord;
  String get toolbarHeading;
  String get toolbarList;
  String get toolbarOrderedList;
  String get toolbarChecklist;
  String get toolbarQuote;
  String get toolbarIndent;
  String get toolbarOutdent;

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  String get toolbarTools;
  String get editorToolsTitle;
  String get toolCountListTitle;
  String get toolCountListSubtitle;
  String get toolCountListNeedsList;
  String get toolMindMapSubtitle;
  String get toolMindMapNeedsList;

  // Diagrams (#530): the full-screen view and the window that holds it.
  String get diagramTitle;
  String get fullScreen;
  String get commandInsertDiagram;
  String get commandInsertMindMap;
  String get commandConvertListToMindMap;
  String get tallySourceLabel;
  String get tallyCutLabel;
  String get tallyCutDash;
  String get tallyCutColon;
  String get tallyCutCommas;
  String get tallyCutWhole;
  String get tallySortLabel;
  String get tallySortCount;
  String get tallySortAlphabetical;
  String get tallySortFirstSeen;
  String get tallyInsert;
  String get tallyUpdate;
  String get tallyNothingToCount;
  String get headingDialogTitle;

  // Toolbar settings (T-TB-05).
  String get toolbarSettingsTitle;
  String get toolbarSettingsHint;
  String get toolbarShowButton;
  String get toolbarHideButton;
  String get toolbarResetOrder;

  // Preview switch (phone mode).
  String get showPreviewTooltip;
  String get showEditorTooltip;

  // Search (T-M3-05).
  String get searchHint;
  String get searchModeWords;
  String get searchModeContains;
  String get searchEmptyHint;
  String get searchTooShortHint;
  String get searchNoMatches;
  String get searchLoadMore;

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  String get replaceTooltip;
  String get replaceInNoteAction;
  String get replaceInThisNote;
  String get replaceWithLabel;
  String get replaceCaseSensitive;
  String get replaceWholeWordsHint;
  String get replaceConfirm;
  String get replaceCancel;
  String get replaceUnavailable;

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  String get findInNoteTooltip;
  String get editorFindHint;
  String get editorReplaceHint;
  String get editorFindCaseTooltip;
  String get editorFindPreviousTooltip;
  String get editorFindNextTooltip;
  String get editorFindCloseTooltip;
  String get editorFindReplaceModeTooltip;
  String get editorReplaceOneTooltip;
  String get editorReplaceAllTooltip;

  // Tags (T-M3-06).
  String get openTagsTooltip;
  String get tagsTitle;
  String get tagsEmpty;
  String get tagsBackTooltip;
  String get tagsNotesEmpty;

  /// The last row of a tag's note list when the tag has more notes than
  /// the list shows (T-M6-01).
  String tagsNotesCapped(int limit);

  // Link navigation (T-M3-07).
  String get unresolvedLinkTitle;
  String get headingNotFoundTitle;
  String get ambiguousLinkTitle;
  String get openLinkFailed;

  // Dead-link note creation (issue #78).
  String get missingNoteLocationTitle;
  String get missingNoteLocationRoot;
  String get missingNoteLocationCurrentFolder;
  String get missingNoteDialogTitle;
  String missingNoteDialogBody(String path);
  String missingNoteFolderMissing(String folder);

  // Task lists (T-TD-04).
  String get todoOpen;
  String get todoDone;

  // Filter row + sheet (T-TDM-03).
  String get todoAllDates;
  String get todoFilter;
  String get todoNoTokens;
  String get todoCountOpen;
  String get todoCountDone;
  String get todoEmptyOpen;
  String get todoEmptyDone;
  String get todoEmptyFiltered;
  String get todoTitle;
  String get todoAddTooltip;

  // The todo.txt format help (T-TD-08).
  String get todoHelpTitle;
  String get todoHelpTooltip;
  String get todoHelpIntro;
  String get todoHelpFilesTitle;
  String get todoHelpFilesBody;
  String get todoHelpLineTitle;
  String get todoHelpLineBody;
  String get todoHelpDoneBody;
  String get todoHelpPriority;
  String get todoHelpPriorityBody;
  String get todoHelpDatesBody;
  String get todoHelpTokensTitle;
  String get todoHelpTokensBody;
  String get todoHelpProjectBody;
  String get todoHelpContextBody;
  String get todoHelpHashtagBody;
  String get todoHelpTagsTitle;
  String get todoHelpTagsBody;
  String get todoHelpDueBody;
  String get todoHelpRemBody;
  String get todoHelpRemDesktop;
  String get todoHelpOtherBody;
  String get todoHelpEditTitle;
  String get todoHelpEditBody;

  // Task dialog (T-TD-06).
  String get todoAddTitle;
  String get todoEditTitle;
  String get todoDescriptionHint;
  String get todoCancel;
  String get todoSave;
  String get todoEditAction;
  String get todoDeleteAction;

  // Task filters (T-TD-05).
  String get todoDueOverdue;
  String get todoDueToday;
  String get todoDueNext7;
  String get todoDueNoDate;
  String get todoRowDue;
  String get todoRowDueToday;
  String get todoSortTooltip;
  String get todoSortDue;
  String get todoSortPriority;
  String get todoSortCreation;

  // Task dialog pickers (T-TD-06).
  String get todoNoPriorityShort;
  String get todoMorePriorities;
  String get todoPriorityTitle;
  String get todoNoDueDate;
  String get todoNoReminder;
  String get todoAddProject;
  String get todoAddContext;
  String get todoAddHashtag;

  // Task reminders (T-TD-07).
  String get todoReminderChannel;
  String get todoReminderChannelDescription;
  String get todoReminderBody;
  String get todoReminderFallbackTitle;
  String get todoReminderBlocked;
  String get todoReminderBattery;
  String get todoReminderInexact;
  String get reminderShowTokensTitle;
  String get reminderShowTokensSubtitle;
  String get todoReminderFixAction;
  String get todoReminderDismissAction;
  String get todoReminderDue;

  // Actions and buttons shared by the dialogs (T-L10N-06).
  String get actionOk;
  String get actionCancel;
  String get actionDownload;
  String get actionCreate;
  String get actionNew;
  String get actionSave;
  String get actionClear;
  String get actionChoose;
  String get actionDelete;
  String get actionRename;
  String get renameNameInvalid;
  String renameNameTaken(String name);
  String get actionMove;
  String get saveAndClose;
  String get closeUnsavedTitle;

  /// The close ask's body, for the unsaved notes' names.
  String closeUnsavedBody(List<String> names);

  /// The save-before-close failed, so the window stays open.
  String get closeSaveFailed;
  String get actionRestore;
  String get actionEmpty;

  // The shell: app bar, tabs and tree actions.
  String get hideSidebarTooltip;
  String get showSidebarTooltip;
  String get windowMinimizeTooltip;
  String get windowMaximizeTooltip;
  String get windowRestoreTooltip;
  String get windowCloseTooltip;
  String get tabFiles;
  String get tabSearch;
  String get tabSettings;
  String get quickNoteTitle;
  String get treeEmpty;
  String get selectANote;
  String get showListTooltip;
  String get editRawTooltip;
  String get sortAscTooltip;
  String get sortDescTooltip;
  String get newNoteTitle;
  String get newItemTooltip;
  String get closeMenuTooltip;

  /// A shell action that threw (issue #381): the sentence the snackbar
  /// shows, while the error itself goes to the log.
  String get shellActionFailed;
  String get newFolderTitle;
  String get newNoteSameFolder;
  String get newFromTemplateSameFolder;
  String trashOriginalPath(String path);
  String get trashOriginalRoot;
  String trashItemCount(int count);
  String get newNoteHere;
  String get newFolderHere;
  String get newListNoteTitle;
  String get newListNoteDefault;
  String get setAsQuickNote;
  String get currentQuickNote;

  /// The pinned section's heading, with its count, e.g. "Pinned · 3".
  String pinnedSectionCount(int count);

  String get templateFolderTitle;
  String get newFromTemplateTitle;
  String get newFromTemplateHere;

  /// A template that could not be read, or whose includes could not be
  /// pasted, before its form opened (#381).
  String get templateOpenFailed;
  String get templateFormTitle;
  String get templateFormBacklink;
  String get templateFormNoNote;
  String get templateFormPickNote;

  // The template placeholder reference (T-TPL-08).
  String get templateHelpTitle;
  String get templateHelpSubtitle;
  String get quickNoteSubtitle;
  String get listFolderSubtitle;
  String get templateFolderSubtitle;
  String get attachmentsFolderSubtitle;
  String get templateHelpIntro;
  String get templateHelpUnknown;
  String get templateHelpValuesTitle;
  String get templateHelpTitleBody;
  String get templateHelpDateBody;
  String get templateHelpNowBody;
  String get templateHelpUuidBody;
  String get templateHelpCounterBody;
  String get templateHelpCursorBody;
  String get templateHelpDatesTitle;
  String get templateHelpDatesBody;
  String get templateHelpYear;
  String get templateHelpMonth;
  String get templateHelpDay;
  String get templateHelpTime;
  String get templateHelpWeek;
  String get templateHelpFiltersTitle;
  String get templateHelpFiltersBody;
  String get templateHelpCaseBody;
  String get templateHelpSlugBody;
  String get templateHelpPadBody;
  String get templateHelpShiftBody;
  String get templateHelpSnapBody;
  String get templateHelpAskTitle;
  String get templateHelpAskBody;
  String get templateHelpAskFieldBody;
  String get templateHelpChoiceBody;
  String get templateHelpWhereTitle;
  String get templateHelpWhereBody;
  String get templateHelpFolderBody;
  String get templateHelpFilenameBody;
  String get templateHelpAppendBody;
  String get templateHelpOpenBody;
  String get templateHelpAroundTitle;
  String get templateHelpParentBody;
  String get templateHelpFolderValueBody;
  String get templateHelpClipboardBody;
  String get templateHelpIncludeTitle;
  String get templateHelpIncludeBody;
  String get templateHelpExampleTitle;

  // What the template checker says as a template is edited (T-TPL-09).

  /// The hint's fix line, with the corrected text inside the sentence: the
  /// hint draws [fix] apart from the words around it.
  String templateHintDidYouMean(String fix);
  String get templateHintNoFix;
  String get templateHintFixAction;
  String get templateHintDismissAction;

  /// The problems a template has, for the count in the status row: what the
  /// number beside it counts.
  String templateProblems(int count);

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  String includeMissing(String path);
  String includeCycle(String path);
  String includeTooDeep(String path);
  String get frontmatterTitle;
  String get frontmatterPanelTitle;
  String get frontmatterPanelSubtitle;
  String get frontmatterShowRaw;
  String get frontmatterShowFields;
  String get frontmatterAddField;
  String get frontmatterNewField;
  String get frontmatterEditField;
  String get frontmatterKeyLabel;
  String get frontmatterValueLabel;
  String get frontmatterTypeLabel;
  String get frontmatterListHint;
  String get frontmatterRemoveField;
  String get frontmatterNoFields;
  String get frontmatterTypeText;
  String get frontmatterTypeNumber;
  String get frontmatterTypeDate;
  String get frontmatterTypeBoolean;
  String get frontmatterTypeList;
  String frontmatterInvalid(String reason);
  String templateFrontmatterInvalid(String template, String reason);
  String get templatePickerTitle;
  String templatePickerEmpty(String folder);

  // Tree actions.
  String get actionPin;
  String get actionUnpin;

  // Home-screen note widget (issue 6).
  String get pinToWidget;
  String get pinnedForWidget;
  String get pinWidgetUnavailable;

  // Handing a note's file to the OS (issue #76).
  String get openInFileManager;
  String get openInDefaultApp;
  String get newNoteTabTooltip;
  String get openNotesTooltip;
  String get closeTabTooltip;
  String get openInNewTab;
  String get splitRight;
  String get splitDown;
  String get moveToOtherPane;
  String get openBeside;
  String get closeAllNotes;
  String get sidePanelTooltip;
  String get historyAllVersions;
  String get commandPaletteTitle;
  String get goToNoteTitle;
  String get paletteGroupNote;
  String get paletteGroupEditor;
  String get paletteGroupView;
  String get paletteGroupLibrary;
  String get paletteGroupGoTo;
  String get paletteGroupJournal;
  String get journalToday;
  String get journalPrevious;
  String get journalNext;
  String get commandNeedJournalEntry;
  String journalCreateAsk(String day);
  String journalTemplateMissing(String path);
  String get journalIntro;
  String get journalFolderTitle;
  String get journalFolderSubtitle;
  String get journalEntryNameTitle;
  String get journalEntryNameSubtitle;
  String journalEntryNamePreview(String path);
  String get journalEntryNameInvalid;
  String get journalTemplateTitle;
  String get journalTemplateSubtitle;
  String get journalTemplateNone;
  String get journalDayStartTitle;
  String get journalDayStartSubtitle;
  String get journalRecent;
  String get journalNoEntry;
  String get journalOpenEntry;
  String get journalShowCalendar;
  String get journalFabToday;
  String journalDueOn(String day);
  String get commandsTitle;
  String get commandsIntro;
  String get commandsKeysNote;
  String get commandsOpenShortcuts;
  String get commandsChangeKeyTooltip;
  String get commandsSubtitle;
  String get keyboardShortcutsSubtitle;
  String get commandNeedNone;
  String get commandNeedOpenNote;
  String get commandNeedTextNote;
  String get commandNeedWideWindow;
  String get commandNeedDockRoom;
  String get commandNeedDesktop;
  String get commandNeedNotInZen;
  String get commandNeedZenRoom;
  String get commandNeedPreview;
  String get commandNeedTwoEditors;
  String get paletteHint;
  String get paletteNoResults;
  String get paletteCommands;
  String get paletteNotes;
  String get paletteFooter;
  String get paletteFooterTouch;
  String get palettePinned;
  String get palettePin;
  String get paletteUnpin;
  String get palettePinFooter;
  String get spellCheckScanning;
  String get spellCheckAgain;
  String spellCheckCapped(int count);
  String get dropHint;
  String get dropNothing;
  String get importFolderAction;
  String get notionImportTitle;

  /// A Notion export that could not be imported (#381).
  String get notionImportFailed;
  String dropRejected(String names);
  String importFolderTitle(String name);
  String importFolderBody(int count);
  String importFolderDone(String folder);
  String importFolderEmpty(String name);
  String get openFileTitle;
  String get outsideFileNote;
  String get typewriterOn;
  String get typewriterOff;
  String get typewriterTitle;
  String get formatNoteTitle;
  String get formatNoteDone;
  String get formatNoteAlreadyTidy;
  String get exportTitle;
  String get exportFormatMarkdown;
  String get exportFormatHtml;
  String get exportFolderTitle;
  String get exportLibraryTitle;
  String get exportFormatPdf;
  String get exportFormatEpub;

  /// The title of the pre-flight dialog a folder's EPUB export shows when
  /// the folder has no metadata source (#303, E3).
  String get exportEpubNoMetadataTitle;

  /// The dialog's message when the exported folder has no `index.md`.
  String get exportEpubNoIndex;

  /// The dialog's message when `index.md` has no frontmatter.
  String get exportEpubNoFrontmatter;

  /// The dialog's proceed action: export anyway, without what the message
  /// said is missing. Both pre-flight dialogs end with it — a book without
  /// metadata (#303, E3), a note drawn as a picture (#63).
  String get exportAnyway;

  /// The title of the pre-flight dialog a note's PDF export shows when the
  /// machine has no browser engine to print the page with (#63): what is
  /// written is a picture of the pages, drawn here.
  String get exportPdfNoEngineTitle;

  /// Why the engine could not print, when it was found and failed: the
  /// note came out as a picture of its pages, and this says why (device
  /// report, 2026-09-29 — the failure used to be silent).
  String exportPdfEngineFailed(Object reason);

  /// The dialog's message: drawn page by page, with no text to select or
  /// search, and slower on a long note.
  String get exportPdfNoEngine;

  String get exportPdfPicture;
  String exportDone(String place);
  String exportFailed(Object error);
  String get tidyOnCloseTitle;
  String get tidyOnCloseSubtitle;
  String get lintRulesTitle;
  String get lintRulesSubtitle;
  String get lintRulesReset;
  String lintRulesValue(int on, int all);
  String get lintRuleTightLists;
  String get lintRuleTaskMarker;
  String get lintRuleListSpacing;
  String get lintRuleClosingFence;
  String get lintRuleFenceLanguage;
  String get lintRuleJoinWrappedItems;
  String get lintRuleJoinParagraphLines;
  String get typewriterSubtitle;
  String get zenMode;
  String get zoomIn;
  String get zoomOut;
  String get zoomReset;
  String get zenModeEnter;
  String get zenModeLeave;
  String get keySpace;
  String get keyEnter;
  String get keyTab;
  String get keyEscape;
  String get keyBackspace;
  String get keyDelete;
  String get keyArrowUp;
  String get keyArrowDown;
  String get keyArrowLeft;
  String get keyArrowRight;
  String get keyHome;
  String get keyEnd;
  String get keyPageUp;
  String get keyPageDown;
  String get keyInsert;
  String get shortcutNone;
  String get shortcutRestoreDefaults;
  String get shortcutRestoreDefaultsConfirm;
  String get shortcutRevert;
  String get shortcutClear;
  String get shortcutCapturePrompt;
  String get shortcutCaptureNeedsModifier;
  String get shortcutMove;
  String get shortcutUseAnyway;
  String get shortcutUndo;
  String get shortcutRedo;
  String shortcutCaptureTitle(String command);
  String shortcutConflict(String keys, String other);
  String shortcutTakesEditorKey(String keys, String what);
  String get openFileMissing;
  String get openFileFailed;
  String get attachmentUnreadable;
  String get attachmentMissing;
  String get attachmentOpenFailed;

  /// The button that copies a link to the place of a PDF or a book
  /// being read (#282).
  String get copyPlaceLink;
  String get placeLinkCopied;

  /// A link's label for [page] of the PDF [name]: `Dune, p. 34`.
  String pdfPageLabel(String name, int page);

  // Annotating a PDF or a book in a note of its own (#284).
  String get annotationsFolderTitle;
  String get annotationsFolderSubtitle;

  // Where a captured web page or quote goes as a new note.
  String get captureFolderTitle;
  String get captureFolderSubtitle;

  /// Ends the name of a note made to annotate a file:
  /// `Dune - Annotation.md`.
  String get annotationNoteSuffix;
  String get annotateAction;
  String get annotationCommentHint;
  String get annotationSaved;
  String get annotationOpenNote;
  String get annotationFailed;
  String get movedToTrash;
  String get deletedMessage;
  String deleteToTrashConfirm(String name);
  String deleteForeverConfirm(String name);
  String get chooseDestination;
  String get libraryRoot;
  String moveTitle(String name);
  String headingLevelLabel(int level);

  // Quick note tab and picker.
  String get quickNoteEmpty;
  String get quickNoteChooseAction;
  String get quickNoteCreateAction;
  String get quickNoteNewTitle;
  String get quickNotePickerTitle;

  // Folder picker (T-TK-07).
  String get folderPickerNewFolder;
  String get folderPickerEmpty;
  String get listFolderTitle;
  String get attachmentsFolderTitle;

  // Trash (M1).
  String get trashEmpty;
  String get trashEmptyAction;
  String get trashEmptyConfirm;
  String trashDeleteConfirm(String name);
  String get trashDeletePermanently;

  /// A restore or a permanent delete of a trashed note failed (#381):
  /// the sentence replaces the caught error's `toString()`.
  String get trashActionFailed;

  /// Emptying the trash failed (#381).
  String get trashEmptyFailed;

  // The open/create library screen.
  String get openLibraryIntro;
  String get openLibraryExisting;
  String get openLibraryCreate;
  String get openLibraryCreateTitle;
  String get openLibraryFolderName;
  String get openLibraryChooseFolder;
  String get openLibraryChooseParent;
  String get openLibraryUnsupported;

  /// The first index's counter, e.g. "412 of 10000 notes".
  String indexingCount(int done, int total);

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  String get knownLibrariesTitle;
  String get libraryUnreachable;
  String get libraryOpenedToday;
  String get libraryOpenedYesterday;
  String libraryOpenedDaysAgo(int days);
  String libraryOpenedOn(DateTime when);
  String get libraryOpenNow;
  String get switchLibraryTitle;
  String get libraryForget;
  String libraryForgetTitle(String name);
  String get libraryForgetExplained;

  String get libraryForgetOpenExplained;

  // Android storage access.
  String get storageAccessAction;
  String get storageAccessNeeded;
  String get storageAccessExplained;
  String folderAccessDenied(Object error);
  String folderPickFailed(Object error);

  // Settings screen rows and messages.
  String get libraryPathTitle;
  String get reindexTitle;
  String get reindexDone;
  // Rebuilding deletes the index file and re-reads the notes into a fresh
  // one (#368), where re-indexing works on the index already there.
  String get rebuildIndexTitle;

  /// Re-reading the library from disk failed (issue #381).
  String get reindexFailed;
  String get closeLibraryTitle;
  String get exportLogTitle;
  String get exportLogSubtitle;
  String get exportLogEmpty;
  String get quickNoteUnset;
  String exportLogDone(Object target);
  String exportLogFailed(Object error);

  // Replace results (T-M3-10).
  String replaceNoMatch(String term);
  String replaceDone(int occurrences, String term, int notes);
  String replaceSkipped(int skipped);
  String replacePreviewEmpty(String term, String? only);

  // The replace panel's scope line (#381): what the run covers, built
  // from the table instead of the pairs "note"/"notes" composed here.
  String get replaceScopeWholeLibrary;

  /// The scope when the run is narrowed to one note: [note] is its path.
  String replaceScopeNote(String note);

  /// The scope when the run covers [count] matching notes.
  String replaceScopeNotes(int count);

  /// The notes that could not be written, appended to a run's outcome.
  String replaceWriteFailed(int count);

  // The about section (issue #80): the app's version and its changelog.
  String get versionTitle;
  String get changelogTitle;
  String get changelogEmpty;
  String changelogWhatsNew(String version);

  // Note history (issues #13, #55, #67).
  String get noteHistoryTitle;
  String get noteMenuTooltip;
  String get historyCurrentVersion;
  String get historyCurrentSubtitle;
  String get historyToday;
  String get historyYesterday;
  String get historyReasonSession;
  String get historyReasonInterval;
  String get historyReasonRestore;
  String get historyReasonSync;
  String get historyReasonReplace;
  String get historyReasonUnknown;
  String get historySyncBase;
  String get historyEmpty;
  String historyKept(int kept, int limit);
  String get historyBaseKept;
  String get historyOff;
  String get historyLoadFailed;
  String get historyCompareSubtitle;
  String get historyTabChanges;
  String get historyTabVersion;
  String get historyNoChanges;
  String get historyRestoreAction;
  String historyRestoreConfirmTitle(String when);
  String get historyRestoreConfirmBody;
  String get historyRestoreConfirm;
  String historyRestored(String when);
  String get historyRestoreFailed;
  String get actionUndo;
  String diffLineRange(int start, int end);
  String diffLineSingle(int line);
  String diffUnchanged(int count);
  String get historyTakeHunk;
  String historyRestoreSelectedAction(int count);
  String get historyRestoreSelectedConfirmBody;
  String get historyNoteChangedReloaded;
  String get historyVersionsTitle;
  String get historyVersionsSubtitle;
  String historyVersionsValue(int count);
  String get historyIntervalTitle;
  String get historyIntervalSubtitle;
  String historyIntervalValue(int minutes);
  String get settingsSectionTranscription;
  String get transcriptionModelTitle;
  String get transcriptionModelNone;
  String get transcriptionLanguageTitle;
  String get transcriptionLanguageSubtitle;
  String transcriptionLanguageApp(String language);
  String get transcriptionLanguageDetect;
  String get transcriptionModelsTitle;
  String transcriptionModelsUsed(String size);
  String get transcriptionModelsInstalled;
  String get transcriptionModelsDownloading;
  String get transcriptionModelsAvailable;
  String get transcriptionModelsFooter;
  String get transcriptionModelDefault;
  String get transcriptionModelSlow;
  String get transcriptionModelHintTiny;
  String get transcriptionModelHintBase;
  String get transcriptionModelHintSmall;
  String get transcriptionModelHintMedium;
  String get transcriptionModelHintLarge;
  String transcriptionModelDeleteTitle(String model);
  String transcriptionModelDeleteBody(String size);
  String get downloadFailed;
  String get actionRetry;
  String get downloadRetrying;
  String downloadPaused(String progress);
  String get actionResume;
  String get audioTranscribe;
  String get audioTranscribeUnsupported;
  String get transcriptionQueued;
  String get transcriptionPreparing;
  String transcriptionRunning(int percent);
  String transcriptionWaitingForModel(String model, int percent);
  String get transcriptionSaved;
  String get transcriptionNoSpeech;
  String get transcriptionFailed;
  String get transcriptionPickModelTitle;
  String get transcriptionPickModelBody;
  String get transcriptionPickModelAction;
  String get transcriptionModelRecommended;
  String get transcriptionExistingTitle;
  String get transcriptionExistingBody;
  String get transcriptionAppend;
  String get transcriptionReplace;

  /// The decimal separator of the language's numbers (`1.5` / `1,5`).
  String get decimalSeparator;
  String get settingsSectionSync;
  String get syncWebDavTitle;
  String get syncNotConfigured;
  String get syncNeverSynced;
  String syncLastSynced(String when);
  String get syncRunning;
  String syncScreenSubtitle(String library);
  String get syncUrlLabel;
  String get syncUrlRequired;
  String get syncUrlHint;
  String get syncHttpWarning;
  String get syncUserLabel;
  String get syncUserHint;
  String get syncPasswordLabel;
  String get syncPasswordHint;
  String get syncPasswordKeepHint;
  String get syncShowPassword;
  String get syncHidePassword;
  String get syncTestAction;
  String get syncTesting;
  String get syncRetargetWarning;
  String get syncTestOk;
  String get syncModeFull;
  String get syncModeCompatible;
  String syncTestOkSubtitle(String mode, int ms);
  String get syncCapBasic;
  String get syncCapEtags;
  String get syncCapNoEtags;
  String get syncCapNoEtagsDetail;
  String get syncCapGuarded;
  String get syncCapUnguarded;
  String get syncCapUnguardedDetail;
  String get syncCapMove;
  String get syncCapNoMove;
  String get syncCapNoMoveDetail;
  String get syncCompatibleNote;
  String get syncTestInvalidUrl;
  String get syncTestInvalidUrlHint;
  String get syncTestOffline;
  String get syncTestOfflineHint;
  String get syncTestAuth;
  String get syncTestAuthHint;
  String get syncTestNotFound;
  String get syncTestNotFoundHint;
  String get syncTestUnsupported;
  String get syncTestUnsupportedHint;
  String get syncTestFailed;
  // A self-signed destination, trusted once by fingerprint (#454).
  String get syncTestCertificate;
  String get syncTestCertificateHint;
  String get syncCertTrustTitle;
  String syncCertTrustBody(String host, String fingerprint);
  String get syncCertTrustAction;
  String get syncCertTrustedTitle;
  String syncCertTrustedSubtitle(String fingerprint);
  String get syncCertForgetTitle;
  String get syncCertForgetBody;
  String get syncCertForgetAction;
  String get syncNowAction;
  String get syncSectionServer;
  String get syncServerRow;
  String get syncRetestTitle;
  String syncProbedAgo(String when);
  String get syncDisconnectTitle;
  String get syncDisconnectSubtitle;
  String get syncDisconnectConfirmTitle;
  String get syncDisconnectConfirmBody;
  String get syncDisconnectConfirm;
  String get syncFirstTitle;
  String get syncFirstIntro;
  String get syncFirstUpload;
  String get syncFirstDownload;
  String get syncFirstBoth;
  String get syncFirstBothHint;
  String get syncFirstNoDelete;
  String get syncStartAction;
  String syncMassTrashTitle(int count);
  String syncMassTrashBody(int count, int total);
  String get syncMassTrashHint;
  String get syncMassTrashConfirm;
  String syncMassDeleteTitle(int count);
  String syncMassDeleteBody(int count, int total);
  String get syncMassDeleteConfirm;
  String get syncTooltip;
  String get syncStageConnecting;
  String get syncStageComparing;
  String syncStageApplying(int done, int total);
  String get syncStatusWarnings;
  String syncConflictsHeader(int count);
  String get syncConflictHint;
  String get syncResolveAction;
  String syncFailuresHeader(int count);
  String get syncFailuresHint;
  String get syncAbortAuth;
  String get syncAbortMissingPassword;
  String get syncAbortOffline;
  String get syncAbortRemoteMissing;
  String get syncAbortUnsupported;
  String get syncAbortFailed;
  String get syncAbortNotConfirmed;
  String get syncAbortNothingTouched;
  String syncLastSuccess(String when);
  String get syncNoSuccessYet;
  String get syncUpdatePasswordAction;
  String get syncRetryAction;
  String get syncOpenSettingsAction;
  String syncTrashedSnack(int count);
  String syncConflictsSnack(int count);
  String get syncShowAction;
  String get syncConflictTitle;
  String get syncConflictBinary;
  String get syncConflictKeepNote;
  String get syncKeepLocal;
  String get syncKeepRemote;
  String get syncConflictLoadFailed;
  String get syncResolveFailed;
  String get syncResolved;
  String get syncConflictMoved;
  String get syncSectionWhen;
  String get syncAutoTitle;
  String get syncAutoSubtitle;
  String get syncIntervalTitle;
  String get syncIntervalSubtitle;
  String get syncIntervalDialogBody;
  String syncIntervalMinutes(int count);
  String get syncIntervalNever;
  String get syncWifiOnlyTitle;
  String get syncWifiOnlySubtitle;
  String syncPendingChanges(int count);
  String syncRetryIn(String wait);
  String syncWaitSeconds(int seconds);
  String syncWaitMinutes(int minutes);
  String get syncWaitingForWifi;
  String get syncWaitingForNetwork;
  String get syncMobileDataHint;
  String get syncQueueKeptHint;
  String get syncAutoPaused;
  String get syncPausedAuthHint;
  String get syncPausedServerHint;
  String get syncPausedConfirmHint;
  String get syncNeedsConfirmation;
  String get syncMergeIntro;
  String get syncMergeClean;
  String get syncMergeNoBase;
  String syncMergeOverlap(int index, int total);
  String get syncMergeFromLocal;
  String get syncMergeFromRemote;
  String get syncMergeRemovedLines;
  String get syncMergeAbsentLines;
  String get syncMergeKeepLocal;
  String get syncMergeKeepRemote;
  String get syncMergeKeepBoth;
  String get syncMergeSave;
  String get syncMergeKeepWhole;

  // The welcome deck and the guided tour (#308).

  String get welcomeSkip;
  String get welcomeNext;
  String get welcomeBack;
  String get welcomeStart;
  String get welcomeClose;
  String get welcomeNotesTitle;
  String get welcomeNotesBody;
  String get welcomeModesTitle;
  String get welcomeModesBody;
  String get welcomeLinksTitle;
  String get welcomeLinksBody;
  String get welcomeFindTitle;
  String get welcomeFindBody;
  String get welcomeExportTitle;
  String get welcomeExportBody;
  String get welcomeTasksTitle;
  String get welcomeTasksBody;
  String get welcomeSyncTitle;
  String get welcomeSyncBody;
  String get welcomeDeviceTitle;
  String get welcomeAndroidBody;
  String get welcomeDesktopBody;
  String get welcomeQuestionTitle;
  String get welcomeQuestionNote;
  String get welcomeAnswerNone;
  String get welcomeAnswerNoneHint;
  String get welcomeAnswerSome;
  String get welcomeAnswerSomeHint;
  String get welcomeAnswerFluent;
  String get welcomeAnswerFluentHint;
  String get welcomeTourOffer;
  String get welcomeTourOfferNote;
  String get welcomeDeckCommand;
  String get welcomeTourCommand;
  String get tourDone;
  String get tourOfferTitle;
  String get tourOfferBody;
  String get tourOfferYes;
  String get tourOfferNo;
  String get tourTreeTitle;
  String get tourTreeBody;
  String get tourCreateTitle;
  String get tourCreateBody;
  String get tourNoteTitle;
  String get tourNoteBody;
  String get tourModesTitle;
  String get tourModesBody;
  String get tourToolbarTitle;
  String get tourToolbarBody;
  String get tourCheatsheetTitle;
  String get tourCheatsheetBody;
  String get tourCheatsheetOpen;
  String get tourTabsTitle;
  String get tourTabsBody;
  String get tourDockTitle;
  String get tourDockBody;
  String welcomePageOf(int page, int of);

  // Cascading a checklist tick (#326).

  String get cascadeChecklistTitle;
  String get cascadeChecklistSubtitle;

  // The wikilink suggester panel (#475): the caption over the list, its own
  // words when nothing matched, the alias a row was found through, the form
  // a book offers, and the keys drawn in its footer.
  //
  // The named things come in as arguments: the caption names the note (or
  // the book) being linked to, and the empty sentence quotes what was
  // typed. A language writes them where its own grammar puts them, and its
  // own quotes around them.

  /// `Headings in <name>`, drawn over the headings a `#` offers.
  String wikilinkHeadingsIn(String named);

  /// `Places in <name>`, drawn over the places a book offers.
  String wikilinkPlacesIn(String named);

  /// The name a caption carries when the note being linked to is the one
  /// being edited.
  String get wikilinkThisNote;

  /// The panel's sentence when no heading matched [query].
  String wikilinkNoMatchHeading(String query);

  /// The panel's sentence when no note matched [query].
  String wikilinkNoMatchNote(String query);
  String wikilinkNoMatchFile(String query);

  /// What stands under [wikilinkNoMatchHeading].
  String get wikilinkNoHeading;

  /// What stands under [wikilinkNoMatchNote].
  String get wikilinkNoNote;

  /// The pill on a row that was found through an alias.
  String wikilinkAlias(String alias);

  /// The note over a book's place form, which is a form and not a list.
  String get wikilinkBookNote;

  /// The footer's words, beside the keys that do them.
  String get wikilinkFooterMove;
  String get wikilinkFooterOr;
  String get wikilinkFooterInsert;
  String get wikilinkFooterClose;

  /// The dimmed note beside a book's `page=`.
  String get suggesterPageHint;

  /// The dimmed note beside a book's `chapter=`.
  String get suggesterChapterHint;

  // What the template checker found, in the words of the hint (T-TPL-09).
  //
  // The checker reports what is wrong as data — the problem and the pieces
  // it names — and the hint builds the sentence here, so it reads in the
  // active language. The pieces are code the template is written in (a
  // placeholder or filter name, a date token, a date format), so they stay
  // as written.

  /// Braces that open and never close.
  String get templateProblemUnclosedBraces;

  /// Braces that close with nothing open before them.

  /// A `{{…}}` with no name in it.
  String get templateProblemEmptyPlaceholder;

  /// A placeholder name the engine does not answer.
  String templateProblemUnknownPlaceholder(String name);

  /// An `{{ask}}` or `{{choice}}` with no label to ask with.
  String templateProblemAskNoLabel(String name);

  /// A `{{counter}}` with no name to count under.
  String templateProblemCounterNoName(String name);

  /// A `{{cursor}}` with filters, which the caret has nothing to apply.
  String templateProblemCursorFilters(String name);

  /// A date format whose quote never closes.
  String get templateProblemUnclosedQuote;

  /// A date-format token the engine does not know.
  String templateProblemUnknownDateToken(String token);

  /// A `|` with no filter name after it.
  String get templateProblemEmptyFilter;

  /// A date move where the engine reads text, with the placeholders that
  /// take one.
  String templateProblemDateMove(String filter, String formats);

  /// A `+…`/`-…` filter that is not a count and a unit.
  String templateProblemNotADateMove(String filter);

  /// A `startof:`/`endof:` the engine does not snap to, with the units it
  /// does.
  String templateProblemSnapUnit(String filter, String units, String unit);

  /// A `pad:` whose width is not a number.
  String templateProblemPadWidth(String filter, String argument);

  /// A filter name the engine does not answer.
  String templateProblemUnknownFilter(String name);

  // Text recognition (#593).

  /// The engine and its version.
  String ocrEngineName(String version);

  /// The Text recognition area (#593).
  String get settingsSectionTextRecognition;

  /// What text recognition does, atop its settings.
  String get ocrIntro;

  /// The engine section.
  String get ocrEngineTitle;

  /// The engine row's state: the distribution's library.
  String get ocrEngineSystem;

  /// The engine row's state: shipped in the package.
  String get ocrEngineBundled;

  /// The engine row's state: no build for this device.
  String get ocrEngineUnavailable;

  /// Asks before deleting the downloaded engine.
  String get ocrEngineDeleteTitle;

  /// The models’ quality setting.
  String get ocrQualityTitle;

  /// tessdata_fast.
  String get ocrQualityFast;

  /// tessdata_best.
  String get ocrQualityBest;

  /// What the two qualities trade.
  String get ocrQualityHint;

  /// The default recognition language.
  String get ocrLanguageTitle;

  /// The second language read with the default.
  String get ocrAlsoTitle;

  /// What "Also" is for.
  String get ocrAlsoSubtitle;

  /// No second language.
  String get ocrAlsoNone;

  /// The downloaded languages’ heading, with their size.
  String ocrOnDevice(String size);

  /// The heading of the languages to download.
  String get ocrOtherLanguages;

  /// The language search field’s hint.
  String ocrSearchLanguages(int count);

  /// The badge on the default language.
  String get ocrLanguageDefault;

  /// Asks before deleting a language.
  String ocrLanguageDeleteTitle(String language);

  /// What deleting an OCR file frees.
  String ocrDeleteBody(String size);

  // Recognize text (#594).

  /// The command, and the dialog that asks how (#594).
  String get ocrRecognizeAction;

  /// The dialog's pages choice.
  String get ocrPagesTitle;

  /// Every page of the PDF.
  String ocrPagesAll(int count);

  /// The page on screen.
  String ocrPagesThis(int page);

  /// A range of pages: its first.
  String get ocrPagesFrom;

  /// A range of pages: its last.
  String get ocrPagesTo;

  /// Where the text goes.
  String get ocrSavedAs;

  /// What the sidecar is.
  String get ocrSavedAsHint;

  /// A PDF that already carries text, so it may not need recognizing.
  String get ocrPdfHasText;

  /// What a first recognition downloads.
  String ocrNeedsDownload(String size);

  /// That the download happens once.
  String get ocrNeedsDownloadHint;

  /// Recognizes after the download it needs.
  String get ocrDownloadAndRecognize;

  /// The progress of a recognition.
  String ocrRecognizing(int page, int total);

  /// A recognition fetching its engine or languages.
  String get ocrPreparing;

  /// A recognition finished.
  String ocrRecognized(int words);

  /// Opens the recognized text.
  String get ocrOpenText;

  /// A recognition that failed.
  String get ocrFailed;

  /// Why the Recognize text command is off.
  String get commandNeedOcrFile;

  // The scan and its text (#595).

  /// The pane, or the switch side, showing the recognized text (#595).
  String get ocrTextTitle;

  /// The switch side showing the scan.
  String get ocrScanTitle;

  /// Opens the recognized text as a note.
  String get ocrOpenAsNote;

  /// Shows the Text pane beside the scan.
  String get ocrShowText;

  /// Hides the Text pane.
  String get ocrHideText;

  /// Copies the recognized text.
  String get ocrCopyText;

  // Recognized lines on the scan (#596).

  /// Lines a hand edit left without their place on the scan (#596).
  String ocrLostPlaces(int page, int lines);

  /// Reads that page again.
  String ocrRecognizeAgain(int page);

  /// Capturing a web page as a note (#531): the command, the dialog's title.
  String get captureWebPage;

  /// The field of the page's address.
  String get capturePageField;

  /// Under the address, when it came from the clipboard.
  String get captureFromClipboard;

  /// An address that is not a web page's.
  String get captureInvalidUrl;

  /// Reads the page at the address typed.
  String get captureRead;

  /// The page is downloading.
  String get captureDownloading;

  /// The page downloaded, and how large it was.
  String captureDownloaded(String size);

  /// The download had too little text.
  String captureFewWords(int words);

  /// The page runs in a browser, after too little text.
  String get captureRunningBrowser;

  /// What the browser a page runs in can reach.
  String get captureBrowserPrivacy;

  /// The article was found by running the page in a browser.
  String get captureReadInBrowser;

  /// A page read with no article in it.
  String get captureNoArticle;

  /// The field of the note's title.
  String get captureTitleField;

  /// The field of the folder the note goes in.
  String get captureFolderField;

  /// The field a tag is added from.
  String get captureAddTag;

  /// The heading of what the note will be.
  String get capturePreview;

  /// How long the article is, and how long it takes to read.
  String captureWordsMinutes(int words, int minutes);

  /// Whether the article's pictures are downloaded into the attachments
  /// folder.
  String captureDownloadPictures(int count, String folder);

  /// The heading of what was left out of the page.
  String get captureRemoved;

  /// The page's scripts and styles, left out.
  String captureRemovedCode(int scripts, int styles);

  /// The page's navigation menu, left out.
  String get captureRemovedMenu;

  /// The page's cookie banner, left out.
  String get captureRemovedBanner;

  /// The rest of the page around the article — its footer, related posts —
  /// left out.
  String captureRemovedAround(int words);

  /// Saves the captured page as a note.
  String get captureSaveNote;

  /// The note is being saved, its pictures downloaded.
  String get captureSaving;

  /// The notice a captured page with no article gets in its note, as
  /// Markdown:
  /// its link to the page is kept.
  String captureUnreadableNotice(String url);

  /// A capture refused: the address is not http or https.
  String get captureFailScheme;

  /// A capture failed: too many redirects.
  String get captureFailRedirects;

  /// A capture failed: no answer in time.
  String get captureFailTimeout;

  /// A capture failed: the page is too large.
  String get captureFailTooLarge;

  /// A capture failed: the address is a file, not a page.
  String get captureFailNotHtml;

  /// A capture failed: the site answered with an error status.
  String captureFailStatus(String code);

  /// A capture failed: the page could not be reached.
  String get captureFailNetwork;

  /// A link dragged over the window.
  String get captureDropHint;

  /// What a link dropped on the window does.
  String get captureDropDetail;

  /// The title of the sheet a browser's share opens (#531).
  String get captureSaveToNiman;

  /// Under the share sheet's Save: the capture goes on without the app on
  /// screen.
  String get captureBackgroundHint;

  /// A shared quote goes at the end of a note the user picks.
  String get captureAppendToNote;

  /// Appends the shared quote.
  String get captureAppend;

  /// The notification while a shared page is read.
  String captureReadingHost(String host);

  /// The notification once a shared page is a note.
  String captureSavedTitle(String title);

  /// Under it: where the note is, how long, and how many pictures came.
  String captureSavedBody(String folder, int words, int images);

  /// The notification once a shared page with no article is a note.
  String get captureSavedUnreadable;

  /// Under it: what such a note keeps.
  String captureUnreadableBody(String host);

  /// The notification once a shared quote is in a note.
  String captureQuoteAdded(String note);

  /// Under it: the page the quote came from.
  String captureQuoteFrom(String title);

  /// The notification when a shared page could not be captured.
  String captureFailedTitle(String host);

  /// A notification's button: the app, the note's folder in the tree.
  String get captureShowFolder;

  /// A notification's button: opens the note a capture made (#531).
  String get captureOpen;

  /// The share sheet's tab for text selected on a page.
  String get captureQuote;

  /// A shared quote goes in a new note in [folder].
  String captureNewNoteIn(String folder);

  /// Downloads a page's pictures into [folder], before their number is
  /// known.
  String captureDownloadPicturesTo(String folder);

  /// Highlights the selected passage of a PDF or a book (#626).
  String get highlightAction;

  /// A highlight, among the marks a tap asks between.
  String get highlightMark;

  /// A highlight's action: takes it out of its note.
  String get highlightRemove;

  /// A highlight could not be written into its note.
  String get highlightFailed;

  /// A highlight colour, as a swatch is named.
  String get highlightYellow;

  /// A highlight colour, as a swatch is named.
  String get highlightGreen;

  /// A highlight colour, as a swatch is named.
  String get highlightBlue;

  /// A highlight colour, as a swatch is named.
  String get highlightPink;

  /// A highlight's action: copies its passage.
  String get highlightCopy;

  /// Paste as Markdown (#531): the clipboard's HTML pasted as Markdown —
  /// the command, and the editor menu's entry.
  String get pasteAsMarkdown;

  /// Said once the clipboard's HTML is pasted as Markdown, with Undo.
  String get pastedAsMarkdown;

  /// The same, when the paste links to the page at [host].
  String pastedAsMarkdownWithLink(String host);

  /// Settings → Navigation (#536): the area, its intro, the two homes of
  /// the layout, and what the locked destination says.
  String get settingsAreaNavigation;
  String get navigationIntro;
  String get navigationScopeLibrary;
  String get navigationScopeDevice;
  String get navigationAlwaysShown;
  String get navigationStart;
  String navigationStartHidden(String hidden, String start);

  // Slide notes (#534).
  String get newSlidesTitle;
  String get newSlidesDefault;
  String get showSlidesTooltip;
  String get slidesPresent;
  String get slidesPresenterView;
  String get slidesMarkdownPreview;
  String get slidesExportPdf;
  String get slidesSpeakerNotes;
  String get slidesOverview;
  String get slidesNotes;
  String get slidesExit;
  String get slidesPrevious;
  String get slidesNext;
  String get slidesNow;
  String get slidesElapsed;
  String get slidesSlideOnly;
  String get slidesPause;
  String get slidesRestart;
  String get slidesSwipeToExit;
  String get slidesMarkdown;
  String get commandNeedSlidesNote;
  String get slidesTemplateSecond;
  String get slidesTemplatePoint;
  String get slidesTemplateNote;

  // Home (#535): the destination, its tiles, and what they say empty.
  String get tabHome;
  String get homeTileActions;
  String get homeTileJournalToday;
  String get homeTileTasksDue;
  String get homeTileRecent;
  String get homeTilePinned;
  String get homeTileJournalCalendar;
  String get homeTileTopTags;
  String get homeTileRandomNote;
  String get homeTileSearch;
  String get homeJournalEmpty;
  String get homeJournalWrite;
  String get homeTasksEmpty;
  String get homeNotesEmpty;
  String get homePinnedEmpty;
  String get homeTagsEmpty;
  String get homeSearchEmpty;
  String get homeSearchNoQuery;
  String get homeRandomAnother;

  // Home (#535): editing it — the grid, the list, where it is kept.
  String get homeEdit;
  String get homeEditDone;
  String get homeReset;
  String get homeResetTitle;
  String get homeResetBody;
  String get homeUseLibraryTitle;
  String get homeUseLibraryBody;
  String get homeUseLibraryConfirm;
  String get homeAddTiles;
  String get homeHiddenTiles;
  String get homeTileOnHome;
  String get homeTileHide;
  String get homeTileShow;
  String get homeTileMove;
  String get homeMoveLeft;
  String get homeMoveRight;
  String get homeMoveUp;
  String get homeMoveDown;
  String get homeWider;
  String get homeNarrower;
  String get homeTaller;
  String get homeShorter;
  String get homeTileSettings;
  String get homeSearchName;
  String get homeSearchQuery;
  String get homeSearchQueryHint;
  String get homeGridHint;
  String get homeColumnHint;

  // Home (#535): its actions, their editor and what breaks them.
  String get homeActionAdd;
  String get homeActionAsk;
  String get homeActionAskHint;
  String get homeActionCaptureFolder;
  String get homeActionContext;
  String get homeActionEdit;
  String get homeActionFieldAdd;
  String get homeActionFieldKey;
  String get homeActionFields;
  String get homeActionFixed;
  String get homeActionFixedHint;
  String get homeActionFolder;
  String get homeActionIcon;
  String get homeActionKind;
  String get homeActionKindOpenNote;
  String get homeActionLabel;
  String get homeActionNoNote;
  String get homeActionNote;
  String get homeActionNoTemplate;
  String get homeActionNoteName;
  String get homeActionOpenAfter;
  String get homeActionProject;
  String get homeActionTemplate;
  String homeActionMissing(String path);
}
