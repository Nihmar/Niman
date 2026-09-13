/// The single file for UI strings — every user-visible label resolves here,
/// in whatever language the app speaks.
library;

// The getters need no per-member docs: their names are the labels', and
// the class doc explains where each label comes from.
// ignore_for_file: public_member_api_docs

import 'package:niman/src/core/language.dart';
import 'package:niman/src/ui/strings/base.dart';
import 'package:niman/src/ui/strings/ca.dart';
import 'package:niman/src/ui/strings/cs.dart';
import 'package:niman/src/ui/strings/da.dart';
import 'package:niman/src/ui/strings/de.dart';
import 'package:niman/src/ui/strings/en.dart';
import 'package:niman/src/ui/strings/es.dart';
import 'package:niman/src/ui/strings/eu.dart';
import 'package:niman/src/ui/strings/fi.dart';
import 'package:niman/src/ui/strings/fr.dart';
import 'package:niman/src/ui/strings/gl.dart';
import 'package:niman/src/ui/strings/hi.dart';
import 'package:niman/src/ui/strings/hr.dart';
import 'package:niman/src/ui/strings/hu.dart';
import 'package:niman/src/ui/strings/it.dart';
import 'package:niman/src/ui/strings/ja.dart';
import 'package:niman/src/ui/strings/nb.dart';
import 'package:niman/src/ui/strings/nl.dart';
import 'package:niman/src/ui/strings/pl.dart';
import 'package:niman/src/ui/strings/pt.dart';
import 'package:niman/src/ui/strings/ro.dart';
import 'package:niman/src/ui/strings/sk.dart';
import 'package:niman/src/ui/strings/sl.dart';
import 'package:niman/src/ui/strings/sv.dart';
import 'package:niman/src/ui/strings/zh.dart';

/// All user-visible app strings, one getter per label.
///
/// The labels live in `ui/strings/<locale>.dart`, one class per language;
/// this facade dispatches to the class of the active language. Each entry
/// is a getter rather than a constant because the answer depends on the
/// active language; call sites never pass a locale and never need a
/// `BuildContext`.
///
/// The locale-independent pieces — brand names, palette names, the
/// task-list format examples, and the plain percent/space formatters —
/// stay in this file.
final class AppStrings {
  const new _();

  /// One strings instance per language, in [AppLanguage] order.
  static const Map<AppLanguage, Strings> _byLanguage = {
    AppLanguage.english: EnglishStrings(),
    AppLanguage.french: FrenchStrings(),
    AppLanguage.german: GermanStrings(),
    AppLanguage.spanish: SpanishStrings(),
    AppLanguage.portuguese: PortugueseStrings(),
    AppLanguage.chinese: ChineseStrings(),
    AppLanguage.japanese: JapaneseStrings(),
    AppLanguage.hindi: HindiStrings(),
    AppLanguage.italian: ItalianStrings(),
    AppLanguage.dutch: DutchStrings(),
    AppLanguage.swedish: SwedishStrings(),
    AppLanguage.norwegian: NorwegianStrings(),
    AppLanguage.danish: DanishStrings(),
    AppLanguage.basque: BasqueStrings(),
    AppLanguage.catalan: CatalanStrings(),
    AppLanguage.galician: GalicianStrings(),
    AppLanguage.czech: CzechStrings(),
    AppLanguage.finnish: FinnishStrings(),
    AppLanguage.polish: PolishStrings(),
    AppLanguage.romanian: RomanianStrings(),
    AppLanguage.slovak: SlovakStrings(),
    AppLanguage.slovenian: SlovenianStrings(),
    AppLanguage.hungarian: HungarianStrings(),
    AppLanguage.croatian: CroatianStrings(),
  };

  /// The strings of the language actually in use.
  static Strings get _s =>
      _byLanguage[AppLanguages.resolved] ?? const EnglishStrings();

  // Dates written out (template placeholders, T-TPL-01). Indexed from
  // zero: month 1 is [0].
  static List<String> get monthNames => _s.monthNames;
  static List<String> get monthNamesShort => _s.monthNamesShort;

  /// Monday first, as `DateTime.weekday` counts: weekday 1 is [0].
  static List<String> get weekdayNames => _s.weekdayNames;
  static List<String> get weekdayNamesShort => _s.weekdayNamesShort;

