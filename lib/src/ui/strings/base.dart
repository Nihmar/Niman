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
  String get debugLogsTitle;
  String get debugLogsSubtitle;
  String get lineNumbersTitle;
  String get lineNumbersSubtitle;
  String get keyboardOnOpenTitle;
  String get keyboardOnOpenSubtitle;
  String get editorKindSource;
  String get editorKindWysiwyg;
  String get settingsPreviewEnabledTitle;
  String get settingsPreviewEnabledSubtitle;
  String get switchToWysiwygTooltip;
  String get switchToSourceTooltip;
  String get wysiwygTooLarge;

  // Settings: the section headings the list is grouped under.
  String get settingsSectionAppearance;
  String get settingsSectionEditor;
  String get settingsSectionLibrary;
  String get settingsSectionReminders;
  String get settingsSectionShortcuts;
  String get keyboardShortcutsTitle;
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

  /// The indent width as a row's value, e.g. "4 spaces".
  String indentWidthValue(int spaces);

  // Settings: theme (T-M6-05).
  String get themeBrightnessTitle;
  String get themeBrightnessSubtitle;
  String get themeBrightnessSystem;
  String get themeBrightnessDay;
  String get themeBrightnessNight;
  String get themePaletteTitle;
  String get themePaletteSubtitle;
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

  // Launcher quick actions (T-SC-02), in the order they are published.
  String get shortcutQuickNote;
  String get shortcutNewTodo;
  String get shortcutNewNote;
  String get shortcutNewList;
  String get shortcutToggleSidebar;
  String get shortcutEditorSection;
  String get shortcutFind;
  String get shortcutReplace;
  String get shortcutSavingNote;

  // Editor status bar.
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
  String get newFolderTitle;
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
}
