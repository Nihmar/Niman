// The Slovenian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class SlovenianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januar',
    'februar',
    'marec',
    'april',
    'maj',
    'junij',
    'julij',
    'avgust',
    'september',
    'oktober',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mar',
    'apr',
    'maj',
    'jun',
    'jul',
    'avg',
    'sep',
    'okt',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'ponedeljek',
    'torek',
    'sreda',
    'četrtek',
    'petek',
    'sobota',
    'nedelja',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'pon',
    'tor',
    'sre',
    'čet',
    'pet',
    'sob',
    'ned',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Koš';
  @override
  String get trashSubtitle =>
      'Izbrisani elementi se prenesejo v .trash/ (izklopljeno = trajno '
      'brisanje)';
  @override
  String get trashAutoEmptyTitle => 'Samodejno praznjenje koša';
  @override
  String get trashAutoEmptySubtitle =>
      'Starejši izbrisi za vedno izginejo ob odprtju knjižnice';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nikoli'
      : switch (days % 100) {
          1 => '$days dan',
          2 => '$days dneva',
          3 || 4 => '$days dnevi',
          _ => '$days dni',
        };
  @override
  String get debugLogsTitle => 'Razhroščevalni dnevnik';
  @override
  String get debugLogsSubtitle =>
      'Zaznava dogodke aplikacije v pomnilniškem medpomnilniku';
  @override
  String get lineNumbersTitle => 'Številke vrstic';
  @override
  String get lineNumbersSubtitle =>
      'Prikaži stolpec številk vrstic v urejevalniku opombe';
  @override
  String get keyboardOnOpenTitle => 'Tipkovnica ob odpiranju';
  @override
  String get keyboardOnOpenSubtitle =>
      'Prikaži tipkovnico ob odpiranju opombe (izklopljeno = ob prvem '
      'dotiku)';
  @override
  String get editorKindSource => 'Markdown vir';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Izvor Markdown, kot je napisan';
  @override
  String get editorKindWysiwygSubtitle =>
      'Oblikovano besedilo, urejeno na mestu';
  @override
  String get settingsFolderToCreate => 'za ustvariti';
  @override
  String get settingsSearchHint => 'Išči v nastavitvah';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 najdena nastavitev' : '$count najdenih nastavitev';
  @override
  String get settingsToggleOn => 'Vklopljeno';
  @override
  String get settingsToggleOff => 'Izklopljeno';
  @override
  String get settingsPreviewEnabledTitle => 'Predogled';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Prikaži izrisano opombo poleg urejevalnika vira';
  @override
  String get switchToWysiwygTooltip => 'Preklopi na urejevalnik WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Preklopi na Markdown vir';
  @override
  String get wysiwygTooLarge =>
      'Ta opomba je prevelika za urejevalnik WYSIWYG. Odprite jo kot '
      'Markdown vir.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Videz';
  @override
  String get settingsSectionEditor => 'Urejevalnik';
  @override
  String get settingsSectionLibrary => 'Knjižnica';
  @override
  String get settingsSectionReminders => 'Opomniki';
  @override
  String get settingsSectionShortcuts => 'Tipkovnica';
  @override
  String get keyboardShortcutsTitle => 'Bližnjice';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Knjižnica $name';
  @override
  String get settingsGroupLibraryHint => 'veli samo za to knjižnico';
  @override
  String get settingsGroupMaintenance => 'Vzdrževanje';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mape in poti';
  @override
  String get settingsAreaTrashHistory => 'Koš in kronologija';
  @override
  String get settingsAreaDiagnostics => 'Diagnostika in info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Potrebna je priključena fizična tipkovnica';
  @override
  String get settingsSectionUpdates => 'Posodobitve';
  @override
  String get autoUpdateTitle => 'Samodejne posodobitve';
  @override
  String get autoUpdateSubtitle =>
      'Preverja GitHub Releases ob zagonu in vsakih 6 ur';
  @override
  String get checkForUpdatesTitle => 'Preveri posodobitve';
  @override
  String updateAvailableMessage(Object version) => 'Na voljo je Niman $version';
  @override
  String get updateUpToDate => 'Niman je posodobljen';
  @override
  String get updateCheckFailed => 'Preverjanje posodobitev ni uspelo';
  @override
  String updateSavedTo(Object path) => 'Posodobitev shranjena v $path';
  @override
  String get updateInstallerStarted => 'Namestitveni program zagnan';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Preverjanje pravopisa';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podčrtuje pravopisne napake med tipkanjem.';
  @override
  String get spellCheckDictionaryTitle => 'Slovar';
  @override
  String get spellCheckDictionarySystem => 'Sistemska privzeta';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Izbira slovarjev';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Izberite vse jezike, v katerih je knjižnica napisana. Beseda preide, '
      'če jo pozna katerikoli od izbranih slovarjev; brez izbire odloča '
      'jezik sistema.';
  @override
  String get spellCheckNoDictionaries =>
      'Na tem sistemu ni bilo mogoče najti slovarjev.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Preverjanje pravopisa';
  @override
  String get spellCheckTitle => 'Pravopis';
  @override
  String get spellCheckEmpty => 'Ni pravopisnih napak.';
  @override
  String get spellCheckUnavailable => 'hunspell ni nameščen na tem sistemu.';
  @override
  String get spellCheckNoSuggestions => 'Ni predlogov';
  @override
  String spellCheckCount(int count) => '$count za preverjanje';
  @override
  String spellCheckLine(int line) => 'vrstica $line';
  @override
  String get addWordToDictionary => 'Dodaj v slovník';

  @override
  String indentWidthValue(int spaces) => '$spaces presledkov';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Svetlost';
  @override
  String get themeBrightnessSubtitle => 'Svetla, temna ali nastavitev naprave';
  @override
  String get themeBrightnessSystem => 'Sistem';
  @override
  String get themeBrightnessDay => 'Svetla';
  @override
  String get themeBrightnessNight => 'Temna';
  @override
  String get themePaletteTitle => 'Barvna paleta';
  @override
  String get themePaletteSubtitle => 'Barve vmesnika in opomb';
  @override
  String get themePaletteSystem => 'Sistem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Velikost besedila vmesnika';
  @override
  String get uiTextScaleSubtitle =>
      'Drevo, zavihki in pogovorna okna; nad nastavitvijo sistema';
  @override
  String get noteTextScaleTitle => 'Velikost besedila opombe';
  @override
  String get noteTextScaleSubtitle =>
      'Urejevalnik in predogled sta vedno v koraku';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Način predogleda';
  @override
  String get previewModeSubtitle =>
      'Ali predogled deli zaslon z urejevalnikom ali ga nadomesti';
  @override
  String get previewModeAuto => 'Ob strani';
  @override
  String get previewModeSwitch => 'Celozaslonski';
  @override
  String get splitRatioTitle => 'Razmerje razdelitve';
  @override
  String get splitRatioSubtitle =>
      'Delež urejevalnika, ko je predogled ob strani';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Oblika povezave';
  @override
  String get linkTypeSubtitle => 'Kaj gumb za povezavo piše v urejevalnik';
  @override
  String get linkTypeWikilink => 'Wiki povezava';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Ustvari manjkajoče opombe v';
  @override
  String get missingNoteLocationRoot => 'Koren knjižnice';
  @override
  String get missingNoteLocationCurrentFolder => 'Trenutna mapa';
  @override
  String get indentWidthTitle => 'Širina zamika';
  @override
  String get indentWidthSubtitle =>
      'Število presledkov, dodanih na vsak raven zamika v urejevalniku';
  @override
  String get languageTitle => 'Jezik';
  @override
  String get languageSubtitle => 'Jezik lastnega besedila aplikacije';
  @override
  String get languageSystem => 'Sistem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Dodaj element';
  @override
  String get listAddTooltip => 'Dodaj element';
  @override
  String get listEmpty => 'Ni še elementov';
  @override
  String get listDragHandleLabel => 'Spremeni vrstni red elementa';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Ni še posnetkov';
  @override
  String get audioRecord => 'Snemaj';
  @override
  String get audioStop => 'Ustavi';
  @override
  String get audioPlay => 'Predvajaj';
  @override
  String get audioDelete => 'Izbriši posnetek';
  @override
  String get audioImport => 'Uvozi zvočno datoteko';
  @override
  String get audioRecording => 'Snemanje …';
  @override
  String get audioPermissionDenied =>
      'Dovoljenje za mikrofon je zavrnjeno — potrebno je za snemanje.';
  @override
  String get newAudioNoteTitle => 'Nova glasovna opomba';
  @override
  String get newAudioNoteDefault => 'Moj posnetek';
  @override
  String get showAudioTooltip => 'Prikaži posnetke';
  @override
  String get audioMessageHint => 'Napišite opombo …';
  @override
  String get audioSend => 'Pošlji';
  @override
  String get audioRename => 'Preimenuj posnetek';
  @override
  String get audioDescriptionHint => 'Opišite ta posnetek …';
  @override
  String get audioEditDescription => 'Uredi opis';
  @override
  String get audioDeleteNote => 'Izbriši opombo';
  @override
  String get audioEditNote => 'Uredi opombo';
  @override
  String get audioPause => 'Premor';
  @override
  String get audioEditTitle => 'Uredi naslov';
  @override
  String get audioTitleHint => 'Naslov tega posnetka…';
  @override
  String audioUntitled(int n) => 'Posnetek $n';
  @override
  String get audioMoreActions => 'Več dejanj';
  @override
  String get audioDiscardRecording => 'Zavrzi posnetek';
  @override
  String get audioPauseRecording => 'Začasno ustavi snemanje';
  @override
  String get audioResumeRecording => 'Nadaljuj snemanje';
  @override
  String get audioRecordingPaused => 'Začasno ustavljeno';
  @override
  String get audioSavingRecording => 'Shranjevanje …';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Hitra opomba';
  @override
  String get shortcutNewTodo => 'Nova naloga';
  @override
  String get shortcutNewNote => 'Nova opomba';
  @override
  String get shortcutNewList => 'Nov seznam';
  @override
  String get shortcutNewAudio => 'Nova glasovna opomba';
  @override
  String get shortcutToggleSidebar => 'Prikaži ali skrij filter';
  @override
  String get shortcutEditorSection => 'V urejevalniku';
  @override
  String get shortcutFind => 'Iskanje';
  @override
  String get shortcutReplace => 'Iskanje in zamenjava';
  @override
  String get shortcutSavingNote =>
      'Spremembe se shranjujejo samodejno, zato shranjevanja ni bližnjice.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Nalaganje…';
  @override
  String get noteStatusSaving => 'Shranjevanje…';
  @override
  String get noteStatusUnsaved => 'Neshranjeno';
  @override
  String get noteStatusSaved => 'Shranjeno';
  @override
  String get noteStatusError => 'Napaka';
  @override
  String wordCount(int count) => switch (count % 100) {
    1 => '$count beseda',
    2 => '$count besedi',
    3 || 4 => '$count besede',
    _ => '$count besed',
  };
  @override
  String get outlineTooltip => 'Struktura';
  @override
  String get outlineNoHeadings => 'Ni naslovov';
  @override
  String get outlineNoTitle => '(brez naslova)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Krepko';
  @override
  String get toolbarItalic => 'Ležeče';
  @override
  String get toolbarStrikethrough => 'Prečrtano';
  @override
  String get toolbarSuperscript => 'Nadpisanje';
  @override
  String get toolbarUnderline => 'Podčrtano';
  @override
  String get toolbarLink => 'Povezava';
  @override
  String get toolbarCode => 'Kodni blok';
  @override
  String get toolbarImage => 'Vstavi sliko';
  @override
  String get toolbarHeading => 'Naslov';
  @override
  String get toolbarList => 'Seznam';
  @override
  String get toolbarOrderedList => 'Oštevilčen seznam';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Zamik';
  @override
  String get toolbarOutdent => 'Prekliči zamik';
  @override
  String get headingDialogTitle => 'Stopnja naslova';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Orodna vrstica urejevalnika';
  @override
  String get toolbarSettingsHint =>
      'Povlecite za spremembo vrstnega reda; oko pokaže ali skrije gumb.';
  @override
  String get toolbarShowButton => 'Prikaži';
  @override
  String get toolbarHideButton => 'Skrij';
  @override
  String get toolbarResetOrder => 'Obnovi privzeto';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Prikaži predogled';
  @override
  String get showEditorTooltip => 'Prikaži urejevalnik';
  @override
  String get enterFullScreenTooltip => 'Celozaslonsko';
  @override
  String get exitFullScreenTooltip => 'Zapusti celozaslonski način';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(neobdelana HTML tabela)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Iskanje po opombah';
  @override
  String get searchModeWords => 'Besede';
  @override
  String get searchModeContains => 'Vsebuje';
  @override
  String get searchEmptyHint =>
      'Vpisajte za iskanje po knjižnici ali ključ = vrednost za filtriranje '
      'po frontmatterju';
  @override
  String get searchTooShortHint => 'Vpisajte vsaj 2 znaka';
  @override
  String get searchNoMatches => 'Ni zadetkov';
  @override
  String get searchLoadMore => 'Prikaži več';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Zamenjaj …';
  @override
  String get replaceInNoteAction => 'Zamenjaj v tej opombi …';
  @override
  String get replaceInThisNote => 'Zamenjaj v tej opombi';
  @override
  String get replaceWithLabel => 'Zamenjaj z';
  @override
  String get replaceCaseSensitive => 'Razlikuj velike in male črke';
  @override
  String get replaceWholeWordsHint =>
      'zamenjajo se samo natančne ujemanja celih besed';
  @override
  String get replaceConfirm => 'Zamenjaj';
  @override
  String get replaceCancel => 'Zapri';
  @override
  String get replaceUnavailable => 'Zamenjava trenutno ni na voljo';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Iskanje po opombi';
  @override
  String get editorFindHint => 'Iskanje';
  @override
  String get editorReplaceHint => 'Zamenjava';
  @override
  String get editorFindCaseTooltip => 'Razlikuj velike in male črke';
  @override
  String get editorFindPreviousTooltip => 'Prejšnji zadetek';
  @override
  String get editorFindNextTooltip => 'Naslednji zadetek';
  @override
  String get editorFindCloseTooltip => 'Zapri iskanje';
  @override
  String get editorFindReplaceModeTooltip => 'Način zamenjave';
  @override
  String get editorReplaceOneTooltip => 'Zamenjaj ta zadetek';
  @override
  String get editorReplaceAllTooltip => 'Zamenjaj vse zadetke';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Oznake';
  @override
  String get tagsTitle => 'Oznake';
  @override
  String get tagsEmpty =>
      'Ni še oznak — dodajte #oznako ali oznake v frontmatter';
  @override
  String get tagsBackTooltip => 'Nazaj na iskanje';
  @override
  String get tagsNotesEmpty => 'Ni opombe s to oznako';
  @override
  String tagsNotesCapped(int limit) =>
      'Prikazani so samo prvi $limit — poiščite oznako za omejitev';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Povezava ni bila najdena';
  @override
  String get headingNotFoundTitle => 'Naslov ni bil najden';
  @override
  String get ambiguousLinkTitle => 'Več opomb ustreza';
  @override
  String get openLinkFailed => 'Povezave ni bilo mogoče odpreti';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Opomba ne obstaja';
  @override
  String missingNoteDialogBody(String path) => 'Ustvariti „$path“?';
  @override
  String missingNoteFolderMissing(String folder) => 'Mapa „$folder“ ne obstaja';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Odprte';
  @override
  String get todoDone => 'Končane';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Vsi datumi';
  @override
  String get todoFilter => 'Filtri';
  @override
  String get todoNoTokens => 'Ni žetonov na tem seznamu';
  @override
  String get todoCountOpen => 'odprte';
  @override
  String get todoCountDone => 'končane';
  @override
  String get todoEmptyOpen => 'Ni še odprtih nalog';
  @override
  String get todoEmptyDone => 'Ni še končanih';
  @override
  String get todoEmptyFiltered => 'Naloga ne ustreza';
  @override
  String get todoTitle => 'Naloge';
  @override
  String get todoAddTooltip => 'Dodaj nalogo';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Oblika todo.txt';
  @override
  String get todoHelpTooltip => 'Informacije o obliki';
  @override
  String get todoHelpIntro =>
      'Vaše naloge so navaden datotek v besedilu, ena naloga na vrstico. '
      'Niman piše sintakso namesto vas, a ničesar ne skrije: datoteko lahko '
      'uredite v poljubnem urejevalniku, Niman pa jo ponovno prebere.';
  @override
  String get todoHelpFilesTitle => 'Dve datoteki';
  @override
  String get todoHelpFilesBody =>
      'Odprte naloge živijo v todo.txt v korenu knjižnice. Ko končate eno, '
      'se vrstica prenese v done.txt, da todo.txt ostane kratek. Končano '
      'vrstico, ki se znova pojavi v todo.txt, Niman arhivira pri naslednjem '
      'branju datotek.';
  @override
  String get todoHelpLineTitle => 'Anatomija vrstice';
  @override
  String get todoHelpLineBody =>
      'Vse, kar je pred opisom, je izbirno in mora priti v tem vrstnem '
      'redit:';
  @override
  String get todoHelpDoneBody =>
      'Označi nalogo kot končano. Niman jo doda, ko potrdite polje.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioriteta. A je najvišja. Prikaže se kot grb na seznamu.';
  @override
  String get todoHelpDatesBody =>
      'Rok, nato datum nastanka. En sam datum je datum nastanka, razen če '
      'vrstica ne začenja s x.';
  @override
  String get todoHelpTokensTitle => 'Projekti, konteksti in oznake';
  @override
  String get todoHelpTokensBody =>
      'Poljubna beseda v opisu s katero koli od teh predpon postane '
      'filtrirana oznaka. Nič ni prednastavljeno: žeton obstaja, kadar ga '
      'napišete.';
  @override
  String get todoHelpProjectBody =>
      'Kateremu projektu naloga pripada, npr. +kuhinja ali +delo.';
  @override
  String get todoHelpContextBody =>
      'Kje ali kako jo opravite, npr. @domov ali @srečanja.';
  @override
  String get todoHelpHashtagBody =>
      'Prostovoljna oznaka za tisto, česar se prve dve ne dotakneta.';
  @override
  String get todoHelpTagsTitle => 'Datumi in opomniki';
  @override
  String get todoHelpTagsBody =>
      'Te so oznake ključ:vrednost. Niman jih piše iz pogovornega okna '
      'nalog in jih bere, kjer koli se pojavijo na vrstici.';
  @override
  String get todoHelpDueBody => 'Rok. Upravlja barvo grba in datumske filtre.';
  @override
  String get todoHelpRemBody =>
      'Kdaj se naj pošlje obvestilo, v vašem časovnem pasu. Zagon, ko je '
      'zaslon izklopljen in aplikacija zaprta.';
  @override
  String get todoHelpRemDesktop =>
      'Na računalniku mora Niman delovati, ko je prišel čas: opomnik se '
      'prikaže, medtem ko je aplikacija odprta, in se ne zagnika, ko je '
      'zaprta.';
  @override
  String get todoHelpOtherBody =>
      'Ohrani se natanko tako, kot je napisano, da oznake drugih todo.txt '
      'aplikacij preživijo pot. Niman jih ne uporablja, rec: included: '
      'ponavljajoča se naloga še ne ponavlja.';
  @override
  String get todoHelpEditTitle => 'Urejanje zunaj Nimana';
  @override
  String get todoHelpEditBody =>
      'Vrstice, ki jih ne dotaknete, se ohranijo bajt za bajtom. Urejeno '
      'vrstico Niman prenapiše samo v svoji kanonski obliki, ostale delo '
      'datoteke ostanejo nedotaknjene.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Dodaj nalogo';
  @override
  String get todoEditTitle => 'Uredi nalogo';
  @override
  String get todoDescriptionHint => 'Opis';
  @override
  String get todoCancel => 'Prekliči';
  @override
  String get todoSave => 'Shrani';
  @override
  String get todoEditAction => 'Uredi';
  @override
  String get todoDeleteAction => 'Izbriši';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Pozno';
  @override
  String get todoDueToday => 'Danes';
  @override
  String get todoDueNext7 => 'Prihodnjih 7 dni';
  @override
  String get todoDueNoDate => 'Brez datuma';
  @override
  String get todoRowDue => 'Rok';
  @override
  String get todoRowDueToday => 'Rok danes';
  @override
  String get todoSortTooltip => 'Razvrsti';
  @override
  String get todoSortDue => 'Datum roka';
  @override
  String get todoSortPriority => 'Prioriteta';
  @override
  String get todoSortCreation => 'Datum nastanka';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Brez prioritete';
  @override
  String get todoNoPriorityShort => 'Ni';
  @override
  String get todoMorePriorities => 'Več …';
  @override
  String get todoPriorityTitle => 'Prioriteta';
  @override
  String get todoNoDueDate => 'Brez roka';
  @override
  String get todoNoReminder => 'Brez opomnika';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Oznaka';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Opomniki nalog';
  @override
  String get todoReminderChannelDescription =>
      'Načrtovane obvestila za naloge s časom opomnika.';
  @override
  String get todoReminderBody => 'Opomnik naloge';
  @override
  String get todoReminderFallbackTitle => 'Opomnik naloge';
  @override
  String get todoReminderBlocked =>
      'Obvestila so izklopljena, zato opomniki ne bodo prikazani.';
  @override
  String get todoReminderBattery =>
      'Optimizacija baterije je vklopljena za Niman. Sistem lahko ustavi '
      'aplikacijo in izgubi čakajoče opomnike.';
  @override
  String get todoReminderInexact =>
      'Ta naprava ne podpira natančnih alarmov, zato opomnik lahko pride '
      'nekaj minut pozneje, ko je zaslon izklopljen.';
  @override
  String get reminderShowTokensTitle => 'Oznake v obvestilih opomnikov';
  @override
  String get reminderShowTokensSubtitle =>
      'Pustite +projekt, @kontekst in #oznako v besedilu obvestila. '
      'Izklopljeno prikaže samo nalogo, ki ste jo napisali.';
  @override
  String get todoReminderFixAction => 'Odpri nastavitve';
  @override
  String get todoReminderDismissAction => 'Zavrni';
  @override
  String get todoReminderDue => 'Rok';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Prekliči';
  @override
  String get actionCreate => 'Ustvari';
  @override
  String get actionNew => 'Novo';
  @override
  String get actionSave => 'Shrani';
  @override
  String get actionClear => 'Počisti';
  @override
  String get actionChoose => 'Izberi';
  @override
  String get actionDelete => 'Izbriši';
  @override
  String get actionRename => 'Preimenuj';
  @override
  String get actionMove => 'Prenesi';
  @override
  String get saveAndClose => 'Shrani in zapri';
  @override
  String get closeUnsavedTitle => 'Neshrane spremembe';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” ima neshrane spremembe. '
          'Shraniti pred zaprtjem?';
    }
    return '${names.length} opomb ima neshrane spremembe. '
        'Shraniti pred zaprtjem?';
  }

  @override
  String get closeSaveFailed => 'Shranjevanje ni uspelo; opomba ostane odprta.';
  @override
  String get actionRestore => 'Obnovi';
  @override
  String get actionEmpty => 'Prazni';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Skrij stranski panel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Prikaži stranski panel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Pomanjšaj';
  @override
  String get windowMaximizeTooltip => 'Povečaj';
  @override
  String get windowRestoreTooltip => 'Obnovi';
  @override
  String get windowCloseTooltip => 'Zapri';
  @override
  String get tabFiles => 'Datoteke';
  @override
  String get tabSearch => 'Iskanje';
  @override
  String get tabSettings => 'Nastavitve';
  @override
  String get quickNoteTitle => 'Hitra opomba';
  @override
  String get treeEmpty => 'Ni še opomb';
  @override
  String get selectANote => 'Izberite opombo';
  @override
  String get showListTooltip => 'Prikaži seznam';
  @override
  String get editRawTooltip => 'Uredi neobdelano';
  @override
  String get sortAscTooltip => 'Razvrsti A–Ž';
  @override
  String get sortDescTooltip => 'Razvrsti Ž–A';
  @override
  String get newNoteTitle => 'Nova opomba';
  @override
  String get newItemTooltip => 'Novo';
  @override
  String get closeMenuTooltip => 'Zapri';
  @override
  String get newFolderTitle => 'Nova mapa';
  @override
  String get newNoteSameFolder => 'Nov zapisek v isti mapi';
  @override
  String get newFromTemplateSameFolder => 'Nov iz predloge v isti mapi';
  @override
  String trashOriginalPath(String path) => 'bil je v $path';
  @override
  String get newNoteHere => 'Nova opomba sem';
  @override
  String get newFolderHere => 'Nova mapa sem';
  @override
  String get newListNoteTitle => 'Nova opomba s seznamom';
  @override
  String get newListNoteDefault => 'Moj seznam';
  @override
  String get setAsQuickNote => 'Nastavi kot hitro opombo';
  @override
  String get currentQuickNote => 'Trenutna hitra opomba';
  @override
  String get pinnedSection => 'Pripeto';
  @override
  String pinnedSectionCount(int count) => 'Pripeto · $count';
  @override
  String get templateFolderTitle => 'Mapa predlog';
  @override
  String get newFromTemplateTitle => 'Novo iz predloge';
  @override
  String get newFromTemplateHere => 'Novo iz predloge sem';
  @override
  String get templateFormTitle => 'Izpolni predlogo';
  @override
  String get templateFormBacklink => 'Povratna povezava';
  @override
  String get templateFormNoNote => 'Brez opombe';
  @override
  String get templateFormPickNote => 'Izberi opombo';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Mestni znaki predlog';
  @override
  String get templateHelpIntro =>
      'Predloga je navadna opomba s prazninami. Ustvarjanje opombe iz nje '
      'kopira besedilo in izpolni praznine.';
  @override
  String get templateHelpUnknown =>
      'Mestni znak, ki ga Niman ne pozna, ostane natanko tak, kot je '
      'napisan, da se vidi v opombi, ne da bi tiho raztrgal vrstico.';
  @override
  String get templateHelpValuesTitle => 'Vrednosti';
  @override
  String get templateHelpTitleBody => 'Ime, po katerem naj se opomba ustvari.';
  @override
  String get templateHelpDateBody =>
      'Danes in trenutni čas. Oba sprejemata obliko: {{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum in čas skupaj.';
  @override
  String get templateHelpUuidBody =>
      'Nov identifikator, drugačnega za vsako uporabo.';
  @override
  String get templateHelpCounterBody =>
      'Število, ki se šteje po imenu, se ohrani med zagoni: prva opomba '
      'napiše 1, naslednja 2. Isto ime v opombi napiše isto številko; '
      'združite z |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Postavite kurzor tukaj ob ustvarjanju opombe; značka se ne zapiše. '
      'Prva značka zmaga, brez filtrov, samo nove opombe — in tipkovnica se '
      'odpre tudi, če je autofocus izklopljen.';
  @override
  String get templateHelpDatesTitle => 'Zapisovanje datuma';
  @override
  String get templateHelpDatesBody =>
      'Te označujejo dele datuma v obliki. Vse, kar ni, je doslovno, '
      'vključno z besedilom v enojnih navodajih. Imena mesecev in dni v '
      'tednu sledijo jezikom aplikacije.';
  @override
  String get templateHelpYear => 'leto: 2026, 26';
  @override
  String get templateHelpMonth => 'mesec: 03, 3, marec, mar';
  @override
  String get templateHelpDay => 'dan: 09, 9, ponedeljek, pon';
  @override
  String get templateHelpTime => 'ure, minute, sekunde';
  @override
  String get templateHelpWeek => 'ISO teden in četrtletje: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtri';
  @override
  String get templateHelpFiltersBody =>
      'Za vrednostjo lahko sledijo filtri, ki se uporabljajo z leve na '
      'desno.';
  @override
  String get templateHelpCaseBody =>
      'Velike črke, male črke in prva črka vsake besede — beseda, napisana z '
      'veliko črko, se ne spremeni.';
  @override
  String get templateHelpSlugBody =>
      'Oblika povezave besedila, za ustvarjanje wiki povezave.';
  @override
  String get templateHelpPadBody =>
      'Odreži konce; dopolni z ničlami do željene širine; nadomestilo, ko je '
      'vrednost prazna.';
  @override
  String get templateHelpShiftBody =>
      'Pomaknite datum za dni, tedne, mesece ali leta — konference za en '
      'teden, dokument iz prejšnjega meseca.';
  @override
  String get templateHelpSnapBody =>
      'Prilepite datum na začetek ali konec tedna, meseca ali leta.';
  @override
  String get templateHelpAskTitle => 'Vprašamo vas za nekaj';
  @override
  String get templateHelpAskBody =>
      'Pred ustvarjanjem opombe se odpre obrazec, polja za vprašanje — in '
      'eno za povratno povezavo, če predloga zahteva. Isti znak dvakrat je '
      'vprašanje in njegov odgovor izpolni vse pojavitve — mapo in ime '
      'datoteke.';
  @override
  String get templateHelpAskFieldBody =>
      'Polje za vpis; besedilo po drugem vejici je začetek.';
  @override
  String get templateHelpChoiceBody =>
      'Izbira iz seznama, lošenega z vejicami.';
  @override
  String get templateHelpWhereTitle => 'Kam opomba pride';
  @override
  String get templateHelpWhereBody =>
      'To ni besedilo: so navodila, ki živijo v niman: bloku frontmatterja '
      'predloge. Blok se izvrši in izbriše, da se nikoli ne prikaže v '
      'opombi. Vrednost lahko vsebuje mestne znake.';
  @override
  String get templateHelpFolderBody =>
      'Mapa, v katero se opomba ustvari, se ustvari, če ne obstaja. Brez '
      'nje opomba pride tja, kjer ste bili.';
  @override
  String get templateHelpFilenameBody =>
      'Kako se opomba poimenuje. Predloga, ki to pove, ne vpraša za ime.';
  @override
  String get templateHelpAppendBody =>
      'Dodaj v opombo, če ta že obstaja, namesto ustvarjanja nove. Tako se '
      'mesečni sestanek postane ena datoteka.';
  @override
  String get templateHelpOpenBody =>
      'Kaj se zgodi, če opomba obstaja: urejevalnik (privzeto), predogled '
      'ali nič — opomba se arhivira in ostane, kjer ste bili.';
  @override
  String get templateHelpAroundTitle => 'Od kod prihaja';
  @override
  String get templateHelpParentBody =>
      'Opomba, ki jo izberete v obrazcu, ponujena na zaslonu; napišite '
      '[[{{parent}}]] kot povratno povezavo.';
  @override
  String get templateHelpFolderValueBody => 'Mapa, v katero opomba pride.';
  @override
  String get templateHelpClipboardBody =>
      'Kaj je na odjeki in izbor v urejevalniku, ko je opomba začela od tam.';
  @override
  String get templateHelpIncludeTitle => 'Ponovna uporaba dela';
  @override
  String get templateHelpIncludeBody =>
      'Vstavite drugo predlogo, da deset predlog deli en kontrolni seznam. '
      'Iskanje se izvede najprej v mapi predlog, .md lahko manjka. Njena '
      'lastna vprašanja gredo v isti obrazec.';
  @override
  String get templateHelpExampleTitle => 'Vse na enem mestu';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ predloga „$path” ne obstaja';
  @override
  String includeCycle(String path) => '⚠ „$path” se vstavi v samega sebe';
  @override
  String includeTooDeep(String path) => '⚠ „$path” je predgloboko vstavljeno';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatterja ni bilo mogoče prebrati: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatterja predloge „$template” ni bilo mogoče prebrati, zato mapa '
      'in ime datoteke nista storila ničesar: $reason';
  @override
  String get templatePickerTitle => 'Izbira predlog';
  @override
  String templatePickerEmpty(String folder) =>
      'Ni še predlog. Vstavite opombo v $folder/ in bo.';

  // Tree actions.
  @override
  String get actionPin => 'Pripni';
  @override
  String get actionUnpin => 'Odpni';
  @override
  String get pinToWidget => 'Pripni v widget na domačem zaslonu';
  @override
  String get pinnedForWidget =>
      'Pripeto: zdaj namesti widget Zapis na domači zaslon';
  @override
  String get pinWidgetUnavailable =>
      'Widgeti domačega zaslona so na voljo na Androidu';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Pokaži v upravitelju datotek';
  @override
  String get openInDefaultApp => 'Odpri s privzeto aplikacijo';
  @override
  String get openFileMissing => 'Datoteke te opombe ni na disku';
  @override
  String get openFileFailed => 'Te opombe ni bilo mogoče odpreti zunaj Nimana';

  @override
  String get movedToTrash => 'Preneseno v koš';
  @override
  String get deletedMessage => 'Izbrisano';
  @override
  String deleteToTrashConfirm(String name) => '$name se prenese v .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name se trajno izbriše';
  @override
  String get chooseDestination => 'Izberi cilj';
  @override
  String get libraryRoot => 'Koren knjižnice';
  @override
  String moveTitle(String name) => 'Prenesi $name';
  @override
  String headingLevelLabel(int level) => 'Naslov stopnje $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ni še hitre opombe. Izberite obstoječo opombo ali ustvarite novo — '
      'hitra opomba se odpre tukaj.';
  @override
  String get quickNoteChooseAction => 'Izberi opombo …';
  @override
  String get quickNoteCreateAction => 'Ustvari novo opombo …';
  @override
  String get quickNoteNewTitle => 'Nova hitra opomba';
  @override
  String get quickNotePickerTitle => 'Izbira hitre opombe';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nova mapa';
  @override
  String get folderPickerEmpty => 'Ni še map';
  @override
  String get listFolderTitle => 'Mapa seznamov';
  @override
  String get attachmentsFolderTitle => 'Mapa prilog';

  // Trash (M1).
  @override
  String get trashEmpty => 'Koš je prazen';
  @override
  String get trashEmptyAction => 'Prazni koš';
  @override
  String get trashEmptyConfirm =>
      'To trajno izbriše vse, kar je v košu, vključno z elementi, ki jih '
      'Niman ni tja dal.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se trajno izbriše (brez obnove)';
  @override
  String get trashDeletePermanently => 'Trajno izbriši';

  // The open/create library screen.
  @override
  String get openLibraryIntro => 'Odpri mapo Markdown opomb kot knjižnico';
  @override
  String get openLibraryExisting => 'Odpri obstoječo';
  @override
  String get openLibraryCreate => 'Ustvari novo';
  @override
  String get openLibraryCreateTitle => 'Ustvari novo knjižnico';
  @override
  String get openLibraryFolderName => 'Ime mape';
  @override
  String get openLibraryChooseFolder => 'Izberi mapo knjižnice';
  @override
  String get openLibraryChooseParent =>
      'Izberi mapo, v katero se knjižnica ustvari';
  @override
  String get openLibraryUnsupported =>
      'Ta mapa ni podprta. Izberite mapo iz shrambe naprave.';
  @override
  String indexingCount(int done, int total) => '$done / $total opomb';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Vaše knjižnice';
  @override
  String get libraryUnreachable => 'Nedosegljiva';
  @override
  String get libraryOpenedToday => 'Odprta danes';
  @override
  String get libraryOpenedYesterday => 'Odprta včeraj';
  @override
  String libraryOpenedDaysAgo(int days) => 'Odprta pred $days dnevi';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Odprta ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Odprta zdaj';
  @override
  String get switchLibraryTitle => 'Preklopi knjižnico';
  @override
  String get libraryForget => 'Pozabi';
  @override
  String libraryForgetTitle(String name) => 'Pozabiti na „$name”?';
  @override
  String get libraryForgetExplained =>
      'Iz tega seznama izgine. Mapa, opombe in nastavitve knjižnice ostanejo '
      'nedotaknjene in ponovno odpiranje vrne na mesto.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dovoli dostop do datotek';
  @override
  String get storageAccessNeeded =>
      'Niman ne more brati vaših opomb brez „Dostop do vseh datotek”. '
      'Omogočite ga za odpiranje knjižnice.';
  @override
  String get storageAccessExplained =>
      'Niman bere vaše opombe kot navadne datoteke, zato Android mora dati '
      'dostop do vseh datotek. Nič se ne pošilja in bere se samo mapa '
      'izbrane knjižnice.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistem ni dovolil dostopa do mape: $error';
  @override
  String folderPickFailed(Object error) => 'Izbira mape ni uspela: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Nastavitve';
  @override
  String get libraryPathTitle => 'Pot do knjižnice';
  @override
  String get reindexTitle => 'Ponovno indeksiraj zdaj';
  @override
  String get reindexDone => 'Ponovno indeksiranje dokončano';
  @override
  String get closeLibraryTitle => 'Zapri knjižnico';
  @override
  String get exportLogTitle => 'Izvozi razhroščevalni dnevnik';
  @override
  String get exportLogSubtitle =>
      'Shranite zabeležene dogodke v datoteko, ki jo izberete';
  @override
  String get exportLogEmpty => 'Medpomnilnik dnevnika je prazen';
  @override
  String get quickNoteUnset => 'Nenastavljeno';
  @override
  String exportLogDone(Object target) => 'Dnevnik izvožen v $target';
  @override
  String exportLogFailed(Object error) => 'Izvoz ni uspel: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ni natančnega zadetka celih besed za „$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Zamenjano $occurrences pojavitve „$term” v $notes opombah';
  @override
  String replaceSkipped(int skipped) => ' ($skipped odprtih opomb preskočeno)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ni natančnega zadetka celih besed za „$term”'
      '${only == null ? '' : ' ni bilo najdeno v $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'O aplikaciji';
  @override
  String get versionTitle => 'Versija';
  @override
  String get changelogTitle => 'Dnevnik sprememb';
  @override
  String get changelogEmpty => 'Vnosi dnevnika niso na voljo';
  @override
  String changelogWhatsNew(String version) => 'Novo v verziji $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Zgodovina';
  @override
  String get noteMenuTooltip => 'Dejanja opombe';
  @override
  String get historyCurrentVersion => 'Trenutna različica';
  @override
  String get historyCurrentSubtitle => 'Opomba, kakršna je zdaj';
  @override
  String get historyToday => 'Danes';
  @override
  String get historyYesterday => 'Včeraj';
  @override
  String get historyReasonSession => 'pred urejanjem';
  @override
  String get historyReasonInterval => 'med urejanjem';
  @override
  String get historyReasonRestore => 'pred obnovitvijo';
  @override
  String get historyReasonSync => 'pred sinhronizacijo';
  @override
  String get historyReasonReplace => 'pred zamenjavo';
  @override
  String get historyReasonUnknown => 'najdena';
  @override
  String get historySyncBase => 'osnova sinhronizacije';
  @override
  String get historyEmpty =>
      'Še ni različic. Niman eno shrani, ko začnete urejati opombo, nato '
      'pa največ eno na nekaj minut, medtem ko pišete.';
  @override
  String historyKept(int kept, int limit) =>
      'Shranjene različice: $kept od $limit';
  @override
  String get historyBaseKept =>
      'Osnova sinhronizacije se ohrani tudi prek omejitve.';
  @override
  String get historyOff =>
      'Zgodovina je za to knjižnico izklopljena (Nastavitve, Knjižnica).';
  @override
  String get historyLoadFailed => 'Zgodovine ni bilo mogoče prebrati';
  @override
  String get historyCompareSubtitle => 'V primerjavi s trenutno različico';
  @override
  String get historyTabChanges => 'Spremembe';
  @override
  String get historyTabVersion => 'Različica';
  @override
  String get historyNoChanges => 'Enako besedilo kot trenutna različica.';
  @override
  String get historyRestoreAction => 'Obnovi to različico';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Želite obnoviti različico, shranjeno $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Trenutno besedilo se najprej shrani v zgodovino, zato se lahko '
      'vedno vrnete.';
  @override
  String get historyRestoreConfirm => 'Obnovi';
  @override
  String historyRestored(String when) =>
      'Obnovljena različica, shranjena $when';
  @override
  String get historyRestoreFailed => 'Različice ni bilo mogoče obnoviti';
  @override
  String get actionUndo => 'Razveljavi';
  @override
  String diffLineRange(int start, int end) => 'Vrstice $start–$end';
  @override
  String diffLineSingle(int line) => 'Vrstica $line';
  @override
  String diffUnchanged(int count) => switch (count % 100) {
    1 => '$count nespremenjena vrstica',
    2 => '$count nespremenjeni vrstici',
    3 || 4 => '$count nespremenjene vrstice',
    _ => '$count nespremenjenih vrstic',
  };
  @override
  String get historyTakeHunk => 'Obnovi tukaj';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Obnovi 1 spremembo' : 'Obnovi $count sprememb';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Izbrane spremembe se vrnejo k besedilu te različice. Zapisek v trenutni '
      'obliki se najprej ohrani kot različica, zato lahko to razveljaviš.';
  @override
  String get historyNoteChangedReloaded =>
      'Zapisek se je spremenil, medtem ko si bil tukaj — primerjava je '
      'osvežena.';
  @override
  String get historyVersionsTitle => 'Število shranjenih različic';
  @override
  String get historyVersionsSubtitle => 'Za vsako opombo, v .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Brez' : '$count';
  @override
  String get historyIntervalTitle => 'Nova različica največ vsakih';
  @override
  String get historyIntervalSubtitle =>
      'Med pisanjem; ob začetku urejanja opombe se ena vedno shrani';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Prepis';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Brez';
  @override
  String get transcriptionLanguageTitle => 'Jezik';
  @override
  String get transcriptionLanguageSubtitle =>
      'Jezik, ki se govori v vaših posnetkih. Izbira jezika je natančnejša od '
      'samodejnega zaznavanja.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Kot aplikacija ($language)';
  @override
  String get transcriptionLanguageDetect => 'Zaznaj samodejno';
  @override
  String get transcriptionModelsTitle => 'Modeli za prepis';
  @override
  String transcriptionModelsUsed(String size) => 'Zasedeno: $size';
  @override
  String get transcriptionModelsInstalled => 'Preneseni';
  @override
  String get transcriptionModelsDownloading => 'Prenašanje';
  @override
  String get transcriptionModelsAvailable => 'Na voljo';
  @override
  String get transcriptionModelsFooter =>
      'Modeli ostanejo v shrambi aplikacije v tej napravi. Ne kopirajo se v '
      'knjižnico in se ne sinhronizirajo.';
  @override
  String get transcriptionModelDefault => 'Privzeto';
  @override
  String get transcriptionModelSlow => 'Počasen';
  @override
  String get transcriptionModelHintTiny => 'Najhitrejši, najmanj natančen';
  @override
  String get transcriptionModelHintBase =>
      'Dobro razmerje med hitrostjo in natančnostjo';
  @override
  String get transcriptionModelHintSmall =>
      'Natančnejši, približno 3× počasnejši';
  @override
  String get transcriptionModelHintMedium =>
      'Zelo natančen, počasen na telefonu';
  @override
  String get transcriptionModelHintLarge =>
      'Najnatančnejši, potrebuje veliko pomnilnika';
  @override
  String get transcriptionModelDownload => 'Prenesi';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Želite izbrisati model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Sprostilo se bo $size. Model lahko pozneje znova prenesete.';
  @override
  String get transcriptionModelFailed =>
      'Prenos ni uspel. Preverite povezavo in poskusite znova.';
  @override
  String get actionRetry => 'Poskusi znova';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Povezava je prekinjena, ponovni poskus…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Začasno ustavljeno pri $progress';
  @override
  String get actionResume => 'Nadaljuj';
  @override
  String get audioTranscribe => 'Prepiši';
  @override
  String get audioTranscribeUnsupported => 'V tej napravi samo posnetki WAV';
  @override
  String get transcriptionQueued => 'V čakalni vrsti';
  @override
  String get transcriptionPreparing => 'Pripravljanje zvoka…';
  @override
  String transcriptionRunning(int percent) => 'Prepisovanje… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Prenašanje modela $model · $percent %';
  @override
  String get transcriptionSaved => 'Prepis je dodan v opis';
  @override
  String get transcriptionNoSpeech => 'V tem posnetku ni bil prepoznan govor';
  @override
  String get transcriptionFailed => 'Prepis ni uspel';
  @override
  String get transcriptionPickModelTitle => 'Izberite model';
  @override
  String get transcriptionPickModelBody =>
      'Prepis poteka v tej napravi in posnetek se nikoli ne pošlje. Model se '
      'prenese samo enkrat.';
  @override
  String get transcriptionPickModelAction => 'Prenesi in prepiši';
  @override
  String get transcriptionModelRecommended => 'Priporočeno';
  @override
  String get transcriptionExistingTitle => 'Ta posnetek že ima opis';
  @override
  String get transcriptionExistingBody =>
      'Ga želite zamenjati s prepisom ali prepis dodati pod njim?';
  @override
  String get transcriptionAppend => 'Dodaj pod';
  @override
  String get transcriptionReplace => 'Zamenjaj';
  @override
  String get settingsSectionSync => 'Sinhronizacija';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Za to knjižnico ni nastavljena';
  @override
  String get syncNeverSynced => 'Še ni sinhronizirana';
  @override
  String syncLastSynced(String when) => 'Sinhronizirana $when';
  @override
  String get syncRunning => 'Sinhronizacija poteka…';
  @override
  String syncScreenSubtitle(String library) => 'Knjižnica $library';
  @override
  String get syncUrlLabel => 'Naslov mape';
  @override
  String get syncUrlHint =>
      'Mapa mora obstajati. Naslov kopirajte tako, kot ga '
      'prikazuje strežnik.';
  @override
  String get syncHttpWarning =>
      'Nešifrirana povezava: v redu prek VPN ali v lokalnem '
      'omrežju.';
  @override
  String get syncUserLabel => 'Uporabnik';
  @override
  String get syncUserHint =>
      'Pustite prazno, če strežnik ne zahteva poverilnic.';
  @override
  String get syncPasswordLabel => 'Geslo';
  @override
  String get syncPasswordHint =>
      'Shranjeno v shrambi ključev te naprave, nikoli v '
      'datotekah knjižnice.';
  @override
  String get syncPasswordKeepHint =>
      'Pustite prazno, da ohranite shranjeno geslo.';
  @override
  String get syncShowPassword => 'Prikaži geslo';
  @override
  String get syncHidePassword => 'Skrij geslo';
  @override
  String get syncTestAction => 'Preizkusi povezavo';
  @override
  String get syncTesting => 'Preizkušanje…';
  @override
  String get syncRetargetWarning =>
      'Z drugim naslovom ali uporabnikom se naslednja '
      'sinhronizacija začne znova kot prva.';
  @override
  String get syncTestOk => 'Povezava deluje';
  @override
  String get syncModeFull => 'Polni način';
  @override
  String get syncModeCompatible => 'Združljivi način';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Branje, pisanje in brisanje';
  @override
  String get syncCapEtags => 'Prstni odtisi datotek (ETag)';
  @override
  String get syncCapNoEtags => 'Brez prstnih odtisov datotek (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Primerja velikost in datum; ob dvomu znova prenese';
  @override
  String get syncCapGuarded => 'Zaščiteni zapisi';
  @override
  String get syncCapUnguarded => 'Nezaščiteni zapisi';
  @override
  String get syncCapUnguardedDetail =>
      'Tik pred pisanjem preveri datoteko na strežniku';
  @override
  String get syncCapMove => 'Preimenuje brez ponovnega nalaganja';
  @override
  String get syncCapNoMove => 'Brez preimenovanja na strežniku';
  @override
  String get syncCapNoMoveDetail =>
      'Preimenovanje postane brisanje in novo nalaganje';
  @override
  String get syncCompatibleNote =>
      'V združljivem načinu sinhronizacija deluje enako, le z '
      'nekaj več zahtevami.';
  @override
  String get syncTestInvalidUrl => 'Neveljaven naslov';
  @override
  String get syncTestInvalidUrlHint =>
      'Vnesite naslov http:// ali https:// brez uporabnika in '
      'gesla.';
  @override
  String get syncTestOffline => 'Strežnik ni dosegljiv';
  @override
  String get syncTestOfflineHint =>
      'Je VPN vklopljen? Naslov 10.x ali 192.168.x deluje le iz '
      'istega omrežja.';
  @override
  String get syncTestAuth => 'Strežnik je zavrnil uporabnika ali geslo';
  @override
  String get syncTestAuthHint => 'Preverite ju in preizkusite znova.';
  @override
  String get syncTestNotFound => 'Mapa ne obstaja';
  @override
  String get syncTestNotFoundHint =>
      'Ustvarite jo na strežniku ali popravite naslov.';
  @override
  String get syncTestUnsupported => 'To ni mapa WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'Strežnik odgovarja, vendar ne kot WebDAV.';
  @override
  String get syncTestFailed => 'Preizkus ni uspel';
  @override
  String get syncNowAction => 'Sinhroniziraj zdaj';
  @override
  String get syncSectionServer => 'Strežnik';
  @override
  String get syncServerRow => 'Naslov, uporabnik in geslo';
  @override
  String get syncRetestTitle => 'Znova preizkusi strežnik';
  @override
  String syncProbedAgo(String when) => 'Zadnji preizkus $when';
  @override
  String get syncDisconnectTitle => 'Odklopi to knjižnico';
  @override
  String get syncDisconnectSubtitle => 'Datoteke ostanejo tu in na strežniku';
  @override
  String get syncDisconnectConfirmTitle => 'Želite odklopiti sinhronizacijo?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ta knjižnica se na tej napravi preneha sinhronizirati. '
      'Nobena datoteka se ne izbriše, ne tu ne na strežniku. Če '
      'jo znova povežete, se prva sinhronizacija začne od '
      'začetka.';
  @override
  String get syncDisconnectConfirm => 'Odklopi';
  @override
  String get syncFirstTitle => 'Prva sinhronizacija';
  @override
  String get syncFirstIntro => 'Knjižnica, primerjana z mapo na strežniku:';
  @override
  String get syncFirstUpload => 'Za nalaganje';
  @override
  String get syncFirstDownload => 'Za prenos';
  @override
  String get syncFirstBoth => 'Na obeh straneh';
  @override
  String get syncFirstBothHint =>
      'Enake: brez prenosa. Različne: za razrešitev';
  @override
  String get syncFirstNoDelete =>
      'Prva sinhronizacija ne izbriše ničesar, ne tu ne na '
      'strežniku.';
  @override
  String get syncStartAction => 'Začni';
  @override
  String syncMassTrashTitle(int count) => count % 100 == 1
      ? 'Premakniti $count datoteko v koš?'
      : count % 100 == 2
      ? 'Premakniti $count datoteki v koš?'
      : count % 100 == 3 || count % 100 == 4
      ? 'Premakniti $count datoteke v koš?'
      : 'Premakniti $count datotek v koš?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Na strežniku manjka $count od $total sinhroniziranih '
      'datotek. To navadno pomeni napačen naslov, nepriklopljen '
      'disk NAS ali pomotoma izpraznjeno mapo.';
  @override
  String get syncMassTrashHint =>
      'Če ste jih res izbrisali na drugi napravi, potrdite: tu '
      'se premaknejo v koš.';
  @override
  String get syncMassTrashConfirm => 'Premakni v koš';
  @override
  String syncMassDeleteTitle(int count) => count % 100 == 1
      ? 'Izbrisati $count datoteko s strežnika?'
      : count % 100 == 2
      ? 'Izbrisati $count datoteki s strežnika?'
      : count % 100 == 3 || count % 100 == 4
      ? 'Izbrisati $count datoteke s strežnika?'
      : 'Izbrisati $count datotek s strežnika?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Tu manjka $count od $total sinhroniziranih datotek. Če '
      'jih niste izbrisali vi, prekličite in preverite mapo '
      'knjižnice.';
  @override
  String get syncMassDeleteConfirm => 'Izbriši s strežnika';
  @override
  String get syncTooltip => 'Sinhronizacija';
  @override
  String get syncStageConnecting => 'Povezovanje s strežnikom…';
  @override
  String get syncStageComparing => 'Primerjanje s strežnikom…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sinhronizacija · $done od $total';
  @override
  String get syncStatusWarnings => 'Sinhronizirana z opozorili';
  @override
  String syncConflictsHeader(int count) =>
      'Spremenjeno tu in na strežniku · $count';
  @override
  String get syncConflictHint => 'Nobena različica ni bila spremenjena';
  @override
  String get syncResolveAction => 'Razreši';
  @override
  String syncFailuresHeader(int count) => 'Ni sinhronizirano · $count';
  @override
  String get syncFailuresHint => 'Nov poskus ob naslednji sinhronizaciji';
  @override
  String get syncAbortAuth => 'Strežnik je zavrnil geslo';
  @override
  String get syncAbortMissingPassword => 'Ni shranjenega gesla';
  @override
  String get syncAbortOffline => 'Strežnik ni dosegljiv';
  @override
  String get syncAbortRemoteMissing => 'Mape na strežniku ni več';
  @override
  String get syncAbortUnsupported => 'Strežnik ne deluje več kot WebDAV';
  @override
  String get syncAbortFailed => 'Sinhronizacija ni uspela';
  @override
  String get syncAbortNotConfirmed => 'Sinhronizacija preklicana';
  @override
  String get syncAbortNothingTouched =>
      'Nobena datoteka ni bila spremenjena. Vaše spremembe '
      'ostanejo tu do naslednje uspešne sinhronizacije.';
  @override
  String syncLastSuccess(String when) => 'Zadnja uspešna sinhronizacija $when';
  @override
  String get syncNoSuccessYet => 'Še ni bilo uspešne sinhronizacije';
  @override
  String get syncUpdatePasswordAction => 'Posodobi geslo';
  @override
  String get syncRetryAction => 'Poskusi znova';
  @override
  String get syncOpenSettingsAction => 'Nastavitve';
  @override
  String get syncCloseAction => 'Zapri';
  @override
  String get syncDoneSnack => 'Sinhronizirano';
  @override
  String syncTrashedSnack(int count) => count % 100 == 1
      ? 'Sinhronizirano · $count datoteka, izbrisana drugje, je v '
            'košu'
      : count % 100 == 2
      ? 'Sinhronizirano · $count datoteki, izbrisani drugje, sta v '
            'košu'
      : count % 100 == 3 || count % 100 == 4
      ? 'Sinhronizirano · $count datoteke, izbrisane drugje, so v '
            'košu'
      : 'Sinhronizirano · $count datotek, izbrisanih drugje, je v '
            'košu';
  @override
  String syncConflictsSnack(int count) => count % 100 == 1
      ? 'Sinhronizirano · $count konflikt za razrešitev'
      : count % 100 == 2
      ? 'Sinhronizirano · $count konflikta za razrešitev'
      : count % 100 == 3 || count % 100 == 4
      ? 'Sinhronizirano · $count konflikti za razrešitev'
      : 'Sinhronizirano · $count konfliktov za razrešitev';
  @override
  String get syncShowAction => 'Prikaži';
  @override
  String get syncConflictTitle => 'Razreši konflikt';
  @override
  String get syncConflictLegend =>
      'Vrstice z oznako − so s strežnika, vrstice z oznako + s '
      'te naprave.';
  @override
  String get syncConflictBinary =>
      'To ni besedilna datoteka: izberite, katero kopijo želite '
      'obdržati.';
  @override
  String get syncConflictKeepNote =>
      'Kopija, ki je ne obdržite, ostane v zgodovini opombe.';
  @override
  String get syncKeepLocal => 'Obdrži različico te naprave';
  @override
  String get syncKeepRemote => 'Obdrži različico strežnika';
  @override
  String get syncConflictIdentical => 'Različici sta enaki';
  @override
  String get syncConflictLoadFailed => 'Obeh različic ni bilo mogoče prebrati';
  @override
  String get syncResolveFailed => 'Konflikta ni bilo mogoče razrešiti';
  @override
  String get syncResolved => 'Konflikt razrešen';
  @override
  String get syncSectionWhen => 'Kdaj sinhronizirati';
  @override
  String get syncAutoTitle => 'Samodejno';
  @override
  String get syncAutoSubtitle => 'Po urejanju, ob odprtju in v presledkih';
  @override
  String get syncIntervalTitle => 'Preveri strežnik vsakih';
  @override
  String get syncIntervalSubtitle => 'Samo dokler je aplikacija odprta';
  @override
  String get syncIntervalDialogBody =>
      'Da vidite spremembe z drugih naprav, dokler je aplikacija odprta. Pri '
      '„Nikoli” samo po urejanju in ob odprtju.';
  @override
  String syncIntervalMinutes(int count) => switch (count % 100) {
    1 => '$count minuta',
    2 => '$count minuti',
    3 || 4 => '$count minute',
    _ => '$count minut',
  };
  @override
  String get syncIntervalNever => 'Nikoli';
  @override
  String get syncWifiOnlyTitle => 'Samo Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Pri mobilnih podatkih sinhronizirajte samo ročno';
  @override
  String syncPendingChanges(int count) => switch (count % 100) {
    1 => '$count sprememba čaka',
    2 => '$count spremembi čakata',
    3 || 4 => '$count spremembe čakajo',
    _ => '$count sprememb čaka',
  };
  @override
  String syncRetryIn(String wait) => 'nov poskus čez $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Čakanje na Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Čakanje na povezavo';
  @override
  String get syncMobileDataHint =>
      '„Sinhroniziraj zdaj” kljub temu porabi mobilne podatke.';
  @override
  String get syncQueueKeptHint =>
      'Spremembe ostanejo tukaj, tudi če zaprete aplikacijo, in odidejo same, '
      'ko strežnik odgovori.';
  @override
  String get syncAutoPaused => 'Samodejna sinhronizacija je zaustavljena';
  @override
  String get syncPausedAuthHint =>
      'Nadaljuje se, ko posodobite geslo ali sinhronizirate ročno.';
  @override
  String get syncPausedServerHint =>
      'Nadaljuje se, ko popravite naslov ali sinhronizirate ročno.';
  @override
  String get syncPausedConfirmHint =>
      '„Sinhroniziraj zdaj” pokaže, kaj bi bilo odstranjeno, in prej vpraša.';
  @override
  String get syncNeedsConfirmation => 'Čaka na vašo potrditev';
  @override
  String get syncMergeIntro =>
      'Spremembe, ki se ne prekrivajo, so že združene; kjer se prekrivajo, '
      'izberite, kaj obdržati.';
  @override
  String get syncMergeClean =>
      'Različici se združita sami: nič se ne prekriva.';
  @override
  String get syncMergeNoBase =>
      'Ni skupne različice za združitev, zato je treba izbrati celotno '
      'datoteko.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Prekrivanje $index od $total';
  @override
  String get syncMergeFromLocal => 'S te naprave';
  @override
  String get syncMergeFromRemote => 'S strežnika';
  @override
  String get syncMergeRemovedLines => 'Odstranjene vrstice';
  @override
  String get syncMergeKeepLocal => 'Moje';
  @override
  String get syncMergeKeepRemote => 'Strežnikove';
  @override
  String get syncMergeKeepBoth => 'Obe';
  @override
  String get syncMergeSave => 'Shrani združitev';
  @override
  String get syncMergeKeepWhole => 'Ali obdržite eno celo kopijo';
}