  // Settings: editor toggles.
  static String get trashTitle => _s.trashTitle;
  static String get trashSubtitle => _s.trashSubtitle;
  static String get debugLogsTitle => _s.debugLogsTitle;
  static String get debugLogsSubtitle => _s.debugLogsSubtitle;
  static String get lineNumbersTitle => _s.lineNumbersTitle;
  static String get lineNumbersSubtitle => _s.lineNumbersSubtitle;
  static String get keyboardOnOpenTitle => _s.keyboardOnOpenTitle;
  static String get keyboardOnOpenSubtitle => _s.keyboardOnOpenSubtitle;
  static String get editorKindSource => _s.editorKindSource;
  static String get editorKindWysiwyg => _s.editorKindWysiwyg;
  static String get settingsPreviewEnabledTitle =>
      _s.settingsPreviewEnabledTitle;
  static String get settingsPreviewEnabledSubtitle =>
      _s.settingsPreviewEnabledSubtitle;
  static String get switchToWysiwygTooltip => _s.switchToWysiwygTooltip;
  static String get switchToSourceTooltip => _s.switchToSourceTooltip;
  static String get wysiwygTooLarge => _s.wysiwygTooLarge;

  // Settings: the section headings the list is grouped under.
  static String get settingsSectionAppearance => _s.settingsSectionAppearance;
  static String get settingsSectionEditor => _s.settingsSectionEditor;
  static String get settingsSectionLibrary => _s.settingsSectionLibrary;
  static String get settingsSectionReminders => _s.settingsSectionReminders;
  static String get settingsSectionShortcuts => _s.settingsSectionShortcuts;
  static String get keyboardShortcutsTitle => _s.keyboardShortcutsTitle;
  static String get settingsSectionDiagnostics => _s.settingsSectionDiagnostics;
  static String get settingsSpellCheckTitle => _s.settingsSpellCheckTitle;
  static String get settingsSpellCheckSubtitle => _s.settingsSpellCheckSubtitle;
  static String get spellCheckDictionaryTitle => _s.spellCheckDictionaryTitle;
  static String get spellCheckDictionarySystem => _s.spellCheckDictionarySystem;
  static String get spellCheckDictionaryChoiceTitle =>
      _s.spellCheckDictionaryChoiceTitle;
  static String get spellCheckDictionaryChoiceSubtitle =>
      _s.spellCheckDictionaryChoiceSubtitle;
  static String get spellCheckNoDictionaries => _s.spellCheckNoDictionaries;

  // Spelling review (T-PP-09).
  static String get spellCheckTooltip => _s.spellCheckTooltip;
  static String get spellCheckTitle => _s.spellCheckTitle;
  static String get spellCheckEmpty => _s.spellCheckEmpty;
  static String get spellCheckUnavailable => _s.spellCheckUnavailable;
  static String get spellCheckNoSuggestions => _s.spellCheckNoSuggestions;
  static String spellCheckCount(int count) => _s.spellCheckCount(count);
  static String spellCheckLine(int line) => _s.spellCheckLine(line);

  /// The indent width as a row's value, e.g. "4 spaces".
  static String indentWidthValue(int spaces) => _s.indentWidthValue(spaces);

  /// The editor's share of a split, as a row's value, e.g. "50%".
  static String splitRatioValue(double ratio) => '${(ratio * 100).round()}%';

  // Settings: theme (T-M6-05).
  static String get themeBrightnessTitle => _s.themeBrightnessTitle;
  static String get themeBrightnessSubtitle => _s.themeBrightnessSubtitle;
  static String get themeBrightnessSystem => _s.themeBrightnessSystem;
  static String get themeBrightnessDay => _s.themeBrightnessDay;
  static String get themeBrightnessNight => _s.themeBrightnessNight;
  static String get themePaletteTitle => _s.themePaletteTitle;
  static String get themePaletteSubtitle => _s.themePaletteSubtitle;

  /// The device-colors palette. Named for what it does rather than for
  /// Material You: on a device that offers nothing it is the colors the
  /// app ships with, and calling that "Material You" would be a promise
  /// the device did not keep.
  static String get themePaletteSystem => _s.themePaletteSystem;

  // The named palettes keep their names: they are what their authors
  // published, and someone looking for Catppuccin is looking for the
  // word.
  static String get themePaletteCatppuccin => 'Catppuccin';
  static String get themePaletteSolarized => 'Solarized';
  static String get themePaletteGruvbox => 'Gruvbox';
  static String get themePaletteNiman => 'Niman';

