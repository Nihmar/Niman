// The Catalan strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class CatalanStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'gener',
    'febrer',
    'març',
    'abril',
    'maig',
    'juny',
    'juliol',
    'agost',
    'setembre',
    'octubre',
    'novembre',
    'desembre',
  ];
  @override
  List<String> get monthNamesShort => const [
    'gen',
    'febr',
    'març',
    'abr',
    'maig',
    'juny',
    'jul',
    'ag',
    'set',
    'oct',
    'nov',
    'des',
  ];
  @override
  List<String> get weekdayNames => const [
    'dilluns',
    'dimarts',
    'dimecres',
    'dijous',
    'divendres',
    'dissabte',
    'diumenge',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'dl',
    'dt',
    'dc',
    'dj',
    'dv',
    'ds',
    'dg',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Paperera';
  @override
  String get trashSubtitle =>
      'Les eliminacions es mouen a .trash/ (desactivat = esborrament '
      'permanent)';
  @override
  String get trashAutoEmptyTitle => 'Buidatge automàtic de la paperera';
  @override
  String get trashAutoEmptySubtitle =>
      'Les supressions antigues desapareixen per sempre en obrir la biblioteca';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Mai'
      : days == 1
      ? '1 dia'
      : '$days dies';
  @override
  String get debugLogsTitle => 'Registres de depuració';
  @override
  String get debugLogsSubtitle =>
      'Registra els esdeveniments de l’app en un búfer de memòria';
  @override
  String get lineNumbersTitle => 'Numeros de línia';
  @override
  String get lineNumbersSubtitle =>
      'Mostra la columna de numeros de línia a l’editor de notes';
  @override
  String get readableLineLengthTitle => 'Longitud de línia llegible';
  @override
  String get readableLineLengthSubtitle =>
      'Mantén el text de la nota en una columna centrada en lloc de tota '
      'l’amplada de la finestra';
  @override
  String get noteColumnWidthTitle => 'Amplada de la columna';
  @override
  String get noteColumnWidthSubtitle =>
      'L’amplada de la columna de la nota; 100% és la predeterminada';
  @override
  String get keyboardOnOpenTitle => 'Teclat en obrir';
  @override
  String get keyboardOnOpenSubtitle =>
      'Mostra el teclat en obrir una nota (desactivat = amb la primera '
      'tocada)';
  @override
  String get editorKindSource => 'Font Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Font Markdown, tal com està escrita';
  @override
  String get editorKindWysiwygSubtitle => 'Text amb format, editat directament';
  @override
  String get settingsFolderToCreate => 'per crear';
  @override
  String get settingsSearchHint => 'Cerca la configuració';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 paràmetre trobat' : '$count paràmetres trobats';
  @override
  String get settingsToggleOn => 'Activat';
  @override
  String get settingsToggleOff => 'Desactivat';
  @override
  String get switchToWysiwygTooltip => 'Canvia a l’editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Canvia a la font Markdown';
  @override
  String get switchToSourceLabel => 'Font';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aparença';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionReminders => 'Recordatoris';
  @override
  String get keyboardShortcutsTitle => 'Dreceres de teclat';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteca $name';
  @override
  String get settingsGroupLibraryHint => "només s'aplica a aquesta biblioteca";
  @override
  String get settingsGroupMaintenance => 'Manteniment';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Carpetes i camins';
  @override
  String get settingsAreaTrashHistory => 'Paperera i cronologia';
  @override
  String get settingsAreaDiagnostics => 'Diagnòstic i informació';
  @override
  String get settingsAreaKeyboardDisabled => 'Cal un teclat físic connectat';
  @override
  String get settingsSectionUpdates => 'Actualitzacions';
  @override
  String get autoUpdateTitle => 'Actualitzacions automàtiques';
  @override
  String get autoUpdateSubtitle =>
      'Comprova GitHub Releases en iniciar i cada 6 hores';
  @override
  String get checkForUpdatesTitle => 'Cerca actualitzacions';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version està disponible';
  @override
  String get updateUpToDate => 'Niman està actualitzat';
  @override
  String get updateCheckFailed =>
      'No s’han pogut comprovar les actualitzacions';
  @override
  String updateSavedTo(Object path) => 'Actualització guardada a $path';
  @override
  String get updateInstallerStarted => 'Instal·lador iniciat';
  @override
  String get settingsSpellCheckTitle => 'Comprovació d’ortografia';
  @override
  String get settingsSpellCheckSubtitle =>
      'Subratlla els errors d’escritura mentre escreis.';
  @override
  String get spellCheckDictionaryTitle => 'Diccionari';
  @override
  String get spellCheckDictionarySystem => 'Per defecte del sistema';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Trieu diccionaris';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Trieu tots els idiomes en què està escrita la biblioteca. Una '
      'paraula passa quan algun dels diccionaris triats la coneix; sense '
      'selecció, l’idioma del sistema decideix.';
  @override
  String get spellCheckNoDictionaries =>
      'No s’ha trobat cap diccionari en aquest sistema.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Comprovació d’ortografia';
  @override
  String get spellCheckTitle => 'Ortografia';
  @override
  String get spellCheckEmpty => 'No hi ha errors d’ortografia.';
  @override
  String get spellCheckUnavailable =>
      'hunspell no està instal·lat en aquest sistema.';
  @override
  String get spellCheckNoSuggestions => 'Cap suggeriment';
  @override
  String spellCheckCount(int count) => '$count a revisar';
  @override
  String spellCheckLine(int line) => 'línia $line';
  @override
  String get addWordToDictionary => 'Afegeix al diccionari';

  @override
  String indentWidthValue(int spaces) => '$spaces espais';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Il·luminació';
  @override
  String get themeBrightnessSubtitle =>
      'Clar, fosc o el que tingui configurat el dispositiu';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Clar';
  @override
  String get themeBrightnessNight => 'Fosc';
  @override
  String get themeTitle => 'Tema';
  @override
  String get themePaletteSystem => 'Sistema';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Temes';
  @override
  String get themesInUse => 'En ús';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Tema nou';
  @override
  String get themeNewName => 'Nom';
  @override
  String get themeNewStartFrom => 'Parteix de';
  @override
  String get themeNewRandom => 'Colors aleatoris';
  @override
  String get themeNameTaken => 'Ja existeix un tema amb aquest nom';
  @override
  String themeDeleteBody(String name) =>
      'Voleu suprimir «$name»? Els seus colors es perdran per sempre.';
  @override
  String get themeDuplicate => 'Duplica';
  @override
  String get themeMenuTooltip => 'Accions del tema';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Edita';
  @override
  String get themeEditorTitle => 'Edita el tema';
  @override
  String get themeEditorChrome => 'Interfície';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Llistes de tasques (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Cada color porta el nom que fa servir el fitxer exportat';
  @override
  String get themeEditorDiscardTitle => 'Descarta els canvis';
  @override
  String get themeEditorDiscardBody => 'Els colors que has canviat no es desen';
  @override
  String get themeEditorDiscard => 'Descarta';
  @override
  String get themeEditorBadColor => 'Fes servir #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Exporta';
  @override
  String themeExportDone(String where) => 'Tema exportat a $where';
  @override
  String themeFileFailed(String error) => 'No s’ha pogut moure el tema: $error';
  @override
  String get themeImport => 'Importa';
  @override
  String get themeImportInvalid => 'Aquest fitxer no és un tema del Niman';
  @override
  String themeImportVersion(int version) =>
      'Aquest tema és d’un Niman més nou (versió $version)';
  @override
  String themeImportBadRole(String role) =>
      'El fitxer no dona cap color per a «$role»';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Mida del text de la interfície';
  @override
  String get uiTextScaleSubtitle =>
      'L’arbre, les pestanyes i els diàlegs; per sobre de la '
      'configuració del sistema';
  @override
  String get noteTextScaleTitle => 'Mida del text de la nota';
  @override
  String get noteTextScaleSubtitle =>
      'L’editor i la previsualització, sempre d’acord';
  @override
  String get sourceFontTitle => 'Tipografia de l’editor de codi font';
  @override
  String get sourceFontSubtitle =>
      'La tipografia del plafó de codi font; la previsualització manté la de '
      'la nota';
  @override
  String get sourceFontMonospace => 'Monoespaiada';
  @override
  String get sourceFontSansSerif => 'Sense serifes';
  @override
  String get sourceFontSerif => 'Amb serifes';
  @override
  String get epubLookTitle => 'Aspecte dels llibres';
  @override
  String get epubLookSubtitle =>
      'Tema, tipus de lletra i mida del text dels llibres EPUB, a part de les '
      'notes';
  @override
  String get epubSameAsApp => "Com l'aplicació";
  @override
  String get epubFontTitle => 'Tipus de lletra';
  @override
  String get epubFontSerif => 'Amb gràcia';
  @override
  String get epubFontSans => 'Sense gràcia';
  @override
  String get epubFontMono => 'Monoespaiat';
  @override
  String get epubTextSizeTitle => 'Mida del text';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Format de l’enllaç';
  @override
  String get linkTypeSubtitle =>
      'Què insereix el botó d’enllaç a '
      'l’editor';
  @override
  String get linkTypeWikilink => 'Enllaç wiki';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Crear notes que manquen a';
  @override
  String get missingNoteLocationRoot => 'Arrel de la biblioteca';
  @override
  String get missingNoteLocationCurrentFolder => 'Carpeta actual';
  @override
  String get indentWidthTitle => 'Ample del sagnat';
  @override
  String get indentWidthSubtitle =>
      'Espaces que s’afegeixen per nivell de sagnat a l’editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Idioma';
  @override
  String get languageSubtitle => 'L’idioma del propi text de l’app';
  @override
  String get languageSystem => 'Sistema';
  @override
  String get weekStartTitle => 'Primer dia de la setmana';
  @override
  String get weekStartSubtitle =>
      'On els calendaris comencen la setmana. El del sistema per defecte; un '
      'dia triat aquí val a cada dispositiu de la biblioteca.';
  @override
  String get weekStartSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Afegeix un element';
  @override
  String get listAddTooltip => 'Afegeix un element';
  @override
  String get listEmpty => 'Encara no hi ha elements';
  @override
  String get listDragHandleLabel => 'Canvia l’ordre de l’element';
  @override
  String get shoppingListName => 'Llista de la compra';
  @override
  String get checklistName => 'Llista de control';
  @override
  String get shoppingQuantityLabel => 'Quantitat';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Encara no hi ha enregistraments';
  @override
  String get audioRecord => 'Enregistra';
  @override
  String get audioStop => 'Atura';
  @override
  String get audioPlay => 'Reprodueix';
  @override
  String get audioDelete => 'Esborra l’enregistrament';
  @override
  String get audioImport => 'Importa un fitxer d’àudio';
  @override
  String get audioRecording => 'Enregistrant…';
  @override
  String get audioPermissionDenied =>
      'Permís del micròfon denegat — cal per enregistrar.';
  @override
  String get newAudioNoteTitle => 'Nota de veu nova';
  @override
  String get newAudioNoteDefault => 'El meu enregistrament';
  @override
  String get showAudioTooltip => 'Mostra els enregistraments';
  @override
  String get audioMessageHint => 'Escriu una nota…';
  @override
  String get audioSend => 'Envia';
  @override
  String get audioRename => 'Canvia el nom de l’enregistrament';
  @override
  String get audioDescriptionHint => 'Descriu aquest enregistrament…';
  @override
  String get audioEditDescription => 'Edita la descripció';
  @override
  String get audioDeleteNote => 'Esborra la nota';
  @override
  String get audioEditNote => 'Edita la nota';
  @override
  String get audioPause => 'Pausa';
  @override
  String get audioEditTitle => 'Edita el títol';
  @override
  String get audioTitleHint => "Títol d'aquesta gravació…";
  @override
  String audioUntitled(int n) => 'Gravació $n';
  @override
  String get audioMoreActions => 'Més accions';
  @override
  String get audioDiscardRecording => 'Descarta la gravació';
  @override
  String get audioPauseRecording => 'Posa en pausa la gravació';
  @override
  String get audioResumeRecording => 'Reprèn la gravació';
  @override
  String get audioRecordingPaused => 'En pausa';
  @override
  String get audioSavingRecording => 'Desant…';
  @override
  String get audioPlayFailed => 'No s’ha pogut reproduir l’àudio';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota ràpida';
  @override
  String get trayOpen => 'Obre el Niman';
  @override
  String get trayQuit => 'Surt';
  @override
  String get closeToTrayTitle => 'Tanca a l’àrea de notificació';
  @override
  String get closeToTraySubtitle =>
      'La × de la finestra amaga el Niman i el deixa funcionant, així els '
      'recordatoris segueixen arribant. Se surt des del menú de la icona.';
  @override
  String get shortcutNewTodo => 'Tasca nova';
  @override
  String get shortcutNewNote => 'Nota nova';
  @override
  String get shortcutNewList => 'Llista nova';
  @override
  String get shortcutNewAudio => 'Nota de veu nova';
  @override
  String get shortcutToggleSidebar => 'Mostra o amaga el filtre';
  @override
  String get shortcutCloseTab => 'Tanca la nota actual';
  @override
  String get shortcutNextTab => 'Nota oberta següent';
  @override
  String get shortcutPreviousTab => 'Nota oberta anterior';
  @override
  String get shortcutEditorSection => 'A l’editor';
  @override
  String get shortcutFormatSection => 'Format';
  @override
  String get shortcutFind => 'Cerca';
  @override
  String get shortcutReplace => 'Cerca i reemplaça';
  @override
  String get shortcutSavingNote =>
      'Els canvis es guarden automàticament, per tant no hi ha cap '
      'drecera de guardat.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Carregant…';
  @override
  String get noteStatusSaving => 'Desant…';
  @override
  String get noteStatusUnsaved => 'Sense desar';
  @override
  String get noteStatusSaved => 'Desat';
  @override
  String get noteStatusError => 'Error';
  @override
  String get noteNotText =>
      'Aquest fitxer no és una nota de text, així '
      'que Niman no el pot mostrar aquí.';
  @override
  String get noteLoadFailed => 'No s’ha pogut obrir aquesta nota.';
  @override
  String wordCount(int count) => count == 1 ? '1 paraula' : '$count paraules';
  @override
  String get outlineTooltip => 'Estructura';
  @override
  String get outlineNoHeadings => 'Cap títol';
  @override
  String get outlineNoTitle => '(sense títol)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Negreta';
  @override
  String get toolbarItalic => 'Cursiva';
  @override
  String get toolbarStrikethrough => 'Ratllat';

  @override
  String get toolbarHighlight => 'Ressaltat';
  @override
  String get toolbarSuperscript => 'Exponent';
  @override
  String get toolbarUnderline => 'Subratllat';
  @override
  String get toolbarLink => 'Enllaç';
  @override
  String get toolbarCode => 'Bloc de codi';
  @override
  String get toolbarImage => 'Insereix imatge';
  @override
  String get toolbarTable => 'Taula';
  @override
  String get tableRow => 'Fila';
  @override
  String get tableColumn => 'Columna';
  @override
  String get tableAddRowAbove => 'Insereix una fila a sobre';
  @override
  String get tableAddRowBelow => 'Insereix una fila a sota';
  @override
  String get tableMoveRowUp => 'Puja la fila';
  @override
  String get tableMoveRowDown => 'Baixa la fila';
  @override
  String get tableDuplicateRow => 'Duplica la fila';
  @override
  String get tableDeleteRow => 'Suprimeix la fila';
  @override
  String get tableAddColumnLeft => "Insereix una columna a l'esquerra";
  @override
  String get tableAddColumnRight => 'Insereix una columna a la dreta';
  @override
  String get tableMoveColumnLeft => "Mou la columna a l'esquerra";
  @override
  String get tableMoveColumnRight => 'Mou la columna a la dreta';
  @override
  String get tableAlignLeft => "Alinea a l'esquerra";
  @override
  String get tableAlignCenter => 'Centra';
  @override
  String get tableAlignRight => 'Alinea a la dreta';
  @override
  String get tableDuplicateColumn => 'Duplica la columna';
  @override
  String get tableDeleteColumn => 'Suprimeix la columna';
  @override
  String get tableSortAscending => 'Ordena per columna (A → Z)';
  @override
  String get tableSortDescending => 'Ordena per columna (Z → A)';
  @override
  String get tableAddRow => 'Afegeix una fila';
  @override
  String get tableAddColumn => 'Afegeix una columna';
  @override
  String get cheatsheetTitle => 'Guia ràpida de Markdown';
  @override
  String get cheatsheetCopy => 'Copia';
  @override
  String get cheatsheetCopied => 'Copiat';
  @override
  String get copyCode => 'Copia el codi';
  @override
  String get codeCopied => 'Codi copiat';
  @override
  String get cheatsheetInsert => 'Insereix a la nota';
  @override
  String get cheatHeadings => 'Títols';
  @override
  String get cheatEmphasis => 'Negreta, cursiva, ratllat';
  @override
  String get cheatHtmlFormats => 'Subratllat, superíndex, subíndex';
  @override
  String get cheatLists => 'Llistes';
  @override
  String get cheatChecklists => 'Llistes de control';
  @override
  String get cheatQuotes => 'Cites';

  @override
  String get cheatCallouts => 'Destacats';
  @override
  String get cheatLinks => 'Enllaços';
  @override
  String get cheatWikilinks => 'Enllaços a notes';
  @override
  String get cheatEmbeds => 'Imatges i incrustacions';
  @override
  String get cheatTags => 'Etiquetes';
  @override
  String get cheatInlineCode => 'Codi en una frase';
  @override
  String get cheatCodeBlocks => 'Blocs de codi';
  @override
  String get cheatMath => 'Matemàtiques';
  @override
  String get cheatTables => 'Taules';
  @override
  String get cheatFootnotes => 'Notes al peu';
  @override
  String get cheatRule => 'Línia horitzontal';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatEpubMetadata => 'Metadades EPUB';
  @override
  String get cheatTemplates => 'Marcadors de les plantilles';
  @override
  String get menuAddLink => 'Afegeix un enllaç';
  @override
  String get menuAddExternalLink => 'Afegeix un enllaç extern';
  @override
  String get menuFormat => 'Format';
  @override
  String get menuParagraph => 'Paràgraf';
  @override
  String get menuInsert => 'Insereix';
  @override
  String get menuBody => 'Text normal';
  @override
  String get formatSubscript => 'Subíndex';
  @override
  String get formatInlineCode => 'Codi';
  @override
  String get insertFootnote => 'Nota al peu';
  @override
  String get insertRule => 'Línia horitzontal';
  @override
  String get insertCodeBlock => 'Bloc de codi';
  @override
  String get insertMathBlock => 'Bloc matemàtic';
  @override
  String get menuHeadingWord => 'Títol';
  @override
  String get toolbarHeading => 'Títol';
  @override
  String get toolbarList => 'Llista';
  @override
  String get toolbarOrderedList => 'Llista numerada';
  @override
  String get toolbarChecklist => 'Llista de control';
  @override
  String get toolbarQuote => 'Cita';
  @override
  String get toolbarIndent => 'Sagna';
  @override
  String get toolbarOutdent => 'Desfà sagnat';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Eines';
  @override
  String get editorToolsTitle => "Eines de l'editor";
  @override
  String get toolCountListTitle => 'Compta una llista';
  @override
  String get toolCountListSubtitle =>
      'Suma el que enumeren les files, com una llista de verificació';
  @override
  String get toolCountListNeedsList =>
      'Aquesta nota no té cap llista per comptar';
  @override
  String get tallySourceLabel => 'Llista';
  @override
  String get tallyCutLabel => 'Llegeix cada fila com a';
  @override
  String get tallyCutDash => 'Nom - valors';
  @override
  String get tallyCutColon => 'Nom: valors';
  @override
  String get tallyCutCommas => 'Valors separats per comes';
  @override
  String get tallyCutWhole => 'Tota la fila, com un sol valor';
  @override
  String get tallySortLabel => 'Ordre';
  @override
  String get tallySortCount => 'Primer els més freqüents';
  @override
  String get tallySortAlphabetical => 'Alfabètic';
  @override
  String get tallySortFirstSeen => 'Tal com són a la llista';
  @override
  String get tallyInsert => 'Insereix';
  @override
  String get tallyUpdate => 'Actualitza';
  @override
  String get tallyNothingToCount => 'Aquí no hi ha res per comptar';
  @override
  String get headingDialogTitle => 'Nivell del títol';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Barra d’eines de l’editor';
  @override
  String get toolbarSettingsHint =>
      'Arrossega per canviar l’ordre; l’ull mostra o amaga un '
      'botó.';
  @override
  String get toolbarShowButton => 'Mostra';
  @override
  String get toolbarHideButton => 'Amaga';
  @override
  String get toolbarResetOrder => 'Restaura el predeterminat';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Mostra la previsualització';
  @override
  String get showEditorTooltip => 'Mostra l’editor';
  // Raw-HTML table fallback.

  // Search (T-M3-05).
  @override
  String get searchHint => 'Cerca a les notes';
  @override
  String get searchModeWords => 'Paraules';
  @override
  String get searchModeContains => 'Conté';
  @override
  String get searchEmptyHint =>
      'Escriu per buscar a la biblioteca, o clau = valor per filtrar per '
      'frontmatter';
  @override
  String get searchTooShortHint => 'Escriu com a mínim 2 caràcters';
  @override
  String get searchNoMatches => 'Cap coincidència';
  @override
  String get searchLoadMore => 'Mostra més';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Reemplaça…';
  @override
  String get replaceInNoteAction => 'Reemplaça en aquesta nota…';
  @override
  String get replaceInThisNote => 'Reemplaça en aquesta nota';
  @override
  String get replaceWithLabel => 'Reemplaça per';
  @override
  String get replaceCaseSensitive => 'Sensibilitat a majúscules i minúscules';
  @override
  String get replaceWholeWordsHint =>
      'només es reemplaça les coincidències exactes de paraules senceres';
  @override
  String get replaceConfirm => 'Reemplaça';
  @override
  String get replaceCancel => 'Tanca';
  @override
  String get replaceUnavailable => 'La substitució no està disponible ara';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Cerca a la nota';
  @override
  String get editorFindHint => 'Cerca';
  @override
  String get editorReplaceHint => 'Reemplaça';
  @override
  String get editorFindCaseTooltip => 'Sensibilitat a majúscules i minúscules';
  @override
  String get editorFindPreviousTooltip => 'Coincidència anterior';
  @override
  String get editorFindNextTooltip => 'Coincidència següent';
  @override
  String get editorFindCloseTooltip => 'Tanca la cerca';
  @override
  String get editorFindReplaceModeTooltip => 'Mode de substitució';
  @override
  String get editorReplaceOneTooltip => 'Reemplaça aquesta coincidència';
  @override
  String get editorReplaceAllTooltip => 'Reemplaça totes les coincidències';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etiquetes';
  @override
  String get tagsTitle => 'Etiquetes';
  @override
  String get tagsEmpty =>
      'Encara no hi ha etiquetes — afegeix una #etiqueta o etiquetes al '
      'frontmatter';
  @override
  String get tagsBackTooltip => 'Torna a la cerca';
  @override
  String get tagsNotesEmpty => 'Cap nota amb aquesta etiqueta';
  @override
  String tagsNotesCapped(int limit) =>
      'Només es mostren les primeres $limit — busca l’etiqueta per '
      'limitar';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'No s’ha trobat l’enllaç';
  @override
  String get headingNotFoundTitle => 'No s’ha trobat el títol';
  @override
  String get ambiguousLinkTitle => 'Diverses notes coincideixen';
  @override
  String get openLinkFailed => 'No s’ha pogut obrir l’enllaç';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'La nota no existeix';
  @override
  String missingNoteDialogBody(String path) => 'Crear «$path»?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'La carpeta «$folder» no existeix';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Obertes';
  @override
  String get todoDone => 'Fetes';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Totes les dates';
  @override
  String get todoFilter => 'Filtra';
  @override
  String get todoNoTokens => 'Cap token en aquesta llista';
  @override
  String get todoCountOpen => 'obertes';
  @override
  String get todoCountDone => 'fetes';
  @override
  String get todoEmptyOpen => 'Encara no hi ha tasques obertes';
  @override
  String get todoEmptyDone => 'Encara res fet';
  @override
  String get todoEmptyFiltered => 'Cap tasca coincideix';
  @override
  String get todoTitle => 'Per fer';
  @override
  String get todoAddTooltip => 'Afegeix tasca';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'El format todo.txt';
  @override
  String get todoHelpTooltip => 'Informació del format';
  @override
  String get todoHelpIntro =>
      'Les teves tasques són un fitxer de text normal, una tasca per '
      'línia. Niman escriu la sintaxi per tu, però no s’oculta res: '
      'pots editar el fitxer a qualsevol editor i Niman el torna a '
      'llegir.';
  @override
  String get todoHelpFilesTitle => 'Els dos fitxers';
  @override
  String get todoHelpFilesBody =>
      'Les tasques obertes viuen a todo.txt a l’arrel de la '
      'biblioteca. Completa una i la línia es mou a done.txt, així '
      'todo.txt es manté curt. Si una línia completada torna a caure a '
      'todo.txt, Niman l’arxiva la propera vegada que llegeix els '
      'fitxers.';
  @override
  String get todoHelpLineTitle => 'L’anatomia d’una línia';
  @override
  String get todoHelpLineBody =>
      'Tot abans de la descripció és opcional i ha de venir en aquest '
      'ordre:';
  @override
  String get todoHelpDoneBody =>
      'Marca la tasca com a feta. Niman l’afegeix quan marques la '
      'casella de verificació.';
  @override
  String get todoHelpPriority => '(A) a (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritat. A és la més alta. Es mostra com una insignia a la '
      'llista.';
  @override
  String get todoHelpDatesBody =>
      'La data de completament, i llavors la data de creació. Amb només '
      'una data, és la data de creació, llevat que la línia comenci amb x.';
  @override
  String get todoHelpTokensTitle => 'Projectes, contextos i etiquetes';
  @override
  String get todoHelpTokensBody =>
      'Per tota la descripció, una paraula amb un d’aquests prefixos '
      'es converteix en una pastilla que es pot filtrar. Res és '
      'predefinit: un token existeix en el moment que l’escrius.';
  @override
  String get todoHelpProjectBody =>
      'El que la tasca pertany, per exemple +cuina o +treball.';
  @override
  String get todoHelpContextBody =>
      'On o com la fas, per exemple @casa o @reunions.';
  @override
  String get todoHelpHashtagBody =>
      'Una etiqueta lliure, per tot el que no cobreixen les altres dues.';
  @override
  String get todoHelpTagsTitle => 'Dates i recordatoris';
  @override
  String get todoHelpTagsBody =>
      'Aquestes són etiquetes clau:valor. Niman les escriu des del '
      'diàleg de tasques i les llegeix allà on apareguin a la línia.';
  @override
  String get todoHelpDueBody =>
      'La data límit. Controla la insignia de color i els filtres de '
      'data.';
  @override
  String get todoHelpRemBody =>
      'Quan s’ha d’enviar una notificació, en el teu horari '
      'local. Es dispara amb la pantalla apagada i l’app tancada.';
  @override
  String get todoHelpRemDesktop =>
      'A l’escriptori, Niman ha d’estar en execució quan '
      'arribi l’hora: el recordatori es mostra mentre l’app '
      'és oberta i no res es dispara quan està tancada.';
  @override
  String get todoHelpOtherBody =>
      'Conservat exactament com està escrit, perquè les etiquetes '
      'd’altres apps de todo.txt sobreviuen un viatge. Niman no '
      'actua sobre elles, rec: included: una tasca recurrent no es '
      'repeteix encara.';
  @override
  String get todoHelpEditTitle => 'Edició fora de Niman';
  @override
  String get todoHelpEditBody =>
      'Una tasca que no has tocat s’escriu de nou byte a byte, '
      'espais estranys inclosos. Edita una línia i Niman reescriu just '
      'aquesta línia en el seu format canònic i deixa la resta del '
      'fitxer intacta.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Afegeix tasca';
  @override
  String get todoEditTitle => 'Edita tasca';
  @override
  String get todoDescriptionHint => 'Descripció';
  @override
  String get todoCancel => 'Cancel·la';
  @override
  String get todoSave => 'Guarda';
  @override
  String get todoEditAction => 'Edita';
  @override
  String get todoDeleteAction => 'Esborra';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Endarrerida';
  @override
  String get todoDueToday => 'Avui';
  @override
  String get todoDueNext7 => 'Pròxims 7 dies';
  @override
  String get todoDueNoDate => 'Sense data';
  @override
  String get todoRowDue => 'Caduca';
  @override
  String get todoRowDueToday => 'Caduca avui';
  @override
  String get todoSortTooltip => 'Ordena';
  @override
  String get todoSortDue => 'Data límit';
  @override
  String get todoSortPriority => 'Prioritat';
  @override
  String get todoSortCreation => 'Data de creació';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriorityShort => 'Cap';
  @override
  String get todoMorePriorities => 'Més…';
  @override
  String get todoPriorityTitle => 'Prioritat';
  @override
  String get todoNoDueDate => 'Sense data límit';
  @override
  String get todoNoReminder => 'Sense recordatori';
  @override
  String get todoAddProject => '+ Projecte';
  @override
  String get todoAddContext => '@ Contexte';
  @override
  String get todoAddHashtag => '# Etiqueta';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Recordatoris de tasques';
  @override
  String get todoReminderChannelDescription =>
      'Notificacions programades per a tasques amb hora de recordatori.';
  @override
  String get todoReminderBody => 'Recordatori de tasques';
  @override
  String get todoReminderFallbackTitle => 'Recordatori de tasques';
  @override
  String get todoReminderBlocked =>
      'Les notificacions estan desactivades, per tant els recordatoris no '
      'es mostren.';
  @override
  String get todoReminderBattery =>
      'L’optimització de bateria està activada per a Niman. El '
      'sistema pot posar l’app en sospens i perdre recordatoris '
      'pendents.';
  @override
  String get todoReminderInexact =>
      'Aquest dispositiu no permet alarmes exactes, per tant un '
      'recordatori pot arribar uns minuts més tard amb la pantalla '
      'apagada.';
  @override
  String get reminderShowTokensTitle =>
      'Etiquetes a les notificacions de recordatori';
  @override
  String get reminderShowTokensSubtitle =>
      'Manté +projecte, @contexte i #etiqueta al text de la '
      'notificació. Desactivat només mostra la tasca que vas escriure.';
  @override
  String get todoReminderFixAction => 'Obre la configuració';
  @override
  String get todoReminderDismissAction => 'Descarta';
  @override
  String get todoReminderDue => 'Caducitat';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'D’acord';
  @override
  String get actionCancel => 'Cancel·la';
  @override
  String get actionDownload => 'Baixa';
  @override
  String get actionCreate => 'Crea';
  @override
  String get actionNew => 'Nova';
  @override
  String get actionSave => 'Guarda';
  @override
  String get actionClear => 'Buida';
  @override
  String get actionChoose => 'Tria';
  @override
  String get actionDelete => 'Esborra';
  @override
  String get actionRename => 'Canvia el nom';
  @override
  String get actionMove => 'Mou';
  @override
  String get saveAndClose => 'Guarda i tanca';
  @override
  String get closeUnsavedTitle => 'Canvis sense guardar';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” té canvis encara no guardats. '
          'Guardar-los abans de tancar?';
    }
    return '${names.length} notes tenen canvis encara no guardats. '
        'Guardar-los abans de tancar?';
  }

  @override
  String get closeSaveFailed => 'No s’ha pogut guardar; segueix oberta.';
  @override
  String get actionRestore => 'Restaura';
  @override
  String get actionEmpty => 'Buideja';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Amaga el panell lateral';
  @override
  String get showSidebarTooltip => 'Mostra el panell lateral';
  @override
  String get windowMinimizeTooltip => 'Minimitza';
  @override
  String get windowMaximizeTooltip => 'Maximitza';
  @override
  String get windowRestoreTooltip => 'Restaura';
  @override
  String get windowCloseTooltip => 'Tanca';
  @override
  String get tabFiles => 'Fitxers';
  @override
  String get tabSearch => 'Cerca';
  @override
  String get tabSettings => 'Configuració';
  @override
  String get quickNoteTitle => 'Nota ràpida';
  @override
  String get treeEmpty => 'Encara no hi ha notes';
  @override
  String get selectANote => 'Tria una nota';
  @override
  String get showListTooltip => 'Mostra la llista';
  @override
  String get editRawTooltip => 'Edita en brut';
  @override
  String get sortAscTooltip => 'Ordena A-Z';
  @override
  String get sortDescTooltip => 'Ordena Z-A';
  @override
  String get newNoteTitle => 'Nota nova';
  @override
  String get newItemTooltip => 'Nou';
  @override
  String get closeMenuTooltip => 'Tanca';
  @override
  String get shellActionFailed => 'No s’ha pogut acabar l’acció';
  @override
  String get newFolderTitle => 'Carpeta nova';
  @override
  String get newNoteSameFolder => 'Nova nota a la mateixa carpeta';
  @override
  String get newFromTemplateSameFolder =>
      'Nova des de plantilla a la mateixa carpeta';
  @override
  String trashOriginalPath(String path) => 'era a $path';
  @override
  String get trashOriginalRoot => 'era a l\u2019arrel de la biblioteca';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 element' : '$count elements';
  @override
  String get newNoteHere => 'Nota nova aquí';
  @override
  String get newFolderHere => 'Carpeta nova aquí';
  @override
  String get newListNoteTitle => 'Nota de llista nova';
  @override
  String get newListNoteDefault => 'La meva llista';
  @override
  String get setAsQuickNote => 'Estableix com a nota ràpida';
  @override
  String get currentQuickNote => 'Nota ràpida actual';
  @override
  String pinnedSectionCount(int count) => 'Fixades · $count';
  @override
  String get templateFolderTitle => 'Carpeta de plantilles';
  @override
  String get newFromTemplateTitle => 'Nova des d’una plantilla';
  @override
  String get newFromTemplateHere => 'Nova des d’una plantilla aquí';
  @override
  String get templateOpenFailed => 'No s’ha pogut obrir la plantilla';
  @override
  String get templateFormTitle => 'Ompla la plantilla';
  @override
  String get templateFormBacklink => 'Enllaçat des de';
  @override
  String get templateFormNoNote => 'Cap nota';
  @override
  String get templateFormPickNote => 'Tria la nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Espais reservats de la plantilla';
  @override
  String get templateHelpSubtitle =>
      'Data, títol i els altres valors per omplir';
  @override
  String get quickNoteSubtitle => 'La nota que obre la pestanya de nota ràpida';
  @override
  String get listFolderSubtitle => 'Les llistes noves de tasques';
  @override
  String get templateFolderSubtitle => 'L’origen de «Nova des de plantilla»';
  @override
  String get attachmentsFolderSubtitle =>
      'Imatges i àudio inserits en una nota';
  @override
  String get templateHelpIntro =>
      'Una plantilla és una nota normal amb forats. Crear una nota '
      'des d’ella copia el text i omple els forats.';
  @override
  String get templateHelpUnknown =>
      'Un espai reservat que Niman no coneix es conserva exactament com '
      'està escrit, per tant un error d’escritura apareix a la nota '
      'en lloc de rompre silenciosament una línia.';
  @override
  String get templateHelpValuesTitle => 'Valors';
  @override
  String get templateHelpTitleBody =>
      'El nom amb què s’ha de crear '
      'la nota.';
  @override
  String get templateHelpDateBody =>
      'Avui, i l’hora actual. Ambdós accepten un format: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data i hora juntes.';
  @override
  String get templateHelpUuidBody =>
      'Un identificador nou, un de diferent per aparició.';
  @override
  String get templateHelpCounterBody =>
      'Un número que compta per nom, conservat entre reinicis: la '
      'primera nota escriu 1, la següent 2. El mateix nom en una nota '
      'escriu el mateix número; combina-ho amb |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Posa el cursor aquí quan es crea la nota; el marcador no '
      's’escriu. El primer marcador guanya, sense filtres, només '
      'notes noves — i el teclat també s’obre amb l’enfocament '
      'automàtic desactivat.';
  @override
  String get templateHelpDatesTitle => 'Escriure una data';
  @override
  String get templateHelpDatesBody =>
      'Aquests representen parts de la data en un format. Tot el que no '
      'és això és literal, i el text entre cometes senceres també és '
      'literal. Els noms de mes i dia de setmana segueixen l’idioma '
      'de l’app.';
  @override
  String get templateHelpYear => 'l’any: 2026, 26';
  @override
  String get templateHelpMonth => 'el mes: 03, 3, març, mar';
  @override
  String get templateHelpDay => 'el dia: 09, 9, dilluns, dl';
  @override
  String get templateHelpTime => 'hores, minuts, segons';
  @override
  String get templateHelpWeek => 'la setmana ISO i el trimestre: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtres';
  @override
  String get templateHelpFiltersBody =>
      'Un valor pot anar seguit de filtres, aplicats de dreta a '
      'esquerra.';
  @override
  String get templateHelpCaseBody =>
      'Majúscules, minúscules, i la primera lletra de cada paraula — una '
      'paraula que tu hagis escrit amb majúscula inicial no es toca.';
  @override
  String get templateHelpSlugBody =>
      'La forma d’enllaç del text, per construir un enllaç wiki.';
  @override
  String get templateHelpPadBody =>
      'Retalla els extrems; omple amb zeros fins a un ample; usa una '
      'alternativa quan el valor és buit.';
  @override
  String get templateHelpShiftBody =>
      'Mou una data per dies, setmanes, mesos o anys — la conferència de '
      'la setmana vinent, el fitxer del mes passat.';
  @override
  String get templateHelpSnapBody =>
      'Fixa una data al principi o al final de la setmana, el mes o '
      'l’any.';
  @override
  String get templateHelpAskTitle => 'Preguntar-te alguna cosa';
  @override
  String get templateHelpAskBody =>
      'Un formulari es mostra abans de crear la nota, un camp per '
      'pregunta — i un per l’enllaç invers, quan la plantilla en '
      'vulgui. La mateixa etiqueta dues vegades és una pregunta, i la '
      'seva resposta omple totes les aparicions — la carpeta i el nom '
      'de fitxer inclosos.';
  @override
  String get templateHelpAskFieldBody =>
      'Un camp on escriure; el text després del segon punt i coma és com '
      'comença.';
  @override
  String get templateHelpChoiceBody =>
      'Una selecció d’una llista, separada per comes.';
  @override
  String get templateHelpWhereTitle => 'On cau la nota';
  @override
  String get templateHelpWhereBody =>
      'Aquestes no són text: són instruccions, i viuen en un bloc niman: '
      'al propi frontmatter de la plantilla. El bloc s’executa i es '
      'suprimeix després, per tant mai es mostra a la nota. El seu valor '
      'pot contenir espais reservats.';
  @override
  String get templateHelpFolderBody =>
      'La carpeta on es crea la nota, creada si no existeix. Sense '
      'això, la nota cau on eres.';
  @override
  String get templateHelpFilenameBody =>
      'Què s’anomena la nota. Una plantilla que això digui no se li '
      'demana un nom.';
  @override
  String get templateHelpAppendBody =>
      'Afegeix a la nota si ja hi és, en lloc de crear-ne una altra. '
      'Això és el que fa que un mes de reunions sigui un sol fitxer.';
  @override
  String get templateHelpOpenBody =>
      'Què passa quan la nota existeix: l’editor (predeterminat), '
      'la previsualització, o res — la nota s’arxiva i quedes on '
      'eres.';
  @override
  String get templateHelpAroundTitle => 'D’on ha vingut';
  @override
  String get templateHelpParentBody =>
      'Una nota que trius al formulari, que se t’ofereix a la '
      'pantalla; escriu [[{{parent}}]] per a un enllaç enrere.';
  @override
  String get templateHelpFolderValueBody => 'La carpeta on ha caigut la nota.';
  @override
  String get templateHelpClipboardBody =>
      'Què hi ha al porta-retalls, i la selecció de l’editor quan '
      'la nota ha començat des d’una.';
  @override
  String get templateHelpIncludeTitle => 'Reutilitzar una part';
  @override
  String get templateHelpIncludeBody =>
      'Enganxa una altra plantilla, de manera que deu plantilles puguin '
      'compartir una llista de verificació. Es busca primer a la carpeta '
      'de plantilles, i .md es pot ometre. Les seves pròpies preguntes '
      'entren al mateix formulari.';
  @override
  String get templateHelpExampleTitle => 'Tot junt';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ no hi ha plantilla “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” s’inclou a si mateixa';
  @override
  String includeTooDeep(String path) => '⚠ “$path” és massa enfilada';
  @override
  String get frontmatterTitle => 'Propietats';
  @override
  String get frontmatterPanelTitle => 'Tauler de propietats';
  @override
  String get frontmatterPanelSubtitle =>
      'Mostra les propietats de la nota a sobre. Tancat fins que '
      'l’obriu, i s’aparta en desplaçar-vos.';
  @override
  String get frontmatterShowRaw => 'YAML en brut';
  @override
  String get frontmatterShowFields => 'Camps';
  @override
  String get frontmatterAddField => 'Afegeix una propietat';
  @override
  String get frontmatterNewField => 'Propietat nova';
  @override
  String get frontmatterEditField => 'Edita la propietat';
  @override
  String get frontmatterKeyLabel => 'Clau';
  @override
  String get frontmatterValueLabel => 'Valor';
  @override
  String get frontmatterTypeLabel => 'Tipus';
  @override
  String get frontmatterListHint => 'Separa els elements amb comes';
  @override
  String get frontmatterRemoveField => 'Elimina la propietat';
  @override
  String get frontmatterNoFields => 'Cap propietat';
  @override
  String get frontmatterTypeText => 'text';
  @override
  String get frontmatterTypeNumber => 'nombre';
  @override
  String get frontmatterTypeDate => 'data';
  @override
  String get frontmatterTypeBoolean => 'booleà';
  @override
  String get frontmatterTypeList => 'llista';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter no llegit: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'El frontmatter de “$template” no es pot llegir, per tant la '
      'carpeta i el nom de fitxer no han fet res: $reason';
  @override
  String get templatePickerTitle => 'Tria una plantilla';
  @override
  String templatePickerEmpty(String folder) =>
      'Encara no hi ha plantilles. Posa una nota a $folder/ i serà una.';

  // Tree actions.
  @override
  String get actionPin => 'Fixa';
  @override
  String get actionUnpin => 'Desfixa';
  @override
  String get pinToWidget => 'Fixa al giny d’inici';
  @override
  String get pinnedForWidget =>
      'Fixat: ara col·loca el giny de Nota a la pantalla d’inici';
  @override
  String get pinWidgetUnavailable =>
      'Els ginys de la pantalla d’inici estan disponibles a Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Mostra al gestor de fitxers';
  @override
  String get openInDefaultApp => 'Obre amb l’aplicació per defecte';
  @override
  String get newNoteTabTooltip => 'Nota nova en una pestanya nova';
  @override
  String get openNotesTooltip => 'Notes obertes';
  @override
  String get closeTabTooltip => 'Tanca';
  @override
  String get openInNewTab => 'Obre en una pestanya nova';
  @override
  String get splitRight => 'Divideix a la dreta';
  @override
  String get splitDown => 'Divideix a sota';
  @override
  String get moveToOtherPane => 'Mou a l’altra subfinestra';
  @override
  String get openBeside => 'Obre al costat';
  @override
  String get closeAllNotes => 'Tanca-les totes';
  @override
  String get sidePanelTooltip => 'Mostra o amaga el plafó lateral';
  @override
  String get historyAllVersions => 'Totes les versions';
  @override
  String get commandPaletteTitle => 'Paleta d’ordres';
  @override
  String get goToNoteTitle => 'Ves a la nota';
  @override
  String get paletteGroupNote => 'Nota';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Visualització';
  @override
  String get paletteGroupLibrary => 'Biblioteca';
  @override
  String get paletteGroupGoTo => 'Ves a';
  @override
  String get paletteGroupJournal => 'Diari';
  @override
  String get journalToday => 'Entrada d’avui';
  @override
  String get journalPrevious => 'Entrada anterior';
  @override
  String get journalNext => 'Entrada següent';
  @override
  String get commandNeedJournalEntry => 'Cal una entrada del diari oberta';
  @override
  String journalCreateAsk(String day) =>
      'Encara no hi ha cap entrada per a $day. La vols crear?';
  @override
  String journalTemplateMissing(String path) =>
      'No s’ha pogut llegir la plantilla del diari $path: l’entrada s’ha '
      'creat sense.';
  @override
  String get journalIntro =>
      'Una nota al dia, creada a partir d’una plantilla la primera vegada que '
      'obres aquell dia. Aquests paràmetres viatgen amb la biblioteca.';
  @override
  String get journalFolderTitle => 'Carpeta del diari';
  @override
  String get journalFolderSubtitle => 'On van les entrades';
  @override
  String get journalEntryNameTitle => 'Nom de l’entrada';
  @override
  String get journalEntryNameSubtitle =>
      "YYYY, MM o M, DD o D per a la data; / crea una carpeta; el text 'entre "
      "cometes' es queda tal qual";
  @override
  String journalEntryNamePreview(String path) => 'Entrada d’avui: $path';
  @override
  String get journalEntryNameInvalid =>
      'Cal YYYY, un mes (MM o M) i un dia (DD o D), i res que un nom de '
      'fitxer no pugui contenir';
  @override
  String get journalTemplateTitle => 'Plantilla';
  @override
  String get journalTemplateSubtitle => 'Amb què comença una entrada nova';
  @override
  String get journalTemplateNone => 'Cap: un títol amb la data';
  @override
  String get journalDayStartTitle => 'Un dia nou comença a les';
  @override
  String get journalDayStartSubtitle =>
      'Et fas tard? A les 04:00 la nit queda en el dia anterior';
  @override
  String get journalRecent => 'Recents';
  @override
  String get journalNoEntry => 'Cap entrada per a aquest dia';
  @override
  String get journalOpenEntry => 'Obre';
  @override
  String get journalShowCalendar => 'Mostra el calendari';
  @override
  String get journalFabToday => 'Entrada d’avui del diari';
  @override
  String journalDueOn(String day) => 'Venç el $day';
  @override
  String get commandsTitle => 'Ordres';
  @override
  String get commandsIntro =>
      "La paleta d'ordres només ofereix les ordres que es poden executar on "
      'ets. Aquí hi són totes, i quan apareix cadascuna.';
  @override
  String get commandsKeysNote =>
      'Aquí no es canvia res. Les tecles són les definides a Dreceres de '
      'teclat i segueixen qualsevol canvi fet allà.';
  @override
  String get commandsOpenShortcuts => 'Canvia les tecles a Dreceres de teclat';
  @override
  String get commandsChangeKeyTooltip => 'Canvia a Dreceres de teclat';
  @override
  String get commandsSubtitle =>
      'El que pot executar la paleta d’ordres, i quan';
  @override
  String get keyboardShortcutsSubtitle => 'Canvia les tecles de cada ordre';
  @override
  String get commandNeedNone => 'Sempre disponible';
  @override
  String get commandNeedOpenNote => 'Cal una nota oberta';
  @override
  String get commandNeedTextNote => 'Cal una nota de text oberta';
  @override
  String get commandNeedWideWindow => 'Només amb finestra ampla';
  @override
  String get commandNeedDockRoom =>
      'Cal una finestra prou ampla per al plafó lateral';
  @override
  String get commandNeedDesktop => "Només a l'escriptori";
  @override
  String get commandNeedNotInZen => 'Fora del mode Zen';
  @override
  String get commandNeedZenRoom =>
      'Escriptori, amb una nota oberta en una pestanya';
  @override
  String get commandNeedPreview =>
      'Amb la previsualització activada, en una nota de text';
  @override
  String get commandNeedTwoEditors => 'Amb tots dos editors activats';
  @override
  String get paletteHint => 'Cerca ordres i notes';
  @override
  String get paletteNoResults => 'Cap coincidència';
  @override
  String get paletteCommands => 'Ordres';
  @override
  String get paletteNotes => 'Notes';
  @override
  String get paletteFooter => '↑↓ per moure’t · ↵ per usar · esc per tancar';
  @override
  String get paletteFooterTouch =>
      'Toca per fer-ho servir · la xinxeta el manté a dalt';
  @override
  String get palettePinned => 'Fixats';
  @override
  String get palettePin => 'Fixa';
  @override
  String get paletteUnpin => 'Treu';
  @override
  String get palettePinFooter => 'alt+P per fixar';
  @override
  String get spellCheckScanning => 'S’està revisant la nota…';
  @override
  String get spellCheckAgain => 'Torna a revisar';
  @override
  String spellCheckCapped(int count) =>
      'Es mostren els primers $count: corregiu-ne alguns i torneu a revisar '
      'per veure la resta';
  @override
  String get dropHint =>
      'Deixeu anar fitxers Markdown per obrir-los, o una carpeta per '
      'importar-la';
  @override
  String get dropNothing =>
      'L’escriptori no ha lliurat cap fitxer en aquest arrossegament.';
  @override
  String get importFolderAction => 'Importa';
  @override
  String get notionImportTitle => 'Importa exportació de Notion';
  @override
  String get notionImportFailed =>
      'No s’ha pogut importar l’exportació de Notion';
  @override
  String dropRejected(String names) =>
      'Aquí només s’obren fitxers Markdown i carpetes: $names';
  @override
  String importFolderTitle(String name) => 'Voleu importar «$name»?';
  @override
  String importFolderBody(int count) =>
      'Els seus fitxers Markdown ($count) es copien en una carpeta nova de '
      'la biblioteca. La carpeta que heu deixat anar queda igual.';
  @override
  String importFolderDone(String folder) => 'Importat a $folder';
  @override
  String importFolderEmpty(String name) => 'No hi ha fitxers Markdown a $name';
  @override
  String get openFileTitle => 'Obre un fitxer';
  @override
  String get outsideFileNote =>
      'Fora de cap biblioteca: es desa on és, sense índex, sense historial, '
      'els enllaços no se segueixen';
  @override
  String get typewriterOn => 'Activa el mode màquina d’escriure';
  @override
  String get typewriterOff => 'Desactiva el mode màquina d’escriure';
  @override
  String get typewriterTitle => 'Mode màquina d’escriure';
  @override
  String get formatNoteTitle => 'Endreça el Markdown';
  @override
  String get formatNoteDone => 'La nota s’ha endreçat.';
  @override
  String get exportTitle => 'Exporta';
  @override
  String get exportFormatMarkdown => 'Markdown';
  @override
  String get exportFormatHtml => 'HTML';
  @override
  String exportDone(String place) => 'Exportat a $place';
  @override
  String exportFailed(Object error) => 'L’exportació ha fallat: $error';
  @override
  String get exportFolderTitle => 'Exporta la carpeta…';
  @override
  String get exportLibraryTitle => 'Exporta la biblioteca…';
  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatEpub => 'EPUB';

  @override
  String get exportEpubNoMetadataTitle => 'Llibre sense metadades';
  @override
  String get exportEpubNoIndex =>
      'Aquesta carpeta no té cap index.md a l’arrel. El llibre portarà '
      'el nom de la carpeta i cap autor, portada ni sèrie.';
  @override
  String get exportEpubNoFrontmatter =>
      'index.md no té frontmatter. El llibre portarà el nom de la '
      'carpeta i cap autor, portada ni sèrie.';
  @override
  String get exportAnyway => 'Exporta igualment';
  @override
  String get exportPdfPicture =>
      'El PDF és una imatge de les pàgines; instal·la un navegador per tenir '
      'text seleccionable.';

  @override
  String exportPdfEngineFailed(Object reason) =>
      'El motor de PDF ha fallat ($reason): la nota s’ha dibuixat '
      'com una imatge.';

  @override
  String get exportPdfNoEngineTitle => 'PDF com a imatge';

  @override
  String get exportPdfNoEngine =>
      "No s'ha trobat cap navegador en aquest ordinador. La nota es "
      'dibuixa com una imatge de les pàgines: el text no es pot '
      'seleccionar ni cercar, i una nota llarga triga més.';
  @override
  String get formatNoteAlreadyTidy => 'La nota ja estava endreçada.';
  @override
  String get lintRulesTitle => 'Regles de Markdown';
  @override
  String get lintRulesSubtitle =>
      'Què arregla l’ordenació: línies buides a les llistes, caselles de '
      'tasca, espais després del marcador i blocs de codi.';
  @override
  String get lintRulesReset => 'Restaura els valors per defecte';
  @override
  String lintRulesValue(int on, int all) =>
      on >= all ? 'Totes $all' : '$on de $all';
  @override
  String get lintRuleTightLists => 'Llistes compactes';
  @override
  String get lintRuleTaskMarker => 'Caselles de tasca';
  @override
  String get lintRuleListSpacing => 'Espaiat de llistes';
  @override
  String get lintRuleClosingFence => 'Tancament del bloc de codi';
  @override
  String get lintRuleFenceLanguage => 'Llengua del bloc de codi';
  @override
  String get lintRuleJoinWrappedItems => 'Uneix els elements de llista partits';
  @override
  String get lintRuleJoinParagraphLines => 'Uneix els paràgrafs partits';
  @override
  String get tidyOnCloseTitle => 'Endreça el Markdown en tancar';
  @override
  String get tidyOnCloseSubtitle =>
      'Quan tanqueu una nota que heu editat, el seu Markdown s’endreça com '
      'amb l’ordre «Endreça el Markdown». Les notes de més de 4 MB es '
      'queden com estan.';
  @override
  String get typewriterSubtitle =>
      'Mantén la línia que escriviu al mig de l’editor';
  @override
  String get zenMode => 'Mode zen';
  @override
  String get zoomIn => 'Amplia';
  @override
  String get zoomOut => 'Redueix';
  @override
  String get zoomReset => 'Restableix el zoom';
  @override
  String get zenModeEnter => 'Entra al mode zen';
  @override
  String get zenModeLeave => 'Surt del mode zen';
  @override
  String get keySpace => 'Espai';
  @override
  String get keyEnter => 'Retorn';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Retrocés';
  @override
  String get keyDelete => 'Supr';
  @override
  String get keyArrowUp => 'Amunt';
  @override
  String get keyArrowDown => 'Avall';
  @override
  String get keyArrowLeft => 'Esquerra';
  @override
  String get keyArrowRight => 'Dreta';
  @override
  String get keyHome => 'Inici';
  @override
  String get keyEnd => 'Fi';
  @override
  String get keyPageUp => 'Re Pàg';
  @override
  String get keyPageDown => 'Av Pàg';
  @override
  String get keyInsert => 'Insereix';
  @override
  String get shortcutNone => 'Cap drecera';
  @override
  String get shortcutRestoreDefaults => 'Restaura les predeterminades';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Tornar totes les dreceres tal com les porta Niman?';
  @override
  String get shortcutRevert => 'Torna a la predeterminada';
  @override
  String get shortcutClear => 'Treu la drecera';
  @override
  String get shortcutCapturePrompt =>
      'Premeu les tecles. Esc i Tab també es capturen: sortiu amb Cancel·la.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Afegiu Ctrl, Alt o Meta: una tecla sola és per escriure.';
  @override
  String get shortcutMove => 'Mou-la';
  @override
  String get shortcutUseAnyway => 'Fes-la servir igualment';
  @override
  String get shortcutUndo => 'Desfés';
  @override
  String get shortcutRedo => 'Refés';
  @override
  String shortcutCaptureTitle(String command) => 'Tecles per a $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys ja és de $other. La voleu moure aquí? $other es quedarà sense '
      'drecera.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys també és $what als camps de text i a l’editor. Allà l’agafarà '
      'la vostra ordre.';
  @override
  String get openFileMissing => 'El fitxer d’aquesta nota no és al disc';
  @override
  String get openFileFailed =>
      'No s’ha pogut obrir aquesta nota fora del Niman';
  @override
  String get attachmentUnreadable => 'No s’ha pogut mostrar aquest fitxer.';
  @override
  String get attachmentMissing => 'Aquest fitxer no és al disc.';
  @override
  String get attachmentOpenFailed =>
      'No s’ha pogut obrir aquest fitxer fora del Niman.';
  @override
  String get copyPlaceLink => "Copia l'enllaç a aquest punt";
  @override
  String get placeLinkCopied => 'Enllaç copiat';
  @override
  String pdfPageLabel(String name, int page) => '$name, p. $page';
  @override
  String get annotationsFolderTitle => "Carpeta d'anotacions";
  @override
  String get annotationsFolderSubtitle => 'Notes que anoten un PDF o un llibre';
  @override
  String get annotationNoteSuffix => 'Anotació';
  @override
  String get annotateAction => 'Anota';
  @override
  String get annotationCommentHint => 'El teu comentari';
  @override
  String get annotationSaved => 'Anotació desada';
  @override
  String get annotationOpenNote => 'Obre la nota';
  @override
  String get annotationFailed => "No s'ha pogut desar l'anotació";

  @override
  String get movedToTrash => 'Moguda a la paperera';
  @override
  String get deletedMessage => 'Esborrat';
  @override
  String deleteToTrashConfirm(String name) => '$name es mourà a .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name s’esborrarà permanentment';
  @override
  String get chooseDestination => 'Tria el destí';
  @override
  String get libraryRoot => 'L’arrel de la biblioteca';
  @override
  String moveTitle(String name) => 'Mou $name';
  @override
  String headingLevelLabel(int level) => 'Títol $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Encara no hi ha nota ràpida. Tria una nota existent o crea-ne '
      'una — la nota ràpida s’obrirà aquí.';
  @override
  String get quickNoteChooseAction => 'Tria una nota…';
  @override
  String get quickNoteCreateAction => 'Crea una nota nova…';
  @override
  String get quickNoteNewTitle => 'Nota ràpida nova';
  @override
  String get quickNotePickerTitle => 'Tria la nota ràpida';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Carpeta nova';
  @override
  String get folderPickerEmpty => 'Encara no hi ha carpetes';
  @override
  String get listFolderTitle => 'Carpeta de llista';
  @override
  String get attachmentsFolderTitle => "Carpeta d'adjunts";

  // Trash (M1).
  @override
  String get trashEmpty => 'La paperera és buida';
  @override
  String get trashEmptyAction => 'Buideja la paperera';
  @override
  String get trashEmptyConfirm =>
      'Això esborra permanentment tot el que hi ha a la paperera, '
      'inclosos els elements que Niman no hi ha posat.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name s’esborrarà permanentment (sense restauració)';
  @override
  String get trashDeletePermanently => 'Esborra permanentment';
  @override
  String get trashActionFailed => 'No s’ha pogut restaurar ni eliminar la nota';
  @override
  String get trashEmptyFailed => 'No s’ha pogut buidar la paperera';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Obre una carpeta de notes Markdown com a biblioteca';
  @override
  String get openLibraryExisting => 'Obre una existent';
  @override
  String get openLibraryCreate => 'Crea una nova';
  @override
  String get openLibraryCreateTitle => 'Crea una biblioteca nova';
  @override
  String get openLibraryFolderName => 'Nom de la carpeta';
  @override
  String get openLibraryChooseFolder => 'Tria la carpeta de la biblioteca';
  @override
  String get openLibraryChooseParent =>
      'Tria la carpeta on es crearà la biblioteca';
  @override
  String get openLibraryUnsupported =>
      'Aquesta carpeta no és compatible. Tria una carpeta a '
      'l’emmagatzematge del dispositiu.';
  @override
  String indexingCount(int done, int total) => '$done de $total notes';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Les teves biblioteques';
  @override
  String get libraryUnreachable => 'Inaccessible';
  @override
  String get libraryOpenedToday => 'Oberta avui';
  @override
  String get libraryOpenedYesterday => 'Oberta ahir';
  @override
  String libraryOpenedDaysAgo(int days) => 'Oberta fa $days dies';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Oberta ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Oberta ara';
  @override
  String get switchLibraryTitle => 'Canvia la biblioteca';
  @override
  String get libraryForget => 'Oblida';
  @override
  String libraryForgetTitle(String name) => 'Oblidar “$name”?';
  @override
  String get libraryForgetExplained =>
      'Es mourà d’aquesta llista. La carpeta, les notes i la '
      'configuració de la biblioteca dins d’ella no es toquen, i '
      'tornar a obrir-la la torna a posar.';

  @override
  String get libraryForgetOpenExplained =>
      'Aquesta biblioteca està oberta ara: primer es tanca i després surt '
      'de la llista. La carpeta, les notes i la configuració de la '
      'biblioteca que hi ha a dins no es toquen, i tornar-la a obrir la '
      'recupera.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dóna accés als fitxers';
  @override
  String get storageAccessNeeded =>
      'Niman no pot llegir les teves notes sense “Accés a tots els '
      'fitxers”. Dóna-li-ho per obrir una biblioteca.';
  @override
  String get storageAccessExplained =>
      'Niman llegeix les teves notes com fitxers normals, per tant '
      'Android ha de donar-li accés a tots els fitxers. No s’envia '
      'res a cap lloc, i només es llegeix la carpeta de biblioteca que '
      'triïs.';
  @override
  String folderAccessDenied(Object error) =>
      'El sistema no ha donat accés a la carpeta: $error';
  @override
  String folderPickFailed(Object error) =>
      'No s’ha pogut triar una carpeta: $error';

  // Settings screen rows and messages.
  @override
  String get libraryPathTitle => 'Camí de la biblioteca';
  @override
  String get reindexTitle => 'Torna a indexar ara';
  @override
  String get reindexDone => 'Reindexació completada';
  @override
  String get reindexFailed => 'No s’ha pogut tornar a llegir la biblioteca';
  @override
  String get closeLibraryTitle => 'Tanca la biblioteca';
  @override
  String get exportLogTitle => 'Exporta el registre de depuració';
  @override
  String get exportLogSubtitle =>
      'Guarda els esdeveniments registrats a un fitxer que triïs';
  @override
  String get exportLogEmpty => 'El búfer del registre de depuració està buit';
  @override
  String get quickNoteUnset => 'Encara no està establert';
  @override
  String exportLogDone(Object target) =>
      'Registre de depuració exportat a $target';
  @override
  String exportLogFailed(Object error) => 'L’exportació ha fallat: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'No s’ha trobat cap coincidència exacta de paraula sencera per '
      'a “$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'S’han reemplaçat $occurrences ocurrencies de “$term” a '
      '$notes notes';
  @override
  String replaceSkipped(int skipped) => ' ($skipped notes obertes s’han omès)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'No s’ha trobat cap coincidència exacta de paraula sencera per '
      'a “$term” ${only == null ? 's’ha trobat' : 'trobat a $only'}';
  @override
  String get replaceScopeWholeLibrary => 'tota la biblioteca';
  @override
  String replaceScopeNote(String note) => 'a $note';
  @override
  String replaceScopeNotes(int count) =>
      count == 1 ? 'a 1 nota' : 'a $count notes';
  @override
  String replaceWriteFailed(int count) => count == 1
      ? ' (1 nota no s’ha pogut escriure)'
      : ' ($count notes no s’han pogut escriure)';

  // About (issue #80).
  @override
  String get versionTitle => 'Versió';
  @override
  String get changelogTitle => 'Registre de canvis';
  @override
  String get changelogEmpty => 'No hi ha entrades de registre disponibles';
  @override
  String changelogWhatsNew(String version) => 'Novetats a la versió $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historial';
  @override
  String get noteMenuTooltip => 'Accions de la nota';
  @override
  String get historyCurrentVersion => 'Versió actual';
  @override
  String get historyCurrentSubtitle => 'La nota tal com és ara';
  @override
  String get historyToday => 'Avui';
  @override
  String get historyYesterday => 'Ahir';
  @override
  String get historyReasonSession => 'abans d’editar';
  @override
  String get historyReasonInterval => 'durant l’edició';
  @override
  String get historyReasonRestore => 'abans de restaurar';
  @override
  String get historyReasonSync => 'abans de sincronitzar';
  @override
  String get historyReasonReplace => 'abans de reemplaçar';
  @override
  String get historyReasonUnknown => 'recuperada';
  @override
  String get historySyncBase => 'base de sincronització';
  @override
  String get historyEmpty =>
      'Encara no hi ha versions. Niman en guarda una quan comences a editar '
      'la nota i després, com a màxim, una cada pocs minuts mentre escrius.';
  @override
  String historyKept(int kept, int limit) => '$kept de $limit versions';
  @override
  String get historyBaseKept =>
      'La base de sincronització es conserva més enllà del límit.';
  @override
  String get historyOff =>
      'L’historial està desactivat per a aquesta biblioteca '
      '(Configuració, Paperera i cronologia).';
  @override
  String get historyLoadFailed => 'No s’ha pogut llegir l’historial';
  @override
  String get historyCompareSubtitle => 'Comparada amb la versió actual';
  @override
  String get historyTabChanges => 'Canvis';
  @override
  String get historyTabVersion => 'Versió';
  @override
  String get historyNoChanges => 'El mateix text que la versió actual.';
  @override
  String get historyRestoreAction => 'Restaura aquesta versió';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Restaurar la versió ($when)?';
  @override
  String get historyRestoreConfirmBody =>
      'Abans es guarda el text actual a l’historial, així que sempre pots '
      'tornar enrere.';
  @override
  String get historyRestoreConfirm => 'Restaura';
  @override
  String historyRestored(String when) => 'S’ha restaurat la versió ($when)';
  @override
  String get historyRestoreFailed => 'No s’ha pogut restaurar la versió';
  @override
  String get actionUndo => 'Desfés';
  @override
  String diffLineRange(int start, int end) => 'Línies $start–$end';
  @override
  String diffLineSingle(int line) => 'Línia $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 línia sense canvis' : '$count línies sense canvis';
  @override
  String get historyTakeHunk => 'Restaura-ho aquí';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Restaura 1 canvi' : 'Restaura $count canvis';
  @override
  String get historyRestoreSelectedConfirmBody =>
      "Els canvis triats tornen al text d'aquesta versió. La nota tal com és "
      'ara es conserva abans com a versió, així que ho pots desfer.';
  @override
  String get historyNoteChangedReloaded =>
      "La nota ha canviat mentre eres aquí: la comparació s'ha actualitzat.";
  @override
  String get historyVersionsTitle => 'Versions que es conserven';
  @override
  String get historyVersionsSubtitle => 'Per nota, a .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Cap' : '$count';
  @override
  String get historyIntervalTitle => 'Nova versió com a màxim cada';
  @override
  String get historyIntervalSubtitle =>
      'Mentre escrius; començar a editar una nota sempre en guarda una';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcripció';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Cap';
  @override
  String get transcriptionLanguageTitle => 'Idioma';
  @override
  String get transcriptionLanguageSubtitle =>
      "L'idioma que es parla als teus enregistraments. Indicar-lo és més "
      'precís que detectar-lo.';
  @override
  String transcriptionLanguageApp(String language) => "Com l'app ($language)";
  @override
  String get transcriptionLanguageDetect => 'Detecta automàticament';
  @override
  String get transcriptionModelsTitle => 'Models de transcripció';
  @override
  String transcriptionModelsUsed(String size) => '$size en ús';
  @override
  String get transcriptionModelsInstalled => 'Baixats';
  @override
  String get transcriptionModelsDownloading => "S'estan baixant";
  @override
  String get transcriptionModelsAvailable => 'Disponibles';
  @override
  String get transcriptionModelsFooter =>
      "Els models es queden a l'emmagatzematge de l'app en aquest dispositiu. "
      'No es copien a la biblioteca ni es sincronitzen.';
  @override
  String get transcriptionModelDefault => 'Per defecte';
  @override
  String get transcriptionModelSlow => 'Lent';
  @override
  String get transcriptionModelHintTiny => 'El més ràpid, el menys precís';
  @override
  String get transcriptionModelHintBase =>
      'Bon equilibri entre velocitat i precisió';
  @override
  String get transcriptionModelHintSmall => 'Més precís, unes 3× més lent';
  @override
  String get transcriptionModelHintMedium => 'Molt precís, lent en un telèfon';
  @override
  String get transcriptionModelHintLarge =>
      'El més precís, necessita molta memòria';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Vols suprimir el model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Allibera $size. Pots tornar a baixar el model més endavant.';
  @override
  String get downloadFailed =>
      "No s'ha pogut baixar. Comprova la connexió i torna-ho a provar.";
  @override
  String get actionRetry => 'Torna-ho a provar';
  @override
  String get decimalSeparator => ',';
  @override
  String get downloadRetrying =>
      "S'ha perdut la connexió, s'està tornant a provar…";
  @override
  String downloadPaused(String progress) => 'En pausa a $progress';
  @override
  String get actionResume => 'Reprèn';
  @override
  String get audioTranscribe => 'Transcriu';
  @override
  String get audioTranscribeUnsupported =>
      'Només enregistraments WAV en aquest dispositiu';
  @override
  String get transcriptionQueued => 'A la cua';
  @override
  String get transcriptionPreparing => "S'està preparant l'àudio…";
  @override
  String transcriptionRunning(int percent) => "S'està transcrivint… $percent %";
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      "S'està baixant $model · $percent %";
  @override
  String get transcriptionSaved => 'Transcripció afegida a la descripció';
  @override
  String get transcriptionNoSpeech =>
      "No s'ha reconegut cap veu en aquest enregistrament";
  @override
  String get transcriptionFailed => "No s'ha pogut transcriure";
  @override
  String get transcriptionPickModelTitle => 'Tria un model';
  @override
  String get transcriptionPickModelBody =>
      "La transcripció es fa en aquest dispositiu i l'enregistrament no "
      "s'envia mai. El model es baixa una sola vegada.";
  @override
  String get transcriptionPickModelAction => 'Baixa i transcriu';
  @override
  String get transcriptionModelRecommended => 'Recomanat';
  @override
  String get transcriptionExistingTitle =>
      'Aquest enregistrament ja té una descripció';
  @override
  String get transcriptionExistingBody =>
      'Vols substituir-la per la transcripció o afegir la transcripció a '
      'sota?';
  @override
  String get transcriptionAppend => 'Afegeix a sota';
  @override
  String get transcriptionReplace => 'Substitueix';
  @override
  String get settingsSectionSync => 'Sincronització';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Sense configurar per a aquesta biblioteca';
  @override
  String get syncNeverSynced => 'Mai sincronitzada';
  @override
  String syncLastSynced(String when) => 'Sincronitzada $when';
  @override
  String get syncRunning => 'Sincronitzant…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteca $library';
  @override
  String get syncUrlLabel => 'Adreça de la carpeta';
  @override
  String get syncUrlRequired => 'Introduïu l’adreça del servidor';
  @override
  String get syncUrlHint =>
      'La carpeta ha d’existir. Copia l’adreça tal com la mostra '
      'el servidor.';
  @override
  String get syncHttpWarning =>
      'Connexió sense xifrar: és correcte en una VPN o a la teva '
      'xarxa local.';
  @override
  String get syncUserLabel => 'Usuari';
  @override
  String get syncUserHint =>
      'Deixa-ho buit si el servidor no demana credencials.';
  @override
  String get syncPasswordLabel => 'Contrasenya';
  @override
  String get syncPasswordHint =>
      'Es guarda al clauer d’aquest dispositiu, mai als fitxers '
      'de la biblioteca.';
  @override
  String get syncPasswordKeepHint =>
      'Deixa-ho buit per mantenir la contrasenya guardada.';
  @override
  String get syncShowPassword => 'Mostra la contrasenya';
  @override
  String get syncHidePassword => 'Amaga la contrasenya';
  @override
  String get syncTestAction => 'Prova la connexió';
  @override
  String get syncTesting => 'Provant…';
  @override
  String get syncRetargetWarning =>
      'Amb una altra adreça o un altre usuari, la propera '
      'sincronització torna a començar com la primera.';
  @override
  String get syncTestOk => 'La connexió funciona';
  @override
  String get syncModeFull => 'Mode complet';
  @override
  String get syncModeCompatible => 'Mode compatible';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lectura, escriptura i esborrament';
  @override
  String get syncCapEtags => 'Empremtes dels fitxers (ETags)';
  @override
  String get syncCapNoEtags => 'Sense empremtes dels fitxers (ETags)';
  @override
  String get syncCapNoEtagsDetail =>
      'Compara la mida i la data; si hi ha dubtes, torna a baixar';
  @override
  String get syncCapGuarded => 'Escriptures protegides';
  @override
  String get syncCapUnguarded => 'Escriptures no protegides';
  @override
  String get syncCapUnguardedDetail =>
      'Comprova el fitxer al servidor just abans d’escriure';
  @override
  String get syncCapMove => 'Canvia el nom sense tornar a pujar';
  @override
  String get syncCapNoMove => 'Sense canvis de nom al servidor';
  @override
  String get syncCapNoMoveDetail =>
      'Un canvi de nom esdevé un esborrament i una pujada nova';
  @override
  String get syncCompatibleNote =>
      'En mode compatible la sincronització funciona igual, amb '
      'unes quantes peticions més.';
  @override
  String get syncTestInvalidUrl => 'No és una adreça vàlida';
  @override
  String get syncTestInvalidUrlHint =>
      'Escriu una adreça http:// o https://, sense usuari ni '
      'contrasenya a dins.';
  @override
  String get syncTestOffline => 'Servidor inaccessible';
  @override
  String get syncTestOfflineHint =>
      'La VPN està activa? Una adreça 10.x o 192.168.x només '
      'funciona des de la mateixa xarxa.';
  @override
  String get syncTestAuth => 'Usuari o contrasenya rebutjats';
  @override
  String get syncTestAuthHint => 'Revisa’ls i torna a provar.';
  @override
  String get syncTestNotFound => 'La carpeta no existeix';
  @override
  String get syncTestNotFoundHint =>
      'Crea-la al servidor o corregeix l’adreça.';
  @override
  String get syncTestUnsupported => 'No és una carpeta WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'El servidor respon, però no com a WebDAV.';
  @override
  String get syncTestFailed => 'La prova no ha funcionat';
  @override
  String get syncTestCertificate => 'El certificat no és de confiança';
  @override
  String get syncTestCertificateHint =>
      'No es pot verificar el certificat. Confia-hi només si la seva empremta '
      'coincideix amb la que mostra el servidor.';
  @override
  String get syncCertTrustTitle => 'Confiar en aquest certificat?';
  @override
  String syncCertTrustBody(String host, String fingerprint) =>
      'No es pot verificar el certificat de $host.\n\nEmpremta '
      'SHA-256:\n$fingerprint\n\nConfia-hi només si és el certificat que '
      'esperes. Niman accepta només aquest certificat per a aquesta '
      'destinació i cap altre.';
  @override
  String get syncCertTrustAction => 'Confia en aquest certificat';
  @override
  String get syncCertTrustedTitle => 'Certificat de confiança';
  @override
  String syncCertTrustedSubtitle(String fingerprint) => 'SHA-256 $fingerprint';
  @override
  String get syncCertForgetTitle => 'Oblidar aquest certificat?';
  @override
  String get syncCertForgetBody =>
      'Aquesta destinació es torna a provar contra l’emmagatzematge de '
      'certificats del dispositiu i caldrà tornar a confirmar un certificat '
      'autofirmat. Res més no canvia.';
  @override
  String get syncCertForgetAction => 'Oblida';
  @override
  String get syncNowAction => 'Sincronitza ara';
  @override
  String get syncSectionServer => 'Servidor';
  @override
  String get syncServerRow => 'Adreça, usuari i contrasenya';
  @override
  String get syncRetestTitle => 'Torna a provar el servidor';
  @override
  String syncProbedAgo(String when) => 'Última prova: $when';
  @override
  String get syncDisconnectTitle => 'Desconnecta aquesta biblioteca';
  @override
  String get syncDisconnectSubtitle =>
      'Els fitxers es queden aquí i al servidor';
  @override
  String get syncDisconnectConfirmTitle => 'Desconnectar la sincronització?';
  @override
  String get syncDisconnectConfirmBody =>
      'Aquesta biblioteca deixa de sincronitzar-se en aquest '
      'dispositiu. No s’esborra cap fitxer, ni aquí ni al '
      'servidor. Si la tornes a connectar, la primera '
      'sincronització torna a començar.';
  @override
  String get syncDisconnectConfirm => 'Desconnecta';
  @override
  String get syncFirstTitle => 'Primera sincronització';
  @override
  String get syncFirstIntro =>
      'He comparat la biblioteca amb la carpeta del servidor:';
  @override
  String get syncFirstUpload => 'Per pujar';
  @override
  String get syncFirstDownload => 'Per baixar';
  @override
  String get syncFirstBoth => 'A tots dos costats';
  @override
  String get syncFirstBothHint =>
      'Iguals: sense transferència. Diferents: per resoldre';
  @override
  String get syncFirstNoDelete =>
      'La primera sincronització no esborra res, ni aquí ni al '
      'servidor.';
  @override
  String get syncStartAction => 'Comença';
  @override
  String syncMassTrashTitle(int count) => 'Moure $count fitxers a la paperera?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Al servidor falten $count dels $total fitxers '
      'sincronitzats. Normalment vol dir una adreça errònia, un '
      'disc del NAS sense muntar o una carpeta buidada per error.';
  @override
  String get syncMassTrashHint =>
      'Si de debò els has esborrat en un altre dispositiu, '
      'confirma-ho: aquí van a la paperera.';
  @override
  String get syncMassTrashConfirm => 'Mou a la paperera';
  @override
  String syncMassDeleteTitle(int count) =>
      'Esborrar $count fitxers del servidor?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Aquí falten $count dels $total fitxers sincronitzats. Si '
      'no els has esborrat tu, cancel·la i revisa la carpeta de '
      'la biblioteca.';
  @override
  String get syncMassDeleteConfirm => 'Esborra del servidor';
  @override
  String get syncTooltip => 'Sincronitza';
  @override
  String get syncStageConnecting => 'Connectant amb el servidor…';
  @override
  String get syncStageComparing => 'Comparant amb el servidor…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sincronitzant · $done de $total';
  @override
  String get syncStatusWarnings => 'Sincronitzada amb avisos';
  @override
  String syncConflictsHeader(int count) =>
      'Modificats aquí i al servidor · $count';
  @override
  String get syncConflictHint => 'No s’ha tocat cap de les dues versions';
  @override
  String get syncResolveAction => 'Resol';
  @override
  String syncFailuresHeader(int count) => 'Sense sincronitzar · $count';
  @override
  String get syncFailuresHint =>
      'Es tornaran a provar a la propera sincronització';
  @override
  String get syncAbortAuth => 'El servidor ha rebutjat la contrasenya';
  @override
  String get syncAbortMissingPassword => 'No hi ha cap contrasenya guardada';
  @override
  String get syncAbortOffline => 'Servidor inaccessible';
  @override
  String get syncAbortRemoteMissing => 'La carpeta del servidor ja no hi és';
  @override
  String get syncAbortUnsupported => 'El servidor ja no funciona com a WebDAV';
  @override
  String get syncAbortFailed => 'La sincronització no ha funcionat';
  @override
  String get syncAbortNotConfirmed => 'Sincronització cancel·lada';
  @override
  String get syncAbortNothingTouched =>
      'No s’ha tocat cap fitxer. Els teus canvis es queden aquí '
      'fins a la propera sincronització correcta.';
  @override
  String syncLastSuccess(String when) =>
      'Última sincronització correcta: $when';
  @override
  String get syncNoSuccessYet => 'Encara no hi ha cap sincronització correcta';
  @override
  String get syncUpdatePasswordAction => 'Actualitza la contrasenya';
  @override
  String get syncRetryAction => 'Torna-ho a provar';
  @override
  String get syncOpenSettingsAction => 'Configuració';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sincronitzada · 1 fitxer esborrat en un altre lloc és a '
            'la paperera'
      : 'Sincronitzada · $count fitxers esborrats en un altre lloc '
            'són a la paperera';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sincronitzada · 1 conflicte per resoldre'
      : 'Sincronitzada · $count conflictes per resoldre';
  @override
  String get syncShowAction => 'Mostra';
  @override
  String get syncConflictTitle => 'Resol el conflicte';
  @override
  String get syncConflictBinary =>
      'No és un fitxer de text: tria quina còpia vols conservar.';
  @override
  String get syncConflictKeepNote =>
      'La còpia que no conservis es queda a l’historial de la '
      'nota.';
  @override
  String get syncKeepLocal => 'Conserva la d’aquest dispositiu';
  @override
  String get syncKeepRemote => 'Conserva la del servidor';
  @override
  String get syncConflictLoadFailed =>
      'No s’han pogut llegir les dues versions';
  @override
  String get syncResolveFailed => 'No s’ha pogut resoldre el conflicte';
  @override
  String get syncResolved => 'Conflicte resolt';
  @override
  String get syncConflictMoved =>
      'Una de les versions ha canviat mentrestant: el conflicte s’ha tornat a '
      'llegir, torna a triar.';
  @override
  String get syncSectionWhen => 'Quan sincronitzar';
  @override
  String get syncAutoTitle => 'Automàticament';
  @override
  String get syncAutoSubtitle => 'Després dels canvis, en obrir i a intervals';
  @override
  String get syncIntervalTitle => 'Comprova el servidor cada';
  @override
  String get syncIntervalSubtitle => 'Només amb l’app oberta';
  @override
  String get syncIntervalDialogBody =>
      'Per veure els canvis fets en altres dispositius mentre l’app és '
      'oberta. Amb “Mai”, només després dels canvis i en obrir.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minut' : '$count minuts';
  @override
  String get syncIntervalNever => 'Mai';
  @override
  String get syncWifiOnlyTitle => 'Només amb Wi-Fi';
  @override
  String get syncWifiOnlySubtitle => 'Amb dades mòbils, sincronitza només a mà';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 canvi en espera' : '$count canvis en espera';
  @override
  String syncRetryIn(String wait) => 'nou intent d’aquí a $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Esperant el Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Esperant la connexió';
  @override
  String get syncMobileDataHint =>
      '“Sincronitza ara” fa servir igualment les dades mòbils.';
  @override
  String get syncQueueKeptHint =>
      'Els canvis es queden aquí, encara que tanquis l’app, i surten sols '
      'quan el servidor respon.';
  @override
  String get syncAutoPaused => 'Sincronització automàtica en pausa';
  @override
  String get syncPausedAuthHint =>
      'Es reprèn quan actualitzes la contrasenya o sincronitzes a mà.';
  @override
  String get syncPausedServerHint =>
      'Es reprèn quan corregeixes l’adreça o sincronitzes a mà.';
  @override
  String get syncPausedConfirmHint =>
      '“Sincronitza ara” mostra què s’eliminaria i demana confirmació.';
  @override
  String get syncNeedsConfirmation => 'Esperant la teva confirmació';
  @override
  String get syncMergeIntro =>
      'Les modificacions que no se superposen ja estan unides; tria què '
      'conservar on sí que se superposen.';
  @override
  String get syncMergeClean =>
      'Les dues versions s’uneixen soles: no hi ha res que se superposi.';
  @override
  String get syncMergeNoBase =>
      'No hi ha cap versió comuna per fusionar: tries tu a cada punt on les '
      'dues còpies difereixen.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Superposició $index de $total';
  @override
  String get syncMergeFromLocal => 'D’aquest dispositiu';
  @override
  String get syncMergeFromRemote => 'Del servidor';
  @override
  String get syncMergeRemovedLines => 'Línies eliminades';
  @override
  String get syncMergeAbsentLines => 'No és en aquesta còpia';
  @override
  String get syncMergeKeepLocal => 'Les meves';
  @override
  String get syncMergeKeepRemote => 'Del servidor';
  @override
  String get syncMergeKeepBoth => 'Totes dues';
  @override
  String get syncMergeSave => 'Desa la unió';
  @override
  String get syncMergeKeepWhole => 'O conserva una còpia sencera';

  // The welcome deck and the guided tour (#308).

  @override
  String get welcomeSkip => 'Omet';
  @override
  String get welcomeNext => 'Següent';
  @override
  String get welcomeBack => 'Enrere';
  @override
  String get welcomeStart => 'Comença a escriure';
  @override
  String get welcomeClose => 'Tanca';
  @override
  String get welcomeNotesTitle => 'Les teves notes són fitxers';
  @override
  String get welcomeNotesBody =>
      'El Niman guarda les teves notes com a fitxers Markdown '
      'senzills, a les carpetes que triïs. Una nota és un fitxer '
      '.md, i tot el que l’aplicació et mostra es construeix a '
      'partir d’ells. Sense compte i sense un format nostre al qual '
      'tornar.';
  @override
  String get welcomeModesTitle => 'Tres maneres d’escriure la mateixa nota';
  @override
  String get welcomeModesBody =>
      'Escriu la font Markdown, escriu la nota tal com es llegeix '
      '(l’editor en directe), o llegeix-la. És una sola nota facis '
      'servir la que facis servir, i pots canviar per nota o per '
      'tota la biblioteca.';
  @override
  String get welcomeLinksTitle => 'Tot es connecta';
  @override
  String get welcomeLinksBody =>
      'Els wikilinks com [[aquest]] troben la seva nota mentre '
      'escrius. Les etiquetes, el frontmatter i les plantilles '
      'treuen del mig les parts que escrius una i altra vegada.';
  @override
  String get welcomeFindTitle => 'Torna-la a trobar';
  @override
  String get welcomeFindBody =>
      'Cerca de text complet a la biblioteca, una paleta d’ordres '
      'per a tot el que sap fer l’aplicació, i la nota ràpida a una '
      'tecla.';
  @override
  String get welcomeExportTitle => 'Va amb tu';
  @override
  String get welcomeExportBody =>
      'Exporta una nota o una carpeta sencera com a Markdown, HTML, '
      'PDF o llibre EPUB. Porta una exportació del Notion, o obre '
      'una volta d’Obsidian on ja és.';
  @override
  String get welcomeTasksTitle => 'Tasques i recordatoris';
  @override
  String get welcomeTasksBody =>
      'Una llista todo.txt que guardes com a fitxer — prioritats, '
      'projectes, terminis — i alarmes rem: que t’avisen quan '
      'alguna cosa venç, al mòbil i a l’escriptori.';
  @override
  String get welcomeSyncTitle => 'Entre les teves màquines';
  @override
  String get welcomeSyncBody =>
      'Apunta una biblioteca a una carpeta WebDAV — Nextcloud, '
      'ownCloud, un NAS — i les edicions se sincronitzen en tots '
      'dos sentits, fusionades línia a línia quan dos dispositius '
      'han tocat la mateixa nota.';
  @override
  String get welcomeDeviceTitle => 'Niman en aquest dispositiu';
  @override
  String get welcomeAndroidBody =>
      'Comparteix text o un fitxer amb el Niman des de qualsevol '
      'aplicació, mantén una nota a la pantalla d’inici i '
      'enregistra una nota de veu en lloc d’escriure.';
  @override
  String get welcomeDesktopBody =>
      'Pestanyes i panells dividits, la safata del sistema, '
      'arrossega i deixa anar a la finestra, i fitxers .md que '
      'obren el Niman.';
  @override
  String get welcomeQuestionTitle => 'Has escrit Markdown abans?';
  @override
  String get welcomeQuestionNote =>
      'Això només decideix com arrenca l’aplicació. Pots activar o '
      'desactivar qualsevol editor a Configuració → Editor quan '
      'vulguis.';
  @override
  String get welcomeAnswerNone => 'Mai';
  @override
  String get welcomeAnswerNoneHint =>
      'L’editor en directe, i la font Markdown no s’ofereix fins '
      'que l’activis.';
  @override
  String get welcomeAnswerSome => 'Una mica';
  @override
  String get welcomeAnswerSomeHint =>
      'L’editor en directe obre les notes; la font Markdown és a un '
      'commutador.';
  @override
  String get welcomeAnswerFluent => 'Sempre';
  @override
  String get welcomeAnswerFluentHint =>
      'La font Markdown, tal com arriba l’aplicació.';
  @override
  String get welcomeTourOffer => 'Ensenya’m l’aplicació';
  @override
  String get welcomeTourOfferNote =>
      'El recorregut comença quan la teva primera biblioteca és '
      'oberta, i assenyala els controls reals.';
  @override
  String get welcomeDeckCommand => 'Què sap fer el Niman';
  @override
  String get welcomeTourCommand => 'Fes el recorregut';
  @override
  String get tourDone => 'Fet';
  @override
  String get tourOfferTitle => 'Et faig un recorregut?';
  @override
  String get tourOfferBody =>
      'Uns quants passos per l’aplicació, assenyalant els controls '
      'reals. Pots aturar-te a qualsevol pas i reprendre’l més tard '
      'des de la paleta d’ordres.';
  @override
  String get tourOfferYes => 'Mostra’m';
  @override
  String get tourOfferNo => 'Ara no';
  @override
  String get tourTreeTitle => 'La teva biblioteca';
  @override
  String get tourTreeBody =>
      'Aquesta és la carpeta que vas triar, carpeta per carpeta. '
      'Tot el que facis a un fitxer fora del Niman apareix aquí tan '
      'bon punt arriba.';
  @override
  String get tourCreateTitle => 'Crea una nota';
  @override
  String get tourCreateBody =>
      'Notes, llistes, notes de veu, plantilles i carpetes comencen '
      'totes aquí. El mateix menú apareix al mòbil com el botó '
      'rodó.';
  @override
  String get tourNoteTitle => 'Una nota alhora';
  @override
  String get tourNoteBody =>
      'La nota a la pantalla; les que has obert es queden en '
      'pestanyes a sobre, i un segon panell es pot obrir al costat '
      'en una finestra ampla.';
  @override
  String get tourModesTitle => 'Tres maneres d’escriure';
  @override
  String get tourModesBody =>
      'Escriu la font Markdown, escriu-la tal com es llegeix, o '
      'llegeix-la — aquest commutador és per nota, i la '
      'configuració de la biblioteca decideix què s’obre.';
  @override
  String get tourToolbarTitle => 'La barra d’eines';
  @override
  String get tourToolbarBody =>
      'Format a la línia on ets, i les mateixes accions amb el clic '
      'dret. Cada construcció que el Niman llegeix és a la xitxa.';
  @override
  String get tourCheatsheetTitle => 'Cada construcció, escrita al costat';
  @override
  String get tourCheatsheetBody =>
      'Aquesta és la xitxa. Cada exemple es pot copiar, i Insereix '
      'el posa a la nota que tens oberta.';
  @override
  String get tourCheatsheetOpen => 'Obre-la';
  @override
  String get tourTabsTitle => 'Tot és una pestanya';
  @override
  String get tourTabsBody =>
      'Fitxers, tasques, cerca, la nota ràpida, configuració. La '
      'paleta d’ordres arriba a totes, i a cada ordre, des del '
      'teclat.';
  @override
  String get tourDockTitle => 'Esquema, etiquetes, historial';
  @override
  String get tourDockBody =>
      'L’esquema de la nota, les seves etiquetes i les seves '
      'versions passades, al costat. Al mòbil el menú de la nota '
      'obre els mateixos tres.';
  @override
  String welcomePageOf(int page, int of) => '$page de $of';

  // Cascading a checklist tick (#326).

  @override
  String get cascadeChecklistTitle => 'Marca les caselles imbricades';
  @override
  String get cascadeChecklistSubtitle =>
      'Marcar una casella marca les que hi ha imbricades a sota. '
      'Desmarcar-la les deixa tal com estan.';

  // Rebuilding the index file (#368).

  @override
  String get rebuildIndexTitle => "Reconstrueix l'índex";

  // What the template checker says in the editor (T-TPL-09).

  @override
  String templateHintDidYouMean(String fix) => 'Volíeu dir $fix?';
  @override
  String get templateHintNoFix =>
      'No s’ofereix cap correcció — el text queda tal com està escrit.';
  @override
  String get templateHintFixAction => 'Corregeix';
  @override
  String get templateHintDismissAction => 'Descarta';
  @override
  String templateProblems(int count) => count == 1
      ? '1 problema en aquesta plantilla'
      : '$count problemes en aquesta plantilla';
  // The wikilink panel (#475) and the two book forms it offers after `#`.

  @override
  String wikilinkHeadingsIn(String named) => 'Títols a $named';
  @override
  String wikilinkPlacesIn(String named) => 'Ubicacions a $named';
  @override
  String get wikilinkThisNote => 'aquesta nota';
  @override
  String wikilinkNoMatchHeading(String query) =>
      'Cap títol coincideix amb “$query”.';
  @override
  String wikilinkNoMatchNote(String query) =>
      'Cap nota coincideix amb “$query”.';
  @override
  String get wikilinkNoHeading => 'aquesta nota no té cap títol amb aquest nom';
  @override
  String get wikilinkNoNote =>
      'res de la biblioteca no té aquest nom ni aquest àlies';
  @override
  String wikilinkAlias(String alias) => 'àlies $alias';
  @override
  String get wikilinkBookNote =>
      'Una pàgina es tria, no es nomena d’una llista: escriu-ne el número.';
  @override
  String get wikilinkFooterMove => 'mou';
  @override
  String get wikilinkFooterOr => 'o';
  @override
  String get wikilinkFooterInsert => 'insereix';
  @override
  String get wikilinkFooterClose => 'tanca';
  @override
  String get suggesterPageHint => 'escriu un número';
  @override
  String get suggesterChapterHint => 'nomena un fitxer del llibre';

  // What the template checker found, as the hint writes it (T-TPL-09).

  @override
  String get templateProblemUnclosedBraces =>
      'claus d’obertura sense tancar: res no tanca aquest espai reservat';
  @override
  String get templateProblemEmptyPlaceholder =>
      'espai reservat buit: no hi ha cap nom entre les claus';
  @override
  String templateProblemUnknownPlaceholder(String name) =>
      'espai reservat desconegut “$name”';
  @override
  String templateProblemAskNoLabel(String name) =>
      '“$name” no té etiqueta: no pregunta res, i l’espai reservat queda tal '
      'com és';
  @override
  String templateProblemCounterNoName(String name) =>
      '“$name” no té nom: no compta res, i l’espai reservat queda tal com és';
  @override
  String templateProblemCursorFilters(String name) =>
      '“$name” no accepta filtres: el cursor no es col·loca, i l’espai '
      'reservat '
      'queda tal com és';
  @override
  String get templateProblemUnclosedQuote =>
      'cometa sense tancar al format de data: tot el que segueix es llegeix '
      'com '
      'a text normal';
  @override
  String templateProblemUnknownDateToken(String token) =>
      'token de data desconegut “$token”';
  @override
  String get templateProblemEmptyFilter =>
      'filtre buit: no hi ha cap nom després del “|”';
  @override
  String templateProblemDateMove(String filter, String formats) =>
      '“$filter” desplaça una data: només $formats accepten un desplaçament, i '
      'només abans de qualsevol altre filtre';
  @override
  String templateProblemNotADateMove(String filter) =>
      '“$filter” no és un desplaçament de data: un desplaçament és un número i '
      'una unitat, com “+7d” o “-1w”';
  @override
  String templateProblemSnapUnit(String filter, String units, String unit) =>
      '“$filter” s’ajusta a $units, no a “$unit”';
  @override
  String templateProblemPadWidth(String filter, String argument) =>
      '“$filter” necessita un número per a l’amplada, i “$argument” no ho és';
  @override
  String templateProblemUnknownFilter(String name) =>
      'filtre desconegut “$name”';
  @override
  String get diagramTitle => 'Diagrama';

  @override
  String get fullScreen => 'Pantalla completa';
  @override
  String get commandInsertDiagram => 'Insereix diagrama (Mermaid)';

  @override
  String get commandInsertMindMap => 'Insereix mapa mental';

  @override
  String get commandConvertListToMindMap =>
      'Converteix la llista en mapa mental';
  @override
  String get toolMindMapSubtitle =>
      'Reemplaça la llista del cursor per un mapa mental';

  @override
  String get toolMindMapNeedsList => 'El cursor no és en una llista';

  @override
  String ocrEngineName(String version) => 'Tesseract $version';

  @override
  String get settingsSectionTextRecognition => 'Reconeixement de text';

  @override
  String get ocrIntro =>
      'Llegeix el text dels PDF escanejats i de les imatges en una '
      'nota al costat. Tot funciona en aquest dispositiu: el motor '
      'i cada idioma es baixen una sola vegada, el primer cop que '
      'calen.';

  @override
  String get ocrEngineTitle => 'Motor';

  @override
  String get ocrEngineSystem => 'Biblioteca del sistema';

  @override
  String get ocrEngineBundled => "Inclòs a l'aplicació";

  @override
  String get ocrEngineUnavailable =>
      'No hi ha cap motor per a aquest dispositiu';

  @override
  String get ocrEngineDeleteTitle => 'Vols suprimir el motor?';

  @override
  String get ocrQualityTitle => 'Qualitat';

  @override
  String get ocrQualityFast => 'Ràpida';

  @override
  String get ocrQualityBest => 'Millor';

  @override
  String get ocrQualityHint =>
      'Ràpida: 1–4 MB per idioma, àgil en qualsevol dispositiu. '
      'Millor: 10–15 MB per idioma, més precisa amb escanejats '
      'difícils, de dues a tres vegades més lenta. Cada qualitat té '
      'els seus idiomes.';

  @override
  String get ocrLanguageTitle => 'Idioma per defecte';

  @override
  String get ocrAlsoTitle => 'També';

  @override
  String get ocrAlsoSubtitle => 'Per a pàgines que barregen dos idiomes';

  @override
  String get ocrAlsoNone => 'Cap';

  @override
  String ocrOnDevice(String size) => 'En aquest dispositiu · $size';

  @override
  String get ocrOtherLanguages => 'Altres idiomes';

  @override
  String ocrSearchLanguages(int count) => 'Cerca entre $count idiomes';

  @override
  String get ocrLanguageDefault => 'Per defecte';

  @override
  String ocrLanguageDeleteTitle(String language) => 'Vols suprimir $language?';

  @override
  String ocrDeleteBody(String size) =>
      'Això allibera $size. Es tornarà a baixar quan el '
      'reconeixement de text el necessiti.';

  @override
  String get ocrRecognizeAction => 'Reconeix el text';

  @override
  String get ocrPagesTitle => 'Pàgines';

  @override
  String ocrPagesAll(int count) => 'Totes les $count';

  @override
  String ocrPagesThis(int page) => 'Aquesta pàgina ($page)';

  @override
  String get ocrPagesFrom => 'De';

  @override
  String get ocrPagesTo => 'a';

  @override
  String get ocrSavedAs => 'Es desarà com a';

  @override
  String get ocrSavedAsHint =>
      'Una nota al costat del fitxer, una secció per pàgina. La '
      'cerca la troba com qualsevol nota.';

  @override
  String get ocrPdfHasText =>
      'Aquest PDF ja conté text: potser no cal reconèixer-lo.';

  @override
  String ocrNeedsDownload(String size) => 'Primer, una baixada de $size';

  @override
  String get ocrNeedsDownloadHint =>
      'Només un cop: després funciona sense connexió.';

  @override
  String get ocrDownloadAndRecognize => 'Baixa i reconeix';

  @override
  String ocrRecognizing(int page, int total) =>
      'Reconeixent p. $page de $total';

  @override
  String get ocrPreparing => 'Baixant el que necessita el reconeixement…';

  @override
  String ocrRecognized(int words) => 'Text reconegut · $words paraules';

  @override
  String get ocrOpenText => 'Obre el text';

  @override
  String get ocrFailed => 'El reconeixement de text ha fallat';

  @override
  String get commandNeedOcrFile => 'Cal un PDF o una imatge a la pantalla';

  @override
  String get ocrTextTitle => 'Text';

  @override
  String get ocrScanTitle => 'Escaneig';

  @override
  String get ocrOpenAsNote => 'Obre com a nota';

  @override
  String get ocrShowText => 'Mostra el text';

  @override
  String get ocrHideText => 'Amaga el text';

  @override
  String get ocrCopyText => 'Copia';

  @override
  String ocrLostPlaces(int page, int lines) =>
      "p. $page: $lines línies han perdut el lloc a l'escaneig. "
      "Allà les anotacions s'apliquen a tota la pàgina.";

  @override
  String ocrRecognizeAgain(int page) => 'Reconeix de nou la p. $page';

  @override
  String get captureWebPage => 'Captura una pàgina web';

  @override
  String get capturePageField => 'Pàgina';

  @override
  String get captureFromClipboard => 'Agafada del porta-retalls.';

  @override
  String get captureInvalidUrl =>
      'Una adreça web comença per http:// o https://.';

  @override
  String get captureRead => 'Llegeix';

  @override
  String get captureDownloading => "S'està baixant…";

  @override
  String captureDownloaded(String size) => 'Baixada · $size';

  @override
  String captureFewWords(int words) => "Només s'han trobat $words paraules";

  @override
  String get captureRunningBrowser =>
      "S'està executant la pàgina en un navegador…";

  @override
  String get captureBrowserPrivacy =>
      "El navegador s'executa amagat, amb un perfil propi que s'esborra "
      'després: el vostre navegador i els seus inicis de sessió no es '
      'toquen.';

  @override
  String get captureReadInBrowser =>
      "Llegida després d'executar la pàgina en un navegador";

  @override
  String get captureNoArticle =>
      "No s'ha trobat cap article: la nota conserva el títol, la descripció "
      "i l'enllaç.";

  @override
  String get captureTitleField => 'Títol';

  @override
  String get captureFolderField => 'Carpeta';

  @override
  String get captureAddTag => 'Afegeix una etiqueta';

  @override
  String get capturePreview => 'Previsualització';

  @override
  String captureWordsMinutes(int words, int minutes) =>
      '$words paraules · $minutes min';

  @override
  String captureDownloadPictures(int count, String folder) =>
      'Baixa les $count imatges a $folder/';

  @override
  String get captureRemoved => 'Eliminat';

  @override
  String captureRemovedCode(int scripts, int styles) =>
      '$scripts scripts i $styles estils';

  @override
  String get captureRemovedMenu => 'El menú de navegació';

  @override
  String get captureRemovedBanner => 'Un bàner de galetes';

  @override
  String captureRemovedAround(int words) =>
      'La resta de la pàgina · $words paraules';

  @override
  String get captureSaveNote => 'Desa la nota';

  @override
  String get captureSaving => "S'està desant…";

  @override
  String captureUnreadableNotice(String url) =>
      'Niman no ha pogut llegir aquesta pàgina: només mostra el text després '
      "d'iniciar sessió o d'un script que no ha pogut executar. [Obriu "
      "l'enllaç](<$url>) per llegir-la.";

  @override
  String get captureFailScheme =>
      'Només es poden capturar pàgines http i https.';

  @override
  String get captureFailRedirects => 'La pàgina redirigeix massa vegades.';

  @override
  String get captureFailTimeout => 'La pàgina no ha respost a temps.';

  @override
  String get captureFailTooLarge => 'La pàgina ocupa més de 10 MB.';

  @override
  String get captureFailNotHtml =>
      'Això no és una pàgina web: és un fitxer, un PDF o una imatge.';

  @override
  String captureFailStatus(String code) =>
      'El lloc ha respost amb un error ($code).';

  @override
  String get captureFailNetwork =>
      "No s'ha pogut accedir a la pàgina: comproveu la connexió.";

  @override
  String get captureDropHint => 'Deixeu anar per capturar aquesta pàgina';

  @override
  String get captureDropDetail => "S'obre el diàleg de captura amb ella.";

  @override
  String get captureSaveToNiman => 'Desa a Niman';

  @override
  String get captureBackgroundHint =>
      'Tornareu al navegador; una notificació us dirà quan la nota estigui '
      'llesta.';

  @override
  String get captureAppendToNote => 'Afegeix a una nota';

  @override
  String get captureAppend => 'Afegeix';

  @override
  String captureReadingHost(String host) => "S'està llegint $host…";

  @override
  String captureSavedTitle(String title) => 'Desat: $title';

  @override
  String captureSavedBody(String folder, int words, int images) =>
      '$folder · $words paraules · $images imatges';

  @override
  String get captureSavedUnreadable => "Desat sense l'article";

  @override
  String captureUnreadableBody(String host) =>
      "No s'ha pogut llegir $host: es conserven el títol, la descripció i "
      "l'enllaç";

  @override
  String captureQuoteAdded(String note) => 'Cita afegida a $note';

  @override
  String captureQuoteFrom(String title) => 'de «$title»';

  @override
  String captureFailedTitle(String host) => "No s'ha pogut capturar $host";

  @override
  String get captureShowFolder => 'Mostra la carpeta';

  @override
  String get captureOpen => 'Obre';

  @override
  String get captureQuote => 'Cita';

  @override
  String captureNewNoteIn(String folder) => 'Nota nova a $folder';

  @override
  String captureDownloadPicturesTo(String folder) =>
      'Baixa les imatges a $folder/';

  @override
  String get highlightAction => 'Ressalta';

  @override
  String get highlightMark => 'Ressaltat';

  @override
  String get highlightRemove => 'Treu el ressaltat';

  @override
  String get highlightFailed => "No s'ha pogut desar el ressaltat";

  @override
  String get highlightYellow => 'Groc';

  @override
  String get highlightGreen => 'Verd';

  @override
  String get highlightBlue => 'Blau';

  @override
  String get highlightPink => 'Rosa';

  @override
  String get highlightCopy => 'Copia';
}
