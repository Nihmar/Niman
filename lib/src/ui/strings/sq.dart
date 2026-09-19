// The Albanian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class AlbanianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'janar',
    'shkurt',
    'mars',
    'prill',
    'maj',
    'qershor',
    'korrik',
    'gusht',
    'shtator',
    'tetor',
    'nëntor',
    'dhjetor',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'shk',
    'mar',
    'pri',
    'maj',
    'qer',
    'kor',
    'gsh',
    'sht',
    'tet',
    'nën',
    'dhj',
  ];
  @override
  List<String> get weekdayNames => const [
    'e hënë',
    'e martë',
    'e mërkurë',
    'e enjte',
    'e premte',
    'e shtunë',
    'e diel',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'hën',
    'mar',
    'mër',
    'enj',
    'pre',
    'sht',
    'die',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Koshi';
  @override
  String get trashSubtitle =>
      'Elementët e fshirë shkojnë në .trash/ (jo aktiv = fshirje '
      'përfundimtare)';
  @override
  String get trashAutoEmptyTitle => 'Zbrazje automatike e koshit';
  @override
  String get trashAutoEmptySubtitle =>
      'Fshirjet më të vjetra zhduken përgjithmonë kur hapet biblioteka';
  @override
  String trashAutoEmptyValue(int days) => days == 0 ? 'Kurrë' : '$days ditë';
  @override
  String get debugLogsTitle => 'Ditëzatat e diagnostikimit';
  @override
  String get debugLogsSubtitle =>
      'Regjistron ngjarjet e aplikacionit në një bufër në memorie';
  @override
  String get lineNumbersTitle => 'Numrat e rreshtave';
  @override
  String get lineNumbersSubtitle =>
      'Tregon shtyllën me numrat e rreshtave në redaktor';
  @override
  String get readableLineLengthTitle => 'Gjatësi rreshti e lexueshme';
  @override
  String get readableLineLengthSubtitle =>
      'Mbaje tekstin e shënimit në një kolonë në qendër në vend të gjithë '
      'gjerësisë së dritares';
  @override
  String get noteColumnWidthTitle => 'Gjerësia e kolonës';
  @override
  String get noteColumnWidthSubtitle =>
      'Sa e gjerë është kolona e shënimit, në piksel';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Tastatura te hapja';
  @override
  String get keyboardOnOpenSubtitle =>
      'Tregon tastaturën sapo hapet shënima (jo aktiv = me prekje e parë)';
  @override
  String get editorKindSource => 'Burimi Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Burimi Markdown, ashtu siç është shkruar';
  @override
  String get editorKindWysiwygSubtitle =>
      'Tekst i formatuar, redaktohet në vend';
  @override
  String get settingsFolderToCreate => 'për t\u2019u krijuar';
  @override
  String get settingsSearchHint => 'Kërko në cilësimet';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 cilësim u gjet' : '$count cilësime u gjetën';
  @override
  String get settingsToggleOn => 'Aktiv';
  @override
  String get settingsToggleOff => 'Joaktiv';
  @override
  String get settingsPreviewEnabledTitle => 'Parapamja';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Tregon shënimin e formatuar pranë redaktorit të burimit';
  @override
  String get switchToWysiwygTooltip => 'Kalo te redaktori WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Kalo te burimi Markdown';
  @override
  String get switchToSourceLabel => 'Burimi';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Kjo shënim është tepër i madh për redaktorin WYSIWYG. Hape te '
      'burimi Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Paraqitja';
  @override
  String get settingsSectionEditor => 'Redaktues';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'Kujtesat';
  @override
  String get settingsSectionShortcuts => 'Tastatura';
  @override
  String get keyboardShortcutsTitle => 'Shkurtoret e tastaturës';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteka $name';
  @override
  String get settingsGroupLibraryHint => 'vlen vetëm për këtë bibliotekë';
  @override
  String get settingsGroupMaintenance => 'Mirëmbajtja';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Tresët dhe rrugët';
  @override
  String get settingsAreaTrashHistory => 'Koshi e kronologjia';
  @override
  String get settingsAreaDiagnostics => 'Diagnostikë e info';
  @override
  String get settingsAreaKeyboardDisabled => 'Kërkon tastierë fizike të lidhur';
  @override
  String get settingsSectionUpdates => 'Përditësime';
  @override
  String get autoUpdateTitle => 'Përditësime automatike';
  @override
  String get autoUpdateSubtitle =>
      'Kontrollon GitHub Releases në nisje dhe çdo 6 orë';
  @override
  String get checkForUpdatesTitle => 'Kontrollo për përditësime';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version është i disponueshëm';
  @override
  String get updateUpToDate => 'Niman është i përditësuar';
  @override
  String get updateCheckFailed => 'Kontrolli i përditësimeve dështoi';
  @override
  String updateSavedTo(Object path) => 'Përditësimi u ruajt në $path';
  @override
  String get updateInstallerStarted => 'Instaluesi u nis';
  @override
  String get settingsSectionDiagnostics => 'Diagnostikimi';
  @override
  String get settingsSpellCheckTitle => 'Kontrolli i shkrimit';
  @override
  String get settingsSpellCheckSubtitle =>
      'Vidon nën fjalët e shkruara gabim ndërsa shkruani.';
  @override
  String get spellCheckDictionaryTitle => 'Fjalor';
  @override
  String get spellCheckDictionarySystem => 'Sistemi standard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Zgjidh fjalorët';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Zgjidhni çdo gjuhë në të cilën është shkruar kjo bibliotekë. '
      'Fjala kalon kur njëri nga fjalorët e zgjedhur e njeh; pa të '
      'zgjedhura, e vendos sistemi.';
  @override
  String get spellCheckNoDictionaries =>
      "S'ka fjalorë të gjetur në këtë sistem.";

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Kontrolli i shkrimit';
  @override
  String get spellCheckTitle => 'Shkrim';
  @override
  String get spellCheckEmpty => 'Nuk ka gabime shkrimi.';
  @override
  String get spellCheckUnavailable =>
      "hunspell s'është instaluar në këtë sistem.";
  @override
  String get spellCheckNoSuggestions => "S'ka sugjerime";
  @override
  String spellCheckCount(int count) => '$count për shqyrtim';
  @override
  String spellCheckLine(int line) => 'rreshti $line';
  @override
  String get addWordToDictionary => 'Shto në fjalor';

  @override
  String indentWidthValue(int spaces) => '$spaces hapësira';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Dritësia';
  @override
  String get themeBrightnessSubtitle =>
      'E ndezur, e errët ose ashtu siç është vendosur pajisja';
  @override
  String get themeBrightnessSystem => 'Sistemi';
  @override
  String get themeBrightnessDay => 'Dritë';
  @override
  String get themeBrightnessNight => 'E errët';
  @override
  String get themePaletteTitle => 'Paleta';
  @override
  String get themePaletteSubtitle => 'Ngjyrat e ndërfaqes dhe të shënit';
  @override
  String get themePaletteSystem => 'Sistemi';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Madhësia e tekstit të ndërfaqes';
  @override
  String get uiTextScaleSubtitle =>
      'Pema, kartat dhe dialogjet; mbi vendosjen e sistemit';
  @override
  String get noteTextScaleTitle => 'Madhësia e tekstit të shënit';
  @override
  String get noteTextScaleSubtitle =>
      'Redaktori dhe parapamja, gjithmonë të bashkërenditura';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Modi i parapamjes';
  @override
  String get previewModeSubtitle =>
      'A e ndan parapamja ekranin me redaktorin apo e zëvendëson';
  @override
  String get previewModeAuto => 'Ngjitur';
  @override
  String get previewModeSwitch => 'Ekran i plotë';
  @override
  String get splitRatioTitle => 'Gjerësia e ndarjes';
  @override
  String get splitRatioSubtitle =>
      'Pjesa e redaktorit kur parapamja është ngjitur me të';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formati i lidhjes';
  @override
  String get linkTypeSubtitle => 'Çfarë butoni i lidhjeve në redaktor shtyn';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Krijoni shënime të munguara në';
  @override
  String get missingNoteLocationRoot => 'Rrënjë e bibliotekës';
  @override
  String get missingNoteLocationCurrentFolder => 'Tresë aktuale';
  @override
  String get indentWidthTitle => 'Gjerësia e indenteve';
  @override
  String get indentWidthSubtitle =>
      'Hapësirat që shtohen për çdo nivel indente në redaktor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Gjuha';
  @override
  String get languageSubtitle => 'Gjuha e tekstit të vetë aplikacionit';
  @override
  String get languageSystem => 'Sistemi';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Shto element';
  @override
  String get listAddTooltip => 'Shto element';
  @override
  String get listEmpty => "Ende s'ka elemente";
  @override
  String get listDragHandleLabel => 'Rirrendni elementin';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => "Ende s'ka regjistrime";
  @override
  String get audioRecord => 'Regjistro';
  @override
  String get audioStop => 'Ndalo';
  @override
  String get audioPlay => 'Luaj';
  @override
  String get audioDelete => 'Fshi regjistrimin';
  @override
  String get audioImport => 'Importo një skedar audio';
  @override
  String get audioRecording => 'Po regjistrohet…';
  @override
  String get audioPermissionDenied =>
      'Leja për mikrofonin u refuzua — nevojitet për regjistrim.';
  @override
  String get newAudioNoteTitle => 'Shënim zanor i ri';
  @override
  String get newAudioNoteDefault => 'Regjistrimi im';
  @override
  String get showAudioTooltip => 'Shfaq regjistrimet';
  @override
  String get audioMessageHint => 'Shkruaj një shënim…';
  @override
  String get audioSend => 'Dërgo';
  @override
  String get audioRename => 'Riemërto regjistrimin';
  @override
  String get audioDescriptionHint => 'Përshkruaj këtë regjistrim…';
  @override
  String get audioEditDescription => 'Ndrysho përshkrimin';
  @override
  String get audioDeleteNote => 'Fshi shënimin';
  @override
  String get audioEditNote => 'Ndrysho shënimin';
  @override
  String get audioPause => 'Pauzë';
  @override
  String get audioEditTitle => 'Ndrysho titullin';
  @override
  String get audioTitleHint => 'Titulli i këtij regjistrimi…';
  @override
  String audioUntitled(int n) => 'Regjistrimi $n';
  @override
  String get audioMoreActions => 'Më shumë veprime';
  @override
  String get audioDiscardRecording => 'Hidh regjistrimin';
  @override
  String get audioPauseRecording => 'Pezullo regjistrimin';
  @override
  String get audioResumeRecording => 'Vazhdo regjistrimin';
  @override
  String get audioRecordingPaused => 'Në pauzë';
  @override
  String get audioSavingRecording => 'Po ruhet…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Shënim i shpejtë';
  @override
  String get shortcutNewTodo => 'Detyrë e re';
  @override
  String get shortcutNewNote => 'Shënim i ri';
  @override
  String get shortcutNewList => 'Listë e re';
  @override
  String get shortcutNewAudio => 'Shënim zanor i ri';
  @override
  String get shortcutToggleSidebar => 'Shfaq ose fsheh pemën e skedarëve';
  @override
  String get shortcutCloseTab => 'Mbyll shënimin aktual';
  @override
  String get shortcutNextTab => 'Shënimi i hapur pasues';
  @override
  String get shortcutPreviousTab => 'Shënimi i hapur paraardhës';
  @override
  String get shortcutEditorSection => 'Në redaktor';
  @override
  String get shortcutFind => 'Kërko';
  @override
  String get shortcutReplace => 'Gjej dhe zëvendëso';
  @override
  String get shortcutSavingNote =>
      'Ndryshimet ruhen automatikisht, pra nuk ka shkurtore për ruajtje.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Po ngarkohet…';
  @override
  String get noteStatusSaving => 'Po ruhet…';
  @override
  String get noteStatusUnsaved => 'E paruajtur';
  @override
  String get noteStatusSaved => 'E ruajtur';
  @override
  String get noteStatusError => 'Gabim';
  @override
  String get noteNotText =>
      'Ky skedar nuk është shënim teksti, ndaj Niman nuk mund ta shfaqë këtu.';
  @override
  String get noteLoadFailed => 'Ky shënim nuk mund të hapej.';
  @override
  String wordCount(int count) => '$count fjalë';
  @override
  String get outlineTooltip => 'Përmbajtja';
  @override
  String get outlineNoHeadings => 'Nuk ka tituj';
  @override
  String get outlineNoTitle => '(pa titull)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Të trashë';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'E anashëzvarrë';
  @override
  String get toolbarSuperscript => 'Superskript';
  @override
  String get toolbarUnderline => 'Nënsvizur';
  @override
  String get toolbarLink => 'Lidhje';
  @override
  String get toolbarCode => 'Bllok kodi';
  @override
  String get toolbarImage => 'Vendos foto';
  @override
  String get toolbarHeading => 'Titull';
  @override
  String get toolbarList => 'Listë';
  @override
  String get toolbarOrderedList => 'Listë me numra';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Indente';
  @override
  String get toolbarOutdent => 'Më pak indent';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Mjete';
  @override
  String get editorToolsTitle => 'Mjetet e redaktuesit';
  @override
  String get toolCountListTitle => 'Numëro një listë';
  @override
  String get toolCountListSubtitle =>
      'Mbledh atë që rendisin rreshtat, si listë kontrolli';
  @override
  String get toolCountListNeedsList => 'Ky shënim nuk ka listë për të numëruar';
  @override
  String get tallySourceLabel => 'Listë';
  @override
  String get tallyCutLabel => 'Lexo çdo rresht si';
  @override
  String get tallyCutDash => 'Emri - vlerat';
  @override
  String get tallyCutColon => 'Emri: vlerat';
  @override
  String get tallyCutCommas => 'Vlera të ndara me presje';
  @override
  String get tallyCutWhole => 'I gjithë rreshti, si një vlerë e vetme';
  @override
  String get tallySortLabel => 'Renditja';
  @override
  String get tallySortCount => 'Më të shumtat në fillim';
  @override
  String get tallySortAlphabetical => 'Alfabetike';
  @override
  String get tallySortFirstSeen => 'Sipas listës';
  @override
  String get tallyInsert => 'Fut';
  @override
  String get tallyUpdate => 'Përditëso';
  @override
  String get tallyNothingToCount => "Këtu s'ka asgjë për të numëruar";
  @override
  String get headingDialogTitle => 'Niveli i titullit';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Shiriti i redaktorit';
  @override
  String get toolbarSettingsHint =>
      "Tërhiq për t'i rirrendur; syu i shfaq ose i fsheh butonin.";
  @override
  String get toolbarShowButton => 'Shfaq';
  @override
  String get toolbarHideButton => 'Fshih';
  @override
  String get toolbarResetOrder => 'Kthe në fillim';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Shfaq parapamjen';
  @override
  String get showEditorTooltip => 'Shfaq redaktorin';
  @override
  String get enterFullScreenTooltip => 'Ekran i plotë';
  @override
  String get exitFullScreenTooltip => 'Dil nga ekran i plotë';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tabela HTML e thjeshtë)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Kërkim shënimesh';
  @override
  String get searchModeWords => 'Fjalë';
  @override
  String get searchModeContains => 'Përmban';
  @override
  String get searchEmptyHint =>
      'Shkruani për të kërkuar në bibliotekë, ose key = value për '
      'filtrim sipas frontmatter';
  @override
  String get searchTooShortHint => 'Shkruani të paktën 2 shenja';
  @override
  String get searchNoMatches => 'Nuk ka përputhje';
  @override
  String get searchLoadMore => 'Shfaq më shumë';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Zëvendëso…';
  @override
  String get replaceInNoteAction => 'Zëvendëso në këtë shënim…';
  @override
  String get replaceInThisNote => 'Zëvendëso në këtë shënim';
  @override
  String get replaceWithLabel => 'Zëvendëso me';
  @override
  String get replaceCaseSensitive => 'Ndart shkrim të madh/të vogël';
  @override
  String get replaceWholeWordsHint =>
      'zëvendësohen vetëm përputhjet e plota të fjalëve të tëra';
  @override
  String get replaceConfirm => 'Zëvendëso';
  @override
  String get replaceCancel => 'Mbyll';
  @override
  String get replaceUnavailable =>
      "Zëvendësimi aktualisht s'është i disponueshëm";

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Gjej në shënim';
  @override
  String get editorFindHint => 'Gjej';
  @override
  String get editorReplaceHint => 'Zëvendëso';
  @override
  String get editorFindCaseTooltip => 'Përputhje e shkrimit';
  @override
  String get editorFindPreviousTooltip => 'Përputhja e mëparshme';
  @override
  String get editorFindNextTooltip => 'Përputhja tjetër';
  @override
  String get editorFindCloseTooltip => 'Mbyll kërkimin';
  @override
  String get editorFindReplaceModeTooltip => 'Modi i zëvendësimit';
  @override
  String get editorReplaceOneTooltip => 'Zëvendëso këtë përputhje';
  @override
  String get editorReplaceAllTooltip => 'Zëvendëso të gjitha';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etiketat';
  @override
  String get tagsTitle => 'Etiketat';
  @override
  String get tagsEmpty =>
      "Ende s'ka etiketa — shtoni #etiketë ose tags në frontmatter";
  @override
  String get tagsBackTooltip => 'Kthehu te kërkimi';
  @override
  String get tagsNotesEmpty => 'Nuk ka shënime me këtë etiketë';
  @override
  String tagsNotesCapped(int limit) =>
      'Shfaqen vetëm $limit të parat — kërkoni etiketën për ta ngjerrë';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => "Lidhja s'u gjet";
  @override
  String get headingNotFoundTitle => "Titulli s'u gjet";
  @override
  String get ambiguousLinkTitle => 'Shënime të shumta përputhen';
  @override
  String get openLinkFailed => "Lidhja s'u hap";

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Shënimi nuk ekziston';
  @override
  String missingNoteDialogBody(String path) => 'Krijoj „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Tresja „$folder“ nuk ekziston';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Hapur';
  @override
  String get todoDone => 'Përfunduar';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Të gjitha datat';
  @override
  String get todoFilter => 'Filtrat';
  @override
  String get todoNoTokens => "S'ka tokene në këtë listë";
  @override
  String get todoCountOpen => 'hapur';
  @override
  String get todoCountDone => 'përfunduar';
  @override
  String get todoEmptyOpen => "Ende s'ka detyra të hapura";
  @override
  String get todoEmptyDone => "Ende s'është përfunduar asgjë";
  @override
  String get todoEmptyFiltered => 'Nuk ka detyra që përputhen';
  @override
  String get todoTitle => 'Detyrat';
  @override
  String get todoAddTooltip => 'Shto detyrë';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Formati todo.txt';
  @override
  String get todoHelpTooltip => 'Ndihmë për formatin';
  @override
  String get todoHelpIntro =>
      'Detyrat tuaja janë një skedar i thjeshtë teksti, një detyrë në '
      "rresht. Niman e shkruan sintaksën për ju, por s'fsheh asgjë: "
      'mund të ndryshoni skedarin në çdo redaktor, dhe Niman do ta '
      'lexojë prapa.';
  @override
  String get todoHelpFilesTitle => 'Dy skedarë';
  @override
  String get todoHelpFilesBody =>
      'Detyrat e hapura janë në todo.txt në rrënjën e bibliotekës. '
      'Përfundimi i një detyre e shton rreshtin në done.txt, kështu '
      'që todo.txt mbetet i shkurtër. Nëse një rresht i përfunduar '
      'përsëri zëvendësohet në todo.txt, Niman e arkivon në leximin '
      'tjetër.';
  @override
  String get todoHelpLineTitle => 'Anatomia e rreshtit';
  @override
  String get todoHelpLineBody =>
      'Gjithçka para përshkrimit është opsionale dhe duhet të vijë në '
      'këtë rend:';
  @override
  String get todoHelpDoneBody =>
      'E shënon detyrën e përfunduar. Niman e shton kur e shënon '
      'katrocin.';
  @override
  String get todoHelpPriority => '(A) te (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Përparësi. A është më e larta. Shfaqet si shenjë në listë.';
  @override
  String get todoHelpDatesBody =>
      'Data e përfundimit, pastaj data e kriimit. Me vetëm një datë, '
      'ajo është data e kriimit, përveç nëse rreshti fillon me x.';
  @override
  String get todoHelpTokensTitle => 'Projektet, kontekstet dhe etiketat';
  @override
  String get todoHelpTokensBody =>
      'Kudo në përshkrim, një fjalë me një prej këtyre prefikseve '
      "bëhet një etiketë me të cilën mund të filtroni. Gjithçka s'është "
      'e përcaktuar përpara: tokeni ekziston sapo e shkruani.';
  @override
  String get todoHelpProjectBody =>
      'Çfarë e bëhet detyra, p.sh. +ndërtim ose +tezë.';
  @override
  String get todoHelpContextBody =>
      'Ku ose si do ta kryeni, p.sh. @shtëpi ose @telefoni';
  @override
  String get todoHelpHashtagBody =>
      "Etiketë e lirë, për gjithçka që dy të tjerat s'e mbuluan";
  @override
  String get todoHelpTagsTitle => 'Datat dhe kujtesat';
  @override
  String get todoHelpTagsBody =>
      'Këto janë etiketa key:value. Niman i shkruan nga dialogu i '
      'detyrës, dhe i lexon kudo që të shfaqen në rresht.';
  @override
  String get todoHelpDueBody =>
      'Data e skadhencës. Vendos bojnë e shenjës dhe filtrat e '
      'skadhencës.';
  @override
  String get todoHelpRemBody =>
      'Kur dërgohet njoftimi, në orën tuaj lokale. Vihet edhe me ekran '
      'të fikur dhe me aplikacion të mbyllur.';
  @override
  String get todoHelpRemDesktop =>
      'Në desktop, Niman duhet të jetë duke punuar kur vjen koha: '
      'kujtesa shfaqet derisa aplikacioni është hapur, dhe kur është '
      "mbyllur asgjë s'vitet.";
  @override
  String get todoHelpOtherBody =>
      'Ruhen saktësisht siç janë të shkruara, pra etiketat nga '
      'aplikacione të tjera todo.txt kalojnë rrotën. Niman nuk vepron '
      "mbi të, rec: included: detyra përsëritëse ende s'përsëritet.";
  @override
  String get todoHelpEditTitle => 'Ndryshime jashtë Niman';
  @override
  String get todoHelpEditBody =>
      'Një detyrë që nuk e keni prekur kthehet bajt pas bajti, '
      'përfshirë hapësirat e çuditshme. Ndryshoni një rresht, dhe '
      'Niman e rishkruan vetëm atë rresht në formën e tij normale, '
      'duke lënë pjesën tjetër të skedarit të pandryshuar.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Shto detyrë';
  @override
  String get todoEditTitle => 'Ndrysho detyrë';
  @override
  String get todoDescriptionHint => 'Përshkrimi';
  @override
  String get todoCancel => 'Anulo';
  @override
  String get todoSave => 'Ruaj';
  @override
  String get todoEditAction => 'Ndrysho';
  @override
  String get todoDeleteAction => 'Fshi';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'E vonuar';
  @override
  String get todoDueToday => 'Sot';
  @override
  String get todoDueNext7 => '7 ditët e ardhshme';
  @override
  String get todoDueNoDate => 'Pa datë';
  @override
  String get todoRowDue => 'Skadhencë';
  @override
  String get todoRowDueToday => 'Skadhencë sot';
  @override
  String get todoSortTooltip => 'Rendit';
  @override
  String get todoSortDue => 'Data e skadhencës';
  @override
  String get todoSortPriority => 'Përparësi';
  @override
  String get todoSortCreation => 'Data e kriimit';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Pa përparësi';
  @override
  String get todoNoPriorityShort => "S'ka";
  @override
  String get todoMorePriorities => 'Më shumë…';
  @override
  String get todoPriorityTitle => 'Përparësi';
  @override
  String get todoNoDueDate => 'Pa datë skadhencë';
  @override
  String get todoNoReminder => 'Pa kujtesë';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Etiketë';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Kujtesa për detyrat';
  @override
  String get todoReminderChannelDescription =>
      'Alarme të planifikuara për detyrat me kohë kujtese.';
  @override
  String get todoReminderBody => 'Kujtesë për detyrë';
  @override
  String get todoReminderFallbackTitle => 'Kujtesë për detyrë';
  @override
  String get todoReminderBlocked =>
      "Njoftimet janë të fikura, pra kujtesat s'do të shfaqen.";
  @override
  String get todoReminderBattery =>
      'Optimizimi i baterisë është i aktivizuar për Niman. Sistemi '
      "mund t'i vendosë aplikacionin në gjumë dhe t'i humbë kujtesat "
      'e pritura.';
  @override
  String get todoReminderInexact =>
      "Kjo pajisje s'lejon alarme të sakta, pra kujtesa mund të "
      'arrijë pas disa minuta me ekran të fikur.';
  @override
  String get reminderShowTokensTitle => 'Etiketa në njoftimet e kujtesave';
  @override
  String get reminderShowTokensSubtitle =>
      'Ruan +projekt, @kontekst dhe #etiketë në tekstin e njoftimit. '
      'Jo aktiv shfaq vetëm detyrën që e keni vendosur.';
  @override
  String get todoReminderFixAction => 'Hap vendosjet';
  @override
  String get todoReminderDismissAction => 'Hiq';
  @override
  String get todoReminderDue => 'Skadhencë';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Anulo';
  @override
  String get actionCreate => 'Krijo';
  @override
  String get actionNew => 'E re';
  @override
  String get actionSave => 'Ruaj';
  @override
  String get actionClear => 'Pastro';
  @override
  String get actionChoose => 'Zgjidh';
  @override
  String get actionDelete => 'Fshi';
  @override
  String get actionRename => 'Rimëmbaj';
  @override
  String get actionMove => 'Lëviz';
  @override
  String get saveAndClose => 'Ruaj dhe mbyll';
  @override
  String get closeUnsavedTitle => 'Ndryshime të patura';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return "„${names.first}“ ka ndryshime që ende s'ruhen. Ruaje "
          'para mbylljes?';
    }
    return "Në ${names.length} shënime ka ndryshime që ende s'ruhen. "
        'Ruanje para mbylljes?';
  }

  @override
  String get closeSaveFailed => 'Nuk u ruajt; është ende hapur.';
  @override
  String get actionRestore => 'Kthe';
  @override
  String get actionEmpty => 'Bosh';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Fshih panelin anësor (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Shfaq panelin anësor (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizo';
  @override
  String get windowMaximizeTooltip => 'Maksimizo';
  @override
  String get windowRestoreTooltip => 'Kthe';
  @override
  String get windowCloseTooltip => 'Mbyll';
  @override
  String get tabFiles => 'Skedarët';
  @override
  String get tabSearch => 'Kërko';
  @override
  String get tabSettings => 'Vendosjet';
  @override
  String get quickNoteTitle => 'Shënim i shpejtë';
  @override
  String get treeEmpty => "Ende s'ka shënime";
  @override
  String get selectANote => 'Zgjidh një shënim';
  @override
  String get showListTooltip => 'Shfaq listën';
  @override
  String get editRawTooltip => 'Ndrysho e thjeshtë';
  @override
  String get sortAscTooltip => 'Rendit A-Z';
  @override
  String get sortDescTooltip => 'Rendit Z-A';
  @override
  String get newNoteTitle => 'Shënim i ri';
  @override
  String get newItemTooltip => 'I ri';
  @override
  String get closeMenuTooltip => 'Mbyll';
  @override
  String get newFolderTitle => 'Tresë e re';
  @override
  String get newNoteSameFolder => 'Shënim i ri në të njëjtën dosje';
  @override
  String get newFromTemplateSameFolder =>
      'I ri nga shablloni në të njëjtën dosje';
  @override
  String trashOriginalPath(String path) => 'ishte në $path';
  @override
  String get trashOriginalRoot =>
      'ishte n\u00eb rr\u00ebnj\u00ebn e bibliotek\u00ebs';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 element' : '$count element\u00eb';
  @override
  String get newNoteHere => 'Shënim i ri këtu';
  @override
  String get newFolderHere => 'Tresë e re këtu';
  @override
  String get newListNoteTitle => 'Shënim-listë i ri';
  @override
  String get newListNoteDefault => 'Lista ime';
  @override
  String get setAsQuickNote => 'Vendos si shënim i shpejtë';
  @override
  String get currentQuickNote => 'Shënim i shpejtë aktual';
  @override
  String get pinnedSection => 'Të ngjitur';
  @override
  String pinnedSectionCount(int count) => 'Të ngjitur · $count';
  @override
  String get templateFolderTitle => 'Tresë e shablloneve';
  @override
  String get newFromTemplateTitle => 'E re nga shabllon';
  @override
  String get newFromTemplateHere => 'E re nga shabllon këtu';
  @override
  String get templateFormTitle => 'Plotëso shabllonin';
  @override
  String get templateFormBacklink => 'Lidhur nga';
  @override
  String get templateFormNoNote => 'Pa shënim';
  @override
  String get templateFormPickNote => 'Zgjidh një shënim';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Vendëzëvendësuesit në shabllon';
  @override
  String get templateHelpSubtitle =>
      'Data, titulli dhe vlerat e tjera për të plotësuar';
  @override
  String get quickNoteSubtitle => 'Shënimi që hap skeda Shënim i shpejtë';
  @override
  String get listFolderSubtitle => 'Listat e reja të detyrave';
  @override
  String get templateFolderSubtitle => 'Burimi i „E re nga shablloni“';
  @override
  String get attachmentsFolderSubtitle =>
      'Imazhe dhe audio të futura në një shënim';
  @override
  String get templateHelpIntro =>
      'Një shabllon është një shënim i thjeshtë me boshnira. Krijimi i '
      'një shënimi nga ai kopjon tekstin e tij dhe i plotëson '
      'boshnirat.';
  @override
  String get templateHelpUnknown =>
      "Një vendëzëvendësues që Niman s'e njeh mbetet saktësisht siç "
      'është i shkruar, pra gabimi në shkrim shihet në shënim në '
      "vend që t'i thyej rreshtin.";
  @override
  String get templateHelpValuesTitle => 'Vlerat';
  @override
  String get templateHelpTitleBody => 'Emri nën të cilin krijohet shënimi.';
  @override
  String get templateHelpDateBody =>
      'Sot, dhe koha aktuale. Të dyja marrin format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data dhe koha së bashku.';
  @override
  String get templateHelpUuidBody =>
      'Një identifikues i ri, i ndryshëm në çdo shfaqje.';
  @override
  String get templateHelpCounterBody =>
      'Numër që rritet sipas emrit, i ruajtur përmes rifillimeve: '
      'shënimi i parë shkruan 1, tjetri 2. E njëjta emër në një '
      'shënim shkruan të njëjtin numër; kombinoni me |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Vendos kursirin këtu kur krijohet shënimi; shenjveti vetë '
      "s'shkruhet. Shenja e parë fiton, pa filtra, vetëm shënime të "
      'reja — dhe tastatura hapet edhe kur autofokusimi është i fikur.';
  @override
  String get templateHelpDatesTitle => 'Shkrimi i datave';
  @override
  String get templateHelpDatesBody =>
      'Këto përfaqësojnë pjesët e datës në format. Gjithçka tjetër '
      'është siç është, dhe teksti në thjesht vetëmbetjet është '
      'gjithashtu siç është. Emrat e muajve dhe ditëve ndjekin '
      'gjuhën e aplikacionit.';
  @override
  String get templateHelpYear => 'viti: 2026, 26';
  @override
  String get templateHelpMonth => 'muaji: 03, 3, Mars, Mar';
  @override
  String get templateHelpDay => 'dita: 09, 9, E hënë, Hën';
  @override
  String get templateHelpTime => 'orët, minutat, sekundat';
  @override
  String get templateHelpWeek => 'Java ISO dhe tregu: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtrat';
  @override
  String get templateHelpFiltersBody =>
      "Vlerës mund t'i ndjekin filtrat, të zbatuar nga e majta te e "
      'djathta.';
  @override
  String get templateHelpCaseBody =>
      'Me të madhe, me të vogël dhe letra e parë e çdo fjalë — fjalët '
      'që i shkruani vetë me të madhe mbeten të pandryshuara.';
  @override
  String get templateHelpSlugBody =>
      'Formati i tekstit për lidhjet, për ndërtimin e wikilink.';
  @override
  String get templateHelpPadBody =>
      'Pranon fundin; plotëson me zero deri te gjerësia; përdor '
      'rezervë kur vlera është bosh.';
  @override
  String get templateHelpShiftBody =>
      'Lëviz datën për ditë, javë, muaj ose vjet — ligjërata e javës '
      'tjetër, skedari i muajit të kaluar.';
  @override
  String get templateHelpSnapBody =>
      'E ngjyt datën në fillimin ose fundin e javës, muajit ose '
      'vitit të saj.';
  @override
  String get templateHelpAskTitle => "Diçka t'ju pyet";
  @override
  String get templateHelpAskBody =>
      'Një formë shfaqet para se shënimi të krijojë, një fushë për '
      'pyetje — dhe një për lidhje prapa, kur shablloni dëshiron një. '
      'E njëjta etiketë dy herë është një pyetje, dhe përgjigjja e '
      'plotëson të gjitha shfaqjet — tresë dhe emri i skedarit '
      'përfshirë.';
  @override
  String get templateHelpAskFieldBody =>
      'Fushë për shkrim; teksti pas dy dyshpulesh të tjetër është ajo '
      'me të cilën fillon.';
  @override
  String get templateHelpChoiceBody =>
      'Zgjedhje nga një listë, e ndarë me presje.';
  @override
  String get templateHelpWhereTitle => 'Ku shkon shënimi';
  @override
  String get templateHelpWhereBody =>
      "Kjo s'është tekst: janë udhëzime, dhe jetojnë në bllokun "
      'niman: në vetë frontmatter-in e shabllonit. Blloku respektohet '
      "dhe pastaj heqet, pra kurrë s'shfaqet në shënim. Vlerat e tyre "
      'mund të përmbajnë vendëzëvendësues.';
  @override
  String get templateHelpFolderBody =>
      "Tresë në të cilën krijohet shënimi, e krijuar nëse s'ekziston. "
      'Pa të, shënimi shkon aty ku ishit.';
  @override
  String get templateHelpFilenameBody =>
      "Si quhet shënimi. Shabllonit që e thotë atë s'i pyet për emër.";
  @override
  String get templateHelpAppendBody =>
      'Shto te shënimi nëse ai tashmë ekziston, në vend që të krijojë '
      'një tjetër. Kjo e bën një muaj takimesh një skedar.';
  @override
  String get templateHelpOpenBody =>
      'Çfarë ndodh pasi shënimi ekziston: redaktori (standard), '
      'parapamja ose asgjë — shënimi nënshkruhet dhe ju mbeni aty ku '
      'ishit.';
  @override
  String get templateHelpAroundTitle => 'Nga vjen';
  @override
  String get templateHelpParentBody =>
      'Shënimin që e zgjidhni në formë, e cila propozon atë në ekran; '
      'shkruani [[{{parent}}]] për lidhje prapa te ai.';
  @override
  String get templateHelpFolderValueBody => 'Tresë ku përfundon shënimi.';
  @override
  String get templateHelpClipboardBody =>
      'Çfarë është në clipboard, dhe përzgjedhja e redaktorit kur '
      'shënimi fillon nga ajo.';
  @override
  String get templateHelpIncludeTitle => 'Përdorim i përsëritur i një pjese';
  @override
  String get templateHelpIncludeBody =>
      'E vendos një shabllon tjetër, kështu që dhjetë shabllone mund '
      'të përdorin të njëjtin checklist. Kërkon fillimisht në tresën '
      'e shablloneve, dhe .md mund të lihet. Pyetjet e tij i bashkohen '
      'të njëjtës formë.';
  @override
  String get templateHelpExampleTitle => 'Gjithçka së bashku';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ s\'ka shabllon „$path"';
  @override
  String includeCycle(String path) => '⚠ „$path" përfshin vetëveten';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path" është i vendosur tepër thellë';
  @override
  String frontmatterInvalid(String reason) => "Frontmatter s'lexohet: $reason";
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter i „$template" s\'lexohet, pra tresë dhe emri i '
      "skedarit të tij s'bënën asgjë: $reason";
  @override
  String get templatePickerTitle => 'Zgjidh shabllon';
  @override
  String templatePickerEmpty(String folder) =>
      "Ende s'ka shabllone. Vendi një shënim në $folder/ dhe do të "
      'bëhet një.';

  // Tree actions.
  @override
  String get actionPin => 'Ngjit';
  @override
  String get actionUnpin => 'Hiq ngjitjen';
  @override
  String get pinToWidget => 'Ngjit në widget-in e ekranit kryesor';
  @override
  String get pinnedForWidget =>
      'U ngjite: tani vendos widget-in Shënim në ekranin kryesor';
  @override
  String get pinWidgetUnavailable =>
      'Widget-et e ekranit kryesor janë të disponueshme në Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Shfaq në menaxherin e skedarëve';
  @override
  String get openInDefaultApp => 'Hap me aplikacionin e parazgjedhur';
  @override
  String get newNoteTabTooltip => 'Shënim i ri në skedë të re';
  @override
  String get openNotesTooltip => 'Shënime të hapura';
  @override
  String get closeTabTooltip => 'Mbyll';
  @override
  String get openInNewTab => 'Hape në skedë të re';
  @override
  String get splitRight => 'Ndaje djathtas';
  @override
  String get splitDown => 'Ndaje poshtë';
  @override
  String get moveToOtherPane => 'Zhvendose te paneli tjetër';
  @override
  String get openBeside => 'Hape anash';
  @override
  String get closeAllNotes => 'Mbyll të gjitha';
  @override
  String get sidePanelTooltip => 'Shfaq ose fshih panelin anësor';
  @override
  String get historyAllVersions => 'Të gjitha versionet';
  @override
  String get commandPaletteTitle => 'Paleta e komandave';
  @override
  String get goToNoteTitle => 'Shko te shënimi';
  @override
  String get paletteGroupNote => 'Shënim';
  @override
  String get paletteGroupEditor => 'Redaktori';
  @override
  String get paletteGroupView => 'Pamja';
  @override
  String get paletteGroupLibrary => 'Biblioteka';
  @override
  String get paletteGroupGoTo => 'Shko te';
  @override
  String get paletteHint => 'Kërko komanda dhe shënime';
  @override
  String get paletteNoResults => 'Asnjë përputhje';
  @override
  String get paletteCommands => 'Komandat';
  @override
  String get paletteNotes => 'Shënimet';
  @override
  String get paletteFooter =>
      '↑↓ për të lëvizur · ↵ për të përdorur · esc për ta mbyllur';
  @override
  String get zenMode => 'Mënyra zen';
  @override
  String get zenModeEnter => 'Hyr në mënyrën zen';
  @override
  String get zenModeLeave => 'Dil nga mënyra zen';
  @override
  String get keySpace => 'Hapësirë';
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
  String get keyArrowUp => 'Lart';
  @override
  String get keyArrowDown => 'Poshtë';
  @override
  String get keyArrowLeft => 'Majtas';
  @override
  String get keyArrowRight => 'Djathtas';
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
  String get shortcutNone => 'Pa shkurtore';
  @override
  String get shortcutRestoreDefaults => 'Rikthe parazgjedhjet';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Të kthehen të gjitha shkurtoret siç i sjell Niman?';
  @override
  String get shortcutRevert => 'Kthehu te parazgjedhja';
  @override
  String get shortcutClear => 'Hiq shkurtoren';
  @override
  String get shortcutCapturePrompt =>
      'Shtyp tastet. Edhe Esc e Tab regjistrohen: dil me Anulo.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Shto Ctrl, Alt ose Meta: një tast i vetëm është për të shkruar.';
  @override
  String get shortcutMove => 'Zhvendose';
  @override
  String get shortcutUseAnyway => 'Përdore gjithsesi';
  @override
  String get shortcutUndo => 'Zhbëj';
  @override
  String get shortcutRedo => 'Ribëj';
  @override
  String get shortcutChange => 'Ndrysho shkurtoren';
  @override
  String shortcutCaptureTitle(String command) => 'Tastet për $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys i përket tashmë $other. Ta zhvendos këtu? $other do të mbetet '
      'pa shkurtore.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys është edhe $what në fushat e tekstit dhe në redaktor. Atje do '
      'ta marrë komanda jote.';
  @override
  String get openFileMissing => 'Skedari i këtij shënimi nuk ndodhet në disk';
  @override
  String get openFileFailed => 'Ky shënim nuk u hap dot jashtë Niman';

  @override
  String get movedToTrash => 'U zhvendos në kosh';
  @override
  String get deletedMessage => 'U fshi';
  @override
  String deleteToTrashConfirm(String name) => '$name do të lëvizet te .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name do të fshihet përfundimisht';
  @override
  String get chooseDestination => 'Zgjidh destinacionin';
  @override
  String get libraryRoot => 'Rrënjja e bibliotekës';
  @override
  String moveTitle(String name) => 'Lëviz $name';
  @override
  String headingLevelLabel(int level) => 'Niveli i titullit $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      "Ende s'ka shënim të shpejtë. Zgjidhni një shënim të "
      'qëndrueshëm ose krijoni një të ri — shënimi i shpejtë hapet '
      'këtu.';
  @override
  String get quickNoteChooseAction => 'Zgjidh shënim…';
  @override
  String get quickNoteCreateAction => 'Krijo një shënim të ri…';
  @override
  String get quickNoteNewTitle => 'Shënim i shpejtë i ri';
  @override
  String get quickNotePickerTitle => 'Zgjidh shënim të shpejtë';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Tresë e re';
  @override
  String get folderPickerEmpty => "Ende s'ka tresë";
  @override
  String get listFolderTitle => 'Tresë e listës';
  @override
  String get attachmentsFolderTitle => 'Tresë e bashkëngjitjeve';

  // Trash (M1).
  @override
  String get trashEmpty => 'Koshi është bosh';
  @override
  String get trashEmptyAction => 'Boshatis koshin';
  @override
  String get trashEmptyConfirm =>
      'Kjo i fshin përfundimisht të gjitha gjërat në kosh, '
      "përfshirë objekte që Niman s'i vendosi aty.";
  @override
  String trashDeleteConfirm(String name) =>
      '$name do të fshihet përfundimisht (pa kthim)';
  @override
  String get trashDeletePermanently => 'Fshi përfundimisht';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Hapni një tresë me shënime Markdown si bibliotekë juaj';
  @override
  String get openLibraryExisting => 'Hap ekzistues';
  @override
  String get openLibraryCreate => 'Krijo të re';
  @override
  String get openLibraryCreateTitle => 'Krijo bibliotekë të re';
  @override
  String get openLibraryFolderName => 'Emri i tresës';
  @override
  String get openLibraryChooseFolder => 'Zgjidh tresën e bibliotekës';
  @override
  String get openLibraryChooseParent =>
      'Zgjidh tresën në të cilën do të krijohet biblioteka';
  @override
  String get openLibraryUnsupported =>
      "Kjo tresë s'është e mbështetur. Zgjidhni një tresë në ruajtjen "
      'e redaktorit.';
  @override
  String indexingCount(int done, int total) => '$done prej $total shënimesh';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Bibliotekat tuaja';
  @override
  String get libraryUnreachable => 'E papërmbajshme';
  @override
  String get libraryOpenedToday => 'Hapur sot';
  @override
  String get libraryOpenedYesterday => 'Hapur dje';
  @override
  String libraryOpenedDaysAgo(int days) => 'Hapur $days ditë më parë';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Hapur më ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Hap tani';
  @override
  String get switchLibraryTitle => 'Ndrysho bibliotekë';
  @override
  String get libraryForget => 'Harro';
  @override
  String libraryForgetTitle(String name) => 'Harron „$name"?';
  @override
  String get libraryForgetExplained =>
      'Ajo del nga ky listë. Tresë, shënimet dhe vendosjet e '
      'bibliotekës në të mbeten të pandryshuara, dhe hapja përsëri e '
      'kthen në vend.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Lejo qasjen te skedarët';
  @override
  String get storageAccessNeeded =>
      "Niman s'mund t'i lexojë shënimet tuaja pa „qasje te të "
      'gjitha skedarët". Lejoje për të hapur një bibliotekë.';
  @override
  String get storageAccessExplained =>
      'Niman i lexon shënimet tuaja si skedarë të thjeshtë, pra '
      "Android duhet t'i lejojë qasjen te të gjitha skedarët. Asgjë "
      "s'u ngjit, dhe lexohet vetëm tresë e bibliotekës që e "
      'zgjidhni.';
  @override
  String folderAccessDenied(Object error) =>
      "Sistemi s'i dha qasje tresës: $error";
  @override
  String folderPickFailed(Object error) => "S'u zgjedh tresë: $error";

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Vendosjet';
  @override
  String get libraryPathTitle => 'Rruga e bibliotekës';
  @override
  String get reindexTitle => 'Rindekso tani';
  @override
  String get reindexDone => 'U rindeksua';
  @override
  String get closeLibraryTitle => 'Mbyll bibliotekën';
  @override
  String get exportLogTitle => 'Eksporto ditëzatin e diagnostikimit';
  @override
  String get exportLogSubtitle =>
      'Ruaj ngjarjet e regjistruara në një skedar që e zgjidhni';
  @override
  String get exportLogEmpty =>
      'Bufëri i ditëzativ të diagnostikimit është bosh';
  @override
  String get quickNoteUnset => "Ende s'është vendosur";
  @override
  String exportLogDone(Object target) => 'Ditëzati u eksportua te $target';
  @override
  String exportLogFailed(Object error) => "Eksporti s'u realizua: $error";

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'S\'u gjet përputhje e plotë e fjalës „$term"';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'U zëvendësuan $occurrences shfaqje të „$term" në $notes shënime';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped shënime të hapura u anashëvu)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'S\'ka përputhje të plotë të fjalës „$term"'
      '${only == null ? "s'u gjet" : 'u gjet në $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Rreth';
  @override
  String get versionTitle => 'Versioni';
  @override
  String get changelogTitle => 'Regjistri i ndryshimeve';
  @override
  String get changelogEmpty => 'Nuk ka hyrje të regjistrit të disponueshme';
  @override
  String changelogWhatsNew(String version) => 'E re në versionin $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historiku';
  @override
  String get noteMenuTooltip => 'Veprimet e shënimit';
  @override
  String get historyCurrentVersion => 'Versioni aktual';
  @override
  String get historyCurrentSubtitle => 'Shënimi siç është tani';
  @override
  String get historyToday => 'Sot';
  @override
  String get historyYesterday => 'Dje';
  @override
  String get historyReasonSession => 'para ndryshimit';
  @override
  String get historyReasonInterval => 'gjatë ndryshimit';
  @override
  String get historyReasonRestore => 'para rikthimit';
  @override
  String get historyReasonSync => 'para sinkronizimit';
  @override
  String get historyReasonReplace => 'para zëvendësimit';
  @override
  String get historyReasonUnknown => 'i rikuperuar';
  @override
  String get historySyncBase => 'baza e sinkronizimit';
  @override
  String get historyEmpty =>
      'Ende nuk ka versione. Niman ruan një kur filloni të ndryshoni '
      'shënimin, pastaj më së shumti një në pak minuta ndërsa shkruani.';
  @override
  String historyKept(int kept, int limit) =>
      '$kept nga $limit versione të ruajtura';
  @override
  String get historyBaseKept =>
      'Baza e sinkronizimit ruhet edhe përtej kufirit.';
  @override
  String get historyOff =>
      'Historiku është i çaktivizuar për këtë bibliotekë '
      '(Vendosjet, Biblioteka).';
  @override
  String get historyLoadFailed => 'Historiku nuk u lexua';
  @override
  String get historyCompareSubtitle => 'Krahasuar me versionin aktual';
  @override
  String get historyTabChanges => 'Ndryshimet';
  @override
  String get historyTabVersion => 'Versioni';
  @override
  String get historyNoChanges => 'I njëjti tekst si versioni aktual.';
  @override
  String get historyRestoreAction => 'Rikthe këtë version';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Të rikthehet versioni ($when)?';
  @override
  String get historyRestoreConfirmBody =>
      'Teksti aktual ruhet më parë në historik, kështu që mund të ktheheni '
      'gjithmonë pas.';
  @override
  String get historyRestoreConfirm => 'Rikthe';
  @override
  String historyRestored(String when) => 'Versioni ($when) u rikthye';
  @override
  String get historyRestoreFailed => 'Versioni nuk u rikthye';
  @override
  String get actionUndo => 'Zhbëj';
  @override
  String diffLineRange(int start, int end) => 'Rreshtat $start–$end';
  @override
  String diffLineSingle(int line) => 'Rreshti $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 rresht i pandryshuar' : '$count rreshta të pandryshuar';
  @override
  String get historyTakeHunk => 'Rikthe këtu';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Rikthe 1 ndryshim' : 'Rikthe $count ndryshime';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Ndryshimet e zgjedhura kthehen te teksti i këtij versioni. Shënimi '
      'ashtu siç është tani ruhet më parë si version, kështu që mund ta '
      'zhbësh.';
  @override
  String get historyNoteChangedReloaded =>
      'Shënimi ndryshoi ndërsa ishe këtu — krahasimi u rifreskua.';
  @override
  String get historyVersionsTitle => 'Versionet që ruhen';
  @override
  String get historyVersionsSubtitle => 'Për çdo shënim, në .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Asnjë' : '$count';
  @override
  String get historyIntervalTitle => 'Version i ri më së shumti çdo';
  @override
  String get historyIntervalSubtitle =>
      'Ndërsa shkruani; fillimi i ndryshimit të një shënimi ruan gjithmonë '
      'një';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkriptimi';
  @override
  String get transcriptionModelTitle => 'Modeli';
  @override
  String get transcriptionModelNone => 'Asnjë';
  @override
  String get transcriptionLanguageTitle => 'Gjuha';
  @override
  String get transcriptionLanguageSubtitle =>
      'Gjuha që flitet në regjistrimet tuaja. Ta tregoni është më e saktë se '
      'ta zbuloni automatikisht.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Si aplikacioni ($language)';
  @override
  String get transcriptionLanguageDetect => 'Zbuloje automatikisht';
  @override
  String get transcriptionModelsTitle => 'Modelet e transkriptimit';
  @override
  String transcriptionModelsUsed(String size) => '$size në përdorim';
  @override
  String get transcriptionModelsInstalled => 'Të shkarkuara';
  @override
  String get transcriptionModelsDownloading => 'Po shkarkohen';
  @override
  String get transcriptionModelsAvailable => 'Të disponueshme';
  @override
  String get transcriptionModelsFooter =>
      'Modelet mbeten në hapësirën e aplikacionit në këtë pajisje. Nuk '
      'kopjohen në bibliotekë dhe nuk sinkronizohen.';
  @override
  String get transcriptionModelDefault => 'Parazgjedhje';
  @override
  String get transcriptionModelSlow => 'I ngadaltë';
  @override
  String get transcriptionModelHintTiny => 'Më i shpejti, më pak i saktë';
  @override
  String get transcriptionModelHintBase =>
      'Ekuilibër i mirë mes shpejtësisë dhe saktësisë';
  @override
  String get transcriptionModelHintSmall =>
      'Më i saktë, rreth 3× më i ngadaltë';
  @override
  String get transcriptionModelHintMedium =>
      'Shumë i saktë, i ngadaltë në telefon';
  @override
  String get transcriptionModelHintLarge => 'Më i sakti, kërkon shumë memorie';
  @override
  String get transcriptionModelDownload => 'Shkarko';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Të fshihet modeli $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Lirohen $size. Modelin mund ta shkarkoni sërish më vonë.';
  @override
  String get transcriptionModelFailed =>
      'Shkarkimi dështoi. Kontrolloni lidhjen dhe provoni sërish.';
  @override
  String get actionRetry => 'Provo sërish';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Lidhja u ndërpre, po provohet sërish…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Në pauzë te $progress';
  @override
  String get actionResume => 'Vazhdo';
  @override
  String get audioTranscribe => 'Transkripto';
  @override
  String get audioTranscribeUnsupported =>
      'Vetëm regjistrime WAV në këtë pajisje';
  @override
  String get transcriptionQueued => 'Në radhë';
  @override
  String get transcriptionPreparing => 'Po përgatitet audioja…';
  @override
  String transcriptionRunning(int percent) => 'Po transkriptohet… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Po shkarkohet $model · $percent%';
  @override
  String get transcriptionSaved => 'Transkriptimi u shtua te përshkrimi';
  @override
  String get transcriptionNoSpeech => 'Nuk u njoh e folur në këtë regjistrim';
  @override
  String get transcriptionFailed => 'Transkriptimi dështoi';
  @override
  String get transcriptionPickModelTitle => 'Zgjidhni një model';
  @override
  String get transcriptionPickModelBody =>
      'Transkriptimi bëhet në këtë pajisje dhe regjistrimi nuk dërgohet '
      'kurrë. Modeli shkarkohet vetëm një herë.';
  @override
  String get transcriptionPickModelAction => 'Shkarko dhe transkripto';
  @override
  String get transcriptionModelRecommended => 'I rekomanduar';
  @override
  String get transcriptionExistingTitle =>
      'Ky regjistrim ka tashmë një përshkrim';
  @override
  String get transcriptionExistingBody =>
      'Ta zëvendësoni me transkriptimin apo ta shtoni transkriptimin poshtë?';
  @override
  String get transcriptionAppend => 'Shto poshtë';
  @override
  String get transcriptionReplace => 'Zëvendëso';
  @override
  String get settingsSectionSync => 'Sinkronizimi';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Nuk është konfiguruar për këtë bibliotekë';
  @override
  String get syncNeverSynced => 'Ende e pasinkronizuar';
  @override
  String syncLastSynced(String when) => 'Sinkronizuar $when';
  @override
  String get syncRunning => 'Po sinkronizohet…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteka $library';
  @override
  String get syncUrlLabel => 'Adresa e tresës';
  @override
  String get syncUrlRequired => 'Jep adresën e serverit';
  @override
  String get syncUrlHint =>
      'Tresa duhet të ekzistojë. Kopjojeni adresën ashtu siç e '
      'shfaq serveri.';
  @override
  String get syncHttpWarning =>
      'Lidhje e pakriptuar: në rregull përmes një VPN ose në '
      'rrjetin lokal.';
  @override
  String get syncUserLabel => 'Përdoruesi';
  @override
  String get syncUserHint => 'Lëreni bosh nëse serveri nuk kërkon kredenciale.';
  @override
  String get syncPasswordLabel => 'Fjalëkalimi';
  @override
  String get syncPasswordHint =>
      'Ruhet në zinxhirin e çelësave të kësaj pajisjeje, kurrë '
      'në skedarët e bibliotekës.';
  @override
  String get syncPasswordKeepHint =>
      'Lëreni bosh për të mbajtur fjalëkalimin e ruajtur.';
  @override
  String get syncShowPassword => 'Shfaq fjalëkalimin';
  @override
  String get syncHidePassword => 'Fshih fjalëkalimin';
  @override
  String get syncTestAction => 'Testo lidhjen';
  @override
  String get syncTesting => 'Po testohet…';
  @override
  String get syncRetargetWarning =>
      'Me një adresë ose përdorues të ri, sinkronizimi i '
      'ardhshëm nis nga e para si sinkronizim i parë.';
  @override
  String get syncTestOk => 'Lidhja funksionon';
  @override
  String get syncModeFull => 'Modaliteti i plotë';
  @override
  String get syncModeCompatible => 'Modaliteti i përputhshëm';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lexim, shkrim dhe fshirje';
  @override
  String get syncCapEtags => 'Gjurmët e skedarëve (ETag)';
  @override
  String get syncCapNoEtags => 'Pa gjurmë skedarësh (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Krahason madhësinë dhe datën; në rast dyshimi shkarkon '
      'përsëri';
  @override
  String get syncCapGuarded => 'Shkrime të mbrojtura';
  @override
  String get syncCapUnguarded => 'Shkrime të pambrojtura';
  @override
  String get syncCapUnguardedDetail =>
      'Kontrollon skedarin në server pak para shkrimit';
  @override
  String get syncCapMove => 'Riemërton pa ngarkuar përsëri';
  @override
  String get syncCapNoMove => 'Pa riemërtime në server';
  @override
  String get syncCapNoMoveDetail =>
      'Një riemërtim bëhet fshirje dhe ngarkim i ri';
  @override
  String get syncCompatibleNote =>
      'Në modalitetin e përputhshëm sinkronizimi funksionon '
      'njësoj, me pak më shumë kërkesa.';
  @override
  String get syncTestInvalidUrl => 'Adresë e pavlefshme';
  @override
  String get syncTestInvalidUrlHint =>
      'Shkruani një adresë http:// ose https://, pa përdorues '
      'apo fjalëkalim brenda saj.';
  @override
  String get syncTestOffline => 'Serveri nuk arrihet';
  @override
  String get syncTestOfflineHint =>
      'A është aktiv VPN? Një adresë 10.x ose 192.168.x '
      'funksionon vetëm nga i njëjti rrjet.';
  @override
  String get syncTestAuth => 'Përdoruesi ose fjalëkalimi u refuzua';
  @override
  String get syncTestAuthHint => 'Kontrollojini dhe testoni përsëri.';
  @override
  String get syncTestNotFound => 'Tresa nuk ekziston';
  @override
  String get syncTestNotFoundHint =>
      'Krijojeni në server ose korrigjoni adresën.';
  @override
  String get syncTestUnsupported => 'Nuk është tresë WebDAV';
  @override
  String get syncTestUnsupportedHint => 'Serveri përgjigjet, por jo si WebDAV.';
  @override
  String get syncTestFailed => 'Testi nuk funksionoi';
  @override
  String get syncNowAction => 'Sinkronizo tani';
  @override
  String get syncSectionServer => 'Serveri';
  @override
  String get syncServerRow => 'Adresa, përdoruesi dhe fjalëkalimi';
  @override
  String get syncRetestTitle => 'Testo përsëri serverin';
  @override
  String syncProbedAgo(String when) => 'Testi i fundit $when';
  @override
  String get syncDisconnectTitle => 'Shkëput këtë bibliotekë';
  @override
  String get syncDisconnectSubtitle => 'Skedarët mbeten këtu dhe në server';
  @override
  String get syncDisconnectConfirmTitle => 'Të shkëputet sinkronizimi?';
  @override
  String get syncDisconnectConfirmBody =>
      'Kjo bibliotekë nuk sinkronizohet më në këtë pajisje. '
      'Asnjë skedar nuk fshihet, as këtu as në server. Nëse e '
      'lidhni përsëri, sinkronizimi i parë nis nga e para.';
  @override
  String get syncDisconnectConfirm => 'Shkëput';
  @override
  String get syncFirstTitle => 'Sinkronizimi i parë';
  @override
  String get syncFirstIntro => 'Krahasova bibliotekën me tresën në server:';
  @override
  String get syncFirstUpload => "Për t'u ngarkuar";
  @override
  String get syncFirstDownload => "Për t'u shkarkuar";
  @override
  String get syncFirstBoth => 'Në të dyja anët';
  @override
  String get syncFirstBothHint =>
      "Të njëjtë: pa transferim. Të ndryshëm: për t'u zgjidhur";
  @override
  String get syncFirstNoDelete =>
      'Sinkronizimi i parë nuk fshin asgjë, as këtu as në server.';
  @override
  String get syncStartAction => 'Nis';
  @override
  String syncMassTrashTitle(int count) => count == 1
      ? 'Të zhvendoset 1 skedar në kosh?'
      : 'Të zhvendosen $count skedarë në kosh?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Në server mungojnë $count nga $total skedarët e '
      'sinkronizuar. Zakonisht kjo do të thotë adresë e gabuar, '
      'disk NAS i pamontuar ose tresë e zbrazur gabimisht.';
  @override
  String get syncMassTrashHint =>
      'Nëse vërtet i fshitë në një pajisje tjetër, konfirmoni: '
      'këtu shkojnë në kosh.';
  @override
  String get syncMassTrashConfirm => 'Zhvendos në kosh';
  @override
  String syncMassDeleteTitle(int count) => count == 1
      ? 'Të fshihet 1 skedar nga serveri?'
      : 'Të fshihen $count skedarë nga serveri?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Këtu mungojnë $count nga $total skedarët e sinkronizuar. '
      'Nëse nuk i fshitë ju, anuloni dhe kontrolloni tresën e '
      'bibliotekës.';
  @override
  String get syncMassDeleteConfirm => 'Fshi nga serveri';
  @override
  String get syncTooltip => 'Sinkronizo';
  @override
  String get syncStageConnecting => 'Po lidhet me serverin…';
  @override
  String get syncStageComparing => 'Po krahasohet me serverin…';
  @override
  String syncStageApplying(int done, int total) =>
      'Po sinkronizohet · $done nga $total';
  @override
  String get syncStatusWarnings => 'Sinkronizuar me paralajmërime';
  @override
  String syncConflictsHeader(int count) =>
      'Ndryshuar këtu dhe në server · $count';
  @override
  String get syncConflictHint => 'Asnjë version nuk u prek';
  @override
  String get syncResolveAction => 'Zgjidh';
  @override
  String syncFailuresHeader(int count) => 'Të pasinkronizuar · $count';
  @override
  String get syncFailuresHint =>
      'Do të provohen përsëri në sinkronizimin e ardhshëm';
  @override
  String get syncAbortAuth => 'Serveri e refuzoi fjalëkalimin';
  @override
  String get syncAbortMissingPassword => 'Nuk ka fjalëkalim të ruajtur';
  @override
  String get syncAbortOffline => 'Serveri nuk arrihet';
  @override
  String get syncAbortRemoteMissing => 'Tresa në server nuk ekziston më';
  @override
  String get syncAbortUnsupported => 'Serveri nuk funksionon më si WebDAV';
  @override
  String get syncAbortFailed => 'Sinkronizimi nuk funksionoi';
  @override
  String get syncAbortNotConfirmed => 'Sinkronizimi u anulua';
  @override
  String get syncAbortNothingTouched =>
      'Asnjë skedar nuk u prek. Ndryshimet tuaja mbeten këtu '
      'deri në sinkronizimin e ardhshëm të suksesshëm.';
  @override
  String syncLastSuccess(String when) =>
      'Sinkronizimi i fundit i suksesshëm $when';
  @override
  String get syncNoSuccessYet => 'Ende asnjë sinkronizim i suksesshëm';
  @override
  String get syncUpdatePasswordAction => 'Përditëso fjalëkalimin';
  @override
  String get syncRetryAction => 'Provo përsëri';
  @override
  String get syncOpenSettingsAction => 'Vendosjet';
  @override
  String get syncCloseAction => 'Mbyll';
  @override
  String get syncDoneSnack => 'Sinkronizuar';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sinkronizuar · 1 skedar i fshirë diku tjetër është në kosh'
      : 'Sinkronizuar · $count skedarë të fshirë diku tjetër janë '
            'në kosh';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? "Sinkronizuar · 1 konflikt për t'u zgjidhur"
      : "Sinkronizuar · $count konflikte për t'u zgjidhur";
  @override
  String get syncShowAction => 'Shfaq';
  @override
  String get syncConflictTitle => 'Zgjidh konfliktin';
  @override
  String get syncConflictLegend =>
      'Rreshtat me − janë të serverit, rreshtat me + të kësaj '
      'pajisjeje.';
  @override
  String get syncConflictBinary =>
      'Nuk është skedar teksti: zgjidhni cilën kopje të mbani.';
  @override
  String get syncConflictKeepNote =>
      'Kopja që nuk mbani mbetet në historikun e shënimit.';
  @override
  String get syncKeepLocal => 'Mbaj versionin e kësaj pajisjeje';
  @override
  String get syncKeepRemote => 'Mbaj versionin e serverit';
  @override
  String get syncConflictIdentical => 'Dy versionet janë identike';
  @override
  String get syncConflictLoadFailed => 'Nuk u lexuan dot të dy versionet';
  @override
  String get syncResolveFailed => 'Konflikti nuk u zgjidh dot';
  @override
  String get syncResolved => 'Konflikti u zgjidh';
  @override
  String get syncSectionWhen => 'Kur të sinkronizohet';
  @override
  String get syncAutoTitle => 'Automatikisht';
  @override
  String get syncAutoSubtitle => 'Pas ndryshimeve, në hapje dhe në intervale';
  @override
  String get syncIntervalTitle => 'Kontrollo serverin çdo';
  @override
  String get syncIntervalSubtitle => 'Vetëm kur aplikacioni është i hapur';
  @override
  String get syncIntervalDialogBody =>
      'Për të parë ndryshimet e bëra në pajisje të tjera kur aplikacioni '
      'është i hapur. Me „Kurrë", vetëm pas ndryshimeve dhe në hapje.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minutë' : '$count minuta';
  @override
  String get syncIntervalNever => 'Kurrë';
  @override
  String get syncWifiOnlyTitle => 'Vetëm me Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Me të dhëna celulare, sinkronizoni vetëm me dorë';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 ndryshim në pritje' : '$count ndryshime në pritje';
  @override
  String syncRetryIn(String wait) => 'provë e re pas $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Në pritje të Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Në pritje të një lidhjeje';
  @override
  String get syncMobileDataHint =>
      '„Sinkronizo tani" përdor sidoqoftë të dhëna celulare.';
  @override
  String get syncQueueKeptHint =>
      'Ndryshimet mbeten këtu, edhe nëse e mbyllni aplikacionin, dhe nisen '
      'vetë kur serveri përgjigjet.';
  @override
  String get syncAutoPaused => 'Sinkronizimi automatik është në pauzë';
  @override
  String get syncPausedAuthHint =>
      'Rifillon kur përditësoni fjalëkalimin ose sinkronizoni me dorë.';
  @override
  String get syncPausedServerHint =>
      'Rifillon kur korrigjoni adresën ose sinkronizoni me dorë.';
  @override
  String get syncPausedConfirmHint =>
      '„Sinkronizo tani" tregon çfarë do të hiqej dhe pyet më parë.';
  @override
  String get syncNeedsConfirmation => 'Në pritje të konfirmimit tuaj';
  @override
  String get syncMergeIntro =>
      'Ndryshimet që nuk mbivendosen janë bashkuar tashmë; zgjidhni çfarë të '
      'mbani aty ku mbivendosen.';
  @override
  String get syncMergeClean =>
      'Dy versionet bashkohen vetë: asgjë nuk mbivendoset.';
  @override
  String get syncMergeNoBase =>
      'Nuk ka një version të përbashkët për t’u bashkuar, prandaj duhet '
      'zgjedhur i gjithë skedari.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Mbivendosja $index nga $total';
  @override
  String get syncMergeFromLocal => 'Nga kjo pajisje';
  @override
  String get syncMergeFromRemote => 'Nga serveri';
  @override
  String get syncMergeRemovedLines => 'Rreshta të hequr';
  @override
  String get syncMergeKeepLocal => 'Të miat';
  @override
  String get syncMergeKeepRemote => 'Të serverit';
  @override
  String get syncMergeKeepBoth => 'Të dyja';
  @override
  String get syncMergeSave => 'Ruaj bashkimin';
  @override
  String get syncMergeKeepWhole => 'Ose mbaj një kopje të plotë';
}
