// The Galician strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class GalicianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'xaneiro',
    'febreiro',
    'marzo',
    'abril',
    'maio',
    'xuño',
    'xullo',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'decembro',
  ];
  @override
  List<String> get monthNamesShort => const [
    'xan',
    'feb',
    'mar',
    'abr',
    'maio',
    'xuño',
    'xul',
    'ago',
    'set',
    'out',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'luns',
    'martes',
    'mércores',
    'xoves',
    'venres',
    'sábado',
    'domingo',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'lu',
    'ma',
    'me',
    'xo',
    've',
    'sa',
    'do',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Paperilleiro';
  @override
  String get trashSubtitle =>
      'Os borrados móvense a .trash/ (desactivado = borrado permanente)';
  @override
  String get trashAutoEmptyTitle => 'Baleirado automático do paperilleiro';
  @override
  String get trashAutoEmptySubtitle =>
      'As eliminacións antigas pérdense ao abrir a biblioteca';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nunca'
      : days == 1
      ? '1 día'
      : '$days días';
  @override
  String get debugLogsTitle => 'Rexistros de depuración';
  @override
  String get debugLogsSubtitle =>
      'Registra os acontecementos da app nun búfer de memoria';
  @override
  String get lineNumbersTitle => 'Numeros de liña';
  @override
  String get lineNumbersSubtitle =>
      'Mostra a columna de numeros de liña no editor de notas';
  @override
  String get readableLineLengthTitle => 'Lonxitude de liña lexible';
  @override
  String get readableLineLengthSubtitle =>
      'Manter o texto da nota nunha columna centrada en vez de en todo o ancho '
      'da xanela';
  @override
  String get noteColumnWidthTitle => 'Ancho da columna';
  @override
  String get noteColumnWidthSubtitle =>
      'Canto mide de ancho a columna da nota; 100% é o predeterminado';
  @override
  String get keyboardOnOpenTitle => 'Teclado ao abrir';
  @override
  String get keyboardOnOpenSubtitle =>
      'Mostra o teclado ao abrirse unha nota (desactivado = co primeiro '
      'toque)';
  @override
  String get editorKindSource => 'Fonte Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Fonte Markdown, tal como está escrita';
  @override
  String get editorKindWysiwygSubtitle =>
      'Texto con formato, editado directamente';
  @override
  String get settingsFolderToCreate => 'por crear';
  @override
  String get settingsSearchHint => 'Buscar nos axustes';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 axuste atopado' : '$count axustes atopados';
  @override
  String get settingsToggleOn => 'Activado';
  @override
  String get settingsToggleOff => 'Desactivado';
  @override
  String get switchToWysiwygTooltip => 'Cambiar ao editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Cambiar á fonte Markdown';
  @override
  String get switchToSourceLabel => 'Fonte';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aparencia';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionReminders => 'Lembranzas';
  @override
  String get keyboardShortcutsTitle => 'Atallos de teclado';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteca $name';
  @override
  String get settingsGroupLibraryHint => 'aplícase só a esta biblioteca';
  @override
  String get settingsGroupMaintenance => 'Mantemento';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Cartafols e camiños';
  @override
  String get settingsAreaTrashHistory => 'Paperilleiro e cronoloxía';
  @override
  String get settingsAreaDiagnostics => 'Diagnóstico e información';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Necesita un teclado físico conectado';
  @override
  String get settingsSectionUpdates => 'Actualizacións';
  @override
  String get autoUpdateTitle => 'Actualizacións automáticas';
  @override
  String get autoUpdateSubtitle =>
      'Comproba GitHub Releases ao iniciar e cada 6 horas';
  @override
  String get checkForUpdatesTitle => 'Buscar actualizacións';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version está dispoñible';
  @override
  String get updateUpToDate => 'Niman está actualizado';
  @override
  String get updateCheckFailed => 'Non se puideron comprobar as actualizacións';
  @override
  String updateSavedTo(Object path) => 'Actualización gardada en $path';
  @override
  String get updateInstallerStarted => 'Instalador iniciado';
  @override
  String get settingsSpellCheckTitle => 'Comprobación ortográfica';
  @override
  String get settingsSpellCheckSubtitle =>
      'Sobralinha os erros ortográficos mentres escribes.';
  @override
  String get spellCheckDictionaryTitle => 'Dicionario';
  @override
  String get spellCheckDictionarySystem => 'Predeterminado do sistema';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Escoller dicionarios';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Escolle todos os idiomas nos que está escrita a biblioteca. Unha '
      'palabra pasa cando calquera dos dicionarios escollidos a coñece; '
      'sen selección, decide o idioma do sistema.';
  @override
  String get spellCheckNoDictionaries =>
      'Non se encontraron dicionarios neste sistema.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Comprobación ortográfica';
  @override
  String get spellCheckTitle => 'Ortografía';
  @override
  String get spellCheckEmpty => 'Non hai erros ortográficos.';
  @override
  String get spellCheckUnavailable =>
      'hunspell non está instalado neste sistema.';
  @override
  String get spellCheckNoSuggestions => 'Sen suxestións';
  @override
  String spellCheckCount(int count) => '$count por revisar';
  @override
  String spellCheckLine(int line) => 'liña $line';
  @override
  String get addWordToDictionary => 'Engade ao diccionario';

  @override
  String indentWidthValue(int spaces) => '$spaces espazos';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Iluminación';
  @override
  String get themeBrightnessSubtitle =>
      'Claro, escuro ou o que teña configurado o dispositivo';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Claro';
  @override
  String get themeBrightnessNight => 'Escuro';
  @override
  String get themeTitle => 'Tema';
  @override
  String get themePaletteSystem => 'Sistema';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Temas';
  @override
  String get themesInUse => 'En uso';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Tema novo';
  @override
  String get themeNewName => 'Nome';
  @override
  String get themeNewStartFrom => 'Partir de';
  @override
  String get themeNewRandom => 'Cores aleatorias';
  @override
  String get themeNameTaken => 'Xa existe un tema con ese nome';
  @override
  String themeDeleteBody(String name) =>
      '¿Eliminar «$name»? As súas cores pérdense para sempre.';
  @override
  String get themeDuplicate => 'Duplicar';
  @override
  String get themeMenuTooltip => 'Accións do tema';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Editar';
  @override
  String get themeEditorTitle => 'Editar o tema';
  @override
  String get themeEditorChrome => 'Interface';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Listas de tarefas (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Cada cor leva o nome que usa o ficheiro exportado';
  @override
  String get themeEditorDiscardTitle => 'Descartar os cambios';
  @override
  String get themeEditorDiscardBody => 'As cores que cambiaste non se gardan';
  @override
  String get themeEditorDiscard => 'Descartar';
  @override
  String get themeEditorBadColor => 'Usa #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Exportar';
  @override
  String themeExportDone(String where) => 'Tema exportado a $where';
  @override
  String themeFileFailed(String error) => 'Non se puido mover o tema: $error';
  @override
  String get themeImport => 'Importar';
  @override
  String get themeImportInvalid => 'Este ficheiro non é un tema de Niman';
  @override
  String themeImportVersion(int version) =>
      'Este tema vén dun Niman máis novo (versión $version)';
  @override
  String themeImportBadRole(String role) =>
      'O ficheiro non dá cor para «$role»';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Tamaño do texto da interfaz';
  @override
  String get uiTextScaleSubtitle =>
      'A árbore, as pestanas e os diálogos; por riba da configuración '
      'do sistema';
  @override
  String get noteTextScaleTitle => 'Tamaño do texto da nota';
  @override
  String get noteTextScaleSubtitle =>
      'O editor e a previsualización, sempre de acordo';
  @override
  String get sourceFontTitle => 'Tipografía do editor de código fonte';
  @override
  String get sourceFontSubtitle =>
      'A tipografía do panel de código fonte; a previsualización conserva a da '
      'nota';
  @override
  String get sourceFontMonospace => 'Monoespazada';
  @override
  String get sourceFontSansSerif => 'Sen serifa';
  @override
  String get sourceFontSerif => 'Con serifa';
  @override
  String get epubLookTitle => 'Aspecto dos libros';
  @override
  String get epubLookSubtitle =>
      'Tema, tipo de letra e tamaño do texto dos libros EPUB, á parte das '
      'notas';
  @override
  String get epubSameAsApp => 'Como a aplicación';
  @override
  String get epubFontTitle => 'Tipo de letra';
  @override
  String get epubFontSerif => 'Con serifa';
  @override
  String get epubFontSans => 'Sen serifa';
  @override
  String get epubFontMono => 'Monoespazada';
  @override
  String get epubTextSizeTitle => 'Tamaño do texto';

  // Settings: preview mode.
  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formato do enlace';
  @override
  String get linkTypeSubtitle => 'Que insere o botón de enlace no editor';
  @override
  String get linkTypeWikilink => 'Enlace wiki';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Crear notas que faltan en';
  @override
  String get missingNoteLocationRoot => 'Raíz da biblioteca';
  @override
  String get missingNoteLocationCurrentFolder => 'Cartafol actual';
  @override
  String get indentWidthTitle => 'Ancho da sangría';
  @override
  String get indentWidthSubtitle =>
      'Espazos que se engaden por nivel de sangría no editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Idioma';
  @override
  String get languageSubtitle => 'O idioma do propio texto da app';
  @override
  String get languageSystem => 'Sistema';
  @override
  String get weekStartTitle => 'Primeiro día da semana';
  @override
  String get weekStartSubtitle =>
      'Onde os calendarios comezan a semana. O do sistema por defecto; un día '
      'escollido aquí vale en cada dispositivo da biblioteca.';
  @override
  String get weekStartSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Engadir un elemento';
  @override
  String get listAddTooltip => 'Engadir un elemento';
  @override
  String get listEmpty => 'Aínda non hai elementos';
  @override
  String get listDragHandleLabel => 'Cambiar a orde do elemento';
  @override
  String get shoppingListName => 'Lista da compra';
  @override
  String get checklistName => 'Lista de control';
  @override
  String get shoppingQuantityLabel => 'Cantidade';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Aínda non hai gravacións';
  @override
  String get audioRecord => 'Gravar';
  @override
  String get audioStop => 'Deter';
  @override
  String get audioPlay => 'Reproducir';
  @override
  String get audioDelete => 'Borrar a gravación';
  @override
  String get audioImport => 'Importar un ficheiro de audio';
  @override
  String get audioRecording => 'Gravando…';
  @override
  String get audioPermissionDenied =>
      'Permiso do micrófono denegado — é necesario para gravar.';
  @override
  String get newAudioNoteTitle => 'Nota de voz nova';
  @override
  String get newAudioNoteDefault => 'A miña gravación';
  @override
  String get showAudioTooltip => 'Mostrar as gravacións';
  @override
  String get audioMessageHint => 'Escribe unha nota…';
  @override
  String get audioSend => 'Enviar';
  @override
  String get audioRename => 'Cambiar o nome da gravación';
  @override
  String get audioDescriptionHint => 'Describe esta gravación…';
  @override
  String get audioEditDescription => 'Editar a descrición';
  @override
  String get audioDeleteNote => 'Borrar a nota';
  @override
  String get audioEditNote => 'Editar a nota';
  @override
  String get audioPause => 'Pausa';
  @override
  String get audioEditTitle => 'Editar título';
  @override
  String get audioTitleHint => 'Título desta gravación…';
  @override
  String audioUntitled(int n) => 'Gravación $n';
  @override
  String get audioMoreActions => 'Máis accións';
  @override
  String get audioDiscardRecording => 'Descartar gravación';
  @override
  String get audioPauseRecording => 'Pausar a gravación';
  @override
  String get audioResumeRecording => 'Retomar a gravación';
  @override
  String get audioRecordingPaused => 'En pausa';
  @override
  String get audioSavingRecording => 'Gardando…';
  @override
  String get audioPlayFailed => 'Non se puido reproducir o audio';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rápida';
  @override
  String get trayOpen => 'Abrir Niman';
  @override
  String get trayQuit => 'Saír';
  @override
  String get closeToTrayTitle => 'Pechar na área de notificación';
  @override
  String get closeToTraySubtitle =>
      'O × da xanela agocha Niman e déixao en marcha, así os recordatorios '
      'seguen chegando. Sáese desde o menú da icona.';
  @override
  String get shortcutNewTodo => 'Tarefa nova';
  @override
  String get shortcutNewNote => 'Nota nova';
  @override
  String get shortcutNewList => 'Lista nova';
  @override
  String get shortcutNewAudio => 'Nota de voz nova';
  @override
  String get shortcutToggleSidebar => 'Mostrar ou ocultar o filtro';
  @override
  String get shortcutCloseTab => 'Pechar a nota actual';
  @override
  String get shortcutNextTab => 'Seguinte nota aberta';
  @override
  String get shortcutPreviousTab => 'Nota aberta anterior';
  @override
  String get shortcutNoteBack => 'Atrás';
  @override
  String get shortcutNoteForward => 'Adiante';
  @override
  String get shortcutEditorSection => 'No editor';
  @override
  String get shortcutFormatSection => 'Formato';
  @override
  String get shortcutFind => 'Buscar';
  @override
  String get shortcutReplace => 'Buscar e substituír';
  @override
  String get shortcutSavingNote =>
      'Os cambios gárdanse automaticamente, polo que non hai atallo para '
      'gardar.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Cargando…';
  @override
  String get noteStatusSaving => 'Gardando…';
  @override
  String get noteStatusUnsaved => 'Sen gardar';
  @override
  String get noteStatusSaved => 'Gardado';
  @override
  String get noteStatusError => 'Erro';
  @override
  String get noteNotText =>
      'Este ficheiro non é unha nota de texto, así '
      'que Niman non pode amosalo aquí.';
  @override
  String get noteLoadFailed => 'Non se puido abrir esta nota.';
  @override
  String wordCount(int count) => count == 1 ? '1 palabra' : '$count palabras';
  @override
  String get outlineTooltip => 'Estrutura';
  @override
  String get outlineNoHeadings => 'Non hai títulos';
  @override
  String get outlineNoTitle => '(sen título)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Negrado';
  @override
  String get toolbarItalic => 'Itálica';
  @override
  String get toolbarStrikethrough => 'Rachado';

  @override
  String get toolbarHighlight => 'Resaltado';
  @override
  String get toolbarSuperscript => 'Superíndice';
  @override
  String get toolbarUnderline => 'Sobralinhado';
  @override
  String get toolbarLink => 'Enlace';
  @override
  String get toolbarCode => 'Bloque de código';
  @override
  String get toolbarImage => 'Inserir imaxe';
  @override
  String get toolbarTable => 'Táboa';
  @override
  String get tableRow => 'Fila';
  @override
  String get tableColumn => 'Columna';
  @override
  String get tableAddRowAbove => 'Inserir fila enriba';
  @override
  String get tableAddRowBelow => 'Inserir fila debaixo';
  @override
  String get tableMoveRowUp => 'Subir fila';
  @override
  String get tableMoveRowDown => 'Baixar fila';
  @override
  String get tableDuplicateRow => 'Duplicar fila';
  @override
  String get tableDeleteRow => 'Eliminar fila';
  @override
  String get tableAddColumnLeft => 'Inserir columna á esquerda';
  @override
  String get tableAddColumnRight => 'Inserir columna á dereita';
  @override
  String get tableMoveColumnLeft => 'Mover columna á esquerda';
  @override
  String get tableMoveColumnRight => 'Mover columna á dereita';
  @override
  String get tableAlignLeft => 'Aliñar á esquerda';
  @override
  String get tableAlignCenter => 'Centrar';
  @override
  String get tableAlignRight => 'Aliñar á dereita';
  @override
  String get tableDuplicateColumn => 'Duplicar columna';
  @override
  String get tableDeleteColumn => 'Eliminar columna';
  @override
  String get tableSortAscending => 'Ordenar pola columna (A → Z)';
  @override
  String get tableSortDescending => 'Ordenar pola columna (Z → A)';
  @override
  String get tableAddRow => 'Engadir fila';
  @override
  String get tableAddColumn => 'Engadir columna';
  @override
  String get cheatsheetTitle => 'Guía rápida de Markdown';
  @override
  String get cheatsheetCopy => 'Copiar';
  @override
  String get cheatsheetCopied => 'Copiado';
  @override
  String get copyCode => 'Copiar o código';
  @override
  String get codeCopied => 'Código copiado';
  @override
  String get cheatsheetInsert => 'Inserir na nota';
  @override
  String get cheatHeadings => 'Títulos';
  @override
  String get cheatEmphasis => 'Negra, cursiva, riscado';
  @override
  String get cheatHtmlFormats => 'Subliñado, superíndice, subíndice';
  @override
  String get cheatLists => 'Listas';
  @override
  String get cheatChecklists => 'Listas de verificación';
  @override
  String get cheatQuotes => 'Citas';

  @override
  String get cheatCallouts => 'Destacados';
  @override
  String get cheatLinks => 'Ligazóns';
  @override
  String get cheatWikilinks => 'Ligazóns a notas';
  @override
  String get cheatEmbeds => 'Imaxes e incrustacións';
  @override
  String get cheatTags => 'Etiquetas';
  @override
  String get cheatInlineCode => 'Código nunha frase';
  @override
  String get cheatCodeBlocks => 'Bloques de código';
  @override
  String get cheatMath => 'Matemáticas';
  @override
  String get cheatTables => 'Táboas';
  @override
  String get cheatFootnotes => 'Notas ao pé';
  @override
  String get cheatRule => 'Liña horizontal';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatEpubMetadata => 'Metadatos EPUB';
  @override
  String get cheatTemplates => 'Marcadores dos modelos';
  @override
  String get menuAddLink => 'Engadir ligazón';
  @override
  String get menuAddExternalLink => 'Engadir ligazón externa';
  @override
  String get menuFormat => 'Formato';
  @override
  String get menuParagraph => 'Parágrafo';
  @override
  String get menuInsert => 'Inserir';
  @override
  String get menuBody => 'Texto normal';
  @override
  String get formatSubscript => 'Subíndice';
  @override
  String get formatInlineCode => 'Código';
  @override
  String get insertFootnote => 'Nota ao pé';
  @override
  String get insertRule => 'Liña horizontal';
  @override
  String get insertCodeBlock => 'Bloque de código';
  @override
  String get insertMathBlock => 'Bloque matemático';
  @override
  String get menuHeadingWord => 'Título';
  @override
  String get toolbarHeading => 'Título';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Lista numerada';
  @override
  String get toolbarChecklist => 'Lista de verificación';
  @override
  String get toolbarQuote => 'Cita';
  @override
  String get toolbarIndent => 'Sangrar';
  @override
  String get toolbarOutdent => 'Desfacer sangría';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Ferramentas';
  @override
  String get editorToolsTitle => 'Ferramentas do editor';
  @override
  String get toolCountListTitle => 'Contar unha lista';
  @override
  String get toolCountListSubtitle =>
      'Suma o que enumeran as filas, como lista de verificación';
  @override
  String get toolCountListNeedsList =>
      'Esta nota non ten ningunha lista que contar';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Ler cada fila como';
  @override
  String get tallyCutDash => 'Nome - valores';
  @override
  String get tallyCutColon => 'Nome: valores';
  @override
  String get tallyCutCommas => 'Valores separados por comas';
  @override
  String get tallyCutWhole => 'Toda a fila, como un só valor';
  @override
  String get tallySortLabel => 'Orde';
  @override
  String get tallySortCount => 'Primeiro os máis frecuentes';
  @override
  String get tallySortAlphabetical => 'Alfabético';
  @override
  String get tallySortFirstSeen => 'Segundo a lista';
  @override
  String get tallyInsert => 'Inserir';
  @override
  String get tallyUpdate => 'Actualizar';
  @override
  String get tallyNothingToCount => 'Aquí non hai nada que contar';
  @override
  String get headingDialogTitle => 'Nivel do título';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Barra de ferramentas do editor';
  @override
  String get toolbarSettingsHint =>
      'Arrastra para cambiar a orde; o ollo mostra ou oculta un botón.';
  @override
  String get toolbarShowButton => 'Mostrar';
  @override
  String get toolbarHideButton => 'Ocultar';
  @override
  String get toolbarResetOrder => 'Restaurar o predeterminado';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Mostrar a previsualización';
  @override
  String get showEditorTooltip => 'Mostrar o editor';
  // Raw-HTML table fallback.

  // Search (T-M3-05).
  @override
  String get searchHint => 'Buscar nas notas';
  @override
  String get searchModeWords => 'Palabras';
  @override
  String get searchModeContains => 'Contén';
  @override
  String get searchEmptyHint =>
      'Escribe para buscar na biblioteca, ou clave = valor para filtrar '
      'por frontmatter';
  @override
  String get searchTooShortHint => 'Escribe como mínimo 2 caracteres';
  @override
  String get searchNoMatches => 'Sen coincidencias';
  @override
  String get searchLoadMore => 'Mostrar máis';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Substituír…';
  @override
  String get replaceInNoteAction => 'Substituír nesta nota…';
  @override
  String get replaceInThisNote => 'Substituír nesta nota';
  @override
  String get replaceWithLabel => 'Substituír por';
  @override
  String get replaceCaseSensitive => 'Sensibilidade a maiúsculas/minúsculas';
  @override
  String get replaceWholeWordsHint =>
      'só se substitúen as coincidencias exactas de palabras completas';
  @override
  String get replaceConfirm => 'Substituír';
  @override
  String get replaceCancel => 'Pechar';
  @override
  String get replaceUnavailable => 'A substitución non está dispoñible agora';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Buscar na nota';
  @override
  String get editorFindHint => 'Buscar';
  @override
  String get editorReplaceHint => 'Substituír';
  @override
  String get editorFindCaseTooltip => 'Sensibilidade a maiúsculas/minúsculas';
  @override
  String get editorFindPreviousTooltip => 'Coincidencia anterior';
  @override
  String get editorFindNextTooltip => 'Coincidencia seguinte';
  @override
  String get editorFindCloseTooltip => 'Pechar a busca';
  @override
  String get editorFindReplaceModeTooltip => 'Modo de substitución';
  @override
  String get editorReplaceOneTooltip => 'Substituír esta coincidencia';
  @override
  String get editorReplaceAllTooltip => 'Substituír todas as coincidencias';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etiquetas';
  @override
  String get tagsTitle => 'Etiquetas';
  @override
  String get tagsEmpty =>
      'Aínda non hai etiquetas — engade unha #etiqueta ou etiquetas no '
      'frontmatter';
  @override
  String get tagsBackTooltip => 'Volver á busca';
  @override
  String get tagsNotesEmpty => 'Non hai notas con esta etiqueta';
  @override
  String tagsNotesCapped(int limit) =>
      'Só se mostran as primeiras $limit — busca a etiqueta para limitar';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Non se encontrou o enlace';
  @override
  String get headingNotFoundTitle => 'Non se encontrou o título';
  @override
  String get ambiguousLinkTitle => 'Varias notas coinciden';
  @override
  String get openLinkFailed => 'Non se puido abrir o enlace';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'A nota non existe';
  @override
  String missingNoteDialogBody(String path) => 'Crear «$path»?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'O cartafol «$folder» non existe';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Abertas';
  @override
  String get todoDone => 'Feitas';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Todas as datas';
  @override
  String get todoFilter => 'Filtrar';
  @override
  String get todoNoTokens => 'Sen tokens nesta lista';
  @override
  String get todoCountOpen => 'abertas';
  @override
  String get todoCountDone => 'feitas';
  @override
  String get todoEmptyOpen => 'Aínda non hai tarefas abertas';
  @override
  String get todoEmptyDone => 'Aínda nada feito';
  @override
  String get todoEmptyFiltered => 'Ningunha tarefa coincide';
  @override
  String get todoTitle => 'Por facer';
  @override
  String get todoAddTooltip => 'Engadir tarefa';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'O formato todo.txt';
  @override
  String get todoHelpTooltip => 'Información do formato';
  @override
  String get todoHelpIntro =>
      'As túas tarefas son un ficheiro de texto normal, unha tarefa por '
      'liña. Niman escribe a sintaxe por ti, pero nada se oculta: podes '
      'editar o ficheiro en calquera editor e Niman volta a lêlo.';
  @override
  String get todoHelpFilesTitle => 'Os dous ficheiros';
  @override
  String get todoHelpFilesBody =>
      'As tarefas abertas viven en todo.txt na raíz da biblioteca. '
      'Completa unha e a liña móvese a done.txt, así todo.txt mantense '
      'curto. Se unha liña completada volta a caer en todo.txt, Niman '
      'arxiva na próxima vez que lea os ficheiros.';
  @override
  String get todoHelpLineTitle => 'A anatomía dunha liña';
  @override
  String get todoHelpLineBody =>
      'Todo antes da descrición é opcional e debe vir nesta orde:';
  @override
  String get todoHelpDoneBody =>
      'Marca a tarefa como feita. Niman engádela cando marcas a caixa de '
      'verificación.';
  @override
  String get todoHelpPriority => '(A) a (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioridade. A é a máis alta. Muéstrase como insignia na lista.';
  @override
  String get todoHelpDatesBody =>
      'A data de completado e despois a data de creación. Con só unha '
      'data, é a data de creación, salvo que a liña comece con x.';
  @override
  String get todoHelpTokensTitle => 'Proxectos, contextos e etiquetas';
  @override
  String get todoHelpTokensBody =>
      'En toda a descrición, unha palabra con calquera destes prefíxos '
      'convértese nunha pastilla que se pode filtrar. Nada está '
      'predefinido: un token existe en tanto o escribes.';
  @override
  String get todoHelpProjectBody =>
      'O que a tarefa pertence, por exemplo +cociña ou +traballo.';
  @override
  String get todoHelpContextBody =>
      'Onde ou como a fas, por exemplo @casa ou @reunións.';
  @override
  String get todoHelpHashtagBody =>
      'Unha etiqueta libre, para todo o que non cubren as outras dúas.';
  @override
  String get todoHelpTagsTitle => 'Datas e lembranzas';
  @override
  String get todoHelpTagsBody =>
      'Estas son etiquetas clave:valor. Niman escríbeas desde o diálogo '
      'de tarefas e léas onde aparezan na liña.';
  @override
  String get todoHelpDueBody =>
      'O prazo. Controla a insignia de cor e os filtros de data.';
  @override
  String get todoHelpRemBody =>
      'Cando se debe enviar unha notificación, no teu horario local. '
      'Dispara cando a pantalla está apagada e a app pechada.';
  @override
  String get todoHelpRemDesktop =>
      'No escritorio, Niman debe estar en execución cando chegue a '
      'hora: a lembranza muéstrase mentres a app está aberta e nada '
      'dispara cando está pechada.';
  @override
  String get todoHelpOtherBody =>
      'Conservado exactamente como está escrito, para que as etiquetas '
      'doutros apps de todo.txt sobrevivan unha viaxe. Niman non actúa '
      'sobre elas, rec: included: unha tarefa recorrente non se repite '
      'aínda.';
  @override
  String get todoHelpEditTitle => 'Edición fóra de Niman';
  @override
  String get todoHelpEditBody =>
      'Unha tarefa que non tocaste escríbese de novo byte a byte, '
      'espazos extraños incluídos. Edita unha liña e Niman reescribe '
      'xusto esa liña no seu formato canónico e deixa o resto do '
      'ficheiro intacto.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Engadir tarefa';
  @override
  String get todoEditTitle => 'Editar tarefa';
  @override
  String get todoDescriptionHint => 'Descrición';
  @override
  String get todoCancel => 'Cancelar';
  @override
  String get todoSave => 'Gardar';
  @override
  String get todoEditAction => 'Editar';
  @override
  String get todoDeleteAction => 'Borrar';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Atrasada';
  @override
  String get todoDueToday => 'Hoxe';
  @override
  String get todoDueNext7 => 'Próximos 7 días';
  @override
  String get todoDueNoDate => 'Sen data';
  @override
  String get todoRowDue => 'Caduca';
  @override
  String get todoRowDueToday => 'Caduca hoxe';
  @override
  String get todoSortTooltip => 'Ordenar';
  @override
  String get todoSortDue => 'Data límite';
  @override
  String get todoSortPriority => 'Prioridade';
  @override
  String get todoSortCreation => 'Data de creación';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriorityShort => 'Ninguna';
  @override
  String get todoMorePriorities => 'Máis…';
  @override
  String get todoPriorityTitle => 'Prioridade';
  @override
  String get todoNoDueDate => 'Sen data límite';
  @override
  String get todoNoReminder => 'Sen lembranza';
  @override
  String get todoAddProject => '+ Proxecto';
  @override
  String get todoAddContext => '@ Contexto';
  @override
  String get todoAddHashtag => '# Etiqueta';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Lembranzas de tarefas';
  @override
  String get todoReminderChannelDescription =>
      'Notificacións programadas para tarefas con hora de lembranza.';
  @override
  String get todoReminderBody => 'Lembranza de tarefa';
  @override
  String get todoReminderFallbackTitle => 'Lembranza de tarefa';
  @override
  String get todoReminderBlocked =>
      'As notificacións están desactivadas, polo que as lembranzas non '
      'se mostran.';
  @override
  String get todoReminderBattery =>
      'A optimización de batería está activada para Niman. O sistema '
      'pode poñer a app en suspensión e perder lembranzas pendentes.';
  @override
  String get todoReminderInexact =>
      'Este dispositivo non permite alarmas exactas, polo que unha '
      'lembanza pode chegar uns minutos máis tarde cando a pantalla está '
      'apagada.';
  @override
  String get reminderShowTokensTitle =>
      'Etiquetas nas notificacións de lembranza';
  @override
  String get reminderShowTokensSubtitle =>
      'Mantén +proxecto, @contexto e #etiqueta no texto da '
      'notificación. Desactivado só mostra a tarefa que escribiches.';
  @override
  String get todoReminderFixAction => 'Abrir a configuración';
  @override
  String get todoReminderDismissAction => 'Descartar';
  @override
  String get todoReminderDue => 'Caducidade';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'De acordo';
  @override
  String get actionCancel => 'Cancelar';
  @override
  String get actionDownload => 'Descargar';
  @override
  String get actionCreate => 'Crear';
  @override
  String get actionNew => 'Nova';
  @override
  String get actionSave => 'Gardar';
  @override
  String get actionClear => 'Limpar';
  @override
  String get actionChoose => 'Escoller';
  @override
  String get actionDelete => 'Borrar';
  @override
  String get actionRename => 'Cambiar o nome';
  @override
  String get renameNameInvalid =>
      'O nome contén un carácter que o sistema de ficheiros rexeita.';
  @override
  String renameNameTaken(String name) => 'Este cartafol xa ten «$name».';
  @override
  String get actionMove => 'Mover';
  @override
  String get saveAndClose => 'Gardar e pechar';
  @override
  String get closeUnsavedTitle => 'Cambios sen gardar';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” ten cambios aínda non gardados. '
          'Gardalos antes de pechar?';
    }
    return '${names.length} notas teñen cambios aínda non gardados. '
        'Gardalos antes de pechar?';
  }

  @override
  String get closeSaveFailed => 'Non se puido gardar; segue aberta.';
  @override
  String get actionRestore => 'Restaurar';
  @override
  String get actionEmpty => 'Limpar';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ocultar o panel lateral';
  @override
  String get showSidebarTooltip => 'Mostrar o panel lateral';
  @override
  String get windowMinimizeTooltip => 'Minimizar';
  @override
  String get windowMaximizeTooltip => 'Maximizar';
  @override
  String get windowRestoreTooltip => 'Restaurar';
  @override
  String get windowCloseTooltip => 'Pechar';
  @override
  String get tabFiles => 'Ficheiros';
  @override
  String get tabSearch => 'Buscar';
  @override
  String get tabSettings => 'Configuración';
  @override
  String get quickNoteTitle => 'Nota rápida';
  @override
  String get treeEmpty => 'Aínda non hai notas';
  @override
  String get selectANote => 'Escoller unha nota';
  @override
  String get showListTooltip => 'Mostrar a lista';
  @override
  String get editRawTooltip => 'Editar a bruto';
  @override
  String get sortAscTooltip => 'Ordenar A-Z';
  @override
  String get sortDescTooltip => 'Ordenar Z-A';
  @override
  String get newNoteTitle => 'Nota nova';
  @override
  String get newItemTooltip => 'Novo';
  @override
  String get closeMenuTooltip => 'Pechar';
  @override
  String get shellActionFailed => 'Non se puido rematar a acción';
  @override
  String get newFolderTitle => 'Cartafol novo';
  @override
  String get newNoteSameFolder => 'Nova nota no mesmo cartafol';
  @override
  String get newFromTemplateSameFolder => 'Nova desde modelo no mesmo cartafol';
  @override
  String trashOriginalPath(String path) => 'estaba en $path';
  @override
  String get trashOriginalRoot => 'estaba na ra\u00edz da biblioteca';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 elemento' : '$count elementos';
  @override
  String get newNoteHere => 'Nota nova aquí';
  @override
  String get newFolderHere => 'Cartafol novo aquí';
  @override
  String get newListNoteTitle => 'Nota de lista nova';
  @override
  String get newListNoteDefault => 'A miña lista';
  @override
  String get setAsQuickNote => 'Establecer como nota rápida';
  @override
  String get currentQuickNote => 'Nota rápida actual';
  @override
  String pinnedSectionCount(int count) => 'Fixadas · $count';
  @override
  String get templateFolderTitle => 'Cartafol de plantillas';
  @override
  String get newFromTemplateTitle => 'Nova desde unha plantilla';
  @override
  String get newFromTemplateHere => 'Nova desde unha plantilla aquí';
  @override
  String get templateOpenFailed => 'Non se puido abrir o modelo';
  @override
  String get templateFormTitle => 'Encher a plantilla';
  @override
  String get templateFormBacklink => 'Enlazado desde';
  @override
  String get templateFormNoNote => 'Sen nota';
  @override
  String get templateFormPickNote => 'Escoller a nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Marcapases da plantilla';
  @override
  String get templateHelpSubtitle =>
      'Data, título e os demais valores por cubrir';
  @override
  String get quickNoteSubtitle => 'A nota que abre a pestana Nota rápida';
  @override
  String get listFolderSubtitle => 'As listas novas de tarefas';
  @override
  String get templateFolderSubtitle => 'A orixe de «Nova desde modelo»';
  @override
  String get attachmentsFolderSubtitle => 'Imaxes e audio inseridos nunha nota';
  @override
  String get templateHelpIntro =>
      'Unha plantilla é unha nota normal con furados. Crear unha nota '
      'desde ela copia o texto e enche os furados.';
  @override
  String get templateHelpUnknown =>
      'Un marcapase que Niman non coñece consérvase exactamente como '
      'está escrito, polo que un erro ortográfico aparece na nota en '
      'vez de romper silenciosamente unha liña.';
  @override
  String get templateHelpValuesTitle => 'Valores';
  @override
  String get templateHelpTitleBody => 'O nome co que se debe crear a nota.';
  @override
  String get templateHelpDateBody =>
      'Hoxe, e a hora actual. Ambos aceptan un formato: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data e hora xuntas.';
  @override
  String get templateHelpUuidBody =>
      'Un identificador novo, un diferente por aparición.';
  @override
  String get templateHelpCounterBody =>
      'Un número que conta por nome, conservado entre reinicios: a '
      'primeira nota escribe 1, a seguinte 2. O mesmo nome nunha nota '
      'escribe o mesmo número; combínalo con |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Pon o cursor aquí cando se crea a nota; o marcador non se escribe. '
      'O primeiro marcador gaña, sen filtros, só notas novas — e o '
      'teclado ábrese tamén co enfoque automático desactivado.';
  @override
  String get templateHelpDatesTitle => 'Escribir unha data';
  @override
  String get templateHelpDatesBody =>
      'Estes representan partes da data nun formato. Todo o que non é '
      'iso é literal, e o texto entre comiñas simples é literal tamén. '
      'Os nomes de mes e de día da semana seguen o idioma da app.';
  @override
  String get templateHelpYear => 'o ano: 2026, 26';
  @override
  String get templateHelpMonth => 'o mes: 03, 3, marzo, mar';
  @override
  String get templateHelpDay => 'o día: 09, 9, luns, lu';
  @override
  String get templateHelpTime => 'horas, minutos, segundos';
  @override
  String get templateHelpWeek => 'a semana ISO e o trimestre: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtros';
  @override
  String get templateHelpFiltersBody =>
      'Un valor pode ir seguido de filtros, aplicados da esquerda á '
      'dereita.';
  @override
  String get templateHelpCaseBody =>
      'Maiúsculas, minúsculas, e a primeira letra de cada palabra — unha '
      'palabra que ti escribiches con inicial en maiúscula non se toca.';
  @override
  String get templateHelpSlugBody =>
      'A forma de enlace do texto, para construir un enlace wiki.';
  @override
  String get templateHelpPadBody =>
      'Recorta as pontas; enche de ceros ata un ancho; usa unha '
      'alternativa cando o valor está baleiro.';
  @override
  String get templateHelpShiftBody =>
      'Mover unha data por días, semanas, meses ou anos — a '
      'conferencia da semana que vén, o ficheiro do mes pasado.';
  @override
  String get templateHelpSnapBody =>
      'Fixar unha data ao comezo ou final da semana, do mes ou do ano.';
  @override
  String get templateHelpAskTitle => 'Preguntarte algo';
  @override
  String get templateHelpAskBody =>
      'Un formulario muéstrase antes de crear a nota, un campo por '
      'pregunta — e un para o enlace inverso, cando a plantilla queira. '
      'A mesma etiqueta dúas veces é unha pregunta, e a súa resposta '
      'enche todas as aparicións — o cartafol e o nome de ficheiro '
      'incluídos.';
  @override
  String get templateHelpAskFieldBody =>
      'Un campo para escribir; o texto despois do segundo punto e coma '
      'é como comeza.';
  @override
  String get templateHelpChoiceBody =>
      'Unha selección dunha lista, separada por comas.';
  @override
  String get templateHelpWhereTitle => 'Onde cae a nota';
  @override
  String get templateHelpWhereBody =>
      'Estas non son texto: son instrucións, e viven nun bloque niman: no '
      'propio frontmatter da plantilla. O bloque execútase e elimínase '
      'despois, polo que nunca se mostra na nota. O seu valor pode '
      'contener marcapases.';
  @override
  String get templateHelpFolderBody =>
      'O cartafol onde se crea a nota, creado se non existe. Sen iso, a '
      'nota cae onde estabas.';
  @override
  String get templateHelpFilenameBody =>
      'Que se chama a nota. Unha plantilla que di iso non se lle pide '
      'un nome.';
  @override
  String get templateHelpAppendBody =>
      'Engadir á nota se xa está, en vez de crear outra. Iso é o que fai '
      'que un mes de reunións sexa un só ficheiro.';
  @override
  String get templateHelpOpenBody =>
      'Que pasa cando a nota existe: o editor (predeterminado), a '
      'previsualización, ou nada — a nota archívase e quedas onde '
      'estabas.';
  @override
  String get templateHelpAroundTitle => 'Donde veu';
  @override
  String get templateHelpParentBody =>
      'Unha nota que escolles no formulario, que se ofrece na pantalla; '
      'escribe [[{{parent}}]] para un enlace de volta.';
  @override
  String get templateHelpFolderValueBody => 'O cartafol onde caeu a nota.';
  @override
  String get templateHelpClipboardBody =>
      'Que hai no portapapeis, e a selección do editor cando a nota '
      'comezou desde unha.';
  @override
  String get templateHelpIncludeTitle => 'Reutilizar unha parte';
  @override
  String get templateHelpIncludeBody =>
      'Pega outra plantilla, de maneira que dez plantillas poidan '
      'compartir unha lista de verificación. Búscase primeiro no '
      'cartafol de plantillas, e .md pódese omitir. As súas propias '
      'preguntas entran no mesmo formulario.';
  @override
  String get templateHelpExampleTitle => 'Todo xunto';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ non hai plantilla “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” inclúese a si mesma';
  @override
  String includeTooDeep(String path) => '⚠ “$path” está demasiado anidada';
  @override
  String get frontmatterTitle => 'Propiedades';
  @override
  String get frontmatterPanelTitle => 'Panel de propiedades';
  @override
  String get frontmatterPanelSubtitle =>
      'Amosa as propiedades da nota enriba. Pechado ata que o abras, '
      'e retírase ao desprazarte.';
  @override
  String get frontmatterShowRaw => 'YAML en bruto';
  @override
  String get frontmatterShowFields => 'Campos';
  @override
  String get frontmatterAddField => 'Engadir unha propiedade';
  @override
  String get frontmatterNewField => 'Propiedade nova';
  @override
  String get frontmatterEditField => 'Editar a propiedade';
  @override
  String get frontmatterKeyLabel => 'Clave';
  @override
  String get frontmatterValueLabel => 'Valor';
  @override
  String get frontmatterTypeLabel => 'Tipo';
  @override
  String get frontmatterListHint => 'Separa os elementos con comas';
  @override
  String get frontmatterRemoveField => 'Quitar a propiedade';
  @override
  String get frontmatterNoFields => 'Non hai propiedades';
  @override
  String get frontmatterTypeText => 'texto';
  @override
  String get frontmatterTypeNumber => 'número';
  @override
  String get frontmatterTypeDate => 'data';
  @override
  String get frontmatterTypeBoolean => 'booleano';
  @override
  String get frontmatterTypeList => 'lista';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter non lido: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'O frontmatter de “$template” non se puido ler, polo que o '
      'cartafol e o nome de ficheiro non fixeron nada: $reason';
  @override
  String get templatePickerTitle => 'Escoller unha plantilla';
  @override
  String templatePickerEmpty(String folder) =>
      'Aínda non hai plantillas. Pón unha nota en $folder/ e será unha.';

  // Tree actions.
  @override
  String get actionPin => 'Fixar';
  @override
  String get actionUnpin => 'Desfacer';
  @override
  String get pinToWidget => 'Fixar no widget da pantalla de inicio';
  @override
  String get pinnedForWidget =>
      'Fixado: agora coloca o widget de Nota na pantalla de inicio';
  @override
  String get pinWidgetUnavailable =>
      'Os widgets da pantalla de inicio están dispoñibles en Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Amosar no xestor de ficheiros';
  @override
  String get openInDefaultApp => 'Abrir coa aplicación predeterminada';
  @override
  String get newNoteTabTooltip => 'Nota nova nunha lapela nova';
  @override
  String get openNotesTooltip => 'Notas abertas';
  @override
  String get closeTabTooltip => 'Pechar';
  @override
  String get openInNewTab => 'Abrir nunha lapela nova';
  @override
  String get splitRight => 'Dividir á dereita';
  @override
  String get splitDown => 'Dividir abaixo';
  @override
  String get moveToOtherPane => 'Mover ao outro panel';
  @override
  String get openBeside => 'Abrir ao lado';
  @override
  String get closeAllNotes => 'Pechar todas';
  @override
  String get sidePanelTooltip => 'Amosar ou agochar o panel lateral';
  @override
  String get historyAllVersions => 'Todas as versións';
  @override
  String get commandPaletteTitle => 'Paleta de ordes';
  @override
  String get goToNoteTitle => 'Ir á nota';
  @override
  String get paletteGroupNote => 'Nota';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Vista';
  @override
  String get paletteGroupLibrary => 'Biblioteca';
  @override
  String get paletteGroupGoTo => 'Ir a';
  @override
  String get paletteGroupJournal => 'Diario';
  @override
  String get journalToday => 'Entrada de hoxe';
  @override
  String get journalPrevious => 'Entrada anterior';
  @override
  String get journalNext => 'Entrada seguinte';
  @override
  String get commandNeedJournalEntry =>
      'Precisa dunha entrada do diario aberta';
  @override
  String journalCreateAsk(String day) =>
      'Aínda non hai entrada para $day. Creala?';
  @override
  String journalTemplateMissing(String path) =>
      'Non se puido ler o modelo do diario $path: a entrada creouse sen el.';
  @override
  String get journalIntro =>
      'Unha nota ao día, creada a partir dun modelo a primeira vez que abres '
      'ese día. Estes axustes viaxan coa biblioteca.';
  @override
  String get journalFolderTitle => 'Cartafol do diario';
  @override
  String get journalFolderSubtitle => 'Onde van as entradas';
  @override
  String get journalEntryNameTitle => 'Nome da entrada';
  @override
  String get journalEntryNameSubtitle =>
      "YYYY, MM ou M, DD ou D para a data; / crea un cartafol; o texto 'entre "
      "comiñas' queda tal cal";
  @override
  String journalEntryNamePreview(String path) => 'Entrada de hoxe: $path';
  @override
  String get journalEntryNameInvalid =>
      'Precisa YYYY, un mes (MM ou M) e un día (DD ou D), e nada que un nome '
      'de ficheiro non poida conter';
  @override
  String get journalTemplateTitle => 'Modelo';
  @override
  String get journalTemplateSubtitle => 'Con que comeza unha entrada nova';
  @override
  String get journalTemplateNone => 'Ningún: un título coa data';
  @override
  String get journalDayStartTitle => 'Un novo día comeza ás';
  @override
  String get journalDayStartSubtitle =>
      'Deitaste tarde? Ás 04:00 a noite queda no día anterior';
  @override
  String get journalRecent => 'Recentes';
  @override
  String get journalNoEntry => 'Non hai entrada para este día';
  @override
  String get journalOpenEntry => 'Abrir';
  @override
  String get journalShowCalendar => 'Amosar o calendario';
  @override
  String get journalFabToday => 'Entrada de hoxe do diario';
  @override
  String journalDueOn(String day) => 'Vence o $day';
  @override
  String get commandsTitle => 'Ordes';
  @override
  String get commandsIntro =>
      'A paleta de ordes só ofrece as ordes que se poden executar onde estás. '
      'Aquí están todas, e cando aparece cada unha.';
  @override
  String get commandsKeysNote =>
      'Aquí non se cambia nada. As teclas son as definidas en Atallos de '
      'teclado e seguen calquera cambio feito alí.';
  @override
  String get commandsOpenShortcuts => 'Cambiar as teclas en Atallos de teclado';
  @override
  String get commandsChangeKeyTooltip => 'Cambiar en Atallos de teclado';
  @override
  String get commandsSubtitle =>
      'O que pode executar a paleta de comandos, e cando';
  @override
  String get keyboardShortcutsSubtitle => 'Cambia as teclas de cada comando';
  @override
  String get commandNeedNone => 'Sempre dispoñible';
  @override
  String get commandNeedOpenNote => 'Precisa unha nota aberta';
  @override
  String get commandNeedTextNote => 'Precisa unha nota de texto aberta';
  @override
  String get commandNeedWideWindow => 'Só con xanela ancha';
  @override
  String get commandNeedDockRoom =>
      'Precisa unha xanela o bastante ancha para o panel lateral';
  @override
  String get commandNeedDesktop => 'Só no escritorio';
  @override
  String get commandNeedNotInZen => 'Fóra do modo Zen';
  @override
  String get commandNeedZenRoom => 'Escritorio, cunha nota aberta nunha lapela';
  @override
  String get commandNeedPreview =>
      'Coa vista previa activada, nunha nota de texto';
  @override
  String get commandNeedTwoEditors => 'Cos dous editores activados';
  @override
  String get paletteHint => 'Buscar ordes e notas';
  @override
  String get paletteNoResults => 'Sen coincidencias';
  @override
  String get paletteCommands => 'Ordes';
  @override
  String get paletteNotes => 'Notas';
  @override
  String get paletteFooter => '↑↓ para moverte · ↵ para usar · esc para pechar';
  @override
  String get paletteFooterTouch =>
      'Toca para usar · o alfinete mantéeno arriba';
  @override
  String get palettePinned => 'Fixados';
  @override
  String get palettePin => 'Fixar';
  @override
  String get paletteUnpin => 'Quitar';
  @override
  String get palettePinFooter => 'alt+P para fixar';
  @override
  String get spellCheckScanning => 'Revisando a nota…';
  @override
  String get spellCheckAgain => 'Revisar de novo';
  @override
  String spellCheckCapped(int count) =>
      'Móstranse os primeiros $count: corrixe algúns e revisa de novo para '
      'ver o resto';
  @override
  String get dropHint =>
      'Solta ficheiros Markdown para abrilos, ou un cartafol para importalo';
  @override
  String get dropNothing =>
      'O escritorio non entregou ningún ficheiro nese arrastre.';
  @override
  String get importFolderAction => 'Importar';
  @override
  String get notionImportTitle => 'Importar exportación de Notion';
  @override
  String get notionImportFailed =>
      'Non se puido importar a exportación de Notion';
  @override
  String dropRejected(String names) =>
      'Aquí só se abren ficheiros Markdown e cartafoles: $names';
  @override
  String importFolderTitle(String name) => 'Importar «$name»?';
  @override
  String importFolderBody(int count) =>
      'Os seus ficheiros Markdown ($count) cópianse nun cartafol novo da '
      'biblioteca. O cartafol que soltaches queda como está.';
  @override
  String importFolderDone(String folder) => 'Importado en $folder';
  @override
  String importFolderEmpty(String name) =>
      'Non hai ficheiros Markdown en $name';
  @override
  String get openFileTitle => 'Abrir ficheiro';
  @override
  String get outsideFileNote =>
      'Fóra de toda biblioteca: gárdase onde está, sen índice, sen '
      'historial, as ligazóns non se seguen';
  @override
  String get typewriterOn => 'Activar o modo máquina de escribir';
  @override
  String get typewriterOff => 'Desactivar o modo máquina de escribir';
  @override
  String get typewriterTitle => 'Modo máquina de escribir';
  @override
  String get formatNoteTitle => 'Arranxar o Markdown';
  @override
  String get formatNoteDone => 'A nota arranxouse.';
  @override
  String get exportTitle => 'Exportar';
  @override
  String get exportFormatMarkdown => 'Markdown';
  @override
  String get exportFormatHtml => 'HTML';
  @override
  String exportDone(String place) => 'Exportado a $place';
  @override
  String exportFailed(Object error) => 'A exportación fallou: $error';
  @override
  String get exportFolderTitle => 'Exportar o cartafol…';
  @override
  String get exportLibraryTitle => 'Exportar a biblioteca…';
  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatEpub => 'EPUB';

  @override
  String get exportEpubNoMetadataTitle => 'Libro sen metadatos';
  @override
  String get exportEpubNoIndex =>
      'Este cartafol non ten ningún index.md na súa raíz. O libro '
      'levará o nome do cartafol e ningún autor, portada ou serie.';
  @override
  String get exportEpubNoFrontmatter =>
      'index.md non ten frontmatter. O libro levará o nome do cartafol '
      'e ningún autor, portada ou serie.';
  @override
  String get exportAnyway => 'Exportar de todos os xeitos';
  @override
  String get exportPdfPicture =>
      'O PDF é unha imaxe das páxinas; instala un navegador para ter texto '
      'seleccionable.';

  @override
  String exportPdfEngineFailed(Object reason) =>
      'O motor de PDF fallou ($reason): a nota debuxouse como unha '
      'imaxe.';

  @override
  String get exportPdfNoEngineTitle => 'PDF como imaxe';

  @override
  String get exportPdfNoEngine =>
      'Non se atopou ningún navegador nesta máquina. A nota '
      'debúxase como unha imaxe das páxinas: o texto non se pode '
      'seleccionar nin buscar, e unha nota longa tarda máis.';
  @override
  String get formatNoteAlreadyTidy => 'A nota xa estaba arranxada.';
  @override
  String get lintRulesTitle => 'Regras de Markdown';
  @override
  String get lintRulesSubtitle =>
      'O que axeita o axuste: liñas baleiras nas listas, caixas de tarefa, '
      'espazos tras o marcador e bloques de código.';
  @override
  String get lintRulesReset => 'Restaurar os valores predeterminados';
  @override
  String lintRulesValue(int on, int all) =>
      on >= all ? 'Todas $all' : '$on de $all';
  @override
  String get lintRuleTightLists => 'Listas compactas';
  @override
  String get lintRuleTaskMarker => 'Caixas de tarefa';
  @override
  String get lintRuleListSpacing => 'Espazado de listas';
  @override
  String get lintRuleClosingFence => 'Pechadura do bloque de código';
  @override
  String get lintRuleFenceLanguage => 'Linguaxe do bloque de código';
  @override
  String get lintRuleJoinWrappedItems => 'Unir elementos de lista partidos';
  @override
  String get lintRuleJoinParagraphLines => 'Unir parágrafos partidos';
  @override
  String get tidyOnCloseTitle => 'Arranxar o Markdown ao pechar';
  @override
  String get tidyOnCloseSubtitle =>
      'Cando pechas unha nota que editaches, o seu Markdown arránxase como '
      'coa orde «Arranxar o Markdown». As notas de máis de 4 MB quedan como '
      'están.';
  @override
  String get typewriterSubtitle =>
      'Mantén a liña que escribes no medio do editor';
  @override
  String get zenMode => 'Modo zen';
  @override
  String get zoomIn => 'Ampliar';
  @override
  String get zoomOut => 'Reducir';
  @override
  String get zoomReset => 'Restablecer o zoom';
  @override
  String get zenModeEnter => 'Entrar no modo zen';
  @override
  String get zenModeLeave => 'Saír do modo zen';
  @override
  String get keySpace => 'Espazo';
  @override
  String get keyEnter => 'Intro';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Retroceso';
  @override
  String get keyDelete => 'Supr';
  @override
  String get keyArrowUp => 'Arriba';
  @override
  String get keyArrowDown => 'Abaixo';
  @override
  String get keyArrowLeft => 'Esquerda';
  @override
  String get keyArrowRight => 'Dereita';
  @override
  String get keyHome => 'Inicio';
  @override
  String get keyEnd => 'Fin';
  @override
  String get keyPageUp => 'Re Páx';
  @override
  String get keyPageDown => 'Av Páx';
  @override
  String get keyInsert => 'Insert';
  @override
  String get shortcutNone => 'Sen atallo';
  @override
  String get shortcutRestoreDefaults => 'Restaurar predeterminados';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Volver poñer todos os atallos como os trae Niman?';
  @override
  String get shortcutRevert => 'Volver ao predeterminado';
  @override
  String get shortcutClear => 'Quitar o atallo';
  @override
  String get shortcutCapturePrompt =>
      'Preme as teclas. Esc e Tab tamén se capturan: sae con Cancelar.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Engade Ctrl, Alt ou Meta: unha tecla soa é para escribir.';
  @override
  String get shortcutMove => 'Movelo';
  @override
  String get shortcutUseAnyway => 'Usar igualmente';
  @override
  String get shortcutUndo => 'Desfacer';
  @override
  String get shortcutRedo => 'Refacer';
  @override
  String shortcutCaptureTitle(String command) => 'Teclas para $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys xa é de $other. Movelo aquí? $other quedará sen atallo.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys tamén é $what nos campos de texto e no editor. Alí collerao a '
      'túa orde.';
  @override
  String get openFileMissing => 'O ficheiro desta nota non está no disco';
  @override
  String get openFileFailed => 'Non foi posible abrir esta nota fóra do Niman';
  @override
  String get attachmentUnreadable => 'Non se puido mostrar este ficheiro.';
  @override
  String get attachmentMissing => 'Este ficheiro non está no disco.';
  @override
  String get attachmentOpenFailed =>
      'Non foi posible abrir este ficheiro fóra do Niman.';
  @override
  String get copyPlaceLink => 'Copiar a ligazón a este punto';
  @override
  String get placeLinkCopied => 'Ligazón copiada';
  @override
  String pdfPageLabel(String name, int page) => '$name, p. $page';
  @override
  String get annotationsFolderTitle => 'Cartafol das anotacións';
  @override
  String get annotationsFolderSubtitle => 'Notas que anotan un PDF ou un libro';
  @override
  String get captureFolderTitle => 'Cartafol das capturas web';
  @override
  String get captureFolderSubtitle =>
      'Páxinas web e citas capturadas como notas novas';
  @override
  String get annotationNoteSuffix => 'Anotación';
  @override
  String get annotateAction => 'Anotar';
  @override
  String get annotationCommentHint => 'O teu comentario';
  @override
  String get annotationSaved => 'Anotación gardada';
  @override
  String get annotationOpenNote => 'Abrir a nota';
  @override
  String get annotationFailed => 'Non se puido gardar a anotación';

  @override
  String get movedToTrash => 'Movida ao paperilleiro';
  @override
  String get deletedMessage => 'Borrado';
  @override
  String deleteForeverConfirm(String name) => '$name borraráse permanentemente';
  @override
  String get chooseDestination => 'Escoller o destino';
  @override
  String get libraryRoot => 'A raíz da biblioteca';
  @override
  String moveTitle(String name) => 'Mover $name';
  @override
  String headingLevelLabel(int level) => 'Título $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Aínda non hai nota rápida. Escolle unha nota existente ou crea '
      'una — a nota rápida abrirase aquí.';
  @override
  String get quickNoteChooseAction => 'Escoller unha nota…';
  @override
  String get quickNoteCreateAction => 'Crear unha nota nova…';
  @override
  String get quickNoteNewTitle => 'Nota rápida nova';
  @override
  String get quickNotePickerTitle => 'Escoller a nota rápida';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Cartafol novo';
  @override
  String get folderPickerEmpty => 'Aínda non hai cartafóis';
  @override
  String get listFolderTitle => 'Cartafol de lista';
  @override
  String get attachmentsFolderTitle => 'Cartafol de anexos';

  // Trash (M1).
  @override
  String get trashEmpty => 'O paperilleiro está baleiro';
  @override
  String get trashEmptyAction => 'Baleirar o paperilleiro';
  @override
  String get trashEmptyConfirm =>
      'Isto borra permanentemente todo o que hai no paperilleiro, '
      'incluídos os elementos que Niman non puxo.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name borraráse permanentemente (sen restauración)';
  @override
  String get trashDeletePermanently => 'Borrar permanentemente';
  @override
  String get trashActionFailed => 'Non se puido restaurar nin eliminar a nota';
  @override
  String get trashEmptyFailed => 'Non se puido baleirar o paperilleiro';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Abrir un cartafol de notas Markdown como biblioteca';
  @override
  String get openLibraryExisting => 'Abrir un existente';
  @override
  String get openLibraryCreate => 'Crear un novo';
  @override
  String get openLibraryCreateTitle => 'Crear unha biblioteca nova';
  @override
  String get openLibraryFolderName => 'Nome do cartafol';
  @override
  String get openLibraryChooseFolder => 'Escoller o cartafol da biblioteca';
  @override
  String get openLibraryChooseParent =>
      'Escoller o cartafol onde se creará a biblioteca';
  @override
  String get openLibraryUnsupported =>
      'Este cartafol non é compatible. Escolle un cartafol no '
      'almacenamento do dispositivo.';
  @override
  String indexingCount(int done, int total) => '$done de $total notas';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'As túas bibliotecas';
  @override
  String get libraryUnreachable => 'Inaccesible';
  @override
  String get libraryOpenedToday => 'Aberta hoxe';
  @override
  String get libraryOpenedYesterday => 'Aberta onte';
  @override
  String libraryOpenedDaysAgo(int days) => 'Aberta hai $days días';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Aberta ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Aberta agora';
  @override
  String get switchLibraryTitle => 'Cambiar a biblioteca';
  @override
  String get libraryForget => 'Esquecer';
  @override
  String libraryForgetTitle(String name) => 'Esquecer “$name”?';
  @override
  String get libraryForgetExplained =>
      'Desaparecerá desta lista. O cartafol, as notas e a configuración '
      'da biblioteca nela non se tocan, e abrila de novo ponla de '
      'volta.';

  @override
  String get libraryForgetOpenExplained =>
      'Esta biblioteca está aberta agora: primeiro péchase e despois sae da '
      'lista. O cartafol, as notas e os axustes da biblioteca que contén '
      'quedan intactos, e volver abrila tráea de volta.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dar acceso aos ficheiros';
  @override
  String get storageAccessNeeded =>
      'Niman non pode ler as túas notas sen “Acceso a todos os '
      'ficheiros”. Dállo para abrir unha biblioteca.';
  @override
  String get storageAccessExplained =>
      'Niman le as túas notas como ficheiros normais, polo que Android '
      'debe darlle acceso a todos os ficheiros. Non se envía nada, e só '
      'se le o cartafol de biblioteca que escolles.';
  @override
  String folderAccessDenied(Object error) =>
      'O sistema non deu acceso ao cartafol: $error';
  @override
  String folderPickFailed(Object error) =>
      'Non se puido escoller un cartafol: $error';

  // Settings screen rows and messages.
  @override
  String get libraryPathTitle => 'Camiño da biblioteca';
  @override
  String get reindexTitle => 'Reindexar agora';
  @override
  String get reindexDone => 'Reindexación completada';
  @override
  String get reindexFailed => 'Non se puido volver ler a biblioteca';
  @override
  String get closeLibraryTitle => 'Pechar a biblioteca';
  @override
  String get exportLogTitle => 'Exportar o rexistro de depuración';
  @override
  String get exportLogSubtitle =>
      'Gardar os acontecementos rexistrados nun ficheiro que escolles';
  @override
  String get exportLogEmpty => 'O búfer do rexistro de depuración está baleiro';
  @override
  String get quickNoteUnset => 'Aínda non está establecido';
  @override
  String exportLogDone(Object target) =>
      'Rexistro de depuración exportado a $target';
  @override
  String exportLogFailed(Object error) => 'A exportación fallou: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Non se encontrou coincidencia exacta de palabra completa para '
      '“$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Substituíronse $occurrences aparicións de “$term” en $notes '
      'notas';
  @override
  String replaceSkipped(int skipped) => ' ($skipped notas abertas omitidas)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Non se encontrou coincidencia exacta de palabra completa para '
      '“$term” ${only == null ? 'atopouse' : 'atopouse en $only'}';
  @override
  String get replaceScopeWholeLibrary => 'toda a biblioteca';
  @override
  String replaceScopeNote(String note) => 'en $note';
  @override
  String replaceScopeNotes(int count) =>
      count == 1 ? 'nunha nota' : 'en $count notas';
  @override
  String replaceWriteFailed(int count) => count == 1
      ? ' (1 nota non se puido escribir)'
      : ' ($count notas non se puideron escribir)';

  // About (issue #80).
  @override
  String get versionTitle => 'Versión';
  @override
  String get changelogTitle => 'Rexistro de cambios';
  @override
  String get changelogEmpty => 'Non hai entradas de rexistro dispoñibles';
  @override
  String changelogWhatsNew(String version) => 'Novidades na versión $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historial';
  @override
  String get noteMenuTooltip => 'Accións da nota';
  @override
  String get historyCurrentVersion => 'Versión actual';
  @override
  String get historyCurrentSubtitle => 'A nota tal como está agora';
  @override
  String get historyToday => 'Hoxe';
  @override
  String get historyYesterday => 'Onte';
  @override
  String get historyReasonSession => 'antes de editar';
  @override
  String get historyReasonInterval => 'durante a edición';
  @override
  String get historyReasonRestore => 'antes de restaurar';
  @override
  String get historyReasonSync => 'antes de sincronizar';
  @override
  String get historyReasonReplace => 'antes de substituír';
  @override
  String get historyReasonUnknown => 'recuperada';
  @override
  String get historySyncBase => 'base de sincronización';
  @override
  String get historyEmpty =>
      'Aínda non hai versións. Niman garda unha cando comezas a editar a '
      'nota e despois, como moito, unha cada poucos minutos mentres '
      'escribes.';
  @override
  String historyKept(int kept, int limit) => '$kept de $limit versións';
  @override
  String get historyBaseKept =>
      'A base de sincronización consérvase aínda que supere o límite.';
  @override
  String get historyOff =>
      'O historial está desactivado nesta biblioteca '
      '(Configuración, Paperilleiro e cronoloxía).';
  @override
  String get historyLoadFailed => 'Non se puido ler o historial';
  @override
  String get historyCompareSubtitle => 'Comparada coa versión actual';
  @override
  String get historyTabChanges => 'Cambios';
  @override
  String get historyTabVersion => 'Versión';
  @override
  String get historyNoChanges => 'O mesmo texto que a versión actual.';
  @override
  String get historyRestoreAction => 'Restaurar esta versión';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Restaurar a versión de $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Antes gárdase o texto actual no historial, así que sempre podes '
      'volver atrás.';
  @override
  String get historyRestoreConfirm => 'Restaurar';
  @override
  String historyRestored(String when) => 'Restaurouse a versión de $when';
  @override
  String get historyRestoreFailed => 'Non se puido restaurar a versión';
  @override
  String get actionUndo => 'Desfacer';
  @override
  String diffLineRange(int start, int end) => 'Liñas $start–$end';
  @override
  String diffLineSingle(int line) => 'Liña $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 liña sen cambios' : '$count liñas sen cambios';
  @override
  String get historyTakeHunk => 'Restaurar aquí';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Restaurar 1 cambio' : 'Restaurar $count cambios';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Os cambios escollidos volven ao texto desta versión. A nota tal como '
      'está agora consérvase antes como versión, así que podes desfacelo.';
  @override
  String get historyNoteChangedReloaded =>
      'A nota cambiou mentres estabas aquí: a comparación actualizouse.';
  @override
  String get historyVersionsTitle => 'Versións que conservar';
  @override
  String get historyVersionsSubtitle => 'Por nota, en .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Ningunha' : '$count';
  @override
  String get historyIntervalTitle => 'Nova versión como moito cada';
  @override
  String get historyIntervalSubtitle =>
      'Mentres escribes; comezar a editar unha nota sempre garda unha';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcrición';
  @override
  String get transcriptionModelTitle => 'Modelo';
  @override
  String get transcriptionModelNone => 'Ningún';
  @override
  String get transcriptionLanguageTitle => 'Idioma';
  @override
  String get transcriptionLanguageSubtitle =>
      'O idioma que se fala nas túas gravacións. Indicalo é máis preciso ca '
      'detectalo.';
  @override
  String transcriptionLanguageApp(String language) => 'Como a app ($language)';
  @override
  String get transcriptionLanguageDetect => 'Detectar automaticamente';
  @override
  String get transcriptionModelsTitle => 'Modelos de transcrición';
  @override
  String transcriptionModelsUsed(String size) => '$size en uso';
  @override
  String get transcriptionModelsInstalled => 'Descargados';
  @override
  String get transcriptionModelsDownloading => 'Descargando';
  @override
  String get transcriptionModelsAvailable => 'Dispoñibles';
  @override
  String get transcriptionModelsFooter =>
      'Os modelos quedan no almacenamento da app neste dispositivo. Non se '
      'copian na biblioteca nin se sincronizan.';
  @override
  String get transcriptionModelDefault => 'Predeterminado';
  @override
  String get transcriptionModelSlow => 'Lento';
  @override
  String get transcriptionModelHintTiny => 'O máis rápido, o menos preciso';
  @override
  String get transcriptionModelHintBase =>
      'Bo equilibrio entre velocidade e precisión';
  @override
  String get transcriptionModelHintSmall => 'Máis preciso, unhas 3× máis lento';
  @override
  String get transcriptionModelHintMedium => 'Moi preciso, lento nun teléfono';
  @override
  String get transcriptionModelHintLarge =>
      'O máis preciso, precisa moita memoria';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Eliminar o modelo $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Libera $size. Podes volver descargar o modelo máis adiante.';
  @override
  String get downloadFailed =>
      'Non se puido descargar. Comproba a conexión e téntao de novo.';
  @override
  String get actionRetry => 'Tentar de novo';
  @override
  String get decimalSeparator => ',';
  @override
  String get downloadRetrying => 'Perdeuse a conexión, tentando de novo…';
  @override
  String downloadPaused(String progress) => 'En pausa en $progress';
  @override
  String get actionResume => 'Retomar';
  @override
  String get audioTranscribe => 'Transcribir';
  @override
  String get audioTranscribeUnsupported =>
      'Só gravacións WAV neste dispositivo';
  @override
  String get transcriptionQueued => 'Na cola';
  @override
  String get transcriptionPreparing => 'Preparando o audio…';
  @override
  String transcriptionRunning(int percent) => 'Transcribindo… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Descargando $model · $percent %';
  @override
  String get transcriptionSaved => 'Transcrición engadida á descrición';
  @override
  String get transcriptionNoSpeech => 'Non se recoñeceu fala nesta gravación';
  @override
  String get transcriptionFailed => 'Non se puido transcribir';
  @override
  String get transcriptionPickModelTitle => 'Escolle un modelo';
  @override
  String get transcriptionPickModelBody =>
      'A transcrición faise neste dispositivo e a gravación nunca se envía. O '
      'modelo descárgase unha soa vez.';
  @override
  String get transcriptionPickModelAction => 'Descargar e transcribir';
  @override
  String get transcriptionModelRecommended => 'Recomendado';
  @override
  String get transcriptionExistingTitle =>
      'Esta gravación xa ten unha descrición';
  @override
  String get transcriptionExistingBody =>
      'Substituíla pola transcrición ou engadir a transcrición debaixo?';
  @override
  String get transcriptionAppend => 'Engadir debaixo';
  @override
  String get transcriptionReplace => 'Substituír';
  @override
  String get settingsSectionSync => 'Sincronización';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Non configurada para esta biblioteca';
  @override
  String get syncNeverSynced => 'Nunca sincronizada';
  @override
  String syncLastSynced(String when) => 'Sincronizada: $when';
  @override
  String get syncRunning => 'Sincronizando…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteca $library';
  @override
  String get syncUrlLabel => 'Enderezo do cartafol';
  @override
  String get syncUrlRequired => 'Introduza o enderezo do servidor';
  @override
  String get syncUrlHint =>
      'O cartafol debe existir. Copia o enderezo tal como o '
      'mostra o servidor.';
  @override
  String get syncHttpWarning =>
      'Conexión sen cifrar: vale nunha VPN ou na túa rede local.';
  @override
  String get syncUserLabel => 'Usuario';
  @override
  String get syncUserHint =>
      'Déixao baleiro se o servidor non pide credenciais.';
  @override
  String get syncPasswordLabel => 'Contrasinal';
  @override
  String get syncPasswordHint =>
      'Gárdase no chaveiro deste dispositivo, nunca nos '
      'ficheiros da biblioteca.';
  @override
  String get syncPasswordKeepHint =>
      'Déixao baleiro para manter o contrasinal gardado.';
  @override
  String get syncShowPassword => 'Mostrar o contrasinal';
  @override
  String get syncHidePassword => 'Ocultar o contrasinal';
  @override
  String get syncTestAction => 'Probar a conexión';
  @override
  String get syncTesting => 'Probando…';
  @override
  String get syncRetargetWarning =>
      'Cun enderezo ou usuario novo, a próxima sincronización '
      'comeza de novo como primeira sincronización.';
  @override
  String get syncTestOk => 'A conexión funciona';
  @override
  String get syncModeFull => 'Modo completo';
  @override
  String get syncModeCompatible => 'Modo compatible';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lectura, escritura e borrado';
  @override
  String get syncCapEtags => 'Pegadas dos ficheiros (ETag)';
  @override
  String get syncCapNoEtags => 'Sen pegadas dos ficheiros (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Comparo tamaño e data; se hai dúbida, descargo de novo';
  @override
  String get syncCapGuarded => 'Escrituras protexidas';
  @override
  String get syncCapUnguarded => 'Escrituras sen protección';
  @override
  String get syncCapUnguardedDetail =>
      'Comprobo o ficheiro no servidor xusto antes de escribir';
  @override
  String get syncCapMove => 'Cambios de nome sen volver subir';
  @override
  String get syncCapNoMove => 'Sen cambios de nome no servidor';
  @override
  String get syncCapNoMoveDetail =>
      'Un cambio de nome convértese nun borrado e nunha nova '
      'subida';
  @override
  String get syncCompatibleNote =>
      'No modo compatible a sincronización funciona igual, con '
      'algunhas peticións máis.';
  @override
  String get syncTestInvalidUrl => 'Non é un enderezo válido';
  @override
  String get syncTestInvalidUrlHint =>
      'Escribe un enderezo http:// ou https://, sen usuario nin '
      'contrasinal dentro.';
  @override
  String get syncTestOffline => 'Non se pode acceder ao servidor';
  @override
  String get syncTestOfflineHint =>
      'Está activa a VPN? Un enderezo 10.x ou 192.168.x só '
      'funciona desde a mesma rede.';
  @override
  String get syncTestAuth => 'Usuario ou contrasinal rexeitados';
  @override
  String get syncTestAuthHint => 'Revísaos e proba de novo.';
  @override
  String get syncTestNotFound => 'O cartafol non existe';
  @override
  String get syncTestNotFoundHint => 'Créao no servidor ou corrixe o enderezo.';
  @override
  String get syncTestUnsupported => 'Non é un cartafol WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'O servidor responde, pero non como WebDAV.';
  @override
  String get syncTestFailed => 'A proba non funcionou';
  @override
  String get syncTestCertificate => 'O certificado non é de confianza';
  @override
  String get syncTestCertificateHint =>
      'Non se pode verificar o certificado. Confía nel só se a súa pegada '
      'coincide coa que mostra o servidor.';
  @override
  String get syncCertTrustTitle => 'Confiar neste certificado?';
  @override
  String syncCertTrustBody(String host, String fingerprint) =>
      'Non se pode verificar o certificado de $host.\n\nPegada '
      'SHA-256:\n$fingerprint\n\nConfía nel só se é o certificado que '
      'esperas. Niman acepta só este certificado para este destino e '
      'ningún outro.';
  @override
  String get syncCertTrustAction => 'Confiar neste certificado';
  @override
  String get syncCertTrustedTitle => 'Certificado de confianza';
  @override
  String syncCertTrustedSubtitle(String fingerprint) => 'SHA-256 $fingerprint';
  @override
  String get syncCertForgetTitle => 'Esquecer este certificado?';
  @override
  String get syncCertForgetBody =>
      'Este destino volve probarse contra o almacén de certificados do '
      'dispositivo e haberá que confirmar unha vez máis un certificado '
      'autoasinado. Nada máis cambia.';
  @override
  String get syncCertForgetAction => 'Esquecer';
  @override
  String get syncNowAction => 'Sincronizar agora';
  @override
  String get syncSectionServer => 'Servidor';
  @override
  String get syncServerRow => 'Enderezo, usuario e contrasinal';
  @override
  String get syncRetestTitle => 'Probar de novo o servidor';
  @override
  String syncProbedAgo(String when) => 'Última proba: $when';
  @override
  String get syncDisconnectTitle => 'Desconectar esta biblioteca';
  @override
  String get syncDisconnectSubtitle => 'Os ficheiros quedan aquí e no servidor';
  @override
  String get syncDisconnectConfirmTitle => 'Desconectar a sincronización?';
  @override
  String get syncDisconnectConfirmBody =>
      'Esta biblioteca deixa de sincronizarse neste dispositivo. '
      'Non se borra ningún ficheiro, nin aquí nin no servidor. '
      'Se a volves conectar, a primeira sincronización comeza de '
      'novo.';
  @override
  String get syncDisconnectConfirm => 'Desconectar';
  @override
  String get syncFirstTitle => 'Primeira sincronización';
  @override
  String get syncFirstIntro => 'Comparei a biblioteca co cartafol do servidor:';
  @override
  String get syncFirstUpload => 'Para subir';
  @override
  String get syncFirstDownload => 'Para descargar';
  @override
  String get syncFirstBoth => 'Nos dous lados';
  @override
  String get syncFirstBothHint =>
      'Idénticos: sen transferencia. Diferentes: para resolver';
  @override
  String get syncFirstNoDelete =>
      'A primeira sincronización non borra nada, nin aquí nin no '
      'servidor.';
  @override
  String get syncStartAction => 'Comezar';
  @override
  String syncMassTrashTitle(int count) =>
      'Mover $count ficheiros ao paperilleiro?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Faltan no servidor $count dos $total ficheiros '
      'sincronizados. Adoita significar un enderezo incorrecto, '
      'un disco do NAS sen montar ou un cartafol baleirado por '
      'erro.';
  @override
  String get syncMassTrashHint =>
      'Se de verdade os borraches noutro dispositivo, confirma: '
      'aquí van ao paperilleiro.';
  @override
  String get syncMassTrashConfirm => 'Mover ao paperilleiro';
  @override
  String syncMassDeleteTitle(int count) =>
      'Borrar $count ficheiros do servidor?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Faltan aquí $count dos $total ficheiros sincronizados. Se '
      'non os borraches ti, cancela e revisa o cartafol da '
      'biblioteca.';
  @override
  String get syncMassDeleteConfirm => 'Borrar do servidor';
  @override
  String get syncTooltip => 'Sincronizar';
  @override
  String get syncStageConnecting => 'Conectando co servidor…';
  @override
  String get syncStageComparing => 'Comparando co servidor…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sincronizando · $done de $total';
  @override
  String get syncStatusWarnings => 'Sincronizada con avisos';
  @override
  String syncConflictsHeader(int count) =>
      'Modificados aquí e no servidor · $count';
  @override
  String get syncConflictHint => 'Non se tocou ningunha das dúas versións';
  @override
  String get syncResolveAction => 'Resolver';
  @override
  String syncFailuresHeader(int count) => 'Sen sincronizar · $count';
  @override
  String get syncFailuresHint => 'Tentaranse de novo na próxima sincronización';
  @override
  String get syncAbortAuth => 'O servidor rexeitou o contrasinal';
  @override
  String get syncAbortMissingPassword => 'Non hai ningún contrasinal gardado';
  @override
  String get syncAbortOffline => 'Non se pode acceder ao servidor';
  @override
  String get syncAbortRemoteMissing => 'O cartafol do servidor xa non está';
  @override
  String get syncAbortUnsupported => 'O servidor xa non funciona como WebDAV';
  @override
  String get syncAbortFailed => 'A sincronización non funcionou';
  @override
  String get syncAbortNotConfirmed => 'Sincronización cancelada';
  @override
  String get syncAbortNothingTouched =>
      'Non se tocou ningún ficheiro. Os teus cambios quedan aquí '
      'ata a próxima sincronización correcta.';
  @override
  String syncLastSuccess(String when) =>
      'Última sincronización correcta: $when';
  @override
  String get syncNoSuccessYet =>
      'Aínda non hai ningunha sincronización correcta';
  @override
  String get syncUpdatePasswordAction => 'Actualizar o contrasinal';
  @override
  String get syncRetryAction => 'Tentar de novo';
  @override
  String get syncOpenSettingsAction => 'Configuración';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sincronizada · 1 ficheiro borrado noutro lugar está no '
            'paperilleiro'
      : 'Sincronizada · $count ficheiros borrados noutro lugar '
            'están no paperilleiro';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sincronizada · 1 conflito por resolver'
      : 'Sincronizada · $count conflitos por resolver';
  @override
  String get syncShowAction => 'Mostrar';
  @override
  String get syncConflictTitle => 'Resolver o conflito';
  @override
  String get syncConflictBinary =>
      'Non é un ficheiro de texto: escolle que copia conservar.';
  @override
  String get syncConflictKeepNote =>
      'A copia que non conserves queda no historial da nota.';
  @override
  String get syncKeepLocal => 'Conservar a deste dispositivo';
  @override
  String get syncKeepRemote => 'Conservar a do servidor';
  @override
  String get syncConflictLoadFailed => 'Non se puideron ler as dúas versións';
  @override
  String get syncResolveFailed => 'Non se puido resolver o conflito';
  @override
  String get syncResolved => 'Conflito resolto';
  @override
  String get syncConflictMoved =>
      'Unha das versións cambiou mentres tanto: o conflito volveuse ler, '
      'escolle de novo.';
  @override
  String get syncSectionWhen => 'Cando sincronizar';
  @override
  String get syncAutoTitle => 'Automaticamente';
  @override
  String get syncAutoSubtitle => 'Tras os cambios, ao abrir e a intervalos';
  @override
  String get syncIntervalTitle => 'Comprobar o servidor cada';
  @override
  String get syncIntervalSubtitle => 'Só coa app aberta';
  @override
  String get syncIntervalDialogBody =>
      'Para ver os cambios feitos noutros dispositivos mentres a app está '
      'aberta. Con “Nunca”, só tras os cambios e ao abrir.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minuto' : '$count minutos';
  @override
  String get syncIntervalNever => 'Nunca';
  @override
  String get syncWifiOnlyTitle => 'Só con Wi-Fi';
  @override
  String get syncWifiOnlySubtitle => 'Con datos móbiles, sincroniza só a man';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 cambio á espera' : '$count cambios á espera';
  @override
  String syncRetryIn(String wait) => 'nova tentativa en $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Agardando polo Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Agardando pola conexión';
  @override
  String get syncMobileDataHint =>
      '“Sincronizar agora” usa igual os datos móbiles.';
  @override
  String get syncQueueKeptHint =>
      'Os cambios quedan aquí, aínda que peches a app, e saen sós cando o '
      'servidor responde.';
  @override
  String get syncAutoPaused => 'Sincronización automática en pausa';
  @override
  String get syncPausedAuthHint =>
      'Retómase cando actualizas o contrasinal ou sincronizas a man.';
  @override
  String get syncPausedServerHint =>
      'Retómase cando corrixes o enderezo ou sincronizas a man.';
  @override
  String get syncPausedConfirmHint =>
      '“Sincronizar agora” mostra o que se borraría e pide confirmación.';
  @override
  String get syncNeedsConfirmation => 'Agardando pola túa confirmación';
  @override
  String get syncMergeIntro =>
      'Os cambios que non se superpoñen xa están unidos; escolle que conservar '
      'onde si se superpoñen.';
  @override
  String get syncMergeClean =>
      'As dúas versións únense soas: non hai nada que se superpoña.';
  @override
  String get syncMergeNoBase =>
      'Non hai unha versión común sobre a que fusionar: escolles ti en cada '
      'punto no que as dúas copias difiren.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Superposición $index de $total';
  @override
  String get syncMergeFromLocal => 'Deste dispositivo';
  @override
  String get syncMergeFromRemote => 'Do servidor';
  @override
  String get syncMergeRemovedLines => 'Liñas eliminadas';
  @override
  String get syncMergeAbsentLines => 'Non está nesta copia';
  @override
  String get syncMergeKeepLocal => 'As miñas';
  @override
  String get syncMergeKeepRemote => 'Do servidor';
  @override
  String get syncMergeKeepBoth => 'Ambas';
  @override
  String get syncMergeSave => 'Gardar a unión';
  @override
  String get syncMergeKeepWhole => 'Ou conserva unha copia enteira';

  // The welcome deck and the guided tour (#308).

  @override
  String get welcomeSkip => 'Omitir';
  @override
  String get welcomeNext => 'Seguinte';
  @override
  String get welcomeBack => 'Atrás';
  @override
  String get welcomeStart => 'Comeza a escribir';
  @override
  String get welcomeClose => 'Pechar';
  @override
  String get welcomeNotesTitle => 'As túas notas son ficheiros';
  @override
  String get welcomeNotesBody =>
      'O Niman garda as túas notas como ficheiros Markdown simples, '
      'nos cartafoles que escollas. Unha nota é un ficheiro .md, e '
      'todo o que a aplicación che mostra constrúese a partir '
      'deles. Sen conta e sen un formato noso ao que volver.';
  @override
  String get welcomeModesTitle => 'Tres xeitos de escribir a mesma nota';
  @override
  String get welcomeModesBody =>
      'Escribe a fonte Markdown, escribe a nota tal como se le (o '
      'editor en vivo), ou lea. É unha soa nota uses a que uses, e '
      'podes cambiar por nota ou para toda a biblioteca.';
  @override
  String get welcomeLinksTitle => 'Todo se conecta';
  @override
  String get welcomeLinksBody =>
      'Os wikilinks como [[este]] atopan a súa nota mentres '
      'escribes. As etiquetas, o frontmatter e os modelos quitan do '
      'medio as partes que escribes unha e outra vez.';
  @override
  String get welcomeFindTitle => 'Atopala outra vez';
  @override
  String get welcomeFindBody =>
      'Busca de texto completo na biblioteca, unha paleta de ordes '
      'para todo o que sabe facer a aplicación, e a nota rápida a '
      'unha tecla.';
  @override
  String get welcomeExportTitle => 'Vai contigo';
  @override
  String get welcomeExportBody =>
      'Exporta unha nota ou un cartafol enteiro como Markdown, '
      'HTML, PDF ou libro EPUB. Trae unha exportación de Notion, ou '
      'abre un vault de Obsidian onde xa está.';
  @override
  String get welcomeTasksTitle => 'Tarefas e recordatorios';
  @override
  String get welcomeTasksBody =>
      'Unha lista todo.txt que gardas como ficheiro — prioridades, '
      'proxectos, prazos — e alarmas rem: que te avisan cando algo '
      'vence, no móbil e no escritorio.';
  @override
  String get welcomeSyncTitle => 'Entre as túas máquinas';
  @override
  String get welcomeSyncBody =>
      'Aponta unha biblioteca a un cartafol WebDAV — Nextcloud, '
      'ownCloud, un NAS — e as edicións sincronízanse nos dous '
      'sentidos, fusionadas liña a liña cando dous dispositivos '
      'tocaron a mesma nota.';
  @override
  String get welcomeDeviceTitle => 'Niman neste dispositivo';
  @override
  String get welcomeAndroidBody =>
      'Comparte texto ou un ficheiro co Niman desde calquera '
      'aplicación, mantén unha nota na pantalla de inicio e grava '
      'unha nota de voz en vez de escribir.';
  @override
  String get welcomeDesktopBody =>
      'Lapelas e paneis divididos, a bandexa do sistema, arrastrar '
      'e soltar na ventá, e ficheiros .md que abren o Niman.';
  @override
  String get welcomeQuestionTitle => 'Xa escribiches Markdown?';
  @override
  String get welcomeQuestionNote =>
      'Isto só decide como arrinca a aplicación. Podes activar ou '
      'desactivar calquera editor en Axustes → Editor cando '
      'queiras.';
  @override
  String get welcomeAnswerNone => 'Nunca';
  @override
  String get welcomeAnswerNoneHint =>
      'O editor en vivo, e a fonte Markdown non se ofrece ata que a '
      'actives.';
  @override
  String get welcomeAnswerSome => 'Un pouco';
  @override
  String get welcomeAnswerSomeHint =>
      'O editor en vivo abre as notas; a fonte Markdown está a un '
      'interruptor.';
  @override
  String get welcomeAnswerFluent => 'Sempre';
  @override
  String get welcomeAnswerFluentHint =>
      'A fonte Markdown, como vén a aplicación.';
  @override
  String get welcomeTourOffer => 'Móstra a aplicación';
  @override
  String get welcomeTourOfferNote =>
      'A visita comeza cando a túa primeira biblioteca está aberta, '
      'e sinala os controis reais.';
  @override
  String get welcomeDeckCommand => 'Que sabe facer o Niman';
  @override
  String get welcomeTourCommand => 'Fai a visita';
  @override
  String get tourDone => 'Feito';
  @override
  String get tourOfferTitle => 'Douche unha volta?';
  @override
  String get tourOfferBody =>
      'Uns cantos pasos pola aplicación, sinalando os controis '
      'reais. Podes parar en calquera paso e retomalo despois desde '
      'a paleta de ordes.';
  @override
  String get tourOfferYes => 'Móstrame';
  @override
  String get tourOfferNo => 'Agora non';
  @override
  String get tourTreeTitle => 'A túa biblioteca';
  @override
  String get tourTreeBody =>
      'Este é o cartafol que escolliches, cartafol por cartafol. '
      'Todo o que fagas a un ficheiro fóra do Niman aparece aquí en '
      'canto chega.';
  @override
  String get tourCreateTitle => 'Crea unha nota';
  @override
  String get tourCreateBody =>
      'Notas, listas, notas de voz, modelos e cartafoles comezan '
      'todos aquí. O mesmo menú aparece no móbil como o botón '
      'redondo.';
  @override
  String get tourNoteTitle => 'Unha nota á vez';
  @override
  String get tourNoteBody =>
      'A nota na pantalla; as que abriches quedan en lapelas '
      'enriba, e un segundo panel pode abrirse ao lado nunha ventá '
      'ancha.';
  @override
  String get tourModesTitle => 'Tres xeitos de escribir';
  @override
  String get tourModesBody =>
      'Escribe a fonte Markdown, escríbea tal como se le, ou lea — '
      'este interruptor é por nota, e o axuste da biblioteca decide '
      'que se abre.';
  @override
  String get tourToolbarTitle => 'A barra de ferramentas';
  @override
  String get tourToolbarBody =>
      'Formato na liña na que estás, e as mesmas accións co clic '
      'dereito. Cada construción que o Niman le está na chuleta.';
  @override
  String get tourCheatsheetTitle => 'Cada construción, escrita ao lado';
  @override
  String get tourCheatsheetBody =>
      'Esta é a chuleta. Cada exemplo pódese copiar, e Inserir '
      'ponno na nota que tes aberta.';
  @override
  String get tourCheatsheetOpen => 'Abrila';
  @override
  String get tourTabsTitle => 'Todo é unha lapela';
  @override
  String get tourTabsBody =>
      'Ficheiros, tarefas, busca, a nota rápida, axustes. A paleta '
      'de ordes chega a todas, e a cada orde, desde o teclado.';
  @override
  String get tourDockTitle => 'Esquema, etiquetas, historial';
  @override
  String get tourDockBody =>
      'O esquema da nota, as súas etiquetas e as súas versións '
      'pasadas, ao lado. No móbil o menú da nota abre os mesmos '
      'tres.';
  @override
  String welcomePageOf(int page, int of) => '$page de $of';

  // Cascading a checklist tick (#326).

  @override
  String get cascadeChecklistTitle => 'Marca as casiñas aniñadas';
  @override
  String get cascadeChecklistSubtitle =>
      'Marcar unha casiña marca as que están aniñadas debaixo. '
      'Desmarcala déixaas como están.';

  // Rebuilding the index file (#368).

  @override
  String get rebuildIndexTitle => 'Reconstruír o índice';

  // What the template checker says in the editor (T-TPL-09).

  @override
  String templateHintDidYouMean(String fix) => 'Querías dicir $fix?';
  @override
  String get templateHintNoFix =>
      'Non se ofrece ningunha corrección: o texto queda como está escrito.';
  @override
  String get templateHintFixAction => 'Corrixir';
  @override
  String get templateHintDismissAction => 'Descartar';
  @override
  String templateProblems(int count) => count == 1
      ? '1 problema nesta plantilla'
      : '$count problemas nesta plantilla';
  // The wikilink panel (#475) and the two book forms it offers after `#`.

  @override
  String wikilinkHeadingsIn(String named) => 'Títulos en $named';
  @override
  String wikilinkPlacesIn(String named) => 'Localizacións en $named';
  @override
  String get wikilinkThisNote => 'esta nota';
  @override
  String wikilinkNoMatchHeading(String query) =>
      'Ningún título coincide con “$query”.';
  @override
  String wikilinkNoMatchNote(String query) =>
      'Ningunha nota coincide con “$query”.';
  @override
  String wikilinkNoMatchFile(String query) =>
      'Ningún ficheiro coincide con «$query».';
  @override
  String get wikilinkNoHeading =>
      'esta nota non ten ningún título con ese nome';
  @override
  String get wikilinkNoNote => 'nada na biblioteca ten ese nome nin ese alias';
  @override
  String wikilinkAlias(String alias) => 'alias $alias';
  @override
  String get wikilinkBookNote =>
      'Unha páxina escóllese, non se nomea dunha lista: escribe o seu número.';
  @override
  String get wikilinkFooterMove => 'mover';
  @override
  String get wikilinkFooterOr => 'ou';
  @override
  String get wikilinkFooterInsert => 'inserir';
  @override
  String get wikilinkFooterClose => 'pechar';
  @override
  String get suggesterPageHint => 'escribe un número';
  @override
  String get suggesterChapterHint => 'nomea un ficheiro do libro';

  // What the template checker found, as the hint writes it (T-TPL-09).

  @override
  String get templateProblemUnclosedBraces =>
      'chaves de apertura sen pechar: nada pecha este marcapase';
  @override
  String get templateProblemEmptyPlaceholder =>
      'marcapase baleiro: non hai ningún nome entre as chaves';
  @override
  String templateProblemUnknownPlaceholder(String name) =>
      'marcapase descoñecido “$name”';
  @override
  String templateProblemAskNoLabel(String name) =>
      '“$name” non ten etiqueta: non pregunta nada, e o marcapase queda tal '
      'cal';
  @override
  String templateProblemCounterNoName(String name) =>
      '“$name” non ten nome: non conta nada, e o marcapase queda tal cal';
  @override
  String templateProblemCursorFilters(String name) =>
      '“$name” non acepta filtros: o cursor non se coloca, e o marcapase queda '
      'tal cal';
  @override
  String get templateProblemUnclosedQuote =>
      'comiña sen pechar no formato de data: todo o que segue lese como texto '
      'normal';
  @override
  String templateProblemUnknownDateToken(String token) =>
      'token de data descoñecido “$token”';
  @override
  String get templateProblemEmptyFilter =>
      'filtro baleiro: non hai ningún nome despois do “|”';
  @override
  String templateProblemDateMove(String filter, String formats) =>
      '“$filter” despraza unha data: só $formats aceptan un desprazamento, e '
      'só '
      'antes de calquera outro filtro';
  @override
  String templateProblemNotADateMove(String filter) =>
      '“$filter” non é un desprazamento de data: un desprazamento é un número '
      'e '
      'unha unidade, como “+7d” ou “-1w”';
  @override
  String templateProblemSnapUnit(String filter, String units, String unit) =>
      '“$filter” axústase a $units, non a “$unit”';
  @override
  String templateProblemPadWidth(String filter, String argument) =>
      '“$filter” precisa un número para o seu ancho, e “$argument” non o é';
  @override
  String templateProblemUnknownFilter(String name) =>
      'filtro descoñecido “$name”';
  @override
  String get diagramTitle => 'Diagrama';

  @override
  String get fullScreen => 'Pantalla completa';
  @override
  String get commandInsertDiagram => 'Inserir diagrama (Mermaid)';

  @override
  String get commandInsertMindMap => 'Inserir mapa mental';

  @override
  String get commandConvertListToMindMap => 'Converter lista en mapa mental';
  @override
  String get toolMindMapSubtitle =>
      'Substitúe a lista no cursor por un mapa mental';

  @override
  String get toolMindMapNeedsList => 'O cursor non está nunha lista';

  @override
  String ocrEngineName(String version) => 'Tesseract $version';

  @override
  String get settingsSectionTextRecognition => 'Recoñecemento de texto';

  @override
  String get ocrIntro =>
      'Le o texto dos PDF escaneados e das imaxes nunha nota ao seu '
      'carón. Todo funciona neste dispositivo: o motor e cada '
      'idioma descárganse unha soa vez, cando se precisan por '
      'primeira vez.';

  @override
  String get ocrEngineTitle => 'Motor';

  @override
  String get ocrEngineSystem => 'Biblioteca do sistema';

  @override
  String get ocrEngineBundled => 'Incluído na app';

  @override
  String get ocrEngineUnavailable => 'Non hai motor para este dispositivo';

  @override
  String get ocrEngineDeleteTitle => 'Eliminar o motor?';

  @override
  String get ocrQualityTitle => 'Calidade';

  @override
  String get ocrQualityFast => 'Rápida';

  @override
  String get ocrQualityBest => 'Mellor';

  @override
  String get ocrQualityHint =>
      'Rápida: 1–4 MB por idioma, áxil en calquera dispositivo. '
      'Mellor: 10–15 MB por idioma, máis precisa en escaneos '
      'difíciles, de dúas a tres veces máis lenta. Cada calidade '
      'ten os seus idiomas.';

  @override
  String get ocrLanguageTitle => 'Idioma predeterminado';

  @override
  String get ocrAlsoTitle => 'Tamén';

  @override
  String get ocrAlsoSubtitle => 'Para páxinas que mesturan dous idiomas';

  @override
  String get ocrAlsoNone => 'Ningún';

  @override
  String ocrOnDevice(String size) => 'Neste dispositivo · $size';

  @override
  String get ocrOtherLanguages => 'Outros idiomas';

  @override
  String ocrSearchLanguages(int count) => 'Buscar entre $count idiomas';

  @override
  String get ocrLanguageDefault => 'Predeterminado';

  @override
  String ocrLanguageDeleteTitle(String language) => 'Eliminar $language?';

  @override
  String ocrDeleteBody(String size) =>
      'Isto libera $size. Volverá descargarse cando o recoñecemento '
      'de texto o precise.';

  @override
  String get ocrRecognizeAction => 'Recoñecer o texto';

  @override
  String get ocrPagesTitle => 'Páxinas';

  @override
  String ocrPagesAll(int count) => 'As $count';

  @override
  String ocrPagesThis(int page) => 'Esta páxina ($page)';

  @override
  String get ocrPagesFrom => 'De';

  @override
  String get ocrPagesTo => 'a';

  @override
  String get ocrSavedAs => 'Gardarase como';

  @override
  String get ocrSavedAsHint =>
      'Unha nota ao carón do ficheiro, unha sección por páxina. A '
      'busca atópaa coma calquera nota.';

  @override
  String get ocrPdfHasText =>
      'Este PDF xa contén texto: quizais non faga falta recoñecelo.';

  @override
  String ocrNeedsDownload(String size) => 'Primeiro, unha descarga de $size';

  @override
  String get ocrNeedsDownloadHint =>
      'Só unha vez: despois funciona sen conexión.';

  @override
  String get ocrDownloadAndRecognize => 'Descargar e recoñecer';

  @override
  String ocrRecognizing(int page, int total) =>
      'Recoñecendo p. $page de $total';

  @override
  String get ocrPreparing => 'Descargando o que precisa o recoñecemento…';

  @override
  String ocrRecognized(int words) => 'Texto recoñecido · $words palabras';

  @override
  String get ocrOpenText => 'Abrir o texto';

  @override
  String get ocrFailed => 'Fallou o recoñecemento de texto';

  @override
  String get commandNeedOcrFile => 'Precisa un PDF ou unha imaxe na pantalla';

  @override
  String get ocrTextTitle => 'Texto';

  @override
  String get ocrScanTitle => 'Escaneo';

  @override
  String get ocrOpenAsNote => 'Abrir como nota';

  @override
  String get ocrShowText => 'Amosar o texto';

  @override
  String get ocrHideText => 'Agochar o texto';

  @override
  String get ocrCopyText => 'Copiar';

  @override
  String ocrLostPlaces(int page, int lines) =>
      'p. $page: $lines liñas perderon o seu lugar no escaneo. Alí '
      'as anotacións van á páxina enteira.';

  @override
  String ocrRecognizeAgain(int page) => 'Recoñecer de novo a p. $page';

  @override
  String get captureWebPage => 'Capturar páxina web';

  @override
  String get capturePageField => 'Páxina';

  @override
  String get captureFromClipboard => 'Tomada do portapapeis.';

  @override
  String get captureInvalidUrl =>
      'Un enderezo web comeza por http:// ou https://.';

  @override
  String get captureRead => 'Ler';

  @override
  String get captureDownloading => 'Descargando…';

  @override
  String captureDownloaded(String size) => 'Descargada · $size';

  @override
  String captureFewWords(int words) => 'Só se atoparon $words palabras';

  @override
  String get captureRunningBrowser => 'Executando a páxina nun navegador…';

  @override
  String get captureBrowserPrivacy =>
      'O navegador execútase agochado, cun perfil propio que se borra '
      'despois: o teu navegador e as súas sesións non se tocan.';

  @override
  String get captureReadInBrowser =>
      'Lida despois de executar a páxina nun navegador';

  @override
  String get captureNoArticle =>
      'Non se atopou ningún artigo: a nota conserva o título, a descrición e '
      'a ligazón.';

  @override
  String get captureTitleField => 'Título';

  @override
  String get captureFolderField => 'Cartafol';

  @override
  String get captureAddTag => 'Engadir unha etiqueta';

  @override
  String get capturePreview => 'Vista previa';

  @override
  String captureWordsMinutes(int words, int minutes) =>
      '$words palabras · $minutes min';

  @override
  String captureDownloadPictures(int count, String folder) =>
      'Descargar as $count imaxes en $folder/';

  @override
  String get captureRemoved => 'Eliminado';

  @override
  String captureRemovedCode(int scripts, int styles) =>
      '$scripts scripts e $styles estilos';

  @override
  String get captureRemovedMenu => 'O menú de navegación';

  @override
  String get captureRemovedBanner => 'Un aviso de cookies';

  @override
  String captureRemovedAround(int words) =>
      'O resto da páxina · $words palabras';

  @override
  String get captureSaveNote => 'Gardar nota';

  @override
  String get captureSaving => 'Gardando…';

  @override
  String captureUnreadableNotice(String url) =>
      'Niman non puido ler esta páxina: só amosa o texto tras iniciar sesión '
      'ou cun script que non se puido executar. [Abre a ligazón](<$url>) '
      'para lela.';

  @override
  String get captureFailScheme => 'Só se poden capturar páxinas http e https.';

  @override
  String get captureFailRedirects => 'A páxina redirixe demasiadas veces.';

  @override
  String get captureFailTimeout => 'A páxina non respondeu a tempo.';

  @override
  String get captureFailTooLarge => 'A páxina ocupa máis de 10 MB.';

  @override
  String get captureFailNotHtml =>
      'Isto non é unha páxina web: é un ficheiro, un PDF ou unha imaxe.';

  @override
  String captureFailStatus(String code) =>
      'O sitio respondeu cun erro ($code).';

  @override
  String get captureFailNetwork =>
      'Non se puido acceder á páxina: comproba a conexión.';

  @override
  String get captureDropHint => 'Solta para capturar esta páxina';

  @override
  String get captureDropDetail => 'Ábrese o diálogo de captura con ela.';

  @override
  String get captureSaveToNiman => 'Gardar en Niman';

  @override
  String get captureBackgroundHint =>
      'Volves ao navegador; unha notificación avisarate cando a nota estea '
      'lista.';

  @override
  String get captureAppendToNote => 'Engadir a unha nota';

  @override
  String get captureAppend => 'Engadir';

  @override
  String captureReadingHost(String host) => 'Lendo $host…';

  @override
  String captureSavedTitle(String title) => 'Gardado: $title';

  @override
  String captureSavedBody(String folder, int words, int images) =>
      '$folder · $words palabras · $images imaxes';

  @override
  String get captureSavedUnreadable => 'Gardado sen o artigo';

  @override
  String captureUnreadableBody(String host) =>
      'Non se puido ler $host: consérvanse o título, a descrición e a ligazón';

  @override
  String captureQuoteAdded(String note) => 'Cita engadida a $note';

  @override
  String captureQuoteFrom(String title) => 'de «$title»';

  @override
  String captureFailedTitle(String host) => 'Non se puido capturar $host';

  @override
  String get captureShowFolder => 'Amosar o cartafol';

  @override
  String get captureOpen => 'Abrir';

  @override
  String get captureQuote => 'Cita';

  @override
  String captureNewNoteIn(String folder) => 'Nota nova en $folder';

  @override
  String captureDownloadPicturesTo(String folder) =>
      'Descargar as imaxes en $folder/';

  @override
  String get highlightAction => 'Destacar';

  @override
  String get highlightMark => 'Destacado';

  @override
  String get highlightRemove => 'Quitar o destacado';

  @override
  String get highlightFailed => 'Non se puido gardar o destacado';

  @override
  String get highlightYellow => 'Amarelo';

  @override
  String get highlightGreen => 'Verde';

  @override
  String get highlightBlue => 'Azul';

  @override
  String get highlightPink => 'Rosa';

  @override
  String get highlightCopy => 'Copiar';

  @override
  String get pasteAsMarkdown => 'Pegar como Markdown';

  @override
  String get pastedAsMarkdown => 'Pegado como Markdown';

  @override
  String pastedAsMarkdownWithLink(String host) =>
      'Pegado como Markdown · coa ligazón a $host';

  @override
  String get settingsAreaNavigation => 'Navegación';

  @override
  String get navigationIntro =>
      'A orde da navegación e os destinos que mostra. Un oculto segue na '
      'paleta de comandos.';

  @override
  String get navigationScopeLibrary => 'Esta biblioteca';

  @override
  String get navigationScopeDevice => 'Só neste dispositivo';

  @override
  String get navigationAlwaysShown => 'Sempre visible';
  @override
  String get navigationStart => 'Ábrese en';
  @override
  String navigationStartHidden(String hidden, String start) =>
      '$hidden está oculto: a app ábrese en $start.';

  @override
  String get newSlidesTitle => 'Nova presentación';

  @override
  String get newSlidesDefault => 'A miña presentación';

  @override
  String get showSlidesTooltip => 'Amosar as diapositivas';

  @override
  String get slidesPresent => 'Presentar';

  @override
  String get slidesPresenterView => 'Vista do presentador';

  @override
  String get slidesMarkdownPreview => 'Vista previa Markdown';

  @override
  String get slidesExportPdf => 'Exportar as diapositivas como PDF';

  @override
  String get slidesSpeakerNotes => 'Notas do orador';

  @override
  String get slidesOverview => 'Vista xeral';

  @override
  String get slidesNotes => 'Notas';

  @override
  String get slidesExit => 'Saír';

  @override
  String get slidesPrevious => 'Anterior';

  @override
  String get slidesNext => 'Seguinte';

  @override
  String get slidesNow => 'Agora';

  @override
  String get slidesElapsed => 'Transcorrido';

  @override
  String get slidesSlideOnly => 'Só a diapositiva';

  @override
  String get slidesPause => 'Pausa';

  @override
  String get slidesRestart => 'Reiniciar';

  @override
  String get slidesSwipeToExit => 'Esvara cara abaixo para saír';

  @override
  String get slidesMarkdown => 'Markdown';

  @override
  String get commandNeedSlidesNote => 'Precisa dunha presentación aberta';

  @override
  String get slidesTemplateSecond => 'Segunda diapositiva';

  @override
  String get slidesTemplatePoint => 'Un punto';

  @override
  String get slidesTemplateNote => 'que dicir aquí — só ti o ves.';

  @override
  String get tabHome => 'Inicio';

  @override
  String get homeTileActions => 'Accións';

  @override
  String get homeTileJournalToday => 'Diario de hoxe';

  @override
  String get homeTileTasksDue => 'Tarefas pendentes';

  @override
  String get homeTileRecent => 'Modificadas recentemente';

  @override
  String get homeTilePinned => 'Fixadas';

  @override
  String get homeTileJournalCalendar => 'Calendario do diario';

  @override
  String get homeTileTopTags => 'Etiquetas principais';

  @override
  String get homeTileRandomNote => 'Nota ao chou';

  @override
  String get homeTileSearch => 'Busca gardada';

  @override
  String get homeJournalEmpty => 'Aínda non hai nada escrito hoxe.';

  @override
  String get homeJournalWrite => 'Escribir a entrada de hoxe';

  @override
  String get homeTasksEmpty => 'Non hai tarefas abertas.';

  @override
  String get homeNotesEmpty => 'Aínda non hai notas.';

  @override
  String get homePinnedEmpty => 'Fixa unha nota e aparecerá aquí.';

  @override
  String get homeTagsEmpty => 'Aínda non hai etiquetas.';

  @override
  String get homeSearchEmpty => 'Sen coincidencias.';

  @override
  String get homeSearchNoQuery => 'Aínda non hai consulta.';

  @override
  String get homeRandomAnother => 'Outra';

  @override
  String get homeEdit => 'Editar inicio';

  @override
  String get homeEditDone => 'Feito';

  @override
  String get homeReset => 'Restablecer';

  @override
  String get homeResetTitle => 'Restablecer o inicio?';

  @override
  String get homeResetBody =>
      'Todos os mosaicos volven ao inicio predeterminado.';

  @override
  String get homeUseLibraryTitle => 'Usar o inicio da biblioteca?';

  @override
  String get homeUseLibraryBody =>
      'Descártase o inicio propio deste dispositivo e aquí volve aparecer o '
      'da biblioteca.';

  @override
  String get homeUseLibraryConfirm => 'Descartar';

  @override
  String get homeAddTiles => 'Engadir mosaicos';

  @override
  String get homeHiddenTiles => 'Agochados';

  @override
  String get homeTileOnHome => 'No inicio';

  @override
  String get homeTileHide => 'Agochar';

  @override
  String get homeTileShow => 'Amosar';

  @override
  String get homeTileMove => 'Mover e cambiar o tamaño';

  @override
  String get homeMoveLeft => 'Mover á esquerda';

  @override
  String get homeMoveRight => 'Mover á dereita';

  @override
  String get homeMoveUp => 'Mover arriba';

  @override
  String get homeMoveDown => 'Mover abaixo';

  @override
  String get homeWider => 'Máis ancho';

  @override
  String get homeNarrower => 'Máis estreito';

  @override
  String get homeTaller => 'Máis alto';

  @override
  String get homeShorter => 'Máis baixo';

  @override
  String get homeTileSettings => 'Axustes do mosaico';

  @override
  String get homeSearchName => 'Nome';

  @override
  String get homeSearchQuery => 'Consulta';

  @override
  String get homeSearchQueryHint => 'Palabras, ou clave = valor';

  @override
  String get homeGridHint =>
      'Arrastra un mosaico para movelo, e a súa esquina para cambiar o '
      'tamaño.';

  @override
  String get homeColumnHint =>
      'Arrastra un asa para reordenar. Un interruptor amosa ou agocha un '
      'mosaico en todos os dispositivos.';

  @override
  String get homeActionAdd => 'Engadir acción';

  @override
  String get homeActionAsk => 'Preguntar';

  @override
  String get homeActionAskHint => 'Pregúntase ao premer o botón';

  @override
  String get homeActionCaptureFolder => 'O cartafol das capturas';

  @override
  String get homeActionContext => 'Contexto';

  @override
  String get homeActionEdit => 'Editar acción';

  @override
  String get homeActionFieldAdd => 'Engadir campo';

  @override
  String get homeActionFieldKey => 'Clave do frontmatter';

  @override
  String get homeActionFields => 'Campos';

  @override
  String get homeActionFixed => 'Fixo';

  @override
  String get homeActionFixedHint => 'Texto, ou {{date}}';

  @override
  String get homeActionFolder => 'Cartafol';

  @override
  String get homeActionIcon => 'Icona';

  @override
  String get homeActionKind => 'Fai';

  @override
  String get homeActionKindOpenNote => 'Abrir unha nota';

  @override
  String get homeActionLabel => 'Etiqueta';

  @override
  String get homeActionNoNote => 'Non se escolleu ningunha nota';

  @override
  String get homeActionNote => 'Nota';

  @override
  String get homeActionNoTemplate => 'Ningún: unha nota baleira';

  @override
  String get homeActionNoteName => 'Nome';

  @override
  String get homeActionOpenAfter => 'Abrir despois de crear';

  @override
  String get homeActionProject => 'Proxecto';

  @override
  String get homeActionTemplate => 'Modelo';

  @override
  String homeActionMissing(String path) => '$path xa non está na biblioteca';
}