  // Settings: text size (T-M6-12).
  static String get uiTextScaleTitle => _s.uiTextScaleTitle;
  static String get uiTextScaleSubtitle => _s.uiTextScaleSubtitle;
  static String get noteTextScaleTitle => _s.noteTextScaleTitle;
  static String get noteTextScaleSubtitle => _s.noteTextScaleSubtitle;

  /// A text size as a row's value, e.g. "120%".
  static String textScaleValue(double scale) => '${(scale * 100).round()}%';

  // Settings: preview mode.
  static String get previewModeTitle => _s.previewModeTitle;
  static String get previewModeSubtitle => _s.previewModeSubtitle;
  static String get previewModeAuto => _s.previewModeAuto;
  static String get previewModeSwitch => _s.previewModeSwitch;
  static String get splitRatioTitle => _s.splitRatioTitle;
  static String get splitRatioSubtitle => _s.splitRatioSubtitle;

  // Settings: editor formatting.
  static String get linkTypeTitle => _s.linkTypeTitle;
  static String get linkTypeSubtitle => _s.linkTypeSubtitle;
  static String get linkTypeWikilink => _s.linkTypeWikilink;
  static String get linkTypeMarkdown => _s.linkTypeMarkdown;
  static String get indentWidthTitle => _s.indentWidthTitle;
  static String get indentWidthSubtitle => _s.indentWidthSubtitle;

  // Settings: language (T-L10N-04).
  static String get languageTitle => _s.languageTitle;
  static String get languageSubtitle => _s.languageSubtitle;

  /// How a language reads as in the language picker: in its own language,
  /// because someone who landed in the wrong one has to be able to find
  /// their way back.
  static String languageName(AppLanguage language) => switch (language) {
    AppLanguage.system => _s.languageSystem,
    AppLanguage.english => 'English',
    AppLanguage.french => 'Français',
    AppLanguage.german => 'Deutsch',
    AppLanguage.spanish => 'Español',
    AppLanguage.portuguese => 'Português',
    AppLanguage.chinese => '中文',
    AppLanguage.japanese => '日本語',
    AppLanguage.hindi => 'हिन्दी',
    AppLanguage.italian => 'Italiano',
    AppLanguage.dutch => 'Nederlands',
    AppLanguage.swedish => 'Svenska',
    AppLanguage.norwegian => 'Norsk bokmål',
    AppLanguage.danish => 'Dansk',
    AppLanguage.basque => 'Euskara',
    AppLanguage.catalan => 'Català',
    AppLanguage.galician => 'Galego',
    AppLanguage.czech => 'Čeština',
    AppLanguage.finnish => 'Suomi',
    AppLanguage.polish => 'Polski',
    AppLanguage.romanian => 'Română',
    AppLanguage.hungarian => 'Magyar',
    AppLanguage.croatian => 'Hrvatski',
    AppLanguage.slovak => 'Slovenčina',
    AppLanguage.slovenian => 'Slovenščina',
  };

  // List note kind (T-TK-02).
  static String get listAddHint => _s.listAddHint;
  static String get listAddTooltip => _s.listAddTooltip;
  static String get listEmpty => _s.listEmpty;
  static String get listDragHandleLabel => _s.listDragHandleLabel;

  // Launcher quick actions (T-SC-02), in the order they are published.
  static String get shortcutQuickNote => _s.shortcutQuickNote;
  static String get shortcutNewTodo => _s.shortcutNewTodo;
  static String get shortcutNewNote => _s.shortcutNewNote;
  static String get shortcutNewList => _s.shortcutNewList;
  static String get shortcutToggleSidebar => _s.shortcutToggleSidebar;
  static String get shortcutEditorSection => _s.shortcutEditorSection;
  static String get shortcutFind => _s.shortcutFind;
  static String get shortcutReplace => _s.shortcutReplace;
  static String get shortcutSavingNote => _s.shortcutSavingNote;

  // Editor status bar.
  static String get outlineTooltip => _s.outlineTooltip;
  static String get outlineNoHeadings => _s.outlineNoHeadings;
  static String get outlineNoTitle => _s.outlineNoTitle;

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  static String get toolbarBold => _s.toolbarBold;
  static String get toolbarItalic => _s.toolbarItalic;
  static String get toolbarStrikethrough => _s.toolbarStrikethrough;
  static String get toolbarSuperscript => _s.toolbarSuperscript;
  static String get toolbarUnderline => _s.toolbarUnderline;
  static String get toolbarLink => _s.toolbarLink;
  static String get toolbarCode => _s.toolbarCode;
  static String get toolbarImage => _s.toolbarImage;
  static String get toolbarHeading => _s.toolbarHeading;
  static String get toolbarList => _s.toolbarList;
  static String get toolbarOrderedList => _s.toolbarOrderedList;
  static String get toolbarQuote => _s.toolbarQuote;
  static String get toolbarIndent => _s.toolbarIndent;
  static String get toolbarOutdent => _s.toolbarOutdent;
  static String get headingDialogTitle => _s.headingDialogTitle;

