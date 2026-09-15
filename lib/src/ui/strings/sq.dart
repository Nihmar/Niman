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
  String get trashTitle => 'Hundë';
  @override
  String get trashSubtitle =>
      'Elementët e fshirë shkojnë në .trash/ (jo aktiv = fshirje '
      'përfundimtare)';
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
  String get keyboardOnOpenTitle => 'Tastatura te hapja';
  @override
  String get keyboardOnOpenSubtitle =>
      'Tregon tastaturën sapo hapet shënima (jo aktiv = me prekje e parë)';
  @override
  String get editorKindSource => 'Burimi Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
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
  String get shortcutNewAudio => 'New voice note';
  @override
  String get shortcutToggleSidebar => 'Shfaq ose fsheh pemën e skedarëve';
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
  String get newFolderTitle => 'Tresë e re';
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
  @override
  String get movedToTrash => 'Lëvizur te hundë';
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
  String get attachmentsFolderTitle => 'Attachments folder';

  // Trash (M1).
  @override
  String get trashEmpty => 'Hundë është bosh';
  @override
  String get trashEmptyAction => 'Boshtëso hundën';
  @override
  String get trashEmptyConfirm =>
      'Kjo i fshin përfundimisht të gjitha gjërat në tresën e hundës, '
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
}
