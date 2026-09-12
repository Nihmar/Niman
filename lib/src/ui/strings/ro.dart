// The Romanian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class RomanianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'ianuarie',
    'februarie',
    'martie',
    'aprilie',
    'mai',
    'iunie',
    'iulie',
    'august',
    'septembrie',
    'octombrie',
    'noiembrie',
    'decembrie',
  ];
  @override
  List<String> get monthNamesShort => const [
    'ian',
    'feb',
    'mar',
    'apr',
    'mai',
    'iun',
    'iul',
    'aug',
    'sept',
    'oct',
    'nov',
    'dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'luni',
    'marți',
    'miercuri',
    'joi',
    'vineri',
    'sâmbătă',
    'duminică',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'lun',
    'mar',
    'mie',
    'joi',
    'vin',
    'sâm',
    'dum',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Coș';
  @override
  String get trashSubtitle =>
      'Elementele șterse se mută în .trash/ (dezactivat = ștergere '
      'permanentă)';
  @override
  String get debugLogsTitle => 'Jurnale de depanare';
  @override
  String get debugLogsSubtitle =>
      'Înregistrează evenimentele aplicației într-un buffer de memorie';
  @override
  String get lineNumbersTitle => 'Numerele de linie';
  @override
  String get lineNumbersSubtitle =>
      'Afișează coloana cu numerele de linie în editorul de note';
  @override
  String get keyboardOnOpenTitle => 'Tastatura la deschidere';
  @override
  String get keyboardOnOpenSubtitle =>
      'Afișează tastatura la deschiderea unei note (dezactivat = la prima '
      'atingere)';
  @override
  String get editorKindSource => 'Sursă Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Previzualizare';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Afișează nota renderizată lângă editorul de sursă';
  @override
  String get switchToWysiwygTooltip => 'Comută la editorul WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Comută la sursa Markdown';
  @override
  String get wysiwygTooLarge =>
      'Această notă este prea mare pentru editorul WYSIWYG. Deschide-o în '
      'sursa Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aspect';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliotecă';
  @override
  String get settingsSectionReminders => 'Mementouri';
  @override
  String get settingsSectionShortcuts => 'Tastatură';
  @override
  String get keyboardShortcutsTitle => 'Scurtături de tastatură';
  @override
  String get settingsSectionDiagnostics => 'Diagnostic';
  @override
  String get settingsSpellCheckTitle => 'Verificarea ortografiei';
  @override
  String get settingsSpellCheckSubtitle =>
      'Subliniază greșelile de ortografie în timp ce scrii.';
  @override
  String get spellCheckDictionaryTitle => 'Dicționar';
  @override
  String get spellCheckDictionarySystem => 'Implicitul sistemului';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Alegere dicționare';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Alege toate limbile în care este scrisă biblioteca. Un cuvânt '
      'trece dacă oricare dintre dicționarele alese îl cunoaște; fără '
      'selecție, decide limba sistemului.';
  @override
  String get spellCheckNoDictionaries =>
      'Nu s-au găsit dicționare pe acest sistem.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Verificarea ortografiei';
  @override
  String get spellCheckTitle => 'Ortografie';
  @override
  String get spellCheckEmpty => 'Nicio greșeală de ortografie.';
  @override
  String get spellCheckUnavailable =>
      'hunspell nu este instalat pe acest sistem.';
  @override
  String get spellCheckNoSuggestions => 'Nicio sugestie';
  @override
  String spellCheckCount(int count) => '$count de verificat';
  @override
  String spellCheckLine(int line) => 'linia $line';

  @override
  String indentWidthValue(int spaces) => '$spaces spații';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Luminanță';
  @override
  String get themeBrightnessSubtitle =>
      'Clar, întunecat sau setarea dispozitivului';
  @override
  String get themeBrightnessSystem => 'Sistem';
  @override
  String get themeBrightnessDay => 'Clar';
  @override
  String get themeBrightnessNight => 'Întunecat';
  @override
  String get themePaletteTitle => 'Paletă de culori';
  @override
  String get themePaletteSubtitle => 'Culorile interfeței și ale notei';
  @override
  String get themePaletteSystem => 'Sistem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Mărimea textului interfeței';
  @override
  String get uiTextScaleSubtitle =>
      'Arborele, filele și dialogurile; peste setarea sistemului';
  @override
  String get noteTextScaleTitle => 'Mărimea textului notei';
  @override
  String get noteTextScaleSubtitle =>
      'Editorul și previzualizarea, mereu de acord';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Modul de previzualizare';
  @override
  String get previewModeSubtitle =>
      'Dacă previzualizarea împarte ecranul cu editorul sau îl înlocuiește';
  @override
  String get previewModeAuto => 'Pe lângă';
  @override
  String get previewModeSwitch => 'Ecran întreg';
  @override
  String get splitRatioTitle => 'Lățimea diviziunii';
  @override
  String get splitRatioSubtitle =>
      'Cota editorului când previzualizarea este pe lângă';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formatul linkului';
  @override
  String get linkTypeSubtitle => 'Ce inserează butonul de link în editor';
  @override
  String get linkTypeWikilink => 'Link wiki';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Lățimea indentării';
  @override
  String get indentWidthSubtitle =>
      'Spațiile adăugate pe fiecare nivel de indentare în editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Limba';
  @override
  String get languageSubtitle => 'Limba propriului text al aplicației';
  @override
  String get languageSystem => 'Sistem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Adaugă un element';
  @override
  String get listAddTooltip => 'Adaugă un element';
  @override
  String get listEmpty => 'Niciun element încă';
  @override
  String get listDragHandleLabel => 'Schimbă ordinea elementului';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Notă rapidă';
  @override
  String get shortcutNewTodo => 'Sarcină nouă';
  @override
  String get shortcutNewNote => 'Notă nouă';
  @override
  String get shortcutNewList => 'Listă nouă';
  @override
  String get shortcutToggleSidebar => 'Afișează sau ascunde filtrul';
  @override
  String get shortcutEditorSection => 'În editor';
  @override
  String get shortcutFind => 'Caută';
  @override
  String get shortcutReplace => 'Caută și înlocuiește';
  @override
  String get shortcutSavingNote =>
      'Modificările se salvează automat, deci nu există scurtătură pentru '
      'salvare.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Structură';
  @override
  String get outlineNoHeadings => 'Niciun titlu';
  @override
  String get outlineNoTitle => '(fără titlu)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Îngroșat';
  @override
  String get toolbarItalic => 'Cursiv';
  @override
  String get toolbarStrikethrough => 'Tăiat';
  @override
  String get toolbarSuperscript => 'Indice sus';
  @override
  String get toolbarUnderline => 'Subliniat';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Bloc de cod';
  @override
  String get toolbarImage => 'Inserează imagine';
  @override
  String get toolbarHeading => 'Titlu';
  @override
  String get toolbarList => 'Listă';
  @override
  String get toolbarOrderedList => 'Listă numerotată';
  @override
  String get toolbarQuote => 'Citat';
  @override
  String get toolbarIndent => 'Indentare';
  @override
  String get toolbarOutdent => 'Scoate indentarea';
  @override
  String get headingDialogTitle => 'Nivelul titlului';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Bara de unelte a editorului';
  @override
  String get toolbarSettingsHint =>
      'Trage pentru a schimba ordinea; ochiul arată sau ascunde un buton.';
  @override
  String get toolbarShowButton => 'Arată';
  @override
  String get toolbarHideButton => 'Ascunde';
  @override
  String get toolbarResetOrder => 'Restaurează implicitul';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Afișează previzualizarea';
  @override
  String get showEditorTooltip => 'Afișează editorul';
  @override
  String get enterFullScreenTooltip => 'Ecran întreg';
  @override
  String get exitFullScreenTooltip => 'Ieși din ecranul întreg';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tabel HTML brut)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Caută în note';
  @override
  String get searchModeWords => 'Cuvinte';
  @override
  String get searchModeContains => 'Conține';
  @override
  String get searchEmptyHint =>
      'Scrie pentru a căuta în bibliotecă, sau cheie = valoare pentru a '
      'filtra după frontmatter';
  @override
  String get searchTooShortHint => 'Scrie cel puțin 2 caractere';
  @override
  String get searchNoMatches => 'Niciun rezultat';
  @override
  String get searchLoadMore => 'Afișează mai multe';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Înlocuiește…';
  @override
  String get replaceInNoteAction => 'Înlocuiește în această notă…';
  @override
  String get replaceInThisNote => 'Înlocuiește în această notă';
  @override
  String get replaceWithLabel => 'Înlocuiește cu';
  @override
  String get replaceCaseSensitive => 'Distinge majusculele de minuscule';
  @override
  String get replaceWholeWordsHint =>
      'se înlocuiesc doar potrivirile exacte de cuvinte întregi';
  @override
  String get replaceConfirm => 'Înlocuiește';
  @override
  String get replaceCancel => 'Închide';
  @override
  String get replaceUnavailable => 'Înlocuirea nu este disponibilă acum';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Caută în notă';
  @override
  String get editorFindHint => 'Caută';
  @override
  String get editorReplaceHint => 'Înlocuiește';
  @override
  String get editorFindCaseTooltip => 'Distinge majusculele de minuscule';
  @override
  String get editorFindPreviousTooltip => 'Potrivirea anterioară';
  @override
  String get editorFindNextTooltip => 'Potrivirea următoare';
  @override
  String get editorFindCloseTooltip => 'Închide căutarea';
  @override
  String get editorFindReplaceModeTooltip => 'Modul de înlocuire';
  @override
  String get editorReplaceOneTooltip => 'Înlocuiește această potrivire';
  @override
  String get editorReplaceAllTooltip => 'Înlocuiește toate potrivirile';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etichete';
  @override
  String get tagsTitle => 'Etichete';
  @override
  String get tagsEmpty =>
      'Nicio etichetă încă — adaugă o #etichetă sau etichete în '
      'frontmatter';
  @override
  String get tagsBackTooltip => 'Înapoi la căutare';
  @override
  String get tagsNotesEmpty => 'Nicio notă cu această etichetă';
  @override
  String tagsNotesCapped(int limit) =>
      'Se afișează doar primele $limit — caută eticheta pentru a limita';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Linkul nu a fost găsit';
  @override
  String get headingNotFoundTitle => 'Titlul nu a fost găsit';
  @override
  String get ambiguousLinkTitle => 'Mai multe note se potrivesc';
  @override
  String get openLinkFailed => 'Linkul nu a putut fi deschis';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Deschise';
  @override
  String get todoDone => 'Finalizate';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Toate datele';
  @override
  String get todoFilter => 'Filtrează';
  @override
  String get todoNoTokens => 'Niciun token în această listă';
  @override
  String get todoCountOpen => 'deschise';
  @override
  String get todoCountDone => 'finalizate';
  @override
  String get todoEmptyOpen => 'Nicio sarcină deschisă încă';
  @override
  String get todoEmptyDone => 'Niciuna finalizată încă';
  @override
  String get todoEmptyFiltered => 'Nicio sarcină nu se potrivește';
  @override
  String get todoTitle => 'De făcut';
  @override
  String get todoAddTooltip => 'Adaugă sarcină';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Formatul todo.txt';
  @override
  String get todoHelpTooltip => 'Informații despre format';
  @override
  String get todoHelpIntro =>
      'Sarcinile tale sunt un fișier de text obișnuit, o sarcină pe linie. '
      'Niman scrie sintaxa pentru tine, dar nu ascunde nimic: poți edita '
      'fișierul în orice editor și Niman îl citește din nou.';
  @override
  String get todoHelpFilesTitle => 'Cele două fișiere';
  @override
  String get todoHelpFilesBody =>
      'Sarcinile deschise locuiesc în todo.txt din rădăcina bibliotecii. '
      'Finalizează una și linia se mută în done.txt, astfel todo.txt '
      'rămâne scurt. O linie finalizată care ajunge din nou în todo.txt '
      'este arhivată de Niman la următoarea citire a fișierelor.';
  @override
  String get todoHelpLineTitle => 'Anatomia unei linii';
  @override
  String get todoHelpLineBody =>
      'Tot ce este înainte de descriere este opțional și trebuie să vină '
      'în această ordine:';
  @override
  String get todoHelpDoneBody =>
      'Marchează sarcina ca finalizată. Niman o adaugă când bifezi '
      'căsuța.';
  @override
  String get todoHelpPriority => '(A) până la (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioritate. A este cea mai înaltă. Se afișează ca emblemă în listă.';
  @override
  String get todoHelpDatesBody =>
      'Data finalizării, apoi data creării. Cu o singură dată, este data '
      'creării, cu excepția cazului în care linia începe cu x.';
  @override
  String get todoHelpTokensTitle => 'Proiecte, contexte și etichete';
  @override
  String get todoHelpTokensBody =>
      'Întreaga descriere, un cuvânt cu oricare dintre aceste prefixe '
      'devine o etichetă care poate fi filtrată. Nimic nu este predefinit: '
      'un token există cât timp îl scrii.';
  @override
  String get todoHelpProjectBody =>
      'La ce proiect aparține sarcina, de exemplu +bucătărie sau +muncă.';
  @override
  String get todoHelpContextBody =>
      'Unde sau cum o faci, de exemplu @acasă sau @întâlniri.';
  @override
  String get todoHelpHashtagBody =>
      'O etichetă liberă pentru orice nu acoperă primele două.';
  @override
  String get todoHelpTagsTitle => 'Date și mementouri';
  @override
  String get todoHelpTagsBody =>
      'Acestea sunt etichete cheie:valoare. Niman le scrie din dialogul de '
      'sarcini și le citește oriunde apar în linie.';
  @override
  String get todoHelpDueBody =>
      'Termenul. Controlează culoarea emblemei și filtrele de date.';
  @override
  String get todoHelpRemBody =>
      'Când ar trebui trimisă notificarea, în fusul tău orar. Se declanșează '
      'când ecranul este stins și aplicația închisă.';
  @override
  String get todoHelpRemDesktop =>
      'Pe desktop, Niman trebuie să ruleze când vine ora: mementorul se '
      'arată cât timp aplicația este deschisă și nimic nu se declanșează '
      'când este închisă.';
  @override
  String get todoHelpOtherBody =>
      'Păstrat exact cum a fost scris, astfel încât etichetele din alte '
      'aplicații todo.txt să supraviețuiască unei călătorii. Niman nu '
      'acționează asupra lor, rec: included: o sarcină recurentă nu se '
      'repetă încă.';
  @override
  String get todoHelpEditTitle => 'Editare în afara Niman';
  @override
  String get todoHelpEditBody =>
      'O sarcină pe care nu o atingi se rescrie byte cu byte, inclusiv '
      'spații ciudate. Editezi o linie și Niman rescrie doar acea linie în '
      'formatul ei canonic și lasă restul fișierului intact.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Adaugă sarcină';
  @override
  String get todoEditTitle => 'Editează sarcină';
  @override
  String get todoDescriptionHint => 'Descriere';
  @override
  String get todoCancel => 'Anulează';
  @override
  String get todoSave => 'Salvează';
  @override
  String get todoEditAction => 'Editează';
  @override
  String get todoDeleteAction => 'Șterge';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Întârziat';
  @override
  String get todoDueToday => 'Astăzi';
  @override
  String get todoDueNext7 => 'Următoarele 7 zile';
  @override
  String get todoDueNoDate => 'Fără dată';
  @override
  String get todoRowDue => 'Termen';
  @override
  String get todoRowDueToday => 'Termen astăzi';
  @override
  String get todoSortTooltip => 'Sortează';
  @override
  String get todoSortDue => 'Data termenului';
  @override
  String get todoSortPriority => 'Prioritate';
  @override
  String get todoSortCreation => 'Data creării';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Fără prioritate';
  @override
  String get todoNoPriorityShort => 'Niciuna';
  @override
  String get todoMorePriorities => 'Mai multe…';
  @override
  String get todoPriorityTitle => 'Prioritate';
  @override
  String get todoNoDueDate => 'Fără termen';
  @override
  String get todoNoReminder => 'Fără mementou';
  @override
  String get todoAddProject => '+ Proiect';
  @override
  String get todoAddContext => '@ Context';
  @override
  String get todoAddHashtag => '# Etichetă';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Mementouri de sarcini';
  @override
  String get todoReminderChannelDescription =>
      'Notificări programate pentru sarcini cu oră de mementou.';
  @override
  String get todoReminderBody => 'Mementou de sarcină';
  @override
  String get todoReminderFallbackTitle => 'Mementou de sarcină';
  @override
  String get todoReminderBlocked =>
      'Notificările sunt dezactivate, deci mementourile nu se vor afișa.';
  @override
  String get todoReminderBattery =>
      'Optimizarea bateriei este activă pentru Niman. Sistemul poate '
      'suspenda aplicația și poate pierde mementouri în așteptare.';
  @override
  String get todoReminderInexact =>
      'Acest dispozitiv nu permite alarme exacte, deci un mementou poate '
      'sosi cu câteva minute mai târziu când ecranul este stins.';
  @override
  String get reminderShowTokensTitle => 'Etichete în notificările de mementou';
  @override
  String get reminderShowTokensSubtitle =>
      'Păstrează +proiect, @context și #etichetă în textul notificării. '
      'Dezactivat arată doar sarcina pe care ai scris-o.';
  @override
  String get todoReminderFixAction => 'Deschide setările';
  @override
  String get todoReminderDismissAction => 'Respinge';
  @override
  String get todoReminderDue => 'Termen';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Anulează';
  @override
  String get actionCreate => 'Creează';
  @override
  String get actionNew => 'Nouă';
  @override
  String get actionSave => 'Salvează';
  @override
  String get actionClear => 'Golește';
  @override
  String get actionChoose => 'Alege';
  @override
  String get actionDelete => 'Șterge';
  @override
  String get actionRename => 'Redenumește';
  @override
  String get actionMove => 'Mută';
  @override
  String get saveAndClose => 'Salvează și închide';
  @override
  String get closeUnsavedTitle => 'Modificări nesalvate';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” are modificări nesalvate. '
          'Salvăm-le înainte de închidere?';
    }
    return '${names.length} note au modificări nesalvate. '
        'Salvăm-le înainte de închidere?';
  }

  @override
  String get closeSaveFailed => 'Salvarea a eșuat; rămâne deschisă.';
  @override
  String get actionRestore => 'Restaurează';
  @override
  String get actionEmpty => 'Golește';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ascunde panoul lateral (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Afișează panoul lateral (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizează';
  @override
  String get windowMaximizeTooltip => 'Maximizează';
  @override
  String get windowRestoreTooltip => 'Restaurează';
  @override
  String get windowCloseTooltip => 'Închide';
  @override
  String get tabFiles => 'Fișiere';
  @override
  String get tabSearch => 'Căutare';
  @override
  String get tabSettings => 'Setări';
  @override
  String get quickNoteTitle => 'Notă rapidă';
  @override
  String get treeEmpty => 'Nicio notă încă';
  @override
  String get selectANote => 'Alege o notă';
  @override
  String get showListTooltip => 'Afișează lista';
  @override
  String get editRawTooltip => 'Editează brut';
  @override
  String get sortAscTooltip => 'Sortează A–Z';
  @override
  String get sortDescTooltip => 'Sortează Z–A';
  @override
  String get newNoteTitle => 'Notă nouă';
  @override
  String get newFolderTitle => 'Dosar nou';
  @override
  String get newNoteHere => 'Notă nouă aici';
  @override
  String get newFolderHere => 'Dosar nou aici';
  @override
  String get newListNoteTitle => 'Notă de listă nouă';
  @override
  String get newListNoteDefault => 'Lista mea';
  @override
  String get setAsQuickNote => 'Setează ca notă rapidă';
  @override
  String get currentQuickNote => 'Notă rapidă curentă';
  @override
  String get pinnedSection => 'Fixate';
  @override
  String pinnedSectionCount(int count) => 'Fixate · $count';
  @override
  String get templateFolderTitle => 'Dosar de șabloane';
  @override
  String get newFromTemplateTitle => 'Nouă din șablon';
  @override
  String get newFromTemplateHere => 'Nouă din șablon aici';
  @override
  String get templateFormTitle => 'Completează șablonul';
  @override
  String get templateFormBacklink => 'Legat de';
  @override
  String get templateFormNoNote => 'Fără notă';
  @override
  String get templateFormPickNote => 'Alege nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Markeri de șablon';
  @override
  String get templateHelpIntro =>
      'Un șablon este o notă obișnuită cu găuri. Crearea unei note din ea '
      'copiază textul și completează găurile.';
  @override
  String get templateHelpUnknown =>
      'Un marker pe care Niman nu îl cunoaște rămâne exact cum a fost '
      'scris, astfel încât o greșeală de tastare apare în notă, în loc să '
      'rupă în tăcere o linie.';
  @override
  String get templateHelpValuesTitle => 'Valori';
  @override
  String get templateHelpTitleBody => 'Numele sub care trebuie creată nota.';
  @override
  String get templateHelpDateBody =>
      'Astăzi și ora curentă. Ambele acceptă un format: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Data și ora împreună.';
  @override
  String get templateHelpUuidBody =>
      'Un identificator nou, diferit la fiecare apariție.';
  @override
  String get templateHelpCounterBody =>
      'Un număr care numără după nume, păstrat între reporniri: prima notă '
      'scrie 1, următoarea 2. Același nume într-o notă scrie același '
      'număr; combină-l cu |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Pune cursorul aici când se creează nota; markerul nu se scrie. '
      'Primul marker câștigă, fără filtre, doar note noi — și tastatura se '
      'deschide și la autofocus dezactivat.';
  @override
  String get templateHelpDatesTitle => 'Scrierea unei date';
  @override
  String get templateHelpDatesBody =>
      'Acestea reprezintă părți ale datei într-un format. Tot restul este '
      'literal, și textul din ghilimele simple. Numele lunilor și ale '
      'zilelor săptămânii urmează limba aplicației.';
  @override
  String get templateHelpYear => 'anul: 2026, 26';
  @override
  String get templateHelpMonth => 'luna: 03, 3, martie, mar';
  @override
  String get templateHelpDay => 'ziua: 09, 9, luni, lun';
  @override
  String get templateHelpTime => 'ore, minute, secunde';
  @override
  String get templateHelpWeek => 'săptămâna ISO și trimestrul: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtre';
  @override
  String get templateHelpFiltersBody =>
      'O valoare poate fi urmată de filtre, aplicate din stânga în dreapta.';
  @override
  String get templateHelpCaseBody =>
      'Majuscule, minuscule și prima literă a fiecărui cuvânt — un cuvânt '
      'pe care l-ai scris cu majuscule nu este atins.';
  @override
  String get templateHelpSlugBody =>
      'Forma de link a textului, pentru a construi un link wiki.';
  @override
  String get templateHelpPadBody =>
      'Taie capetele; completează cu zerouri până la lățimea dorită; '
      'folosește o alternativă când valoarea este goală.';
  @override
  String get templateHelpShiftBody =>
      'Mută o dată cu zile, săptămâni, luni sau ani — conferința de '
      'săptămâna viitoare, fișierul de luna trecută.';
  @override
  String get templateHelpSnapBody =>
      'Fixează o dată la începutul sau sfârșitul săptămânii, lunii sau '
      'anului.';
  @override
  String get templateHelpAskTitle => 'Să te întreb ceva';
  @override
  String get templateHelpAskBody =>
      'Un formular se arată înainte de crearea notei, un câmp pe întrebare '
      '— și unul pentru linkul invers, când șablonul cere. Eticheta aceea '
      'de două ori este o întrebare, iar răspunsul ei completează toate '
      'aparițiile — inclusiv dosarul și numele fișierului.';
  @override
  String get templateHelpAskFieldBody =>
      'Un câmp de scris; textul după al doilea douăpunct este începutul.';
  @override
  String get templateHelpChoiceBody =>
      'O alegere dintr-o listă, separată prin virgule.';
  @override
  String get templateHelpWhereTitle => 'Unde ajunge nota';
  @override
  String get templateHelpWhereBody =>
      'Acestea nu sunt text: sunt instrucțiuni și locuiesc într-un bloc '
      'niman: din propriul frontmatter al șablonului. Blocul se execută și '
      'se șterge, astfel nu se arată niciodată în notă. Valoarea sa poate '
      'conține markeri.';
  @override
  String get templateHelpFolderBody =>
      'Dosarul în care se creează nota, creat dacă nu există. Fără el, nota '
      'ajunge unde erai.';
  @override
  String get templateHelpFilenameBody =>
      'Cum se numește nota. Un șablon care spune asta nu este întrebat de '
      'nume.';
  @override
  String get templateHelpAppendBody =>
      'Adaugă la notă dacă deja există, în loc să creezi alta. Astfel o '
      'lună de întâlniri devine un singur fișier.';
  @override
  String get templateHelpOpenBody =>
      'Ce se întâmplă când nota există: editorul (implicit), previzualizarea, '
      'sau nimic — nota este arhivată și rămâi unde erai.';
  @override
  String get templateHelpAroundTitle => 'De unde a venit';
  @override
  String get templateHelpParentBody =>
      'O notă pe care o alegi în formular, oferită pe ecran; scrie '
      '[[{{parent}}]] pentru un link de întoarcere.';
  @override
  String get templateHelpFolderValueBody => 'Dosarul în care a ajuns nota.';
  @override
  String get templateHelpClipboardBody =>
      'Ce este în clipboard și selecția din editor când nota a pornit de '
      'acolo.';
  @override
  String get templateHelpIncludeTitle => 'Reutilizarea unei părți';
  @override
  String get templateHelpIncludeBody =>
      'Lipește alt șablon, astfel încât zece șabloane să poată împărți o '
      'listă de verificare. Cautat întâi în dosarul de șabloane, .md poate '
      'fi omis. Întrebările sale proprii intră în același formular.';
  @override
  String get templateHelpExampleTitle => 'Totul la un loc';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nu există șablonul “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” se include pe sine';
  @override
  String includeTooDeep(String path) => '⚠ “$path” este înfipt prea adânc';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter necitit: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Frontmatterul “$template” nu a putut fi citit, deci dosarul și '
      'numele fișierului nu au făcut nimic: $reason';
  @override
  String get templatePickerTitle => 'Alegere șablon';
  @override
  String templatePickerEmpty(String folder) =>
      'Niciun șablon încă. Pune o notă în $folder/ și va fi șablon.';

  // Tree actions.
  @override
  String get actionPin => 'Fixează';
  @override
  String get actionUnpin => 'Dezfixează';
  @override
  String get movedToTrash => 'Mutat în coș';
  @override
  String get deletedMessage => 'Șters';
  @override
  String deleteToTrashConfirm(String name) => '$name se mută în .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name se șterge permanent';
  @override
  String get chooseDestination => 'Alege destinația';
  @override
  String get libraryRoot => 'Rădăcina bibliotecii';
  @override
  String moveTitle(String name) => 'Mută $name';
  @override
  String headingLevelLabel(int level) => 'Titlu $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Nicio notă rapidă încă. Alege o notă existentă sau creează — nota '
      'rapidă se va deschide aici.';
  @override
  String get quickNoteChooseAction => 'Alege o notă…';
  @override
  String get quickNoteCreateAction => 'Creează o notă nouă…';
  @override
  String get quickNoteNewTitle => 'Notă rapidă nouă';
  @override
  String get quickNotePickerTitle => 'Alegere notă rapidă';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Dosar nou';
  @override
  String get folderPickerEmpty => 'Niciun dosar încă';
  @override
  String get listFolderTitle => 'Dosar de liste';

  // Trash (M1).
  @override
  String get trashEmpty => 'Coșul este gol';
  @override
  String get trashEmptyAction => 'Golește coșul';
  @override
  String get trashEmptyConfirm =>
      'Asta șterge permanent tot ce este în coș, inclusiv elementele pe '
      'care Niman nu le-a pus.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name se șterge permanent (fără restaurare)';
  @override
  String get trashDeletePermanently => 'Șterge permanent';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Deschide un dosar de note Markdown ca bibliotecă';
  @override
  String get openLibraryExisting => 'Deschide una existentă';
  @override
  String get openLibraryCreate => 'Creează una nouă';
  @override
  String get openLibraryCreateTitle => 'Creează o bibliotecă nouă';
  @override
  String get openLibraryFolderName => 'Numele dosarului';
  @override
  String get openLibraryChooseFolder => 'Alege dosarul bibliotecii';
  @override
  String get openLibraryChooseParent =>
      'Alege dosarul în care se va crea biblioteca';
  @override
  String get openLibraryUnsupported =>
      'Acest dosar nu este compatibil. Alege un dosar din stocarea '
      'dispozitivului.';
  @override
  String indexingCount(int done, int total) => '$done din $total note';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Bibliotecile tale';
  @override
  String get libraryUnreachable => 'Nedisponibilă';
  @override
  String get libraryOpenedToday => 'Deschisă azi';
  @override
  String get libraryOpenedYesterday => 'Deschisă ieri';
  @override
  String libraryOpenedDaysAgo(int days) => 'Deschisă acum $days zile';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Deschisă ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Deschisă acum';
  @override
  String get switchLibraryTitle => 'Schimbă biblioteca';
  @override
  String get libraryForget => 'Uită';
  @override
  String libraryForgetTitle(String name) => 'Uită „$name”?';
  @override
  String get libraryForgetExplained =>
      'Dispare din această listă. Dosarul, notele și setările bibliotecii '
      'rămân neatinse, iar redeschiderea o pune la loc.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dă acces la fișiere';
  @override
  String get storageAccessNeeded =>
      'Niman nu poate citi notele tale fără „Acces la toate fișierele”. '
      'Dă-l pentru a deschide o bibliotecă.';
  @override
  String get storageAccessExplained =>
      'Niman citește notele tale ca fișiere obișnuite, deci Android trebuie '
      'să-i dea acces la toate fișierele. Nimic nu este trimis, și se '
      'citește doar dosarul de bibliotecă pe care îl alegi.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistemul nu a dat acces la dosar: $error';
  @override
  String folderPickFailed(Object error) => 'Dosarul nu a putut fi ales: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Setări';
  @override
  String get libraryPathTitle => 'Calea bibliotecii';
  @override
  String get reindexTitle => 'Reindexează acum';
  @override
  String get reindexDone => 'Reindexare finalizată';
  @override
  String get closeLibraryTitle => 'Închide biblioteca';
  @override
  String get exportLogTitle => 'Exportă jurnalul de depanare';
  @override
  String get exportLogSubtitle =>
      'Salvează evenimentele înregistrate într-un fișier pe care îl alegi';
  @override
  String get exportLogEmpty => 'Bufferul jurnalului de depanare este gol';
  @override
  String get quickNoteUnset => 'Nesetate';
  @override
  String exportLogDone(Object target) =>
      'Jurnalul de depanare exportat în $target';
  @override
  String exportLogFailed(Object error) => 'Exportul a eșuat: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nicio potrivire exactă de cuvânt întreg pentru „$term”';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'S-au înlocuit $occurrences apariții ale „$term” în $notes note';
  @override
  String replaceSkipped(int skipped) => ' ($skipped note deschise omitate)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nicio potrivire exactă de cuvânt întreg pentru „$term”'
      '${only == null ? ' a fost găsită' : ' a fost găsită în $only'}';
}
