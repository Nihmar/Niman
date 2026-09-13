// The Latvian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class LatvianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'janvāris',
    'februāris',
    'marts',
    'aprīlis',
    'maijs',
    'jūnijs',
    'jūlijs',
    'augusts',
    'septembris',
    'oktobris',
    'novembris',
    'decembris',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mar',
    'apr',
    'mai',
    'jūn',
    'jūl',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'pirmdiena',
    'otrdiena',
    'trešdiena',
    'ceturtdiena',
    'piektdiena',
    'sestdiena',
    'svētdiena',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'pr',
    'ot',
    'tr',
    'ct',
    'pk',
    'st',
    'sv',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Konteiners';
  @override
  String get trashSubtitle =>
      'Dzēstie elementi tiek pārvietoti uz .trash/ (izslēgts = neatgriezeniska '
      'dzēšana)';
  @override
  String get debugLogsTitle => 'Atkļūdošanas žurnāls';
  @override
  String get debugLogsSubtitle => 'Fiksē programmas notikumus atmiņas buferī';
  @override
  String get lineNumbersTitle => 'Rindu numuri';
  @override
  String get lineNumbersSubtitle =>
      'Rāda rindu numuru kolonnu piezīmju redaktorā';
  @override
  String get keyboardOnOpenTitle => 'Tastatūra atverot';
  @override
  String get keyboardOnOpenSubtitle =>
      'Rāda tastatūru piezīmes atverot (izslēgts = pie pirmās pieskāres)';
  @override
  String get editorKindSource => 'Markdown avots';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Priekšskatījums';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Rāda izveidoto piezīmi blakus avota redaktoram';
  @override
  String get switchToWysiwygTooltip => 'Pārslēgt uz WYSIWYG redaktoru';
  @override
  String get switchToSourceTooltip => 'Pārslēgt uz Markdown avotu';
  @override
  String get wysiwygTooLarge =>
      'Šī piezīme ir pārāk liela WYSIWYG redaktoram. Atveriet to kā Markdown '
      'avotu.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Izskats';
  @override
  String get settingsSectionEditor => 'Redaktors';
  @override
  String get settingsSectionLibrary => 'Bibliotēka';
  @override
  String get settingsSectionReminders => 'Atgādinājumi';
  @override
  String get settingsSectionShortcuts => 'Tastatūra';
  @override
  String get keyboardShortcutsTitle => 'Tastatūras saīsinājumi';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Orfogrāfiskā pārbaude';
  @override
  String get settingsSpellCheckSubtitle =>
      'Pasvītro ortogrāfiskās kļūdas rakstīšanas laikā.';
  @override
  String get spellCheckDictionaryTitle => 'Vārdnīca';
  @override
  String get spellCheckDictionarySystem => 'Sistēmas noklusējums';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Vārdnīcu izvēle';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Izvēlieties visas valodas, kādās ir uzrakstīta bibliotēka. Vārds '
      'ieiet, ja kāda no izvēlētajām vārdnīcām to atpazīst; bez izvēles '
      'izdodas sistēmas valoda.';
  @override
  String get spellCheckNoDictionaries =>
      'Šajā sistēmā vārdnīcas netika atrastas.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Orfogrāfiskā pārbaude';
  @override
  String get spellCheckTitle => 'Orfogrāfija';
  @override
  String get spellCheckEmpty => 'Nav ortogrāfisko kļūdu.';
  @override
  String get spellCheckUnavailable => 'hunspell nav instalēts šajā sistēmā.';
  @override
  String get spellCheckNoSuggestions => 'Nav ieteikumu';
  @override
  String spellCheckCount(int count) => '$count pārbaudei';
  @override
  String spellCheckLine(int line) => 'rinda $line';

  @override
  String indentWidthValue(int spaces) => '$spaces atstarpes';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Gaišums';
  @override
  String get themeBrightnessSubtitle => 'Gaiša, tumša vai ierīces iestatījums';
  @override
  String get themeBrightnessSystem => 'Sistēma';
  @override
  String get themeBrightnessDay => 'Gaiša';
  @override
  String get themeBrightnessNight => 'Tumša';
  @override
  String get themePaletteTitle => 'Krāsu palete';
  @override
  String get themePaletteSubtitle => 'Saskarnes un piezīmju krāsas';
  @override
  String get themePaletteSystem => 'Sistēma';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Saskarnes teksta izmērs';
  @override
  String get uiTextScaleSubtitle =>
      'Koks, cilnes un dialogi; virs sistēmas iestatījuma';
  @override
  String get noteTextScaleTitle => 'Piezīmju teksta izmērs';
  @override
  String get noteTextScaleSubtitle =>
      'Redaktors un priekšskatījums vienmēr ir saskaņā';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Priekšskatījuma režīms';
  @override
  String get previewModeSubtitle =>
      'Vai priekšskatījums dala ekrānu ar redaktoru vai to aizvieto';
  @override
  String get previewModeAuto => 'Blakus';
  @override
  String get previewModeSwitch => 'Pilnekrāns';
  @override
  String get splitRatioTitle => 'Dalījuma attiecība';
  @override
  String get splitRatioSubtitle =>
      'Redaktora daļa, kad priekšskatījums ir blakus';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Saites formāts';
  @override
  String get linkTypeSubtitle => 'Ko saites poga ieraksta redaktorā';
  @override
  String get linkTypeWikilink => 'Viki saite';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Ielādes platums';
  @override
  String get indentWidthSubtitle =>
      'Atstarpju skaits, kas tiek pievienots katram ielādes līmenim '
      'redaktorā';
  @override
  String get languageTitle => 'Valoda';
  @override
  String get languageSubtitle => 'Pašas programmas teksta valoda';
  @override
  String get languageSystem => 'Sistēma';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Pievienot elementu';
  @override
  String get listAddTooltip => 'Pievienot elementu';
  @override
  String get listEmpty => 'Vēl nav elementu';
  @override
  String get listDragHandleLabel => 'Mainīt elementa secību';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Ātrā piezīme';
  @override
  String get shortcutNewTodo => 'Jauns uzdevums';
  @override
  String get shortcutNewNote => 'Jauna piezīme';
  @override
  String get shortcutNewList => 'Jauns saraksts';
  @override
  String get shortcutToggleSidebar => 'Rādīt vai paslēpt filtru';
  @override
  String get shortcutEditorSection => 'Redaktorā';
  @override
  String get shortcutFind => 'Meklēt';
  @override
  String get shortcutReplace => 'Meklēt un aizstāt';
  @override
  String get shortcutSavingNote =>
      'Izmēnas tiek saglabātas automātiski, tāpēc saglabāšanas saīsinājuma '
      'nav.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Struktūra';
  @override
  String get outlineNoHeadings => 'Nav virsrakstu';
  @override
  String get outlineNoTitle => '(bez virsraksta)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Treļns';
  @override
  String get toolbarItalic => 'Slīps';
  @override
  String get toolbarStrikethrough => 'Nodzīsvilkt';
  @override
  String get toolbarSuperscript => 'Augšindekss';
  @override
  String get toolbarUnderline => 'Nospīdēt';
  @override
  String get toolbarLink => 'Saite';
  @override
  String get toolbarCode => 'Koda bloks';
  @override
  String get toolbarImage => 'Ievietot attēlu';
  @override
  String get toolbarHeading => 'Virsraksts';
  @override
  String get toolbarList => 'Saraksts';
  @override
  String get toolbarOrderedList => 'Numurēts saraksts';
  @override
  String get toolbarQuote => 'Citāts';
  @override
  String get toolbarIndent => 'Ielāde';
  @override
  String get toolbarOutdent => 'Atcelt ielādi';
  @override
  String get headingDialogTitle => 'Virsraksta līmenis';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Redaktora rīku josla';
  @override
  String get toolbarSettingsHint =>
      'Velciet, lai mainītu secību; acs rāda vai paslēpj pogu.';
  @override
  String get toolbarShowButton => 'Rādīt';
  @override
  String get toolbarHideButton => 'Paslēpt';
  @override
  String get toolbarResetOrder => 'Atjaunot noklusēto';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Rādīt priekšskatījumu';
  @override
  String get showEditorTooltip => 'Rādīt redaktoru';
  @override
  String get enterFullScreenTooltip => 'Pilnekrāns';
  @override
  String get exitFullScreenTooltip => 'Iziet no pilnekrāna';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(neapstrādāta HTML tabula)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Meklēt piezīmēs';
  @override
  String get searchModeWords => 'Vārdi';
  @override
  String get searchModeContains => 'Satur';
  @override
  String get searchEmptyHint =>
      'Rakstiet, lai meklētu bibliotēkā, vai atslēga = vērtība, lai '
      'filtrētu pēc frontmattera';
  @override
  String get searchTooShortHint => 'Rakstiet vismaz 2 rakstzīmes';
  @override
  String get searchNoMatches => 'Nav rezultātu';
  @override
  String get searchLoadMore => 'Rādīt vairāk';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Aizstāt…';
  @override
  String get replaceInNoteAction => 'Aizstāt šajā piezīmē…';
  @override
  String get replaceInThisNote => 'Aizstāt šajā piezīmē';
  @override
  String get replaceWithLabel => 'Aizstāt ar';
  @override
  String get replaceCaseSensitive => 'Atšķirt lielos un mazos burtus';
  @override
  String get replaceWholeWordsHint =>
      'aizstājami tikai precīzi visu vārdu sakritījumi';
  @override
  String get replaceConfirm => 'Aizstāt';
  @override
  String get replaceCancel => 'Aizvērt';
  @override
  String get replaceUnavailable => 'Aizstāšana pašlaik nav pieejama';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Meklēt piezīmē';
  @override
  String get editorFindHint => 'Meklēt';
  @override
  String get editorReplaceHint => 'Aizstāt';
  @override
  String get editorFindCaseTooltip => 'Atšķirt lielos un mazos burtus';
  @override
  String get editorFindPreviousTooltip => 'Iepriekšējais rezultāts';
  @override
  String get editorFindNextTooltip => 'Nākamais rezultāts';
  @override
  String get editorFindCloseTooltip => 'Aizvērt meklēšanu';
  @override
  String get editorFindReplaceModeTooltip => 'Aizstāšanas režīms';
  @override
  String get editorReplaceOneTooltip => 'Aizstāt šo rezultātu';
  @override
  String get editorReplaceAllTooltip => 'Aizstāt visus rezultātus';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Cilpes';
  @override
  String get tagsTitle => 'Cilpes';
  @override
  String get tagsEmpty =>
      'Vēl nav cilpu — pievienojiet piezīmē #cilpe vai frontmatterā cilpes';
  @override
  String get tagsBackTooltip => 'Atpakaļ uz meklēšanu';
  @override
  String get tagsNotesEmpty => 'Nav piezīmes ar šo cilpi';
  @override
  String tagsNotesCapped(int limit) =>
      'Tiek rādītas tikai pirmās $limit — meklējiet, lai ierobežotu';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Saite netika atrasta';
  @override
  String get headingNotFoundTitle => 'Virsraksts netika atrasts';
  @override
  String get ambiguousLinkTitle => 'Vairākas piezīmes atbilst';
  @override
  String get openLinkFailed => 'Nevarēja atvērt saiti';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Atvērti';
  @override
  String get todoDone => 'Pabeigti';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Visi datumi';
  @override
  String get todoFilter => 'Filtrēt';
  @override
  String get todoNoTokens => 'Šajā sarakstā nav žetonu';
  @override
  String get todoCountOpen => 'atvērti';
  @override
  String get todoCountDone => 'pabeigti';
  @override
  String get todoEmptyOpen => 'Vēl nav atvērtu uzdevumu';
  @override
  String get todoEmptyDone => 'Vēl nav pabeigtu';
  @override
  String get todoEmptyFiltered => 'Neviens uzdevums neattiecas';
  @override
  String get todoTitle => 'Uzdevumi';
  @override
  String get todoAddTooltip => 'Pievienot uzdevumu';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt formāts';
  @override
  String get todoHelpTooltip => 'Informācija par formātu';
  @override
  String get todoHelpIntro =>
      'Jūsu uzdevumi ir parasts teksta fails, viens uzdevums rindā. Niman '
      'raksta sintaksi jūsu vietā, bet failu var rediģēt jebkurā redaktorā, '
      'un Niman to atkal izlasīs.';
  @override
  String get todoHelpFilesTitle => 'Divi faili';
  @override
  String get todoHelpFilesBody =>
      'Atvērti uzdevumi dzīvo todo.txt bibliotēkas saknē. Pabeidzot vienu, '
      'rinda tiek pārvietota uz done.txt, lai todo.txt paliktu īss. Pabeigta '
      'rinda, kas atkal nonāk todo.txt, Niman arhivē nākamajā failu '
      'lasīšanā.';
  @override
  String get todoHelpLineTitle => 'Rindas anatomija';
  @override
  String get todoHelpLineBody =>
      'Viss, kas ir pirms apraksta, ir izvēles un tam jābūt šajā secībā:';
  @override
  String get todoHelpDoneBody =>
      'Atzīmē uzdevumu kā pabeigtu. Niman to pievieno, kad jūs pārbaudāt '
      'lauku.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritāte. A ir augstākā. Tiek rādīta kā emblema sarakstā.';
  @override
  String get todoHelpDatesBody =>
      'Termiņš, pēc tam izveidošanas datums. Ar vienu datumu tas ir '
      'izveidošanas datums, ja rinda nesākas ar x.';
  @override
  String get todoHelpTokensTitle => 'Projekti, konteksti un cilpes';
  @override
  String get todoHelpTokensBody =>
      'Jebkurš vārds aprakstā ar kādu no šīm priekšlikumiem kļūst par '
      'filtrējamu cilpi. Nekas nav iepriekš definēts: žetons eksistē, kamēr '
      'to neraksta.';
  @override
  String get todoHelpProjectBody =>
      'Kurai projektam uzdevums pieder, piemēram, +virtuve vai +darbs.';
  @override
  String get todoHelpContextBody =>
      'Kur vai kā to izdarīt, piemēram, @mājās vai @satikšanās.';
  @override
  String get todoHelpHashtagBody =>
      'Brīva cilpe tam, ko pārējie divi nepaklāj.';
  @override
  String get todoHelpTagsTitle => 'Datumi un atgādinājumi';
  @override
  String get todoHelpTagsBody =>
      'Šīs ir atslēga:vērtība cilpes. Niman tās raksta no uzdevuma dialoga '
      'un lasa tās jebkurā vietā, kur tās parādās rindā.';
  @override
  String get todoHelpDueBody =>
      'Termiņš. Vada emblemas krāsu un datuma filtrus.';
  @override
  String get todoHelpRemBody =>
      'Kad jānosūta ziņojums, jūsu laika joslā. Palaižas, kad ekrāns ir '
      'izslēgts un programma ir aizvērts.';
  @override
  String get todoHelpRemDesktop =>
      'Datorā Nimanam jādarbojas, kad laiks ir pienācis: atgādinājums tiek '
      'rādīts, kamēr programma ir atvērta, un nekas nenotiek, kad tā ir '
      'aizvērts.';
  @override
  String get todoHelpOtherBody =>
      'Tas tiek saglabāts tieši tā, kā tas ir uzrakstīts, lai citu todo.txt '
      'programmu cilpes izdzīvotu ceļu. Niman tos neizlieto, rec: included: '
      'atkārtojošs uzdevums vēl neatkārtojas.';
  @override
  String get todoHelpEditTitle => 'Rediģēšana ārpus Nimana';
  @override
  String get todoHelpEditBody =>
      'Rindas, kuras jūs nešķērsojat, tiek saglabātas baitu pa baitu. Niman '
      'pārraksta tikai to rindu kanoniskajā secībā, un pārējā faila daļa '
      'paliek neskartra.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Pievienot uzdevumu';
  @override
  String get todoEditTitle => 'Rediģēt uzdevumu';
  @override
  String get todoDescriptionHint => 'Apraksts';
  @override
  String get todoCancel => 'Atcelt';
  @override
  String get todoSave => 'Saglabāt';
  @override
  String get todoEditAction => 'Rediģēt';
  @override
  String get todoDeleteAction => 'Dzēst';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Termiņš ir pārgājis';
  @override
  String get todoDueToday => 'Šodien';
  @override
  String get todoDueNext7 => 'Nākošās 7 dienas';
  @override
  String get todoDueNoDate => 'Bez datuma';
  @override
  String get todoRowDue => 'Termiņš';
  @override
  String get todoRowDueToday => 'Termiņš šodien';
  @override
  String get todoSortTooltip => 'Kārtot';
  @override
  String get todoSortDue => 'Termiņa datums';
  @override
  String get todoSortPriority => 'Prioritāte';
  @override
  String get todoSortCreation => 'Izveidošanas datums';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez prioritātes';
  @override
  String get todoNoPriorityShort => 'Nav';
  @override
  String get todoMorePriorities => 'Vairāk…';
  @override
  String get todoPriorityTitle => 'Prioritāte';
  @override
  String get todoNoDueDate => 'Bez termiņa';
  @override
  String get todoNoReminder => 'Bez atgādinājuma';
  @override
  String get todoAddProject => '+ Projekts';
  @override
  String get todoAddContext => '@ Konteksts';
  @override
  String get todoAddHashtag => '# Cilpe';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Uzdevumu atgādinājumi';
  @override
  String get todoReminderChannelDescription =>
      'Plānoti ziņojumi uzdevumiem ar atgādinājuma laiku.';
  @override
  String get todoReminderBody => 'Uzdevuma atgādinājums';
  @override
  String get todoReminderFallbackTitle => 'Uzdevuma atgādinājums';
  @override
  String get todoReminderBlocked =>
      'Ziņojumi ir izslēgti, tāpēc atgādinājumi netiks rādīti.';
  @override
  String get todoReminderBattery =>
      'Akumulatora optimizācijai Niman ir piekļuve. Sistēma var apturēt '
      'programmu un zaudēt gaidītos atgādinājumus.';
  @override
  String get todoReminderInexact =>
      'Šī ierīce neatbalžo precīzus alarmus, tāpēc atgādinājums var '
      'ierasties dažas minūtes vēlāk, ja ekrāns ir izslēgts.';
  @override
  String get reminderShowTokensTitle => 'Cilpes atgādinājumu ziņojumos';
  @override
  String get reminderShowTokensSubtitle =>
      'Atstājiet +projekts, @konteksts un #cilpe ziņojuma tekstā. Izslēgts '
      'rāda tikai uzdevumu, ko jūs uzrakstījāt.';
  @override
  String get todoReminderFixAction => 'Atvērt iestatījumus';
  @override
  String get todoReminderDismissAction => 'Noraidīt';
  @override
  String get todoReminderDue => 'Termiņš';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Labi';
  @override
  String get actionCancel => 'Atcelt';
  @override
  String get actionCreate => 'Izveidot';
  @override
  String get actionNew => 'Jauns';
  @override
  String get actionSave => 'Saglabāt';
  @override
  String get actionClear => 'Notīrīt';
  @override
  String get actionChoose => 'Izvēlēties';
  @override
  String get actionDelete => 'Dzēst';
  @override
  String get actionRename => 'Pārsaukt';
  @override
  String get actionMove => 'Pārvietot';
  @override
  String get saveAndClose => 'Saglabāt un aizvērt';
  @override
  String get closeUnsavedTitle => 'Nesaglabātas izmēnas';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” ir nesaglabātas izmēnas. '
          'Saglabāt pirms aizvēršanas?';
    }
    return '${names.length} piezīmēm ir nesaglabātas izmēnas. '
        'Saglabāt pirms aizvēršanas?';
  }

  @override
  String get closeSaveFailed =>
      'Saglabāšana neizdevās; piezīme paliek atvērta.';
  @override
  String get actionRestore => 'Atjaunot';
  @override
  String get actionEmpty => 'Iztukšot';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Paslēpt sānpaneli (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Rādīt sānpaneli (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizēt';
  @override
  String get windowMaximizeTooltip => 'Maksimizēt';
  @override
  String get windowRestoreTooltip => 'Atjaunot';
  @override
  String get windowCloseTooltip => 'Aizvērt';
  @override
  String get tabFiles => 'Faili';
  @override
  String get tabSearch => 'Meklēšana';
  @override
  String get tabSettings => 'Iestatījumi';
  @override
  String get quickNoteTitle => 'Ātrā piezīme';
  @override
  String get treeEmpty => 'Vēl nav piezīmes';
  @override
  String get selectANote => 'Izvēlieties piezīmi';
  @override
  String get showListTooltip => 'Rādīt sarakstu';
  @override
  String get editRawTooltip => 'Rediģēt neapstrādātu';
  @override
  String get sortAscTooltip => 'Kārtot A–Z';
  @override
  String get sortDescTooltip => 'Kārtot Z–A';
  @override
  String get newNoteTitle => 'Jauna piezīme';
  @override
  String get newFolderTitle => 'Jauns katalogs';
  @override
  String get newNoteHere => 'Jauna piezīme šeit';
  @override
  String get newFolderHere => 'Jauns katalogs šeit';
  @override
  String get newListNoteTitle => 'Jauna piezīme ar sarakstu';
  @override
  String get newListNoteDefault => 'Mans saraksts';
  @override
  String get setAsQuickNote => 'Iestatīt kā ātro piezīmi';
  @override
  String get currentQuickNote => 'Pašreizējā ātrā piezīme';
  @override
  String get pinnedSection => 'Piestiprināts';
  @override
  String pinnedSectionCount(int count) => 'Piestiprināts · $count';
  @override
  String get templateFolderTitle => 'Šablonu katalogs';
  @override
  String get newFromTemplateTitle => 'Jauns no šablona';
  @override
  String get newFromTemplateHere => 'Jauns no šablona šeit';
  @override
  String get templateFormTitle => 'Aizpildīt šablonu';
  @override
  String get templateFormBacklink => 'Atpakaļsaite';
  @override
  String get templateFormNoNote => 'Bez piezīmes';
  @override
  String get templateFormPickNote => 'Izvēlēties piezīmi';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Šablona aizstājējzīmes';
  @override
  String get templateHelpIntro =>
      'Šablons ir parasta piezīme ar atverēm. Izveidojot piezīmi no tā, '
      'teksts tiek kopēts un atveres tiek aizpildītas.';
  @override
  String get templateHelpUnknown =>
      'Aizstājējzīme, ko Niman nezin, paliek tieši tā, kā tā ir uzrakstīta, '
      'lai klaviatūras kļūda būtu redzama piezīmē, nevis lai klusāi '
      'izdārtu rindu.';
  @override
  String get templateHelpValuesTitle => 'Vērtības';
  @override
  String get templateHelpTitleBody => 'Nosaukums, ar kuru piezīme jāizveido.';
  @override
  String get templateHelpDateBody =>
      'Šodien un pašreizējais laiks. Abi pītvadī formatu: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datums un laiks kopā.';
  @override
  String get templateHelpUuidBody =>
      'Jauns identifikators, kas atšķiras katrā lietojumā.';
  @override
  String get templateHelpCounterBody =>
      'Skaitlis, kas tiek skaitīts pēc nosaukuma, tiek saglabāts starp '
      'palaišķiem: pirmā piezīme uzraksta 1, nākošā 2. Tāds pats nosaukums '
      'piezīmē uzraksta to pašu skaitli; kombinējiet ar |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Novietojiet kursoru šeit, izveidojot piezīmi; zīme netiek uzrakstīta. '
      'Pirmā zīme uzvar, bez filtriem, tikai jaunās piezīmes — un klaviatūra '
      'atveras arī, ja autofocus ir izslēgts.';
  @override
  String get templateHelpDatesTitle => 'Datuma uzrakstīšana';
  @override
  String get templateHelpDatesBody =>
      'Šīs apzīmē datuma daļas formātā. Viss, kas nav, ir doslovno, '
      'ieskaitot tekstu vienkāršās pēdās. Mēneša un nedēļas dienu nosaukumi '
      'izmanto programmas valodu.';
  @override
  String get templateHelpYear => 'gads: 2026, 26';
  @override
  String get templateHelpMonth => 'mēnesis: 03, 3, marts, mar';
  @override
  String get templateHelpDay => 'diena: 09, 9, pirmdiena, pr';
  @override
  String get templateHelpTime => 'stundas, minūtes, sekundes';
  @override
  String get templateHelpWeek => 'ISO nedēļa un ceturksnis: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtrs';
  @override
  String get templateHelpFiltersBody =>
      'Pēc vērtības var sekot filtri, kas tiek piemēroti no kreisās uz '
      'labo pusi.';
  @override
  String get templateHelpCaseBody =>
      'Lielie burti, mazie burti un katra vārda pirmais burts — vārds, kas '
      'ir uzrakstīts ar lielo burtu, nemainās.';
  @override
  String get templateHelpSlugBody =>
      'Teksta saites forma, lai izveidotu viki saiti.';
  @override
  String get templateHelpPadBody =>
      'Noņem galus; aizpilda ar nullām līdz vēlamajam platumam; '
      'alternatīva, ja vērtība ir tukša.';
  @override
  String get templateHelpShiftBody =>
      'Pārvietojiet datumu par dienām, nedēļām, mēnešiem vai gadiem — '
      'konference pēc nedēļas, dokuments no pagājušā mēneša.';
  @override
  String get templateHelpSnapBody =>
      'Piestipriniet datumu nedēļas, mēneša vai gada sākumam vai galam.';
  @override
  String get templateHelpAskTitle => 'Jautājam jums kaut ko';
  @override
  String get templateHelpAskBody =>
      'Pirms piezīmes izveidošanas tiek rādīts form, jautājuma lauki — un '
      'viena atpakaļsaite, ja šablons to pieprasa. Tāda pati zīme divas '
      'reizes ir jautājums, un tās atbilde aizpilda visus parādījumus — '
      'katalogu un faila nosaukumu.';
  @override
  String get templateHelpAskFieldBody =>
      'Lauks, par ko jautā; teksts pēc otrā komata ir sākuma vērtība.';
  @override
  String get templateHelpChoiceBody =>
      'Izvēle no saraksta, atdalīta ar komatiem.';
  @override
  String get templateHelpWhereTitle => 'Kur piezīme nonāk';
  @override
  String get templateHelpWhereBody =>
      'Šis nav teksts: tie ir norādījumi, kas dzīvo šablona frontmattera '
      'niman: blokā. Bloks tiek palaists un dzēsts, lai tas nekad netiktu '
      'rādīts piezīmē. Vērtība var saturēt aizstājējzīmes.';
  @override
  String get templateHelpFolderBody =>
      'Katalogs, kurā piezīme tiek izveidota, tiek izveidots, ja tas '
      'neeksistē. Bez tā piezīme nonāk tur, kur jūs bijāt.';
  @override
  String get templateHelpFilenameBody =>
      'Kā piezīme tiek nosaukta. Šablons, kas to saka, nejautā par nosaukumu.';
  @override
  String get templateHelpAppendBody =>
      'Pievieno piezīmei, ja tā jau eksistē, nevis izveido jaunu. Tā mēneša '
      'sanāksmes kļūst par vienu failu.';
  @override
  String get templateHelpOpenBody =>
      'Kas notiek, ja piezīme eksistē: redaktors (noklusēts), priekšskatījums '
      'vai nekas — piezīme tiek arhivēta un jūs paliekat tur, kur bijāt.';
  @override
  String get templateHelpAroundTitle => 'No kurienes tā nāk';
  @override
  String get templateHelpParentBody =>
      'Piezīme, kuru jūs izvēlaties formā; uzrakstiet [[{{parent}}]] '
      'kā atpakaļsaite.';
  @override
  String get templateHelpFolderValueBody => 'Katalogs, kurā piezīme nonāk.';
  @override
  String get templateHelpClipboardBody =>
      'Kas ir starpliktuvē un kas ir izvēlēts redaktorā, ja piezīme sāka '
      'turienes.';
  @override
  String get templateHelpIncludeTitle => 'Daļu atkārtota izlietošana';
  @override
  String get templateHelpIncludeBody =>
      'Ievietojiet citu šablonu, lai daži šabloni dalītu vienu pārbaudes '
      'sarakstu. Meklēšana vispirms notiek šablonu katalogā, .md var būt '
      'izlaista. Tā paši jautājumi iet uz to pašu formu.';
  @override
  String get templateHelpExampleTitle => 'Viskas vienā vietā';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ šablons „$path” neeksistē';
  @override
  String includeCycle(String path) => '⚠ „$path” ievietojas sevī';
  @override
  String includeTooDeep(String path) => '⚠ „$path” ir pārāk dziļi ievietots';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatteru nevarēja izlasīt: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Šablona „$template” frontmatteru nevarēja izlasīt, tāpēc katalogs un '
      'faila nosaukums neko neatdarināja: $reason';
  @override
  String get templatePickerTitle => 'Šablonu izvēle';
  @override
  String templatePickerEmpty(String folder) =>
      'Vēl nav šablonu. Ievietojiet piezīmi $folder/ un tas būs šablons.';

  // Tree actions.
  @override
  String get actionPin => 'Piestiprināt';
  @override
  String get actionUnpin => 'Atdzīt';
  @override
  String get movedToTrash => 'Pārvietots konteinerā';
  @override
  String get deletedMessage => 'Dzēsts';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name tiks pārvietots uz .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name tiks neatgriezeniski dzēsts';
  @override
  String get chooseDestination => 'Izvēlēties mērķi';
  @override
  String get libraryRoot => 'Bibliotēkas sakne';
  @override
  String moveTitle(String name) => 'Pārvietot $name';
  @override
  String headingLevelLabel(int level) => 'Virsraksta līmenis $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Vēl nav ātrās piezīmes. Izvēlieties esošo piezīmi vai izveidojiet '
      'jaunu — ātrā piezīme atvērsies šeit.';
  @override
  String get quickNoteChooseAction => 'Izvēlēties piezīmi…';
  @override
  String get quickNoteCreateAction => 'Izveidot jaunu piezīmi…';
  @override
  String get quickNoteNewTitle => 'Jauna ātrā piezīme';
  @override
  String get quickNotePickerTitle => 'Ātrās piezīmes izvēle';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Jauns katalogs';
  @override
  String get folderPickerEmpty => 'Vēl nav kataloga';
  @override
  String get listFolderTitle => 'Sarakstu katalogs';

  // Trash (M1).
  @override
  String get trashEmpty => 'Konteiners ir tukšs';
  @override
  String get trashEmptyAction => 'Iztukšot konteineru';
  @override
  String get trashEmptyConfirm =>
      'Tas neatgriezeniski izdzēs visu, kas ir konteinerā, ieskaitot '
      'elementus, ko Niman tur neielika.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name tiks neatgriezeniski dzēsts (bez atjaunošanas)';
  @override
  String get trashDeletePermanently => 'Dzēst neatgriezeniski';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Atveriet Markdown piezīmju katalogu kā bibliotēku';
  @override
  String get openLibraryExisting => 'Atvērt esošo';
  @override
  String get openLibraryCreate => 'Izveidot jaunu';
  @override
  String get openLibraryCreateTitle => 'Izveidot jaunu bibliotēku';
  @override
  String get openLibraryFolderName => 'Kataloga nosaukums';
  @override
  String get openLibraryChooseFolder => 'Izvēlēties bibliotēkas katalogu';
  @override
  String get openLibraryChooseParent =>
      'Izvēlēties katalogu, kurā bibliotēka tiks izveidota';
  @override
  String get openLibraryUnsupported =>
      'Šis katalogs netiek atbalstīts. Izvēlieties katalogu no ierīces '
      'uzglabāšanas.';
  @override
  String indexingCount(int done, int total) => '$done / $total piezīmes';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Jūsu bibliotēkas';
  @override
  String get libraryUnreachable => 'Neiedarāms';
  @override
  String get libraryOpenedToday => 'Atvērta šodien';
  @override
  String get libraryOpenedYesterday => 'Atvērta vakar';
  @override
  String libraryOpenedDaysAgo(int days) => 'Atvērta pirms $days dienām';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Atvērta ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Pašlaik atvērta';
  @override
  String get switchLibraryTitle => 'Pārslēgt bibliotēku';
  @override
  String get libraryForget => 'Aizmirst';
  @override
  String libraryForgetTitle(String name) => 'Aizmirst „$name”?';
  @override
  String get libraryForgetExplained =>
      'Tā pazudīs no šī saraksta. Katalogs, piezīmes un bibliotēkas '
      'iestatījumi paliek neskartri, un atkārtota atvēršana atgriež uz '
      'vietu.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Atļaut piekļuvi failiem';
  @override
  String get storageAccessNeeded =>
      'Niman nevar lasīt jūsu piezīmes bez „Piekļuve visiem failiem”. '
      'Atļaujiet to, lai atvērtu bibliotēku.';
  @override
  String get storageAccessExplained =>
      'Niman lasa jūsu piezīmes kā parastus failus, tāpēc Android jāsniedz '
      'piekļuve visiem failiem. Nekas netiek sūtīts; lasa tikai izvēlēto '
      'bibliotēkas katalogu.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistēma neļāva piekļūt katalogam: $error';
  @override
  String folderPickFailed(Object error) => 'Kataloga izvēle neizdevās: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Iestatījumi';
  @override
  String get libraryPathTitle => 'Bibliotēkas ceļš';
  @override
  String get reindexTitle => 'Pārraudzīt tagad';
  @override
  String get reindexDone => 'Pārraudzīšana pabeigta';
  @override
  String get closeLibraryTitle => 'Aizvērt bibliotēku';
  @override
  String get exportLogTitle => 'Eksportēt atkļūdošanas žurnālu';
  @override
  String get exportLogSubtitle =>
      'Saglabiet reģistrētos notikumus failā, ko jūs izvēlaties';
  @override
  String get exportLogEmpty => 'Žurnāla buferis ir tukšs';
  @override
  String get quickNoteUnset => 'Niestatīts';
  @override
  String exportLogDone(Object target) => 'Žurnāls eksportēts uz $target';
  @override
  String exportLogFailed(Object error) => 'Eksports neizdevās: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '„$term” nav precīza visa vārda sakritējuma';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Aizstāti $occurrences parādījumi „$term” $notes piezīmēs';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped atvērtas piezīmes izlaistas)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '„$term” nav precīza visa vārda sakritējuma'
      '${only == null ? '' : ' netika atrasts $only'}';
}
