// The Greek strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class GreekStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'Ιανουάριος',
    'Φεβρουάριος',
    'Μάρτιος',
    'Απρίλιος',
    'Μάιος',
    'Ιούνιος',
    'Ιούλιος',
    'Αύγουστος',
    'Σεπτέμβριος',
    'Οκτώβριος',
    'Νοέμβριος',
    'Δεκέμβριος',
  ];
  @override
  List<String> get monthNamesShort => const [
    'Ιαν',
    'Φεβ',
    'Μαρ',
    'Απρ',
    'Μαΐ',
    'Ιούν',
    'Ιούλ',
    'Αυγ',
    'Σεπ',
    'Οκτ',
    'Νοε',
    'Δεκ',
  ];
  @override
  List<String> get weekdayNames => const [
    'Δευτέρα',
    'Τρίτη',
    'Τετάρτη',
    'Πέμπτη',
    'Παρασκευή',
    'Σάββατο',
    'Κυριακή',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'Δευ',
    'Τρι',
    'Τετ',
    'Πεμ',
    'Παρ',
    'Σαβ',
    'Κυρ',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Σκουπιδιέρα';
  @override
  String get trashSubtitle =>
      'Τα διαγραμμένα στοιχεία πάνε στο .trash/ (ανενεργό = μόνιμη '
      'διαγραφή)';
  @override
  String get trashAutoEmptyTitle => 'Αυτόματη εκκένωση σκουπιδιέρας';
  @override
  String get trashAutoEmptySubtitle =>
      'Οι παλαιότερες διαγραφές χάνονται οριστικά μόλις ανοίξει η βιβλιοθήκη';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Ποτέ'
      : days == 1
      ? '1 ημέρα'
      : '$days ημέρες';
  @override
  String get debugLogsTitle => 'Καταγραφές αποσφαλμάτωσης';
  @override
  String get debugLogsSubtitle =>
      'Καταγράφει συμβάντα της εφαρμογής σε απομνημονευτήρα';
  @override
  String get lineNumbersTitle => 'Αριθμοί γραμμών';
  @override
  String get lineNumbersSubtitle =>
      'Εμφανίζει τη στήλη με τους αριθμούς γραμμών στον επεξεργαστή';
  @override
  String get readableLineLengthTitle => 'Ευανάγνωστο μήκος γραμμής';
  @override
  String get readableLineLengthSubtitle =>
      'Το κείμενο της σημείωσης μένει σε κεντραρισμένη στήλη αντί για όλο το '
      'πλάτος του παραθύρου';
  @override
  String get noteColumnWidthTitle => 'Πλάτος στήλης';
  @override
  String get noteColumnWidthSubtitle =>
      'Πόσο φαρδιά είναι η στήλη της σημείωσης, σε pixel';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Πληκτρολόγιο στο άνοιγμα';
  @override
  String get keyboardOnOpenSubtitle =>
      'Εμφανίζει το πληκτρολόγιο μόλις ανοίξει η σημείωση '
      '(ανενεργό = στην πρώτη άγγιση)';
  @override
  String get editorKindSource => 'Πηγή Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Πηγή Markdown, όπως γράφτηκε';
  @override
  String get editorKindWysiwygSubtitle =>
      'Μορφοποιημένο κείμενο, επεξεργασία επιτόπου';
  @override
  String get settingsFolderToCreate => 'για δημιουργία';
  @override
  String get settingsSearchHint => 'Αναζήτηση ρυθμίσεων';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 ρύθμιση βρέθηκε' : '$count ρυθμίσεις βρέθηκαν';
  @override
  String get settingsToggleOn => 'Ενεργό';
  @override
  String get settingsToggleOff => 'Ανενεργό';
  @override
  String get settingsPreviewEnabledTitle => 'Προεπισκόπηση';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Εμφανίζει τη μορφοποιημένη σημείωση δίπλα στον επεξεργαστή '
      'πηγής';
  @override
  String get switchToWysiwygTooltip => 'Μετάβαση στον επεξεργαστή WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Μετάβαση στην πηγή Markdown';
  @override
  String get switchToSourceLabel => 'Πηγή';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Αυτή η σημείωση είναι πολύ μεγάλη για τον επεξεργαστή WYSIWYG. '
      'Ανοίξτε την στην πηγή Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Εμφάνιση';
  @override
  String get settingsSectionEditor => 'Επεξεργαστής';
  @override
  String get settingsSectionLibrary => 'Βιβλιοθήκη';
  @override
  String get settingsSectionReminders => 'Υπενθυμίσεις';
  @override
  String get settingsSectionShortcuts => 'Πληκτρολόγιο';
  @override
  String get keyboardShortcutsTitle => 'Συντόμευση πληκτρολογίου';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Βιβλιοθήκη $name';
  @override
  String get settingsGroupLibraryHint => 'ισχύει μόνο για αυτή τη βιβλιοθήκη';
  @override
  String get settingsGroupMaintenance => 'Συντήρηση';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Φάκελοι και διαδρομές';
  @override
  String get settingsAreaTrashHistory => 'Σκουπιδιέρα και χρονολόγιο';
  @override
  String get settingsAreaDiagnostics => 'Διάγνωση και πληροφορίες';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Χρειέται συνδεδεμένο φυσικό πληκτρολόγιο';
  @override
  String get settingsSectionUpdates => 'Ενημερώσεις';
  @override
  String get autoUpdateTitle => 'Αυτόματες ενημερώσεις';
  @override
  String get autoUpdateSubtitle =>
      'Έλεγχος στο GitHub Releases κατά την εκκίνηση και κάθε 6 ώρες';
  @override
  String get checkForUpdatesTitle => 'Έλεγχος για ενημερώσεις';
  @override
  String updateAvailableMessage(Object version) =>
      'Το Niman $version είναι διαθέσιμο';
  @override
  String get updateUpToDate => 'Το Niman είναι ενημερωμένο';
  @override
  String get updateCheckFailed => 'Ο έλεγχος ενημερώσεων απέτυχε';
  @override
  String updateSavedTo(Object path) => 'Η ενημέρωση αποθηκεύτηκε στο $path';
  @override
  String get updateInstallerStarted => 'Το πρόγραμμα εγκατάστασης ξεκίνησε';
  @override
  String get settingsSectionDiagnostics => 'Διάγνωση';
  @override
  String get settingsSpellCheckTitle => 'Έλεγχος ορθογραφίας';
  @override
  String get settingsSpellCheckSubtitle =>
      'Υπογραμμίζει λέξεις που γράφτηκαν λάθος καθώς γράφετε.';
  @override
  String get spellCheckDictionaryTitle => 'Λεξικό';
  @override
  String get spellCheckDictionarySystem => 'Σύστημα προεπιλογής';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Επιλέξτε λεξικά';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Επιλέξτε κάθε γλώσσα στα οποία έχει γραφεί αυτή η βιβλιοθήκη. '
      'Η λέξη περνάει όταν ο ένας από τα επιλεγμένα λεξικά τη '
      'αναγνωρίζει. Αν δεν υπάρχουν επιλεγμένα, το σύστημα '
      'αποφασίζει.';
  @override
  String get spellCheckNoDictionaries =>
      'Δεν βρέθηκαν λεξικά σε αυτό το σύστημα.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Έλεγχος ορθογραφίας';
  @override
  String get spellCheckTitle => 'Ορθογραφία';
  @override
  String get spellCheckEmpty => 'Δεν υπάρχουν ορθογραφικά λάθη.';
  @override
  String get spellCheckUnavailable =>
      'Το hunspell δεν είναι εγκατεστημένο σε αυτό το σύστημα.';
  @override
  String get spellCheckNoSuggestions => 'Δεν υπάρχουν προτάσεις';
  @override
  String spellCheckCount(int count) => '$count προς επιθεώρηση';
  @override
  String spellCheckLine(int line) => 'γραμμή $line';
  @override
  String get addWordToDictionary => 'Προσθήκη στο λεξικό';

  @override
  String indentWidthValue(int spaces) => '$spaces κενά';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Φωτεινότητα';
  @override
  String get themeBrightnessSubtitle =>
      'Φωτεινό, σκούρο ή όπως έχει ορισθεί η συσκευή';
  @override
  String get themeBrightnessSystem => 'Σύστημα';
  @override
  String get themeBrightnessDay => 'Φωτεινό';
  @override
  String get themeBrightnessNight => 'Σκούρο';
  @override
  String get themePaletteTitle => 'Παλέτα';
  @override
  String get themePaletteSubtitle => 'Χρώματα της διεπαφής και της σημείωσης';
  @override
  String get themePaletteSystem => 'Σύστημα';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Μέγεθος κείμενου διεπαφής';
  @override
  String get uiTextScaleSubtitle =>
      'Δέντρο, κάρτες και διαλόγοι. Πάνω από το ρύθμιση συστήματος';
  @override
  String get noteTextScaleTitle => 'Μέγεθος κείμενου σημείωσης';
  @override
  String get noteTextScaleSubtitle =>
      'Επεξεργαστής και προεπισκόπηση, πάντα συγχρονισμένοι';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Λειτουργία προεπισκόπησης';
  @override
  String get previewModeSubtitle =>
      'Αν η προεπισκόπηση μοιράζεται την οθόνη με τον επεξεργαστή ή '
      'την αντικαθιστά';
  @override
  String get previewModeAuto => 'Παράλληλα';
  @override
  String get previewModeSwitch => 'Πλήρης οθόνη';
  @override
  String get splitRatioTitle => 'Ρυθμός διαίρεσης';
  @override
  String get splitRatioSubtitle =>
      'Μέρος του επεξεργαστή όταν η προεπισκόπηση είναι δίπλα του';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Μορφή συνδέσμου';
  @override
  String get linkTypeSubtitle =>
      'Τι ενσωματώνει το κουμπί συνδέσμων στον επεξεργαστή';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Δημιουργία λείποντων σημειώσεων στο';
  @override
  String get missingNoteLocationRoot => 'Ρίζα βιβλιοθήκης';
  @override
  String get missingNoteLocationCurrentFolder => 'Τρέχων φάκελος';
  @override
  String get indentWidthTitle => 'Πλάτος εισαγωγής';
  @override
  String get indentWidthSubtitle =>
      'Κενά που προστίθενται ανά επίπεδο εισαγωγής στον επεξεργαστή';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Γλώσσα';
  @override
  String get languageSubtitle => 'Γλώσσα του κειμένου της ίδιας της εφαρμογής';
  @override
  String get languageSystem => 'Σύστημα';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Προσθήκη στοιχείου';
  @override
  String get listAddTooltip => 'Προσθήκη στοιχείου';
  @override
  String get listEmpty => 'Δεν υπάρχουν ακόμα στοιχεία';
  @override
  String get listDragHandleLabel => 'Επαναταξινόμηση στοιχείου';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Δεν υπάρχουν ακόμα ηχογραφήσεις';
  @override
  String get audioRecord => 'Εγγραφή';
  @override
  String get audioStop => 'Διακοπή';
  @override
  String get audioPlay => 'Αναπαραγωγή';
  @override
  String get audioDelete => 'Διαγραφή ηχογράφησης';
  @override
  String get audioImport => 'Εισαγωγή αρχείου ήχου';
  @override
  String get audioRecording => 'Ηχογράφηση…';
  @override
  String get audioPermissionDenied =>
      'Δεν δόθηκε άδεια μικροφώνου — απαιτείται για την ηχογράφηση.';
  @override
  String get newAudioNoteTitle => 'Νέα φωνητική σημείωση';
  @override
  String get newAudioNoteDefault => 'Η ηχογράφησή μου';
  @override
  String get showAudioTooltip => 'Εμφάνιση ηχογραφήσεων';
  @override
  String get audioMessageHint => 'Γράψτε μια σημείωση…';
  @override
  String get audioSend => 'Αποστολή';
  @override
  String get audioRename => 'Μετονομασία ηχογράφησης';
  @override
  String get audioDescriptionHint => 'Περιγράψτε αυτή την ηχογράφηση…';
  @override
  String get audioEditDescription => 'Επεξεργασία περιγραφής';
  @override
  String get audioDeleteNote => 'Διαγραφή σημείωσης';
  @override
  String get audioEditNote => 'Επεξεργασία σημείωσης';
  @override
  String get audioPause => 'Παύση';
  @override
  String get audioEditTitle => 'Επεξεργασία τίτλου';
  @override
  String get audioTitleHint => 'Τίτλος ηχογράφησης…';
  @override
  String audioUntitled(int n) => 'Ηχογράφηση $n';
  @override
  String get audioMoreActions => 'Περισσότερες ενέργειες';
  @override
  String get audioDiscardRecording => 'Απόρριψη ηχογράφησης';
  @override
  String get audioPauseRecording => 'Παύση ηχογράφησης';
  @override
  String get audioResumeRecording => 'Συνέχιση ηχογράφησης';
  @override
  String get audioRecordingPaused => 'Σε παύση';
  @override
  String get audioSavingRecording => 'Αποθήκευση…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Γρήγορη σημείωση';
  @override
  String get shortcutNewTodo => 'Νέο καθήκον';
  @override
  String get shortcutNewNote => 'Νέα σημείωση';
  @override
  String get shortcutNewList => 'Νέα λίστα';
  @override
  String get shortcutNewAudio => 'Νέα φωνητική σημείωση';
  @override
  String get shortcutToggleSidebar => 'Εμφάνιση ή κρύψη του δέντρου αρχείων';
  @override
  String get shortcutCloseTab => 'Κλείσιμο της τρέχουσας σημείωσης';
  @override
  String get shortcutNextTab => 'Επόμενη ανοιχτή σημείωση';
  @override
  String get shortcutPreviousTab => 'Προηγούμενη ανοιχτή σημείωση';
  @override
  String get shortcutEditorSection => 'Στον επεξεργαστή';
  @override
  String get shortcutFind => 'Εύρεση';
  @override
  String get shortcutReplace => 'Εύρεση και αντικατάσταση';
  @override
  String get shortcutSavingNote =>
      'Οι αλλαγές αποθηκεύονται αυτόματα, οπότε δεν υπάρχει συντόμευση '
      'αποθήκευσης.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Φόρτωση…';
  @override
  String get noteStatusSaving => 'Αποθήκευση…';
  @override
  String get noteStatusUnsaved => 'Μη αποθηκευμένο';
  @override
  String get noteStatusSaved => 'Αποθηκεύτηκε';
  @override
  String get noteStatusError => 'Σφάλμα';
  @override
  String get noteNotText =>
      'Αυτό το αρχείο δεν είναι σημείωση κειμένου, οπότε το '
      'Niman δεν μπορεί να το εμφανίσει εδώ.';
  @override
  String get noteLoadFailed => 'Δεν ήταν δυνατό να ανοίξει αυτή η σημείωση.';
  @override
  String wordCount(int count) => count == 1 ? '1 λέξη' : '$count λέξεις';
  @override
  String get outlineTooltip => 'Περιεχόμενο';
  @override
  String get outlineNoHeadings => 'Δεν υπάρχουν τίτλοι';
  @override
  String get outlineNoTitle => '(χωρίς τίτλο)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Έντονη';
  @override
  String get toolbarItalic => 'Πλάγια';
  @override
  String get toolbarStrikethrough => 'Με διαγραφή';
  @override
  String get toolbarSuperscript => 'Υπεργράμματο';
  @override
  String get toolbarUnderline => 'Υπογράμμιση';
  @override
  String get toolbarLink => 'Σύνδεσμος';
  @override
  String get toolbarCode => 'Μπλοκ κώδικα';
  @override
  String get toolbarImage => 'Εισαγωγή εικόνας';
  @override
  String get toolbarHeading => 'Τίτλος';
  @override
  String get toolbarList => 'Λίστα';
  @override
  String get toolbarOrderedList => 'Αριθμημένη λίστα';
  @override
  String get toolbarQuote => 'Παράθεση';
  @override
  String get toolbarIndent => 'Εισαγωγή';
  @override
  String get toolbarOutdent => 'Αφαίρεση εισαγωγής';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Εργαλεία';
  @override
  String get editorToolsTitle => 'Εργαλεία επεξεργαστή';
  @override
  String get toolCountListTitle => 'Μέτρηση λίστας';
  @override
  String get toolCountListSubtitle =>
      'Αθροίζει όσα απαριθμούν οι γραμμές, ως λίστα ελέγχου';
  @override
  String get toolCountListNeedsList =>
      'Αυτή η σημείωση δεν έχει λίστα για μέτρηση';
  @override
  String get tallySourceLabel => 'Λίστα';
  @override
  String get tallyCutLabel => 'Ανάγνωση κάθε γραμμής ως';
  @override
  String get tallyCutDash => 'Όνομα - τιμές';
  @override
  String get tallyCutColon => 'Όνομα: τιμές';
  @override
  String get tallyCutCommas => 'Τιμές χωρισμένες με κόμμα';
  @override
  String get tallyCutWhole => 'Όλη η γραμμή ως μία τιμή';
  @override
  String get tallySortLabel => 'Σειρά';
  @override
  String get tallySortCount => 'Πρώτα τα περισσότερα';
  @override
  String get tallySortAlphabetical => 'Αλφαβητικά';
  @override
  String get tallySortFirstSeen => 'Όπως αναγράφονται';
  @override
  String get tallyInsert => 'Εισαγωγή';
  @override
  String get tallyUpdate => 'Ενημέρωση';
  @override
  String get tallyNothingToCount => 'Δεν υπάρχει τίποτα να μετρηθεί εδώ';
  @override
  String get headingDialogTitle => 'Επίπεδο τίτλου';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Γραμμή εργαλείων επεξεργαστή';
  @override
  String get toolbarSettingsHint =>
      'Σύρετε για επαναταξινόμηση. Το μάτι εμφανίζει ή κρύβει το '
      'κουμπί.';
  @override
  String get toolbarShowButton => 'Εμφάνιση';
  @override
  String get toolbarHideButton => 'Κρύψη';
  @override
  String get toolbarResetOrder => 'Επαναφορά προεπιλογών';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Εμφάνιση προεπισκόπησης';
  @override
  String get showEditorTooltip => 'Εμφάνιση επεξεργαστή';
  @override
  String get enterFullScreenTooltip => 'Πλήρης οθόνη';
  @override
  String get exitFullScreenTooltip => 'Έξοδος από πλήρη οθόνη';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(μη αναλυμένος HTML πίνακας)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Αναζήτηση σημειώσεων';
  @override
  String get searchModeWords => 'Λέξεις';
  @override
  String get searchModeContains => 'Περιέχει';
  @override
  String get searchEmptyHint =>
      'Γράψτε για αναζήτηση στη βιβλιοθήκη ή key = value για φίλτρο '
      'frontmatter';
  @override
  String get searchTooShortHint => 'Γράψτε τουλάχιστον 2 χαρακτήρες';
  @override
  String get searchNoMatches => 'Δεν υπάρχουν ταυτοτήτες';
  @override
  String get searchLoadMore => 'Εμφάνιση περισσότερων';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Αντικατάσταση…';
  @override
  String get replaceInNoteAction => 'Αντικατάσταση σε αυτή τη σημείωση…';
  @override
  String get replaceInThisNote => 'Αντικατάσταση σε αυτή τη σημείωση';
  @override
  String get replaceWithLabel => 'Αντικατάσταση με';
  @override
  String get replaceCaseSensitive => 'Διακρίνει πεζά/κεφαλαία';
  @override
  String get replaceWholeWordsHint =>
      'αντικαθιστώνται μόνο ακριβείς ολόκληρες λέξεις';
  @override
  String get replaceConfirm => 'Αντικατάσταση';
  @override
  String get replaceCancel => 'Κλείσιμο';
  @override
  String get replaceUnavailable =>
      'Η αντικατάσταση δεν είναι διαθέσιμη αυτή τη στιγμή';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Εύρεση στη σημείωση';
  @override
  String get editorFindHint => 'Εύρεση';
  @override
  String get editorReplaceHint => 'Αντικατάσταση';
  @override
  String get editorFindCaseTooltip => 'Ταύτιση πεζών/κεφαλαίων';
  @override
  String get editorFindPreviousTooltip => 'Προηγούμενο ταύτιμα';
  @override
  String get editorFindNextTooltip => 'Επόμενο ταύτιμα';
  @override
  String get editorFindCloseTooltip => 'Κλείσιμο αναζήτησης';
  @override
  String get editorFindReplaceModeTooltip => 'Λειτουργία αντικατάστασης';
  @override
  String get editorReplaceOneTooltip => 'Αντικατάσταση αυτού του ταυτίματος';
  @override
  String get editorReplaceAllTooltip => 'Αντικατάσταση όλων';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Ετικέτες';
  @override
  String get tagsTitle => 'Ετικέτες';
  @override
  String get tagsEmpty =>
      'Δεν υπάρχουν ακόμα ετικέτες — προσθέστε #ετικέτα ή tags στο '
      'frontmatter';
  @override
  String get tagsBackTooltip => 'Επιστροφή στην αναζήτηση';
  @override
  String get tagsNotesEmpty => 'Δεν υπάρχουν σημειώσεις με αυτή την ετικέτα';
  @override
  String tagsNotesCapped(int limit) =>
      'Εμφανίζονται μόνο οι πρώτες $limit — αναζητήστε την ετικέτα για '
      'να περιορίσετε';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Ο σύνδεσμος δεν βρέθηκε';
  @override
  String get headingNotFoundTitle => 'Ο τίτλος δεν βρέθηκε';
  @override
  String get ambiguousLinkTitle => 'Πολλές σημειώσεις ταυτίζονται';
  @override
  String get openLinkFailed => 'Δεν ήταν δυνατό το άνοιγμα του συνδέσμου';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Η σημείωση δεν υπάρχει';
  @override
  String missingNoteDialogBody(String path) => 'Δημιουργία «$path»;';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Ο φάκελος «$folder» δεν υπάρχει';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Ανοιχτά';
  @override
  String get todoDone => 'Ολοκληρωμένα';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Όλες οι ημερομηνίες';
  @override
  String get todoFilter => 'Φίλτρα';
  @override
  String get todoNoTokens => 'Δεν υπάρχουν tokens σε αυτή τη λίστα';
  @override
  String get todoCountOpen => 'ανοιχτά';
  @override
  String get todoCountDone => 'ολοκληρωμένα';
  @override
  String get todoEmptyOpen => 'Δεν υπάρχουν ακόμα ανοιχτά καθήκοντα';
  @override
  String get todoEmptyDone => 'Δεν ολοκληρώθηκε τίποτα ακόμα';
  @override
  String get todoEmptyFiltered => 'Δεν υπάρχουν καθήκοντα που ταυτίζονται';
  @override
  String get todoTitle => 'Καθήκοντα';
  @override
  String get todoAddTooltip => 'Προσθήκη καθήκοντος';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Μορφή todo.txt';
  @override
  String get todoHelpTooltip => 'Βοήθεια μορφής';
  @override
  String get todoHelpIntro =>
      'Τα καθήκοντά σας είναι ένα απλό αρχείο κειμένου, ένα καθήκον '
      'ανά γραμμή. Η Niman γράφει τη σύνταξη για σας, αλλά δεν κρύβει '
      'τίποτα: μπορείτε να επεξεργαστείτε το αρχείο σε οποιονδήποτε '
      'επεξεργαστή, και η Niman θα το διαβάσει πίσω.';
  @override
  String get todoHelpFilesTitle => 'Δύο αρχεία';
  @override
  String get todoHelpFilesBody =>
      'Τα ανοιχτά καθήκοντα είναι στο todo.txt στη ρίζα της '
      'βιβλιοθήκης. Η ολοκλήρωση μετακινεί τη γραμμή του στο done.txt, '
      'ώστε το todo.txt να παραμείνει σύντομο. Αν μια ολοκληρωμένη '
      'γραμμή ξαναεμφανιστεί στο todo.txt, η Niman την αρχειώνει την '
      'επόμενη φορά που θα διαβάζει τα αρχεία.';
  @override
  String get todoHelpLineTitle => 'Ανατομία γραμμής';
  @override
  String get todoHelpLineBody =>
      'Ό,τι πριν την περιγραφή είναι προαιρετικό και πρέπει να '
      'έρχεται σε αυτή τη σειρά:';
  @override
  String get todoHelpDoneBody =>
      'Σημαίνει το καθήκον ολοκληρωμένο. Η Niman το προσθέτει όταν '
      'τσεκάρετε το κουτάκι.';
  @override
  String get todoHelpPriority => '(A) έως (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Προτεραιότητα. Το A είναι το υψηλότερο. Εμφανίζεται ως σήμα στη '
      'λίστα.';
  @override
  String get todoHelpDatesBody =>
      'Ημερομηνία λήξης, μετά ημερομηνία δημιουργίας. Με μόνο μία '
      'ημερομηνία, αυτή είναι ημερομηνία δημιουργίας, εκτός αν η '
      'γραμμή ξεκινά με x.';
  @override
  String get todoHelpTokensTitle => 'Προγράμματα, πλαίσια και ετικέτες';
  @override
  String get todoHelpTokensBody =>
      'Οπουδήποτε στην περιγραφή, μια λέξη με ένα από αυτά τα πρόθεμα '
      'γίνεται chip με το οποίο μπορείτε να φιλτράρετε. Τίποτα δεν είναι '
      'προεξοφλημένο: το token υπάρχει μόλις το γράψετε.';
  @override
  String get todoHelpProjectBody =>
      'Τι είναι το καθήκον, π.χ. +κατασκευή ή +διπλωματική.';
  @override
  String get todoHelpContextBody =>
      'Πού ή πώς θα το εκτελέσετε, π.χ. @σπίτι ή @τηλέφωνο';
  @override
  String get todoHelpHashtagBody =>
      'Ελεύθερη ετικέτα, για ό,τι δεν καλύπτουν τα υπόλοιπα δύο';
  @override
  String get todoHelpTagsTitle => 'Ημερομηνίες και υπενθυμίσεις';
  @override
  String get todoHelpTagsBody =>
      'Αυτές είναι ετικέτες key:value. Η Niman τις γράφει από τον '
      'διάλογο καθήκοντος και τις διαβάζει όπου και αν εμφανιστούν στη '
      'γραμμή.';
  @override
  String get todoHelpDueBody =>
      'Ημερομηνία λήξης. Ορίζει το χρώμα του σήματος και τα φίλτρα '
      'λήξης.';
  @override
  String get todoHelpRemBody =>
      'Πότε αποστέλλεται η ειδοποίηση, στη τοπική σας ώρα. Εκτελείται '
      'ακόμα και με σβηστή οθόνη και με κλειστή εφαρμογή.';
  @override
  String get todoHelpRemDesktop =>
      'Στον desktop, η Niman πρέπει να τρέχει όταν έρθει η ώρα: η '
      'υπενθύμιση εμφανίζεται όσο η εφαρμογή είναι ανοιχτή, και αν '
      'είναι κλειστή τίποτα δεν εκτελείται.';
  @override
  String get todoHelpOtherBody =>
      'Αποθηκεύονται ακριβώς όπως έχουν γραφεί, οπότε οι ετικέτες από '
      'άλλες todo.txt εφαρμογές επιβιώνουν τη μεταγωγή. Η Niman δεν '
      'δρα σε αυτές. rec: included: ένα επαναλαμβανόμενο καθήκον δεν '
      'επαναλαμβάνεται ακόμα.';
  @override
  String get todoHelpEditTitle => 'Επεξεργασία εκτός Niman';
  @override
  String get todoHelpEditBody =>
      'Ένα καθήκον που δεν το πειράξατε επιστρέφει byte-to-byte, '
      'συμπεριλαμβανομένων των περίεργων διαστημάτων. Επεξεργαστείτε '
      'μία γραμμή και η Niman το ξαναγράφει μόνο αυτή τη γραμμή στην '
      'κανονική της μορφή, αφήνοντας το υπόλοιπο αρχείο ανέπαφο.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Προσθήκη καθήκοντος';
  @override
  String get todoEditTitle => 'Επεξεργασία καθήκοντος';
  @override
  String get todoDescriptionHint => 'Περιγραφή';
  @override
  String get todoCancel => 'Ακύρωση';
  @override
  String get todoSave => 'Αποθήκευση';
  @override
  String get todoEditAction => 'Επεξεργασία';
  @override
  String get todoDeleteAction => 'Διαγραφή';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Υπέρβασε';
  @override
  String get todoDueToday => 'Σήμερα';
  @override
  String get todoDueNext7 => 'Επόμενες 7 ημέρες';
  @override
  String get todoDueNoDate => 'Χωρίς ημερομηνία';
  @override
  String get todoRowDue => 'Λήξη';
  @override
  String get todoRowDueToday => 'Λήξη σήμερα';
  @override
  String get todoSortTooltip => 'Ταξινόμηση';
  @override
  String get todoSortDue => 'Ημερομηνία λήξης';
  @override
  String get todoSortPriority => 'Προτεραιότητα';
  @override
  String get todoSortCreation => 'Ημερομηνία δημιουργίας';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Χωρίς προτεραιότητα';
  @override
  String get todoNoPriorityShort => 'Καμία';
  @override
  String get todoMorePriorities => 'Περισσότερα…';
  @override
  String get todoPriorityTitle => 'Προτεραιότητα';
  @override
  String get todoNoDueDate => 'Χωρίς ημερομηνία λήξης';
  @override
  String get todoNoReminder => 'Χωρίς υπενθύμιση';
  @override
  String get todoAddProject => '+ Πρόγραμμα';
  @override
  String get todoAddContext => '@ Πλαίσιο';
  @override
  String get todoAddHashtag => '# Ετικέτα';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Υπενθυμίσεις καθήκοντων';
  @override
  String get todoReminderChannelDescription =>
      'Προγραμματισμένοι συναγμοί για καθήκοντα με ώρα υπενθύμισης.';
  @override
  String get todoReminderBody => 'Υπενθύμιση καθήκοντος';
  @override
  String get todoReminderFallbackTitle => 'Υπενθύμιση καθήκοντος';
  @override
  String get todoReminderBlocked =>
      'Οι ειδοποιήσεις είναι απενεργοποιημένες, οπότε οι υπενθυμίσεις '
      'δεν θα εμφανιστούν.';
  @override
  String get todoReminderBattery =>
      'Η βελτιστοποίηση μπαταρίας είναι ενεργοποιημένη για την Niman. '
      'Το σύστημα μπορεί να βάλει την εφαρμογή σε κατάσταση νύχτας και '
      'να χάσει τις αναμενόμενες υπενθυμίσεις.';
  @override
  String get todoReminderInexact =>
      'Αυτή η συσκευή δεν επιτρέπει ακριβείς συναγμούς, οπότε η '
      'υπενθύμιση μπορεί να φτάσει μερικά λεπτά αργότερα με σβηστή '
      'οθόνη.';
  @override
  String get reminderShowTokensTitle =>
      'Ετικέτες στις ειδοποιήσεις υπενθύμισης';
  @override
  String get reminderShowTokensSubtitle =>
      'Διατηρεί +πρόγραμμα, @πλαίσιο και #ετικέτα στο κείμενο της '
      'ειδοποίησης. Ανενεργό, εμφανίζει μόνο το καθήκον που οριστήκατε.';
  @override
  String get todoReminderFixAction => 'Ανοίξτε τις ρυθμίσεις';
  @override
  String get todoReminderDismissAction => 'Απόρριψη';
  @override
  String get todoReminderDue => 'Λήξη';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Ακύρωση';
  @override
  String get actionCreate => 'Δημιουργία';
  @override
  String get actionNew => 'Νέο';
  @override
  String get actionSave => 'Αποθήκευση';
  @override
  String get actionClear => 'Εκκαθάριση';
  @override
  String get actionChoose => 'Επιλογή';
  @override
  String get actionDelete => 'Διαγραφή';
  @override
  String get actionRename => 'Μετανομασία';
  @override
  String get actionMove => 'Μετακίνηση';
  @override
  String get saveAndClose => 'Αποθήκευση και κλείσιμο';
  @override
  String get closeUnsavedTitle => 'Μη αποθηκευμένες αλλαγές';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return 'Το «${names.first}» έχει αλλαγές που δεν έχουν '
          'αποθηκευτεί. Αποθήκευση πριν το κλείσιμο;';
    }
    return 'Στις ${names.length} σημειώσεις υπάρχουν αλλαγές που δεν '
        'έχουν αποθηκευτεί. Αποθήκευση πριν το κλείσιμο;';
  }

  @override
  String get closeSaveFailed => 'Δεν αποθηκεύτηκε. Είναι ακόμα ανοιχτό.';
  @override
  String get actionRestore => 'Επαναφορά';
  @override
  String get actionEmpty => 'Εκκένωση';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Απόκρυψη πλαισίου (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Εμφάνιση πλαισίου (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Ελαχιστοποίηση';
  @override
  String get windowMaximizeTooltip => 'Μεγιστοποίηση';
  @override
  String get windowRestoreTooltip => 'Επαναφορά';
  @override
  String get windowCloseTooltip => 'Κλείσιμο';
  @override
  String get tabFiles => 'Αρχεία';
  @override
  String get tabSearch => 'Αναζήτηση';
  @override
  String get tabSettings => 'Ρυθμίσεις';
  @override
  String get quickNoteTitle => 'Γρήγορη σημείωση';
  @override
  String get treeEmpty => 'Δεν υπάρχουν ακόμα σημειώσεις';
  @override
  String get selectANote => 'Επιλέξτε σημείωση';
  @override
  String get showListTooltip => 'Εμφάνιση λίστας';
  @override
  String get editRawTooltip => 'Επεξεργασία ως είναι';
  @override
  String get sortAscTooltip => 'Ταξινόμηση Α-Ω';
  @override
  String get sortDescTooltip => 'Ταξινόμηση Ω-Α';
  @override
  String get newNoteTitle => 'Νέα σημείωση';
  @override
  String get newItemTooltip => 'Νέο';
  @override
  String get closeMenuTooltip => 'Κλείσιμο';
  @override
  String get newFolderTitle => 'Νέος φάκελος';
  @override
  String get newNoteSameFolder => 'Νέα σημείωση στον ίδιο φάκελο';
  @override
  String get newFromTemplateSameFolder => 'Νέα από πρότυπο στον ίδιο φάκελο';
  @override
  String trashOriginalPath(String path) => 'ήταν στο $path';
  @override
  String get trashOriginalRoot => 'ήταν στη ρίζα της βιβλιοθήκης';
  @override
  String trashItemCount(int count) => count == 1
      ? '1 \u03c3\u03c4\u03bf\u03b9\u03c7\u03b5\u03af\u03bf'
      : '$count \u03c3\u03c4\u03bf\u03b9\u03c7\u03b5\u03af\u03b1';
  @override
  String get newNoteHere => 'Νέα σημείωση εδώ';
  @override
  String get newFolderHere => 'Νέος φάκελος εδώ';
  @override
  String get newListNoteTitle => 'Νέα σημείωση-λίστα';
  @override
  String get newListNoteDefault => 'Η λίστα μου';
  @override
  String get setAsQuickNote => 'Ορισμός ως γρήγορη σημείωση';
  @override
  String get currentQuickNote => 'Τρέχουσα γρήγορη σημείωση';
  @override
  String get pinnedSection => 'Στιβαρωμένες';
  @override
  String pinnedSectionCount(int count) => 'Στιβαρωμένες · $count';
  @override
  String get templateFolderTitle => 'Φάκελος προτύπων';
  @override
  String get newFromTemplateTitle => 'Νέο από πρότυπο';
  @override
  String get newFromTemplateHere => 'Νέο από πρότυπο εδώ';
  @override
  String get templateFormTitle => 'Συμπλήρωση προτύπου';
  @override
  String get templateFormBacklink => 'Συνδεδεμένο από';
  @override
  String get templateFormNoNote => 'Χωρίς σημείωση';
  @override
  String get templateFormPickNote => 'Επιλογή σημείωσης';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Στοιχεία αντικατάστασης στο πρότυπο';
  @override
  String get templateHelpSubtitle =>
      'Ημερομηνία, τίτλος και οι υπόλοιπες τιμές προς συμπλήρωση';
  @override
  String get quickNoteSubtitle =>
      'Η σημείωση που ανοίγει η καρτέλα Γρήγορη σημείωση';
  @override
  String get listFolderSubtitle => 'Οι νέες λίστες εργασιών';
  @override
  String get templateFolderSubtitle => 'Η πηγή του „Νέο από πρότυπο“';
  @override
  String get attachmentsFolderSubtitle => 'Εικόνες και ήχος σε μια σημείωση';
  @override
  String get templateHelpIntro =>
      'Μια πρότυπο είναι μια απλή σημείωση με κενά. Η δημιουργία '
      'σημείωσης από αυτήν αντιγράφει το κείμενο της και γεμίζει τα '
      'κενά.';
  @override
  String get templateHelpUnknown =>
      'Ένα στοιχείο αντικατάστασης που η Niman δεν το αναγνωρίζει '
      'παραμένει ακριβώς όπως γράφτηκε, οπότε το τυπογραφικό λάθος '
      'φαίνεται στη σημείωση αντί να σπάσει τη γραμμή.';
  @override
  String get templateHelpValuesTitle => 'Τιμές';
  @override
  String get templateHelpTitleBody =>
      'Το όνομα υπό το οποίο δημιουργείται η σημείωση.';
  @override
  String get templateHelpDateBody =>
      'Σήμερα και τρέχουσα ώρα. Και τα δύο λαμβάνουν μορφή: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Ημερομηνία και ώρα μαζί.';
  @override
  String get templateHelpUuidBody =>
      'Νέο ταυτοποιητικό, διαφορετικό σε κάθε εμφάνιση.';
  @override
  String get templateHelpCounterBody =>
      'Αριθμός που αυξάνεται ανά όνομα, αποθηκευμένο δια της '
      'επανεκκίνησης: η πρώτη σημείωση γράφει 1, η επόμενη 2. Το ίδιο '
      'όνομα σε μία σημείωση γράφει τον ίδιο αριθμό. Συνδυάστε με '
      '|pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Βάζει τον δροβιέρα εδώ όταν δημιουργείται η σημείωση. Ο '
      'μερικός όρος αυτός δεν γράφεται. Ο πρώτος μερικός όρος κερδίζει, '
      'χωρίς φίλτρα, μόνο νέες σημειώσεις — και το πληκτρολόγιο '
      'ανοίγει ακόμα και αν η αυτόματη εστίαση είναι απενεργοποιημένη.';
  @override
  String get templateHelpDatesTitle => 'Γραφή ημερομηνιών';
  @override
  String get templateHelpDatesBody =>
      'Αυτά εκπροσωπούν τμήματα της ημερομηνίας στη μορφή. Ό,τι άλλο '
      "είναι κατ' ουσία, και κείμενο σε απλούς χαρακτήρες είναι επίσης "
      "κατ' ουσία. Τα ονόματα των μηνών και των ημερών ακολουθούν τη "
      'γλώσσα της εφαρμογής.';
  @override
  String get templateHelpYear => 'έτος: 2026, 26';
  @override
  String get templateHelpMonth => 'μήνας: 03, 3, Μάρτιος, Μάρ';
  @override
  String get templateHelpDay => 'μέρα: 09, 9, Δευτέρα, Δευ';
  @override
  String get templateHelpTime => 'ώρες, λεπτά, δευτερόλεπτα';
  @override
  String get templateHelpWeek => 'Εβδομάδα ISO και τρίμηνο: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Φίλτρα';
  @override
  String get templateHelpFiltersBody =>
      'Η τιμή μπορεί να ακολουθείται από φίλτρα, εφαρμοσμένα αριστερά '
      'προς τα δεξιά.';
  @override
  String get templateHelpCaseBody =>
      'Κεφαλαίο, πεζό και πρώτη κεφαλαία του κάθε λέξης — μια λέξη που '
      'γράψατε με κεφαλαίο παραμένει αναλλοίωτη.';
  @override
  String get templateHelpSlugBody =>
      'Η μορφή του κειμένου για συνδέσμους, για να χτίσετε wikilinks.';
  @override
  String get templateHelpPadBody =>
      'Κόβει το τέλος. Συμπληρώνει με μηδενικά έως το πλάτος. '
      'Χρησιμοποιεί εναλλακτική όταν η τιμή είναι άδεια.';
  @override
  String get templateHelpShiftBody =>
      'Μετακινεί την ημερομηνία κατά ημέρες, εβδομάδες, μήνες ή έτη — '
      'παρουσίαση την επόμενη εβδομάδα, αρχείο του προηγούμενου μήνα.';
  @override
  String get templateHelpSnapBody =>
      'Προσαρμόζει την ημερομηνία στην αρχή ή το τέλος της εβδομάδας, '
      'του μήνα ή του έτους.';
  @override
  String get templateHelpAskTitle => 'Κάτι σας ρωτάει';
  @override
  String get templateHelpAskBody =>
      'Μια φόρμα εμφανίζεται πριν δημιουργηθεί η σημείωση, ένα πεδίο '
      'ανά ερώτηση — και ένα για σύνδεσμο επιστροφής αν το πρότυπο το '
      'ζητήσει. Το ίδιο όνομα δύο φορές είναι μία ερώτηση, και η '
      'απάντηση της γεμίζει όλες τις εμφανίσεις — φάκελος και όνομα '
      'αρχείου περιλαμβάνονται.';
  @override
  String get templateHelpAskFieldBody =>
      'Πεδίο εγγραφής. Το κείμενο μετά τους δύο διπλούς άστελκους είναι '
      'αυτό με το οποίο ξεκινά.';
  @override
  String get templateHelpChoiceBody =>
      'Επιλογή από λίστα, διαχωρισμένη με κόμματα.';
  @override
  String get templateHelpWhereTitle => 'Πού πάει η σημείωση';
  @override
  String get templateHelpWhereBody =>
      'Αυτό δεν είναι κείμενο: είναι οδηγίες, και ζουν στο μπλοκ '
      'niman: στο ίδιο το frontmatter του προτύπου. Το μπλοκ '
      'υποστηρίζεται και στη συνέχεια αφαιρείται, οπότε δεν '
      'εμφανίζεται ποτέ στη σημείωση. Οι τιμές του μπορούν να '
      'περιέχουν στοιχεία αντικατάστασης.';
  @override
  String get templateHelpFolderBody =>
      'Ο φάκελος όπου δημιουργείται η σημείωση, που δημιουργείται αν '
      'δεν υπάρχει. Αν το λείπει, η σημείωση πηγαίνει εκεί που ήσασταν.';
  @override
  String get templateHelpFilenameBody =>
      'Πώς ονομάζεται η σημείωση. Ένα πρότυπο που το δηλώνει δεν '
      'ερωτάται για όνομα.';
  @override
  String get templateHelpAppendBody =>
      'Προσθέτει στη σημείωση αν αυτή ήδη υπάρχει, αντί να δημιουργήσει '
      'δεύτερη. Αυτό μετατρέπει έναν μήνα συζητήσεων σε ένα αρχείο.';
  @override
  String get templateHelpOpenBody =>
      'Τι γίνεται μόλις υπάρχει η σημείωση: επεξεργαστής (προεπιλογή), '
      'προεπισκόπηση ή τίποτα — η σημείωση υπογραμμίζεται και εσείς '
      'μένετε εκεί που ήσασταν.';
  @override
  String get templateHelpAroundTitle => 'Από πού προέρχεται';
  @override
  String get templateHelpParentBody =>
      'Η σημείωση που επιλέγεται στη φόρμα, η οποία προτείνει αυτή που '
      'είναι στην οθόνη. Γράψτε [[{{parent}}]] για σύνδεσμο επιστροφής '
      'προς αυτήν.';
  @override
  String get templateHelpFolderValueBody =>
      'Ο φάκελος όπου καταλήγει η σημείωση.';
  @override
  String get templateHelpClipboardBody =>
      'Τι υπάρχει στο πρόχειρο, και η επιλογή του επεξεργαστή όταν η '
      'σημείωση ξεκινά από αυτή.';
  @override
  String get templateHelpIncludeTitle => 'Επαναχρήση τμήματος';
  @override
  String get templateHelpIncludeBody =>
      'Ενσωματώνει άλλο ένα πρότυπο, οπότε δέκα πρότυπα μπορούν να '
      'μοιράζονται μία λίστα ελέγχου. Αναζητείται πρώτα στον φάκελο '
      'των προτύπων, και το .md μπορεί να παραληφθεί. Οι ερωτήσεις του '
      'προστίθενται στην ίδια φόρμα.';
  @override
  String get templateHelpExampleTitle => 'Όλα μαζί';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ Δεν υπάρχει πρότυπο «$path»';
  @override
  String includeCycle(String path) => '⚠ Το «$path» περιλαμβάνει τον εαυτό του';
  @override
  String includeTooDeep(String path) =>
      '⚠ Το «$path» είναι ενταγμένο πολύ βαθιά';
  @override
  String frontmatterInvalid(String reason) =>
      'Το frontmatter δεν διαβάζεται: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Το frontmatter του «$template» δεν διαβάζεται, οπότε ο φάκελός '
      'και το όνομα αρχείου του δεν έκαναν τίποτα: $reason';
  @override
  String get templatePickerTitle => 'Επιλογή προτύπου';
  @override
  String templatePickerEmpty(String folder) =>
      'Δεν υπάρχουν ακόμα πρότυπα. Τοποθετήστε μια σημείωση στο $folder/ '
      'και θα γίνει μία.';

  // Tree actions.
  @override
  String get actionPin => 'Στιβάρισμα';
  @override
  String get actionUnpin => 'Αποστιβάρισμα';
  @override
  String get pinToWidget => 'Σταθεροποίηση στο widget';
  @override
  String get pinnedForWidget =>
      'Σταθεροποιήθηκε: τοποθετήστε το widget Σημειώσεων στην αρχική οθόνη';
  @override
  String get pinWidgetUnavailable =>
      'Τα widgets της αρχικής οθόνης είναι διαθέσιμα στο Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Εμφάνιση στη διαχείριση αρχείων';
  @override
  String get openInDefaultApp => 'Άνοιγμα με την προεπιλεγμένη εφαρμογή';
  @override
  String get newNoteTabTooltip => 'Νέα σημείωση σε νέα καρτέλα';
  @override
  String get openNotesTooltip => 'Ανοιχτές σημειώσεις';
  @override
  String get closeTabTooltip => 'Κλείσιμο';
  @override
  String get openInNewTab => 'Άνοιγμα σε νέα καρτέλα';
  @override
  String get splitRight => 'Διαίρεση δεξιά';
  @override
  String get splitDown => 'Διαίρεση κάτω';
  @override
  String get moveToOtherPane => 'Μετακίνηση στο άλλο τμήμα';
  @override
  String get openBeside => 'Άνοιγμα στο πλάι';
  @override
  String get closeAllNotes => 'Κλείσιμο όλων';
  @override
  String get sidePanelTooltip => 'Εμφάνιση ή απόκρυψη του πλαϊνού πίνακα';
  @override
  String get historyAllVersions => 'Όλες οι εκδόσεις';
  @override
  String get openFileMissing =>
      'Το αρχείο αυτής της σημείωσης δεν βρίσκεται στον δίσκο';
  @override
  String get openFileFailed =>
      'Δεν ήταν δυνατό το άνοιγμα της σημείωσης εκτός του Niman';

  @override
  String get movedToTrash => 'Μετακινήθηκε στη σκουπιδιέρα';
  @override
  String get deletedMessage => 'Διαγράφηκε';
  @override
  String deleteToTrashConfirm(String name) =>
      'Το $name θα μεταφερθεί στο .trash/';
  @override
  String deleteForeverConfirm(String name) => 'Το $name θα διαγραφεί μόνιμα';
  @override
  String get chooseDestination => 'Επιλογή προορισμού';
  @override
  String get libraryRoot => 'Ρίζα βιβλιοθήκης';
  @override
  String moveTitle(String name) => 'Μετακίνηση $name';
  @override
  String headingLevelLabel(int level) => 'Επίπεδο τίτλου $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Δεν υπάρχει ακόμα γρήγορη σημείωση. Επιλέξτε μια μόνιμη '
      'σημείωση ή δημιουργήστε νέα — η γρήγορη σημείωση ανοίγει εδώ.';
  @override
  String get quickNoteChooseAction => 'Επιλογή σημείωσης…';
  @override
  String get quickNoteCreateAction => 'Δημιουργία νέας σημείωσης…';
  @override
  String get quickNoteNewTitle => 'Νέα γρήγορη σημείωση';
  @override
  String get quickNotePickerTitle => 'Επιλογή γρήγορης σημείωσης';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Νέος φάκελος';
  @override
  String get folderPickerEmpty => 'Δεν υπάρχουν ακόμα φάκελοι';
  @override
  String get listFolderTitle => 'Φάκελος λίστας';
  @override
  String get attachmentsFolderTitle => 'Φάκελος συνημμένων';

  // Trash (M1).
  @override
  String get trashEmpty => 'Η σκουπιδιέρα είναι άδεια';
  @override
  String get trashEmptyAction => 'Εκκένωση σκουπιδιέρας';
  @override
  String get trashEmptyConfirm =>
      'Αυτό διαγράφει μόνιμα όλα όσα βρίσκονται στον φάκελο της '
      'σκουπιδιέρας, συμπεριλαμβανομένων αντικειμένων που η Niman δεν '
      'τα τοποθέτησε εκεί.';
  @override
  String trashDeleteConfirm(String name) =>
      'Το $name θα διαγραφεί μόνιμα (χωρίς επιστροφή)';
  @override
  String get trashDeletePermanently => 'Μόνιμη διαγραφή';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Ανοίξτε έναν φάκελο με σημειώσεις Markdown ως τη βιβλιοθήκη '
      'σας';
  @override
  String get openLibraryExisting => 'Άνοιγμα υπάρχουσας';
  @override
  String get openLibraryCreate => 'Δημιουργία νέας';
  @override
  String get openLibraryCreateTitle => 'Δημιουργία νέας βιβλιοθήκης';
  @override
  String get openLibraryFolderName => 'Όνομα φακέλου';
  @override
  String get openLibraryChooseFolder => 'Επιλογή φακέλου βιβλιοθήκης';
  @override
  String get openLibraryChooseParent =>
      'Επιλογή φακέλου όπου θα δημιουργηθεί η βιβλιοθήκη';
  @override
  String get openLibraryUnsupported =>
      'Αυτός ο φάκελος δεν υποστηρίζεται. Επιλέξτε έναν φάκελο '
      'αποθήκευσης του επεξεργαστή.';
  @override
  String indexingCount(int done, int total) => '$done από $total σημειώσεις';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Οι βιβλιοθήκες σας';
  @override
  String get libraryUnreachable => 'Ανεπίτυπτη';
  @override
  String get libraryOpenedToday => 'Ανοίχτηκε σήμερα';
  @override
  String get libraryOpenedYesterday => 'Ανοίχτηκε χθες';
  @override
  String libraryOpenedDaysAgo(int days) => 'Ανοίχτηκε $days ημέρες πριν';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Ανοίχτηκε ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Άνοιγμα τώρα';
  @override
  String get switchLibraryTitle => 'Αλλαγή βιβλιοθήκης';
  @override
  String get libraryForget => 'Λήθη';
  @override
  String libraryForgetTitle(String name) => 'Λήθη «$name»?';
  @override
  String get libraryForgetExplained =>
      'Αφανίζεται από αυτή τη λίστα. Ο φάκελος, οι σημειώσεις και οι '
      'ρυθμίσεις της βιβλιοθήκης μέσα του παραμένουν αναλλοίωτες, και '
      'η επανάνοιξή της το επιστρέφει στη θέση του.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Επιτρέψτε πρόσβαση στα αρχεία';
  @override
  String get storageAccessNeeded =>
      'Η Niman δεν μπορεί να διαβάσει τις σημειώσεις σας χωρίς «Πρόσβαση '
      'σε όλα τα αρχεία». Επιτρέψτε το για να ανοίξετε μια βιβλιοθήκη.';
  @override
  String get storageAccessExplained =>
      'Η Niman διαβάζει τις σημειώσεις σας ως απλά αρχεία, οπότε το '
      'Android πρέπει να επιτρέψει πρόσβαση σε όλα τα αρχεία. Τίποτα '
      'δεν ανεβάστηκε, και διαβάζεται μόνο ο φάκελος της βιβλιοθήκης '
      'που επιλέξατε.';
  @override
  String folderAccessDenied(Object error) =>
      'Το σύστημα δεν έδωσε πρόσβαση στον φάκελο: $error';
  @override
  String folderPickFailed(Object error) => 'Η επιλογή φακέλου απέτυχε: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Ρυθμίσεις';
  @override
  String get libraryPathTitle => 'Διαδρομή βιβλιοθήκης';
  @override
  String get reindexTitle => 'Επαναδημιουργία δείκτη τώρα';
  @override
  String get reindexDone => 'Ο δείκτης επαναδημιουργήθηκε';
  @override
  String get closeLibraryTitle => 'Κλείσιμο βιβλιοθήκης';
  @override
  String get exportLogTitle => 'Εξαγωγή καταγραφών αποσφαλμάτωσης';
  @override
  String get exportLogSubtitle =>
      'Αποθήκευση των καταγεγραμένων συμβάντων σε αρχείο που θα '
      'επιλέξετε';
  @override
  String get exportLogEmpty =>
      'Ο απομνημονευτήρας καταγραφών αποσφαλμάτωσης είναι άδειος';
  @override
  String get quickNoteUnset => 'Δεν έχει οριστεί ακόμα';
  @override
  String exportLogDone(Object target) => 'Οι καταγραφές εξήχθησαν στο $target';
  @override
  String exportLogFailed(Object error) => 'Η εξαγωγή απέτυχε: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Δεν βρέθηκε ακριβές ταύτιμα όλης της λέξης «$term»';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Αντικαταστάθηκαν $occurrences εμφανίσεις του «$term» σε $notes '
      'σημειώσεις';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped ανοιχτές σημειώσεις παραλείφθηκαν)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Δεν υπάρχει ακριβές ταύτιμα όλης της λέξης «$term»'
      '${only == null ? 'δεν βρέθηκε' : 'βρέθηκε στο $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Σχετικά';
  @override
  String get versionTitle => 'Έκδοση';
  @override
  String get changelogTitle => 'Χangelog';
  @override
  String get changelogEmpty => 'Δεν υπάρχουν διαθέσιμες καταχωρίσεις';
  @override
  String changelogWhatsNew(String version) => 'Νέα στην έκδοση $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Ιστορικό';
  @override
  String get noteMenuTooltip => 'Ενέργειες σημείωσης';
  @override
  String get historyCurrentVersion => 'Τρέχουσα έκδοση';
  @override
  String get historyCurrentSubtitle => 'Η σημείωση όπως είναι τώρα';
  @override
  String get historyToday => 'Σήμερα';
  @override
  String get historyYesterday => 'Χθες';
  @override
  String get historyReasonSession => 'πριν την επεξεργασία';
  @override
  String get historyReasonInterval => 'κατά την επεξεργασία';
  @override
  String get historyReasonRestore => 'πριν την επαναφορά';
  @override
  String get historyReasonSync => 'πριν τον συγχρονισμό';
  @override
  String get historyReasonReplace => 'πριν την αντικατάσταση';
  @override
  String get historyReasonUnknown => 'ανακτημένη';
  @override
  String get historySyncBase => 'βάση συγχρονισμού';
  @override
  String get historyEmpty =>
      'Δεν υπάρχουν ακόμα εκδόσεις. Το Niman κρατά μία όταν αρχίζετε να '
      'επεξεργάζεστε τη σημείωση και μετά το πολύ μία κάθε λίγα λεπτά όσο '
      'γράφετε.';
  @override
  String historyKept(int kept, int limit) =>
      'Εκδόσεις που διατηρούνται: $kept από $limit';
  @override
  String get historyBaseKept =>
      'Η βάση συγχρονισμού διατηρείται και πέρα από το όριο.';
  @override
  String get historyOff =>
      'Το ιστορικό είναι απενεργοποιημένο για αυτή τη βιβλιοθήκη '
      '(Ρυθμίσεις, Βιβλιοθήκη).';
  @override
  String get historyLoadFailed => 'Δεν ήταν δυνατή η ανάγνωση του ιστορικού';
  @override
  String get historyCompareSubtitle => 'Σε σύγκριση με την τρέχουσα έκδοση';
  @override
  String get historyTabChanges => 'Αλλαγές';
  @override
  String get historyTabVersion => 'Έκδοση';
  @override
  String get historyNoChanges => 'Ίδιο κείμενο με την τρέχουσα έκδοση.';
  @override
  String get historyRestoreAction => 'Επαναφορά αυτής της έκδοσης';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Επαναφορά της έκδοσης ($when);';
  @override
  String get historyRestoreConfirmBody =>
      'Το τρέχον κείμενο αποθηκεύεται πρώτα στο ιστορικό, οπότε μπορείτε '
      'πάντα να επιστρέψετε.';
  @override
  String get historyRestoreConfirm => 'Επαναφορά';
  @override
  String historyRestored(String when) => 'Έγινε επαναφορά της έκδοσης ($when)';
  @override
  String get historyRestoreFailed => 'Δεν ήταν δυνατή η επαναφορά της έκδοσης';
  @override
  String get actionUndo => 'Αναίρεση';
  @override
  String diffLineRange(int start, int end) => 'Γραμμές $start–$end';
  @override
  String diffLineSingle(int line) => 'Γραμμή $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 αμετάβλητη γραμμή' : '$count αμετάβλητες γραμμές';
  @override
  String get historyTakeHunk => 'Επαναφορά εδώ';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Επαναφορά 1 αλλαγής' : 'Επαναφορά $count αλλαγών';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Οι επιλεγμένες αλλαγές επιστρέφουν στο κείμενο αυτής της έκδοσης. Η '
      'σημείωση όπως είναι τώρα διατηρείται πρώτα ως έκδοση, ώστε να μπορείς '
      'να το αναιρέσεις.';
  @override
  String get historyNoteChangedReloaded =>
      'Η σημείωση άλλαξε όσο ήσουν εδώ — η σύγκριση ενημερώθηκε.';
  @override
  String get historyVersionsTitle => 'Εκδόσεις προς διατήρηση';
  @override
  String get historyVersionsSubtitle => 'Ανά σημείωση, στο .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Καμία' : '$count';
  @override
  String get historyIntervalTitle => 'Νέα έκδοση το πολύ κάθε';
  @override
  String get historyIntervalSubtitle =>
      'Όσο γράφετε· η έναρξη επεξεργασίας μιας σημείωσης κρατά πάντα μία';
  @override
  String historyIntervalValue(int minutes) => '$minutes λεπ.';
  @override
  String get settingsSectionTranscription => 'Μεταγραφή';
  @override
  String get transcriptionModelTitle => 'Μοντέλο';
  @override
  String get transcriptionModelNone => 'Κανένα';
  @override
  String get transcriptionLanguageTitle => 'Γλώσσα';
  @override
  String get transcriptionLanguageSubtitle =>
      'Η γλώσσα που μιλιέται στις ηχογραφήσεις σας. Αν την ορίσετε, η '
      'μεταγραφή είναι ακριβέστερη από την αυτόματη ανίχνευση.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Όπως η εφαρμογή ($language)';
  @override
  String get transcriptionLanguageDetect => 'Αυτόματη ανίχνευση';
  @override
  String get transcriptionModelsTitle => 'Μοντέλα μεταγραφής';
  @override
  String transcriptionModelsUsed(String size) => 'Σε χρήση $size';
  @override
  String get transcriptionModelsInstalled => 'Ληφθέντα';
  @override
  String get transcriptionModelsDownloading => 'Λήψη σε εξέλιξη';
  @override
  String get transcriptionModelsAvailable => 'Διαθέσιμα';
  @override
  String get transcriptionModelsFooter =>
      'Τα μοντέλα μένουν στον χώρο αποθήκευσης της εφαρμογής σε αυτή τη '
      'συσκευή. Δεν αντιγράφονται στη βιβλιοθήκη ούτε συγχρονίζονται.';
  @override
  String get transcriptionModelDefault => 'Προεπιλογή';
  @override
  String get transcriptionModelSlow => 'Αργό';
  @override
  String get transcriptionModelHintTiny => 'Το ταχύτερο, το λιγότερο ακριβές';
  @override
  String get transcriptionModelHintBase =>
      'Καλή ισορροπία ταχύτητας και ακρίβειας';
  @override
  String get transcriptionModelHintSmall => 'Πιο ακριβές, περίπου 3× πιο αργό';
  @override
  String get transcriptionModelHintMedium => 'Πολύ ακριβές, αργό σε τηλέφωνο';
  @override
  String get transcriptionModelHintLarge =>
      'Το πιο ακριβές, χρειάζεται πολλή μνήμη';
  @override
  String get transcriptionModelDownload => 'Λήψη';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Διαγραφή του μοντέλου $model;';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Θα ελευθερωθούν $size. Μπορείτε να κατεβάσετε ξανά το μοντέλο '
      'αργότερα.';
  @override
  String get transcriptionModelFailed =>
      'Η λήψη απέτυχε. Ελέγξτε τη σύνδεση και δοκιμάστε ξανά.';
  @override
  String get actionRetry => 'Δοκιμή ξανά';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Η σύνδεση χάθηκε, νέα προσπάθεια…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Σε παύση στο $progress';
  @override
  String get actionResume => 'Συνέχιση';
  @override
  String get audioTranscribe => 'Μεταγραφή';
  @override
  String get audioTranscribeUnsupported =>
      'Μόνο ηχογραφήσεις WAV σε αυτή τη συσκευή';
  @override
  String get transcriptionQueued => 'Σε αναμονή';
  @override
  String get transcriptionPreparing => 'Προετοιμασία ήχου…';
  @override
  String transcriptionRunning(int percent) => 'Μεταγραφή… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Λήψη $model · $percent%';
  @override
  String get transcriptionSaved => 'Η μεταγραφή προστέθηκε στην περιγραφή';
  @override
  String get transcriptionNoSpeech =>
      'Δεν αναγνωρίστηκε ομιλία σε αυτή την ηχογράφηση';
  @override
  String get transcriptionFailed => 'Η μεταγραφή απέτυχε';
  @override
  String get transcriptionPickModelTitle => 'Επιλέξτε μοντέλο';
  @override
  String get transcriptionPickModelBody =>
      'Η μεταγραφή γίνεται σε αυτή τη συσκευή και η ηχογράφηση δεν '
      'αποστέλλεται ποτέ. Το μοντέλο λαμβάνεται μία φορά.';
  @override
  String get transcriptionPickModelAction => 'Λήψη και μεταγραφή';
  @override
  String get transcriptionModelRecommended => 'Προτεινόμενο';
  @override
  String get transcriptionExistingTitle =>
      'Αυτή η ηχογράφηση έχει ήδη περιγραφή';
  @override
  String get transcriptionExistingBody =>
      'Να αντικατασταθεί με τη μεταγραφή ή να προστεθεί η μεταγραφή από κάτω;';
  @override
  String get transcriptionAppend => 'Προσθήκη από κάτω';
  @override
  String get transcriptionReplace => 'Αντικατάσταση';
  @override
  String get settingsSectionSync => 'Συγχρονισμός';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Δεν έχει ρυθμιστεί για αυτή τη βιβλιοθήκη';
  @override
  String get syncNeverSynced => 'Δεν έχει συγχρονιστεί ποτέ';
  @override
  String syncLastSynced(String when) => 'Συγχρονίστηκε $when';
  @override
  String get syncRunning => 'Συγχρονισμός…';
  @override
  String syncScreenSubtitle(String library) => 'Βιβλιοθήκη $library';
  @override
  String get syncUrlLabel => 'Διεύθυνση φακέλου';
  @override
  String get syncUrlRequired => 'Εισαγάγετε τη διεύθυνση διακομιστή';
  @override
  String get syncUrlHint =>
      'Ο φάκελος πρέπει να υπάρχει. Αντιγράψτε τη διεύθυνση όπως '
      'τη δείχνει ο διακομιστής.';
  @override
  String get syncHttpWarning =>
      'Μη κρυπτογραφημένη σύνδεση: εντάξει μέσω VPN ή στο τοπικό '
      'σας δίκτυο.';
  @override
  String get syncUserLabel => 'Χρήστης';
  @override
  String get syncUserHint =>
      'Αφήστε το κενό αν ο διακομιστής δεν ζητά διαπιστευτήρια.';
  @override
  String get syncPasswordLabel => 'Κωδικός πρόσβασης';
  @override
  String get syncPasswordHint =>
      'Φυλάσσεται στην κλειδοθήκη αυτής της συσκευής, ποτέ στα '
      'αρχεία της βιβλιοθήκης.';
  @override
  String get syncPasswordKeepHint =>
      'Αφήστε το κενό για να κρατήσετε τον αποθηκευμένο κωδικό.';
  @override
  String get syncShowPassword => 'Εμφάνιση κωδικού';
  @override
  String get syncHidePassword => 'Απόκρυψη κωδικού';
  @override
  String get syncTestAction => 'Δοκιμή σύνδεσης';
  @override
  String get syncTesting => 'Δοκιμή…';
  @override
  String get syncRetargetWarning =>
      'Με νέα διεύθυνση ή νέο χρήστη, ο επόμενος συγχρονισμός '
      'ξεκινά από την αρχή ως πρώτος.';
  @override
  String get syncTestOk => 'Η σύνδεση λειτουργεί';
  @override
  String get syncModeFull => 'Πλήρης λειτουργία';
  @override
  String get syncModeCompatible => 'Συμβατή λειτουργία';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Ανάγνωση, εγγραφή και διαγραφή';
  @override
  String get syncCapEtags => 'Αποτυπώματα αρχείων (ETag)';
  @override
  String get syncCapNoEtags => 'Χωρίς αποτυπώματα αρχείων (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Συγκρίνει μέγεθος και ημερομηνία· αν υπάρχει αμφιβολία, '
      'κατεβάζει ξανά';
  @override
  String get syncCapGuarded => 'Προστατευμένες εγγραφές';
  @override
  String get syncCapUnguarded => 'Μη προστατευμένες εγγραφές';
  @override
  String get syncCapUnguardedDetail =>
      'Ελέγχει το αρχείο στον διακομιστή ακριβώς πριν την εγγραφή';
  @override
  String get syncCapMove => 'Μετονομασία χωρίς νέα αποστολή';
  @override
  String get syncCapNoMove => 'Χωρίς μετονομασίες στον διακομιστή';
  @override
  String get syncCapNoMoveDetail =>
      'Η μετονομασία γίνεται διαγραφή και νέα αποστολή';
  @override
  String get syncCompatibleNote =>
      'Στη συμβατή λειτουργία ο συγχρονισμός δουλεύει το ίδιο, '
      'με λίγα περισσότερα αιτήματα.';
  @override
  String get syncTestInvalidUrl => 'Μη έγκυρη διεύθυνση';
  @override
  String get syncTestInvalidUrlHint =>
      'Γράψτε μια διεύθυνση http:// ή https://, χωρίς χρήστη ή '
      'κωδικό μέσα της.';
  @override
  String get syncTestOffline => 'Ο διακομιστής δεν είναι προσβάσιμος';
  @override
  String get syncTestOfflineHint =>
      'Είναι ενεργό το VPN; Μια διεύθυνση 10.x ή 192.168.x '
      'λειτουργεί μόνο από το ίδιο δίκτυο.';
  @override
  String get syncTestAuth => 'Ο χρήστης ή ο κωδικός απορρίφθηκε';
  @override
  String get syncTestAuthHint => 'Ελέγξτε τα και δοκιμάστε ξανά.';
  @override
  String get syncTestNotFound => 'Ο φάκελος δεν υπάρχει';
  @override
  String get syncTestNotFoundHint =>
      'Δημιουργήστε τον στον διακομιστή ή διορθώστε τη διεύθυνση.';
  @override
  String get syncTestUnsupported => 'Δεν είναι φάκελος WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'Ο διακομιστής απαντά, αλλά όχι ως WebDAV.';
  @override
  String get syncTestFailed => 'Η δοκιμή δεν πέτυχε';
  @override
  String get syncNowAction => 'Συγχρονισμός τώρα';
  @override
  String get syncSectionServer => 'Διακομιστής';
  @override
  String get syncServerRow => 'Διεύθυνση, χρήστης και κωδικός';
  @override
  String get syncRetestTitle => 'Νέα δοκιμή του διακομιστή';
  @override
  String syncProbedAgo(String when) => 'Τελευταία δοκιμή: $when';
  @override
  String get syncDisconnectTitle => 'Αποσύνδεση αυτής της βιβλιοθήκης';
  @override
  String get syncDisconnectSubtitle =>
      'Τα αρχεία μένουν εδώ και στον διακομιστή';
  @override
  String get syncDisconnectConfirmTitle => 'Αποσύνδεση του συγχρονισμού;';
  @override
  String get syncDisconnectConfirmBody =>
      'Αυτή η βιβλιοθήκη σταματά να συγχρονίζεται σε αυτή τη '
      'συσκευή. Κανένα αρχείο δεν διαγράφεται, ούτε εδώ ούτε '
      'στον διακομιστή. Αν τη συνδέσετε ξανά, ο πρώτος '
      'συγχρονισμός ξεκινά από την αρχή.';
  @override
  String get syncDisconnectConfirm => 'Αποσύνδεση';
  @override
  String get syncFirstTitle => 'Πρώτος συγχρονισμός';
  @override
  String get syncFirstIntro =>
      'Σύγκρινα τη βιβλιοθήκη με τον φάκελο στον διακομιστή:';
  @override
  String get syncFirstUpload => 'Για αποστολή';
  @override
  String get syncFirstDownload => 'Για λήψη';
  @override
  String get syncFirstBoth => 'Και στις δύο πλευρές';
  @override
  String get syncFirstBothHint =>
      'Ίδια: καμία μεταφορά. Διαφορετικά: προς επίλυση';
  @override
  String get syncFirstNoDelete =>
      'Ο πρώτος συγχρονισμός δεν διαγράφει τίποτα, ούτε εδώ ούτε '
      'στον διακομιστή.';
  @override
  String get syncStartAction => 'Έναρξη';
  @override
  String syncMassTrashTitle(int count) => count == 1
      ? 'Μετακίνηση 1 αρχείου στη σκουπιδιέρα;'
      : 'Μετακίνηση $count αρχείων στη σκουπιδιέρα;';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Από τον διακομιστή λείπουν $count από τα $total '
      'συγχρονισμένα αρχεία. Συνήθως αυτό σημαίνει λάθος '
      'διεύθυνση, μη προσαρτημένο δίσκο NAS ή φάκελο που '
      'αδειάστηκε κατά λάθος.';
  @override
  String get syncMassTrashHint =>
      'Αν τα διαγράψατε πράγματι σε άλλη συσκευή, επιβεβαιώστε: '
      'εδώ πηγαίνουν στη σκουπιδιέρα.';
  @override
  String get syncMassTrashConfirm => 'Μετακίνηση στη σκουπιδιέρα';
  @override
  String syncMassDeleteTitle(int count) => count == 1
      ? 'Διαγραφή 1 αρχείου από τον διακομιστή;'
      : 'Διαγραφή $count αρχείων από τον διακομιστή;';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Εδώ λείπουν $count από τα $total συγχρονισμένα αρχεία. Αν '
      'δεν τα διαγράψατε εσείς, ακυρώστε και ελέγξτε τον φάκελο '
      'της βιβλιοθήκης.';
  @override
  String get syncMassDeleteConfirm => 'Διαγραφή από τον διακομιστή';
  @override
  String get syncTooltip => 'Συγχρονισμός';
  @override
  String get syncStageConnecting => 'Σύνδεση με τον διακομιστή…';
  @override
  String get syncStageComparing => 'Σύγκριση με τον διακομιστή…';
  @override
  String syncStageApplying(int done, int total) =>
      'Συγχρονισμός · $done από $total';
  @override
  String get syncStatusWarnings => 'Συγχρονίστηκε με προειδοποιήσεις';
  @override
  String syncConflictsHeader(int count) =>
      'Άλλαξαν εδώ και στον διακομιστή · $count';
  @override
  String get syncConflictHint => 'Καμία από τις δύο εκδόσεις δεν αγγίχτηκε';
  @override
  String get syncResolveAction => 'Επίλυση';
  @override
  String syncFailuresHeader(int count) => 'Δεν συγχρονίστηκαν · $count';
  @override
  String get syncFailuresHint => 'Νέα προσπάθεια στον επόμενο συγχρονισμό';
  @override
  String get syncAbortAuth => 'Ο διακομιστής απέρριψε τον κωδικό';
  @override
  String get syncAbortMissingPassword => 'Δεν υπάρχει αποθηκευμένος κωδικός';
  @override
  String get syncAbortOffline => 'Ο διακομιστής δεν είναι προσβάσιμος';
  @override
  String get syncAbortRemoteMissing =>
      'Ο φάκελος στον διακομιστή δεν υπάρχει πια';
  @override
  String get syncAbortUnsupported =>
      'Ο διακομιστής δεν λειτουργεί πια ως WebDAV';
  @override
  String get syncAbortFailed => 'Ο συγχρονισμός δεν πέτυχε';
  @override
  String get syncAbortNotConfirmed => 'Ο συγχρονισμός ακυρώθηκε';
  @override
  String get syncAbortNothingTouched =>
      'Κανένα αρχείο δεν αγγίχτηκε. Οι αλλαγές σας μένουν εδώ ως '
      'τον επόμενο επιτυχημένο συγχρονισμό.';
  @override
  String syncLastSuccess(String when) =>
      'Τελευταίος επιτυχημένος συγχρονισμός: $when';
  @override
  String get syncNoSuccessYet => 'Κανένας επιτυχημένος συγχρονισμός ακόμα';
  @override
  String get syncUpdatePasswordAction => 'Ενημέρωση κωδικού';
  @override
  String get syncRetryAction => 'Νέα προσπάθεια';
  @override
  String get syncOpenSettingsAction => 'Ρυθμίσεις';
  @override
  String get syncCloseAction => 'Κλείσιμο';
  @override
  String get syncDoneSnack => 'Συγχρονίστηκε';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Συγχρονίστηκε · 1 αρχείο που διαγράφηκε αλλού είναι στη '
            'σκουπιδιέρα'
      : 'Συγχρονίστηκε · $count αρχεία που διαγράφηκαν αλλού είναι '
            'στη σκουπιδιέρα';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Συγχρονίστηκε · 1 διένεξη προς επίλυση'
      : 'Συγχρονίστηκε · $count διενέξεις προς επίλυση';
  @override
  String get syncShowAction => 'Εμφάνιση';
  @override
  String get syncConflictTitle => 'Επίλυση διένεξης';
  @override
  String get syncConflictLegend =>
      'Οι γραμμές με − είναι του διακομιστή, οι γραμμές με + '
      'αυτής της συσκευής.';
  @override
  String get syncConflictBinary =>
      'Δεν είναι αρχείο κειμένου: επιλέξτε ποιο αντίγραφο θα '
      'κρατήσετε.';
  @override
  String get syncConflictKeepNote =>
      'Το αντίγραφο που δεν κρατάτε μένει στο ιστορικό της '
      'σημείωσης.';
  @override
  String get syncKeepLocal => 'Διατήρηση έκδοσης συσκευής';
  @override
  String get syncKeepRemote => 'Διατήρηση έκδοσης διακομιστή';
  @override
  String get syncConflictIdentical => 'Οι δύο εκδόσεις είναι ίδιες';
  @override
  String get syncConflictLoadFailed =>
      'Δεν ήταν δυνατή η ανάγνωση των δύο εκδόσεων';
  @override
  String get syncResolveFailed => 'Δεν ήταν δυνατή η επίλυση της διένεξης';
  @override
  String get syncResolved => 'Η διένεξη επιλύθηκε';
  @override
  String get syncSectionWhen => 'Πότε γίνεται συγχρονισμός';
  @override
  String get syncAutoTitle => 'Αυτόματα';
  @override
  String get syncAutoSubtitle =>
      'Μετά από αλλαγές, στο άνοιγμα και ανά διαστήματα';
  @override
  String get syncIntervalTitle => 'Έλεγχος του διακομιστή κάθε';
  @override
  String get syncIntervalSubtitle => 'Μόνο όσο η εφαρμογή είναι ανοιχτή';
  @override
  String get syncIntervalDialogBody =>
      'Για να βλέπετε αλλαγές από άλλες συσκευές όσο η εφαρμογή είναι '
      'ανοιχτή. Με «Ποτέ», μόνο μετά από αλλαγές και στο άνοιγμα.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 λεπτό' : '$count λεπτά';
  @override
  String get syncIntervalNever => 'Ποτέ';
  @override
  String get syncWifiOnlyTitle => 'Μόνο με Wi-Fi';
  @override
  String get syncWifiOnlySubtitle =>
      'Με δεδομένα κινητής, συγχρονισμός μόνο χειροκίνητα';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 αλλαγή σε αναμονή' : '$count αλλαγές σε αναμονή';
  @override
  String syncRetryIn(String wait) => 'νέα προσπάθεια σε $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds δευτ.';
  @override
  String syncWaitMinutes(int minutes) => '$minutes λεπ.';
  @override
  String get syncWaitingForWifi => 'Αναμονή για Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Αναμονή για σύνδεση';
  @override
  String get syncMobileDataHint =>
      'Το «Συγχρονισμός τώρα» λειτουργεί και με δεδομένα κινητής.';
  @override
  String get syncQueueKeptHint =>
      'Οι αλλαγές μένουν εδώ, ακόμα κι αν κλείσετε την εφαρμογή, και '
      'αποστέλλονται μόνες τους όταν απαντήσει ο διακομιστής.';
  @override
  String get syncAutoPaused => 'Ο αυτόματος συγχρονισμός είναι σε παύση';
  @override
  String get syncPausedAuthHint =>
      'Συνεχίζεται όταν ενημερώσετε τον κωδικό ή συγχρονίσετε '
      'χειροκίνητα.';
  @override
  String get syncPausedServerHint =>
      'Συνεχίζεται όταν διορθώσετε τη διεύθυνση ή συγχρονίσετε '
      'χειροκίνητα.';
  @override
  String get syncPausedConfirmHint =>
      'Το «Συγχρονισμός τώρα» δείχνει τι θα αφαιρεθεί και ρωτά πρώτα.';
  @override
  String get syncNeedsConfirmation => 'Αναμονή για την επιβεβαίωσή σας';
  @override
  String get syncMergeIntro =>
      'Οι αλλαγές που δεν επικαλύπτονται είναι ήδη ενωμένες· '
      'επιλέξτε τι θα κρατήσετε εκεί που επικαλύπτονται.';
  @override
  String get syncMergeClean =>
      'Οι δύο εκδόσεις ενώνονται μόνες τους: τίποτα δεν επικαλύπτεται.';
  @override
  String get syncMergeNoBase =>
      'Δεν υπάρχει κοινή έκδοση για την ένωση, οπότε πρέπει να '
      'επιλεγεί ολόκληρο το αρχείο.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Επικάλυψη $index από $total';
  @override
  String get syncMergeFromLocal => 'Από αυτή τη συσκευή';
  @override
  String get syncMergeFromRemote => 'Από τον διακομιστή';
  @override
  String get syncMergeRemovedLines => 'Γραμμές που αφαιρέθηκαν';
  @override
  String get syncMergeKeepLocal => 'Δικές μου';
  @override
  String get syncMergeKeepRemote => 'Του διακομιστή';
  @override
  String get syncMergeKeepBoth => 'Και τα δύο';
  @override
  String get syncMergeSave => 'Αποθήκευση της ένωσης';
  @override
  String get syncMergeKeepWhole => 'Ή κρατήστε ένα ολόκληρο αντίγραφο';
}
