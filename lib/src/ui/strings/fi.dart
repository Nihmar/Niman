// The Finnish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class FinnishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'tammikuu',
    'helmikuu',
    'maaliskuu',
    'huhtikuu',
    'toukokuu',
    'kesäkuu',
    'heinäkuu',
    'elokuu',
    'syyskuu',
    'lokakuu',
    'marraskuu',
    'joulukuu',
  ];
  @override
  List<String> get monthNamesShort => const [
    'tam',
    'hel',
    'maa',
    'huh',
    'tou',
    'kes',
    'hei',
    'elo',
    'sys',
    'lok',
    'mar',
    'jou',
  ];
  @override
  List<String> get weekdayNames => const [
    'maanantai',
    'tiistai',
    'keskiviikko',
    'torstai',
    'perjantai',
    'lauantai',
    'sunnuntai',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'ma',
    'ti',
    'ke',
    'to',
    'pe',
    'la',
    'su',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Korisi';
  @override
  String get trashSubtitle =>
      'Poistetut siirtyvät kansioon .trash/ (pois päältä = pysyvä poisto)';
  @override
  String get debugLogsTitle => 'Vianetsintälokit';
  @override
  String get debugLogsSubtitle =>
      'Tallentaa sovelluksen tapahtumat muistipuskuriin';
  @override
  String get lineNumbersTitle => 'Rivinumerot';
  @override
  String get lineNumbersSubtitle => 'Näytä rivinumerojen palsta muokkainnissa';
  @override
  String get keyboardOnOpenTitle => 'Näppäimistö avattaessa';
  @override
  String get keyboardOnOpenSubtitle =>
      'Näytä näppäimistö, kun muistiinpano avataan (pois päältä = '
      'ensi kosketuksesta)';
  @override
  String get editorKindSource => 'Markdown-lähdekoodi';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Esikatselu';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Näytä renderöity muistiinpano lähdekoodin muokkainnin vieressä';
  @override
  String get switchToWysiwygTooltip => 'Vaihda WYSIWYG-muokkainniin';
  @override
  String get switchToSourceTooltip => 'Vaihda Markdown-lähdekoodiin';
  @override
  String get wysiwygTooLarge =>
      'Tämä muistiinpano on liian suuri WYSIWYG-muokkainille. Avaa se '
      'Markdown-lähdekoodina.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Ulkoasu';
  @override
  String get settingsSectionEditor => 'Muokkain';
  @override
  String get settingsSectionLibrary => 'Kirjasto';
  @override
  String get settingsSectionReminders => 'Muistutukset';
  @override
  String get settingsSectionShortcuts => 'Näppäimistö';
  @override
  String get keyboardShortcutsTitle => 'Näppäimistön oikotiet';
  @override
  String get settingsSectionDiagnostics => 'Diagnostiikka';
  @override
  String get settingsSpellCheckTitle => 'Oikoluku';
  @override
  String get settingsSpellCheckSubtitle =>
      'Alleviivaa kirjoitustarkkuusvirheet kirjoittaessa.';
  @override
  String get spellCheckDictionaryTitle => 'Sanakirja';
  @override
  String get spellCheckDictionarySystem => 'Järjestelmän oletus';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Sanakirjojen valinta';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Valitse kaikki kielet, joilla kirjasto on kirjoitettu. Sana '
      'läpäisee, jos valittu sanakirja tuntee sen; ilman valintaa '
      'päätöstä ohjaa järjestelmän kieli.';
  @override
  String get spellCheckNoDictionaries =>
      'Sanakirjoja ei löytynyt tältä järjestelmältä.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Oikoluku';
  @override
  String get spellCheckTitle => 'Kirjoitustarkkuus';
  @override
  String get spellCheckEmpty => 'Ei kirjoitusvirheita.';
  @override
  String get spellCheckUnavailable =>
      'hunspell ei ole asennettu tälle järjestelmälle.';
  @override
  String get spellCheckNoSuggestions => 'Ei ehdotuksia';
  @override
  String spellCheckCount(int count) => '$count tarkistettavana';
  @override
  String spellCheckLine(int line) => 'rivi $line';

  @override
  String indentWidthValue(int spaces) => '$spaces välilyöntiä';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Kirkkaus';
  @override
  String get themeBrightnessSubtitle => 'Vaalea, tumma tai laitteen asetus';
  @override
  String get themeBrightnessSystem => 'Järjestelmä';
  @override
  String get themeBrightnessDay => 'Vaalea';
  @override
  String get themeBrightnessNight => 'Tumma';
  @override
  String get themePaletteTitle => 'Väripaletti';
  @override
  String get themePaletteSubtitle => 'Käyttöliittymän ja muistiinpanon värit';
  @override
  String get themePaletteSystem => 'Järjestelmä';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Käyttöliittymätekstin koko';
  @override
  String get uiTextScaleSubtitle =>
      'Puu, välilehdet ja dialogit; järjestelmän asetuksen päälle';
  @override
  String get noteTextScaleTitle => 'Muistiinpanon tekstin koko';
  @override
  String get noteTextScaleSubtitle => 'Muokkain ja esikatselu aina samassa';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Esikatselutila';
  @override
  String get previewModeSubtitle =>
      'Jakoiko esikatselu ruudun muokkainnin kanssa vai korvaa se sen';
  @override
  String get previewModeAuto => 'Vierekkäin';
  @override
  String get previewModeSwitch => 'Koko näyttö';
  @override
  String get splitRatioTitle => 'Jako-osuuden leveys';
  @override
  String get splitRatioSubtitle =>
      'Muokkainnin osa, kun esikatselu on vierekkäin';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Linkin muoto';
  @override
  String get linkTypeSubtitle => 'Mitä linkkipainike kirjoittaa muokkainnin';
  @override
  String get linkTypeWikilink => 'Wikilinkki';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Sisäännyrjäyksen leveys';
  @override
  String get indentWidthSubtitle =>
      'Välilyöntien määrä, joka lisätään sisäännyrjäyksen tasolla '
      'muokkainnissa';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Kieli';
  @override
  String get languageSubtitle => 'Itse sovelluksen tekstin kieli';
  @override
  String get languageSystem => 'Järjestelmä';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Lisää kohde';
  @override
  String get listAddTooltip => 'Lisää kohde';
  @override
  String get listEmpty => 'Ei vielä kohteita';
  @override
  String get listDragHandleLabel => 'Muuta kohteen järjestys';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Pikamuistiinpano';
  @override
  String get shortcutNewTodo => 'Uusi tehtävä';
  @override
  String get shortcutNewNote => 'Uusi muistiinpano';
  @override
  String get shortcutNewList => 'Uusi lista';
  @override
  String get shortcutToggleSidebar => 'Näytä tai piilota suodatin';
  @override
  String get shortcutEditorSection => 'Muokkainnissa';
  @override
  String get shortcutFind => 'Etsi';
  @override
  String get shortcutReplace => 'Etsi ja korvaa';
  @override
  String get shortcutSavingNote =>
      'Muutokset tallentuvat automaattisesti, joten tallennuksen oikotietä '
      'ei ole.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Rakenne';
  @override
  String get outlineNoHeadings => 'Ei otsikoita';
  @override
  String get outlineNoTitle => '(ei otsikoa)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Lihavointi';
  @override
  String get toolbarItalic => 'Kursivointi';
  @override
  String get toolbarStrikethrough => 'Yläviiva';
  @override
  String get toolbarSuperscript => 'Yläindeksi';
  @override
  String get toolbarUnderline => 'Alleviivaus';
  @override
  String get toolbarLink => 'Linkki';
  @override
  String get toolbarCode => 'Koodilohko';
  @override
  String get toolbarImage => 'Lisää kuva';
  @override
  String get toolbarHeading => 'Otsikko';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Numeroitu lista';
  @override
  String get toolbarQuote => 'Lainaus';
  @override
  String get toolbarIndent => 'Sisäännyrjäys';
  @override
  String get toolbarOutdent => 'Ulosnyrjäys';
  @override
  String get headingDialogTitle => 'Otsikon taso';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Muokkainnin työkalupalkki';
  @override
  String get toolbarSettingsHint =>
      'Vedä muuttaaksesi järjestystä; silmä näytetään tai piilotaan '
      'painike.';
  @override
  String get toolbarShowButton => 'Näytä';
  @override
  String get toolbarHideButton => 'Piilota';
  @override
  String get toolbarResetOrder => 'Palauta oletus';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Näytä esikatselu';
  @override
  String get showEditorTooltip => 'Näytä muokkain';
  @override
  String get enterFullScreenTooltip => 'Koko näyttö';
  @override
  String get exitFullScreenTooltip => 'Poistu kokonäytöstä';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(raaka HTML-taulukko)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Etsi muistiinpanoista';
  @override
  String get searchModeWords => 'Sanat';
  @override
  String get searchModeContains => 'Sisältää';
  @override
  String get searchEmptyHint =>
      'Kirjoita etsiäksesi kirjastosta, tai avain = arvo suodatukseksi '
      'frontmatterin mukaan';
  @override
  String get searchTooShortHint => 'Kirjoita vähintään 2 merkkiä';
  @override
  String get searchNoMatches => 'Ei osumia';
  @override
  String get searchLoadMore => 'Näytä lisää';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Korvaa…';
  @override
  String get replaceInNoteAction => 'Korvaa tässä muistiinpanossa…';
  @override
  String get replaceInThisNote => 'Korvaa tässä muistiinpanossa';
  @override
  String get replaceWithLabel => 'Korvaa tällä';
  @override
  String get replaceCaseSensitive => 'Havaitse isot ja pienet kirjaimet';
  @override
  String get replaceWholeWordsHint =>
      'korvataan vain täydet sanan kokonaisuudet';
  @override
  String get replaceConfirm => 'Korvaa';
  @override
  String get replaceCancel => 'Sulje';
  @override
  String get replaceUnavailable => 'Korvaus ei nyt ole käytettävissä';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Etsi muistiinpanosta';
  @override
  String get editorFindHint => 'Etsi';
  @override
  String get editorReplaceHint => 'Korvaa';
  @override
  String get editorFindCaseTooltip => 'Havaitse isot ja pienet kirjaimet';
  @override
  String get editorFindPreviousTooltip => 'Edellinen osuma';
  @override
  String get editorFindNextTooltip => 'Seuraava osuma';
  @override
  String get editorFindCloseTooltip => 'Sulje haku';
  @override
  String get editorFindReplaceModeTooltip => 'Korvaustila';
  @override
  String get editorReplaceOneTooltip => 'Korvaa tämä osuma';
  @override
  String get editorReplaceAllTooltip => 'Korvaa kaikki osumat';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tunnisteet';
  @override
  String get tagsTitle => 'Tunnisteet';
  @override
  String get tagsEmpty =>
      'Ei vielä tunnistetta — lisää #tunniste tai tunnistetta '
      'frontmatteriin';
  @override
  String get tagsBackTooltip => 'Takaisin hakuun';
  @override
  String get tagsNotesEmpty => 'Ei muistiinpanoja tällä tunnisteen kanssa';
  @override
  String tagsNotesCapped(int limit) =>
      'Näytetään vain ensimmäiset $limit — etsi tunnistetta rajaksi';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Linkkiä ei löytynyt';
  @override
  String get headingNotFoundTitle => 'Otsikkoa ei löytynyt';
  @override
  String get ambiguousLinkTitle => 'Useat muistiinpanot täsmäävät';
  @override
  String get openLinkFailed => 'Linkkiä ei voitu avata';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Avoimet';
  @override
  String get todoDone => 'Valmiit';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Kaikki päivämäärät';
  @override
  String get todoFilter => 'Suodata';
  @override
  String get todoNoTokens => 'Ei tokeneita tällä listalla';
  @override
  String get todoCountOpen => 'avoinna';
  @override
  String get todoCountDone => 'valmiina';
  @override
  String get todoEmptyOpen => 'Ei vielä avoimia tehtäviä';
  @override
  String get todoEmptyDone => 'Ei vielä valmiita';
  @override
  String get todoEmptyFiltered => 'Ei tehtäviä, jotka täsmäävät';
  @override
  String get todoTitle => 'Tehtävät';
  @override
  String get todoAddTooltip => 'Lisää tehtävä';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt-muoto';
  @override
  String get todoHelpTooltip => 'Muodon tiedot';
  @override
  String get todoHelpIntro =>
      'Tehtäväsi ovat tavallinen tekstitiedosto, yksi tehtävä per rivi. '
      'Niman kirjoittaa syntaksin puolestasi, mutta ei mitään peittele: '
      'voit muokata tiedostoa millä tahansa muokkainnilla ja Niman lukee '
      'sen uudelleen.';
  @override
  String get todoHelpFilesTitle => 'Kaksi tiedostoa';
  @override
  String get todoHelpFilesBody =>
      'Avoinna olevat tehtävät asuvat todo.txt:ssä kirjaston juuressa. '
      'Kun valmiit teet yhden, rivi siirtyy done.txt:ään, jolloin '
      'todo.txt pysyy lyhyenä. Jos valmis rivi joutuu uudestaan '
      'todo.txt:ään, Niman arkistoi sen seuraavan lukuoperaation aikana.';
  @override
  String get todoHelpLineTitle => 'Rivin rakenne';
  @override
  String get todoHelpLineBody =>
      'Kaikki kuvausten eteen on valinnainen ja sen tulee tulla tässä '
      'järjestyksessä:';
  @override
  String get todoHelpDoneBody =>
      'Merkitsee tehtävän valmiiksi. Niman lisää sen, kun merkitset '
      'valintaruudun.';
  @override
  String get todoHelpPriority => '(A)–(Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioriteetti. A on korkein. Näytetään listan tarrana.';
  @override
  String get todoHelpDatesBody =>
      'Suorituspäivä, sitten luontipäivä. Yhden päivämäärän kanssa se on '
      'luontipäivä, ellei rivi ala x:llä.';
  @override
  String get todoHelpTokensTitle => 'Projektit, kontekstit ja tunnistet';
  @override
  String get todoHelpTokensBody =>
      'Kaikessa kuvauksessa sana, jolla on jokin näistä etuliitteistä, '
      'tulee suodatettavaksi etiketiksi. Mikään ei ole ennalta määritelty: '
      'tokeni on olemassa, kun sen kirjoitat.';
  @override
  String get todoHelpProjectBody =>
      'Mihin tehtävä kuuluu, esimerkiksi +keittiö tai +työ.';
  @override
  String get todoHelpContextBody =>
      'Missä tai miten sen teet, esimerkiksi @koti tai @kokoukset.';
  @override
  String get todoHelpHashtagBody =>
      'Vapaatunniste kaikelle, mitä ei kata kaksi muuta.';
  @override
  String get todoHelpTagsTitle => 'Päivämäärät ja muistutukset';
  @override
  String get todoHelpTagsBody =>
      'Nämä ovat avain-arvo-merkinnät. Niman kirjoittaa ne tehtävädialogista '
      'ja lukee ne rivillä, missä ne esiintyvät.';
  @override
  String get todoHelpDueBody =>
      'Eräpäivä. Hallitsee tarran väriä ja päivämääräsuodattimet.';
  @override
  String get todoHelpRemBody =>
      'Milloin ilmoitus tulee lähettää, paikallisessa ajassa. Laukaa, kun '
      'näyttö on suljettu ja sovellus suljettu.';
  @override
  String get todoHelpRemDesktop =>
      'Tietokoneella Nimanin pitää olla käynnissä, kun aika koittaa: '
      'muistutus näytetään, kun sovellus on auki, eikä mitään laueta, '
      'kun se on suljettu.';
  @override
  String get todoHelpOtherBody =>
      'Säilytetään juuri niin kuin on kirjoitettu, jotta muiden '
      'todo.txt-sovellusten merkinnät selviävät matkan. Niman ei käytä '
      'niitä, rec: included: toistuva tehtävä ei vielä toistu.';
  @override
  String get todoHelpEditTitle => 'Muokkaus Nimanin ulkopuolella';
  @override
  String get todoHelpEditBody =>
      'Tehtävä, jota et kosketa, kirjoitetaan uudelleen tavu kerrallaan, '
      'myös kummatkin välit. Kun muokkaat riviä, Niman kirjoittaa vain '
      'sen rivin omassa kanonisessa muodossa ja jättää loput tiedostoa '
      'koskematta.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Lisää tehtävä';
  @override
  String get todoEditTitle => 'Muokkaa tehtävä';
  @override
  String get todoDescriptionHint => 'Kuvaus';
  @override
  String get todoCancel => 'Peruuta';
  @override
  String get todoSave => 'Tallenna';
  @override
  String get todoEditAction => 'Muokkaa';
  @override
  String get todoDeleteAction => 'Poista';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Myöhässä';
  @override
  String get todoDueToday => 'Tänään';
  @override
  String get todoDueNext7 => 'Seuraavat 7 päivää';
  @override
  String get todoDueNoDate => 'Ilman päivämäärää';
  @override
  String get todoRowDue => 'Eräpäivä';
  @override
  String get todoRowDueToday => 'Eräpäivä tänään';
  @override
  String get todoSortTooltip => 'Järjestä';
  @override
  String get todoSortDue => 'Eräpäivä';
  @override
  String get todoSortPriority => 'Prioriteetti';
  @override
  String get todoSortCreation => 'Luontipäivä';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Ei prioriteettia';
  @override
  String get todoNoPriorityShort => 'Ei';
  @override
  String get todoMorePriorities => 'Lisää…';
  @override
  String get todoPriorityTitle => 'Prioriteetti';
  @override
  String get todoNoDueDate => 'Ei eräpäivää';
  @override
  String get todoNoReminder => 'Ei muistutusta';
  @override
  String get todoAddProject => '+ Projekti';
  @override
  String get todoAddContext => '@ Konteksti';
  @override
  String get todoAddHashtag => '# Tunniste';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Tehtävämuistutukset';
  @override
  String get todoReminderChannelDescription =>
      'Suunnitellut ilmoitukset tehtäville, joilla on muistutusaika.';
  @override
  String get todoReminderBody => 'Tehtävän muistutus';
  @override
  String get todoReminderFallbackTitle => 'Tehtävän muistutus';
  @override
  String get todoReminderBlocked =>
      'Ilmoitukset ovat poiskytketyt, joten muistutuksia ei näytetä.';
  @override
  String get todoReminderBattery =>
      'Akun säästö on päällä Nimanissa. Järjestelmä voi keskeyttää '
      'sovelluksen ja menettää odottavat muistutukset.';
  @override
  String get todoReminderInexact =>
      'Tämä laite ei tue tarkkoja hälytyksiä, joten muistutus voi '
      'saapua muutama minuutti myöhemmin, kun näyttö on suljettu.';
  @override
  String get reminderShowTokensTitle => 'Tunnisteet muistutusilmoituksissa';
  @override
  String get reminderShowTokensSubtitle =>
      'Jätä +projekti, @konteksti ja #tunniste ilmoituksen tekstiin. '
      'Poiskytkettynä näytetään vain kirjoittamasi tehtävä.';
  @override
  String get todoReminderFixAction => 'Avaa asetukset';
  @override
  String get todoReminderDismissAction => 'Hylkää';
  @override
  String get todoReminderDue => 'Eräpäivä';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Peruuta';
  @override
  String get actionCreate => 'Luo';
  @override
  String get actionNew => 'Uusi';
  @override
  String get actionSave => 'Tallenna';
  @override
  String get actionClear => 'Tyhjennä';
  @override
  String get actionChoose => 'Valitse';
  @override
  String get actionDelete => 'Poista';
  @override
  String get actionRename => 'Nimeä uudelleen';
  @override
  String get actionMove => 'Siirrä';
  @override
  String get saveAndClose => 'Tallenna ja sulje';
  @override
  String get closeUnsavedTitle => 'Tallentamattomat muutokset';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” sisältää tallentamattomia muutoksia. '
          'Tallennetaanko ne ennen sulkemista?';
    }
    return '${names.length} muistiinpanoa sisältää tallentamattomia '
        'muutoksia. Tallennetaanko ne ennen sulkemista?';
  }

  @override
  String get closeSaveFailed => 'Tallennus epäonnistui; se on edelleen auki.';
  @override
  String get actionRestore => 'Palauta';
  @override
  String get actionEmpty => 'Tyhjennä';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Piilota sivupaneeli (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Näytä sivupaneeli (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Pienennä';
  @override
  String get windowMaximizeTooltip => 'Suurenna';
  @override
  String get windowRestoreTooltip => 'Palauta';
  @override
  String get windowCloseTooltip => 'Sulje';
  @override
  String get tabFiles => 'Tiedostot';
  @override
  String get tabSearch => 'Haku';
  @override
  String get tabSettings => 'Asetukset';
  @override
  String get quickNoteTitle => 'Pikamuistiinpano';
  @override
  String get treeEmpty => 'Ei vielä muistiinpanoja';
  @override
  String get selectANote => 'Valitse muistiinpano';
  @override
  String get showListTooltip => 'Näytä lista';
  @override
  String get editRawTooltip => 'Muokkaa raakana';
  @override
  String get sortAscTooltip => 'Järjestä A–Z';
  @override
  String get sortDescTooltip => 'Järjestä Z–A';
  @override
  String get newNoteTitle => 'Uusi muistiinpano';
  @override
  String get newFolderTitle => 'Uusi kansio';
  @override
  String get newNoteHere => 'Uusi muistiinpano tähän';
  @override
  String get newFolderHere => 'Uusi kansio tähän';
  @override
  String get newListNoteTitle => 'Uusi listamuistiinpano';
  @override
  String get newListNoteDefault => 'Listani';
  @override
  String get setAsQuickNote => 'Aseta pikamuistiinpanoksi';
  @override
  String get currentQuickNote => 'Nykyinen pikamuistiinpano';
  @override
  String get pinnedSection => 'Kiinnitetty';
  @override
  String pinnedSectionCount(int count) => 'Kiinnitetty · $count';
  @override
  String get templateFolderTitle => 'Mallipohjien kansio';
  @override
  String get newFromTemplateTitle => 'Uusi mallipohjasta';
  @override
  String get newFromTemplateHere => 'Uusi mallipohjasta tähän';
  @override
  String get templateFormTitle => 'Täytä mallipohja';
  @override
  String get templateFormBacklink => 'Linkitty';
  @override
  String get templateFormNoNote => 'Ei muistiinpanoa';
  @override
  String get templateFormPickNote => 'Valitse muistiinpano';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Mallipohjan väliaikaiset symbolit';
  @override
  String get templateHelpIntro =>
      'Mallipohja on tavallinen muistiinpano, jolla on reikät. '
      'Muistiinpanon luonti siitä kopioi tekstin ja täyttää reikät.';
  @override
  String get templateHelpUnknown =>
      'Nimanin tuntematon väliaikainen symboli jätetään juuri '
      'sellaiseksi kuin se on kirjoitettu, jolloin kirjoitusvirhe näkyy '
      'muistiinpanossa sen sijaan, että rivi hiljaisesti rikkoontuisi.';
  @override
  String get templateHelpValuesTitle => 'Arvot';
  @override
  String get templateHelpTitleBody => 'Nimi, jolla muistiinpano on luotava.';
  @override
  String get templateHelpDateBody =>
      'Tänään ja nykyinen aika. Molemmat hyväksyvät muodon: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Päivä ja aika yhdessä.';
  @override
  String get templateHelpUuidBody => 'Uusi tunnistus, eri jokaisessa käytössä.';
  @override
  String get templateHelpCounterBody =>
      'Luku, joka laskee nimellä ja joka säilyy käynnistysten välillä: '
      'ensimmäinen muistiinpano kirjoittaa 1, seuraava 2. Sama nimi '
      'muistiinpanossa kirjoittaa saman numeron; yhdistä |pad:3:n kanssa.';
  @override
  String get templateHelpCursorBody =>
      'Aseta osoitin tähän, kun muistiinpano luodaan; merkintää ei '
      'kirjoiteta. Ensimmäinen merkintä voittaa, ilman suodattimia, vain '
      'uudet muistiinpanot — ja näppäimistö avautuu myös autofokusin '
      'ollessa poiskytkettynä.';
  @override
  String get templateHelpDatesTitle => 'Päivämäärän kirjoittaminen';
  @override
  String get templateHelpDatesBody =>
      'Nämä edustavat päivämäärän osia muodossa. Kaikki muu on '
      'kirjaimellista, myös yksikertaluovissa oleva teksti. Kuukausien ja '
      'viikkopäivien nimet seuraavat sovelluksen kieltä.';
  @override
  String get templateHelpYear => 'vuosi: 2026, 26';
  @override
  String get templateHelpMonth => 'kuukausi: 03, 3, maaliskuu, maa';
  @override
  String get templateHelpDay => 'päivä: 09, 9, maanantai, ma';
  @override
  String get templateHelpTime => 'tunnit, minuutit, sekunnit';
  @override
  String get templateHelpWeek => 'ISO-viikko ja neljännes: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Suodattimet';
  @override
  String get templateHelpFiltersBody =>
      'Arvon jälkeen voi olla suodattimia, jotka sovelletaan vasemmalta '
      'oikealle.';
  @override
  String get templateHelpCaseBody =>
      'Isot, pienet kirjaimet ja jokaisen sanan ensimmäinen kirjain — '
      'sana, jonka olet kirjoittanut alusta isolla, ei muuteta.';
  @override
  String get templateHelpSlugBody =>
      'Linkin muoto tekstistä, jotta wikilinkki rakennetaan.';
  @override
  String get templateHelpPadBody =>
      'Leikkaa päätyt; täytä nollilla haluttuun leveyteen; käytä '
      'vaihtoehtoista, jos arvo on tyhjä.';
  @override
  String get templateHelpShiftBody =>
      'Siirrä päivämäärää päivillä, viikoilla, kuukausilla tai vuosilla '
      '— ensi viikon konferenssi, edellisen kuukauden tiedosto.';
  @override
  String get templateHelpSnapBody =>
      'Kiinnitä päivämäärä viikon, kuukauden tai vuoden alkuun tai '
      'loppuun.';
  @override
  String get templateHelpAskTitle => 'Kysyä jotain sinulta';
  @override
  String get templateHelpAskBody =>
      'Lomake näytetään ennen muistiinpanon luomista, yksi kenttä '
      'kysymykseen — ja yksi palautuslinkkiin, jos mallipohja sitä '
      'vaatii. Sama etiketti kaksi kertaa on kysymys, ja sen vastaus '
      'täyttää kaikki esiintymät — kansio ja tiedostonimi mukaan '
      'lukien.';
  @override
  String get templateHelpAskFieldBody =>
      'Kenttä, johon kirjoitetaan; teksti toisen kahvipilun jälkeen on '
      'alku.';
  @override
  String get templateHelpChoiceBody => 'Valinta listasta, pilkulla erottuna.';
  @override
  String get templateHelpWhereTitle => 'Mihin muistiinpano joutuu';
  @override
  String get templateHelpWhereBody =>
      'Nämä eivät ole tekstiä: ne ovat ohjeita ja ne asuvat niman: '
      'lohossa mallipohjan frontmatterissa. Lohko suoritetaan ja '
      'poistetaan, jolloin sitä ei koskaan näytetä muistiinpanossa. '
      'Arvo voi sisältää väliaikaisia symboleja.';
  @override
  String get templateHelpFolderBody =>
      'Kansio, johon muistiinpano luodaan; luodaan, jos sitä ei ole. '
      'Ilman sitä muistiinpano joutuu, jossa olit.';
  @override
  String get templateHelpFilenameBody =>
      'Mikä muistiinpanon nimi on. Mallipohja, joka sen sanoo, ei kysy '
      'nimeä.';
  @override
  String get templateHelpAppendBody =>
      'Lisää muistiinpanoon, jos se on jo olemassa, eikä luo uutta. '
      'Tämän ansiosta kuukauden kokoukset ovat yksi tiedosto.';
  @override
  String get templateHelpOpenBody =>
      'Mitä tapahtuu, jos muistiinpano on olemassa: muokkain (oletus), '
      'esikatselu, tai mitään — muistiinpano arkistoidaan ja pysyt, '
      'jossa olit.';
  @override
  String get templateHelpAroundTitle => 'Mistä se tuli';
  @override
  String get templateHelpParentBody =>
      'Muistiinpano, jonka valitset lomakkeesta, joka tarjotaan '
      'ruudulla; kirjoita [[{{parent}}]] palautuslinkki.';
  @override
  String get templateHelpFolderValueBody =>
      'Kansio, jossa muistiinpano joutui.';
  @override
  String get templateHelpClipboardBody =>
      'Mitä leikepöydällä on ja muokkainnin valinta, kun muistiinpano '
      'alkoi siitä.';
  @override
  String get templateHelpIncludeTitle => 'Osan uudelleenkäyttö';
  @override
  String get templateHelpIncludeBody =>
      'Liitä toinen mallipohja, jotta kymmenen mallipohjaa voi jakaa '
      'yhden tarkistuslistan. Etsitään ensin mallipohjien kansiosta, '
      '.md voidaan jättää pois. Sen omat kysymykset tulevat samaan '
      'lomakkeeseen.';
  @override
  String get templateHelpExampleTitle => 'Kaikki yhdessä';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ mallipohjaa “$path” ei ole';
  @override
  String includeCycle(String path) => '⚠ “$path” sisältää itsensä';
  @override
  String includeTooDeep(String path) =>
      '⚠ “$path” on liian syvällisesti sisäkkäinen';
  @override
  String frontmatterInvalid(String reason) =>
      'Frontmatteria ei voitu lukea: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      '“$template” -mallipohjan frontmatteria ei voitu lukea, joten '
      'kansio ja tiedostonimi eivät tehneet mitään: $reason';
  @override
  String get templatePickerTitle => 'Mallipohjan valinta';
  @override
  String templatePickerEmpty(String folder) =>
      'Ei vielä mallipohjaa. Aseta muistiinpano kansioon $folder/ ja se '
      'on.';

  // Tree actions.
  @override
  String get actionPin => 'Kiinnitä';
  @override
  String get actionUnpin => 'Irrota';
  @override
  String get movedToTrash => 'Siirretty koriin';
  @override
  String get deletedMessage => 'Poistettu';
  @override
  String deleteToTrashConfirm(String name) => '$name siirtyy kansioon .trash/';
  @override
  String deleteForeverConfirm(String name) => '$name poistetaan pysyvästi';
  @override
  String get chooseDestination => 'Valitse kohde';
  @override
  String get libraryRoot => 'Kirjaston juuri';
  @override
  String moveTitle(String name) => 'Siirrä $name';
  @override
  String headingLevelLabel(int level) => 'Otsikko $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ei vielä pikamuistiinpanoa. Valitse olemassa oleva muistiinpano '
      'tai luo — pikamuistiinpano avautuu tähän.';
  @override
  String get quickNoteChooseAction => 'Valitse muistiinpano…';
  @override
  String get quickNoteCreateAction => 'Luo uusi muistiinpano…';
  @override
  String get quickNoteNewTitle => 'Uusi pikamuistiinpano';
  @override
  String get quickNotePickerTitle => 'Pikamuistiinpanon valinta';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Uusi kansio';
  @override
  String get folderPickerEmpty => 'Ei vielä kansiota';
  @override
  String get listFolderTitle => 'Listojen kansio';

  // Trash (M1).
  @override
  String get trashEmpty => 'Korisi on tyhjä';
  @override
  String get trashEmptyAction => 'Tyhjennä kori';
  @override
  String get trashEmptyConfirm =>
      'Tämä poistaa pysyvästi kaiken, mikä on korissa, mukaan lukien '
      'kohteet, joita Niman ei ole sijoittanut.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name poistetaan pysyvästi (ei palautusta)';
  @override
  String get trashDeletePermanently => 'Poista pysyvästi';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Avaa Markdown-muistiinpanojen kansio kirjastona';
  @override
  String get openLibraryExisting => 'Avaa olemassa oleva';
  @override
  String get openLibraryCreate => 'Luo uusi';
  @override
  String get openLibraryCreateTitle => 'Luo uusi kirjasto';
  @override
  String get openLibraryFolderName => 'Kansion nimi';
  @override
  String get openLibraryChooseFolder => 'Valitse kirjaston kansio';
  @override
  String get openLibraryChooseParent =>
      'Valitse kansio, jossa kirjasto luodaan';
  @override
  String get openLibraryUnsupported =>
      'Tämä kansio ei tue. Valitse kansio laitteen tallennusalueelta.';
  @override
  String indexingCount(int done, int total) => '$done / $total muistiinpanoa';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Kirjastosi';
  @override
  String get libraryUnreachable => 'Ei saatavilla';
  @override
  String get libraryOpenedToday => 'Avattu tänään';
  @override
  String get libraryOpenedYesterday => 'Avattu eilen';
  @override
  String libraryOpenedDaysAgo(int days) => 'Avattu $days päivää sitten';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Avattu ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Avattu nyt';
  @override
  String get switchLibraryTitle => 'Vaihda kirjastoa';
  @override
  String get libraryForget => 'Unohda';
  @override
  String libraryForgetTitle(String name) => 'Unohdaako “$name”?';
  @override
  String get libraryForgetExplained =>
      'Katoaa tästä listasta. Kansio, muistiinpanot ja kirjaston '
      'asetukset jätetään koskematta, ja uudelleen avaaminen palauttaa '
      'sen.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Anna tiedostoihin pääsy';
  @override
  String get storageAccessNeeded =>
      'Niman ei voi lukea muistiinpanoittasi ilman “Kaikkien tiedostojen '
      'pääsyä”. Anna se kirjaston avaamiseksi.';
  @override
  String get storageAccessExplained =>
      'Niman lukee muistiinpanoittasi tavallisina tiedostoina, joten '
      'Androidin on annettava sille pääsy kaikkiin tiedostoihin. Mitään '
      'ei lähetetä, ja vain valitsemasi kirjaston kansio luetaan.';
  @override
  String folderAccessDenied(Object error) =>
      'Järjestelmä ei antanut pääsyä kansiota: $error';
  @override
  String folderPickFailed(Object error) =>
      'Kansion valinta epäonnistui: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Asetukset';
  @override
  String get libraryPathTitle => 'Kirjaston polku';
  @override
  String get reindexTitle => 'Luo hakuelokuva nyt';
  @override
  String get reindexDone => 'Hakuelokuvaaminen valmis';
  @override
  String get closeLibraryTitle => 'Sulje kirjasto';
  @override
  String get exportLogTitle => 'Vie vianetsintäloki';
  @override
  String get exportLogSubtitle =>
      'Tallenna lokatut tapahtumat tiedostoon, jonka valitset';
  @override
  String get exportLogEmpty => 'Vianetsintälokin puskuri on tyhjä';
  @override
  String get quickNoteUnset => 'Ei asetettu';
  @override
  String exportLogDone(Object target) => 'Vianetsintäloki viety ${target}iin';
  @override
  String exportLogFailed(Object error) => 'Vienti epäonnistui: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Ei täsmällistä kokonaissanan “$term” osumaa';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Korvattiin $occurrences “$term” -esintymää $notes muistiinpanossa';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped avointa muistiinpanoa ohitettu)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Ei täsmällistä kokonaissanan “$term” osumaa'
      '${only == null ? '' : ' löytyi ${only}ssa'}';
}