  // Toolbar settings (T-TB-05).
  static String get toolbarSettingsTitle => _s.toolbarSettingsTitle;
  static String get toolbarSettingsHint => _s.toolbarSettingsHint;
  static String get toolbarShowButton => _s.toolbarShowButton;
  static String get toolbarHideButton => _s.toolbarHideButton;
  static String get toolbarResetOrder => _s.toolbarResetOrder;

  // Preview switch (phone mode).
  static String get showPreviewTooltip => _s.showPreviewTooltip;
  static String get showEditorTooltip => _s.showEditorTooltip;
  static String get enterFullScreenTooltip => _s.enterFullScreenTooltip;
  static String get exitFullScreenTooltip => _s.exitFullScreenTooltip;

  // Raw-HTML table fallback.
  static String get htmlTableFallback => _s.htmlTableFallback;

  // Search (T-M3-05).
  static String get searchHint => _s.searchHint;
  static String get searchModeWords => _s.searchModeWords;
  static String get searchModeContains => _s.searchModeContains;
  static String get searchEmptyHint => _s.searchEmptyHint;
  static String get searchTooShortHint => _s.searchTooShortHint;
  static String get searchNoMatches => _s.searchNoMatches;
  static String get searchLoadMore => _s.searchLoadMore;

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  static String get replaceTooltip => _s.replaceTooltip;
  static String get replaceInNoteAction => _s.replaceInNoteAction;
  static String get replaceInThisNote => _s.replaceInThisNote;
  static String get replaceWithLabel => _s.replaceWithLabel;
  static String get replaceCaseSensitive => _s.replaceCaseSensitive;
  static String get replaceWholeWordsHint => _s.replaceWholeWordsHint;
  static String get replaceConfirm => _s.replaceConfirm;
  static String get replaceCancel => _s.replaceCancel;
  static String get replaceUnavailable => _s.replaceUnavailable;

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  static String get findInNoteTooltip => _s.findInNoteTooltip;
  static String get editorFindHint => _s.editorFindHint;
  static String get editorReplaceHint => _s.editorReplaceHint;
  static String get editorFindCaseTooltip => _s.editorFindCaseTooltip;
  static String get editorFindPreviousTooltip => _s.editorFindPreviousTooltip;
  static String get editorFindNextTooltip => _s.editorFindNextTooltip;
  static String get editorFindCloseTooltip => _s.editorFindCloseTooltip;
  static String get editorFindReplaceModeTooltip =>
      _s.editorFindReplaceModeTooltip;
  static String get editorReplaceOneTooltip => _s.editorReplaceOneTooltip;
  static String get editorReplaceAllTooltip => _s.editorReplaceAllTooltip;

  // Tags (T-M3-06).
  static String get openTagsTooltip => _s.openTagsTooltip;
  static String get tagsTitle => _s.tagsTitle;
  static String get tagsEmpty => _s.tagsEmpty;
  static String get tagsBackTooltip => _s.tagsBackTooltip;
  static String get tagsNotesEmpty => _s.tagsNotesEmpty;

  /// The last row of a tag's note list when the tag has more notes than
  /// the list shows (T-M6-01).
  static String tagsNotesCapped(int limit) => _s.tagsNotesCapped(limit);

  // Link navigation (T-M3-07).
  static String get unresolvedLinkTitle => _s.unresolvedLinkTitle;
  static String get headingNotFoundTitle => _s.headingNotFoundTitle;
  static String get ambiguousLinkTitle => _s.ambiguousLinkTitle;
  static String get openLinkFailed => _s.openLinkFailed;

  // Task lists (T-TD-04).
  static String get todoOpen => _s.todoOpen;
  static String get todoDone => _s.todoDone;

  // Filter row + sheet (T-TDM-03).
  static String get todoAllDates => _s.todoAllDates;
  static String get todoFilter => _s.todoFilter;
  static String get todoNoTokens => _s.todoNoTokens;

