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
  String get trashAutoEmptyTitle => 'Papierkorb automatisch leeren';
  @override
  String get trashAutoEmptySubtitle =>
      'Ältere Löschungen verschwinden beim Öffnen endgültig';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Nie'
      : days == 1
      ? '1 Tag'
      : '$days Tage';
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
  String get readableLineLengthTitle => 'Lesbare Zeilenlänge';
  @override
  String get readableLineLengthSubtitle =>
      'Den Text einer Notiz in einer zentrierten Spalte halten statt über die '
      'ganze Fensterbreite';
  @override
  String get noteColumnWidthTitle => 'Spaltenbreite';
  @override
  String get noteColumnWidthSubtitle =>
      'Wie breit die Spalte der Notiz ist, in Pixeln';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
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
  String get editorKindSourceSubtitle => 'Markdown-Quelle, wie geschrieben';
  @override
  String get editorKindWysiwygSubtitle =>
      'Formatierter Text, direkt bearbeitet';
  @override
  String get settingsFolderToCreate => 'zu erstellen';
  @override
  String get settingsSearchHint => 'Einstellungen durchsuchen';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 Einstellung gefunden' : '$count Einstellungen gefunden';
  @override
  String get settingsToggleOn => 'An';
  @override
  String get settingsToggleOff => 'Aus';
  @override
  String get switchToWysiwygTooltip => 'Zum WYSIWYG-Editor wechseln';
  @override
  String get switchToSourceTooltip => 'Zum Markdown-Quelltext wechseln';
  @override
  String get switchToSourceLabel => 'Quelle';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
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

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bibliothek $name';
  @override
  String get settingsGroupLibraryHint => 'gilt nur für diese Bibliothek';
  @override
  String get settingsGroupMaintenance => 'Wartung';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Ordner und Pfade';
  @override
  String get settingsAreaTrashHistory => 'Papierkorb und Verlauf';
  @override
  String get settingsAreaDiagnostics => 'Diagnose und Info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Benötigt eine angeschlossene physische Tastatur';
  @override
  String get settingsSectionUpdates => 'Updates';
  @override
  String get autoUpdateTitle => 'Automatische Updates';
  @override
  String get autoUpdateSubtitle =>
      'GitHub Releases beim Start und alle 6 Stunden prüfen';
  @override
  String get checkForUpdatesTitle => 'Nach Updates suchen';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version ist verfügbar';
  @override
  String get updateUpToDate => 'Niman ist auf dem neuesten Stand';
  @override
  String get updateCheckFailed => 'Update-Prüfung fehlgeschlagen';
  @override
  String updateSavedTo(Object path) => 'Update gespeichert unter $path';
  @override
  String get updateInstallerStarted => 'Installationsprogramm gestartet';
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
  String get addWordToDictionary => 'Zum Wörterbuch hinzufügen';

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
  String get themeTitle => 'Design';
  @override
  String get themeSubtitle => 'Die Farben der Oberfläche und der Notiz';
  @override
  String get themePaletteSystem => 'System';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Designs';
  @override
  String get themesInUse => 'In Verwendung';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Neues Design';
  @override
  String get themeNewName => 'Name';
  @override
  String get themeNewStartFrom => 'Beginnen mit';
  @override
  String get themeNewRandom => 'Zufällige Farben';
  @override
  String get themeNameTaken => 'Ein Design mit diesem Namen gibt es schon';
  @override
  String themeDeleteBody(String name) =>
      '„$name“ löschen? Seine Farben sind dann endgültig weg.';
  @override
  String get themeDuplicate => 'Duplizieren';
  @override
  String get themeMenuTooltip => 'Design-Aktionen';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Bearbeiten';
  @override
  String get themeEditorTitle => 'Design bearbeiten';
  @override
  String get themeEditorChrome => 'Oberfläche';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorTaskLists => 'Aufgabenlisten (todo.txt)';
  @override
  String get themeEditorRolesHint =>
      'Jede Farbe heißt so, wie die exportierte Datei sie nennt';
  @override
  String get themeEditorDiscardTitle => 'Änderungen verwerfen';
  @override
  String get themeEditorDiscardBody =>
      'Die Farben, die du geändert hast, werden nicht gespeichert';
  @override
  String get themeEditorDiscard => 'Verwerfen';
  @override
  String get themeEditorBadColor => '#RRGGBB verwenden';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Exportieren';
  @override
  String themeExportDone(String where) => 'Design exportiert nach $where';
  @override
  String themeFileFailed(String error) =>
      'Das Design konnte nicht übertragen werden: $error';
  @override
  String get themeImport => 'Importieren';
  @override
  String get themeImportInvalid => 'Diese Datei ist kein Niman-Design';
  @override
  String themeImportVersion(int version) =>
      'Dieses Design stammt aus einem neueren Niman (Version $version)';
  @override
  String themeImportBadRole(String role) =>
      'Die Datei gibt keine Farbe für „$role“ an';

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
  @override
  String get epubLookTitle => 'Aussehen der Bücher';
  @override
  String get epubLookSubtitle =>
      'Design, Schrift und Textgröße der EPUB-Bücher, getrennt von den Notizen';
  @override
  String get epubSameAsApp => 'Wie die App';
  @override
  String get epubFontTitle => 'Schrift';
  @override
  String get epubFontSerif => 'Serifen';
  @override
  String get epubFontSans => 'Serifenlos';
  @override
  String get epubFontMono => 'Monospace';
  @override
  String get epubTextSizeTitle => 'Textgröße';

  // Settings: preview mode.
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
  String get missingNoteLocationTitle => 'Fehlende Notizen erstellen in';
  @override
  String get missingNoteLocationRoot => 'Bibliothekswurzel';
  @override
  String get missingNoteLocationCurrentFolder => 'Aktueller Ordner';
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

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Noch keine Aufnahmen';
  @override
  String get audioRecord => 'Aufnehmen';
  @override
  String get audioStop => 'Stopp';
  @override
  String get audioPlay => 'Abspielen';
  @override
  String get audioDelete => 'Aufnahme löschen';
  @override
  String get audioImport => 'Audiodatei importieren';
  @override
  String get audioRecording => 'Aufnahme läuft…';
  @override
  String get audioPermissionDenied =>
      'Mikrofonzugriff verweigert — für Aufnahmen erforderlich.';
  @override
  String get newAudioNoteTitle => 'Neue Sprachnotiz';
  @override
  String get newAudioNoteDefault => 'Meine Aufnahme';
  @override
  String get showAudioTooltip => 'Aufnahmen anzeigen';
  @override
  String get audioMessageHint => 'Notiz schreiben…';
  @override
  String get audioSend => 'Senden';
  @override
  String get audioRename => 'Aufnahme umbenennen';
  @override
  String get audioDescriptionHint => 'Beschreibe diese Aufnahme…';
  @override
  String get audioEditDescription => 'Beschreibung bearbeiten';
  @override
  String get audioDeleteNote => 'Notiz löschen';
  @override
  String get audioEditNote => 'Notiz bearbeiten';
  @override
  String get audioPause => 'Pause';
  @override
  String get audioEditTitle => 'Titel bearbeiten';
  @override
  String get audioTitleHint => 'Titel für diese Aufnahme…';
  @override
  String audioUntitled(int n) => 'Aufnahme $n';
  @override
  String get audioMoreActions => 'Weitere Aktionen';
  @override
  String get audioDiscardRecording => 'Aufnahme verwerfen';
  @override
  String get audioPauseRecording => 'Aufnahme pausieren';
  @override
  String get audioResumeRecording => 'Aufnahme fortsetzen';
  @override
  String get audioRecordingPaused => 'Pausiert';
  @override
  String get audioSavingRecording => 'Wird gespeichert…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Schnellnotiz';
  @override
  String get trayOpen => 'Niman öffnen';
  @override
  String get trayQuit => 'Beenden';
  @override
  String get closeToTrayTitle => 'In den Infobereich schließen';
  @override
  String get closeToTraySubtitle =>
      'Das × des Fensters blendet Niman aus und lässt es laufen, damit '
      'Erinnerungen weiter kommen. Beenden über das Menü des Symbols.';
  @override
  String get shortcutNewTodo => 'Neue Aufgabe';
  @override
  String get shortcutNewNote => 'Neue Notiz';
  @override
  String get shortcutNewList => 'Neue Liste';
  @override
  String get shortcutNewAudio => 'Neue Sprachnotiz';
  @override
  String get shortcutToggleSidebar => 'Dateibaum anzeigen oder ausblenden';
  @override
  String get shortcutCloseTab => 'Aktuelle Notiz schließen';
  @override
  String get shortcutNextTab => 'Nächste offene Notiz';
  @override
  String get shortcutPreviousTab => 'Vorherige offene Notiz';
  @override
  String get shortcutEditorSection => 'Im Editor';
  @override
  String get shortcutFormatSection => 'Formatierung';
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
  String get noteStatusLoading => 'Wird geladen…';
  @override
  String get noteStatusSaving => 'Wird gespeichert…';
  @override
  String get noteStatusUnsaved => 'Nicht gespeichert';
  @override
  String get noteStatusSaved => 'Gespeichert';
  @override
  String get noteStatusError => 'Fehler';
  @override
  String get noteNotText =>
      'Diese Datei ist keine Textnotiz, daher kann '
      'Niman sie hier nicht anzeigen.';
  @override
  String get noteLoadFailed => 'Diese Notiz konnte nicht geöffnet werden.';
  @override
  String wordCount(int count) => count == 1 ? '1 Wort' : '$count Wörter';
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
  String get toolbarHighlight => 'Hervorheben';
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
  String get toolbarTable => 'Tabelle';
  @override
  String get tableRow => 'Zeile';
  @override
  String get tableColumn => 'Spalte';
  @override
  String get tableAddRowAbove => 'Zeile darüber einfügen';
  @override
  String get tableAddRowBelow => 'Zeile darunter einfügen';
  @override
  String get tableMoveRowUp => 'Zeile nach oben';
  @override
  String get tableMoveRowDown => 'Zeile nach unten';
  @override
  String get tableDuplicateRow => 'Zeile duplizieren';
  @override
  String get tableDeleteRow => 'Zeile löschen';
  @override
  String get tableAddColumnLeft => 'Spalte links einfügen';
  @override
  String get tableAddColumnRight => 'Spalte rechts einfügen';
  @override
  String get tableMoveColumnLeft => 'Spalte nach links';
  @override
  String get tableMoveColumnRight => 'Spalte nach rechts';
  @override
  String get tableAlignLeft => 'Linksbündig';
  @override
  String get tableAlignCenter => 'Zentriert';
  @override
  String get tableAlignRight => 'Rechtsbündig';
  @override
  String get tableDuplicateColumn => 'Spalte duplizieren';
  @override
  String get tableDeleteColumn => 'Spalte löschen';
  @override
  String get tableSortAscending => 'Nach Spalte sortieren (A → Z)';
  @override
  String get tableSortDescending => 'Nach Spalte sortieren (Z → A)';
  @override
  String get tableAddRow => 'Zeile hinzufügen';
  @override
  String get tableAddColumn => 'Spalte hinzufügen';
  @override
  String get cheatsheetTitle => 'Markdown-Spickzettel';
  @override
  String get cheatsheetCopy => 'Kopieren';
  @override
  String get cheatsheetCopied => 'Kopiert';
  @override
  String get cheatsheetInsert => 'In die Notiz einfügen';
  @override
  String get cheatsheetWritten => 'Geschrieben';
  @override
  String get cheatsheetShown => 'Angezeigt';
  @override
  String get cheatHeadings => 'Überschriften';
  @override
  String get cheatEmphasis => 'Fett, kursiv, durchgestrichen';
  @override
  String get cheatHtmlFormats => 'Unterstrichen, hochgestellt, tiefgestellt';
  @override
  String get cheatLists => 'Listen';
  @override
  String get cheatChecklists => 'Checklisten';
  @override
  String get cheatQuotes => 'Zitate';

  @override
  String get cheatCallouts => 'Callouts';
  @override
  String get cheatLinks => 'Links';
  @override
  String get cheatWikilinks => 'Links zu Notizen';
  @override
  String get cheatEmbeds => 'Bilder und Einbettungen';
  @override
  String get cheatTags => 'Tags';
  @override
  String get cheatInlineCode => 'Code im Satz';
  @override
  String get cheatCodeBlocks => 'Codeblöcke';
  @override
  String get cheatMath => 'Mathematik';
  @override
  String get cheatTables => 'Tabellen';
  @override
  String get cheatFootnotes => 'Fußnoten';
  @override
  String get cheatRule => 'Trennlinie';
  @override
  String get cheatFrontmatter => 'Frontmatter';
  @override
  String get cheatTemplates => 'Vorlagen-Platzhalter';
  @override
  String get menuAddLink => 'Link hinzufügen';
  @override
  String get menuAddExternalLink => 'Externen Link hinzufügen';
  @override
  String get menuFormat => 'Format';
  @override
  String get menuParagraph => 'Absatz';
  @override
  String get menuInsert => 'Einfügen';
  @override
  String get menuBody => 'Fließtext';
  @override
  String get formatSubscript => 'Tiefgestellt';
  @override
  String get formatInlineCode => 'Code';
  @override
  String get insertFootnote => 'Fußnote';
  @override
  String get insertRule => 'Trennlinie';
  @override
  String get insertCodeBlock => 'Codeblock';
  @override
  String get insertMathBlock => 'Mathematikblock';
  @override
  String get menuHeadingWord => 'Überschrift';
  @override
  String get toolbarHeading => 'Überschrift';
  @override
  String get toolbarList => 'Liste';
  @override
  String get toolbarOrderedList => 'Nummerierte Liste';
  @override
  String get toolbarChecklist => 'Checkliste';
  @override
  String get toolbarQuote => 'Zitat';
  @override
  String get toolbarIndent => 'Einzug vergrößern';
  @override
  String get toolbarOutdent => 'Einzug verkleinern';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Werkzeuge';
  @override
  String get editorToolsTitle => 'Editor-Werkzeuge';
  @override
  String get toolCountListTitle => 'Liste zählen';
  @override
  String get toolCountListSubtitle =>
      'Zählt zusammen, was die Zeilen aufführen, als Checkliste';
  @override
  String get toolCountListNeedsList => 'Diese Notiz hat keine Liste zum Zählen';
  @override
  String get tallySourceLabel => 'Liste';
  @override
  String get tallyCutLabel => 'Jede Zeile lesen als';
  @override
  String get tallyCutDash => 'Name - Werte';
  @override
  String get tallyCutColon => 'Name: Werte';
  @override
  String get tallyCutCommas => 'Werte, durch Komma getrennt';
  @override
  String get tallyCutWhole => 'Die ganze Zeile als ein Wert';
  @override
  String get tallySortLabel => 'Reihenfolge';
  @override
  String get tallySortCount => 'Häufigste zuerst';
  @override
  String get tallySortAlphabetical => 'Alphabetisch';
  @override
  String get tallySortFirstSeen => 'Wie aufgeführt';
  @override
  String get tallyInsert => 'Einfügen';
  @override
  String get tallyUpdate => 'Aktualisieren';
  @override
  String get tallyNothingToCount => 'Hier gibt es nichts zu zählen';
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

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Notiz existiert nicht';
  @override
  String missingNoteDialogBody(String path) => '„$path" erstellen?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Der Ordner „$folder" existiert nicht';

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
  String get newItemTooltip => 'Neu';
  @override
  String get closeMenuTooltip => 'Schließen';
  @override
  String get newFolderTitle => 'Neuer Ordner';
  @override
  String get newNoteSameFolder => 'Neue Notiz im selben Ordner';
  @override
  String get newFromTemplateSameFolder => 'Neu aus Vorlage im selben Ordner';
  @override
  String trashOriginalPath(String path) => 'war in $path';
  @override
  String get trashOriginalRoot => 'war im Hauptordner der Bibliothek';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 Element' : '$count Elemente';
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
  String get templateHelpSubtitle =>
      'Datum, Titel und die übrigen auszufüllenden Werte';
  @override
  String get quickNoteSubtitle => 'Die Notiz, die der Reiter Kurznotiz öffnet';
  @override
  String get listFolderSubtitle => 'Die neuen Aufgabenlisten';
  @override
  String get templateFolderSubtitle => 'Die Quelle für „Neu aus Vorlage“';
  @override
  String get attachmentsFolderSubtitle => 'Bilder und Audio in einer Notiz';
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
  String get pinToWidget => 'An Home-Widget anheften';
  @override
  String get pinnedForWidget =>
      'Geheftet: füge jetzt das Notiz-Widget zum Startbildschirm hinzu';
  @override
  String get pinWidgetUnavailable =>
      'Home-Bildschirm-Widgets sind auf Android verfügbar';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Im Dateimanager anzeigen';
  @override
  String get openInDefaultApp => 'Mit Standard-App öffnen';
  @override
  String get newNoteTabTooltip => 'Neue Notiz in neuem Tab';
  @override
  String get openNotesTooltip => 'Offene Notizen';
  @override
  String get closeTabTooltip => 'Schließen';
  @override
  String get openInNewTab => 'In neuem Tab öffnen';
  @override
  String get splitRight => 'Rechts teilen';
  @override
  String get splitDown => 'Unten teilen';
  @override
  String get moveToOtherPane => 'In den anderen Bereich verschieben';
  @override
  String get openBeside => 'Daneben öffnen';
  @override
  String get closeAllNotes => 'Alle schließen';
  @override
  String get sidePanelTooltip => 'Seitenleiste ein- oder ausblenden';
  @override
  String get historyAllVersions => 'Alle Versionen';
  @override
  String get commandPaletteTitle => 'Befehlspalette';
  @override
  String get goToNoteTitle => 'Zur Notiz';
  @override
  String get paletteGroupNote => 'Notiz';
  @override
  String get paletteGroupEditor => 'Editor';
  @override
  String get paletteGroupView => 'Ansicht';
  @override
  String get paletteGroupLibrary => 'Bibliothek';
  @override
  String get paletteGroupGoTo => 'Gehe zu';
  @override
  String get paletteGroupJournal => 'Tagebuch';
  @override
  String get journalToday => 'Heutiger Eintrag';
  @override
  String get journalPrevious => 'Vorheriger Eintrag';
  @override
  String get journalNext => 'Nächster Eintrag';
  @override
  String get commandNeedJournalEntry => 'Braucht einen offenen Tagebucheintrag';
  @override
  String journalCreateAsk(String day) =>
      'Für $day gibt es noch keinen Eintrag. Anlegen?';
  @override
  String journalTemplateMissing(String path) =>
      'Die Tagebuchvorlage $path ließ sich nicht lesen: Der Eintrag wurde '
      'ohne sie angelegt.';
  @override
  String get journalIntro =>
      'Eine Notiz pro Tag, beim ersten Öffnen des Tages aus einer Vorlage '
      'angelegt. Diese Einstellungen reisen mit der Bibliothek.';
  @override
  String get journalFolderTitle => 'Tagebuchordner';
  @override
  String get journalFolderSubtitle => 'Wohin die Einträge kommen';
  @override
  String get journalEntryNameTitle => 'Name des Eintrags';
  @override
  String get journalEntryNameSubtitle =>
      'YYYY, MM oder M, DD oder D für das Datum; / legt einen Ordner an; Text '
      "in 'Anführungszeichen' bleibt, wie er ist";
  @override
  String journalEntryNamePreview(String path) => 'Heutiger Eintrag: $path';
  @override
  String get journalEntryNameInvalid =>
      'Braucht YYYY, einen Monat (MM oder M) und einen Tag (DD oder D), und '
      'nichts, was ein Dateiname nicht enthalten darf';
  @override
  String get journalTemplateTitle => 'Vorlage';
  @override
  String get journalTemplateSubtitle => 'Womit ein neuer Eintrag beginnt';
  @override
  String get journalTemplateNone => 'Keine: eine Überschrift mit dem Datum';
  @override
  String get journalDayStartTitle => 'Ein neuer Tag beginnt um';
  @override
  String get journalDayStartSubtitle =>
      'Lange auf? Um 04:00 bleibt die Nacht beim Vortag';
  @override
  String get journalRecent => 'Zuletzt';
  @override
  String get journalNoEntry => 'Kein Eintrag für diesen Tag';
  @override
  String get journalOpenEntry => 'Öffnen';
  @override
  String get journalShowCalendar => 'Kalender zeigen';
  @override
  String get journalFabToday => 'Heutiger Tagebucheintrag';
  @override
  String journalDueOn(String day) => 'Fällig am $day';
  @override
  String get commandsTitle => 'Befehle';
  @override
  String get commandsIntro =>
      'Die Befehlspalette bietet nur die Befehle an, die dort ausführbar '
      'sind, wo du gerade bist. Hier stehen alle, und wann jeder erscheint.';
  @override
  String get commandsKeysNote =>
      'Hier wird nichts geändert. Die Tasten sind die unter „Tastaturkürzel“ '
      'festgelegten und folgen jeder Änderung dort.';
  @override
  String get commandsOpenShortcuts => 'Tasten unter „Tastaturkürzel“ ändern';
  @override
  String get commandsChangeKeyTooltip => 'Unter „Tastaturkürzel“ ändern';
  @override
  String get commandsSubtitle =>
      'Was die Befehlspalette ausführen kann, und wann';
  @override
  String get keyboardShortcutsSubtitle => 'Die Tasten jedes Befehls ändern';
  @override
  String get commandNeedNone => 'Immer verfügbar';
  @override
  String get commandNeedOpenNote => 'Braucht eine offene Notiz';
  @override
  String get commandNeedTextNote => 'Braucht eine offene Textnotiz';
  @override
  String get commandNeedWideWindow => 'Nur in breiten Fenstern';
  @override
  String get commandNeedDockRoom =>
      'Braucht ein Fenster, das breit genug für die Seitenleiste ist';
  @override
  String get commandNeedDesktop => 'Nur auf dem Desktop';
  @override
  String get commandNeedNotInZen => 'Nicht im Zen-Modus';
  @override
  String get commandNeedZenRoom => 'Desktop, mit einer Notiz in einem Tab';
  @override
  String get commandNeedPreview =>
      'Mit aktivierter Vorschau, bei einer Textnotiz';
  @override
  String get commandNeedTwoEditors => 'Wenn beide Editoren aktiviert sind';
  @override
  String get paletteHint => 'Befehle und Notizen suchen';
  @override
  String get paletteNoResults => 'Keine Treffer';
  @override
  String get paletteCommands => 'Befehle';
  @override
  String get paletteNotes => 'Notizen';
  @override
  String get paletteFooter =>
      '↑↓ zum Bewegen · ↵ zum Ausführen · Esc zum Schließen';
  @override
  String get paletteFooterTouch =>
      'Tippen zum Ausführen · die Nadel hält es oben';
  @override
  String get palettePinned => 'Angepinnt';
  @override
  String get palettePin => 'Anpinnen';
  @override
  String get paletteUnpin => 'Lösen';
  @override
  String get palettePinFooter => 'alt+P zum Anpinnen';
  @override
  String get spellCheckScanning => 'Notiz wird geprüft…';
  @override
  String get spellCheckAgain => 'Erneut prüfen';
  @override
  String spellCheckCapped(int count) =>
      'Die ersten $count werden angezeigt: einige korrigieren, dann für den '
      'Rest erneut prüfen';
  @override
  String get dropHint =>
      'Markdown-Dateien ablegen, um sie zu öffnen, oder einen Ordner, um ihn '
      'zu importieren';
  @override
  String get dropNothing =>
      'Der Desktop hat für dieses Ablegen keine Dateien übergeben.';
  @override
  String get importFolderAction => 'Importieren';
  @override
  String dropRejected(String names) =>
      'Hier öffnen sich nur Markdown-Dateien und Ordner: $names';
  @override
  String importFolderTitle(String name) => '„$name“ importieren?';
  @override
  String importFolderBody(int count) =>
      'Seine Markdown-Dateien ($count) werden in einen neuen Ordner der '
      'Bibliothek kopiert. Der abgelegte Ordner bleibt, wie er ist.';
  @override
  String importFolderDone(String folder) => 'Importiert nach $folder';
  @override
  String importFolderEmpty(String name) => 'Keine Markdown-Dateien in $name';
  @override
  String get openFileTitle => 'Datei öffnen';
  @override
  String get outsideFileNote =>
      'Außerhalb jeder Bibliothek: dort gespeichert, wo sie liegt, nicht '
      'indiziert, ohne Verlauf, Links werden nicht verfolgt';
  @override
  String get typewriterOn => 'Schreibmaschinenmodus einschalten';
  @override
  String get typewriterOff => 'Schreibmaschinenmodus ausschalten';
  @override
  String get typewriterTitle => 'Schreibmaschinenmodus';
  @override
  String get formatNoteTitle => 'Markdown aufräumen';
  @override
  String get formatNoteDone => 'Die Notiz wurde aufgeräumt.';
  @override
  String get formatNoteAlreadyTidy => 'Die Notiz war schon aufgeräumt.';
  @override
  String get lintRulesTitle => 'Markdown-Regeln';
  @override
  String get lintRulesSubtitle =>
      'Was das Aufräumen regelt: Leerzeilen in Listen, Aufgabenkästchen, '
      'Abstände nach dem Marker und Codeblöcke.';
  @override
  String get lintRulesReset => 'Auf Standard zurücksetzen';
  @override
  String lintRulesValue(int on, int all) =>
      on >= all ? 'Alle $all' : '$on von $all';
  @override
  String get lintRuleTightLists => 'Enge Listen';
  @override
  String get lintRuleTaskMarker => 'Aufgabenkästchen';
  @override
  String get lintRuleListSpacing => 'Listenabstände';
  @override
  String get lintRuleClosingFence => 'Schließender Zaun';
  @override
  String get lintRuleFenceLanguage => 'Zaunsprache';
  @override
  String get tidyOnCloseTitle => 'Markdown beim Schließen aufräumen';
  @override
  String get tidyOnCloseSubtitle =>
      'Wenn Sie eine bearbeitete Notiz schließen, wird ihr Markdown '
      'aufgeräumt wie mit dem Befehl „Markdown aufräumen“. Notizen über '
      '4 MB bleiben, wie sie sind.';
  @override
  String get typewriterSubtitle =>
      'Die Zeile, in der Sie schreiben, bleibt in der Mitte des Editors';
  @override
  String get zenMode => 'Zen-Modus';
  @override
  String get zenModeEnter => 'Zen-Modus starten';
  @override
  String get zenModeLeave => 'Zen-Modus verlassen';
  @override
  String get keySpace => 'Leertaste';
  @override
  String get keyEnter => 'Eingabe';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Rücktaste';
  @override
  String get keyDelete => 'Entf';
  @override
  String get keyArrowUp => 'Nach oben';
  @override
  String get keyArrowDown => 'Nach unten';
  @override
  String get keyArrowLeft => 'Nach links';
  @override
  String get keyArrowRight => 'Nach rechts';
  @override
  String get keyHome => 'Pos1';
  @override
  String get keyEnd => 'Ende';
  @override
  String get keyPageUp => 'Bild auf';
  @override
  String get keyPageDown => 'Bild ab';
  @override
  String get keyInsert => 'Einfg';
  @override
  String get shortcutNone => 'Kein Kürzel';
  @override
  String get shortcutRestoreDefaults => 'Standard wiederherstellen';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Alle Kürzel so zurücksetzen, wie Niman sie ausliefert?';
  @override
  String get shortcutRevert => 'Zurück zum Standard';
  @override
  String get shortcutClear => 'Kürzel entfernen';
  @override
  String get shortcutCapturePrompt =>
      'Drücken Sie die Tasten. Auch Esc und Tab werden aufgenommen: '
      'Abbrechen führt hinaus.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Fügen Sie Strg, Alt oder Meta hinzu: eine Taste allein ist zum '
      'Schreiben da.';
  @override
  String get shortcutMove => 'Verschieben';
  @override
  String get shortcutUseAnyway => 'Trotzdem verwenden';
  @override
  String get shortcutUndo => 'Rückgängig';
  @override
  String get shortcutRedo => 'Wiederholen';
  @override
  String get shortcutChange => 'Kürzel ändern';
  @override
  String shortcutCaptureTitle(String command) => 'Tasten für $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys gehört schon zu $other. Hierher verschieben? $other hat dann '
      'kein Kürzel.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys ist in Textfeldern und im Editor auch $what. Dort übernimmt Ihr '
      'Befehl sie.';
  @override
  String get openFileMissing =>
      'Die Datei dieser Notiz liegt nicht auf dem Datenträger';
  @override
  String get openFileFailed =>
      'Diese Notiz konnte außerhalb von Niman nicht geöffnet werden';
  @override
  String get attachmentUnreadable =>
      'Diese Datei konnte nicht angezeigt werden.';
  @override
  String get attachmentMissing =>
      'Diese Datei liegt nicht auf dem Datenträger.';
  @override
  String get attachmentOpenFailed =>
      'Diese Datei konnte außerhalb von Niman nicht geöffnet werden.';
  @override
  String get copyPlaceLink => 'Link zu dieser Stelle kopieren';
  @override
  String get placeLinkCopied => 'Link kopiert';
  @override
  String pdfPageLabel(String name, int page) => '$name, S. $page';
  @override
  String get annotationsFolderTitle => 'Ordner für Anmerkungen';
  @override
  String get annotationsFolderSubtitle =>
      'Notizen, die ein PDF oder Buch annotieren';
  @override
  String get annotationNoteSuffix => 'Anmerkung';
  @override
  String get annotateAction => 'Anmerken';
  @override
  String get annotationCommentHint => 'Dein Kommentar';
  @override
  String get annotationSaved => 'Anmerkung gespeichert';
  @override
  String get annotationOpenNote => 'Notiz öffnen';
  @override
  String get annotationFailed =>
      'Die Anmerkung konnte nicht gespeichert werden';

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
  @override
  String get attachmentsFolderTitle => 'Anhänge-Ordner';

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

  @override
  String get libraryForgetOpenExplained =>
      'Diese Bibliothek ist gerade geöffnet: Sie wird zuerst geschlossen '
      'und verschwindet dann aus der Liste. Der Ordner, die Notizen und die '
      'Bibliothekseinstellungen darin bleiben unangetastet, und ein '
      'erneutes Öffnen bringt sie zurück.';

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

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Info';
  @override
  String get versionTitle => 'Version';
  @override
  String get changelogTitle => 'Änderungsprotokoll';
  @override
  String get changelogEmpty => 'Keine Einträge im Änderungsprotokoll';
  @override
  String changelogWhatsNew(String version) => 'Neu in Version $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Verlauf';
  @override
  String get noteMenuTooltip => 'Notizaktionen';
  @override
  String get historyCurrentVersion => 'Aktuelle Version';
  @override
  String get historyCurrentSubtitle => 'Die Notiz in ihrem jetzigen Stand';
  @override
  String get historyToday => 'Heute';
  @override
  String get historyYesterday => 'Gestern';
  @override
  String get historyReasonSession => 'vor dem Bearbeiten';
  @override
  String get historyReasonInterval => 'beim Bearbeiten';
  @override
  String get historyReasonRestore => 'vor dem Wiederherstellen';
  @override
  String get historyReasonSync => 'vor dem Synchronisieren';
  @override
  String get historyReasonReplace => 'vor dem Ersetzen';
  @override
  String get historyReasonUnknown => 'wiedergefunden';
  @override
  String get historySyncBase => 'Sync-Basis';
  @override
  String get historyEmpty =>
      'Noch keine Versionen. Niman legt eine an, wenn du mit dem Bearbeiten '
      'der Notiz beginnst, und danach höchstens alle paar Minuten eine, '
      'während du schreibst.';
  @override
  String historyKept(int kept, int limit) => '$kept von $limit Versionen';
  @override
  String get historyBaseKept =>
      'Die Sync-Basis bleibt auch über das Limit hinaus erhalten.';
  @override
  String get historyOff =>
      'Der Verlauf ist für diese Bibliothek ausgeschaltet '
      '(Einstellungen, Bibliothek).';
  @override
  String get historyLoadFailed => 'Verlauf konnte nicht gelesen werden';
  @override
  String get historyCompareSubtitle => 'Verglichen mit der aktuellen Version';
  @override
  String get historyTabChanges => 'Änderungen';
  @override
  String get historyTabVersion => 'Version';
  @override
  String get historyNoChanges => 'Gleicher Text wie die aktuelle Version.';
  @override
  String get historyRestoreAction => 'Diese Version wiederherstellen';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Version von $when wiederherstellen?';
  @override
  String get historyRestoreConfirmBody =>
      'Der aktuelle Text wird vorher im Verlauf gesichert, du kannst also '
      'jederzeit zurück.';
  @override
  String get historyRestoreConfirm => 'Wiederherstellen';
  @override
  String historyRestored(String when) => 'Version von $when wiederhergestellt';
  @override
  String get historyRestoreFailed =>
      'Version konnte nicht wiederhergestellt werden';
  @override
  String get actionUndo => 'Rückgängig';
  @override
  String diffLineRange(int start, int end) => 'Zeilen $start–$end';
  @override
  String diffLineSingle(int line) => 'Zeile $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 unveränderte Zeile' : '$count unveränderte Zeilen';
  @override
  String get historyTakeHunk => 'Hier wiederherstellen';
  @override
  String historyRestoreSelectedAction(int count) => count == 1
      ? '1 Änderung wiederherstellen'
      : '$count Änderungen wiederherstellen';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Die gewählten Änderungen kehren zum Text dieser Version zurück. Die '
      'Notiz in ihrem jetzigen Stand wird zuvor als Version behalten, du '
      'kannst das also rückgängig machen.';
  @override
  String get historyNoteChangedReloaded =>
      'Die Notiz hat sich geändert, während du hier warst — der Vergleich '
      'wurde aktualisiert.';
  @override
  String get historyVersionsTitle => 'Aufbewahrte Versionen';
  @override
  String get historyVersionsSubtitle => 'Pro Notiz, in .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Keine' : '$count';
  @override
  String get historyIntervalTitle => 'Neue Version höchstens alle';
  @override
  String get historyIntervalSubtitle =>
      'Beim Schreiben; zu Beginn einer Bearbeitung entsteht immer eine';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transkription';
  @override
  String get transcriptionModelTitle => 'Modell';
  @override
  String get transcriptionModelNone => 'Keins';
  @override
  String get transcriptionLanguageTitle => 'Sprache';
  @override
  String get transcriptionLanguageSubtitle =>
      'Die Sprache in deinen Aufnahmen. Sie anzugeben ist genauer, als sie '
      'erkennen zu lassen.';
  @override
  String transcriptionLanguageApp(String language) => 'Wie die App ($language)';
  @override
  String get transcriptionLanguageDetect => 'Automatisch erkennen';
  @override
  String get transcriptionModelsTitle => 'Transkriptionsmodelle';
  @override
  String transcriptionModelsUsed(String size) => '$size belegt';
  @override
  String get transcriptionModelsInstalled => 'Heruntergeladen';
  @override
  String get transcriptionModelsDownloading => 'Wird heruntergeladen';
  @override
  String get transcriptionModelsAvailable => 'Verfügbar';
  @override
  String get transcriptionModelsFooter =>
      'Modelle bleiben im Speicher der App auf diesem Gerät. Sie werden weder '
      'in die Bibliothek kopiert noch synchronisiert.';
  @override
  String get transcriptionModelDefault => 'Standard';
  @override
  String get transcriptionModelSlow => 'Langsam';
  @override
  String get transcriptionModelHintTiny => 'Am schnellsten, am ungenauesten';
  @override
  String get transcriptionModelHintBase =>
      'Gute Balance aus Tempo und Genauigkeit';
  @override
  String get transcriptionModelHintSmall => 'Genauer, etwa 3× langsamer';
  @override
  String get transcriptionModelHintMedium =>
      'Sehr genau, langsam auf dem Handy';
  @override
  String get transcriptionModelHintLarge =>
      'Am genauesten, braucht viel Arbeitsspeicher';
  @override
  String get transcriptionModelDownload => 'Herunterladen';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Modell $model löschen?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Das gibt $size frei. Du kannst das Modell später erneut herunterladen.';
  @override
  String get transcriptionModelFailed =>
      'Download fehlgeschlagen. Prüfe die Verbindung und versuche es erneut.';
  @override
  String get actionRetry => 'Erneut versuchen';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Verbindung unterbrochen, neuer Versuch…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Pausiert bei $progress';
  @override
  String get actionResume => 'Fortsetzen';
  @override
  String get audioTranscribe => 'Transkribieren';
  @override
  String get audioTranscribeUnsupported => 'Auf diesem Gerät nur WAV-Aufnahmen';
  @override
  String get transcriptionQueued => 'In der Warteschlange';
  @override
  String get transcriptionPreparing => 'Audio wird vorbereitet…';
  @override
  String transcriptionRunning(int percent) => 'Transkription… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model wird geladen · $percent %';
  @override
  String get transcriptionSaved => 'Transkription zur Beschreibung hinzugefügt';
  @override
  String get transcriptionNoSpeech =>
      'In dieser Aufnahme wurde keine Sprache erkannt';
  @override
  String get transcriptionFailed => 'Transkription fehlgeschlagen';
  @override
  String get transcriptionPickModelTitle => 'Modell auswählen';
  @override
  String get transcriptionPickModelBody =>
      'Die Transkription läuft auf diesem Gerät, die Aufnahme wird nie '
      'hochgeladen. Das Modell wird nur einmal heruntergeladen.';
  @override
  String get transcriptionPickModelAction => 'Herunterladen und transkribieren';
  @override
  String get transcriptionModelRecommended => 'Empfohlen';
  @override
  String get transcriptionExistingTitle =>
      'Diese Aufnahme hat schon eine Beschreibung';
  @override
  String get transcriptionExistingBody =>
      'Durch die Transkription ersetzen oder die Transkription darunter '
      'anfügen?';
  @override
  String get transcriptionAppend => 'Darunter anfügen';
  @override
  String get transcriptionReplace => 'Ersetzen';
  @override
  String get settingsSectionSync => 'Synchronisierung';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Für diese Bibliothek nicht eingerichtet';
  @override
  String get syncNeverSynced => 'Noch nie synchronisiert';
  @override
  String syncLastSynced(String when) => 'Synchronisiert $when';
  @override
  String get syncRunning => 'Wird synchronisiert…';
  @override
  String syncScreenSubtitle(String library) => 'Bibliothek $library';
  @override
  String get syncUrlLabel => 'Ordneradresse';
  @override
  String get syncUrlRequired => 'Serveradresse eingeben';
  @override
  String get syncUrlHint =>
      'Der Ordner muss existieren. Kopiere die Adresse so, wie '
      'der Server sie anzeigt.';
  @override
  String get syncHttpWarning =>
      'Unverschlüsselte Verbindung: in Ordnung über VPN oder im '
      'lokalen Netzwerk.';
  @override
  String get syncUserLabel => 'Benutzer';
  @override
  String get syncUserHint =>
      'Leer lassen, wenn der Server keine Zugangsdaten verlangt.';
  @override
  String get syncPasswordLabel => 'Passwort';
  @override
  String get syncPasswordHint =>
      'Liegt im Schlüsselbund dieses Geräts, nie in den Dateien '
      'der Bibliothek.';
  @override
  String get syncPasswordKeepHint =>
      'Leer lassen, um das gespeicherte Passwort zu behalten.';
  @override
  String get syncShowPassword => 'Passwort anzeigen';
  @override
  String get syncHidePassword => 'Passwort verbergen';
  @override
  String get syncTestAction => 'Verbindung testen';
  @override
  String get syncTesting => 'Wird getestet…';
  @override
  String get syncRetargetWarning =>
      'Mit einer neuen Adresse oder einem neuen Benutzer beginnt '
      'die nächste Synchronisierung wieder als erste.';
  @override
  String get syncTestOk => 'Verbindung funktioniert';
  @override
  String get syncModeFull => 'Voller Modus';
  @override
  String get syncModeCompatible => 'Kompatibler Modus';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lesen, Schreiben und Löschen';
  @override
  String get syncCapEtags => 'Datei-Fingerabdrücke (ETags)';
  @override
  String get syncCapNoEtags => 'Keine Datei-Fingerabdrücke (ETags)';
  @override
  String get syncCapNoEtagsDetail =>
      'Vergleicht Größe und Datum; lädt im Zweifel neu herunter';
  @override
  String get syncCapGuarded => 'Geschützte Schreibvorgänge';
  @override
  String get syncCapUnguarded => 'Ungeschützte Schreibvorgänge';
  @override
  String get syncCapUnguardedDetail =>
      'Prüft die Datei auf dem Server direkt vor dem Schreiben';
  @override
  String get syncCapMove => 'Umbenennen ohne erneutes Hochladen';
  @override
  String get syncCapNoMove => 'Kein Umbenennen auf dem Server';
  @override
  String get syncCapNoMoveDetail =>
      'Eine Umbenennung wird zu Löschen und neuem Hochladen';
  @override
  String get syncCompatibleNote =>
      'Im kompatiblen Modus funktioniert die Synchronisierung '
      'genauso, nur mit ein paar Anfragen mehr.';
  @override
  String get syncTestInvalidUrl => 'Keine gültige Adresse';
  @override
  String get syncTestInvalidUrlHint =>
      'Gib eine Adresse mit http:// oder https:// ein, ohne '
      'Benutzer oder Passwort darin.';
  @override
  String get syncTestOffline => 'Server nicht erreichbar';
  @override
  String get syncTestOfflineHint =>
      'Ist das VPN an? Eine Adresse 10.x oder 192.168.x '
      'funktioniert nur aus demselben Netzwerk.';
  @override
  String get syncTestAuth => 'Benutzer oder Passwort abgelehnt';
  @override
  String get syncTestAuthHint => 'Prüfe beides und teste erneut.';
  @override
  String get syncTestNotFound => 'Der Ordner existiert nicht';
  @override
  String get syncTestNotFoundHint =>
      'Lege ihn auf dem Server an oder korrigiere die Adresse.';
  @override
  String get syncTestUnsupported => 'Kein WebDAV-Ordner';
  @override
  String get syncTestUnsupportedHint =>
      'Der Server antwortet, aber nicht als WebDAV.';
  @override
  String get syncTestFailed => 'Der Test hat nicht funktioniert';
  @override
  String get syncNowAction => 'Jetzt synchronisieren';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Adresse, Benutzer und Passwort';
  @override
  String get syncRetestTitle => 'Server erneut testen';
  @override
  String syncProbedAgo(String when) => 'Letzter Test: $when';
  @override
  String get syncDisconnectTitle => 'Diese Bibliothek trennen';
  @override
  String get syncDisconnectSubtitle =>
      'Die Dateien bleiben hier und auf dem Server';
  @override
  String get syncDisconnectConfirmTitle => 'Synchronisierung trennen?';
  @override
  String get syncDisconnectConfirmBody =>
      'Diese Bibliothek wird auf diesem Gerät nicht mehr '
      'synchronisiert. Es wird keine Datei gelöscht, weder hier '
      'noch auf dem Server. Wenn du sie wieder verbindest, '
      'beginnt die erste Synchronisierung von vorn.';
  @override
  String get syncDisconnectConfirm => 'Trennen';
  @override
  String get syncFirstTitle => 'Erste Synchronisierung';
  @override
  String get syncFirstIntro =>
      'Ich habe die Bibliothek mit dem Ordner auf dem Server '
      'verglichen:';
  @override
  String get syncFirstUpload => 'Hochzuladen';
  @override
  String get syncFirstDownload => 'Herunterzuladen';
  @override
  String get syncFirstBoth => 'Auf beiden Seiten';
  @override
  String get syncFirstBothHint =>
      'Gleich: keine Übertragung. Verschieden: zu klären';
  @override
  String get syncFirstNoDelete =>
      'Die erste Synchronisierung löscht nichts, weder hier noch '
      'auf dem Server.';
  @override
  String get syncStartAction => 'Starten';
  @override
  String syncMassTrashTitle(int count) =>
      '$count Dateien in den Papierkorb verschieben?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count der $total synchronisierten Dateien fehlen auf dem '
      'Server. Meist steckt eine falsche Adresse, eine nicht '
      'eingebundene NAS-Festplatte oder ein versehentlich '
      'geleerter Ordner dahinter.';
  @override
  String get syncMassTrashHint =>
      'Wenn du sie wirklich auf einem anderen Gerät gelöscht '
      'hast, bestätige: Hier landen sie im Papierkorb.';
  @override
  String get syncMassTrashConfirm => 'In den Papierkorb';
  @override
  String syncMassDeleteTitle(int count) => '$count Dateien vom Server löschen?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count der $total synchronisierten Dateien fehlen hier. '
      'Wenn du sie nicht gelöscht hast, brich ab und prüfe den '
      'Bibliotheks-Ordner.';
  @override
  String get syncMassDeleteConfirm => 'Vom Server löschen';
  @override
  String get syncTooltip => 'Synchronisieren';
  @override
  String get syncStageConnecting => 'Verbindung zum Server…';
  @override
  String get syncStageComparing => 'Vergleich mit dem Server…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synchronisierung · $done von $total';
  @override
  String get syncStatusWarnings => 'Mit Warnungen synchronisiert';
  @override
  String syncConflictsHeader(int count) =>
      'Hier und auf dem Server geändert · $count';
  @override
  String get syncConflictHint => 'Keine der beiden Versionen wurde angetastet';
  @override
  String get syncResolveAction => 'Lösen';
  @override
  String syncFailuresHeader(int count) => 'Nicht synchronisiert · $count';
  @override
  String get syncFailuresHint =>
      'Neuer Versuch bei der nächsten Synchronisierung';
  @override
  String get syncAbortAuth => 'Passwort vom Server abgelehnt';
  @override
  String get syncAbortMissingPassword => 'Kein Passwort gespeichert';
  @override
  String get syncAbortOffline => 'Server nicht erreichbar';
  @override
  String get syncAbortRemoteMissing => 'Der Ordner auf dem Server ist weg';
  @override
  String get syncAbortUnsupported =>
      'Der Server arbeitet nicht mehr als WebDAV';
  @override
  String get syncAbortFailed => 'Synchronisierung hat nicht funktioniert';
  @override
  String get syncAbortNotConfirmed => 'Synchronisierung abgebrochen';
  @override
  String get syncAbortNothingTouched =>
      'Keine Datei wurde angetastet. Deine Änderungen bleiben '
      'hier bis zur nächsten erfolgreichen Synchronisierung.';
  @override
  String syncLastSuccess(String when) =>
      'Letzte erfolgreiche Synchronisierung: $when';
  @override
  String get syncNoSuccessYet => 'Noch keine erfolgreiche Synchronisierung';
  @override
  String get syncUpdatePasswordAction => 'Passwort aktualisieren';
  @override
  String get syncRetryAction => 'Erneut versuchen';
  @override
  String get syncOpenSettingsAction => 'Einstellungen';
  @override
  String get syncCloseAction => 'Schließen';
  @override
  String get syncDoneSnack => 'Synchronisiert';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synchronisiert · 1 anderswo gelöschte Datei liegt im '
            'Papierkorb'
      : 'Synchronisiert · $count anderswo gelöschte Dateien liegen '
            'im Papierkorb';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synchronisiert · 1 Konflikt zu lösen'
      : 'Synchronisiert · $count Konflikte zu lösen';
  @override
  String get syncShowAction => 'Anzeigen';
  @override
  String get syncConflictTitle => 'Konflikt lösen';
  @override
  String get syncConflictBinary =>
      'Keine Textdatei: Wähle, welche Kopie du behältst.';
  @override
  String get syncConflictKeepNote =>
      'Die Kopie, die du nicht behältst, bleibt im Verlauf der '
      'Notiz.';
  @override
  String get syncKeepLocal => 'Version dieses Geräts behalten';
  @override
  String get syncKeepRemote => 'Version des Servers behalten';
  @override
  String get syncConflictLoadFailed =>
      'Die beiden Versionen konnten nicht gelesen werden';
  @override
  String get syncResolveFailed => 'Konflikt konnte nicht gelöst werden';
  @override
  String get syncResolved => 'Konflikt gelöst';
  @override
  String get syncConflictMoved =>
      'Eine Seite hat sich inzwischen geändert; der Konflikt wurde neu '
      'gelesen. Bitte erneut wählen.';
  @override
  String get syncSectionWhen => 'Wann synchronisiert wird';
  @override
  String get syncAutoTitle => 'Automatisch';
  @override
  String get syncAutoSubtitle =>
      'Nach Änderungen, beim Öffnen und in Abständen';
  @override
  String get syncIntervalTitle => 'Intervall für Serverabfrage';
  @override
  String get syncIntervalSubtitle => 'Nur solange die App geöffnet ist';
  @override
  String get syncIntervalDialogBody =>
      'Um Änderungen von anderen Geräten zu sehen, während die App geöffnet '
      'ist. Mit „Nie“ nur nach Änderungen und beim Öffnen.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 Minute' : '$count Minuten';
  @override
  String get syncIntervalNever => 'Nie';
  @override
  String get syncWifiOnlyTitle => 'Nur mit WLAN';
  @override
  String get syncWifiOnlySubtitle =>
      'Mit mobilen Daten nur von Hand synchronisieren';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 Änderung wartet' : '$count Änderungen warten';
  @override
  String syncRetryIn(String wait) => 'neuer Versuch in $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Warten auf WLAN';
  @override
  String get syncWaitingForNetwork => 'Warten auf Verbindung';
  @override
  String get syncMobileDataHint =>
      '„Jetzt synchronisieren“ nutzt trotzdem mobile Daten.';
  @override
  String get syncQueueKeptHint =>
      'Änderungen bleiben hier, auch wenn du die App schließt, und werden von '
      'selbst übertragen, sobald der Server antwortet.';
  @override
  String get syncAutoPaused => 'Automatische Synchronisierung pausiert';
  @override
  String get syncPausedAuthHint =>
      'Sie läuft weiter, wenn du das Passwort aktualisierst oder von Hand '
      'synchronisierst.';
  @override
  String get syncPausedServerHint =>
      'Sie läuft weiter, wenn du die Adresse korrigierst oder von Hand '
      'synchronisierst.';
  @override
  String get syncPausedConfirmHint =>
      '„Jetzt synchronisieren“ zeigt, was entfernt würde, und fragt vorher '
      'nach.';
  @override
  String get syncNeedsConfirmation => 'Wartet auf deine Bestätigung';
  @override
  String get syncMergeIntro =>
      'Änderungen, die sich nicht überschneiden, sind schon zusammengeführt; '
      'wähle bei Überschneidungen, was bleibt.';
  @override
  String get syncMergeClean =>
      'Die beiden Versionen lassen sich von selbst zusammenführen: nichts '
      'überschneidet sich.';
  @override
  String get syncMergeNoBase =>
      'Es gibt keine gemeinsame Version zum Zusammenführen: An jeder Stelle, '
      'an der sich die Kopien unterscheiden, wählst du.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Überschneidung $index von $total';
  @override
  String get syncMergeFromLocal => 'Von diesem Gerät';
  @override
  String get syncMergeFromRemote => 'Vom Server';
  @override
  String get syncMergeRemovedLines => 'Entfernte Zeilen';
  @override
  String get syncMergeAbsentLines => 'Nicht in dieser Kopie';
  @override
  String get syncMergeKeepLocal => 'Meine';
  @override
  String get syncMergeKeepRemote => 'Vom Server';
  @override
  String get syncMergeKeepBoth => 'Beide';
  @override
  String get syncMergeSave => 'Zusammenführung speichern';
  @override
  String get syncMergeKeepWhole => 'Oder eine ganze Kopie behalten';
}
