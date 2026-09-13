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
  String get newFolderTitle => 'Nova mapa';
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
}
