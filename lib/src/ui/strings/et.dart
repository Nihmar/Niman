// The Estonian strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class EstonianStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'jaanuar',
    'veebruar',
    'märts',
    'aprill',
    'mai',
    'juuni',
    'juuli',
    'august',
    'september',
    'oktoober',
    'november',
    'detsember',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jaan',
    'veebr',
    'märts',
    'apr',
    'mai',
    'juuni',
    'juuli',
    'aug',
    'sep',
    'okt',
    'nov',
    'dets',
  ];
  @override
  List<String> get weekdayNames => const [
    'esmaspäev',
    'teisipäev',
    'kolmapäev',
    'neljapäev',
    'reede',
    'laupäev',
    'pühapäev',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'E',
    'T',
    'K',
    'N',
    'R',
    'L',
    'P',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Prügikast';
  @override
  String get trashSubtitle =>
      'Kustutatud elemendid liigutatakse .trash/-i (välja lülitatud = püsiv '
      'kustutamine)';
  @override
  String get debugLogsTitle => 'Silumise logid';
  @override
  String get debugLogsSubtitle => 'Logib rakenduse sündmused mälupufferis';
  @override
  String get lineNumbersTitle => 'Ridade numbrid';
  @override
  String get lineNumbersSubtitle => 'Kuvab numbrite veeru märgiste redaktoris';
  @override
  String get keyboardOnOpenTitle => 'Klaviatuur avamisel';
  @override
  String get keyboardOnOpenSubtitle =>
      'Kuvab klaviatuuri märgise avamisel (välja lülitatud = esimesel '
      'puudutusel)';
  @override
  String get editorKindSource => 'Markdowni allikas';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Eelvaade';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Kuvab kujundatud märgise allika redaktori kõrval';
  @override
  String get switchToWysiwygTooltip => 'Lülita WYSIWYG-redaktorile';
  @override
  String get switchToSourceTooltip => 'Lülita Markdowni allikale';
  @override
  String get wysiwygTooLarge =>
      'See märge on WYSIWYG-redaktoriks liiga suur. Ava see Markdowni '
      'allikana.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Välimus';
  @override
  String get settingsSectionEditor => 'Redaktor';
  @override
  String get settingsSectionLibrary => 'Kogu';
  @override
  String get settingsSectionReminders => 'Meeldetuletused';
  @override
  String get settingsSectionShortcuts => 'Klaviatuur';
  @override
  String get keyboardShortcutsTitle => 'Klaviatuuri lühendid';
  @override
  String get settingsSectionDiagnostics => 'Diagnostika';
  @override
  String get settingsSpellCheckTitle => 'Õigekirjapide';
  @override
  String get settingsSpellCheckSubtitle =>
      'Allkirjeldab õigekirjavigad kirjutamisel.';
  @override
  String get spellCheckDictionaryTitle => 'Sõnaraamat';
  @override
  String get spellCheckDictionarySystem => 'Süsteemi vaike';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Sõnaraamatute valik';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Valige kõik keeled, milles kogu on kirjutatud. Sõna läbib, kui üks '
      'valitud sõnaraamatutest seda tunneb; ilma valikuta otsustab süsteemi '
      'keel.';
  @override
  String get spellCheckNoDictionaries =>
      'Selles süsteemis ei leitud sõnaraamatuid.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Õigekirjapide';
  @override
  String get spellCheckTitle => 'Õigekiri';
  @override
  String get spellCheckEmpty => 'Õigekirjavigade pole.';
  @override
  String get spellCheckUnavailable =>
      'hunspell pole selles süsteemis installitud.';
  @override
  String get spellCheckNoSuggestions => 'Soovitused puuduvad';
  @override
  String spellCheckCount(int count) => '$count kontrollimiseks';
  @override
  String spellCheckLine(int line) => 'rida $line';

  @override
  String indentWidthValue(int spaces) => '$spaces tühikut';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Heledus';
  @override
  String get themeBrightnessSubtitle => 'Hele, tume või seadme seadistus';
  @override
  String get themeBrightnessSystem => 'Süsteem';
  @override
  String get themeBrightnessDay => 'Hele';
  @override
  String get themeBrightnessNight => 'Tume';
  @override
  String get themePaletteTitle => 'Värvipaleett';
  @override
  String get themePaletteSubtitle => 'Kasutajaliides ja märgiste värvid';
  @override
  String get themePaletteSystem => 'Süsteem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Kasutajaliidese teksti suurus';
  @override
  String get uiTextScaleSubtitle =>
      'Puus, kaardid ja dialoogid; süsteemi seadistuse kohal';
  @override
  String get noteTextScaleTitle => 'Märgiste teksti suurus';
  @override
  String get noteTextScaleSubtitle =>
      'Redaktor ja eelvaade on alati sünkroonis';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Eelvaate režiim';
  @override
  String get previewModeSubtitle =>
      'Kas eelvaade jagab ekraani redaktoriga või asendab selle';
  @override
  String get previewModeAuto => 'Kõrval';
  @override
  String get previewModeSwitch => 'Täisekraan';
  @override
  String get splitRatioTitle => 'Jagunisuhe';
  @override
  String get splitRatioSubtitle => 'Redaktori osa, kui eelvaade on kõrval';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Viide formaat';
  @override
  String get linkTypeSubtitle => 'Mida viide nupp redaktorisse kirjutab';
  @override
  String get linkTypeWikilink => 'Viikiviide';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Taande laius';
  @override
  String get indentWidthSubtitle =>
      'Taande iga taseme lisandatud tühikute arv redaktoris';
  @override
  String get languageTitle => 'Keel';
  @override
  String get languageSubtitle => 'Rakenduse enda teksti keel';
  @override
  String get languageSystem => 'Süsteem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Lisa element';
  @override
  String get listAddTooltip => 'Lisa element';
  @override
  String get listEmpty => 'Elemente veel pole';
  @override
  String get listDragHandleLabel => 'Muuda elemendi järjekorda';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Kiirmärge';
  @override
  String get shortcutNewTodo => 'Uus ülesanne';
  @override
  String get shortcutNewNote => 'Uus märge';
  @override
  String get shortcutNewList => 'Uus loetelu';
  @override
  String get shortcutToggleSidebar => 'Kuva või peida filter';
  @override
  String get shortcutEditorSection => 'Redaktoris';
  @override
  String get shortcutFind => 'Otsing';
  @override
  String get shortcutReplace => 'Otsi ja asenda';
  @override
  String get shortcutSavingNote =>
      'Muudused salvestatakse automaatselt, seega salvestamise lühendit ei '
      'ole.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Struktuur';
  @override
  String get outlineNoHeadings => 'Pealkirju pole';
  @override
  String get outlineNoTitle => '(pealkirjata)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Rasvane';
  @override
  String get toolbarItalic => 'Kalded';
  @override
  String get toolbarStrikethrough => 'Läbijoonitud';
  @override
  String get toolbarSuperscript => 'Üleind';
  @override
  String get toolbarUnderline => 'Alljoonitud';
  @override
  String get toolbarLink => 'Viide';
  @override
  String get toolbarCode => 'Koodiplokk';
  @override
  String get toolbarImage => 'Sisesta pilt';
  @override
  String get toolbarHeading => 'Pealkiri';
  @override
  String get toolbarList => 'Loetelu';
  @override
  String get toolbarOrderedList => 'Numbreeritud loetelu';
  @override
  String get toolbarQuote => 'Tsitaat';
  @override
  String get toolbarIndent => 'Taande';
  @override
  String get toolbarOutdent => 'Tühista taande';
  @override
  String get headingDialogTitle => 'Pealkirja tase';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Redaktori tööriistapaneel';
  @override
  String get toolbarSettingsHint =>
      'Lohista järjekorra muutmiseks; silm kuvab või peidab nupu.';
  @override
  String get toolbarShowButton => 'Kuva';
  @override
  String get toolbarHideButton => 'Peida';
  @override
  String get toolbarResetOrder => 'Taasta vaikimisi';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Kuva eelvaadet';
  @override
  String get showEditorTooltip => 'Kuva redaktorit';
  @override
  String get enterFullScreenTooltip => 'Täisekraan';
  @override
  String get exitFullScreenTooltip => 'Välju täisekraanist';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(toore HTML-tabel)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Otsi märgistest';
  @override
  String get searchModeWords => 'Sõnad';
  @override
  String get searchModeContains => 'Sisaldab';
  @override
  String get searchEmptyHint =>
      'Kirjuta kogus otsimiseks või võti = väärtus frontmatteri '
      'filtreerimiseks';
  @override
  String get searchTooShortHint => 'Kirjuta vähemalt 2 tähte';
  @override
  String get searchNoMatches => 'Tulemusi pole';
  @override
  String get searchLoadMore => 'Kuva rohkem';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Asenda …';
  @override
  String get replaceInNoteAction => 'Asenda selle märgise sees …';
  @override
  String get replaceInThisNote => 'Asenda selle märgise sees';
  @override
  String get replaceWithLabel => 'Asenda';
  @override
  String get replaceCaseSensitive => 'Suur- ja väiketundlik';
  @override
  String get replaceWholeWordsHint =>
      'asendatakse ainult täpsed täissõnade vasted';
  @override
  String get replaceConfirm => 'Asenda';
  @override
  String get replaceCancel => 'Sulge';
  @override
  String get replaceUnavailable => 'Asendus hetkel ei ole saadaval';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Otsi märgisest';
  @override
  String get editorFindHint => 'Otsi';
  @override
  String get editorReplaceHint => 'Asenda';
  @override
  String get editorFindCaseTooltip => 'Suur- ja väiketundlik';
  @override
  String get editorFindPreviousTooltip => 'Eelmine tulemus';
  @override
  String get editorFindNextTooltip => 'Järgmine tulemus';
  @override
  String get editorFindCloseTooltip => 'Sulge otsing';
  @override
  String get editorFindReplaceModeTooltip => 'Asendamisrežiim';
  @override
  String get editorReplaceOneTooltip => 'Asenda see tulemus';
  @override
  String get editorReplaceAllTooltip => 'Asenda kõik tulemused';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Sildid';
  @override
  String get tagsTitle => 'Sildid';
  @override
  String get tagsEmpty =>
      'Sildid pole veel — lisa #sild või sildid frontmatterisse';
  @override
  String get tagsBackTooltip => 'Tagasi otsingusse';
  @override
  String get tagsNotesEmpty => 'Selle sildiga märgist ei ole';
  @override
  String tagsNotesCapped(int limit) =>
      'Kuvatakse ainult esimesed $limit — otsige silti, et kitsendada';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Viidet ei leitud';
  @override
  String get headingNotFoundTitle => 'Pealkirja ei leitud';
  @override
  String get ambiguousLinkTitle => 'Mitu märgist vastab';
  @override
  String get openLinkFailed => 'Viidet ei õnnestunud avada';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Avatud';
  @override
  String get todoDone => 'Lõpetatud';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Kõik kuupäevad';
  @override
  String get todoFilter => 'Filtreeri';
  @override
  String get todoNoTokens => 'Selles loetelus pole tokeneid';
  @override
  String get todoCountOpen => 'avatud';
  @override
  String get todoCountDone => 'lõpetatud';
  @override
  String get todoEmptyOpen => 'Avatud ülesandeid pole veel';
  @override
  String get todoEmptyDone => 'Lõpetatud ei ole veel';
  @override
  String get todoEmptyFiltered => 'Ülesanne ei vasta';
  @override
  String get todoTitle => 'Ülesanded';
  @override
  String get todoAddTooltip => 'Lisa ülesanne';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt formaat';
  @override
  String get todoHelpTooltip => 'Formaati infot';
  @override
  String get todoHelpIntro =>
      'Teie ülesanded on tavaline tekstifail, üks ülesanne rida kohta. Niman '
      'kirjutab süntaksit teie eest, kuid ei peida midagi: faili saab muuta '
      'mis tahes redaktoris ja Niman loeb selle uuesti.';
  @override
  String get todoHelpFilesTitle => 'Kaks faili';
  @override
  String get todoHelpFilesBody =>
      'Avatud ülesanded elavad kogu juures olevas todo.txt-is. Lõpetades '
      'ühe, liigutatakse rida done.txt-i, et todo.txt jääks lühikeseks. '
      'Lõpetatud rida, mis uuesti todo.txt-sse satub, arhiveerib Niman '
      'järgmisel failide lugemisel.';
  @override
  String get todoHelpLineTitle => 'Rida anatoomia';
  @override
  String get todoHelpLineBody =>
      'Kõik, mis on kirjelduse ees, on valikuline ja peab tulema selles '
      'järjekorras:';
  @override
  String get todoHelpDoneBody =>
      'Tähistab ülesande lõpetatuna. Niman lisab selle, kui kontrollite kasti.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioriteet. A on kõige kõrgem. Kuvatakse embleemina loetelus.';
  @override
  String get todoHelpDatesBody =>
      'Lõpp, seejärel loomise kuupäev. Ühe kuupäevaga on see loomise '
      'kuupäev, kui rida ei algne tähe x-iga.';
  @override
  String get todoHelpTokensTitle => 'Projektid, kontekstid ja sildid';
  @override
  String get todoHelpTokensBody =>
      'Iga sõna kirjelduses, millel on üks neist eesliitest, muutub '
      'filtreeritavaks sildiks. Midagi ei ole eeldefineeritud: token '
      'eksisteerib, kuni seda kirjutatakse.';
  @override
  String get todoHelpProjectBody =>
      'Millisele projektile ülesanne kuulub, nt +köök või +töö.';
  @override
  String get todoHelpContextBody =>
      'Kus või kuidas seda tehakse, nt @kodu või @kohtumised.';
  @override
  String get todoHelpHashtagBody =>
      'Vaba sild selle jaoks, mida esimesed kaks ei kata.';
  @override
  String get todoHelpTagsTitle => 'Kuupäevad ja meeldetuletused';
  @override
  String get todoHelpTagsBody =>
      'Need on võti:väärtus sildid. Niman kirjutab need ülesannete dialoogist '
      'ja loeb neid, kuhu iganes need ridadel ilmuvad.';
  @override
  String get todoHelpDueBody =>
      'Lõpp. Juhib embleemi värvi ja kuupäevafiltreid.';
  @override
  String get todoHelpRemBody =>
      'Millal tuleks teavitus saata, teie ajavöös. Käivitub, kui ekraan on '
      'välja lülitatud ja rakendus suletud.';
  @override
  String get todoHelpRemDesktop =>
      'Arvutis peab Niman töötama, kui aeg on käes: meeldetuletus kuvatakse, '
      'kui rakendus on avatud, ja käivitamist ei toimu, kui see on suletud.';
  @override
  String get todoHelpOtherBody =>
      'Säilitatakse täpselt kirjutatud kujul, et muude todo.txt rakenduste '
      'sildid saaksid teekonda ellu jääda. Niman ei kasuta neid, rec: '
      'included: korduv ülesanne ei kordu veel.';
  @override
  String get todoHelpEditTitle => 'Muutmine Nimanis';
  @override
  String get todoHelpEditBody =>
      'Ridad, mida ei puudutatud, säilitatakse baitide kaupa. Muudetud rida '
      'kirjutab Niman ainult selle rida kanonilises vormis, muu osa failist '
      'jääb puutumatuks.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Lisa ülesanne';
  @override
  String get todoEditTitle => 'Muuda ülesannet';
  @override
  String get todoDescriptionHint => 'Kirjeldus';
  @override
  String get todoCancel => 'Tühista';
  @override
  String get todoSave => 'Salvesta';
  @override
  String get todoEditAction => 'Muuda';
  @override
  String get todoDeleteAction => 'Kustuta';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Aegumiskäik möödas';
  @override
  String get todoDueToday => 'Täna';
  @override
  String get todoDueNext7 => 'Järgmise 7 päeva';
  @override
  String get todoDueNoDate => 'Kuupäevata';
  @override
  String get todoRowDue => 'Lõpp';
  @override
  String get todoRowDueToday => 'Lõpp täna';
  @override
  String get todoSortTooltip => 'Sorteeri';
  @override
  String get todoSortDue => 'Lõppkuupäev';
  @override
  String get todoSortPriority => 'Prioriteet';
  @override
  String get todoSortCreation => 'Loomise kuupäev';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Prioriteedita';
  @override
  String get todoNoPriorityShort => 'Puudub';
  @override
  String get todoMorePriorities => 'Rohkem …';
  @override
  String get todoPriorityTitle => 'Prioriteet';
  @override
  String get todoNoDueDate => 'Lõputa';
  @override
  String get todoNoReminder => 'Meeldetuletuseta';
  @override
  String get todoAddProject => '+ Projekt';
  @override
  String get todoAddContext => '@ Kontekst';
  @override
  String get todoAddHashtag => '# Sild';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Ülesannete meeldetuletused';
  @override
  String get todoReminderChannelDescription =>
      'Planeeritud teavitused ülesannete jaoks, millel on meeldetuletuse aeg.';
  @override
  String get todoReminderBody => 'Ülesande meeldetuletus';
  @override
  String get todoReminderFallbackTitle => 'Ülesande meeldetuletus';
  @override
  String get todoReminderBlocked =>
      'Teavitused on välja lülitatud, seega meeldetuletusi ei kuvata.';
  @override
  String get todoReminderBattery =>
      'Aku optimeerimine on Niman jaoks sisse lülitatud. Süsteem võib '
      'rakenduse kuhjata ja ootavad meeldetuletused kaotada.';
  @override
  String get todoReminderInexact =>
      'See seade ei toeta täpseid alarme, seega meeldetuletus võib tulla '
      'paar minutit hiljem, kui ekraan on välja lülitatud.';
  @override
  String get reminderShowTokensTitle => 'Sildid meeldetuletuse teavitustes';
  @override
  String get reminderShowTokensSubtitle =>
      'Jätke +projekt, @kontekst ja #sild teavituse teksti. Välja lülitatud '
      'kuvab ainult ülesande, mille te kirjutasite.';
  @override
  String get todoReminderFixAction => 'Ava seaded';
  @override
  String get todoReminderDismissAction => 'Aldesta';
  @override
  String get todoReminderDue => 'Lõpp';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Tühista';
  @override
  String get actionCreate => 'Loo';
  @override
  String get actionNew => 'Uus';
  @override
  String get actionSave => 'Salvesta';
  @override
  String get actionClear => 'Tühjendi';
  @override
  String get actionChoose => 'Vali';
  @override
  String get actionDelete => 'Kustuta';
  @override
  String get actionRename => 'Nime muuda';
  @override
  String get actionMove => 'Liiguta';
  @override
  String get saveAndClose => 'Salvesta ja sulge';
  @override
  String get closeUnsavedTitle => 'Salvestamata muudused';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '„${names.first}” on salvestamata muudused. '
          'Kas salvestada enne sulgemist?';
    }
    return '${names.length} märgist on salvestamata muudused. '
        'Kas salvestada enne sulgemist?';
  }

  @override
  String get closeSaveFailed => 'Salvestamine ebaõnnestus; märge jääb avatuks.';
  @override
  String get actionRestore => 'Taasta';
  @override
  String get actionEmpty => 'Tühjendi';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Peida külgpaneel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Kuva külgpaneel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimeeri';
  @override
  String get windowMaximizeTooltip => 'Maksimeeri';
  @override
  String get windowRestoreTooltip => 'Taasta';
  @override
  String get windowCloseTooltip => 'Sulge';
  @override
  String get tabFiles => 'Failid';
  @override
  String get tabSearch => 'Otsing';
  @override
  String get tabSettings => 'Seaded';
  @override
  String get quickNoteTitle => 'Kiirmärge';
  @override
  String get treeEmpty => 'Märgist ei ole veel';
  @override
  String get selectANote => 'Vali märge';
  @override
  String get showListTooltip => 'Kuva loetelu';
  @override
  String get editRawTooltip => 'Muuda toorelt';
  @override
  String get sortAscTooltip => 'Sorteeri A–Z';
  @override
  String get sortDescTooltip => 'Sorteeri Z–A';
  @override
  String get newNoteTitle => 'Uus märge';
  @override
  String get newFolderTitle => 'Uus kaust';
  @override
  String get newNoteHere => 'Uus märge siia';
  @override
  String get newFolderHere => 'Uus kaust siia';
  @override
  String get newListNoteTitle => 'Uus märge loeteluga';
  @override
  String get newListNoteDefault => 'Minu loetelu';
  @override
  String get setAsQuickNote => 'Määra kiirmärgiks';
  @override
  String get currentQuickNote => 'Aktuaalne kiirmärge';
  @override
  String get pinnedSection => 'Kinnitatud';
  @override
  String pinnedSectionCount(int count) => 'Kinnitatud · $count';
  @override
  String get templateFolderTitle => 'Šabloonide kaust';
  @override
  String get newFromTemplateTitle => 'Uus šabloonist';
  @override
  String get newFromTemplateHere => 'Uus šabloonist siia';
  @override
  String get templateFormTitle => 'Täita šabloon';
  @override
  String get templateFormBacklink => 'Tagasiviide';
  @override
  String get templateFormNoNote => 'Märgita';
  @override
  String get templateFormPickNote => 'Vali märge';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Šablooni asendused';
  @override
  String get templateHelpIntro =>
      'Šabloon on tavaline märge, millel on augud. Märgise loomine sellest '
      'kopioneerib teksti ja täidab augud.';
  @override
  String get templateHelpUnknown =>
      'Asendus, mida Niman ei tunne, jääb täpselt kirjutatud kujul, et '
      'vigad näeksid välja märge, mitte et vaikselt katkeks rida.';
  @override
  String get templateHelpValuesTitle => 'Väärtused';
  @override
  String get templateHelpTitleBody => 'Nimi, mille all märge tuleb luua.';
  @override
  String get templateHelpDateBody =>
      'Täna ja aktuaalne aeg. Mõlemad acceptuju formaati: '
      '{{date:DD.MM.YYYY}}.';
  @override
  String get templateHelpNowBody => 'Kuupäev ja aeg koos.';
  @override
  String get templateHelpUuidBody =>
      'Uus identifikaator, iga kasutamise jaoks erinev.';
  @override
  String get templateHelpCounterBody =>
      'Nime järgi lugemis hoiab arvu käikude vahel: esimene märge kirjutab '
      '1, järgmine 2. Sama nimi märgist kirjutab sama arvu; kombineerige '
      '|pad:3-ga.';
  @override
  String get templateHelpCursorBody =>
      'Pange kursor siia märgise loomisel; märk ei kirjutata. Esimene märk '
      'võidab, filtreerimata, ainult uued märgid — ja klaviatuur avaneb ka, '
      'kui autofocus on välja lülitatud.';
  @override
  String get templateHelpDatesTitle => 'Kuupäeva kirjutamine';
  @override
  String get templateHelpDatesBody =>
      'Need tähistavad formaadis kuupäeva osi. Kõik, mis ei ole, on '
      'kirjaviisne, kaasa arvatud teksti ühekordses ümbermõõdus. Kuu- ja '
      'päevanimed järgnevad rakenduse keelt.';
  @override
  String get templateHelpYear => 'aasta: 2026, 26';
  @override
  String get templateHelpMonth => 'kuu: 03, 3, märts, mär';
  @override
  String get templateHelpDay => 'päev: 09, 9, esmaspäev, E';
  @override
  String get templateHelpTime => 'tunnid, minutid, sekundid';
  @override
  String get templateHelpWeek => 'ISO nädal ja kvartal: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtrid';
  @override
  String get templateHelpFiltersBody =>
      'Väärtusele järgnevad filtrid, mis rakendatakse vasakult paremale.';
  @override
  String get templateHelpCaseBody =>
      'Suurkirjad, väikekirjad ja igas sõnas esimene täht — suurekirjaga '
      'kirjutatud sõna ei muutu.';
  @override
  String get templateHelpSlugBody => 'Teksti viidevorm, viikiviide luumiseks.';
  @override
  String get templateHelpPadBody =>
      'Lõigake otsad; täitke nullidega soovitud laiusele; alternatiiv, kui '
      'väärtus on tühi.';
  @override
  String get templateHelpShiftBody =>
      'Liigutage kuupäeva päevi, nädalaid, kuud või aastaid — konverents '
      'nädala pärast, dokument eelmisest kuust.';
  @override
  String get templateHelpSnapBody =>
      'Kinnitage kuupäev nädala, kuu või aasta algusse või lõppu.';
  @override
  String get templateHelpAskTitle => 'Küsim teile midagi';
  @override
  String get templateHelpAskBody =>
      'Enne märgise loomist kuvatakse vorm, küsimuse väljad — ja üks '
      'tagasiviide, kui šabloon seda nõuab. Sama märk kaks korda on küsimus '
      'ja selle vastus täidab kõik esinemised — kausta ja failinime.';
  @override
  String get templateHelpAskFieldBody =>
      'Kirjutamise väli; tekst teise koma järel on algus.';
  @override
  String get templateHelpChoiceBody => 'Valik loetelust, komaga eraldatud.';
  @override
  String get templateHelpWhereTitle => 'Kuhu märge jõuab';
  @override
  String get templateHelpWhereBody =>
      'See ei ole tekst: need on juhised, mis elavad šablooni frontmatteri '
      'niman: blokkis. Blokk käivitatakse ja kustutatakse, et see kunagi '
      'märgis ei kuvata. Väärtus võib sisaldada asendusi.';
  @override
  String get templateHelpFolderBody =>
      'Kaust, kuhu märge luuakse, luuakse, kui see ei eksisteeri. Ilma '
      'selleeta jõuab märge sinna, kus te olite.';
  @override
  String get templateHelpFilenameBody =>
      'Kuidas märge nimetatakse. Šabloon, mis selle ütleb, ei küsi nime.';
  @override
  String get templateHelpAppendBody =>
      'Lisatakse märgise juurde, kui see juba eksisteerib, uue loomise '
      'asemel. Nii saab kuu kokkusaamistest ühest failist.';
  @override
  String get templateHelpOpenBody =>
      'Mis juhtub, kui märge eksisteerib: redaktor (vaike), eelvaade või '
      'midagi — märge arhiveeritakse ja te jääte sinna, kus olite.';
  @override
  String get templateHelpAroundTitle => 'Kust see tuleb';
  @override
  String get templateHelpParentBody =>
      'Märge, mille te vormis valite, kuvatakse ekraanil; kirjutage '
      '[[{{parent}}]] tagasiviidena.';
  @override
  String get templateHelpFolderValueBody => 'Kaust, kuhu märge jõuab.';
  @override
  String get templateHelpClipboardBody =>
      'Mis on lõikepuhvris ja valik redaktoris, kui märge sealt alustas.';
  @override
  String get templateHelpIncludeTitle => 'Osade korduvkasutus';
  @override
  String get templateHelpIncludeBody =>
      'Sisestage teine šabloon, et kümme šabloon jagaks ühte kontrollloetelu. '
      'Otsing toimub esmalt šabloonide kaustas, .md võib puududa. Selle '
      'omased küsimused lähevad samasse vormi.';
  @override
  String get templateHelpExampleTitle => 'Kõik ühes kohas';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ šabloon „$path” ei eksisteeri';
  @override
  String includeCycle(String path) => '⚠ „$path” sisestub iseendasse';
  @override
  String includeTooDeep(String path) =>
      '⚠ „$path” on liiga sügavalt sisestatud';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatteri ei õnnestunud lugeda: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Šablooni „$template” frontmatteri ei õnnestunud lugeda, seega kaust ja '
      'failinime ei toimeta midagi: $reason';
  @override
  String get templatePickerTitle => 'Šabloonide valik';
  @override
  String templatePickerEmpty(String folder) =>
      'Šabloonid pole veel. Sisestage märge $folder/ ja see on šabloon.';

  // Tree actions.
  @override
  String get actionPin => 'Kinnita';
  @override
  String get actionUnpin => 'Eemalda kinnitus';
  @override
  String get movedToTrash => 'Liigutatud prügikastu';
  @override
  String get deletedMessage => 'Kustutatud';
  @override
  String deleteToTrashConfirm(String name) => '$name liigutatakse .trash/-i';
  @override
  String deleteForeverConfirm(String name) => '$name kustutatakse püsivalt';
  @override
  String get chooseDestination => 'Vali sihtkoht';
  @override
  String get libraryRoot => 'Kogu juur';
  @override
  String moveTitle(String name) => 'Liiguta $name';
  @override
  String headingLevelLabel(int level) => 'Pealkiri taseme $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Kiirmärgi pole veel. Valige olemasolev märge või looge uue — kiirmärge '
      'avaneb siin.';
  @override
  String get quickNoteChooseAction => 'Vali märge …';
  @override
  String get quickNoteCreateAction => 'Loo uus märge …';
  @override
  String get quickNoteNewTitle => 'Uus kiirmärge';
  @override
  String get quickNotePickerTitle => 'Kiirmärgi valik';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Uus kaust';
  @override
  String get folderPickerEmpty => 'Kaustu pole veel';
  @override
  String get listFolderTitle => 'Loetelute kaust';

  // Trash (M1).
  @override
  String get trashEmpty => 'Prügikast on tühi';
  @override
  String get trashEmptyAction => 'Tühjendi prügikasti';
  @override
  String get trashEmptyConfirm =>
      'See kustutab püsivalt kõik, mis prügikastus on, kaasa arvatud '
      'elemendid, mida Niman sinna ei pannud.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name kustutatakse püsivalt (taastamata)';
  @override
  String get trashDeletePermanently => 'Kustuta püsivalt';

  // The open/create library screen.
  @override
  String get openLibraryIntro => 'Ava Markdowni märkiste kaust kogu';
  @override
  String get openLibraryExisting => 'Ava olemasolev';
  @override
  String get openLibraryCreate => 'Loo uus';
  @override
  String get openLibraryCreateTitle => 'Loo uus kogu';
  @override
  String get openLibraryFolderName => 'Kausta nimi';
  @override
  String get openLibraryChooseFolder => 'Vali kogu kaust';
  @override
  String get openLibraryChooseParent => 'Vali kaust, kuhu kogu luuakse';
  @override
  String get openLibraryUnsupported =>
      'Seda kausta ei toetata. Valige seadme hoiukohast kaust.';
  @override
  String indexingCount(int done, int total) => '$done / $total märgist';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Teie kogud';
  @override
  String get libraryUnreachable => 'Saavutamatu';
  @override
  String get libraryOpenedToday => 'Avatud täna';
  @override
  String get libraryOpenedYesterday => 'Avatud eile';
  @override
  String libraryOpenedDaysAgo(int days) => 'Avatud $days päeva eest';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Avatud ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Avatud hetkel';
  @override
  String get switchLibraryTitle => 'Lülita kogu';
  @override
  String get libraryForget => 'Unusta';
  @override
  String libraryForgetTitle(String name) => 'Unustada „$name”?';
  @override
  String get libraryForgetExplained =>
      'Kaob sellest loetelust. Kaust, märgid ja koguse seaded jäävad '
      'puutumatuks ja uuesti avamine viib kohale.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Luba failidele ligipääs';
  @override
  String get storageAccessNeeded =>
      'Niman ei saa teie märgisi lugeda ilma „Kõikide failide juurdepääs”eta. '
      'Lubage see kogu avamiseks.';
  @override
  String get storageAccessExplained =>
      'Niman loeb teie märgisi tavalistena failidena, seega peab Android '
      'andma kõigi failide juurdepääsu. Midagi ei saadeta ja luuakse ainult '
      'valitud kogu kaust.';
  @override
  String folderAccessDenied(Object error) =>
      'Süsteem ei lubanud kausta ligipääsu: $error';
  @override
  String folderPickFailed(Object error) => 'Kausta valik ebaõnnestus: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Seaded';
  @override
  String get libraryPathTitle => 'Kogu aadress';
  @override
  String get reindexTitle => 'Indekseeri uuesti hetkel';
  @override
  String get reindexDone => 'Uuesti indekseerimine lõpetatud';
  @override
  String get closeLibraryTitle => 'Sulge kogu';
  @override
  String get exportLogTitle => 'Ekspordi silumise logid';
  @override
  String get exportLogSubtitle =>
      'Salvestage registreeritud sündmused faili, mille te valite';
  @override
  String get exportLogEmpty => 'Logi bufer on tühi';
  @override
  String get quickNoteUnset => 'Määramata';
  @override
  String exportLogDone(Object target) => 'Logid eksporditud $target';
  @override
  String exportLogFailed(Object error) => 'Ekspordi ebaõnnestus: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) => '„$term” täpset täissõna vastet ei ole';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Asendatud $occurrences esinemised „$term” $notes märgist';
  @override
  String replaceSkipped(int skipped) => ' ($skipped avatud märgist jäetud)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '„$term” täpset täissõna vastet ei ole'
      '${only == null ? '' : ' ei leitud $only-s'}';
}