  // The "N open" / "N done" count (T-TDM-03).
  static String get todoCountOpen => _s.todoCountOpen;
  static String get todoCountDone => _s.todoCountDone;
  static String get todoEmptyOpen => _s.todoEmptyOpen;
  static String get todoEmptyDone => _s.todoEmptyDone;
  static String get todoEmptyFiltered => _s.todoEmptyFiltered;
  static String get todoTitle => _s.todoTitle;
  static String get todoAddTooltip => _s.todoAddTooltip;

  // The todo.txt format help (T-TD-08).
  static String get todoHelpTitle => _s.todoHelpTitle;
  static String get todoHelpTooltip => _s.todoHelpTooltip;
  static String get todoHelpIntro => _s.todoHelpIntro;
  static String get todoHelpFilesTitle => _s.todoHelpFilesTitle;
  static String get todoHelpFilesBody => _s.todoHelpFilesBody;
  static String get todoHelpLineTitle => _s.todoHelpLineTitle;
  static String get todoHelpLineBody => _s.todoHelpLineBody;
  // The format examples themselves are not text: they are the syntax,
  // written the same in every language.
  static String get todoHelpDone => 'x';
  static String get todoHelpDoneBody => _s.todoHelpDoneBody;
  static String get todoHelpPriority => _s.todoHelpPriority;
  static String get todoHelpPriorityBody => _s.todoHelpPriorityBody;
  static String get todoHelpDates => '2026-09-08 2026-09-01';
  static String get todoHelpDatesBody => _s.todoHelpDatesBody;
  static String get todoHelpTokensTitle => _s.todoHelpTokensTitle;
  static String get todoHelpTokensBody => _s.todoHelpTokensBody;
  static String get todoHelpProject => '+project';
  static String get todoHelpProjectBody => _s.todoHelpProjectBody;
  static String get todoHelpContext => '@context';
  static String get todoHelpContextBody => _s.todoHelpContextBody;
  static String get todoHelpHashtag => '#tag';
  static String get todoHelpHashtagBody => _s.todoHelpHashtagBody;
  static String get todoHelpTagsTitle => _s.todoHelpTagsTitle;
  static String get todoHelpTagsBody => _s.todoHelpTagsBody;
  static String get todoHelpDue => 'due:2026-09-09';
  static String get todoHelpDueBody => _s.todoHelpDueBody;
  static String get todoHelpRem => 'rem:2026-09-08T14:30';
  static String get todoHelpRemBody => _s.todoHelpRemBody;
  static String get todoHelpRemDesktop => _s.todoHelpRemDesktop;
  static String get todoHelpOther => 'anything:else';
  static String get todoHelpOtherBody => _s.todoHelpOtherBody;
  static String get todoHelpEditTitle => _s.todoHelpEditTitle;
  static String get todoHelpEditBody => _s.todoHelpEditBody;
  static String get todoAddTitle => _s.todoAddTitle;
  static String get todoEditTitle => _s.todoEditTitle;
  static String get todoDescriptionHint => _s.todoDescriptionHint;
  static String get todoCancel => _s.todoCancel;
  static String get todoSave => _s.todoSave;
  static String get todoEditAction => _s.todoEditAction;
  static String get todoDeleteAction => _s.todoDeleteAction;

  // Task filters (T-TD-05).
  static String get todoDueOverdue => _s.todoDueOverdue;
  static String get todoDueToday => _s.todoDueToday;
  static String get todoDueNext7 => _s.todoDueNext7;
  static String get todoDueNoDate => _s.todoDueNoDate;
  // The row's due labels (the range menu above names the ranges): the
  // prefix keeps the due date from being read as the reminder's date.
  static String get todoRowDue => _s.todoRowDue;
  static String get todoRowDueToday => _s.todoRowDueToday;
  static String get todoSortTooltip => _s.todoSortTooltip;
  static String get todoSortDue => _s.todoSortDue;
  static String get todoSortPriority => _s.todoSortPriority;
  static String get todoSortCreation => _s.todoSortCreation;

  // Task dialog pickers (T-TD-06).
  static String get todoNoPriority => _s.todoNoPriority;
  static String get todoNoPriorityShort => _s.todoNoPriorityShort;
  static String get todoMorePriorities => _s.todoMorePriorities;
  static String get todoPriorityTitle => _s.todoPriorityTitle;
  static String get todoNoDueDate => _s.todoNoDueDate;
  static String get todoNoReminder => _s.todoNoReminder;
  static String get todoAddProject => _s.todoAddProject;
  static String get todoAddContext => _s.todoAddContext;
  static String get todoAddHashtag => _s.todoAddHashtag;

