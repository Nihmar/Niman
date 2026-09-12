// The Basque strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class BasqueStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'urtarrila',
    'otsaila',
    'martxoa',
    'apirila',
    'maiatza',
    'ekaina',
    'uztaila',
    'abuztua',
    'iraila',
    'urria',
    'azaroa',
    'abendua',
  ];
  @override
  List<String> get monthNamesShort => const [
    'urt',
    'ots',
    'mar',
    'api',
    'mai',
    'eka',
    'uzt',
    'abu',
    'ira',
    'urr',
    'aza',
    'abe',
  ];
  @override
  List<String> get weekdayNames => const [
    'astelehena',
    'asteartea',
    'asteazkena',
    'osteguna',
    'ostirala',
    'larunbata',
    'igandea',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'al',
    'ar',
    'as',
    'og',
    'os',
    'lb',
    'ig',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Zaborrontza';
  @override
  String get trashSubtitle =>
      'Ezabatzeak .trash/-ra joaten dira (desaktibatuta = betirako ezabatzea)';
  @override
  String get debugLogsTitle => 'Arazte-erregistroak';
  @override
  String get debugLogsSubtitle =>
      'Erregistratu aplikazioaren gertaerak memoria-bufreakin';
  @override
  String get lineNumbersTitle => 'Lerro-zenbakiak';
  @override
  String get lineNumbersSubtitle =>
      'Erakutsi lerro-zenbaki zutabea ohar-erreditoran';
  @override
  String get keyboardOnOpenTitle => 'Teklategia irekitzean';
  @override
  String get keyboardOnOpenSubtitle =>
      'Erakutsi teklatua oharra irekitzen denekoan (desaktibatuta = '
      'lehen ukitzean)';
  @override
  String get editorKindSource => 'Markdown-iturria';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Aurrebista';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Erakutsi errenderatutako oharra iturri-erreditoraren ondoan';
  @override
  String get switchToWysiwygTooltip => 'Pasatu WYSIWYG erreditorra';
  @override
  String get switchToSourceTooltip => 'Pasatu Markdown-iturrira';
  @override
  String get wysiwygTooLarge =>
      'Ohar honek ez du WYSIWYG erreditorrentzat. Ireki Markdown-iturrian.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Itxura';
  @override
  String get settingsSectionEditor => 'Erreditorra';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'Gogorapenak';
  @override
  String get settingsSectionShortcuts => 'Teklategia';
  @override
  String get keyboardShortcutsTitle => 'Teklatu-lasterdarrak';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Ortografia-egiaztapena';
  @override
  String get settingsSpellCheckSubtitle =>
      'Azpimarratzen du akats ortografikoak idazten ari zarenean.';
  @override
  String get spellCheckDictionaryTitle => 'Hiztegia';
  @override
  String get spellCheckDictionarySystem => 'Sistemaren lehenespena';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Hiztegiak hautatu';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Hautatu bibliotekan erabilitako hizkuntza guztiak. Hitz bat pasatzen '
      'da hautatutako hiztegi bat ezagutzen duenean; hautapenik gabe, '
      'sistemaren hizkuntzaren arabera.';
  @override
  String get spellCheckNoDictionaries =>
      'Hiztegirik ez da aurkitu sistemako honetan.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Ortografia-egiaztapena';
  @override
  String get spellCheckTitle => 'Ortografia';
  @override
  String get spellCheckEmpty => 'Ez dago ortografia-akatsik.';
  @override
  String get spellCheckUnavailable =>
      'hunspell ez dago instalatuta sistemako honetan.';
  @override
  String get spellCheckNoSuggestions => 'Ez dago iradokirik';
  @override
  String spellCheckCount(int count) => '$count begiratzeko';
  @override
  String spellCheckLine(int line) => 'lerroa $line';

  @override
  String indentWidthValue(int spaces) => '$spaces zuriune';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Argitasuna';
  @override
  String get themeBrightnessSubtitle => 'Argia, iluna edo gailuaren ezarpena';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Argia';
  @override
  String get themeBrightnessNight => 'Iluna';
  @override
  String get themePaletteTitle => 'Kolore-paleta';
  @override
  String get themePaletteSubtitle => 'Interfazearen eta oharreko koloreak';
  @override
  String get themePaletteSystem => 'Sistema';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Interfazearen testuaren tamaina';
  @override
  String get uiTextScaleSubtitle =>
      'Zuhurra, fitxak eta dialoguak; sistemaren ezarpenaren gainetik';
  @override
  String get noteTextScaleTitle => 'Oharreko testuaren tamaina';
  @override
  String get noteTextScaleSubtitle =>
      'Erreditorra eta aurrebista, beti bat etorritakoak';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Aurrebista-eredua';
  @override
  String get previewModeSubtitle =>
      'Aurrebistak pantaila erreditorarekin banatzen du edo ordezkatzen '
      'du';
  @override
  String get previewModeAuto => 'Bata bestearen ondoan';
  @override
  String get previewModeSwitch => 'Pantaila osoa';
  @override
  String get splitRatioTitle => 'Banaketa-zabalera';
  @override
  String get splitRatioSubtitle =>
      'Erreditorearen partea aurrebista bat bestearrekin ondoan badu';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Esteka-forma';
  @override
  String get linkTypeSubtitle => 'Esteka-botoiak erreditoran txertatzen duena';
  @override
  String get linkTypeWikilink => 'Wiki-esteka';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Bilketa-zabalera';
  @override
  String get indentWidthSubtitle => 'Erreditoraren bikoiztze-mailako zuriuneak';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Hizkuntza';
  @override
  String get languageSubtitle => 'Aplikazioaren testuaren hizkuntza';
  @override
  String get languageSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Gehitu elementu bat';
  @override
  String get listAddTooltip => 'Gehitu elementu bat';
  @override
  String get listEmpty => 'Oraindik ez dago elementurik';
  @override
  String get listDragHandleLabel => 'Aldatu elementuaren ordena';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Ohar azkarra';
  @override
  String get shortcutNewTodo => 'Zeregin berria';
  @override
  String get shortcutNewNote => 'Ohar berria';
  @override
  String get shortcutNewList => 'Zerrenda berria';
  @override
  String get shortcutToggleSidebar => 'Ezkutatu edo erakutsi iragazkia';
  @override
  String get shortcutEditorSection => 'Erreditoran';
  @override
  String get shortcutFind => 'Bilatu';
  @override
  String get shortcutReplace => 'Bilatu eta ordezkatu';
  @override
  String get shortcutSavingNote =>
      'Aldaketak automatikoki gordetzen dira, beraz ez dago gordetzeko '
      'lasterdarririk.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Egitura';
  @override
  String get outlineNoHeadings => 'Ez dago izenbururik';
  @override
  String get outlineNoTitle => '(izenbururik gabe)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Lodia';
  @override
  String get toolbarItalic => 'Etzana';
  @override
  String get toolbarStrikethrough => 'Marratua';
  @override
  String get toolbarSuperscript => 'Goiko indizea';
  @override
  String get toolbarUnderline => 'Azpimarratua';
  @override
  String get toolbarLink => 'Esteka';
  @override
  String get toolbarCode => 'Kode blokea';
  @override
  String get toolbarImage => 'Txertatu irudia';
  @override
  String get toolbarHeading => 'Izenburua';
  @override
  String get toolbarList => 'Zerrenda';
  @override
  String get toolbarOrderedList => 'Zerrenda zenbatua';
  @override
  String get toolbarQuote => 'Aipua';
  @override
  String get toolbarIndent => 'Bilkatu';
  @override
  String get toolbarOutdent => 'Desbilkatu';
  @override
  String get headingDialogTitle => 'Izenburu-maila';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Erreditorearen tresna-barra';
  @override
  String get toolbarSettingsHint =>
      'Arrastatu ordena aldatzeko; begiz ikusten edo ezkutatzen du '
      'botoi bat.';
  @override
  String get toolbarShowButton => 'Erakutsi';
  @override
  String get toolbarHideButton => 'Ezkutatu';
  @override
  String get toolbarResetOrder => 'Leheneratu';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Erakutsi aurrebista';
  @override
  String get showEditorTooltip => 'Erakutsi erreditorra';
  @override
  String get enterFullScreenTooltip => 'Pantaila osoa';
  @override
  String get exitFullScreenTooltip => 'Irten pantaila osoetik';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(HTML taula krudoa)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Bilatu oharretan';
  @override
  String get searchModeWords => 'Hitzak';
  @override
  String get searchModeContains => 'Eman du';
  @override
  String get searchEmptyHint =>
      'Idatzi bibliotekan bilatzeko, edo tekla = balioa frontmatter '
      'iragazteko';
  @override
  String get searchTooShortHint => 'Idatzi gutxienez 2 karaktere';
  @override
  String get searchNoMatches => 'Ez dago emaitzarik';
  @override
  String get searchLoadMore => 'Ikusi gehiago';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Ordezkatu…';
  @override
  String get replaceInNoteAction => 'Ordezkatu ohar honetan…';
  @override
  String get replaceInThisNote => 'Ordezkatu ohar honetan';
  @override
  String get replaceWithLabel => 'Ordezkatu honekin';
  @override
  String get replaceCaseSensitive => 'Maiuskula/minuszkula';
  @override
  String get replaceWholeWordsHint =>
      'soilik zehaztasunezko hitz osoko emaitzak ordezkatzen dira';
  @override
  String get replaceConfirm => 'Ordezkatu';
  @override
  String get replaceCancel => 'Itxi';
  @override
  String get replaceUnavailable => 'Ordezkapena ez dago orain eskuragarri';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Bilatu oharrean';
  @override
  String get editorFindHint => 'Bilatu';
  @override
  String get editorReplaceHint => 'Ordezkatu';
  @override
  String get editorFindCaseTooltip => 'Maiuskula/minuszkula';
  @override
  String get editorFindPreviousTooltip => 'Aurreko emaitza';
  @override
  String get editorFindNextTooltip => 'Hurrengo emaitza';
  @override
  String get editorFindCloseTooltip => 'Itxi bilaketa';
  @override
  String get editorFindReplaceModeTooltip => 'Ordezkapen-eredua';
  @override
  String get editorReplaceOneTooltip => 'Ordezkatu emaitza hau';
  @override
  String get editorReplaceAllTooltip => 'Ordezkatu emaitza guztiak';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etiketak';
  @override
  String get tagsTitle => 'Etiketak';
  @override
  String get tagsEmpty =>
      'Oraindik ez dago etiketarik — gehitu #etiketa bat edo '
      'frontmatter-etiketak';
  @override
  String get tagsBackTooltip => 'Itzuli bilaketara';
  @override
  String get tagsNotesEmpty => 'Ez dago oharrik etiketa honekin';
  @override
  String tagsNotesCapped(int limit) =>
      'Lehenengo $limit bakarrik daude ikusgai — bilatu etiketa '
      'mugatzeko';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Ez da estekarik aurkitu';
  @override
  String get headingNotFoundTitle => 'Ez da izenbururik aurkitu';
  @override
  String get ambiguousLinkTitle => 'Ohar askok bat etortzen dute';
  @override
  String get openLinkFailed => 'Ezin izan da esteka ireki';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Irekitakoak';
  @override
  String get todoDone => 'Bukatuta';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Data guztiak';
  @override
  String get todoFilter => 'Iragazi';
  @override
  String get todoNoTokens => 'Ez dago tokenerik zerrenda honetan';
  @override
  String get todoCountOpen => 'irekitakoak';
  @override
  String get todoCountDone => 'bukatutakoak';
  @override
  String get todoEmptyOpen => 'Oraindik ez dago zeregin irekirik';
  @override
  String get todoEmptyDone => 'Oraindik ez da ezer bukatu';
  @override
  String get todoEmptyFiltered => 'Ez dago zeregirik bat etorritako';
  @override
  String get todoTitle => 'Egin beharrekoa';
  @override
  String get todoAddTooltip => 'Gehitu zeregin';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt formatoa';
  @override
  String get todoHelpTooltip => 'Formatu-azalpena';
  @override
  String get todoHelpIntro =>
      'Zure zereginak testu fitxategi arrunt bat dira, zeregin bat lerroko. '
      'Niman sintaxia zuretzat idazten du, baina ezer ez da ezkutuan: '
      'fitxategia edozein editorean editatu dezakezu, Niman berriro '
      'irakurrita.';
  @override
  String get todoHelpFilesTitle => 'Fitxategi biak';
  @override
  String get todoHelpFilesBody =>
      'Irekitako zereginak todo.txt-n daude bibliotekararen erraizean. '
      'Bat bukatzera, lerroa done.txt-ra joaten da, todo.txt labur '
      'mantentzeko. Lerro bat bukaturik todo.txt-ra itzulitzen bada, Niman '
      'artxibatuko du fitxategiak berriro irakurtzen dituenean.';
  @override
  String get todoHelpLineTitle => 'Lerro baten anatomia';
  @override
  String get todoHelpLineBody =>
      'Deskribapen aurreko guztia aukerakoa da eta ordena honetan etorri '
      'behar da:';
  @override
  String get todoHelpDoneBody =>
      'Zeregina bukatutako gisa markatzen du. Niman markatzen du '
      'atakasiko koadroan markatzen duzunean.';
  @override
  String get todoHelpPriority => '(A) (Z) arte';
  @override
  String get todoHelpPriorityBody =>
      'Lehentasuna. A da altuena. Zerrendan badge gisa agertzen da.';
  @override
  String get todoHelpDatesBody =>
      'Bukatzeko data, eta gero sortze-data. Data bakarra bada, '
      'sortze-data da, lerroa x-ekin hasten ez den bitartean.';
  @override
  String get todoHelpTokensTitle => 'Proiektuak, testuinguruak eta etiketak';
  @override
  String get todoHelpTokensBody =>
      'Deskribapen guztian, aurrarazoi hauetako bat duen hitza chip bat '
      'bihurtzen da iragazteko. Ez dago aurretik definiturik: tokena dago '
      'zuretzat idazten duzunean.';
  @override
  String get todoHelpProjectBody =>
      'Zereginaren zehar, adibidez +suila edo +tramitazioa.';
  @override
  String get todoHelpContextBody =>
      'Non edo nola egiten duzun, adibidez @etxean edo @bitarrerak.';
  @override
  String get todoHelpHashtagBody =>
      'Etiketa askea, bestea bi ez dute estaltzen guztiarentzat.';
  @override
  String get todoHelpTagsTitle => 'Data eta gogorapenak';
  @override
  String get todoHelpTagsBody =>
      'Hau da tekla:balio etiketak. Niman egin zuek egin eta irakurten '
      'dituen zerrendan non agertzen diren.';
  @override
  String get todoHelpDueBody =>
      'Epea. Coloreko badge eta data iragazleen zuzendaria.';
  @override
  String get todoHelpRemBody =>
      'Bekoa bidali behar duenean, zuen unera baliagarri. Pantaila '
      'itzalita eta aplikazioa itxita abiarazten da.';
  @override
  String get todoHelpRemDesktop =>
      'Mahaigainean Niman egon behar du unea iritsi denean: gogorapena '
      'aplikazioa zabalik dagoela erakusten da, eta ez da ezer abiarazten '
      'itxita.';
  @override
  String get todoHelpOtherBody =>
      'Ez da aldatzen idatzitako bezala, todo.txt beste aplikazioetako '
      'etiketak biratzean bizirik irautzeko. Niman ez da horietan '
      'eragiten, rec: included: zeregin errepikagarria oraindik ez da '
      'errepikatzen.';
  @override
  String get todoHelpEditTitle => 'Niman kanpoko edizioa';
  @override
  String get todoHelpEditBody =>
      'Ezin dituzun zereginak zuretzat berriro idazten dira byte byte, '
      'zuriune arrarazoiak kontuan hartuta. Lerro bat editatu eta Niman '
      'kanpoko formatuaren lerro bereziak idazten du, eta fitxategiaren '
      'gainerakoa ez du ukitzen.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Gehitu zeregin';
  @override
  String get todoEditTitle => 'Editatu zeregin';
  @override
  String get todoDescriptionHint => 'Deskribapena';
  @override
  String get todoCancel => 'Utzi';
  @override
  String get todoSave => 'Gorde';
  @override
  String get todoEditAction => 'Editatu';
  @override
  String get todoDeleteAction => 'Ezabatu';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Epe galdu';
  @override
  String get todoDueToday => 'Gaur';
  @override
  String get todoDueNext7 => 'Hurrengo 7 egunean';
  @override
  String get todoDueNoDate => 'Datarik gabe';
  @override
  String get todoRowDue => 'Epe';
  @override
  String get todoRowDueToday => 'Epe gaur';
  @override
  String get todoSortTooltip => 'Ordenatu';
  @override
  String get todoSortDue => 'Epe-data';
  @override
  String get todoSortPriority => 'Lehentasuna';
  @override
  String get todoSortCreation => 'Sortze-data';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Ez dago lehentasunik';
  @override
  String get todoNoPriorityShort => 'Ez';
  @override
  String get todoMorePriorities => 'Gehiago…';
  @override
  String get todoPriorityTitle => 'Lehentasuna';
  @override
  String get todoNoDueDate => 'Epe datarik gabe';
  @override
  String get todoNoReminder => 'Ez dago gogorapenik';
  @override
  String get todoAddProject => '+ Proiektua';
  @override
  String get todoAddContext => '@ Testuingurua';
  @override
  String get todoAddHashtag => '# Etiketa';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Zeregin-gogorapenak';
  @override
  String get todoReminderChannelDescription =>
      'Zeregin gogorapen-unearen aurrez zehaztutako abisua.';
  @override
  String get todoReminderBody => 'Todo gogorapena';
  @override
  String get todoReminderFallbackTitle => 'Zeregin-gogorapena';
  @override
  String get todoReminderBlocked =>
      'Abisuak ez daude gaituta, gogorapenak ez dira erakusten.';
  @override
  String get todoReminderBattery =>
      'Bateria-optimizazioa Niman-entzat gaituta dago. Sistema '
      'aplikazioa loara utzi eta gogorapen itxaromendakoak galdu '
      'ditzake.';
  @override
  String get todoReminderInexact =>
      'Gailu honek ez du alarma zehatzak ahalbidetzen, gogorapena minutu '
      'batzuekin berandu ager daiteke pantaila itzalia.';
  @override
  String get reminderShowTokensTitle => 'Etiketak gogorapen abisuetan';
  @override
  String get reminderShowTokensSubtitle =>
      'Mantendu +proiektua, @testuingurua eta #etiketa abisuaren testuan. '
      'Desaktibatuta zure idatzitako zeregin bakarrik erakusten da.';
  @override
  String get todoReminderFixAction => 'Ireki ezarpenak';
  @override
  String get todoReminderDismissAction => 'Baztertu';
  @override
  String get todoReminderDue => 'Epe';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Ados';
  @override
  String get actionCancel => 'Utzi';
  @override
  String get actionCreate => 'Sortu';
  @override
  String get actionNew => 'Berria';
  @override
  String get actionSave => 'Gorde';
  @override
  String get actionClear => 'Garbitu';
  @override
  String get actionChoose => 'Hautatu';
  @override
  String get actionDelete => 'Ezabatu';
  @override
  String get actionRename => 'Izena aldatu';
  @override
  String get actionMove => 'Mugitu';
  @override
  String get saveAndClose => 'Gorde eta itxi';
  @override
  String get closeUnsavedTitle => 'Gorde gabeko aldaketak';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” oraindik gorde gabeko aldaketak ditu. '
          'Gorde aurre itxi aurretik?';
    }
    return '${names.length} oharrek oraindik gorde gabeko aldaketak '
        'dituzte. Gorde aurre itxi aurretik?';
  }

  @override
  String get closeSaveFailed => 'Ezin izan da gorde; oraindik zabalik.';
  @override
  String get actionRestore => 'Berrezarri';
  @override
  String get actionEmpty => 'Hutsu';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ezkutatu barra aldekoa (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Erakutsi barra aldekoa (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizatu';
  @override
  String get windowMaximizeTooltip => 'Maksimatu';
  @override
  String get windowRestoreTooltip => 'Berrezarri';
  @override
  String get windowCloseTooltip => 'Itxi';
  @override
  String get tabFiles => 'Fitxategiak';
  @override
  String get tabSearch => 'Bilatu';
  @override
  String get tabSettings => 'Ezarpenak';
  @override
  String get quickNoteTitle => 'Ohar azkarra';
  @override
  String get treeEmpty => 'Oraindik ez dago oharrik';
  @override
  String get selectANote => 'Hautatu ohar bat';
  @override
  String get showListTooltip => 'Erakutsi zerrenda';
  @override
  String get editRawTooltip => 'Editatu krudoa';
  @override
  String get sortAscTooltip => 'Ordenatu A-Z';
  @override
  String get sortDescTooltip => 'Ordenatu Z-A';
  @override
  String get newNoteTitle => 'Ohar berria';
  @override
  String get newFolderTitle => 'Fitxategi-biltegi berria';
  @override
  String get newNoteHere => 'Ohar berria hemen';
  @override
  String get newFolderHere => 'Fitxategi-biltegi berria hemen';
  @override
  String get newListNoteTitle => 'Ohar zerrenda berria';
  @override
  String get newListNoteDefault => 'Nire zerrenda';
  @override
  String get setAsQuickNote => 'Ezarri ohar azkar gisa';
  @override
  String get currentQuickNote => 'Ohar azkar uneko';
  @override
  String get pinnedSection => 'Txertatua';
  @override
  String pinnedSectionCount(int count) => 'Txertatua · $count';
  @override
  String get templateFolderTitle => 'Txantiloi-biltegia';
  @override
  String get newFromTemplateTitle => 'Berria txantiloitik';
  @override
  String get newFromTemplateHere => 'Berria txantiloitik hemen';
  @override
  String get templateFormTitle => 'Bete txantiloia';
  @override
  String get templateFormBacklink => 'Estekatua hemendik';
  @override
  String get templateFormNoNote => 'Oharrik ez';
  @override
  String get templateFormPickNote => 'Hautatu oharra';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Txantiloi leku-ordainleak';
  @override
  String get templateHelpIntro =>
      'Txantiloi bat ohar arruntena da zuloekin. Txantiloi batetik oharra '
      'sortzean testua kopiatzen eta zuloak betetzen dira.';
  @override
  String get templateHelpUnknown =>
      'Niman ez du ezagutzen leku-ordainle bakarrak idatzitako modu '
      'zehatz berezira mantentzen, ortografia akats bat ikusten da '
      'oharrean lerro bat begiratu eta irekitzen denean.';
  @override
  String get templateHelpValuesTitle => 'Balioak';
  @override
  String get templateHelpTitleBody => 'Izena oharra sortzeko.';
  @override
  String get templateHelpDateBody =>
      'Gaur, orain unea. Biak forma bat har dute: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data eta ordua batera.';
  @override
  String get templateHelpUuidBody =>
      'Identifikadore berria, bakoitzak bere berezia.';
  @override
  String get templateHelpCounterBody =>
      'Izen izendapena zenbatzen duen zenbakia, berrabiarazteetan gordeta: '
      'lehenengo oharra 1 idazten du, hurrengoa 2. Izen berdinak ohar '
      'bakarrean zenbaki bera idazten du; |pad:3-kin konbinatu.';
  @override
  String get templateHelpCursorBody =>
      'Kurtsorea hemendik jartzen du oharra sortzen denean; kurtsorea ez '
      'da idazten. Kurtsore lehenengoa irabazten du, iragazlik gabe, ohar '
      'berriak bakarrik — eta teklatua autofokusarekin irekitzen da.';
  @override
  String get templateHelpDatesTitle => 'Data idazteko';
  @override
  String get templateHelpDatesBody =>
      'Hauek data formatuaren zatien ordez datoz. Bestelako guztia '
      'letrak da, eta zati bakarra ez da letrak ere. Hilabeteko eta '
      'aste egun izenak aplikazioaren hizkuntzaren arabera.';
  @override
  String get templateHelpYear => 'urtea: 2026, 26';
  @override
  String get templateHelpMonth => 'hilabetea: 03, 3, martxo, mar';
  @override
  String get templateHelpDay => 'eguna: 09, 9, astelehen, al';
  @override
  String get templateHelpTime => 'ordu, minutu, segundoen';
  @override
  String get templateHelpWeek => 'ISO astea eta hiruhilekoa: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Iragazkiak';
  @override
  String get templateHelpFiltersBody =>
      'Balioak iragazki batzuekin jarraitu daiteke, ezkerretik eskuinera.';
  @override
  String get templateHelpCaseBody =>
      'Maiuskulak, minuskulak, eta hitz bakoitzaren lehen letra — zu '
      'berdin idatzitako hitza ez da ukitzen.';
  @override
  String get templateHelpSlugBody =>
      'Testuaren esteka-forma, wiki-esteka eraikitzeko.';
  @override
  String get templateHelpPadBody =>
      'Muturrak ebaki; zeroraz bete zabalera batera; alternatiboa erabili '
      'balioa hutsa badu.';
  @override
  String get templateHelpShiftBody =>
      'Data egun, aste, hilabete edo urte batzuetan mugitu — hurrengo '
      'astearen auzia, aurreko hilabeteko fitxategia.';
  @override
  String get templateHelpSnapBody =>
      'Data asteko, hilabeteko edo urteko hasierara edo amaierara jarri.';
  @override
  String get templateHelpAskTitle => 'Zuretzat galdetzeko';
  @override
  String get templateHelpAskBody =>
      'Formularioa erakusten da oharra sortu aurretik, galdera bakoitzeko '
      'eremu bat — eta backlink eremu bat txantiloiak nahi badu. Etiketa '
      'bereko biak galdera bat dira, eta erantzuna dena betetzen du — '
      'biltegia eta fitxarraren izena ere kontuan.';
  @override
  String get templateHelpAskFieldBody =>
      'Idazteko eremua; bigarren ikurburuko aurreko testua dena hasierakoa '
      'da.';
  @override
  String get templateHelpChoiceBody => 'Zerrendako hautapena, komaz bereizita.';
  @override
  String get templateHelpWhereTitle => 'Oharra non geratzen den';
  @override
  String get templateHelpWhereBody =>
      'Hauek ez dira testua: aginduak dira, txantiloiaren frontmatter '
      'propioan niman: bloke batean daude. Blokea abiatzen da eta gero '
      'ezabatzen da, ez da inoiz oharrean ikusten. Balioek leku-ordainleak '
      'izan ditzakete.';
  @override
  String get templateHelpFolderBody =>
      'Oharra sortzen den biltegia, ez dagoenean sortzen da. Ez badu, '
      'oharra zeurengandik geratzen da.';
  @override
  String get templateHelpFilenameBody =>
      'Oharra nola izendatzen den. Izendapen hau esaten duen txantiloiari '
      'ez diot izena galdetzen.';
  @override
  String get templateHelpAppendBody =>
      'Oharra gehitu badu, ohar berria sortzearen ordez. Honek hilabeteko '
      'bitera bat fitxategi bakarra bihurtzen du.';
  @override
  String get templateHelpOpenBody =>
      'Oharra badu zer gertatzen den: erreditorra (lehenespena), '
      'aurrebista, edo ezer — oharra artxibatzen da zeurengandik '
      'geratzen zaie.';
  @override
  String get templateHelpAroundTitle => 'Non datorkio';
  @override
  String get templateHelpParentBody =>
      'Formularioan hautatutako oharra, pantailan iradokitzen da; '
      '[[{{parent}}]] idatzi esteka itzultzeko.';
  @override
  String get templateHelpFolderValueBody => 'Oharra geratu den biltegia.';
  @override
  String get templateHelpClipboardBody =>
      'Ordezkaritik zer dagoen, eta oharra hasi aurreko erreditor '
      'hautapena.';
  @override
  String get templateHelpIncludeTitle => 'Zati baten berri';
  @override
  String get templateHelpIncludeBody =>
      'Txantiloi beste bat txertatzen du, txantiloi hamabira zerrenda '
      'kontrolatu bakoitzak izateko. Txantiloi-biltegian lehenik '
      'bilatzen da, .md kendu daiteke. Bere galderak formulario berean '
      'daude.';
  @override
  String get templateHelpExampleTitle => 'Dena batera';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ez dago txantiloirik “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” bera barne hartzen du';
  @override
  String includeTooDeep(String path) => '⚠ “$path” asko sakon dago';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter ez da irakurri: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      '“$template” frontmatter ez da irakurri, biltegia eta fitxarraren '
      'izena ez zuten ezer egin: $reason';
  @override
  String get templatePickerTitle => 'Hautatu txantiloi bat';
  @override
  String templatePickerEmpty(String folder) =>
      'Oraindik ez dago txantiloirik. Ohar bat $folder/-an jarri eta '
      'txantiloi bihurtuko da.';

  // Tree actions.
  @override
  String get actionPin => 'Txertatu';
  @override
  String get actionUnpin => 'Askatu';
  @override
  String get movedToTrash => 'Zaborrontzara mugitua';
  @override
  String get deletedMessage => 'Ezabatua';
  @override
  String deleteToTrashConfirm(String name) => '$name .trash/-ra mugituko da';
  @override
  String deleteForeverConfirm(String name) => '$name betirako ezabatuko da';
  @override
  String get chooseDestination => 'Hautatu helmuga';
  @override
  String get libraryRoot => 'Bibliotekararen erraizea';
  @override
  String moveTitle(String name) => 'Mugitu $name';
  @override
  String headingLevelLabel(int level) => 'Izenburua $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Oraindik ez dago ohar azkarrik. Ohar bat hautatu, edo berria '
      'sortu — ohar azkarrak hemen irekitzen da.';
  @override
  String get quickNoteChooseAction => 'Hautatu ohar bat…';
  @override
  String get quickNoteCreateAction => 'Sortu ohar berria…';
  @override
  String get quickNoteNewTitle => 'Ohar azkar berria';
  @override
  String get quickNotePickerTitle => 'Hautatu ohar azkarrak';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Fitxategi-biltegi berria';
  @override
  String get folderPickerEmpty => 'Oraindik ez dago fitxategi-biltegirik';
  @override
  String get listFolderTitle => 'Zerrenda-biltegia';

  // Trash (M1).
  @override
  String get trashEmpty => 'Zaborrontza hutsik dago';
  @override
  String get trashEmptyAction => 'Huts zaborrontza';
  @override
  String get trashEmptyConfirm =>
      'Honek zaborrontzako guztia betirako ezabatuko du, Niman ez zuen '
      'bertan jarriko elementuak ere.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name betirako ezabatuko da (ez dago berrezarriketa)';
  @override
  String get trashDeletePermanently => 'Ezabatu betirako';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Ireki ohar Markdownen fitxategi-biltegi bat biblioteka gisa';
  @override
  String get openLibraryExisting => 'Ireki dagoena';
  @override
  String get openLibraryCreate => 'Sortu berria';
  @override
  String get openLibraryCreateTitle => 'Sortu biblioteka berria';
  @override
  String get openLibraryFolderName => 'Biltegiko izena';
  @override
  String get openLibraryChooseFolder =>
      'Hautatu bibliotekararen fitxategi-biltegia';
  @override
  String get openLibraryChooseParent =>
      'Hautatu fitxategi-biltegia non sortuko den';
  @override
  String get openLibraryUnsupported =>
      'Fitxategi-biltegi hau ez da onartzen. Hautatu gailuaren gordailuko '
      'biltegia.';
  @override
  String indexingCount(int done, int total) => '$total oharretako $done';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Zure bibliotekak';
  @override
  String get libraryUnreachable => 'Ezin da iritsi';
  @override
  String get libraryOpenedToday => 'Gaur irekita';
  @override
  String get libraryOpenedYesterday => 'Atzo irekita';
  @override
  String libraryOpenedDaysAgo(int days) => '$days egunetan itzulita irekita';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Irekita ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Orain zabalik';
  @override
  String get switchLibraryTitle => 'Aldatu biblioteka';
  @override
  String get libraryForget => 'Ahaztu';
  @override
  String libraryForgetTitle(String name) => '“$name” ahaztu?';
  @override
  String get libraryForgetExplained =>
      'Zerrenda honetatik desagertuko da. Fitxategi-biltegia, ohar eta '
      'bibliotekararen ezarpenak ez dira ukitzen, berriro irekitzean '
      'itzuliko da.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Eman fitxategi sarbidea';
  @override
  String get storageAccessNeeded =>
      'Niman ez du zure oharrik irakurri gabe “fitxategi guztietara '
      'sarbidea”. Eman sarbidea biblioteka bat irekitzeko.';
  @override
  String get storageAccessExplained =>
      'Niman zure ohar arruntak irakurtzen du fitxategian, beraz '
      'Android-ek fitxategi guztietara sarbidea eman behar dio. Ezer ez da '
      'igotzen, eta zure hautatutako biblioteka-biltegia bakarrik '
      'irakurtzen da.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistemak ez du fitxategi-biltegiako sarbiderik eman: $error';
  @override
  String folderPickFailed(Object error) =>
      'Ezin izan da fitxategi-biltegi bat hautatu: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Ezarpenak';
  @override
  String get libraryPathTitle => 'Bibliotekararen bidea';
  @override
  String get reindexTitle => 'Berrindekatu orain';
  @override
  String get reindexDone => 'Berrindekatzea amaituta';
  @override
  String get closeLibraryTitle => 'Itxi biblioteka';
  @override
  String get exportLogTitle => 'Esportatu arazte-erregistroa';
  @override
  String get exportLogSubtitle =>
      'Gordetu erregistratutako gertaerak hautatutako fitxategi batean';
  @override
  String get exportLogEmpty => 'Arazte-erregistroaren buffer hutsik dago';
  @override
  String get quickNoteUnset => 'Oraindik ez da ezarrita';
  @override
  String exportLogDone(Object target) =>
      'Arazte-erregistroa $target-ra esportatua';
  @override
  String exportLogFailed(Object error) => 'Esportazioak huts egin du: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '“$term”-en hitz osoko emaitzazko emaitzarik ez da aurkitu';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences “$term”-en ohar $notes ordezkatua';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped ohar zabalik ez zuen kontuan hartu)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '“$term”-en hitz osoko emaitzazko emaitzarik ez da '
      '${only == null ? 'aurkitu' : '$only-n aurkitu'}';
}
