// The Swedish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class SwedishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'januari',
    'februari',
    'mars',
    'april',
    'maj',
    'juni',
    'juli',
    'augusti',
    'september',
    'oktober',
    'november',
    'december',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan',
    'feb',
    'mars',
    'apr',
    'maj',
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
    'måndag',
    'tisdag',
    'onsdag',
    'torsdag',
    'fredag',
    'lördag',
    'söndag',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'mån',
    'tis',
    'ons',
    'tors',
    'fre',
    'lör',
    'sön',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Papperskorgen';
  @override
  String get trashSubtitle =>
      'Borttagningar flyttas till .trash/ (av = permanent radering)';
  @override
  String get debugLogsTitle => 'Felsökningsloggar';
  @override
  String get debugLogsSubtitle =>
      'Registrera appens händelser i en buffert i minnet';
  @override
  String get lineNumbersTitle => 'Radnummer';
  @override
  String get lineNumbersSubtitle =>
      'Visa radnumrerkolumnen i anteckningseditorn';
  @override
  String get keyboardOnOpenTitle => 'Tangentbord vid öppning';
  @override
  String get keyboardOnOpenSubtitle =>
      'Visa tangentbordet så snart en anteckning öppnas (av = vid första '
      'beröringen)';
  @override
  String get editorKindSource => 'Markdown-källa';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Förhandsvisning';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Visa den renderade anteckningen bredvid källtexteditorn';
  @override
  String get switchToWysiwygTooltip => 'Byt till WYSIWYG-editorn';
  @override
  String get switchToSourceTooltip => 'Byt till Markdown-källan';
  @override
  String get wysiwygTooLarge =>
      'Denna anteckning är för stor för WYSIWYG-editorn. Öppna den i '
      'Markdown-källan.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Utseende';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliotek';
  @override
  String get settingsSectionReminders => 'Påminnelser';
  @override
  String get settingsSectionShortcuts => 'Tangentbord';
  @override
  String get keyboardShortcutsTitle => 'Tangentbordsgenvägar';
  @override
  String get settingsSectionDiagnostics => 'Diagnostik';
  @override
  String get settingsSpellCheckTitle => 'Stavkontroll';
  @override
  String get settingsSpellCheckSubtitle =>
      'Understryka felstavningar medan du skriver.';
  @override
  String get spellCheckDictionaryTitle => 'Ordbok';
  @override
  String get spellCheckDictionarySystem => 'Systemstandard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Välj ordböcker';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Välj alla språk som biblioteket är skrivet på. Ett ord går igenom '
      'när någon vald ordbok känner till det; utan val avgör '
      'systemspråket.';
  @override
  String get spellCheckNoDictionaries =>
      'Inga ordböcker hittades på det här systemet.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Stavkontroll';
  @override
  String get spellCheckTitle => 'Stavning';
  @override
  String get spellCheckEmpty => 'Inga stavfel.';
  @override
  String get spellCheckUnavailable =>
      'hunspell är inte installerad på det här systemet.';
  @override
  String get spellCheckNoSuggestions => 'Inga förslag';
  @override
  String spellCheckCount(int count) => '$count att granska';
  @override
  String spellCheckLine(int line) => 'rad $line';

  @override
  String indentWidthValue(int spaces) => '$spaces mellanslag';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Ljusstyrka';
  @override
  String get themeBrightnessSubtitle =>
      'Ljus, mörk eller vad enheten är inställd på';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Ljus';
  @override
  String get themeBrightnessNight => 'Mörk';
  @override
  String get themePaletteTitle => 'Färgpalett';
  @override
  String get themePaletteSubtitle =>
      'Färgerna i gränssnittet och i anteckningen';
  @override
  String get themePaletteSystem => 'System';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Gränssnittstextens storlek';
  @override
  String get uiTextScaleSubtitle =>
      'Trädet, flikarna och dialogrutor; ovanpå systeminställningen';
  @override
  String get noteTextScaleTitle => 'Anteckningarnas textstorlek';
  @override
  String get noteTextScaleSubtitle =>
      'Editorn och förhandsvisningen, som alltid håller ihop';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Förhandsvisningsläge';
  @override
  String get previewModeSubtitle =>
      'Huru förhandsvisningen delar skärmen med editorn eller ersätter '
      'den';
  @override
  String get previewModeAuto => 'Sida vid sida';
  @override
  String get previewModeSwitch => 'Helskärm';
  @override
  String get splitRatioTitle => 'Utdelningsbredd';
  @override
  String get splitRatioSubtitle =>
      'Editorns andel när förhandsvisningen är sida vid sida';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Länkformat';
  @override
  String get linkTypeSubtitle => 'Vad länkknappen i editorn inserar';
  @override
  String get linkTypeWikilink => 'Wikilänk';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Indenteringsbredd';
  @override
  String get indentWidthSubtitle =>
      'Mellanslag som läggs till per indenteringsnivå i editorn';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Språk';
  @override
  String get languageSubtitle => 'Språket på appens egen text';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Lägg till ett objekt';
  @override
  String get listAddTooltip => 'Lägg till ett objekt';
  @override
  String get listEmpty => 'Inga objekt ännu';
  @override
  String get listDragHandleLabel => 'Byt ordning på objektet';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Snabbanteckning';
  @override
  String get shortcutNewTodo => 'Ny uppgift';
  @override
  String get shortcutNewNote => 'Ny anteckning';
  @override
  String get shortcutNewList => 'Ny lista';
  @override
  String get shortcutToggleSidebar => 'Visa eller dölj filträdet';
  @override
  String get shortcutEditorSection => 'I editorn';
  @override
  String get shortcutFind => 'Sök';
  @override
  String get shortcutReplace => 'Sök och ersätt';
  @override
  String get shortcutSavingNote =>
      'Ändringar sparas automatiskt, så det finns ingen genväg för att '
      'spara.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Struktur';
  @override
  String get outlineNoHeadings => 'Inga rubriker';
  @override
  String get outlineNoTitle => '(ingen titel)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Fet';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'Genomstrykning';
  @override
  String get toolbarSuperscript => 'Upphöjd';
  @override
  String get toolbarUnderline => 'Understrykning';
  @override
  String get toolbarLink => 'Länk';
  @override
  String get toolbarCode => 'Kodblock';
  @override
  String get toolbarImage => 'Infoga bild';
  @override
  String get toolbarHeading => 'Rubrik';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Numrerad lista';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Indentera';
  @override
  String get toolbarOutdent => 'Ta bort indentering';
  @override
  String get headingDialogTitle => 'Rubriknivå';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editorverktygsfält';
  @override
  String get toolbarSettingsHint =>
      'Dra för att byta ordning; ögat visar eller döljer en knapp.';
  @override
  String get toolbarShowButton => 'Visa';
  @override
  String get toolbarHideButton => 'Dölj';
  @override
  String get toolbarResetOrder => 'Återställ standard';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Visa förhandsvisning';
  @override
  String get showEditorTooltip => 'Visa editor';
  @override
  String get enterFullScreenTooltip => 'Helskärm';
  @override
  String get exitFullScreenTooltip => 'Lämnar helskärm';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(rå HTML-tabell)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Sök i anteckningar';
  @override
  String get searchModeWords => 'Ord';
  @override
  String get searchModeContains => 'Innehåller';
  @override
  String get searchEmptyHint =>
      'Skriv för att söka i biblioteket, eller nyckel = värde för att '
      'filtrera på frontmatter';
  @override
  String get searchTooShortHint => 'Skriv minst 2 tecken';
  @override
  String get searchNoMatches => 'Inga träffar';
  @override
  String get searchLoadMore => 'Visa mer';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Ersätt…';
  @override
  String get replaceInNoteAction => 'Ersätt i den här anteckningen…';
  @override
  String get replaceInThisNote => 'Ersätt i den här anteckningen';
  @override
  String get replaceWithLabel => 'Ersätt med';
  @override
  String get replaceCaseSensitive => 'Skiftlägeskänsligt';
  @override
  String get replaceWholeWordsHint => 'bara exakta helt-ord-träffar ersätts';
  @override
  String get replaceConfirm => 'Ersätt';
  @override
  String get replaceCancel => 'Stäng';
  @override
  String get replaceUnavailable => 'Ersätt är inte tillgängligt just nu';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Sök i anteckning';
  @override
  String get editorFindHint => 'Sök';
  @override
  String get editorReplaceHint => 'Ersätt';
  @override
  String get editorFindCaseTooltip => 'Skiftlägeskänsligt';
  @override
  String get editorFindPreviousTooltip => 'Föregående träff';
  @override
  String get editorFindNextTooltip => 'Nästa träff';
  @override
  String get editorFindCloseTooltip => 'Stäng sök';
  @override
  String get editorFindReplaceModeTooltip => 'Ersättningsläge';
  @override
  String get editorReplaceOneTooltip => 'Ersätt den här träffen';
  @override
  String get editorReplaceAllTooltip => 'Ersätt alla träffar';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Taggar';
  @override
  String get tagsTitle => 'Taggar';
  @override
  String get tagsEmpty =>
      'Inga taggar ännu — lägg till en #tag eller taggar i frontmatter';
  @override
  String get tagsBackTooltip => 'Tillbaka till sökning';
  @override
  String get tagsNotesEmpty => 'Inga anteckningar med den här taggen';
  @override
  String tagsNotesCapped(int limit) =>
      'Bara de första $limit listas — sök taggen för att begränsa';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Länken hittades inte';
  @override
  String get headingNotFoundTitle => 'Rubriken hittades inte';
  @override
  String get ambiguousLinkTitle => 'Flera anteckningar matchar';
  @override
  String get openLinkFailed => 'Kunde inte öppna länken';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Öppna';
  @override
  String get todoDone => 'Klart';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Alla datum';
  @override
  String get todoFilter => 'Filtrera';
  @override
  String get todoNoTokens => 'Inga token i den här listan';
  @override
  String get todoCountOpen => 'öppna';
  @override
  String get todoCountDone => 'klar';
  @override
  String get todoEmptyOpen => 'Inga pågående uppgifter ännu';
  @override
  String get todoEmptyDone => 'Inget slutfört ännu';
  @override
  String get todoEmptyFiltered => 'Inga uppgifter matchar';
  @override
  String get todoTitle => 'Att göra';
  @override
  String get todoAddTooltip => 'Lägg till uppgift';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt-formatet';
  @override
  String get todoHelpTooltip => 'Formatinformation';
  @override
  String get todoHelpIntro =>
      'Dina uppgifter är en vanlig textfil, en uppgift per rad. Niman '
      'skriver syntaxen åt dig, men ingenting göms: du kan redigera filen '
      'i valfri editor och Niman läser den igen.';
  @override
  String get todoHelpFilesTitle => 'De två filerna';
  @override
  String get todoHelpFilesBody =>
      'Öppna uppgifter ligger i todo.txt i roten av biblioteket. '
      'Slutför en och raden flyttas till done.txt, så att todo.txt hålls '
      'kort. Om en slutförd rad hamnar tillbaka i todo.txt arkiverar '
      'Niman den nästa gång den läser filerna.';
  @override
  String get todoHelpLineTitle => 'En rads anatomi';
  @override
  String get todoHelpLineBody =>
      'Allt före beskrivningen är valfritt och måste komma i denna '
      'ordning:';
  @override
  String get todoHelpDoneBody =>
      'Markerar uppgiften som klar. Niman lägger till den när du bockar i '
      'rutchen.';
  @override
  String get todoHelpPriority => '(A) till (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritet. A är den högsta. Visas som en märke i listan.';
  @override
  String get todoHelpDatesBody =>
      'Slutdatum, sedan skapadatum. Med bara ett datum är det skapadatum, '
      'om raden inte börjar med x.';
  @override
  String get todoHelpTokensTitle => 'Projekt, kontexter och taggar';
  @override
  String get todoHelpTokensBody =>
      'Var som helst i beskrivningen blir ett ord med ett av dessa prefix '
      'en chip du kan filtrera på. Inget är fördefinierat: ett token finns '
      'så snart du skriver det.';
  @override
  String get todoHelpProjectBody =>
      'Vad uppgiften ingår i, till exempel +kök eller +examensarbete.';
  @override
  String get todoHelpContextBody =>
      'Var eller hur du kommer att göra den, till exempel @hemma eller '
      '@samtal.';
  @override
  String get todoHelpHashtagBody =>
      'En fri etikett, för allt det andra två inte täcker.';
  @override
  String get todoHelpTagsTitle => 'Datum och påminnelser';
  @override
  String get todoHelpTagsBody =>
      'De här är nyckel: värde-taggar. Niman skriver dem från '
      'uppgiftdialogen och läser dem var de än förekommer på raden.';
  @override
  String get todoHelpDueBody =>
      'Förfallsdatumet. Styrs av den färgade märken och datumfilterna.';
  @override
  String get todoHelpRemBody =>
      'När en avisering ska skickas, i din lokala tid. Den utlöses med '
      'skärmen avstängd och appen stängd.';
  @override
  String get todoHelpRemDesktop =>
      'På skrivbord måste Niman vara i gång när tiden är inne: påminnelsen '
      'visas medan appen är öppen, och ingenting utlöses när den är '
      'stängd.';
  @override
  String get todoHelpOtherBody =>
      'Bevaras exakt som skrivet, så att taggar från andra todo.txt-appar '
      'överlever en omväg. Niman agerar inte på dem, rec: included: en '
      'återkommande uppgift upprepas inte än.';
  @override
  String get todoHelpEditTitle => 'Redigering utanför Niman';
  @override
  String get todoHelpEditBody =>
      'En uppgift du inte rört skrivs tillbaka byte för byte, konstiga '
      'avstånd medräknade. Redigera en rad och Niman skriver om just den '
      'raden i sin kanoniska form och rör inte resten av filen.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Lägg till uppgift';
  @override
  String get todoEditTitle => 'Redigera uppgift';
  @override
  String get todoDescriptionHint => 'Beskrivning';
  @override
  String get todoCancel => 'Avbryt';
  @override
  String get todoSave => 'Spara';
  @override
  String get todoEditAction => 'Redigera';
  @override
  String get todoDeleteAction => 'Ta bort';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Över tid';
  @override
  String get todoDueToday => 'Idag';
  @override
  String get todoDueNext7 => 'Nästa 7 dagar';
  @override
  String get todoDueNoDate => 'Inget datum';
  @override
  String get todoRowDue => 'Förfällig';
  @override
  String get todoRowDueToday => 'Förfällig idag';
  @override
  String get todoSortTooltip => 'Sortera';
  @override
  String get todoSortDue => 'Förfallsdatum';
  @override
  String get todoSortPriority => 'Prioritet';
  @override
  String get todoSortCreation => 'Skapadatum';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Ingen prioritet';
  @override
  String get todoNoPriorityShort => 'Ingen';
  @override
  String get todoMorePriorities => 'Fler…';
  @override
  String get todoPriorityTitle => 'Prioritet';
  @override
  String get todoNoDueDate => 'Inget förfallsdatum';
  @override
  String get todoNoReminder => 'Ingen påminnelse';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontext';
  @override
  String get todoAddHashtag => '# Tagg';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Uppgiftspåminnelser';
  @override
  String get todoReminderChannelDescription =>
      'Schemalagda aviseringar för uppgifter med påminnelsestid.';
  @override
  String get todoReminderBody => 'Att-göra-påminnelse';
  @override
  String get todoReminderFallbackTitle => 'Uppgiftspåminnelse';
  @override
  String get todoReminderBlocked =>
      'Aviseringar är avstängda, så påminnelser visas inte.';
  @override
  String get todoReminderBattery =>
      'Batterioptimering är påslagen för Niman. Systemet kan låta appen '
      'sova och tappa väntande påminnelser.';
  @override
  String get todoReminderInexact =>
      'Den här enheten tillåter inte exakta alarmer, så en påminnelse kan '
      'komma flera minuter sent med skärmen avstängd.';
  @override
  String get reminderShowTokensTitle => 'Taggar i påminnelseaviseringar';
  @override
  String get reminderShowTokensSubtitle =>
      'Behåll +projekt, @kontext och #tag i aviseringstexten. Av visar '
      'bara den uppgift du skrev.';
  @override
  String get todoReminderFixAction => 'Öppna inställningar';
  @override
  String get todoReminderDismissAction => 'Ignorera';
  @override
  String get todoReminderDue => 'Förfällig';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Avbryt';
  @override
  String get actionCreate => 'Skapa';
  @override
  String get actionNew => 'Ny';
  @override
  String get actionSave => 'Spara';
  @override
  String get actionClear => 'Rensa';
  @override
  String get actionChoose => 'Välj';
  @override
  String get actionDelete => 'Ta bort';
  @override
  String get actionRename => 'Byt namn';
  @override
  String get actionMove => 'Flytta';
  @override
  String get saveAndClose => 'Spara och stäng';
  @override
  String get closeUnsavedTitle => 'OSparade ändringar';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” har ändringar som inte är sparade ännu. '
          'Spara dem innan stängning?';
    }
    return '${names.length} anteckningar har ändringar som inte är sparade '
        'ännu. Spara dem innan stängning?';
  }

  @override
  String get closeSaveFailed => 'Kunde inte spara; fortfarande öppen.';
  @override
  String get actionRestore => 'Återställ';
  @override
  String get actionEmpty => 'Töm';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Dölj sidopanelen (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Visa sidopanelen (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimera';
  @override
  String get windowMaximizeTooltip => 'Maximera';
  @override
  String get windowRestoreTooltip => 'Återställ';
  @override
  String get windowCloseTooltip => 'Stäng';
  @override
  String get tabFiles => 'Filer';
  @override
  String get tabSearch => 'Sök';
  @override
  String get tabSettings => 'Inställningar';
  @override
  String get quickNoteTitle => 'Snabbanteckning';
  @override
  String get treeEmpty => 'Inga anteckningar ännu';
  @override
  String get selectANote => 'Välj en anteckning';
  @override
  String get showListTooltip => 'Visa lista';
  @override
  String get editRawTooltip => 'Redigera rå';
  @override
  String get sortAscTooltip => 'Sortera A-Ö';
  @override
  String get sortDescTooltip => 'Sortera Ö-A';
  @override
  String get newNoteTitle => 'Ny anteckning';
  @override
  String get newFolderTitle => 'Ny mapp';
  @override
  String get newNoteHere => 'Ny anteckning här';
  @override
  String get newFolderHere => 'Ny mapp här';
  @override
  String get newListNoteTitle => 'Ny listaanteckning';
  @override
  String get newListNoteDefault => 'Min lista';
  @override
  String get setAsQuickNote => 'Sätt som snabbanteckning';
  @override
  String get currentQuickNote => 'Aktuell snabbanteckning';
  @override
  String get pinnedSection => 'Fästa';
  @override
  String pinnedSectionCount(int count) => 'Fästa · $count';
  @override
  String get templateFolderTitle => 'Mallmapp';
  @override
  String get newFromTemplateTitle => 'Ny från mall';
  @override
  String get newFromTemplateHere => 'Ny från mall här';
  @override
  String get templateFormTitle => 'Fyll i mallen';
  @override
  String get templateFormBacklink => 'Länkad från';
  @override
  String get templateFormNoNote => 'Ingen anteckning';
  @override
  String get templateFormPickNote => 'Välj anteckningen';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Mallplatshållare';
  @override
  String get templateHelpIntro =>
      'En mall är en vanlig anteckning med hål i. Att skapa en anteckning '
      'ur en kopierar texten och fyller hålen.';
  @override
  String get templateHelpUnknown =>
      'En platshållare Niman inte känner till lämnas exakt som skrivet, '
      'så ett stavfel syns i anteckningen i stället för att tyst äta en '
      'rad.';
  @override
  String get templateHelpValuesTitle => 'Värden';
  @override
  String get templateHelpTitleBody => 'Namnet anteckningen skapas med.';
  @override
  String get templateHelpDateBody =>
      'Idag, och klockan nu. Båda tar ett format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum och klocka tillsammans.';
  @override
  String get templateHelpUuidBody =>
      'En ny identifierare, en annan vid varje förekomst.';
  @override
  String get templateHelpCounterBody =>
      'Ett tal som räknar upp per namn, bevarat över omstartar: den första '
      'anteckningen skriver 1, nästa 2. Samma namn i en anteckning skriver '
      'samma tal; kombinera med |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Sätter markören här när anteckningen skapas; markören själv '
      'skrivs inte. Första markören vinner, inga filter, bara nya '
      'anteckningar — och tangentbordet öppnas även med autofokus '
      'avstängt.';
  @override
  String get templateHelpDatesTitle => 'Att skriva ett datum';
  @override
  String get templateHelpDatesBody =>
      'De här står för delar av datumen i ett format. Allt annat är '
      'bokstavligt, och text i enkelcitat är också bokstavligt. Månads- '
      'och veckodagsnamn följer appens språk.';
  @override
  String get templateHelpYear => 'året: 2026, 26';
  @override
  String get templateHelpMonth => 'månaden: 03, 3, mars, mar';
  @override
  String get templateHelpDay => 'dagen: 09, 9, måndag, mån';
  @override
  String get templateHelpTime => 'timmar, minuter, sekunder';
  @override
  String get templateHelpWeek => 'ISO-vecka och kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filter';
  @override
  String get templateHelpFiltersBody =>
      'Ett värde kan följas av filter, tillämpade vänster till höger.';
  @override
  String get templateHelpCaseBody =>
      'Versaler, gemener och den första bokstaven i varje ord — ett ord '
      'du själv högbokstävat lämnas orört.';
  @override
  String get templateHelpSlugBody =>
      'Länkformen av texten, för att bygga en wikilänk.';
  @override
  String get templateHelpPadBody =>
      'Boka av ändarna; fylla med nollor till en bredd; använd ett '
      'alternativ när värdet är tomt.';
  @override
  String get templateHelpShiftBody =>
      'Flytta ett datum med dagar, veckor, månader eller år — nästa '
      'veckas föreläsning, förra månadens fil.';
  @override
  String get templateHelpSnapBody =>
      'Ställ in ett datum på början eller slutet av dess vecka, månad '
      'eller år.';
  @override
  String get templateHelpAskTitle => 'Att fråga dig något';
  @override
  String get templateHelpAskBody =>
      'Ett formulär visas innan anteckningen skapas, en ruta per fråga — '
      'och en för baklänken, när mallen vill ha en. Samma etikett två '
      'gånger är en fråga, och svaret fyller varje förekomst — mapp och '
      'filnamn medräknade.';
  @override
  String get templateHelpAskFieldBody =>
      'En ruta att skriva i; texten efter det andra kolontecknet är vad '
      'den börjar med.';
  @override
  String get templateHelpChoiceBody =>
      'Ett val ur en lista, separerat med kommas.';
  @override
  String get templateHelpWhereTitle => 'Vär anteckningen hamnar';
  @override
  String get templateHelpWhereBody =>
      'De här är inte text: de är instruktioner, och de bor i en niman: '
      'block i mallens egen frontmatter. Blocket lydnas och tas sedan '
      'bort, så det visas aldrig i anteckningen. Deras värden kan '
      'innehålla platshållare.';
  @override
  String get templateHelpFolderBody =>
      'Mappen anteckningen skapas i, skapas om den inte finns. Utan den '
      'landar anteckningen där du var.';
  @override
  String get templateHelpFilenameBody =>
      'Vad anteckningen heter. En mall som anger det här frågas inte om '
      'ett namn.';
  @override
  String get templateHelpAppendBody =>
      'Lägg till i anteckningen om den redan finns, i stället för att '
      'göra en andra. Det är det som gör en månad av möten till en fil.';
  @override
  String get templateHelpOpenBody =>
      'Vad som händer när anteckningen finns: editorn (standard), '
      'förhandsvisningen, eller ingenting — anteckningen arkiveras och du '
      'stannar där du var.';
  @override
  String get templateHelpAroundTitle => 'Var det kom ifrån';
  @override
  String get templateHelpParentBody =>
      'En anteckning du väljer i formuläret, som föreslår den på skärmen; '
      'skriv [[{{parent}}]] för en länk tillbaka.';
  @override
  String get templateHelpFolderValueBody => 'Mappen anteckningen hamnade i.';
  @override
  String get templateHelpClipboardBody =>
      'Vad som ligger i klippbordet, och editorvalen när anteckningen '
      'startades från en.';
  @override
  String get templateHelpIncludeTitle => 'Återanvända ett stycke';
  @override
  String get templateHelpIncludeBody =>
      'Klistrar in en annan mall, så tio mallar kan dela en checklista. '
      'Den söks upp i mallmappen först, och .md kan utelämnas. Dens egna '
      'frågor går med i samma formulär.';
  @override
  String get templateHelpExampleTitle => 'Allt tillsammans';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ ingen mall “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” inkluderar sig själv';
  @override
  String includeTooDeep(String path) => '⚠ “$path” är för djupt nästlad';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter inte läst: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatter för “$template” lästes inte, så mapp och filnamn gjorde '
      'ingenting: $reason';
  @override
  String get templatePickerTitle => 'Välj en mall';
  @override
  String templatePickerEmpty(String folder) =>
      'Inga mallar ännu. Lägg en anteckning i $folder/ och den blir en.';

  // Tree actions.
  @override
  String get actionPin => 'Fäst';
  @override
  String get actionUnpin => 'Lösen';
  @override
  String get movedToTrash => 'Flyttad till papperskorgen';
  @override
  String get deletedMessage => 'Togs bort';
  @override
  String deleteToTrashConfirm(String name) => '$name flyttas till .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name tas bort permanent';
  @override
  String get chooseDestination => 'Välj mål';
  @override
  String get libraryRoot => 'Bibliotekets rot';
  @override
  String moveTitle(String name) => 'Flytta $name';
  @override
  String headingLevelLabel(int level) => 'Rubrik $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ingen snabbanteckning ännu. Välj en befintlig anteckning, eller '
      'skapa en ny — snabbanteckningen öppnas här.';
  @override
  String get quickNoteChooseAction => 'Välj en anteckning…';
  @override
  String get quickNoteCreateAction => 'Skapa en ny anteckning…';
  @override
  String get quickNoteNewTitle => 'Ny snabbanteckning';
  @override
  String get quickNotePickerTitle => 'Välj snabbanteckning';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Ny mapp';
  @override
  String get folderPickerEmpty => 'Inga mappar ännu';
  @override
  String get listFolderTitle => 'Listmapp';

  // Trash (M1).
  @override
  String get trashEmpty => 'Papperskorgen är tom';
  @override
  String get trashEmptyAction => 'Töm papperskorgen';
  @override
  String get trashEmptyConfirm =>
      'Det här raderar allt i papperskorgen permanent, inklusive objekt '
      'Niman inte lagt dit.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name raderas permanent (ingen återställning)';
  @override
  String get trashDeletePermanently => 'Radera permanent';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Öppna en mapp med Markdown-anteckningar som bibliotek';
  @override
  String get openLibraryExisting => 'Öppna befintlig';
  @override
  String get openLibraryCreate => 'Skapa ny';
  @override
  String get openLibraryCreateTitle => 'Skapa nytt bibliotek';
  @override
  String get openLibraryFolderName => 'Mappnamn';
  @override
  String get openLibraryChooseFolder => 'Välj biblioteksmappen';
  @override
  String get openLibraryChooseParent => 'Välj mappen biblioteket ska skapas i';
  @override
  String get openLibraryUnsupported =>
      'Den mappen stöds inte. Välj en mapp i enhetens lagring.';
  @override
  String indexingCount(int done, int total) => '$done av $total anteckningar';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Dina bibliotek';
  @override
  String get libraryUnreachable => 'Onåbar';
  @override
  String get libraryOpenedToday => 'Öppnad idag';
  @override
  String get libraryOpenedYesterday => 'Öppnad igår';
  @override
  String libraryOpenedDaysAgo(int days) => 'Öppnad för $days dagar sedan';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Öppnad ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Öppen nu';
  @override
  String get switchLibraryTitle => 'Byt bibliotek';
  @override
  String get libraryForget => 'Glöm';
  @override
  String libraryForgetTitle(String name) => 'Glömma “$name”?';
  @override
  String get libraryForgetExplained =>
      'Den försvinner ur den här listan. Mappen, anteckningarna och '
      'biblioteksinställningarna i den rör inte, och att öppna den igen '
      'tar den tillbaka.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Bevilja filåtkomst';
  @override
  String get storageAccessNeeded =>
      'Niman kan inte läsa dina anteckningar utan “All filåtkomst”. '
      'Bevilja det för att öppna ett bibliotek.';
  @override
  String get storageAccessExplained =>
      'Niman läser dina anteckningar som vanliga filer, så Android behöver '
      'ge det åtkomst till alla filer. Inget laddas upp, och bara den '
      'biblioteksmapp du väljer läses.';
  @override
  String folderAccessDenied(Object error) =>
      'Systemet gav ingen åtkomst till mappen: $error';
  @override
  String folderPickFailed(Object error) => 'Kunde inte välja en mapp: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Inställningar';
  @override
  String get libraryPathTitle => 'Bibliotekspath';
  @override
  String get reindexTitle => 'Indexera om nu';
  @override
  String get reindexDone => 'Omindexering klar';
  @override
  String get closeLibraryTitle => 'Stäng biblioteket';
  @override
  String get exportLogTitle => 'Exportera felsökningsloggen';
  @override
  String get exportLogSubtitle =>
      'Spara de registrerade händelserna till en fil du väljer';
  @override
  String get exportLogEmpty => 'Felsökningsloggbufferten är tom';
  @override
  String get quickNoteUnset => 'Inte satt ännu';
  @override
  String exportLogDone(Object target) =>
      'Felsökningsloggen exporterad till $target';
  @override
  String exportLogFailed(Object error) => 'Exporten misslyckades: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ingen exakt helt-ord-träff på “$term” hittades';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Ersatte $occurrences förekomster av “$term” i $notes anteckningar';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped öppna anteckningar hoppade över)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ingen exakt helt-ord-träff på “$term” '
      '${only == null ? 'hittades' : 'hittad i $only'}';
}