  // Task reminders (T-TD-07).
  static String get todoReminderChannel => _s.todoReminderChannel;
  static String get todoReminderChannelDescription =>
      _s.todoReminderChannelDescription;
  static String get todoReminderBody => _s.todoReminderBody;
  static String get todoReminderFallbackTitle => _s.todoReminderFallbackTitle;
  static String get todoReminderBlocked => _s.todoReminderBlocked;
  static String get todoReminderBattery => _s.todoReminderBattery;
  static String get todoReminderInexact => _s.todoReminderInexact;
  static String get reminderShowTokensTitle => _s.reminderShowTokensTitle;
  static String get reminderShowTokensSubtitle => _s.reminderShowTokensSubtitle;
  static String get todoReminderFixAction => _s.todoReminderFixAction;
  static String get todoReminderDismissAction => _s.todoReminderDismissAction;
  static String get todoReminderDue => _s.todoReminderDue;

  // Actions and buttons shared by the dialogs (T-L10N-06).
  static String get actionOk => _s.actionOk;
  static String get actionCancel => _s.actionCancel;
  static String get actionCreate => _s.actionCreate;

  /// The desktop tree footer's create menu (T-PP-22).
  static String get actionNew => _s.actionNew;
  static String get actionSave => _s.actionSave;
  static String get actionClear => _s.actionClear;
  static String get actionChoose => _s.actionChoose;
  static String get actionDelete => _s.actionDelete;
  static String get actionRename => _s.actionRename;
  static String get actionMove => _s.actionMove;

  /// The close-with-unsaved-edits ask (T-PP-11).
  static String get saveAndClose => _s.saveAndClose;
  static String get closeUnsavedTitle => _s.closeUnsavedTitle;

  /// The close ask's body, for the unsaved notes' names.
  static String closeUnsavedBody(List<String> names) =>
      _s.closeUnsavedBody(names);

  /// The save-before-close failed, so the window stays open.
  static String get closeSaveFailed => _s.closeSaveFailed;
  static String get actionRestore => _s.actionRestore;
  static String get actionEmpty => _s.actionEmpty;

  // The shell: app bar, tabs and tree actions.
  static const String appTitle = 'Niman';

  // The window's own title bar (T-PP-22).
  static String get hideSidebarTooltip => _s.hideSidebarTooltip;
  static String get showSidebarTooltip => _s.showSidebarTooltip;
  static String get windowMinimizeTooltip => _s.windowMinimizeTooltip;
  static String get windowMaximizeTooltip => _s.windowMaximizeTooltip;
  static String get windowRestoreTooltip => _s.windowRestoreTooltip;
  static String get windowCloseTooltip => _s.windowCloseTooltip;

  static String get tabFiles => _s.tabFiles;
  static String get tabSearch => _s.tabSearch;
  static String get tabSettings => _s.tabSettings;
  static String get quickNoteTitle => _s.quickNoteTitle;
  static String get treeEmpty => _s.treeEmpty;
  static String get selectANote => _s.selectANote;
  static String get showListTooltip => _s.showListTooltip;
  static String get editRawTooltip => _s.editRawTooltip;
  static String get sortAscTooltip => _s.sortAscTooltip;
  static String get sortDescTooltip => _s.sortDescTooltip;
  static String get newNoteTitle => _s.newNoteTitle;
  static String get newFolderTitle => _s.newFolderTitle;
  static String get newNoteHere => _s.newNoteHere;
  static String get newFolderHere => _s.newFolderHere;
  static String get newListNoteTitle => _s.newListNoteTitle;
  static String get newListNoteDefault => _s.newListNoteDefault;
  static String get setAsQuickNote => _s.setAsQuickNote;
  static String get currentQuickNote => _s.currentQuickNote;
  static String get pinnedSection => _s.pinnedSection;
  static String pinnedSectionCount(int count) => _s.pinnedSectionCount(count);
  static String get templateFolderTitle => _s.templateFolderTitle;
  static String get newFromTemplateTitle => _s.newFromTemplateTitle;
  static String get newFromTemplateHere => _s.newFromTemplateHere;
  static String get templateFormTitle => _s.templateFormTitle;
  static String get templateFormBacklink => _s.templateFormBacklink;
  static String get templateFormNoNote => _s.templateFormNoNote;
  static String get templateFormPickNote => _s.templateFormPickNote;

