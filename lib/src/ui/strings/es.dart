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
  String get settingsPreviewEnabledTitle => 'Vista previa';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Muestra la nota renderizada junto al editor de fuente';
  @override
  String get switchToWysiwygTooltip => 'Cambiar al editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Cambiar a la fuente Markdown';
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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rápida';
  @override
  String get shortcutNewTodo => 'Nueva tarea';
  @override
  String get shortcutNewNote => 'Nueva nota';
  @override
  String get shortcutNewList => 'Nueva lista';
  @override
  String get shortcutToggleSidebar => 'Mostrar u ocultar el árbol de archivos';
  @override
  String get shortcutEditorSection => 'En el editor';
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
  String get newFolderTitle => 'Nueva carpeta';
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
}
