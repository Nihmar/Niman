// The Dutch strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class DutchStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januari',
    'februari',
    'maart',
    'april',
    'mei',
    'juni',
    'juli',
    'augustus',
    'september',
    'oktober',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mrt',
    'apr',
    'mei',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'maandag',
    'dinsdag',
    'woensdag',
    'donderdag',
    'vrijdag',
    'zaterdag',
    'zondag',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'ma',
    'di',
    'wo',
    'do',
    'vr',
    'za',
    'zo',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Prullenbak';
  @override
  String get trashSubtitle =>
      'Verwijderingen gaan naar .trash/ (uit = definitief verwijderen)';
  @override
  String get trashAutoEmptyTitle => 'Prullenbak automatisch legen';
  @override
  String get trashAutoEmptySubtitle =>
      'Oudere verwijderingen verdwijnen bij het openen';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nooit'
      : days == 1
      ? '1 dag'
      : '$days dagen';
  @override
  String get debugLogsTitle => 'Debuglogs';
  @override
  String get debugLogsSubtitle =>
      'App-evenementen in een buffer in het geheugen vastleggen';
  @override
  String get lineNumbersTitle => 'Regelnummers';
  @override
  String get lineNumbersSubtitle =>
      'Toon de kolom met regelnummers in de notitie-editor';
  @override
  String get readableLineLengthTitle => 'Leesbare regellengte';
  @override
  String get readableLineLengthSubtitle =>
      'De tekst van een notitie in een gecentreerde kolom houden in plaats van '
      'over de hele vensterbreedte';
  @override
  String get noteColumnWidthTitle => 'Kolombreedte';
  @override
  String get noteColumnWidthSubtitle =>
      'Hoe breed de kolom van de notitie is, in pixels';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Toetsenbord bij openen';
  @override
  String get keyboardOnOpenSubtitle =>
      'Toon het toetsenbord zodra een notitie opent (uit = bij de eerste tik)';
  @override
  String get editorKindSource => 'Markdown-brontekst';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown-bron, zoals geschreven';
  @override
  String get editorKindWysiwygSubtitle => 'Opgemaakte tekst, direct bewerkt';
  @override
  String get settingsFolderToCreate => 'aan te maken';
  @override
  String get settingsSearchHint => 'Zoeken in instellingen';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 instelling gevonden' : '$count instellingen gevonden';
  @override
  String get settingsToggleOn => 'Aan';
  @override
  String get settingsToggleOff => 'Uit';
  @override
  String get settingsPreviewEnabledTitle => 'Voorbeeld';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Toon de gerenderde notitie naast de brontekst-editor';
  @override
  String get switchToWysiwygTooltip => 'Over naar de WYSIWYG-editor';
  @override
  String get switchToSourceTooltip => 'Over naar de Markdown-brontekst';
  @override
  String get switchToSourceLabel => 'Bron';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Deze notitie is te groot voor de WYSIWYG-editor. Open hem in de '
      'Markdown-brontekst.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Uiterlijk';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliotheek';
  @override
  String get settingsSectionReminders => 'Herinneringen';
  @override
  String get settingsSectionShortcuts => 'Toetsenbord';
  @override
  String get keyboardShortcutsTitle => 'Sneltoetsen';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bibliotheek $name';
  @override
  String get settingsGroupLibraryHint => 'geldt alleen voor deze bibliotheek';
  @override
  String get settingsGroupMaintenance => 'Onderhoud';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Mappen en paden';
  @override
  String get settingsAreaTrashHistory => 'Prullenbak en chronologie';
  @override
  String get settingsAreaDiagnostics => 'Diagnostiek en info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Vereist een aangesloten fysiek toetsenbord';
  @override
  String get settingsSectionUpdates => 'Updates';
  @override
  String get autoUpdateTitle => 'Automatische updates';
  @override
  String get autoUpdateSubtitle =>
      'GitHub Releases controleren bij het opstarten en elke 6 uur';
  @override
  String get checkForUpdatesTitle => 'Controleren op updates';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version is beschikbaar';
  @override
  String get updateUpToDate => 'Niman is up-to-date';
  @override
  String get updateCheckFailed => 'Controleren op updates mislukt';
  @override
  String updateSavedTo(Object path) => 'Update opgeslagen in $path';
  @override
  String get updateInstallerStarted => 'Installatieprogramma gestart';
  @override
  String get settingsSectionDiagnostics => 'Diagnostiek';
  @override
  String get settingsSpellCheckTitle => 'Spellingscontrole';
  @override
  String get settingsSpellCheckSubtitle =>
      'Onderstreep foutjes terwijl je typt.';
  @override
  String get spellCheckDictionaryTitle => 'Woordenboek';
  @override
  String get spellCheckDictionarySystem => 'Systeemstandaard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Woordenboeken kiezen';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Kies elke taal waarin deze bibliotheek is geschreven. Een woord '
      'slaat als een gekozen woordenboek het kent; zonder keuzes beslist de '
      'systeemtaal.';
  @override
  String get spellCheckNoDictionaries =>
      'Geen woordenboeken gevonden op dit systeem.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Spellingscontrole';
  @override
  String get spellCheckTitle => 'Spelling';
  @override
  String get spellCheckEmpty => 'Geen spelfouten.';
  @override
  String get spellCheckUnavailable =>
      'hunspell is niet geïnstalleerd op dit systeem.';
  @override
  String get spellCheckNoSuggestions => 'Geen suggesties';
  @override
  String spellCheckCount(int count) => '$count te controleren';
  @override
  String spellCheckLine(int line) => 'regel $line';
  @override
  String get addWordToDictionary => 'Toevoegen aan woordenlijst';

  @override
  String indentWidthValue(int spaces) => '$spaces spaties';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Helderheid';
  @override
  String get themeBrightnessSubtitle =>
      'Licht, donker of wat het apparaat is ingesteld op';
  @override
  String get themeBrightnessSystem => 'Systeem';
  @override
  String get themeBrightnessDay => 'Licht';
  @override
  String get themeBrightnessNight => 'Donker';
  @override
  String get themePaletteTitle => 'Kleurenpalet';
  @override
  String get themePaletteSubtitle =>
      'De kleuren van de interface en van de notitie';
  @override
  String get themePaletteSystem => 'Systeem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Interface-tekstgrootte';
  @override
  String get uiTextScaleSubtitle =>
      'De boom, de tabbladen en de dialoogvensters; bovenop de '
      'systeeminstelling';
  @override
  String get noteTextScaleTitle => 'Notitie-tekstgrootte';
  @override
  String get noteTextScaleSubtitle =>
      'De editor en het voorbeeld, die altijd overeenkomen';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Voorbeeldmodus';
  @override
  String get previewModeSubtitle =>
      'Of het voorbeeld het scherm deelt met de editor, of hem vervangt';
  @override
  String get previewModeAuto => 'Naast elkaar';
  @override
  String get previewModeSwitch => 'Volledig scherm';
  @override
  String get splitRatioTitle => 'Indelingsbreedte';
  @override
  String get splitRatioSubtitle =>
      'Het aandeel van de editor als het voorbeeld naast elkaar staat';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Linkformaat';
  @override
  String get linkTypeSubtitle => 'Wat de linkknop in de editor invoegt';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Ontbrekende notities maken in';
  @override
  String get missingNoteLocationRoot => 'Bibliotheek-wortel';
  @override
  String get missingNoteLocationCurrentFolder => 'Huidige map';
  @override
  String get indentWidthTitle => 'Inspringbreedte';
  @override
  String get indentWidthSubtitle =>
      'Spaties die per inspringingsniveau in de editor worden toegevoegd';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Taal';
  @override
  String get languageSubtitle => 'De taal van de tekst van de app zelf';
  @override
  String get languageSystem => 'Systeem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Item toevoegen';
  @override
  String get listAddTooltip => 'Item toevoegen';
  @override
  String get listEmpty => 'Nog geen items';
  @override
  String get listDragHandleLabel => 'Item van plaats verwisselen';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Nog geen opnamen';
  @override
  String get audioRecord => 'Opnemen';
  @override
  String get audioStop => 'Stoppen';
  @override
  String get audioPlay => 'Afspelen';
  @override
  String get audioDelete => 'Opname verwijderen';
  @override
  String get audioImport => 'Audiobestand importeren';
  @override
  String get audioRecording => 'Opnemen…';
  @override
  String get audioPermissionDenied =>
      'Microfoontoegang geweigerd — nodig om op te nemen.';
  @override
  String get newAudioNoteTitle => 'Nieuwe spraaknotitie';
  @override
  String get newAudioNoteDefault => 'Mijn opname';
  @override
  String get showAudioTooltip => 'Opnamen tonen';
  @override
  String get audioMessageHint => 'Schrijf een notitie…';
  @override
  String get audioSend => 'Versturen';
  @override
  String get audioRename => 'Opname hernoemen';
  @override
  String get audioDescriptionHint => 'Beschrijf deze opname…';
  @override
  String get audioEditDescription => 'Omschrijving bewerken';
  @override
  String get audioDeleteNote => 'Notitie verwijderen';
  @override
  String get audioEditNote => 'Notitie bewerken';
  @override
  String get audioPause => 'Pauzeren';
  @override
  String get audioEditTitle => 'Titel bewerken';
  @override
  String get audioTitleHint => 'Titel voor deze opname…';
  @override
  String audioUntitled(int n) => 'Opname $n';
  @override
  String get audioMoreActions => 'Meer acties';
  @override
  String get audioDiscardRecording => 'Opname weggooien';
  @override
  String get audioPauseRecording => 'Opname pauzeren';
  @override
  String get audioResumeRecording => 'Opname hervatten';
  @override
  String get audioRecordingPaused => 'Gepauzeerd';
  @override
  String get audioSavingRecording => 'Opslaan…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Snelnotitie';
  @override
  String get shortcutNewTodo => 'Nieuwe taak';
  @override
  String get shortcutNewNote => 'Nieuwe notitie';
  @override
  String get shortcutNewList => 'Nieuwe lijst';
  @override
  String get shortcutNewAudio => 'Nieuwe spraaknotitie';
  @override
  String get shortcutToggleSidebar => 'Bestandsboom tonen of verbergen';
  @override
  String get shortcutCloseTab => 'Huidige notitie sluiten';
  @override
  String get shortcutNextTab => 'Volgende open notitie';
  @override
  String get shortcutPreviousTab => 'Vorige open notitie';
  @override
  String get shortcutEditorSection => 'In de editor';
  @override
  String get shortcutFormatSection => 'Opmaak';
  @override
  String get shortcutFind => 'Zoeken';
  @override
  String get shortcutReplace => 'Vinden en vervangen';
  @override
  String get shortcutSavingNote =>
      'Wijzigingen worden automatisch opgeslagen, dus er is geen sneltoets '
      'voor opslaan.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Laden…';
  @override
  String get noteStatusSaving => 'Opslaan…';
  @override
  String get noteStatusUnsaved => 'Niet opgeslagen';
  @override
  String get noteStatusSaved => 'Opgeslagen';
  @override
  String get noteStatusError => 'Fout';
  @override
  String get noteNotText =>
      'Dit bestand is geen tekstnotitie, dus Niman kan het hier niet tonen.';
  @override
  String get noteLoadFailed => 'Deze notitie kon niet worden geopend.';
  @override
  String wordCount(int count) => count == 1 ? '1 woord' : '$count woorden';
  @override
  String get outlineTooltip => 'Structuur';
  @override
  String get outlineNoHeadings => 'Geen koppen';
  @override
  String get outlineNoTitle => '(geen titel)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Vet';
  @override
  String get toolbarItalic => 'Cursief';
  @override
  String get toolbarStrikethrough => 'Doorhalen';
  @override
  String get toolbarSuperscript => 'Superscript';
  @override
  String get toolbarUnderline => 'Onderstrepen';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Codeblok';
  @override
  String get toolbarImage => 'Afbeelding invoegen';
  @override
  String get toolbarHeading => 'Kop';
  @override
  String get toolbarList => 'Lijst';
  @override
  String get toolbarOrderedList => 'Genummerde lijst';
  @override
  String get toolbarQuote => 'Citaat';
  @override
  String get toolbarIndent => 'Inspringen';
  @override
  String get toolbarOutdent => 'Uitspringen';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Gereedschap';
  @override
  String get editorToolsTitle => 'Editorgereedschap';
  @override
  String get toolCountListTitle => 'Lijst tellen';
  @override
  String get toolCountListSubtitle =>
      'Telt op wat de regels opsommen, als afvinklijst';
  @override
  String get toolCountListNeedsList =>
      'Deze notitie heeft geen lijst om te tellen';
  @override
  String get tallySourceLabel => 'Lijst';
  @override
  String get tallyCutLabel => 'Lees elke regel als';
  @override
  String get tallyCutDash => 'Naam - waarden';
  @override
  String get tallyCutColon => 'Naam: waarden';
  @override
  String get tallyCutCommas => "Waarden, gescheiden door komma's";
  @override
  String get tallyCutWhole => 'De hele regel, als één waarde';
  @override
  String get tallySortLabel => 'Volgorde';
  @override
  String get tallySortCount => 'Meeste eerst';
  @override
  String get tallySortAlphabetical => 'Alfabetisch';
  @override
  String get tallySortFirstSeen => 'Zoals opgesomd';
  @override
  String get tallyInsert => 'Invoegen';
  @override
  String get tallyUpdate => 'Bijwerken';
  @override
  String get tallyNothingToCount => 'Hier valt niets te tellen';
  @override
  String get headingDialogTitle => 'Kopniveau';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editor-werkbalk';
  @override
  String get toolbarSettingsHint =>
      'Sleep om te herschikken; het oog toont of verbarg een knop.';
  @override
  String get toolbarShowButton => 'Tonen';
  @override
  String get toolbarHideButton => 'Verbergen';
  @override
  String get toolbarResetOrder => 'Standaardwaarden herstellen';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Voorbeeld tonen';
  @override
  String get showEditorTooltip => 'Editor tonen';
  @override
  String get enterFullScreenTooltip => 'Volledig scherm';
  @override
  String get exitFullScreenTooltip => 'Volledig scherm verlaten';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(ruwe HTML-tabel)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Notities zoeken';
  @override
  String get searchModeWords => 'Woorden';
  @override
  String get searchModeContains => 'Bevat';
  @override
  String get searchEmptyHint =>
      'Typ om in de bibliotheek te zoeken, of sleutel = waarde om te '
      'filteren op frontmatter';
  @override
  String get searchTooShortHint => 'Typ minstens 2 tekens';
  @override
  String get searchNoMatches => 'Geen overeenkomsten';
  @override
  String get searchLoadMore => 'Meer tonen';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Vervangen…';
  @override
  String get replaceInNoteAction => 'Vervangen in deze notitie…';
  @override
  String get replaceInThisNote => 'Vervangen in deze notitie';
  @override
  String get replaceWithLabel => 'Vervangen door';
  @override
  String get replaceCaseSensitive => 'Hoofdlettergevoelig';
  @override
  String get replaceWholeWordsHint =>
      'worden alleen exacte hele-woorden vervangen';
  @override
  String get replaceConfirm => 'Vervangen';
  @override
  String get replaceCancel => 'Sluiten';
  @override
  String get replaceUnavailable => 'Vervangen is nu niet beschikbaar';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'In notitie zoeken';
  @override
  String get editorFindHint => 'Zoeken';
  @override
  String get editorReplaceHint => 'Vervangen';
  @override
  String get editorFindCaseTooltip => 'Hoofdlettergevoelig';
  @override
  String get editorFindPreviousTooltip => 'Vorige match';
  @override
  String get editorFindNextTooltip => 'Volgende match';
  @override
  String get editorFindCloseTooltip => 'Zoekvenster sluiten';
  @override
  String get editorFindReplaceModeTooltip => 'Vervangmodus';
  @override
  String get editorReplaceOneTooltip => 'Deze match vervangen';
  @override
  String get editorReplaceAllTooltip => 'Alle matches vervangen';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tags';
  @override
  String get tagsTitle => 'Tags';
  @override
  String get tagsEmpty =>
      'Nog geen tags — voeg een #tag of tags in de frontmatter toe';
  @override
  String get tagsBackTooltip => 'Terug naar zoeken';
  @override
  String get tagsNotesEmpty => 'Geen notities met deze tag';
  @override
  String tagsNotesCapped(int limit) =>
      'Alleen de eerste $limit worden getoond — zoek op de tag om '
      'in te zoomen';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Link niet gevonden';
  @override
  String get headingNotFoundTitle => 'Kop niet gevonden';
  @override
  String get ambiguousLinkTitle => 'Meerdere notities komen overeen';
  @override
  String get openLinkFailed => 'Kon de link niet openen';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'De notitie bestaat niet';
  @override
  String missingNoteDialogBody(String path) => '„$path" maken?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Map „$folder" bestaat niet';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Open';
  @override
  String get todoDone => 'Klaar';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Alle datums';
  @override
  String get todoFilter => 'Filteren';
  @override
  String get todoNoTokens => 'Geen tokens in deze lijst';
  @override
  String get todoCountOpen => 'open';
  @override
  String get todoCountDone => 'klaar';
  @override
  String get todoEmptyOpen => 'Nog geen openstaande taken';
  @override
  String get todoEmptyDone => 'Nog niets afgerond';
  @override
  String get todoEmptyFiltered => 'Geen taken komen overeen';
  @override
  String get todoTitle => 'Te doen';
  @override
  String get todoAddTooltip => 'Taak toevoegen';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Het todo.txt-formaat';
  @override
  String get todoHelpTooltip => 'Formaatinfo';
  @override
  String get todoHelpIntro =>
      'Je taken zijn één plat tekstbestand, een taak per regel. Niman '
      'schrijft de syntax voor je, maar niets is verborgen: je kunt het '
      'bestand in elke editor bewerken en Niman leest het terug.';
  @override
  String get todoHelpFilesTitle => 'De twee bestanden';
  @override
  String get todoHelpFilesBody =>
      'Openstaande taken staan in todo.txt aan de basis van je '
      'bibliotheek. Werk een taak af en de regel gaat naar done.txt, zodat '
      'todo.txt kort blijft. Als een afgeronde regel toch weer in todo.txt '
      'belandt, archiveert Niman hem de volgende keer dat hij de bestanden '
      'leest.';
  @override
  String get todoHelpLineTitle => 'Anatomie van een regel';
  @override
  String get todoHelpLineBody =>
      'Alles vóór de omschrijving is facultatief en moet in deze volgorde:';
  @override
  String get todoHelpDoneBody =>
      'Markeert de taak als afgerond. Niman voegt het toe als je het vakje '
      'aanvinkt.';
  @override
  String get todoHelpPriority => '(A) tot (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioriteit. A is de hoogste. Getoond als badge in de lijst.';
  @override
  String get todoHelpDatesBody =>
      'Voltooingsdatum, dan creatiedatum. Met slechts één datum is het de '
      'creatiedatum, tenzij de regel begint met x.';
  @override
  String get todoHelpTokensTitle => 'Projecten, contexten en tags';
  @override
  String get todoHelpTokensBody =>
      'Overal in de omschrijving wordt een woord met een van deze '
      'voorvoegsels een chip waarop je kunt filteren. Niets is vooraf '
      'gedefinieerd: een token bestaat zodra je het typt.';
  @override
  String get todoHelpProjectBody =>
      'Waarin de taak hoort, bijvoorbeeld +keuken of +scriptie.';
  @override
  String get todoHelpContextBody =>
      'Waar of hoe je het doet, bijvoorbeeld @thuis of @belletjes.';
  @override
  String get todoHelpHashtagBody =>
      'Een vrij label, voor alles wat de andere twee niet dekken.';
  @override
  String get todoHelpTagsTitle => 'Datums en herinneringen';
  @override
  String get todoHelpTagsBody =>
      'Dit zijn sleutel:waarde-tags. Niman schrijft ze uit het taakvenster '
      'en leest ze overal waar ze op de regel voorkomen.';
  @override
  String get todoHelpDueBody =>
      'De vervaldatum. Stuurt de gekleurde badge en de datumfilters.';
  @override
  String get todoHelpRemBody =>
      'Wanneer een melding sturen, in de lokale tijd. Werkt ook met het '
      'scherm uit en de app gesloten.';
  @override
  String get todoHelpRemDesktop =>
      'Op desktop moet Niman op het juiste moment draaien: de herinnering '
      'verschijnt zolang de app open is, en er gaat niets af als de app '
      'gesloten is.';
  @override
  String get todoHelpOtherBody =>
      'Exact zoals getypt bewaard, zodat tags van andere todo.txt-apps een '
      'heen-en-weer overleven. Niman handelt er niet op, rec: included: een '
      'terugkerende taak wordt nog niet herhaald.';
  @override
  String get todoHelpEditTitle => 'Bewerken buiten Niman';
  @override
  String get todoHelpEditBody =>
      'Een taak die je niet hebt aangeraakt wordt byte-voor-byte '
      'weggeschreven, vreemde spasering meegeteld. Bewerk een regel en Niman '
      'schrijft die ene regel in de canonieke vorm, de rest van het bestand '
      'raakt hij niet aan.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Taak toevoegen';
  @override
  String get todoEditTitle => 'Taak bewerken';
  @override
  String get todoDescriptionHint => 'Omschrijving';
  @override
  String get todoCancel => 'Annuleren';
  @override
  String get todoSave => 'Opslaan';
  @override
  String get todoEditAction => 'Bewerken';
  @override
  String get todoDeleteAction => 'Verwijderen';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Verlopen';
  @override
  String get todoDueToday => 'Vandaag';
  @override
  String get todoDueNext7 => 'Komende 7 dagen';
  @override
  String get todoDueNoDate => 'Geen datum';
  @override
  String get todoRowDue => 'Vervalt';
  @override
  String get todoRowDueToday => 'Vervalt vandaag';
  @override
  String get todoSortTooltip => 'Sorteren';
  @override
  String get todoSortDue => 'Vervaldatum';
  @override
  String get todoSortPriority => 'Prioriteit';
  @override
  String get todoSortCreation => 'Creatiedatum';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Geen prioriteit';
  @override
  String get todoNoPriorityShort => 'Geen';
  @override
  String get todoMorePriorities => 'Meer…';
  @override
  String get todoPriorityTitle => 'Prioriteit';
  @override
  String get todoNoDueDate => 'Geen vervaldatum';
  @override
  String get todoNoReminder => 'Geen herinnering';
  @override
  String get todoAddProject => '+ Project';
  @override
  String get todoAddContext => '@ Context';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Taakherinneringen';
  @override
  String get todoReminderChannelDescription =>
      'Ingeplande meldingen voor taken met een herinneringstijd.';
  @override
  String get todoReminderBody => 'Todo-herinnering';
  @override
  String get todoReminderFallbackTitle => 'Taakherinnering';
  @override
  String get todoReminderBlocked =>
      'Meldingen staan uit, dus er verschijnen geen herinneringen.';
  @override
  String get todoReminderBattery =>
      'Batterijoptimalisatie staat aan voor Niman. Het systeem kan de app '
      'laten slapen en wachtende herinneringen laten verdwijnen.';
  @override
  String get todoReminderInexact =>
      'Dit apparaat staat geen exacte alarmen toe, dus een herinnering kan '
      'met het scherm uit enkele minuten laat aankomen.';
  @override
  String get reminderShowTokensTitle => 'Tags in herinneringsmeldingen';
  @override
  String get reminderShowTokensSubtitle =>
      'Houd +project, @context en #tag in de meldingstekst. Uit toont '
      'alleen de taak die je typte.';
  @override
  String get todoReminderFixAction => 'Instellingen openen';
  @override
  String get todoReminderDismissAction => 'Negeren';
  @override
  String get todoReminderDue => 'Vervalt';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Annuleren';
  @override
  String get actionCreate => 'Aanmaken';
  @override
  String get actionNew => 'Nieuw';
  @override
  String get actionSave => 'Opslaan';
  @override
  String get actionClear => 'Leegmaken';
  @override
  String get actionChoose => 'Kiezen';
  @override
  String get actionDelete => 'Verwijderen';
  @override
  String get actionRename => 'Hernoemen';
  @override
  String get actionMove => 'Verplaatsen';
  @override
  String get saveAndClose => 'Opslaan en sluiten';
  @override
  String get closeUnsavedTitle => 'Niet-opgeslagen wijzigingen';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” heeft wijzigingen die nog niet zijn '
          'opgeslagen. Opslaan voordat er gesloten wordt?';
    }
    return '${names.length} notities hebben wijzigingen die nog niet zijn '
        'opgeslagen. Opslaan voordat er gesloten wordt?';
  }

  @override
  String get closeSaveFailed => 'Kon niet opslaan; nog steeds open.';
  @override
  String get actionRestore => 'Herstellen';
  @override
  String get actionEmpty => 'Leegmaken';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Zijpaneel verbergen (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Zijpaneel tonen (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimaliseren';
  @override
  String get windowMaximizeTooltip => 'Maximaliseren';
  @override
  String get windowRestoreTooltip => 'Herstellen';
  @override
  String get windowCloseTooltip => 'Sluiten';
  @override
  String get tabFiles => 'Bestanden';
  @override
  String get tabSearch => 'Zoeken';
  @override
  String get tabSettings => 'Instellingen';
  @override
  String get quickNoteTitle => 'Snelnotitie';
  @override
  String get treeEmpty => 'Nog geen notities';
  @override
  String get selectANote => 'Kies een notitie';
  @override
  String get showListTooltip => 'Lijst tonen';
  @override
  String get editRawTooltip => 'Ruwe tekst bewerken';
  @override
  String get sortAscTooltip => 'Sorteren A-Z';
  @override
  String get sortDescTooltip => 'Sorteren Z-A';
  @override
  String get newNoteTitle => 'Nieuwe notitie';
  @override
  String get newItemTooltip => 'Nieuw';
  @override
  String get closeMenuTooltip => 'Sluiten';
  @override
  String get newFolderTitle => 'Nieuwe map';
  @override
  String get newNoteSameFolder => 'Nieuwe notitie in dezelfde map';
  @override
  String get newFromTemplateSameFolder => 'Nieuw uit sjabloon in dezelfde map';
  @override
  String trashOriginalPath(String path) => 'stond in $path';
  @override
  String get trashOriginalRoot => 'stond in de hoofdmap van de bibliotheek';
  @override
  String trashItemCount(int count) => count == 1 ? '1 item' : '$count items';
  @override
  String get newNoteHere => 'Nieuwe notitie hier';
  @override
  String get newFolderHere => 'Nieuwe map hier';
  @override
  String get newListNoteTitle => 'Nieuwe lijstnotitie';
  @override
  String get newListNoteDefault => 'Mijn lijst';
  @override
  String get setAsQuickNote => 'Instellen als snelnotitie';
  @override
  String get currentQuickNote => 'Huidige snelnotitie';
  @override
  String get pinnedSection => 'Vastgezet';
  @override
  String pinnedSectionCount(int count) => 'Vastgezet · $count';
  @override
  String get templateFolderTitle => 'Sjabloonmap';
  @override
  String get newFromTemplateTitle => 'Nieuw uit sjabloon';
  @override
  String get newFromTemplateHere => 'Nieuw uit sjabloon hier';
  @override
  String get templateFormTitle => 'Sjabloon invullen';
  @override
  String get templateFormBacklink => 'Gekoppeld van';
  @override
  String get templateFormNoNote => 'Geen notitie';
  @override
  String get templateFormPickNote => 'Kies de notitie';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Sjabloon-placeholders';
  @override
  String get templateHelpSubtitle =>
      'Datum, titel en de overige in te vullen waarden';
  @override
  String get quickNoteSubtitle =>
      'De notitie die het tabblad Snelle notitie opent';
  @override
  String get listFolderSubtitle => 'De nieuwe takenlijsten';
  @override
  String get templateFolderSubtitle => 'De bron van „Nieuw uit sjabloon“';
  @override
  String get attachmentsFolderSubtitle =>
      'Afbeeldingen en audio in een notitie';
  @override
  String get templateHelpIntro =>
      'Een sjabloon is een gewone notitie met gaten. Een notitie uit een '
      'sjabloon maken kopieert de tekst en vult de gaten in.';
  @override
  String get templateHelpUnknown =>
      'Een placeholder die Niman niet kent blijft exact zoals getypt, '
      'zodat een typefout in de notitie zichtbaar is in plaats van een '
      'regel stil op te eten.';
  @override
  String get templateHelpValuesTitle => 'Waarden';
  @override
  String get templateHelpTitleBody =>
      'De naam waaronder de notitie wordt aangemaakt.';
  @override
  String get templateHelpDateBody =>
      'Vandaag, en nu het tijdstip. Beide accepteren een opmaak: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'De datum en het tijdstip samen.';
  @override
  String get templateHelpUuidBody =>
      'Een nieuwe identificatiecode, een andere bij elke voorkoming.';
  @override
  String get templateHelpCounterBody =>
      'Een nummer dat per naam omhoog telt, bewaard over herstarts heen: de '
      'eerste notitie schrijft 1, de volgende 2. Dezelfde naam in één '
      'notitie schrijft hetzelfde nummer; combineer met |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Zet de cursor hier wanneer de notitie wordt aangemaakt; de '
      'markering zelf wordt niet geschreven. Eerste markering wint, geen '
      'filters, alleen nieuwe notities — en het toetsenbord opent ook met '
      'autofocus uit.';
  @override
  String get templateHelpDatesTitle => 'Een datum schrijven';
  @override
  String get templateHelpDatesBody =>
      'Deze staan voor delen van de datum binnen een opmaak. Alles anders '
      'is letterlijk, en tekst in enkel aanhalingstekens ook. Maan- en '
      'dagnamen volgen de taal van de app.';
  @override
  String get templateHelpYear => 'het jaar: 2026, 26';
  @override
  String get templateHelpMonth => 'de maand: 03, 3, maart, mrt';
  @override
  String get templateHelpDay => 'de dag: 09, 9, maandag, ma';
  @override
  String get templateHelpTime => 'uren, minuten, seconden';
  @override
  String get templateHelpWeek => 'de ISO-week en het kwartaal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filters';
  @override
  String get templateHelpFiltersBody =>
      'Een waarde kan gevolgd worden door filters, van links naar rechts '
      'toegepast.';
  @override
  String get templateHelpCaseBody =>
      'Hoofdletters, kleine letters, en de eerste letter van elk woord — '
      'een woord dat je zelf in hoofdletters schreef, wordt niet '
      'aangeroerd.';
  @override
  String get templateHelpSlugBody =>
      'De linkvorm van de tekst, om een wikilink mee te bouwen.';
  @override
  String get templateHelpPadBody =>
      'Knip de uiteinden af; vul aan met nullen tot een breedte; gebruik '
      'een vervanging wanneer de waarde leeg is.';
  @override
  String get templateHelpShiftBody =>
      'Verschuif een datum met dagen, weken, maanden of jaren — de les van '
      'volgende week, het bestand van vorige maand.';
  @override
  String get templateHelpSnapBody =>
      'Zet een datum op het begin of het einde van de week, de maand of het '
      'jaar.';
  @override
  String get templateHelpAskTitle => 'Iets van je vragen';
  @override
  String get templateHelpAskBody =>
      'Vóór de notitie wordt aangemaakt verschijnt een formulier, een veld '
      'per vraag — en een voor de backlink, wanneer het sjabloon die wil. '
      'Twee keer hetzelfde label is één vraag, en het antwoord vult elke '
      'voorkoming — de map en de bestandsnaam meegeteld.';
  @override
  String get templateHelpAskFieldBody =>
      'Een veld om in te typen; de tekst na de tweede dubbele punt is waar '
      'het mee begint.';
  @override
  String get templateHelpChoiceBody =>
      'Een keuze uit een lijst, gescheiden door komma’s.';
  @override
  String get templateHelpWhereTitle => 'Waar de notitie naartoe gaat';
  @override
  String get templateHelpWhereBody =>
      'Dit is geen tekst: het zijn instructies, en ze staan in een niman: '
      'blok in de frontmatter van het sjabloon zelf. Het blok wordt '
      'uitgevoerd en daarna verwijderd, dus het komt nooit in de notitie. '
      'De waarden mogen placeholders bevatten.';
  @override
  String get templateHelpFolderBody =>
      'De map waarin de notitie wordt aangemaakt, aangemaakt als hij er nog '
      'niet is. Zonder hem landt de notitie waar jij was.';
  @override
  String get templateHelpFilenameBody =>
      'Waarnaar de notitie heet. Een sjabloon dat dit opgeeft, wordt niet '
      'om een naam gevraagd.';
  @override
  String get templateHelpAppendBody =>
      'Voeg toe aan de notitie als hij al bestaat, in plaats van een '
      'tweede te maken. Dit maakt van een maand aan vergaderingen één '
      'bestand.';
  @override
  String get templateHelpOpenBody =>
      'Wat er gebeurt zodra de notitie bestaat: de editor (de standaard), '
      'het voorbeeld, of niets — de notitie wordt opgeborgen en je blijft '
      'waar je was.';
  @override
  String get templateHelpAroundTitle => 'Waar het vandaan komt';
  @override
  String get templateHelpParentBody =>
      'Een notitie die je in het formulier kiest; hij stelt degene op het '
      'scherm voor. Schrijf [[{{parent}}]] voor een link terug.';
  @override
  String get templateHelpFolderValueBody =>
      'De map waar de notitie uiteindelijk belandde.';
  @override
  String get templateHelpClipboardBody =>
      'Wat op het klembord ligt, en de selectie in de editor wanneer de '
      'notitie eruit werd gestart.';
  @override
  String get templateHelpIncludeTitle => 'Een stuk hergebruiken';
  @override
  String get templateHelpIncludeBody =>
      'Plakt een ander sjabloon in, zodat tien sjablonen één controlelijst '
      'kunnen delen. Het wordt eerst in de sjabloonmap gezocht, en de .md '
      'mag worden weggelaten. Zijn eigen vragen komen in hetzelfde '
      'formulier.';
  @override
  String get templateHelpExampleTitle => 'Alles bij elkaar';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ geen sjabloon “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” bevat zichzelf';
  @override
  String includeTooDeep(String path) => '⚠ “$path” is te diep genest';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter niet gelezen: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'De frontmatter van “$template” is niet gelezen, dus de map en de '
      'bestandsnaam hebben niets gedaan: $reason';
  @override
  String get templatePickerTitle => 'Kies een sjabloon';
  @override
  String templatePickerEmpty(String folder) =>
      'Nog geen sjablonen. Leg een notitie in $folder/ en het wordt er een.';

  // Tree actions.
  @override
  String get actionPin => 'Vastzetten';
  @override
  String get actionUnpin => 'Losmaken';
  @override
  String get pinToWidget => 'Vastmaken aan startschermwidget';
  @override
  String get pinnedForWidget =>
      'Vastgemaakt: plaats nu de Notitie-widget op het startscherm';
  @override
  String get pinWidgetUnavailable =>
      'Startschermwidgets zijn beschikbaar op Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Tonen in bestandsbeheer';
  @override
  String get openInDefaultApp => 'Openen met standaardapp';
  @override
  String get newNoteTabTooltip => 'Nieuwe notitie in een nieuw tabblad';
  @override
  String get openNotesTooltip => 'Open notities';
  @override
  String get closeTabTooltip => 'Sluiten';
  @override
  String get openInNewTab => 'Openen in nieuw tabblad';
  @override
  String get splitRight => 'Rechts splitsen';
  @override
  String get splitDown => 'Onder splitsen';
  @override
  String get moveToOtherPane => 'Naar het andere paneel verplaatsen';
  @override
  String get openBeside => 'Ernaast openen';
  @override
  String get closeAllNotes => 'Alles sluiten';
  @override
  String get sidePanelTooltip => 'Zijpaneel tonen of verbergen';
  @override
  String get historyAllVersions => 'Alle versies';
  @override
  String get commandPaletteTitle => 'Opdrachtpalet';
  @override
  String get goToNoteTitle => 'Naar notitie';
  @override
  String get paletteGroupNote => 'Notitie';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Weergave';
  @override
  String get paletteGroupLibrary => 'Bibliotheek';
  @override
  String get paletteGroupGoTo => 'Ga naar';
  @override
  String get commandsTitle => 'Opdrachten';
  @override
  String get commandsIntro =>
      'Het opdrachtenpalet biedt alleen de opdrachten aan die kunnen draaien '
      'waar je bent. Hier staan ze allemaal, en wanneer elke verschijnt.';
  @override
  String get commandNeedNone => 'Altijd beschikbaar';
  @override
  String get commandNeedOpenNote => 'Vereist een geopende notitie';
  @override
  String get commandNeedWideWindow => 'Alleen in een breed venster';
  @override
  String get commandNeedDockRoom =>
      'Vereist een venster dat breed genoeg is voor het zijpaneel';
  @override
  String get commandNeedDesktop => 'Alleen op de desktop';
  @override
  String get commandNeedNotInZen => 'Niet in zenmodus';
  @override
  String get commandNeedZenRoom =>
      'Desktop, met een notitie open in een tabblad';
  @override
  String get commandNeedPreview =>
      'Met de voorvertoning aan, bij een tekstnotitie';
  @override
  String get commandNeedTwoEditors => 'Met beide editors ingeschakeld';
  @override
  String get paletteHint => 'Opdrachten en notities zoeken';
  @override
  String get paletteNoResults => 'Niets gevonden';
  @override
  String get paletteCommands => 'Opdrachten';
  @override
  String get paletteNotes => 'Notities';
  @override
  String get paletteFooter =>
      '↑↓ om te bewegen · ↵ om te gebruiken · esc om te sluiten';
  @override
  String get palettePinned => 'Vastgezet';
  @override
  String get palettePin => 'Vastzetten';
  @override
  String get paletteUnpin => 'Losmaken';
  @override
  String get palettePinFooter => 'alt+P om vast te zetten';
  @override
  String get spellCheckScanning => 'Notitie controleren…';
  @override
  String get spellCheckAgain => 'Opnieuw controleren';
  @override
  String spellCheckCapped(int count) =>
      'De eerste $count worden getoond: verbeter er een paar en controleer '
      'opnieuw voor de rest';
  @override
  String get dropHint =>
      'Sleep Markdown-bestanden hierheen om ze te openen, of een map om hem '
      'te importeren';
  @override
  String get importFolderAction => 'Importeren';
  @override
  String dropRejected(String names) =>
      'Hier openen alleen Markdown-bestanden en mappen: $names';
  @override
  String importFolderTitle(String name) => '“$name” importeren?';
  @override
  String importFolderBody(int count) =>
      'De Markdown-bestanden ($count) worden gekopieerd naar een nieuwe map '
      'in de bibliotheek. De map die je losliet, blijft zoals hij is.';
  @override
  String importFolderDone(String folder) => 'Geïmporteerd in $folder';
  @override
  String importFolderEmpty(String name) => 'Geen Markdown-bestanden in $name';
  @override
  String get openFileTitle => 'Bestand openen';
  @override
  String get outsideFileNote =>
      'Buiten elke bibliotheek: opgeslagen waar het staat, niet geïndexeerd, '
      'geen geschiedenis, links worden niet gevolgd';
  @override
  String get typewriterOn => 'Typemachinemodus aanzetten';
  @override
  String get typewriterOff => 'Typemachinemodus uitzetten';
  @override
  String get typewriterTitle => 'Typemachinemodus';
  @override
  String get typewriterSubtitle =>
      'Houd de regel waarop je schrijft in het midden van de editor';
  @override
  String get zenMode => 'Zen-modus';
  @override
  String get zenModeEnter => 'Zen-modus openen';
  @override
  String get zenModeLeave => 'Zen-modus verlaten';
  @override
  String get keySpace => 'Spatie';
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
  String get keyArrowUp => 'Omhoog';
  @override
  String get keyArrowDown => 'Omlaag';
  @override
  String get keyArrowLeft => 'Links';
  @override
  String get keyArrowRight => 'Rechts';
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
  String get shortcutNone => 'Geen sneltoets';
  @override
  String get shortcutRestoreDefaults => 'Standaard herstellen';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Alle sneltoetsen terugzetten zoals Niman ze levert?';
  @override
  String get shortcutRevert => 'Terug naar standaard';
  @override
  String get shortcutClear => 'Sneltoets verwijderen';
  @override
  String get shortcutCapturePrompt =>
      'Druk op de toetsen. Ook Esc en Tab worden opgenomen: Annuleren is de '
      'uitweg.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Voeg Ctrl, Alt of Meta toe: een losse toets is om te typen.';
  @override
  String get shortcutMove => 'Verplaatsen';
  @override
  String get shortcutUseAnyway => 'Toch gebruiken';
  @override
  String get shortcutUndo => 'Ongedaan maken';
  @override
  String get shortcutRedo => 'Opnieuw';
  @override
  String get shortcutChange => 'Sneltoets wijzigen';
  @override
  String shortcutCaptureTitle(String command) => 'Toetsen voor $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys is al van $other. Hierheen verplaatsen? $other heeft dan geen '
      'sneltoets.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys is ook $what in tekstvelden en de editor. Daar neemt je '
      'opdracht hem over.';
  @override
  String get openFileMissing =>
      'Het bestand van deze notitie staat niet op de schijf';
  @override
  String get openFileFailed => 'Kon deze notitie niet buiten Niman openen';

  @override
  String get movedToTrash => 'Naar de prullenbak verplaatst';
  @override
  String get deletedMessage => 'Verwijderd';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name wordt naar .trash/ verplaatst';
  @override
  String deleteForeverConfirm(String name) =>
      '$name wordt definitief verwijderd';
  @override
  String get chooseDestination => 'Kies bestemming';
  @override
  String get libraryRoot => 'Basis van de bibliotheek';
  @override
  String moveTitle(String name) => 'Verplaats $name';
  @override
  String headingLevelLabel(int level) => 'Kop $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Nog geen snelnotitie. Kies een bestaande notitie, of maak een '
      'nieuwe — de snelnotitie opent hier.';
  @override
  String get quickNoteChooseAction => 'Kies een notitie…';
  @override
  String get quickNoteCreateAction => 'Nieuwe notitie maken…';
  @override
  String get quickNoteNewTitle => 'Nieuwe snelnotitie';
  @override
  String get quickNotePickerTitle => 'Snelnotitie kiezen';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nieuwe map';
  @override
  String get folderPickerEmpty => 'Nog geen mappen';
  @override
  String get listFolderTitle => 'Lijstmap';
  @override
  String get attachmentsFolderTitle => 'Bijlagenmap';

  // Trash (M1).
  @override
  String get trashEmpty => 'De prullenbak is leeg';
  @override
  String get trashEmptyAction => 'Prullenbak legen';
  @override
  String get trashEmptyConfirm =>
      'Dit verwijdert alles in de prullenbakmap definitief, inclusief '
      'items die Niman er niet in heeft gelegd.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name wordt definitief verwijderd (niet te herstellen)';
  @override
  String get trashDeletePermanently => 'Definitief verwijderen';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Open een map met Markdown-notities als bibliotheek';
  @override
  String get openLibraryExisting => 'Bestaande openen';
  @override
  String get openLibraryCreate => 'Nieuwe maken';
  @override
  String get openLibraryCreateTitle => 'Nieuwe bibliotheek maken';
  @override
  String get openLibraryFolderName => 'Mapnaam';
  @override
  String get openLibraryChooseFolder => 'Kies de bibliotheekmap';
  @override
  String get openLibraryChooseParent =>
      'Kies de map waarin de bibliotheek wordt aangemaakt';
  @override
  String get openLibraryUnsupported =>
      'Die map wordt niet ondersteund. Kies een map op de opslag van het '
      'apparaat.';
  @override
  String indexingCount(int done, int total) => '$done van $total notities';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Je bibliotheken';
  @override
  String get libraryUnreachable => 'Onbereikbaar';
  @override
  String get libraryOpenedToday => 'Vandaag geopend';
  @override
  String get libraryOpenedYesterday => 'Gisteren geopend';
  @override
  String libraryOpenedDaysAgo(int days) => '$days dagen geleden geopend';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Geopend op ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Nu geopend';
  @override
  String get switchLibraryTitle => 'Van bibliotheek wisselen';
  @override
  String get libraryForget => 'Vergeten';
  @override
  String libraryForgetTitle(String name) => '“$name” vergeten?';
  @override
  String get libraryForgetExplained =>
      'Hij komt van deze lijst af. De map, de notities en de '
      'bibliotheekinstellingen erin worden onaangetast gelaten, en opnieuw '
      'openen brengt hem terug.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Bestandstoegang verlenen';
  @override
  String get storageAccessNeeded =>
      'Zonder “Toegang tot alle bestanden” kan Niman je notities niet '
      'lezen. Verlen het om een bibliotheek te openen.';
  @override
  String get storageAccessExplained =>
      'Niman leest je notities als gewone bestanden, dus Android moet hem '
      'toegang tot alle bestanden geven. Er wordt niets geüpload, en alleen '
      'de bibliotheekmap die je kiest wordt gelezen.';
  @override
  String folderAccessDenied(Object error) =>
      'Het systeem gaf geen toegang tot de map: $error';
  @override
  String folderPickFailed(Object error) => 'Kon geen map kiezen: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Instellingen';
  @override
  String get libraryPathTitle => 'Bibliotheekpad';
  @override
  String get reindexTitle => 'Nu herindexeren';
  @override
  String get reindexDone => 'Herindexeren afgerond';
  @override
  String get closeLibraryTitle => 'Bibliotheek sluiten';
  @override
  String get exportLogTitle => 'Debuglog exporteren';
  @override
  String get exportLogSubtitle =>
      'Sla de opgenomen evenementen op in een bestand dat je kiest';
  @override
  String get exportLogEmpty => 'De buffer van de debuglog is leeg';
  @override
  String get quickNoteUnset => 'Nog niet ingesteld';
  @override
  String exportLogDone(Object target) => 'Debuglog geëxporteerd naar $target';
  @override
  String exportLogFailed(Object error) => 'Exporteren mislukt: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Geen exacte heel-woordmatch van “$term” gevonden';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences keer “$term” vervangen in $notes notities';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped open notities overgeslagen)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Geen exacte heel-woordmatch van “$term” '
      '${only == null ? 'gevonden' : 'gevonden in $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Over';
  @override
  String get versionTitle => 'Versie';
  @override
  String get changelogTitle => 'Wijzigingslog';
  @override
  String get changelogEmpty => 'Geen wijzigingen beschikbaar';
  @override
  String changelogWhatsNew(String version) => 'Nieuw in versie $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Geschiedenis';
  @override
  String get noteMenuTooltip => 'Notitieacties';
  @override
  String get historyCurrentVersion => 'Huidige versie';
  @override
  String get historyCurrentSubtitle => 'De notitie zoals die nu is';
  @override
  String get historyToday => 'Vandaag';
  @override
  String get historyYesterday => 'Gisteren';
  @override
  String get historyReasonSession => 'vóór bewerken';
  @override
  String get historyReasonInterval => 'tijdens bewerken';
  @override
  String get historyReasonRestore => 'vóór herstel';
  @override
  String get historyReasonSync => 'vóór sync';
  @override
  String get historyReasonReplace => 'vóór vervangen';
  @override
  String get historyReasonUnknown => 'teruggevonden';
  @override
  String get historySyncBase => 'sync-basis';
  @override
  String get historyEmpty =>
      'Nog geen versies. Niman bewaart er een zodra je de notitie gaat '
      'bewerken, en daarna hooguit één om de paar minuten terwijl je schrijft.';
  @override
  String historyKept(int kept, int limit) => '$kept van $limit versies bewaard';
  @override
  String get historyBaseKept =>
      'De sync-basis blijft ook boven de limiet bewaard.';
  @override
  String get historyOff =>
      'Geschiedenis staat uit voor deze bibliotheek '
      '(Instellingen, Bibliotheek).';
  @override
  String get historyLoadFailed => 'Kon de geschiedenis niet lezen';
  @override
  String get historyCompareSubtitle => 'Vergeleken met de huidige versie';
  @override
  String get historyTabChanges => 'Wijzigingen';
  @override
  String get historyTabVersion => 'Versie';
  @override
  String get historyNoChanges => 'Zelfde tekst als de huidige versie.';
  @override
  String get historyRestoreAction => 'Deze versie herstellen';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Versie van $when herstellen?';
  @override
  String get historyRestoreConfirmBody =>
      'De huidige tekst wordt eerst in de geschiedenis bewaard, dus je kunt '
      'altijd terug.';
  @override
  String get historyRestoreConfirm => 'Herstellen';
  @override
  String historyRestored(String when) => 'Versie van $when hersteld';
  @override
  String get historyRestoreFailed => 'Kon de versie niet herstellen';
  @override
  String get actionUndo => 'Ongedaan maken';
  @override
  String diffLineRange(int start, int end) => 'Regels $start–$end';
  @override
  String diffLineSingle(int line) => 'Regel $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 ongewijzigde regel' : '$count ongewijzigde regels';
  @override
  String get historyTakeHunk => 'Hier herstellen';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? '1 wijziging herstellen' : '$count wijzigingen herstellen';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'De gekozen wijzigingen keren terug naar de tekst van deze versie. De '
      'notitie zoals die nu is wordt eerst als versie bewaard, dus je kunt dit '
      'ongedaan maken.';
  @override
  String get historyNoteChangedReloaded =>
      'De notitie is veranderd terwijl je hier was — de vergelijking is '
      'bijgewerkt.';
  @override
  String get historyVersionsTitle => 'Te bewaren versies';
  @override
  String get historyVersionsSubtitle => 'Per notitie, in .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Geen' : '$count';
  @override
  String get historyIntervalTitle => 'Nieuwe versie hooguit elke';
  @override
  String get historyIntervalSubtitle =>
      'Tijdens het schrijven; beginnen met bewerken bewaart er altijd een';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcriptie';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Geen';
  @override
  String get transcriptionLanguageTitle => 'Taal';
  @override
  String get transcriptionLanguageSubtitle =>
      'De taal die in je opnames wordt gesproken. Die opgeven is nauwkeuriger '
      'dan hem laten herkennen.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Zoals de app ($language)';
  @override
  String get transcriptionLanguageDetect => 'Automatisch herkennen';
  @override
  String get transcriptionModelsTitle => 'Transcriptiemodellen';
  @override
  String transcriptionModelsUsed(String size) => '$size in gebruik';
  @override
  String get transcriptionModelsInstalled => 'Gedownload';
  @override
  String get transcriptionModelsDownloading => 'Bezig met downloaden';
  @override
  String get transcriptionModelsAvailable => 'Beschikbaar';
  @override
  String get transcriptionModelsFooter =>
      'Modellen blijven in de opslag van de app op dit apparaat. Ze worden '
      'niet naar de bibliotheek gekopieerd of gesynchroniseerd.';
  @override
  String get transcriptionModelDefault => 'Standaard';
  @override
  String get transcriptionModelSlow => 'Traag';
  @override
  String get transcriptionModelHintTiny => 'Snelst, minst nauwkeurig';
  @override
  String get transcriptionModelHintBase =>
      'Goede balans tussen snelheid en nauwkeurigheid';
  @override
  String get transcriptionModelHintSmall => 'Nauwkeuriger, ongeveer 3× trager';
  @override
  String get transcriptionModelHintMedium =>
      'Zeer nauwkeurig, traag op een telefoon';
  @override
  String get transcriptionModelHintLarge =>
      'Nauwkeurigst, heeft veel geheugen nodig';
  @override
  String get transcriptionModelDownload => 'Downloaden';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Model $model verwijderen?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Dit maakt $size vrij. Je kunt het model later opnieuw downloaden.';
  @override
  String get transcriptionModelFailed =>
      'Downloaden mislukt. Controleer de verbinding en probeer het opnieuw.';
  @override
  String get actionRetry => 'Opnieuw proberen';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Verbinding verbroken, nieuwe poging…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Gepauzeerd bij $progress';
  @override
  String get actionResume => 'Hervatten';
  @override
  String get audioTranscribe => 'Transcriberen';
  @override
  String get audioTranscribeUnsupported => 'Alleen WAV-opnames op dit apparaat';
  @override
  String get transcriptionQueued => 'In de wachtrij';
  @override
  String get transcriptionPreparing => 'Audio voorbereiden…';
  @override
  String transcriptionRunning(int percent) => 'Transcriberen… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model downloaden · $percent%';
  @override
  String get transcriptionSaved =>
      'Transcriptie toegevoegd aan de beschrijving';
  @override
  String get transcriptionNoSpeech => 'Geen spraak herkend in deze opname';
  @override
  String get transcriptionFailed => 'Transcriptie mislukt';
  @override
  String get transcriptionPickModelTitle => 'Kies een model';
  @override
  String get transcriptionPickModelBody =>
      'De transcriptie gebeurt op dit apparaat en de opname wordt nooit '
      'geüpload. Het model wordt één keer gedownload.';
  @override
  String get transcriptionPickModelAction => 'Downloaden en transcriberen';
  @override
  String get transcriptionModelRecommended => 'Aanbevolen';
  @override
  String get transcriptionExistingTitle =>
      'Deze opname heeft al een beschrijving';
  @override
  String get transcriptionExistingBody =>
      'Vervangen door de transcriptie, of de transcriptie eronder toevoegen?';
  @override
  String get transcriptionAppend => 'Eronder toevoegen';
  @override
  String get transcriptionReplace => 'Vervangen';
  @override
  String get settingsSectionSync => 'Synchronisatie';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Niet ingesteld voor deze bibliotheek';
  @override
  String get syncNeverSynced => 'Nog nooit gesynchroniseerd';
  @override
  String syncLastSynced(String when) => 'Gesynchroniseerd $when';
  @override
  String get syncRunning => 'Synchroniseren…';
  @override
  String syncScreenSubtitle(String library) => 'Bibliotheek $library';
  @override
  String get syncUrlLabel => 'Mapadres';
  @override
  String get syncUrlRequired => 'Voer het serveradres in';
  @override
  String get syncUrlHint =>
      'De map moet al bestaan. Kopieer het adres zoals de server '
      'het toont.';
  @override
  String get syncHttpWarning =>
      'Onversleutelde verbinding: prima via een VPN of op je '
      'lokale netwerk.';
  @override
  String get syncUserLabel => 'Gebruiker';
  @override
  String get syncUserHint =>
      'Laat leeg als de server geen inloggegevens vraagt.';
  @override
  String get syncPasswordLabel => 'Wachtwoord';
  @override
  String get syncPasswordHint =>
      'Bewaard in de sleutelhanger van dit apparaat, nooit in de '
      'bestanden van de bibliotheek.';
  @override
  String get syncPasswordKeepHint =>
      'Laat leeg om het opgeslagen wachtwoord te houden.';
  @override
  String get syncShowPassword => 'Wachtwoord tonen';
  @override
  String get syncHidePassword => 'Wachtwoord verbergen';
  @override
  String get syncTestAction => 'Verbinding testen';
  @override
  String get syncTesting => 'Testen…';
  @override
  String get syncRetargetWarning =>
      'Met een nieuw adres of een andere gebruiker begint de '
      'volgende sync opnieuw als eerste sync.';
  @override
  String get syncTestOk => 'Verbinding werkt';
  @override
  String get syncModeFull => 'Volledige modus';
  @override
  String get syncModeCompatible => 'Compatibele modus';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lezen, schrijven en verwijderen';
  @override
  String get syncCapEtags => 'Bestandsvingerafdrukken (ETags)';
  @override
  String get syncCapNoEtags => 'Geen bestandsvingerafdrukken (ETags)';
  @override
  String get syncCapNoEtagsDetail =>
      'Vergelijkt grootte en datum; downloadt opnieuw bij twijfel';
  @override
  String get syncCapGuarded => 'Beveiligde schrijfacties';
  @override
  String get syncCapUnguarded => 'Onbeveiligde schrijfacties';
  @override
  String get syncCapUnguardedDetail =>
      'Controleert het bestand op de server vlak voor het '
      'schrijven';
  @override
  String get syncCapMove => 'Hernoemt zonder opnieuw te uploaden';
  @override
  String get syncCapNoMove => 'Geen hernoemen op de server';
  @override
  String get syncCapNoMoveDetail =>
      'Hernoemen wordt verwijderen plus een nieuwe upload';
  @override
  String get syncCompatibleNote =>
      'In compatibele modus werkt sync hetzelfde, met iets meer '
      'verzoeken.';
  @override
  String get syncTestInvalidUrl => 'Geen geldig adres';
  @override
  String get syncTestInvalidUrlHint =>
      'Voer een adres in dat met http:// of https:// begint, '
      'zonder gebruiker of wachtwoord erin.';
  @override
  String get syncTestOffline => 'Server niet bereikbaar';
  @override
  String get syncTestOfflineHint =>
      'Staat de VPN aan? Een adres als 10.x of 192.168.x werkt '
      'alleen vanaf hetzelfde netwerk.';
  @override
  String get syncTestAuth => 'Gebruiker of wachtwoord geweigerd';
  @override
  String get syncTestAuthHint => 'Controleer ze en test opnieuw.';
  @override
  String get syncTestNotFound => 'De map bestaat niet';
  @override
  String get syncTestNotFoundHint =>
      'Maak hem aan op de server of corrigeer het adres.';
  @override
  String get syncTestUnsupported => 'Geen WebDAV-map';
  @override
  String get syncTestUnsupportedHint =>
      'De server antwoordt, maar niet als WebDAV.';
  @override
  String get syncTestFailed => 'De test is mislukt';
  @override
  String get syncNowAction => 'Nu synchroniseren';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adres, gebruiker en wachtwoord';
  @override
  String get syncRetestTitle => 'Server opnieuw testen';
  @override
  String syncProbedAgo(String when) => 'Laatste test $when';
  @override
  String get syncDisconnectTitle => 'Deze bibliotheek ontkoppelen';
  @override
  String get syncDisconnectSubtitle => 'Bestanden blijven hier en op de server';
  @override
  String get syncDisconnectConfirmTitle => 'Sync ontkoppelen?';
  @override
  String get syncDisconnectConfirmBody =>
      'Deze bibliotheek wordt op dit apparaat niet meer '
      'gesynchroniseerd. Er wordt geen bestand verwijderd, hier '
      'noch op de server. Koppel je hem opnieuw, dan begint de '
      'eerste sync opnieuw.';
  @override
  String get syncDisconnectConfirm => 'Ontkoppelen';
  @override
  String get syncFirstTitle => 'Eerste sync';
  @override
  String get syncFirstIntro =>
      'De bibliotheek is vergeleken met de map op de server:';
  @override
  String get syncFirstUpload => 'Te uploaden';
  @override
  String get syncFirstDownload => 'Te downloaden';
  @override
  String get syncFirstBoth => 'Aan beide kanten';
  @override
  String get syncFirstBothHint =>
      'Gelijk: geen overdracht. Verschillend: op te lossen';
  @override
  String get syncFirstNoDelete =>
      'De eerste sync verwijdert niets, hier noch op de server.';
  @override
  String get syncStartAction => 'Starten';
  @override
  String syncMassTrashTitle(int count) =>
      '$count bestanden naar de prullenbak verplaatsen?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count van de $total gesynchroniseerde bestanden '
      'ontbreken op de server. Meestal betekent dat een verkeerd '
      'adres, een niet-gekoppelde NAS-schijf of een per ongeluk '
      'geleegde map.';
  @override
  String get syncMassTrashHint =>
      'Heb je ze echt op een ander apparaat verwijderd, bevestig '
      'dan: hier gaan ze naar de prullenbak.';
  @override
  String get syncMassTrashConfirm => 'Naar de prullenbak';
  @override
  String syncMassDeleteTitle(int count) =>
      '$count bestanden van de server verwijderen?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count van de $total gesynchroniseerde bestanden '
      'ontbreken hier. Heb je ze niet verwijderd, annuleer dan '
      'en controleer de bibliotheekmap.';
  @override
  String get syncMassDeleteConfirm => 'Van server verwijderen';
  @override
  String get syncTooltip => 'Synchroniseren';
  @override
  String get syncStageConnecting => 'Verbinden met de server…';
  @override
  String get syncStageComparing => 'Vergelijken met de server…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synchroniseren · $done van $total';
  @override
  String get syncStatusWarnings => 'Gesynchroniseerd met waarschuwingen';
  @override
  String syncConflictsHeader(int count) =>
      'Hier en op de server gewijzigd · $count';
  @override
  String get syncConflictHint => 'Geen van beide versies is aangeraakt';
  @override
  String get syncResolveAction => 'Oplossen';
  @override
  String syncFailuresHeader(int count) => 'Niet gesynchroniseerd · $count';
  @override
  String get syncFailuresHint => 'Bij de volgende sync opnieuw geprobeerd';
  @override
  String get syncAbortAuth => 'Wachtwoord geweigerd door de server';
  @override
  String get syncAbortMissingPassword => 'Geen wachtwoord opgeslagen';
  @override
  String get syncAbortOffline => 'Server niet bereikbaar';
  @override
  String get syncAbortRemoteMissing => 'De map op de server is weg';
  @override
  String get syncAbortUnsupported => 'De server werkt niet meer als WebDAV';
  @override
  String get syncAbortFailed => 'Sync is mislukt';
  @override
  String get syncAbortNotConfirmed => 'Sync geannuleerd';
  @override
  String get syncAbortNothingTouched =>
      'Er is geen bestand aangeraakt. Je wijzigingen blijven '
      'hier tot de volgende geslaagde sync.';
  @override
  String syncLastSuccess(String when) => 'Laatste geslaagde sync $when';
  @override
  String get syncNoSuccessYet => 'Nog geen geslaagde sync';
  @override
  String get syncUpdatePasswordAction => 'Wachtwoord bijwerken';
  @override
  String get syncRetryAction => 'Opnieuw proberen';
  @override
  String get syncOpenSettingsAction => 'Instellingen';
  @override
  String get syncCloseAction => 'Sluiten';
  @override
  String get syncDoneSnack => 'Gesynchroniseerd';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Gesynchroniseerd · 1 elders verwijderd bestand staat in '
            'de prullenbak'
      : 'Gesynchroniseerd · $count elders verwijderde bestanden '
            'staan in de prullenbak';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Gesynchroniseerd · 1 conflict op te lossen'
      : 'Gesynchroniseerd · $count conflicten op te lossen';
  @override
  String get syncShowAction => 'Tonen';
  @override
  String get syncConflictTitle => 'Conflict oplossen';
  @override
  String get syncConflictLegend =>
      'Regels met − zijn van de server, regels met + van dit '
      'apparaat.';
  @override
  String get syncConflictBinary =>
      'Geen tekstbestand: kies welke kopie je houdt.';
  @override
  String get syncConflictKeepNote =>
      'De kopie die je niet houdt, blijft in de geschiedenis van '
      'de notitie.';
  @override
  String get syncKeepLocal => 'Versie van dit apparaat houden';
  @override
  String get syncKeepRemote => 'Versie van de server houden';
  @override
  String get syncConflictIdentical => 'De twee versies zijn identiek';
  @override
  String get syncConflictLoadFailed => 'Kon de twee versies niet lezen';
  @override
  String get syncResolveFailed => 'Kon het conflict niet oplossen';
  @override
  String get syncResolved => 'Conflict opgelost';
  @override
  String get syncSectionWhen => 'Wanneer synchroniseren';
  @override
  String get syncAutoTitle => 'Automatisch';
  @override
  String get syncAutoSubtitle =>
      'Na wijzigingen, bij openen en met tussenpozen';
  @override
  String get syncIntervalTitle => 'Interval voor servercontrole';
  @override
  String get syncIntervalSubtitle => 'Alleen terwijl de app open is';
  @override
  String get syncIntervalDialogBody =>
      'Om wijzigingen van andere apparaten te zien terwijl de app open is. '
      'Met “Nooit” alleen na wijzigingen en bij openen.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minuut' : '$count minuten';
  @override
  String get syncIntervalNever => 'Nooit';
  @override
  String get syncWifiOnlyTitle => 'Alleen via wifi';
  @override
  String get syncWifiOnlySubtitle =>
      'Via mobiele data alleen handmatig synchroniseren';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 wijziging wacht' : '$count wijzigingen wachten';
  @override
  String syncRetryIn(String wait) => 'nieuwe poging over $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Wachten op wifi';
  @override
  String get syncWaitingForNetwork => 'Wachten op verbinding';
  @override
  String get syncMobileDataHint =>
      '“Nu synchroniseren” gebruikt toch mobiele data.';
  @override
  String get syncQueueKeptHint =>
      'Wijzigingen blijven hier, ook als je de app sluit, en worden vanzelf '
      'verstuurd zodra de server reageert.';
  @override
  String get syncAutoPaused => 'Automatische sync gepauzeerd';
  @override
  String get syncPausedAuthHint =>
      'Gaat verder zodra je het wachtwoord bijwerkt of handmatig '
      'synchroniseert.';
  @override
  String get syncPausedServerHint =>
      'Gaat verder zodra je het adres corrigeert of handmatig synchroniseert.';
  @override
  String get syncPausedConfirmHint =>
      '“Nu synchroniseren” toont wat er verwijderd zou worden en vraagt '
      'eerst.';
  @override
  String get syncNeedsConfirmation => 'Wacht op je bevestiging';
  @override
  String get syncMergeIntro =>
      'Wijzigingen die elkaar niet overlappen, zijn al samengevoegd; kies wat '
      'je houdt waar ze elkaar wel overlappen.';
  @override
  String get syncMergeClean =>
      'De twee versies voegen zichzelf samen: niets overlapt.';
  @override
  String get syncMergeNoBase =>
      'Er is geen gedeelde versie om op samen te voegen, dus het hele bestand '
      'moet gekozen worden.';
  @override
  String syncMergeOverlap(int index, int total) => 'Overlap $index van $total';
  @override
  String get syncMergeFromLocal => 'Van dit apparaat';
  @override
  String get syncMergeFromRemote => 'Van de server';
  @override
  String get syncMergeRemovedLines => 'Verwijderde regels';
  @override
  String get syncMergeKeepLocal => 'Van mij';
  @override
  String get syncMergeKeepRemote => 'Van de server';
  @override
  String get syncMergeKeepBoth => 'Beide';
  @override
  String get syncMergeSave => 'Samenvoeging opslaan';
  @override
  String get syncMergeKeepWhole => 'Of houd één hele kopie';
}
