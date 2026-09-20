// The Croatian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class CroatianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'siječanj',
    'veljača',
    'ožujak',
    'travanj',
    'svibanj',
    'lipanj',
    'srpanj',
    'kolovoz',
    'rujan',
    'listopad',
    'studeni',
    'prosinac',
  ];
  @override
  List<String> get monthNamesShort => const [
    'sij',
    'velj',
    'ožu',
    'tra',
    'svi',
    'lip',
    'srp',
    'kol',
    'ruj',
    'lis',
    'stu',
    'pro',
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
      'Izbrisani elementi se premještaju u .trash/ (isključeno = trajno '
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
  String get debugLogsTitle => 'Dijagnostički dnevnik';
  @override
  String get debugLogsSubtitle =>
      'Pohranjuje događaje aplikacije u memo bufers';
  @override
  String get lineNumbersTitle => 'Brojevi redaka';
  @override
  String get lineNumbersSubtitle =>
      'Prikaži stupac s brojevima redaka u uređivaču napomene';
  @override
  String get readableLineLengthTitle => 'Čitljiva duljina retka';
  @override
  String get readableLineLengthSubtitle =>
      'Drži tekst bilješke u centriranom stupcu umjesto preko cijele širine '
      'prozora';
  @override
  String get noteColumnWidthTitle => 'Širina stupca';
  @override
  String get noteColumnWidthSubtitle =>
      'Koliko je širok stupac bilješke, u pikselima';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Tipkovnica pri otvaranju';
  @override
  String get keyboardOnOpenSubtitle =>
      'Prikaži tipkovnicu pri otvaranju napomene (isključeno = na prvi '
      'dodir)';
  @override
  String get editorKindSource => 'Markdown izvor';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown izvor, kako je napisan';
  @override
  String get editorKindWysiwygSubtitle =>
      'Formatirani tekst, uređuje se izravno';
  @override
  String get settingsFolderToCreate => 'za stvoriti';
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
      'Prikaži renderiranu napomenu pored izvornog uređivača';
  @override
  String get switchToWysiwygTooltip => 'Prebaci na WYSIWYG uređivač';
  @override
  String get switchToSourceTooltip => 'Prebaci na Markdown izvor';
  @override
  String get switchToSourceLabel => 'Izvor';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Ova napomena je prevelika za WYSIWYG uređivač. Otvori je kao '
      'Markdown izvor.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Izgled';
  @override
  String get settingsSectionEditor => 'Uređivač';
  @override
  String get settingsSectionLibrary => 'Biblioteka';
  @override
  String get settingsSectionReminders => 'Podsjetnici';
  @override
  String get settingsSectionShortcuts => 'Tipkovnica';
  @override
  String get keyboardShortcutsTitle => 'Tipkovnički prečaci';

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
  String get settingsAreaFolders => 'Direktorijs i putanje';
  @override
  String get settingsAreaTrashHistory => 'Korpa i hronologija';
  @override
  String get settingsAreaDiagnostics => 'Dijagnostika i info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Potrebna je povezana fizička tipkovnica';
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
  String get updateUpToDate => 'Niman je ažuran';
  @override
  String get updateCheckFailed => 'Provjera ažuriranja nije uspjela';
  @override
  String updateSavedTo(Object path) => 'Ažuriranje spremljeno u $path';
  @override
  String get updateInstallerStarted => 'Instalacijski program pokrenut';
  @override
  String get settingsSectionDiagnostics => 'Dijagnostika';
  @override
  String get settingsSpellCheckTitle => 'Kontrola pravopisa';
  @override
  String get settingsSpellCheckSubtitle =>
      'Podcrtava pravopisne greške tijekom pisanja.';
  @override
  String get spellCheckDictionaryTitle => 'Rječnik';
  @override
  String get spellCheckDictionarySystem => 'Podrazumijevano sustava';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Odabir rječnika';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Odaberi sve jezike u kojima je biblioteka napisana. Riječ prolazi '
      'ako je neki od odabranih rječnika prepoznaje; bez odabira, odlučuje '
      'jezik sustava.';
  @override
  String get spellCheckNoDictionaries =>
      'Na ovom sustavu nisu pronađeni rječnici.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Kontrola pravopisa';
  @override
  String get spellCheckTitle => 'Pravopis';
  @override
  String get spellCheckEmpty => 'Nema pravopisnih grešaka.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nije instaliran na ovom sustavu.';
  @override
  String get spellCheckNoSuggestions => 'Nema prijedloga';
  @override
  String spellCheckCount(int count) => '$count za provjeru';
  @override
  String spellCheckLine(int line) => 'redak $line';
  @override
  String get addWordToDictionary => 'Dodaj u rječnik';

  @override
  String indentWidthValue(int spaces) => '$spaces razmaka';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Svijetlost';
  @override
  String get themeBrightnessSubtitle => 'Svijetlo, tamno ili postavka uređaja';
  @override
  String get themeBrightnessSystem => 'Sustav';
  @override
  String get themeBrightnessDay => 'Svijetlo';
  @override
  String get themeBrightnessNight => 'Tamno';
  @override
  String get themePaletteTitle => 'Paleta boja';
  @override
  String get themePaletteSubtitle => 'Boje sučelja i napomene';
  @override
  String get themePaletteSystem => 'Sustav';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Veličina teksta sučelja';
  @override
  String get uiTextScaleSubtitle =>
      'Stablo, kartice i dijalozi; iznad postavke sustava';
  @override
  String get noteTextScaleTitle => 'Veličina teksta napomene';
  @override
  String get noteTextScaleSubtitle => 'Uređivač i pregled su uvijek usklađeni';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Način pregleda';
  @override
  String get previewModeSubtitle =>
      'Podijeli li pregled zaslon s uređivačem ili ga zamijeni';
  @override
  String get previewModeAuto => 'Pored';
  @override
  String get previewModeSwitch => 'Cijeli zaslon';
  @override
  String get splitRatioTitle => 'Širina omjera podjele';
  @override
  String get splitRatioSubtitle => 'Udio uređivača kada je pregled pored';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Format veze';
  @override
  String get linkTypeSubtitle => 'Što gumb veze upisuje u uređivač';
  @override
  String get linkTypeWikilink => 'Wikipoveza';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Kreiranje nedostajućih napomena u';
  @override
  String get missingNoteLocationRoot => 'Korijen biblioteke';
  @override
  String get missingNoteLocationCurrentFolder => 'Trenutni direktorij';
  @override
  String get indentWidthTitle => 'Širina uvlačenja';
  @override
  String get indentWidthSubtitle =>
      'Broj razmaka dodanih po razini uvlačenja u uređivaču';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Jezik';
  @override
  String get languageSubtitle => 'Jezik vlastitog teksta aplikacije';
  @override
  String get languageSystem => 'Sustav';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Dodaj stavku';
  @override
  String get listAddTooltip => 'Dodaj stavku';
  @override
  String get listEmpty => 'Još nema stavaka';
  @override
  String get listDragHandleLabel => 'Promijeni redoslijed stavke';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Još nema snimaka';
  @override
  String get audioRecord => 'Snimi';
  @override
  String get audioStop => 'Zaustavi';
  @override
  String get audioPlay => 'Reproduciraj';
  @override
  String get audioDelete => 'Obriši snimku';
  @override
  String get audioImport => 'Uvezi audiodatoteku';
  @override
  String get audioRecording => 'Snimanje…';
  @override
  String get audioPermissionDenied =>
      'Dopuštenje za mikrofon je odbijeno — potrebno je za snimanje.';
  @override
  String get newAudioNoteTitle => 'Nova glasovna napomena';
  @override
  String get newAudioNoteDefault => 'Moja snimka';
  @override
  String get showAudioTooltip => 'Prikaži snimke';
  @override
  String get audioMessageHint => 'Napiši napomenu…';
  @override
  String get audioSend => 'Pošalji';
  @override
  String get audioRename => 'Preimenuj snimku';
  @override
  String get audioDescriptionHint => 'Opiši ovu snimku…';
  @override
  String get audioEditDescription => 'Uredi opis';
  @override
  String get audioDeleteNote => 'Obriši napomenu';
  @override
  String get audioEditNote => 'Uredi napomenu';
  @override
  String get audioPause => 'Pauza';
  @override
  String get audioEditTitle => 'Uredi naslov';
  @override
  String get audioTitleHint => 'Naslov ove snimke…';
  @override
  String audioUntitled(int n) => 'Snimka $n';
  @override
  String get audioMoreActions => 'Više radnji';
  @override
  String get audioDiscardRecording => 'Odbaci snimku';
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
  String get shortcutQuickNote => 'Brza napomena';
  @override
  String get trayOpen => 'Otvori Niman';
  @override
  String get trayQuit => 'Izađi';
  @override
  String get closeToTrayTitle => 'Zatvori u traku obavijesti';
  @override
  String get closeToTraySubtitle =>
      '× prozora skriva Niman i ostavlja ga pokrenutim, pa podsjetnici još '
      'dolaze. Izlazi se iz izbornika ikone.';
  @override
  String get shortcutNewTodo => 'Nova zadaća';
  @override
  String get shortcutNewNote => 'Nova napomena';
  @override
  String get shortcutNewList => 'Novi popis';
  @override
  String get shortcutNewAudio => 'Nova glasovna napomena';
  @override
  String get shortcutToggleSidebar => 'Prikaži ili sakrij filter';
  @override
  String get shortcutCloseTab => 'Zatvori trenutačnu bilješku';
  @override
  String get shortcutNextTab => 'Sljedeća otvorena bilješka';
  @override
  String get shortcutPreviousTab => 'Prethodna otvorena bilješka';
  @override
  String get shortcutEditorSection => 'U uređivaču';
  @override
  String get shortcutFormatSection => 'Oblikovanje';
  @override
  String get shortcutFind => 'Traži';
  @override
  String get shortcutReplace => 'Traži i zamijeni';
  @override
  String get shortcutSavingNote =>
      'Promjene se automatski spremaju, pa ne postoji prečac za spremanje.';

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
  String get noteLoadFailed => 'Ova se bilješka nije mogla otvoriti.';
  @override
  String wordCount(int count) =>
      count % 10 == 1 && count % 100 != 11 ? '$count riječ' : '$count riječi';
  @override
  String get outlineTooltip => 'Struktura';
  @override
  String get outlineNoHeadings => 'Nema naslova';
  @override
  String get outlineNoTitle => '(bez naslova)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Podebljano';
  @override
  String get toolbarItalic => 'Kurziv';
  @override
  String get toolbarStrikethrough => 'Prekrižano';
  @override
  String get toolbarSuperscript => 'Gornji indeks';
  @override
  String get toolbarUnderline => 'Podvučeno';
  @override
  String get toolbarLink => 'Veza';
  @override
  String get toolbarCode => 'Kodni blok';
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
  String get toolbarIndent => 'Uvlačenje';
  @override
  String get toolbarOutdent => 'Ukloni uvlačenje';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Alati';
  @override
  String get editorToolsTitle => 'Alati uređivača';
  @override
  String get toolCountListTitle => 'Prebroji popis';
  @override
  String get toolCountListSubtitle =>
      'Zbraja ono što retci navode, kao popis s kvačicama';
  @override
  String get toolCountListNeedsList => 'Ova bilješka nema popis za brojanje';
  @override
  String get tallySourceLabel => 'Popis';
  @override
  String get tallyCutLabel => 'Čitaj svaki redak kao';
  @override
  String get tallyCutDash => 'Ime - vrijednosti';
  @override
  String get tallyCutColon => 'Ime: vrijednosti';
  @override
  String get tallyCutCommas => 'Vrijednosti odvojene zarezom';
  @override
  String get tallyCutWhole => 'Cijeli redak kao jedna vrijednost';
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
  String get tallyNothingToCount => 'Ovdje nema što brojati';
  @override
  String get headingDialogTitle => 'Razina naslova';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Traka alata uređivača';
  @override
  String get toolbarSettingsHint =>
      'Povuci da promijeniš redoslijed; oko prikazuje ili sakriva gumb.';
  @override
  String get toolbarShowButton => 'Prikaži';
  @override
  String get toolbarHideButton => 'Sakrij';
  @override
  String get toolbarResetOrder => 'Vrati podrazumijevano';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Prikaži pregled';
  @override
  String get showEditorTooltip => 'Prikaži uređivač';
  @override
  String get enterFullScreenTooltip => 'Cijeli zaslon';
  @override
  String get exitFullScreenTooltip => 'Izadi iz celog zaslona';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(sirova HTML tablica)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Traži po napomenama';
  @override
  String get searchModeWords => 'Riječi';
  @override
  String get searchModeContains => 'Sadrži';
  @override
  String get searchEmptyHint =>
      'Upiši za pretragu biblioteke, ili ključ = vrijednost za filtriranje '
      'po frontmatteru';
  @override
  String get searchTooShortHint => 'Upiši najmanje 2 znaka';
  @override
  String get searchNoMatches => 'Nema rezultata';
  @override
  String get searchLoadMore => 'Prikaži više';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Zamijeni…';
  @override
  String get replaceInNoteAction => 'Zamijeni u ovoj napomeni…';
  @override
  String get replaceInThisNote => 'Zamijeni u ovoj napomeni';
  @override
  String get replaceWithLabel => 'Zamijeni s';
  @override
  String get replaceCaseSensitive => 'Razlikuj velika i mala slova';
  @override
  String get replaceWholeWordsHint =>
      'zamjenjuju se samo točni rezultati cijelih riječi';
  @override
  String get replaceConfirm => 'Zamijeni';
  @override
  String get replaceCancel => 'Zatvori';
  @override
  String get replaceUnavailable => 'Zamjena trenutno nije dostupna';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Traži po napomeni';
  @override
  String get editorFindHint => 'Traži';
  @override
  String get editorReplaceHint => 'Zamijeni';
  @override
  String get editorFindCaseTooltip => 'Razlikuj velika i mala slova';
  @override
  String get editorFindPreviousTooltip => 'Prethodni rezultat';
  @override
  String get editorFindNextTooltip => 'Sljedeći rezultat';
  @override
  String get editorFindCloseTooltip => 'Zatvori pretragu';
  @override
  String get editorFindReplaceModeTooltip => 'Način zamjene';
  @override
  String get editorReplaceOneTooltip => 'Zamijeni ovaj rezultat';
  @override
  String get editorReplaceAllTooltip => 'Zamijeni sve rezultate';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Oznake';
  @override
  String get tagsTitle => 'Oznake';
  @override
  String get tagsEmpty =>
      'Još nema oznake — dodaj #oznaku ili oznake u frontmatter';
  @override
  String get tagsBackTooltip => 'Natrag na pretragu';
  @override
  String get tagsNotesEmpty => 'Nema napomene s ovom oznakom';
  @override
  String tagsNotesCapped(int limit) =>
      'Prikazuju se samo prve $limit — pretraži oznaku za ograničenje';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Veza nije pronađena';
  @override
  String get headingNotFoundTitle => 'Naslov nije pronađen';
  @override
  String get ambiguousLinkTitle => 'Više napomena odgovara';
  @override
  String get openLinkFailed => 'Veza se nije mogla otvoriti';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Napomena ne postoji';
  @override
  String missingNoteDialogBody(String path) => 'Kreirati „$path“?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Direktorij „$folder“ ne postoji';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Otvorene';
  @override
  String get todoDone => 'Završene';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Svi datumi';
  @override
  String get todoFilter => 'Filtriraj';
  @override
  String get todoNoTokens => 'Nema tokena na ovom popisu';
  @override
  String get todoCountOpen => 'otvoreno';
  @override
  String get todoCountDone => 'završeno';
  @override
  String get todoEmptyOpen => 'Još nema otvorenih zadaća';
  @override
  String get todoEmptyDone => 'Još nema završenih';
  @override
  String get todoEmptyFiltered => 'Nema zadaća koje odgovaraju';
  @override
  String get todoTitle => 'Zadaci';
  @override
  String get todoAddTooltip => 'Dodaj zadaću';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt format';
  @override
  String get todoHelpTooltip => 'Informacije o formatu';
  @override
  String get todoHelpIntro =>
      'Tvoji zadaci su obična tekstualna datoteka, jedan zadatak po retku. '
      'Niman piše sintaksu za tebe, ali ništa ne sakriva: možeš uređivati '
      'datoteku u bilo kojem uređivaču i Niman će je ponovno pročitati.';
  @override
  String get todoHelpFilesTitle => 'Dvije datoteke';
  @override
  String get todoHelpFilesBody =>
      'Otvoreni zadaci žive u todo.txt-u na korijenu biblioteke. Završiš '
      'li jedan, redak se premješta u done.txt, tako da todo.txt ostane '
      'kratak. Završeni redak koji ponovno dođe u todo.txt, Niman arhivira '
      'sljedećem čitanju datoteka.';
  @override
  String get todoHelpLineTitle => 'Anatomija retka';
  @override
  String get todoHelpLineBody =>
      'Sve što je prije opisa je opcionalno i mora doći u ovom '
      'redoslijedu:';
  @override
  String get todoHelpDoneBody =>
      'Označava zadatak kao završen. Niman ga dodaje kada označiš okviricu.';
  @override
  String get todoHelpPriority => '(A) do (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A je najviši. Prikazuje se kao grb u popisu.';
  @override
  String get todoHelpDatesBody =>
      'Rok, a zatim datum izrade. Sa jednim datumom, to je datum izrade, '
      'osim ako redak ne počinje s x.';
  @override
  String get todoHelpTokensTitle => 'Projekti, konteksti i oznake';
  @override
  String get todoHelpTokensBody =>
      'Bilo koja riječ u opisu s bilo kojim od ovih prefikxa postaje '
      'filtrirajuća oznaka. Ništa nije unaprijed definirano: token postoji '
      'dok ga pišeš.';
  @override
  String get todoHelpProjectBody =>
      'Komu projektu zadatak pripada, npr. +kuchinja ili +posao.';
  @override
  String get todoHelpContextBody =>
      'Gdje ga radiš ili kako, npr. @kod kuće ili @susretanja.';
  @override
  String get todoHelpHashtagBody =>
      'Slobodna oznaka za ono što prve dvije ne pokrivaju.';
  @override
  String get todoHelpTagsTitle => 'Datumi i podsjetnici';
  @override
  String get todoHelpTagsBody =>
      'Ove su ključ:vrijednost oznake. Niman ih piše iz dijaloga zadatka i '
      'čita ih bilo gdje se pojave na retku.';
  @override
  String get todoHelpDueBody => 'Rok. Upravlja bojom grba i filterima datuma.';
  @override
  String get todoHelpRemBody =>
      'Kada bi se trebalo poslati obavještenje, u tvojoj vremenskoj zoni. '
      'Okida se kada je zaslon ugašen i aplikacija zatvorena.';
  @override
  String get todoHelpRemDesktop =>
      'Na računaru Niman mora raditi kada dođe vrijeme: podsjetnik se '
      'prikazuje dok je aplikacija otvorena, a ništa se ne okida kada je '
      'zatvorena.';
  @override
  String get todoHelpOtherBody =>
      'Čuva se točno kao što je napisano, tako da oznake drugih todo.txt '
      'aplikacija prežive putovanje. Niman ih ne koristi, rec: included: '
      'ponavljajući se zadatak se još ne ponavlja.';
  @override
  String get todoHelpEditTitle => 'Uređivanje izvan Nimana';
  @override
  String get todoHelpEditBody =>
      'Zadatak koji ne diraš ponovno se piše bajt po bajt, uključujući '
      'čudne razmake. Uređivanjem retka, Niman ponovno piše samo taj redak u '
      'njegovu kanonskom obliku i ostavlja ostatak datoteke netaknutim.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Dodaj zadaću';
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
  String get todoDueOverdue => 'Isteklo';
  @override
  String get todoDueToday => 'Danas';
  @override
  String get todoDueNext7 => 'Sljedećih 7 dana';
  @override
  String get todoDueNoDate => 'Bez datuma';
  @override
  String get todoRowDue => 'Rok';
  @override
  String get todoRowDueToday => 'Rok danas';
  @override
  String get todoSortTooltip => 'Sortiraj';
  @override
  String get todoSortDue => 'Datum roka';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Datum izrade';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Bez prioriteta';
  @override
  String get todoNoPriorityShort => 'Nema';
  @override
  String get todoMorePriorities => 'Više…';
  @override
  String get todoPriorityTitle => 'Prioritet';
  @override
  String get todoNoDueDate => 'Bez roka';
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
  String get todoReminderChannel => 'Podsjetnici za zadatke';
  @override
  String get todoReminderChannelDescription =>
      'Zakazane obavještenja za zadatke s podsjetničkim vremenom.';
  @override
  String get todoReminderBody => 'Podsjetnik za zadatak';
  @override
  String get todoReminderFallbackTitle => 'Podsjetnik za zadatak';
  @override
  String get todoReminderBlocked =>
      'Obavještenja su isključena, tako da se podsjetnici neće prikazati.';
  @override
  String get todoReminderBattery =>
      'Optimizacija baterije je aktivna za Niman. Sustav može obustaviti '
      'aplikaciju i izgubiti čekajuće podsjetnike.';
  @override
  String get todoReminderInexact =>
      'Ovaj uređaj ne podržava točne alarme, pa podsjetnik može doći '
      'nekoliko minuta kasnije kada je zaslon ugašen.';
  @override
  String get reminderShowTokensTitle => 'Oznake u obavještenjima podsjetnika';
  @override
  String get reminderShowTokensSubtitle =>
      'Ostavi +projekt, @kontekst i #oznaku u tekstu obavještenja. '
      'Isključeno prikazuje samo napisani zadatak.';
  @override
  String get todoReminderFixAction => 'Otvori postavke';
  @override
  String get todoReminderDismissAction => 'Odbaci';
  @override
  String get todoReminderDue => 'Rok';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'U redu';
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
  String get actionRename => 'Preimenuj';
  @override
  String get actionMove => 'Premjesti';
  @override
  String get saveAndClose => 'Spremi i zatvori';
  @override
  String get closeUnsavedTitle => 'Nespremljene promjene';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” ima nespremljene promjene. '
          'Spremiti ih prije zatvaranja?';
    }
    return '${names.length} napomena ima nespremljene promjene. '
        'Spremiti ih prije zatvaranja?';
  }

  @override
  String get closeSaveFailed =>
      'Spremanje nije uspjelo; napomena ostaje otvorena.';
  @override
  String get actionRestore => 'Vrati';
  @override
  String get actionEmpty => 'Isprazni';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Sakrij bočni panel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Prikaži bočni panel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimiziraj';
  @override
  String get windowMaximizeTooltip => 'Maksimiziraj';
  @override
  String get windowRestoreTooltip => 'Vrati';
  @override
  String get windowCloseTooltip => 'Zatvori';
  @override
  String get tabFiles => 'Datoteke';
  @override
  String get tabSearch => 'Pretraga';
  @override
  String get tabSettings => 'Postavke';
  @override
  String get quickNoteTitle => 'Brza napomena';
  @override
  String get treeEmpty => 'Još nema napomena';
  @override
  String get selectANote => 'Odaberi napomenu';
  @override
  String get showListTooltip => 'Prikaži popis';
  @override
  String get editRawTooltip => 'Uredi sirovo';
  @override
  String get sortAscTooltip => 'Sortiraj A–Z';
  @override
  String get sortDescTooltip => 'Sortiraj Z–A';
  @override
  String get newNoteTitle => 'Nova napomena';
  @override
  String get newItemTooltip => 'Novo';
  @override
  String get closeMenuTooltip => 'Zatvori';
  @override
  String get newFolderTitle => 'Novi direktorij';
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
  String get newNoteHere => 'Nova napomena ovdje';
  @override
  String get newFolderHere => 'Novi direktorij ovdje';
  @override
  String get newListNoteTitle => 'Nova popisna napomena';
  @override
  String get newListNoteDefault => 'Moj popis';
  @override
  String get setAsQuickNote => 'Postavi kao brzu napomenu';
  @override
  String get currentQuickNote => 'Trenutna brza napomena';
  @override
  String get pinnedSection => 'Prikvačeno';
  @override
  String pinnedSectionCount(int count) => 'Prikvačeno · $count';
  @override
  String get templateFolderTitle => 'Direktorij predlošaka';
  @override
  String get newFromTemplateTitle => 'Novo iz predloška';
  @override
  String get newFromTemplateHere => 'Novo iz predloška ovdje';
  @override
  String get templateFormTitle => 'Popuni predložak';
  @override
  String get templateFormBacklink => 'Povezano s';
  @override
  String get templateFormNoNote => 'Bez napomene';
  @override
  String get templateFormPickNote => 'Odaberi napomenu';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Zamjenski znaci predloška';
  @override
  String get templateHelpSubtitle =>
      'Datum, naslov i ostale vrijednosti za popuniti';
  @override
  String get quickNoteSubtitle => 'Bilješka koju otvara kartica brze bilješke';
  @override
  String get listFolderSubtitle => 'Novi popisi zadataka';
  @override
  String get templateFolderSubtitle => 'Izvor za „Novo iz predloška“';
  @override
  String get attachmentsFolderSubtitle => 'Slike i zvuk umetnuti u bilješku';
  @override
  String get templateHelpIntro =>
      'Predložak je obična napomena s rupama. Kreiranjem napomene iz njega '
      'kopira se tekst i popunjavaju rupe.';
  @override
  String get templateHelpUnknown =>
      'Zamjenski znak koji Niman ne poznaje ostaje točno kao što je '
      'napisan, tako da se tipkastička greška uočava u napomeni, a ne da '
      'tiho slomi redak.';
  @override
  String get templateHelpValuesTitle => 'Vrijednosti';
  @override
  String get templateHelpTitleBody =>
      'Ime pod kojim bi napomena trebala biti kreirana.';
  @override
  String get templateHelpDateBody =>
      'Danas i trenutno vrijeme. Oboje prihvaćaju format: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum i vrijeme zajedno.';
  @override
  String get templateHelpUuidBody =>
      'Novi identifikator, različit na svakoj upotrebi.';
  @override
  String get templateHelpCounterBody =>
      'Broj koji se broji po imenu, čuva se između pokretanja: prva '
      'napomena piše 1, sljedeća 2. Isto ime u napomeni piše isti broj; '
      'spoji s |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Postavi pokazivač ovdje kada se napomena kreira; oznaka se ne '
      'upisuje. Prvi zamjenski znak pobjeđuje, bez filtera, samo nove '
      'napomene — i tipkovnica se otvara i kada je autofokus isključen.';
  @override
  String get templateHelpDatesTitle => 'Pisanje datuma';
  @override
  String get templateHelpDatesBody =>
      'Ovi označavaju dijelove datuma u formatu. Sve ostalo je doslovno, '
      'uključujući tekst u jednostrukim navodnicima. Imena mjeseci i dana u '
      'tjednu prate jezik aplikacije.';
  @override
  String get templateHelpYear => 'godina: 2026, 26';
  @override
  String get templateHelpMonth => 'mjesec: 03, 3, ožujak, ožu';
  @override
  String get templateHelpDay => 'dan: 09, 9, ponedjeljak, pon';
  @override
  String get templateHelpTime => 'sati, minute, sekunde';
  @override
  String get templateHelpWeek => 'ISO tjedan i kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filteri';
  @override
  String get templateHelpFiltersBody =>
      'Vrijednosti mogu slijediti filteri, primjenjuju se slijeva udesno.';
  @override
  String get templateHelpCaseBody =>
      'Velika slova, mala slova i prvo slovo svake riječi — riječ koju si '
      'napisao velikim slovima ostaje takva.';
  @override
  String get templateHelpSlugBody =>
      'Vezi oblik teksta, da se izgradi wikipoveza.';
  @override
  String get templateHelpPadBody =>
      'Izreži krajeve; ispunjavanje nulama do željene širine; alternativa '
      'kada je vrijednost prazna.';
  @override
  String get templateHelpShiftBody =>
      'Pomakni datum za dane, tjedne, mjeseci ili godine — idući tjedan '
      'konferencija, prošlog mjeseca datoteka.';
  @override
  String get templateHelpSnapBody =>
      'Prikvaci datum na početak ili kraj tjedna, mjeseca ili godine.';
  @override
  String get templateHelpAskTitle => 'Pitamo te nešto';
  @override
  String get templateHelpAskBody =>
      'Prije kreiranja napomene prikazuje se obrazac, jedno polje po '
      'pitanju — i jedno za povratnu vezu, ako predložak traži. Isto ime '
      'dvaput je pitanje, a njegov odgovor popunjava sve pojave — i '
      'direktorij i ime datoteke.';
  @override
  String get templateHelpAskFieldBody =>
      'Polje za upis; tekst nakon dvije dvotočke je početak.';
  @override
  String get templateHelpChoiceBody => 'Odabir iz popisa, odvojen zarezom.';
  @override
  String get templateHelpWhereTitle => 'Kamo napomena dolazi';
  @override
  String get templateHelpWhereBody =>
      'Ovo nije tekst: to su upute koje žive u niman: bloku predloškovog '
      'frontmattera. Blok se izvrši i obriše, tako da se nikad ne prikazuje '
      'u napomeni. Vrijednost može sadržavati zamjenske znake.';
  @override
  String get templateHelpFolderBody =>
      'Direktorij u koji se napomena kreira, kreira se ako ne postoji. Bez '
      'njega, napomena dolazi odakle si bio.';
  @override
  String get templateHelpFilenameBody =>
      'Kako se napomena imenuje. Predložak koji to navede, ne pita za ime.';
  @override
  String get templateHelpAppendBody =>
      'Dodaje u napomenu ako već postoji, umjesto da kreira drugu. Tako '
      'mjesec sastanaka postane jedna datoteka.';
  @override
  String get templateHelpOpenBody =>
      'Što se događa kada napomena postoji: uređivač (podrazumijevano), '
      'pregled ili ništa — napomena se arhivira i ostaješ odakle si bio.';
  @override
  String get templateHelpAroundTitle => 'Odakle je došao';
  @override
  String get templateHelpParentBody =>
      'Napomena koju odabereš u obrascu, ponuđena na zaslonu; upiši '
      '[[{{parent}}]] za povratnu vezu.';
  @override
  String get templateHelpFolderValueBody =>
      'Direktorij u kojem napomena dolazi.';
  @override
  String get templateHelpClipboardBody =>
      'Što je na međuspremniku i izbor u uređivaču kada se napomena odande '
      'pokrenula.';
  @override
  String get templateHelpIncludeTitle => 'Ponovna upotreba dijela';
  @override
  String get templateHelpIncludeBody =>
      'Umetni drugi predložak, tako da deset predložaka može podijeliti '
      'jedan kontrolni popis. Pretražuje se prvo u direktoriju predložaka, '
      '.md može se izostaviti. Njegova vlastita pitanja idu u isti obrazac.';
  @override
  String get templateHelpExampleTitle => 'Sve na jednom mjestu';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ne postoji predložak „$path”';
  @override
  String includeCycle(String path) => '⚠ „$path” uključuje sam sebe';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path” je previše duboko ugniježđen';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter nije pročitiv: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter „$template” predloška nije pročitiv, pa direktorij i '
      'ime datoteke nisu ništa učinili: $reason';
  @override
  String get templatePickerTitle => 'Odabir predloška';
  @override
  String templatePickerEmpty(String folder) =>
      'Još nema predložaka. Stavi napomenu u $folder/ i bit će predložak.';

  // Tree actions.
  @override
  String get actionPin => 'Prikvaci';
  @override
  String get actionUnpin => 'Odkvaci';
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
  String get paletteGroupLibrary => 'Knjižnica';
  @override
  String get paletteGroupGoTo => 'Idi na';
  @override
  String get commandsTitle => 'Naredbe';
  @override
  String get commandsIntro =>
      'Paleta naredbi nudi samo naredbe koje se mogu pokrenuti tamo gdje '
      'jeste. Ovdje su sve, i kada se koja prikazuje.';
  @override
  String get commandNeedNone => 'Uvijek dostupno';
  @override
  String get commandNeedOpenNote => 'Potrebna je otvorena bilješka';
  @override
  String get commandNeedWideWindow => 'Samo u širokom prozoru';
  @override
  String get commandNeedDockRoom =>
      'Potreban je prozor dovoljno širok za bočnu ploču';
  @override
  String get commandNeedDesktop => 'Samo na računalu';
  @override
  String get commandNeedNotInZen => 'Ne u Zen načinu';
  @override
  String get commandNeedZenRoom => 'Računalo, s bilješkom otvorenom u kartici';
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
  String get palettePinned => 'Prikvačeno';
  @override
  String get palettePin => 'Prikvači';
  @override
  String get paletteUnpin => 'Otkvači';
  @override
  String get palettePinFooter => 'alt+P prikvači';
  @override
  String get spellCheckScanning => 'Provjera bilješke…';
  @override
  String get spellCheckAgain => 'Provjeri ponovno';
  @override
  String spellCheckCapped(int count) =>
      'Prikazano je prvih $count: ispravite neke, zatim ponovno provjerite '
      'za ostale';
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
  String importFolderTitle(String name) => 'Uvesti „$name”?';
  @override
  String importFolderBody(int count) =>
      'Njezine Markdown datoteke ($count) kopiraju se u novu mapu knjižnice. '
      'Ispuštena mapa ostaje kakva jest.';
  @override
  String importFolderDone(String folder) => 'Uvezeno u $folder';
  @override
  String importFolderEmpty(String name) => 'Nema Markdown datoteka u $name';
  @override
  String get openFileTitle => 'Otvori datoteku';
  @override
  String get outsideFileNote =>
      'Izvan knjižnice: sprema se gdje jest, bez indeksa, bez povijesti, '
      'poveznice se ne prate';
  @override
  String get typewriterOn => 'Uključi način pisaćeg stroja';
  @override
  String get typewriterOff => 'Isključi način pisaćeg stroja';
  @override
  String get typewriterTitle => 'Način pisaćeg stroja';
  @override
  String get typewriterSubtitle =>
      'Redak koji pišete ostaje u sredini uređivača';
  @override
  String get zenMode => 'Zen način';
  @override
  String get zenModeEnter => 'Uđi u zen način';
  @override
  String get zenModeLeave => 'Izađi iz zen načina';
  @override
  String get keySpace => 'Razmaknica';
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
  String get shortcutNone => 'Bez prečaca';
  @override
  String get shortcutRestoreDefaults => 'Vrati zadano';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Vratiti sve prečace kako ih Niman isporučuje?';
  @override
  String get shortcutRevert => 'Vrati na zadano';
  @override
  String get shortcutClear => 'Ukloni prečac';
  @override
  String get shortcutCapturePrompt =>
      'Pritisnite tipke. I Esc i Tab se bilježe: izlaz je Odustani.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Dodajte Ctrl, Alt ili Meta: sama tipka služi za pisanje.';
  @override
  String get shortcutMove => 'Premjesti';
  @override
  String get shortcutUseAnyway => 'Ipak upotrijebi';
  @override
  String get shortcutUndo => 'Poništi';
  @override
  String get shortcutRedo => 'Ponovi';
  @override
  String get shortcutChange => 'Promijeni prečac';
  @override
  String shortcutCaptureTitle(String command) => 'Tipke za $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys već pripada $other. Premjestiti ovamo? $other ostaje bez prečaca.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys je i $what u tekstnim poljima i uređivaču. Ondje će ga preuzeti '
      'vaša naredba.';
  @override
  String get openFileMissing => 'Datoteka ove napomene nije na disku';
  @override
  String get openFileFailed =>
      'Ovu napomenu nije bilo moguće otvoriti izvan Nimana';

  @override
  String get movedToTrash => 'Premješteno u korpu';
  @override
  String get deletedMessage => 'Obrisano';
  @override
  String deleteToTrashConfirm(String name) => '$name se premješta u .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name se trajno briše';
  @override
  String get chooseDestination => 'Odaberi odredište';
  @override
  String get libraryRoot => 'Korijen biblioteke';
  @override
  String moveTitle(String name) => 'Premjesti $name';
  @override
  String headingLevelLabel(int level) => 'Naslov razine $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Još nema brze napomene. Odaberi postojeću napomenu ili kreiraj — '
      'brza napomena će se otvoriti ovdje.';
  @override
  String get quickNoteChooseAction => 'Odaberi napomenu…';
  @override
  String get quickNoteCreateAction => 'Kreiraj novu napomenu…';
  @override
  String get quickNoteNewTitle => 'Nova brza napomena';
  @override
  String get quickNotePickerTitle => 'Odabir brze napomene';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Novi direktorij';
  @override
  String get folderPickerEmpty => 'Još nema direktorija';
  @override
  String get listFolderTitle => 'Direktorij popisa';
  @override
  String get attachmentsFolderTitle => 'Direktorij privitaka';

  // Trash (M1).
  @override
  String get trashEmpty => 'Korpa je prazna';
  @override
  String get trashEmptyAction => 'Isprazni korpu';
  @override
  String get trashEmptyConfirm =>
      'Ovo trajno briše sve što je u korpi, uključujući elemente koje Niman '
      'nije smjestio.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se trajno briše (bez vraćanja)';
  @override
  String get trashDeletePermanently => 'Trajno obriši';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Otvori direktorij Markdown napomena kao biblioteku';
  @override
  String get openLibraryExisting => 'Otvori postojeću';
  @override
  String get openLibraryCreate => 'Kreiraj novu';
  @override
  String get openLibraryCreateTitle => 'Kreiraj novu biblioteku';
  @override
  String get openLibraryFolderName => 'Ime direktorija';
  @override
  String get openLibraryChooseFolder => 'Odaberi direktorij biblioteke';
  @override
  String get openLibraryChooseParent =>
      'Odaberi direktorij u kojem će se kreirati biblioteka';
  @override
  String get openLibraryUnsupported =>
      'Ovaj direktorij nije podržan. Odaberi direktorij iz pohrane '
      'uređaja.';
  @override
  String indexingCount(int done, int total) => '$done / $total napomena';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Tvoje biblioteke';
  @override
  String get libraryUnreachable => 'Nedostupna';
  @override
  String get libraryOpenedToday => 'Otvoreno danas';
  @override
  String get libraryOpenedYesterday => 'Otvoreno jučer';
  @override
  String libraryOpenedDaysAgo(int days) => 'Otvoreno prije $days dana';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Otvoreno ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Otvoreno sada';
  @override
  String get switchLibraryTitle => 'Promijeni biblioteku';
  @override
  String get libraryForget => 'Zaboravi';
  @override
  String libraryForgetTitle(String name) => 'Zaboraviti „$name”?';
  @override
  String get libraryForgetExplained =>
      'Nestaje s ovog popisa. Direktorij, napomene i postavke biblioteke '
      'ostaju netaknuti, a ponovno otvaranje vraća na mjesto.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Odobri pristup datotekama';
  @override
  String get storageAccessNeeded =>
      'Niman ne može čitati tvoje napomene bez „Pristup svim datotekama”. '
      'Odobri ga za otvaranje biblioteke.';
  @override
  String get storageAccessExplained =>
      'Niman čita tvoje napomene kao obične datoteke, pa Android mora dati '
      'pristup svim datotekama. Ništa se ne šalje, a čita se samo direktorij '
      'odabrane biblioteke.';
  @override
  String folderAccessDenied(Object error) =>
      'Sustav nije odobrio pristup direktoriju: $error';
  @override
  String folderPickFailed(Object error) =>
      'Odabir direktorija nije uspio: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Postavke';
  @override
  String get libraryPathTitle => 'Putanje biblioteke';
  @override
  String get reindexTitle => 'Ponovno indeksiraj odmah';
  @override
  String get reindexDone => 'Ponovno indeksiranje završeno';
  @override
  String get closeLibraryTitle => 'Zatvori biblioteku';
  @override
  String get exportLogTitle => 'Izvezi dijagnostički dnevnik';
  @override
  String get exportLogSubtitle =>
      'Spremi zabilježene događaje u datoteku koju odabereš';
  @override
  String get exportLogEmpty => 'Bufers dijagnostičkog dnevnika je prazan';
  @override
  String get quickNoteUnset => 'Nije postavljeno';
  @override
  String exportLogDone(Object target) =>
      'Dijagnostički dnevnik izvezen u $target';
  @override
  String exportLogFailed(Object error) => 'Izvoz nije uspio: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nema točnog rezultata cijele riječi za „$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Zamijenjeno $occurrences pojava „$term” u $notes napomena';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped otvorenih napomena izostavljeno)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nema točnog rezultata cijele riječi za „$term”'
      '${only == null ? '' : ' u $only'}';

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
  String get noteHistoryTitle => 'Povijest';
  @override
  String get noteMenuTooltip => 'Radnje s napomenom';
  @override
  String get historyCurrentVersion => 'Trenutna verzija';
  @override
  String get historyCurrentSubtitle => 'Napomena kakva je sada';
  @override
  String get historyToday => 'Danas';
  @override
  String get historyYesterday => 'Jučer';
  @override
  String get historyReasonSession => 'prije uređivanja';
  @override
  String get historyReasonInterval => 'tijekom uređivanja';
  @override
  String get historyReasonRestore => 'prije vraćanja';
  @override
  String get historyReasonSync => 'prije sinkronizacije';
  @override
  String get historyReasonReplace => 'prije zamjene';
  @override
  String get historyReasonUnknown => 'pronađena';
  @override
  String get historySyncBase => 'osnova sinkronizacije';
  @override
  String get historyEmpty =>
      'Još nema verzija. Niman sprema jednu kad počneš uređivati napomenu, '
      'a zatim najviše jednu svakih nekoliko minuta dok pišeš.';
  @override
  String historyKept(int kept, int limit) =>
      'Spremljene verzije: $kept od $limit';
  @override
  String get historyBaseKept =>
      'Osnova sinkronizacije čuva se i iznad ograničenja.';
  @override
  String get historyOff =>
      'Povijest je isključena za ovu biblioteku (Postavke, Biblioteka).';
  @override
  String get historyLoadFailed => 'Povijest se nije mogla pročitati';
  @override
  String get historyCompareSubtitle => 'U usporedbi s trenutnom verzijom';
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
      'Trenutni tekst najprije se sprema u povijest, pa se uvijek možeš '
      'vratiti.';
  @override
  String get historyRestoreConfirm => 'Vrati';
  @override
  String historyRestored(String when) => 'Vraćena verzija spremljena $when';
  @override
  String get historyRestoreFailed => 'Verzija se nije mogla vratiti';
  @override
  String get actionUndo => 'Poništi';
  @override
  String diffLineRange(int start, int end) => 'Retci $start–$end';
  @override
  String diffLineSingle(int line) => 'Redak $line';
  @override
  String diffUnchanged(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count nepromijenjen redak',
    (2 || 3 || 4, < 12 || > 14) => '$count nepromijenjena retka',
    _ => '$count nepromijenjenih redaka',
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
      'Bilješka se promijenila dok si bio ovdje — usporedba je osvježena.';
  @override
  String get historyVersionsTitle => 'Broj čuvanih verzija';
  @override
  String get historyVersionsSubtitle => 'Po napomeni, u .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Nijedna' : '$count';
  @override
  String get historyIntervalTitle => 'Nova verzija najviše svakih';
  @override
  String get historyIntervalSubtitle =>
      'Dok pišeš; početak uređivanja napomene uvijek sprema jednu';
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
      'Jezik kojim se govori u tvojim snimkama. Odabrati ga je točnije nego '
      'ga prepoznavati.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Kao aplikacija ($language)';
  @override
  String get transcriptionLanguageDetect => 'Prepoznaj automatski';
  @override
  String get transcriptionModelsTitle => 'Modeli transkripcije';
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
      'biblioteku i ne sinkroniziraju se.';
  @override
  String get transcriptionModelDefault => 'Zadano';
  @override
  String get transcriptionModelSlow => 'Spor';
  @override
  String get transcriptionModelHintTiny => 'Najbrži, najmanje točan';
  @override
  String get transcriptionModelHintBase => 'Dobar omjer brzine i točnosti';
  @override
  String get transcriptionModelHintSmall => 'Točniji, oko 3× sporiji';
  @override
  String get transcriptionModelHintMedium => 'Vrlo točan, spor na telefonu';
  @override
  String get transcriptionModelHintLarge => 'Najtočniji, treba puno memorije';
  @override
  String get transcriptionModelDownload => 'Preuzmi';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Izbrisati model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Oslobodit će se $size. Model možeš kasnije ponovno preuzeti.';
  @override
  String get transcriptionModelFailed =>
      'Preuzimanje nije uspjelo. Provjeri vezu i pokušaj ponovno.';
  @override
  String get actionRetry => 'Pokušaj ponovno';
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
  String get audioTranscribe => 'Transkribiraj';
  @override
  String get audioTranscribeUnsupported => 'Na ovom uređaju samo WAV snimke';
  @override
  String get transcriptionQueued => 'U redu čekanja';
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
  String get transcriptionNoSpeech => 'U ovoj snimci nije prepoznat govor';
  @override
  String get transcriptionFailed => 'Transkripcija nije uspjela';
  @override
  String get transcriptionPickModelTitle => 'Odaberi model';
  @override
  String get transcriptionPickModelBody =>
      'Transkripcija se izvodi na ovom uređaju i snimka se nikad ne šalje. '
      'Model se preuzima samo jednom.';
  @override
  String get transcriptionPickModelAction => 'Preuzmi i transkribiraj';
  @override
  String get transcriptionModelRecommended => 'Preporučeno';
  @override
  String get transcriptionExistingTitle => 'Ova snimka već ima opis';
  @override
  String get transcriptionExistingBody =>
      'Zamijeniti ga transkripcijom ili dodati transkripciju ispod?';
  @override
  String get transcriptionAppend => 'Dodaj ispod';
  @override
  String get transcriptionReplace => 'Zamijeni';
  @override
  String get settingsSectionSync => 'Sinkronizacija';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Nije postavljeno za ovu biblioteku';
  @override
  String get syncNeverSynced => 'Nikad sinkronizirano';
  @override
  String syncLastSynced(String when) => 'Sinkronizirano: $when';
  @override
  String get syncRunning => 'Sinkronizacija…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteka $library';
  @override
  String get syncUrlLabel => 'Adresa direktorija';
  @override
  String get syncUrlRequired => 'Unesite adresu poslužitelja';
  @override
  String get syncUrlHint =>
      'Direktorij mora postojati. Kopiraj adresu kako je '
      'prikazuje poslužitelj.';
  @override
  String get syncHttpWarning =>
      'Nešifrirana veza: u redu preko VPN-a ili u lokalnoj mreži.';
  @override
  String get syncUserLabel => 'Korisnik';
  @override
  String get syncUserHint =>
      'Ostavi prazno ako poslužitelj ne traži vjerodajnice.';
  @override
  String get syncPasswordLabel => 'Lozinka';
  @override
  String get syncPasswordHint =>
      'Čuva se u spremištu ključeva ovog uređaja, nikad u '
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
      'S novom adresom ili korisnikom sljedeća sinkronizacija '
      'počinje ispočetka, kao prva sinkronizacija.';
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
  String get syncCapNoEtags => 'Nema otisaka datoteka (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Uspoređujem veličinu i datum; u slučaju sumnje ponovno '
      'preuzimam';
  @override
  String get syncCapGuarded => 'Zaštićeno pisanje';
  @override
  String get syncCapUnguarded => 'Nezaštićeno pisanje';
  @override
  String get syncCapUnguardedDetail =>
      'Provjeravam datoteku na poslužitelju neposredno prije '
      'pisanja';
  @override
  String get syncCapMove => 'Preimenovanje bez ponovnog slanja';
  @override
  String get syncCapNoMove => 'Nema preimenovanja na poslužitelju';
  @override
  String get syncCapNoMoveDetail =>
      'Preimenovanje postaje brisanje i novo slanje';
  @override
  String get syncCompatibleNote =>
      'U kompatibilnom načinu sinkronizacija radi isto, uz '
      'nekoliko zahtjeva više.';
  @override
  String get syncTestInvalidUrl => 'Adresa nije valjana';
  @override
  String get syncTestInvalidUrlHint =>
      'Upiši adresu http:// ili https://, bez korisnika i '
      'lozinke u njoj.';
  @override
  String get syncTestOffline => 'Poslužitelj nije dostupan';
  @override
  String get syncTestOfflineHint =>
      'Je li VPN uključen? Adresa 10.x ili 192.168.x radi samo '
      'iz iste mreže.';
  @override
  String get syncTestAuth => 'Korisnik ili lozinka odbijeni';
  @override
  String get syncTestAuthHint => 'Provjeri ih pa testiraj ponovno.';
  @override
  String get syncTestNotFound => 'Direktorij ne postoji';
  @override
  String get syncTestNotFoundHint =>
      'Kreiraj ga na poslužitelju ili ispravi adresu.';
  @override
  String get syncTestUnsupported => 'Nije WebDAV direktorij';
  @override
  String get syncTestUnsupportedHint =>
      'Poslužitelj odgovara, ali ne kao WebDAV.';
  @override
  String get syncTestFailed => 'Test nije uspio';
  @override
  String get syncNowAction => 'Sinkroniziraj sada';
  @override
  String get syncSectionServer => 'Poslužitelj';
  @override
  String get syncServerRow => 'Adresa, korisnik i lozinka';
  @override
  String get syncRetestTitle => 'Ponovno testiraj poslužitelj';
  @override
  String syncProbedAgo(String when) => 'Zadnji test: $when';
  @override
  String get syncDisconnectTitle => 'Odspoji ovu biblioteku';
  @override
  String get syncDisconnectSubtitle =>
      'Datoteke ostaju ovdje i na poslužitelju';
  @override
  String get syncDisconnectConfirmTitle => 'Odspojiti sinkronizaciju?';
  @override
  String get syncDisconnectConfirmBody =>
      'Ova se biblioteka prestaje sinkronizirati na ovom '
      'uređaju. Nijedna datoteka se ne briše, ni ovdje ni na '
      'poslužitelju. Ako je ponovno povežeš, prva sinkronizacija '
      'počinje ispočetka.';
  @override
  String get syncDisconnectConfirm => 'Odspoji';
  @override
  String get syncFirstTitle => 'Prva sinkronizacija';
  @override
  String get syncFirstIntro =>
      'Biblioteka je uspoređena s direktorijem na poslužitelju:';
  @override
  String get syncFirstUpload => 'Za slanje';
  @override
  String get syncFirstDownload => 'Za preuzimanje';
  @override
  String get syncFirstBoth => 'Na obje strane';
  @override
  String get syncFirstBothHint =>
      'Iste: bez prijenosa. Različite: za rješavanje';
  @override
  String get syncFirstNoDelete =>
      'Prva sinkronizacija ništa ne briše, ni ovdje ni na '
      'poslužitelju.';
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
      'Sinkronizirane datoteke kojih nema na poslužitelju: '
      '$count od $total. Obično to znači pogrešnu adresu, disk '
      'NAS-a koji nije montiran ili direktorij ispražnjen '
      'greškom.';
  @override
  String get syncMassTrashHint =>
      'Ako si ih stvarno obrisao na drugom uređaju, potvrdi: '
      'ovdje idu u korpu.';
  @override
  String get syncMassTrashConfirm => 'Premjesti u korpu';
  @override
  String syncMassDeleteTitle(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Obrisati $count datoteku s poslužitelja?'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Obrisati $count datoteke s poslužitelja?'
      : 'Obrisati $count datoteka s poslužitelja?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Sinkronizirane datoteke kojih ovdje nema: $count od '
      '$total. Ako ih nisi obrisao, odustani i provjeri '
      'direktorij biblioteke.';
  @override
  String get syncMassDeleteConfirm => 'Obriši s poslužitelja';
  @override
  String get syncTooltip => 'Sinkroniziraj';
  @override
  String get syncStageConnecting => 'Povezivanje s poslužiteljem…';
  @override
  String get syncStageComparing => 'Usporedba s poslužiteljem…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sinkronizacija · $done od $total';
  @override
  String get syncStatusWarnings => 'Sinkronizirano s upozorenjima';
  @override
  String syncConflictsHeader(int count) =>
      'Promijenjeno ovdje i na poslužitelju · $count';
  @override
  String get syncConflictHint => 'Nijedna verzija nije dirana';
  @override
  String get syncResolveAction => 'Riješi';
  @override
  String syncFailuresHeader(int count) => 'Nije sinkronizirano · $count';
  @override
  String get syncFailuresHint => 'Novi pokušaj pri sljedećoj sinkronizaciji';
  @override
  String get syncAbortAuth => 'Poslužitelj je odbio lozinku';
  @override
  String get syncAbortMissingPassword => 'Nema spremljene lozinke';
  @override
  String get syncAbortOffline => 'Poslužitelj nije dostupan';
  @override
  String get syncAbortRemoteMissing =>
      'Direktorij na poslužitelju više ne postoji';
  @override
  String get syncAbortUnsupported => 'Poslužitelj više ne radi kao WebDAV';
  @override
  String get syncAbortFailed => 'Sinkronizacija nije uspjela';
  @override
  String get syncAbortNotConfirmed => 'Sinkronizacija otkazana';
  @override
  String get syncAbortNothingTouched =>
      'Nijedna datoteka nije dirana. Tvoje promjene ostaju ovdje '
      'do sljedeće uspješne sinkronizacije.';
  @override
  String syncLastSuccess(String when) =>
      'Zadnja uspješna sinkronizacija: $when';
  @override
  String get syncNoSuccessYet => 'Još nema uspješne sinkronizacije';
  @override
  String get syncUpdatePasswordAction => 'Ažuriraj lozinku';
  @override
  String get syncRetryAction => 'Pokušaj ponovno';
  @override
  String get syncOpenSettingsAction => 'Postavke';
  @override
  String get syncCloseAction => 'Zatvori';
  @override
  String get syncDoneSnack => 'Sinkronizirano';
  @override
  String syncTrashedSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Sinkronizirano · $count datoteka obrisana drugdje je u '
            'korpi'
      : count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 12 || count % 100 > 14)
      ? 'Sinkronizirano · $count datoteke obrisane drugdje su u '
            'korpi'
      : 'Sinkronizirano · $count datoteka obrisanih drugdje je u '
            'korpi';
  @override
  String syncConflictsSnack(int count) => count % 10 == 1 && count % 100 != 11
      ? 'Sinkronizirano · $count sukob za rješavanje'
      : 'Sinkronizirano · $count sukoba za rješavanje';
  @override
  String get syncShowAction => 'Prikaži';
  @override
  String get syncConflictTitle => 'Riješi sukob';
  @override
  String get syncConflictLegend =>
      'Retci označeni s − su s poslužitelja, a retci označeni s '
      '+ s ovog uređaja.';
  @override
  String get syncConflictBinary =>
      'Nije tekstualna datoteka: odaberi koju kopiju zadržati.';
  @override
  String get syncConflictKeepNote =>
      'Kopija koju ne zadržiš ostaje u povijesti napomene.';
  @override
  String get syncKeepLocal => 'Zadrži s ovog uređaja';
  @override
  String get syncKeepRemote => 'Zadrži s poslužitelja';
  @override
  String get syncConflictIdentical => 'Obje verzije su iste';
  @override
  String get syncConflictLoadFailed => 'Nije moguće pročitati obje verzije';
  @override
  String get syncResolveFailed => 'Sukob nije moguće riješiti';
  @override
  String get syncResolved => 'Sukob riješen';
  @override
  String get syncSectionWhen => 'Kada sinkronizirati';
  @override
  String get syncAutoTitle => 'Automatski';
  @override
  String get syncAutoSubtitle =>
      'Nakon uređivanja, pri otvaranju i u razmacima';
  @override
  String get syncIntervalTitle => 'Provjeri poslužitelj svakih';
  @override
  String get syncIntervalSubtitle => 'Samo dok je aplikacija otvorena';
  @override
  String get syncIntervalDialogBody =>
      'Da vidiš promjene napravljene na drugim uređajima dok je aplikacija '
      'otvorena. Uz „Nikad”, samo nakon uređivanja i pri otvaranju.';
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
      'Na mobilnim podacima sinkroniziraj samo ručno';
  @override
  String syncPendingChanges(int count) => switch ((count % 10, count % 100)) {
    (1, != 11) => '$count promjena čeka',
    (2 || 3 || 4, < 12 || > 14) => '$count promjene čekaju',
    _ => '$count promjena čeka',
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
      '„Sinkroniziraj sada” ipak koristi mobilne podatke.';
  @override
  String get syncQueueKeptHint =>
      'Promjene ostaju ovdje, čak i ako zatvoriš aplikaciju, i same odlaze '
      'kada poslužitelj odgovori.';
  @override
  String get syncAutoPaused => 'Automatska sinkronizacija je pauzirana';
  @override
  String get syncPausedAuthHint =>
      'Nastavlja se kada ažuriraš lozinku ili sinkroniziraš ručno.';
  @override
  String get syncPausedServerHint =>
      'Nastavlja se kada ispraviš adresu ili sinkroniziraš ručno.';
  @override
  String get syncPausedConfirmHint =>
      '„Sinkroniziraj sada” pokazuje što bi bilo uklonjeno i prvo pita.';
  @override
  String get syncNeedsConfirmation => 'Čeka tvoju potvrdu';
  @override
  String get syncMergeIntro =>
      'Izmjene koje se ne preklapaju već su spojene; gdje se preklapaju, '
      'odaberi što zadržati.';
  @override
  String get syncMergeClean =>
      'Dvije se verzije spajaju same: ništa se ne preklapa.';
  @override
  String get syncMergeNoBase =>
      'Nema zajedničke verzije za spajanje, pa se bira cijela datoteka.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Preklapanje $index od $total';
  @override
  String get syncMergeFromLocal => 'S ovog uređaja';
  @override
  String get syncMergeFromRemote => 'S poslužitelja';
  @override
  String get syncMergeRemovedLines => 'Uklonjeni retci';
  @override
  String get syncMergeKeepLocal => 'Moji';
  @override
  String get syncMergeKeepRemote => 'Poslužitelj';
  @override
  String get syncMergeKeepBoth => 'Oba';
  @override
  String get syncMergeSave => 'Spremi spajanje';
  @override
  String get syncMergeKeepWhole => 'Ili zadrži jednu cijelu kopiju';
}
