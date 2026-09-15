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
  String get settingsPreviewEnabledTitle => 'Previsualització';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Mostra la nota renderitzada al costat de l’editor de font';
  @override
  String get switchToWysiwygTooltip => 'Canvia a l’editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Canvia a la font Markdown';
  @override
  String get wysiwygTooLarge =>
      'Aquesta nota és massa gran per a l’editor WYSIWYG. Obre-la a '
      'la font Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aparença';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Biblioteca';
  @override
  String get settingsSectionReminders => 'Recordatoris';
  @override
  String get settingsSectionShortcuts => 'Teclat';
  @override
  String get keyboardShortcutsTitle => 'Dreceres de teclat';
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
  String get settingsSectionDiagnostics => 'Diagnòstic';
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
  String get themePaletteTitle => 'Paleta de colors';
  @override
  String get themePaletteSubtitle => 'Els colors de la interfície i de la nota';
  @override
  String get themePaletteSystem => 'Sistema';

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

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Mode de previsualització';
  @override
  String get previewModeSubtitle =>
      'Si la previsualització comparteix la pantalla amb l’editor o '
      'la substitueix';
  @override
  String get previewModeAuto => 'Costat a costat';
  @override
  String get previewModeSwitch => 'Pantalla completa';
  @override
  String get splitRatioTitle => 'Amplitud de la divisió';
  @override
  String get splitRatioSubtitle =>
      'La part de l’editor quan la previsualització és costat a '
      'costat';

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

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Afegeix un element';
  @override
  String get listAddTooltip => 'Afegeix un element';
  @override
  String get listEmpty => 'Encara no hi ha elements';
  @override
  String get listDragHandleLabel => 'Canvia l’ordre de l’element';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota ràpida';
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
  String get shortcutEditorSection => 'A l’editor';
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
  String get toolbarHeading => 'Títol';
  @override
  String get toolbarList => 'Llista';
  @override
  String get toolbarOrderedList => 'Llista numerada';
  @override
  String get toolbarQuote => 'Cita';
  @override
  String get toolbarIndent => 'Sagna';
  @override
  String get toolbarOutdent => 'Desfà sagnat';
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
  @override
  String get enterFullScreenTooltip => 'Pantalla completa';
  @override
  String get exitFullScreenTooltip => 'Surt de la pantalla completa';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(taula HTML en brut)';

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
  String get todoNoPriority => 'Sense prioritat';
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
  String get hideSidebarTooltip => 'Amaga el panell lateral (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Mostra el panell lateral (Ctrl+B)';
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
  String get newFolderTitle => 'Carpeta nova';
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
  String get pinnedSection => 'Fixades';
  @override
  String pinnedSectionCount(int count) => 'Fixades · $count';
  @override
  String get templateFolderTitle => 'Carpeta de plantilles';
  @override
  String get newFromTemplateTitle => 'Nova des d’una plantilla';
  @override
  String get newFromTemplateHere => 'Nova des d’una plantilla aquí';
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
  String get settingsTitle => 'Configuració';
  @override
  String get libraryPathTitle => 'Camí de la biblioteca';
  @override
  String get reindexTitle => 'Torna a indexar ara';
  @override
  String get reindexDone => 'Reindexació completada';
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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Quant a';
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
      '(Configuració, Biblioteca).';
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
  String get transcriptionModelDownload => 'Baixa';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Vols suprimir el model $model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Allibera $size. Pots tornar a baixar el model més endavant.';
  @override
  String get transcriptionModelFailed =>
      "No s'ha pogut baixar. Comprova la connexió i torna-ho a provar.";
  @override
  String get actionRetry => 'Torna-ho a provar';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      "S'ha perdut la connexió, s'està tornant a provar…";
  @override
  String transcriptionModelInterrupted(String progress) =>
      'En pausa a $progress';
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
}
