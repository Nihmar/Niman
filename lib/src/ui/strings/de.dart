// The German strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class GermanStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  @override
  List<String> get monthNamesShort => const [
    'Jan.',
    'Feb.',
    'März',
    'Apr.',
    'Mai',
    'Juni',
    'Juli',
    'Aug.',
    'Sept.',
    'Okt.',
    'Nov.',
    'Dez.',
  ];
  @override
  List<String> get weekdayNames => const [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'Mo.',
    'Di.',
    'Mi.',
    'Do.',
    'Fr.',
    'Sa.',
    'So.',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Papierkorb';
  @override
  String get trashSubtitle =>
      'Gelöschtes wird nach .trash/ verschoben (aus = endgültig löschen)';
  @override
  String get debugLogsTitle => 'Debug-Protokoll';
  @override
  String get debugLogsSubtitle =>
      'Zeichnet App-Ereignisse in einen Speicher-Puffer auf';
  @override
  String get lineNumbersTitle => 'Zeilennummern';
  @override
  String get lineNumbersSubtitle =>
      'Zeigt die Zeilennummer-Spalte im Notiz-Editor';
  @override
  String get keyboardOnOpenTitle => 'Tastatur beim Öffnen';
  @override
  String get keyboardOnOpenSubtitle =>
      'Zeigt die Tastatur, sobald eine Notiz geöffnet wird (aus = beim '
      'ersten Tippen)';
  @override
  String get editorKindSource => 'Markdown-Quelltext';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Vorschau';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Zeigt die gerenderte Notiz neben dem Quelltext-Editor';
  @override
  String get switchToWysiwygTooltip => 'Zum WYSIWYG-Editor wechseln';
  @override
  String get switchToSourceTooltip => 'Zum Markdown-Quelltext wechseln';
  @override
  String get wysiwygTooLarge =>
      'Diese Notiz ist für den WYSIWYG-Editor zu groß. Öffne sie im '
      'Markdown-Quelltext.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Erscheinungsbild';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Bibliothek';
  @override
  String get settingsSectionReminders => 'Erinnerungen';
  @override
  String get settingsSectionShortcuts => 'Tastatur';
  @override
  String get keyboardShortcutsTitle => 'Tastaturkürzel';
  @override
  String get settingsSectionDiagnostics => 'Diagnose';
  @override
  String get settingsSpellCheckTitle => 'Rechtschreibung prüfen';
  @override
  String get settingsSpellCheckSubtitle =>
      'Unterstreicht falsch geschriebene Wörter beim Schreiben.';
  @override
  String get spellCheckDictionaryTitle => 'Wörterbuch';
  @override
  String get spellCheckDictionarySystem => 'Systemstandard';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Wörterbücher wählen';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Wähle jede Sprache, in der diese Bibliothek geschrieben ist. Ein '
      'Wort ist korrekt, wenn es ein gewähltes Wörterbuch kennt; ohne '
      'Wahl entscheidet die Systemeinstellung.';
  @override
  String get spellCheckNoDictionaries =>
      'Auf diesem System wurden keine Wörterbücher gefunden.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Rechtschreibung prüfen';
  @override
  String get spellCheckTitle => 'Rechtschreibung';
  @override
  String get spellCheckEmpty => 'Keine Rechtschreibfehler.';
  @override
  String get spellCheckUnavailable =>
      'hunspell ist auf diesem System nicht installiert.';
  @override
  String get spellCheckNoSuggestions => 'Keine Vorschläge';
  @override
  String spellCheckCount(int count) => '$count zu prüfen';
  @override
  String spellCheckLine(int line) => 'Zeile $line';

  @override
  String indentWidthValue(int spaces) => '$spaces Leerzeichen';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Helligkeit';
  @override
  String get themeBrightnessSubtitle =>
      'Hell, dunkel oder wie auf dem Gerät eingestellt';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Hell';
  @override
  String get themeBrightnessNight => 'Dunkel';
  @override
  String get themePaletteTitle => 'Farbpalette';
  @override
  String get themePaletteSubtitle => 'Die Farben der Oberfläche und der Notiz';
  @override
  String get themePaletteSystem => 'System';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Textgröße der Oberfläche';
  @override
  String get uiTextScaleSubtitle =>
      'Der Baum, die Registerkarten und die Dialoge; zusätzlich zur '
      'Systemeinstellung';
  @override
  String get noteTextScaleTitle => 'Textgröße der Notizen';
  @override
  String get noteTextScaleSubtitle =>
      'Der Editor und die Vorschau, die immer übereinstimmen';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Vorschau-Modus';
  @override
  String get previewModeSubtitle =>
      'Ob die Vorschau den Bildschirm mit dem Editor teilt oder ihn '
      'ersetzt';
  @override
  String get previewModeAuto => 'Nebeneinander';
  @override
  String get previewModeSwitch => 'Vollbild';
  @override
  String get splitRatioTitle => 'Teilungsbreite';
  @override
  String get splitRatioSubtitle =>
      'Der Anteil des Editors, wenn die Vorschau daneben steht';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Linkformat';
  @override
  String get linkTypeSubtitle => 'Was der Link-Knopf im Editor einfügt';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Einzugstiefe';
  @override
  String get indentWidthSubtitle => 'Leerzeichen pro Einzugsebene im Editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Sprache';
  @override
  String get languageSubtitle => 'Die Sprache der App-eigenen Texte';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Eintrag hinzufügen';
  @override
  String get listAddTooltip => 'Eintrag hinzufügen';
  @override
  String get listEmpty => 'Noch keine Einträge';
  @override
  String get listDragHandleLabel => 'Eintrag umsortieren';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Schnellnotiz';
  @override
  String get shortcutNewTodo => 'Neue Aufgabe';
  @override
  String get shortcutNewNote => 'Neue Notiz';
  @override
  String get shortcutNewList => 'Neue Liste';
  @override
  String get shortcutToggleSidebar => 'Dateibaum anzeigen oder ausblenden';
  @override
  String get shortcutEditorSection => 'Im Editor';
  @override
  String get shortcutFind => 'Suchen';
  @override
  String get shortcutReplace => 'Suchen und ersetzen';
  @override
  String get shortcutSavingNote =>
      'Änderungen werden automatisch gespeichert: es gibt kein '
      'Speichern-Kürzel.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Übersicht';
  @override
  String get outlineNoHeadings => 'Keine Überschriften';
  @override
  String get outlineNoTitle => '(ohne Titel)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Fett';
  @override
  String get toolbarItalic => 'Kursiv';
  @override
  String get toolbarStrikethrough => 'Durchgestrichen';
  @override
  String get toolbarSuperscript => 'Oberhalb';
  @override
  String get toolbarUnderline => 'Unterstreichen';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Codeblock';
  @override
  String get toolbarImage => 'Bild einfügen';
  @override
  String get toolbarHeading => 'Überschrift';
  @override
  String get toolbarList => 'Liste';
  @override
  String get toolbarOrderedList => 'Nummerierte Liste';
  @override
  String get toolbarQuote => 'Zitat';
  @override
  String get toolbarIndent => 'Einzug vergrößern';
  @override
  String get toolbarOutdent => 'Einzug verkleinern';
  @override
  String get headingDialogTitle => 'Überschriftsstufe';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editor-Symbolleiste';
  @override
  String get toolbarSettingsHint =>
      'Ziehen zum Umsortieren; das Auge zeigt oder blendet einen Knopf '
      'aus.';
  @override
  String get toolbarShowButton => 'Zeigen';
  @override
  String get toolbarHideButton => 'Ausblenden';
  @override
  String get toolbarResetOrder => 'Standard wiederherstellen';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Vorschau zeigen';
  @override
  String get showEditorTooltip => 'Editor zeigen';
  @override
  String get enterFullScreenTooltip => 'Vollbild';
  @override
  String get exitFullScreenTooltip => 'Vollbild beenden';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(rohe HTML-Tabelle)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Notizen durchsuchen';
  @override
  String get searchModeWords => 'Wörter';
  @override
  String get searchModeContains => 'Enthält';
  @override
  String get searchEmptyHint =>
      'Eingeben, um in der Bibliothek zu suchen, oder Schlüssel = Wert, '
      'um nach Frontmatter zu filtern';
  @override
  String get searchTooShortHint => 'Gib mindestens 2 Zeichen ein';
  @override
  String get searchNoMatches => 'Keine Treffer';
  @override
  String get searchLoadMore => 'Mehr anzeigen';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Ersetzen…';
  @override
  String get replaceInNoteAction => 'In dieser Notiz ersetzen…';
  @override
  String get replaceInThisNote => 'In dieser Notiz ersetzen';
  @override
  String get replaceWithLabel => 'Ersetzen durch';
  @override
  String get replaceCaseSensitive => 'Groß-/Kleinschreibung beachten';
  @override
  String get replaceWholeWordsHint =>
      'nur exakte Treffer ganzer Wörter werden ersetzt';
  @override
  String get replaceConfirm => 'Ersetzen';
  @override
  String get replaceCancel => 'Schließen';
  @override
  String get replaceUnavailable => 'Ersetzen ist gerade nicht verfügbar';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'In Notiz suchen';
  @override
  String get editorFindHint => 'Suchen';
  @override
  String get editorReplaceHint => 'Ersetzen';
  @override
  String get editorFindCaseTooltip => 'Groß-/Kleinschreibung beachten';
  @override
  String get editorFindPreviousTooltip => 'Vorheriger Treffer';
  @override
  String get editorFindNextTooltip => 'Nächster Treffer';
  @override
  String get editorFindCloseTooltip => 'Suche schließen';
  @override
  String get editorFindReplaceModeTooltip => 'Ersetzen-Modus';
  @override
  String get editorReplaceOneTooltip => 'Diesen Treffer ersetzen';
  @override
  String get editorReplaceAllTooltip => 'Alle Treffer ersetzen';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tags';
  @override
  String get tagsTitle => 'Tags';
  @override
  String get tagsEmpty =>
      'Noch keine Tags — füge ein #tag oder Frontmatter-Tags hinzu';
  @override
  String get tagsBackTooltip => 'Zurück zur Suche';
  @override
  String get tagsNotesEmpty => 'Keine Notizen mit diesem Tag';
  @override
  String tagsNotesCapped(int limit) =>
      'Nur die ersten $limit sind aufgelistet — suche den Tag, um zu '
      'filtern';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Link nicht gefunden';
  @override
  String get headingNotFoundTitle => 'Überschrift nicht gefunden';
  @override
  String get ambiguousLinkTitle => 'Mehrere Notizen passen';
  @override
  String get openLinkFailed => 'Link konnte nicht geöffnet werden';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Offen';
  @override
  String get todoDone => 'Erledigt';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Alle Daten';
  @override
  String get todoFilter => 'Filtern';
  @override
  String get todoNoTokens => 'Keine Token in dieser Liste';
  @override
  String get todoCountOpen => 'offen';
  @override
  String get todoCountDone => 'erledigt';
  @override
  String get todoEmptyOpen => 'Noch keine offenen Aufgaben';
  @override
  String get todoEmptyDone => 'Bisher nichts erledigt';
  @override
  String get todoEmptyFiltered => 'Keine Aufgabe passt';
  @override
  String get todoTitle => 'Aufgaben';
  @override
  String get todoAddTooltip => 'Aufgabe hinzufügen';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Das todo.txt-Format';
  @override
  String get todoHelpTooltip => 'Format-Hilfe';
  @override
  String get todoHelpIntro =>
      'Deine Aufgaben sind eine einfache Textdatei, eine Aufgabe pro '
      'Zeile. Niman schreibt die Syntax für dich, aber nichts ist '
      'verborgen: Du kannst die Datei in jedem Editor bearbeiten und '
      'Niman liest sie wieder ein.';
  @override
  String get todoHelpFilesTitle => 'Die zwei Dateien';
  @override
  String get todoHelpFilesBody =>
      'Offene Aufgaben liegen in todo.txt im Wurzelverzeichnis deiner '
      'Bibliothek. Wenn du eine abschließt, wandert ihre Zeile nach '
      'done.txt, damit todo.txt kurz bleibt. Landet eine abgeschlossene '
      'Zeile wieder in todo.txt, archiviert Niman sie beim nächsten '
      'Lesen der Dateien.';
  @override
  String get todoHelpLineTitle => 'Aufbau einer Zeile';
  @override
  String get todoHelpLineBody =>
      'Alles vor der Beschreibung ist optional und muss in dieser '
      'Reihenfolge stehen:';
  @override
  String get todoHelpDoneBody =>
      'Markiert die Aufgabe als erledigt. Niman fügt sie hinzu, wenn du '
      'das Kontrollkästchen anhäkst.';
  @override
  String get todoHelpPriority => 'von (A) bis (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priorität. A ist die höchste. Wird als Abzeichen in der Liste '
      'gezeigt.';
  @override
  String get todoHelpDatesBody =>
      'Erledigungsdatum, dann Erstellungsdatum. Mit nur einem Datum ist '
      'es das Erstellungsdatum, außer die Zeile beginnt mit x.';
  @override
  String get todoHelpTokensTitle => 'Projekte, Kontexte und Tags';
  @override
  String get todoHelpTokensBody =>
      'Überall in der Beschreibung wird ein Wort mit einem dieser '
      'Präfixe zu einem Chip, nach dem du filtern kannst. Nichts ist '
      'vorgegeben: Ein Token existiert, sobald du es schreibst.';
  @override
  String get todoHelpProjectBody =>
      'Wozu die Aufgabe gehört, zum Beispiel +küche oder +arbeit.';
  @override
  String get todoHelpContextBody =>
      'Wo oder wie du sie machst, zum Beispiel @zuhaus oder @anrufe.';
  @override
  String get todoHelpHashtagBody =>
      'Ein freies Label, für alles, was die anderen beiden nicht '
      'abdecken.';
  @override
  String get todoHelpTagsTitle => 'Daten und Erinnerungen';
  @override
  String get todoHelpTagsBody =>
      'Das sind Schlüssel:Wert-Tags. Niman schreibt sie aus dem '
      'Aufgaben-Dialog und liest sie überall dort, wo sie in der Zeile '
      'stehen.';
  @override
  String get todoHelpDueBody =>
      'Das Fälligkeitsdatum. Steuert das farbige Abzeichen und die '
      'Fälligkeitsfilter.';
  @override
  String get todoHelpRemBody =>
      'Wann eine Benachrichtigung gesendet wird, in deiner lokalen Zeit. '
      'Sie löst aus, wenn der Bildschirm aus ist und die App geschlossen.';
  @override
  String get todoHelpRemDesktop =>
      'Am Desktop muss Niman laufen, wenn der Zeitpunkt kommt: Die '
      'Erinnerung wird angezeigt, während die App offen ist, und es '
      'löst nichts aus, wenn sie geschlossen ist.';
  @override
  String get todoHelpOtherBody =>
      'Wird exakt so gespeichert, wie geschrieben, damit Tags anderer '
      'todo.txt-Apps den Hin- und Rückweg überstehen. Niman reagiert '
      'nicht darauf, rec: inklusive: Eine wiederkehrende Aufgabe wird '
      'noch nicht wiederholt.';
  @override
  String get todoHelpEditTitle => 'Bearbeiten außerhalb von Niman';
  @override
  String get todoHelpEditBody =>
      'Eine Aufgabe, die du nicht angefasst hast, wird bytegenau '
      'zurückgeschrieben, seltsame Abstände inklusive. Bearbeite eine '
      'Zeile, und Niman schreibt genau diese Zeile in ihrer kanonischen '
      'Form um und lässt den Rest der Datei in Ruhe.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Aufgabe hinzufügen';
  @override
  String get todoEditTitle => 'Aufgabe bearbeiten';
  @override
  String get todoDescriptionHint => 'Beschreibung';
  @override
  String get todoCancel => 'Abbrechen';
  @override
  String get todoSave => 'Speichern';
  @override
  String get todoEditAction => 'Bearbeiten';
  @override
  String get todoDeleteAction => 'Löschen';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Überfällig';
  @override
  String get todoDueToday => 'Heute';
  @override
  String get todoDueNext7 => 'Nächste 7 Tage';
  @override
  String get todoDueNoDate => 'Ohne Datum';
  @override
  String get todoRowDue => 'Fällig';
  @override
  String get todoRowDueToday => 'Heute fällig';
  @override
  String get todoSortTooltip => 'Sortieren';
  @override
  String get todoSortDue => 'Fälligkeitsdatum';
  @override
  String get todoSortPriority => 'Priorität';
  @override
  String get todoSortCreation => 'Erstellungsdatum';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Ohne Priorität';
  @override
  String get todoNoPriorityShort => 'Keine';
  @override
  String get todoMorePriorities => 'Mehr…';
  @override
  String get todoPriorityTitle => 'Priorität';
  @override
  String get todoNoDueDate => 'Ohne Fälligkeitsdatum';
  @override
  String get todoNoReminder => 'Ohne Erinnerung';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontext';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Aufgabenerinnerungen';
  @override
  String get todoReminderChannelDescription =>
      'Geplante Meldungen für Aufgaben mit Erinnerungszeit.';
  @override
  String get todoReminderBody => 'Aufgabenerinnerung';
  @override
  String get todoReminderFallbackTitle => 'Aufgabenerinnerung';
  @override
  String get todoReminderBlocked =>
      'Benachrichtigungen sind aus, daher erscheinen Erinnerungen nicht.';
  @override
  String get todoReminderBattery =>
      'Die Akkulaufzeit-Optimierung ist für Niman aktiv. Das System '
      'kann die App schlafen legen und ausstehende Erinnerungen verfallen '
      'lassen.';
  @override
  String get todoReminderInexact =>
      'Dieses Gerät erlaubt keine exakten Wecker, daher kann eine '
      'Erinnerung mit dem Bildschirm aus einige Minuten spät eintreffen.';
  @override
  String get reminderShowTokensTitle =>
      'Tags in Erinnerungs-Benachrichtigungen';
  @override
  String get reminderShowTokensSubtitle =>
      'Behält +projekt, @kontext und #tag im Benachrichtigungstext. Aus '
      'zeigt nur die Aufgabe, die du eingegeben hast.';
  @override
  String get todoReminderFixAction => 'Einstellungen öffnen';
  @override
  String get todoReminderDismissAction => 'Verwerfen';
  @override
  String get todoReminderDue => 'Fällig';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Abbrechen';
  @override
  String get actionCreate => 'Erstellen';
  @override
  String get actionNew => 'Neu';
  @override
  String get actionSave => 'Speichern';
  @override
  String get actionClear => 'Leeren';
  @override
  String get actionChoose => 'Wählen';
  @override
  String get actionDelete => 'Löschen';
  @override
  String get actionRename => 'Umbenennen';
  @override
  String get actionMove => 'Verschieben';
  @override
  String get saveAndClose => 'Speichern und schließen';
  @override
  String get closeUnsavedTitle => 'Nicht gespeicherte Änderungen';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}“ hat noch nicht gespeicherte Änderungen. '
          'Vor dem Schließen speichern?';
    }
    return '$names.length Notizen haben noch nicht gespeicherte '
        'Änderungen. Vor dem Schließen speichern?';
  }

  @override
  String get closeSaveFailed =>
      'Speichern nicht möglich; die Notiz bleibt geöffnet.';
  @override
  String get actionRestore => 'Wiederherstellen';
  @override
  String get actionEmpty => 'Leeren';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Seitenleiste ausblenden (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Seitenleiste anzeigen (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimieren';
  @override
  String get windowMaximizeTooltip => 'Maximieren';
  @override
  String get windowRestoreTooltip => 'Wiederherstellen';
  @override
  String get windowCloseTooltip => 'Schließen';
  @override
  String get tabFiles => 'Dateien';
  @override
  String get tabSearch => 'Suche';
  @override
  String get tabSettings => 'Einstellungen';
  @override
  String get quickNoteTitle => 'Schnellnotiz';
  @override
  String get treeEmpty => 'Noch keine Notizen';
  @override
  String get selectANote => 'Notiz auswählen';
  @override
  String get showListTooltip => 'Liste anzeigen';
  @override
  String get editRawTooltip => 'Rohdaten bearbeiten';
  @override
  String get sortAscTooltip => 'A-Z sortieren';
  @override
  String get sortDescTooltip => 'Z-A sortieren';
  @override
  String get newNoteTitle => 'Neue Notiz';
  @override
  String get newFolderTitle => 'Neuer Ordner';
  @override
  String get newNoteHere => 'Neue Notiz hier';
  @override
  String get newFolderHere => 'Neuer Ordner hier';
  @override
  String get newListNoteTitle => 'Neue Listen-Notiz';
  @override
  String get newListNoteDefault => 'Meine Liste';
  @override
  String get setAsQuickNote => 'Als Schnellnotiz festlegen';
  @override
  String get currentQuickNote => 'Aktuelle Schnellnotiz';
  @override
  String get pinnedSection => 'Angeheftet';
  @override
  String pinnedSectionCount(int count) => 'Angeheftet · $count';
  @override
  String get templateFolderTitle => 'Vorlagen-Ordner';
  @override
  String get newFromTemplateTitle => 'Neu aus Vorlage';
  @override
  String get newFromTemplateHere => 'Neu aus Vorlage hier';
  @override
  String get templateFormTitle => 'Vorlage ausfüllen';
  @override
  String get templateFormBacklink => 'Verlinkt von';
  @override
  String get templateFormNoNote => 'Keine Notiz';
  @override
  String get templateFormPickNote => 'Notiz wählen';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Vorlagen-Platzhalter';
  @override
  String get templateHelpIntro =>
      'Eine Vorlage ist eine gewöhnliche Notiz mit Löchern. Eine Notiz '
      'aus ihr zu erstellen kopiert ihren Text und füllt die Löcher.';
  @override
  String get templateHelpUnknown =>
      'Ein Platzhalter, den Niman nicht kennt, bleibt exakt so, wie '
      'geschrieben, damit ein Tippfehler in der Notiz sichtbar wird '
      'statt eine Zeile still zu fressen.';
  @override
  String get templateHelpValuesTitle => 'Werte';
  @override
  String get templateHelpTitleBody =>
      'Der Name, unter dem die Notiz erstellt wird.';
  @override
  String get templateHelpDateBody =>
      'Heute, und die Uhrzeit jetzt. Beide nehmen ein Format: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Datum und Uhrzeit zusammen.';
  @override
  String get templateHelpUuidBody =>
      'Eine frische Kennung, bei jedem Vorkommen anders.';
  @override
  String get templateHelpCounterBody =>
      'Eine Zahl, die pro Namen hochzählt und über Neustarts erhalten '
      'bleibt: Die erste Notiz schreibt 1, die nächste 2. Gleicher Name '
      'in einer Notiz schreibt die gleiche Zahl; mit |pad:3 kombinieren.';
  @override
  String get templateHelpCursorBody =>
      'Setzt den Cursor hier, wenn die Notiz erstellt wird; der Marker '
      'selbst wird nicht geschrieben. Der erste Marker gewinnt, keine '
      'Filter, nur neue Notizen — und die Tastatur öffnet sich auch mit '
      'ausgeschaltetem Auto-Fokus.';
  @override
  String get templateHelpDatesTitle => 'Ein Datum schreiben';
  @override
  String get templateHelpDatesBody =>
      'Diese stehen für Teile des Datums in einem Format. Alles andere '
      'ist wörtlich, und auch Text in einfachen Anführungszeichen. '
      'Monats- und Wochentagsnamen folgen der App-Sprache.';
  @override
  String get templateHelpYear => 'das Jahr: 2026, 26';
  @override
  String get templateHelpMonth => 'der Monat: 03, 3, März, März';
  @override
  String get templateHelpDay => 'der Tag: 09, 9, Montag, Mo.';
  @override
  String get templateHelpTime => 'Stunden, Minuten, Sekunden';
  @override
  String get templateHelpWeek => 'die ISO-Woche und das Quartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filter';
  @override
  String get templateHelpFiltersBody =>
      'Einem Wert können Filter folgen, von links nach rechts angewendet.';
  @override
  String get templateHelpCaseBody =>
      'Großschreibung, Kleinschreibung, und der Anfangsbuchstabe jedes '
      'Worts — ein Wort, das du selbst großgeschrieben hast, bleibt so.';
  @override
  String get templateHelpSlugBody =>
      'Die Link-Form des Textes, um einen Wikilink zu bauen.';
  @override
  String get templateHelpPadBody =>
      'Enden abschneiden; mit Nullen auf eine Breite auffüllen; ein '
      'Rückgriff, wenn der Wert leer ist.';
  @override
  String get templateHelpShiftBody =>
      'Ein Datum um Tage, Wochen, Monate oder Jahre verschieben — der '
      'Vortrag nächste Woche, die Datei vom letzten Monat.';
  @override
  String get templateHelpSnapBody =>
      'Ein Datum auf den Anfang oder das Ende seiner Woche, seines '
      'Monats oder seiner Jahres ansetzen.';
  @override
  String get templateHelpAskTitle => 'Etwas von dir verlangen';
  @override
  String get templateHelpAskBody =>
      'Vor der Erstellung erscheint ein Formular, ein Feld pro Frage — '
      'und eines für den Rückverweis, wenn die Vorlage ihn will. Dieselbe '
      'Beschriftung zweimal ist eine Frage, und ihre Antwort füllt '
      'jedes Vorkommen — Ordner und Dateiname inklusive.';
  @override
  String get templateHelpAskFieldBody =>
      'Ein Feld zum Tippen; der Text nach dem zweiten Doppelpunkt ist, '
      'mit dem es beginnt.';
  @override
  String get templateHelpChoiceBody =>
      'Eine Auswahl aus einer Liste, getrennt durch Kommas.';
  @override
  String get templateHelpWhereTitle => 'Wohin die Notiz geht';
  @override
  String get templateHelpWhereBody =>
      'Das sind kein Text: Das sind Anweisungen, und sie stehen in einem '
      'niman:-Block im eigenen Frontmatter der Vorlage. Der Block wird '
      'ausgeführt und dann entfernt, er erscheint also nie in der Notiz. '
      'Ihre Werte können Platzhalter enthalten.';
  @override
  String get templateHelpFolderBody =>
      'Der Ordner, in dem die Notiz erstellt wird, erstellt, wenn er '
      'nicht da ist. Ohne ihn landet die Notiz, wo du warst.';
  @override
  String get templateHelpFilenameBody =>
      'Wie die Notiz heißt. Eine Vorlage, die das angibt, wird nicht '
      'nach einem Namen gefragt.';
  @override
  String get templateHelpAppendBody =>
      'Fügt der Notiz hinzu, wenn sie schon da ist, statt eine zweite zu '
      'erstellen. Das macht aus einem Monat Meetings eine einzige Datei.';
  @override
  String get templateHelpOpenBody =>
      'Was passiert, wenn die Notiz existiert: der Editor (der '
      'Standard), die Vorschau, oder nichts — die Notiz wird abgelegt '
      'und du bleibst, wo du warst.';
  @override
  String get templateHelpAroundTitle => 'Woher sie kommt';
  @override
  String get templateHelpParentBody =>
      'Eine Notiz, die du im Formular wählst, die die auf dem Bildschirm '
      'vorschlägt; schreibe [[{{parent}}]] für einen Rückverweis.';
  @override
  String get templateHelpFolderValueBody =>
      'Der Ordner, in dem die Notiz gelandet ist.';
  @override
  String get templateHelpClipboardBody =>
      'Was in der Zwischenablage liegt, und die Editor-Auswahl, wenn die '
      'Notiz von einer ausging.';
  @override
  String get templateHelpIncludeTitle => 'Ein Stück wiederverwenden';
  @override
  String get templateHelpIncludeBody =>
      'Fügt eine andere Vorlage ein, damit zehn Vorlagen eine einzige '
      'Checkliste teilen. Gesucht wird zuerst im Vorlagen-Ordner, und '
      'die .md kann weggelassen werden. Ihre eigenen Fragen kommen in '
      'dasselbe Formular.';
  @override
  String get templateHelpExampleTitle => 'Alles zusammen';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ keine Vorlage „$path“';
  @override
  String includeCycle(String path) => '⚠ „$path“ enthält sich selbst';
  @override
  String includeTooDeep(String path) => '⚠ „$path“ ist zu tief verschachtelt';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatter nicht gelesen: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Das Frontmatter von „$template“ wurde nicht gelesen, daher haben '
      'sein Ordner und Dateiname nichts getan: $reason';
  @override
  String get templatePickerTitle => 'Vorlage wählen';
  @override
  String templatePickerEmpty(String folder) =>
      'Noch keine Vorlagen. Lege eine Notiz in $folder/ ab, und sie wird '
      'eine.';

  // Tree actions.
  @override
  String get actionPin => 'Anheften';
  @override
  String get actionUnpin => 'Loslösen';
  @override
  String get movedToTrash => 'In den Papierkorb verschoben';
  @override
  String get deletedMessage => 'Gelöscht';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name wird nach .trash/ verschoben';
  @override
  String deleteForeverConfirm(String name) => '$name wird endgültig gelöscht';
  @override
  String get chooseDestination => 'Ziel wählen';
  @override
  String get libraryRoot => 'Bibliotheks-Wurzel';
  @override
  String moveTitle(String name) => '$name verschieben';
  @override
  String headingLevelLabel(int level) => 'Überschrift Stufe $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Noch keine Schnellnotiz. Wähle eine vorhandene Notiz oder erstelle '
      'eine neue — die Schnellnotiz öffnet sich hier.';
  @override
  String get quickNoteChooseAction => 'Notiz wählen…';
  @override
  String get quickNoteCreateAction => 'Neue Notiz erstellen…';
  @override
  String get quickNoteNewTitle => 'Neue Schnellnotiz';
  @override
  String get quickNotePickerTitle => 'Schnellnotiz wählen';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Neuer Ordner';
  @override
  String get folderPickerEmpty => 'Noch keine Ordner';
  @override
  String get listFolderTitle => 'Listen-Ordner';

  // Trash (M1).
  @override
  String get trashEmpty => 'Der Papierkorb ist leer';
  @override
  String get trashEmptyAction => 'Papierkorb leeren';
  @override
  String get trashEmptyConfirm =>
      'Das löscht alles im Papierkorb-Ordner endgültig, auch Einträge, '
      'die Niman dort nicht hingelegt hat.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name wird endgültig gelöscht (ohne Wiederherstellung)';
  @override
  String get trashDeletePermanently => 'Endgültig löschen';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Öffne einen Ordner mit Markdown-Notizen als Bibliothek';
  @override
  String get openLibraryExisting => 'Bestehende öffnen';
  @override
  String get openLibraryCreate => 'Neue erstellen';
  @override
  String get openLibraryCreateTitle => 'Neue Bibliothek erstellen';
  @override
  String get openLibraryFolderName => 'Ordnername';
  @override
  String get openLibraryChooseFolder => 'Bibliotheks-Ordner wählen';
  @override
  String get openLibraryChooseParent =>
      'Ordner wählen, in dem die Bibliothek erstellt wird';
  @override
  String get openLibraryUnsupported =>
      'Dieser Ordner wird nicht unterstützt. Wähle einen Ordner im '
      'Speicher des Geräts.';
  @override
  String indexingCount(int done, int total) => '$done von $total Notizen';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Deine Bibliotheken';
  @override
  String get libraryUnreachable => 'Nicht erreichbar';
  @override
  String get libraryOpenedToday => 'Heute geöffnet';
  @override
  String get libraryOpenedYesterday => 'Gestern geöffnet';
  @override
  String libraryOpenedDaysAgo(int days) => 'Vor $days Tagen geöffnet';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Geöffnet am $d.$m.${when.year}';
  }

  @override
  String get libraryOpenNow => 'Jetzt öffnen';
  @override
  String get switchLibraryTitle => 'Bibliothek wechseln';
  @override
  String get libraryForget => 'Vergessen';
  @override
  String libraryForgetTitle(String name) => '„$name“ vergessen?';
  @override
  String get libraryForgetExplained =>
      'Sie verschwindet aus dieser Liste. Der Ordner, die Notizen und '
      'die Bibliothekseinstellungen bleiben, wo sie sind, und das '
      'erneute Öffnen bringt sie zurück.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dateizugriff erteilen';
  @override
  String get storageAccessNeeded =>
      'Ohne „Zugriff auf alle Dateien“ kann Niman deine Notizen nicht '
      'lesen. Erteile ihn, um eine Bibliothek zu öffnen.';
  @override
  String get storageAccessExplained =>
      'Niman liest deine Notizen als gewöhnliche Dateien, daher muss '
      'Android ihm den Zugriff auf alle Dateien erlauben. Es wird '
      'nichts hochgeladen, und nur der gewählte Bibliotheks-Ordner '
      'wird gelesen.';
  @override
  String folderAccessDenied(Object error) =>
      'Das System hat keinen Zugriff auf den Ordner gegeben: $error';
  @override
  String folderPickFailed(Object error) =>
      'Ordner konnte nicht gewählt werden: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Einstellungen';
  @override
  String get libraryPathTitle => 'Bibliothekspfad';
  @override
  String get reindexTitle => 'Jetzt neu indizieren';
  @override
  String get reindexDone => 'Neu-Indizierung abgeschlossen';
  @override
  String get closeLibraryTitle => 'Bibliothek schließen';
  @override
  String get exportLogTitle => 'Debug-Protokoll exportieren';
  @override
  String get exportLogSubtitle =>
      'Speichert die aufgezeichneten Ereignisse in eine Datei deiner '
      'Wahl';
  @override
  String get exportLogEmpty => 'Der Debug-Protokoll-Puffer ist leer';
  @override
  String get quickNoteUnset => 'Noch nicht festgelegt';
  @override
  String exportLogDone(Object target) =>
      'Debug-Protokoll nach $target exportiert';
  @override
  String exportLogFailed(Object error) => 'Export fehlgeschlagen: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Kein Treffer des ganzen Worts „$term“ gefunden';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences Vorkommen von „$term“ in $notes Notiz(en) ersetzt';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped offene Notiz(en) übersprungen)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Kein exakter Treffer des ganzen Worts „$term“ '
      '${only == null ? 'gefunden' : 'gefunden in $only'}';
}
