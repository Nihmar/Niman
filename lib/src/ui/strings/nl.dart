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
  String get keyboardOnOpenTitle => 'Toetsenbord bij openen';
  @override
  String get keyboardOnOpenSubtitle =>
      'Toon het toetsenbord zodra een notitie opent (uit = bij de eerste tik)';
  @override
  String get editorKindSource => 'Markdown-brontekst';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
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
  String get shortcutToggleSidebar => 'Bestandsboom tonen of verbergen';
  @override
  String get shortcutEditorSection => 'In de editor';
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
  String get newFolderTitle => 'Nieuwe map';
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
}
