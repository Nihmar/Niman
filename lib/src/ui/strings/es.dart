// The Spanish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class SpanishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  @override
  List<String> get monthNamesShort => const [
    'ene.',
    'feb.',
    'mar.',
    'abr.',
    'may.',
    'jun.',
    'jul.',
    'ago.',
    'sept.',
    'oct.',
    'nov.',
    'dic.',
  ];
  @override
  List<String> get weekdayNames => const [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'lun.',
    'mar.',
    'mié.',
    'jue.',
    'vie.',
    'sáb.',
    'dom.',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Papelera';
  @override
  String get trashSubtitle =>
      'Los elementos eliminados van a .trash/ (off = borrado definitivo)';
  @override
  String get trashAutoEmptyTitle => 'Vaciado automático de la papelera';
  @override
  String get trashAutoEmptySubtitle =>
      'Las eliminaciones antiguas se pierden al abrir la biblioteca';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nunca'
      : days == 1
      ? '1 día'
      : '$days días';
  @override
  String get debugLogsTitle => 'Registros de depuración';
  @override
  String get debugLogsSubtitle =>
      'Registra los eventos de la app en un búfer en memoria';
  @override
  String get lineNumbersTitle => 'Números de línea';
  @override
  String get lineNumbersSubtitle =>
      'Muestra la columna de números de línea en el editor';
  @override
  String get readableLineLengthTitle => 'Longitud de línea legible';
  @override
  String get readableLineLengthSubtitle =>
      'Mantén el texto de la nota en una columna centrada en lugar de todo el '
      'ancho de la ventana';
  @override
  String get noteColumnWidthTitle => 'Ancho de la columna';
  @override
  String get noteColumnWidthSubtitle =>
      'Cuánto mide de ancho la columna de la nota, en píxeles';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Teclado al abrir';
  @override
  String get keyboardOnOpenSubtitle =>
      'Muestra el teclado en cuanto se abre una nota (off = al primer '
      'toque)';
  @override
  String get editorKindSource => 'Fuente Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Fuente Markdown, tal como está escrita';
  @override
  String get editorKindWysiwygSubtitle =>
      'Texto con formato, editado directamente';
  @override
  String get settingsFolderToCreate => 'por crear';
  @override
  String get settingsSearchHint => 'Buscar ajustes';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 ajuste encontrado' : '$count ajustes encontrados';
  @override
  String get settingsToggleOn => 'Activado';
  @override
  String get settingsToggleOff => 'Desactivado';
  @override
  String get settingsPreviewEnabledTitle => 'Vista previa';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Muestra la nota renderizada junto al editor de fuente';
  @override
  String get switchToWysiwygTooltip => 'Cambiar al editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Cambiar a la fuente Markdown';
  @override
  String get switchToSourceLabel => 'Fuente';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Esta nota es demasiado grande para el editor WYSIWYG. Ábrela en la '
      'fuente Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Apariencia';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Biblioteca';
  @override
  String get settingsSectionReminders => 'Recordatorios';
  @override
  String get settingsSectionShortcuts => 'Teclado';
  @override
  String get keyboardShortcutsTitle => 'Atajos de teclado';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Biblioteca $name';
  @override
  String get settingsGroupLibraryHint => 'aplica solo a esta biblioteca';
  @override
  String get settingsGroupMaintenance => 'Mantenimiento';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Carpetas y rutas';
  @override
  String get settingsAreaTrashHistory => 'Papelera y cronología';
  @override
  String get settingsAreaDiagnostics => 'Diagnóstico e información';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Necesita un teclado físico conectado';
  @override
  String get settingsSectionUpdates => 'Actualizaciones';
  @override
  String get autoUpdateTitle => 'Actualizaciones automáticas';
  @override
  String get autoUpdateSubtitle =>
      'Comprueba GitHub Releases al iniciar y cada 6 horas';
  @override
  String get checkForUpdatesTitle => 'Buscar actualizaciones';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version está disponible';
  @override
  String get updateUpToDate => 'Niman está actualizado';
  @override
  String get updateCheckFailed => 'Error al buscar actualizaciones';
  @override
  String updateSavedTo(Object path) => 'Actualización guardada en $path';
  @override
  String get updateInstallerStarted => 'Instalador iniciado';
  @override
  String get settingsSectionDiagnostics => 'Diagnóstico';
  @override
  String get settingsSpellCheckTitle => 'Comprobar ortografía';
  @override
  String get settingsSpellCheckSubtitle =>
      'Subraya las palabras mal escritas mientras escribes.';
  @override
  String get spellCheckDictionaryTitle => 'Diccionario';
  @override
  String get spellCheckDictionarySystem => 'Predeterminado del sistema';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Elegir diccionarios';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Elige cada idioma en el que está escrita esta biblioteca. Una '
      'palabra es correcta si la conoce algún diccionario elegido; sin '
      'elección, decide el idioma del sistema.';
  @override
  String get spellCheckNoDictionaries =>
      'No se encontraron diccionarios en este sistema.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Comprobar ortografía';
  @override
  String get spellCheckTitle => 'Ortografía';
  @override
  String get spellCheckEmpty => 'Sin errores de ortografía.';
  @override
  String get spellCheckUnavailable =>
      'hunspell no está instalado en este sistema.';
  @override
  String get spellCheckNoSuggestions => 'Sin sugerencias';
  @override
  String spellCheckCount(int count) => '$count por revisar';
  @override
  String spellCheckLine(int line) => 'línea $line';
  @override
  String get addWordToDictionary => 'Añadir al diccionario';

  @override
  String indentWidthValue(int spaces) => '$spaces espacios';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Brillo';
  @override
  String get themeBrightnessSubtitle =>
      'Claro, oscuro o el que tenga el dispositivo';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Claro';
  @override
  String get themeBrightnessNight => 'Oscuro';
  @override
  String get themePaletteTitle => 'Paleta';
  @override
  String get themePaletteSubtitle => 'Los colores de la interfaz y de la nota';
  @override
  String get themePaletteSystem => 'Sistema';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Tamaño del texto de la interfaz';
  @override
  String get uiTextScaleSubtitle =>
      'El árbol, las pestañas y los diálogos; encima de la '
      'configuración del sistema';
  @override
  String get noteTextScaleTitle => 'Tamaño del texto de las notas';
  @override
  String get noteTextScaleSubtitle =>
      'El editor y la vista previa, que siempre coinciden';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Modo de vista previa';
  @override
  String get previewModeSubtitle =>
      'Si la vista previa comparte la pantalla con el editor o lo '
      'sustituye';
  @override
  String get previewModeAuto => 'Lado a lado';
  @override
  String get previewModeSwitch => 'Pantalla completa';
  @override
  String get splitRatioTitle => 'Anchura de la división';
  @override
  String get splitRatioSubtitle =>
      'La parte del editor cuando la vista previa está lado a lado';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formato del enlace';
  @override
  String get linkTypeSubtitle => 'Lo que inserta el botón de enlace del editor';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Crear notas que faltan en';
  @override
  String get missingNoteLocationRoot => 'Raíz de la biblioteca';
  @override
  String get missingNoteLocationCurrentFolder => 'Carpeta actual';
  @override
  String get indentWidthTitle => 'Anchura de sangría';
  @override
  String get indentWidthSubtitle =>
      'Espacios añadidos por nivel de sangría en el editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Idioma';
  @override
  String get languageSubtitle => 'El idioma de los propios textos de la app';
  @override
  String get languageSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Añadir un elemento';
  @override
  String get listAddTooltip => 'Añadir un elemento';
  @override
  String get listEmpty => 'Aún no hay elementos';
  @override
  String get listDragHandleLabel => 'Reordenar el elemento';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Aún no hay grabaciones';
  @override
  String get audioRecord => 'Grabar';
  @override
  String get audioStop => 'Detener';
  @override
  String get audioPlay => 'Reproducir';
  @override
  String get audioDelete => 'Eliminar la grabación';
  @override
  String get audioImport => 'Importar un archivo de audio';
  @override
  String get audioRecording => 'Grabando…';
  @override
  String get audioPermissionDenied =>
      'Permiso del micrófono denegado — hace falta para grabar.';
  @override
  String get newAudioNoteTitle => 'Nueva nota de voz';
  @override
  String get newAudioNoteDefault => 'Mi grabación';
  @override
  String get showAudioTooltip => 'Mostrar las grabaciones';
  @override
  String get audioMessageHint => 'Escribe una nota…';
  @override
  String get audioSend => 'Enviar';
  @override
  String get audioRename => 'Renombrar la grabación';
  @override
  String get audioDescriptionHint => 'Describe esta grabación…';
  @override
  String get audioEditDescription => 'Editar la descripción';
  @override
  String get audioDeleteNote => 'Eliminar la nota';
  @override
  String get audioEditNote => 'Editar la nota';
  @override
  String get audioPause => 'Pausa';
  @override
  String get audioEditTitle => 'Editar título';
  @override
  String get audioTitleHint => 'Título de esta grabación…';
  @override
  String audioUntitled(int n) => 'Grabación $n';
  @override
  String get audioMoreActions => 'Más acciones';
  @override
  String get audioDiscardRecording => 'Descartar grabación';
  @override
  String get audioPauseRecording => 'Pausar grabación';
  @override
  String get audioResumeRecording => 'Reanudar grabación';
  @override
  String get audioRecordingPaused => 'En pausa';
  @override
  String get audioSavingRecording => 'Guardando…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rápida';
  @override
  String get trayOpen => 'Abrir Niman';
  @override
  String get trayQuit => 'Salir';
  @override
  String get closeToTrayTitle => 'Cerrar al área de notificación';
  @override
  String get closeToTraySubtitle =>
      'La × de la ventana oculta Niman y lo deja en marcha, así los '
      'recordatorios siguen llegando. Se sale desde el menú del icono.';
  @override
  String get shortcutNewTodo => 'Nueva tarea';
  @override
  String get shortcutNewNote => 'Nueva nota';
  @override
  String get shortcutNewList => 'Nueva lista';
  @override
  String get shortcutNewAudio => 'Nueva nota de voz';
  @override
  String get shortcutToggleSidebar => 'Mostrar u ocultar el árbol de archivos';
  @override
  String get shortcutCloseTab => 'Cerrar la nota actual';
  @override
  String get shortcutNextTab => 'Siguiente nota abierta';
  @override
  String get shortcutPreviousTab => 'Nota abierta anterior';
  @override
  String get shortcutEditorSection => 'En el editor';
  @override
  String get shortcutFormatSection => 'Formato';
  @override
  String get shortcutFind => 'Buscar';
  @override
  String get shortcutReplace => 'Buscar y reemplazar';
  @override
  String get shortcutSavingNote =>
      'Los cambios se guardan automáticamente: no hay un atajo para '
      'guardar.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Cargando…';
  @override
  String get noteStatusSaving => 'Guardando…';
  @override
  String get noteStatusUnsaved => 'Sin guardar';
  @override
  String get noteStatusSaved => 'Guardado';
  @override
  String get noteStatusError => 'Error';
  @override
  String get noteNotText =>
      'Este archivo no es una nota de texto, así que '
      'Niman no puede mostrarlo aquí.';
  @override
  String get noteLoadFailed => 'No se pudo abrir esta nota.';
  @override
  String wordCount(int count) => count == 1 ? '1 palabra' : '$count palabras';
  @override
  String get outlineTooltip => 'Esquema';
  @override
  String get outlineNoHeadings => 'Sin títulos';
  @override
  String get outlineNoTitle => '(sin título)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Negrita';
  @override
  String get toolbarItalic => 'Cursiva';
  @override
  String get toolbarStrikethrough => 'Tachado';
  @override
  String get toolbarSuperscript => 'Superíndice';
  @override
  String get toolbarUnderline => 'Subrayado';
  @override
  String get toolbarLink => 'Enlace';
  @override
  String get toolbarCode => 'Bloque de código';
  @override
  String get toolbarImage => 'Insertar imagen';
  @override
  String get toolbarHeading => 'Título';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Lista numerada';
  @override
  String get toolbarQuote => 'Cita';
  @override
  String get toolbarIndent => 'Aumentar sangría';
  @override
  String get toolbarOutdent => 'Reducir sangría';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Herramientas';
  @override
  String get editorToolsTitle => 'Herramientas del editor';
  @override
  String get toolCountListTitle => 'Contar una lista';
  @override
  String get toolCountListSubtitle =>
      'Suma lo que enumeran las filas, como lista de verificación';
  @override
  String get toolCountListNeedsList =>
      'Esta nota no tiene ninguna lista que contar';
  @override
  String get tallySourceLabel => 'Lista';
  @override
  String get tallyCutLabel => 'Leer cada fila como';
  @override
  String get tallyCutDash => 'Nombre - valores';
  @override
  String get tallyCutColon => 'Nombre: valores';
  @override
  String get tallyCutCommas => 'Valores separados por comas';
  @override
  String get tallyCutWhole => 'Toda la fila, como un solo valor';
  @override
  String get tallySortLabel => 'Orden';
  @override
  String get tallySortCount => 'Primero los más frecuentes';
  @override
  String get tallySortAlphabetical => 'Alfabético';
  @override
  String get tallySortFirstSeen => 'Según la lista';
  @override
  String get tallyInsert => 'Insertar';
  @override
  String get tallyUpdate => 'Actualizar';
  @override
  String get tallyNothingToCount => 'Aquí no hay nada que contar';
  @override
  String get headingDialogTitle => 'Nivel del título';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Barra de herramientas del editor';
  @override
  String get toolbarSettingsHint =>
      'Arrastra para reordenar; el ojo muestra u oculta un botón.';
  @override
  String get toolbarShowButton => 'Mostrar';
  @override
  String get toolbarHideButton => 'Ocultar';
  @override
  String get toolbarResetOrder => 'Restaurar los predeterminados';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Mostrar vista previa';
  @override
  String get showEditorTooltip => 'Mostrar editor';
  @override
  String get enterFullScreenTooltip => 'Pantalla completa';
  @override
  String get exitFullScreenTooltip => 'Salir de pantalla completa';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tabla HTML en bruto)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Buscar en las notas';
  @override
  String get searchModeWords => 'Palabras';
  @override
  String get searchModeContains => 'Contiene';
  @override
  String get searchEmptyHint =>
      'Escribe para buscar en la biblioteca, o clave = valor para '
      'filtrar por frontmatter';
  @override
  String get searchTooShortHint => 'Escribe al menos 2 caracteres';
  @override
  String get searchNoMatches => 'Sin coincidencias';
  @override
  String get searchLoadMore => 'Mostrar más';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Reemplazar…';
  @override
  String get replaceInNoteAction => 'Reemplazar en esta nota…';
  @override
  String get replaceInThisNote => 'Reemplazar en esta nota';
  @override
  String get replaceWithLabel => 'Reemplazar con';
  @override
  String get replaceCaseSensitive => 'Distinguir mayúsculas';
  @override
  String get replaceWholeWordsHint =>
      'solo se reemplazan coincidencias exactas de palabras completas';
  @override
  String get replaceConfirm => 'Reemplazar';
  @override
  String get replaceCancel => 'Cerrar';
  @override
  String get replaceUnavailable =>
      'El reemplazo no está disponible ahora mismo';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Buscar en la nota';
  @override
  String get editorFindHint => 'Buscar';
  @override
  String get editorReplaceHint => 'Reemplazar';
  @override
  String get editorFindCaseTooltip => 'Distinguir mayúsculas';
  @override
  String get editorFindPreviousTooltip => 'Coincidencia anterior';
  @override
  String get editorFindNextTooltip => 'Coincidencia siguiente';
  @override
  String get editorFindCloseTooltip => 'Cerrar la búsqueda';
  @override
  String get editorFindReplaceModeTooltip => 'Modo reemplazo';
  @override
  String get editorReplaceOneTooltip => 'Reemplazar esta coincidencia';
  @override
  String get editorReplaceAllTooltip => 'Reemplazar todas';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etiquetas';
  @override
  String get tagsTitle => 'Etiquetas';
  @override
  String get tagsEmpty =>
      'Aún no hay etiquetas — añade un #tag o etiquetas en el '
      'frontmatter';
  @override
  String get tagsBackTooltip => 'Volver a la búsqueda';
  @override
  String get tagsNotesEmpty => 'Ninguna nota con esta etiqueta';
  @override
  String tagsNotesCapped(int limit) =>
      'Solo se listan las primeras $limit — busca la etiqueta para '
      'restringir';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Enlace no encontrado';
  @override
  String get headingNotFoundTitle => 'Título no encontrado';
  @override
  String get ambiguousLinkTitle => 'Varias notas coinciden';
  @override
  String get openLinkFailed => 'No se pudo abrir el enlace';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'La nota no existe';
  @override
  String missingNoteDialogBody(String path) => '¿Crear «$path»?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'La carpeta «$folder» no existe';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Pendientes';
  @override
  String get todoDone => 'Hechas';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Todas las fechas';
  @override
  String get todoFilter => 'Filtrar';
  @override
  String get todoNoTokens => 'Sin tokens en esta lista';
  @override
  String get todoCountOpen => 'pendientes';
  @override
  String get todoCountDone => 'hechas';
  @override
  String get todoEmptyOpen => 'Aún no hay tareas pendientes';
  @override
  String get todoEmptyDone => 'Nada completado aún';
  @override
  String get todoEmptyFiltered => 'Ninguna tarea coincide';
  @override
  String get todoTitle => 'Tareas';
  @override
  String get todoAddTooltip => 'Añadir tarea';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'El formato todo.txt';
  @override
  String get todoHelpTooltip => 'Ayuda del formato';
  @override
  String get todoHelpIntro =>
      'Tus tareas son un único archivo de texto plano, una tarea por '
      'línea. Niman escribe la sintaxis por ti, pero nada está oculto: '
      'puedes editar el archivo en cualquier editor y Niman lo volverá '
      'a leer.';
  @override
  String get todoHelpFilesTitle => 'Los dos archivos';
  @override
  String get todoHelpFilesBody =>
      'Las tareas pendientes están en todo.txt en la raíz de tu '
      'biblioteca. Al completar una, su línea pasa a done.txt, para que '
      'todo.txt se mantenga corto. Si una línea completada vuelve a '
      'todo.txt, Niman la archiva la próxima vez que lea los archivos.';
  @override
  String get todoHelpLineTitle => 'Anatomía de una línea';
  @override
  String get todoHelpLineBody =>
      'Todo lo que precede a la descripción es opcional y debe ir en '
      'este orden:';
  @override
  String get todoHelpDoneBody =>
      'Marca la tarea como hecha. Niman la añade cuando marcas la '
      'casilla.';
  @override
  String get todoHelpPriority => 'de (A) a (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioridad. A es la más alta. Aparece como insignia en la lista.';
  @override
  String get todoHelpDatesBody =>
      'Fecha de completar y luego fecha de creación. Con una sola fecha '
      'es la de creación, a menos que la línea empiece con x.';
  @override
  String get todoHelpTokensTitle => 'Proyectos, contextos y etiquetas';
  @override
  String get todoHelpTokensBody =>
      'En cualquier punto de la descripción, una palabra con uno de '
      'estos prefijos se convierte en una ficha por la que puedes '
      'filtrar. Nada está predefinido: un token existe en cuanto lo '
      'escribes.';
  @override
  String get todoHelpProjectBody =>
      'De qué forma parte la tarea, por ejemplo +cocina o +tesis.';
  @override
  String get todoHelpContextBody =>
      'Dónde o cómo la harás, por ejemplo @casa o @llamadas.';
  @override
  String get todoHelpHashtagBody =>
      'Una etiqueta libre, para todo lo que las otras dos no cubren.';
  @override
  String get todoHelpTagsTitle => 'Fechas y recordatorios';
  @override
  String get todoHelpTagsBody =>
      'Son etiquetas clave:valor. Niman las escribe desde el diálogo de '
      'la tarea y las lee dondequiera que aparezcan en la línea.';
  @override
  String get todoHelpDueBody =>
      'La fecha límite. Dirige la insignia de color y los filtros por '
      'fecha.';
  @override
  String get todoHelpRemBody =>
      'Cuándo enviar una notificación, en tu hora local. Se dispara con '
      'la pantalla apagada y la app cerrada.';
  @override
  String get todoHelpRemDesktop =>
      'En escritorio Niman debe estar abierto cuando llega el momento: el '
      'recordatorio se muestra mientras la app está abierta, y no se '
      'dispara nada con ella cerrada.';
  @override
  String get todoHelpOtherBody =>
      'Se conservan exactamente como se escribieron, para que las '
      'etiquetas de otras apps todo.txt sobrevivan al viaje. Niman no '
      'actúa sobre ellas, rec: incluida: una tarea recurrente aún no se '
      'repite.';
  @override
  String get todoHelpEditTitle => 'Edición fuera de Niman';
  @override
  String get todoHelpEditBody =>
      'Una tarea que no has tocado se reescribe byte a byte, espacios '
      'raros incluidos. Edita una línea y Niman reescribe solo esa en su '
      'forma canónica, dejando el resto del archivo tal cual.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Añadir tarea';
  @override
  String get todoEditTitle => 'Editar tarea';
  @override
  String get todoDescriptionHint => 'Descripción';
  @override
  String get todoCancel => 'Cancelar';
  @override
  String get todoSave => 'Guardar';
  @override
  String get todoEditAction => 'Editar';
  @override
  String get todoDeleteAction => 'Eliminar';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Vencidas';
  @override
  String get todoDueToday => 'Hoy';
  @override
  String get todoDueNext7 => 'Próximos 7 días';
  @override
  String get todoDueNoDate => 'Sin fecha';
  @override
  String get todoRowDue => 'Vence';
  @override
  String get todoRowDueToday => 'Vence hoy';
  @override
  String get todoSortTooltip => 'Ordenar';
  @override
  String get todoSortDue => 'Fecha límite';
  @override
  String get todoSortPriority => 'Prioridad';
  @override
  String get todoSortCreation => 'Fecha de creación';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Sin prioridad';
  @override
  String get todoNoPriorityShort => 'Ninguna';
  @override
  String get todoMorePriorities => 'Más…';
  @override
  String get todoPriorityTitle => 'Prioridad';
  @override
  String get todoNoDueDate => 'Sin fecha límite';
  @override
  String get todoNoReminder => 'Sin recordatorio';
  @override
  String get todoAddProject => '+ Proyecto';
  @override
  String get todoAddContext => '@ Contexto';
  @override
  String get todoAddHashtag => '# Etiqueta';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Recordatorios de tareas';
  @override
  String get todoReminderChannelDescription =>
      'Alertas programadas para tareas con hora de recordatorio.';
  @override
  String get todoReminderBody => 'Recordatorio de tarea';
  @override
  String get todoReminderFallbackTitle => 'Recordatorio de tarea';
  @override
  String get todoReminderBlocked =>
      'Las notificaciones están desactivadas, por lo que los '
      'recordatorios no aparecerán.';
  @override
  String get todoReminderBattery =>
      'La optimización de batería está activa para Niman. El sistema '
      'puede poner la app en suspensión y perder recordatorios '
      'pendientes.';
  @override
  String get todoReminderInexact =>
      'Este dispositivo no permite alarmas exactas, por lo que un '
      'recordatorio puede llegar con varios minutos de retraso con la '
      'pantalla apagada.';
  @override
  String get reminderShowTokensTitle =>
      'Etiquetas en las notificaciones de recordatorio';
  @override
  String get reminderShowTokensSubtitle =>
      'Mantiene +proyecto, @contexto y #tag en el texto de la '
      'notificación. Off solo muestra la tarea que escribiste.';
  @override
  String get todoReminderFixAction => 'Abrir ajustes';
  @override
  String get todoReminderDismissAction => 'Descartar';
  @override
  String get todoReminderDue => 'Vence';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Cancelar';
  @override
  String get actionCreate => 'Crear';
  @override
  String get actionNew => 'Nuevo';
  @override
  String get actionSave => 'Guardar';
  @override
  String get actionClear => 'Vaciar';
  @override
  String get actionChoose => 'Elegir';
  @override
  String get actionDelete => 'Eliminar';
  @override
  String get actionRename => 'Renombrar';
  @override
  String get actionMove => 'Mover';
  @override
  String get saveAndClose => 'Guardar y cerrar';
  @override
  String get closeUnsavedTitle => 'Cambios sin guardar';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '«${names.first}» tiene cambios que aún no se guardaron. '
          '¿Guardarlos antes de cerrar?';
    }
    return '$names.length notas tienen cambios que aún no se guardaron. '
        '¿Guardarlos antes de cerrar?';
  }

  @override
  String get closeSaveFailed => 'No se pudo guardar; sigue abierta.';
  @override
  String get actionRestore => 'Restaurar';
  @override
  String get actionEmpty => 'Vaciar';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ocultar el panel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Mostrar el panel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizar';
  @override
  String get windowMaximizeTooltip => 'Maximizar';
  @override
  String get windowRestoreTooltip => 'Restaurar';
  @override
  String get windowCloseTooltip => 'Cerrar';
  @override
  String get tabFiles => 'Archivos';
  @override
  String get tabSearch => 'Buscar';
  @override
  String get tabSettings => 'Ajustes';
  @override
  String get quickNoteTitle => 'Nota rápida';
  @override
  String get treeEmpty => 'Aún no hay notas';
  @override
  String get selectANote => 'Selecciona una nota';
  @override
  String get showListTooltip => 'Mostrar lista';
  @override
  String get editRawTooltip => 'Editar la fuente';
  @override
  String get sortAscTooltip => 'Ordenar A-Z';
  @override
  String get sortDescTooltip => 'Ordenar Z-A';
  @override
  String get newNoteTitle => 'Nueva nota';
  @override
  String get newItemTooltip => 'Nuevo';
  @override
  String get closeMenuTooltip => 'Cerrar';
  @override
  String get newFolderTitle => 'Nueva carpeta';
  @override
  String get newNoteSameFolder => 'Nueva nota en la misma carpeta';
  @override
  String get newFromTemplateSameFolder =>
      'Nueva desde plantilla en la misma carpeta';
  @override
  String trashOriginalPath(String path) => 'estaba en $path';
  @override
  String get trashOriginalRoot => 'estaba en la ra\u00edz de la biblioteca';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 elemento' : '$count elementos';
  @override
  String get newNoteHere => 'Nueva nota aquí';
  @override
  String get newFolderHere => 'Nueva carpeta aquí';
  @override
  String get newListNoteTitle => 'Nueva nota-lista';
  @override
  String get newListNoteDefault => 'Mi lista';
  @override
  String get setAsQuickNote => 'Fijar como nota rápida';
  @override
  String get currentQuickNote => 'Nota rápida actual';
  @override
  String get pinnedSection => 'Fijadas';
  @override
  String pinnedSectionCount(int count) => 'Fijadas · $count';
  @override
  String get templateFolderTitle => 'Carpeta de plantillas';
  @override
  String get newFromTemplateTitle => 'Nueva desde plantilla';
  @override
  String get newFromTemplateHere => 'Nueva desde plantilla aquí';
  @override
  String get templateFormTitle => 'Rellenar la plantilla';
  @override
  String get templateFormBacklink => 'Enlazada desde';
  @override
  String get templateFormNoNote => 'Sin nota';
  @override
  String get templateFormPickNote => 'Elegir la nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Marcadores de posición de las plantillas';
  @override
  String get templateHelpSubtitle =>
      'Fecha, título y los demás valores por rellenar';
  @override
  String get quickNoteSubtitle => 'La nota que abre la pestaña Nota rápida';
  @override
  String get listFolderSubtitle => 'Las listas nuevas de tareas';
  @override
  String get templateFolderSubtitle => 'El origen de «Nueva desde plantilla»';
  @override
  String get attachmentsFolderSubtitle =>
      'Imágenes y audio insertados en una nota';
  @override
  String get templateHelpIntro =>
      'Una plantilla es una nota ordinaria con huecos. Crear una nota '
      'desde una copia su texto y rellena los huecos.';
  @override
  String get templateHelpUnknown =>
      'Un marcador que Niman no conoce queda tal como está escrito, para '
      'que un error de tecleo se vea en la nota en vez de tragar una '
      'línea en silencio.';
  @override
  String get templateHelpValuesTitle => 'Valores';
  @override
  String get templateHelpTitleBody =>
      'El nombre con el que se va a crear la nota.';
  @override
  String get templateHelpDateBody =>
      'Hoy, y la hora ahora. Ambos aceptan un formato: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'La fecha y la hora juntas.';
  @override
  String get templateHelpUuidBody =>
      'Un identificador nuevo, distinto en cada aparición.';
  @override
  String get templateHelpCounterBody =>
      'Un número que cuenta por nombre y se conserva entre reinicios: la '
      'primera nota escribe 1, la siguiente 2. El mismo nombre en una '
      'nota escribe el mismo número; combínalo con |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Coloca el cursor aquí cuando se crea la nota; el marcador no se '
      'escribe. Gana el primer marcador, sin filtros, solo notas '
      'nuevas — y el teclado se abre incluso con el auto-enfoque '
      'apagado.';
  @override
  String get templateHelpDatesTitle => 'Escribir una fecha';
  @override
  String get templateHelpDatesBody =>
      'Estos representan partes de la fecha dentro de un formato. Todo '
      'lo demás es literal, y también el texto entre comillas simples. '
      'Los nombres de mes y de día siguen el idioma de la app.';
  @override
  String get templateHelpYear => 'el año: 2026, 26';
  @override
  String get templateHelpMonth => 'el mes: 03, 3, marzo, mar.';
  @override
  String get templateHelpDay => 'el día: 09, 9, lunes, lun.';
  @override
  String get templateHelpTime => 'horas, minutos, segundos';
  @override
  String get templateHelpWeek => 'la semana ISO y el trimestre: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtros';
  @override
  String get templateHelpFiltersBody =>
      'Un valor puede ir seguido de filtros, aplicados de izquierda a '
      'derecha.';
  @override
  String get templateHelpCaseBody =>
      'Mayúsculas, minúsculas, y la primera letra de cada palabra — una '
      'palabra que capitalizaste tú queda como está.';
  @override
  String get templateHelpSlugBody =>
      'La forma de enlace del texto, para construir un wikilink.';
  @override
  String get templateHelpPadBody =>
      'Recorta los extremos; rellena con ceros hasta un ancho; usa un '
      'respaldo cuando el valor está vacío.';
  @override
  String get templateHelpShiftBody =>
      'Desplaza una fecha de días, semanas, meses o años — la clase de '
      'la semana próxima, el archivo del mes pasado.';
  @override
  String get templateHelpSnapBody =>
      'Ajusta una fecha al principio o al final de su semana, mes o año.';
  @override
  String get templateHelpAskTitle => 'Pedirte algo';
  @override
  String get templateHelpAskBody =>
      'Antes de crear la nota aparece un formulario, una caja por '
      'pregunta — y una para el enlace inverso, cuando la plantilla lo '
      'pide. La misma etiqueta dos veces es una sola pregunta, y su '
      'respuesta rellena cada aparición — la carpeta y el nombre del '
      'archivo incluidos.';
  @override
  String get templateHelpAskFieldBody =>
      'Una caja para escribir; el texto tras los dos puntos dobles es '
      'con el que empieza.';
  @override
  String get templateHelpChoiceBody =>
      'Una elección de una lista, separada por comas.';
  @override
  String get templateHelpWhereTitle => 'Dónde va la nota';
  @override
  String get templateHelpWhereBody =>
      'No son texto: son instrucciones, y viven en un bloque niman: del '
      'frontmatter propio de la plantilla. El bloque se ejecuta y luego '
      'se retira, por lo que nunca aparece en la nota. Sus valores '
      'pueden contener marcadores.';
  @override
  String get templateHelpFolderBody =>
      'La carpeta en la que se crea la nota, creada si no existe. Sin '
      'ella, la nota llega a donde estabas.';
  @override
  String get templateHelpFilenameBody =>
      'Cómo se llama la nota. A una plantilla que lo declara no se le '
      'pide el nombre.';
  @override
  String get templateHelpAppendBody =>
      'Añade a la nota si ya existe, en vez de crear una segunda. Esto '
      'convierte un mes de reuniones en un solo archivo.';
  @override
  String get templateHelpOpenBody =>
      'Lo que pasa cuando la nota existe: el editor (el valor '
      'predeterminado), la vista previa, o nada — la nota se archiva y '
      'tú sigues donde estabas.';
  @override
  String get templateHelpAroundTitle => 'De dónde viene';
  @override
  String get templateHelpParentBody =>
      'Una nota que eliges en el formulario, que te propone la que está '
      'en pantalla; escribe [[{{parent}}]] para un enlace de vuelta.';
  @override
  String get templateHelpFolderValueBody =>
      'La carpeta en la que ha acabado la nota.';
  @override
  String get templateHelpClipboardBody =>
      'Lo que hay en el portapapeles, y la selección del editor cuando la '
      'nota se inició desde una.';
  @override
  String get templateHelpIncludeTitle => 'Reutilizar un trozo';
  @override
  String get templateHelpIncludeBody =>
      'Pega otra plantilla, para que diez plantillas compartan una única '
      'lista de verificación. Se busca primero en la carpeta de '
      'plantillas, y la .md puede omitirse. Sus propias preguntas se '
      'unen al mismo formulario.';
  @override
  String get templateHelpExampleTitle => 'Todo junto';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ no hay plantilla «$path»';
  @override
  String includeCycle(String path) => '⚠ «$path» se incluye a sí misma';
  @override
  String includeTooDeep(String path) =>
      '⚠ «$path» está anidada demasiado profundamente';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter no leído: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'El frontmatter de «$template» no se leyó, por lo que su carpeta y '
      'su nombre de archivo no hicieron nada: $reason';
  @override
  String get templatePickerTitle => 'Elegir una plantilla';
  @override
  String templatePickerEmpty(String folder) =>
      'Aún no hay plantillas. Pon una nota en $folder/ y se convierte en '
      'una.';

  // Tree actions.
  @override
  String get actionPin => 'Fijar';
  @override
  String get actionUnpin => 'Dejar de fijar';
  @override
  String get pinToWidget => 'Fijar en el widget de inicio';
  @override
  String get pinnedForWidget =>
      'Fijada: ahora coloca el widget de Nota en la pantalla de inicio';
  @override
  String get pinWidgetUnavailable =>
      'Los widgets de la pantalla de inicio están disponibles en Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Mostrar en el gestor de archivos';
  @override
  String get openInDefaultApp => 'Abrir con la app predeterminada';
  @override
  String get newNoteTabTooltip => 'Nota nueva en una pestaña nueva';
  @override
  String get openNotesTooltip => 'Notas abiertas';
  @override
  String get closeTabTooltip => 'Cerrar';
  @override
  String get openInNewTab => 'Abrir en una pestaña nueva';
  @override
  String get splitRight => 'Dividir a la derecha';
  @override
  String get splitDown => 'Dividir hacia abajo';
  @override
  String get moveToOtherPane => 'Mover al otro panel';
  @override
  String get openBeside => 'Abrir al lado';
  @override
  String get closeAllNotes => 'Cerrar todas';
  @override
  String get sidePanelTooltip => 'Mostrar u ocultar el panel lateral';
  @override
  String get historyAllVersions => 'Todas las versiones';
  @override
  String get commandPaletteTitle => 'Paleta de comandos';
  @override
  String get goToNoteTitle => 'Ir a la nota';
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
  String get commandsTitle => 'Comandos';
  @override
  String get commandsIntro =>
      'La paleta de comandos ofrece solo los comandos que se pueden ejecutar '
      'donde estás. Aquí están todos, y cuándo aparece cada uno.';
  @override
  String get commandsKeysNote =>
      'Aquí no se cambia nada. Las teclas son las definidas en Atajos de '
      'teclado y siguen cualquier cambio hecho allí.';
  @override
  String get commandsOpenShortcuts => 'Cambiar las teclas en Atajos de teclado';
  @override
  String get commandsChangeKeyTooltip => 'Cambiar en Atajos de teclado';
  @override
  String get commandsSubtitle =>
      'Lo que puede ejecutar la paleta de comandos, y cuándo';
  @override
  String get keyboardShortcutsSubtitle => 'Cambia las teclas de cada comando';
  @override
  String get commandNeedNone => 'Siempre disponible';
  @override
  String get commandNeedOpenNote => 'Necesita una nota abierta';
  @override
  String get commandNeedWideWindow => 'Solo con ventana ancha';
  @override
  String get commandNeedDockRoom =>
      'Necesita una ventana lo bastante ancha para el panel lateral';
  @override
  String get commandNeedDesktop => 'Solo en escritorio';
  @override
  String get commandNeedNotInZen => 'Fuera del modo Zen';
  @override
  String get commandNeedZenRoom =>
      'Escritorio, con una nota abierta en una pestaña';
  @override
  String get commandNeedPreview =>
      'Con la vista previa activada, en una nota de texto';
  @override
  String get commandNeedTwoEditors => 'Con ambos editores activados';
  @override
  String get paletteHint => 'Buscar comandos y notas';
  @override
  String get paletteNoResults => 'Sin coincidencias';
  @override
  String get paletteCommands => 'Comandos';
  @override
  String get paletteNotes => 'Notas';
  @override
  String get paletteFooter => '↑↓ para moverte · ↵ para usar · esc para cerrar';
  @override
  String get paletteFooterTouch =>
      'Toca para usar · el alfiler lo mantiene arriba';
  @override
  String get palettePinned => 'Fijados';
  @override
  String get palettePin => 'Fijar';
  @override
  String get paletteUnpin => 'Quitar';
  @override
  String get palettePinFooter => 'alt+P para fijar';
  @override
  String get spellCheckScanning => 'Revisando la nota…';
  @override
  String get spellCheckAgain => 'Revisar de nuevo';
  @override
  String spellCheckCapped(int count) =>
      'Se muestran los primeros $count: corrige algunos y vuelve a revisar '
      'para ver el resto';
  @override
  String get dropHint =>
      'Suelta archivos Markdown para abrirlos, o una carpeta para importarla';
  @override
  String get dropNothing =>
      'El escritorio no entregó ningún archivo en ese arrastre.';
  @override
  String get importFolderAction => 'Importar';
  @override
  String dropRejected(String names) =>
      'Aquí solo se abren archivos Markdown y carpetas: $names';
  @override
  String importFolderTitle(String name) => '¿Importar «$name»?';
  @override
  String importFolderBody(int count) =>
      'Sus archivos Markdown ($count) se copian en una carpeta nueva de la '
      'biblioteca. La carpeta que soltaste queda como está.';
  @override
  String importFolderDone(String folder) => 'Importado en $folder';
  @override
  String importFolderEmpty(String name) => 'No hay archivos Markdown en $name';
  @override
  String get openFileTitle => 'Abrir archivo';
  @override
  String get outsideFileNote =>
      'Fuera de toda biblioteca: se guarda donde está, sin índice, sin '
      'historial, los enlaces no se siguen';
  @override
  String get typewriterOn => 'Activar el modo máquina de escribir';
  @override
  String get typewriterOff => 'Desactivar el modo máquina de escribir';
  @override
  String get typewriterTitle => 'Modo máquina de escribir';
  @override
  String get formatNoteTitle => 'Ordenar el Markdown';
  @override
  String get formatNoteDone => 'La nota se ha ordenado.';
  @override
  String get formatNoteAlreadyTidy => 'La nota ya estaba ordenada.';
  @override
  String get typewriterSubtitle =>
      'Mantén la línea que escribes en el centro del editor';
  @override
  String get zenMode => 'Modo zen';
  @override
  String get zenModeEnter => 'Entrar en modo zen';
  @override
  String get zenModeLeave => 'Salir del modo zen';
  @override
  String get keySpace => 'Espacio';
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
  String get keyArrowDown => 'Abajo';
  @override
  String get keyArrowLeft => 'Izquierda';
  @override
  String get keyArrowRight => 'Derecha';
  @override
  String get keyHome => 'Inicio';
  @override
  String get keyEnd => 'Fin';
  @override
  String get keyPageUp => 'Re Pág';
  @override
  String get keyPageDown => 'Av Pág';
  @override
  String get keyInsert => 'Insert';
  @override
  String get shortcutNone => 'Sin atajo';
  @override
  String get shortcutRestoreDefaults => 'Restaurar predeterminados';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      '¿Devolver todos los atajos a como los trae Niman?';
  @override
  String get shortcutRevert => 'Volver al predeterminado';
  @override
  String get shortcutClear => 'Quitar el atajo';
  @override
  String get shortcutCapturePrompt =>
      'Pulsa las teclas. Esc y Tab también se capturan: sal con Cancelar.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Añade Ctrl, Alt o Meta: una tecla sola es para escribir.';
  @override
  String get shortcutMove => 'Moverlo';
  @override
  String get shortcutUseAnyway => 'Usar de todos modos';
  @override
  String get shortcutUndo => 'Deshacer';
  @override
  String get shortcutRedo => 'Rehacer';
  @override
  String get shortcutChange => 'Cambiar el atajo';
  @override
  String shortcutCaptureTitle(String command) => 'Teclas para $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys ya es de $other. ¿Moverlo aquí? $other se quedará sin atajo.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys también es $what en los campos de texto y el editor. Allí lo '
      'tomará tu comando.';
  @override
  String get openFileMissing => 'El archivo de esta nota no está en el disco';
  @override
  String get openFileFailed => 'No se pudo abrir esta nota fuera de Niman';

  @override
  String get movedToTrash => 'Movido a la papelera';
  @override
  String get deletedMessage => 'Eliminado';
  @override
  String deleteToTrashConfirm(String name) => '$name se moverá a .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name se eliminará permanentemente';
  @override
  String get chooseDestination => 'Elegir el destino';
  @override
  String get libraryRoot => 'Raíz de la biblioteca';
  @override
  String moveTitle(String name) => 'Mover $name';
  @override
  String headingLevelLabel(int level) => 'Título nivel $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Aún no hay nota rápida. Elige una existente o crea una nueva: la '
      'nota rápida se abre aquí.';
  @override
  String get quickNoteChooseAction => 'Elegir una nota…';
  @override
  String get quickNoteCreateAction => 'Crear una nota nueva…';
  @override
  String get quickNoteNewTitle => 'Nueva nota rápida';
  @override
  String get quickNotePickerTitle => 'Elegir la nota rápida';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nueva carpeta';
  @override
  String get folderPickerEmpty => 'Aún no hay carpetas';
  @override
  String get listFolderTitle => 'Carpeta de listas';
  @override
  String get attachmentsFolderTitle => 'Carpeta de adjuntos';

  // Trash (M1).
  @override
  String get trashEmpty => 'La papelera está vacía';
  @override
  String get trashEmptyAction => 'Vaciar la papelera';
  @override
  String get trashEmptyConfirm =>
      'Esto borra permanentemente todo lo que hay en la papelera, '
      'incluidos los elementos que Niman no puso ahí.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se eliminará permanentemente (sin restauración)';
  @override
  String get trashDeletePermanently => 'Eliminar permanentemente';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Abre una carpeta de notas Markdown como tu biblioteca';
  @override
  String get openLibraryExisting => 'Abrir existente';
  @override
  String get openLibraryCreate => 'Crear nueva';
  @override
  String get openLibraryCreateTitle => 'Crear una biblioteca nueva';
  @override
  String get openLibraryFolderName => 'Nombre de la carpeta';
  @override
  String get openLibraryChooseFolder => 'Elegir la carpeta de la biblioteca';
  @override
  String get openLibraryChooseParent =>
      'Elegir la carpeta en la que se creará la biblioteca';
  @override
  String get openLibraryUnsupported =>
      'Esa carpeta no está soportada. Elige una carpeta del almacenamiento '
      'del dispositivo.';
  @override
  String indexingCount(int done, int total) => '$done de $total notas';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Tus bibliotecas';
  @override
  String get libraryUnreachable => 'No accesible';
  @override
  String get libraryOpenedToday => 'Abierta hoy';
  @override
  String get libraryOpenedYesterday => 'Abierta ayer';
  @override
  String libraryOpenedDaysAgo(int days) => 'Abierta hace $days días';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Abierta el $d/$m/${when.year}';
  }

  @override
  String get libraryOpenNow => 'Abrir ahora';
  @override
  String get switchLibraryTitle => 'Cambiar de biblioteca';
  @override
  String get libraryForget => 'Olvidar';
  @override
  String libraryForgetTitle(String name) => '¿Olvidar «$name»?';
  @override
  String get libraryForgetExplained =>
      'Sale de esta lista. La carpeta, las notas y los ajustes de la '
      'biblioteca se quedan donde están, y al abrirla vuelve a aparecer.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Conceder el acceso a los archivos';
  @override
  String get storageAccessNeeded =>
      'Sin el «acceso a todos los archivos», Niman no puede leer tus '
      'notas. Concedérmelo para abrir una biblioteca.';
  @override
  String get storageAccessExplained =>
      'Niman lee tus notas como archivos ordinarios, por lo que Android '
      'debe permitirle el acceso a todos los archivos. No se sube nada, '
      'y solo se lee la carpeta de la biblioteca que elijas.';
  @override
  String folderAccessDenied(Object error) =>
      'El sistema no dio acceso a la carpeta: $error';
  @override
  String folderPickFailed(Object error) =>
      'No se pudo elegir la carpeta: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get libraryPathTitle => 'Ruta de la biblioteca';
  @override
  String get reindexTitle => 'Reindexar ahora';
  @override
  String get reindexDone => 'Reindexación completada';
  @override
  String get closeLibraryTitle => 'Cerrar la biblioteca';
  @override
  String get exportLogTitle => 'Exportar el registro de depuración';
  @override
  String get exportLogSubtitle =>
      'Guarda los eventos registrados en un archivo a tu elección';
  @override
  String get exportLogEmpty => 'El búfer del registro de depuración está vacío';
  @override
  String get quickNoteUnset => 'Aún no fijada';
  @override
  String exportLogDone(Object target) =>
      'Registro de depuración exportado a $target';
  @override
  String exportLogFailed(Object error) => 'Error al exportar: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'No se encontró ninguna palabra completa «$term»';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences ocurrencia(s) de «$term» reemplazadas en $notes '
      'nota(s)';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped nota(s) abierta(s) omitidas)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'No hay ninguna palabra completa exacta «$term» '
      '${only == null ? 'encontrada' : 'encontrada en $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Acerca de';
  @override
  String get versionTitle => 'Versión';
  @override
  String get changelogTitle => 'Registro de cambios';
  @override
  String get changelogEmpty => 'No hay entradas de registro disponibles';
  @override
  String changelogWhatsNew(String version) =>
      'Novedades en la versión $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historial';
  @override
  String get noteMenuTooltip => 'Acciones de la nota';
  @override
  String get historyCurrentVersion => 'Versión actual';
  @override
  String get historyCurrentSubtitle => 'La nota tal como está ahora';
  @override
  String get historyToday => 'Hoy';
  @override
  String get historyYesterday => 'Ayer';
  @override
  String get historyReasonSession => 'antes de editar';
  @override
  String get historyReasonInterval => 'durante la edición';
  @override
  String get historyReasonRestore => 'antes de restaurar';
  @override
  String get historyReasonSync => 'antes de sincronizar';
  @override
  String get historyReasonReplace => 'antes de reemplazar';
  @override
  String get historyReasonUnknown => 'recuperada';
  @override
  String get historySyncBase => 'base de sincronización';
  @override
  String get historyEmpty =>
      'Aún no hay versiones. Niman guarda una cuando empiezas a editar la '
      'nota y luego, como mucho, una cada pocos minutos mientras escribes.';
  @override
  String historyKept(int kept, int limit) => '$kept de $limit versiones';
  @override
  String get historyBaseKept =>
      'La base de sincronización se conserva aunque supere el límite.';
  @override
  String get historyOff =>
      'El historial está desactivado en esta biblioteca '
      '(Ajustes, Biblioteca).';
  @override
  String get historyLoadFailed => 'No se pudo leer el historial';
  @override
  String get historyCompareSubtitle => 'Comparada con la versión actual';
  @override
  String get historyTabChanges => 'Cambios';
  @override
  String get historyTabVersion => 'Versión';
  @override
  String get historyNoChanges => 'El mismo texto que la versión actual.';
  @override
  String get historyRestoreAction => 'Restaurar esta versión';
  @override
  String historyRestoreConfirmTitle(String when) =>
      '¿Restaurar la versión de $when?';
  @override
  String get historyRestoreConfirmBody =>
      'Antes se guarda el texto actual en el historial, así que siempre '
      'puedes volver atrás.';
  @override
  String get historyRestoreConfirm => 'Restaurar';
  @override
  String historyRestored(String when) => 'Versión de $when restaurada';
  @override
  String get historyRestoreFailed => 'No se pudo restaurar la versión';
  @override
  String get actionUndo => 'Deshacer';
  @override
  String diffLineRange(int start, int end) => 'Líneas $start–$end';
  @override
  String diffLineSingle(int line) => 'Línea $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 línea sin cambios' : '$count líneas sin cambios';
  @override
  String get historyTakeHunk => 'Restaurar aquí';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Restaurar 1 cambio' : 'Restaurar $count cambios';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Los cambios elegidos vuelven al texto de esta versión. La nota tal como '
      'está ahora se conserva antes como versión, así que puedes deshacerlo.';
  @override
  String get historyNoteChangedReloaded =>
      'La nota cambió mientras estabas aquí: la comparación se ha actualizado.';
  @override
  String get historyVersionsTitle => 'Versiones que conservar';
  @override
  String get historyVersionsSubtitle => 'Por nota, en .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Ninguna' : '$count';
  @override
  String get historyIntervalTitle => 'Nueva versión como máximo cada';
  @override
  String get historyIntervalSubtitle =>
      'Mientras escribes; empezar a editar una nota siempre guarda una';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcripción';
  @override
  String get transcriptionModelTitle => 'Modelo';
  @override
  String get transcriptionModelNone => 'Ninguno';
  @override
  String get transcriptionLanguageTitle => 'Idioma';
  @override
  String get transcriptionLanguageSubtitle =>
      'El idioma que se habla en tus grabaciones. Indicarlo es más preciso '
      'que detectarlo.';
  @override
  String transcriptionLanguageApp(String language) => 'Como la app ($language)';
  @override
  String get transcriptionLanguageDetect => 'Detectar automáticamente';
  @override
  String get transcriptionModelsTitle => 'Modelos de transcripción';
  @override
  String transcriptionModelsUsed(String size) => '$size en uso';
  @override
  String get transcriptionModelsInstalled => 'Descargados';
  @override
  String get transcriptionModelsDownloading => 'Descargando';
  @override
  String get transcriptionModelsAvailable => 'Disponibles';
  @override
  String get transcriptionModelsFooter =>
      'Los modelos se quedan en el almacenamiento de la app en este '
      'dispositivo. No se copian a la biblioteca ni se sincronizan.';
  @override
  String get transcriptionModelDefault => 'Predeterminado';
  @override
  String get transcriptionModelSlow => 'Lento';
  @override
  String get transcriptionModelHintTiny => 'El más rápido, el menos preciso';
  @override
  String get transcriptionModelHintBase =>
      'Buen equilibrio entre velocidad y precisión';
  @override
  String get transcriptionModelHintSmall => 'Más preciso, unas 3× más lento';
  @override
  String get transcriptionModelHintMedium =>
      'Muy preciso, lento en un teléfono';
  @override
  String get transcriptionModelHintLarge =>
      'El más preciso, necesita mucha memoria';
  @override
  String get transcriptionModelDownload => 'Descargar';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      '¿Eliminar el modelo $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Libera $size. Puedes volver a descargar el modelo más adelante.';
  @override
  String get transcriptionModelFailed =>
      'No se pudo descargar. Comprueba la conexión y vuelve a intentarlo.';
  @override
  String get actionRetry => 'Reintentar';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Conexión perdida, reintentando…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'En pausa en $progress';
  @override
  String get actionResume => 'Reanudar';
  @override
  String get audioTranscribe => 'Transcribir';
  @override
  String get audioTranscribeUnsupported =>
      'Solo grabaciones WAV en este dispositivo';
  @override
  String get transcriptionQueued => 'En cola';
  @override
  String get transcriptionPreparing => 'Preparando el audio…';
  @override
  String transcriptionRunning(int percent) => 'Transcribiendo… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Descargando $model · $percent %';
  @override
  String get transcriptionSaved => 'Transcripción añadida a la descripción';
  @override
  String get transcriptionNoSpeech => 'No se reconoció voz en esta grabación';
  @override
  String get transcriptionFailed => 'No se pudo transcribir';
  @override
  String get transcriptionPickModelTitle => 'Elige un modelo';
  @override
  String get transcriptionPickModelBody =>
      'La transcripción se hace en este dispositivo y la grabación nunca se '
      'sube. El modelo se descarga una sola vez.';
  @override
  String get transcriptionPickModelAction => 'Descargar y transcribir';
  @override
  String get transcriptionModelRecommended => 'Recomendado';
  @override
  String get transcriptionExistingTitle =>
      'Esta grabación ya tiene una descripción';
  @override
  String get transcriptionExistingBody =>
      '¿Reemplazarla por la transcripción o añadir la transcripción debajo?';
  @override
  String get transcriptionAppend => 'Añadir debajo';
  @override
  String get transcriptionReplace => 'Reemplazar';
  @override
  String get settingsSectionSync => 'Sincronización';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Sin configurar en esta biblioteca';
  @override
  String get syncNeverSynced => 'Nunca sincronizada';
  @override
  String syncLastSynced(String when) => 'Sincronizada $when';
  @override
  String get syncRunning => 'Sincronizando…';
  @override
  String syncScreenSubtitle(String library) => 'Biblioteca $library';
  @override
  String get syncUrlLabel => 'Dirección de la carpeta';
  @override
  String get syncUrlRequired => 'Introduce la dirección del servidor';
  @override
  String get syncUrlHint =>
      'La carpeta debe existir. Copia la dirección tal como la '
      'muestra el servidor.';
  @override
  String get syncHttpWarning =>
      'Conexión sin cifrar: está bien en una VPN o en tu red '
      'local.';
  @override
  String get syncUserLabel => 'Usuario';
  @override
  String get syncUserHint =>
      'Déjalo vacío si el servidor no pide credenciales.';
  @override
  String get syncPasswordLabel => 'Contraseña';
  @override
  String get syncPasswordHint =>
      'Se guarda en el llavero de este dispositivo, nunca en los '
      'archivos de la biblioteca.';
  @override
  String get syncPasswordKeepHint =>
      'Déjala vacía para mantener la contraseña guardada.';
  @override
  String get syncShowPassword => 'Mostrar contraseña';
  @override
  String get syncHidePassword => 'Ocultar contraseña';
  @override
  String get syncTestAction => 'Probar conexión';
  @override
  String get syncTesting => 'Probando…';
  @override
  String get syncRetargetWarning =>
      'Con otra dirección u otro usuario, la próxima '
      'sincronización empieza de nuevo como la primera.';
  @override
  String get syncTestOk => 'La conexión funciona';
  @override
  String get syncModeFull => 'Modo completo';
  @override
  String get syncModeCompatible => 'Modo compatible';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lectura, escritura y borrado';
  @override
  String get syncCapEtags => 'Huellas de archivo (ETags)';
  @override
  String get syncCapNoEtags => 'Sin huellas de archivo (ETags)';
  @override
  String get syncCapNoEtagsDetail =>
      'Compara tamaño y fecha; ante la duda, vuelve a descargar';
  @override
  String get syncCapGuarded => 'Escrituras protegidas';
  @override
  String get syncCapUnguarded => 'Escrituras sin protección';
  @override
  String get syncCapUnguardedDetail =>
      'Comprueba el archivo en el servidor justo antes de '
      'escribir';
  @override
  String get syncCapMove => 'Renombra sin volver a subir';
  @override
  String get syncCapNoMove => 'Sin renombrado en el servidor';
  @override
  String get syncCapNoMoveDetail =>
      'Un renombrado se convierte en un borrado y una nueva '
      'subida';
  @override
  String get syncCompatibleNote =>
      'En modo compatible la sincronización funciona igual, con '
      'algunas peticiones más.';
  @override
  String get syncTestInvalidUrl => 'Dirección no válida';
  @override
  String get syncTestInvalidUrlHint =>
      'Escribe una dirección http:// o https://, sin usuario ni '
      'contraseña dentro.';
  @override
  String get syncTestOffline => 'Servidor no accesible';
  @override
  String get syncTestOfflineHint =>
      '¿Está activa la VPN? Una dirección 10.x o 192.168.x solo '
      'funciona desde la misma red.';
  @override
  String get syncTestAuth => 'Usuario o contraseña rechazados';
  @override
  String get syncTestAuthHint => 'Revísalos y vuelve a probar.';
  @override
  String get syncTestNotFound => 'La carpeta no existe';
  @override
  String get syncTestNotFoundHint =>
      'Créala en el servidor o corrige la dirección.';
  @override
  String get syncTestUnsupported => 'No es una carpeta WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'El servidor responde, pero no como WebDAV.';
  @override
  String get syncTestFailed => 'La prueba no funcionó';
  @override
  String get syncNowAction => 'Sincronizar ahora';
  @override
  String get syncSectionServer => 'Servidor';
  @override
  String get syncServerRow => 'Dirección, usuario y contraseña';
  @override
  String get syncRetestTitle => 'Probar de nuevo el servidor';
  @override
  String syncProbedAgo(String when) => 'Última prueba: $when';
  @override
  String get syncDisconnectTitle => 'Desconectar esta biblioteca';
  @override
  String get syncDisconnectSubtitle =>
      'Los archivos se quedan aquí y en el servidor';
  @override
  String get syncDisconnectConfirmTitle => '¿Desconectar la sincronización?';
  @override
  String get syncDisconnectConfirmBody =>
      'Esta biblioteca deja de sincronizarse en este '
      'dispositivo. No se elimina ningún archivo, ni aquí ni en '
      'el servidor. Si la vuelves a conectar, la primera '
      'sincronización empieza de nuevo.';
  @override
  String get syncDisconnectConfirm => 'Desconectar';
  @override
  String get syncFirstTitle => 'Primera sincronización';
  @override
  String get syncFirstIntro =>
      'He comparado la biblioteca con la carpeta del servidor:';
  @override
  String get syncFirstUpload => 'Por subir';
  @override
  String get syncFirstDownload => 'Por descargar';
  @override
  String get syncFirstBoth => 'En ambos lados';
  @override
  String get syncFirstBothHint =>
      'Iguales: sin transferencia. Distintos: por resolver';
  @override
  String get syncFirstNoDelete =>
      'La primera sincronización no elimina nada, ni aquí ni en '
      'el servidor.';
  @override
  String get syncStartAction => 'Empezar';
  @override
  String syncMassTrashTitle(int count) =>
      '¿Mover $count archivos a la papelera?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Faltan en el servidor $count de los $total archivos '
      'sincronizados. Suele indicar una dirección errónea, un '
      'disco del NAS sin montar o una carpeta vaciada por error.';
  @override
  String get syncMassTrashHint =>
      'Si de verdad los eliminaste en otro dispositivo, '
      'confirma: aquí van a la papelera.';
  @override
  String get syncMassTrashConfirm => 'Mover a la papelera';
  @override
  String syncMassDeleteTitle(int count) =>
      '¿Eliminar $count archivos del servidor?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Faltan aquí $count de los $total archivos sincronizados. '
      'Si no los eliminaste tú, cancela y revisa la carpeta de '
      'la biblioteca.';
  @override
  String get syncMassDeleteConfirm => 'Eliminar del servidor';
  @override
  String get syncTooltip => 'Sincronizar';
  @override
  String get syncStageConnecting => 'Conectando con el servidor…';
  @override
  String get syncStageComparing => 'Comparando con el servidor…';
  @override
  String syncStageApplying(int done, int total) =>
      'Sincronizando · $done de $total';
  @override
  String get syncStatusWarnings => 'Sincronizada con avisos';
  @override
  String syncConflictsHeader(int count) =>
      'Modificados aquí y en el servidor · $count';
  @override
  String get syncConflictHint => 'No se tocó ninguna de las dos versiones';
  @override
  String get syncResolveAction => 'Resolver';
  @override
  String syncFailuresHeader(int count) => 'Sin sincronizar · $count';
  @override
  String get syncFailuresHint => 'Se reintentan en la próxima sincronización';
  @override
  String get syncAbortAuth => 'El servidor rechazó la contraseña';
  @override
  String get syncAbortMissingPassword => 'No hay contraseña guardada';
  @override
  String get syncAbortOffline => 'Servidor no accesible';
  @override
  String get syncAbortRemoteMissing => 'La carpeta del servidor ya no está';
  @override
  String get syncAbortUnsupported => 'El servidor ya no funciona como WebDAV';
  @override
  String get syncAbortFailed => 'La sincronización no funcionó';
  @override
  String get syncAbortNotConfirmed => 'Sincronización cancelada';
  @override
  String get syncAbortNothingTouched =>
      'No se tocó ningún archivo. Tus cambios se quedan aquí '
      'hasta la próxima sincronización correcta.';
  @override
  String syncLastSuccess(String when) =>
      'Última sincronización correcta: $when';
  @override
  String get syncNoSuccessYet => 'Aún no hay ninguna sincronización correcta';
  @override
  String get syncUpdatePasswordAction => 'Actualizar contraseña';
  @override
  String get syncRetryAction => 'Reintentar';
  @override
  String get syncOpenSettingsAction => 'Ajustes';
  @override
  String get syncCloseAction => 'Cerrar';
  @override
  String get syncDoneSnack => 'Sincronizada';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Sincronizada · 1 archivo eliminado en otro lugar está en '
            'la papelera'
      : 'Sincronizada · $count archivos eliminados en otro lugar '
            'están en la papelera';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Sincronizada · 1 conflicto por resolver'
      : 'Sincronizada · $count conflictos por resolver';
  @override
  String get syncShowAction => 'Mostrar';
  @override
  String get syncConflictTitle => 'Resolver conflicto';
  @override
  String get syncConflictLegend =>
      'Las líneas con − son del servidor; las líneas con + son '
      'de este dispositivo.';
  @override
  String get syncConflictBinary =>
      'No es un archivo de texto: elige qué copia conservar.';
  @override
  String get syncConflictKeepNote =>
      'La copia que no conserves queda en el historial de la '
      'nota.';
  @override
  String get syncKeepLocal => 'Conservar la de este dispositivo';
  @override
  String get syncKeepRemote => 'Conservar la del servidor';
  @override
  String get syncConflictIdentical => 'Las dos versiones son idénticas';
  @override
  String get syncConflictLoadFailed => 'No se pudieron leer las dos versiones';
  @override
  String get syncResolveFailed => 'No se pudo resolver el conflicto';
  @override
  String get syncResolved => 'Conflicto resuelto';
  @override
  String get syncSectionWhen => 'Cuándo sincronizar';
  @override
  String get syncAutoTitle => 'Automáticamente';
  @override
  String get syncAutoSubtitle => 'Tras los cambios, al abrir y a intervalos';
  @override
  String get syncIntervalTitle => 'Comprobar el servidor cada';
  @override
  String get syncIntervalSubtitle => 'Solo con la app abierta';
  @override
  String get syncIntervalDialogBody =>
      'Para ver los cambios hechos en otros dispositivos mientras la app está '
      'abierta. Con «Nunca», solo tras los cambios y al abrir.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minuto' : '$count minutos';
  @override
  String get syncIntervalNever => 'Nunca';
  @override
  String get syncWifiOnlyTitle => 'Solo con Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Con datos móviles, sincroniza solo a mano';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 cambio en espera' : '$count cambios en espera';
  @override
  String syncRetryIn(String wait) => 'nuevo intento en $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Esperando al Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Esperando la conexión';
  @override
  String get syncMobileDataHint =>
      '«Sincronizar ahora» usa datos móviles igualmente.';
  @override
  String get syncQueueKeptHint =>
      'Los cambios se quedan aquí, aunque cierres la app, y salen solos '
      'cuando el servidor responde.';
  @override
  String get syncAutoPaused => 'Sincronización automática en pausa';
  @override
  String get syncPausedAuthHint =>
      'Se reanuda cuando actualizas la contraseña o sincronizas a mano.';
  @override
  String get syncPausedServerHint =>
      'Se reanuda cuando corriges la dirección o sincronizas a mano.';
  @override
  String get syncPausedConfirmHint =>
      '«Sincronizar ahora» muestra qué se eliminaría y pide confirmación.';
  @override
  String get syncNeedsConfirmation => 'Esperando tu confirmación';
  @override
  String get syncMergeIntro =>
      'Los cambios que no se superponen ya están unidos; elige qué conservar '
      'donde sí se superponen.';
  @override
  String get syncMergeClean =>
      'Las dos versiones se unen solas: no hay nada que se superponga.';
  @override
  String get syncMergeNoBase =>
      'No hay una versión común sobre la que unir, así que hay que elegir el '
      'archivo entero.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Superposición $index de $total';
  @override
  String get syncMergeFromLocal => 'De este dispositivo';
  @override
  String get syncMergeFromRemote => 'Del servidor';
  @override
  String get syncMergeRemovedLines => 'Líneas eliminadas';
  @override
  String get syncMergeKeepLocal => 'Las mías';
  @override
  String get syncMergeKeepRemote => 'Del servidor';
  @override
  String get syncMergeKeepBoth => 'Ambas';
  @override
  String get syncMergeSave => 'Guardar la unión';
  @override
  String get syncMergeKeepWhole => 'O conserva una copia entera';
}
