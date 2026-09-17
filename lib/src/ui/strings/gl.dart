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
  String get settingsPreviewEnabledTitle => 'Previsualización';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Mostra a nota renderizada ao lado do editor de fonte';
  @override
  String get switchToWysiwygTooltip => 'Cambiar ao editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Cambiar á fonte Markdown';
  @override
  String get wysiwygTooLarge =>
      'Esta nota é demasiado grande para o editor WYSIWYG. Ábrea na '
      'fonte Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aparencia';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Biblioteca';
  @override
  String get settingsSectionReminders => 'Lembranzas';
  @override
  String get settingsSectionShortcuts => 'Teclado';
  @override
  String get keyboardShortcutsTitle => 'Atallos de teclado';
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
  String get settingsSectionDiagnostics => 'Diagnóstico';
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
  String get themePaletteTitle => 'Paleta de cores';
  @override
  String get themePaletteSubtitle => 'As cores da interfaz e da nota';
  @override
  String get themePaletteSystem => 'Sistema';

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

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Modo de previsualización';
  @override
  String get previewModeSubtitle =>
      'Se a previsualización comparte a pantalla co editor ou a '
      'substitúe';
  @override
  String get previewModeAuto => 'Lado a lado';
  @override
  String get previewModeSwitch => 'Pantalla completa';
  @override
  String get splitRatioTitle => 'Amplitud da división';
  @override
  String get splitRatioSubtitle =>
      'A parte do editor cando a previsualización é lado a lado';

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

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Engadir un elemento';
  @override
  String get listAddTooltip => 'Engadir un elemento';
  @override
  String get listEmpty => 'Aínda non hai elementos';
  @override
  String get listDragHandleLabel => 'Cambiar a orde do elemento';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rápida';
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
  String get shortcutEditorSection => 'No editor';
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
  String get toolbarHeading => 'Título';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Lista numerada';
  @override
  String get toolbarQuote => 'Cita';
  @override
  String get toolbarIndent => 'Sangrar';
  @override
  String get toolbarOutdent => 'Desfacer sangría';
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
  @override
  String get enterFullScreenTooltip => 'Pantalla completa';
  @override
  String get exitFullScreenTooltip => 'Saír da pantalla completa';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(táboa HTML a bruto)';

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
  String get todoNoPriority => 'Sen prioridade';
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
  String get hideSidebarTooltip => 'Ocultar o panel lateral (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Mostrar o panel lateral (Ctrl+B)';
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
  String get newFolderTitle => 'Cartafol novo';
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
  String get pinnedSection => 'Fixadas';
  @override
  String pinnedSectionCount(int count) => 'Fixadas · $count';
  @override
  String get templateFolderTitle => 'Cartafol de plantillas';
  @override
  String get newFromTemplateTitle => 'Nova desde unha plantilla';
  @override
  String get newFromTemplateHere => 'Nova desde unha plantilla aquí';
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
  String get openFileMissing => 'O ficheiro desta nota non está no disco';
  @override
  String get openFileFailed => 'Non foi posible abrir esta nota fóra do Niman';

  @override
  String get movedToTrash => 'Movida ao paperilleiro';
  @override
  String get deletedMessage => 'Borrado';
  @override
  String deleteToTrashConfirm(String name) => '$name moverase a .trash/';
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
  String get settingsTitle => 'Configuración';
  @override
  String get libraryPathTitle => 'Camiño da biblioteca';
  @override
  String get reindexTitle => 'Reindexar agora';
  @override
  String get reindexDone => 'Reindexación completada';
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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Sobre';
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
      '(Configuración, Biblioteca).';
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
  String get transcriptionModelDownload => 'Descargar';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Eliminar o modelo $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Libera $size. Podes volver descargar o modelo máis adiante.';
  @override
  String get transcriptionModelFailed =>
      'Non se puido descargar. Comproba a conexión e téntao de novo.';
  @override
  String get actionRetry => 'Tentar de novo';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Perdeuse a conexión, tentando de novo…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'En pausa en $progress';
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
  String get syncCloseAction => 'Pechar';
  @override
  String get syncDoneSnack => 'Sincronizada';
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
  String get syncConflictLegend =>
      'As liñas marcadas con − son do servidor; as marcadas con '
      '+ son deste dispositivo.';
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
  String get syncConflictIdentical => 'As dúas versións son idénticas';
  @override
  String get syncConflictLoadFailed => 'Non se puideron ler as dúas versións';
  @override
  String get syncResolveFailed => 'Non se puido resolver o conflito';
  @override
  String get syncResolved => 'Conflito resolto';
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
      'Non hai unha versión común sobre a que unir, así que hai que escoller o '
      'ficheiro enteiro.';
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
  String get syncMergeKeepLocal => 'As miñas';
  @override
  String get syncMergeKeepRemote => 'Do servidor';
  @override
  String get syncMergeKeepBoth => 'Ambas';
  @override
  String get syncMergeSave => 'Gardar a unión';
  @override
  String get syncMergeKeepWhole => 'Ou conserva unha copia enteira';
}
