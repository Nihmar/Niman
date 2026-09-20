// The Bosnian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class BosnianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januar',
    'februar',
    'mart',
    'april',
    'maj',
    'juni',
    'juli',
    'august',
    'septembar',
    'oktobar',
    'novembar',
    'decembar',
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
    'ponedjeljak',
    'utorak',
    'srijeda',
    'četvrtak',
    'petak',
    'subota',
    'nedjelja',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'pon',
    'uto',
    'sri',
    'čet',
    'pet',
    'sub',
    'ned',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Korpa';
  @override
  String get trashSubtitle =>
      'Brisani elementi se premještaju u .trash/ (isključeno = trajno '
      'brisanje)';
  @override
  String get trashAutoEmptyTitle => 'Automatsko pražnjenje korpe';
  @override
  String get trashAutoEmptySubtitle =>
      'Starija brisanja nestaju zauvijek pri otvaranju biblioteke';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nikad'
      : switch ((days % 10, days % 100)) {
          (1, != 11) => '$days dan',
          _ => '$days dana',
        };
  @override
  String get debugLogsTitle => 'Dnevnik za otklanjanje grešaka';
  @override
  String get debugLogsSubtitle =>
      'Bilježi događaje aplikacije u memorijskom buferu';
  @override
  String get lineNumbersTitle => 'Brojevi redova';
  @override
  String get lineNumbersSubtitle =>
      'Prikazuje kolonu brojeva redova u uređivaču';
  @override
  String get readableLineLengthTitle => 'Čitljiva dužina reda';
  @override
  String get readableLineLengthSubtitle =>
      'Drži tekst bilješke u centriranoj koloni umjesto preko cijele širine '
      'prozora';
  @override
  String get noteColumnWidthTitle => 'Širina kolone';
  @override
  String get noteColumnWidthSubtitle =>
      'Koliko je široka kolona bilješke, u pikselima';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Tastatura pri otvaranju';
  @override
  String get keyboardOnOpenSubtitle =>
      'Prikazuje tastaturu čim se bilješka otvori (isključeno = na prvi '
      'dodir)';
  @override
  String get editorKindSource => 'Markdown izvor';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown izvor, kako je napisan';
  @override
  String get editorKindWysiwygSubtitle =>
      'Formatirani tekst, uređuje se direktno';
  @override
  String get settingsFolderToCreate => 'za napraviti';
  @override
  String get settingsSearchHint => 'Pretraži postavke';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 pronađena postavka' : '$count pronađenih postavki';
  @override
  String get settingsToggleOn => 'Uključeno';
  @override
  String get settingsToggleOff => 'Isključeno';
  @override
  String get settingsPreviewEnabledTitle => 'Pregled';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Prikazuje oblikovanu bilješku pored uređivača izvora';
  @override
  String get switchToWysiwygTooltip => 'Pređi na WYSIWYG uređivač';
  @override
  String get switchToSourceTooltip => 'Pređi na Markdown izvor';
  @override
  String get switchToSourceLabel => 'Izvor';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Ova bilješka je prevelika za WYSIWYG uređivač. Otvorite je u '
      'Markdown izvoru.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Izgled';
  @override
  String get settingsSectionEditor => 'Uređivač';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'Podsjetke';
  @override
  String get settingsSectionShortcuts => 'Tastatura';
  @override
  String get keyboardShortcutsTitle => 'Prečice na tastaturi';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteka $name';
  @override
  String get settingsGroupLibraryHint => 'važi samo za ovu biblioteku';
  @override
  String get settingsGroupMaintenance => 'Održavanje';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mape i putanje';
  @override
  String get settingsAreaTrashHistory => 'Korpa i hronologija';
  @override
  String get settingsAreaDiagnostics => 'Dijagnostika i info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Potrebna je povezana fizička tastatura';
  @override
  String get settingsSectionUpdates => 'Ažuriranja';
  @override
  String get autoUpdateTitle => 'Automatska ažuriranja';
  @override
  String get autoUpdateSubtitle =>
      'Provjerava GitHub Releases pri pokretanju i svakih 6 sati';
  @override
  String get checkForUpdatesTitle => 'Provjeri ažuriranja';
  @override
  String updateAvailableMessage(Object version) => 'Dostupan je Niman $version';
  @override
  String get updateUpToDate => 'Niman je ažuriran';
  @override
  String get updateCheckFailed => 'Provjera ažuriranja nije uspjela';
  @override
  String updateSavedTo(Object path) => 'Ažuriranje spremljeno u $path';
  @override
  String get updateInstallerStarted => 'Program za instalaciju pokrenut';
  @override
  String get settingsSectionDiagnostics => 'Dijagnostika';
  @override
  String get settingsSpellCheckTitle => 'Provjera pravopisa';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podcrtava riječi napisane s greškom dok pišete.';
  @override
  String get spellCheckDictionaryTitle => 'Rječnik';
  @override
  String get spellCheckDictionarySystem => 'Podrazumijevani sistemski';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Odaberi rječnike';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Odaberite svaki jezik na kojem je ova biblioteka napisana. Riječ '
      'prolazi kada jedan od odabranih rječnika prepoznaje; bez odabranih '
      'odlučuje sistemski jezik.';
  @override
  String get spellCheckNoDictionaries =>
      'Nijedan rječnik nije pronađen na ovom sistemu.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Provjera pravopisa';
  @override
  String get spellCheckTitle => 'Pravopis';
  @override
  String get spellCheckEmpty => 'Nema grešaka u pravopisu.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nije instaliran na ovom sistemu.';
  @override
  String get spellCheckNoSuggestions => 'Nema prijedloga';
  @override
  String spellCheckCount(int count) => '$count za pregled';
  @override
  String spellCheckLine(int line) => 'red $line';
  @override
  String get addWordToDictionary => 'Dodaj u rječnik';

  @override
  String indentWidthValue(int spaces) => '$spaces razmaka';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Osvjetljenje';
  @override
  String get themeBrightnessSubtitle =>
      'Svijetla, tamna ili onakvo kao što je uređaj podesen';
  @override
  String get themeBrightnessSystem => 'Sistem';
  @override
  String get themeBrightnessDay => 'Svijetla';
  @override
  String get themeBrightnessNight => 'Tamna';
  @override
  String get themePaletteTitle => 'Paleta';
  @override
  String get themePaletteSubtitle => 'Boje sučelja i bilješke';
  @override
  String get themePaletteSystem => 'Sistem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Veličina teksta sučelja';
  @override
  String get uiTextScaleSubtitle =>
      'Stablo, kartice i dijalozi; iznad sistemskog podešavanja';
  @override
  String get noteTextScaleTitle => 'Veličina teksta bilješke';
  @override
  String get noteTextScaleSubtitle =>
      'Uređivač i pregled, koji su uvijek u skladu';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Način pregleda';
  @override
  String get previewModeSubtitle =>
      'Da li pregled dijeli ekran s uređivačem ili ga zamjenjuje';
  @override
  String get previewModeAuto => 'Jedan pored drugog';
  @override
  String get previewModeSwitch => 'Cijeli ekran';
  @override
  String get splitRatioTitle => 'Širina podjele';
  @override
  String get splitRatioSubtitle => 'Udio uređivača kada je pregled pored njega';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Format veze';
  @override
  String get linkTypeSubtitle => 'Što gumb za veze u uređivaču umetne';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Kreiranje nedostajućih bilješki u';
  @override
  String get missingNoteLocationRoot => 'Korijen biblioteke';
  @override
  String get missingNoteLocationCurrentFolder => 'Trenutna mapa';
  @override
  String get indentWidthTitle => 'Širina uvlačenja';
  @override
  String get indentWidthSubtitle =>
      'Razmaci koji se dodaju po razini uvlačenja u uređivaču';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Jezik';
  @override
  String get languageSubtitle => 'Jezik teksta same aplikacije';
  @override
  String get languageSystem => 'Sistem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Dodaj stavku';
  @override
  String get listAddTooltip => 'Dodaj stavku';
  @override
  String get listEmpty => 'Još nema stavki';
  @override
  String get listDragHandleLabel => 'Preuredi stavku';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Još nema snimaka';
  @override
  String get audioRecord => 'Snimi';
  @override
  String get audioStop => 'Zaustavi';
  @override
  String get audioPlay => 'Pusti';
  @override
  String get audioDelete => 'Obriši snimak';
  @override
  String get audioImport => 'Uvezi audio datoteku';
  @override
  String get audioRecording => 'Snimanje…';
  @override
  String get audioPermissionDenied =>
      'Dozvola za mikrofon je odbijena — potrebna je za snimanje.';
  @override
  String get newAudioNoteTitle => 'Nova glasovna bilješka';
  @override
  String get newAudioNoteDefault => 'Moj snimak';
  @override
  String get showAudioTooltip => 'Prikaži snimke';
  @override
  String get audioMessageHint => 'Napišite bilješku…';
  @override
  String get audioSend => 'Pošalji';
  @override
  String get audioRename => 'Promijeni ime snimka';
  @override
  String get audioDescriptionHint => 'Opišite ovaj snimak…';
  @override
  String get audioEditDescription => 'Uredi opis';
  @override
  String get audioDeleteNote => 'Obriši bilješku';
  @override
  String get audioEditNote => 'Uredi bilješku';
  @override
  String get audioPause => 'Pauza';
  @override
  String get audioEditTitle => 'Uredi naslov';
  @override
  String get audioTitleHint => 'Naslov ovog snimka…';
  @override
  String audioUntitled(int n) => 'Snimak $n';
  @override
  String get audioMoreActions => 'Više radnji';
  @override
  String get audioDiscardRecording => 'Odbaci snimak';
  @override
  String get audioPauseRecording => 'Pauziraj snimanje';
  @override
  String get audioResumeRecording => 'Nastavi snimanje';
  @override
  String get audioRecordingPaused => 'Pauzirano';
  @override
  String get audioSavingRecording => 'Spremanje…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Brza bilješka';
  @override
  String get trayOpen => 'Otvori Niman';
  @override
  String get trayQuit => 'Izađi';
  @override
  String get closeToTrayTitle => 'Zatvori u traku obavještenja';
  @override
  String get closeToTraySubtitle =>
      '× prozora skriva Niman i ostavlja ga pokrenutim, pa podsjetnici još '
      'dolaze. Izlazi se iz menija ikone.';
  @override
  String get shortcutNewTodo => 'Nova zadaća';
  @override
  String get shortcutNewNote => 'Nova bilješka';
  @override
  String get shortcutNewList => 'Novi popis';
  @override
  String get shortcutNewAudio => 'Nova glasovna bilješka';
  @override
  String get shortcutToggleSidebar => 'Prikaži ili sakrij stablo datoteka';
  @override
  String get shortcutCloseTab => 'Zatvori trenutnu bilješku';
  @override
  String get shortcutNextTab => 'Sljedeća otvorena bilješka';
  @override
  String get shortcutPreviousTab => 'Prethodna otvorena bilješka';
  @override
  String get shortcutEditorSection => 'U uređivaču';
  @override
  String get shortcutFormatSection => 'Formatiranje';
  @override
  String get shortcutFind => 'Pretraga';
  @override
  String get shortcutReplace => 'Pronađi i zamijeni';
  @override
  String get shortcutSavingNote =>
      'Izmjene se automatski čuvaju, pa nema prečice za spremanje.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Učitavanje…';
  @override
  String get noteStatusSaving => 'Spremanje…';
  @override
  String get noteStatusUnsaved => 'Nespremljeno';
  @override
  String get noteStatusSaved => 'Spremljeno';
  @override
  String get noteStatusError => 'Greška';
  @override
  String get noteNotText =>
      'Ova datoteka nije tekstualna bilješka, pa je '
      'Niman ne može prikazati ovdje.';
  @override
  String get noteLoadFailed => 'Ova bilješka se nije mogla otvoriti.';
  @override
  String wordCount(int count) =>
      count % 10 == 1 && count % 100 != 11 ? '$count riječ' : '$count riječi';
  @override
  String get outlineTooltip => 'Sadržaj';
  @override
  String get outlineNoHeadings => 'Nema naslova';
  @override
  String get outlineNoTitle => '(bez naslova)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Podebljano';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'Precrtano';
  @override
  String get toolbarSuperscript => 'Superskript';
  @override
  String get toolbarUnderline => 'Podcrtano';
  @override
  String get toolbarLink => 'Veza';
  @override
  String get toolbarCode => 'Blok koda';
  @override
  String get toolbarImage => 'Umetni sliku';
  @override
  String get toolbarHeading => 'Naslov';
  @override
  String get toolbarList => 'Popis';
  @override
  String get toolbarOrderedList => 'Brojčani popis';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Uvuci';
  @override
  String get toolbarOutdent => 'Smanji uvlačenje';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Alati';
  @override
  String get editorToolsTitle => 'Alati uređivača';
  @override
  String get toolCountListTitle => 'Prebroj listu';
  @override
  String get toolCountListSubtitle =>
      'Sabira ono što redovi navode, kao listu sa kvačicama';
  @override
  String get toolCountListNeedsList => 'Ova bilješka nema listu za brojanje';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Čitaj svaki red kao';
  @override
  String get tallyCutDash => 'Ime - vrijednosti';
  @override
  String get tallyCutColon => 'Ime: vrijednosti';
  @override
  String get tallyCutCommas => 'Vrijednosti odvojene zarezom';
  @override
  String get tallyCutWhole => 'Cijeli red kao jedna vrijednost';
  @override
  String get tallySortLabel => 'Redoslijed';
  @override
  String get tallySortCount => 'Najviše prvo';
  @override
  String get tallySortAlphabetical => 'Abecedno';
  @override
  String get tallySortFirstSeen => 'Kako su navedeni';
  @override
  String get tallyInsert => 'Umetni';
  @override
  String get tallyUpdate => 'Ažuriraj';
  @override
  String get tallyNothingToCount => 'Ovdje nema šta brojati';
  @override
  String get headingDialogTitle => 'Razina naslova';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Uređivačka traka';
  @override
  String get toolbarSettingsHint =>
      'Povucite za preuređivanje; oko prikazuje ili sakriva gumb.';
  @override
  String get toolbarShowButton => 'Prikaži';
  @override
  String get toolbarHideButton => 'Sakrij';
  @override
  String get toolbarResetOrder => 'Vrati zadano';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Prikaži pregled';
  @override
  String get showEditorTooltip => 'Prikaži uređivač';
  @override
  String get enterFullScreenTooltip => 'Cijeli ekran';
  @override
  String get exitFullScreenTooltip => 'Izađi iz cijelog ekrana';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tablica sirovog HTML-a)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Pretraga bilješki';
  @override
  String get searchModeWords => 'Riječi';
  @override
  String get searchModeContains => 'Sadrži';
  @override
  String get searchEmptyHint =>
      'Ukucajte za pretragu biblioteke, ili key = value za filtriranje '
      'po frontmatter';
  @override
  String get searchTooShortHint => 'Ukucajte barem 2 znaka';
  @override
  String get searchNoMatches => 'Nema podudaranja';
  @override
  String get searchLoadMore => 'Prikaži više';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Zamijeni…';
  @override
  String get replaceInNoteAction => 'Zamijeni u ovoj bilješci…';
  @override
  String get replaceInThisNote => 'Zamijeni u ovoj bilješci';
  @override
  String get replaceWithLabel => 'Zamijeni s';
  @override
  String get replaceCaseSensitive => 'Razlikuj velika i mala slova';
  @override
  String get replaceWholeWordsHint =>
      'samo točna podudaranja cijelih riječi se zamjenjuju';
  @override
  String get replaceConfirm => 'Zamijeni';
  @override
  String get replaceCancel => 'Zatvori';
  @override
  String get replaceUnavailable => 'Zamjena trenutno nije dostupna';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Pronađi u bilješci';
  @override
  String get editorFindHint => 'Pronađi';
  @override
  String get editorReplaceHint => 'Zamijeni';
  @override
  String get editorFindCaseTooltip => 'Razlikuj veličinu slova';
  @override
  String get editorFindPreviousTooltip => 'Prethodno podudaranje';
  @override
  String get editorFindNextTooltip => 'Sljedeće podudaranje';
  @override
  String get editorFindCloseTooltip => 'Zatvori pretragu';
  @override
  String get editorFindReplaceModeTooltip => 'Način zamjene';
  @override
  String get editorReplaceOneTooltip => 'Zamijeni ovo podudaranje';
  @override
  String get editorReplaceAllTooltip => 'Zamijeni sva podudaranja';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Oznake';
  @override
  String get tagsTitle => 'Oznake';
  @override
  String get tagsEmpty =>
      'Još nema oznaka — dodajte #oznaku ili tags u frontmatter';
  @override
  String get tagsBackTooltip => 'Natrag na pretragu';
  @override
  String get tagsNotesEmpty => 'Nema bilješki s ovom oznakom';
  @override
  String tagsNotesCapped(int limit) =>
      'Navedeno je samo prvih $limit — pretražite oznaku da suzite';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Veza nije pronađena';
  @override
  String get headingNotFoundTitle => 'Naslov nije pronađen';
  @override
  String get ambiguousLinkTitle => 'Više bilješki se podudara';
  @override
  String get openLinkFailed => 'Veza se ne može otvoriti';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Bilješka ne postoji';
  @override
  String missingNoteDialogBody(String path) => 'Kreirati „$path“?';
  @override
  String missingNoteFolderMissing(String folder) => 'Mapa „$folder“ ne postoji';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Otvoreno';
  @override
  String get todoDone => 'Završeno';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Svi datumi';
  @override
  String get todoFilter => 'Filter';
  @override
  String get todoNoTokens => 'Nema tokena u ovom popisu';
  @override
  String get todoCountOpen => 'otvoreno';
  @override
  String get todoCountDone => 'završeno';
  @override
  String get todoEmptyOpen => 'Još nema otvorenih zadaća';
  @override
  String get todoEmptyDone => 'Još ništa završeno';
  @override
  String get todoEmptyFiltered => 'Nema zadaća koje se podudaraju';
  @override
  String get todoTitle => 'Zadaci';
  @override
  String get todoAddTooltip => 'Dodaj zadatak';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt format';
  @override
  String get todoHelpTooltip => 'Pomoć o formatu';
  @override
  String get todoHelpIntro =>
      'Vaši zadaci su jedna obična tekstualna datoteka, jedan zadatak po '
      'redu. Niman za vas piše sintaksu, ali ništa nije sakriveno: možete '
      'uređivati datoteku u bilo kojem uređivaču, a Niman će je pročitati '
      'natrag.';
  @override
  String get todoHelpFilesTitle => 'Dve datoteke';
  @override
  String get todoHelpFilesBody =>
      'Otvoreni zadaci stoje u todo.txt u korijenu biblioteke. '
      'Završavanje jednog premješta njegov red u done.txt, pa todo.txt '
      'ostaje kratak. Ako završen red završi opet u todo.txt, Niman ga '
      'arhivira sljedeći put kada čita datoteke.';
  @override
  String get todoHelpLineTitle => 'Anatomija reda';
  @override
  String get todoHelpLineBody =>
      'Sve prije opisa je opcionalno i mora doći u ovom poretku:';
  @override
  String get todoHelpDoneBody =>
      'Označava zadatak završenim. Niman ga dodaje kada odškrknete '
      'kućicu.';
  @override
  String get todoHelpPriority => '(A) do (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A je najviši. Prikazan kao značka u popisu.';
  @override
  String get todoHelpDatesBody =>
      'Datum završetka, pa datum kreiranja. S samo jednim datumom to je '
      'datum kreiranja, osim ako red ne počinje sa x.';
  @override
  String get todoHelpTokensTitle => 'Projekti, konteksti i oznake';
  @override
  String get todoHelpTokensBody =>
      'Gdje god u opisu, riječ s jednim od ovih prefikasa postaje čip '
      'kojom možete filtrirati. Ništa nije unaprijed definirano: token '
      'postoji čim ga navedete.';
  @override
  String get todoHelpProjectBody =>
      'Odjeljak zadatka, na primjer +gradnja ili +teza.';
  @override
  String get todoHelpContextBody =>
      'Gdje ili kako ćete ga obaviti, na primjer @doma ili @pozivi.';
  @override
  String get todoHelpHashtagBody =>
      'Slobodna oznaka, za sve što druga dva ne pokrivaju.';
  @override
  String get todoHelpTagsTitle => 'Datumi i podsjetke';
  @override
  String get todoHelpTagsBody =>
      'Ovo su key:value oznake. Niman ih piše iz dijaloga zadatka, '
      'i čita ih gdje god se pojave u redu.';
  @override
  String get todoHelpDueBody =>
      'Datum dospijeća. Vodi boju značke i filtere za dospijeće.';
  @override
  String get todoHelpRemBody =>
      'Kad poslati obavještenje, u vašem lokalnom vremenu. Pokreće se '
      'i s gašenim ekranom i zatvorenom aplikacijom.';
  @override
  String get todoHelpRemDesktop =>
      'Na desktopu Niman mora raditi kada dođe vrijeme: podsjetnik se '
      'prikazuje dok je aplikacija otvorena, a kada je zatvorena ništa se '
      'ne pokreće.';
  @override
  String get todoHelpOtherBody =>
      'Čuva se točno kao što je napisano, pa oznake iz drugih todo.txt '
      'aplikacija prežive povratak. Niman na njih ne djeluje, rec: '
      'included: ponavljajući zadatak se još ne ponavlja.';
  @override
  String get todoHelpEditTitle => 'Uređivanje izvan Nimana';
  @override
  String get todoHelpEditBody =>
      'Zadatak koji niste dodirnuli vraća se bajt po bajt, sa svim '
      'neobičnim razmacima. Uredite red, pa Niman prepisuje samo taj red '
      'u svom kanonskom obliku, ostavljajući ostatak datoteke na miru.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Dodaj zadatak';
  @override
  String get todoEditTitle => 'Uredi zadatak';
  @override
  String get todoDescriptionHint => 'Opis';
  @override
  String get todoCancel => 'Odustani';
  @override
  String get todoSave => 'Spremi';
  @override
  String get todoEditAction => 'Uredi';
  @override
  String get todoDeleteAction => 'Obriši';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Zakašnjelo';
  @override
  String get todoDueToday => 'Danas';
  @override
  String get todoDueNext7 => 'Sljedećih 7 dana';
  @override
  String get todoDueNoDate => 'Bez datuma';
  @override
  String get todoRowDue => 'Dospijeće';
  @override
  String get todoRowDueToday => 'Dospijeće danas';
  @override
  String get todoSortTooltip => 'Sortiraj';
  @override
  String get todoSortDue => 'Datum dospijeća';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Datum kreiranja';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez prioriteta';
  @override
  String get todoNoPriorityShort => 'Nijedan';
  @override
  String get todoMorePriorities => 'Više…';
  @override
  String get todoPriorityTitle => 'Prioritet';
  @override
  String get todoNoDueDate => 'Bez datuma dospijeća';
  @override
  String get todoNoReminder => 'Bez podsjetnika';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Oznaka';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Podsjetnici o zadacima';
  @override
  String get todoReminderChannelDescription =>
      'Zakazani alarmi za zadatke s vremenskim podsjetnikom.';
  @override
  String get todoReminderBody => 'Podsjetnik o zadatku';
  @override
  String get todoReminderFallbackTitle => 'Podsjetnik o zadatku';
  @override
  String get todoReminderBlocked =>
      'Obavještenja su isključena, pa podsjetnici neće izići.';
  @override
  String get todoReminderBattery =>
      'Optimizacija baterije je uključena za Niman. Sistem može zaspiti '
      'aplikaciju i odbaciti čekajuće podsjetnike.';
  @override
  String get todoReminderInexact =>
      'Ovaj uređaj ne dopušta precizne alarme, pa podsjetnik može stići '
      'nekoliko minuta kasnije s gašenim ekranom.';
  @override
  String get reminderShowTokensTitle => 'Oznake u obavještenjima podsjetnika';
  @override
  String get reminderShowTokensSubtitle =>
      'Čuva +projekt, @kontekst i #oznaku u tekstu obavještenja. '
      'Isključeno prikazuje samo zadatak koji ste naveli.';
  @override
  String get todoReminderFixAction => 'Otvori podešavanja';
  @override
  String get todoReminderDismissAction => 'Odbaci';
  @override
  String get todoReminderDue => 'Dospijeće';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Odustani';
  @override
  String get actionCreate => 'Kreiraj';
  @override
  String get actionNew => 'Novo';
  @override
  String get actionSave => 'Spremi';
  @override
  String get actionClear => 'Očisti';
  @override
  String get actionChoose => 'Odaberi';
  @override
  String get actionDelete => 'Obriši';
  @override
  String get actionRename => 'Promijeni ime';
  @override
  String get actionMove => 'Premjesti';
  @override
  String get saveAndClose => 'Spremi i zatvori';
  @override
  String get closeUnsavedTitle => 'Nespremljene izmjene';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '"${names.first}" ima izmjene koje još nisu spremljene. '
          'Spremiti prije zatvaranja?';
    }
    return 'U ${names.length} bilješki ima izmjena koje još nisu '
        'spremljene. Spremiti prije zatvaranja?';
  }

  @override
  String get closeSaveFailed =>
      'Spremanje nije uspjelo; bilješka je još otvorena.';
  @override
  String get actionRestore => 'Vrati';
  @override
  String get actionEmpty => 'Isprazni';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Sakrij bočnu ploču (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Prikaži bočnu ploču (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimiziraj';
  @override
  String get windowMaximizeTooltip => 'Maksimimiziraj';
  @override
  String get windowRestoreTooltip => 'Vrati';
  @override
  String get windowCloseTooltip => 'Zatvori';
  @override
  String get tabFiles => 'Datoteke';
  @override
  String get tabSearch => 'Pretraga';
  @override
  String get tabSettings => 'Podešavanja';
  @override
  String get quickNoteTitle => 'Brza bilješka';
  @override
  String get treeEmpty => 'Još nema bilješki';
  @override
  String get selectANote => 'Odaberi bilješku';
  @override
  String get showListTooltip => 'Prikaži popis';
  @override
  String get editRawTooltip => 'Uredi sirovo';
  @override
  String get sortAscTooltip => 'Sortiraj A-Ž';
  @override
  String get sortDescTooltip => 'Sortiraj Ž-A';
  @override
  String get newNoteTitle => 'Nova bilješka';
  @override
  String get newItemTooltip => 'Novo';
  @override
  String get closeMenuTooltip => 'Zatvori';
  @override
  String get newFolderTitle => 'Nova mapa';
  @override
  String get newNoteSameFolder => 'Nova bilješka u istoj mapi';
  @override
  String get newFromTemplateSameFolder => 'Nova iz predloška u istoj mapi';
  @override
  String trashOriginalPath(String path) => 'bilo u $path';
  @override
  String get trashOriginalRoot => 'bilo je u korijenu biblioteke';
  @override
  String trashItemCount(int count) => count == 1 ? '1 stavka' : '$count stavki';
  @override
  String get newNoteHere => 'Nova bilješka ovdje';
  @override
  String get newFolderHere => 'Nova mapa ovdje';
  @override
  String get newListNoteTitle => 'Nova bilješka-popis';
  @override
  String get newListNoteDefault => 'Moj popis';
  @override
  String get setAsQuickNote => 'Postavi kao brzu bilješku';
  @override
  String get currentQuickNote => 'Trenutna brza bilješka';
  @override
  String get pinnedSection => 'Prikvačeno';
  @override
  String pinnedSectionCount(int count) => 'Prikvačeno · $count';
  @override
  String get templateFolderTitle => 'Mapa predložaka';
  @override
  String get newFromTemplateTitle => 'Novo iz predloška';
  @override
  String get newFromTemplateHere => 'Novo iz predloška ovdje';
  @override
  String get templateFormTitle => 'Ispuni predložak';
  @override
  String get templateFormBacklink => 'Povezano iz';
  @override
  String get templateFormNoNote => 'Bez bilješke';
  @override
  String get templateFormPickNote => 'Odaberi bilješku';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Mjesta zamjene u predlošku';
  @override
  String get templateHelpSubtitle =>
      'Datum, naslov i ostale vrijednosti za popuniti';
  @override
  String get quickNoteSubtitle => 'Bilješka koju otvara kartica brze bilješke';
  @override
  String get listFolderSubtitle => 'Nove liste zadataka';
  @override
  String get templateFolderSubtitle => 'Izvor za „Novo iz šablona“';
  @override
  String get attachmentsFolderSubtitle => 'Slike i zvuk umetnuti u bilješku';
  @override
  String get templateHelpIntro =>
      'Predložak je obična bilješka s rupama. Kreiranje bilješke iz njega '
      'kopira njegov tekst i ispunjava rupe.';
  @override
  String get templateHelpUnknown =>
      'Mjesto zamjene koje Niman ne prepoznaje ostaje točno kao što je '
      'napisano, pa greška u kučanju vidi se u bilješki umjesto da tiho '
      'pojede red.';
  @override
  String get templateHelpValuesTitle => 'Vrijednosti';
  @override
  String get templateHelpTitleBody => 'Ime pod kojim se bilješka kreira.';
  @override
  String get templateHelpDateBody =>
      'Danas, i trenutačno vrijeme. Oba uzimaju format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum i vrijeme zajedno.';
  @override
  String get templateHelpUuidBody =>
      'Svježi identifikator, drugačiji na svakom pojavljivanju.';
  @override
  String get templateHelpCounterBody =>
      'Broj koji se povećava po imenu, i čuva se kroz ponovna pokretanja: '
      'prva bilješka piše 1, sljedeća 2. Isto ime u jednoj bilješki piše '
      'isti broj; spojite s |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Smeti kursor ovdje kada se bilješka kreira; sam marker se ne piše. '
      'Prvi marker pobjeđuje, bez filtera, samo nove bilješke — i '
      'tastatura se otvara čak i kada je autofokus isključen.';
  @override
  String get templateHelpDatesTitle => 'Pisanje datuma';
  @override
  String get templateHelpDatesBody =>
      'Ovi stoje za dijelove datuma u formatu. Sve ostalo je doslovno, i '
      'tekst u jednostrukim navodnicima je također doslovno. Imena mjeseci '
      'i dana u tjednu prate jezik aplikacije.';
  @override
  String get templateHelpYear => 'godina: 2026, 26';
  @override
  String get templateHelpMonth => 'mjesec: 03, 3, Mart, Mar';
  @override
  String get templateHelpDay => 'dan: 09, 9, Ponedjeljak, Pon';
  @override
  String get templateHelpTime => 'sati, minute, sekunde';
  @override
  String get templateHelpWeek => 'ISO tjedan i kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filteri';
  @override
  String get templateHelpFiltersBody =>
      'Vrijednosti mogu pratiti filteri, primjenjeni slijeva na desno.';
  @override
  String get templateHelpCaseBody =>
      'Velika slova, mala slova i prvo slovo svake riječi — riječ koju ste '
      'same pisali velikim slovom ostaje na miru.';
  @override
  String get templateHelpSlugBody =>
      'Oblik teksta za veze, za gradnju wikilinka.';
  @override
  String get templateHelpPadBody =>
      'Odrezi krajeve; popuni nulama do širine; koristi rezervu kada je '
      'vrijednost prazna.';
  @override
  String get templateHelpShiftBody =>
      'Pomakni datum za dane, tjedne, mjesece ili godine — predavanje '
      'sljedećeg tjedna, datoteka prošlog mjeseca.';
  @override
  String get templateHelpSnapBody =>
      'Prilepi datum na početak ili kraj svog tjedna, mjeseca ili godine.';
  @override
  String get templateHelpAskTitle => 'Nešto vas pita';
  @override
  String get templateHelpAskBody =>
      'Forma se pojavljuje prije kreiranja bilješke, jedno polje po '
      'pitanju — i jedno za povratnu vezu, kada predložak to želi. Ista '
      'oznaka dvaput jedno je pitanje, i njegov odgovor ispunjava sva '
      'pojavljivanja — mapu i ime datoteke uključujući.';
  @override
  String get templateHelpAskFieldBody =>
      'Polje za kučanje; tekst nakon dvije dvotočke je ono čime počinje.';
  @override
  String get templateHelpChoiceBody =>
      'Odabir iz popisa, razdvojenog zarezima.';
  @override
  String get templateHelpWhereTitle => 'Kamo bilješka ide';
  @override
  String get templateHelpWhereBody =>
      'Ovo nije tekst: to su uputstva, i žive u niman: bloku u samom '
      'frontmatter predloška. Blok se poštuje i onda se uklanja, pa se '
      'nikad ne pojavljuje u bilješci. Njihove vrijednosti mogu držati '
      'mjesta zamjene.';
  @override
  String get templateHelpFolderBody =>
      'Mapa u kojoj se bilješka kreira, pravi se ako ne postoji. Bez nje '
      'bilješka sleti tamo gdje ste bili.';
  @override
  String get templateHelpFilenameBody =>
      'Kako se bilješka zove. Predložak koji to navede ne biva pitan za '
      'ime.';
  @override
  String get templateHelpAppendBody =>
      'Dodaj bilješci ako već postoji, umjesto da pravi drugu. Ovo '
      'pretvara mjesec sastanaka u jednu datoteku.';
  @override
  String get templateHelpOpenBody =>
      'Što se događa kad bilješka postoji: uređivač (zadano), pregled ili '
      'ništa — bilješka se posloži, i vi ostajete gdje ste bili.';
  @override
  String get templateHelpAroundTitle => 'Odatle je došla';
  @override
  String get templateHelpParentBody =>
      'Bilješka koju odaberete u formi, koja sugerira onu na ekranu; '
      'napišite [[{{parent}}]] za vezu natrag na nju.';
  @override
  String get templateHelpFolderValueBody =>
      'Mapa u kojoj se bilješka završila.';
  @override
  String get templateHelpClipboardBody =>
      'Što je na međuspoju, i selekcija uređivača kada je bilješka '
      'započeta iz nje.';
  @override
  String get templateHelpIncludeTitle => 'Ponovna uporaba dijela';
  @override
  String get templateHelpIncludeBody =>
      'Umetne drugi predložak, pa deset predložaka može dijeliti jedan '
      'popis zadataka. Prvo se traži u mapi predložaka, i .md se može '
      'izostaviti. Njegova pitanja se pridružuju istoj formi.';
  @override
  String get templateHelpExampleTitle => 'Sve zajedno';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nema predloška "$path"';
  @override
  String includeCycle(String path) => '⚠ "$path" uključuje samo sebe';
  @override
  String includeTooDeep(String path) => '⚠ "$path" je ugniježdeno preduboko';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter nije pročitano: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter od "$template" nije pročitano, pa njegova mapa i ime '
      'datoteke nisu ništa učinili: $reason';
  @override
  String get templatePickerTitle => 'Odaberi predložak';
  @override
  String templatePickerEmpty(String folder) =>
      'Još nema predložaka. Stavite bilješku u $folder/ i postat će '
      'predložak.';

  // Tree actions.
  @override
  String get actionPin => 'Prikvaci';
  @override
  String get actionUnpin => 'Otkvaci';
  @override
  String get pinToWidget => 'Zakači u widget';
  @override
  String get pinnedForWidget =>
      'Zakačeno: sada postavite widget Bilješke na početni ekran';
  @override
  String get pinWidgetUnavailable =>
      'Widgeti početnog ekrana dostupni su na Androidu';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Prikaži u upravitelju datoteka';
  @override
  String get openInDefaultApp => 'Otvori u zadanoj aplikaciji';
  @override
  String get newNoteTabTooltip => 'Nova bilješka u novoj kartici';
  @override
  String get openNotesTooltip => 'Otvorene bilješke';
  @override
  String get closeTabTooltip => 'Zatvori';
  @override
  String get openInNewTab => 'Otvori u novoj kartici';
  @override
  String get splitRight => 'Podijeli desno';
  @override
  String get splitDown => 'Podijeli dolje';
  @override
  String get moveToOtherPane => 'Premjesti u drugo okno';
  @override
  String get openBeside => 'Otvori sa strane';
  @override
  String get closeAllNotes => 'Zatvori sve';
  @override
  String get sidePanelTooltip => 'Prikaži ili sakrij bočnu ploču';
  @override
  String get historyAllVersions => 'Sve verzije';
  @override
  String get commandPaletteTitle => 'Paleta naredbi';
  @override
  String get goToNoteTitle => 'Idi na bilješku';
  @override
  String get paletteGroupNote => 'Bilješka';
  @override
  String get paletteGroupEditor => 'Uređivač';
  @override
  String get paletteGroupView => 'Prikaz';
  @override
  String get paletteGroupLibrary => 'Biblioteka';
  @override
  String get paletteGroupGoTo => 'Idi na';
  @override
  String get commandsTitle => 'Komande';
  @override
  String get commandsIntro =>
      'Paleta komandi nudi samo komande koje se mogu pokrenuti tamo gdje '
      'jeste. Ovdje su sve, i kada se koja prikazuje.';
  @override
  String get commandNeedNone => 'Uvijek dostupno';
  @override
  String get commandNeedOpenNote => 'Potrebna je otvorena bilješka';
  @override
  String get commandNeedWideWindow => 'Samo u širokom prozoru';
  @override
  String get commandNeedDockRoom =>
      'Potreban je prozor dovoljno širok za bočni panel';
  @override
  String get commandNeedDesktop => 'Samo na računaru';
  @override
  String get commandNeedNotInZen => 'Ne u Zen načinu';
  @override
  String get commandNeedZenRoom => 'Računar, s bilješkom otvorenom u kartici';
  @override
  String get commandNeedPreview =>
      'S uključenim pregledom, na tekstualnoj bilješci';
  @override
  String get commandNeedTwoEditors => 'S oba uključena uređivača';
  @override
  String get paletteHint => 'Traži naredbe i bilješke';
  @override
  String get paletteNoResults => 'Nema rezultata';
  @override
  String get paletteCommands => 'Naredbe';
  @override
  String get paletteNotes => 'Bilješke';
  @override
  String get paletteFooter =>
      '↑↓ za kretanje · ↵ za odabir · esc za zatvaranje';
  @override
  String get palettePinned => 'Prikačeno';
  @override
  String get palettePin => 'Prikači';
  @override
  String get paletteUnpin => 'Otkači';
  @override
  String get palettePinFooter => 'alt+P prikači';
  @override
  String get spellCheckScanning => 'Provjera bilješke…';
  @override
  String get spellCheckAgain => 'Provjeri ponovo';
  @override
  String spellCheckCapped(int count) =>
      'Prikazano je prvih $count: ispravite neke, pa ponovo provjerite za '
      'ostale';
  @override
  String get dropHint =>
      'Ispustite Markdown datoteke da ih otvorite ili mapu da je uvezete';
  @override
  String get dropNothing =>
      'Radna površina nije predala nijednu datoteku pri tom ispuštanju.';
  @override
  String get importFolderAction => 'Uvezi';
  @override
  String dropRejected(String names) =>
      'Ovdje se otvaraju samo Markdown datoteke i mape: $names';
  @override
  String importFolderTitle(String name) => 'Uvesti „$name“?';
  @override
  String importFolderBody(int count) =>
      'Njene Markdown datoteke ($count) kopiraju se u novu mapu biblioteke. '
      'Ispuštena mapa ostaje kakva jest.';
  @override
  String importFolderDone(String folder) => 'Uvezeno u $folder';
  @override
  String importFolderEmpty(String name) => 'Nema Markdown datoteka u $name';
  @override
  String get openFileTitle => 'Otvori datoteku';
  @override
  String get outsideFileNote =>
      'Izvan biblioteke: sprema se gdje jest, bez indeksa, bez historije, '
      'veze se ne prate';
  @override
  String get typewriterOn => 'Uključi način pisaće mašine';
  @override
  String get typewriterOff => 'Isključi način pisaće mašine';
  @override
  String get typewriterTitle => 'Način pisaće mašine';
  @override
  String get formatNoteTitle => 'Posloži Markdown';
  @override
  String get formatNoteDone => 'Bilješka je posložena.';
  @override
  String get formatNoteAlreadyTidy => 'Bilješka je već bila posložena.';
  @override
  String get typewriterSubtitle => 'Red koji pišete ostaje u sredini uređivača';
  @override
  String get zenMode => 'Zen način';
  @override
  String get zenModeEnter => 'Uđi u Zen način';
  @override
  String get zenModeLeave => 'Izađi iz Zen načina';
  @override
  String get keySpace => 'Razmak';
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
  String get keyArrowUp => 'Gore';
  @override
  String get keyArrowDown => 'Dolje';
  @override
  String get keyArrowLeft => 'Lijevo';
  @override
  String get keyArrowRight => 'Desno';
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
  String get shortcutNone => 'Bez prečice';
  @override
  String get shortcutRestoreDefaults => 'Vrati zadane';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Vratiti sve prečice kako ih Niman isporučuje?';
  @override
  String get shortcutRevert => 'Vrati na zadanu';
  @override
  String get shortcutClear => 'Ukloni prečicu';
  @override
  String get shortcutCapturePrompt =>
      'Pritisnite tipke. I Esc i Tab se bilježe: izlaz je Otkaži.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Dodajte Ctrl, Alt ili Meta: sama tipka je za pisanje.';
  @override
  String get shortcutMove => 'Premjesti';
  @override
  String get shortcutUseAnyway => 'Ipak koristi';
  @override
  String get shortcutUndo => 'Poništi';
  @override
  String get shortcutRedo => 'Ponovi';
  @override
  String get shortcutChange => 'Promijeni prečicu';
  @override
  String shortcutCaptureTitle(String command) => 'Tipke za $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys je već $other. Premjestiti ovdje? $other će ostati bez prečice.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys je i $what u tekstualnim poljima i uređivaču. Tamo će je '
      'preuzeti vaša naredba.';
  @override
  String get openFileMissing => 'Datoteka ove bilješke nije na disku';
  @override
  String get openFileFailed =>
      'Ovu bilješku nije bilo moguće otvoriti izvan Nimana';

  @override
  String get movedToTrash => 'Pomaknuto u korpu';
  @override
  String get deletedMessage => 'Obrisano';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name će biti premješteno u .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name će biti trajno obrisano';
  @override
  String get chooseDestination => 'Odaberi odredište';
  @override
  String get libraryRoot => 'Korijen biblioteke';
  @override
  String moveTitle(String name) => 'Premjesti $name';
  @override
  String headingLevelLabel(int level) => 'Razina naslova $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Još nema brze bilješke. Odaberite postojeću bilješku ili kreirajte '
      'novu — brza bilješka se otvara ovdje.';
  @override
  String get quickNoteChooseAction => 'Odaberi bilješku…';
  @override
  String get quickNoteCreateAction => 'Kreiraj novu bilješku…';
  @override
  String get quickNoteNewTitle => 'Nova brza bilješka';
  @override
  String get quickNotePickerTitle => 'Odaberi brzu bilješku';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nova mapa';
  @override
  String get folderPickerEmpty => 'Još nema mapa';
  @override
  String get listFolderTitle => 'Mapa popisa';
  @override
  String get attachmentsFolderTitle => 'Mapa priloga';

  // Trash (M1).
  @override
  String get trashEmpty => 'Korpa je prazna';
  @override
  String get trashEmptyAction => 'Isprazni korpu';
  @override
  String get trashEmptyConfirm =>
      'Ovo trajno briše sve u mapi korpe, uključujući stavke koje Niman '
      'nije tamo stavio.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name će biti trajno obrisano (bez povratka)';
  @override
  String get trashDeletePermanently => 'Obriši trajno';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Otvorite mapu Markdown bilješki kao svoju biblioteku';
  @override
  String get openLibraryExisting => 'Otvori postojeću';
  @override
  String get openLibraryCreate => 'Kreiraj novu';
  @override
  String get openLibraryCreateTitle => 'Kreiraj novu biblioteku';
  @override
  String get openLibraryFolderName => 'Ime mape';
  @override
  String get openLibraryChooseFolder => 'Odaberite mapu biblioteke';
  @override
  String get openLibraryChooseParent =>
      'Odaberite mapu u kojoj će biblioteka biti kreirana';
  @override
  String get openLibraryUnsupported =>
      'Ta mapa nije podržana. Odaberite mapu na pohrani uređaja.';
  @override
  String indexingCount(int done, int total) => '$done od $total bilješki';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Vaše biblioteke';
  @override
  String get libraryUnreachable => 'Nedostupna';
  @override
  String get libraryOpenedToday => 'Otvorena danas';
  @override
  String get libraryOpenedYesterday => 'Otvorena jučer';
  @override
  String libraryOpenedDaysAgo(int days) => 'Otvorena prije $days dana';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Otvorena ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Otvori sada';
  @override
  String get switchLibraryTitle => 'Promijeni biblioteku';
  @override
  String get libraryForget => 'Zaboravi';
  @override
  String libraryForgetTitle(String name) => 'Zaboraviti "$name"?';
  @override
  String get libraryForgetExplained =>
      'Ona ide s ovog popisa. Mapa, bilješke i podešavanja biblioteke u '
      'njoj ostaju na miru, i ponovno otvaranje vraća je na mjesto.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Daj pristup datotekama';
  @override
  String get storageAccessNeeded =>
      'Niman ne može čitati vaše bilješke bez "pristupa svim datotekama". '
      'Dostavite ga da biste otvorili biblioteku.';
  @override
  String get storageAccessExplained =>
      'Niman čita vaše bilješke kao obične datoteke, pa Android mora '
      'dozvoliti pristup svim datotekama. Ništa se ne šalje u oblak, i čita '
      'se samo mapa biblioteke koju odaberete.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistem nije dao pristup mapi: $error';
  @override
  String folderPickFailed(Object error) => 'Nije moguće odabrati mapu: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Podešavanja';
  @override
  String get libraryPathTitle => 'Putanje biblioteke';
  @override
  String get reindexTitle => 'Ponovno indeksiraj odmah';
  @override
  String get reindexDone => 'Ponovno indeksirano';
  @override
  String get closeLibraryTitle => 'Zatvori biblioteku';
  @override
  String get exportLogTitle => 'Izvezi dnevnik za otklanjanje grešaka';
  @override
  String get exportLogSubtitle =>
      'Spremi zabilježene događaje u datoteku koju odaberete';
  @override
  String get exportLogEmpty =>
      'Bufer dnevnika za otklanjanje grešaka je prazan';
  @override
  String get quickNoteUnset => 'Još nije postavljeno';
  @override
  String exportLogDone(Object target) => 'Dnevnik je izvezen u $target';
  @override
  String exportLogFailed(Object error) => 'Izvoz nije uspio: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nije pronađeno točno podudaranje cijele riječi "$term"';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Zamijenjeno $occurrences pojavljivanja "$term" u $notes bilješki';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped otvorenih bilješki preskočeno)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nema točnog podudaranja cijele riječi "$term"'
      '${only == null ? 'nije pronađeno' : 'pronađeno u $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'O aplikaciji';
  @override
  String get versionTitle => 'Verzija';
  @override
  String get changelogTitle => 'Dnevnik promjena';
  @override
  String get changelogEmpty => 'Nema dostupnih zapisa u dnevniku';
  @override
  String changelogWhatsNew(String version) => 'Novo u verziji $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historija';
  @override
  String get noteMenuTooltip => 'Radnje s bilješkom';
  @override
  String get historyCurrentVersion => 'Trenutna verzija';
  @override
  String get historyCurrentSubtitle => 'Bilješka kakva je sada';
  @override
  String get historyToday => 'Danas';
  @override
  String get historyYesterday => 'Jučer';
  @override
  String get historyReasonSession => 'prije uređivanja';
  @override
  String get historyReasonInterval => 'tokom uređivanja';
  @override
  String get historyReasonRestore => 'prije vraćanja';
  @override
  String get historyReasonSync => 'prije sinhronizacije';
  @override
  String get historyReasonReplace => 'prije zamjene';
  @override
  String get historyReasonUnknown => 'pronađena';
  @override
  String get historySyncBase => 'osnova sinhronizacije';
  @override
  String get historyEmpty =>
      'Još nema verzija. Niman sprema jednu kada počneš uređivati '
      'bilješku, a zatim najviše jednu svakih nekoliko minuta dok pišeš.';
  @override
  String historyKept(int kept, int limit) =>
      'Spremljene verzije: $kept od $limit';
  @override
  String get historyBaseKept =>
      'Osnova sinhronizacije se čuva i preko ograničenja.';
  @override
  String get historyOff =>
      'Historija je isključena za ovu biblioteku '
      '(Podešavanja, Biblioteka).';
  @override
  String get historyLoadFailed => 'Historija se ne može pročitati';
  @override
  String get historyCompareSubtitle => 'U poređenju s trenutnom verzijom';
  @override
  String get historyTabChanges => 'Promjene';
  @override
  String get historyTabVersion => 'Verzija';
  @override
  String get historyNoChanges => 'Isti tekst kao trenutna verzija.';
  @override
  String get historyRestoreAction => 'Vrati ovu verziju';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Vratiti verziju spremljenu $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Trenutni tekst se prvo sprema u historiju, pa se uvijek možeš '
      'vratiti.';
  @override
  String get historyRestoreConfirm => 'Vrati';
  @override
  String historyRestored(String when) => 'Vraćena verzija spremljena $when';
  @override
  String get historyRestoreFailed => 'Verzija se ne može vratiti';
  @override
  String get actionUndo => 'Poništi';
  @override
  String diffLineRange(int start, int end) => 'Redovi $start–$end';
  @override
  String diffLineSingle(int line) => 'Red $line';
  @override
  String diffUnchanged(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count nepromijenjen red',
    (2 || 3 || 4, < 12 || > 14) => '$count nepromijenjena reda',
    _ => '$count nepromijenjenih redova',
  };
  @override
  String get historyTakeHunk => 'Vrati ovdje';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Vrati 1 promjenu' : 'Vrati $count promjena';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Odabrane promjene vraćaju se na tekst ove verzije. Bilješka u trenutnom '
      'obliku prvo se čuva kao verzija, pa ovo možeš poništiti.';
  @override
  String get historyNoteChangedReloaded =>
      'Bilješka se promijenila dok si bio ovdje — poređenje je osvježeno.';
  @override
  String get historyVersionsTitle => 'Broj čuvanih verzija';
  @override
  String get historyVersionsSubtitle => 'Po bilješci, u .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Nijedna' : '$count';
  @override
  String get historyIntervalTitle => 'Nova verzija najviše svakih';
  @override
  String get historyIntervalSubtitle =>
      'Dok pišeš; početak uređivanja bilješke uvijek sprema jednu';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkripcija';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Nijedan';
  @override
  String get transcriptionLanguageTitle => 'Jezik';
  @override
  String get transcriptionLanguageSubtitle =>
      'Jezik kojim se govori u tvojim snimcima. Odabrati ga je tačnije nego '
      'ga prepoznavati.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Kao aplikacija ($language)';
  @override
  String get transcriptionLanguageDetect => 'Prepoznaj automatski';
  @override
  String get transcriptionModelsTitle => 'Modeli za transkripciju';
  @override
  String transcriptionModelsUsed(String size) => 'Zauzeto $size';
  @override
  String get transcriptionModelsInstalled => 'Preuzeti';
  @override
  String get transcriptionModelsDownloading => 'Preuzimanje';
  @override
  String get transcriptionModelsAvailable => 'Dostupni';
  @override
  String get transcriptionModelsFooter =>
      'Modeli ostaju u pohrani aplikacije na ovom uređaju. Ne kopiraju se u '
      'biblioteku i ne sinhronizuju se.';
  @override
  String get transcriptionModelDefault => 'Zadano';
  @override
  String get transcriptionModelSlow => 'Spor';
  @override
  String get transcriptionModelHintTiny => 'Najbrži, najmanje tačan';
  @override
  String get transcriptionModelHintBase => 'Dobar omjer brzine i tačnosti';
  @override
  String get transcriptionModelHintSmall => 'Tačniji, oko 3× sporiji';
  @override
  String get transcriptionModelHintMedium => 'Vrlo tačan, spor na telefonu';
  @override
  String get transcriptionModelHintLarge => 'Najtačniji, treba mnogo memorije';
  @override
  String get transcriptionModelDownload => 'Preuzmi';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Izbrisati model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Oslobodit će se $size. Model možeš kasnije ponovo preuzeti.';
  @override
  String get transcriptionModelFailed =>
      'Preuzimanje nije uspjelo. Provjeri vezu i pokušaj ponovo.';
  @override
  String get actionRetry => 'Pokušaj ponovo';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Veza je prekinuta, ponovni pokušaj…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pauzirano na $progress';
  @override
  String get actionResume => 'Nastavi';
  @override
  String get audioTranscribe => 'Transkribuj';
  @override
  String get audioTranscribeUnsupported => 'Na ovom uređaju samo WAV snimci';
  @override
  String get transcriptionQueued => 'Na čekanju';
  @override
  String get transcriptionPreparing => 'Priprema zvuka…';
  @override
  String transcriptionRunning(int percent) => 'Transkripcija… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Preuzimanje modela $model · $percent %';
  @override
  String get transcriptionSaved => 'Transkripcija je dodana u opis';
  @override
  String get transcriptionNoSpeech => 'U ovom snimku nije prepoznat govor';
  @override
  String get transcriptionFailed => 'Transkripcija nije uspjela';
  @override
  String get transcriptionPickModelTitle => 'Odaberi model';
  @override
  String get transcriptionPickModelBody =>
      'Transkripcija se radi na ovom uređaju i snimak se nikad ne šalje. '
      'Model se preuzima samo jednom.';
  @override
  String get transcriptionPickModelAction => 'Preuzmi i transkribuj';
  @override
  String get transcriptionModelRecommended => 'Preporučeno';
  @override
  String get transcriptionExistingTitle => 'Ovaj snimak već ima opis';
  @override
  String get transcriptionExistingBody =>
      'Zamijeniti ga transkripcijom ili dodati transkripciju ispod?';
  @override
  String get transcriptionAppend => 'Dodaj ispod';
  @override
  String get transcriptionReplace => 'Zamijeni';
  @override
  String get settingsSectionSync => 'Sinhronizacija';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Nije podešeno za ovu biblioteku';
  @override
  String get syncNeverSynced => 'Nikad sinhronizovano';
  @override
  String syncLastSynced(String when) => 'Sinhronizovano $when';
  @override
  String get syncRunning => 'Sinhronizacija…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteka $library';
  @override
  String get syncUrlLabel => 'Adresa mape';
  @override
  String get syncUrlRequired => 'Unesite adresu servera';
  @override
  String get syncUrlHint =>
      'Mapa mora postojati. Kopiraj adresu onako kako je server '
      'prikazuje.';
  @override
  String get syncHttpWarning =>
      'Nešifrovana veza: u redu preko VPN-a ili u tvojoj '
      'lokalnoj mreži.';
  @override
  String get syncUserLabel => 'Korisnik';
  @override
  String get syncUserHint =>
      'Ostavi prazno ako server ne traži pristupne podatke.';
  @override
  String get syncPasswordLabel => 'Lozinka';
  @override
  String get syncPasswordHint =>
      'Čuva se u privjesku ključeva ovog uređaja, nikad u '
      'datotekama biblioteke.';
  @override
  String get syncPasswordKeepHint =>
      'Ostavi prazno da zadržiš spremljenu lozinku.';
  @override
  String get syncShowPassword => 'Prikaži lozinku';
  @override
  String get syncHidePassword => 'Sakrij lozinku';
  @override
  String get syncTestAction => 'Testiraj vezu';
  @override
  String get syncTesting => 'Testiranje…';
  @override
  String get syncRetargetWarning =>
      'S novom adresom ili korisnikom sljedeća sinhronizacija '
      'počinje ispočetka, kao prva.';
  @override
  String get syncTestOk => 'Veza radi';
  @override
  String get syncModeFull => 'Potpuni način';
  @override
  String get syncModeCompatible => 'Kompatibilni način';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Čitanje, pisanje i brisanje';
  @override
  String get syncCapEtags => 'Otisci datoteka (ETag)';
  @override
  String get syncCapNoEtags => 'Bez otisaka datoteka (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Poredi veličinu i datum; u slučaju sumnje ponovo preuzima';
  @override
  String get syncCapGuarded => 'Zaštićeno pisanje';
  @override
  String get syncCapUnguarded => 'Nezaštićeno pisanje';
  @override
  String get syncCapUnguardedDetail =>
      'Provjerava datoteku na serveru neposredno prije pisanja';
  @override
  String get syncCapMove => 'Preimenuje bez ponovnog otpremanja';
  @override
  String get syncCapNoMove => 'Bez preimenovanja na serveru';
  @override
  String get syncCapNoMoveDetail =>
      'Preimenovanje postaje brisanje i novo otpremanje';
  @override
  String get syncCompatibleNote =>
      'U kompatibilnom načinu sinhronizacija radi isto, uz nešto '
      'više zahtjeva.';
  @override
  String get syncTestInvalidUrl => 'Adresa nije ispravna';
  @override
  String get syncTestInvalidUrlHint =>
      'Unesi adresu http:// ili https://, bez korisnika i '
      'lozinke u njoj.';
  @override
  String get syncTestOffline => 'Server nije dostupan';
  @override
  String get syncTestOfflineHint =>
      'Je li VPN uključen? Adresa 10.x ili 192.168.x radi samo '
      'iz iste mreže.';
  @override
  String get syncTestAuth => 'Korisnik ili lozinka odbijeni';
  @override
  String get syncTestAuthHint => 'Provjeri ih i testiraj ponovo.';
  @override
  String get syncTestNotFound => 'Mapa ne postoji';
  @override
  String get syncTestNotFoundHint =>
      'Napravi je na serveru ili ispravi adresu.';
  @override
  String get syncTestUnsupported => 'Nije WebDAV mapa';
  @override
  String get syncTestUnsupportedHint => 'Server odgovara, ali ne kao WebDAV.';
  @override
  String get syncTestFailed => 'Test nije uspio';
  @override
  String get syncNowAction => 'Sinhronizuj sada';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresa, korisnik i lozinka';
  @override
  String get syncRetestTitle => 'Ponovo testiraj server';
  @override
  String syncProbedAgo(String when) => 'Posljednji test: $when';
  @override
  String get syncDisconnectTitle => 'Odspoji ovu biblioteku';
  @override
  String get syncDisconnectSubtitle => 'Datoteke ostaju ovdje i na serveru';
  @override
  String get syncDisconnectConfirmTitle => 'Odspojiti sinhronizaciju?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ova biblioteka prestaje da se sinhronizuje na ovom '
      'uređaju. Nijedna datoteka se ne briše, ni ovdje ni na '
      'serveru. Ako je ponovo povežeš, prva sinhronizacija '
      'počinje ispočetka.';
  @override
  String get syncDisconnectConfirm => 'Odspoji';
  @override
  String get syncFirstTitle => 'Prva sinhronizacija';
  @override
  String get syncFirstIntro => 'Biblioteka je upoređena s mapom na serveru:';
  @override
  String get syncFirstUpload => 'Za otpremanje';
  @override
  String get syncFirstDownload => 'Za preuzimanje';
  @override
  String get syncFirstBoth => 'Na obje strane';
  @override
  String get syncFirstBothHint =>
      'Iste: bez prijenosa. Različite: za rješavanje';
  @override
  String get syncFirstNoDelete =>
      'Prva sinhronizacija ništa ne briše, ni ovdje ni na '
      'serveru.';
  @override
  String get syncStartAction => 'Pokreni';
  @override
  String syncMassTrashTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Premjestiti $count datoteku u korpu?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Premjestiti $count datoteke u korpu?'
      : 'Premjestiti $count datoteka u korpu?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Na serveru nedostaje $count od $total sinhronizovanih '
      'datoteka. To obično znači pogrešnu adresu, nemontiran '
      'disk NAS-a ili mapu ispražnjenu greškom.';
  @override
  String get syncMassTrashHint =>
      'Ako su stvarno obrisane na drugom uređaju, potvrdi: ovdje '
      'idu u korpu.';
  @override
  String get syncMassTrashConfirm => 'Premjesti u korpu';
  @override
  String syncMassDeleteTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Obrisati $count datoteku sa servera?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Obrisati $count datoteke sa servera?'
      : 'Obrisati $count datoteka sa servera?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Ovdje nedostaje $count od $total sinhronizovanih '
      'datoteka. Ako nisu obrisane namjerno, odustani i provjeri '
      'mapu biblioteke.';
  @override
  String get syncMassDeleteConfirm => 'Obriši sa servera';
  @override
  String get syncTooltip => 'Sinhronizuj';
  @override
  String get syncStageConnecting => 'Povezivanje sa serverom…';
  @override
  String get syncStageComparing => 'Poređenje sa serverom…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sinhronizacija · $done od $total';
  @override
  String get syncStatusWarnings => 'Sinhronizovano s upozorenjima';
  @override
  String syncConflictsHeader(int count) =>
      'Izmijenjeno ovdje i na serveru · $count';
  @override
  String get syncConflictHint => 'Nijedna verzija nije dirana';
  @override
  String get syncResolveAction => 'Riješi';
  @override
  String syncFailuresHeader(int count) => 'Nije sinhronizovano · $count';
  @override
  String get syncFailuresHint => 'Ponovni pokušaj pri sljedećoj sinhronizaciji';
  @override
  String get syncAbortAuth => 'Server je odbio lozinku';
  @override
  String get syncAbortMissingPassword => 'Nema spremljene lozinke';
  @override
  String get syncAbortOffline => 'Server nije dostupan';
  @override
  String get syncAbortRemoteMissing => 'Mapa na serveru više ne postoji';
  @override
  String get syncAbortUnsupported => 'Server više ne radi kao WebDAV';
  @override
  String get syncAbortFailed => 'Sinhronizacija nije uspjela';
  @override
  String get syncAbortNotConfirmed => 'Sinhronizacija otkazana';
  @override
  String get syncAbortNothingTouched =>
      'Nijedna datoteka nije dirana. Tvoje izmjene ostaju ovdje '
      'do sljedeće uspješne sinhronizacije.';
  @override
  String syncLastSuccess(String when) =>
      'Posljednja uspješna sinhronizacija: $when';
  @override
  String get syncNoSuccessYet => 'Još nema uspješne sinhronizacije';
  @override
  String get syncUpdatePasswordAction => 'Ažuriraj lozinku';
  @override
  String get syncRetryAction => 'Pokušaj ponovo';
  @override
  String get syncOpenSettingsAction => 'Podešavanja';
  @override
  String get syncCloseAction => 'Zatvori';
  @override
  String get syncDoneSnack => 'Sinhronizovano';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Sinhronizovano · $count datoteka obrisana drugdje je u '
            'korpi'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Sinhronizovano · $count datoteke obrisane drugdje su u '
            'korpi'
      : 'Sinhronizovano · $count datoteka obrisanih drugdje je u '
            'korpi';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Sinhronizovano · $count konflikt za rješavanje'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Sinhronizovano · $count konflikta za rješavanje'
      : 'Sinhronizovano · $count konflikata za rješavanje';
  @override
  String get syncShowAction => 'Prikaži';
  @override
  String get syncConflictTitle => 'Riješi konflikt';
  @override
  String get syncConflictLegend =>
      'Redovi označeni s − su sa servera, redovi označeni s + s '
      'ovog uređaja.';
  @override
  String get syncConflictBinary =>
      'Nije tekstualna datoteka: odaberi koju kopiju zadržati.';
  @override
  String get syncConflictKeepNote =>
      'Kopija koju ne zadržiš ostaje u historiji bilješke.';
  @override
  String get syncKeepLocal => 'Zadrži verziju s ovog uređaja';
  @override
  String get syncKeepRemote => 'Zadrži verziju sa servera';
  @override
  String get syncConflictIdentical => 'Dvije verzije su identične';
  @override
  String get syncConflictLoadFailed => 'Obje verzije se ne mogu pročitati';
  @override
  String get syncResolveFailed => 'Konflikt se ne može riješiti';
  @override
  String get syncResolved => 'Konflikt riješen';
  @override
  String get syncSectionWhen => 'Kada sinhronizovati';
  @override
  String get syncAutoTitle => 'Automatski';
  @override
  String get syncAutoSubtitle => 'Nakon izmjena, pri otvaranju i u razmacima';
  @override
  String get syncIntervalTitle => 'Provjeri server svakih';
  @override
  String get syncIntervalSubtitle => 'Samo dok je aplikacija otvorena';
  @override
  String get syncIntervalDialogBody =>
      'Da vidiš izmjene napravljene na drugim uređajima dok je aplikacija '
      'otvorena. Uz „Nikad”, samo nakon izmjena i pri otvaranju.';
  @override
  String syncIntervalMinutes(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count minuta',
    (2 || 3 || 4, < 12 || > 14) => '$count minute',
    _ => '$count minuta',
  };
  @override
  String get syncIntervalNever => 'Nikad';
  @override
  String get syncWifiOnlyTitle => 'Samo Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Na mobilnim podacima sinhronizuj samo ručno';
  @override
  String syncPendingChanges(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count izmjena čeka',
    (2 || 3 || 4, < 12 || > 14) => '$count izmjene čekaju',
    _ => '$count izmjena čeka',
  };
  @override
  String syncRetryIn(String wait) => 'novi pokušaj za $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Čeka se Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Čeka se veza';
  @override
  String get syncMobileDataHint =>
      '„Sinhronizuj sada” ipak koristi mobilne podatke.';
  @override
  String get syncQueueKeptHint =>
      'Izmjene ostaju ovdje, čak i ako zatvoriš aplikaciju, i same odlaze kada '
      'server odgovori.';
  @override
  String get syncAutoPaused => 'Automatska sinhronizacija je pauzirana';
  @override
  String get syncPausedAuthHint =>
      'Nastavlja se kada ažuriraš lozinku ili sinhronizuješ ručno.';
  @override
  String get syncPausedServerHint =>
      'Nastavlja se kada ispraviš adresu ili sinhronizuješ ručno.';
  @override
  String get syncPausedConfirmHint =>
      '„Sinhronizuj sada” pokazuje šta bi bilo uklonjeno i prvo pita.';
  @override
  String get syncNeedsConfirmation => 'Čeka tvoju potvrdu';
  @override
  String get syncMergeIntro =>
      'Izmjene koje se ne preklapaju već su spojene; gdje se preklapaju, '
      'odaberi šta zadržati.';
  @override
  String get syncMergeClean =>
      'Dvije verzije se spajaju same: ništa se ne preklapa.';
  @override
  String get syncMergeNoBase =>
      'Nema zajedničke verzije za spajanje, pa se bira cijela datoteka.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Preklapanje $index od $total';
  @override
  String get syncMergeFromLocal => 'S ovog uređaja';
  @override
  String get syncMergeFromRemote => 'Sa servera';
  @override
  String get syncMergeRemovedLines => 'Uklonjeni redovi';
  @override
  String get syncMergeKeepLocal => 'Moji';
  @override
  String get syncMergeKeepRemote => 'Serverski';
  @override
  String get syncMergeKeepBoth => 'Oba';
  @override
  String get syncMergeSave => 'Sačuvaj spajanje';
  @override
  String get syncMergeKeepWhole => 'Ili zadrži jednu cijelu kopiju';
}
