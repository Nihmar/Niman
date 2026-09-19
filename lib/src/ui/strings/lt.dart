// The Lithuanian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class LithuanianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'sausis',
    'vasaris',
    'kovas',
    'balandis',
    'gegužė',
    'birželis',
    'liepa',
    'rugpjūtis',
    'rugsėjis',
    'spalis',
    'lapkritis',
    'gruodis',
  ];
  @override
  List<String> get monthNamesShort => const [
    'saus',
    'vas',
    'kov',
    'bal',
    'geg',
    'birž',
    'liep',
    'rgp',
    'rgs',
    'spal',
    'lapk',
    'gruo',
  ];
  @override
  List<String> get weekdayNames => const [
    'pirmadienis',
    'antradienis',
    'trečiadienis',
    'ketvirtadienis',
    'penktadienis',
    'šeštadienis',
    'sekmadienis',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'pr',
    'an',
    'tr',
    'kt',
    'pk',
    'št',
    'sk',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Šiukšlinė';
  @override
  String get trashSubtitle =>
      'Ištrinti elementai perkeliama į .trash/ (išjungta = nevildinamas '
      'ištrininimas)';
  @override
  String get trashAutoEmptyTitle => 'Automatiškai ištuštinti šiukšlinę';
  @override
  String get trashAutoEmptySubtitle =>
      'Senesni ištrynimai dingsta visam laikui atveriant biblioteką';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Niekada'
      : days % 10 == 1 && days % 100 != 11
      ? '$days diena'
      : days % 10 >= 2 && (days % 100 < 11 || days % 100 > 19)
      ? '$days dienos'
      : '$days dienų';
  @override
  String get debugLogsTitle => 'Derinimo žurnalai';
  @override
  String get debugLogsSubtitle =>
      'Fiksuoja programos įvykius atminties buferiui';
  @override
  String get lineNumbersTitle => 'Eilučių numeriai';
  @override
  String get lineNumbersSubtitle =>
      'Rodys eilučių numerių stulpelį pastabų redaktoriaus ekrane';
  @override
  String get readableLineLengthTitle => 'Patogus eilutės ilgis';
  @override
  String get readableLineLengthSubtitle =>
      'Laikyti užrašo tekstą centruotame stulpelyje, o ne per visą lango plotį';
  @override
  String get noteColumnWidthTitle => 'Stulpelio plotis';
  @override
  String get noteColumnWidthSubtitle =>
      'Koks platus užrašo stulpelis, pikseliais';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Klaviatūra atidarant';
  @override
  String get keyboardOnOpenSubtitle =>
      'Rodys klaviatūrą atidarant pastabą (išjungta = pirmojo prisilietimo '
      'metu)';
  @override
  String get editorKindSource => 'Markdown šaltinis';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Markdown pirminis tekstas, kaip parašyta';
  @override
  String get editorKindWysiwygSubtitle =>
      'Suformatuotas tekstas, redaguojamas vietoje';
  @override
  String get settingsFolderToCreate => 'sukurti';
  @override
  String get settingsSearchHint => 'Ieškoti nustatymuose';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 nustatymas rastas' : '$count nustatymai rasti';
  @override
  String get settingsToggleOn => 'Įjungta';
  @override
  String get settingsToggleOff => 'Išjungta';
  @override
  String get settingsPreviewEnabledTitle => 'Peržiūra';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Rodys sukurtą pastabą šalia šaltinio redaktoriaus';
  @override
  String get switchToWysiwygTooltip => 'Perjungti į WYSIWYG redaktorių';
  @override
  String get switchToSourceTooltip => 'Perjungti į Markdown šaltinį';
  @override
  String get switchToSourceLabel => 'Šaltinis';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Ši pastaba per didelė WYSIWYG redaktoriui. Atidarykite ją kaip '
      'Markdown šaltinį.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Išvaizda';
  @override
  String get settingsSectionEditor => 'Redaktorius';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'PrimINIMAI';
  @override
  String get settingsSectionShortcuts => 'Klaviatūra';
  @override
  String get keyboardShortcutsTitle => 'Klaviatūros santraupos';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteka $name';
  @override
  String get settingsGroupLibraryHint => 'taiko tik šiai bibliotekai';
  @override
  String get settingsGroupMaintenance => 'Priežiūra';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Katalogai ir keliai';
  @override
  String get settingsAreaTrashHistory => 'Šiukšlinė ir istorija';
  @override
  String get settingsAreaDiagnostics => 'Diagnostika ir info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Reikia prijungtos fizinės klaviatūros';
  @override
  String get settingsSectionUpdates => 'Atnaujinimai';
  @override
  String get autoUpdateTitle => 'Automatiniai atnaujinimai';
  @override
  String get autoUpdateSubtitle =>
      'Tikrinti GitHub Releases paleidžiant ir kas 6 valandas';
  @override
  String get checkForUpdatesTitle => 'Tikrinti atnaujinimus';
  @override
  String updateAvailableMessage(Object version) => 'Pasiekiama Niman $version';
  @override
  String get updateUpToDate => 'Naudojate naujausią Niman versiją';
  @override
  String get updateCheckFailed => 'Nepavyko patikrinti atnaujinimų';
  @override
  String updateSavedTo(Object path) => 'Atnaujinimas išsaugotas: $path';
  @override
  String get updateInstallerStarted => 'Diegimo programa paleista';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Rašybos patikra';
  @override
  String get settingsSpellCheckSubtitle => 'Paryškina rašybos klaidas rašant.';
  @override
  String get spellCheckDictionaryTitle => 'Žodynas';
  @override
  String get spellCheckDictionarySystem => 'Sistemos numatytasis';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Žodynų parinkimas';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Pasirinkite visas kalbas, kuriose parašyta biblioteka. Žodis praeina, '
      'jei jį atpažįsta bent vienas pasirinktas žodynas; ne pasirinkus – '
      'sistemos kalba.';
  @override
  String get spellCheckNoDictionaries => 'Šioje sistemoje žodynai nerasta.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Rašybos patikra';
  @override
  String get spellCheckTitle => 'Rašyba';
  @override
  String get spellCheckEmpty => 'Rašybos klaidų nėra.';
  @override
  String get spellCheckUnavailable => 'hunspell nėra įdiegtas šioje sistemoje.';
  @override
  String get spellCheckNoSuggestions => 'Pasiūlymų nėra';
  @override
  String spellCheckCount(int count) => '$count tikrinamų';
  @override
  String spellCheckLine(int line) => 'eilutė $line';
  @override
  String get addWordToDictionary => 'Pridėti į žodyną';

  @override
  String indentWidthValue(int spaces) => '$spaces tarpai';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Šviesumas';
  @override
  String get themeBrightnessSubtitle =>
      'Šviesi, tamsi arba įrenginio nustatymas';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Šviesi';
  @override
  String get themeBrightnessNight => 'Tamsi';
  @override
  String get themePaletteTitle => 'Spalvų paletė';
  @override
  String get themePaletteSubtitle => 'Sąsajos ir pastabų spalvos';
  @override
  String get themePaletteSystem => 'Sistema';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Sąsijos teksto dydis';
  @override
  String get uiTextScaleSubtitle =>
      'Medis, kortelės ir dialogai; virš sistemos nustatymo';
  @override
  String get noteTextScaleTitle => 'Pastabų teksto dydis';
  @override
  String get noteTextScaleSubtitle =>
      'Redaktorius ir peržiūra visada suderinami';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Peržiūros režimas';
  @override
  String get previewModeSubtitle =>
      'Ar peržiūra dalija ekraną su redaktoriumi, ar jį pakeičia';
  @override
  String get previewModeAuto => 'Šalia';
  @override
  String get previewModeSwitch => 'Visas ekranas';
  @override
  String get splitRatioTitle => 'Padalinimo santykis';
  @override
  String get splitRatioSubtitle => 'Redaktoriaus dalis, kai peržiūra yra šalia';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Nuorodos formatas';
  @override
  String get linkTypeSubtitle => 'Ką nuorodos mygtukas įrašo redaktoriuje';
  @override
  String get linkTypeWikilink => 'Vikinuoroda';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Trūkst pastabų sukūrimas';
  @override
  String get missingNoteLocationRoot => 'Bibliotekos šaknyje';
  @override
  String get missingNoteLocationCurrentFolder => 'Dabartiniame kataloge';
  @override
  String get indentWidthTitle => 'Įtraukos plotis';
  @override
  String get indentWidthSubtitle =>
      'Tarpų skaičius, pridedamas kiekvienu įtraukos lygmenyje redaktoriuje';
  @override
  String get languageTitle => 'Kalba';
  @override
  String get languageSubtitle => 'Pati programos teksto kalba';
  @override
  String get languageSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Pridėti elementą';
  @override
  String get listAddTooltip => 'Pridėti elementą';
  @override
  String get listEmpty => 'Elementų dar nėra';
  @override
  String get listDragHandleLabel => 'Keisti elemento tvarką';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Įrašų dar nėra';
  @override
  String get audioRecord => 'Įrašyti';
  @override
  String get audioStop => 'Stabdyti';
  @override
  String get audioPlay => 'Groti';
  @override
  String get audioDelete => 'Ištrinti įrašą';
  @override
  String get audioImport => 'Importuoti garso failą';
  @override
  String get audioRecording => 'Įrašoma…';
  @override
  String get audioPermissionDenied =>
      'Nėra leidimo naudoti mikrofoną — jis reikalingas įrašymui.';
  @override
  String get newAudioNoteTitle => 'Nauja balso pastaba';
  @override
  String get newAudioNoteDefault => 'Mano įrašas';
  @override
  String get showAudioTooltip => 'Rodyti įrašus';
  @override
  String get audioMessageHint => 'Parašykite pastabą…';
  @override
  String get audioSend => 'Siųsti';
  @override
  String get audioRename => 'Pervadinti įrašą';
  @override
  String get audioDescriptionHint => 'Aprašykite šį įrašą…';
  @override
  String get audioEditDescription => 'Redaguoti aprašą';
  @override
  String get audioDeleteNote => 'Ištrinti pastabą';
  @override
  String get audioEditNote => 'Redaguoti pastabą';
  @override
  String get audioPause => 'Pristabdyti';
  @override
  String get audioEditTitle => 'Redaguoti pavadinimą';
  @override
  String get audioTitleHint => 'Įrašo pavadinimas…';
  @override
  String audioUntitled(int n) => 'Įrašas $n';
  @override
  String get audioMoreActions => 'Daugiau veiksmų';
  @override
  String get audioDiscardRecording => 'Atmesti įrašą';
  @override
  String get audioPauseRecording => 'Pristabdyti įrašymą';
  @override
  String get audioResumeRecording => 'Tęsti įrašymą';
  @override
  String get audioRecordingPaused => 'Pristabdyta';
  @override
  String get audioSavingRecording => 'Išsaugoma…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Greita pastaba';
  @override
  String get shortcutNewTodo => 'Nauja užduotis';
  @override
  String get shortcutNewNote => 'Nauja pastaba';
  @override
  String get shortcutNewList => 'Naujas sąrašas';
  @override
  String get shortcutNewAudio => 'Nauja balso pastaba';
  @override
  String get shortcutToggleSidebar => 'Rodyti arba slėpti filtrą';
  @override
  String get shortcutCloseTab => 'Uždaryti dabartinį užrašą';
  @override
  String get shortcutNextTab => 'Kitas atvertas užrašas';
  @override
  String get shortcutPreviousTab => 'Ankstesnis atvertas užrašas';
  @override
  String get shortcutEditorSection => 'Redaktoriuje';
  @override
  String get shortcutFind => 'Ieškoti';
  @override
  String get shortcutReplace => 'Ieškoti ir pakeisti';
  @override
  String get shortcutSavingNote =>
      'Pakeitimai išsaugomi automatiškai, todėl išsaugojimo santraukos '
      'nėra.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Įkeliama…';
  @override
  String get noteStatusSaving => 'Įrašoma…';
  @override
  String get noteStatusUnsaved => 'Neįrašyta';
  @override
  String get noteStatusSaved => 'Įrašyta';
  @override
  String get noteStatusError => 'Klaida';
  @override
  String get noteNotText =>
      'Šis failas nėra tekstinis užrašas, todėl Niman negali jo čia parodyti.';
  @override
  String get noteLoadFailed => 'Šio užrašo atidaryti nepavyko.';
  @override
  String wordCount(int count) => count % 100 >= 11 && count % 100 <= 19
      ? '$count žodžių'
      : switch (count % 10) {
          1 => '$count žodis',
          0 => '$count žodžių',
          _ => '$count žodžiai',
        };
  @override
  String get outlineTooltip => 'Struktūra';
  @override
  String get outlineNoHeadings => 'Antraščių nėra';
  @override
  String get outlineNoTitle => '(be pavadinimo)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Paryškintas';
  @override
  String get toolbarItalic => 'Kursyvas';
  @override
  String get toolbarStrikethrough => 'Perbrauktas';
  @override
  String get toolbarSuperscript => 'Viršutinis indeksas';
  @override
  String get toolbarUnderline => 'Pabrauktas';
  @override
  String get toolbarLink => 'Nuoroda';
  @override
  String get toolbarCode => 'Kodo blokas';
  @override
  String get toolbarImage => 'Įterpti vaizdą';
  @override
  String get toolbarHeading => 'Antraštė';
  @override
  String get toolbarList => 'Sąrašas';
  @override
  String get toolbarOrderedList => 'Numeruotas sąrašas';
  @override
  String get toolbarQuote => 'Citata';
  @override
  String get toolbarIndent => 'Įtrauka';
  @override
  String get toolbarOutdent => 'Atleisti įtrauką';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Įrankiai';
  @override
  String get editorToolsTitle => 'Redaktoriaus įrankiai';
  @override
  String get toolCountListTitle => 'Suskaičiuoti sąrašą';
  @override
  String get toolCountListSubtitle =>
      'Sudeda tai, ką eilutės išvardija, kaip žymimąjį sąrašą';
  @override
  String get toolCountListNeedsList =>
      'Šiame užraše nėra sąrašo, kurį būtų galima suskaičiuoti';
  @override
  String get tallySourceLabel => 'Sąrašas';
  @override
  String get tallyCutLabel => 'Kiekvieną eilutę skaityti kaip';
  @override
  String get tallyCutDash => 'Vardas - reikšmės';
  @override
  String get tallyCutColon => 'Vardas: reikšmės';
  @override
  String get tallyCutCommas => 'Kableliais atskirtos reikšmės';
  @override
  String get tallyCutWhole => 'Visa eilutė kaip viena reikšmė';
  @override
  String get tallySortLabel => 'Tvarka';
  @override
  String get tallySortCount => 'Daugiausia pirmiausia';
  @override
  String get tallySortAlphabetical => 'Abėcėlės tvarka';
  @override
  String get tallySortFirstSeen => 'Sąrašo tvarka';
  @override
  String get tallyInsert => 'Įterpti';
  @override
  String get tallyUpdate => 'Atnaujinti';
  @override
  String get tallyNothingToCount => 'Čia nėra ko skaičiuoti';
  @override
  String get headingDialogTitle => 'Antraštės lygis';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Redaktoriaus įrankių juosta';
  @override
  String get toolbarSettingsHint =>
      'Tempkite, kad keistumėte tvarką; akis rodo arba slepia mygtuką.';
  @override
  String get toolbarShowButton => 'Rodyti';
  @override
  String get toolbarHideButton => 'Slėpti';
  @override
  String get toolbarResetOrder => 'Atkurti numatytąjį';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Rodyti peržiūrą';
  @override
  String get showEditorTooltip => 'Rodyti redaktorių';
  @override
  String get enterFullScreenTooltip => 'Visas ekranas';
  @override
  String get exitFullScreenTooltip => 'Išeiti iš viso ekrano';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(neapdorota HTML lentelė)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Ieškoti pastabose';
  @override
  String get searchModeWords => 'Žodžiai';
  @override
  String get searchModeContains => 'Turi';
  @override
  String get searchEmptyHint =>
      'Rašykite, kad ieškotumėte bibliotekoje, arba raktas = vertė, kad '
      'filtruotumėte pagal metaduomenis';
  @override
  String get searchTooShortHint => 'Rašykite bent 2 simbolius';
  @override
  String get searchNoMatches => 'Rezultatų nėra';
  @override
  String get searchLoadMore => 'Rodyti daugiau';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Pakeisti…';
  @override
  String get replaceInNoteAction => 'Pakeisti šioje pastaboje…';
  @override
  String get replaceInThisNote => 'Pakeisti šioje pastaboje';
  @override
  String get replaceWithLabel => 'Pakeisti į';
  @override
  String get replaceCaseSensitive => 'Skirti didžiąsias ir mažąsias raides';
  @override
  String get replaceWholeWordsHint =>
      'keičiami tik visą žodį tiksliai atitinkantys';
  @override
  String get replaceConfirm => 'Pakeisti';
  @override
  String get replaceCancel => 'Uždaryti';
  @override
  String get replaceUnavailable => 'Pakeitimas dabar nepasiekiamas';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Ieškoti pastaboje';
  @override
  String get editorFindHint => 'Ieškoti';
  @override
  String get editorReplaceHint => 'Pakeisti';
  @override
  String get editorFindCaseTooltip => 'Skirti didžiąsias ir mažąsias raides';
  @override
  String get editorFindPreviousTooltip => 'Ankstesnis rezultatas';
  @override
  String get editorFindNextTooltip => 'Kitas rezultatas';
  @override
  String get editorFindCloseTooltip => 'Uždaryti paiešką';
  @override
  String get editorFindReplaceModeTooltip => 'Pakeitimo režimas';
  @override
  String get editorReplaceOneTooltip => 'Pakeisti šį rezultatą';
  @override
  String get editorReplaceAllTooltip => 'Pakeisti visus rezultatus';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Žymos';
  @override
  String get tagsTitle => 'Žymos';
  @override
  String get tagsEmpty =>
      'Žymų dar nėra – pridėkite pastaboje #žyma ar žymas metaduomenyse';
  @override
  String get tagsBackTooltip => 'Atgal į paiešką';
  @override
  String get tagsNotesEmpty => 'Pastabos su šia žyma nėra';
  @override
  String tagsNotesCapped(int limit) =>
      'Rodomos tik pirmos $limit – ieškokite žymos, kad susiaurintumėte';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Nuoroda nerasta';
  @override
  String get headingNotFoundTitle => 'Antraštė nerasta';
  @override
  String get ambiguousLinkTitle => 'Kelioms pastaboms tinka';
  @override
  String get openLinkFailed => 'Nepavyko atidaryti nuorodos';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Pastaba neegzistuoja';
  @override
  String missingNoteDialogBody(String path) => 'Sukurti „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Katalogas „$folder“ neegzistuoja';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Atidarytos';
  @override
  String get todoDone => 'Atliktos';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Visos datos';
  @override
  String get todoFilter => 'Filtruoti';
  @override
  String get todoNoTokens => 'Šiame sąraše žetonų nėra';
  @override
  String get todoCountOpen => 'atidarytos';
  @override
  String get todoCountDone => 'atliktos';
  @override
  String get todoEmptyOpen => 'Atidarytų užduočių dar nėra';
  @override
  String get todoEmptyDone => 'Atliktų dar nėra';
  @override
  String get todoEmptyFiltered => 'Atitinkančių užduočių nėra';
  @override
  String get todoTitle => 'Užduotys';
  @override
  String get todoAddTooltip => 'Pridėti užduotį';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt formatas';
  @override
  String get todoHelpTooltip => 'Informacija apie formatą';
  @override
  String get todoHelpIntro =>
      'Jūsų užduotys – įprastas teksto failas, viena užduotis eilutėje. Niman '
      'rašo sintaksę jūsų vietoje, tačiau failą galima redaguoti bet kuriame '
      'redaktoriuje, o Niman jį vėl perskaitys.';
  @override
  String get todoHelpFilesTitle => 'Du failai';
  @override
  String get todoHelpFilesBody =>
      'Atidarytos užduotys gyvena todo.txt bibliotekos šaknyje. Atlikus '
      'vieną, eilutė perkel į done.txt, kad todo.txt liktų trumpa. Atlikta '
      'eilutė, vėl patekusi į todo.txt, Niman archyvuoja sekaname failo '
      'skaityme.';
  @override
  String get todoHelpLineTitle => 'Eilutės anatomija';
  @override
  String get todoHelpLineBody =>
      'Viskas prieš aprašą – pasirinkimai, ir jie turi būti šia tvarka:';
  @override
  String get todoHelpDoneBody =>
      'Žyma užduotį kaip atliktą. Niman ją prideda, kai pažymėjote langelį.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritetas. A yra aukščiausias. Rodomas kaip simbolis sąraše.';
  @override
  String get todoHelpDatesBody =>
      'Įvykdymo data, tada sukūrimo data. Su viena data tai sukūrimo data, '
      'jei eilutė nesideda nuo x.';
  @override
  String get todoHelpTokensTitle => 'Projektai, kontekstai ir žymos';
  @override
  String get todoHelpTokensBody =>
      'Bet kuris aprašo žodis su vienu iš šių priesakių tampa filtruojama '
      'žyma. Nieko nėra išanksto apibrėžta: žetonas egzistuoja, kol jis '
      'neįrašytas.';
  @override
  String get todoHelpProjectBody =>
      'Kuriam projektui užduotis priklauso, pvz., +virtuvė ar +darbas.';
  @override
  String get todoHelpContextBody =>
      'Kur arba kaip tai atlikti, pvz., @namie arba @susitikimas.';
  @override
  String get todoHelpHashtagBody => 'Laisva žyma tam, ko kitos dvi neapsengia.';
  @override
  String get todoHelpTagsTitle => 'Datos ir primINIMAI';
  @override
  String get todoHelpTagsBody =>
      'Šios yra raktas:vertė žymos. Niman jas rašo iš užduoties dialogo ir '
      'skaitys ten, kur jos pasirodys eilutėje.';
  @override
  String get todoHelpDueBody =>
      'Įvykdymo terminas. Valdo simbolio spalvą ir datų filtrus.';
  @override
  String get todoHelpRemBody =>
      'Kai siųsti prANEŠIMĄ jūsų laiko juostoje. Veikia, kai ekranas '
      'išjungtas, o programa uždaryta.';
  @override
  String get todoHelpRemDesktop =>
      'Kompiuteryje, kad veiktų laiku, Niman turi veikti: primINIMAS rodomas, '
      'kol programa atidaryta, o uždarius nieko nenutinka.';
  @override
  String get todoHelpOtherBody =>
      'Ji saugoma taip, kaip įrašyta, kad kitų todo.txt programų žymos '
      'išgyventų kelionę. Niman jų nenaudoja, rec: included: pasikartojanti '
      'užduotis vis dar nekartojasi.';
  @override
  String get todoHelpEditTitle => 'Redagavimas išoriškai';
  @override
  String get todoHelpEditBody =>
      'Eilutės, kurių nepadarėte, saugomos bajtų bajtais. Niman tik tai '
      'eilutę įrašo kanonine tvarka, o likusi failo dalis lieka nepaliesta.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Pridėti užduotį';
  @override
  String get todoEditTitle => 'Redaguoti užduotį';
  @override
  String get todoDescriptionHint => 'Aprašas';
  @override
  String get todoCancel => 'Atšaukti';
  @override
  String get todoSave => 'Išsaugoti';
  @override
  String get todoEditAction => 'Redaguoti';
  @override
  String get todoDeleteAction => 'Ištrinti';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Terminas praleistas';
  @override
  String get todoDueToday => 'Šiandien';
  @override
  String get todoDueNext7 => 'Kitos 7 dienos';
  @override
  String get todoDueNoDate => 'Bez datos';
  @override
  String get todoRowDue => 'Terminas';
  @override
  String get todoRowDueToday => 'Terminas šiandien';
  @override
  String get todoSortTooltip => 'Rizuoti';
  @override
  String get todoSortDue => 'Įvykdymo data';
  @override
  String get todoSortPriority => 'Prioritetas';
  @override
  String get todoSortCreation => 'Sukūrimo data';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez prioriteto';
  @override
  String get todoNoPriorityShort => 'Nėra';
  @override
  String get todoMorePriorities => 'Daugiau…';
  @override
  String get todoPriorityTitle => 'Prioritetas';
  @override
  String get todoNoDueDate => 'Bez termino';
  @override
  String get todoNoReminder => 'Bez primINIMO';
  @override
  String get todoAddProject => '+ Projektai';
  @override
  String get todoAddContext => '@ Kontekstas';
  @override
  String get todoAddHashtag => '# Žyma';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Užduočių primINIMAI';
  @override
  String get todoReminderChannelDescription =>
      'Suplanuoti prANEŠIMAI užduotims, turinčioms primINIMO laiką.';
  @override
  String get todoReminderBody => 'Užduoties primINIMAS';
  @override
  String get todoReminderFallbackTitle => 'Užduoties primINIMAS';
  @override
  String get todoReminderBlocked =>
      'PrANEŠIMAI išjungti, todėl primINIMAI nerodomi.';
  @override
  String get todoReminderBattery =>
      'Niman yra įjungta baterijų optimizacija. Sistema gali sustabdyti '
      'programą ir prarasti laukiančius primINIMUS.';
  @override
  String get todoReminderInexact =>
      'Šis įrenginys nepalaiko tikslių pabudimų, todėl, jei ekranas '
      'išjungtas, primINIMAS gali pasiekti po kelių minučių.';
  @override
  String get reminderShowTokensTitle => 'Žymos primINIMO prANEŠIMUOSE';
  @override
  String get reminderShowTokensSubtitle =>
      'Palikite +projektą, @konteksą ir #žymą prANEŠIMO tekste. Išjungus '
      'rodoma tik užduotis, kurią parašėte.';
  @override
  String get todoReminderFixAction => 'Atidaryti nustatymus';
  @override
  String get todoReminderDismissAction => 'Atmesti';
  @override
  String get todoReminderDue => 'Terminas';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Gerai';
  @override
  String get actionCancel => 'Atšaukti';
  @override
  String get actionCreate => 'Sukurti';
  @override
  String get actionNew => 'Naujas';
  @override
  String get actionSave => 'Išsaugoti';
  @override
  String get actionClear => 'Išvalyti';
  @override
  String get actionChoose => 'Pasirinkti';
  @override
  String get actionDelete => 'Ištrinti';
  @override
  String get actionRename => 'Pervadinti';
  @override
  String get actionMove => 'Perkelti';
  @override
  String get saveAndClose => 'Išsaugoti ir uždaryti';
  @override
  String get closeUnsavedTitle => 'Neišsaugoti pakeitimai';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” turi neišsaugotų pakeitimų. '
          'Išsaugoti prieš uždarydami?';
    }
    return '${names.length} pastabos turi neišsaugotų pakeitimų. '
        'Išsaugoti prieš uždarydami?';
  }

  @override
  String get closeSaveFailed => 'Išsaugoti nepavyko; pastaba lieka atidaryta.';
  @override
  String get actionRestore => 'Atkurti';
  @override
  String get actionEmpty => 'Ištuštinti';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Paslėpti šoninį panelį (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Rodyti šoninį panelį (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Sup mažinti';
  @override
  String get windowMaximizeTooltip => 'Padidinti';
  @override
  String get windowRestoreTooltip => 'Atkurti';
  @override
  String get windowCloseTooltip => 'Uždaryti';
  @override
  String get tabFiles => 'Failai';
  @override
  String get tabSearch => 'Paieška';
  @override
  String get tabSettings => 'Nustatymai';
  @override
  String get quickNoteTitle => 'Greita pastaba';
  @override
  String get treeEmpty => 'Pastabų dar nėra';
  @override
  String get selectANote => 'Pasirinkite pastabą';
  @override
  String get showListTooltip => 'Rodyti sąrašą';
  @override
  String get editRawTooltip => 'Redaguoti žalią';
  @override
  String get sortAscTooltip => 'Rizuoti A–Z';
  @override
  String get sortDescTooltip => 'Rizuoti Z–A';
  @override
  String get newNoteTitle => 'Nauja pastaba';
  @override
  String get newItemTooltip => 'Naujas';
  @override
  String get closeMenuTooltip => 'Uždaryti';
  @override
  String get newFolderTitle => 'Naujas katalogas';
  @override
  String get newNoteSameFolder => 'Nauja pastaba tame pačiame aplanke';
  @override
  String get newFromTemplateSameFolder =>
      'Nauja iš šablono tame pačiame aplanke';
  @override
  String trashOriginalPath(String path) => 'buvo: $path';
  @override
  String get trashOriginalRoot => 'buvo bibliotekos \u0161aknyje';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 elementas' : '$count elementai';
  @override
  String get newNoteHere => 'Nauja pastaba čia';
  @override
  String get newFolderHere => 'Naujas katalogas čia';
  @override
  String get newListNoteTitle => 'Nauja sąrašo pastaba';
  @override
  String get newListNoteDefault => 'Mano sąrašas';
  @override
  String get setAsQuickNote => 'Nustatyti kaip greitą pastabą';
  @override
  String get currentQuickNote => 'Dabartinė greita pastaba';
  @override
  String get pinnedSection => 'Prisegta';
  @override
  String pinnedSectionCount(int count) => 'Prisegta · $count';
  @override
  String get templateFolderTitle => 'Šablonų katalogas';
  @override
  String get newFromTemplateTitle => 'Nauja iš šablonų';
  @override
  String get newFromTemplateHere => 'Nauja iš šablonų čia';
  @override
  String get templateFormTitle => 'Užpildyti šabloną';
  @override
  String get templateFormBacklink => 'Atgalinė nuoroda';
  @override
  String get templateFormNoNote => 'Bez pastabos';
  @override
  String get templateFormPickNote => 'Pasirinkti pastabą';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Šablonų vietos';
  @override
  String get templateHelpSubtitle =>
      'Data, pavadinimas ir kitos pildytinos reikšmės';
  @override
  String get quickNoteSubtitle => 'Užrašas, kurį atidaro greito užrašo kortelė';
  @override
  String get listFolderSubtitle => 'Nauji užduočių sąrašai';
  @override
  String get templateFolderSubtitle => 'Šaltinis „Naujas iš šablono“';
  @override
  String get attachmentsFolderSubtitle => 'Į užrašą įterpti vaizdai ir garsas';
  @override
  String get templateHelpIntro =>
      'Šablonas – įprasta pastaba su vietomis. Sukūrus pastabą iš jo, '
      'tekstas nukopijuojamas, o vietos užpildomos.';
  @override
  String get templateHelpUnknown =>
      'Vietojos, kurios Niman nežino, lieka taip, kaip įrašytos, kad '
      'klaviatūros klaida būtų matoma pastaboje, o ne tyliai praleistos '
      'eilutės.';
  @override
  String get templateHelpValuesTitle => 'Vertės';
  @override
  String get templateHelpTitleBody =>
      'Pavadinimas, kuriuo pastaba turi būti sukurta.';
  @override
  String get templateHelpDateBody =>
      'Šiandien ir dabartinis laikas. Abi priima formatą: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data ir laikas kartu.';
  @override
  String get templateHelpUuidBody =>
      'Naujas unikalus identifikatorius, skirtingas kiekviename naudojime.';
  @override
  String get templateHelpCounterBody =>
      'Skaičius, skaičiuojamas pagal pavadinimą, saugojamas tarp '
      'paleidimų: pirmoji pastaba rašo 1, antroji – 2. Tas pats pavadinimas '
      'pastaboje rašo tą patį skaičių; sujungite su |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Padėkite kursorą čia sukurdami pastabą; simbolis nėra įrašomas. '
      'Pirmasis simbolis laimėja, be filtrų, tik naujose pastabose – ir '
      'klaviatūra atsivers netgi, jei autofocus yra išjungtas.';
  @override
  String get templateHelpDatesTitle => 'Datos rašymas';
  @override
  String get templateHelpDatesBody =>
      'Šios žymi datas formato dalyje. Viskas, kas nėra, yra tiesioginis, '
      'įskaitant tekstą tiesioginėse kabutėse. Mėnesio ir savaitės dienos '
      'pavadinimai naudoja programos kalbą.';
  @override
  String get templateHelpYear => 'metai: 2026, 26';
  @override
  String get templateHelpMonth => 'mėnuo: 03, 3, kovas, kov';
  @override
  String get templateHelpDay => 'diena: 09, 9, pirmadienis, pr';
  @override
  String get templateHelpTime => 'valandos, minutės, sekundės';
  @override
  String get templateHelpWeek => 'ISO savaitė ir ketvirtis: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtrai';
  @override
  String get templateHelpFiltersBody =>
      'Po vertės gali eiti filtrai, taikomi iš kairės į dešinę.';
  @override
  String get templateHelpCaseBody =>
      'Didžiosios, mažosios ir pirmoji kiekvieno žodžio raidė – žodis, '
      'įrašytas su didžiąja raide, lieka nepasikeitęs.';
  @override
  String get templateHelpSlugBody =>
      'Teksto nuorodos forma, kad sukurtumėte vikinuorodą.';
  @override
  String get templateHelpPadBody =>
      'Sup trinti galus; užpildyti nuliais iki norimo pločio; alternatyva, '
      'jei vertė tuščia.';
  @override
  String get templateHelpShiftBody =>
      'Perkelti datą dienomis, savaitėmis, mėnesiais ar metais – '
      'konferencija po savaitės, dokumentas iš praėjusio mėnesio.';
  @override
  String get templateHelpSnapBody =>
      'Prisegti datą savaitės, mėnesio ar metų pradžiai arba pabaigai.';
  @override
  String get templateHelpAskTitle => 'Klausti kažko';
  @override
  String get templateHelpAskBody =>
      'Prieš sukūrant pastabą rodosi forma su klausimų laukais – ir viena '
      'atgalinė nuoroda, jei šablonas jos prašo. Toks pats simbolis du '
      'kartus yra klausimas, ir jo atsakymas užpildo visus pasirodymus – '
      'katalogą ir failo pavadinimą.';
  @override
  String get templateHelpAskFieldBody =>
      'Laukas, apie kurį klausiamasi; tekstas po antrojo kablelio yra '
      'pradžia.';
  @override
  String get templateHelpChoiceBody =>
      'Parinkimas iš sąrašo, atskirta kableliais.';
  @override
  String get templateHelpWhereTitle => 'Kur pastaba patenka';
  @override
  String get templateHelpWhereBody =>
      'Tai ne tekstas: tai nurodymai, gyvuojantys šablonų metaduomenų '
      'niman: bloke. Blokas paleidžiamas ir išimamas, kad niekada '
      'nerodytų pastaboje. Vertė gali turėti vietų.';
  @override
  String get templateHelpFolderBody =>
      'Katalogas, kuriame sukuriama pastaba, sukuriamas, jei jo nėra. Be '
      'jos pastaba patenka ten, kur buvote.';
  @override
  String get templateHelpFilenameBody =>
      'Kaip pavadinama pastaba. Šablonas, kuris to sako, neklausia '
      'pavadinimo.';
  @override
  String get templateHelpAppendBody =>
      'Pridėti prie pastabos, jei ji jau egzistuoja, o ne kurti naują. Taip '
      'kas mėnesį susitikimas tampa vienu failu.';
  @override
  String get templateHelpOpenBody =>
      'Kas nutinka, jei pastaba egzistuoja: redaktorius (numatytas), '
      'peržiūra arba niekas – pastaba archyvuojama ir liekate ten, kur '
      'buvote.';
  @override
  String get templateHelpAroundTitle => 'Iš kur ji ateina';
  @override
  String get templateHelpParentBody =>
      'Pastaba, kurią pasirinkote formoje; įrašykite [[{{parent}}]] kaip '
      'atgalinę nuorodą.';
  @override
  String get templateHelpFolderValueBody =>
      'Katalogas, kuriame pastaba patenka.';
  @override
  String get templateHelpClipboardBody =>
      'Kas yra tarpinėje atmintyje ir kas pasirinkta redaktoriuje, jei '
      'pastaba prasidėjo ten.';
  @override
  String get templateHelpIncludeTitle => 'Dalies pakartotinas naudojimas';
  @override
  String get templateHelpIncludeBody =>
      'Įterpkite kitą šabloną, kad keli šablonai dalytų vieną kontrolinį '
      'sąrašą. Paieška pirmiausia vyksta šablonų kataloge, .md gali būti '
      'praleista. Tokie pat klausimai eina į tą pačią formą.';
  @override
  String get templateHelpExampleTitle => 'Viskas vienoje vietoje';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ šablonas „$path” neegzistuoja';
  @override
  String includeCycle(String path) => '⚠ „$path” įterpia pats save';
  @override
  String includeTooDeep(String path) => '⚠ „$path” įterpta per giliai';
  @override
  String frontmatterInvalid(String reason) =>
      'Metaduomenų nepavyko perskaityti: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Šablonas „$template” metaduomenų nepavyko perskaityti, todėl '
      'katalogas ir failo pavadinimas netaikė: $reason';
  @override
  String get templatePickerTitle => 'Šablonų parinkimas';
  @override
  String templatePickerEmpty(String folder) =>
      'Šablonų dar nėra. Įdėkite pastabą $folder/ ir ji bus šablonu.';

  // Tree actions.
  @override
  String get actionPin => 'Prisegti';
  @override
  String get actionUnpin => 'Atsegti';
  @override
  String get pinToWidget => 'Užfiksuoti į pradinio ekrano valdiklį';
  @override
  String get pinnedForWidget =>
      'Užfiksuota: dabar įdėkite „Pastaba“ valdiklį į pradinį ekraną';
  @override
  String get pinWidgetUnavailable =>
      'Pradinio ekrano valdikliai prieinami Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Rodyti failų tvarkytuvėje';
  @override
  String get openInDefaultApp => 'Atverti numatytąja programa';
  @override
  String get newNoteTabTooltip => 'Naujas užrašas naujoje kortelėje';
  @override
  String get openNotesTooltip => 'Atverti užrašai';
  @override
  String get closeTabTooltip => 'Uždaryti';
  @override
  String get openInNewTab => 'Atverti naujoje kortelėje';
  @override
  String get splitRight => 'Skaidyti į dešinę';
  @override
  String get splitDown => 'Skaidyti žemyn';
  @override
  String get moveToOtherPane => 'Perkelti į kitą polangį';
  @override
  String get openBeside => 'Atverti šalia';
  @override
  String get closeAllNotes => 'Uždaryti visus';
  @override
  String get sidePanelTooltip => 'Rodyti arba slėpti šoninį skydelį';
  @override
  String get historyAllVersions => 'Visos versijos';
  @override
  String get commandPaletteTitle => 'Komandų paletė';
  @override
  String get goToNoteTitle => 'Eiti į užrašą';
  @override
  String get paletteGroupNote => 'Užrašas';
  @override
  String get paletteGroupEditor => 'Redaktorius';
  @override
  String get paletteGroupView => 'Rodinys';
  @override
  String get paletteGroupLibrary => 'Biblioteka';
  @override
  String get paletteGroupGoTo => 'Eiti į';
  @override
  String get paletteHint => 'Ieškoti komandų ir užrašų';
  @override
  String get paletteNoResults => 'Nieko nerasta';
  @override
  String get paletteCommands => 'Komandos';
  @override
  String get paletteNotes => 'Užrašai';
  @override
  String get paletteFooter => '↑↓ judėti · ↵ naudoti · esc uždaryti';
  @override
  String get dropHint =>
      'Numeskite Markdown failus, kad juos atidarytumėte, arba aplanką, kad '
      'jį importuotumėte';
  @override
  String get importFolderAction => 'Importuoti';
  @override
  String dropRejected(String names) =>
      'Čia atidaromi tik Markdown failai ir aplankai: $names';
  @override
  String importFolderTitle(String name) => 'Importuoti „$name“?';
  @override
  String importFolderBody(int count) =>
      'Jo Markdown failai ($count) nukopijuojami į naują bibliotekos '
      'aplanką. Numestas aplankas lieka nepakitęs.';
  @override
  String importFolderDone(String folder) => 'Importuota į $folder';
  @override
  String importFolderEmpty(String name) => 'Aplanke $name nėra Markdown failų';
  @override
  String get openFileTitle => 'Atidaryti failą';
  @override
  String get outsideFileNote =>
      'Už bibliotekos ribų: išsaugoma vietoje, neindeksuojama, be istorijos, '
      'nuorodos neatidaromos';
  @override
  String get typewriterOn => 'Įjungti rašomosios mašinėlės režimą';
  @override
  String get typewriterOff => 'Išjungti rašomosios mašinėlės režimą';
  @override
  String get typewriterTitle => 'Rašomosios mašinėlės režimas';
  @override
  String get typewriterSubtitle =>
      'Eilutė, kurią rašote, lieka redaktoriaus viduryje';
  @override
  String get zenMode => 'Zen režimas';
  @override
  String get zenModeEnter => 'Įjungti zen režimą';
  @override
  String get zenModeLeave => 'Išeiti iš zen režimo';
  @override
  String get keySpace => 'Tarpas';
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
  String get keyArrowUp => 'Aukštyn';
  @override
  String get keyArrowDown => 'Žemyn';
  @override
  String get keyArrowLeft => 'Kairėn';
  @override
  String get keyArrowRight => 'Dešinėn';
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
  String get shortcutNone => 'Nėra spartiojo klavišo';
  @override
  String get shortcutRestoreDefaults => 'Atkurti numatytuosius';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Grąžinti visus sparčiuosius klavišus, kaip juos pateikia Niman?';
  @override
  String get shortcutRevert => 'Grąžinti numatytąjį';
  @override
  String get shortcutClear => 'Pašalinti spartųjį klavišą';
  @override
  String get shortcutCapturePrompt =>
      'Paspauskite klavišus. Esc ir Tab taip pat įrašomi: išeiti galima '
      'mygtuku Atšaukti.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Pridėkite Ctrl, Alt arba Meta: vienas klavišas skirtas rašyti.';
  @override
  String get shortcutMove => 'Perkelti';
  @override
  String get shortcutUseAnyway => 'Vis tiek naudoti';
  @override
  String get shortcutUndo => 'Anuliuoti';
  @override
  String get shortcutRedo => 'Pakartoti';
  @override
  String get shortcutChange => 'Keisti spartųjį klavišą';
  @override
  String shortcutCaptureTitle(String command) => 'Klavišai: $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys jau priklauso $other. Perkelti čia? $other liks be sparčiojo '
      'klavišo.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys teksto laukuose ir redaktoriuje taip pat yra $what. Ten jį '
      'perims jūsų komanda.';
  @override
  String get openFileMissing => 'Šios pastabos failo diske nėra';
  @override
  String get openFileFailed => 'Nepavyko atverti šios pastabos už Niman ribų';

  @override
  String get movedToTrash => 'Perkelta į šiukšlinę';
  @override
  String get deletedMessage => 'Ištrintas';
  @override
  String deleteToTrashConfirm(String name) => '$name bus perkeltas į .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name bus nevildinamai ištrintas';
  @override
  String get chooseDestination => 'Pasirinkti paskirtį';
  @override
  String get libraryRoot => 'Bibliotekos šaknis';
  @override
  String moveTitle(String name) => 'Perkelti $name';
  @override
  String headingLevelLabel(int level) => 'Antraštės lygis $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Greitos pastabos dar nėra. Pasirinkite esamą pastabą arba sukurkite '
      'naują – greita pastaba atsivers čia.';
  @override
  String get quickNoteChooseAction => 'Pasirinkti pastabą…';
  @override
  String get quickNoteCreateAction => 'Sukurti naują pastabą…';
  @override
  String get quickNoteNewTitle => 'Nauja greita pastaba';
  @override
  String get quickNotePickerTitle => 'Greitos pastabos parinkimas';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Naujas katalogas';
  @override
  String get folderPickerEmpty => 'Katalogų dar nėra';
  @override
  String get listFolderTitle => 'Sąrašų katalogas';
  @override
  String get attachmentsFolderTitle => 'Priedų katalogas';

  // Trash (M1).
  @override
  String get trashEmpty => 'Šiukšlinė tuščia';
  @override
  String get trashEmptyAction => 'Ištuštinti šiukšlinę';
  @override
  String get trashEmptyConfirm =>
      'Tai negrįžtamai ištrins viską, kas yra šiukšlinėje, įskaitant '
      'elementus, kurių Niman ten neįdėjo.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name bus nevildinamai ištrintas (be atkūrimo)';
  @override
  String get trashDeletePermanently => 'Ištrinti nevildinamai';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Atidarykite Markdown pastabų katalogą kaip biblioteką';
  @override
  String get openLibraryExisting => 'Atidaryti esamą';
  @override
  String get openLibraryCreate => 'Sukurti naują';
  @override
  String get openLibraryCreateTitle => 'Sukurti naują biblioteką';
  @override
  String get openLibraryFolderName => 'Katalogo pavadinimas';
  @override
  String get openLibraryChooseFolder => 'Pasirinkti bibliotekos katalogą';
  @override
  String get openLibraryChooseParent =>
      'Pasirinkite katalogą, kuriame sukuriama biblioteka';
  @override
  String get openLibraryUnsupported =>
      'Šio katalogo nepalaikoma. Pasirinkite katalogą iš įrenginio '
      'saugyklos.';
  @override
  String indexingCount(int done, int total) => '$done / $total pastabos';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Jūsų bibliotekos';
  @override
  String get libraryUnreachable => 'Nepasiekiama';
  @override
  String get libraryOpenedToday => 'Atidaryta šiandien';
  @override
  String get libraryOpenedYesterday => 'Atidaryta vakar';
  @override
  String libraryOpenedDaysAgo(int days) => 'Atidaryta prieš $days dienas';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Atidaryta ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Dabar atidaryta';
  @override
  String get switchLibraryTitle => 'Perjungti biblioteką';
  @override
  String get libraryForget => 'Pamiršti';
  @override
  String libraryForgetTitle(String name) => 'Pamiršti „$name”?';
  @override
  String get libraryForgetExplained =>
      'Ji išnyks iš šio sąrašo. Katalogas, pastabos ir bibliotekos '
      'nustatymai lieka nepaliesti, ir dar kartą atidarius grįžta į '
      'vietą.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Leisti failų prieigą';
  @override
  String get storageAccessNeeded =>
      'Niman negali skaityti jūsų pastabų be „Prieiga visiems failams”. '
      'Leiskite tai, kad atidarytumėte biblioteką.';
  @override
  String get storageAccessExplained =>
      'Niman skaitys jūsų pastabas kaip įprastus failus, todėl Android '
      'reikia duoti prieigą prie visų failų. Nieko nesiunčiama, ir skaitymas '
      'vyksta tik pasirinktame bibliotekos kataloge.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistema neleido prieiti prie katalogo: $error';
  @override
  String folderPickFailed(Object error) =>
      'Katalogo parinkimas nepavyko: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Nustatymai';
  @override
  String get libraryPathTitle => 'Bibliotekos kelias';
  @override
  String get reindexTitle => 'Perskirti dabar';
  @override
  String get reindexDone => 'Perskirta baigta';
  @override
  String get closeLibraryTitle => 'Uždaryti biblioteką';
  @override
  String get exportLogTitle => 'Eksportuoti derinimo žurnalą';
  @override
  String get exportLogSubtitle =>
      'Išsaugoti užregistruotus įvykius faile, kurį pasirinksite';
  @override
  String get exportLogEmpty => 'Žurnalo buferis tuščias';
  @override
  String get quickNoteUnset => 'Nenustatyta';
  @override
  String exportLogDone(Object target) => 'Žurnalas eksportuotas į $target';
  @override
  String exportLogFailed(Object error) => 'Eksportas nepavyko: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '„$term” neturi tikslaus visą žodį atitinkančio atitikmens';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Pakeisti $occurrences „$term” pasirodymų $notes pastabose';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped atidarytų pastabų praleista)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '„$term” neturi tikslaus visą žodį atitinkančio atitikmens'
      '${only == null ? '' : ' – tik $only rasta'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Apie';
  @override
  String get versionTitle => 'Versija';
  @override
  String get changelogTitle => 'Pakeitimų žurnalas';
  @override
  String get changelogEmpty => 'Pakeitimų žurnalo įrašų nėra';
  @override
  String changelogWhatsNew(String version) => 'Naujienos versijoje $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Istorija';
  @override
  String get noteMenuTooltip => 'Pastabos veiksmai';
  @override
  String get historyCurrentVersion => 'Dabartinė versija';
  @override
  String get historyCurrentSubtitle => 'Pastaba tokia, kokia yra dabar';
  @override
  String get historyToday => 'Šiandien';
  @override
  String get historyYesterday => 'Vakar';
  @override
  String get historyReasonSession => 'prieš redagavimą';
  @override
  String get historyReasonInterval => 'redaguojant';
  @override
  String get historyReasonRestore => 'prieš atkūrimą';
  @override
  String get historyReasonSync => 'prieš sinchronizavimą';
  @override
  String get historyReasonReplace => 'prieš pakeitimą';
  @override
  String get historyReasonUnknown => 'atgauta';
  @override
  String get historySyncBase => 'sinchronizavimo bazė';
  @override
  String get historyEmpty =>
      'Versijų dar nėra. Niman išsaugo vieną, kai pradedate redaguoti '
      'pastabą, o paskui – ne dažniau nei kas kelias minutes, kol rašote.';
  @override
  String historyKept(int kept, int limit) =>
      'Išsaugota versijų: $kept iš $limit';
  @override
  String get historyBaseKept =>
      'Sinchronizavimo bazė išsaugoma ir viršijus ribą.';
  @override
  String get historyOff =>
      'Šios bibliotekos istorija išjungta (Nustatymai, Biblioteka).';
  @override
  String get historyLoadFailed => 'Nepavyko perskaityti istorijos';
  @override
  String get historyCompareSubtitle => 'Palyginta su dabartine versija';
  @override
  String get historyTabChanges => 'Pakeitimai';
  @override
  String get historyTabVersion => 'Versija';
  @override
  String get historyNoChanges => 'Tekstas toks pat kaip dabartinėje versijoje.';
  @override
  String get historyRestoreAction => 'Atkurti šią versiją';
  @override
  String historyRestoreConfirmTitle(String when) => 'Atkurti versiją ($when)?';
  @override
  String get historyRestoreConfirmBody =>
      'Dabartinis tekstas pirmiausia išsaugomas istorijoje, todėl visada '
      'galėsite grįžti.';
  @override
  String get historyRestoreConfirm => 'Atkurti';
  @override
  String historyRestored(String when) => 'Versija atkurta ($when)';
  @override
  String get historyRestoreFailed => 'Nepavyko atkurti versijos';
  @override
  String get actionUndo => 'Anuliuoti';
  @override
  String diffLineRange(int start, int end) => 'Eilutės $start–$end';
  @override
  String diffLineSingle(int line) => 'Eilutė $line';
  @override
  String diffUnchanged(int count) => switch ((count % 10, count % 100)) {
    (_, >= 11 && <= 19) => '$count nepakeistų eilučių',
    (1, _) => '$count nepakeista eilutė',
    (0, _) => '$count nepakeistų eilučių',
    _ => '$count nepakeistos eilutės',
  };
  @override
  String get historyTakeHunk => 'Atkurti čia';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Atkurti 1 pakeitimą' : 'Atkurti $count pakeitimus';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Pasirinkti pakeitimai grįžta į šios versijos tekstą. Užrašas toks, koks '
      'yra dabar, pirma išsaugomas kaip versija, todėl gali tai atšaukti.';
  @override
  String get historyNoteChangedReloaded =>
      'Užrašas pasikeitė, kol buvai čia — palyginimas atnaujintas.';
  @override
  String get historyVersionsTitle => 'Kiek versijų saugoti';
  @override
  String get historyVersionsSubtitle =>
      'Kiekvienai pastabai, kataloge .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Nė vienos' : '$count';
  @override
  String get historyIntervalTitle => 'Nauja versija ne dažniau nei kas';
  @override
  String get historyIntervalSubtitle =>
      'Rašant; pradėjus redaguoti pastabą, versija išsaugoma visada';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkripcija';
  @override
  String get transcriptionModelTitle => 'Modelis';
  @override
  String get transcriptionModelNone => 'Nėra';
  @override
  String get transcriptionLanguageTitle => 'Kalba';
  @override
  String get transcriptionLanguageSubtitle =>
      'Kalba, kuria kalbama jūsų įrašuose. Ją nurodyti tiksliau nei leisti '
      'atpažinti.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Kaip programoje ($language)';
  @override
  String get transcriptionLanguageDetect => 'Atpažinti automatiškai';
  @override
  String get transcriptionModelsTitle => 'Transkripcijos modeliai';
  @override
  String transcriptionModelsUsed(String size) => 'Užimta $size';
  @override
  String get transcriptionModelsInstalled => 'Atsisiųsti';
  @override
  String get transcriptionModelsDownloading => 'Siunčiama';
  @override
  String get transcriptionModelsAvailable => 'Galimi';
  @override
  String get transcriptionModelsFooter =>
      'Modeliai lieka programos saugykloje šiame įrenginyje. Jie '
      'nekopijuojami į biblioteką ir nesinchronizuojami.';
  @override
  String get transcriptionModelDefault => 'Numatytasis';
  @override
  String get transcriptionModelSlow => 'Lėtas';
  @override
  String get transcriptionModelHintTiny => 'Greičiausias, mažiausiai tikslus';
  @override
  String get transcriptionModelHintBase =>
      'Gera greičio ir tikslumo pusiausvyra';
  @override
  String get transcriptionModelHintSmall => 'Tikslesnis, maždaug 3× lėtesnis';
  @override
  String get transcriptionModelHintMedium => 'Labai tikslus, telefone lėtas';
  @override
  String get transcriptionModelHintLarge =>
      'Tiksliausias, reikia daug atminties';
  @override
  String get transcriptionModelDownload => 'Atsisiųsti';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Ištrinti modelį $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Bus atlaisvinta $size. Modelį vėliau galėsite atsisiųsti iš naujo.';
  @override
  String get transcriptionModelFailed =>
      'Atsisiųsti nepavyko. Patikrinkite ryšį ir bandykite dar kartą.';
  @override
  String get actionRetry => 'Bandyti dar kartą';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Ryšys nutrūko, bandoma dar kartą…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pristabdyta: $progress';
  @override
  String get actionResume => 'Tęsti';
  @override
  String get audioTranscribe => 'Transkribuoti';
  @override
  String get audioTranscribeUnsupported => 'Šiame įrenginyje tik WAV įrašai';
  @override
  String get transcriptionQueued => 'Eilėje';
  @override
  String get transcriptionPreparing => 'Ruošiamas garsas…';
  @override
  String transcriptionRunning(int percent) => 'Transkribuojama… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Siunčiamas $model · $percent %';
  @override
  String get transcriptionSaved => 'Transkripcija pridėta prie aprašo';
  @override
  String get transcriptionNoSpeech => 'Šiame įraše kalba neatpažinta';
  @override
  String get transcriptionFailed => 'Transkribuoti nepavyko';
  @override
  String get transcriptionPickModelTitle => 'Pasirinkite modelį';
  @override
  String get transcriptionPickModelBody =>
      'Transkribuojama šiame įrenginyje, įrašas niekur nesiunčiamas. Modelis '
      'atsisiunčiamas tik kartą.';
  @override
  String get transcriptionPickModelAction => 'Atsisiųsti ir transkribuoti';
  @override
  String get transcriptionModelRecommended => 'Rekomenduojama';
  @override
  String get transcriptionExistingTitle => 'Šis įrašas jau turi aprašą';
  @override
  String get transcriptionExistingBody =>
      'Pakeisti jį transkripcija ar pridėti transkripciją po juo?';
  @override
  String get transcriptionAppend => 'Pridėti apačioje';
  @override
  String get transcriptionReplace => 'Pakeisti';
  @override
  String get settingsSectionSync => 'Sinchronizavimas';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Šiai bibliotekai nenustatyta';
  @override
  String get syncNeverSynced => 'Dar nesinchronizuota';
  @override
  String syncLastSynced(String when) => 'Sinchronizuota $when';
  @override
  String get syncRunning => 'Sinchronizuojama…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteka $library';
  @override
  String get syncUrlLabel => 'Katalogo adresas';
  @override
  String get syncUrlRequired => 'Įveskite serverio adresą';
  @override
  String get syncUrlHint =>
      'Katalogas turi egzistuoti. Nukopijuokite adresą taip, '
      'kaip jį rodo serveris.';
  @override
  String get syncHttpWarning =>
      'Nešifruotas ryšys: tinka per VPN arba vietiniame tinkle.';
  @override
  String get syncUserLabel => 'Naudotojas';
  @override
  String get syncUserHint =>
      'Palikite tuščią, jei serveris neprašo prisijungimo '
      'duomenų.';
  @override
  String get syncPasswordLabel => 'Slaptažodis';
  @override
  String get syncPasswordHint =>
      'Saugomas šio įrenginio raktų saugykloje, niekada ne '
      'bibliotekos failuose.';
  @override
  String get syncPasswordKeepHint =>
      'Palikite tuščią, kad liktų išsaugotas slaptažodis.';
  @override
  String get syncShowPassword => 'Rodyti slaptažodį';
  @override
  String get syncHidePassword => 'Slėpti slaptažodį';
  @override
  String get syncTestAction => 'Tikrinti ryšį';
  @override
  String get syncTesting => 'Tikrinama…';
  @override
  String get syncRetargetWarning =>
      'Pakeitus adresą ar naudotoją, kitas sinchronizavimas '
      'prasidės iš naujo kaip pirmasis.';
  @override
  String get syncTestOk => 'Ryšys veikia';
  @override
  String get syncModeFull => 'Visas režimas';
  @override
  String get syncModeCompatible => 'Suderinamumo režimas';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Skaitymas, rašymas ir trynimas';
  @override
  String get syncCapEtags => 'Failų atspaudai (ETag)';
  @override
  String get syncCapNoEtags => 'Nėra failų atspaudų (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Lyginamas dydis ir data; abejojant atsisiunčiama iš naujo';
  @override
  String get syncCapGuarded => 'Apsaugotas rašymas';
  @override
  String get syncCapUnguarded => 'Neapsaugotas rašymas';
  @override
  String get syncCapUnguardedDetail =>
      'Failas serveryje patikrinamas prieš pat rašant';
  @override
  String get syncCapMove => 'Pervadinama neįkeliant iš naujo';
  @override
  String get syncCapNoMove => 'Serveryje pervadinti negalima';
  @override
  String get syncCapNoMoveDetail =>
      'Pervadinimas tampa trynimu ir nauju įkėlimu';
  @override
  String get syncCompatibleNote =>
      'Suderinamumo režimu sinchronizavimas veikia taip pat, tik '
      'su keliomis papildomomis užklausomis.';
  @override
  String get syncTestInvalidUrl => 'Netinkamas adresas';
  @override
  String get syncTestInvalidUrlHint =>
      'Įveskite http:// arba https:// adresą be naudotojo ir '
      'slaptažodžio.';
  @override
  String get syncTestOffline => 'Serveris nepasiekiamas';
  @override
  String get syncTestOfflineHint =>
      'Ar įjungtas VPN? 10.x arba 192.168.x adresas veikia tik '
      'iš to paties tinklo.';
  @override
  String get syncTestAuth => 'Naudotojas arba slaptažodis atmestas';
  @override
  String get syncTestAuthHint => 'Patikrinkite juos ir bandykite dar kartą.';
  @override
  String get syncTestNotFound => 'Katalogas neegzistuoja';
  @override
  String get syncTestNotFoundHint =>
      'Sukurkite jį serveryje arba pataisykite adresą.';
  @override
  String get syncTestUnsupported => 'Tai ne WebDAV katalogas';
  @override
  String get syncTestUnsupportedHint => 'Serveris atsako, bet ne kaip WebDAV.';
  @override
  String get syncTestFailed => 'Patikrinti nepavyko';
  @override
  String get syncNowAction => 'Sinchronizuoti dabar';
  @override
  String get syncSectionServer => 'Serveris';
  @override
  String get syncServerRow => 'Adresas, naudotojas ir slaptažodis';
  @override
  String get syncRetestTitle => 'Dar kartą patikrinti serverį';
  @override
  String syncProbedAgo(String when) => 'Paskutinis patikrinimas $when';
  @override
  String get syncDisconnectTitle => 'Atjungti šią biblioteką';
  @override
  String get syncDisconnectSubtitle => 'Failai lieka čia ir serveryje';
  @override
  String get syncDisconnectConfirmTitle => 'Atjungti sinchronizavimą?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ši biblioteka šiame įrenginyje nebebus sinchronizuojama. '
      'Joks failas neištrinamas nei čia, nei serveryje. Vėl '
      'prijungus, pirmasis sinchronizavimas prasidės iš naujo.';
  @override
  String get syncDisconnectConfirm => 'Atjungti';
  @override
  String get syncFirstTitle => 'Pirmasis sinchronizavimas';
  @override
  String get syncFirstIntro => 'Biblioteka palyginta su katalogu serveryje:';
  @override
  String get syncFirstUpload => 'Bus įkelta';
  @override
  String get syncFirstDownload => 'Bus atsisiųsta';
  @override
  String get syncFirstBoth => 'Abiejose pusėse';
  @override
  String get syncFirstBothHint =>
      'Vienodi: neperduodama. Skirtingi: reikia išspręsti';
  @override
  String get syncFirstNoDelete =>
      'Pirmasis sinchronizavimas nieko neištrina nei čia, nei '
      'serveryje.';
  @override
  String get syncStartAction => 'Pradėti';
  @override
  String syncMassTrashTitle(int count) =>
      'Perkelti failus į šiukšlinę ($count)?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Serveryje trūksta $count iš $total sinchronizuotų failų. '
      'Dažniausiai tai reiškia neteisingą adresą, neprijungtą '
      'NAS diską arba per klaidą ištuštintą katalogą.';
  @override
  String get syncMassTrashHint =>
      'Jei tikrai juos ištrynėte kitame įrenginyje, '
      'patvirtinkite: čia jie bus perkelti į šiukšlinę.';
  @override
  String get syncMassTrashConfirm => 'Perkelti į šiukšlinę';
  @override
  String syncMassDeleteTitle(int count) =>
      'Ištrinti failus iš serverio ($count)?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Čia trūksta $count iš $total sinchronizuotų failų. Jei jų '
      'neištrynėte, atšaukite ir patikrinkite bibliotekos '
      'katalogą.';
  @override
  String get syncMassDeleteConfirm => 'Ištrinti iš serverio';
  @override
  String get syncTooltip => 'Sinchronizuoti';
  @override
  String get syncStageConnecting => 'Jungiamasi prie serverio…';
  @override
  String get syncStageComparing => 'Lyginama su serveriu…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sinchronizuojama · $done iš $total';
  @override
  String get syncStatusWarnings => 'Sinchronizuota su įspėjimais';
  @override
  String syncConflictsHeader(int count) => 'Pakeista čia ir serveryje · $count';
  @override
  String get syncConflictHint => 'Nė viena versija nepaliesta';
  @override
  String get syncResolveAction => 'Išspręsti';
  @override
  String syncFailuresHeader(int count) => 'Nesinchronizuota · $count';
  @override
  String get syncFailuresHint => 'Bus bandoma per kitą sinchronizavimą';
  @override
  String get syncAbortAuth => 'Serveris atmetė slaptažodį';
  @override
  String get syncAbortMissingPassword => 'Slaptažodis neišsaugotas';
  @override
  String get syncAbortOffline => 'Serveris nepasiekiamas';
  @override
  String get syncAbortRemoteMissing => 'Katalogo serveryje nebėra';
  @override
  String get syncAbortUnsupported => 'Serveris nebeveikia kaip WebDAV';
  @override
  String get syncAbortFailed => 'Sinchronizuoti nepavyko';
  @override
  String get syncAbortNotConfirmed => 'Sinchronizavimas atšauktas';
  @override
  String get syncAbortNothingTouched =>
      'Nė vienas failas nepaliestas. Jūsų pakeitimai lieka čia '
      'iki kito sėkmingo sinchronizavimo.';
  @override
  String syncLastSuccess(String when) =>
      'Paskutinis sėkmingas sinchronizavimas $when';
  @override
  String get syncNoSuccessYet => 'Dar nė vieno sėkmingo sinchronizavimo';
  @override
  String get syncUpdatePasswordAction => 'Atnaujinti slaptažodį';
  @override
  String get syncRetryAction => 'Bandyti dar kartą';
  @override
  String get syncOpenSettingsAction => 'Nustatymai';
  @override
  String get syncCloseAction => 'Uždaryti';
  @override
  String get syncDoneSnack => 'Sinchronizuota';
  @override
  String syncTrashedSnack(int count) => switch ((count % 10, count % 100)) {
    (_, >= 11 && <= 19) =>
      'Sinchronizuota · $count kitur ištrintų failų yra '
          'šiukšlinėje',
    (1, _) =>
      'Sinchronizuota · $count kitur ištrintas failas yra '
          'šiukšlinėje',
    (0, _) =>
      'Sinchronizuota · $count kitur ištrintų failų yra '
          'šiukšlinėje',
    _ =>
      'Sinchronizuota · $count kitur ištrinti failai yra '
          'šiukšlinėje',
  };
  @override
  String syncConflictsSnack(int count) => switch ((count % 10, count % 100)) {
    (_, >= 11 && <= 19) => 'Sinchronizuota · $count konfliktų laukia sprendimo',
    (1, _) => 'Sinchronizuota · $count konfliktas laukia sprendimo',
    (0, _) => 'Sinchronizuota · $count konfliktų laukia sprendimo',
    _ => 'Sinchronizuota · $count konfliktai laukia sprendimo',
  };
  @override
  String get syncShowAction => 'Rodyti';
  @override
  String get syncConflictTitle => 'Išspręsti konfliktą';
  @override
  String get syncConflictLegend =>
      'Eilutės su − yra iš serverio, eilutės su + – iš šio '
      'įrenginio.';
  @override
  String get syncConflictBinary =>
      'Tai ne tekstinis failas: pasirinkite, kurią kopiją '
      'palikti.';
  @override
  String get syncConflictKeepNote =>
      'Nepalikta kopija lieka pastabos istorijoje.';
  @override
  String get syncKeepLocal => 'Palikti šio įrenginio';
  @override
  String get syncKeepRemote => 'Palikti serverio';
  @override
  String get syncConflictIdentical => 'Abi versijos vienodos';
  @override
  String get syncConflictLoadFailed => 'Nepavyko perskaityti abiejų versijų';
  @override
  String get syncResolveFailed => 'Nepavyko išspręsti konflikto';
  @override
  String get syncResolved => 'Konfliktas išspręstas';
  @override
  String get syncSectionWhen => 'Kada sinchronizuoti';
  @override
  String get syncAutoTitle => 'Automatiškai';
  @override
  String get syncAutoSubtitle =>
      'Po pakeitimų, atidarius ir kas tam tikrą laiką';
  @override
  String get syncIntervalTitle => 'Serverio tikrinimo intervalas';
  @override
  String get syncIntervalSubtitle => 'Tik kol programa atidaryta';
  @override
  String get syncIntervalDialogBody =>
      'Kad matytumėte kituose įrenginiuose atliktus pakeitimus, kol programa '
      'atidaryta. Pasirinkus „Niekada“ – tik po pakeitimų ir atidarius.';
  @override
  String syncIntervalMinutes(int count) => count % 10 == 1 && count % 100 != 11
      ? '$count minutė'
      : count % 10 >= 2 && (count % 100 < 11 || count % 100 > 19)
      ? '$count minutės'
      : '$count minučių';
  @override
  String get syncIntervalNever => 'Niekada';
  @override
  String get syncWifiOnlyTitle => 'Tik per Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Mobiliuoju ryšiu sinchronizuoti tik rankiniu būdu';
  @override
  String syncPendingChanges(int count) => count % 10 == 1 && count % 100 != 11
      ? '$count pakeitimas laukia'
      : count % 10 >= 2 && (count % 100 < 11 || count % 100 > 19)
      ? '$count pakeitimai laukia'
      : '$count pakeitimų laukia';
  @override
  String syncRetryIn(String wait) => 'kitas bandymas po $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Laukiama Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Laukiama ryšio';
  @override
  String get syncMobileDataHint =>
      '„Sinchronizuoti dabar“ vis tiek naudoja mobiliuosius duomenis.';
  @override
  String get syncQueueKeptHint =>
      'Pakeitimai lieka čia, net jei uždarysite programą, ir išsiunčiami '
      'patys, kai serveris atsako.';
  @override
  String get syncAutoPaused => 'Automatinis sinchronizavimas pristabdytas';
  @override
  String get syncPausedAuthHint =>
      'Jis bus tęsiamas, kai atnaujinsite slaptažodį arba sinchronizuosite '
      'rankiniu būdu.';
  @override
  String get syncPausedServerHint =>
      'Jis bus tęsiamas, kai pataisysite adresą arba sinchronizuosite '
      'rankiniu būdu.';
  @override
  String get syncPausedConfirmHint =>
      '„Sinchronizuoti dabar“ parodo, kas būtų pašalinta, ir pirmiausia '
      'paklausia.';
  @override
  String get syncNeedsConfirmation => 'Laukiama jūsų patvirtinimo';
  @override
  String get syncMergeIntro =>
      'Pakeitimai, kurie nepersidengia, jau sulieti; ten, kur persidengia, '
      'pasirinkite, ką palikti.';
  @override
  String get syncMergeClean =>
      'Abi versijos susilieja pačios: niekas nepersidengia.';
  @override
  String get syncMergeNoBase =>
      'Nėra bendros versijos, ant kurios būtų galima sulieti, todėl reikia '
      'pasirinkti visą failą.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Persidengimas $index iš $total';
  @override
  String get syncMergeFromLocal => 'Iš šio įrenginio';
  @override
  String get syncMergeFromRemote => 'Iš serverio';
  @override
  String get syncMergeRemovedLines => 'Pašalintos eilutės';
  @override
  String get syncMergeKeepLocal => 'Mano';
  @override
  String get syncMergeKeepRemote => 'Serverio';
  @override
  String get syncMergeKeepBoth => 'Abi';
  @override
  String get syncMergeSave => 'Išsaugoti suliejimą';
  @override
  String get syncMergeKeepWhole => 'Arba palikti vieną visą kopiją';
}