  // The template placeholder reference (T-TPL-08).
  static String get templateHelpTitle => _s.templateHelpTitle;
  static String get templateHelpIntro => _s.templateHelpIntro;
  static String get templateHelpUnknown => _s.templateHelpUnknown;

  static String get templateHelpValuesTitle => _s.templateHelpValuesTitle;
  static String get templateHelpTitleBody => _s.templateHelpTitleBody;
  static String get templateHelpDateBody => _s.templateHelpDateBody;
  static String get templateHelpNowBody => _s.templateHelpNowBody;
  static String get templateHelpUuidBody => _s.templateHelpUuidBody;
  static String get templateHelpCounterBody => _s.templateHelpCounterBody;
  static String get templateHelpCursorBody => _s.templateHelpCursorBody;

  static String get templateHelpDatesTitle => _s.templateHelpDatesTitle;
  static String get templateHelpDatesBody => _s.templateHelpDatesBody;
  static String get templateHelpYear => _s.templateHelpYear;
  static String get templateHelpMonth => _s.templateHelpMonth;
  static String get templateHelpDay => _s.templateHelpDay;
  static String get templateHelpTime => _s.templateHelpTime;
  static String get templateHelpWeek => _s.templateHelpWeek;

  static String get templateHelpFiltersTitle => _s.templateHelpFiltersTitle;
  static String get templateHelpFiltersBody => _s.templateHelpFiltersBody;
  static String get templateHelpCaseBody => _s.templateHelpCaseBody;
  static String get templateHelpSlugBody => _s.templateHelpSlugBody;
  static String get templateHelpPadBody => _s.templateHelpPadBody;
  static String get templateHelpShiftBody => _s.templateHelpShiftBody;
  static String get templateHelpSnapBody => _s.templateHelpSnapBody;

  static String get templateHelpAskTitle => _s.templateHelpAskTitle;
  static String get templateHelpAskBody => _s.templateHelpAskBody;
  static String get templateHelpAskFieldBody => _s.templateHelpAskFieldBody;
  static String get templateHelpChoiceBody => _s.templateHelpChoiceBody;

  static String get templateHelpWhereTitle => _s.templateHelpWhereTitle;
  static String get templateHelpWhereBody => _s.templateHelpWhereBody;
  static String get templateHelpFolderBody => _s.templateHelpFolderBody;
  static String get templateHelpFilenameBody => _s.templateHelpFilenameBody;
  static String get templateHelpAppendBody => _s.templateHelpAppendBody;
  static String get templateHelpOpenBody => _s.templateHelpOpenBody;

  static String get templateHelpAroundTitle => _s.templateHelpAroundTitle;
  static String get templateHelpParentBody => _s.templateHelpParentBody;
  static String get templateHelpFolderValueBody =>
      _s.templateHelpFolderValueBody;
  static String get templateHelpClipboardBody => _s.templateHelpClipboardBody;

  static String get templateHelpIncludeTitle => _s.templateHelpIncludeTitle;
  static String get templateHelpIncludeBody => _s.templateHelpIncludeBody;

  static String get templateHelpExampleTitle => _s.templateHelpExampleTitle;

  // What an {{include:…}} that could not be pasted leaves behind, beside
  // the placeholder it could not replace (T-TPL-06).
  static String includeMissing(String path) => _s.includeMissing(path);
  static String includeCycle(String path) => _s.includeCycle(path);
  static String includeTooDeep(String path) => _s.includeTooDeep(path);
  static String frontmatterInvalid(String reason) =>
      _s.frontmatterInvalid(reason);
  static String templateFrontmatterInvalid(String template, String reason) =>
      _s.templateFrontmatterInvalid(template, reason);
  static String get templatePickerTitle => _s.templatePickerTitle;
  static String templatePickerEmpty(String folder) =>
      _s.templatePickerEmpty(folder);
  static String get actionPin => _s.actionPin;
  static String get actionUnpin => _s.actionUnpin;
  static String get movedToTrash => _s.movedToTrash;
  static String get deletedMessage => _s.deletedMessage;
  static String deleteToTrashConfirm(String name) =>
      _s.deleteToTrashConfirm(name);
  static String deleteForeverConfirm(String name) =>
      _s.deleteForeverConfirm(name);
  static String get chooseDestination => _s.chooseDestination;
  static String get libraryRoot => _s.libraryRoot;
  static String moveTitle(String name) => _s.moveTitle(name);
  static String headingLevelLabel(int level) => _s.headingLevelLabel(level);

