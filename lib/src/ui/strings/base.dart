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
  String noteColumnWidthValue(int pixels);
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
  String get settingsPreviewEnabledTitle;
  String get settingsPreviewEnabledSubtitle;
  String get switchToWysiwygTooltip;
  String get switchToSourceTooltip;
  String get switchToSourceLabel;
  String get switchToWysiwygLabel;
  String get wysiwygTooLarge;

  // Settings: the section headings the list is grouped under.
  String get settingsSectionAppearance;
  String get settingsSectionEditor;
  String get settingsSectionLibrary;
  String get settingsSectionReminders;
  String get settingsSectionShortcuts;
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
  String get settingsSectionDiagnostics;
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
  String get themeSubtitle;

  /// The settings area the colors live in, and the mark on the
  /// theme in use (issue #269).
  String get settingsSectionThemes;
  String get themesInUse;
  String get themePaletteSystem;

  // Settings: text size (T-M6-12).
  String get uiTextScaleTitle;
  String get uiTextScaleSubtitle;
  String get noteTextScaleTitle;
  String get noteTextScaleSubtitle;

  // Settings: preview mode.
  String get previewModeTitle;
  String get previewModeSubtitle;
  String get previewModeAuto;
  String get previewModeSwitch;
  String get splitRatioTitle;
  String get splitRatioSubtitle;

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

  // List note kind (T-TK-02).
  String get listAddHint;
  String get listAddTooltip;
  String get listEmpty;
  String get listDragHandleLabel;

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
  String get toolbarSuperscript;
  String get toolbarUnderline;
  String get toolbarLink;
  String get toolbarCode;
  String get toolbarImage;
  String get toolbarHeading;
  String get toolbarList;
  String get toolbarOrderedList;
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
  String get enterFullScreenTooltip;
  String get exitFullScreenTooltip;

  // Raw-HTML table fallback.
  String get htmlTableFallback;

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
  String get todoNoPriority;
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
  String get actionCreate;
  String get actionNew;
  String get actionSave;
  String get actionClear;
  String get actionChoose;
  String get actionDelete;
  String get actionRename;
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
  String get pinnedSection;

  /// The pinned section's heading, with its count, e.g. "Pinned · 3".
  String pinnedSectionCount(int count);

  String get templateFolderTitle;
  String get newFromTemplateTitle;
  String get newFromTemplateHere;
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

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  String includeMissing(String path);
  String includeCycle(String path);
  String includeTooDeep(String path);
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
  String get commandsTitle;
  String get commandsIntro;
  String get commandNeedNone;
  String get commandNeedOpenNote;
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
  String get typewriterSubtitle;
  String get zenMode;
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
  String get shortcutChange;
  String shortcutCaptureTitle(String command);
  String shortcutConflict(String keys, String other);
  String shortcutTakesEditorKey(String keys, String what);
  String get openFileMissing;
  String get openFileFailed;
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

  // Android storage access.
  String get storageAccessAction;
  String get storageAccessNeeded;
  String get storageAccessExplained;
  String folderAccessDenied(Object error);
  String folderPickFailed(Object error);

  // Settings screen rows and messages.
  String get settingsTitle;
  String get libraryPathTitle;
  String get reindexTitle;
  String get reindexDone;
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

  // The about section (issue #80): the app's version and its changelog.
  String get settingsSectionAbout;
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
  String get transcriptionModelDownload;
  String transcriptionModelDeleteTitle(String model);
  String transcriptionModelDeleteBody(String size);
  String get transcriptionModelFailed;
  String get actionRetry;
  String get transcriptionModelRetrying;
  String transcriptionModelInterrupted(String progress);
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
  String get syncCloseAction;
  String get syncDoneSnack;
  String syncTrashedSnack(int count);
  String syncConflictsSnack(int count);
  String get syncShowAction;
  String get syncConflictTitle;
  String get syncConflictLegend;
  String get syncConflictBinary;
  String get syncConflictKeepNote;
  String get syncKeepLocal;
  String get syncKeepRemote;
  String get syncConflictIdentical;
  String get syncConflictLoadFailed;
  String get syncResolveFailed;
  String get syncResolved;
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
  String get syncMergeKeepLocal;
  String get syncMergeKeepRemote;
  String get syncMergeKeepBoth;
  String get syncMergeSave;
  String get syncMergeKeepWhole;
}
