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
  String get trashTitle => 'Zakarrontzia';
  @override
  String get trashSubtitle =>
      'Ezabatzeak .trash/-ra joaten dira (desaktibatuta = betirako ezabatzea)';
  @override
  String get trashAutoEmptyTitle => 'Zakarrontzia automatikoki hustu';
  @override
  String get trashAutoEmptySubtitle =>
      'Ezabaketa zaharrenak betiko desagertzen dira biblioteka irekitzean';
  @override
  String trashAutoEmptyValue(int days) => days == 0 ? 'Inoiz ez' : '$days egun';
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
  String get readableLineLengthTitle => 'Lerro-luzera irakurgarria';
  @override
  String get readableLineLengthSubtitle =>
      'Mantendu oharraren testua zutabe zentratu batean, leihoaren zabalera '
      'osoan beharrean';
  @override
  String get noteColumnWidthTitle => 'Zutabearen zabalera';
  @override
  String get noteColumnWidthSubtitle =>
      'Oharraren zutabearen zabalera, pixeletan';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
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
  String get editorKindSourceSubtitle =>
      'Markdown jatorria, idatzita dagoen bezala';
  @override
  String get editorKindWysiwygSubtitle => 'Formatodun testua, bertan editatua';
  @override
  String get settingsFolderToCreate => 'sortzeke';
  @override
  String get settingsSearchHint => 'Bilatu ezarpenetan';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 ezarpen aurkituta' : '$count ezarpen aurkituta';
  @override
  String get settingsToggleOn => 'Aktibatuta';
  @override
  String get settingsToggleOff => 'Desaktibatuta';
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
  String get switchToSourceLabel => 'Iturria';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteka $name';
  @override
  String get settingsGroupLibraryHint => 'soilik honi balio du';
  @override
  String get settingsGroupMaintenance => 'Mantentze';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Biltegiak eta bideak';
  @override
  String get settingsAreaTrashHistory => 'Zakarrontzia eta kronologia';
  @override
  String get settingsAreaDiagnostics => 'Diagnostika eta info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Konektatutako teklatu fisiko bat behar du';
  @override
  String get settingsSectionUpdates => 'Eguneratzeak';
  @override
  String get autoUpdateTitle => 'Eguneratze automatikoak';
  @override
  String get autoUpdateSubtitle =>
      'Egiaztatu GitHub Releases abiaraztean eta 6 orduro';
  @override
  String get checkForUpdatesTitle => 'Bilatu eguneratzeak';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version erabilgarri dago';
  @override
  String get updateUpToDate => 'Niman eguneratuta dago';
  @override
  String get updateCheckFailed => 'Ezin izan dira eguneratzeak egiaztatu';
  @override
  String updateSavedTo(Object path) => 'Eguneratzea hemen gorde da: $path';
  @override
  String get updateInstallerStarted => 'Instalatzailea abiarazi da';
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
  String get addWordToDictionary => 'Gehitu hiztehirian';

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
  String get missingNoteLocationTitle => 'Falta dagoen oharrak sortu';
  @override
  String get missingNoteLocationRoot => 'Bibliotekaren erroan';
  @override
  String get missingNoteLocationCurrentFolder => 'Uneko karpetan';
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

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Oraindik ez dago grabaziorik';
  @override
  String get audioRecord => 'Grabatu';
  @override
  String get audioStop => 'Gelditu';
  @override
  String get audioPlay => 'Erreproduzitu';
  @override
  String get audioDelete => 'Ezabatu grabazioa';
  @override
  String get audioImport => 'Inportatu audio-fitxategi bat';
  @override
  String get audioRecording => 'Grabatzen…';
  @override
  String get audioPermissionDenied =>
      'Mikrofonoaren baimena ukatu da — grabatzeko beharrezkoa da.';
  @override
  String get newAudioNoteTitle => 'Ahots-ohar berria';
  @override
  String get newAudioNoteDefault => 'Nire grabazioa';
  @override
  String get showAudioTooltip => 'Erakutsi grabazioak';
  @override
  String get audioMessageHint => 'Idatzi ohar bat…';
  @override
  String get audioSend => 'Bidali';
  @override
  String get audioRename => 'Grabazioaren izena aldatu';
  @override
  String get audioDescriptionHint => 'Deskribatu grabazio hau…';
  @override
  String get audioEditDescription => 'Editatu deskribapena';
  @override
  String get audioDeleteNote => 'Ezabatu oharra';
  @override
  String get audioEditNote => 'Editatu oharra';
  @override
  String get audioPause => 'Pausatu';
  @override
  String get audioEditTitle => 'Editatu izenburua';
  @override
  String get audioTitleHint => 'Grabazio honen izenburua…';
  @override
  String audioUntitled(int n) => '$n. grabazioa';
  @override
  String get audioMoreActions => 'Ekintza gehiago';
  @override
  String get audioDiscardRecording => 'Baztertu grabazioa';
  @override
  String get audioPauseRecording => 'Grabazioa pausatu';
  @override
  String get audioResumeRecording => 'Grabazioari berrekin';
  @override
  String get audioRecordingPaused => 'Pausatuta';
  @override
  String get audioSavingRecording => 'Gordetzen…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Ohar azkarra';
  @override
  String get trayOpen => 'Ireki Niman';
  @override
  String get trayQuit => 'Irten';
  @override
  String get closeToTrayTitle => 'Itxi jakinarazpen-eremura';
  @override
  String get closeToTraySubtitle =>
      'Leihoaren × Niman ezkutatzen du eta martxan uzten, oroigarriak iristen '
      'jarraitzeko. Ikonoaren menutik irteten da.';
  @override
  String get shortcutNewTodo => 'Zeregin berria';
  @override
  String get shortcutNewNote => 'Ohar berria';
  @override
  String get shortcutNewList => 'Zerrenda berria';
  @override
  String get shortcutNewAudio => 'Ahots-ohar berria';
  @override
  String get shortcutToggleSidebar => 'Ezkutatu edo erakutsi iragazkia';
  @override
  String get shortcutCloseTab => 'Itxi uneko oharra';
  @override
  String get shortcutNextTab => 'Hurrengo ohar irekia';
  @override
  String get shortcutPreviousTab => 'Aurreko ohar irekia';
  @override
  String get shortcutEditorSection => 'Erreditoran';
  @override
  String get shortcutFormatSection => 'Formatua';
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
  String get noteStatusLoading => 'Kargatzen…';
  @override
  String get noteStatusSaving => 'Gordetzen…';
  @override
  String get noteStatusUnsaved => 'Gorde gabe';
  @override
  String get noteStatusSaved => 'Gordeta';
  @override
  String get noteStatusError => 'Errorea';
  @override
  String get noteNotText =>
      'Fitxategi hau ez da testu-ohar bat, beraz '
      'Nimanek ezin du hemen erakutsi.';
  @override
  String get noteLoadFailed => 'Ezin izan da ohar hau ireki.';
  @override
  String wordCount(int count) => '$count hitz';
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

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Tresnak';
  @override
  String get editorToolsTitle => 'Editorearen tresnak';
  @override
  String get toolCountListTitle => 'Zerrenda zenbatu';
  @override
  String get toolCountListSubtitle =>
      'Errenkadek zerrendatzen dutena batzen du, egiaztapen-zerrenda gisa';
  @override
  String get toolCountListNeedsList =>
      'Ohar honek ez du zerrendarik zenbatzeko';
  @override
  String get tallySourceLabel => 'Zerrenda';
  @override
  String get tallyCutLabel => 'Irakurri errenkada bakoitza honela';
  @override
  String get tallyCutDash => 'Izena - balioak';
  @override
  String get tallyCutColon => 'Izena: balioak';
  @override
  String get tallyCutCommas => 'Komaz bereizitako balioak';
  @override
  String get tallyCutWhole => 'Errenkada osoa, balio bakar gisa';
  @override
  String get tallySortLabel => 'Ordena';
  @override
  String get tallySortCount => 'Gehien lehenik';
  @override
  String get tallySortAlphabetical => 'Alfabetikoki';
  @override
  String get tallySortFirstSeen => 'Zerrendan bezala';
  @override
  String get tallyInsert => 'Txertatu';
  @override
  String get tallyUpdate => 'Eguneratu';
  @override
  String get tallyNothingToCount => 'Hemen ez dago ezer zenbatzeko';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Oharra ez dago';
  @override
  String missingNoteDialogBody(String path) => '«$path» sortu?';
  @override
  String missingNoteFolderMissing(String folder) =>
      '«$folder» karpetak ez dago';

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
  String get newItemTooltip => 'Berria';
  @override
  String get closeMenuTooltip => 'Itxi';
  @override
  String get newFolderTitle => 'Karpeta berria';
  @override
  String get newNoteSameFolder => 'Ohar berria karpeta berean';
  @override
  String get newFromTemplateSameFolder => 'Txantiloitik berria karpeta berean';
  @override
  String trashOriginalPath(String path) => 'hemen zegoen: $path';
  @override
  String get trashOriginalRoot => 'liburutegiaren erroan zegoen';
  @override
  String trashItemCount(int count) =>
      count == 1 ? 'elementu 1' : '$count elementu';
  @override
  String get newNoteHere => 'Ohar berria hemen';
  @override
  String get newFolderHere => 'Karpeta berria hemen';
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
  String get templateHelpSubtitle =>
      'Data, izenburua eta bete beharreko gainerako balioak';
  @override
  String get quickNoteSubtitle => 'Ohar azkar fitxak irekitzen duen oharra';
  @override
  String get listFolderSubtitle => 'Eginkizun-zerrenda berriak';
  @override
  String get templateFolderSubtitle => '«Txantiloitik berria»-ren iturria';
  @override
  String get attachmentsFolderSubtitle =>
      'Oharrean txertatutako irudiak eta audioa';
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
  String get pinToWidget => 'Festu hasierako widgetean';
  @override
  String get pinnedForWidget =>
      'Festuta: jarri orain Oharraren widgeta hasierako pantailan';
  @override
  String get pinWidgetUnavailable =>
      'Hasierako pantailako widgetak Android-en daude eskuragarri';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Erakutsi fitxategi-kudeatzailean';
  @override
  String get openInDefaultApp => 'Ireki aplikazio lehenetsian';
  @override
  String get newNoteTabTooltip => 'Ohar berria fitxa berrian';
  @override
  String get openNotesTooltip => 'Ohar irekiak';
  @override
  String get closeTabTooltip => 'Itxi';
  @override
  String get openInNewTab => 'Ireki fitxa berrian';
  @override
  String get splitRight => 'Zatitu eskuinera';
  @override
  String get splitDown => 'Zatitu behera';
  @override
  String get moveToOtherPane => 'Eraman beste panelera';
  @override
  String get openBeside => 'Ireki alboan';
  @override
  String get closeAllNotes => 'Itxi guztiak';
  @override
  String get sidePanelTooltip => 'Erakutsi edo ezkutatu alboko panela';
  @override
  String get historyAllVersions => 'Bertsio guztiak';
  @override
  String get commandPaletteTitle => 'Komando-paleta';
  @override
  String get goToNoteTitle => 'Joan oharrera';
  @override
  String get paletteGroupNote => 'Oharra';
  @override
  String get paletteGroupEditor => 'Editorea';
  @override
  String get paletteGroupView => 'Ikuspegia';
  @override
  String get paletteGroupLibrary => 'Liburutegia';
  @override
  String get paletteGroupGoTo => 'Joan';
  @override
  String get paletteGroupJournal => 'Egunkaria';
  @override
  String get journalToday => 'Gaurko sarrera';
  @override
  String get journalPrevious => 'Aurreko sarrera';
  @override
  String get journalNext => 'Hurrengo sarrera';
  @override
  String get commandNeedJournalEntry => 'Egunkariko sarrera bat ireki behar da';
  @override
  String journalCreateAsk(String day) =>
      'Oraindik ez dago sarrerarik $day egunerako. Sortu?';
  @override
  String journalTemplateMissing(String path) =>
      'Ezin izan da $path egunkari-txantiloia irakurri: sarrera hura gabe '
      'sortu da.';
  @override
  String get journalIntro =>
      'Ohar bat egun bakoitzeko, txantiloi batetik sortua egun hori lehen '
      'aldiz irekitzean. Ezarpen hauek liburutegiarekin bidaiatzen dute.';
  @override
  String get journalFolderTitle => 'Egunkariaren karpeta';
  @override
  String get journalFolderSubtitle => 'Sarrerak nora doazen';
  @override
  String get journalEntryNameTitle => 'Sarreraren izena';
  @override
  String get journalEntryNameSubtitle =>
      "YYYY, MM edo M, DD edo D datarako; / karpeta bat sortzen du; 'komatxo "
      "arteko' testua dagoen bezala geratzen da";
  @override
  String journalEntryNamePreview(String path) => 'Gaurko sarrera: $path';
  @override
  String get journalEntryNameInvalid =>
      'YYYY, hilabete bat (MM edo M) eta egun bat (DD edo D) behar ditu, eta '
      'fitxategi-izen batek eduki ezin duen ezer ez';
  @override
  String get journalTemplateTitle => 'Txantiloia';
  @override
  String get journalTemplateSubtitle => 'Zerekin hasten den sarrera berri bat';
  @override
  String get journalTemplateNone => 'Bat ere ez: data duen izenburua';
  @override
  String get journalDayStartTitle => 'Egun berria ordu honetan hasten da';
  @override
  String get journalDayStartSubtitle =>
      'Berandu? 04:00etan gaua aurreko egunean geratzen da';
  @override
  String get journalRecent => 'Azkenak';
  @override
  String get journalNoEntry => 'Ez dago sarrerarik egun honetarako';
  @override
  String get journalOpenEntry => 'Ireki';
  @override
  String get journalShowCalendar => 'Erakutsi egutegia';
  @override
  String get journalFabToday => 'Egunkariko gaurko sarrera';
  @override
  String journalDueOn(String day) => 'Epea: $day';
  @override
  String get commandsTitle => 'Komandoak';
  @override
  String get commandsIntro =>
      'Komando-paletak zauden lekuan exekutatu daitezkeen komandoak soilik '
      'eskaintzen ditu. Hemen daude guztiak, eta noiz agertzen den bakoitza.';
  @override
  String get commandNeedNone => 'Beti erabilgarri';
  @override
  String get commandNeedOpenNote => 'Ohar ireki bat behar du';
  @override
  String get commandNeedWideWindow => 'Leiho zabalean soilik';
  @override
  String get commandNeedDockRoom =>
      'Alboko panelerako adina zabala den leihoa behar du';
  @override
  String get commandNeedDesktop => 'Mahaigainean soilik';
  @override
  String get commandNeedNotInZen => 'Ez Zen moduan';
  @override
  String get commandNeedZenRoom => 'Mahaigaina, ohar bat fitxa batean irekita';
  @override
  String get commandNeedPreview => 'Aurrebista aktibatuta, testu-ohar batean';
  @override
  String get commandNeedTwoEditors => 'Bi editoreak gaituta';
  @override
  String get paletteHint => 'Bilatu komandoak eta oharrak';
  @override
  String get paletteNoResults => 'Ez dago bat datorrenik';
  @override
  String get paletteCommands => 'Komandoak';
  @override
  String get paletteNotes => 'Oharrak';
  @override
  String get paletteFooter => '↑↓ mugitzeko · ↵ erabiltzeko · esc ixteko';
  @override
  String get paletteFooterTouch =>
      'Ukitu erabiltzeko · iltzeak goian mantentzen du';
  @override
  String get palettePinned => 'Ainguratuta';
  @override
  String get palettePin => 'Ainguratu';
  @override
  String get paletteUnpin => 'Askatu';
  @override
  String get palettePinFooter => 'alt+P ainguratzeko';
  @override
  String get spellCheckScanning => 'Oharra egiaztatzen…';
  @override
  String get spellCheckAgain => 'Egiaztatu berriro';
  @override
  String spellCheckCapped(int count) =>
      'Lehen ${count}ak ageri dira: zuzendu batzuk eta egiaztatu berriro '
      'gainerakoak ikusteko';
  @override
  String get dropHint =>
      'Askatu Markdown fitxategiak irekitzeko, edo karpeta bat inportatzeko';
  @override
  String get dropNothing =>
      'Mahaigainak ez du fitxategirik eman arrastatze horretan.';
  @override
  String get importFolderAction => 'Inportatu';
  @override
  String dropRejected(String names) =>
      'Hemen Markdown fitxategiak eta karpetak soilik irekitzen dira: $names';
  @override
  String importFolderTitle(String name) => '«$name» inportatu?';
  @override
  String importFolderBody(int count) =>
      'Bere Markdown fitxategiak ($count) liburutegiko karpeta berri batera '
      'kopiatzen dira. Askatutako karpeta dagoen bezala geratzen da.';
  @override
  String importFolderDone(String folder) => '$folder karpetara inportatua';
  @override
  String importFolderEmpty(String name) =>
      'Ez dago Markdown fitxategirik $name karpetan';
  @override
  String get openFileTitle => 'Ireki fitxategia';
  @override
  String get outsideFileNote =>
      'Liburutegitik kanpo: dagoen tokian gordetzen da, indexatu gabe, '
      'historiarik gabe, estekak ez dira jarraitzen';
  @override
  String get typewriterOn => 'Aktibatu idazmakina modua';
  @override
  String get typewriterOff => 'Desaktibatu idazmakina modua';
  @override
  String get typewriterTitle => 'Idazmakina modua';
  @override
  String get formatNoteTitle => 'Markdown txukundu';
  @override
  String get formatNoteDone => 'Oharra txukundu da.';
  @override
  String get formatNoteAlreadyTidy => 'Oharra txukun zegoen jada.';
  @override
  String get typewriterSubtitle =>
      'Idazten ari zaren lerroa editorearen erdian mantentzen da';
  @override
  String get zenMode => 'Zen modua';
  @override
  String get zenModeEnter => 'Sartu zen moduan';
  @override
  String get zenModeLeave => 'Irten zen modutik';
  @override
  String get keySpace => 'Zuriunea';
  @override
  String get keyEnter => 'Sartu';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Atzera';
  @override
  String get keyDelete => 'Ezabatu';
  @override
  String get keyArrowUp => 'Gora';
  @override
  String get keyArrowDown => 'Behera';
  @override
  String get keyArrowLeft => 'Ezkerrera';
  @override
  String get keyArrowRight => 'Eskuinera';
  @override
  String get keyHome => 'Hasiera';
  @override
  String get keyEnd => 'Amaiera';
  @override
  String get keyPageUp => 'Orri gora';
  @override
  String get keyPageDown => 'Orri behera';
  @override
  String get keyInsert => 'Txertatu';
  @override
  String get shortcutNone => 'Lasterbiderik ez';
  @override
  String get shortcutRestoreDefaults => 'Berrezarri lehenetsiak';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Lasterbide guztiak Nimanek dakartzan bezala jarri?';
  @override
  String get shortcutRevert => 'Itzuli lehenetsira';
  @override
  String get shortcutClear => 'Kendu lasterbidea';
  @override
  String get shortcutCapturePrompt =>
      'Sakatu teklak. Esc eta Tab ere hartzen dira: irten Utzi botoiarekin.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Gehitu Ctrl, Alt edo Meta: tekla bakarra idazteko da.';
  @override
  String get shortcutMove => 'Mugitu';
  @override
  String get shortcutUseAnyway => 'Erabili hala ere';
  @override
  String get shortcutUndo => 'Desegin';
  @override
  String get shortcutRedo => 'Berregin';
  @override
  String get shortcutChange => 'Aldatu lasterbidea';
  @override
  String shortcutCaptureTitle(String command) => 'Teklak: $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys dagoeneko $other-ena da. Hona mugitu? $other lasterbiderik gabe '
      'geratuko da.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys ere $what da testu-eremuetan eta editorean. Han zure komandoak '
      'hartuko du.';
  @override
  String get openFileMissing => 'Ohar honen fitxategia ez dago diskoan';
  @override
  String get openFileFailed => 'Ezin izan da ohar hau Nimanetik kanpo ireki';

  @override
  String get movedToTrash => 'Zakarrontzira mugitua';
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
  String get folderPickerNewFolder => 'Karpeta berria';
  @override
  String get folderPickerEmpty => 'Oraindik ez dago karpetarik';
  @override
  String get listFolderTitle => 'Zerrenda-biltegia';
  @override
  String get attachmentsFolderTitle => 'Eranskinen biltegia';

  // Trash (M1).
  @override
  String get trashEmpty => 'Zakarrontzia hutsik dago';
  @override
  String get trashEmptyAction => 'Hustu zakarrontzia';
  @override
  String get trashEmptyConfirm =>
      'Honek zakarrontziko guztia betirako ezabatuko du, Niman ez zuen '
      'bertan jarriko elementuak ere.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name betirako ezabatuko da (ez dago berrezarriketa)';
  @override
  String get trashDeletePermanently => 'Ezabatu betirako';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Ireki ohar Markdownen karpeta bat biblioteka gisa';
  @override
  String get openLibraryExisting => 'Ireki dagoena';
  @override
  String get openLibraryCreate => 'Sortu berria';
  @override
  String get openLibraryCreateTitle => 'Sortu biblioteka berria';
  @override
  String get openLibraryFolderName => 'Biltegiko izena';
  @override
  String get openLibraryChooseFolder => 'Hautatu bibliotekaren karpeta';
  @override
  String get openLibraryChooseParent => 'Hautatu karpeta non sortuko den';
  @override
  String get openLibraryUnsupported =>
      'Karpeta hau ez da onartzen. Hautatu gailuaren gordailuko '
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
      'Zerrenda honetatik desagertuko da. Karpeta, oharrak eta '
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
      'Sistemak ez du karpetarako sarbiderik eman: $error';
  @override
  String folderPickFailed(Object error) =>
      'Ezin izan da karpeta bat hautatu: $error';

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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Informazioa';
  @override
  String get versionTitle => 'Bertsioa';
  @override
  String get changelogTitle => 'Aldaketen erregistroa';
  @override
  String get changelogEmpty => 'Ez dago aldaketa-sarerik';
  @override
  String changelogWhatsNew(String version) => 'Berria $version bertsioan';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historia';
  @override
  String get noteMenuTooltip => 'Oharraren ekintzak';
  @override
  String get historyCurrentVersion => 'Uneko bertsioa';
  @override
  String get historyCurrentSubtitle => 'Oharra orain dagoen bezala';
  @override
  String get historyToday => 'Gaur';
  @override
  String get historyYesterday => 'Atzo';
  @override
  String get historyReasonSession => 'editatu aurretik';
  @override
  String get historyReasonInterval => 'editatzean';
  @override
  String get historyReasonRestore => 'berrezarri aurretik';
  @override
  String get historyReasonSync => 'sinkronizatu aurretik';
  @override
  String get historyReasonReplace => 'ordezkatu aurretik';
  @override
  String get historyReasonUnknown => 'berreskuratua';
  @override
  String get historySyncBase => 'sinkronizazio-oinarria';
  @override
  String get historyEmpty =>
      'Oraindik ez dago bertsiorik. Niman-ek bat gordetzen du oharra '
      'editatzen hasten zarenean, eta gero, gehienez, bat minutu gutxiro '
      'idazten duzun bitartean.';
  @override
  String historyKept(int kept, int limit) => '$kept/$limit bertsio gordeta';
  @override
  String get historyBaseKept =>
      'Sinkronizazio-oinarria mugaz gain ere gordetzen da.';
  @override
  String get historyOff =>
      'Historia desaktibatuta dago biblioteka honetan '
      '(Ezarpenak, Biblioteka).';
  @override
  String get historyLoadFailed => 'Ezin izan da historia irakurri';
  @override
  String get historyCompareSubtitle => 'Uneko bertsioarekin alderatuta';
  @override
  String get historyTabChanges => 'Aldaketak';
  @override
  String get historyTabVersion => 'Bertsioa';
  @override
  String get historyNoChanges => 'Uneko bertsioaren testu bera.';
  @override
  String get historyRestoreAction => 'Berrezarri bertsio hau';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Berrezarri bertsio hau ($when)?';
  @override
  String get historyRestoreConfirmBody =>
      'Uneko testua historian gordetzen da lehenik, beraz beti itzul '
      'zaitezke atzera.';
  @override
  String get historyRestoreConfirm => 'Berrezarri';
  @override
  String historyRestored(String when) => 'Bertsioa ($when) berrezarri da';
  @override
  String get historyRestoreFailed => 'Ezin izan da bertsioa berrezarri';
  @override
  String get actionUndo => 'Desegin';
  @override
  String diffLineRange(int start, int end) => 'Lerroak $start–$end';
  @override
  String diffLineSingle(int line) => 'Lerroa $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? 'lerro 1 aldatu gabe' : '$count lerro aldatu gabe';
  @override
  String get historyTakeHunk => 'Berrezarri hemen';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Berrezarri aldaketa 1' : 'Berrezarri $count aldaketa';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Aukeratutako aldaketak bertsio honen testura itzultzen dira. Oharra '
      'dagoen moduan bertsio gisa gordetzen da lehenik, beraz desegin '
      'dezakezu.';
  @override
  String get historyNoteChangedReloaded =>
      'Oharra aldatu egin da hemen zeunden bitartean — konparazioa eguneratu '
      'da.';
  @override
  String get historyVersionsTitle => 'Gorde beharreko bertsioak';
  @override
  String get historyVersionsSubtitle => 'Ohar bakoitzeko, .history/ karpetan';
  @override
  String historyVersionsValue(int count) =>
      count == 0 ? 'Bat ere ez' : '$count';
  @override
  String get historyIntervalTitle => 'Bertsio berrien arteko tarte txikiena';
  @override
  String get historyIntervalSubtitle =>
      'Idazten duzun bitartean; ohar bat editatzen hastean beti gordetzen '
      'da bat';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkripzioa';
  @override
  String get transcriptionModelTitle => 'Eredua';
  @override
  String get transcriptionModelNone => 'Bat ere ez';
  @override
  String get transcriptionLanguageTitle => 'Hizkuntza';
  @override
  String get transcriptionLanguageSubtitle =>
      'Grabazioetan hitz egiten den hizkuntza. Zehaztea automatikoki '
      'hautematea baino zehatzagoa da.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Aplikazioaren berdina ($language)';
  @override
  String get transcriptionLanguageDetect => 'Hauteman automatikoki';
  @override
  String get transcriptionModelsTitle => 'Transkripzio-ereduak';
  @override
  String transcriptionModelsUsed(String size) => '$size erabilita';
  @override
  String get transcriptionModelsInstalled => 'Deskargatuak';
  @override
  String get transcriptionModelsDownloading => 'Deskargatzen';
  @override
  String get transcriptionModelsAvailable => 'Erabilgarri';
  @override
  String get transcriptionModelsFooter =>
      'Ereduak gailu honetako aplikazioaren biltegian geratzen dira. Ez dira '
      'liburutegira kopiatzen, ezta sinkronizatzen ere.';
  @override
  String get transcriptionModelDefault => 'Lehenetsia';
  @override
  String get transcriptionModelSlow => 'Motela';
  @override
  String get transcriptionModelHintTiny => 'Azkarrena, zehaztasun txikienekoa';
  @override
  String get transcriptionModelHintBase =>
      'Abiaduraren eta zehaztasunaren arteko oreka ona';
  @override
  String get transcriptionModelHintSmall => 'Zehatzagoa, 3× inguru motelagoa';
  @override
  String get transcriptionModelHintMedium => 'Oso zehatza, motela telefonoan';
  @override
  String get transcriptionModelHintLarge => 'Zehatzena, memoria asko behar du';
  @override
  String get transcriptionModelDownload => 'Deskargatu';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      '$model eredua ezabatu?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      '$size askatuko dira. Eredua geroago berriro deskarga dezakezu.';
  @override
  String get transcriptionModelFailed =>
      'Ezin izan da deskargatu. Egiaztatu konexioa eta saiatu berriro.';
  @override
  String get actionRetry => 'Saiatu berriro';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Konexioa galdu da, berriro saiatzen…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pausatuta: $progress';
  @override
  String get actionResume => 'Jarraitu';
  @override
  String get audioTranscribe => 'Transkribatu';
  @override
  String get audioTranscribeUnsupported =>
      'WAV grabazioak soilik gailu honetan';
  @override
  String get transcriptionQueued => 'Ilaran';
  @override
  String get transcriptionPreparing => 'Audioa prestatzen…';
  @override
  String transcriptionRunning(int percent) => 'Transkribatzen… % $percent';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model deskargatzen · % $percent';
  @override
  String get transcriptionSaved => 'Transkripzioa deskribapenari gehitu zaio';
  @override
  String get transcriptionNoSpeech =>
      'Ez da hizketarik hauteman grabazio honetan';
  @override
  String get transcriptionFailed => 'Ezin izan da transkribatu';
  @override
  String get transcriptionPickModelTitle => 'Aukeratu eredu bat';
  @override
  String get transcriptionPickModelBody =>
      'Transkripzioa gailu honetan egiten da eta grabazioa ez da inoiz '
      'igotzen. Eredua behin bakarrik deskargatzen da.';
  @override
  String get transcriptionPickModelAction => 'Deskargatu eta transkribatu';
  @override
  String get transcriptionModelRecommended => 'Gomendatua';
  @override
  String get transcriptionExistingTitle => 'Grabazio honek badu deskribapena';
  @override
  String get transcriptionExistingBody =>
      'Transkripzioarekin ordeztu, edo transkripzioa azpian gehitu?';
  @override
  String get transcriptionAppend => 'Gehitu azpian';
  @override
  String get transcriptionReplace => 'Ordeztu';
  @override
  String get settingsSectionSync => 'Sinkronizazioa';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Ez dago konfiguratuta biblioteka honetarako';
  @override
  String get syncNeverSynced => 'Inoiz ez da sinkronizatu';
  @override
  String syncLastSynced(String when) => 'Sinkronizatuta: $when';
  @override
  String get syncRunning => 'Sinkronizatzen…';
  @override
  String syncScreenSubtitle(String library) => '$library biblioteka';
  @override
  String get syncUrlLabel => 'Karpetaren helbidea';
  @override
  String get syncUrlRequired => 'Sartu zerbitzariaren helbidea';
  @override
  String get syncUrlHint =>
      'Karpetak existitu behar du. Kopiatu helbidea zerbitzariak '
      'erakusten duen bezala.';
  @override
  String get syncHttpWarning =>
      'Zifratu gabeko konexioa: ondo dago VPN baten bidez edo '
      'sare lokalean.';
  @override
  String get syncUserLabel => 'Erabiltzailea';
  @override
  String get syncUserHint =>
      'Utzi hutsik zerbitzariak kredentzialik eskatzen ez badu.';
  @override
  String get syncPasswordLabel => 'Pasahitza';
  @override
  String get syncPasswordHint =>
      'Gailu honen giltzatakoan gordetzen da, inoiz ez '
      'bibliotekako fitxategietan.';
  @override
  String get syncPasswordKeepHint =>
      'Utzi hutsik gordetako pasahitza mantentzeko.';
  @override
  String get syncShowPassword => 'Erakutsi pasahitza';
  @override
  String get syncHidePassword => 'Ezkutatu pasahitza';
  @override
  String get syncTestAction => 'Probatu konexioa';
  @override
  String get syncTesting => 'Probatzen…';
  @override
  String get syncRetargetWarning =>
      'Beste helbide edo erabiltzaile batekin, hurrengo '
      'sinkronizazioa lehen sinkronizazio gisa hasiko da berriro.';
  @override
  String get syncTestOk => 'Konexioak funtzionatzen du';
  @override
  String get syncModeFull => 'Modu osoa';
  @override
  String get syncModeCompatible => 'Modu bateragarria';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Irakurri, idatzi eta ezabatu';
  @override
  String get syncCapEtags => 'Fitxategien hatz-markak (ETag)';
  @override
  String get syncCapNoEtags => 'Fitxategien hatz-markarik ez (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Tamaina eta data alderatzen ditut; zalantzarik badago, '
      'berriro deskargatzen dut';
  @override
  String get syncCapGuarded => 'Idazketa babestuak';
  @override
  String get syncCapUnguarded => 'Babesik gabeko idazketak';
  @override
  String get syncCapUnguardedDetail =>
      'Zerbitzariko fitxategia egiaztatzen dut idatzi baino lehen';
  @override
  String get syncCapMove => 'Izena aldatzen du berriro igo gabe';
  @override
  String get syncCapNoMove => 'Ez da izenik aldatzen zerbitzarian';
  @override
  String get syncCapNoMoveDetail =>
      'Izen-aldaketa bat ezabatze eta igoera berri bihurtzen da';
  @override
  String get syncCompatibleNote =>
      'Modu bateragarrian sinkronizazioak berdin funtzionatzen '
      'du, eskaera batzuk gehiagorekin.';
  @override
  String get syncTestInvalidUrl => 'Helbidea ez da baliozkoa';
  @override
  String get syncTestInvalidUrlHint =>
      'Idatzi http:// edo https:// helbide bat, erabiltzailerik '
      'eta pasahitzik gabe.';
  @override
  String get syncTestOffline => 'Ezin da zerbitzarira iritsi';
  @override
  String get syncTestOfflineHint =>
      'VPNa aktibatuta dago? 10.x edo 192.168.x helbide batek '
      'sare beretik bakarrik funtzionatzen du.';
  @override
  String get syncTestAuth => 'Erabiltzailea edo pasahitza baztertu da';
  @override
  String get syncTestAuthHint => 'Egiaztatu, eta probatu berriro.';
  @override
  String get syncTestNotFound => 'Karpeta ez da existitzen';
  @override
  String get syncTestNotFoundHint => 'Sortu zerbitzarian edo zuzendu helbidea.';
  @override
  String get syncTestUnsupported => 'Ez da WebDAV karpeta bat';
  @override
  String get syncTestUnsupportedHint =>
      'Zerbitzariak erantzuten du, baina ez WebDAV gisa.';
  @override
  String get syncTestFailed => 'Probak ez du funtzionatu';
  @override
  String get syncNowAction => 'Sinkronizatu orain';
  @override
  String get syncSectionServer => 'Zerbitzaria';
  @override
  String get syncServerRow => 'Helbidea, erabiltzailea eta pasahitza';
  @override
  String get syncRetestTitle => 'Probatu zerbitzaria berriro';
  @override
  String syncProbedAgo(String when) => 'Azken proba: $when';
  @override
  String get syncDisconnectTitle => 'Deskonektatu biblioteka hau';
  @override
  String get syncDisconnectSubtitle =>
      'Fitxategiak hemen eta zerbitzarian geratzen dira';
  @override
  String get syncDisconnectConfirmTitle => 'Sinkronizazioa deskonektatu?';
  @override
  String get syncDisconnectConfirmBody =>
      'Biblioteka hau ez da gehiago sinkronizatuko gailu '
      'honetan. Ez da fitxategirik ezabatzen, ez hemen ez '
      'zerbitzarian. Berriro konektatzen baduzu, lehen '
      'sinkronizazioa hasieratik hasiko da.';
  @override
  String get syncDisconnectConfirm => 'Deskonektatu';
  @override
  String get syncFirstTitle => 'Lehen sinkronizazioa';
  @override
  String get syncFirstIntro =>
      'Biblioteka zerbitzariko karpetarekin alderatu dut:';
  @override
  String get syncFirstUpload => 'Igotzeko';
  @override
  String get syncFirstDownload => 'Deskargatzeko';
  @override
  String get syncFirstBoth => 'Bi aldeetan';
  @override
  String get syncFirstBothHint =>
      'Berdinak: transferentziarik ez. Desberdinak: ebazteko';
  @override
  String get syncFirstNoDelete =>
      'Lehen sinkronizazioak ez du ezer ezabatzen, ez hemen ez '
      'zerbitzarian.';
  @override
  String get syncStartAction => 'Hasi';
  @override
  String syncMassTrashTitle(int count) =>
      '$count fitxategi zaborrontzara mugitu?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Sinkronizatutako $total fitxategietatik $count falta dira '
      'zerbitzarian. Normalean helbide okerra, muntatu gabeko '
      'NAS diskoa edo nahi gabe hustutako karpeta bat esan nahi '
      'du.';
  @override
  String get syncMassTrashHint =>
      'Beste gailu batean benetan ezabatu badituzu, berretsi: '
      'hemen zaborrontzara joango dira.';
  @override
  String get syncMassTrashConfirm => 'Mugitu zaborrontzara';
  @override
  String syncMassDeleteTitle(int count) =>
      '$count fitxategi zerbitzaritik ezabatu?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Sinkronizatutako $total fitxategietatik $count falta dira '
      'hemen. Zuk ezabatu ez badituzu, utzi eta egiaztatu '
      'bibliotekaren karpeta.';
  @override
  String get syncMassDeleteConfirm => 'Ezabatu zerbitzaritik';
  @override
  String get syncTooltip => 'Sinkronizatu';
  @override
  String get syncStageConnecting => 'Zerbitzarira konektatzen…';
  @override
  String get syncStageComparing => 'Zerbitzariarekin alderatzen…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sinkronizatzen · $done / $total';
  @override
  String get syncStatusWarnings => 'Abisuekin sinkronizatuta';
  @override
  String syncConflictsHeader(int count) =>
      'Hemen eta zerbitzarian aldatuak · $count';
  @override
  String get syncConflictHint => 'Bi bertsioetako bat ere ez da ukitu';
  @override
  String get syncResolveAction => 'Ebatzi';
  @override
  String syncFailuresHeader(int count) => 'Sinkronizatu gabeak · $count';
  @override
  String get syncFailuresHint => 'Hurrengo sinkronizazioan saiatuko da berriro';
  @override
  String get syncAbortAuth => 'Zerbitzariak pasahitza baztertu du';
  @override
  String get syncAbortMissingPassword => 'Ez dago pasahitzik gordeta';
  @override
  String get syncAbortOffline => 'Ezin da zerbitzarira iritsi';
  @override
  String get syncAbortRemoteMissing => 'Zerbitzariko karpeta ez dago jada';
  @override
  String get syncAbortUnsupported =>
      'Zerbitzariak ez du jada WebDAV gisa funtzionatzen';
  @override
  String get syncAbortFailed => 'Sinkronizazioak ez du funtzionatu';
  @override
  String get syncAbortNotConfirmed => 'Sinkronizazioa bertan behera utzi da';
  @override
  String get syncAbortNothingTouched =>
      'Ez da fitxategirik ukitu. Zure aldaketak hemen geratzen '
      'dira hurrengo sinkronizazio arrakastatsura arte.';
  @override
  String syncLastSuccess(String when) =>
      'Azken sinkronizazio arrakastatsua: $when';
  @override
  String get syncNoSuccessYet =>
      'Oraindik ez da sinkronizazio arrakastatsurik egon';
  @override
  String get syncUpdatePasswordAction => 'Eguneratu pasahitza';
  @override
  String get syncRetryAction => 'Saiatu berriro';
  @override
  String get syncOpenSettingsAction => 'Ezarpenak';
  @override
  String get syncCloseAction => 'Itxi';
  @override
  String get syncDoneSnack => 'Sinkronizatuta';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sinkronizatuta · beste nonbait ezabatutako fitxategi 1 '
            'zaborrontzan dago'
      : 'Sinkronizatuta · beste nonbait ezabatutako $count '
            'fitxategi zaborrontzan daude';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sinkronizatuta · gatazka 1 ebazteko'
      : 'Sinkronizatuta · $count gatazka ebazteko';
  @override
  String get syncShowAction => 'Erakutsi';
  @override
  String get syncConflictTitle => 'Ebatzi gatazka';
  @override
  String get syncConflictLegend =>
      '− markadun lerroak zerbitzarikoak dira, eta + markadunak '
      'gailu honetakoak.';
  @override
  String get syncConflictBinary =>
      'Ez da testu-fitxategi bat: aukeratu zein kopia gorde.';
  @override
  String get syncConflictKeepNote =>
      'Gordetzen ez duzun kopia oharraren historian geratzen da.';
  @override
  String get syncKeepLocal => 'Gorde gailu honetakoa';
  @override
  String get syncKeepRemote => 'Gorde zerbitzarikoa';
  @override
  String get syncConflictIdentical => 'Bi bertsioak berdinak dira';
  @override
  String get syncConflictLoadFailed => 'Ezin izan dira bi bertsioak irakurri';
  @override
  String get syncResolveFailed => 'Ezin izan da gatazka ebatzi';
  @override
  String get syncResolved => 'Gatazka ebatzita';
  @override
  String get syncSectionWhen => 'Noiz sinkronizatu';
  @override
  String get syncAutoTitle => 'Automatikoki';
  @override
  String get syncAutoSubtitle => 'Aldaketen ondoren, irekitzean eta tarteka';
  @override
  String get syncIntervalTitle => 'Zerbitzaria egiaztatzeko maiztasuna';
  @override
  String get syncIntervalSubtitle =>
      'Aplikazioa irekita dagoen bitartean bakarrik';
  @override
  String get syncIntervalDialogBody =>
      'Beste gailu batzuetan egindako aldaketak ikusteko, aplikazioa irekita '
      'dagoen bitartean. “Inoiz ez” aukerarekin, aldaketen ondoren eta '
      'irekitzean bakarrik.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? 'minutu 1' : '$count minutu';
  @override
  String get syncIntervalNever => 'Inoiz ez';
  @override
  String get syncWifiOnlyTitle => 'Wi-Fi bidez bakarrik';
  @override
  String get syncWifiOnlySubtitle =>
      'Datu mugikorrekin, sinkronizatu eskuz bakarrik';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? 'aldaketa 1 zain' : '$count aldaketa zain';
  @override
  String syncRetryIn(String wait) => '$wait barru berriro saiatuko da';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Wi-Fi zain';
  @override
  String get syncWaitingForNetwork => 'Konexioaren zain';
  @override
  String get syncMobileDataHint =>
      '“Sinkronizatu orain” aukerak datu mugikorrak erabiltzen ditu hala ere.';
  @override
  String get syncQueueKeptHint =>
      'Aldaketak hemen geratzen dira, aplikazioa ixten baduzu ere, eta berez '
      'bidaltzen dira zerbitzariak erantzuten duenean.';
  @override
  String get syncAutoPaused => 'Sinkronizazio automatikoa pausatuta';
  @override
  String get syncPausedAuthHint =>
      'Pasahitza eguneratzean edo eskuz sinkronizatzean berriro abiatuko da.';
  @override
  String get syncPausedServerHint =>
      'Helbidea zuzentzean edo eskuz sinkronizatzean berriro abiatuko da.';
  @override
  String get syncPausedConfirmHint =>
      '“Sinkronizatu orain” aukerak zer kenduko litzatekeen erakusten du eta '
      'aurretik galdetzen du.';
  @override
  String get syncNeedsConfirmation => 'Zure berrespenaren zain';
  @override
  String get syncMergeIntro =>
      'Gainjartzen ez diren aldaketak jada batuta daude; gainjartzen direnetan '
      'aukeratu zer gorde.';
  @override
  String get syncMergeClean =>
      'Bi bertsioak berez batzen dira: ez da ezer gainjartzen.';
  @override
  String get syncMergeNoBase =>
      'Ez dago bertsio komunik batzeko, beraz fitxategi osoa aukeratu behar '
      'da.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Gainjartzea $index / $total';
  @override
  String get syncMergeFromLocal => 'Gailu honetakoa';
  @override
  String get syncMergeFromRemote => 'Zerbitzarikoa';
  @override
  String get syncMergeRemovedLines => 'Kendutako lerroak';
  @override
  String get syncMergeKeepLocal => 'Nireak';
  @override
  String get syncMergeKeepRemote => 'Zerbitzarikoak';
  @override
  String get syncMergeKeepBoth => 'Biak';
  @override
  String get syncMergeSave => 'Gorde bateratzea';
  @override
  String get syncMergeKeepWhole => 'Edo gorde kopia oso bat';
}