  // Quick note tab and picker.
  static String get quickNoteEmpty => _s.quickNoteEmpty;
  static String get quickNoteChooseAction => _s.quickNoteChooseAction;
  static String get quickNoteCreateAction => _s.quickNoteCreateAction;
  static String get quickNoteNewTitle => _s.quickNoteNewTitle;
  static String get quickNotePickerTitle => _s.quickNotePickerTitle;

  // Folder picker (T-TK-07).
  static String get folderPickerNewFolder => _s.folderPickerNewFolder;
  static String get folderPickerEmpty => _s.folderPickerEmpty;
  static String get listFolderTitle => _s.listFolderTitle;

  // Trash (M1).
  static String get trashEmpty => _s.trashEmpty;
  static String get trashEmptyAction => _s.trashEmptyAction;
  static String get trashEmptyConfirm => _s.trashEmptyConfirm;
  static String trashDeleteConfirm(String name) => _s.trashDeleteConfirm(name);
  static String get trashDeletePermanently => _s.trashDeletePermanently;

  // The open/create library screen.
  static String get openLibraryIntro => _s.openLibraryIntro;
  static String get openLibraryExisting => _s.openLibraryExisting;
  static String get openLibraryCreate => _s.openLibraryCreate;
  static String get openLibraryCreateTitle => _s.openLibraryCreateTitle;
  static String get openLibraryFolderName => _s.openLibraryFolderName;
  static String get openLibraryChooseFolder => _s.openLibraryChooseFolder;
  static String get openLibraryChooseParent => _s.openLibraryChooseParent;
  static String get openLibraryUnsupported => _s.openLibraryUnsupported;

  /// The first index's counter, e.g. "412 of 10000 notes".
  static String indexingCount(int done, int total) =>
      _s.indexingCount(done, total);

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  static String get knownLibrariesTitle => _s.knownLibrariesTitle;
  static String get libraryUnreachable => _s.libraryUnreachable;
  static String get libraryOpenedToday => _s.libraryOpenedToday;
  static String get libraryOpenedYesterday => _s.libraryOpenedYesterday;
  static String libraryOpenedDaysAgo(int days) => _s.libraryOpenedDaysAgo(days);
  static String libraryOpenedOn(DateTime when) => _s.libraryOpenedOn(when);

  static String get libraryOpenNow => _s.libraryOpenNow;
  static String get switchLibraryTitle => _s.switchLibraryTitle;
  static String get libraryForget => _s.libraryForget;
  static String libraryForgetTitle(String name) => _s.libraryForgetTitle(name);
  static String get libraryForgetExplained => _s.libraryForgetExplained;

  // Android storage access.
  static String get storageAccessAction => _s.storageAccessAction;
  static String get storageAccessNeeded => _s.storageAccessNeeded;
  static String get storageAccessExplained => _s.storageAccessExplained;
  static String folderAccessDenied(Object error) =>
      _s.folderAccessDenied(error);
  static String folderPickFailed(Object error) => _s.folderPickFailed(error);

  // Settings screen rows and messages.
  static String get settingsTitle => _s.settingsTitle;
  static String get libraryPathTitle => _s.libraryPathTitle;
  static String get reindexTitle => _s.reindexTitle;
  static String get reindexDone => _s.reindexDone;
  static String get closeLibraryTitle => _s.closeLibraryTitle;
  static String get exportLogTitle => _s.exportLogTitle;
  static String get exportLogSubtitle => _s.exportLogSubtitle;
  static String get exportLogEmpty => _s.exportLogEmpty;
  static String get quickNoteUnset => _s.quickNoteUnset;
  static String exportLogDone(Object target) => _s.exportLogDone(target);
  static String exportLogFailed(Object error) => _s.exportLogFailed(error);

  // Replace results (T-M3-10).
  static String replaceNoMatch(String term) => _s.replaceNoMatch(term);
  static String replaceDone(int occurrences, String term, int notes) =>
      _s.replaceDone(occurrences, term, notes);
  static String replaceSkipped(int skipped) => _s.replaceSkipped(skipped);
  static String replacePreviewEmpty(String term, String? only) =>
      _s.replacePreviewEmpty(term, only);
}
